import Foundation

/// Immutable receipt for one committed clear. Light remains the conserved ledger.
public struct SkyScoreAward: Equatable, Sendable {
    public let baseLight: Int
    public let clearedStarCount: Int
    public let bonus: Int
    public let displayPoints: Int

    init(baseLight: Int, clearedStarCount: Int) {
        self.baseLight = baseLight
        self.clearedStarCount = clearedStarCount
        bonus = max(0, clearedStarCount - 3) * 1_000
        displayPoints = baseLight * 1_000 + bonus
    }
}

/// A bounded histogram validates earned bonuses without an unbounded event log.
struct StoryScoreLedger: Codable, Equatable, Sendable {
    private(set) var clearCounts = Array(repeating: 0, count: 50)

    mutating func record(stars: Int) {
        precondition((2...49).contains(stars))
        clearCounts[stars] += 1
    }

    var bonusUnits: Int {
        guard clearCounts.count == 50, clearCounts.allSatisfy({ (0...1_000).contains($0) }) else { return Int.max }
        return clearCounts.enumerated().reduce(0) { $0 + $1.element * max(0, $1.offset - 3) }
    }

    func isValid(light: Int, target: Int) -> Bool {
        guard clearCounts.count == 50, clearCounts[0] == 0, clearCounts[1] == 0,
              (0...(target / 1_000 + 98)).contains(light),
              clearCounts.allSatisfy({ (0...light).contains($0) }) else { return false }
        let stars = clearCounts.enumerated().reduce(0) { $0 + $1.offset * $1.element }
        guard stars <= light, light <= stars * 2 else { return false }
        // Before the last clear the target was unmet; one clear spends at most 49 grown stars.
        return light + bonusUnits < target / 1_000 + 144
    }
}

/// Revision 1 content for the first two repairs. Historical challenge IDs stay intact.
struct StoryChallengeDefinition: Sendable {
    let challenge: StarfallChallenge
    static let revision = 1

    init?(_ challenge: StarfallChallenge) {
        guard challenge == .firstLight || challenge == .ribbonCrossing else { return nil }
        self.challenge = challenge
    }

    var seed: UInt64 { challenge == .firstLight ? 42 : 4_202 }
    var target: Int { challenge == .firstLight ? 150_000 : 220_000 }
    var balance: StarfallBalance {
        .init(pace: challenge == .firstLight ? .gentle : .steady, darkStars: .none)
    }
    var initialBoard: [StarfallGem?] {
        // Lantern offers two independent taps and an aqua top to keep for growth.
        // Ribbon offers a five-aqua cross-component trace, a useful vertical swap,
        // and an ordinary three-aqua clear with recoverable remaining ingredients.
        let rows = challenge == .firstLight ? ["AAA.RRR", "AA....."] : ["ARAAA..", "RAR...."]
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                board[row * 7 + column] = StarfallGem(id: id, kind: symbol == "A" ? .aqua : .rose)
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
        let motifs = motifs
        return showers / motifs.count * motifs.reduce(0) { $0 + $1.1.count }
            + motifs.prefix(showers % motifs.count).reduce(0) { $0 + $1.1.count }
    }

    /// Committed showers never inspect later actions or rewrite an announced preview.
    /// Mirrored motifs and a rotated palette develop the same readable techniques.
    func shower(number: Int) -> [IncomingStar] {
        precondition(number > 0 && number < Int.max / 6)
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
}
