import XCTest
@testable import StarfallCore

/// One revision-four production-action witness, not a human difficulty or timing claim.
final class StoryMasteryRecoveryWitnessTests: XCTestCase {
    func testLanternRevisionFourWinsWithALaterChainAfterConsumingItsOpeningFollowUp() throws {
        // Each row precedes one unchanged shower, except the final winning row.
        // Six exchanges per shower is this authoring witness's maximum, not a rule.
        let plan: [[(Int, Int)]] = [
            [(1, 2), (10, 17), (16, 15), (7, 8), (12, 19), (1, 2)],
            [(14, 15), (0, 7), (5, 6)],
            [(19, 20), (7, 8), (8, 9), (11, 10), (12, 11), (1, 8)],
            [(26, 27), (16, 17), (0, 1), (7, 8), (8, 9), (5, 6)],
            [(5, 12), (6, 13)],
            [(15, 16), (2, 3), (26, 25), (18, 17), (0, 1)],
            [(9, 10), (2, 9), (1, 8), (14, 15)],
            [(41, 40), (18, 19), (33, 32), (25, 24)],
            [(9, 16), (18, 25), (19, 20), (4, 5)],
            [(34, 41), (18, 25), (26, 25), (27, 26), (4, 5)],
            [(29, 28), (24, 25), (30, 31), (31, 32), (25, 26)],
            [(18, 19), (9, 10), (22, 23), (7, 8), (13, 12), (0, 7)],
            [(10, 11), (10, 17), (4, 11), (21, 22), (22, 23), (4, 5)],
            [(18, 19), (5, 6), (9, 10), (0, 1), (1, 2), (2, 3)],
            [(1, 2), (3, 10)],
            [(20, 19), (4, 11), (2, 9)]
        ]
        let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 4))
        var game = FallingSky(definition: definition)
        let opening = game
        var actionIndex = 0, swaps = 0
        var firstGrownAction: Int?, firstLaterChainAction: Int?
        var collectedGrown = false, earnedLaterChain = false
        func roundTrip(_ value: FallingSky) throws -> FallingSky {
            XCTAssertTrue(value.isValidSave)
            XCTAssertEqual(value.score + value.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, value.starsLanded)
            let copy = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(value))
            XCTAssertEqual(copy, value)
            XCTAssertTrue(copy.isValidSave)
            return copy
        }
        func commit(_ exchange: (Int, Int)?) throws {
            XCTAssertEqual(game.outcome, .playing)
            let before = game
            var restored = try roundTrip(before)
            let turn: FallingSkyTurn, restoredTurn: FallingSkyTurn
            if let (from, to) = exchange {
                let source = Cell(from / 7, from % 7), target = Cell(to / 7, to % 7)
                turn = try XCTUnwrap(game.nudge(from: source, to: target))
                restoredTurn = try XCTUnwrap(restored.nudge(from: source, to: target))
                XCTAssertEqual(game.incoming, before.incoming)
                XCTAssertEqual(game.turns, before.turns)
                swaps += 1
            } else {
                turn = try XCTUnwrap(game.letStarsFall())
                restoredTurn = try XCTUnwrap(restored.letStarsFall())
                XCTAssertEqual(game.turns, before.turns + 1)
            }
            XCTAssertEqual(restored, game)
            XCTAssertEqual(restoredTurn.resolutionPhases, turn.resolutionPhases)
            XCTAssertEqual(restoredTurn.arrivals.map(\.star), turn.arrivals.map(\.star))
            XCTAssertEqual(restoredTurn.arrivals.map(\.cell), turn.arrivals.map(\.cell))
            XCTAssertEqual(restoredTurn.arrivals.map(\.gem), turn.arrivals.map(\.gem))
            XCTAssertEqual(restoredTurn.arrivals.map(\.grew), turn.arrivals.map(\.grew))
            XCTAssertEqual(turn.forecast, before.incoming)
            XCTAssertEqual(game.displayScore, before.displayScore + turn.displayAward)
            for phase in turn.resolutionPhases {
                XCTAssertEqual(phase.kind, .recipe)
                XCTAssertEqual(phase.recipes, StarRecipe.find(in: phase.before, lineLength: 4))
                XCTAssertEqual(phase.cleared, Set(phase.recipes.flatMap(\.cells)))
                let grown = phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
                    .filter { $0.grown && $0.kind != nil && !$0.isLight && $0.gravityKind == nil }.map(\.id)
                if !grown.isEmpty {
                    collectedGrown = true
                    if firstGrownAction == nil {
                        firstGrownAction = actionIndex
                        XCTAssertEqual(Set(grown), [21])
                        XCTAssertEqual(before.turns, 1)
                    }
                    XCTAssertTrue(Set(grown).isDisjoint(with: phase.settled.compactMap { $0?.id }))
                }
            }
            for (earlier, later) in zip(turn.resolutionPhases, turn.resolutionPhases.dropFirst()) {
                XCTAssertEqual(later.comboDepth, earlier.comboDepth + 1)
                XCTAssertEqual(later.before, earlier.settled)
                let spent = Set(earlier.cleared.compactMap { earlier.before[$0.row * 7 + $0.column]?.id })
                let ids = Set(later.cleared.compactMap { later.before[$0.row * 7 + $0.column]?.id })
                XCTAssertFalse(spent.isEmpty || ids.isEmpty)
                XCTAssertTrue(spent.isDisjoint(with: ids))
                XCTAssertTrue(ids.isSubset(of: Set(earlier.settled.compactMap { $0?.id })))
                XCTAssertTrue(ids.contains { id in
                    earlier.before.firstIndex(where: { $0?.id == id })
                        != later.before.firstIndex(where: { $0?.id == id })
                })
                for recipe in later.recipes {
                    XCTAssertFalse(earlier.recipes.contains { $0.starIDs == recipe.starIDs })
                }
                if before.turns >= 1 {
                    earnedLaterChain = true
                    if firstLaterChainAction == nil {
                        firstLaterChainAction = actionIndex
                        XCTAssertEqual(before.turns, 1)
                        XCTAssertEqual(before.displayScore, 11_000)
                        XCTAssertEqual(game.displayScore, 27_000)
                    }
                }
            }
            if actionIndex == 0 {
                XCTAssertEqual(turn.resolutionPhases.count, 1)
                XCTAssertEqual(turn.displayAward, 5_000)
                let phase = try XCTUnwrap(turn.resolutionPhases.first)
                let consumed = Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id })
                XCTAssertEqual(consumed, [2, 8, 15, 22])
                XCTAssertTrue(consumed.isDisjoint(with: game.board.compactMap { $0?.id }))
            }
            if game.outcome == .won {
                XCTAssertEqual(actionIndex, 87)
                XCTAssertEqual(before.displayScore, 140_000)
                XCTAssertEqual(turn.resolutionPhases.last?.settled, game.board)
                let winningGrown = turn.resolutionPhases.flatMap { phase in
                    phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }.filter(\.grown).map(\.id)
                }
                XCTAssertEqual(winningGrown, [29], "The complete earned winning transaction includes its grown collection")
            }
            _ = try roundTrip(game)
            XCTAssertTrue(Set([2, 8, 15, 22]).isDisjoint(with: game.board.compactMap { $0?.id }),
                          "The declined opening's consumed ingredients never return")
            actionIndex += 1
        }
        for (showersBefore, exchanges) in plan.enumerated() {
            XCTAssertEqual(game.turns, showersBefore)
            XCTAssertLessThanOrEqual(exchanges.count, 6)
            for exchange in exchanges { try commit(exchange) }
            if showersBefore < plan.count - 1 { try commit(nil) }
        }
        XCTAssertEqual(actionIndex, 88)
        XCTAssertEqual(swaps, 73)
        XCTAssertEqual(game.turns, 15)
        XCTAssertEqual(firstGrownAction, 7)
        XCTAssertEqual(firstLaterChainAction, 8)
        XCTAssertTrue(collectedGrown && earnedLaterChain)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, 150_000)
        let won = game
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertNil(game.letStarsFall())
        XCTAssertEqual(game, won)
        XCTAssertEqual(game.replay(), opening)
    }
}
