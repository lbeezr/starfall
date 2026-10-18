import XCTest
import StarfallCore
@testable import Starfall

final class FallingSkyStoreTests: XCTestCase {
    @MainActor func testWelcomeSaveAvailabilityDoesNotWriteOrAdvanceSky() throws {
        let suite = "Starfall.Welcome.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.removePersistentDomain(forName: suite)
        let clock = ManualRainClock()
        let fresh = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
        XCTAssertFalse(fresh.hasSavedSky); XCTAssertTrue(fresh.suspended)
        XCTAssertNil(defaults.data(forKey: FallingSkyStore.saveKey))
        clock.advance(100); fresh.setReducedMotion(true)
        XCTAssertEqual(fresh.game.turns, 0); XCTAssertNil(clock.deadline)
        fresh.startFirstLight()
        XCTAssertTrue(fresh.hasSavedSky)
        let saved = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
        XCTAssertTrue(restored.hasSavedSky); XCTAssertEqual(restored.game, fresh.game)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved)
        defaults.set(Data([1,2,3]), forKey: FallingSkyStore.saveKey)
        let invalid = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
        XCTAssertFalse(invalid.hasSavedSky)
        XCTAssertEqual(SkyFlowScreen.initial(arguments: []), .welcome)
        XCTAssertEqual(SkyFlowScreen.initial(arguments: ["--starfalls-reset", "--sky-flow-review"]), .welcome)
    }

    @MainActor func testWelcomeRestoreKeepsCommittedSkyButNotTransientClearCopy() throws {
        let (store, presenter, _, defaults) = makeStore()
        store.callShower(); presenter.finish()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first)); presenter.finish()
        XCTAssertTrue(store.message.hasPrefix("+"))
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertTrue(restored.hasSavedSky)
        XCTAssertEqual(restored.game, store.game)
        XCTAssertTrue(restored.message.contains("Your sky is paused"))
        XCTAssertFalse(restored.message.contains("+"))
    }

    @MainActor private func makeStore() -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let defaults = UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)")!
        // Keep the established legacy-clock regression scenarios source-bound.
        // New-opening behavior is exercised separately below with a fresh store.
        defaults.set(try! JSONEncoder().encode(FallingSky(seed: 5,
            balance: .init(pace: .steady), openingCascade: false)), forKey: SkySaveArchive.legacyKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-seed=5"], presenter: presenter, clock: clock)
        addTeardownBlock { defaults.removeObject(forKey: SkySaveArchive.legacyKey); defaults.removeObject(forKey: SkySaveArchive.key) }
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
    }

    @MainActor private func makeOpeningStore(seed: UInt64 = 5) -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.Opening.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=\(seed)"],
                                   presenter: presenter, clock: clock)
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
    }

    @MainActor func testOpeningClearBeforeFinalWaveKeepsDeadlineAndRegularPace() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        XCTAssertEqual(store.game.occupiedCount, 0)
        clock.advance(20); XCTAssertEqual(store.game.turns, 0)
        store.togglePause()
        clock.advance(0.24); XCTAssertEqual(store.game.turns, 0)
        clock.advance(0.01); XCTAssertEqual(store.game.turns, 1)
        XCTAssertFalse(store.canClear, "A single in-flight batch remains atomic")
        clock.advance(1) // Full normal animation would have settled by this point.
        presenter.finish()
        XCTAssertTrue(store.canClear); XCTAssertTrue(store.game.isOpeningCascade)
        let deadline = clock.deadline
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
        XCTAssertEqual(store.game.score, 3)
        XCTAssertEqual(clock.deadline, deadline)
        clock.advance(0.56); presenter.finish()
        for turn in 2...4 {
            clock.advance(try XCTUnwrap(clock.deadline) - clock.now)
            XCTAssertEqual(store.game.turns, turn)
            presenter.finish()
        }
        XCTAssertFalse(store.game.isOpeningCascade)
        XCTAssertEqual(store.showerInterval, 2)
        clock.advance(1.99); XCTAssertEqual(store.game.turns, 4)
        clock.advance(0.01); XCTAssertEqual(store.game.turns, 5)
    }

    @MainActor func testOpeningShowerInvalidatesTraceWithoutPostponingDeadline() throws {
        let (store, presenter, clock, defaults) = makeOpeningStore(seed: 4)
        store.togglePause()
        for _ in 0..<3 {
            clock.advance(try XCTUnwrap(clock.deadline) - clock.now)
            presenter.finish()
        }
        let source = store.game, generation = store.constellationInputGeneration
        let intent = ConstellationTraceIntent()
        let path = (0..<5).map { Cell(0, $0) }
        XCTAssertNotNil(source.constellationCells(along: path))
        let start = try XCTUnwrap(path.first)
        let ticket = try XCTUnwrap(intent.begin(start, game: source,
            generation: generation, enabled: store.canClear))
        for cell in path.dropFirst() {
            XCTAssertTrue(intent.visit(cell, ticket: ticket, game: source,
                generation: generation, enabled: store.canClear))
        }
        let deadline = try XCTUnwrap(clock.deadline)
        clock.advance(deadline - clock.now)
        XCTAssertEqual(store.game.turns, 4)
        XCTAssertNotEqual(store.constellationInputGeneration, generation)
        presenter.finish()
        XCTAssertNil(intent.finish(ticket: ticket, game: store.game,
            generation: store.constellationInputGeneration, enabled: store.canClear))
        let committed = store.game
        store.clearTracedConstellation(path, snapshot: source, generation: generation)
        XCTAssertEqual(store.game, committed)
        let saved = try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(saved, committed)
        XCTAssertEqual(store.showerInterval, 2)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 2, accuracy: 0.001)
    }

    @MainActor func testOpeningRestoreAndRestartRejectStaleWork() throws {
        let (store, presenter, clock, defaults) = makeOpeningStore()
        store.togglePause(); clock.advance(0.25)
        let staleTimer = clock.action, staleAnimation = presenter.completions.last
        store.setSuspended(true)
        clock.advance(100); staleTimer?(); staleAnimation?()
        XCTAssertEqual(store.game.turns, 1)
        let restoredClock = ManualRainClock()
        let restored = FallingSkyStore(defaults: defaults, presenter: FallingSkyRecorder(), clock: restoredClock)
        XCTAssertEqual(restored.game, store.game)
        XCTAssertTrue(restored.isPaused); XCTAssertEqual(restored.showerInterval, 1.8)
        restored.setSuspended(false); restoredClock.advance(100)
        XCTAssertEqual(restored.game.turns, 1)
        restored.togglePause(); restoredClock.advance(1.8)
        XCTAssertEqual(restored.game.turns, 2, "Restoring never repeats the opening's first wave")
        store.restart(sameSky: true)
        staleTimer?(); staleAnimation?()
        XCTAssertEqual(store.game.turns, 0); XCTAssertEqual(store.game.occupiedCount, 0)
        XCTAssertTrue(store.game.hasOpeningCascade); XCTAssertEqual(store.showerInterval, 0.25)
    }

    @MainActor func testOpeningSettingsMotionAndPendingClearHaveNoCatchUp() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.togglePause(); clock.advance(0.25)
        store.setReducedMotion(true)
        XCTAssertFalse(store.busy); XCTAssertEqual(presenter.lastRendered, store.game)
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
        clock.advance(100)
        XCTAssertEqual(store.game.turns, 1)
        XCTAssertFalse(store.canClear)
        presenter.finish(); XCTAssertEqual(store.game.turns, 2)
        store.setSuspended(true); store.setPace(.gentle)
        clock.advance(100); presenter.finish()
        XCTAssertEqual(store.game.turns, 2)
        store.setSuspended(false)
        clock.advance(1.79); XCTAssertEqual(store.game.turns, 2)
        clock.advance(0.01); XCTAssertEqual(store.game.turns, 3)
        presenter.finish(); clock.advance(1.8); presenter.finish()
        XCTAssertEqual(store.game.turns, 4); XCTAssertEqual(store.showerInterval, 6)
    }

    @MainActor func testAutomaticClockStartsOnlyOnRequestAndCommitsBeforeAnimation() throws {
        let (store, presenter, clock, defaults) = makeStore()
        clock.advance(20); XCTAssertEqual(store.game.turns, 0)
        store.togglePause()
        clock.advance(3.9); XCTAssertEqual(store.game.turns, 0)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 1); XCTAssertTrue(store.busy)
        let saved = try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(store.game, saved)
        store.clear(Cell(0, 0)); XCTAssertEqual(store.game, saved)
        presenter.finish()
        clock.advance(4); XCTAssertEqual(store.game.turns, 2)
    }

    @MainActor func testClearsAndInvalidTapsDoNotPostponeRainAndDueRainCannotBeStarved() throws {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause()
        let deadline = clock.deadline
        store.clear(Cell(0, 0)); XCTAssertEqual(clock.deadline, deadline)
        for _ in 0..<20 where store.game.legalGroups.isEmpty && !store.game.isOver {
            clock.advance(4); presenter.finish()
        }
        let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
        let showers = store.game.turns
        clock.advance(3.9)
        let imminent = clock.deadline
        store.clear(cell)
        XCTAssertEqual(clock.deadline, imminent); XCTAssertEqual(store.game.turns, showers)
        XCTAssertGreaterThan(store.game.score, 0)
        clock.advance(0.1)
        XCTAssertEqual(store.game.turns, showers, "Finish the committed clear before presenting rain")
        store.clear(cell)
        presenter.finish()
        XCTAssertEqual(store.game.turns, showers + 1)
        XCTAssertTrue(store.busy, "A due shower takes priority over another clear")
        presenter.finish(); XCTAssertFalse(store.busy)
    }

    @MainActor func testPauseAndBackgroundFreezeRemainingTimeWithoutCatchUp() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(2)
        store.togglePause(); clock.advance(100)
        XCTAssertEqual(store.game.turns, 0); XCTAssertNil(store.nextShowerDate)
        store.togglePause(); clock.advance(1.9); XCTAssertEqual(store.game.turns, 0)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 1)
        store.setSuspended(true)
        XCTAssertFalse(store.busy); XCTAssertNil(store.pending)
        clock.advance(100)
        presenter.finish() // stale animation completion
        XCTAssertEqual(store.game.turns, 1)
        store.setSuspended(false)
        clock.advance(3.9); XCTAssertEqual(store.game.turns, 1)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 2)
    }

    @MainActor func testLateClockAndLongAnimationNeverQueueABurst() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(100)
        XCTAssertEqual(store.game.turns, 1)
        clock.advance(100) // at most one due shower while the presenter is busy
        XCTAssertEqual(store.game.turns, 1)
        presenter.finish()
        XCTAssertEqual(store.game.turns, 2)
        presenter.finish()
        XCTAssertEqual(store.game.turns, 2)
        clock.advance(3.9); XCTAssertEqual(store.game.turns, 2)
    }

    @MainActor func testRestartRejectsStaleTimerAndAnimationAndRestoreStartsPaused() {
        let (store, presenter, clock, defaults) = makeStore()
        let initial = store.game
        defaults.set(Data([1,2,3]), forKey: "starfall.game.v1")
        defer { defaults.removeObject(forKey: "starfall.game.v1") }
        store.togglePause()
        let staleTimer = clock.action
        clock.advance(4)
        let staleAnimation = presenter.completions[0]
        store.restart(sameSky: true)
        staleTimer?(); staleAnimation()
        XCTAssertEqual(store.game, initial); XCTAssertTrue(store.isPaused); XCTAssertFalse(store.busy)
        store.togglePause(); clock.advance(4)
        staleAnimation(); XCTAssertTrue(store.busy)
        presenter.finish()
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, store.game); XCTAssertTrue(restored.isPaused)
        XCTAssertEqual(defaults.data(forKey: "starfall.game.v1"), Data([1,2,3]))
    }

    @MainActor func testCalmChangeSettlesCommittedBoardAndKeepsClock() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(4)
        let deadline = clock.deadline
        store.setReducedMotion(true)
        XCTAssertTrue(presenter.reduceMotion); XCTAssertFalse(store.busy)
        XCTAssertEqual(presenter.lastRendered, store.game)
        XCTAssertEqual(clock.deadline, deadline)
        presenter.finish(); XCTAssertEqual(store.game.turns, 1)
    }

    @MainActor func testDiscardedResetStorePreservesLiveSaveUntilActivation() throws {
        let (store, presenter, clock, defaults) = makeStore()
        store.togglePause(); clock.advance(4); presenter.finish()
        store.setSuspended(true)
        XCTAssertEqual(store.game.turns, 1)
        let committed = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        let resetArguments = ["--starfalls-reset", "--starfalls-seed=5"]

        do {
            let discarded = FallingSkyStore(defaults: defaults, arguments: resetArguments,
                presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(discarded.game.turns, 0)
            XCTAssertTrue(discarded.suspended)
        }
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), committed,
                       "Constructing a discarded view's store must not replace the live save")

        let restored = FallingSkyStore(defaults: defaults, arguments: [],
            presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, store.game)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), committed)

        let resetClock = ManualRainClock()
        let reset = FallingSkyStore(defaults: defaults, arguments: resetArguments,
            presenter: FallingSkyRecorder(), clock: resetClock)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), committed)
        reset.setSuspended(false)
        let activated = try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(activated, FallingSky(seed: 5, generation: .current, duskRule: .feeding))
        XCTAssertEqual(activated, reset.game)
        XCTAssertTrue(reset.isPaused)
        XCTAssertNil(resetClock.deadline, "Activation preserves the explicit Start sky boundary")
    }

    @MainActor func testOverflowStopsClockAndPauseCanCancelPendingRain() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(4); clock.advance(4)
        store.togglePause()
        presenter.finish()
        XCTAssertEqual(store.game.turns, 1); XCTAssertNil(clock.deadline)
        store.togglePause()
        for _ in 0..<40 where !store.game.isOver { clock.advance(4); presenter.finish() }
        XCTAssertTrue(store.game.isOver); XCTAssertNil(clock.deadline)
        let ended = store.game
        clock.advance(100); store.togglePause(); store.clear(Cell(0, 0))
        XCTAssertEqual(store.game, ended)
    }

    @MainActor func testDarkStarFeedbackClearAndSavedInfluence() throws {
        let (store, presenter, clock, defaults) = makeStore()
        store.togglePause()
        for _ in 0..<6 { clock.advance(4); presenter.finish() }
        // Search by behavior rather than an obsolete seed-specific cell layout.
        for _ in 0..<30 where !store.game.isOver && !store.game.legalGroups.contains(where: { !store.game.darkStarsBeside(Set($0)).isEmpty }) {
            if let cell = store.game.legalGroups.first?.first { store.clear(cell); presenter.finish() }
            clock.advance(4); presenter.finish()
        }
        let group = try XCTUnwrap(store.game.legalGroups.first { !store.game.darkStarsBeside(Set($0)).isEmpty })
        let dark = try XCTUnwrap(store.game.darkStarsBeside(Set(group)).first)
        let beside = try XCTUnwrap(group.first { store.game.isDrained(at: $0) })
        let expectedScore = store.game.score + store.game.reward(of: Set(group))
        let expectedDark = store.game.darkStarsCleared + store.game.darkStarsBeside(Set(group)).count
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, store.game)
        XCTAssertTrue(restored.isPaused)
        let before = store.game
        store.clear(dark)
        XCTAssertEqual(store.game, before)
        XCTAssertTrue(store.message.contains("dissolve"))
        store.clear(beside)
        XCTAssertEqual(store.game.darkStarsCleared, expectedDark)
        XCTAssertEqual(store.game.score, expectedScore)
        XCTAssertTrue(store.message.contains("Dusk dissolved"))
        let saved = try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(saved, store.game)
        XCTAssertTrue(saved.isValidSave)
    }

    @MainActor func testPaceChangeSettlesCommittedArrivalAndRejectsOldCallbacks() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(4)
        let oldTimer = clock.action, oldAnimation = presenter.completions.last
        let board = store.game.board, preview = store.game.incoming
        store.setPace(.gentle)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game.board, board); XCTAssertEqual(store.game.incoming, preview)
        XCTAssertEqual(clock.deadline, 10)
        oldTimer?(); oldAnimation?()
        XCTAssertEqual(store.game.turns, 1)
        clock.advance(5.9); XCTAssertEqual(store.game.turns, 1)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 2)
        presenter.finish()
        let deadline = clock.deadline
        store.setPace(.gentle)
        XCTAssertEqual(clock.deadline, deadline, "Selecting the current balance does not postpone rain")
    }

    @MainActor func testSettingsChangesWaitForDismissalAndBackgroundKeepsNewPace() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(2)
        store.setSuspended(true)
        store.setPace(.brisk); store.setDarkStarFrequency(.frequent)
        XCTAssertNil(clock.deadline)
        clock.advance(100); XCTAssertEqual(store.game.turns, 0)
        store.setSuspended(false)
        clock.advance(2.9); XCTAssertEqual(store.game.turns, 0)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 1)
        presenter.finish()
        clock.advance(1); store.setSuspended(true)
        clock.advance(100); store.setSuspended(false)
        clock.advance(1.9); XCTAssertEqual(store.game.turns, 1)
        clock.advance(0.1); XCTAssertEqual(store.game.turns, 2)
    }

    @MainActor func testBalancePersistsThroughReplayNewSkyAndRelaunch() {
        let (store, presenter, clock, defaults) = makeStore()
        let balance = StarfallBalance(pace: .gentle, darkStars: .none)
        store.setBalance(balance)
        XCTAssertNil(clock.deadline); XCTAssertTrue(store.isPaused)
        store.togglePause(); clock.advance(6); presenter.finish()
        let firstPreview = store.game.incoming
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.balance, balance); XCTAssertEqual(store.game.turns, 0)
        store.togglePause(); clock.advance(6); presenter.finish()
        XCTAssertEqual(store.game.incoming, firstPreview)
        store.restart(sameSky: false)
        XCTAssertEqual(store.game.balance, balance); XCTAssertTrue(store.isPaused)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, store.game); XCTAssertEqual(restored.game.balance.pace, .gentle)
        XCTAssertEqual(restored.showerInterval, 0.25, "A genuinely new sky gets an opening even after a legacy round")
        let board = restored.game.board
        restored.setBalance(StarfallBalance())
        XCTAssertEqual(restored.game.balance.pace, .brisk); XCTAssertEqual(restored.game.board, board)
        XCTAssertEqual(restored.showerInterval, 0.25)
        XCTAssertTrue(restored.isPaused)
    }
    @MainActor func testChallengeCompletionStopsClockRestoresAndReplays() throws {
        let (store, presenter, clock, defaults) = makeStore()
        store.startFirstLight()
        let initial = store.game
        XCTAssertEqual(initial.challenge, .firstLight)
        XCTAssertNil(clock.deadline); XCTAssertTrue(store.isPaused)
        store.togglePause()
        for _ in 0..<30 where !store.game.isOver {
            clock.advance(4); presenter.finish()
            while !store.game.isOver, let cell = store.game.legalGroups.first?.first {
                store.clear(cell); presenter.finish()
            }
        }
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertNil(clock.deadline); XCTAssertFalse(store.canClear)
        let completed = store.game
        clock.advance(100); store.callShower(); store.togglePause(); store.clear(Cell(0, 0))
        XCTAssertEqual(store.game, completed)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, completed); XCTAssertTrue(restored.message.contains("complete"))
        restored.restart(sameSky: false)
        XCTAssertNil(restored.game.challenge)
        XCTAssertEqual(restored.game.balance, StarfallBalance())
        XCTAssertEqual(restored.game.cadenceID, .announcedCycleV2)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, initial); XCTAssertTrue(store.isPaused)
        store.restart(sameSky: false)
        XCTAssertNil(store.game.challenge); XCTAssertEqual(store.game.outcome, .playing)
    }

    @MainActor func testLeavingOverflowedChallengeRestoresNormalCadenceAndBalance() {
        let (store, presenter, _, _) = makeStore()
        store.startFirstLight()
        for _ in 0..<50 where !store.game.isOver { store.callShower(); presenter.finish() }
        XCTAssertEqual(store.game.outcome, .lost)
        store.restart(sameSky: false)
        XCTAssertNil(store.game.challenge)
        XCTAssertEqual(store.game.balance, StarfallBalance())
        XCTAssertEqual(store.game.cadenceID, .announcedCycleV2)
        XCTAssertEqual(store.nextShowerCadence, .init(delay: 0.25, phase: .opening))
        XCTAssertTrue(store.isPaused)
    }

    @MainActor func testStartingChallengeRejectsOldRainAndAnimationCallbacks() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause()
        let timer = clock.action
        clock.advance(4)
        let completion = presenter.completions.last
        store.startFirstLight()
        let challenge = store.game
        timer?(); completion?(); clock.advance(100)
        XCTAssertEqual(store.game, challenge)
        XCTAssertFalse(store.busy); XCTAssertTrue(store.isPaused)
        XCTAssertNil(clock.deadline)
        store.setPace(.brisk)
        XCTAssertEqual(store.game.balance, StarfallChallenge.firstLight.balance)
    }

    @MainActor func testManualShowersAndClearsWorkPausedWithoutStartingClock() throws {
        let (store, presenter, clock, _) = makeStore()
        XCTAssertTrue(store.isPaused)
        store.callShower()
        XCTAssertEqual(store.game.turns, 1); XCTAssertNil(clock.deadline)
        store.callShower(); XCTAssertEqual(store.game.turns, 1, "Busy input is ignored")
        presenter.finish()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
        XCTAssertEqual(store.game.score, 3); XCTAssertNil(clock.deadline)
        presenter.finish(); clock.advance(100)
        XCTAssertEqual(store.game.turns, 1)
        store.setSuspended(true); store.callShower()
        XCTAssertEqual(store.game.turns, 1)
    }

    @MainActor func testFeedbackOnlyFiresForCommittedClearAndStopsOnMuteAndSuspend() throws {
        let defaults = UserDefaults(suiteName: "SkyFeedback.\(UUID())")!
        let feedback = SkyFeedbackRecorder(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"],
            presenter: presenter, clock: clock, feedback: feedback)
        store.setSuspended(false)
        XCTAssertTrue(store.soundEnabled); XCTAssertTrue(store.hapticsEnabled)
        store.clear(Cell(0, 0)); XCTAssertEqual(feedback.clears, 0)
        store.soundEnabled = true; store.hapticsEnabled = true
        store.callShower(); presenter.finish()
        let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
        store.clear(cell); store.clear(cell)
        XCTAssertEqual(feedback.clears, 1)
        XCTAssertTrue(feedback.sound); XCTAssertTrue(feedback.haptics)
        store.soundEnabled = false
        XCTAssertEqual(feedback.stops, 1)
        store.setSuspended(true); XCTAssertEqual(feedback.stops, 2)
    }

    @MainActor func testSpeechPreservesExplicitFeedbackWithoutAutomaticShowerInterruptions() throws {
        let suite = "SkySpeech.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = SkyFeedbackRecorder(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=5"],
            presenter: presenter, clock: clock, feedback: feedback)
        store.setSuspended(false)
        store.clear(Cell(0, 0))
        XCTAssertEqual(feedback.announcements, [store.guideLine.spokenText], "Invalid explicit input explains the rule")
        feedback.announcements.removeAll()
        store.callShower(); presenter.finish()
        XCTAssertEqual(feedback.announcements, [store.guideLine.spokenText], "Manual showers speak their committed result")
        feedback.announcements.removeAll()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first)); presenter.finish()
        XCTAssertEqual(feedback.announcements, [store.guideLine.spokenText], "Explicit clears retain spoken feedback")
        feedback.announcements.removeAll()
        store.togglePause()
        clock.advance(4); presenter.finish()
        XCTAssertEqual(store.game.turns, 2)
        XCTAssertTrue(feedback.announcements.isEmpty, "Automatic rain leaves exploration speech alone")
        for _ in 0..<40 where !store.game.isOver { clock.advance(4); presenter.finish() }
        XCTAssertTrue(store.game.isOver)
        XCTAssertEqual(feedback.announcements, [
            "Nova. 1 lighter shower before storm",
            "Nova. Storm · 3 heavy showers left. Faster after next shower",
            "Nova. Lighter showers · 9 showers. Faster passage. Showers are closer together",
            "Nova. Lighter showers · 8 showers. Breathing window. More time between showers",
            "Nova. 1 lighter shower before storm",
            store.guideLine.spokenText
        ], "Only announced pressure transitions and the terminal result interrupt automatic play")
        store.restart(sameSky: true)
        feedback.announcements.removeAll()
        store.callShower(); store.setSuspended(true); presenter.finish()
        XCTAssertTrue(feedback.announcements.isEmpty, "Suspension rejects stale result speech")
    }

    @MainActor func testCeremonyOwnsTerminalSpeechWithoutSuppressingExplicitPlayFeedback() {
        let suite = "SkyCeremonySpeech.\(UUID())", presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"],
                                    presenter: presenter, clock: clock, feedback: feedback)
        store.terminalSpeech = .ceremony
        store.setSuspended(false)
        store.callShower(); presenter.finish()
        XCTAssertEqual(feedback.announcements, [store.guideLine.spokenText])
        feedback.announcements.removeAll()
        store.togglePause()
        for _ in 0..<40 where !store.game.isOver {
            // Cadence/storm transitions during play remain legitimate feedback.
            // Isolate the terminal turn to check its single presentation owner.
            feedback.announcements.removeAll()
            clock.advance(4); presenter.finish()
            if store.game.isOver {
                XCTAssertTrue(feedback.announcements.isEmpty, "The focused result heading owns terminal speech once")
            }
        }
        XCTAssertTrue(store.game.isOver); XCTAssertFalse(store.busy)
        XCTAssertNotNil(SkyResultSnapshot(game: store.game))
    }

    @MainActor func testFeedbackDefaultsDoNotOverwriteExplicitMuteOrWriteDuringInitialization() {
        let suite = "SkyFeedbackDefaults.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let fresh = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"])
        XCTAssertTrue(fresh.soundEnabled); XCTAssertTrue(fresh.hapticsEnabled)
        XCTAssertNil(defaults.object(forKey: "soundEnabled"))
        XCTAssertNil(defaults.object(forKey: "starfall.haptics"))
        fresh.soundEnabled = false; fresh.hapticsEnabled = false
        let restored = FallingSkyStore(defaults: defaults, arguments: [])
        XCTAssertFalse(restored.soundEnabled); XCTAssertFalse(restored.hapticsEnabled)
    }

}

