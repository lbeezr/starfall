import StarfallCore

extension FallingSkyTurn {
    /// Committed multi-phase collapses and historical orbits remain atomic.
    /// Ordinary falls and showers reserve only their changing columns.
    var changingColumns: Set<Int> {
        if !presentationPhases.isEmpty || !resolutionPhases.isEmpty { return Set(0..<7) }
        return Set(cleared.map(\.column)).union(arrivals.map { $0.cell.column }).union(duskAffectedColumns).union(stellarAffectedColumns).union(exchange.map { [$0.from.column,$0.to.column] } ?? [])
    }
}


/// Owns only outstanding committed presentations. The store retains clocks and input.
struct SkyPresentationLedger {
    struct Ticket: Equatable {
        fileprivate let epoch: UInt64
        fileprivate let sequence: UInt64
    }
    private struct Entry {
        let ticket: Ticket
        let turn: FallingSkyTurn
        let stableCells: [Cell: Int]
    }
    private var epoch: UInt64 = 0
    private var sequence: UInt64 = 0
    private var entries: [Entry] = []
    var busy: Bool { !entries.isEmpty }
    var pending: FallingSkyTurn? {
        entries.first(where: { !$0.turn.arrivals.isEmpty })?.turn ?? entries.last?.turn
    }
    var changingColumns: Set<Int> {
        entries.reduce(into: []) { $0.formUnion($1.turn.changingColumns) }
    }
    /// Input can name only identities that remain visibly in the same cell
    /// throughout these committed snapshots. Node coordinates never decide it.
    func preservesInputIdentity(at cell: Cell, id: Int) -> Bool {
        entries.allSatisfy { $0.stableCells[cell] == id }
    }
    mutating func begin(_ turn: FallingSkyTurn, from old: FallingSky? = nil, to game: FallingSky? = nil) -> Ticket {
        sequence &+= 1
        let ticket = Ticket(epoch: epoch, sequence: sequence)
        var snapshots = old.map { [$0.board] } ?? []
        for phase in turn.resolutionPhases {
            snapshots += [phase.before, phase.settled]
            if !phase.refillArrivals.isEmpty { snapshots.append(phase.refilled) }
        }
        for phase in turn.presentationPhases { snapshots.append(phase.board) }
        snapshots.append(turn.settled)
        if let game { snapshots.append(game.board) }
        var stable: [Cell: Int] = [:]
        if let final = snapshots.last {
            for (index, gem) in final.enumerated() {
                guard let gem, snapshots.allSatisfy({ $0[index]?.id == gem.id }) else { continue }
                stable[Cell(index / 7, index % 7)] = gem.id
            }
        }
        if let exchange = turn.exchange {
            // An empty upward exchange can settle back to its original cell.
            // Equal before/final snapshots do not make that visible trip idle.
            let movingIDs = Set([old?.gem(at: exchange.from)?.id, old?.gem(at: exchange.to)?.id].compactMap { $0 })
            stable = stable.filter {
                $0.key != exchange.from && $0.key != exchange.to && !movingIDs.contains($0.value)
            }
        }
        entries.append(Entry(ticket: ticket, turn: turn, stableCells: stable))
        return ticket
    }
    @discardableResult mutating func complete(_ ticket: Ticket) -> Bool {
        guard ticket.epoch == epoch, let index = entries.firstIndex(where: { $0.ticket == ticket }) else { return false }
        entries.remove(at: index)
        return true
    }
    func isLatest(_ ticket: Ticket) -> Bool {
        ticket.epoch == epoch && ticket.sequence == sequence
    }
    func isActive(_ ticket: Ticket) -> Bool {
        ticket.epoch == epoch && entries.contains { $0.ticket == ticket }
    }
    mutating func invalidate() {
        epoch &+= 1
        entries.removeAll()
    }
}
