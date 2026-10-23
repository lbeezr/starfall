import XCTest
@testable import StarfallCore

final class FullBoardRoundArcTests: XCTestCase {
    private let highRoute = [(27,34), (1,2), (31,32), (12,13), (16,17),
                             (8,9), (11,12), (29,30), (29,36), (9,16)]
    private let highScores = [42_000, 47_000, 54_000, 63_000, 78_000,
                              83_000, 88_000, 93_000, 98_000, 156_000]
    private let lineRoute = [(1,2), (27,34), (5,12), (0,1), (16,17), (24,31), (25,32),
                             (1,2), (1,8), (7,14), (37,44), (2,3), (2,9), (33,34),
                             (18,19), (16,17), (18,25), (18,19), (1,2), (4,11), (32,33)]
    private let lineScores = [27_000, 46_000, 61_000, 66_000, 71_000, 76_000, 91_000,
                              91_000, 96_000, 101_000, 108_000, 108_000, 113_000, 118_000,
                              123_000, 128_000, 133_000, 138_000, 138_000, 143_000, 150_000]

    private func revisionFive() -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    @discardableResult private func play(_ move: (Int, Int), in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(move.0 / 7, move.0 % 7), to: Cell(move.1 / 7, move.1 % 7)))
    }

    private func run(_ moves: [(Int, Int)], scores: [Int]? = nil) throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        for (index, move) in moves.enumerated() {
            var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            let actual = try play(move, in: &game)
            let repeated = try play(move, in: &restored)
            XCTAssertEqual(actual.resolutionPhases, repeated.resolutionPhases)
            XCTAssertEqual(game, restored)
            if let scores { XCTAssertEqual(game.displayScore, scores[index]) }
            XCTAssertEqual(game.challengeRevision, 6)
            XCTAssertEqual(game.occupiedCount, 49)
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertEqual(game.starsLanded, game.score + 49)
            XCTAssertTrue(game.isValidSave)
        }
        return game
    }

    private func scoringCount(_ game: FallingSky) -> Int {
        var count = 0
        for row in 0..<7 { for column in 0..<7 {
            for destination in [Cell(row, column + 1), Cell(row + 1, column)] where destination.row < 7 && destination.column < 7 {
                var next = game
                if let turn = next.nudge(from: Cell(row, column), to: destination), turn.displayAward > 0 { count += 1 }
            }
        } }
        return count
    }

    func testNewFullBoardSelectsSixWhileSkyAndRetainedDefinitionsKeepTheirCapabilities() throws {
        XCTAssertEqual(StoryChallengeDefinition.currentRevision, 4)
        XCTAssertEqual(StoryChallengeDefinition.maximumSupportedRevision, 8)
        XCTAssertEqual(FallingSky.fullBoardLantern().challengeRevision, 6)
        XCTAssertTrue(FallingSky.fullBoardLantern().usesFullBoardRefill)
        XCTAssertEqual(FallingSky.fullBoardLantern(), FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 6))))
        for challenge in StarfallChallenge.allCases {
            XCTAssertFalse(FallingSky.freshChallenge(challenge).usesFullBoardRefill)
            for revision in 1...6 {
                if let definition = StoryChallengeDefinition(challenge, revision: revision) {
                    XCTAssertEqual(definition.usesFullBoardRefill, challenge == .firstLight && revision >= 5)
                    XCTAssertEqual(FallingSky(definition: definition).usesFullBoardRefill, definition.usesFullBoardRefill)
                } else if revision >= 5 {
                    XCTAssertNotEqual(challenge, .firstLight)
                }
            }
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 9))
        }
    }

    func testTwoAuthoredIngredientsChangeWithoutRetuningSupplyTargetOrScoring() throws {
        let old = revisionFive(), current = FallingSky.fullBoardLantern()
        let changed = zip(old.board, current.board).enumerated().compactMap { index, pair in
            pair.0 == pair.1 ? nil : index
        }
        XCTAssertEqual(changed, [29, 37])
        XCTAssertEqual(old.gem(at: Cell(4,1))?.kind, .violet)
        XCTAssertEqual(current.gem(at: Cell(4,1))?.kind, .aqua)
        XCTAssertEqual(old.gem(at: Cell(5,2))?.kind, .mint)
        XCTAssertEqual(current.gem(at: Cell(5,2))?.kind, .rose)
        XCTAssertEqual(old.board.map { $0?.id }, current.board.map { $0?.id })
        XCTAssertEqual(current.seed, 42)
        XCTAssertEqual(current.seed, old.seed)
        XCTAssertEqual(current.balance, old.balance)
        XCTAssertEqual(current.displayTarget, 150_000)
        XCTAssertEqual(current.displayTarget, old.displayTarget)
        XCTAssertEqual(current.occupiedCount, 49)
        XCTAssertEqual(Set(current.board.compactMap { $0?.kind }), Set(Jewel.allCases))
        XCTAssertTrue(current.recipes.isEmpty)
        XCTAssertTrue(current.incoming.isEmpty)
        XCTAssertEqual(current.automaticLineLength, 4)
        XCTAssertFalse(current.supportsManualClears)
        XCTAssertTrue(current.isValidSave)
    }

    func testWelcomingSquareKeepsItsTwoEarnedPhasesAndLeavesTheRestOfTheGoal() throws {
        var current = FallingSky.fullBoardLantern(), retained = revisionFive()
        let turn = try play((8,9), in: &current)
        let historical = try play((8,9), in: &retained)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(turn.resolutionPhases.map(\.cleared.count), [4, 4])
        XCTAssertEqual(turn.displayAward, 15_000)
        XCTAssertEqual(current.displayScore, 15_000)
        XCTAssertEqual(current.score, 8)
        XCTAssertEqual(current.turns, 1)
        XCTAssertEqual(current.outcome, .playing)
        XCTAssertEqual(historical.displayAward, 66_000)
        XCTAssertEqual(historical.resolutionPhases.prefix(2).map(\.recipes), turn.resolutionPhases.map(\.recipes))
        XCTAssertEqual(historical.resolutionPhases.prefix(2).map(\.cleared), turn.resolutionPhases.map(\.cleared))
        XCTAssertEqual(scoringCount(current), 10)
    }

    func testOpeningAdviceStillOffersTwoUsefulVisiblePatterns() throws {
        let opening = FallingSky.fullBoardLantern()
        let choices = opening.fullBoardChoices()
        XCTAssertEqual(choices.count, 2)
        XCTAssertEqual(choices[0].recipes.map(\.shape), [.line])
        XCTAssertEqual(choices[1].recipes.map(\.shape), [.square])
        for (index, points) in [27_000, 5_000].enumerated() {
            var game = opening
            let exchange = try XCTUnwrap(choices[index].exchanges.first)
            let turn = try XCTUnwrap(game.nudge(from: exchange.from, to: exchange.to))
            XCTAssertEqual(turn.displayAward, points)
            XCTAssertEqual(turn.resolutionPhases.first?.recipes, choices[index].recipes)
            XCTAssertTrue(game.isValidSave)
        }
    }

    func testContrastingOpeningRoutesFinishAndReplayTheirOwnCurrentDefinition() throws {
        for (route, scores, physicalLight) in [(highRoute, highScores, 77), (lineRoute, lineScores, 95)] {
            var game = try run(route, scores: scores)
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, route.count)
            XCTAssertEqual(game.score, physicalLight)
            let final = game
            XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertNil(game.letStarsFall())
            XCTAssertEqual(game, final)
            XCTAssertTrue(game.fullBoardChoices().isEmpty)
            XCTAssertEqual(game.replay(), FallingSky.fullBoardLantern())
        }
    }

    func testMiddleChoicesTradeImmediatePointsForMoreReadyContinuations() throws {
        let middle = try run([(1,2), (30,37), (11,18), (26,27), (12,19), (0,1), (31,38), (39,40)],
                             scores: [27_000, 32_000, 41_000, 46_000, 51_000, 56_000, 71_000, 76_000])
        let choices = middle.fullBoardChoices()
        XCTAssertEqual(choices.map { $0.recipes.map(\.shape) }, [[.line], [.cross, .line]])
        var smaller = middle, larger = middle
        let small = try play((4,5), in: &smaller)
        let large = try play((33,40), in: &larger)
        XCTAssertEqual(small.displayAward, 5_000)
        XCTAssertEqual(large.displayAward, 9_000)
        XCTAssertEqual(small.resolutionPhases.first?.recipes, choices[0].recipes)
        XCTAssertEqual(large.resolutionPhases.first?.recipes, choices[1].recipes)
        XCTAssertEqual(scoringCount(smaller), 3)
        XCTAssertEqual(scoringCount(larger), 0)
        XCTAssertEqual(larger.fullBoardChoices().first?.exchanges.count, 2)
    }

    func testARealNoClearMiddlePositionAllowsPreparationAndContinuedProgress() throws {
        var game = try run([(8,9), (27,34), (0,1), (12,13), (16,17)],
                           scores: [15_000, 34_000, 39_000, 44_000, 94_000])
        XCTAssertEqual(scoringCount(game), 0)
        let plan = try XCTUnwrap(game.fullBoardChoices().first)
        XCTAssertEqual(plan.exchanges.count, 2)
        XCTAssertEqual(plan.exchanges[0], .init(from: Cell(0,4), to: Cell(1,4)))
        XCTAssertEqual(plan.exchanges[1], .init(from: Cell(0,5), to: Cell(0,6)))
        let setup = try play((4,11), in: &game)
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertEqual(game.displayScore, 94_000)
        XCTAssertEqual(game.turns, 6)
        XCTAssertTrue(game.isValidSave)
        let clear = try play((5,6), in: &game)
        XCTAssertEqual(clear.resolutionPhases.first?.recipes, plan.recipes)
        XCTAssertEqual(clear.displayAward, 5_000)
        XCTAssertEqual(game.displayScore, 99_000)
        XCTAssertEqual(game.turns, 7)
        XCTAssertTrue(game.isValidSave)
    }

    func testFinalChoiceCanEarnTheFinishImmediatelyOrLeaveAnotherUsefulBoard() throws {
        let before = try run(Array(highRoute.dropLast()), scores: Array(highScores.dropLast()))
        XCTAssertEqual(before.displayScore, 98_000)
        XCTAssertEqual(scoringCount(before), 9)
        let choices = before.fullBoardChoices()
        XCTAssertEqual(choices.map { $0.recipes.map(\.shape) }, [[.square], [.cross, .line, .line]])
        var square = before, finish = before
        let small = try play((3,10), in: &square)
        let earned = try play((9,16), in: &finish)
        XCTAssertEqual(small.displayAward, 5_000)
        XCTAssertEqual(square.displayScore, 103_000)
        XCTAssertEqual(square.outcome, .playing)
        XCTAssertEqual(scoringCount(square), 9)
        XCTAssertEqual(earned.resolutionPhases.map(\.award.displayPoints), [17_000, 26_000, 15_000])
        XCTAssertEqual(earned.resolutionPhases.map(\.cleared.count), [10, 8, 4])
        XCTAssertEqual(earned.displayAward, 58_000)
        XCTAssertEqual(finish.displayScore, 156_000)
        XCTAssertEqual(finish.outcome, .won)
        XCTAssertEqual(finish.turns, 10)
    }

    func testCurrentAndRetainedSavesRestoreTheirExactOpeningAndRejectForeignSupply() throws {
        for original in [revisionFive(), FallingSky.fullBoardLantern()] {
            var game = original
            try play((8,9), in: &game)
            let data = try JSONEncoder().encode(game)
            let restored = try JSONDecoder().decode(FallingSky.self, from: data)
            XCTAssertEqual(restored, game)
            XCTAssertTrue(restored.isValidSave)
            XCTAssertEqual(restored.replay(), original)
            XCTAssertEqual(restored.challengeRevision, original.challengeRevision)
            let mutations: [(inout [String: Any]) -> Void] = [
                { $0.removeValue(forKey: "fullBoardSupply") },
                { $0["blockedColumn"] = 0 },
                { $0["random"] = ["state": 42] },
                { $0["savedChallengeRevision"] = 7 },
                { $0["challenge"] = "ribbonCrossing" }
            ]
            for mutate in mutations {
                var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                mutate(&fields)
                let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
                XCTAssertFalse(invalid.isValidSave)
            }
        }
    }

    func testEveryNewOpeningExchangeRoundTripsItsExactCommittedRefill() throws {
        let opening = FallingSky.fullBoardLantern()
        for row in 0..<7 { for column in 0..<7 {
            for to in [Cell(row, column + 1), Cell(row + 1, column)] where to.row < 7 && to.column < 7 {
                var game = opening
                var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(opening))
                let actual = try XCTUnwrap(game.nudge(from: Cell(row, column), to: to))
                let repeated = try XCTUnwrap(restored.nudge(from: Cell(row, column), to: to))
                XCTAssertEqual(actual.resolutionPhases, repeated.resolutionPhases)
                XCTAssertEqual(game, restored)
                XCTAssertTrue(game.isValidSave)
                XCTAssertEqual(game.replay(), opening)
            }
        } }
    }
}
