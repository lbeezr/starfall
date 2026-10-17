import Foundation
import StarfallCore

private func ordered(_ cells: Set<Cell>) -> [Cell] {
    cells.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
}
private func height(_ game: FallingSky, _ column: Int) -> Int {
    (0..<7).filter { game.gem(at: Cell($0, column)) != nil }.count
}
private struct Choice {
    let path: [Cell]
    let trace: Bool
}
// One canonical full-component walk per component. Bounded, not exhaustive subset strategy.
private func choices(_ game: FallingSky) -> [Choice] {
    var result = game.legalGroups.map { Choice(path: ordered(Set($0)), trace: false) }
    var seen = Set<Cell>()
    for row in 0..<7 { for column in 0..<7 {
        let start = Cell(row, column)
        guard !seen.contains(start) else { continue }
        let component = game.constellationGroup(at: start)
        seen.formUnion(component)
        guard component.count >= 5 else { continue }
        var visited = Set<Cell>(), path: [Cell] = []
        func walk(_ cell: Cell) {
            visited.insert(cell); path.append(cell)
            for next in ordered(component) where !visited.contains(next) && abs(next.row-cell.row) <= 1 && abs(next.column-cell.column) <= 1 {
                walk(next); path.append(cell)
            }
        }
        walk(start)
        precondition(path.count <= 196 && game.constellationCells(along: path) != nil)
        result.append(.init(path: path, trace: true))
    }}
    return result
}
private func choose(_ game: FallingSky, persona: String) -> Choice? {
    let alternatives = choices(game)
    func rank(_ choice: Choice) -> Int {
        let selected = choice.trace ? Set(choice.path) : game.group(at: choice.path[0])
        if persona == "height-safety" {
            // Only visible committed board; no trial shower or hidden incoming columns.
            return selected.reduce(0) { $0 + height(game, $1.column) * height(game, $1.column) }
        }
        return game.value(of: selected) + (persona == "trace-oriented" && choice.trace ? 1000 : 0)
    }
    return alternatives.enumerated().max { a,b in
        rank(a.element) == rank(b.element) ? a.offset > b.offset : rank(a.element) < rank(b.element)
    }?.element
}
private struct Event: Codable {
    let time: Double
    let kind: String
    let turns: Int
    let score: Int
    let deadline: Double?
    let phase: String
    let busy: Bool
    let inputEnabled: Bool
    let paused: Bool
    let suspended: Bool
    let cells: [[Int]]?
}
private struct Run: Codable {
    let seed: UInt64, cadence: String, persona: String, motion: String
    var activeSeconds = 0.0, presentationSeconds = 0.0, noOpportunitySeconds = 0.0
    var longestGap = 0.0, longestEarlyGap = 0.0
    var firstAcceptedClear: Double?
    var taps = 0, traces = 0, traceStarts = 0, deadlineCancelledTraces = 0, otherCancelledTraces = 0
    var parityCommits = 0
    var deferred = 0, maxHeight = 0, darkBlockedCells = 0, growth = 0, overflow = false
    var minimumIncomingHeadroom = 7
    var lateness: [Double] = [], deliveredIntervals: [Double] = [], scheduledIntervals: [Double] = []
    var events: [Event] = []
}
@main enum PacingMeasure {
    @MainActor private static func run(seed: UInt64, b: Bool, persona: String, quiet: Bool, limit: Double) -> Run {
        let clock = PacingClock()
        // Presenter and scheduler must share the exact monotonic clock.
        let display = PacingPresenter(clock, quiet: quiet)
        let suite = "starfall.pacing.tool.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=\(seed)"], presenter: display, clock: clock)
        var result = Run(seed: seed, cadence: b ? TimingCycleFixture.identity : "openingV1", persona: persona, motion: quiet ? "quiet-model" : "full-motion-model")
        let intent = ConstellationTraceIntent()
        var gesture: Choice?, ticket: UInt64?, pathIndex = 0
        var decisionAt: Double?, gestureAt: Double?
        var cancelledGesture = false
        var lastDelivery: Double?
        var replayA = store.game, replayB = store.game
        var lastAction: Choice?
        func record(_ kind: String, cells: [Cell]? = nil, deadline: Double? = nil,
                    snapshot: FallingSkyStore.TimingSnapshot? = nil) {
            let state = snapshot ?? store.timingSnapshot
            result.events.append(.init(time: state.time, kind: kind, turns: state.game.turns, score: state.game.score,
                deadline: deadline, phase: String(describing: state.cadence.phase), busy: state.busy,
                inputEnabled: state.canClear, paused: state.paused, suspended: state.suspended, cells: cells?.map { [$0.row,$0.column] }))
        }
        store.configureTimingTest(lookup: { (b ? SkyCadenceID.announcedCycleV1 : .openingV1).step(committedShowers: $0.turns, pace: $0.balance.pace) }, observe: { event in
            record(String(describing: event.kind), deadline: event.showerDeadline, snapshot: event.snapshot)
            switch event.kind {
            case .automaticShower, .manualShower:
                replayA.letStarsFall(); replayB.letStarsFall()
            case .tapAccepted:
                precondition(replayA.clear(lastAction!.path[0]) != nil)
                precondition(replayB.clear(lastAction!.path[0]) != nil)
            case .traceAccepted:
                precondition(replayA.clearConstellation(lastAction!.path) != nil)
                precondition(replayB.clearConstellation(lastAction!.path) != nil)
            default: break
            }
            switch event.kind {
            case .automaticShower, .manualShower, .tapAccepted, .traceAccepted:
                _ = replayA.cadenceStep
                _ = TimingCycleFixture.step(committedShowers: replayB.turns,pace: replayB.balance.pace)
                precondition(replayA == replayB && replayA == event.snapshot.game)
                precondition(replayA.isValidSave)
                result.parityCommits += 1
            default: break
            }
            switch event.kind {
            case .scheduled: result.scheduledIntervals.append(event.snapshot.cadence.delay)
            case .deferred: result.deferred += 1
            case .automaticShower:
                if let due = event.showerDeadline { result.lateness.append(clock.now-due) }
                if let previous = lastDelivery { result.deliveredIntervals.append(clock.now-previous) }
                lastDelivery = clock.now
            case .tapAccepted: result.taps += 1; if result.firstAcceptedClear == nil { result.firstAcceptedClear = clock.now }
            case .traceAccepted: result.traces += 1; if result.firstAcceptedClear == nil { result.firstAcceptedClear = clock.now }
            case .invalidated(let reason):
                if gesture != nil && reason != "clear" {
                    if reason == "automaticShower" { result.deadlineCancelledTraces += 1 }
                    else { result.otherCancelledTraces += 1 }
                    record("gestureCancelled:" + reason, snapshot: event.snapshot)
                    cancelledGesture = true
                }
            default: break
            }
        })
        store.setSuspended(false); store.togglePause()
        var gap = 0.0, earlyGap = 0.0
        // Event count and time bounds prevent accidental unbounded offline execution.
        for _ in 0..<20000 {
            if clock.now >= limit || store.game.isOver { break }
            if store.canClear && gesture == nil && decisionAt == nil { decisionAt = clock.now + 0.45 }
            if !store.canClear { decisionAt = nil }
            let next = min(limit, clock.deadline ?? .infinity, display.finishAt ?? .infinity, decisionAt ?? .infinity, gestureAt ?? .infinity)
            precondition(next >= clock.now && next.isFinite)
            let delta = next-clock.now
            result.activeSeconds += delta
            if store.busy { result.presentationSeconds += delta }
            let noOpportunity = store.canClear && choices(store.game).isEmpty
            gap = noOpportunity ? gap+delta : 0
            earlyGap = noOpportunity ? earlyGap + max(0, min(next,30)-min(clock.now,30)) : 0
            if noOpportunity { result.noOpportunitySeconds += delta }
            result.longestGap = max(result.longestGap,gap); result.longestEarlyGap = max(result.longestEarlyGap,earlyGap)
            clock.now = next
            // Rain wins exact timestamp ties, matching a conservative gesture-boundary probe.
            if let due = clock.deadline, due <= next {
                for star in store.game.incoming { result.minimumIncomingHeadroom = min(result.minimumIncomingHeadroom,7-height(store.game,star.column)) }
                clock.fire()
            }
            if cancelledGesture {
                cancelledGesture = false; intent.cancel(); gesture = nil; gestureAt = nil; store.constellationTracing = false
            }
            if let end = display.finishAt, end <= next { display.finish() }
            if let time = gestureAt, time <= next, let action = gesture {
                if pathIndex < action.path.count {
                    _ = intent.visit(action.path[pathIndex], ticket: ticket, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
                    pathIndex += 1; gestureAt = next + 0.12
                } else {
                    let commit = intent.finish(ticket: ticket, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
                    gesture = nil; gestureAt = nil; store.constellationTracing = false
                    if let commit { lastAction = action; record("traceRelease", cells: commit.path); store.clearTracedConstellation(commit.path,snapshot: commit.snapshot,generation: commit.generation) }
                    else { result.otherCancelledTraces += 1; record("traceReleaseRejected") }
                }
            }
            if let time = decisionAt, time <= next {
                decisionAt = nil
                if store.canClear, let action = choose(store.game,persona: persona) {
                    if action.trace {
                        ticket = intent.begin(action.path[0],game: store.game,generation: store.constellationInputGeneration,enabled: store.canClear)
                        precondition(ticket != nil)
                        gesture = action; pathIndex = 1; gestureAt = next+0.12
                        result.traceStarts += 1; record("traceBegin",cells: action.path)
                        store.constellationTracing = true
                    } else { lastAction = action; record("tapAttempt",cells: [action.path[0]]); store.clear(action.path[0]) }
                } else { decisionAt = next+0.45 }
            }
            result.maxHeight = max(result.maxHeight,(0..<7).map { height(store.game,$0) }.max()!)
            result.darkBlockedCells = max(result.darkBlockedCells,(0..<49).filter { store.game.isGrowthBlocked(at: Cell($0/7,$0%7)) }.count)
        }
        precondition(clock.now >= limit || store.game.isOver, "event bound exhausted")
        if gesture != nil { record("gestureCensoredAtHorizon") }
        result.growth = display.growthEvents
        result.overflow = store.game.blockedColumn != nil
        store.setSuspended(true)
        return result
    }
    @MainActor static func main() throws {
        let seeds = Int(CommandLine.arguments[1])!, seconds = Double(CommandLine.arguments[2])!
        checks()
        var runs: [Run] = []
        for seed in 0..<seeds { for b in [false,true] { for persona in ["largest-clear","height-safety","trace-oriented"] { for quiet in [false,true] {
            runs.append(run(seed: UInt64(seed),b: b,persona: persona,quiet: quiet,limit: seconds))
        }}}}
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        print(String(data: try encoder.encode(runs),encoding: .utf8)!)
    }
}
