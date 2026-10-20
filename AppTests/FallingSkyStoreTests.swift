import XCTest
import StarfallCore
@testable import Starfall

@MainActor private final class CascadePresenter: FallingSkyPresenting {
    var reduceMotion = false
    var staged: FallingSky?
    var rendered: FallingSky?
    var openings: [() -> Void] = []
    var phases: [(Int) -> Void] = []
    var completions: [() -> Void] = []
    func render(_ game: FallingSky) { rendered = game }
    func prepareOpening(_ game: FallingSky) { staged = game }
    func presentOpening(_ game: FallingSky, completion: @escaping () -> Void) {
        openings.append(completion)
    }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) { completions.append(completion) }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        phases.append(phaseBegan); completions.append(completion)
    }
}

final class FallingSkyStoreTests: XCTestCase {
    @MainActor func testSceneQuietCompletionWithoutPhaseCallbacksGetsOneAggregateReceipt() throws {
        let suite = "Starfall.SystemQuietCascade.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = CascadePresenter(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                   clock: ManualRainClock(), feedback: feedback)
        store.startFirstLight(); store.setSuspended(false); presenter.openings[0]()
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)),
                                            snapshot: store.game, generation: store.constellationInputGeneration))
        presenter.completions[0]()
        XCTAssertEqual(store.celebration?.displayAward, 15_000)
        XCTAssertEqual(feedback.clears, 1)
        presenter.completions[0](); presenter.phases[0](1)
        XCTAssertEqual(feedback.clears, 1)
        store.setSuspended(true)
    }

    @MainActor func testLayoutOrMotionInterruptionRearmsTheUnpausedOpeningClock() throws {
        for motionChange in [false, true] {
            let suite = "Starfall.OpeningSettle.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let presenter = CascadePresenter(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            store.startFirstLight(); store.setSuspended(false); store.togglePause()
            XCTAssertNil(clock.deadline)
            if motionChange { store.setReducedMotion(true) }
            else { store.settlePresentation(reason: "presentation") }
            XCTAssertFalse(store.busy)
            XCTAssertNotNil(clock.deadline)
            let deadline = clock.deadline
            presenter.openings[0]()
            XCTAssertEqual(clock.deadline, deadline)
            store.setSuspended(true)
        }
    }

    @MainActor func testOpeningCommitsOnceAndHoldsClockAndInputUntilRainFinishes() throws {
        let suite = "Starfall.CascadeOpening.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = CascadePresenter(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.startFirstLight()
        let opening = store.game
        XCTAssertEqual(opening.board.compactMap { $0 }.count, 24)
        XCTAssertEqual(opening.displayScore, 0)
        XCTAssertEqual(presenter.staged, opening)
        XCTAssertTrue(presenter.openings.isEmpty)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        store.setSuspended(false)
        XCTAssertEqual(presenter.openings.count, 1)
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.changingColumns, Set(0..<7))
        store.togglePause()
        XCTAssertNil(clock.deadline)
        store.callShower()
        XCTAssertEqual(store.game, opening)
        presenter.openings[0]()
        XCTAssertFalse(store.busy)
        XCTAssertNotNil(clock.deadline)
        XCTAssertEqual(store.game, opening)
        store.setSuspended(true); store.setSuspended(false)
        XCTAssertEqual(presenter.openings.count, 1)
        XCTAssertEqual(store.game, opening)
        store.setSuspended(true)
    }

    @MainActor func testInterruptedOpeningAndCascadeRejectStaleCompletionsAndReceipts() throws {
        let suite = "Starfall.CascadeInterruption.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = CascadePresenter(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock, feedback: feedback)
        store.startFirstLight(); store.setSuspended(false)
        store.setSuspended(true)
        presenter.openings[0]()
        XCTAssertFalse(store.busy)
        XCTAssertNil(clock.deadline)
        store.setSuspended(false)
        let before = store.game
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)),
                                            snapshot: before, generation: store.constellationInputGeneration))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game.displayScore, 15_000)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
        XCTAssertNil(store.celebration)
        presenter.phases[0](0)
        XCTAssertEqual(store.celebration?.displayAward, 5_000)
        presenter.phases[0](1)
        XCTAssertEqual(store.celebration?.displayAward, 15_000)
        XCTAssertEqual(store.celebration?.level, .cascade(2))
        XCTAssertEqual(feedback.clears, 2)
        presenter.completions[0]()
        XCTAssertFalse(store.busy)
        presenter.phases[0](0)
        XCTAssertEqual(feedback.clears, 2, "Completed presentations cannot emit another receipt")
        store.startChallenge(.ribbonCrossing)
        let replacement = store.game
        presenter.phases[0](1); presenter.completions[0](); presenter.openings[0]()
        XCTAssertEqual(store.game, replacement)
        XCTAssertTrue(store.busy, "An old opening cannot finish a replacement opening")
        XCTAssertNil(store.celebration)
        XCTAssertNil(clock.deadline)
        store.setSuspended(true)
    }

    @MainActor func testQuietCascadePublishesOneAggregateReceiptAndNeverReawardsOnResume() throws {
        let suite = "Starfall.QuietCascade.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = CascadePresenter(), feedback = SkyFeedbackRecorder()
        presenter.reduceMotion = true
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                   clock: ManualRainClock(), feedback: feedback)
        store.startChallenge(.ribbonCrossing); store.setSuspended(false)
        presenter.openings[0]()
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)),
                                            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.celebration?.displayAward, 30_000)
        XCTAssertEqual(store.celebration?.level, .cascade(3))
        XCTAssertEqual(feedback.clears, 1)
        presenter.phases[0](0); presenter.phases[0](1); presenter.phases[0](2)
        XCTAssertEqual(feedback.clears, 1)
        let final = store.game
        store.setSuspended(true); presenter.completions[0](); store.setSuspended(false)
        XCTAssertEqual(store.game, final)
        XCTAssertNil(store.celebration)
        XCTAssertEqual(feedback.clears, 1)
        store.setSuspended(true)
    }

    #if DEBUG
    @MainActor func testObservatoryReviewUsesIsolatedGameAndPreferenceDefaults() throws {
        let suiteName = "Starfall.ObservatoryReview"
        let review = UserDefaults(suiteName: suiteName)!
        let previousReview = review.persistentDomain(forName: suiteName)
        defer {
            review.removePersistentDomain(forName: suiteName)
            if let previousReview { review.setPersistentDomain(previousReview, forName: suiteName) }
        }
        review.removePersistentDomain(forName: suiteName)
        let ordinary = UserDefaults.standard
        let normalSave = ordinary.data(forKey: FallingSkyStore.saveKey)
        let normalPlace = ordinary.string(forKey: "landingPlace")
        let normalSound = ordinary.object(forKey: "soundEnabled") as? Bool
        let normalHaptics = ordinary.object(forKey: "starfall.haptics") as? Bool
        let arguments = ["--starfalls-reset", "--observatory-review"]
        let selected = SkyDefaults.forApp(arguments: arguments)
        selected.set("archive", forKey: "landingPlace")
        let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
        defer { store.setSuspended(true) }
        XCTAssertEqual(store.game, ObservatoryReviewFixture.game(dense: false).adoptingFeedingDusk())
        store.soundEnabled = false; store.hapticsEnabled = false
        store.setReducedMotion(true); store.setSuspended(false)
        var expected = store.game
        _ = expected.clear(Cell(0, 0))
        store.clear(Cell(0, 0))
        let saved = try XCTUnwrap(review.data(forKey: FallingSkyStore.saveKey))
        let committed = try SkySaveArchive.decode(saved)
        XCTAssertEqual(committed, expected)
        XCTAssertGreaterThan(committed.score, 0)
        XCTAssertEqual(review.string(forKey: "landingPlace"), "archive")
        XCTAssertEqual(review.object(forKey: "soundEnabled") as? Bool, false)
        XCTAssertEqual(review.object(forKey: "starfall.haptics") as? Bool, false)
        XCTAssertEqual(ordinary.data(forKey: FallingSkyStore.saveKey), normalSave)
        XCTAssertEqual(ordinary.string(forKey: "landingPlace"), normalPlace)
        XCTAssertEqual(ordinary.object(forKey: "soundEnabled") as? Bool, normalSound)
        XCTAssertEqual(ordinary.object(forKey: "starfall.haptics") as? Bool, normalHaptics)
        XCTAssertTrue(SkyDefaults.forApp(arguments: []) === ordinary)
        XCTAssertTrue(SkyDefaults.forApp(arguments: ["--observatory-review"]) === ordinary)
        XCTAssertTrue(SkyDefaults.forApp(arguments: ["--starfalls-reset"]) === ordinary)
    }

    @MainActor func testLanternReviewFixturesRetainFirstLightRulesAndFinishThroughARealClear() throws {
        let suite = "Starfall.LanternFixture.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for score in [0, 5, 9, 14, 18] {
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--dialogue-review", "--lantern-restoration-review=\(score)"],
                presenter: presenter, clock: ManualRainClock())
            XCTAssertTrue(store.game.isValidSave)
            XCTAssertEqual(store.game.challenge, .firstLight)
            XCTAssertEqual(store.game.seed, StarfallChallenge.firstLight.seed)
            XCTAssertEqual(store.game.balance, StarfallChallenge.firstLight.balance)
            XCTAssertEqual(store.game.score, score)
            XCTAssertFalse(store.game.board.contains { $0?.isDark == true })
            XCTAssertFalse(store.game.incoming.contains(where: \.isDark))
            XCTAssertEqual(store.game.restoration, StarlightRestoration(score: score, target: 18))
            if score == 14 {
                store.setSuspended(false)
                store.clear(Cell(0, 0))
                XCTAssertTrue(store.busy)
                XCTAssertEqual(store.game.score, 18)
                XCTAssertEqual(store.game.outcome, .won)
                XCTAssertEqual(store.game.restoration?.milestone, .complete)
                presenter.finish()
                XCTAssertFalse(store.busy)
                store.setSuspended(true)
            }
        }
    }

    @MainActor func testLanternReviewRequiresResetDialogueReviewAndABoundedScore() throws {
        let suite = "Starfall.LanternFixtureGuards.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = FallingSky.freshSurvival(seed: 91)
        let saved = try SkySaveArchive.encode(original)
        defaults.set(saved, forKey: FallingSkyStore.saveKey)
        let fixture = "--lantern-restoration-review=14"
        let cases = [
            [fixture], ["--dialogue-review", fixture], ["--starfalls-reset", fixture],
            ["--starfalls-reset", "--dialogue-review"],
            ["--starfalls-reset", "--dialogue-review", "--lantern-restoration-review=-1"],
            ["--starfalls-reset", "--dialogue-review", "--lantern-restoration-review=19"],
            ["--starfalls-reset", "--dialogue-review", "--lantern-restoration-review=invalid"]
        ]
        for arguments in cases {
            let store = FallingSkyStore(defaults: defaults, arguments: arguments,
                presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertNil(store.game.challenge, "Unexpected fixture for \(arguments)")
            XCTAssertNil(store.game.restoration)
            XCTAssertEqual(store.game, arguments.contains("--starfalls-reset") ? FallingSky.freshSurvival(seed: 5) : original)
            XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved, "Fixture parsing must not write the retained archive")
        }
    }
    #endif

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
        XCTAssertTrue(restored.message.contains("Your sky is waiting"))
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
        XCTAssertEqual(store.showerInterval, 3)
        clock.advance(2.99); XCTAssertEqual(store.game.turns, 4)
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
        XCTAssertEqual(store.showerInterval, 3)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 3, accuracy: 0.001)
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
        XCTAssertEqual(store.game.turns, 0); XCTAssertFalse(store.showerCountdown.advancing)
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

    @MainActor func testForecastUsesHeldRemainderAndActualDeadlineThroughDeferredRain() throws {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(1.5)
        XCTAssertEqual(store.showerCountdown.remaining,2.5,accuracy:0.001)
        XCTAssertEqual(store.showerCountdown.progress,0.375,accuracy:0.001)
        XCTAssertTrue(store.showerCountdown.advancing)
        let hold = try XCTUnwrap(store.beginConstellationHold())
        let frozen = store.showerCountdown
        XCTAssertFalse(frozen.advancing); XCTAssertFalse(frozen.paused)
        clock.advance(40)
        XCTAssertEqual(store.showerCountdown,frozen)
        store.endConstellationHold(hold)
        XCTAssertEqual(store.showerCountdown.progress,frozen.progress,accuracy:0.001)
        XCTAssertEqual(try XCTUnwrap(clock.deadline)-clock.now,frozen.remaining,accuracy:0.001)
        clock.advance(2.5)
        XCTAssertEqual(store.game.turns,1)
        XCTAssertTrue(store.showerCountdown.arriving); XCTAssertEqual(store.showerCountdown.progress,1)
        clock.advance(100)
        XCTAssertEqual(store.game.turns,1)
        XCTAssertEqual(store.showerCountdown.remaining,0)
        XCTAssertFalse(store.showerCountdown.advancing)
        presenter.finish(); presenter.finish()
        XCTAssertEqual(store.game.turns,2)
        XCTAssertFalse(store.showerCountdown.arriving)
        XCTAssertEqual(store.showerCountdown.remaining,4,accuracy:0.001)
        XCTAssertEqual(store.showerCountdown.progress,0)
    }

    @MainActor func testForecastPreservesPauseGraceBackgroundAndQuietOutcome() {
        let (store, presenter, clock, _) = makeStore()
        store.togglePause(); clock.advance(3.9)
        store.togglePause()
        XCTAssertTrue(store.showerCountdown.paused)
        XCTAssertFalse(store.showerCountdown.advancing)
        XCTAssertEqual(store.showerCountdown.remaining,0.5,accuracy:0.001)
        let frozen = store.showerCountdown
        store.setReducedMotion(true); clock.advance(100)
        XCTAssertEqual(store.showerCountdown,frozen)
        store.setSuspended(true); clock.advance(100); store.setSuspended(false)
        XCTAssertEqual(store.showerCountdown,frozen)
        store.togglePause(); clock.advance(0.49)
        XCTAssertEqual(store.game.turns,0)
        clock.advance(0.01); presenter.finish()
        XCTAssertEqual(store.game.turns,1)
        XCTAssertEqual(store.showerCountdown.remaining,4,accuracy:0.001)
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
        XCTAssertEqual(activated, FallingSky.freshSurvival(seed: 5))
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
        XCTAssertTrue(store.message.contains("send me off"))
        store.clear(beside)
        XCTAssertEqual(store.game.darkStarsCleared, expectedDark)
        XCTAssertEqual(store.game.score, expectedScore)
        XCTAssertTrue(store.message.contains("Dusk removed"))
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
        XCTAssertEqual(initial, FallingSky.freshChallenge(.firstLight))
        XCTAssertEqual(initial.displayTarget, 150_000)
        XCTAssertEqual(initial.restoration?.milestone, .unrestored)
        XCTAssertNil(clock.deadline); XCTAssertTrue(store.isPaused)
        store.togglePause()
        // Use the current rules: take rewarding swaps as well as taps, and make
        // a one-swap tap setup when no immediate scoring action remains.
        for _ in 0..<80 where !store.game.isOver {
            for _ in 0..<50 where !store.game.isOver {
                guard let (from, to) = storyScoringChoice(store.game) else { break }
                if let to {
                    XCTAssertTrue(store.performTechnique(.nudge(from, to), snapshot: store.game,
                                                         generation: store.constellationInputGeneration))
                } else { store.clear(from) }
                presenter.finish()
            }
            if !store.game.isOver { clock.advance(store.showerInterval); presenter.finish() }
        }
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertNil(clock.deadline); XCTAssertFalse(store.canClear)
        let completed = store.game
        XCTAssertEqual(completed.restoration?.milestone, .complete)
        clock.advance(100); store.callShower(); store.togglePause(); store.clear(Cell(0, 0))
        XCTAssertEqual(store.game, completed)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, completed); XCTAssertTrue(restored.message.contains("complete"))
        restored.restart(sameSky: false)
        XCTAssertNil(restored.game.challenge)
        XCTAssertNil(restored.game.restoration)
        XCTAssertEqual(restored.game.balance, StarfallBalance())
        XCTAssertEqual(restored.game.cadenceID, .announcedCycleV1)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, initial); XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game.restoration?.milestone, .unrestored)
        store.restart(sameSky: false)
        XCTAssertNil(store.game.challenge); XCTAssertEqual(store.game.outcome, .playing)
        XCTAssertNil(store.game.restoration)
    }

    @MainActor func testLeavingOverflowedChallengeRestoresNormalCadenceAndBalance() {
        let (store, presenter, _, _) = makeStore()
        store.startFirstLight()
        for _ in 0..<50 where !store.game.isOver { store.callShower(); presenter.finish() }
        XCTAssertEqual(store.game.outcome, .lost)
        store.restart(sameSky: false)
        XCTAssertNil(store.game.challenge)
        XCTAssertEqual(store.game.balance, StarfallBalance())
        XCTAssertEqual(store.game.cadenceID, .announcedCycleV1)
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
        XCTAssertEqual(store.game.balance, challenge.balance)
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
        defaults.set(try! SkySaveArchive.encode(FallingSky(seed: 5, generation: .current, duskRule: .patientFeeding)), forKey: SkySaveArchive.key)
        let feedback = SkyFeedbackRecorder(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [],
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
            "Nova. 1 lighter shower before the storm. Dusk will eat 1 star after 3 more showers with a touching star.",
            "Nova. Storm: 3 heavy showers left. Showers get faster after the next shower. Dusk will eat 2 stars after 2 more showers with a touching star.",
            "Nova. 9 lighter showers before the storm. Showers are closer together now. Dusk will eat 1 star after 3 more showers with a touching star.",
            "Nova. 8 lighter showers before the storm. More time between showers now. Dusk will eat 1 star after 2 more showers with a touching star.",
            "Nova. 1 lighter shower before the storm. Dusk will eat 3 stars after 5 more showers with a touching star.",
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
        defaults.set(try! SkySaveArchive.encode(FallingSky(seed: 5, generation: .current, duskRule: .patientFeeding)), forKey: SkySaveArchive.key)
        let feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [],
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
            XCTAssertEqual(store.nextShowerCadence, SkyCadenceID.announcedCycleV1.step(committedShowers: count, pace: .brisk))
            XCTAssertFalse(store.game.isOver)
            store.callShower(); presenter.finish()
            while let cell = store.game.legalGroups.first?.first { store.clear(cell); presenter.finish() }
        }
        XCTAssertEqual(events.filter { $0.kind == .manualShower }.count, 16)
        XCTAssertNil(clock.deadline)
        store.togglePause()
        let scheduled = try XCTUnwrap(events.last { $0.kind == .scheduled })
        XCTAssertEqual(scheduled.snapshot.cadence, SkyCadenceID.announcedCycleV1.step(committedShowers: 16, pace: .brisk))
        XCTAssertEqual(try XCTUnwrap(scheduled.snapshot.scheduledDeadline) - scheduled.snapshot.time, 3)
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
        XCTAssertEqual(store.showerInterval, 6); XCTAssertEqual(store.nextShowerCadence.phase, .steady)
        store.togglePause(); clock.advance(4)
        XCTAssertEqual(store.game.turns, 0, "New Lantern keeps its gentle deadline instead of the historical four-second pace")
        clock.advance(2)
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
    @MainActor func testFreshAutomaticBoundariesSurviveSettingsPauseAndMotion() throws {
        let (store, presenter, clock, _) = makeOpeningStore()
        store.setSuspended(true)
        store.setSuspended(false); store.togglePause()
        for count in 0..<16 {
            let cadence = store.nextShowerCadence
            XCTAssertEqual(cadence, SkyCadenceID.announcedCycleV1.step(committedShowers: count, pace: .brisk))
            if count == 9 {
                XCTAssertTrue(cadence.warnsFasterNext)
                clock.advance(1)
                store.setSuspended(true); clock.advance(100); store.setSuspended(false)
                XCTAssertEqual(store.nextShowerCadence, cadence)
                XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 2, accuracy: 0.001)
                store.togglePause(); clock.advance(100); store.togglePause()
                XCTAssertEqual(store.nextShowerCadence, cadence)
                XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 2, accuracy: 0.001)
            }
            clock.advance(try XCTUnwrap(clock.deadline) - clock.now)
            XCTAssertEqual(store.game.turns, count + 1)
            let nextDeadline = clock.deadline
            store.setReducedMotion(count.isMultiple(of: 2))
            presenter.finish()
            XCTAssertEqual(clock.deadline, nextDeadline)
            while let cell = store.game.legalGroups.first?.first { store.clear(cell); presenter.finish() }
        }
        XCTAssertEqual(store.nextShowerCadence, .init(delay: 3, phase: .steady))
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
        XCTAssertTrue(store.pausedGuideLine.text.contains("Tap matching stars connected"))
        XCTAssertTrue(store.pausedGuideLine.text.contains("1 lighter shower"))
        XCTAssertEqual(feedback.announcements, [store.pausedGuideLine.spokenText])
        XCTAssertEqual(store.dialogue.line, store.pausedGuideLine)
        store.callShower(); presenter.finish()
        XCTAssertTrue(store.pausedGuideLine.text.contains("Storm: 3 heavy showers left."))
        XCTAssertTrue(store.pausedGuideLine.text.contains("Showers get faster after the next shower."))
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
