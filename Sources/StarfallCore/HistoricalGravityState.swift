/// Historical gravity state, isolated from the current game's clock, RNG, score and saves.
/// FallingSky applies this value at its committed mutation boundary; no encoded fields move.
struct HistoricalGravityState {
    var board: [StarfallGem?]
    var orbit: OrbitField?
    var nextGravityID: Int?
    var retiredMagnetic: Int?
    let starsLanded: Int

    private func gem(at cell: Cell) -> StarfallGem? {
        guard (0..<7).contains(cell.row), (0..<7).contains(cell.column) else { return nil }
        return board[cell.row*7+cell.column]
    }
    private func recordPhase(_ event: SkyPresentationPhase.Event, into phases: inout [SkyPresentationPhase]) {
        phases.append(.init(event: event, board: board, field: orbit))
    }
    mutating func allocateGravityID() -> Int {
        let id = max(nextGravityID ?? starsLanded, starsLanded)
        nextGravityID = id + 1
        return id
    }
    mutating func closeOrbit(into phases: inout [SkyPresentationPhase], settles: Bool = true) {
        guard let field = orbit else { return }
        board[field.center.row*7+field.center.column] = nil
        retiredMagnetic = (retiredMagnetic ?? 0) + 2
        orbit = nil
        recordPhase(.release, into: &phases)
        if settles {
            board = GravityFieldRules.settle(board, field: nil)
            recordPhase(.settling, into: &phases)
        }
    }
    mutating func resolveGravityClear(_ selected: Set<Cell>, dark: Set<Cell>, into phases: inout [SkyPresentationPhase]) -> Set<Cell> {
        let hadOrbit = orbit != nil
        let removed = selected.union(dark)
        let captiveHit = orbit.map { !selected.isDisjoint(with: $0.slots) } ?? false
        for cell in removed { board[cell.row*7+cell.column] = nil }
        recordPhase(.removal, into: &phases)
        if captiveHit { closeOrbit(into: &phases, settles: false) }
        let middle = hadOrbit ? nil : GravityFieldRules.collision(in: board, opened: removed)
        let pair: Set<Cell> = middle.map { [Cell($0.row,$0.column-1),Cell($0.row,$0.column+1)] } ?? []
        let nearby = Set(selected.flatMap(GravityFieldRules.neighbors)).subtracting(pair)
        for cell in nearby where board[cell.row*7+cell.column]?.gravityKind == .magnet {
            board[cell.row*7+cell.column] = nil
            retiredMagnetic = (retiredMagnetic ?? 0) + 1
        }
        var newbornID: Int?
        if let middle {
            for cell in pair { board[cell.row*7+cell.column] = nil }
            let id = allocateGravityID(); newbornID = id
            board[middle.row*7+middle.column] = StarfallGem(id: id, kind: nil, gravity: .hole)
            recordPhase(.collision, into: &phases)
        }
        board = GravityFieldRules.settle(board, field: orbit)
        recordPhase(.settling, into: &phases)
        if let id = newbornID, let index = board.firstIndex(where: { $0?.id == id }) {
            let center = Cell(index/7,index%7)
            let slots = GravityFieldRules.neighbors(center).filter { board[$0.row*7+$0.column]?.kind != nil }
            orbit = OrbitField(holeID: id, center: center, slots: slots, windowsRemaining: 3)
            recordPhase(.capture, into: &phases)
            if slots.count < 2 { closeOrbit(into: &phases) }
        }
        return removed
    }
    mutating func advanceOrbit(into phases: inout [SkyPresentationPhase]) {
        guard var field = orbit else { return }
        if field.windowsRemaining == 1 { closeOrbit(into: &phases); return }
        let occupants = field.slots.map { board[$0.row*7+$0.column] }
        for index in field.slots.indices {
            let target = field.slots[(index+1)%field.slots.count]
            board[target.row*7+target.column] = occupants[index]
        }
        field.windowsRemaining -= 1; orbit = field
        recordPhase(.rotation, into: &phases)
    }
    var isValid: Bool {
        let special = board.compactMap { $0 }.filter { $0.gravityKind != nil }
        guard special.allSatisfy({ $0.kind == nil && !$0.grown && !$0.isLight }),
              retiredMagnetic.map({ $0 >= 0 && $0 <= starsLanded }) ?? true,
              nextGravityID.map({ $0 >= starsLanded && $0 < Int.max/2 }) ?? true else { return false }
        if let field = orbit {
            guard (0..<7).contains(field.center.row), (0..<7).contains(field.center.column),
                  (1...3).contains(field.windowsRemaining), (2...4).contains(field.slots.count),
                  Set(field.slots).count == field.slots.count,
                  field.slots == GravityFieldRules.neighbors(field.center).filter({ field.slots.contains($0) }),
                  gem(at: field.center)?.gravityKind == .hole, gem(at: field.center)?.id == field.holeID,
                  field.slots.allSatisfy({ gem(at: $0)?.kind != nil }),
                  special.filter({ $0.gravityKind == .hole }).count == 1 else { return false }
        } else if special.contains(where: { $0.gravityKind == .hole }) { return false }
        return GravityFieldRules.settle(board, field: orbit) == board
    }
}
