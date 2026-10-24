import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkyHeadroomFeedbackTests: XCTestCase {
    @discardableResult private func exchange(_ from: Int, _ to: Int,
                                             in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) throws -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        try edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    func testKiteOpeningChoicesNameTheirDifferentColumnsAndActualSpaces() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        var space = opening, points = opening
        let smaller = try exchange(15, 14, in: &space), larger = try exchange(4, 11, in: &points)
        let high = try XCTUnwrap(SkyHeadroomFeedback(turn: smaller, from: opening, to: space))
        let low = try XCTUnwrap(SkyHeadroomFeedback(turn: larger, from: opening, to: points))
        XCTAssertEqual(smaller.displayAward, 5_000)
        XCTAssertEqual(larger.displayAward, 7_000)
        XCTAssertEqual(high.columns.map(\.index), Array(0..<7))
        XCTAssertEqual(high.columns.map(\.beforeSpaces), [1, 1, 4, 4, 5, 5, 5])
        XCTAssertEqual(high.columns.map(\.afterSpaces), [5, 1, 4, 4, 5, 5, 5])
        XCTAssertEqual(high.kind, .opened(columns: [0], spaces: 4))
        XCTAssertEqual(low.columns.map(\.beforeSpaces), high.columns.map(\.beforeSpaces))
        XCTAssertEqual(low.columns.map(\.afterSpaces), [1, 1, 5, 5, 6, 6, 6])
        XCTAssertEqual(low.kind, .opened(columns: [2, 3, 4, 5, 6], spaces: 5))
        XCTAssertEqual(space.incoming, opening.incoming)
        XCTAssertEqual(points.incoming, opening.incoming)
        XCTAssertEqual(space.turns, 0)
        XCTAssertEqual(points.starsLanded, opening.starsLanded)
    }

    func testHighClearReallyRecoversFourSpacesAfterTheSameShowerFillsBothLeftColumns() throws {
        var game = FallingSky.freshChallenge(.kiteHarbor)
        try exchange(4, 11, in: &game)
        XCTAssertNotNil(game.letStarsFall())
        let before = game, forecast = game.incoming
        XCTAssertEqual(SkyPressureCue(game: before)?.columns, [0, 1])
        let turn = try exchange(15, 14, in: &game)
        let feedback = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: before, to: game))
        XCTAssertEqual(turn.displayAward, 5_000)
        XCTAssertEqual(feedback.columns.map(\.beforeSpaces), [0, 0, 5, 4, 6, 5, 6])
        XCTAssertEqual(feedback.columns.map(\.afterSpaces), [4, 0, 5, 4, 6, 5, 6])
        XCTAssertEqual(feedback.kind, .opened(columns: [0], spaces: 4))
        XCTAssertEqual(SkyPressureCue(game: game)?.columns, [1])
        XCTAssertEqual(game.incoming, forecast)
        XCTAssertEqual(game.turns, before.turns)
    }

    func testGrownLightCountsAsOneBodySpaceRatherThanTwoLightUnits() throws {
        let incoming = (0..<3).map { IncomingStar(id: $0, kind: .rose, column: 0) }
        // Existing repeated-column Core fixture, not a naturally reached save claim.
        var game = FallingSky(board: Array(repeating: nil, count: 49), incoming: incoming)
        XCTAssertNotNil(game.letStarsFall())
        let before = game
        XCTAssertTrue(before.isValidSave)
        XCTAssertEqual(before.occupiedCount, 2)
        let turn = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertEqual(turn.collected, 3)
        XCTAssertEqual(turn.cleared.count, 2)
        let feedback = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: before, to: game))
        XCTAssertEqual(feedback.kind, .opened(columns: [0], spaces: 2))
        XCTAssertEqual(feedback.columns[0].beforeSpaces, 5)
        XCTAssertEqual(feedback.columns[0].afterSpaces, 7)
    }

    func testPreparationAndMatchingGrowthWithoutAnyClearHaveNoRoomAward() throws {
        var game = FallingSky.freshChallenge(.frostfruitOrchard)
        let opening = game
        let setup = try exchange(35, 36, in: &game)
        XCTAssertEqual(setup.collected, 0)
        XCTAssertTrue(setup.resolutionPhases.isEmpty)
        XCTAssertNil(SkyHeadroomFeedback(turn: setup, from: opening, to: game))
        let before = game
        let growth = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(growth.arrivals.filter(\.grew).count, 2)
        XCTAssertTrue(growth.resolutionPhases.isEmpty)
        XCTAssertNil(SkyHeadroomFeedback(turn: growth, from: before, to: game))
    }

    func testFullBoardCountsActualReplacementsAndNeverPromisesTemporaryEmptySpaces() throws {
        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        for (opening, expectedStars, expectedPoints) in [
            (FallingSky.fullBoardLantern(), 8, 15_000), (retained, 18, 66_000)
        ] {
            var game = opening
            let turn = try exchange(8, 9, in: &game)
            let feedback = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: opening, to: game))
            XCTAssertEqual(game.displayScore, expectedPoints)
            XCTAssertEqual(turn.resolutionPhases.flatMap(\.refillArrivals).count, expectedStars)
            XCTAssertEqual(feedback.kind, .refilled(stars: expectedStars))
            XCTAssertEqual(feedback.columns.map(\.beforeSpaces), Array(repeating: 0, count: 7))
            XCTAssertEqual(feedback.columns.map(\.afterSpaces), Array(repeating: 0, count: 7))
            XCTAssertEqual(game.occupiedCount, 49)
            XCTAssertTrue(turn.resolutionPhases.contains { $0.settled.contains(nil) },
                          "Temporary vacancies are refilled before the committed board")
            XCTAssertTrue(game.incoming.isEmpty)
            XCTAssertEqual(game.starsLanded - opening.starsLanded, expectedStars)
        }
    }

    func testZeroLightManualHistoryStillReportsAllFourBodiesRemoved() throws {
        let before = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var game = before
        let turn = try XCTUnwrap(game.clear(Cell(0, 1)))
        XCTAssertTrue(before.isValidSave)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(turn.collected, 0)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(turn.cleared.count, 4)
        XCTAssertEqual(game.occupiedCount, 0)
        let feedback = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: before, to: game))
        XCTAssertEqual(feedback.kind, .opened(columns: [0, 1, 2], spaces: 4))
        XCTAssertEqual(feedback.columns.map(\.beforeSpaces), [6, 6, 5, 7, 7, 7, 7])
        XCTAssertEqual(feedback.columns.map(\.afterSpaces), Array(repeating: 7, count: 7))
    }

    func testNamedPositiveColumnGainDoesNotClaimAnOverallNetGainAfterARecipeShower() throws {
        // Labeled invariant-valid current-rule mechanical position, not a route
        // or difficulty claim. All five supplied stars are the actual preview.
        let before = try mixedColumnShowerPosition()
        XCTAssertTrue(before.isValidSave)
        XCTAssertTrue(before.recipes.isEmpty)
        var game = before
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.resolutionPhases.map(\.cleared.count), [4])
        XCTAssertEqual(game.displayScore, 5_000)
        XCTAssertEqual(game.occupiedCount, before.occupiedCount + 1)
        let feedback = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: before, to: game))
        XCTAssertEqual(feedback.columns.map(\.beforeSpaces), [1, 1, 1, 6, 6, 7, 3])
        XCTAssertEqual(feedback.columns.map(\.afterSpaces), [0, 0, 2, 6, 6, 7, 3])
        XCTAssertEqual(feedback.kind, .opened(columns: [2], spaces: 1))
        XCTAssertEqual(feedback.columns.reduce(0) { $0 + $1.afterSpaces - $1.beforeSpaces }, -1)
    }

    func testTerminalWinningClearKeepsOutcomePriorityInsteadOfAddingHeadroomFeedback() throws {
        let before = FallingSky.freshChallenge(.silverPools)
        var game = before
        let turn = try exchange(9, 10, in: &game)
        XCTAssertEqual(turn.displayAward, 19_000)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertFalse(turn.resolutionPhases.isEmpty)
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: before, to: game))
    }

    func testInvalidOrForeignContextsAndNoClearFullBoardSetupCannotProduceFeedback() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        var game = opening
        let turn = try exchange(15, 14, in: &game)
        let corruptBefore = try changed(opening) { $0["starsLanded"] = 0 }
        let corruptAfter = try changed(game) { $0["starsLanded"] = 0 }
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: corruptBefore, to: game))
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: opening, to: corruptAfter))
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: .freshChallenge(.seedMoon), to: game))
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: FallingSky(challenge: .kiteHarbor), to: game))
        var full = FallingSky.fullBoardLantern()
        let fullBefore = full
        let setup = try exchange(0, 1, in: &full)
        XCTAssertTrue(setup.resolutionPhases.isEmpty)
        XCTAssertNil(SkyHeadroomFeedback(turn: setup, from: fullBefore, to: full))
        XCTAssertNil(SkyHeadroomFeedback(turn: turn, from: fullBefore, to: game))
    }

    func testRepeatedFeedbackLeavesEncodedStateAndItsActualFollowingShowerUnchanged() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        var game = opening
        let turn = try exchange(15, 14, in: &game)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let beforeBytes = try encoder.encode(opening), afterBytes = try encoder.encode(game)
        let expected = try XCTUnwrap(SkyHeadroomFeedback(turn: turn, from: opening, to: game))
        for _ in 0..<3 { XCTAssertEqual(SkyHeadroomFeedback(turn: turn, from: opening, to: game), expected) }
        XCTAssertEqual(try encoder.encode(opening), beforeBytes)
        XCTAssertEqual(try encoder.encode(game), afterBytes)
        var restored = try JSONDecoder().decode(FallingSky.self, from: afterBytes)
        let announced = game.incoming
        let shower = try XCTUnwrap(game.letStarsFall()), control = try XCTUnwrap(restored.letStarsFall())
        XCTAssertEqual(shower.forecast, announced)
        XCTAssertEqual(shower.arrivals, control.arrivals)
        XCTAssertEqual(shower.resolutionPhases, control.resolutionPhases)
        XCTAssertEqual(game, restored)
        XCTAssertEqual(game.replay(), opening)
    }

    private func mixedColumnShowerPosition() throws -> FallingSky {
        let colors: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var board = Array<StarfallGem?>(repeating: nil, count: 49), nextID = 0
        for (row, text) in ["RVAAA.M", "VRR...Y", "MYV...R", "YMR...V", "RVV....", "VRR...."].enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                board[row * 7 + column] = .init(id: nextID, kind: colors[symbol]!)
                nextID += 1
            }
        }
        XCTAssertEqual(nextID, 24)
        return try changed(.freshChallenge(.firstLight)) {
            $0["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(board))
        }
    }
}
