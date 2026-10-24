import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkyScoreExplanationTests: XCTestCase {
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

    func testSilverWinningChainCopiesBothPhaseComponentsAndTheNineteenThousandTotal() throws {
        let before = FallingSky.freshChallenge(.silverPools)
        var game = before
        let turn = try exchange(9, 10, in: &game)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(explanation.total, 19_000)
        XCTAssertEqual(explanation.phases.map(\.depth), [1, 2])
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [4, 5])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [4, 5])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [4_000, 5_000])
        XCTAssertEqual(explanation.phases.map(\.sizeBonus), [1_000, 2_000])
        XCTAssertEqual(explanation.phases.map(\.comboBonus), [0, 7_000])
        XCTAssertEqual(explanation.phases.map(\.points), [5_000, 14_000])
        XCTAssertTrue(explanation.phases.allSatisfy(\.usesStoryPoints))
        XCTAssertEqual(explanation.phases.reduce(0) { $0 + $1.basePoints + $1.sizeBonus + $1.comboBonus }, explanation.total)
    }

    func testCurrentCelebrationPrefixExplainsItsCumulativeNumberRatherThanOnlyTheLastPhase() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let turn = try exchange(9, 10, in: &game)
        let first = try XCTUnwrap(SkyScoreExplanation(phases: Array(turn.resolutionPhases.prefix(1)), expectedTotal: 5_000))
        let second = try XCTUnwrap(SkyScoreExplanation(phases: turn.resolutionPhases, expectedTotal: 19_000))
        XCTAssertEqual(first.phases.map(\.points), [5_000])
        XCTAssertEqual(second.phases.last?.points, 14_000)
        XCTAssertEqual(second.total, 19_000)
        XCTAssertNil(SkyScoreExplanation(phases: turn.resolutionPhases, expectedTotal: 14_000))
        XCTAssertNil(SkyScoreExplanation(phases: [turn.resolutionPhases[1]], expectedTotal: 14_000),
                     "A second phase alone is not a contiguous action prefix")
    }

    func testIndependentSilverClearsResetDepthAndNeverReceiveAChainBonus() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        let firstTurn = try exchange(2, 9, in: &game)
        let first = try XCTUnwrap(SkyScoreExplanation(turn: firstTurn, from: opening))
        let intermediate = game
        let secondTurn = try exchange(23, 22, in: &game)
        let second = try XCTUnwrap(SkyScoreExplanation(turn: secondTurn, from: intermediate))
        XCTAssertEqual(first.total, 7_000)
        XCTAssertEqual(second.total, 5_000)
        XCTAssertEqual(first.phases.map(\.depth), [1])
        XCTAssertEqual(second.phases.map(\.depth), [1])
        XCTAssertEqual(first.phases.map(\.comboBonus), [0])
        XCTAssertEqual(second.phases.map(\.comboBonus), [0])
        XCTAssertEqual(first.phases.map(\.sizeBonus), [2_000])
        XCTAssertEqual(second.phases.map(\.sizeBonus), [1_000])
        XCTAssertEqual(game.displayScore, 12_000)
    }

    func testSimultaneousOverlappingSquaresCountTheirSixActualIngredientsOnce() throws {
        // Geometry/mechanical resolver fixture, not an authored reachable route.
        let phases = SkyRecipeResolution.resolve(board(["AAA....", "AAA...."]), lineLength: 4)
        let phase = try XCTUnwrap(phases.first)
        XCTAssertEqual(phase.recipes.map(\.shape), [.square, .square])
        XCTAssertEqual(phase.recipes.flatMap(\.cells).count, 8)
        XCTAssertEqual(phase.cleared.count, 6)
        let explanation = try XCTUnwrap(SkyScoreExplanation(phases: phases, expectedTotal: 9_000))
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [6])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [6])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [6_000])
        XCTAssertEqual(explanation.phases.map(\.sizeBonus), [3_000])
        XCTAssertEqual(explanation.phases.map(\.comboBonus), [0])
    }

    func testSeedGrownIngredientAddsBaseLightWithoutAddingASizeBonusStar() throws {
        let before = FallingSky.freshChallenge(.seedMoon)
        var game = before
        let turn = try exchange(4, 3, in: &game)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(explanation.total, 6_000)
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [4])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [5])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [5_000])
        XCTAssertEqual(explanation.phases.map(\.sizeBonus), [1_000])
        XCTAssertEqual(explanation.phases.map(\.comboBonus), [0])
        XCTAssertTrue(explanation.phases[0].usesStoryPoints)
    }

    func testOpenSkyGrownManualClearKeepsOneToOneLightAndNoBonuses() throws {
        let incoming = (0..<3).map { IncomingStar(id: $0, kind: .rose, column: 0) }
        var game = FallingSky(board: Array(repeating: nil, count: 49), incoming: incoming)
        XCTAssertNotNil(game.letStarsFall())
        let before = game
        XCTAssertTrue(before.isValidSave)
        let turn = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertNil(turn.award)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(explanation.total, 3)
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [2])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [3])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [3])
        XCTAssertEqual(explanation.phases.map(\.sizeBonus), [0])
        XCTAssertEqual(explanation.phases.map(\.comboBonus), [0])
        XCTAssertFalse(explanation.phases[0].usesStoryPoints)
    }

    @MainActor func testHistoricalEighteenLightChallengeDoesNotBorrowCurrentStoryPointUnits() throws {
        let before = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .kiteHarbor)
        XCTAssertEqual(before.challengeRevision, 0)
        XCTAssertEqual(before.displayTarget, 18)
        XCTAssertTrue(before.isValidSave)
        var game = before
        let turn = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertNil(turn.award)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(explanation.total, turn.collected)
        XCTAssertEqual(explanation.phases[0].basePoints, turn.collected)
        XCTAssertEqual(explanation.phases[0].clearedStarCount, turn.cleared.count)
        XCTAssertEqual(explanation.phases[0].sizeBonus, 0)
        XCTAssertEqual(explanation.phases[0].comboBonus, 0)
        XCTAssertFalse(explanation.phases[0].usesStoryPoints)
        XCTAssertEqual(game.replay(), before.replay())
    }

    func testRetainedSizeOnlyAwardUsesItsActualAwardWithoutInventingACausalBonus() throws {
        let before = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 1)))
        var game = before
        let turn = try XCTUnwrap(game.clear(Cell(0, 0)))
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(explanation.total, 7_000)
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [5])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [5])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [5_000])
        XCTAssertEqual(explanation.phases.map(\.sizeBonus), [2_000])
        XCTAssertEqual(explanation.phases.map(\.comboBonus), [0])
        XCTAssertTrue(explanation.phases[0].usesStoryPoints)
    }

    func testZeroLightDuskClearStillExplainsFourRemovedBodiesAndZeroEarnedLight() throws {
        let before = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var game = before
        let turn = try XCTUnwrap(game.clear(Cell(0, 1)))
        XCTAssertEqual(turn.collected, 0)
        XCTAssertEqual(turn.cleared.count, 4)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: before))
        XCTAssertEqual(explanation.total, 0)
        XCTAssertEqual(explanation.phases.map(\.clearedStarCount), [4])
        XCTAssertEqual(explanation.phases.map(\.baseLight), [0])
        XCTAssertEqual(explanation.phases.map(\.basePoints), [0])
        XCTAssertFalse(explanation.phases[0].usesStoryPoints)
    }

    func testFullBoardCurrentAndRetainedTransactionsKeepEveryEarnedRefillPhase() throws {
        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        for (opening, expected) in [(FallingSky.fullBoardLantern(), [5_000, 10_000]),
                                    (retained, [5_000, 10_000, 51_000]),
                                    (FallingSky.fullBoardRibbon(), [5_000, 10_000, 15_000])] {
            var game = opening
            let turn = try exchange(8, 9, in: &game)
            let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
            XCTAssertEqual(explanation.phases.map(\.points), expected)
            XCTAssertEqual(explanation.total, turn.displayAward)
            XCTAssertEqual(explanation.phases.count, turn.resolutionPhases.count)
            XCTAssertEqual(explanation.phases.map(\.clearedStarCount), turn.resolutionPhases.map { $0.award.clearedStarCount })
            XCTAssertEqual(game.occupiedCount, 49)
        }
    }

    func testDefensivePrefixBoundPreservesTheCoreCapAndDoesNotMultiplyPhaseSixBySix() throws {
        XCTAssertEqual(SkyScoreExplanation.maximumPhases, FullBoardLanternResolution.maximumPhases)
        let position = board(["AA.....", "AA....."])
        let cells: Set<Cell> = [Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)]
        // Numerical/resource boundary only. Repeated boards are not a claimed
        // causal route; each award is produced by the unchanged Core owner.
        let phases = (1...SkyScoreExplanation.maximumPhases).map {
            SkyResolutionPhase(kind: .recipe, before: position, cleared: cells, comboDepth: $0)
        }
        let total = phases.reduce(0) { $0 + $1.award.displayPoints }
        let explanation = try XCTUnwrap(SkyScoreExplanation(phases: phases, expectedTotal: total))
        XCTAssertEqual(explanation.phases.count, 20)
        XCTAssertEqual(explanation.phases[4].points, 25_000)
        XCTAssertEqual(explanation.phases[5].depth, 6)
        XCTAssertEqual(explanation.phases[5].comboBonus, 20_000)
        XCTAssertEqual(explanation.phases[5].points, 25_000)
        XCTAssertEqual(explanation.total, 450_000)
        let excess = phases + [SkyResolutionPhase(kind: .recipe, before: position, cleared: cells, comboDepth: 21)]
        XCTAssertNil(SkyScoreExplanation(phases: excess, expectedTotal: total + 25_000))
        XCTAssertNil(SkyScoreExplanation(phases: [], expectedTotal: 0))
        XCTAssertNil(SkyScoreExplanation(phases: Array(phases.prefix(2).reversed()), expectedTotal: 15_000))
    }

    func testNoClearOrInconsistentAggregateIsOmittedAndExplanationCannotConsumeContinuation() throws {
        var setup = FallingSky.freshChallenge(.seedMoon)
        let setupBefore = setup
        let noClear = try exchange(1, 8, in: &setup)
        XCTAssertTrue(noClear.resolutionPhases.isEmpty)
        XCTAssertNil(SkyScoreExplanation(turn: noClear, from: setupBefore))
        let opening = FallingSky.freshChallenge(.silverPools)
        var game = opening
        let turn = try exchange(2, 9, in: &game)
        let forged = FallingSkyTurn(resolutionPhases: turn.resolutionPhases,
            award: SkyScoreAward(baseLight: 6, clearedStarCount: 5), cleared: [], collected: 5,
            settled: turn.settled, forecast: turn.forecast, arrivals: [], blockedColumn: nil)
        XCTAssertNil(SkyScoreExplanation(turn: forged, from: opening))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let beforeBytes = try encoder.encode(opening), afterBytes = try encoder.encode(game)
        let expected = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
        for _ in 0..<3 { XCTAssertEqual(SkyScoreExplanation(turn: turn, from: opening), expected) }
        XCTAssertEqual(try encoder.encode(opening), beforeBytes)
        XCTAssertEqual(try encoder.encode(game), afterBytes)
        var control = try JSONDecoder().decode(FallingSky.self, from: afterBytes)
        let actual = try XCTUnwrap(game.letStarsFall()), untouched = try XCTUnwrap(control.letStarsFall())
        XCTAssertEqual(actual.arrivals, untouched.arrivals)
        XCTAssertEqual(actual.resolutionPhases, untouched.resolutionPhases)
        XCTAssertEqual(game, control)
    }
}
