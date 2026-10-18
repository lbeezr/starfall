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
private func choose(_ game: FallingSky, persona: String, available: (Choice) -> Bool = { _ in true }) -> Choice? {
    let alternatives = choices(game).filter(available)
    func rank(_ choice: Choice) -> Int {
        let selected = choice.trace ? Set(choice.path) : game.group(at: choice.path[0])
        if persona == "height-safety" {
            // Only visible committed board; no trial shower or hidden incoming columns.
            return selected.reduce(0) { $0 + height(game, $1.column) * height(game, $1.column) }
        }
        return game.reward(of: selected) + (persona == "trace-oriented" && choice.trace ? 1000 : 0)
    }
    return alternatives.enumerated().max { a,b in
        rank(a.element) == rank(b.element) ? a.offset > b.offset : rank(a.element) < rank(b.element)
    }?.element
}
private struct SetupChoice {
    let from: Cell, to: Cell
    let snapshot: FallingSky
    let generation: UInt64
}
// One improving exchange per committed shower, selected from the visible board.
// Search time is represented by the explicit reaction assumption, not measured.
private func improvingSetup(_ game: FallingSky, generation: UInt64, available: (FallingSkyTurn) -> Bool = { _ in true }) -> SetupChoice? {
    func reward(_ game: FallingSky) -> Int {
        choices(game).map { game.reward(of: $0.trace ? Set($0.path) : game.group(at: $0.path[0])) }.max() ?? 0
    }
    let current = reward(game)
    var best = current, result: SetupChoice?
    for row in 0..<7 { for column in 0..<7 { for delta in [-1,1] {
        let from = Cell(row,column), to = Cell(row,column+delta)
        guard game.canNudge(from: from, to: to) else { continue }
        var copy = game
        guard let turn = copy.nudge(from: from, to: to), available(turn) else { continue }
        let value = reward(copy)
        if value > best {
            best = value; result = .init(from: from, to: to, snapshot: game, generation: generation)
        }
    } } }
    return result
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
    let readyContactColumns: [Int]
    let paused: Bool
    let suspended: Bool
    let cells: [[Int]]?
}
private struct Run: Codable {
    let seed: UInt64, cadence: String, persona: String, motion: String
    let inputModel: String
    var activeSeconds = 0.0, presentationSeconds = 0.0, noOpportunitySeconds = 0.0
    var blockedOpportunitySeconds = 0.0
    var startsDuringPresentation = 0, maximumPendingPresentations = 0
    var longestGap = 0.0, longestEarlyGap = 0.0
    var firstAcceptedClear: Double?
    var taps = 0, traces = 0, traceStarts = 0, deadlineCancelledTraces = 0, otherCancelledTraces = 0
    var exchanges = 0, exchangeStarts = 0, exchangeRejections = 0, heldSeconds = 0.0
    var finalScore = 0, deliveredShowers = 0
    var parityCommits = 0
    var deferred = 0, maxHeight = 0, darkBlockedCells = 0, growth = 0, overflow = false
    var minimumIncomingHeadroom = 7
    var lateness: [Double] = [], deliveredIntervals: [Double] = [], scheduledIntervals: [Double] = []
    var events: [Event] = []
}
@main enum PacingMeasure {
    @MainActor private static func run(seed: UInt64, cadence: SkyCadenceID, persona: String, quiet: Bool, limit: Double, reaction: Double, traceStep: Double, swapSeconds: Double, inputModel: String) -> Run {
        let clock = PacingClock()
        // Presenter and scheduler must share the exact monotonic clock.
        let display = PacingPresenter(clock, quiet: quiet)
        let suite = "starfall.pacing.tool.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--starfalls-seed=\(seed)"], presenter: display, clock: clock)
        var result = Run(seed: seed, cadence: cadence.rawValue, persona: persona, motion: quiet ? "quiet-model" : "full-motion-model", inputModel: inputModel)
        func mayDecide() -> Bool { inputModel == "settled" ? store.canClear : store.canReceiveInput }
        func available(_ choice: Choice) -> Bool {
            guard mayDecide() else { return false }
            return choice.trace ? store.canTrace(choice.path) : store.canClear(choice.path[0])
        }
        let interaction = SkyInteractionSession()
        let intent = interaction.trace
        var gesture: Choice?, ticket: UInt64?, pathIndex = 0
        var decisionAt: Double?, gestureAt: Double?
        var setup: SetupChoice?, setupAt: Double?, lastSetupShower: Int?
        var cancelledGesture = false
        var lastDelivery: Double?
        var replayA = store.game, replayB = store.game
        var lastAction: Choice?
        func record(_ kind: String, cells: [Cell]? = nil, deadline: Double? = nil,
                    snapshot: FallingSkyStore.TimingSnapshot? = nil) {
            let state = snapshot ?? store.timingSnapshot
            result.events.append(.init(time: state.time, kind: kind, turns: state.game.turns, score: state.game.score,
                deadline: deadline, phase: String(describing: state.cadence.phase), busy: state.busy,
                inputEnabled: state.canClear, readyContactColumns: (0..<7).filter { store.canContact(Cell(0,$0)) },
                paused: state.paused, suspended: state.suspended, cells: cells?.map { [$0.row,$0.column] }))
        }
        store.configureTimingTest(lookup: { cadence.step(committedShowers: $0.turns, pace: $0.balance.pace) }, observe: { event in
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
            if mayDecide() && gesture == nil && setup == nil && decisionAt == nil { decisionAt = clock.now + reaction }
            if !mayDecide() { decisionAt = nil }
            let next = min(limit, clock.deadline ?? .infinity, display.finishAt ?? .infinity, decisionAt ?? .infinity, gestureAt ?? .infinity, setupAt ?? .infinity)
            precondition(next >= clock.now && next.isFinite)
            let delta = next-clock.now
            result.activeSeconds += delta
            if store.busy { result.presentationSeconds += delta }
            if gesture != nil || setup != nil { result.heldSeconds += delta }
            let options = choices(store.game)
            let idle = gesture == nil && setup == nil
            let noOpportunity = idle && mayDecide() && options.isEmpty
            if idle && store.canReceiveInput && !options.isEmpty && !options.contains(where: available) {
                result.blockedOpportunitySeconds += delta
            }
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
                cancelledGesture = false; gesture = nil; gestureAt = nil
                interaction.cancelContact(release: store.endConstellationHold)
            }
            if let end = display.finishAt, end <= next { display.finish() }
            if let time = setupAt, time <= next, let move = setup {
                setup = nil; setupAt = nil
                let owned = interaction.holdTicket
                interaction.technique.cancel()
                let accepted = store.performTechnique(.nudge(move.from, move.to), snapshot: move.snapshot, generation: move.generation)
                interaction.endContact(ticket: owned, release: store.endConstellationHold)
                precondition(interaction.holdTicket == nil && !store.constellationTracing)
                if accepted {
                    precondition(replayA.nudge(from: move.from, to: move.to) != nil)
                    precondition(replayB.nudge(from: move.from, to: move.to) != nil)
                    precondition(replayA == replayB && replayA == store.game && store.game.isValidSave)
                    result.parityCommits += 1; result.exchanges += 1
                    record("exchangeAccepted", cells: [move.from,move.to])
                } else { result.exchangeRejections += 1; record("exchangeRejected") }
            }
            if let time = gestureAt, time <= next, let action = gesture {
                if pathIndex < action.path.count {
                    _ = intent.visit(action.path[pathIndex], ticket: ticket, game: store.game, generation: store.constellationInputGeneration, enabled: inputModel == "settled" ? store.canClear : store.canTrace(intent.path + [action.path[pathIndex]]))
                    pathIndex += 1; gestureAt = next + traceStep
                } else {
                    let commit = intent.finish(ticket: ticket, game: store.game, generation: store.constellationInputGeneration, enabled: inputModel == "settled" ? store.canClear : store.canTrace(intent.path))
                    let owned = interaction.holdTicket
                    gesture = nil; gestureAt = nil
                    if let commit { lastAction = action; record("traceRelease", cells: commit.path); store.clearTracedConstellation(commit.path,snapshot: commit.snapshot,generation: commit.generation) }
                    else { result.otherCancelledTraces += 1; record("traceReleaseRejected") }
                    // Match native release: commit before the logical contact returns its ticket.
                    interaction.endContact(ticket: owned, release: store.endConstellationHold)
                    precondition(interaction.holdTicket == nil && !store.constellationTracing)
                }
            }
            if let time = decisionAt, time <= next {
                decisionAt = nil
                if persona == "setup-first", mayDecide(), lastSetupShower != store.game.turns,
                   let move = improvingSetup(store.game, generation: store.constellationInputGeneration, available: {
                       $0.changingColumns.isDisjoint(with: store.changingColumns)
                   }) {
                    if store.busy { result.startsDuringPresentation += 1 }
                    precondition(interaction.acquireHold(at: move.from, using: store.beginConstellationHold))
                    interaction.armSwap(from: move.from, to: move.to, game: store.game, generation: store.constellationInputGeneration)
                    lastSetupShower = store.game.turns
                    setup = move; setupAt = next + swapSeconds
                    result.exchangeStarts += 1; record("exchangeBegin", cells: [move.from,move.to])
                } else if mayDecide(), let action = choose(store.game,persona: persona, available: available) {
                    if store.busy { result.startsDuringPresentation += 1 }
                    if action.trace {
                        ticket = intent.begin(action.path[0],game: store.game,generation: store.constellationInputGeneration,enabled: available(action))
                        precondition(ticket != nil)
                        gesture = action; pathIndex = 1; gestureAt = next+traceStep
                        result.traceStarts += 1; record("traceBegin",cells: action.path)
                        precondition(interaction.acquireHold(at: action.path[0], using: store.beginConstellationHold))
                    } else { lastAction = action; record("tapAttempt",cells: [action.path[0]]); store.clear(action.path[0]) }
                } else { decisionAt = next+reaction }
            }
            result.maxHeight = max(result.maxHeight,(0..<7).map { height(store.game,$0) }.max()!)
            result.darkBlockedCells = max(result.darkBlockedCells,(0..<49).filter { store.game.isGrowthBlocked(at: Cell($0/7,$0%7)) }.count)
        }
        precondition(clock.now >= limit || store.game.isOver, "event bound exhausted")
        precondition(result.exchanges <= store.game.turns && result.exchanges <= result.exchangeStarts)
        if gesture != nil { record("gestureCensoredAtHorizon") }
        if setup != nil { record("exchangeCensoredAtHorizon") }
        result.growth = display.growthEvents
        result.maximumPendingPresentations = display.maximumPendingCount
        result.overflow = store.game.blockedColumn != nil
        result.finalScore = store.game.score; result.deliveredShowers = store.game.turns
        store.setSuspended(true)
        return result
    }
    @MainActor static func main() throws {
        let seeds = Int(CommandLine.arguments[1])!, seconds = Double(CommandLine.arguments[2])!
        let baseline = SkyCadenceID(rawValue: CommandLine.arguments[3])!
        let candidate = SkyCadenceID(rawValue: CommandLine.arguments[4])!
        let reaction = Double(CommandLine.arguments[5])!, traceStep = Double(CommandLine.arguments[6])!
        let includeSetups = CommandLine.arguments.contains("--include-setups")
        let swapSeconds = Double(CommandLine.arguments[7])!
        let inputModel = CommandLine.arguments[8]
        let seedStart = UInt64(CommandLine.arguments[9])!
        precondition(seedStart <= 1000000)
        precondition(["settled", "columns"].contains(inputModel))
        precondition(baseline != candidate && reaction >= 0.05 && reaction <= 5 && traceStep >= 0.02 && traceStep <= 1)
        checks()
        let drained = DuskFixture.zeroClear.game()
        let zero = choose(drained, persona: "largest-clear")!
        let zeroCells = zero.trace ? Set(zero.path) : drained.group(at: zero.path[0])
        precondition(drained.value(of: zeroCells) >= 3 && drained.reward(of: zeroCells) == 0)
        let source = SkyTechniqueExample.nudge.game()
        let setup = improvingSetup(source, generation: 7)!
        var moved = source
        precondition(setup.snapshot == source && setup.generation == 7)
        precondition(moved.nudge(from: setup.from, to: setup.to) != nil)
        precondition(moved.turns == source.turns && moved.incoming == source.incoming)
        let original = choose(source, persona: "largest-clear").map { source.reward(of: $0.trace ? Set($0.path) : source.group(at: $0.path[0])) } ?? 0
        let improved = choose(moved, persona: "largest-clear")!
        precondition(moved.reward(of: improved.trace ? Set(improved.path) : moved.group(at: improved.path[0])) > original)
        var runs: [Run] = []
        let personas = ["largest-clear","height-safety","trace-oriented"] + (includeSetups ? ["setup-first"] : [])
        for seed in 0..<seeds { for cadence in [baseline,candidate] { for persona in personas { for quiet in [false,true] {
            runs.append(run(seed: seedStart + UInt64(seed),cadence: cadence,persona: persona,quiet: quiet,limit: seconds,reaction: reaction,traceStep: traceStep,swapSeconds: swapSeconds,inputModel: inputModel))
        }}}}
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        print(String(data: try encoder.encode(runs),encoding: .utf8)!)
    }
}
