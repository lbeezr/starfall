import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkyLastClearSnapshotTests: XCTestCase {
    @discardableResult private func exchange(_ from: Int, _ to: Int,
                                             in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
    }

    private func snapshot(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                          path: [Cell] = [], recipe: StarRecipe? = nil,
                          sequence: UInt64 = 1) throws -> SkyLastClearSnapshot {
        try XCTUnwrap(SkyLastClearSnapshot(turn: turn, from: old, to: game, path: path, recipe: recipe,
                                          roundGeneration: 4, sequence: sequence))
    }

    private func receipt(_ phases: [SkyResolutionPhase]) -> FallingSkyTurn {
        let award = SkyScoreAward(summing: phases.map(\.award))
        return FallingSkyTurn(resolutionPhases: phases, award: award, cleared: [], collected: award.baseLight,
                              settled: phases.last?.refilled ?? [], forecast: [], arrivals: [], blockedColumn: nil)
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    func testSilverWinningClearKeepsBothActualBoardsSeparatePathsAndTheMovedIngredient() throws {
        let before = FallingSky.freshChallenge(.silverPools)
        var game = before
        let turn = try exchange(9, 10, in: &game)
        let value = try snapshot(turn, from: before, to: game)
        XCTAssertEqual(value.id, "4:1")
        XCTAssertEqual(value.context.challenge, .silverPools)
        XCTAssertEqual(value.context.challengeRevision, 4)
        XCTAssertFalse(value.context.fullBoard)
        XCTAssertFalse(value.context.manualClears)
        XCTAssertTrue(value.manualPath.isEmpty)
        XCTAssertEqual(value.phases.map(\.board), turn.resolutionPhases.map(\.before))
        XCTAssertNotEqual(value.phases[0].board, before.board, "The first recipe is after the actual exchange")
        XCTAssertEqual(value.phases.map(\.paths), turn.resolutionPhases.map { $0.recipes.map(\.presentationPath) })
        XCTAssertEqual(value.phases.map(\.cleared), turn.resolutionPhases.map(\.cleared))
        XCTAssertTrue(value.phases.allSatisfy { $0.drained.isEmpty })
        XCTAssertEqual(value.score.phases.map(\.points), [5_000, 14_000])
        XCTAssertEqual(value.score.total, 19_000)
        XCTAssertEqual(value.phases.map(\.score), value.score.phases)
        XCTAssertNil(value.phases[0].survivors)
        let movement = try XCTUnwrap(value.phases[1].survivors?.movements.first)
        XCTAssertEqual(movement.id, 23)
        XCTAssertEqual(movement.from, Cell(4, 2))
        XCTAssertEqual(movement.to, Cell(0, 2))
        XCTAssertEqual(movement.gem, .init(id: 23, kind: .aqua))
        XCTAssertEqual(value.survivorCount, 1)
        XCTAssertEqual(value.totalRefillCount, 0)
        XCTAssertEqual(value.resultingOccupiedCount, game.occupiedCount)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertNil(value.headroom, "Terminal recap does not bypass the guide's outcome priority")
    }

    func testIndependentSilverClearsHaveIndependentPhaseDepthsAndReceipts() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        let firstTurn = try exchange(2, 9, in: &game)
        let first = try snapshot(firstTurn, from: opening, to: game)
        let middle = game
        let secondTurn = try exchange(23, 22, in: &game)
        let second = try snapshot(secondTurn, from: middle, to: game, sequence: 2)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(first.score.total, 7_000)
        XCTAssertEqual(second.score.total, 5_000)
        XCTAssertEqual(first.score.phases.map(\.depth), [1])
        XCTAssertEqual(second.score.phases.map(\.depth), [1])
        XCTAssertEqual(second.phases.map(\.paths), secondTurn.resolutionPhases.map { $0.recipes.map(\.presentationPath) })
        XCTAssertEqual(second.survivorCount, 0)
        XCTAssertEqual(game.displayScore, 12_000)
    }

    func testCurrentAndRetainedFullBoardsCopyActualReplacementsWithoutTemporaryRoom() throws {
        let historical = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        for (before, revision, points, refills) in [
            (FallingSky.fullBoardLantern(), 6, [5_000, 10_000], 8),
            (FallingSky.fullBoardRibbon(), 7, [5_000, 10_000, 15_000], 12),
            (historical, 5, [5_000, 10_000, 51_000], 18)
        ] {
            var game = before
            let turn = try exchange(8, 9, in: &game)
            let value = try snapshot(turn, from: before, to: game)
            XCTAssertTrue(value.context.fullBoard)
            XCTAssertFalse(value.context.manualClears)
            XCTAssertEqual(value.context.challengeRevision, revision)
            XCTAssertEqual(value.score.phases.map(\.points), points)
            XCTAssertEqual(value.totalRefillCount, refills)
            XCTAssertEqual(value.phases.map(\.refillCount), turn.resolutionPhases.map { $0.refillArrivals.count })
            XCTAssertEqual(value.phases.map(\.occupiedAfter), turn.resolutionPhases.map { $0.refilled.compactMap { $0 }.count })
            XCTAssertEqual(value.resultingOccupiedCount, 49)
            XCTAssertEqual(value.headroom?.kind, .refilled(stars: refills))
            if revision == 6 { XCTAssertEqual(value.survivorCount, 2) }
            if revision == 7 { XCTAssertEqual(value.survivorCount, 4) }
            XCTAssertEqual(value.phases.map(\.paths), turn.resolutionPhases.map { $0.recipes.map(\.presentationPath) })
        }
    }

    func testWinningFullBoardCopiesItsFinalActualOccupancyAndRefillsWithoutATerminalOverride() throws {
        // Existing current-Lantern HIGH10 route; no new search or target change.
        let route = [(27,34), (1,2), (31,32), (12,13), (16,17),
                     (8,9), (11,12), (29,30), (29,36), (9,16)]
        var game = FallingSky.fullBoardLantern()
        for move in route.dropLast() { try exchange(move.0, move.1, in: &game) }
        let before = game
        let move = try XCTUnwrap(route.last)
        let turn = try exchange(move.0, move.1, in: &game)
        let value = try snapshot(turn, from: before, to: game)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(value.score.phases.map(\.points), [17_000, 26_000, 15_000])
        XCTAssertEqual(value.score.total, 58_000)
        XCTAssertEqual(value.resultingOccupiedCount, game.occupiedCount)
        XCTAssertEqual(value.totalRefillCount, turn.resolutionPhases.flatMap(\.refillArrivals).count)
        XCTAssertEqual(value.phases.last?.occupiedAfter, game.occupiedCount)
        XCTAssertNil(value.headroom)
    }

    func testCompareKeepsBothSimultaneousPathsAndTheHistoricalSurvivorActionDistinct() throws {
        for chapter in [SkyTutorial.fullBoardImmediate, .fullBoardSurvivors] {
            let before = chapter.game()
            var game = before
            let turn = try XCTUnwrap(chapter.actions.first?.perform(in: &game))
            let value = try snapshot(turn, from: before, to: game)
            XCTAssertEqual(value.context.challengeRevision, 5)
            XCTAssertTrue(value.context.fullBoard)
            XCTAssertEqual(value.phases.map(\.paths), turn.resolutionPhases.map { $0.recipes.map(\.presentationPath) })
            if chapter == .fullBoardImmediate {
                XCTAssertEqual(value.score.total, 13_000)
                XCTAssertEqual(value.phases.count, 1)
                XCTAssertEqual(value.phases[0].paths.count, 2)
                XCTAssertEqual(value.phases[0].cleared.count, 8)
                XCTAssertEqual(value.survivorCount, 0)
            } else {
                XCTAssertEqual(value.score.total, 15_000)
                XCTAssertEqual(value.phases[1].survivors?.movements.map(\.id), [62, 64])
                XCTAssertEqual(value.survivorCount, 2)
            }
        }
    }

    func testManualGapsRevisitsAndDrainedStarsKeepTheActualWalkRatherThanAUnionOutline() throws {
        let branch = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,3), Cell(0,4), Cell(1,5), Cell(1,6)]
        let cases: [(ConstellationFixture, [Cell])] = [
            (.singleGap, [0,1,2,3,5].map { Cell(0,$0) }), (.overlap, branch), (.darkness, branch)
        ]
        for (fixture, path) in cases {
            // This historical fixture predates feeding Dusk. Match the actual
            // Store admission before asking for its drained appearance.
            let before = fixture.game().adoptingFeedingDusk()
            var game = before
            let turn = try XCTUnwrap(game.clearConstellation(path))
            let value = try snapshot(turn, from: before, to: game, path: path)
            XCTAssertTrue(value.context.manualClears)
            XCTAssertFalse(value.context.fullBoard)
            XCTAssertEqual(value.manualPath, path)
            XCTAssertEqual(value.phases.count, 1)
            XCTAssertEqual(value.phases[0].board, before.board)
            XCTAssertEqual(value.phases[0].paths, [path])
            XCTAssertEqual(value.phases[0].cleared, turn.cleared)
            let expectedDrained = Set(before.board.enumerated().compactMap { index, gem -> Cell? in
                let cell = Cell(index / 7, index % 7)
                return gem != nil && before.isDrained(at: cell) ? cell : nil
            })
            XCTAssertEqual(value.phases[0].drained, expectedDrained)
            XCTAssertEqual(value.resultingOccupiedCount, game.occupiedCount)
            XCTAssertEqual(value.score.total, turn.collected)
            XCTAssertFalse(value.score.phases[0].usesStoryPoints)
            if fixture == .darkness {
                XCTAssertFalse(value.phases[0].drained.isDisjoint(with: Set(path)))
                XCTAssertTrue(value.phases[0].drained.allSatisfy { before.gem(at: $0)?.isDark == false })
            } else { XCTAssertTrue(value.phases[0].drained.isEmpty) }
        }
    }

    func testZeroLightDuskClearStillProducesANewFourBodyRecap() throws {
        let before = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var game = before
        let turn = try XCTUnwrap(game.clear(Cell(0, 1)))
        let value = try snapshot(turn, from: before, to: game, sequence: 2)
        XCTAssertEqual(value.id, "4:2")
        XCTAssertEqual(value.score.total, 0)
        XCTAssertEqual(value.score.phases[0].baseLight, 0)
        XCTAssertEqual(value.phases[0].score.clearedStarCount, 4)
        XCTAssertEqual(value.phases[0].cleared, turn.cleared)
        XCTAssertEqual(value.phases[0].drained, [Cell(0, 1), Cell(0, 2)])
        XCTAssertTrue(value.phases[0].drained.isSubset(of: value.phases[0].cleared))
        XCTAssertEqual(value.phases[0].paths, [])
        XCTAssertEqual(value.resultingOccupiedCount, 0)
        XCTAssertEqual(value.totalRefillCount, 0)
        XCTAssertEqual(value.headroom?.kind, .opened(columns: [0, 1, 2], spaces: 4))
    }

    @MainActor func testOrdinaryGrownTapAndRetainedManualStoryDoNotInventADrawingOrPointScale() throws {
        let incoming = (0..<3).map { IncomingStar(id: $0, kind: .rose, column: 0) }
        var sky = FallingSky(board: Array(repeating: nil, count: 49), incoming: incoming)
        XCTAssertNotNil(sky.letStarsFall())
        let skyBefore = sky
        let tap = try XCTUnwrap(sky.clear(Cell(0, 0)))
        let plain = try snapshot(tap, from: skyBefore, to: sky)
        XCTAssertNil(plain.context.challenge)
        XCTAssertEqual(plain.score.total, 3)
        XCTAssertEqual(plain.phases[0].score.clearedStarCount, 2)
        XCTAssertTrue(plain.manualPath.isEmpty)
        XCTAssertTrue(plain.phases[0].paths.isEmpty)
        XCTAssertFalse(plain.phases[0].score.usesStoryPoints)

        let history = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .kiteHarbor)
        var retained = history
        let clear = try XCTUnwrap(retained.clear(Cell(0, 0)))
        let value = try snapshot(clear, from: history, to: retained)
        XCTAssertEqual(value.context.challenge, .kiteHarbor)
        XCTAssertEqual(value.context.challengeRevision, 0)
        XCTAssertTrue(value.context.manualClears)
        XCTAssertEqual(value.score.total, clear.collected)
        XCTAssertFalse(value.phases[0].score.usesStoryPoints)
    }

    func testKiteRoomFactsRemainCommittedAndNoClearPreparationIsNotARecap() throws {
        let before = FallingSky.freshChallenge(.kiteHarbor)
        var high = before, low = before
        let highTurn = try exchange(15, 14, in: &high), lowTurn = try exchange(4, 11, in: &low)
        let highValue = try snapshot(highTurn, from: before, to: high)
        let lowValue = try snapshot(lowTurn, from: before, to: low)
        XCTAssertEqual(highValue.headroom?.kind, .opened(columns: [0], spaces: 4))
        XCTAssertEqual(lowValue.headroom?.kind, .opened(columns: [2, 3, 4, 5, 6], spaces: 5))
        XCTAssertEqual(highValue.resultingOccupiedCount, 20)
        XCTAssertEqual(lowValue.resultingOccupiedCount, 19)
        var setup = FallingSky.freshChallenge(.frostfruitOrchard)
        let opening = setup
        let noClear = try exchange(35, 36, in: &setup)
        XCTAssertNil(SkyLastClearSnapshot(turn: noClear, from: opening, to: setup,
                                         path: [], recipe: nil, roundGeneration: 4, sequence: 1))
    }

    func testRepeatedReadingPreservesEncodedStateAndTheActualNextRefill() throws {
        let before = FallingSky.fullBoardRibbon()
        var game = before
        let turn = try exchange(8, 9, in: &game)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let oldBytes = try encoder.encode(before), bytes = try encoder.encode(game)
        let expected = try snapshot(turn, from: before, to: game)
        for _ in 0..<3 { XCTAssertEqual(try snapshot(turn, from: before, to: game), expected) }
        XCTAssertEqual(try encoder.encode(before), oldBytes)
        XCTAssertEqual(try encoder.encode(game), bytes)
        var control = try JSONDecoder().decode(FallingSky.self, from: bytes)
        let next = try exchange(11, 12, in: &game), untouched = try exchange(11, 12, in: &control)
        XCTAssertEqual(next.resolutionPhases, untouched.resolutionPhases)
        XCTAssertEqual(game, control)
        XCTAssertEqual(expected.score.total, 30_000, "A retained value does not follow later game mutation")
        XCTAssertEqual(game.displayScore, 35_000)
    }

    func testForeignInvalidOrStaleCommittedBoardsAndWrongRecipeIDsAreRejected() throws {
        let before = FallingSky.freshChallenge(.silverPools)
        var game = before
        let turn = try exchange(9, 10, in: &game)
        for old in [FallingSky.freshChallenge(.seedMoon), try changed(before, { $0["starsLanded"] = 0 })] {
            XCTAssertNil(SkyLastClearSnapshot(turn: turn, from: old, to: game,
                                             path: [], recipe: nil, roundGeneration: 0, sequence: 0))
        }
        XCTAssertNil(SkyLastClearSnapshot(turn: turn, from: before, to: before,
                                         path: [], recipe: nil, roundGeneration: 0, sequence: 0))

        let manual = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 1)))
        var cleared = manual
        let actualRecipe = try XCTUnwrap(manual.recipes.first)
        let clear = try XCTUnwrap(cleared.activate(actualRecipe))
        let actual = try snapshot(clear, from: manual, to: cleared, recipe: actualRecipe)
        XCTAssertEqual(actual.phases[0].paths, [actualRecipe.presentationPath])
        let forged = StarRecipe(shape: actualRecipe.shape, cells: actualRecipe.cells, starIDs: [10_000])
        XCTAssertNil(SkyLastClearSnapshot(turn: clear, from: manual, to: cleared,
                                         path: [], recipe: forged, roundGeneration: 0, sequence: 0))
    }

    func testDiscontinuousDuplicateIdentityAndExcessPhasePrefixesCannotBecomeRecaps() throws {
        let before = FallingSky.freshChallenge(.silverPools)
        var game = before
        let phases = try exchange(9, 10, in: &game).resolutionPhases
        var duplicate = phases[0].before
        duplicate[0] = duplicate[1]
        let badFirst = SkyResolutionPhase(kind: .recipe, before: duplicate,
            cleared: phases[0].cleared, recipes: phases[0].recipes, comboDepth: 1)
        let skipped = SkyResolutionPhase(kind: .recipe, before: phases[1].before,
            cleared: phases[1].cleared, recipes: phases[1].recipes, comboDepth: 3)
        let excess = Array(repeating: phases[0], count: SkyLastClearSnapshot.maximumPhases) + [phases[1]]
        for hostile in [[badFirst, phases[1]], [phases[0], skipped], excess] {
            XCTAssertNil(SkyLastClearSnapshot(turn: receipt(hostile), from: before, to: game,
                                             path: [], recipe: nil, roundGeneration: 0, sequence: 0))
        }
        XCTAssertEqual(SkyLastClearSnapshot.maximumPhases, FullBoardLanternResolution.maximumPhases)
    }

    func testTheActualManualWalkBoundKeepsRevisitsAndRejectsAnExcessEntryOrInvalidCell() throws {
        let before = ConstellationFixture.singleGap.game()
        let outward = [0,1,2,3,5].map { Cell(0,$0) }
        let loop = outward + outward.dropLast().reversed()
        let path = Array(Array(repeating: loop, count: 22).flatMap { $0 }.prefix(196))
        var game = before
        let turn = try XCTUnwrap(game.clearConstellation(path))
        let value = try snapshot(turn, from: before, to: game, path: path)
        XCTAssertEqual(value.manualPath.count, 196)
        XCTAssertEqual(value.phases[0].paths, [path])
        XCTAssertEqual(Set(path).count, 5)
        for hostile in [path + [try XCTUnwrap(path.last)], [Cell(-1, 0)] + outward] {
            XCTAssertNil(SkyLastClearSnapshot(turn: turn, from: before, to: game,
                                             path: hostile, recipe: nil, roundGeneration: 0, sequence: 0))
        }
    }
}