@MainActor private final class SkyFeedbackRecorder: FallingSkyFeedbackProviding {
    var clears = 0, stops = 0
    var announcements: [String] = []
    var sound = false, haptics = false
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        clears += 1; sound = soundEnabled; haptics = hapticsEnabled
    }
    func announce(_ message: String) { announcements.append(message) }
    func stopSounds() { stops += 1 }
}


extension FallingSkyStoreTests {
    private var chosenTrace: [Cell] { [Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)] }

    @MainActor func testTraceCoreClearsOnlyChosenStarsAndPreservesPreviewReplay() throws {
        var game = ConstellationFixture.overlap.game()
        let initial = game, selected = Set(chosenTrace)
        let untraced = Set(initial.board.compactMap { $0 }.map(\.id)).subtracting(selected.compactMap { initial.gem(at: $0)?.id })
        let before = try JSONSerialization.jsonObject(with: JSONEncoder().encode(initial)) as! NSDictionary
        let turn = try XCTUnwrap(game.clearConstellation(chosenTrace))
        XCTAssertEqual(turn.collected, 5); XCTAssertEqual(turn.cleared, selected)
        XCTAssertEqual(Set(game.board.compactMap { $0 }.map(\.id)), untraced)
        XCTAssertEqual(game.incoming, initial.incoming); XCTAssertEqual(game.turns, initial.turns)
        XCTAssertTrue(game.isValidSave)
        let after = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! NSDictionary
        for key in ["random","remainingColumns"] { XCTAssertTrue((before[key] as? NSObject)?.isEqual(after[key]) == true) }
        var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        var control = game
        restored.letStarsFall(); control.letStarsFall(); XCTAssertEqual(restored, control)
    }

    @MainActor func testTraceCoreRejectsCountFamilyJumpsAndUnboundedWalksWithoutMutation() {
        let fixture = ConstellationFixture.overlap.game()
        let paths = [Array(chosenTrace.prefix(4)), [Cell(0,4),Cell(0,5),Cell(0,6),Cell(1,3),Cell(2,4)],
                     [Cell(0,4),Cell(1,4),Cell(2,4),Cell(1,5),Cell(1,6)],
                     [Cell(-1,4)]+chosenTrace, Array(repeating: Cell(0,4), count: 197)+chosenTrace]
        for path in paths {
            var game = fixture; XCTAssertNil(game.clearConstellation(path)); XCTAssertEqual(game, fixture)
        }
        var four = ConstellationFixture.fourGrown.game()
        let initial = four
        XCTAssertNil(four.clearConstellation((0..<4).map { Cell($0,$0) })); XCTAssertEqual(four, initial)
        var repeated = fixture
        let walk = [Cell(0,4),Cell(1,3),Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)]
        XCTAssertEqual(repeated.clearConstellation(walk)?.collected, 5)
    }

    @MainActor func testTraceDarknessAndOrdinaryTapRemainSeparate() {
        var game = ConstellationFixture.darkness.game()
        let before = game
        XCTAssertNil(game.clear(Cell(1,3))); XCTAssertEqual(game,before)
        XCTAssertEqual(game.clearConstellation(chosenTrace)?.collected,5)
        XCTAssertEqual(game.darkStarsCleared,1)
        XCTAssertTrue(game.gem(at: Cell(0,2))?.isDark == true)
        XCTAssertTrue(game.isValidSave)
        var opening = FallingSky(seed:5)
        opening.letStarsFall()
        XCTAssertEqual(opening.clear(opening.legalGroups[0][0])?.collected,3)
    }

    @MainActor func testTraceIntentTicketsRevisitsAndInterruptionBoundaries() throws {
        for interruption in ["settings","pause","restart","fixture","motion","shower"] {
            let (store, presenter, _, _) = makeStore()
            store.loadConstellationFixture(.overlap)
            let intent = ConstellationTraceIntent(), source = store.game
            let ticket = try XCTUnwrap(intent.begin(chosenTrace[0], game: source, generation:store.constellationInputGeneration, enabled:store.canClear))
            for cell in chosenTrace.dropFirst() {
                XCTAssertTrue(intent.visit(cell,ticket:ticket,game:store.game,generation:store.constellationInputGeneration,enabled:store.canClear))
            }
            XCTAssertEqual(intent.count,5); XCTAssertEqual(intent.value,5)
            switch interruption {
            case "settings": store.setSuspended(true)
            case "pause": store.togglePause()
            case "restart": store.restart(sameSky:true)
            case "fixture": store.loadConstellationFixture(.overlap)
            case "motion": store.setReducedMotion(true)
            default: store.callShower()
            }
            let committed = store.game
            let outcome = intent.finish(ticket:ticket,game:store.game,generation:store.constellationInputGeneration,enabled:store.canClear)
            XCTAssertNil(outcome,interruption)
            store.clearTracedConstellation(chosenTrace,snapshot:source,generation:0)
            XCTAssertEqual(store.game,committed,interruption)
            presenter.finish()
        }
        let intent = ConstellationTraceIntent(), game = ConstellationFixture.five.game()
        let old = intent.begin(chosenTrace[0],game:game,generation:1,enabled:true)
        intent.cancel()
        let current = intent.begin(chosenTrace[0],game:game,generation:1,enabled:true)
        XCTAssertFalse(intent.visit(chosenTrace[1],ticket:old,game:game,generation:1,enabled:true))
        XCTAssertEqual(intent.count,1)
        XCTAssertTrue(intent.visit(chosenTrace[1],ticket:current,game:game,generation:1,enabled:true))
    }

    @MainActor func testTraceStoreCommitsOnceBeforeEffectsAndRestoresOnlyCommittedState() throws {
        let (store,presenter,_,defaults) = makeStore()
        store.loadConstellationFixture(.overlap)
        let source = store.game, ticket = store.constellationInputGeneration
        store.clear(Cell(1,3)); XCTAssertEqual(store.game,source)
        store.clearTracedConstellation(chosenTrace,snapshot:source,generation:ticket)
        XCTAssertEqual(store.game.score,5); XCTAssertTrue(store.busy)
        let committed = store.game
        store.clearTracedConstellation(chosenTrace,snapshot:source,generation:ticket)
        XCTAssertEqual(store.game,committed)
        let restored = FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(restored.game,committed); XCTAssertTrue(restored.isPaused)
        presenter.finish(); XCTAssertFalse(store.busy)
    }

    @MainActor func testTraceVisualsHaveNoRestingSolutionAndStayBounded() {
        let scene = FallingSkyScene()
        scene.render(ConstellationFixture.overlap.game())
        var links = 0
        scene.enumerateChildNodes(withName:"//constellation.trace.thread") { _,_ in links += 1 }
        scene.enumerateChildNodes(withName:"//lab.constellation.link") { _,_ in links += 1 }
        XCTAssertEqual(links,0)
        for _ in 0..<10 { scene.showConstellationTrace(chosenTrace,ready:true) }
        var sparks=0
        scene.enumerateChildNodes(withName:"//constellation.trace.spark") { _,_ in sparks += 1 }
        XCTAssertEqual(sparks,5)
        scene.clearConstellationTrace()
        links=0
        scene.enumerateChildNodes(withName:"//constellation.trace.thread") { _,_ in links += 1 }
        XCTAssertEqual(links,0)
    }
}

