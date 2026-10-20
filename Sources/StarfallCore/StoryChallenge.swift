import Foundation

/// Authored definitions preserve every previously shipped revision.
public struct StoryChallengeDefinition: Sendable {
    public let challenge: StarfallChallenge
    public let revision: Int
    public static let currentRevision = 2

    public init?(_ challenge: StarfallChallenge, revision: Int = currentRevision) {
        guard (1...Self.currentRevision).contains(revision),
              challenge == .firstLight || challenge == .ribbonCrossing else { return nil }
        self.challenge = challenge
        self.revision = revision
    }

    var seed: UInt64 { challenge == .firstLight ? 42 : 4_202 }
    var target: Int { challenge == .firstLight ? 150_000 : 220_000 }
    var balance: StarfallBalance {
        .init(pace: challenge == .firstLight ? .gentle : .steady, darkStars: .none)
    }
    var palette: [Jewel] {
        if revision == 1 { return [.rose, .aqua, .amber, .violet, .mint] }
        return challenge == .firstLight ? [.aqua, .rose, .violet] : [.aqua, .rose, .violet, .mint]
    }
    var initialBoard: [StarfallGem?] {
        // Lantern offers two independent taps and an aqua top to keep for growth.
        // Ribbon offers a five-aqua cross-component trace, a useful vertical swap,
        // and an ordinary three-aqua clear with recoverable remaining ingredients.
        let rows: [String]
        if revision == 1 {
            rows = challenge == .firstLight ? ["AAA.RRR", "AA....."] : ["ARAAA..", "RAR...."]
        } else {
            // Both start recipe-free. The near-square at lower left can begin
            // two causal phases in Lantern and three in Ribbon.
            rows = challenge == .firstLight
                ? ["AARVVRR", "ARAAVVV", "ARRAVRV", "ARA...."]
                : ["AARARMM", "ARAAMMV", "ARAVRVV", "VRAV..."]
        }
        let kinds: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                board[row * 7 + column] = StarfallGem(id: id, kind: kinds[symbol]!)
                id += 1
            }
        }
        return board
    }
    var initialLight: Int { initialBoard.compactMap { $0 }.reduce(0) { $0 + $1.value } }

    private var motifs: [(Jewel, [Int])] {
        let lantern: [(Jewel, [Int])] = [
            (.aqua, [0, 1, 2]), (.rose, [4, 5, 6]),
            (.amber, [0, 0]), (.amber, [0]),
            (.mint, [2, 3, 4]), (.violet, [6, 6, 6]),
            (.rose, [0, 1, 2]), (.aqua, [4, 5, 6]),
            (.mint, [6, 6]), (.mint, [6]),
            (.amber, [2, 3, 4]), (.violet, [0, 0, 0])
        ]
        let ribbon: [(Jewel, [Int])] = [
            // Ordinary opening clears leave the split aqua pair. These announced
            // columns first remove its rose cap, then reconnect it from below.
            (.rose, [0, 0, 0]), (.aqua, [0, 0, 0]), (.rose, [1, 1, 1]),
            (.aqua, [0, 2, 4]),
            (.aqua, [1, 3]), (.amber, [6, 6, 6]),
            (.mint, [0, 1, 2]), (.rose, [4, 5, 6]),
            (.violet, [0, 0]), (.violet, [0]),
            (.amber, [2, 4, 6]), (.amber, [3, 5]),
            (.mint, [0, 0, 0]), (.rose, [4, 4]),
            (.rose, [4]), (.aqua, [1, 2, 3]),
            (.violet, [4, 5, 6]), (.mint, [2, 2, 2])
        ]
        return challenge == .firstLight ? lantern : ribbon
    }

    func suppliedLight(after showers: Int) -> Int {
        precondition(showers >= 0 && showers < Int.max / 6)
        if revision == 2 { return showers * 5 }
        let motifs = motifs
        return showers / motifs.count * motifs.reduce(0) { $0 + $1.1.count }
            + motifs.prefix(showers % motifs.count).reduce(0) { $0 + $1.1.count }
    }

    /// Committed showers never inspect later actions or rewrite an announced preview.
    /// Mirrored motifs and a rotated palette develop the same readable techniques.
    func shower(number: Int) -> [IncomingStar] {
        precondition(number > 0 && number < Int.max / 6)
        if revision == 2 { return mixedShower(number: number) }
        let motifs = motifs
        let cycle = (number - 1) / motifs.count
        let motif = motifs[(number - 1) % motifs.count]
        // Freeze this order within revision 1 even if the global cast later expands.
        let palette: [Jewel] = [.rose, .aqua, .amber, .violet, .mint]
        let color = palette[(palette.firstIndex(of: motif.0)! + cycle) % palette.count]
        return motif.1.enumerated().map { offset, column in
            IncomingStar(id: (number - 1) * FallingSky.maximumShowerSize + offset,
                         kind: color, column: cycle.isMultiple(of: 2) ? column : 6 - column)
        }
    }

    /// Five mixed stars develop local near-squares and distant supports. Columns
    /// rotate around the board; each 21-wave cycle mirrors and changes families.
    /// This authored supply is independent of actions and never retargets a preview.
    private func mixedShower(number: Int) -> [IncomingStar] {
        let index = number - 1, cycle = index / 21, block = (index % 21) / 3
        let palette = palette
        let layouts: [[(Int, Int)]] = [
            [(0, 0), (1, 0), (2, 1), (4, 2), (5, 2)],
            [(0, 0), (1, 1), (2, 0), (4, 2), (5, 1)],
            [(0, 0), (1, 0), (2, 1), (4, 1), (5, 2)]
        ]
        return layouts[index % 3].enumerated().map { offset, ingredient in
            let column = (block * 2 + ingredient.0) % 7
            return IncomingStar(id: index * FallingSky.maximumShowerSize + offset,
                                kind: palette[(block + ingredient.1 + cycle) % palette.count],
                                column: cycle.isMultiple(of: 2) ? column : 6 - column)
        }
    }
}
