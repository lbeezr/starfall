import XCTest
@testable import StarfallCore

final class FullBoardChoiceTests: XCTestCase {
    private func revisionFive() -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    private func exchange(_ from: Int, _ to: Int) -> FallingSkyTurn.Exchange {
        .init(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7))
    }

    @discardableResult private func play(_ from: Int, _ to: Int, in game: inout FallingSky) throws -> FallingSkyTurn {
        let move = exchange(from, to)
        return try XCTUnwrap(game.nudge(from: move.from, to: move.to))
    }

    private func afterOpening() throws -> FallingSky {
        var game = revisionFive()
        try play(8, 9, in: &game)
        XCTAssertEqual(game.displayScore, 66_000)
        return game
    }

    private func awkwardBoard() throws -> FallingSky {
        var game = try afterOpening()
        for (from, to) in [(3, 10), (5, 12), (33, 40), (24, 31)] {
            try play(from, to, in: &game)
        }
        XCTAssertEqual(game.displayScore, 106_000)
        return game
    }

    private func encoded(_ game: FallingSky) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(game)
    }

    private func scoringExchanges(in game: FallingSky) -> Int {
        var count = 0
        for row in 0..<7 { for column in 0..<7 {
            for to in [Cell(row, column + 1), Cell(row + 1, column)] where to.row < 7 && to.column < 7 {
                var copy = game
                if let turn = copy.nudge(from: Cell(row, column), to: to), turn.displayAward > 0 { count += 1 }
            }
        } }
        return count
    }

    func testOpeningOffersDifferentVisiblePatternsAndEverySuggestedClearIsReal() throws {
        let opening = revisionFive()
        let choices = opening.fullBoardChoices()
        XCTAssertEqual(choices.count, 2)
        XCTAssertEqual(choices[0].exchanges, [exchange(1, 2)])
        XCTAssertEqual(choices[0].recipes.map(\.shape), [.line])
        XCTAssertEqual(choices[1].exchanges, [exchange(5, 12)])
        XCTAssertEqual(choices[1].recipes.map(\.shape), [.square])
        XCTAssertNotEqual(Set(choices[0].recipes.flatMap(\.starIDs)), Set(choices[1].recipes.flatMap(\.starIDs)))
        for choice in choices {
            var branch = opening
            let move = try XCTUnwrap(choice.exchanges.first)
            let turn = try XCTUnwrap(branch.nudge(from: move.from, to: move.to))
            XCTAssertEqual(turn.resolutionPhases.first?.recipes, choice.recipes)
            XCTAssertEqual(turn.resolutionPhases.first?.cleared, choice.cleared)
            XCTAssertEqual(choice.cleared.count, 4)
            XCTAssertTrue(branch.isValidSave)
        }
    }

    func testPostOpeningSquareAndLineLeaveDifferentRewardsAndNextChoices() throws {
        let game = try afterOpening()
        let choices = game.fullBoardChoices()
        XCTAssertEqual(choices.count, 2)
        XCTAssertEqual(choices[0].exchanges, [exchange(3, 10)])
        XCTAssertEqual(choices[0].recipes.map(\.shape), [.square])
        XCTAssertEqual(choices[1].exchanges, [exchange(15, 16)])
        XCTAssertEqual(choices[1].recipes.map(\.shape), [.line])
        var square = game, line = game
        let squareTurn = try play(3, 10, in: &square)
        let lineTurn = try play(15, 16, in: &line)
        XCTAssertEqual(squareTurn.displayAward, 15_000)
        XCTAssertEqual(lineTurn.displayAward, 5_000)
        XCTAssertEqual(squareTurn.resolutionPhases.first?.recipes, choices[0].recipes)
        XCTAssertEqual(lineTurn.resolutionPhases.first?.recipes, choices[1].recipes)
        XCTAssertEqual(scoringExchanges(in: square), 4)
        XCTAssertEqual(scoringExchanges(in: line), 6)
        XCTAssertNotEqual(square.board, line.board)
        XCTAssertTrue(square.isValidSave)
        XCTAssertTrue(line.isValidSave)
    }

    func testAwkwardBoardOffersAFreeArrangementBeforeTheUsefulClear() throws {
        let game = try awkwardBoard()
        XCTAssertEqual(scoringExchanges(in: game), 0)
        let choices = game.fullBoardChoices()
        XCTAssertEqual(choices.count, 1)
        let plan = try XCTUnwrap(choices.first)
        XCTAssertEqual(plan.exchanges, [exchange(1, 2), exchange(8, 15)])
        XCTAssertEqual(plan.recipes.map(\.shape), [.square])
        XCTAssertEqual(plan.cleared.count, 4)
        var branch = game
        let arrangement = try play(1, 2, in: &branch)
        XCTAssertEqual(arrangement.displayAward, 0)
        XCTAssertTrue(arrangement.resolutionPhases.isEmpty)
        XCTAssertEqual(branch.turns, game.turns + 1)
        XCTAssertEqual(branch.occupiedCount, 49)
        XCTAssertFalse(branch.fullBoardChoices().isEmpty)
        let turn = try play(8, 15, in: &branch)
        XCTAssertEqual(turn.resolutionPhases.first?.recipes, plan.recipes)
        XCTAssertEqual(turn.resolutionPhases.first?.cleared, plan.cleared)
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        XCTAssertEqual(turn.displayAward, 5_000)
        XCTAssertEqual(branch.displayScore, 111_000)
        XCTAssertEqual(branch.occupiedCount, 49)
        XCTAssertTrue(branch.isValidSave)
    }

    func testAdviceLeavesEncodedStateRandomContinuationAndReplayUnchanged() throws {
        for game in [revisionFive(), try afterOpening(), try awkwardBoard()] {
            let before = try encoded(game)
            let restored = try JSONDecoder().decode(FallingSky.self, from: before)
            let choices = game.fullBoardChoices()
            XCTAssertEqual(choices, game.fullBoardChoices())
            XCTAssertEqual(choices, restored.fullBoardChoices())
            XCTAssertEqual(try encoded(game), before)
            XCTAssertEqual(game, restored)
            XCTAssertEqual(game.replay(), revisionFive())
            var queried = game, control = restored
            let move = try XCTUnwrap(choices.first?.exchanges.first)
            let actual = try XCTUnwrap(queried.nudge(from: move.from, to: move.to))
            let expected = try XCTUnwrap(control.nudge(from: move.from, to: move.to))
            XCTAssertEqual(actual.resolutionPhases, expected.resolutionPhases)
            XCTAssertEqual(queried, control)
        }
    }

    func testHistoricalAndOtherModesDoNotOfferFullBoardAdvice() {
        XCTAssertTrue(FallingSky.freshSurvival(seed: 42).fullBoardChoices().isEmpty)
        for challenge in StarfallChallenge.allCases {
            XCTAssertTrue(FallingSky.freshChallenge(challenge).fullBoardChoices().isEmpty)
            XCTAssertTrue(FallingSky(challenge: challenge).fullBoardChoices().isEmpty)
        }
    }

    func testBothPostOpeningChoicesPermitCompleteRoundsAndTerminalAdviceStops() throws {
        let routes: [([(Int, Int)], [Int])] = [
            ([(8, 9), (3, 10), (5, 12), (33, 40), (24, 31),
              (22, 23), (23, 24), (28, 29), (36, 37), (32, 39)],
             [66_000, 81_000, 86_000, 91_000, 106_000, 106_000, 121_000, 140_000, 145_000, 150_000]),
            ([(8, 9), (15, 16), (5, 12), (1, 8), (9, 10),
              (17, 24), (1, 8), (25, 32), (23, 30), (32, 33)],
             [66_000, 71_000, 94_000, 109_000, 116_000, 123_000, 132_000, 137_000, 142_000, 155_000])
        ]
        for (route, scores) in routes {
            var game = revisionFive()
            for (index, move) in route.enumerated() {
                let before = game
                XCTAssertFalse(game.fullBoardChoices().isEmpty)
                XCTAssertEqual(game, before)
                try play(move.0, move.1, in: &game)
                XCTAssertEqual(game.displayScore, scores[index])
                XCTAssertEqual(game.occupiedCount, 49)
                XCTAssertTrue(game.isValidSave)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, 10)
            XCTAssertTrue(game.fullBoardChoices().isEmpty)
            let restored = try JSONDecoder().decode(FallingSky.self, from: encoded(game))
            XCTAssertEqual(restored, game)
            XCTAssertEqual(restored.replay(), revisionFive())
            XCTAssertTrue(restored.fullBoardChoices().isEmpty)
        }
    }

    func testNoShortPlanIsAnEmptyResultWithoutRewritingTheBoard() throws {
        // Synthetic valid carrier for the bounded-search boundary, not a
        // claimed reachable opening. No four-star recipe is within two swaps.
        let original = revisionFive()
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded(original)) as? [String: Any])
        var board = try XCTUnwrap(fields["board"] as? [[String: Any]])
        for index in board.indices {
            board[index]["kind"] = Jewel.allCases[(index / 7 + (index % 7) * 2) % 5].rawValue
        }
        fields["board"] = board
        let game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertTrue(game.isValidSave)
        let before = try encoded(game)
        XCTAssertTrue(game.fullBoardChoices().isEmpty)
        XCTAssertEqual(try encoded(game), before)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertFalse(game.isOver)
    }

    func testCancelledAnalysisReturnsNoAdvice() async {
        let game = revisionFive()
        let task = Task.detached {
            withUnsafeCurrentTask { $0?.cancel() }
            return game.fullBoardChoices()
        }
        let choices = await task.value
        XCTAssertTrue(choices.isEmpty)
    }
}