extension FallingSkyStoreTests {
    @MainActor func testProductionCyclePublishesNextIntervalBeforeSchedule() throws {
        let suite = "Pacing.Cycle.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let clock = ManualRainClock(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=5"], presenter: presenter, clock: clock)
        var events: [FallingSkyStore.TimingEvent] = []
        store.configureTimingTest(observe: { events.append($0) })
        store.setSuspended(false)
        let initial = store.game
        // Manual showers consume identical slots, even with no running clock.
        for count in 0..<16 {
            XCTAssertEqual(store.nextShowerCadence, SkyCadenceID.announcedCycleV2.step(committedShowers: count, pace: .brisk))
            XCTAssertFalse(store.game.isOver)
            store.callShower(); presenter.finish()
            while let cell = store.game.legalGroups.first?.first { store.clear(cell); presenter.finish() }
        }
        XCTAssertEqual(events.filter { $0.kind == .manualShower }.count, 16)
        XCTAssertNil(clock.deadline)
        store.togglePause()
        let scheduled = try XCTUnwrap(events.last { $0.kind == .scheduled })
        XCTAssertEqual(scheduled.snapshot.cadence, SkyCadenceID.announcedCycleV2.step(committedShowers: 16, pace: .brisk))
        XCTAssertEqual(try XCTUnwrap(scheduled.snapshot.scheduledDeadline) - scheduled.snapshot.time, 2)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.turns, 0); XCTAssertEqual(store.nextShowerCadence.phase, .opening)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game, initial.replay())
    }

    @MainActor func testTimingObservationSeparatesLateDeadlineDeferralAndDelivery() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        // Baseline observation only; no alternative scheduling implementation.
        store.setSuspended(true)
        var events: [FallingSkyStore.TimingEvent] = []
        store.configureTimingTest(observe: { events.append($0) })
        store.setSuspended(false); store.togglePause()
        clock.advance(0.25)
        let firstDeadline = try XCTUnwrap(clock.deadline)
        clock.advance(10)
        let deferred = try XCTUnwrap(events.last { $0.kind == .deferred })
        XCTAssertTrue(deferred.snapshot.rainDue); XCTAssertTrue(deferred.snapshot.busy)
        XCTAssertFalse(deferred.snapshot.canClear)
        XCTAssertEqual(deferred.snapshot.scheduledDeadline, firstDeadline)
        XCTAssertEqual(store.game.turns, 1)
        clock.advance(20); presenter.finish()
        let delivered = try XCTUnwrap(events.last { $0.kind == .automaticShower })
        XCTAssertEqual(delivered.snapshot.time, clock.now)
        XCTAssertEqual(delivered.showerDeadline, firstDeadline)
        XCTAssertEqual(delivered.snapshot.game.turns, 2)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 1.8, accuracy: 0.001)
        presenter.finish()
        XCTAssertTrue(store.timingSnapshot.canClear)
        XCTAssertEqual(events.filter { $0.kind == .automaticShower }.count, 2)
    }

    @MainActor func testTimingCandidateCannotOverrideHistoricalOrChallengeAndReplayUsesCoreContract() throws {
        let (store, presenter, clock, _) = makeStore()
        store.setSuspended(true)
        store.configureTimingTest(lookup: { _ in .init(delay: 99, phase: .faster) })
        XCTAssertEqual(store.showerInterval, 4)
        let initial = store.game
        store.setSuspended(false); store.callShower(); presenter.finish()
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, initial.replay()); XCTAssertEqual(store.showerInterval, 4)
        store.startFirstLight()
        XCTAssertEqual(store.showerInterval, 4); XCTAssertEqual(store.nextShowerCadence.phase, .steady)
        store.togglePause(); clock.advance(4)
        XCTAssertEqual(store.game.turns, 1)
    }

    @MainActor func testTimingTraceDeadlineClassificationAndInterruptionSnapshots() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.setSuspended(true)
        var events: [FallingSkyStore.TimingEvent] = []
        store.configureTimingTest(observe: { events.append($0) })
        store.setSuspended(false); store.togglePause(); clock.advance(0.25); presenter.finish()
        let inputGeneration = store.constellationInputGeneration
        let hold = try XCTUnwrap(store.beginConstellationHold())
        XCTAssertTrue(store.timingSnapshot.canClear); XCTAssertFalse(store.timingSnapshot.canTap)
        XCTAssertFalse(store.timingSnapshot.canCallShower)
        store.callShower()
        XCTAssertEqual(store.game.turns, 1, "A manual shower cannot interrupt an owned trace either")
        clock.advance(1.8)
        XCTAssertEqual(store.constellationInputGeneration, inputGeneration)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(store.game.turns, 1, "A live trace owns the deadline hold")
        store.endConstellationHold(hold)
        clock.advance(1.8)
        XCTAssertNotEqual(store.constellationInputGeneration, inputGeneration)
        XCTAssertNotNil(events.last { $0.kind == .invalidated("automaticShower") })
        XCTAssertEqual(store.game.turns, 2)
        store.setSuspended(true)
        XCTAssertFalse(store.timingSnapshot.canClear); XCTAssertNil(store.timingSnapshot.scheduledDeadline)
        XCTAssertNotNil(events.last { $0.kind == .invalidated("suspension") })
        let stale = presenter.completions.last
        store.restart(sameSky: true); stale?()
        XCTAssertEqual(store.game.turns, 0); XCTAssertFalse(store.busy)
        XCTAssertNotNil(events.last { $0.kind == .invalidated("restart") })
    }
}


