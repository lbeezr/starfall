import Foundation

/// Authored definitions preserve every previously shipped revision.
public struct StoryChallengeDefinition: Sendable {
    public let challenge: StarfallChallenge
    public let revision: Int
    public static let currentRevision = 4
    /// Full Board develops independently; ordinary new Story visits stay on four.
    public static let maximumSupportedRevision = 6
    public var usesFullBoardRefill: Bool { challenge == .firstLight && (5...6).contains(revision) }

    public init?(_ challenge: StarfallChallenge, revision: Int = currentRevision) {
        guard (1...Self.maximumSupportedRevision).contains(revision),
              revision < 5 || challenge == .firstLight else { return nil }
        switch challenge {
        case .firstLight, .ribbonCrossing: break
        case .kiteHarbor, .seedMoon, .silverPools:
            guard revision == 4 else { return nil }
        default: return nil
        }
        self.challenge = challenge
        self.revision = revision
    }

    var seed: UInt64 {
        switch challenge {
        case .firstLight, .kiteHarbor, .seedMoon, .silverPools: return 42
        case .ribbonCrossing: return 4_202
        default: preconditionFailure("Unsupported authored challenge")
        }
    }
    var automaticLineLength: Int? {
        switch revision {
        case 3: return 7
        case 4, 5, 6: return 4
        default: return nil
        }
    }
    var target: Int {
        switch challenge {
        case .firstLight: return 150_000
        case .ribbonCrossing: return 220_000
        case .kiteHarbor: return 17_000
        case .seedMoon: return 11_000
        case .silverPools: return 12_000
        default: preconditionFailure("Unsupported authored challenge")
        }
    }
    var balance: StarfallBalance {
        switch challenge {
        case .firstLight, .kiteHarbor, .seedMoon, .silverPools: return .init(pace: .gentle, darkStars: .none)
        case .ribbonCrossing: return .init(pace: .steady, darkStars: .none)
        default: preconditionFailure("Unsupported authored challenge")
        }
    }
    var palette: [Jewel] {
        if revision == 1 { return [.rose, .aqua, .amber, .violet, .mint] }
        if revision >= 3 { return [.aqua, .rose, .violet, .mint, .amber] }
        return challenge == .firstLight ? [.aqua, .rose, .violet] : [.aqua, .rose, .violet, .mint]
    }
    var initialBoard: [StarfallGem?] {
        let rows: [String]
        if usesFullBoardRefill {
            // Recipe-free, five-family full board. The same lower-left exchange
            // starts a survivor chain. Six changes two upper ingredients so the
            // welcome leaves more of the unchanged objective for later choices.
            rows = revision == 5
                ? ["AARVVMY", "ARAYMRM", "VRVAYMM", "YRYMMMR", "YVRYYYM", "VAMVMYA", "MAAVRMV"]
                : ["AARVVMY", "ARAYMRM", "VRVAYMM", "YRYMMMR", "YARYYYM", "VARVMYA", "MAAVRMV"]
        } else if challenge == .kiteHarbor {
            // Choose high-column room or a larger low clear. Both choices keep
            // the same supply and can recover the remaining crowded column.
            rows = ["AVAARAA", "ARMYAMY", "RAVR...", "AM.....", "MY.....", "VR....."]
        } else if challenge == .seedMoon {
            // The grown aqua can join the immediate low line or be moved into
            // a larger pattern. Both choices leave a short legal restoration.
            rows = ["AAARAVY", "ARARAMV", "RMVARYM", ".....RA"]
        } else if challenge == .silverPools {
            // Clearing the rose support drops an aqua into the lower line.
            // Taking that line first leaves a separate rose-line recovery.
            rows = ["AARAAMV", "VMARYRA", "MVRA...", "YAR....", "MRA...."]
        } else if revision == 1 {
            // Retain the original explicit-clear openings and all of their identities.
            rows = challenge == .firstLight ? ["AAA.RRR", "AA....."] : ["ARAAA..", "RAR...."]
        } else if revision == 2 {
            // Both start recipe-free. The near-square at lower left can begin
            // two causal phases in Lantern and three in Ribbon.
            rows = challenge == .firstLight
                ? ["AARVVRR", "ARAAVVV", "ARRAVRV", "ARA...."]
                : ["AARARMM", "ARAAMMV", "ARAVRVV", "VRAV..."]
        } else {
            // Preserve the five-family revision-three openings. The lower-left
            // exchange earns a two-/three-phase cascade; revision four adds a
            // short-line opportunity without changing a single opening star.
            rows = challenge == .firstLight
                ? ["AARVVMY", "ARAYMRM", "VRVAYMM", "YRY...."]
                : ["AARMVYY", "ARAMYAY", "MRMVVYV", "VRMR..."]
        }
        let kinds: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                board[row * 7 + column] = StarfallGem(id: id, kind: kinds[symbol]!,
                                                    grown: challenge == .seedMoon && id == 1)
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
        if usesFullBoardRefill { return 0 }
        if revision >= 2 { return showers * 5 }
        let motifs = motifs
        return showers / motifs.count * motifs.reduce(0) { $0 + $1.1.count }
            + motifs.prefix(showers % motifs.count).reduce(0) { $0 + $1.1.count }
    }

