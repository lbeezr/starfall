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
public struct GravityPhase: Sendable {
    public enum Event: String, Sendable { case removal, collision, settling, capture, rotation, release }
    public let event: Event
    public let board: [StarfallGem?]
    public let field: OrbitField?
}
public struct GravitySave: Codable {
    public let version: Int
    public let ruleset: String
    public let game: FallingSky
    public init(_ game: FallingSky) { version = 1; ruleset = "gravity-occupied-supports"; self.game = game }
    public static func restore(_ data: Data) -> FallingSky? {
        guard let saved = try? JSONDecoder().decode(Self.self, from: data), saved.version == 1,
              saved.ruleset == "gravity-occupied-supports", saved.game.isValidSave else { return nil }
        return saved.game
    }
}
/// Fixed occupied anchors support the ordinary segments above them. No empty slot is reserved.
public enum GravityFieldRules {
    public static func height(_ board: [StarfallGem?], column: Int) -> Int {
        (0..<7).last(where: { board[$0*7+column] != nil }).map { $0+1 } ?? 0
    }
    public static func neighbors(_ cell: Cell) -> [Cell] {
        [Cell(cell.row+1,cell.column), Cell(cell.row,cell.column+1),
         Cell(cell.row-1,cell.column), Cell(cell.row,cell.column-1)]
            .filter { (0..<7).contains($0.row) && (0..<7).contains($0.column) }
    }
    public static func settle(_ board: [StarfallGem?], field: OrbitField?) -> [StarfallGem?] {
        var result = board
        let anchors = Set(field.map { $0.slots + [$0.center] } ?? [])
        for column in 0..<7 {
            var base = 0
            let stops = (0..<7).filter { anchors.contains(Cell($0,column)) } + [7]
            for stop in stops {
                let survivors = (base..<stop).compactMap { board[$0*7+column] }
                for row in base..<stop { result[row*7+column] = row-base < survivors.count ? survivors[row-base] : nil }
                base = stop+1
            }
        }
        return result
    }
    public static func collision(in board: [StarfallGem?], opened: Set<Cell>) -> Cell? {
        opened.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }.first { middle in
            guard (1..<6).contains(middle.column), board[middle.row*7+middle.column] == nil else { return false }
            return board[middle.row*7+middle.column-1]?.gravityKind == .magnet &&
                   board[middle.row*7+middle.column+1]?.gravityKind == .magnet
        }
    }
}