extension FallingSkyStoreTests {
    @MainActor func testCandidateAutomaticBoundariesSurviveSettingsPauseAndMotion() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.setSuspended(true)
        store.setSuspended(false); store.togglePause()
        for count in 0..<16 {
            let cadence = store.nextShowerCadence
            XCTAssertEqual(cadence, SkyCadenceID.announcedCycleV2.step(committedShowers: count, pace: .brisk))
            if count == 9 {
                XCTAssertTrue(cadence.warnsFasterNext)
                clock.advance(1)
                store.setSuspended(true); clock.advance(100); store.setSuspended(false)
                XCTAssertEqual(store.nextShowerCadence, cadence)
                XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 1, accuracy: 0.001)
                store.togglePause(); clock.advance(100); store.togglePause()
                XCTAssertEqual(store.nextShowerCadence, cadence)
                XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 1, accuracy: 0.001)
            }
            clock.advance(try XCTUnwrap(clock.deadline) - clock.now)
            XCTAssertEqual(store.game.turns, count + 1)
            let nextDeadline = clock.deadline
            store.setReducedMotion(count.isMultiple(of: 2))
            presenter.finish()
            XCTAssertEqual(clock.deadline, nextDeadline)
            while let cell = store.game.legalGroups.first?.first { store.clear(cell); presenter.finish() }
        }
        XCTAssertEqual(store.nextShowerCadence, .init(delay: 2, phase: .steady))
    }
}

