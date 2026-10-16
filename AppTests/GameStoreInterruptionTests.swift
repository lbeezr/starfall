import XCTest
import StarfallCore
@testable import Starfall

/// Store-boundary tests, not claims about real touch delivery or SpriteKit timing.
final class GameStoreInterruptionTests: XCTestCase {
    @MainActor func testMuteAndLifecycleStopSoundsWithoutReplayingCommittedTurns() async throws {
        let suite = "StarfallAudioLifecycleTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = ControlledPresenter()
        let feedback = RecordingFeedback()
        let store = GameStore(defaults: defaults, arguments: ["--demo"],
                              presenter: presenter, feedback: feedback)
        XCTAssertFalse(store.soundEnabled)
        store.soundEnabled = true
        store.tap(Cell(1, 1))
        XCTAssertEqual(feedback.clearCounts, [3])
        store.soundEnabled = false
        XCTAssertEqual(feedback.stopCount, 1)
        XCTAssertFalse(defaults.bool(forKey: "soundEnabled"))
        store.settings = true
        XCTAssertEqual(feedback.stopCount, 2)
        store.settings = false
        presenter.completions[0]()
        XCTAssertEqual(feedback.clearCounts, [3])
        XCTAssertTrue(feedback.announcements.isEmpty)
        store.restart()
        XCTAssertEqual(feedback.stopCount, 3)
        store.playing = false
        XCTAssertEqual(feedback.stopCount, 4)
        store.start()
        store.settlePresentation() // Same production path used for backgrounding/detachment.
        XCTAssertEqual(feedback.stopCount, 5)
        XCTAssertEqual(feedback.clearCounts, [3])
    }

    @MainActor func testMenuAndSettingsBlockInputAndSettlePendingTurn() async throws {
        try withFixture { store, presenter, defaults in
            store.tap(try legalCell(in: store.game))
            let committed = store.game
            store.settings = true
            XCTAssertFalse(store.busy)
            XCTAssertEqual(presenter.rendered.last, committed)
            store.tap(try legalCell(in: committed))
            XCTAssertEqual(store.game, committed)
            store.settings = false
            store.playing = false
            store.tap(try legalCell(in: committed))
            XCTAssertEqual(store.game, committed)
            store.start()
            store.tap(try legalCell(in: committed))
            XCTAssertEqual(store.game.moves, committed.moves - 1)
            XCTAssertEqual(try savedGame(defaults), store.game)
        }
    }

    @MainActor func testFeedbackIsOncePerValidTurnAndCancelledAnnouncementStaysSilent() async throws {
        let suite = "StarfallFeedbackTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = ControlledPresenter()
        let feedback = RecordingFeedback()
        let store = GameStore(defaults: defaults, arguments: ["--demo"],
                              presenter: presenter, feedback: feedback)
        store.soundEnabled = true
        store.calmEffects = true
        store.tap(Cell(1, 1))
        XCTAssertEqual(feedback.clearCounts, [3])
        XCTAssertEqual(feedback.soundSettings, [true])
        XCTAssertEqual(feedback.calmSettings, [true])
        store.tap(try legalCell(in: store.game))
        XCTAssertEqual(feedback.clearCounts, [3])
        XCTAssertTrue(feedback.announcements.isEmpty)
        store.settings = true
        presenter.completions[0]()
        XCTAssertTrue(feedback.announcements.isEmpty)
        store.settings = false
        store.tap(try legalCell(in: store.game))
        presenter.completions[1]()
        XCTAssertEqual(feedback.announcements.count, 1)
        XCTAssertTrue(feedback.announcements[0].contains("16 moves remaining"))
        presenter.completions[1]()
        XCTAssertEqual(feedback.announcements.count, 1)
    }

    @MainActor func testInvalidTapAnnouncesNoMoveWithoutClearFeedback() async throws {
        let suite = "StarfallFeedbackTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = RecordingFeedback()
        let store = GameStore(defaults: defaults, arguments: ["--demo"],
                              presenter: ControlledPresenter(), feedback: feedback)
        let initial = store.game
        store.tap(Cell(0, 0))
        XCTAssertEqual(store.game, initial)
        XCTAssertTrue(feedback.clearCounts.isEmpty)
        XCTAssertEqual(feedback.announcements.count, 1)
        XCTAssertTrue(feedback.announcements[0].hasSuffix("No move used."))
    }

    @MainActor func testSecondLegalInputWhileBusyDoesNotSpendAnotherMove() async throws {
        try withFixture { store, presenter, defaults in
            let initial = store.game
            store.tap(try legalCell(in: initial))
            let committed = store.game
            XCTAssertEqual(committed.moves, initial.moves - 1)
            XCTAssertTrue(store.busy)
            XCTAssertEqual(presenter.completions.count, 1)
            store.tap(try legalCell(in: committed))
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(try savedGame(defaults), committed)
            XCTAssertEqual(presenter.completions.count, 1)
            presenter.completions[0]()
            XCTAssertFalse(store.busy)
        }
    }

