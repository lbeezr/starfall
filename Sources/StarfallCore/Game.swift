import Foundation

public enum Jewel: Int, CaseIterable, Codable, Sendable { case rose, aqua, amber, violet, mint }
public enum Outcome: String, Codable, Sendable { case playing, won, lost }
public struct Cell: Hashable, Codable, Sendable {
    public let row: Int
    public let column: Int
    public init(_ row: Int, _ column: Int) { self.row = row; self.column = column }
}
/// Stable generator makes seeds and saved games reproducible across platforms.
public struct SeededRandom: RandomNumberGenerator, Codable, Equatable, Sendable {
    private var state: UInt64
    public init(seed: UInt64) { state = seed }
    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func jewel() -> Jewel { Jewel(rawValue: Int(next() % 5))! }
}
public struct Turn: Sendable {
    public let cleared: Set<Cell>
    public let reshuffled: Bool
}
/// Row zero is the bottom. Every clear scores exactly one point per jewel.
public struct Game: Codable, Equatable, Sendable {
    public static let side = 7
    public static let startingMoves = 18
    public static let target = 70
    public private(set) var board: [Jewel]
    public private(set) var moves: Int
    public private(set) var score: Int
    public private(set) var seed: UInt64
    private var random: SeededRandom
    public var outcome: Outcome { score >= Self.target ? .won : (moves == 0 ? .lost : .playing) }
    public init(seed: UInt64) {
        self.seed = seed; random = SeededRandom(seed: seed)
        moves = Self.startingMoves; score = 0; board = []
        for _ in 0..<(Self.side * Self.side) { board.append(random.jewel()) }
        ensureMove()
    }
    // Internal fixture initializer, deliberately not a public rule customization surface.
    init(board: [Jewel], moves: Int = Self.startingMoves, score: Int = 0, seed: UInt64 = 1) {
        precondition(board.count == Self.side * Self.side)
        self.board = board; self.moves = moves; self.score = score
        self.seed = seed; random = SeededRandom(seed: seed)
    }
    public func jewel(at cell: Cell) -> Jewel? {
        guard (0..<Self.side).contains(cell.row), (0..<Self.side).contains(cell.column) else { return nil }
        return board[cell.row * Self.side + cell.column]
    }
    public func group(at start: Cell) -> Set<Cell> {
        guard let kind = jewel(at: start) else { return [] }
        var found: Set<Cell> = [start], pending = [start]
        while let cell = pending.popLast() {
            for next in [Cell(cell.row-1, cell.column), Cell(cell.row+1, cell.column), Cell(cell.row, cell.column-1), Cell(cell.row, cell.column+1)] {
                if !found.contains(next), jewel(at: next) == kind { found.insert(next); pending.append(next) }
            }
        }
        return found
    }
    /// Each clearable connected group appears once, ordered by its first cell.
    /// Cells within each group are ordered by row, then column (bottom-to-top).
    /// This describes the board even after the game ends; `tap` still locks terminal games.
    public var legalGroups: [[Cell]] {
        var visited: Set<Cell> = []
        var groups: [[Cell]] = []
        for row in 0..<Self.side {
            for column in 0..<Self.side {
                let cell = Cell(row, column)
                guard !visited.contains(cell) else { continue }
                let connected = group(at: cell)
                visited.formUnion(connected)
                if connected.count >= 3 {
                    groups.append(connected.sorted {
                        $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
                    })
                }
            }
        }
        return groups
    }
    public var hasMove: Bool { !legalGroups.isEmpty }
    @discardableResult public mutating func tap(_ cell: Cell) -> Turn? {
        guard outcome == .playing else { return nil }
        let cleared = group(at: cell)
        guard cleared.count >= 3 else { return nil }
        moves -= 1; score += cleared.count
        for column in 0..<Self.side {
            var survivors = (0..<Self.side).filter { !cleared.contains(Cell($0, column)) }.map { board[$0 * Self.side + column] }
            while survivors.count < Self.side { survivors.append(random.jewel()) }
            for row in 0..<Self.side { board[row * Self.side + column] = survivors[row] }
        }
        let reshuffled = outcome == .playing && !hasMove
        if reshuffled { ensureMove() }
        return Turn(cleared: cleared, reshuffled: reshuffled)
    }
    /// Bounded recovery: a stalled board receives a guaranteed three-jewel group, free of charge.
    private mutating func ensureMove() {
        guard !hasMove else { return }
        let kind = random.jewel()
        board[0] = kind; board[1] = kind; board[2] = kind
    }
    public var isValidSave: Bool {
        guard board.count == Self.side * Self.side,
              (0...Self.startingMoves).contains(moves) else { return false }
        let turnsTaken = Self.startingMoves - moves
        // Every spent move clears at least three jewels. A game stops as soon as it
        // wins, so the last clear can add at most one full board to a score of 69.
        guard score >= turnsTaken * 3,
              score <= turnsTaken * Self.side * Self.side,
              score <= Self.target - 1 + Self.side * Self.side else { return false }
        return outcome != .playing || hasMove
    }
}