final class SkySaveArchiveTests: XCTestCase {
    @MainActor private func makeDefaults() -> UserDefaults {
        let suite = "Starfall.SaveArchive.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    private func opalSky() -> FallingSky {
        var game = FallingSky(seed: 17, balance: .init(darkStars: .none), generation: .current)
        for _ in 0..<5 {
            XCTAssertNotNil(game.letStarsFall())
            for _ in 0..<49 {
                guard !game.isOver, let first = game.legalGroups.first?.first else { break }
                XCTAssertNotNil(game.clear(first))
            }
            XCTAssertTrue(game.isValidSave)
        }
        XCTAssertTrue(game.incoming.contains(where: \.isLight))
        return game
    }

    @MainActor func testLegacyMigrationWaitsForActivationAndPreservesExactSkyAndOldBytes() throws {
        let defaults = makeDefaults()
        let original = FallingSky(seed: 17, openingCascade: false)
        let legacy = try JSONEncoder().encode(original)
        defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        XCTAssertTrue(store.hasSavedSky); XCTAssertEqual(store.game, original.adoptingFeedingDusk())
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        clock.advance(100)
        XCTAssertEqual(store.game, original.adoptingFeedingDusk()); XCTAssertNil(clock.deadline)
        store.setSuspended(false)
        let current = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(current), original.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, original.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        restored.setSuspended(false)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current, "Canonical migration is idempotent")
        var reference = original.adoptingFeedingDusk()
        for _ in 0..<8 where !reference.isOver {
            reference.letStarsFall(); store.callShower(); presenter.finish()
            XCTAssertEqual(store.game, reference)
        }
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
    }

    func testCurrentEnvelopePreservesWhiteIdentityAndRejectsWrongSchemasAndInvalidCore() throws {
        let game = opalSky()
        let data = try SkySaveArchive.encode(game)
        XCTAssertEqual(try SkySaveArchive.decode(data), game)
        XCTAssertEqual(try SkySaveArchive.encode(game), data)
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONEncoder().encode(FallingSky(seed: 17))))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        fields["schemaVersion"] = 99
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONSerialization.data(withJSONObject: fields)))
        fields["schemaVersion"] = SkySaveArchive.schemaVersion
        var core = try XCTUnwrap(fields["game"] as? [String: Any])
        core["savedGeneration"] = 99; fields["game"] = core
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONSerialization.data(withJSONObject: fields)))
    }

    @MainActor func testRawModernSkyCannotMasqueradeAsLegacySave() throws {
        for game in [FallingSky(seed: 17, generation: .current), opalSky()] {
            let defaults = makeDefaults(), bytes = try JSONEncoder().encode(game)
            defaults.set(bytes, forKey: SkySaveArchive.legacyKey)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            let store = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertFalse(store.hasSavedSky)
            XCTAssertEqual(store.game.seed, 5)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
    }

    @MainActor func testPresentInvalidCurrentSaveNeverResurrectsLegacyRound() throws {
        let defaults = makeDefaults()
        let old = try JSONEncoder().encode(FallingSky(seed: 17))
        defaults.set(old, forKey: SkySaveArchive.legacyKey)
        let current = Data("broken".utf8)
        defaults.set(current, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertFalse(store.hasSavedSky); XCTAssertEqual(store.game.seed, 5)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), old)
        defaults.set(true, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults), "Wrong-type current presence also blocks downgrade")
    }

    @MainActor func testCurrentEnvelopeTakesPrecedenceAndInitializationDoesNotWrite() throws {
        let defaults = makeDefaults(), game = opalSky()
        let current = try SkySaveArchive.encode(game)
        let legacy = try JSONEncoder().encode(FallingSky(seed: 123))
        defaults.set(current, forKey: SkySaveArchive.key)
        defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertTrue(store.hasSavedSky); XCTAssertEqual(store.game, game.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.generation, .current)
        XCTAssertEqual(store.game.seed, game.seed)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
    }

}

