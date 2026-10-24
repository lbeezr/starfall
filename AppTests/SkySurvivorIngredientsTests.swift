import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkySurvivorIngredientsTests: XCTestCase {
    @discardableResult private func exchange(_ from: Int, _ to: Int,
                                             in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
    }

    private func board(_ rows: [String], grown: Set<Int> = []) -> [StarfallGem?] {
        let colors: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var result = Array<StarfallGem?>(repeating: nil, count: 49), id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                result[row * 7 + column] = .init(id: id, kind: colors[symbol]!, grown: grown.contains(id))
                id += 1
            }
        }
        return result
    }

    private func assertMovements(_ value: SkySurvivorIngredients,
                                 ids: [Int], from: [Cell], to: [Cell],
                                 file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(value.movements.map(\.id), ids, file: file, line: line)
        XCTAssertEqual(value.movements.map(\.from), from, file: file, line: line)
        XCTAssertEqual(value.movements.map(\.to), to, file: file, line: line)
        XCTAssertEqual(Set(value.movements.map(\.id)).count, value.movements.count, file: file, line: line)
        XCTAssertLessThanOrEqual(value.movements.count, SkySurvivorIngredients.maximumMovements, file: file, line: line)
    }

    func testSilverSupportClearNamesOnlyTheAquaThatActuallyFallsIntoTheNextLine() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let turn = try exchange(9, 10, in: &game)
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: turn.resolutionPhases, currentIndex: 1))
        assertMovements(value, ids: [23], from: [Cell(4, 2)], to: [Cell(0, 2)])
        XCTAssertEqual(value.movements[0].gem, .init(id: 23, kind: .aqua))
        XCTAssertEqual(value.movements[0].recipeIndices, [0])
        XCTAssertEqual(value.patterns, turn.resolutionPhases[1].recipes)
        XCTAssertEqual(value.patterns[0].starIDs, [0, 1, 3, 4, 23])
        XCTAssertTrue(Set(value.movements.map(\.id)).isDisjoint(with: [0, 1, 3, 4]), "Unmoved ingredients are not falling survivors")
        XCTAssertEqual(game.outcome, .won, "Committed terminal phases remain usable without delaying the win")
    }

    func testRibbonThreePhaseOpeningUsesEachImmediatelyPrecedingClear() throws {
        var game = FallingSky.fullBoardRibbon()
        let turn = try exchange(8, 9, in: &game)
        XCTAssertEqual(turn.resolutionPhases.count, 3)
        let second = try XCTUnwrap(SkySurvivorIngredients(phases: turn.resolutionPhases, currentIndex: 1))
        let third = try XCTUnwrap(SkySurvivorIngredients(phases: turn.resolutionPhases, currentIndex: 2))
        assertMovements(second, ids: [15, 22], from: [Cell(2, 1), Cell(3, 1)], to: [Cell(0, 1), Cell(1, 1)])
        assertMovements(third, ids: [16, 23], from: [Cell(2, 2), Cell(3, 2)], to: [Cell(0, 2), Cell(1, 2)])
        XCTAssertEqual(second.patterns, turn.resolutionPhases[1].recipes)
        XCTAssertEqual(third.patterns, turn.resolutionPhases[2].recipes)
        XCTAssertTrue(second.movements.allSatisfy { $0.recipeIndices == [0] })
        XCTAssertTrue(third.movements.allSatisfy { $0.recipeIndices == [0] })
        XCTAssertEqual(game.displayScore, 30_000)
    }

    func testLanternSixUsesRefilledContinuityWhileExcludingThoseNewBodies() throws {
        var game = FallingSky.fullBoardLantern()
        let turn = try exchange(8, 9, in: &game)
        let phases = turn.resolutionPhases
        XCTAssertNotEqual(phases[0].settled, phases[1].before)
        XCTAssertEqual(phases[0].refilled, phases[1].before)
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 1))
        assertMovements(value, ids: [15, 22], from: [Cell(2, 1), Cell(3, 1)], to: [Cell(0, 1), Cell(1, 1)])
        XCTAssertTrue(Set(value.movements.map(\.id)).isDisjoint(with: phases[0].refillArrivals.map { $0.gem.id }))
        XCTAssertEqual(game.displayScore, 15_000)
    }

    func testCompareClearsAllowsIngredientsBornBeforeThisActionAndExcludesUnmovedLineMembers() throws {
        let chapter = SkyTutorial.fullBoardSurvivors
        let before = chapter.game()
        var game = before
        let turn = try XCTUnwrap(chapter.actions.first?.perform(in: &game))
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: turn.resolutionPhases, currentIndex: 1))
        assertMovements(value, ids: [62, 64], from: [Cell(5, 3), Cell(5, 4)], to: [Cell(3, 3), Cell(3, 4)])
        XCTAssertEqual(value.patterns.map(\.starIDs), [[53, 55, 62, 64]])
        XCTAssertTrue(Set(value.movements.map(\.id)).isSubset(of: Set(before.board.compactMap { $0?.id })))
        XCTAssertTrue(value.movements.allSatisfy { $0.id >= 49 }, "A prior action's refill is an original ingredient of this action")
        XCTAssertTrue(Set(value.movements.map(\.id)).isDisjoint(with: [53, 55]))
        XCTAssertEqual(turn.displayAward, 15_000)
    }

    func testTwoSimultaneousSquaresAreNotMistakenForALaterSurvivorPhase() throws {
        let chapter = SkyTutorial.fullBoardImmediate
        var game = chapter.game()
        let turn = try XCTUnwrap(chapter.actions.first?.perform(in: &game))
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        XCTAssertEqual(turn.resolutionPhases[0].recipes.count, 2)
        XCTAssertNil(SkySurvivorIngredients(phases: turn.resolutionPhases, currentIndex: 0))
    }

    func testIndependentSilverActionsCannotBeJoinedIntoASurvivorTransition() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let first = try exchange(2, 9, in: &game), second = try exchange(23, 22, in: &game)
        XCTAssertEqual(first.resolutionPhases.map(\.comboDepth), [1])
        XCTAssertEqual(second.resolutionPhases.map(\.comboDepth), [1])
        XCTAssertNil(SkySurvivorIngredients(phases: first.resolutionPhases + second.resolutionPhases, currentIndex: 1))
        XCTAssertNil(SkySurvivorIngredients(phases: second.resolutionPhases, currentIndex: 0))
    }

    func testActualRefillMadeRecipeKeepsItsPathButCannotSupplySurvivorMovements() throws {
        let opening = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        var position = opening.board
        position.swapAt(8, 9)
        var random = SeededRandom(seed: 15), nextID = 49
        // Existing bounded Core stabilization fixture, not a natural saved route.
        let phases = FullBoardLanternResolution.resolve(position, random: &random, nextID: &nextID, maximumOrdinaryRefills: 1)
        XCTAssertTrue(phases[1].recipes.contains { $0.starIDs.allSatisfy { $0 >= 49 } })
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 1))
        XCTAssertEqual(value.patterns, phases[1].recipes, "All simultaneous paths survive, including refill-made patterns")
        XCTAssertEqual(value.movements.map(\.id), [15, 22])
        XCTAssertTrue(value.movements.allSatisfy { $0.id < 49 })
    }

    func testEarlierRefillBirthRemainsExcludedAfterSurvivingAnIntermediateClear() throws {
        // Provenance-admission fixture only, not a reachable mode/save claim.
        // Its final two clear geometries are the production Silver transaction.
        var silver = FallingSky.freshChallenge(.silverPools)
        let actual = try exchange(9, 10, in: &silver).resolutionPhases
        var firstBoard = actual[0].before
        let arriving = try XCTUnwrap(firstBoard[4 * 7 + 2])
        firstBoard[4 * 7 + 2] = nil
        firstBoard[2 * 7 + 5] = .init(id: 1_000, kind: .mint, grown: true)
        firstBoard[3 * 7 + 5] = .init(id: 1_001, kind: .mint)
        let arrival = FallingSkyTurn.Arrival(star: .init(id: arriving.id, kind: arriving.kind, column: 2),
                                            cell: Cell(4, 2), gem: arriving, grew: false)
        let first = SkyResolutionPhase(kind: .manual, before: firstBoard,
            cleared: [Cell(2, 5), Cell(3, 5)], comboDepth: 1,
            refillArrivals: [arrival], refilled: actual[0].before)
        let middle = SkyResolutionPhase(kind: .recipe, before: actual[0].before,
            cleared: actual[0].cleared, recipes: actual[0].recipes, comboDepth: 2)
        let last = SkyResolutionPhase(kind: .recipe, before: actual[1].before,
            cleared: actual[1].cleared, recipes: actual[1].recipes, comboDepth: 3)
        XCTAssertFalse(first.before.contains { $0?.id == 23 })
        XCTAssertTrue(middle.before.contains { $0?.id == 23 })
        XCTAssertFalse(middle.cleared.contains(Cell(4, 2)))
        XCTAssertTrue(middle.settled.contains { $0?.id == 23 })
        XCTAssertEqual(middle.refilled, last.before)
        let empty = try XCTUnwrap(SkySurvivorIngredients(phases: [first, middle, last], currentIndex: 2))
        XCTAssertTrue(empty.movements.isEmpty,
                      "Checking only the immediately preceding refill would mislabel the earlier birth")
        XCTAssertEqual(empty.patterns, last.recipes, "A valid empty boundary is distinct from invalid input")
    }

    func testSharedMovedIngredientReferencesBothOverlappingPathsWithoutDuplicatingItsBody() throws {
        // Real manual-clear/recipe resolver geometry; no route or balance claim.
        let phases = SkyRecipeResolution.resolve(board(["RRA....", "RAA....", "AA.....", "A......"], grown: [6]),
            manualClear: [Cell(0, 0), Cell(0, 1), Cell(1, 0)], lineLength: 4)
        XCTAssertEqual(phases.count, 2)
        XCTAssertEqual(phases[1].recipes.map(\.shape), [.square, .square])
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 1))
        assertMovements(value, ids: [4, 6, 7, 8],
            from: [Cell(1, 1), Cell(2, 0), Cell(2, 1), Cell(3, 0)],
            to: [Cell(0, 1), Cell(0, 0), Cell(1, 1), Cell(1, 0)])
        XCTAssertEqual(value.patterns, phases[1].recipes)
        XCTAssertEqual(value.movements.first { $0.id == 4 }?.recipeIndices, [0, 1])
        XCTAssertEqual(value.movements.first { $0.id == 7 }?.recipeIndices, [0, 1])
        XCTAssertEqual(value.movements.first { $0.id == 6 }?.gem.grown, true)
        XCTAssertTrue(Set(value.movements.map(\.id)).isDisjoint(with: [0, 1, 3]))
    }

    func testValidEmptyLaterBoundaryDoesNotEraseTheEarlierPositiveTransition() throws {
        // Provenance-admission fixture, not a reachable Silver refill rule.
        // Extend its actual first two clear geometries with four new bodies.
        var game = FallingSky.freshChallenge(.silverPools)
        let actual = try exchange(9, 10, in: &game).resolutionPhases
        var refilled = actual[1].settled
        let arrivals = (0..<4).map { row in
            let gem = StarfallGem(id: 100 + row, kind: .rose)
            refilled[row * 7 + 2] = gem
            return FallingSkyTurn.Arrival(star: .init(id: gem.id, kind: gem.kind, column: 2),
                                           cell: Cell(row, 2), gem: gem, grew: false)
        }
        let second = SkyResolutionPhase(kind: .recipe, before: actual[1].before,
            cleared: actual[1].cleared, recipes: actual[1].recipes, comboDepth: 2,
            refillArrivals: arrivals, refilled: refilled)
        let recipes = StarRecipe.find(in: refilled, lineLength: 4)
        XCTAssertEqual(recipes.map(\.starIDs), [Set(100..<104)])
        let third = SkyResolutionPhase(kind: .recipe, before: refilled,
            cleared: Set(recipes.flatMap(\.cells)), recipes: recipes, comboDepth: 3)
        let phases = [actual[0], second, third]
        let positive = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 1))
        let empty = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 2))
        XCTAssertEqual(positive.movements.map(\.id), [23])
        XCTAssertTrue(empty.movements.isEmpty)
        XCTAssertEqual([positive, empty].flatMap(\.movements).map(\.id), [23])
        XCTAssertEqual(empty.patterns, recipes)
    }

    func testMalformedIdentitySnapshotOrDiscontinuousBoardCannotProduceAFalseMovement() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let phases = try exchange(9, 10, in: &game).resolutionPhases
        var duplicate = phases[0].before
        duplicate[0] = duplicate[1]
        let badFirst = SkyResolutionPhase(kind: .recipe, before: duplicate,
            cleared: phases[0].cleared, recipes: phases[0].recipes, comboDepth: 1)
        XCTAssertNil(SkySurvivorIngredients(phases: [badFirst, phases[1]], currentIndex: 1))
        var changed = phases[1].before
        changed[2] = .init(id: 23, kind: .rose)
        let badSecond = SkyResolutionPhase(kind: .recipe, before: changed,
            cleared: phases[1].cleared, recipes: phases[1].recipes, comboDepth: 2)
        XCTAssertNil(SkySurvivorIngredients(phases: [phases[0], badSecond], currentIndex: 1))
        let missingRecipes = SkyResolutionPhase(kind: .recipe, before: phases[1].before,
            cleared: phases[1].cleared, comboDepth: 2)
        XCTAssertNil(SkySurvivorIngredients(phases: [phases[0], missingRecipes], currentIndex: 1))
    }

    func testPhaseAndMovementBoundsRejectInvalidIndicesWithoutTruncatingRealRecipes() throws {
        XCTAssertEqual(SkySurvivorIngredients.maximumPhases, FullBoardLanternResolution.maximumPhases)
        XCTAssertEqual(SkySurvivorIngredients.maximumMovements, FallingSky.side * FallingSky.side)
        var game = FallingSky.fullBoardRibbon()
        let phases = try exchange(8, 9, in: &game).resolutionPhases
        for index in [-1, 0, phases.count, Int.max] {
            XCTAssertNil(SkySurvivorIngredients(phases: phases, currentIndex: index))
        }
        XCTAssertNil(SkySurvivorIngredients(phases: [], currentIndex: 1))
        XCTAssertNil(SkySurvivorIngredients(phases: Array(repeating: phases[0], count: 21), currentIndex: 1))
        let value = try XCTUnwrap(SkySurvivorIngredients(phases: phases, currentIndex: 2))
        XCTAssertEqual(value.patterns, phases[2].recipes)
    }

    func testRepeatedReadLeavesEveryCommittedSnapshotSaveAndFollowingRefillUnchanged() throws {
        var game = FallingSky.fullBoardRibbon()
        let turn = try exchange(8, 9, in: &game), snapshots = turn.resolutionPhases
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let bytes = try encoder.encode(game)
        let expected = try XCTUnwrap(SkySurvivorIngredients(phases: snapshots, currentIndex: 2))
        for _ in 0..<3 {
            XCTAssertEqual(SkySurvivorIngredients(phases: snapshots, currentIndex: 2), expected)
            XCTAssertEqual(turn.resolutionPhases, snapshots)
        }
        XCTAssertEqual(try encoder.encode(game), bytes)
        var control = try JSONDecoder().decode(FallingSky.self, from: bytes)
        let next = try exchange(11, 12, in: &game), untouched = try exchange(11, 12, in: &control)
        XCTAssertEqual(next.resolutionPhases, untouched.resolutionPhases)
        XCTAssertEqual(game, control)
        XCTAssertEqual(game.displayScore, 35_000)
    }
}
