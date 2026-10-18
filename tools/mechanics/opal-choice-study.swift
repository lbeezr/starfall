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
}
private struct Alternatives { let actions: [Action]; let complete: Bool }
private func choices(_ game: FallingSky, subsets: Bool) -> Alternatives {
    guard !game.isOver else { return .init(actions: [], complete: true) }
    var result: [UInt64: Action] = [:], components: Set<UInt64> = []
    func action(_ selected: UInt64, tap: Cell? = nil, trace: [Cell]? = nil) -> Action {
        let selectedCells = Set(cells(selected))
        return .init(selected: selected, light: game.value(of: selectedCells),
            opalsSpent: selectedCells.filter { game.gem(at: $0)?.isLight == true }.count, tap: tap, trace: trace)
    }
    for group in game.legalGroups { result[mask(group)] = action(mask(group), tap: group[0]) }
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
    let turn = action.tap.map { game.clear($0) } ?? game.clearConstellation(action.trace!)
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
private struct Summary: Codable {
    let policy: String
    var counts: [String: Int] = [:]
    var rounds = 0, ended = 0, score = 0, showers = 0
    var examples: [Example] = []
    mutating func count(_ key: String) { counts[key, default: 0] += 1 }
}
@main private enum OpalChoiceStudy {
    static func checks() {
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
        var summaries: [Summary] = []
        for preserve in [false, true] {
            var summary = Summary(policy: preserve ? "preserve-opal-on-score-ties" : "largest-immediate")
            for key in ["decisionStates", "opalStates", "cappedOpalStates", "uncappedOpalDecisionStates",
                        "opalStatesWithoutClear", "sharedOpalStates", "equalFirstImmediateGainStates",
                        "smallerFirstImmediateGainStates", "preservingForecastOracleGainStates",
                        "preservingForecastOracleSafetyStates", "waitForecastOracleGainStates"] { summary.counts[key] = 0 }
            for seed in start..<(start + UInt64(seeds)) {
                var game = FallingSky(seed: seed, generation: .current)
                for _ in 0..<limit where !game.isOver {
                    game.letStarsFall(); precondition(game.isValidSave)
                    guard !game.isOver else { break }
                    summary.count("decisionStates")
                    let hasOpal = game.board.contains { $0?.isLight == true }
                    let alternatives = choices(game, subsets: hasOpal)
                    let source = game
                    if hasOpal {
                        summary.count("opalStates")
                        if !alternatives.complete { summary.count("cappedOpalStates") }
                        else if let greedy = select(alternatives.actions, preserveTies: false) {
                            summary.count("uncappedOpalDecisionStates")
                            let opals = (0..<49).map { Cell($0/7,$0%7) }.filter { game.gem(at: $0)?.isLight == true }
                            if opals.contains(where: { orb in
                                let families = Set(alternatives.actions.filter { $0.selected & bit(orb) != 0 }.flatMap {
                                    cells($0.selected).compactMap { game.gem(at: $0)?.kind?.rawValue }
                                })
                                return families.count >= 2
                            }) { summary.count("sharedOpalStates") }
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
                            if equal { summary.count("equalFirstImmediateGainStates") }
                            if smaller { summary.count("smallerFirstImmediateGainStates") }
                            if forecast { summary.count("preservingForecastOracleGainStates") }
                            if safety { summary.count("preservingForecastOracleSafetyStates") }
                            if greedy.opalsSpent > 0 {
                                let waiting = evaluate(nil, game)
                                if !waiting.overflow && waiting.afterShowerTotal > baseline.afterShowerTotal {
                                    summary.count("waitForecastOracleGainStates")
                                    retain("wait-forecast-oracle-gain", nil, waiting)
                                }
                            }
                        } else { summary.count("opalStatesWithoutClear") }
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
            summaries.append(summary)
        }
        struct Report: Codable { let seedStart: UInt64; let seeds: Int; let showerLimit: Int; let summaries: [Summary] }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        FileHandle.standardOutput.write(try encoder.encode(Report(seedStart: start, seeds: seeds, showerLimit: limit, summaries: summaries)))
    }
}
