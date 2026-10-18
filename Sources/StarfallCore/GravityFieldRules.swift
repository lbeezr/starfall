import Foundation

public enum GravityKind: String, Codable, Sendable { case magnet, hole }
public enum SkyIdentity: Equatable, Sendable {
    case colored(Jewel), dusk, white, magnet, hole
}
public struct OrbitField: Codable, Equatable, Sendable {
    public let holeID: Int
    public let center: Cell
    public let slots: [Cell]
    public var windowsRemaining: Int
}
/// Fixed occupied anchors support the ordinary segments above them. No empty slot is reserved.
public enum GravityFieldRules {
    public static func height(_ board: [StarfallGem?], column: Int) -> Int {
        SkyBoardSettling.height(board, column: column)
    }
    public static func neighbors(_ cell: Cell) -> [Cell] {
        [Cell(cell.row+1,cell.column), Cell(cell.row,cell.column+1),
         Cell(cell.row-1,cell.column), Cell(cell.row,cell.column-1)]
            .filter { (0..<7).contains($0.row) && (0..<7).contains($0.column) }
    }
    public static func settle(_ board: [StarfallGem?], field: OrbitField?) -> [StarfallGem?] {
        SkyBoardSettling.settle(board, anchors: Set(field.map { $0.slots + [$0.center] } ?? []))
    }
    public static func collision(in board: [StarfallGem?], opened: Set<Cell>) -> Cell? {
        opened.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }.first { middle in
            guard (1..<6).contains(middle.column), board[middle.row*7+middle.column] == nil else { return false }
            return board[middle.row*7+middle.column-1]?.gravityKind == .magnet &&
                   board[middle.row*7+middle.column+1]?.gravityKind == .magnet
        }
    }
}
