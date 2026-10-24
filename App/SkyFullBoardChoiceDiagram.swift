import SwiftUI
import StarfallCore

/// Disposable exchange-only frames of Core's visible-board advice. Never run
/// the resolver here: a completed nudge would already contain falls/refills.
struct SkyFullBoardChoiceDiagram {
    struct Frame {
        let board: [StarfallGem?]
        let exchange: FallingSkyTurn.Exchange?
        let recipes: [StarRecipe]
        let step: Int

        var title: String {
            SkyCopy.text(exchange == nil ? .choiceDiagramAfter : .choiceDiagramBefore,
                         values: ["number": String(step)])
        }
        var detail: String {
            if let exchange { return SkyTutorial.Action.swap(exchange.from, exchange.to).instruction }
            let cells = Set(recipes.flatMap(\.cells)).sorted {
                $0.row == $1.row ? $0.column < $1.column : $0.row > $1.row
            }
            return SkyCopy.text(.choiceDiagramIngredients, values: ["positions": cells.map {
                let position = SkyCopy.boardPosition($0)
                return SkyCopy.text(.practicePosition, values: ["row": String(position.row),
                                                              "column": String(position.column)])
            }.joined(separator: "; ")])
        }
    }

    let frames: [Frame]

    init?(game: FallingSky, choice: FullBoardChoice) {
        guard SkyFullBoardChoiceAnalysis.supports(game), game.canArrangeStars,
              game.board.count == 49, game.board.allSatisfy({ $0 != nil }),
              Set(game.board.compactMap { $0?.id }).count == 49,
              (1...2).contains(choice.exchanges.count),
              !choice.recipes.isEmpty, choice.recipes.count <= PatternReturnLayout.maximumPatterns else { return nil }
        var board = game.board
        var result: [Frame] = []
        for (index, exchange) in choice.exchanges.enumerated() {
            guard [exchange.from, exchange.to].allSatisfy(Self.valid),
                  abs(exchange.from.row - exchange.to.row) + abs(exchange.from.column - exchange.to.column) == 1 else { return nil }
            result.append(Frame(board: board, exchange: exchange, recipes: [], step: index + 1))
            board.swapAt(exchange.from.row * 7 + exchange.from.column, exchange.to.row * 7 + exchange.to.column)
            board = SkyBoardSettling.settle(board)
        }
        // Core produced the recipes. Reject a result from a different snapshot;
        // do not rediscover patterns, rank moves or inspect the refill stream.
        guard choice.recipes.allSatisfy({ recipe in
            (4...7).contains(recipe.cells.count) && Set(recipe.cells).count == recipe.cells.count
                && recipe.cells.allSatisfy(Self.valid)
                && Set(recipe.cells.compactMap { board[$0.row * 7 + $0.column]?.id }) == recipe.starIDs
                && recipe.starIDs.count == recipe.cells.count
        }) else { return nil }
        result.append(Frame(board: board, exchange: nil, recipes: choice.recipes, step: choice.exchanges.count))
        frames = result
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<7).contains(cell.row) && (0..<7).contains(cell.column)
    }
}

/// A full-board fit with the same bottom-origin Core/top-origin reading map.
/// The gutter belongs to row/column labels, never to additional hit targets.
struct SkyFullBoardChoiceGeometry {
    let board: CGRect
    let step: CGFloat
    init?(size: CGSize) {
        guard size.width.isFinite, size.height.isFinite, size.width >= 112, size.height >= 112 else { return nil }
        let side = min(size.width, size.height) - 44
        board = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
        step = side / 7
    }
    func point(_ cell: Cell) -> CGPoint {
        CGPoint(x: board.minX + (CGFloat(cell.column) + 0.5) * step,
                y: board.minY + (6.5 - CGFloat(cell.row)) * step)
    }
    @MainActor func imageRect(at cell: Cell, grown: Bool) -> CGRect {
        let center = point(cell)
        let radius = step * (grown ? 0.40 : 0.29)
        let side = radius * 2 * CGFloat(SkyPiece.rasterSide) / SkyPiece.silhouetteSide
        return CGRect(x: center.x - side / 2, y: center.y - side / 2, width: side, height: side)
    }
}
