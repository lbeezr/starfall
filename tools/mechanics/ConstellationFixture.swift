import Foundation

/// Only compiled into exported labs, never shipping core. All fixtures are valid committed saves.
public enum ConstellationFixture: String, CaseIterable {
    case five, fourGrown, overlap, darkness, diagonalSix
    public var title: String {
        switch self {
        case .diagonalSix: "Six diagonal stars"
        case .five: "Five pink stars"
        case .fourGrown: "Four large diagonal stars"
        case .overlap: "Connected seven-star group"
        case .darkness: "Five stars beside darkness"
        }
    }
    public func game() -> FallingSky {
        var pink: Set<Cell> = [Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)]
        if self == .diagonalSix { pink = Set((0..<6).map { Cell($0,$0) }) }
        if self == .fourGrown { pink = [Cell(0,0),Cell(1,1),Cell(2,2),Cell(3,3)] }
        if self == .overlap { pink.formUnion([Cell(0,5),Cell(0,6)]) }
        let dark: Set<Cell> = self == .darkness ? [Cell(0,3),Cell(0,2)] : []
        var board: [Any] = Array(repeating: NSNull(), count: 49)
        var id = 0, value = 0
        for column in 0..<7 {
            let height = pink.union(dark).filter { $0.column == column }.map(\.row).max() ?? -1
            guard height >= 0 else { continue }
            for row in 0...height {
                let cell = Cell(row,column), grown = self == .fourGrown && pink.contains(cell)
                var gem: [String: Any] = ["id": id, "grown": grown]
                if !dark.contains(cell) { gem["kind"] = (pink.contains(cell) ? Jewel.rose : Jewel.aqua).rawValue }
                board[row*7+column] = gem
                id += 1; value += grown ? 2 : 1
            }
        }
        var object = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky(seed: 5))) as! [String: Any]
        object["board"] = board; object["starsLanded"] = value; object["turns"] = (value+4)/5
        let result = try! JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        precondition(result.isValidSave && !result.isOver)
        return result
    }
}
