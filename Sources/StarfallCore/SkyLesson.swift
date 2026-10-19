import Foundation

/// Small authored demonstrations. They never create a campaign or own a saved round.
public enum SkyLesson: String, CaseIterable, Sendable {
    case square, cross, opal, relay

    public enum Move: Equatable, Sendable {
        case swap(Cell, Cell), trace([Cell]), tap(Cell)

        @discardableResult public func perform(in game: inout FallingSky) -> FallingSkyTurn? {
            switch self {
            case .swap(let from, let to): game.nudge(from: from, to: to)
            case .trace(let path): game.clearConstellation(path)
            case .tap(let cell): game.clear(cell)
            }
        }
    }

    public var moves: [Move] {
        switch self {
        case .square:
            [.swap(Cell(1,2), Cell(1,1)), .trace([Cell(0,0), Cell(0,1), Cell(1,1), Cell(1,0)])]
        case .cross:
            [.trace([Cell(1,1), Cell(2,1), Cell(1,1), Cell(1,0), Cell(1,1), Cell(1,2), Cell(1,1), Cell(0,1)])]
        case .opal: [.tap(Cell(0,0))]
        case .relay:
            [.tap(Cell(0,0)), .trace([Cell(0,1), Cell(0,2), Cell(1,2), Cell(1,1)])]
        }
    }

    public func game() -> FallingSky {
        let rows: [String]
        switch self {
        case .square: rows = ["AAP", "APA"]
        case .cross: rows = ["PAP", "AAA", "PAP"]
        case .opal: rows = ["AOAP"]
        case .relay: rows = ["SSA", "SSA", ".A", ".A"]
        }
        let kinds: [Character: Jewel] = ["A": .aqua, "P": .mint, "S": .amber]
        var board: [StarfallGem?] = Array(repeating: nil, count: FallingSky.side * FallingSky.side)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, key) in text.enumerated() where key != "." {
                board[row * FallingSky.side + column] = .init(id: id, kind: kinds[key], light: key == "O")
                id += 1
            }
        }
        return FallingSky(board: board, incoming: [.init(id: 100, kind: .rose, column: 6)])
    }
}
