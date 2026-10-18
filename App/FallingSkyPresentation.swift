import StarfallCore

extension FallingSkyTurn {
    /// Orbit formation/release can move stars across columns and remains atomic.
    /// Ordinary gravity and showers reserve only their changing columns.
    var changingColumns: Set<Int> {
        if !gravityPhases.isEmpty { return Set(0..<7) }
        return Set(cleared.map(\.column)).union(arrivals.map { $0.cell.column }).union(duskAffectedColumns)
    }
}
