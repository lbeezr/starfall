#if DEBUG
import Foundation

/// Debug-only deterministic input fixtures; never loaded without an explicit reset argument.
public enum ConstellationFixture: String, CaseIterable {
    case five, fourGrown, overlap, darkness, diagonalSix, opalChoice, opalTrace, stormWarning
    public var title: String {
        switch self {
        case .opalTrace: "Trace through an Opal Orb"
        case .opalChoice: "An orb shared by different colors"
        case .stormWarning: "A storm approaches"
        case .diagonalSix: "Six diagonal stars"
        case .five: "Five pink stars"
        case .fourGrown: "Four large diagonal stars"
        case .overlap: "Connected seven-star group"
        case .darkness: "Five stars beside darkness"
        }
    }
    public func game() -> FallingSky {
        if self == .opalChoice || self == .opalTrace || self == .stormWarning { return naturalMechanicsSky() }
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
    /// Real seeded history: no invented board, counters or preview. Native checks
    /// can restore this through the same validated archive as ordinary play.
    private func naturalMechanicsSky() -> FallingSky {
        let configuration: (seed: UInt64, last: Int, retainOpals: Bool)
        switch self {
        case .opalChoice: configuration = (1, 18, true)
        case .opalTrace: configuration = (3, 12, true)
        case .stormWarning: configuration = (17, 8, false)
        default: preconditionFailure("Not a mechanics history fixture")
        }
        let last = configuration.last
        var game = FallingSky(seed: configuration.seed, generation: .current)
        for number in 1...last {
            precondition(game.letStarsFall() != nil && !game.isOver)
            if configuration.retainOpals {
                guard number >= 6, number < last else { continue }
                if let group = game.legalGroups.filter({ group in
                    !group.contains { game.gem(at: $0)?.isLight == true }
                }).min(by: { game.value(of: Set($0)) < game.value(of: Set($1)) }), let cell = group.first {
                    _ = game.clear(cell)
                }
            } else {
                for _ in 0..<49 {
                    guard let cell = game.legalGroups.first?.first else { break }
                    _ = game.clear(cell)
                }
            }
        }
        precondition(game.isValidSave)
        if configuration.retainOpals { precondition(game.board.contains { $0?.isLight == true }) }
        return game
    }

}

#endif
