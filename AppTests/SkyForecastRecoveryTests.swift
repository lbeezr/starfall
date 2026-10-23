import XCTest
import StarfallCore
@testable import Starfall

final class SkyForecastRecoveryTests: XCTestCase {
    private func crowded(_ challenge: StarfallChallenge) throws -> FallingSky {
        var game = FallingSky.freshChallenge(challenge)
        for _ in 0..<4 { _ = try XCTUnwrap(game.letStarsFall()) }
        XCTAssertTrue(game.isValidSave)
        return game
    }

    private func fullColumns(_ game: FallingSky) -> Set<Int> {
        Set((0..<7).filter { SkyBoardSettling.height(game.board, column: $0) == 7 }.map { $0 + 1 })
    }

    @MainActor func testLanternRecoveryKeepsTheAnnouncedDestinationsThroughPresentationAndRestore() throws {
        let opening = try crowded(.firstLight)
        let preview = opening.incoming
        XCTAssertEqual(preview.map(\.id), Array(20...24))
        XCTAssertEqual(SkyForecastSnapshot(forecast: preview).entries.map(\.column), [7, 6, 1, 2, 4])
        XCTAssertEqual(fullColumns(opening), [2])

        let suite = "Starfall.ForecastRecovery.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(opening), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: SkyFeedbackRecorder())
        defer { store.setSuspended(true) }
        store.setSuspended(false)
        XCTAssertEqual(store.game, opening)
        XCTAssertTrue(store.isPaused)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0,1), Cell(0,2)), snapshot: store.game,
                                             generation: store.constellationInputGeneration))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game.displayScore, 5_000)
        XCTAssertEqual(SkyBoardSettling.height(store.game.board, column: 1), 3)
        XCTAssertEqual(store.forecast, preview)
        XCTAssertEqual(store.game.incoming, preview)
        XCTAssertEqual(SkyForecastSnapshot(forecast: store.forecast), SkyForecastSnapshot(forecast: preview))
        let clearSave = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(clearSave), store.game)
        presenter.finish()
        XCTAssertFalse(store.busy)

        var expected = store.game
        let actualShower = try XCTUnwrap(expected.letStarsFall())
        store.callShower()
        XCTAssertEqual(store.game, expected)
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.pending?.forecast, preview)
        XCTAssertEqual(store.pending?.arrivals.map(\.star), preview)
        XCTAssertEqual(actualShower.arrivals.map(\.star), preview)
        XCTAssertNil(actualShower.blockedColumn)
        XCTAssertEqual(store.forecast, preview, "The in-flight shower keeps its own announced destinations")
        XCTAssertNotEqual(store.game.incoming, preview, "Core has already committed the following forecast")
        let committedSave = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(committedSave), expected)
        presenter.finish()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.forecast, expected.incoming)
        XCTAssertEqual(SkyForecastSnapshot(forecast: store.forecast).entries.map(\.id), Array(25...29))

        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                       clock: ManualRainClock(), feedback: SkyFeedbackRecorder())
        defer { restored.setSuspended(true) }
        restored.setSuspended(false)
        XCTAssertEqual(restored.game, expected)
        XCTAssertEqual(restored.forecast, expected.incoming)
        XCTAssertNil(restored.pending)
        XCTAssertTrue(restored.isPaused)
    }

    func testAnUnproductiveLanternExchangeLeavesTheSameFourthArrivalBlocked() throws {
        let opening = try crowded(.firstLight)
        let preview = opening.incoming
        var missed = opening
        let setup = try XCTUnwrap(missed.nudge(from: Cell(1,0), to: Cell(1,1)))
        XCTAssertNotEqual(missed.board, opening.board)
        XCTAssertTrue(setup.resolutionPhases.isEmpty)
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertEqual(missed.incoming, preview)
        XCTAssertEqual(fullColumns(missed), [2])
        XCTAssertEqual(missed.gem(at: Cell(6,1))?.kind, .aqua)
        XCTAssertEqual(preview[3].id, 23)
        XCTAssertEqual(preview[3].kind, .rose)
        XCTAssertEqual(SkyForecastSnapshot(forecast: preview).entries[3].column, 2)

        let loss = try XCTUnwrap(missed.letStarsFall())
        XCTAssertEqual(loss.forecast, preview)
        XCTAssertEqual(loss.arrivals.map(\.star.id), [20, 21, 22])
        XCTAssertEqual(loss.blockedColumn, 1)
        XCTAssertEqual(missed.outcome, .lost)
        XCTAssertEqual(missed.displayScore, 0)
        XCTAssertEqual(missed.incoming, preview)
        XCTAssertTrue(missed.isValidSave)
        XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(missed)), missed)

        var idle = opening
        let unchanged = try XCTUnwrap(idle.letStarsFall())
        XCTAssertEqual(unchanged.blockedColumn, loss.blockedColumn)
        XCTAssertEqual(unchanged.arrivals.map(\.star), loss.arrivals.map(\.star))
        XCTAssertEqual(idle.outcome, .lost)
    }

    func testAColumnDestinationCanAcceptMatchingTopGrowthWhileAlreadyFull() throws {
        var game = FallingSky.freshSurvival(seed: 14)
        for _ in 0..<18 { _ = try XCTUnwrap(game.letStarsFall()) }
        XCTAssertFalse(game.isOver)
        XCTAssertTrue(fullColumns(game).contains(1))
        let before = game, forecast = game.incoming
        let destinations = SkyForecastSnapshot(forecast: forecast)
        let turn = try XCTUnwrap(game.letStarsFall())
        let growth = try XCTUnwrap(turn.arrivals.first { $0.grew && $0.cell == Cell(6,0) })
        let entry = try XCTUnwrap(destinations.entries.first { $0.id == growth.star.id })
        XCTAssertEqual(entry.column, 1)
        XCTAssertEqual(entry.family, before.gem(at: Cell(6,0))?.identity)
        XCTAssertEqual(before.gem(at: Cell(6,0))?.grown, false)
        XCTAssertEqual(game.gem(at: Cell(6,0))?.grown, true)
        XCTAssertEqual(turn.forecast, forecast)
        XCTAssertNil(turn.blockedColumn)
        XCTAssertFalse(game.isOver, "Receiving an arrival in a full column does not guarantee a loss")
        XCTAssertEqual(game.occupiedCount, before.occupiedCount)
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 0), 7)
        XCTAssertTrue(game.isValidSave)
    }

    func testRibbonPreviewIdentifiesWhichFullColumnReceivesTheNextShower() throws {
        var game = try crowded(.ribbonCrossing)
        let preview = game.incoming
        let destinations = SkyForecastSnapshot(forecast: preview)
        XCTAssertEqual(fullColumns(game), [1, 2, 4])
        XCTAssertEqual(destinations.entries.map(\.id), Array(20...24))
        XCTAssertEqual(destinations.entries.map(\.column), [3, 5, 7, 2, 6])
        let receiving = Set(destinations.entries.map(\.column))
        XCTAssertEqual(fullColumns(game).intersection(receiving), [2])
        XCTAssertEqual(fullColumns(game).subtracting(receiving), [1, 4])

        let clear = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
        XCTAssertEqual(clear.displayAward, 50_000)
        XCTAssertTrue(fullColumns(game).isEmpty)
        XCTAssertEqual(game.incoming, preview)
        XCTAssertEqual(SkyForecastSnapshot(forecast: game.incoming), destinations)
        let arrivals = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(arrivals.forecast, preview)
        XCTAssertEqual(arrivals.arrivals.map(\.star), preview)
        XCTAssertNil(arrivals.blockedColumn)
        XCTAssertNotEqual(game.outcome, .lost)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
    }
}
