import Foundation

/// Separate, turn-based accumulation experiment. The original Game is unchanged.
public struct StarfallGem: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel
    public var grown: Bool
    public var value: Int { grown ? 2 : 1 }
    public init(id: Int, kind: Jewel, grown: Bool = false) {
        self.id = id; self.kind = kind; self.grown = grown
    }
}

public struct IncomingStar: Codable, Equatable, Sendable, Identifiable {
    public let id: Int
    public let kind: Jewel
    public let column: Int
    public init(id: Int, kind: Jewel, column: Int) {
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
    public static let showerSize = 3
    public private(set) var board: [StarfallGem?]
    public private(set) var incoming: [IncomingStar]
    public private(set) var score = 0
    public private(set) var turns = 0
    public private(set) var starsLanded = 0
    public private(set) var blockedColumn: Int?
    public let seed: UInt64
    private var random: SeededRandom
    private var remainingColumns: [Int] = []
    public var isOver: Bool { blockedColumn != nil }
    public var occupiedCount: Int { board.compactMap { $0 }.count }

    public init(seed: UInt64) {
        self.seed = seed
        random = SeededRandom(seed: seed)
        board = Array(repeating: nil, count: Self.side * Self.side)
        incoming = []
        incoming = nextShower()
    }

    // Internal deterministic positions for rule tests, not an app customization API.
    init(board: [StarfallGem?], incoming: [IncomingStar], seed: UInt64 = 1) {
        precondition(board.count == 49 && incoming.count == Self.showerSize)
        self.seed = seed; self.board = board; self.incoming = incoming
        starsLanded = board.compactMap { $0 }.reduce(0) { $0 + $1.value }
        random = SeededRandom(seed: seed)
    }

    public func gem(at cell: Cell) -> StarfallGem? {
        guard (0..<Self.side).contains(cell.row), (0..<Self.side).contains(cell.column) else { return nil }
        return board[cell.row * Self.side + cell.column]
    }

    public func group(at start: Cell) -> Set<Cell> {
        guard let kind = gem(at: start)?.kind else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for next in [Cell(cell.row-1, cell.column), Cell(cell.row+1, cell.column),
                         Cell(cell.row, cell.column-1), Cell(cell.row, cell.column+1)] {
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
        return advance(clearing: cells)
    }

    /// Explicitly invite the previewed shower when no clear is wanted or possible.
    @discardableResult public mutating func letStarsFall() -> StarfallExperimentTurn? {
        guard !isOver else { return nil }
        return advance(clearing: [])
    }

    private mutating func advance(clearing cells: Set<Cell>) -> StarfallExperimentTurn {
        let collected = value(of: cells)
        score += collected; turns += 1
        for cell in cells { board[cell.row * Self.side + cell.column] = nil }
        for column in 0..<Self.side {
            let survivors = (0..<Self.side).compactMap { board[$0 * Self.side + column] }
            for row in 0..<Self.side {
                board[row * Self.side + column] = row < survivors.count ? survivors[row] : nil
            }
        }
        let settled = board, forecast = incoming
        var arrivals: [StarfallExperimentTurn.Arrival] = []
        for star in forecast {
            let height = (0..<Self.side).filter { board[$0 * Self.side + star.column] != nil }.count
            // A matching small top jewel can grow even when its column is full.
            if height > 0, var top = board[(height-1) * Self.side + star.column],
               top.kind == star.kind, !top.grown {
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
        return .init(cleared: cells, collected: collected, settled: settled,
                     forecast: forecast, arrivals: arrivals, blockedColumn: blockedColumn)
    }

    private mutating func nextShower() -> [IncomingStar] {
        (0..<Self.showerSize).map { offset in
            let kind = random.jewel()
            // Visit all seven columns in random order before repeating a column.
            // This keeps one unlucky column from filling before the field develops.
            if remainingColumns.isEmpty { remainingColumns = Array(0..<Self.side) }
            let index = Int(random.next() % UInt64(remainingColumns.count))
            return IncomingStar(id: turns * Self.showerSize + offset, kind: kind,
                                column: remainingColumns.remove(at: index))
        }
    }

    public var isValidSave: Bool {
        guard board.count == 49, incoming.count == Self.showerSize,
              remainingColumns.allSatisfy({ (0..<7).contains($0) }),
              Set(remainingColumns).count == remainingColumns.count,
              turns >= 0, turns < Int.max / 6, score >= 0, starsLanded >= 0,
              incoming.allSatisfy({ (0..<7).contains($0.column) && $0.id >= 0 }),
              blockedColumn.map({ (0..<7).contains($0) }) ?? true else { return false }
        let gems = board.compactMap { $0 }
        guard Set(gems.map(\.id)).count == gems.count,
              gems.allSatisfy({ $0.id >= 0 && $0.id < starsLanded }),
              starsLanded <= turns * Self.showerSize,
              score == starsLanded - gems.reduce(0, { $0 + $1.value }) else { return false }
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
