import Foundation

/// Separate accumulation experiment with deterministic shower events. The original Game is unchanged.
public struct StarfallGem: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel?
    public var grown: Bool
    public var isDark: Bool { kind == nil }
    public var value: Int { isDark ? 0 : grown ? 2 : 1 }
    public init(id: Int, kind: Jewel?, grown: Bool = false) {
        self.id = id; self.kind = kind; self.grown = grown
    }
}

public struct IncomingStar: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel?
    public let column: Int
    public var isDark: Bool { kind == nil }
    public init(id: Int, kind: Jewel?, column: Int) {
        self.id = id; self.kind = kind; self.column = column
    }
}

public struct StarfallExperimentTurn: Sendable {
    public struct Arrival: Sendable {
        public let star: IncomingStar
        public let cell: Cell
        public let gem: StarfallGem
        public let grew: Bool
    }
    public let cleared: Set<Cell>
    public let collected: Int
    public let settled: [StarfallGem?]
    public let forecast: [IncomingStar]
    public let arrivals: [Arrival]
    public let blockedColumn: Int?
}

public struct StarfallExperiment: Codable, Equatable, Sendable {
    public static let side = 7
    public static let maximumShowerSize = 5
    public static let showerSizes = [1, 2, 3, 5]
    public private(set) var board: [StarfallGem?]
    public private(set) var incoming: [IncomingStar]
    public private(set) var score = 0
    public private(set) var turns = 0
    public private(set) var starsLanded = 0
    public private(set) var darkStarsCleared = 0
    public private(set) var blockedColumn: Int?
    public let seed: UInt64
    private var random: SeededRandom
    private var remainingColumns: [Int] = []
    private var showersUntilDark = 5
    // Optional storage lets pre-tuning v3 saves retain their board and original balance.
    private var savedBalance: StarfallBalance?
    // Missing in older saves: retain their original independent-color sky.
    private var cohesiveShowers: Bool?
    public var balance: StarfallBalance { savedBalance ?? StarfallBalance() }
    public var isOver: Bool { blockedColumn != nil }
    public var occupiedCount: Int { board.compactMap { $0 }.count }

    public init(seed: UInt64, balance: StarfallBalance = StarfallBalance()) {
        self.seed = seed
        savedBalance = balance
        cohesiveShowers = true
        showersUntilDark = balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0
        random = SeededRandom(seed: seed)
        board = Array(repeating: nil, count: Self.side * Self.side)
        incoming = []
        incoming = nextShower()
    }

    // Internal deterministic positions for rule tests, not an app customization API.
    init(board: [StarfallGem?], incoming: [IncomingStar], seed: UInt64 = 1) {
        precondition(board.count == 49 && Self.showerSizes.contains(incoming.count))
        self.seed = seed; self.board = board; self.incoming = incoming
        starsLanded = board.compactMap { $0 }.reduce(0) { $0 + ($1.isDark ? 1 : $1.value) }
        random = SeededRandom(seed: seed)
    }

    /// Keep the board and announced preview; new frequency starts with later previews.
    public mutating func setBalance(_ newBalance: StarfallBalance) {
        if newBalance.darkStars != balance.darkStars {
            showersUntilDark = newBalance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0
        }
        savedBalance = newBalance
    }

    public func gem(at cell: Cell) -> StarfallGem? {
        guard (0..<Self.side).contains(cell.row), (0..<Self.side).contains(cell.column) else { return nil }
        return board[cell.row * Self.side + cell.column]
    }

    private func neighbors(of cell: Cell) -> [Cell] {
        [Cell(cell.row-1, cell.column), Cell(cell.row+1, cell.column),
         Cell(cell.row, cell.column-1), Cell(cell.row, cell.column+1)]
    }

    /// Only orthogonal neighbors are shaded. Existing growth and matching stay intact.
    public func isGrowthBlocked(at cell: Cell) -> Bool {
        guard let jewel = gem(at: cell), !jewel.isDark else { return false }
        return neighbors(of: cell).contains { gem(at: $0)?.isDark == true }
    }

    public func darkStarsBeside(_ cells: Set<Cell>) -> Set<Cell> {
        Set(cells.flatMap { neighbors(of: $0) }.filter { gem(at: $0)?.isDark == true })
    }