final class SkyPhasePresentationTests: XCTestCase {
    private func sky(after showers: Int) -> FallingSky {
        var game = FallingSky(seed: 17, generation: .current)
        for _ in 0..<showers {
            XCTAssertNotNil(game.letStarsFall())
            for _ in 0..<49 {
                guard let cell = game.legalGroups.first?.first else { break }
                XCTAssertNotNil(game.clear(cell))
            }
        }
        XCTAssertTrue(game.isValidSave); XCTAssertFalse(game.isOver)
        return game
    }
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.Phases.\(UUID().uuidString)"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }
    func testWarningStormRecoveryAndLaterCycleFollowCommittedForecast() throws {
        for (turns, expected, announces) in [
            (0, "Lighter showers · 9 showers", false),
            (8, "1 lighter shower before storm", true),
            (9, "Storm · 3 heavy showers left", true),
            (10, "Storm · 2 heavy showers left", false),
            (11, "Storm · 1 heavy shower left", false),
            (12, "Lighter showers · 9 showers", true),
            (20, "1 lighter shower before storm", true),
            (21, "Storm · 3 heavy showers left", true)
        ] {
            var game = sky(after: turns)
            let cue = try XCTUnwrap(SkyPhaseCue(game: game))
            XCTAssertEqual(cue.text, expected); XCTAssertEqual(cue.announcesTransition, announces)
            let turn = try XCTUnwrap(game.letStarsFall())
            XCTAssertEqual(SkyPhaseCue(game: game, pending: turn), cue, "Arrival still displays its committed forecast")
            XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
            XCTAssertEqual(SkyPhaseCue(game: game)?.shower, turns + 2)
        }
        XCTAssertNil(SkyPhaseCue(game: FallingSky(seed: 17)))
        XCTAssertNil(SkyPhaseCue(game: FallingSky(challenge: .firstLight)))
    }
    @MainActor func testFreshSkyOptsInButOldRestoreAndReplayKeepOriginalRules() throws {
        let saved = defaults(), old = FallingSky(seed: 17)
        saved.set(try JSONEncoder().encode(old), forKey: SkySaveArchive.legacyKey)
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.game, old.adoptingFeedingDusk()); XCTAssertNil(store.phaseCue)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.generation, .legacy); XCTAssertNil(store.phaseCue)
        store.restart(sameSky: false)
        XCTAssertEqual(store.game.generation, .current); XCTAssertNotNil(store.phaseCue)
        store.startFirstLight()
        XCTAssertEqual(store.game.generation, .legacy); XCTAssertNil(store.phaseCue)
        let fresh = FallingSkyStore(defaults: defaults(), arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(fresh.game.generation, .current); XCTAssertNotNil(fresh.phaseCue)
    }
    @MainActor func testAutomaticTransitionSpeaksAtSettlementAndInterruptionRejectsStaleSpeech() throws {
        let saved = defaults(), original = sky(after: 8)
        saved.set(try SkySaveArchive.encode(original), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: clock, feedback: feedback)
        store.setSuspended(false); store.togglePause()
        clock.advance(store.showerInterval)
        XCTAssertEqual(store.game.turns, 9)
        XCTAssertEqual(store.phaseCue?.shower, 9); XCTAssertTrue(feedback.announcements.isEmpty)
        presenter.finish()
        XCTAssertEqual(store.phaseCue?.shower, 10)
        XCTAssertEqual(feedback.announcements, ["Nova. Storm · 3 heavy showers left. Faster after next shower"])
        clock.advance(store.showerInterval); presenter.finish()
        XCTAssertEqual(store.game.turns, 10); XCTAssertEqual(feedback.announcements.count, 1)
        store.setSuspended(true)
        let committed = store.game
        clock.advance(100); presenter.finish()
        XCTAssertEqual(store.game, committed); XCTAssertEqual(feedback.announcements.count, 1)
        let restored = FallingSkyStore(defaults: saved, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, committed); XCTAssertEqual(restored.phaseCue, store.phaseCue)
        XCTAssertTrue(restored.isPaused)
    }
    @MainActor func testLiveTraceUsesCoreFamilyThroughOpalAndRejectsAnotherColor() throws {
        let game = ConstellationFixture.opalTrace.game(), intent = ConstellationTraceIntent()
        let path = (0..<5).map { Cell($0, 2) }
        let ticket = try XCTUnwrap(intent.begin(path[0], game: game, generation: 1, enabled: true))
        for cell in path.dropFirst() {
            XCTAssertTrue(intent.visit(cell, ticket: ticket, game: game, generation: 1, enabled: true))
        }
        XCTAssertEqual(intent.count, 5); XCTAssertEqual(intent.value, 8)
        XCTAssertNotNil(intent.finish(ticket: ticket, game: game, generation: 1, enabled: true))
        let shared = ConstellationFixture.opalChoice.game()
        let rose = [Cell(3,1), Cell(3,2), Cell(2,3), Cell(2,4), Cell(2,5)]
        let branch = try XCTUnwrap(intent.begin(rose[0], game: shared, generation: 2, enabled: true))
        for cell in rose.dropFirst() { XCTAssertTrue(intent.visit(cell, ticket: branch, game: shared, generation: 2, enabled: true)) }
        XCTAssertFalse(intent.visit(Cell(3,5), ticket: branch, game: shared, generation: 2, enabled: true))
        XCTAssertEqual(intent.snapshot, shared, "A spatial miss must not replace the rose family")
        XCTAssertEqual(intent.count, 5)
        let preserved = try XCTUnwrap(intent.finish(ticket: branch, game: shared, generation: 2, enabled: true))
        XCTAssertFalse(preserved.path.contains(Cell(3,5)))
        XCTAssertNil(intent.begin(Cell(2,5), game: shared, generation: 2, enabled: true))
    }
    @MainActor func testCanceledManualWarningDoesNotSpeakAnObsoletePhase() throws {
        let saved = defaults()
        saved.set(try SkySaveArchive.encode(sky(after: 8)), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: ManualRainClock(), feedback: feedback)
        store.setSuspended(false); store.callShower()
        XCTAssertEqual(store.phaseCue?.shower, 9)
        store.setSuspended(true); presenter.finish()
        XCTAssertEqual(store.phaseCue?.shower, 10); XCTAssertTrue(feedback.announcements.isEmpty)
    }
}