    /// Committed showers never inspect later actions or rewrite an announced preview.
    /// Mirrored motifs and a rotated palette develop the same readable techniques.
    func shower(number: Int) -> [IncomingStar] {
        precondition(number > 0 && number < Int.max / 6)
        if usesFullBoardRefill { return [] }
        if revision >= 3 { return shuffledShower(number: number) }
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

    /// Two of each family per ten arrivals; five arrivals per column every seven
    /// showers. Independent seeded bags give finite droughts without consulting
    /// the board, changing an announced forecast, or targeting the current board.
    private func shuffledShower(number: Int) -> [IncomingStar] {
        let index = number - 1, colorBlock = index / 2
        let palette = palette
        let bag = (0..<10).map { palette[($0 + colorBlock) % palette.count] }
        // These salts freeze independent color/column streams for revision three;
        // they select reproducible permutations, not difficulty or board relief.
        var colorRandom = SeededRandom(seed: UInt64(colorBlock) &* 0x45d9f3b &+ seed)
        var colors = shuffled(bag, using: &colorRandom)
        for _ in 0..<50 {
            if colors[0] != colors[1], colors[8] != colors[9] { break }
            colors = shuffled(bag, using: &colorRandom)
        }
        // Distinct endpoints bound equal-family runs to two even across bags.
        // This deterministic fallback preserves every bag's counts and the RNG bound.
        if colors[0] == colors[1], let other = (2..<8).first(where: { colors[$0] != colors[0] }) {
            colors.swapAt(1, other)
        }
        if colors[8] == colors[9], let other = (2..<8).first(where: { colors[$0] != colors[8] }) {
            colors.swapAt(8, other)
        }
        let columnBlock = index / 7
        var columnRandom = SeededRandom(seed: UInt64(columnBlock) &* 0x7fffffff &+ seed &- 1)
        let columns = shuffled(Array(0..<7), using: &columnRandom)
        return (0..<5).map { offset in
            IncomingStar(id: index * FallingSky.maximumShowerSize + offset,
                         kind: colors[(index % 2) * 5 + offset],
                         column: columns[((index % 7) * 5 + offset) % 7])
        }
    }

    /// Freeze the Fisher–Yates draw order for authored replay across Swift releases.
    private func shuffled<Value>(_ values: [Value], using random: inout SeededRandom) -> [Value] {
        var result = values
        for index in stride(from: result.count - 1, through: 1, by: -1) {
            result.swapAt(index, Int(random.next() % UInt64(index + 1)))
        }
        return result
    }
}
