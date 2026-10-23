import XCTest
@testable import StarfallCore

final class FullBoardLanternTests: XCTestCase {
    private func revisionFive() -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        let copy = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(copy, game)
        XCTAssertTrue(copy.isValidSave)
        return copy
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    private var exchanges: [(Cell, Cell)] {
        (0..<7).flatMap { row in
            (0..<7).flatMap { column -> [(Cell, Cell)] in
                let from = Cell(row, column)
                return [(Cell(row, column + 1)), Cell(row + 1, column)].filter {
                    $0.row < 7 && $0.column < 7
                }.map { (from, $0) }
            }
        }
    }

    func testExplicitComparisonKeepsCurrentAndHistoricalSkyDefinitionsSeparate() throws {
        let game = revisionFive()
        XCTAssertTrue(game.usesFullBoardRefill)
        XCTAssertEqual(game.challenge, .firstLight)
        XCTAssertEqual(game.challengeRevision, 5)
        XCTAssertEqual(game.displayTarget, 150_000)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
        XCTAssertEqual(Set(game.board.compactMap { $0?.id }), Set(0..<49))
        XCTAssertTrue(game.incoming.isEmpty)
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertFalse(game.hasCriticalMass)
        XCTAssertEqual(try restored(game).replay(), game)
        XCTAssertEqual(StoryChallengeDefinition.currentRevision, 4)
        XCTAssertEqual(StoryChallengeDefinition.maximumSupportedRevision, 6)
        XCTAssertNil(StoryChallengeDefinition(.ribbonCrossing, revision: 5))
        XCTAssertNil(StoryChallengeDefinition(.firstLight, revision: 7))
        for challenge in StarfallChallenge.allCases {
            XCTAssertFalse(FallingSky.freshChallenge(challenge).usesFullBoardRefill)
            XCTAssertFalse(FallingSky(challenge: challenge).usesFullBoardRefill)
        }
    }

