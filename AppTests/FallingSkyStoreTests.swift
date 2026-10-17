import XCTest
import StarfallCore
@testable import Starfall

final class FallingSkyStoreTests: XCTestCase {
    @MainActor private func makeStore() -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let defaults = UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)")!
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-seed=5"], presenter: presenter, clock: clock)
        addTeardownBlock { defaults.removeObject(forKey: "starfall.accumulation.v3") }
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
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
        XCTAssertEqual(restored.game, store.game); XCTAssertEqual(restored.showerInterval, 6)
        let board = restored.game.board
        restored.setBalance(StarfallBalance())
        XCTAssertEqual(restored.showerInterval, 4); XCTAssertEqual(restored.game.board, board)
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
        XCTAssertFalse(store.soundEnabled); XCTAssertFalse(store.hapticsEnabled)
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
    var sound = false, haptics = false
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        clears += 1; sound = soundEnabled; haptics = hapticsEnabled
    }
    func stopSounds() { stops += 1 }
}
