import XCTest
@testable import StarfallCore

/// Production-action witnesses bound reachability and restore determinism.
/// They do not establish human timing, difficulty or enjoyment.
final class StoryFourStarLinePolicyTests: XCTestCase {
    private func witness(for challenge: StarfallChallenge) -> [[(Int, Int)]] {
        if challenge == .firstLight {
            return [
            [(8, 9), (0, 1), (5, 12), (0, 1)],
            [],
            [],
            [(4, 11), (1, 2), (10, 9), (11, 12)],
            [(3, 10), (3, 4), (9, 10), (10, 11)],
            [(17, 18), (3, 4), (5, 6)],
            [(12, 13), (5, 12)],
            [(13, 12), (5, 12), (0, 1), (1, 2)],
            [(4, 5), (1, 8), (21, 22), (8, 15)],
            [(3, 4), (2, 3), (1, 2), (20, 19)],
            [(2, 3), (5, 12), (16, 17)],
            [],
            [(13, 20), (1, 2), (2, 3), (3, 4)],
            [(4, 5), (0, 7), (8, 15), (5, 6)],
            [(3, 10), (5, 6), (1, 2), (2, 3)],
            [(9, 10), (22, 23), (7, 8), (4, 5)],
            [(3, 4), (2, 3), (10, 17), (5, 6)],
            [(4, 5), (1, 2), (2, 3), (6, 13)],
            [(28, 29), (1, 8), (1, 2), (7, 8)],
            [(21, 22), (5, 6), (4, 5), (3, 4)],
            [(2, 3), (1, 2), (12, 19), (3, 4)],
            [(4, 5), (7, 8), (1, 8), (0, 1)],
            [(5, 12), (12, 13), (11, 12)]
            ]
        }
        return [
            [(8, 9), (11, 12), (18, 19), (5, 12)],
            [],
            [],
            [(7, 8), (10, 17), (9, 10), (7, 8)],
            [(10, 9), (21, 22), (15, 16), (7, 8)],
            [(4, 5), (6, 13), (13, 20), (19, 20)],
            [(10, 11), (11, 12), (14, 15), (8, 9)],
            [(2, 9)],
            [(12, 13), (11, 12), (11, 10), (7, 14)],
            [(2, 3), (1, 2), (1, 2), (7, 8)],
            [(3, 4), (1, 8), (11, 12), (13, 20)],
            [(25, 24), (3, 4), (4, 5), (18, 17)],
            [(3, 10)],
            [(8, 9), (10, 11), (6, 13), (0, 1)],
            [(2, 3), (1, 2), (0, 1), (0, 7)],
            [(5, 12), (3, 10), (3, 4), (12, 13)],
            [],
            [(27, 26), (5, 12)],
            [(8, 15), (7, 8), (9, 10), (8, 9)],
            [(7, 8), (3, 4), (2, 3), (27, 26)],
            [(19, 18), (4, 11)],
            [(19, 18), (11, 10), (14, 15), (8, 9)],
            [(8, 9), (0, 1), (4, 5), (2, 3)],
            [(27, 26), (26, 25), (4, 11), (13, 20)],
            [(4, 11), (11, 12)],
            [],
            [(5, 6), (0, 1), (2, 3), (1, 2)],
            [(3, 4), (3, 10), (15, 16), (9, 10)],
            [(11, 12), (20, 19), (19, 18), (9, 10)],
            [(9, 10), (11, 18), (6, 13)],
            [(18, 19), (4, 5)],
            [(8, 9), (21, 22), (1, 2), (3, 4)],
            [(2, 3)]
        ]
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        XCTAssertTrue(game.isValidSave)
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(restored, game)
        XCTAssertTrue(restored.isValidSave)
        XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, game.starsLanded)
        return restored
    }

    func testCurrentRecordedPlansWinAndRestoreEveryCommittedSwapAndShower() throws {
        for (challenge, expectedShowers, expectedSwaps, expectedScore) in [
            (StarfallChallenge.firstLight, 22, 75, 151_000),
            (.ribbonCrossing, 32, 98, 220_000)
        ] {
            var game = FallingSky.freshChallenge(challenge)
            let opening = game
            let plan = witness(for: challenge)
            XCTAssertEqual(game.challengeRevision, 4)
            XCTAssertEqual(game.automaticLineLength, 4)
            var swaps = 0, shortLines = 0
            for (showersBefore, exchanges) in plan.enumerated() {
                XCTAssertEqual(game.turns, showersBefore)
                XCTAssertLessThanOrEqual(exchanges.count, 4)
                for (fromIndex, toIndex) in exchanges {
                    let from = Cell(fromIndex / 7, fromIndex % 7)
                    let to = Cell(toIndex / 7, toIndex % 7)
                    let before = game
                    var copy = try restored(game)
                    let turn = try XCTUnwrap(game.nudge(from: from, to: to))
                    let copiedTurn = try XCTUnwrap(copy.nudge(from: from, to: to))
                    XCTAssertEqual(copiedTurn.resolutionPhases, turn.resolutionPhases)
                    XCTAssertEqual(copy, game)
                    XCTAssertEqual(game.incoming, before.incoming)
                    XCTAssertEqual(game.turns, before.turns)
                    XCTAssertEqual(game.displayScore, before.displayScore + turn.displayAward)
                    XCTAssertTrue(turn.resolutionPhases.allSatisfy { $0.kind == .recipe })
                    XCTAssertTrue(game.recipes.isEmpty)
                    shortLines += turn.resolutionPhases.flatMap(\.recipes).filter { $0.shape == .line && $0.cells.count == 4 }.count
                    game = try restored(game)
                    swaps += 1
                }
                if game.isOver {
                    XCTAssertEqual(showersBefore, plan.count - 1)
                    break
                }
                let forecast = game.incoming, points = game.displayScore
                var copy = try restored(game)
                let turn = try XCTUnwrap(game.letStarsFall())
                let copiedTurn = try XCTUnwrap(copy.letStarsFall())
                XCTAssertEqual(copiedTurn.resolutionPhases, turn.resolutionPhases)
                XCTAssertEqual(copiedTurn.arrivals.map(\.star), turn.arrivals.map(\.star))
                XCTAssertEqual(copiedTurn.arrivals.map(\.cell), turn.arrivals.map(\.cell))
                XCTAssertEqual(copiedTurn.arrivals.map(\.gem), turn.arrivals.map(\.gem))
                XCTAssertEqual(copiedTurn.arrivals.map(\.grew), turn.arrivals.map(\.grew))
                XCTAssertEqual(copy, game)
                XCTAssertEqual(turn.forecast, forecast)
                XCTAssertEqual(game.displayScore, points + turn.displayAward)
                game = try restored(game)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, expectedShowers)
            XCTAssertEqual(swaps, expectedSwaps)
            XCTAssertEqual(game.displayScore, expectedScore)
            XCTAssertGreaterThan(shortLines, 0)
            XCTAssertEqual(game.replay(), opening)
        }
    }

    func testRecordedLanternWinningRouteCollectsNaturalGrownStarsAfterItsOpeningChain() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        var actionIndex = 0
        var grownActions: [Int] = [], chainActions: [Int] = []
        var firstGrownIDs: [Int] = []
        func inspect(_ turn: FallingSkyTurn, scoreBefore: Int, showersBefore: Int) {
            var collectedGrown = false
            for phase in turn.resolutionPhases {
                XCTAssertEqual(phase.kind, .recipe)
                let ingredients = phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
                let grown = ingredients.filter {
                    $0.grown && $0.kind != nil && !$0.isLight && $0.gravityKind == nil
                }.map(\.id).sorted()
                XCTAssertEqual(!grown.isEmpty, phase.award.baseLight > phase.award.clearedStarCount,
                               "For this automatic-only colored-star route, physical surplus comes from collected growth")
                XCTAssertTrue(Set(grown).isDisjoint(with: phase.settled.compactMap { $0?.id }))
                if !grown.isEmpty {
                    collectedGrown = true
                    if grownActions.isEmpty {
                        firstGrownIDs = grown
                        XCTAssertEqual(showersBefore, 6)
                        XCTAssertEqual(scoreBefore, 50_000)
                        XCTAssertEqual(game.displayScore, 56_000)
                    }
                }
            }
            if collectedGrown { grownActions.append(actionIndex) }
            if turn.resolutionPhases.count > 1 {
                chainActions.append(actionIndex)
                for (earlier, later) in zip(turn.resolutionPhases, turn.resolutionPhases.dropFirst()) {
                    let earlierIDs = Set(earlier.cleared.compactMap { earlier.before[$0.row * 7 + $0.column]?.id })
                    let laterIDs = Set(later.cleared.compactMap { later.before[$0.row * 7 + $0.column]?.id })
                    XCTAssertEqual(later.before, earlier.settled)
                    XCTAssertEqual(later.comboDepth, earlier.comboDepth + 1)
                    XCTAssertFalse(earlierIDs.isEmpty || laterIDs.isEmpty)
                    XCTAssertTrue(earlierIDs.isDisjoint(with: laterIDs))
                    XCTAssertTrue(laterIDs.isSubset(of: Set(earlier.before.compactMap { $0?.id })),
                                  "The later ingredients already survived in this same transaction")
                    let moved = laterIDs.filter { id in
                        earlier.before.firstIndex(where: { $0?.id == id })
                            != later.before.firstIndex(where: { $0?.id == id })
                    }
                    XCTAssertFalse(moved.isEmpty, "Settling moves ingredients into the later recipe")
                    for recipe in later.recipes {
                        XCTAssertFalse(earlier.recipes.contains { $0.starIDs == recipe.starIDs },
                                       "A simultaneous ready recipe is not a later survivor-created phase")
                    }
                }
            }
            if actionIndex == 1 {
                XCTAssertEqual(turn.resolutionPhases.count, 1)
                XCTAssertEqual(turn.displayAward, 5_000)
                XCTAssertTrue(turn.resolutionPhases.allSatisfy {
                    $0.award.baseLight == $0.award.clearedStarCount
                }, "The neighboring independent line clear does not collect growth or extend the opening chain")
            }
            if actionIndex == 6 {
                XCTAssertTrue(turn.resolutionPhases.isEmpty)
                XCTAssertEqual(turn.arrivals.filter(\.grew).map { $0.gem.id }, [30])
                XCTAssertTrue(game.board.contains { $0?.id == 30 && $0?.grown == true },
                              "Growing a surviving star does not collect it or qualify goal A")
            }
            actionIndex += 1
        }
        let plan = witness(for: .firstLight)
        for (showersBefore, exchanges) in plan.enumerated() {
            for (from, to) in exchanges {
                let score = game.displayScore
                let turn = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
                inspect(turn, scoreBefore: score, showersBefore: showersBefore)
            }
            if !game.isOver {
                let score = game.displayScore
                let turn = try XCTUnwrap(game.letStarsFall())
                inspect(turn, scoreBefore: score, showersBefore: showersBefore)
            }
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, 151_000)
        XCTAssertEqual(game.turns, 22)
        XCTAssertEqual(grownActions, [22, 36, 40, 51, 55, 57, 76, 85, 91])
        XCTAssertEqual(firstGrownIDs, [30])
        XCTAssertEqual(chainActions, [0], "This recorded route does not prove a later chain after missing its opening")
        let won = game
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertNil(game.letStarsFall())
        XCTAssertEqual(game, won, "Qualification cannot require a surplus action after the earned win")
    }

    func testLanternOpeningCanConsumeItsFollowUpWithoutTakingTheOpeningChain() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(opening.board.compactMap { $0 }.allSatisfy { !$0.grown },
                      "Missing an opening chain is different from missing the first grown-star opportunity")
        var chain = opening
        let chainTurn = try XCTUnwrap(chain.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(chainTurn.resolutionPhases.count, 2)
        let followUp = chainTurn.resolutionPhases[1]
        let followUpIDs = Set(followUp.cleared.compactMap { followUp.before[$0.row * 7 + $0.column]?.id })
        XCTAssertEqual(followUpIDs, [2, 8, 15, 22])
        var declined = opening
        let direct = try XCTUnwrap(declined.nudge(from: Cell(0, 1), to: Cell(0, 2)))
        XCTAssertEqual(direct.resolutionPhases.count, 1)
        XCTAssertEqual(direct.displayAward, 5_000)
        let phase = try XCTUnwrap(direct.resolutionPhases.first)
        XCTAssertEqual(Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id }), followUpIDs)
        XCTAssertTrue(followUpIDs.isDisjoint(with: declined.board.compactMap { $0?.id }),
                      "The alternative consumes the original follow-up; this is not moving and undoing the same opening")
        XCTAssertEqual(try restored(declined), declined)
        XCTAssertEqual(declined.outcome, .playing, "This local contrast makes no claim about an alternate complete win")
    }
}
