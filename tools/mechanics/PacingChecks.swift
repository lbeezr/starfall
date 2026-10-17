import Foundation
import StarfallCore

extension PacingMeasure {
    @MainActor static func checks() {
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
        // Real intent must reject a gesture whose generation changed across incoming rain.
        let fixture = ConstellationFixture.five.game()
        let start = (0..<49).map { Cell($0/7,$0%7) }.first { fixture.constellationGroup(at: $0).count >= 5 }!
        let intent = ConstellationTraceIntent()
        let component = fixture.constellationGroup(at: start)
        var path: [Cell] = [], visited = Set<Cell>()
        func walk(_ cell: Cell) {
            visited.insert(cell); path.append(cell)
            for next in component.sorted(by: { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row })
                where !visited.contains(next) && abs(next.row-cell.row) <= 1 && abs(next.column-cell.column) <= 1 {
                walk(next); path.append(cell)
            }
        }
        walk(start)
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