extension SkySaveArchiveTests {
    @MainActor func testV4MigrationPreservesGenerationForecastReplayAndBytes() throws {
        for generation in [SkyGeneration.legacy, .opalStorms] {
            let defaults = makeDefaults()
            var game = FallingSky(seed:19,generation:generation)
            for _ in 0..<5 { game.letStarsFall(); for group in game.legalGroups { if let cell = group.first { game.clear(cell) } } }
            let gameJSON = try JSONSerialization.jsonObject(with:JSONEncoder().encode(game))
            let bytes = try JSONSerialization.data(withJSONObject:["schemaVersion":4,"game":gameJSON])
            defaults.set(bytes,forKey:SkySaveArchive.previousKey)
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:ManualRainClock())
            XCTAssertEqual(store.game,game.adoptingFeedingDusk()); XCTAssertTrue(store.isPaused)
            XCTAssertNil(defaults.object(forKey:SkySaveArchive.key))
            store.setSuspended(false)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))),game.adoptingFeedingDusk())
            XCTAssertEqual(defaults.data(forKey:SkySaveArchive.previousKey),bytes)
            game = game.adoptingFeedingDusk(); game.letStarsFall(); store.callShower(); presenter.finish(); XCTAssertEqual(store.game,game)
            store.restart(sameSky:true); XCTAssertEqual(store.game.generation,generation)
            defaults.set(Data("broken".utf8),forKey:SkySaveArchive.key)
            XCTAssertNil(SkySaveArchive.load(from:defaults))
        }
    }
    @MainActor func testMalformedV4DoesNotFallbackAndV4CannotAdmitGravity() throws {
        let defaults = makeDefaults()
        defaults.set(try JSONEncoder().encode(FallingSky(seed:1)),forKey:SkySaveArchive.legacyKey)
        for game in [GravityFixture.opportunity.game()] {
            let json = try JSONSerialization.jsonObject(with:JSONEncoder().encode(game))
            defaults.set(try JSONSerialization.data(withJSONObject:["schemaVersion":4,"game":json]),forKey:SkySaveArchive.previousKey)
            XCTAssertNil(SkySaveArchive.load(from:defaults))
        }
        defaults.set(true,forKey:SkySaveArchive.previousKey)
        XCTAssertNil(SkySaveArchive.load(from:defaults))
    }
}