    @MainActor func testInactiveSettlementPreservesCommittedGame() async throws {
        try withFixture { store, presenter, defaults in
            store.tap(try legalCell(in: store.game))
            let committed = store.game
            XCTAssertTrue(store.busy)
            // StarfallView calls this production method when scenePhase is not active.
            store.settlePresentation()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(try savedGame(defaults), committed)
            XCTAssertEqual(presenter.cancelCount, 1)
            XCTAssertEqual(presenter.rendered.last, committed)
            presenter.completions[0]()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, committed)
        }
    }

    @MainActor func testReducedMotionSettlesWithoutChangingCommittedGame() async throws {
        try withFixture { store, presenter, defaults in
            XCTAssertFalse(store.soundEnabled)
            XCTAssertFalse(store.calmEffects)
            store.soundEnabled = true
            store.calmEffects = true
            XCTAssertTrue(defaults.bool(forKey: "soundEnabled"))
            XCTAssertTrue(defaults.bool(forKey: "calmEffects"))
            store.tap(try legalCell(in: store.game))
            let committed = store.game
            XCTAssertTrue(store.busy)
            store.updateReducedMotion(true)
            XCTAssertTrue(presenter.reduceMotion)
            XCTAssertFalse(store.busy)
            XCTAssertEqual(presenter.cancelCount, 1)
            XCTAssertEqual(presenter.rendered.last, committed)
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(try savedGame(defaults), committed)
            presenter.completions[0]()
            XCTAssertFalse(store.busy)
            store.updateReducedMotion(false)
            XCTAssertFalse(presenter.reduceMotion)
            XCTAssertEqual(presenter.cancelCount, 1)
        }
    }

    @MainActor func testStaleCompletionCannotUnlockNewerTurn() async throws {
        try withFixture { store, presenter, defaults in
            store.tap(try legalCell(in: store.game))
            let oldCompletion = try XCTUnwrap(presenter.completions.first)
            store.settlePresentation()
            store.tap(try legalCell(in: store.game))
            let secondCommitted = store.game
            XCTAssertEqual(presenter.completions.count, 2)
            XCTAssertTrue(store.busy)
            oldCompletion()
            XCTAssertTrue(store.busy)
            store.tap(try legalCell(in: secondCommitted))
            XCTAssertEqual(store.game, secondCommitted)
            XCTAssertEqual(try savedGame(defaults), secondCommitted)
            XCTAssertEqual(presenter.completions.count, 2)
            presenter.completions[1]()
            XCTAssertFalse(store.busy)
            // Repeated old completions also cannot affect an already settled turn.
            oldCompletion()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, secondCommitted)
        }
    }

    @MainActor private func withFixture(
        _ body: (GameStore, ControlledPresenter, UserDefaults) throws -> Void
    ) throws {
        let suite = "StarfallAppTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONEncoder().encode(Game(seed: 42)), forKey: "starfall.game.v1")
        defaults.set(false, forKey: "soundEnabled")
        defaults.set(false, forKey: "calmEffects")
        let presenter = ControlledPresenter()
        let store = GameStore(defaults: defaults, arguments: [], presenter: presenter)
        XCTAssertEqual(store.game, Game(seed: 42))
        store.start()
        try body(store, presenter, defaults)
    }

    private func legalCell(in game: Game) throws -> Cell {
        try XCTUnwrap((0..<(Game.side * Game.side))
            .map { Cell($0 / Game.side, $0 % Game.side) }
            .first { game.group(at: $0).count >= 3 })
    }

    private func savedGame(_ defaults: UserDefaults) throws -> Game {
        try JSONDecoder().decode(Game.self,
            from: XCTUnwrap(defaults.data(forKey: "starfall.game.v1")))
    }
}

@MainActor private final class RecordingFeedback: GameFeedbackProviding {
    var clearCounts: [Int] = []
    var soundSettings: [Bool] = []
    var calmSettings: [Bool] = []
    var announcements: [String] = []
    var stopCount = 0
    func cleared(_ turn: Turn, outcome: Outcome, soundEnabled: Bool, calmEffects: Bool) {
        clearCounts.append(turn.cleared.count)
        soundSettings.append(soundEnabled)
        calmSettings.append(calmEffects)
    }
    func announce(_ message: String) { announcements.append(message) }
    func stopSounds() { stopCount += 1 }
}

@MainActor private final class ControlledPresenter: TurnPresenting {
    var reduceMotion = false
    var rendered: [Game] = []
    var completions: [() -> Void] = []
    var cancelCount = 0
    func render(_ game: Game) { rendered.append(game) }
    func nudge(_ cell: Cell) {}
    func cancelAnimations() {
        cancelCount += 1
        // Intentionally retain cancelled callbacks to exercise stale-completion safety.
    }
    func animate(turn: Turn, old: Game, new: Game, completion: @escaping () -> Void) {
        completions.append(completion)
    }
}
