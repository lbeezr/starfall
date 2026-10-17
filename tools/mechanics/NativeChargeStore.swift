    // Injected inside the lab store. Intent is transient, never a save field.
    private(set) var chargeCell: Cell?
    @ObservationIgnored private var chargeSequence: UInt64 = 0
    @ObservationIgnored private var chargeCandidate: (ticket: UInt64, cell: Cell, snapshot: StarfallExperiment)?

    @discardableResult func prepareCharge(_ cell: Cell) -> UInt64? {
        cancelCharge()
        guard canClear, game.challenge == nil, game.value(of: game.group(at: cell)) >= 5 else { return nil }
        chargeSequence &+= 1
        chargeCandidate = (chargeSequence, cell, game)
        return chargeSequence
    }

    func armCharge(_ ticket: UInt64?) {
        guard let candidate = chargeCandidate, candidate.ticket == ticket else { return }
        guard canClear, candidate.snapshot == game else {
            cancelCharge(); return
        }
        chargeCell = candidate.cell
    }

    func cancelCharge() { chargeCell = nil; chargeCandidate = nil }

    func cancelCharge(_ ticket: UInt64?) {
        guard chargeCandidate?.ticket == ticket, ticket != nil else { return }
        cancelCharge()
    }

    func commitCharge(_ ticket: UInt64?) {
        guard let candidate = chargeCandidate, candidate.ticket == ticket else { return }
        guard canClear, chargeCell == candidate.cell, candidate.snapshot == game else {
            cancelCharge(); return
        }
        cancelCharge()
        clear(candidate.cell, charged: true)
    }

    func accessibleCharge(_ cell: Cell) {
        let ticket = prepareCharge(cell)
        armCharge(ticket); commitCharge(ticket)
    }
