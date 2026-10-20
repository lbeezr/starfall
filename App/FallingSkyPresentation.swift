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
    mutating func begin(_ turn: FallingSkyTurn) -> Ticket {
        sequence &+= 1
        let ticket = Ticket(epoch: epoch, sequence: sequence)
        entries.append(Entry(ticket: ticket, turn: turn))
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