extension FallingSkyStoreTests {
    @MainActor func testOpalPlanningSurvivesOneDueFasterShowerBetweenClears() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.loadConstellationFixture(.opalPlanning)
        let initial = store.game
        store.togglePause()
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 1.7, accuracy: 0.001)
        store.clear(Cell(1,1))
        XCTAssertEqual(store.game.score, 29)
        XCTAssertTrue(store.busy)
        clock.advance(1.7)
        XCTAssertEqual(store.game.turns, 12, "A due shower cannot replace the committed clear presentation")
        XCTAssertFalse(store.canClear)
        clock.advance(30)
        XCTAssertEqual(store.game.turns, 12)
        presenter.finish()
        XCTAssertEqual(store.game.turns, 13, "Settlement delivers exactly one due shower, without catch-up")
        presenter.finish()
        XCTAssertTrue(store.canClear)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 2.5, accuracy: 0.001)
        store.clear(Cell(0,3)); presenter.finish()
        XCTAssertEqual(store.game.score, 33)
        var expected = initial
        XCTAssertEqual(expected.clear(Cell(1,1))?.collected, 2)
        XCTAssertNotNil(expected.letStarsFall())
        XCTAssertEqual(expected.clear(Cell(0,3))?.collected, 4)
        XCTAssertEqual(store.game, expected)
        XCTAssertTrue(store.game.isValidSave)
    }
}

extension FallingSkyStoreTests {
    @MainActor func testDialogueDoesNotMutateRoundSaveOrDeadlineAndRestartDiscardsIt() throws {
        let suite = "Starfall.Dialogue.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let clock = ManualRainClock(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"], presenter: presenter, clock: clock)
        store.setSuspended(false); store.togglePause()
        let game = store.game, deadline = clock.deadline, save = defaults.data(forKey: FallingSkyStore.saveKey)
        XCTAssertTrue(store.say(SkyDialogueLibrary.script("studio.cast")))
        store.nextDialogue()
        XCTAssertEqual(store.dialogue.line?.speaker, .spark)
        XCTAssertEqual(store.game, game); XCTAssertEqual(clock.deadline, deadline)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), save)
        let revision = store.dialogue.revision
        store.setSuspended(true); clock.advance(100)
        let retainedLine = store.dialogue.line
        store.nextDialogue()
        XCTAssertEqual(store.dialogue.line, retainedLine, "Suspended screens reject stale Continue actions")
        XCTAssertEqual(store.game, game)
        store.restart(sameSky: true)
        store.dialogue.expire(revision: revision)
        XCTAssertNil(store.dialogue.line)
        XCTAssertFalse(store.say(SkyDialogueLibrary.script("studio.cast")), "Suspended screens reject scenario events")
    }

}

extension FallingSkyStoreTests {
    @MainActor func testPressureAndExplicitHelpShareOneVisibleSpokenMessageWithoutChangingTheSky() throws {
        let suite = "Starfall.DialoguePressure.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults,
            arguments: ["--starfalls-reset", "--constellation-fixture=stormWarning"],
            presenter: presenter, clock: clock, feedback: feedback)
        store.setSuspended(false)
        XCTAssertTrue(store.pausedGuideLine.text.contains("1 lighter shower"))
        let committed = store.game, bytes = defaults.data(forKey: FallingSkyStore.saveKey)
        let empty = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }.first { store.game.gem(at: $0) == nil })
        store.clear(empty)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), bytes)
        XCTAssertTrue(store.pausedGuideLine.text.contains("Match three light"))
        XCTAssertTrue(store.pausedGuideLine.text.contains("1 lighter shower"))
        XCTAssertEqual(feedback.announcements, [store.pausedGuideLine.spokenText])
        XCTAssertEqual(store.dialogue.line, store.pausedGuideLine)
        store.callShower(); presenter.finish()
        XCTAssertTrue(store.pausedGuideLine.text.contains("Storm · 3 heavy showers left"))
        XCTAssertTrue(store.pausedGuideLine.text.contains("Faster after next shower"))
        XCTAssertEqual(store.pausedGuideLine.speaker, .nova)
        XCTAssertEqual(store.game.turns, committed.turns + 1)
    }
}


extension FallingSkyStoreTests {
    @MainActor func testCurrentOpalOrbitChoiceAndTraceSurviveOneDueRecoveryShower() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.loadConstellationFixture(.opalStormPlanning)
        let initial = store.game
        store.togglePause()
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 1.7, accuracy: 0.001)
        store.clear(Cell(0,4))
        XCTAssertEqual(store.game.score, 33)
        XCTAssertNil(store.game.orbit)
        clock.advance(1.7)
        clock.advance(30)
        XCTAssertEqual(store.game.turns, 12)
        XCTAssertFalse(store.canClear)
        presenter.finish()
        XCTAssertEqual(store.game.turns, 13)
        presenter.finish()
        XCTAssertTrue(store.canClear)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 2.5, accuracy: 0.001)
        let path = [Cell(0,4),Cell(0,5),Cell(0,6),Cell(1,6),Cell(2,5)]
        store.clearTracedConstellation(path, snapshot: store.game, generation: store.constellationInputGeneration)
        presenter.finish()
        var expected = initial
        XCTAssertEqual(expected.clear(Cell(0,4))?.collected, 3)
        XCTAssertNotNil(expected.letStarsFall())
        XCTAssertEqual(expected.clearConstellation(path)?.collected, 2)
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(store.game.score, 35)
        XCTAssertEqual(store.game.board.compactMap { $0 }.filter(\.isLight).count, 1)
        XCTAssertTrue(store.game.isValidSave)
    }
}
