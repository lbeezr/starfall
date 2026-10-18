import Foundation
import StarfallCore

extension PacingMeasure {
    @MainActor static func checks() {
        checkCalibrationTraces()
        // Current native fixture: four overlapping sources, one arrival after swallow/settling.
        var pressure = CriticalMassFixture.game()
        let beforePressure = pressure
        let pressureTurn = pressure.letStarsFall()!
        precondition(pressureTurn.stellarCollapses.count == 4 && pressureTurn.arrivals.count == 1)
        let removed = pressureTurn.stellarCollapses.reduce(into: Set<Cell>()) { $0.formUnion($1.consumed); $0.insert($1.center) }
        precondition(removed.count < pressureTurn.stellarCollapses.reduce(0) { $0 + $1.consumed.count + 1 })
        // Independent fixture budget: 0.46 swallow + 0.40 phases, overlapping flight, then landing.
        precondition(abs(PacingPresenter.duration(of: pressureTurn, quiet: false) - 1.34) < 0.000001)
        precondition(abs(PacingPresenter.duration(of: pressureTurn, quiet: true) - 0.15) < 0.000001)
        let pressureClock = PacingClock()
        // A fresh clock/display pair below verifies actual completion ownership too.
        let ownedDisplay = PacingPresenter(pressureClock, quiet: false)
        var completions = 0
        ownedDisplay.animate(pressureTurn, from: beforePressure, to: pressure) { completions += 1 }
        precondition(ownedDisplay.collapseSources == 4 && ownedDisplay.swallowedCells == removed.count)
        precondition(completions == 0 && abs(ownedDisplay.finishAt! - 1.34) < 0.000001)
        pressureClock.now = ownedDisplay.finishAt!; ownedDisplay.finish(); ownedDisplay.finish()
        precondition(completions == 1 && ownedDisplay.pendingCount == 0)
        var ordinary = ConstellationFixture.singleGap.game()
        let ordinaryClear = ordinary.clear(Cell(0,0))!
        precondition(abs(PacingPresenter.duration(of: ordinaryClear, quiet: false) - 0.56) < 0.000001)
        var gravity = GravityFixture.opportunity.game()
        let gravityClear = gravity.clear(Cell(0,3))!
        precondition(gravityClear.arrivals.isEmpty && !gravityClear.gravityPhases.isEmpty)
        precondition(PacingPresenter.duration(of: gravityClear, quiet: false) ==
                     StarfallMotion.GravityTimeline(phases: gravityClear.gravityPhases.map(\.event), arrivals: 0).phaseEnd)
        // A recorded accepted-action script, replayed independently under both timing lookups.
        // Cadence lookup must never affect rule state or RNG, even after clear-induced relief.
        for seed in UInt64(0)..<16 {
            var a = FallingSky(seed: seed), b = a
            for _ in 0..<40 where !a.isOver {
                _ = a.cadenceStep
                _ = TimingCycleFixture.step(committedShowers: b.turns,pace: b.balance.pace)
                a.letStarsFall(); b.letStarsFall()
                precondition(a == b)
                if !a.isOver, let group = a.legalGroups.first, let cell = group.first {
                    let forecast = a.incoming
                    precondition(a.clear(cell) != nil && b.clear(cell) != nil)
                    precondition(a.incoming == forecast && a == b)
                }
            }
        }
        let clock = PacingClock()
        let presenter = PacingPresenter(clock,quiet: false)
        let name = "starfall.pacing.check.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"],presenter: presenter,clock: clock)
        var delivered = 0, deferred = 0
        store.configureTimingTest(observe: { event in
            if event.kind == .automaticShower { delivered += 1 }
            if event.kind == .deferred { deferred += 1 }
        })
        store.setSuspended(false); store.togglePause()
        clock.now = 0.25; clock.fire()
        precondition(delivered == 1 && store.busy)
        // Hold the presenter past the next deadline; the actual Store must defer exactly once.
        clock.now = 2.05; clock.fire()
        precondition(delivered == 1 && deferred == 1 && store.timingSnapshot.rainDue)
        clock.now = 8; presenter.finish()
        precondition(delivered == 2 && store.game.turns == 2 && store.busy)
        precondition(abs((clock.deadline ?? 0)-9.8) < 0.000001)
        store.setSuspended(true)
        precondition(clock.deadline == nil)
        presenter.finish()
        precondition(delivered == 2)
        store.restart(sameSky: true)
        store.setSuspended(false)
        let beforeInvalid = store.game
        store.clear(Cell(0,0))
        precondition(store.game == beforeInvalid && store.isPaused && clock.deadline == nil)
        store.callShower()
        precondition(store.game.turns == 1 && store.isPaused && clock.deadline == nil)
        presenter.finish()
        store.togglePause()
        let stale = clock.action
        store.togglePause()
        stale?()
        precondition(store.game.turns == 1 && clock.deadline == nil)
        store.setSuspended(true)
        // Two independent clears use distinct model completions and reservations.
        // A single pending callback would strand the first store presentation.
        for quiet in [false, true] {
            let overlapClock = PacingClock()
            let overlapPresenter = PacingPresenter(overlapClock, quiet: quiet)
            let overlapName = "starfall.pacing.overlap.\(UUID().uuidString)"
            let overlapDefaults = UserDefaults(suiteName: overlapName)!
            defer { overlapDefaults.removePersistentDomain(forName: overlapName) }
            let original = ObservatoryReviewFixture.game(dense: false)
            overlapDefaults.set(try! SkySaveArchive.encode(original), forKey: SkySaveArchive.key)
            let overlap = FallingSkyStore(defaults: overlapDefaults, arguments: [], presenter: overlapPresenter, clock: overlapClock)
            overlap.setSuspended(false)
            overlap.clear(Cell(0,0))
            precondition(overlap.busy && !overlap.canClear && !overlap.canContact(Cell(0,0)))
            precondition(overlap.canClear(Cell(2,6)))
            let afterFirst = overlap.game
            overlap.clear(Cell(0,0))
            precondition(overlap.game == afterFirst && overlapPresenter.pendingCount == 1)
            overlapClock.now = 0.1
            overlap.clear(Cell(2,6))
            precondition(overlapPresenter.pendingCount == 2 && overlapPresenter.maximumPendingCount == 2)
            let committed = overlap.game
            precondition(committed.score > afterFirst.score && committed.isValidSave)
            overlapClock.now = overlapPresenter.finishAt!
            overlapPresenter.finish()
            precondition(overlap.busy && overlapPresenter.pendingCount == 1)
            precondition(overlap.canContact(Cell(0,0)) && !overlap.canContact(Cell(2,6)))
            overlapClock.now = overlapPresenter.finishAt!
            overlapPresenter.finish()
            precondition(!overlap.busy && overlapPresenter.pendingCount == 0 && overlap.game == committed)
            overlap.setSuspended(true)
        }
        // Real intent must reject a gesture whose generation changed across incoming rain.
        let fixture = ConstellationFixture.five.game()
        let start = (0..<49).map { Cell($0/7,$0%7) }.first { fixture.constellationGroup(at: $0).count >= 5 }!
        let intent = ConstellationTraceIntent()
        let component = fixture.constellationGroup(at: start)
        let path = calibrationTrace(component, in: fixture)!
        for finishGeneration: UInt64 in [1,2] {
            let ticket = intent.begin(start,game: fixture,generation: 1,enabled: true)
            precondition(ticket != nil)
            for cell in path.dropFirst() {
                precondition(intent.visit(cell,ticket: ticket,game: fixture,generation: 1,enabled: true))
            }
            precondition((intent.finish(ticket: ticket,game: fixture,generation: finishGeneration,enabled: true) != nil) == (finishGeneration == 1))
        }
    }
}
