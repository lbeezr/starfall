import XCTest
@testable import StarfallCore

final class FullBoardRibbonTests: XCTestCase {
    private let survivorRoute = [(8,9), (11,12), (31,38), (17,24), (9,16), (9,10), (1,8),
                                 (1,2), (1,8), (9,10), (10,11), (22,29), (2,3), (2,9),
                                 (1,8), (37,38), (2,3), (16,17)]
    private let survivorScores = [30_000, 35_000, 40_000, 45_000, 50_000, 65_000, 80_000,
                                  80_000, 85_000, 85_000, 90_000, 179_000, 179_000, 184_000,
                                  199_000, 214_000, 214_000, 229_000]
    private let lineRoute = [(1,2), (7,8), (11,12), (30,37), (8,9), (36,37), (39,40), (32,33),
                             (0,1), (1,8), (43,44), (36,37), (4,5), (3,4), (19,20), (2,9),
                             (2,3), (17,24), (1,8), (8,9), (8,15), (38,45), (2,9), (9,16),
                             (3,10), (9,10), (14,15), (26,33), (31,32), (12,19), (18,25),
                             (14,21), (32,33), (16,23)]
    private let lineScores = [5_000, 28_000, 33_000, 71_000, 76_000, 83_000, 88_000, 93_000,
                              93_000, 98_000, 103_000, 110_000, 110_000, 115_000, 120_000, 120_000,
                              125_000, 130_000, 130_000, 135_000, 140_000, 145_000, 145_000, 150_000,
                              155_000, 160_000, 165_000, 170_000, 175_000, 175_000, 180_000,
                              195_000, 218_000, 223_000]

