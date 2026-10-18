import Foundation

private func bit(_ cell: Cell) -> UInt64 { 1 << (cell.row * 7 + cell.column) }
private func cells(_ mask: UInt64) -> [Cell] {
    (0..<49).filter { mask & (1 << $0) != 0 }.map { Cell($0 / 7, $0 % 7) }
}
private func mask(_ cells: some Sequence<Cell>) -> UInt64 { cells.reduce(0) { $0 | bit($1) } }
private func adjacent(_ a: Cell, _ b: Cell) -> Bool {
    a != b && abs(a.row-b.row) <= 1 && abs(a.column-b.column) <= 1
}
private func walk(_ selected: UInt64, _ game: FallingSky) -> [Cell]? {
    let ordered = cells(selected)
    guard let first = ordered.first(where: { game.gem(at: $0)?.kind != nil }) else { return nil }
    var seen: Set<Cell> = [first], path = [first]
    func visit(_ cell: Cell) {
        for next in ordered where !seen.contains(next) && adjacent(cell, next) {
            seen.insert(next); path.append(next); visit(next); path.append(cell)
        }
    }
    visit(first)
    guard seen.count == ordered.count else { return nil }
    precondition(path.count <= 97)
    return path
}
private func fives(_ component: UInt64, cap: Int = 256) -> [UInt64]? {
    let members = cells(component)
    guard members.count >= 5 else { return [] }
    var frontier = Set(members.map(bit))
    for _ in 2...5 {
        var next: Set<UInt64> = []
        for selected in frontier.sorted() {
            let current = cells(selected)
            for cell in members where selected & bit(cell) == 0 && current.contains(where: { adjacent($0, cell) }) {
                next.insert(selected | bit(cell))
                if next.count > cap { return nil }
            }
        }
        frontier = next
    }
    return frontier.sorted()
}
private struct Action: Codable {
    let selected: UInt64
    let light: Int
    let opalsSpent: Int
    var tap: Cell?
    var trace: [Cell]?
    var recipeCells: [Cell]? = nil
}
private struct Alternatives { let actions: [Action]; let complete: Bool }
private func choices(_ game: FallingSky, subsets: Bool, recipes: Bool = false) -> Alternatives {
    guard !game.isOver else { return .init(actions: [], complete: true) }
    var result: [UInt64: Action] = [:], components: Set<UInt64> = []
    func action(_ selected: UInt64, tap: Cell? = nil, trace: [Cell]? = nil) -> Action {
        let selectedCells = Set(cells(selected))
        return .init(selected: selected, light: game.reward(of: selectedCells),
            opalsSpent: selectedCells.filter { game.gem(at: $0)?.isLight == true }.count, tap: tap, trace: trace)
    }
    for group in game.legalGroups { result[mask(group)] = action(mask(group), tap: group[0]) }
    if recipes {
        for recipe in game.recipes where result[mask(recipe.cells)] == nil {
            var selected = action(mask(recipe.cells))
            selected.recipeCells = recipe.cells
            result[selected.selected] = selected
        }
    }
    for row in 0..<7 { for column in 0..<7 {
        let component = game.constellationGroup(at: Cell(row,column))
        if !component.isEmpty { components.insert(mask(component)) }
    } }
    func addTrace(_ selected: UInt64) {
        guard result[selected] == nil, let path = walk(selected, game) else { return }
        precondition(game.constellationCells(along: path) == Set(cells(selected)))
        result[selected] = action(selected, trace: path)
    }
    for component in components.sorted() { addTrace(component) }
    let base = result.values.sorted { $0.selected < $1.selected }
    if subsets {
        for component in components.sorted() {
            guard let partials = fives(component) else { return .init(actions: base, complete: false) }
            for partial in partials { addTrace(partial) }
            if result.count > 512 { return .init(actions: base, complete: false) }
        }
    }
    return .init(actions: result.values.sorted { $0.selected < $1.selected }, complete: true)
}
// Only visible reward, Opal consumption and stable selection enter policy choice.
private func select(_ actions: [Action], preserveTies: Bool) -> Action? {
    actions.sorted {
        if $0.light != $1.light { return $0.light > $1.light }
        if preserveTies && $0.opalsSpent != $1.opalsSpent { return $0.opalsSpent < $1.opalsSpent }
        return $0.selected < $1.selected
    }.first
}
@discardableResult private func commit(_ action: Action, _ game: inout FallingSky) -> Int {
    let before = game
    let turn: FallingSkyTurn?
    if let tap = action.tap { turn = game.clear(tap) }
    else if let cells = action.recipeCells { turn = game.activate(game.recipe(matching: Set(cells))!) }
    else { turn = game.clearConstellation(action.trace!) }
    precondition(turn?.collected == action.light && game.isValidSave)
    precondition(game.turns == before.turns && game.incoming == before.incoming)
    return turn!.collected
}
private func bestClear(_ game: FallingSky) -> Action? { select(choices(game, subsets: false).actions, preserveTies: false) }
private struct StudyOutcome: Codable {
    let first: Int
    let remainingOpals: Int
    let immediateSecond: Int
    let afterShowerSecond: Int
    let overflow: Bool
    var immediateTotal: Int { first + immediateSecond }
    var afterShowerTotal: Int { first + afterShowerSecond }
}
private func evaluate(_ first: Action?, _ source: FallingSky) -> StudyOutcome {
    var game = source
    let reward = first.map { commit($0, &game) } ?? 0
    let opals = game.board.compactMap { $0 }.filter(\.isLight).count
    var immediate = game
    let second = bestClear(immediate).map { commit($0, &immediate) } ?? 0
    game.letStarsFall(); precondition(game.isValidSave)
    let overflow = game.isOver
    let after = bestClear(game).map { commit($0, &game) } ?? 0
    return .init(first: reward, remainingOpals: opals, immediateSecond: second,
                 afterShowerSecond: after, overflow: overflow)
}
private struct Example: Codable {
    let category: String
    let seed: UInt64
    let shower: Int
    let initial: FallingSky
    let greedy: Action
    let alternative: Action?
    let greedyOutcome: StudyOutcome
    let alternativeOutcome: StudyOutcome
}
private func phaseName(_ game: FallingSky) -> String {
    game.generation.phase(for: game.turns)?.isStorm == true ? "storm" : "calm"
}
private struct Summary: Codable {
    let policy: String
    var counts: [String: Int] = [:]
    var phaseCounts: [String: [String: Int]] = [:]
    var rounds = 0, ended = 0, score = 0, showers = 0
    var examples: [Example] = []
    mutating func count(_ key: String, phase: String) {
        counts[key, default: 0] += 1
        phaseCounts[phase, default: [:]][key, default: 0] += 1
    }
}
@main private enum OpalChoiceStudy {
    /// Visible-board action bounds, without forecasting or unlimited exchange chains.
    static func calibrate(start: UInt64, seeds: Int, limit: Int, duskRule: DuskRule) throws {
        struct Round: Codable {
            let seed: UInt64; let showers: Int; let score: Int; let ended: Bool
            let clears: Int; let traces: Int; let recipes: Int; let exchanges: Int
            let noClearArrivals: Int; let longestNoClearRun: Int; let lostStarlight: Int
        }
        struct Exchange { let from: Cell; let to: Cell; let gain: Int }
        func best(_ game: FallingSky, recipes: Bool) -> Action? {
            select(choices(game, subsets: false, recipes: recipes).actions, preserveTies: false)
        }
        func setup(_ game: FallingSky) -> Exchange? {
            let current = best(game, recipes: true)?.light ?? 0
            var result: Exchange?
            for row in 0..<7 { for column in 0..<7 { for delta in [-1, 1] {
                let from = Cell(row,column), to = Cell(row,column+delta)
                guard game.canNudge(from: from, to: to) else { continue }
                var copy = game
                guard copy.nudge(from: from, to: to) != nil else { continue }
                let gain = (best(copy, recipes: true)?.light ?? 0) - current
                if gain > 0 && gain > (result?.gain ?? 0) { result = .init(from: from, to: to, gain: gain) }
            } } }
            return result
        }
        var example = SkyTechniqueExample.nudge.game()
        let before = example, exchange = setup(example)!
        precondition(example == before)
        precondition(example.nudge(from: exchange.from, to: exchange.to) != nil)
        precondition(example.turns == before.turns && example.incoming == before.incoming)
        precondition(best(example, recipes: true)!.light > (best(before, recipes: true)?.light ?? 0))
        var policies: [String: [Round]] = [:]
        for policy in ["clear-one", "recipe-one", "setup-one", "setup-all"] {
            var rounds: [Round] = []
            for seed in start..<(start + UInt64(seeds)) {
                var game = FallingSky(seed: seed, generation: .current, duskRule: duskRule)
                var clears = 0, traces = 0, recipes = 0, exchanges = 0, dry = 0, streak = 0, longest = 0
                while !game.isOver && game.turns < limit {
                    game.letStarsFall(); precondition(game.isValidSave)
                    guard !game.isOver else { break }
                    if policy.hasPrefix("setup"), let move = setup(game) {
                        let old = game
                        precondition(game.nudge(from: move.from, to: move.to) != nil)
                        precondition(game.turns == old.turns && game.incoming == old.incoming && game.score == old.score)
                        precondition(game.isValidSave); exchanges += 1
                    }
                    let includeRecipes = policy != "clear-one"
                    if best(game, recipes: includeRecipes) == nil { dry += 1; streak += 1; longest = max(longest, streak) }
                    else { streak = 0 }
                    for _ in 0..<(policy == "setup-all" ? 49 : 1) {
                        guard let action = best(game, recipes: includeRecipes) else { break }
                        if action.recipeCells != nil { recipes += 1 }
                        else if action.tap == nil { traces += 1 }
                        commit(action, &game); clears += 1
                    }
                    let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                    precondition(game == restored && restored.isValidSave)
                }
                rounds.append(.init(seed: seed, showers: game.turns, score: game.score, ended: game.isOver,
                                    clears: clears, traces: traces, recipes: recipes, exchanges: exchanges,
                                    noClearArrivals: dry, longestNoClearRun: longest, lostStarlight: game.lostStarlight))
            }
            policies[policy] = rounds
            FileHandle.standardError.write(Data("\(policy): \(seeds) seeds complete\n".utf8))
        }
        struct Report: Codable {
            let seedStart: UInt64; let seeds: Int; let showerLimit: Int
            let duskRule: Int; let feedingShowers: Int
            let method: String; let policies: [String: [Round]]
        }
        let report = Report(seedStart: start, seeds: seeds, showerLimit: limit,
                            duskRule: duskRule.rawValue, feedingShowers: duskRule.feedingShowers,
                            method: "Current generation/cadence with explicitly selected Dusk version. Largest immediate visible reward, stable cell-mask ties. Full valid component traces, no subset enumeration. Setup allows one exchange per shower only for strictly better visible immediate reward. No forecast search. One/all clear budgets are diagnostics, not human timing. No-clear arrivals are after optional setup and exclude terminal arrivals. Recipe counts omit outcomes already available as ordinary taps.", policies: policies)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        FileHandle.standardOutput.write(try encoder.encode(report))
    }
    static func checks() {
        // Feeding Dusk can drain a legal match to zero. Policy ranking and
        // commit assertions must use collectible reward, not face value.
        let drained = DuskFixture.zeroClear.game()
        let drainedActions = choices(drained, subsets: false, recipes: true).actions
        precondition(drainedActions.contains { $0.light == 0 && drained.value(of: Set(cells($0.selected))) >= 3 })
        for action in drainedActions {
            var copy = drained
            precondition(commit(action, &copy) == action.light)
        }
        precondition(drained == DuskFixture.zeroClear.game())
        for shower in [9, 10, 12, 13] {
            precondition(SkyGeneration.current.phase(for: shower)?.isStorm == ([10, 12].contains(shower)))
        }
        let chain = mask((0..<6).map { Cell($0,$0) })
        precondition(fives(chain)!.count == 2)
        let rectangle = mask((0..<2).flatMap { row in (0..<3).map { Cell(row,$0) } })
        precondition(fives(rectangle)!.count == 6 && fives(rectangle, cap: 2) == nil)
        let game = ConstellationFixture.opalChoice.game(), before = game
        let alternatives = choices(game, subsets: true)
        precondition(alternatives.complete)
        let path = [Cell(3,1),Cell(3,2),Cell(2,3),Cell(2,4),Cell(2,5)]
        let selected = alternatives.actions.first { $0.selected == mask(path) }!
        precondition(selected.light == 5 && selected.opalsSpent == 1)
        let flood = alternatives.actions.first { $0.tap == Cell(0,6) }!
        precondition(flood.light == 5 && flood.opalsSpent == 2)
        _ = evaluate(selected, game); _ = evaluate(flood, game)
        precondition(game == before)
        precondition(Set(alternatives.actions.map(\.selected)).count == alternatives.actions.count)
        for action in alternatives.actions {
            var copy = game; commit(action, &copy)
            precondition(try! JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(copy)) == copy)
        }
    }
    static func main() throws {
        checks()
        let start = UInt64(CommandLine.arguments[1])!, seeds = Int(CommandLine.arguments[2])!
        let limit = Int(CommandLine.arguments[3])!
        if CommandLine.arguments.contains("--calibration") {
            let rule = CommandLine.arguments.first { $0.hasPrefix("--dusk-rule=") } ?? "--dusk-rule=patientFeeding"
            precondition(["--dusk-rule=feeding", "--dusk-rule=patientFeeding"].contains(rule))
            try calibrate(start: start, seeds: seeds, limit: limit,
                          duskRule: rule == "--dusk-rule=feeding" ? .feeding : .patientFeeding)
            return
        }
        var summaries: [Summary] = []
        for preserve in [false, true] {
            var summary = Summary(policy: preserve ? "preserve-opal-on-score-ties" : "largest-immediate")
            for key in ["decisionStates", "opalStates", "cappedOpalStates", "uncappedOpalDecisionStates",
                        "opalStatesWithoutClear", "sharedOpalStates", "equalFirstImmediateGainStates",
                        "smallerFirstImmediateGainStates", "preservingForecastOracleGainStates",
                        "preservingForecastOracleSafetyStates", "waitForecastOracleGainStates", "clearAvailableStates", "multipleClearStates",
                        "activeOrbitStates", "orbitWithOpalStates"] {
                summary.counts[key] = 0
                for phase in ["calm", "storm"] { summary.phaseCounts[phase, default: [:]][key] = 0 }
            }
            for seed in start..<(start + UInt64(seeds)) {
                var game = FallingSky(seed: seed, generation: .current)
                for _ in 0..<limit where !game.isOver {
                    game.letStarsFall(); precondition(game.isValidSave)
                    guard !game.isOver else { break }
                    let phase = phaseName(game)
                    summary.count("decisionStates", phase: phase)
                    let hasOpal = game.board.contains { $0?.isLight == true }
                    let alternatives = choices(game, subsets: hasOpal)
                    let source = game
                    if !alternatives.actions.isEmpty { summary.count("clearAvailableStates", phase: phase) }
                    if alternatives.actions.count > 1 { summary.count("multipleClearStates", phase: phase) }
                    if game.orbit != nil {
                        summary.count("activeOrbitStates", phase: phase)
                        if hasOpal { summary.count("orbitWithOpalStates", phase: phase) }
                    }
                    if hasOpal {
                        summary.count("opalStates", phase: phase)
                        if !alternatives.complete { summary.count("cappedOpalStates", phase: phase) }
                        else if let greedy = select(alternatives.actions, preserveTies: false) {
                            summary.count("uncappedOpalDecisionStates", phase: phase)
                            let opals = (0..<49).map { Cell($0/7,$0%7) }.filter { game.gem(at: $0)?.isLight == true }
                            if opals.contains(where: { orb in
                                let families = Set(alternatives.actions.filter { $0.selected & bit(orb) != 0 }.flatMap {
                                    cells($0.selected).compactMap { game.gem(at: $0)?.kind?.rawValue }
                                })
                                return families.count >= 2
                            }) { summary.count("sharedOpalStates", phase: phase) }
                            let baseline = evaluate(greedy, game)
                            var equal = false, smaller = false, forecast = false, safety = false
                            func retain(_ category: String, _ alternative: Action?, _ result: StudyOutcome) {
                                guard !summary.examples.contains(where: { $0.category == category }) else { return }
                                summary.examples.append(.init(category: category, seed: seed, shower: game.turns,
                                    initial: game, greedy: greedy, alternative: alternative,
                                    greedyOutcome: baseline, alternativeOutcome: result))
                            }
                            for action in alternatives.actions where action.opalsSpent < greedy.opalsSpent {
                                let result = evaluate(action, game)
                                if result.immediateTotal > baseline.immediateTotal {
                                    if action.light == greedy.light { equal = true; retain("equal-first-immediate-gain", action, result) }
                                    else { smaller = true; retain("smaller-first-immediate-gain", action, result) }
                                }
                                if !result.overflow && result.afterShowerTotal > baseline.afterShowerTotal {
                                    forecast = true; retain("preserving-forecast-oracle-gain", action, result)
                                }
                                if !baseline.overflow && !result.overflow,
                                   result.immediateTotal <= baseline.immediateTotal,
                                   result.afterShowerTotal <= baseline.afterShowerTotal {
                                    retain("safe-preservation-without-two-clear-gain", action, result)
                                }
                                if baseline.overflow && !result.overflow {
                                    safety = true; retain("preserving-forecast-oracle-safety", action, result)
                                }
                            }
                            if equal { summary.count("equalFirstImmediateGainStates", phase: phase) }
                            if smaller { summary.count("smallerFirstImmediateGainStates", phase: phase) }
                            if forecast { summary.count("preservingForecastOracleGainStates", phase: phase) }
                            if safety { summary.count("preservingForecastOracleSafetyStates", phase: phase) }
                            if greedy.opalsSpent > 0 {
                                let waiting = evaluate(nil, game)
                                if !waiting.overflow && waiting.afterShowerTotal > baseline.afterShowerTotal {
                                    summary.count("waitForecastOracleGainStates", phase: phase)
                                    retain("wait-forecast-oracle-gain", nil, waiting)
                                }
                            }
                        } else { summary.count("opalStatesWithoutClear", phase: phase) }
                    }
                    precondition(game == source)
                    if let chosen = select(alternatives.actions, preserveTies: preserve) { commit(chosen, &game) }
                }
                summary.rounds += 1; summary.score += game.score; summary.showers += game.turns
                if game.isOver { summary.ended += 1 }
                if (seed-start+1).isMultiple(of: 16) {
                    FileHandle.standardError.write(Data("\(summary.policy): \(seed-start+1)/\(seeds) seeds\n".utf8))
                }
            }
            for (key, value) in summary.counts {
                precondition(summary.phaseCounts.values.reduce(0) { $0 + ($1[key] ?? 0) } == value)
            }
            summaries.append(summary)
        }
        struct Report: Codable { let seedStart: UInt64; let seeds: Int; let showerLimit: Int; let summaries: [Summary] }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        FileHandle.standardOutput.write(try encoder.encode(Report(seedStart: start, seeds: seeds, showerLimit: limit, summaries: summaries)))
    }
}
