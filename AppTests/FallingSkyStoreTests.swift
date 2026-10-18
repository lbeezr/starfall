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

    @MainActor func testLargeReceiptUsesGrownValueAndExcludesDissolvedDarkness() throws {
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky(seed: 5))) as! [String: Any]
        var board: [Any] = Array(repeating: NSNull(), count: 49)
        for column in 0..<4 { board[column] = ["id": column, "grown": true, "kind": Jewel.aqua.rawValue] }
        board[4] = ["id": 4, "grown": false]
        object["board"] = board; object["starsLanded"] = 9; object["turns"] = 2
        var game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(game.isValidSave)
        let old = game
        let turn = try XCTUnwrap(game.clear(Cell(0, 0)))
        let receipt = try XCTUnwrap(StarlightCelebration(id: 1, turn: turn, from: old, total: game.score))
        XCTAssertEqual(receipt.level, .brilliant)
        XCTAssertEqual(receipt.collected, 8); XCTAssertEqual(receipt.total, 8)
        XCTAssertEqual(receipt.cells, (0..<4).map { Cell(0, $0) })
        XCTAssertEqual(turn.cleared.count, 5); XCTAssertEqual(game.darkStarsCleared, 1)
        XCTAssertEqual(game.incoming, old.incoming); XCTAssertTrue(game.isValidSave)
        let next = try XCTUnwrap(game.letStarsFall())
        XCTAssertNil(StarlightCelebration(id: 2, turn: next, from: game, total: game.score))
    }

    @MainActor func testCelebrationIsOneCommittedReceiptAndDoesNotReplayOnRestore() throws {
        let (store, presenter, _, defaults) = makeStore()
        store.clear(Cell(0, 0)); XCTAssertNil(store.celebration)
        store.callShower(); presenter.finish()
        let before = store.game
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
        let event = try XCTUnwrap(store.celebration)
        XCTAssertEqual(event.collected, 3); XCTAssertEqual(event.total, store.game.score)
        XCTAssertEqual(event.level, .ordinary)
        XCTAssertTrue(event.cells.allSatisfy { before.gem(at: $0)?.kind != nil })
        store.clear(event.cells[0]); XCTAssertEqual(store.celebration, event, "Rapid duplicate input cannot create a receipt")
        let saved = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertEqual(try JSONDecoder().decode(FallingSky.self, from: saved), store.game)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertNil(restored.celebration); XCTAssertEqual(restored.game, store.game)
        presenter.finish()
        XCTAssertTrue(store.canClear, "Decorative tail does not hold input")
        XCTAssertEqual(store.celebration, event)
    }

    @MainActor func testCelebrationCancelsAcrossLifecycleAndStaleCompletions() throws {
        for boundary in ["settings", "motion", "restart", "challenge", "shower", "layout"] {
            let (store, presenter, _, _) = makeStore()
            store.callShower(); presenter.finish()
            store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
            XCTAssertNotNil(store.celebration)
            switch boundary {
            case "settings": store.setSuspended(true)
            case "motion": store.setReducedMotion(true)
            case "restart": store.restart(sameSky: true)
            case "challenge": store.startFirstLight()
            case "shower": presenter.finish(); store.callShower()
            default: store.scene.onLayout?()
            }
            XCTAssertNil(store.celebration, boundary)
            let committed = store.game
            presenter.finish()
            XCTAssertNil(store.celebration, boundary)
            XCTAssertEqual(store.game, committed, boundary)
        }
    }

    @MainActor func testCelebrationExpiresIndependentlyOfTurnCompletion() async throws {
        let (store, presenter, _, _) = makeStore()
        store.callShower(); presenter.finish()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first))
        XCTAssertNotNil(store.celebration)
        let committed = store.game
        let expired = expectation(description: "Finite receipt expires")
        let observation = Task { @MainActor in
            while store.celebration != nil && !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(20)) } catch { return }
            }
            expired.fulfill()
        }
        await fulfillment(of: [expired], timeout: 3)
        observation.cancel()
        XCTAssertTrue(store.busy, "Expiration cannot complete the gameplay presentation")
        XCTAssertEqual(store.game, committed)
        presenter.finish(); XCTAssertTrue(store.canClear)
    }

    @MainActor private func makeStore() -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let defaults = UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)")!
        // Keep the established legacy-clock regression scenarios source-bound.
        // New-opening behavior is exercised separately below with a fresh store.
        defaults.set(try! JSONEncoder().encode(FallingSky(seed: 5,
            balance: .init(pace: .steady), openingCascade: false)), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-seed=5"], presenter: presenter, clock: clock)
        addTeardownBlock { defaults.removeObject(forKey: "starfall.accumulation.v3") }
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
    }

    @MainActor private func makeOpeningStore() -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.Opening.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=5"],
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
        XCTAssertEqual(store.showerInterval, 3)
        clock.advance(2.99); XCTAssertEqual(store.game.turns, 4)
        clock.advance(0.01); XCTAssertEqual(store.game.turns, 5)
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
        let saved = try JSONDecoder().decode(FallingSky.self, from: XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
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
        let activated = try JSONDecoder().decode(FallingSky.self,
            from: XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(activated, FallingSky(seed: 5))
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
        let beside = try XCTUnwrap(group.first { store.game.isGrowthBlocked(at: $0) })
        let expectedScore = store.game.score + store.game.value(of: Set(group))
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
        XCTAssertTrue(store.message.contains("Dark star dissolved"))
        let saved = try JSONDecoder().decode(FallingSky.self, from: XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
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
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, initial); XCTAssertTrue(store.isPaused)
        store.restart(sameSky: false)
        XCTAssertNil(store.game.challenge); XCTAssertEqual(store.game.outcome, .playing)
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
        XCTAssertEqual(feedback.announcements, [store.message], "Invalid explicit input explains the rule")
        feedback.announcements.removeAll()
        store.callShower(); presenter.finish()
        XCTAssertEqual(feedback.announcements, [store.message], "Manual showers speak their committed result")
        feedback.announcements.removeAll()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first)); presenter.finish()
        XCTAssertEqual(feedback.announcements, [store.message + " Total \(store.game.score) starlight."], "Explicit clears retain award and total")
        feedback.announcements.removeAll()
        store.togglePause()
        clock.advance(4); presenter.finish()
        XCTAssertEqual(store.game.turns, 2)
        XCTAssertTrue(feedback.announcements.isEmpty, "Automatic rain leaves exploration speech alone")
        for _ in 0..<40 where !store.game.isOver { clock.advance(4); presenter.finish() }
        XCTAssertTrue(store.game.isOver)
        XCTAssertEqual(feedback.announcements, [store.message], "The terminal automatic result still speaks")
        store.restart(sameSky: true)
        feedback.announcements.removeAll()
        store.callShower(); store.setSuspended(true); presenter.finish()
        XCTAssertTrue(feedback.announcements.isEmpty, "Suspension rejects stale result speech")
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

@MainActor private final class ManualRainClock: FallingSkyRainScheduling {
    var now: TimeInterval = 0
    var deadline: TimeInterval?
    var action: (@MainActor () -> Void)?
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {
        deadline = now + delay; self.action = action
    }
    func cancel() { deadline = nil; action = nil }
    func advance(_ duration: TimeInterval) {
        now += duration
        if let deadline, deadline <= now + 0.00001 {
            let callback = action
            cancel(); callback?()
        }
    }
}

@MainActor private final class FallingSkyRecorder: FallingSkyPresenting {
    var reduceMotion = false
    var lastRendered: FallingSky?
    var completions: [() -> Void] = []
    func render(_ game: FallingSky) { lastRendered = game }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        completions.append(completion)
    }
    func finish() { completions.last?() }
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