    @discardableResult private func play(_ move: (Int, Int), in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(move.0 / 7, move.0 % 7), to: Cell(move.1 / 7, move.1 % 7)))
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        let copy = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(copy, game)
        XCTAssertTrue(copy.isValidSave)
        return copy
    }

    private func run(_ route: [(Int, Int)], scores: [Int]) throws -> FallingSky {
        var game = FallingSky.fullBoardRibbon()
        for (index, move) in route.enumerated() {
            var copy = try restored(game)
            let turn = try play(move, in: &game)
            let repeatTurn = try play(move, in: &copy)
            XCTAssertEqual(turn.resolutionPhases, repeatTurn.resolutionPhases)
            XCTAssertEqual(game, copy)
            XCTAssertEqual(game.displayScore, scores[index])
            XCTAssertEqual(game.challengeRevision, 7)
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
            for to in [Cell(row, column + 1), Cell(row + 1, column)] where to.row < 7 && to.column < 7 {
                var copy = game
                if let turn = copy.nudge(from: Cell(row, column), to: to), turn.displayAward > 0 { count += 1 }
            }
        } }
        return count
    }

    func testDefinitionsAdmitOnlyTheirActuallyAuthoredChallengeRevisionPairs() {
        XCTAssertEqual(StoryChallengeDefinition.currentRevision, 4)
        XCTAssertEqual(StoryChallengeDefinition.maximumSupportedRevision, 7)
        for challenge in StarfallChallenge.allCases {
            for revision in 1...7 {
                let expected: Bool
                switch challenge {
                case .firstLight: expected = revision <= 6
                case .ribbonCrossing: expected = revision <= 4 || revision == 7
                case .kiteHarbor, .seedMoon, .silverPools: expected = revision == 4
                default: expected = false
                }
                let definition = StoryChallengeDefinition(challenge, revision: revision)
                XCTAssertEqual(definition != nil, expected, "\(challenge) revision \(revision)")
                if let definition {
                    let refill = (challenge == .firstLight && (5...6).contains(revision))
                        || (challenge == .ribbonCrossing && revision == 7)
                    XCTAssertEqual(definition.usesFullBoardRefill, refill)
                }
            }
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 8))
        }
        XCTAssertEqual(FallingSky.freshChallenge(.ribbonCrossing).challengeRevision, 4)
        XCTAssertFalse(FallingSky.freshChallenge(.ribbonCrossing).usesFullBoardRefill)
        XCTAssertEqual(FallingSky.fullBoardLantern().challengeRevision, 6)
    }

    func testRibbonStartsWithItsOwnFullBoardAndOriginalLowerSurvivorIngredients() throws {
        let game = FallingSky.fullBoardRibbon()
        XCTAssertEqual(game.challenge, .ribbonCrossing)
        XCTAssertEqual(game.challengeRevision, 7)
        XCTAssertTrue(game.usesFullBoardRefill)
        XCTAssertEqual(game.seed, 4_202)
        XCTAssertEqual(game.displayTarget, 220_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<49))
        XCTAssertTrue(game.board.allSatisfy { $0?.grown == false })
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.incoming.isEmpty)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertFalse(game.supportsManualClears)
        let sky = FallingSky.freshChallenge(.ribbonCrossing)
        for index in sky.board.indices where sky.board[index] != nil {
            XCTAssertEqual(game.board[index], sky.board[index])
        }
        XCTAssertNotEqual(game.board, FallingSky.fullBoardLantern().board)
        XCTAssertEqual(try restored(game).replay(), game)
    }

    func testOpeningSquareReleasesThreePhasesMadeEntirelyFromVisibleSurvivors() throws {
        let opening = FallingSky.fullBoardRibbon()
        let visible = Set(opening.board.compactMap { $0?.id })
        var game = opening
        let turn = try play((8,9), in: &game)
        XCTAssertEqual(turn.displayAward, 30_000)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000, 15_000])
        XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), [1, 2, 3])
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.square], [.square], [.square]])
        let ingredients: [Set<Int>] = [[0,1,7,9], [2,8,15,22], [3,10,16,23]]
        for (index, phase) in turn.resolutionPhases.enumerated() {
            let ids = Set(phase.recipes.flatMap(\.starIDs))
            XCTAssertEqual(ids, ingredients[index])
            XCTAssertTrue(ids.isSubset(of: visible))
            XCTAssertEqual(phase.refillArrivals.map(\.gem.id), Array((49 + index * 4)..<(53 + index * 4)))
            XCTAssertEqual(phase.refilled.compactMap { $0 }.count, 49)
            if index > 0 {
                let prior = turn.resolutionPhases[index - 1]
                XCTAssertEqual(phase.before, prior.refilled)
                XCTAssertTrue(ids.isSubset(of: Set(prior.settled.compactMap { $0?.id })))
                XCTAssertTrue(ids.isDisjoint(with: Set(prior.refillArrivals.map(\.gem.id))))
            }
        }
        XCTAssertEqual(game.score, 12)
        XCTAssertEqual(game.starsLanded, 61)
        XCTAssertEqual(game.turns, 1)
        XCTAssertTrue(game.isValidSave)
    }

    func testTakingTheLineFirstLeavesDifferentSurvivorsAndMoreImmediateChoices() throws {
        let opening = FallingSky.fullBoardRibbon()
        let plans = opening.fullBoardChoices()
        XCTAssertEqual(plans.map { $0.recipes.map(\.shape) }, [[.line], [.square]])
        var line = opening, squares = opening
        let immediate = try play((1,2), in: &line)
        let sequence = try play((8,9), in: &squares)
        XCTAssertEqual(immediate.displayAward, 5_000)
        XCTAssertEqual(immediate.resolutionPhases.count, 1)
        XCTAssertEqual(immediate.resolutionPhases.first?.recipes, plans[0].recipes)
        XCTAssertEqual(sequence.resolutionPhases.first?.recipes, plans[1].recipes)
        XCTAssertEqual(Set(immediate.resolutionPhases.flatMap(\.recipes).flatMap(\.starIDs)), [2,8,15,22])
        XCTAssertEqual(scoringCount(line), 7)
        XCTAssertEqual(scoringCount(squares), 5)
        XCTAssertNotEqual(line.board, squares.board)
        XCTAssertTrue(line.isValidSave)
        XCTAssertTrue(squares.isValidSave)
    }

    func testBothOpeningDecisionsHaveCompleteRestorableRoundsAndExactReplay() throws {
        for (route, scores, light) in [(survivorRoute, survivorScores, 102), (lineRoute, lineScores, 142)] {
            var game = try run(route, scores: scores)
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, route.count)
            XCTAssertEqual(game.score, light)
            XCTAssertEqual(game.displayScore, scores.last)
            XCTAssertEqual(try restored(game).replay(), FallingSky.fullBoardRibbon())
            let final = game
            XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertNil(game.letStarsFall())
            XCTAssertEqual(game, final)
            XCTAssertTrue(game.fullBoardChoices().isEmpty)
        }
    }

    func testMiddleWithoutAnImmediateClearAllowsPreparationAndContinuedProgress() throws {
        var game = try run(Array(survivorRoute.prefix(7)), scores: Array(survivorScores.prefix(7)))
        XCTAssertEqual(game.displayScore, 80_000)
        XCTAssertEqual(scoringCount(game), 0)
        let plan = try XCTUnwrap(game.fullBoardChoices().first)
        XCTAssertEqual(plan.exchanges, [.init(from: Cell(0,1), to: Cell(0,2)),
                                        .init(from: Cell(0,1), to: Cell(1,1))])
        let setup = try play((1,2), in: &game)
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertEqual(game.displayScore, 80_000)
        XCTAssertTrue(game.isValidSave)
        let clear = try play((1,8), in: &game)
        XCTAssertEqual(clear.resolutionPhases.first?.recipes, plan.recipes)
        XCTAssertEqual(game.displayScore, 85_000)
        XCTAssertEqual(game.turns, 9)
        XCTAssertTrue(game.isValidSave)
    }

    func testFullBoardIgnoresShowersManualClearsAndInvalidExchanges() throws {
        var game = FallingSky.fullBoardRibbon()
        let before = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.clear(Cell(0,0)))
        XCTAssertNil(game.clearConstellation([Cell(0,0), Cell(0,1), Cell(1,1), Cell(1,2), Cell(2,2)]))
        XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(1,1)))
        XCTAssertEqual(game, before)
        XCTAssertEqual(try restored(game), before)
    }

    func testRetainedLanternAndRibbonSkyKeepTheirOriginalRulesAndReplay() throws {
        for (revision, points) in [(5, 66_000), (6, 15_000)] {
            let original = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision)))
            var game = original
            XCTAssertEqual(try play((8,9), in: &game).displayAward, points)
            XCTAssertEqual(try restored(game).replay(), original)
            XCTAssertEqual(game.challengeRevision, revision)
        }
        let opening = FallingSky.freshChallenge(.ribbonCrossing)
        var sky = opening
        XCTAssertEqual(sky.challengeRevision, 4)
        XCTAssertFalse(sky.usesFullBoardRefill)
        XCTAssertEqual(sky.occupiedCount, 25)
        XCTAssertEqual(try play((8,9), in: &sky).displayAward, 30_000)
        let preview = sky.incoming
        let shower = try XCTUnwrap(sky.letStarsFall())
        XCTAssertEqual(shower.forecast, preview)
        XCTAssertEqual(try restored(sky).replay(), opening)
    }

    func testSaveValidationRejectsForeignRevisionsSupplyIdentitiesAndRandomState() throws {
        var game = FallingSky.fullBoardRibbon()
        try play((8,9), in: &game)
        let bytes = try JSONEncoder().encode(game)
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0.removeValue(forKey: "fullBoardSupply") },
            { $0["fullBoardSupply"] = ["suppliedStars": 0, "refillingPhases": 0] },
            { $0["fullBoardSupply"] = ["suppliedStars": game.score, "refillingPhases": 0] },
            { $0["fullBoardSupply"] = ["suppliedStars": Int.max, "refillingPhases": Int.max] },
            { $0.removeValue(forKey: "storyScoreLedger") },
            { $0["storyScoreLedger"] = ["clearCounts": []] },
            { $0["savedChallengeRevision"] = 5 },
            { $0["savedChallengeRevision"] = 6 },
            { $0["savedChallengeRevision"] = 8 },
            { $0["challenge"] = "firstLight" },
            { $0["blockedColumn"] = 0 },
            { $0["seed"] = 42 },
            { $0["random"] = ["state": 42] },
            { $0["turns"] = 0 },
            { $0["starsLanded"] = game.starsLanded + 1 },
            { $0["incoming"] = [["id": 0, "column": 0, "kind": 0]] },
            { fields in var board = fields["board"] as! [[String: Any]]; board[0]["grown"] = true; fields["board"] = board },
            { fields in var board = fields["board"] as! [[String: Any]]; board[0]["id"] = board[1]["id"]; fields["board"] = board }
        ]
        for (index, mutate) in mutations.enumerated() {
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            mutate(&fields)
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave, "Mutation \(index)")
        }
    }

    func testSupplyBudgetUsesTheDefinitionTargetAndPreservesTheLanternBound() throws {
        // Isolate the accounting limit; this fixture does not claim a reachable
        // round history. The same receipt and RNG must differ only by the target.
        let data = Data(#"{"suppliedStars":592,"refillingPhases":148}"#.utf8)
        let supply = try JSONDecoder().decode(FullBoardSupply.self, from: data)
        var ledger = StoryScoreLedger(automaticRecipes: true)
        for _ in 0..<148 { ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4)) }
        var random = SeededRandom(seed: 4_202)
        for _ in 0..<592 { _ = random.next() }
        XCTAssertTrue(supply.isValid(score: 592, turns: 148, ledger: ledger, random: random, seed: 4_202, target: 220_000))
        XCTAssertFalse(supply.isValid(score: 592, turns: 148, ledger: ledger, random: random, seed: 4_202, target: 150_000))
        XCTAssertFalse(supply.isValid(score: 592, turns: 148, ledger: ledger, random: random, seed: 4_202, target: 0))
    }
}
