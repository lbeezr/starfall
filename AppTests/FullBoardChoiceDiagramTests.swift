import XCTest
import CoreGraphics
@testable import StarfallCore
@testable import Starfall

final class FullBoardChoiceDiagramTests: XCTestCase {
    private let lanternFinish = [(27,34), (1,2), (31,32), (12,13), (16,17),
                                 (8,9), (11,12), (29,30), (29,36), (9,16)]

    private func retainedLantern() throws -> FallingSky {
        FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
    }

    private func exchange(_ from: Int, _ to: Int) -> FallingSkyTurn.Exchange {
        .init(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7))
    }

    @discardableResult private func play(_ move: (Int, Int), in game: inout FallingSky) throws -> FallingSkyTurn {
        let move = exchange(move.0, move.1)
        return try XCTUnwrap(game.nudge(from: move.from, to: move.to))
    }

    private func encoded(_ game: FallingSky) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(game)
    }

    /// Production turns are the oracle: a diagram must stop before the first
    /// clear, while real play continues into falls, new identities and refills.
    @MainActor private func assertPreClearFrames(_ game: FallingSky, choice: FullBoardChoice,
                                                file: StaticString = #filePath, line: UInt = #line) throws {
        let before = try encoded(game)
        let diagram = try XCTUnwrap(SkyFullBoardChoiceDiagram(game: game, choice: choice), file: file, line: line)
        XCTAssertEqual(diagram.frames.count, choice.exchanges.count + 1, file: file, line: line)
        XCTAssertLessThanOrEqual(diagram.frames.count, 3, file: file, line: line)
        var played = game
        var firstClear: SkyResolutionPhase?
        for (index, move) in choice.exchanges.enumerated() {
            let frame = diagram.frames[index]
            XCTAssertEqual(frame.board, played.board, file: file, line: line)
            XCTAssertEqual(frame.exchange, move, file: file, line: line)
            XCTAssertEqual(frame.step, index + 1, file: file, line: line)
            XCTAssertTrue(frame.recipes.isEmpty, "Do not draw a later recipe over earlier ingredients", file: file, line: line)
            XCTAssertEqual(frame.detail, SkyTutorial.Action.swap(move.from, move.to).instruction, file: file, line: line)
            let turn = try XCTUnwrap(played.nudge(from: move.from, to: move.to), file: file, line: line)
            if index < choice.exchanges.count - 1 {
                XCTAssertTrue(turn.resolutionPhases.isEmpty, file: file, line: line)
                XCTAssertEqual(turn.displayAward, 0, file: file, line: line)
            } else {
                firstClear = try XCTUnwrap(turn.resolutionPhases.first, file: file, line: line)
            }
        }
        let final = try XCTUnwrap(diagram.frames.last, file: file, line: line)
        let phase = try XCTUnwrap(firstClear, file: file, line: line)
        XCTAssertNil(final.exchange, file: file, line: line)
        XCTAssertEqual(final.step, choice.exchanges.count, file: file, line: line)
        XCTAssertEqual(final.board, phase.before, file: file, line: line)
        XCTAssertEqual(final.recipes, phase.recipes, file: file, line: line)
        XCTAssertEqual(final.recipes, choice.recipes, file: file, line: line)
        XCTAssertNotEqual(final.board, game.board, "The original board is not the completed arrangement", file: file, line: line)
        XCTAssertNotEqual(final.board, played.board, "The final figure must not depict hidden refill results", file: file, line: line)
        let visibleIDs = Set(game.board.compactMap { $0?.id })
        XCTAssertEqual(Set(final.board.compactMap { $0?.id }), visibleIDs, file: file, line: line)
        XCTAssertEqual(final.board.compactMap { $0 }.count, 49, file: file, line: line)
        XCTAssertTrue(Set(phase.refillArrivals.map { $0.gem.id }).isDisjoint(with: visibleIDs), file: file, line: line)
        for recipe in final.recipes {
            let actualIDs = Set(recipe.cells.compactMap { final.board[$0.row * 7 + $0.column]?.id })
            XCTAssertEqual(actualIDs, recipe.starIDs, file: file, line: line)
        }
        XCTAssertEqual(try encoded(game), before, file: file, line: line)
    }

    @MainActor func testCurrentAndRetainedDirectChoicesShowTheRealFirstPreClearBoard() throws {
        for game in [FallingSky.fullBoardLantern(), .fullBoardRibbon(), try retainedLantern()] {
            let choices = game.fullBoardChoices()
            XCTAssertEqual(choices.count, 2)
            XCTAssertNotEqual(Set(choices[0].recipes.flatMap(\.starIDs)), Set(choices[1].recipes.flatMap(\.starIDs)))
            for choice in choices {
                XCTAssertEqual(choice.exchanges.count, 1)
                try assertPreClearFrames(game, choice: choice)
            }
        }
    }

    @MainActor func testRealTwoExchangeSetupsKeepSourceIntermediateAndFirstPatternSeparate() throws {
        let histories: [(FallingSky, [(Int, Int)], Int, [FallingSkyTurn.Exchange])] = [
            (.fullBoardLantern(), [(8,9), (27,34), (0,1), (12,13), (16,17)], 94_000,
             [exchange(4,11), exchange(5,6)]),
            (.fullBoardRibbon(), [(8,9), (11,12), (31,38), (17,24), (9,16), (9,10), (1,8)], 80_000,
             [exchange(1,2), exchange(1,8)]),
            (try retainedLantern(), [(8,9), (3,10), (5,12), (33,40), (24,31)], 106_000,
             [exchange(1,2), exchange(8,15)])
        ]
        for (opening, prefix, points, expectedExchanges) in histories {
            var game = opening
            for move in prefix { try play(move, in: &game) }
            XCTAssertEqual(game.displayScore, points)
            XCTAssertTrue(game.isValidSave)
            let choices = game.fullBoardChoices()
            XCTAssertEqual(choices.count, 1)
            let choice = try XCTUnwrap(choices.first)
            XCTAssertEqual(choice.exchanges, expectedExchanges)
            try assertPreClearFrames(game, choice: choice)
        }
    }

    @MainActor func testOverlappingFirstPatternsKeepEverySeparateRecipeAndSpendActualIngredientsOnce() throws {
        var game = FallingSky.fullBoardLantern()
        for move in lanternFinish.dropLast() { try play(move, in: &game) }
        XCTAssertEqual(game.displayScore, 98_000)
        let choices = game.fullBoardChoices()
        XCTAssertEqual(choices.count, 2)
        let choice = try XCTUnwrap(choices.last)
        XCTAssertEqual(choice.recipes.map(\.shape), [.cross, .line, .line])
        XCTAssertEqual(choice.recipes.flatMap(\.cells).count, 13)
        XCTAssertEqual(choice.cleared.count, 10)
        let diagram = try XCTUnwrap(SkyFullBoardChoiceDiagram(game: game, choice: choice))
        let final = try XCTUnwrap(diagram.frames.last)
        XCTAssertEqual(final.recipes.count, 3)
        XCTAssertEqual(final.recipes.map(\.presentationPath), choice.recipes.map(\.presentationPath))
        XCTAssertEqual(Set(final.recipes.flatMap(\.starIDs)).count, 10)
        try assertPreClearFrames(game, choice: choice)
    }

    @MainActor func testRepeatedDiagramConstructionPreservesEncodedRoundReplayAndNextRefill() throws {
        for opening in [FallingSky.fullBoardLantern(), .fullBoardRibbon(), try retainedLantern()] {
            var game = opening
            try play((8,9), in: &game)
            let bytes = try encoded(game)
            let control = try JSONDecoder().decode(FallingSky.self, from: bytes)
            let choices = game.fullBoardChoices()
            for choice in choices {
                let first = try XCTUnwrap(SkyFullBoardChoiceDiagram(game: game, choice: choice))
                let repeated = try XCTUnwrap(SkyFullBoardChoiceDiagram(game: game, choice: choice))
                XCTAssertEqual(first.frames.map(\.board), repeated.frames.map(\.board))
                XCTAssertEqual(first.frames.map(\.recipes), repeated.frames.map(\.recipes))
            }
            XCTAssertEqual(try encoded(game), bytes)
            XCTAssertEqual(game, control)
            XCTAssertEqual(game.replay(), opening)
            let next = try XCTUnwrap(choices.first?.exchanges.first)
            var inspected = game, untouched = control
            let actual = try XCTUnwrap(inspected.nudge(from: next.from, to: next.to))
            let expected = try XCTUnwrap(untouched.nudge(from: next.from, to: next.to))
            XCTAssertEqual(actual.resolutionPhases, expected.resolutionPhases)
            XCTAssertEqual(inspected, untouched, "Inspection cannot consume or substitute the next refill stream")
        }
    }

    @MainActor func testInvalidAndConsumedChoicesUnsupportedModesAndCompletedRoundsHaveNoDiagram() throws {
        let game = FallingSky.fullBoardLantern()
        let choice = try XCTUnwrap(game.fullBoardChoices().first)
        let move = try XCTUnwrap(choice.exchanges.first)
        let invalidMoves: [[FallingSkyTurn.Exchange]] = [
            [], [move, move, move], [.init(from: Cell(0,0), to: Cell(0,0))],
            [.init(from: Cell(0,0), to: Cell(1,1))], [.init(from: Cell(-1,0), to: Cell(0,0))],
            [.init(from: Cell(6,6), to: Cell(7,6))]
        ]
        for exchanges in invalidMoves {
            XCTAssertNil(SkyFullBoardChoiceDiagram(game: game,
                choice: FullBoardChoice(exchanges: exchanges, recipes: choice.recipes)))
        }
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: game,
            choice: FullBoardChoice(exchanges: choice.exchanges, recipes: [])))
        let recipe = try XCTUnwrap(choice.recipes.first)
        let foreignIDs = StarRecipe(shape: recipe.shape, cells: recipe.cells, starIDs: [10_000,10_001,10_002,10_003])
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: game,
            choice: FullBoardChoice(exchanges: choice.exchanges, recipes: [foreignIDs])))
        let duplicatedCell = StarRecipe(shape: recipe.shape,
            cells: Array(repeating: recipe.cells[0], count: 4), starIDs: recipe.starIDs)
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: game,
            choice: FullBoardChoice(exchanges: choice.exchanges, recipes: [duplicatedCell])))
        let oversized = Array(repeating: recipe, count: PatternReturnLayout.maximumPatterns + 1)
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: game,
            choice: FullBoardChoice(exchanges: choice.exchanges, recipes: oversized)))
        var consumed = game
        XCTAssertNotNil(consumed.nudge(from: move.from, to: move.to))
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: consumed, choice: choice), "A consumed ingredient cannot be redrawn in a new snapshot")
        for unsupported in [FallingSky.freshSurvival(seed: 42), .freshChallenge(.firstLight), FallingSky(challenge: .firstLight)] {
            XCTAssertNil(SkyFullBoardChoiceDiagram(game: unsupported, choice: choice))
        }
        var won = game
        for move in lanternFinish { try play(move, in: &won) }
        XCTAssertEqual(won.outcome, .won)
        XCTAssertNil(SkyFullBoardChoiceDiagram(game: won, choice: choice))
    }

    @MainActor func testGeometryKeepsTopDownRowsSquareMaterialsAndGrownBodiesWithinThePassiveCanvas() throws {
        let image = SkyPiece.image(for: .colored(.aqua))
        for size in [CGSize(width:112,height:112), CGSize(width:300,height:300), CGSize(width:520,height:300)] {
            let geometry = try XCTUnwrap(SkyFullBoardChoiceGeometry(size: size))
            let canvas = CGRect(origin: .zero, size: size)
            XCTAssertTrue(canvas.contains(geometry.board))
            XCTAssertEqual(geometry.board.width, geometry.board.height)
            let upperLeft = geometry.point(Cell(6,0)), lowerRight = geometry.point(Cell(0,6))
            XCTAssertLessThan(upperLeft.x, lowerRight.x)
            XCTAssertLessThan(upperLeft.y, lowerRight.y)
            XCTAssertEqual(geometry.point(Cell(6,1)).x - upperLeft.x, geometry.step, accuracy: 0.000001)
            XCTAssertEqual(geometry.point(Cell(5,0)).y - upperLeft.y, geometry.step, accuracy: 0.000001)
            for row in 0..<7 { for column in 0..<7 {
                let cell = Cell(row,column), center = geometry.point(cell)
                XCTAssertTrue(geometry.board.contains(center))
                let small = geometry.imageRect(at: cell, grown: false)
                let grown = geometry.imageRect(at: cell, grown: true)
                for rect in [small, grown] {
                    XCTAssertTrue(canvas.contains(rect))
                    XCTAssertEqual(rect.midX, center.x, accuracy: 0.000001)
                    XCTAssertEqual(rect.midY, center.y, accuracy: 0.000001)
                    XCTAssertEqual(rect.width / rect.height, image.size.width / image.size.height, accuracy: 0.000001)
                }
                XCTAssertGreaterThan(grown.width, small.width)
                XCTAssertGreaterThan(grown.height, small.height)
            } }
        }
    }

    func testGeometryRejectsNonfiniteAndTooSmallCanvases() {
        for size in [CGSize.zero, CGSize(width:111,height:300), CGSize(width:300,height:111),
                     CGSize(width:CGFloat.infinity,height:300), CGSize(width:300,height:CGFloat.nan),
                     CGSize(width:-300,height:300)] {
            XCTAssertNil(SkyFullBoardChoiceGeometry(size: size))
        }
    }
}
