
/// Transient input ticket. Core remains the authority for whether a walk can clear.
@MainActor final class ConstellationTraceIntent {
    var lastFinger: CGPoint?
    private(set) var path: [Cell] = []
    private(set) var snapshot: FallingSky?
    private(set) var generation: UInt64 = 0
    private(set) var sequence: UInt64 = 0
    var count: Int { Set(path).count }
    var value: Int { snapshot?.value(of: Set(path)) ?? 0 }

    @discardableResult func begin(_ cell: Cell, game: FallingSky, generation: UInt64, enabled: Bool) -> UInt64? {
        cancel()
        guard enabled, !game.isOver, game.group(at: cell).count >= 5 else { return nil }
        sequence &+= 1
        snapshot = game; self.generation = generation; path = [cell]
        return sequence
    }
    @discardableResult func visit(_ cell: Cell, ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> Bool {
        guard ticket == sequence, snapshot != nil else { return false }
        guard enabled, snapshot == game, self.generation == generation,
              let last = path.last, path.count < 196,
              game.gem(at: cell)?.kind == game.gem(at: last)?.kind,
              abs(cell.row-last.row) <= 1, abs(cell.column-last.column) <= 1 else {
            cancel(); return false
        }
        if cell == last { return false }
        path.append(cell)
        return true
    }
    func finish(ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> (path: [Cell], snapshot: FallingSky, generation: UInt64)? {
        defer { cancel() }
        guard ticket == sequence, let snapshot, snapshot == game, self.generation == generation,
              enabled, game.constellationCells(along: path) != nil else { return nil }
        return (path, snapshot, generation)
    }
    func cancel() { lastFinger = nil; path = []; snapshot = nil; sequence &+= 1 }
}