    func testComparisonIgnoresShowersManualClearsAndInvalidExchangesWithoutMutation() {
        var game = revisionFive()
        let original = game
        for _ in 0..<20 { XCTAssertNil(game.letStarsFall()) }
        XCTAssertNil(game.clear(Cell(0, 0)))
        XCTAssertNil(game.clearConstellation([Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1), Cell(2, 0)]))
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(1, 1)))
        XCTAssertNil(game.nudge(from: Cell(-1, 0), to: Cell(0, 0)))
        XCTAssertEqual(game, original)
    }

    func testSetupAndSameFamilyExchangesKeepAFullBoardAndCountOnlyCommittedMoves() throws {
        var game = revisionFive()
        let original = game
        let turn = try XCTUnwrap(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertTrue(turn.resolutionPhases.isEmpty)
        XCTAssertEqual(turn.collected, 0)
        XCTAssertEqual(game.turns, 1)
        XCTAssertEqual(game.starsLanded, original.starsLanded)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertEqual(game.gem(at: Cell(0, 0))?.id, original.gem(at: Cell(0, 1))?.id)
        XCTAssertEqual(game.gem(at: Cell(0, 1))?.id, original.gem(at: Cell(0, 0))?.id)
        XCTAssertEqual(try restored(game).replay(), original)
        var nonScoring = original
        let setup = try XCTUnwrap(exchanges.first { from, to in
            guard original.gem(at: from)?.kind != original.gem(at: to)?.kind else { return false }
            var candidate = original
            return candidate.nudge(from: from, to: to)?.collected == 0
        })
        XCTAssertNotNil(nonScoring.nudge(from: setup.0, to: setup.1))
        XCTAssertEqual(nonScoring.turns, 1)
        XCTAssertEqual(nonScoring.occupiedCount, 49)
        XCTAssertEqual(nonScoring.displayScore, 0)
        _ = try restored(nonScoring)
    }

    func testOpeningSquareCommitsClearSettleRefillAndActualCascades() throws {
        var game = revisionFive()
        let opening = game
        var copy = try restored(game)
        let turn = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        let copiedTurn = try XCTUnwrap(copy.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(copiedTurn.resolutionPhases, turn.resolutionPhases)
        XCTAssertEqual(copy, game)
        XCTAssertEqual(turn.resolutionPhases.count, 3)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000, 51_000])
        XCTAssertEqual(turn.resolutionPhases.first?.recipes.first?.shape, .square)
        XCTAssertLessThanOrEqual(turn.resolutionPhases.count, FullBoardLanternResolution.maximumPhases)
        XCTAssertEqual(turn.collected, turn.resolutionPhases.reduce(0) { $0 + $1.award.baseLight })
        XCTAssertEqual(turn.displayAward, turn.resolutionPhases.reduce(0) { $0 + $1.award.displayPoints })
        XCTAssertEqual(game.displayScore, turn.displayAward)
        XCTAssertEqual(game.turns, 1)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.incoming.isEmpty)
        XCTAssertEqual(game.starsLanded, 49 + game.score)
        var spent: Set<Int> = [], supplied: Set<Int> = []
        for (index, phase) in turn.resolutionPhases.enumerated() {
            XCTAssertEqual(phase.comboDepth, index + 1)
            XCTAssertEqual(phase.before.compactMap { $0 }.count, 49)
            let clearedIDs = Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id })
            XCTAssertTrue(spent.isDisjoint(with: clearedIDs))
            spent.formUnion(clearedIDs)
            XCTAssertEqual(clearedIDs, Set(phase.recipes.flatMap(\.starIDs)))
            XCTAssertEqual(phase.refillArrivals.count, phase.cleared.count)
            XCTAssertEqual(phase.refilled.compactMap { $0 }.count, 49)
            XCTAssertEqual(Set(phase.settled.compactMap { $0?.id }), Set(phase.before.compactMap { $0?.id }).subtracting(clearedIDs))
            for arrival in phase.refillArrivals {
                XCTAssertFalse(arrival.grew)
                XCTAssertFalse(arrival.gem.grown)
                XCTAssertEqual(arrival.star.id, arrival.gem.id)
                XCTAssertEqual(arrival.star.kind, arrival.gem.kind)
                XCTAssertEqual(arrival.star.column, arrival.cell.column)
                XCTAssertNil(phase.settled[arrival.cell.row * 7 + arrival.cell.column])
                XCTAssertEqual(phase.refilled[arrival.cell.row * 7 + arrival.cell.column], arrival.gem)
                XCTAssertTrue(supplied.insert(arrival.gem.id).inserted)
                XCTAssertGreaterThanOrEqual(arrival.gem.id, 49)
            }
            if index > 0 { XCTAssertEqual(phase.before, turn.resolutionPhases[index - 1].refilled) }
        }
        XCTAssertEqual(game.board, turn.resolutionPhases.last?.refilled)
        XCTAssertEqual(supplied.count, game.score)
        XCTAssertEqual(try restored(game).replay(), opening)
    }

    func testEveryOpeningExchangeRestoresItsExactRefillReceiptsAndStableBoard() throws {
        let opening = revisionFive()
        for (from, to) in exchanges {
            var game = opening, copy = try restored(opening)
            let turn = try XCTUnwrap(game.nudge(from: from, to: to))
            let copied = try XCTUnwrap(copy.nudge(from: from, to: to))
            XCTAssertEqual(turn.resolutionPhases, copied.resolutionPhases)
            XCTAssertEqual(game, copy)
            XCTAssertEqual(game.occupiedCount, 49)
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertEqual(game.starsLanded, game.score + 49)
            _ = try restored(game)
        }
    }

    func testBoundedStabilizationAwardsEverySurvivorPhaseAndPreservesTheSurvivors() throws {
        let opening = revisionFive()
        var board = opening.board
        board.swapAt(8, 9)
        var random = SeededRandom(seed: opening.seed), nextID = 49
        let phases = FullBoardLanternResolution.resolve(board, random: &random, nextID: &nextID, maximumOrdinaryRefills: 0)
        XCTAssertGreaterThanOrEqual(phases.count, 2)
        XCTAssertTrue(phases.dropLast().allSatisfy { $0.refillArrivals.isEmpty })
        let last = try XCTUnwrap(phases.last)
        XCTAssertFalse(last.refillArrivals.isEmpty)
        XCTAssertEqual(last.refilled.compactMap { $0 }.count, 49)
        XCTAssertTrue(StarRecipe.find(in: last.refilled, lineLength: 4).isEmpty)
        XCTAssertEqual(phases.reduce(0) { $0 + $1.award.baseLight }, nextID - 49)
        for (earlier, later) in zip(phases, phases.dropFirst()) { XCTAssertEqual(earlier.refilled, later.before) }
        XCTAssertEqual(Set(last.refilled.compactMap { $0?.id }).intersection(0..<49), Set(last.settled.compactMap { $0?.id }))
        var expectedRandom = SeededRandom(seed: opening.seed)
        for _ in 49..<nextID { _ = expectedRandom.next() }
        XCTAssertEqual(random, expectedRandom)
        XCTAssertLessThanOrEqual(phases.count, SkyRecipeResolution.maximumPhases)
    }

    func testStabilizationStillAwardsARecipeMadeEntirelyByTheLastOrdinaryRefill() throws {
        var board = revisionFive().board
        board.swapAt(8, 9)
        // This supply's first four stars are rose, completing the top-left
        // square after the initiating square's survivors settle.
        var random = SeededRandom(seed: 15), nextID = 49
        let phases = FullBoardLanternResolution.resolve(board, random: &random, nextID: &nextID, maximumOrdinaryRefills: 1)
        XCTAssertGreaterThanOrEqual(phases.count, 2)
        XCTAssertEqual(phases[0].refillArrivals.count, 4)
        XCTAssertTrue(phases[1].recipes.contains { $0.starIDs.allSatisfy { $0 >= 49 } })
        XCTAssertTrue(phases.dropFirst().dropLast().allSatisfy { $0.refillArrivals.isEmpty })
        let final = try XCTUnwrap(phases.last?.refilled)
        XCTAssertEqual(final.compactMap { $0 }.count, 49)
        XCTAssertTrue(StarRecipe.find(in: final, lineLength: 4).isEmpty)
        XCTAssertEqual(phases.reduce(0) { $0 + $1.award.baseLight }, nextID - 49)
        XCTAssertLessThanOrEqual(phases.count, 1 + SkyRecipeResolution.maximumPhases)
    }

    func testStabilizationCanSpendAndRefillAllFortyNineDistinctStars() throws {
        let board: [StarfallGem?] = (0..<49).map { StarfallGem(id: $0, kind: .aqua) }
        var random = SeededRandom(seed: 42), nextID = 49
        let phases = FullBoardLanternResolution.resolve(board, random: &random, nextID: &nextID, maximumOrdinaryRefills: 0)
        let phase = try XCTUnwrap(phases.first)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phase.cleared.count, 49)
        XCTAssertEqual(phase.award.displayPoints, 95_000)
        XCTAssertTrue(phase.settled.allSatisfy { $0 == nil })
        XCTAssertEqual(phase.refillArrivals.count, 49)
        XCTAssertEqual(Set(phase.refilled.compactMap { $0?.id }), Set(49..<98))
        XCTAssertTrue(StarRecipe.find(in: phase.refilled, lineLength: 4).isEmpty)
        XCTAssertEqual(nextID, 98)
    }

    func testComparisonSaveRejectsMissingForgedOrForeignSupplyAndRNG() throws {
        var played = revisionFive()
        _ = played.nudge(from: Cell(1, 1), to: Cell(1, 2))
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0.removeValue(forKey: "fullBoardSupply") },
            { $0["fullBoardSupply"] = ["suppliedStars": 0, "refillingPhases": 0] },
            { $0["fullBoardSupply"] = ["suppliedStars": Int.max, "refillingPhases": Int.max] },
            { $0["fullBoardSupply"] = ["suppliedStars": played.score, "refillingPhases": 0] },
            { $0["turns"] = 0 },
            { $0["turns"] = Int.max },
            { $0["score"] = Int.max },
            { $0["starsLanded"] = played.starsLanded + 1 },
            { $0["seed"] = 43 },
            { $0["random"] = ["state": 42] },
            { $0["incoming"] = [["id": 0, "column": 0, "kind": 0]] },
            { $0["blockedColumn"] = 0 },
            { $0["savedChallengeRevision"] = 4 },
            { $0["savedChallengeRevision"] = 7 },
            { $0["challenge"] = "ribbonCrossing" },
            { fields in var board = fields["board"] as! [[String: Any]]; board[0]["grown"] = true; fields["board"] = board },
            { fields in var board = fields["board"] as! [[String: Any]]; board[0]["id"] = board[1]["id"]; fields["board"] = board },
            { fields in var board = fields["board"] as! [Any]; board[0] = NSNull(); fields["board"] = board }
        ]
        for (index, mutation) in mutations.enumerated() {
            let invalid = try changed(played, mutation)
            _ = invalid.displayScore
            XCTAssertFalse(invalid.isValidSave, "Mutation \(index)")
        }
        let foreignSupply = try changed(FallingSky.freshChallenge(.firstLight)) {
            $0["fullBoardSupply"] = ["suppliedStars": 0, "refillingPhases": 0]
        }
        XCTAssertFalse(foreignSupply.isValidSave)
    }

    func testCorruptedScalarBoundsRejectBeforeShowerAndSupplyDerivation() throws {
        for game in [revisionFive(), FallingSky.freshChallenge(.firstLight),
                     FallingSky(challenge: .firstLight), FallingSky.freshSurvival(seed: 42)] {
            for value in [Int.min, -1, Int.max] {
                XCTAssertFalse(try changed(game) { $0["turns"] = value }.isValidSave)
            }
            for key in ["score", "starsLanded"] {
                XCTAssertFalse(try changed(game) { $0[key] = -1 }.isValidSave)
            }
        }
    }

    func testFixedTenMoveWinRestoresEveryRefillAndReplaysTheSameVariant() throws {
        let opening = revisionFive()
        var game = opening
        let witness = [(8, 9), (3, 10), (5, 12), (33, 40), (24, 31),
                       (22, 23), (23, 24), (28, 29), (36, 37), (32, 39)]
        let scores = [66_000, 81_000, 86_000, 91_000, 106_000, 106_000, 121_000, 140_000, 145_000, 150_000]
        for (index, indices) in witness.enumerated() {
            let move = (Cell(indices.0 / 7, indices.0 % 7), Cell(indices.1 / 7, indices.1 % 7))
            var copy = try restored(game)
            let turn = try XCTUnwrap(game.nudge(from: move.0, to: move.1))
            let copied = try XCTUnwrap(copy.nudge(from: move.0, to: move.1))
            XCTAssertEqual(turn.resolutionPhases, copied.resolutionPhases)
            XCTAssertEqual(game, copy)
            XCTAssertEqual(game.occupiedCount, 49)
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertEqual(game.displayScore, scores[index])
            XCTAssertEqual(game.turns, index + 1)
            _ = try restored(game)
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.turns, witness.count)
        XCTAssertGreaterThanOrEqual(game.displayScore, 150_000)
        XCTAssertEqual(game.score, 67)
        XCTAssertEqual(game.starsLanded, 116)
        XCTAssertEqual(try restored(game).replay(), opening)
        let finished = game
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertNil(game.letStarsFall())
        XCTAssertEqual(game, finished)
    }
}