    public func group(at start: Cell) -> Set<Cell> {
        guard let kind = gem(at: start)?.kind else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for next in neighbors(of: cell) {
                if !found.contains(next), gem(at: next)?.kind == kind {
                    found.insert(next); pending.append(next)
                }
            }
        }
        return found
    }

    public var legalGroups: [[Cell]] {
        var seen: Set<Cell> = [], groups: [[Cell]] = []
        for row in 0..<Self.side { for column in 0..<Self.side {
            let cell = Cell(row, column)
            guard !seen.contains(cell) else { continue }
            let group = group(at: cell); seen.formUnion(group)
            if value(of: group) >= 3 {
                groups.append(group.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row })
            }
        } }
        return groups
    }

    /// Growth counts toward both the clear threshold and collected starlight.
    public func value(of cells: Set<Cell>) -> Int {
        cells.reduce(0) { $0 + (gem(at: $1)?.value ?? 0) }
    }

    /// Invalid clears never advance the forecast, score, turn counter, or RNG.
    @discardableResult public mutating func clear(_ cell: Cell) -> StarfallExperimentTurn? {
        guard !isOver else { return nil }
        let cells = group(at: cell)
        guard value(of: cells) >= 3 else { return nil }
        let collected = value(of: cells)
        let darkStars = darkStarsBeside(cells)
        let removed = cells.union(darkStars)
        darkStarsCleared += darkStars.count
        score += collected
        for cell in removed { board[cell.row * Self.side + cell.column] = nil }
        for column in 0..<Self.side {
            let survivors = (0..<Self.side).compactMap { board[$0 * Self.side + column] }
            for row in 0..<Self.side {
                board[row * Self.side + column] = row < survivors.count ? survivors[row] : nil
            }
        }
        return .init(cleared: removed, collected: collected, settled: board,
                     forecast: incoming, arrivals: [], blockedColumn: nil)
    }

    /// Clock-independent event: the presentation layer decides when the sky advances.
    /// Clearing never consumes or regenerates this preview.
    @discardableResult public mutating func letStarsFall() -> StarfallExperimentTurn? {
        guard !isOver else { return nil }
        turns += 1
        let settled = board, forecast = incoming
        var arrivals: [StarfallExperimentTurn.Arrival] = []
        for star in forecast {
            let height = (0..<Self.side).filter { board[$0 * Self.side + star.column] != nil }.count
            // A matching small top jewel can grow even when its column is full.
            if !star.isDark, height > 0, var top = board[(height-1) * Self.side + star.column],
               top.kind == star.kind, !top.grown, !isGrowthBlocked(at: Cell(height-1, star.column)) {
                top.grown = true
                let cell = Cell(height-1, star.column)
                board[cell.row * Self.side + cell.column] = top
                starsLanded += 1
                arrivals.append(.init(star: star, cell: cell, gem: top, grew: true))
            } else {
                guard height < Self.side else { blockedColumn = star.column; break }
                let cell = Cell(height, star.column)
                let gem = StarfallGem(id: starsLanded, kind: star.kind)
                board[cell.row * Self.side + cell.column] = gem
                starsLanded += 1
                arrivals.append(.init(star: star, cell: cell, gem: gem, grew: false))
            }
        }
        if !isOver { incoming = nextShower() }
        return .init(cleared: [], collected: 0, settled: settled,
                     forecast: forecast, arrivals: arrivals, blockedColumn: blockedColumn)
    }

    private mutating func nextShower() -> [IncomingStar] {
        let sizes = [1, 2, 2, 3, 3, 3, 5]
        let naturalCount = sizes[Int(random.next() % UInt64(sizes.count))]
        // A dry board gets a useful run in its next forecast, plus two pressure
        // stars. Never rewrite an announced preview or alter the board for free.
        let heights = (0..<Self.side).map { column in
            (0..<Self.side).filter { board[$0 * Self.side + column] != nil }.count
        }
        let reliefColumn = cohesiveShowers == true && turns > 0 && legalGroups.isEmpty
            ? heights.indices.filter { heights[$0] <= 4 }.min { heights[$0] < heights[$1] } : nil
        let count = reliefColumn == nil ? naturalCount : 5
        let darkIndex: Int?
        if let gap = balance.darkStars.showerGap, showersUntilDark == 0 {
            darkIndex = reliefColumn == nil ? Int(random.next() % UInt64(count)) : 3 + Int(random.next() % 2)
            showersUntilDark = gap.lowerBound - 1 + Int(random.next() % UInt64(gap.count))
        } else {
            darkIndex = nil
            if balance.darkStars != .none { showersUntilDark -= 1 }
        }
        let sharedKind = cohesiveShowers == true ? random.jewel() : nil
        // A fresh sky teaches the clear immediately with three adjacent stars.
        // Keep column coverage fair by reserving the other four for later.
        if cohesiveShowers == true, turns == 0, starsLanded == 0 {
            let start = Int(random.next() % 5)
            remainingColumns = (0..<Self.side).filter { !(start..<(start + 3)).contains($0) }
            return (0..<3).map { IncomingStar(id: $0, kind: sharedKind!, column: start + $0) }
        }
        return (0..<count).map { offset in
            let kind = random.jewel()
            // Natural arrivals rotate through columns; relief runs deliberately
            // stack three matching stars in a low column to restore a choice.
            if remainingColumns.isEmpty { remainingColumns = Array(0..<Self.side) }
            let index = Int(random.next() % UInt64(remainingColumns.count))
            let naturalColumn = remainingColumns.remove(at: index)
            return IncomingStar(id: turns * Self.maximumShowerSize + offset, kind: offset == darkIndex ? nil : (sharedKind ?? kind),
                                column: offset < 3 ? (reliefColumn ?? naturalColumn) : naturalColumn)
        }
    }

    public var isValidSave: Bool {
        guard board.count == 49, Self.showerSizes.contains(incoming.count),
              remainingColumns.allSatisfy({ (0..<7).contains($0) }),
              Set(remainingColumns).count == remainingColumns.count,
              turns >= 0, turns < Int.max / 6, score >= 0, starsLanded >= 0,
              (0...(balance.darkStars.showerGap.map { $0.upperBound - 1 } ?? 0)).contains(showersUntilDark),
              darkStarsCleared >= 0, darkStarsCleared <= starsLanded,
              incoming.allSatisfy({ (0..<7).contains($0.column) && $0.id >= 0 }),
              blockedColumn.map({ (0..<7).contains($0) }) ?? true else { return false }
        let gems = board.compactMap { $0 }
        guard Set(gems.map(\.id)).count == gems.count,
              gems.allSatisfy({ $0.id >= 0 && $0.id < starsLanded && !($0.isDark && $0.grown) }),
              starsLanded <= turns * Self.maximumShowerSize,
              score == starsLanded - darkStarsCleared - gems.reduce(0, { $0 + ($1.isDark ? 1 : $1.value) }) else { return false }
        for column in 0..<7 {
            var foundSpace = false
            for row in 0..<7 {
                if board[row * 7 + column] == nil { foundSpace = true }
                else if foundSpace { return false }
            }
        }
        return true
    }
}
