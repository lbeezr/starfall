import XCTest
import StarfallCore
@testable import Starfall

/// Store-boundary tests, not claims about real touch delivery or SpriteKit timing.
final class GameStoreInterruptionTests: XCTestCase {
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
