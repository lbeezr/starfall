import Foundation

/// A recipe identifies the actual ingredients, not a screen-space outline.
public struct StarRecipe: Equatable, Sendable, Identifiable {
    public enum Shape: String, Codable, CaseIterable, Sendable { case square, cross }
    public let shape: Shape
    public let cells: [Cell]
    public let starIDs: Set<Int>
    public var id: String { shape.rawValue + ":" + starIDs.sorted().map(String.init).joined(separator: ",") }
}

extension StarRecipe {
    /// Bounded by 36 squares + 25 crosses on a 7×7 sky. Extra surrounding stars are not spent.
    static func find(in board: [StarfallGem?]) -> [StarRecipe] {
        func gem(at cell: Cell) -> StarfallGem? {
            guard (0..<7).contains(cell.row), (0..<7).contains(cell.column) else { return nil }
            return board[cell.row * 7 + cell.column]
        }
        func make(_ shape: Shape, cells: [Cell]) -> StarRecipe? {
            guard let kind = cells.compactMap({ gem(at: $0)?.kind }).first,
                  cells.allSatisfy({ gem(at: $0)?.kind == kind || gem(at: $0)?.isLight == true }) else { return nil }
            return StarRecipe(shape: shape, cells: cells, starIDs: Set(cells.compactMap { gem(at: $0)?.id }))
        }
        var result: [StarRecipe] = []
        for row in 0..<7 { for column in 0..<7 {
            let origin = Cell(row, column)
            let square = [origin, Cell(row, column+1), Cell(row+1, column), Cell(row+1, column+1)]
            if let recipe = make(.square, cells: square) { result.append(recipe) }
            let cross = [Cell(row-1, column), Cell(row, column-1), origin, Cell(row, column+1), Cell(row+1, column)]
            if let recipe = make(.cross, cells: cross) { result.append(recipe) }
        } }
        return result
    }
}

extension FallingSky {
    public var recipes: [StarRecipe] { StarRecipe.find(in: board) }

    public func recipes(containing cell: Cell) -> [StarRecipe] { recipes.filter { $0.cells.contains(cell) } }

    public func recipe(matching cells: Set<Cell>) -> StarRecipe? {
        recipes.first { Set($0.cells) == cells }
    }

    /// Compatibility name for the current authoritative selected-walk resolver.
    public func selectedClearCells(along path: [Cell]) -> Set<Cell>? { constellationCells(along:path) }

    public var canArrangeStars: Bool {
        !isOver && supportsArrangingStars && orbit == nil && !board.contains { $0?.gravityKind != nil }
    }

    public func canNudge(from: Cell, to: Cell) -> Bool {
        canArrangeStars
            && (0..<Self.side).contains(from.row) && (0..<Self.side).contains(from.column)
            && (0..<Self.side).contains(to.row) && (0..<Self.side).contains(to.column)
            && abs(from.row-to.row) + abs(from.column-to.column) == 1
            && gem(at: from) != nil
    }
}
