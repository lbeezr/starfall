import XCTest
import StarfallCore
@testable import Starfall

final class StarfallExperimentStoreTests: XCTestCase {
    @MainActor func testRapidInputAndLifecycleCommitEachShowerOnce() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)"))
        defer { defaults.removeObject(forKey: StarfallExperimentStore.saveKey) }
        let presenter = ExperimentRecorder()
        let store = StarfallExperimentStore(defaults: defaults, arguments: ["--starfalls-seed=42"], presenter: presenter)
        store.inviteShower()
        let committed = store.game
        XCTAssertTrue(store.busy)
        store.inviteShower(); store.clear(Cell(0, 0))
        XCTAssertEqual(store.game, committed)
        let saved = try JSONDecoder().decode(StarfallExperiment.self, from: XCTUnwrap(defaults.data(forKey: StarfallExperimentStore.saveKey)))
        XCTAssertEqual(saved, committed)
        store.setSuspended(true)
        XCTAssertFalse(store.busy); XCTAssertNil(store.pending)
        store.inviteShower(); XCTAssertEqual(store.game, committed)
        presenter.completions[0]()
        XCTAssertEqual(store.game, committed)
        store.setSuspended(false); store.inviteShower()
        XCTAssertEqual(store.game.turns, 2)
        XCTAssertTrue(store.busy)
        presenter.completions[0]()
        XCTAssertTrue(store.busy, "A stale completion cannot unlock a newer turn")
        presenter.completions[1]()
        XCTAssertFalse(store.busy)
    }

    @MainActor func testReplayRestoresTheSameEmptySkyAndKeepsOriginalSaveSeparate() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)"))
        defaults.set(Data([1,2,3]), forKey: "starfall.game.v1")
        defer { defaults.removeObject(forKey: StarfallExperimentStore.saveKey); defaults.removeObject(forKey: "starfall.game.v1") }
        let presenter = ExperimentRecorder()
        let store = StarfallExperimentStore(defaults: defaults, arguments: ["--starfalls-seed=42"], presenter: presenter)
        let initial = store.game
        store.inviteShower()
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, initial); XCTAssertFalse(store.busy)
        presenter.completions[0]()
        XCTAssertEqual(store.game, initial)
        XCTAssertEqual(defaults.data(forKey: "starfall.game.v1"), Data([1,2,3]))
        store.inviteShower(); presenter.completions[1]()
        let resumed = StarfallExperimentStore(defaults: defaults, arguments: ["--starfalls-seed=999"], presenter: ExperimentRecorder())
        XCTAssertEqual(resumed.game, store.game)
    }

    @MainActor func testCalmChangeSettlesCommittedBoardAndInvalidTapIsFree() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "Starfalls.\(UUID().uuidString)"))
        defer { defaults.removeObject(forKey: StarfallExperimentStore.saveKey) }
        let presenter = ExperimentRecorder()
        let store = StarfallExperimentStore(defaults: defaults, arguments: [], presenter: presenter)
        let empty = store.game
        store.clear(Cell(0, 0))
        XCTAssertEqual(store.game, empty); XCTAssertTrue(presenter.completions.isEmpty)
        store.inviteShower()
        store.setReducedMotion(true)
        XCTAssertTrue(presenter.reduceMotion); XCTAssertFalse(store.busy)
        XCTAssertEqual(presenter.lastRendered, store.game)
        presenter.completions[0]()
        XCTAssertEqual(store.game.turns, 1)
    }
}

@MainActor private final class ExperimentRecorder: ExperimentPresenting {
    var reduceMotion = false
    var lastRendered: StarfallExperiment?
    var completions: [() -> Void] = []
    func render(_ game: StarfallExperiment) { lastRendered = game }
    func animate(_ turn: StarfallExperimentTurn, from old: StarfallExperiment,
                 to game: StarfallExperiment, completion: @escaping () -> Void) {
        completions.append(completion)
    }
}
