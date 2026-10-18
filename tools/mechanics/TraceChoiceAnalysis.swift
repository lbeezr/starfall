import Foundation

private func bit(_ cell: Cell) -> UInt64 { UInt64(1) << (cell.row * 7 + cell.column) }
private func mask(_ cells: some Sequence<Cell>) -> UInt64 { cells.reduce(0) { $0 | bit($1) } }
private func cells(_ mask: UInt64) -> [Cell] {
    (0..<49).filter { mask & (UInt64(1) << $0) != 0 }.map { Cell($0 / 7, $0 % 7) }
}
private func adjacent(_ a: Cell, _ b: Cell) -> Bool {
    a != b && abs(a.row-b.row) <= 1 && abs(a.column-b.column) <= 1
}

private func walk(_ selected: UInt64) -> [Cell] {
    let ordered = cells(selected)
    guard let first = ordered.first else { return [] }
    var seen: Set<Cell> = [first], path = [first]
    func visit(_ cell: Cell) {
        for next in ordered where adjacent(cell, next) && !seen.contains(next) {
            seen.insert(next); path.append(next); visit(next); path.append(cell)
        }
    }
    visit(first)
    precondition(seen.count == ordered.count && path.count <= 196)
    return path
}

private func fives(_ component: UInt64, cap: Int = 512) -> (sets: [UInt64], complete: Bool) {
    let members = cells(component)
    var frontier = Set(members.map(bit))
    guard members.count >= 5 else { return ([], true) }
    for _ in 2...5 {
        var next: Set<UInt64> = []
        for selected in frontier.sorted() {
            let current = cells(selected)
            for cell in members where selected & bit(cell) == 0 && current.contains(where: { adjacent($0, cell) }) {
                next.insert(selected | bit(cell))
                if next.count > cap { return ([], false) }
            }
        }
        frontier = next
    }
    return (frontier.sorted(), true)
}

private struct Choice: Codable {
    let selected: UInt64
    var trace: [Cell]?
    var tap: Cell?
}
private struct ChoiceSet {
    let choices: [Choice]
    let complete: Bool
}
private func choices(_ game: FallingSky, enumerate: Bool = true) -> ChoiceSet {
    guard !game.isOver else { return ChoiceSet(choices: [], complete: true) }
    var result: [UInt64: Choice] = [:]
    for group in game.orthogonalLegalGroups {
        let key = mask(group)
        result[key] = Choice(selected: key, trace: nil, tap: group[0])
    }
    let components = game.legalGroups.filter { $0.count >= 5 }.map { mask($0) }
    func addTrace(_ key: UInt64) {
        let path = walk(key)
        precondition(game.constellationCells(along: path) == Set(cells(key)))
        var choice = result[key] ?? Choice(selected: key, trace: nil, tap: nil)
        choice.trace = path; result[key] = choice
    }
    for component in components { addTrace(component) }
    let base = result.values.sorted { $0.selected < $1.selected }
    if enumerate {
        for component in components {
            let five = fives(component)
            guard five.complete else { return ChoiceSet(choices: base, complete: false) }
            for selected in five.sets { addTrace(selected) }
            guard result.count <= 1024 else { return ChoiceSet(choices: base, complete: false) }
        }
    }
    return ChoiceSet(choices: result.values.sorted { $0.selected < $1.selected }, complete: true)
}
private func light(_ choice: Choice, _ game: FallingSky) -> Int { game.value(of: Set(cells(choice.selected))) }
private func largest(_ alternatives: [Choice], _ game: FallingSky) -> Choice? {
    alternatives.sorted {
        let a = light($0, game), b = light($1, game)
        return a == b ? $0.selected < $1.selected : a > b
    }.first
}
@discardableResult private func commit(_ choice: Choice, _ game: inout FallingSky) -> Int {
    let before = game
    let turn: FallingSkyTurn?
    if let tap = choice.tap { turn = game.clearOrdinary(tap) }
    else { turn = game.clearConstellation(choice.trace!) }
    precondition(turn != nil && turn!.collected == light(choice, before))
    precondition(game.turns == before.turns && game.incoming == before.incoming && game.isValidSave)
    return turn!.collected
}
private func heights(_ game: FallingSky) -> [Int] {
    (0..<7).map { column in (0..<7).filter { game.gem(at: Cell($0, column)) != nil }.count }
}
private struct TraceChoiceOutcome: Codable, Equatable {
    let collected: Int
    let occupiedAfterClear: Int
    let heightsAfterClear: [Int]
    let darknessRemoved: Int
    let immediateBestFollowupLight: Int
    let collectedPlusImmediateBestFollowup: Int
    let overflowAfterAnnouncedShower: Bool
    let bestFollowupLight: Int
    let collectedPlusBestFollowup: Int
}
private func outcome(_ choice: Choice, _ source: FallingSky) -> (TraceChoiceOutcome, Choice?) {
    var game = source
    let collected = commit(choice, &game)
    let occupied = game.occupiedCount, height = heights(game), dark = game.darkStarsCleared-source.darkStarsCleared
    let immediate = largest(choices(game, enumerate: false).choices, game)
    let immediateValue = immediate.map { light($0, game) } ?? 0
    game.letStarsFall(); precondition(game.isValidSave)
    let followup = largest(choices(game, enumerate: false).choices, game)
    let value = followup.map { light($0, game) } ?? 0
    return (TraceChoiceOutcome(collected: collected, occupiedAfterClear: occupied, heightsAfterClear: height,
                    darknessRemoved: dark, immediateBestFollowupLight: immediateValue,
                    collectedPlusImmediateBestFollowup: collected+immediateValue,
                    overflowAfterAnnouncedShower: game.isOver,
                    bestFollowupLight: value, collectedPlusBestFollowup: collected+value), followup)
}
private struct Branch: Codable {
    let choice: Choice
    let result: TraceChoiceOutcome
    let bestFollowup: Choice?
    let immediateBestFollowup: Choice?
}
private struct Fixture: Codable {
    let category: String
    let policy: String
    let seed: UInt64
    let shower: Int
    let clearIndex: Int
    let initial: FallingSky
    let branches: [Branch]
}
private struct Round: Codable { let seed: UInt64; let showers: Int; let score: Int; let clears: Int; let overflow: Bool }
private struct Summary: Codable { var counts: [String: Int] = [:]; var rounds: [Round] = [] }

@main private enum TraceChoiceAnalysis {
    static func selfChecks() -> [String] {
        let chain = mask((0..<6).map { Cell($0,$0) })
        precondition(fives(chain).sets == [mask((0..<5).map { Cell($0,$0) }), mask((1..<6).map { Cell($0,$0) })].sorted())
        let rectangle = mask((0..<2).flatMap { row in (0..<3).map { Cell(row,$0) } })
        precondition(fives(rectangle).sets.count == 6)
        precondition(!fives(rectangle, cap: 2).complete)
        for selected in fives(rectangle).sets {
            let path = walk(selected)
            precondition(mask(path) == selected && path.count <= 9)
            precondition(zip(path, path.dropFirst()).allSatisfy { adjacent($0.0, $0.1) })
        }
        // Layout-only topology check; never persisted or retained as a valid save.
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        for column in 0..<5 { board[column] = .init(id: column, kind: .rose) }
        let game = FallingSky(board: board, incoming: [.init(id: 0, kind: .aqua, column: 6)])
        let alternatives = choices(game)
        precondition(alternatives.complete && alternatives.choices.count == 1)
        precondition(alternatives.choices[0].trace != nil && alternatives.choices[0].tap != nil)
        precondition(game.constellationCells(along: walk(mask((0..<5).map { Cell(0,$0) })))?.count == 5)
        // Committed arrivals make a valid save. An immediate follow-up cannot
        // spend a generated preview; probing must leave the source unchanged.
        var arrived = FallingSky(board: Array(repeating: nil, count: 49), incoming:
            (0..<3).map { IncomingStar(id: $0, kind: .rose, column: $0) }, seed: 17)
        arrived.letStarsFall()
        precondition(arrived.isValidSave)
        let beforeProbe = arrived
        let first = largest(choices(arrived).choices, arrived)!
        let probe = outcome(first, arrived).0
        precondition(probe.collected == 3 && probe.immediateBestFollowupLight == 0)
        precondition(probe.collectedPlusImmediateBestFollowup == 3 && arrived == beforeProbe)
        var cleared = arrived
        commit(first, &cleared)
        precondition(cleared.occupiedCount == 0 && cleared.incoming == arrived.incoming && cleared.turns == arrived.turns)
        return ["six-chain has exactly two connected fives", "two-by-three has six connected fives",
                "cap excludes incomplete enumeration", "walks preserve chosen sets with bounded retracing",
                "tap/trace duplicate outcome counted once", "immediate probe cannot spend future arrivals or mutate its source"]
    }
    static func main() throws {
        let checks = selfChecks()
        var summaries: [String: Summary] = [:]
        var retained: [String: (Int, Fixture)] = [:]
        for policy in ["largest-whole-or-tap", "five-at-a-time-or-tap"] {
            var summary = Summary()
            for key in ["decisionStates", "cappedStatesExcludedFromComparisons", "statesWithFiveStarChoice",
                        "enumeratedFiveChoices", "maximumFiveChoicesInOneState", "statesWithSameValueFiveAlternatives",
                        "statesWithSameValueShowerSafetyDifference", "statesWithSameValueNextClearDifference",
                        "statesWherePartialHasHigherTwoClearPotential", "wholeOrTapFallbacks", "ordinaryTapCommits",
                        "traceCommits", "commitsPreservingPartOfLargerComponent", "tracedFiveFromLargerComponent",
                        "statesWherePartialHasHigherImmediateTwoClearPotential", "statesWithSameValueImmediateClearDifference",
                        "statesWithMultipleLegalChoices", "statesWhereSmallerFirstBeatsLargestOverTwoImmediateClears",
                        "statesWhereEqualFirstValueBeatsLargestTieOverTwoImmediateClears"] { summary.counts[key] = 0 }
            for seed in UInt64(0)...15 {
                var game = FallingSky(seed: seed), clears = 0
                while game.turns < 24 && !game.isOver {
                    game.letStarsFall(); precondition(game.isValidSave)
                    let showerRestore = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                    precondition(showerRestore == game)
                    if game.isOver { break }
                    var index = 0
                    while index < 49 {
                        let alternatives = choices(game)
                        if alternatives.choices.isEmpty { break }
                        summary.counts["decisionStates", default: 0] += 1
                        let five = alternatives.choices.filter { $0.trace != nil && $0.selected.nonzeroBitCount == 5 }
                        let whole = alternatives.choices.filter { $0.trace != nil && $0.selected.nonzeroBitCount > 5 }
                        if !alternatives.complete { summary.counts["cappedStatesExcludedFromComparisons", default: 0] += 1 }
                        else {
                            if !five.isEmpty {
                            summary.counts["statesWithFiveStarChoice", default: 0] += 1
                            summary.counts["enumeratedFiveChoices", default: 0] += five.count
                            summary.counts["maximumFiveChoicesInOneState"] = max(summary.counts["maximumFiveChoicesInOneState", default: 0], five.count)
                            }
                            let evaluated = Dictionary(uniqueKeysWithValues: alternatives.choices.map { ($0.selected, outcome($0, game)) })
                            func retain(_ category: String, _ strength: Int, _ a: Choice, _ b: Choice) {
                                guard strength > (retained[category]?.0 ?? -1) else { return }
                                let fixture = Fixture(category: category, policy: policy, seed: seed, shower: game.turns,
                                    clearIndex: index, initial: game, branches: [a,b].map {
                                        let result = evaluated[$0.selected]!
                                        var cleared = game
                                        commit($0, &cleared)
                                        return Branch(choice: $0, result: result.0, bestFollowup: result.1,
                                            immediateBestFollowup: largest(choices(cleared, enumerate: false).choices, cleared))
                                    })
                                retained[category] = (strength, fixture)
                            }
                            if alternatives.choices.count > 1 {
                                summary.counts["statesWithMultipleLegalChoices", default: 0] += 1
                                let greedy = largest(alternatives.choices, game)!
                                let baseline = evaluated[greedy.selected]!.0
                                var smaller = false, equal = false
                                for choice in alternatives.choices where choice.selected != greedy.selected {
                                    let candidate = evaluated[choice.selected]!.0
                                    let gain = candidate.collectedPlusImmediateBestFollowup-baseline.collectedPlusImmediateBestFollowup
                                    if gain > 0 && candidate.collected < baseline.collected {
                                        smaller = true
                                        retain("smaller-first-before-shower", gain, choice, greedy)
                                    } else if gain > 0 && candidate.collected == baseline.collected { equal = true }
                                }
                                if smaller { summary.counts["statesWhereSmallerFirstBeatsLargestOverTwoImmediateClears", default: 0] += 1 }
                                if equal { summary.counts["statesWhereEqualFirstValueBeatsLargestTieOverTwoImmediateClears", default: 0] += 1 }
                            }
                            let grouped = Dictionary(grouping: five, by: { light($0, game) })
                            let cohorts = grouped.keys.sorted().compactMap { key in
                                grouped[key]!.count > 1 ? grouped[key] : nil
                            }
                            if !cohorts.isEmpty { summary.counts["statesWithSameValueFiveAlternatives", default: 0] += 1 }
                            var safety = false, followup = false, partial = false, immediatePartial = false, immediateDifferent = false
                            for cohort in cohorts {
                                let immediateValues = Set(cohort.map { evaluated[$0.selected]!.0.immediateBestFollowupLight })
                                if immediateValues.count > 1 {
                                    immediateDifferent = true
                                    let best = cohort.max { evaluated[$0.selected]!.0.immediateBestFollowupLight < evaluated[$1.selected]!.0.immediateBestFollowupLight }!
                                    let worst = cohort.min { evaluated[$0.selected]!.0.immediateBestFollowupLight < evaluated[$1.selected]!.0.immediateBestFollowupLight }!
                                    let gain = evaluated[best.selected]!.0.immediateBestFollowupLight-evaluated[worst.selected]!.0.immediateBestFollowupLight
                                    retain("same-value-before-shower", gain, best, worst)
                                }
                                let alive = cohort.filter { !evaluated[$0.selected]!.0.overflowAfterAnnouncedShower }
                                let lost = cohort.filter { evaluated[$0.selected]!.0.overflowAfterAnnouncedShower }
                                if let a = alive.first, let b = lost.first {
                                    safety = true; retain("same-value-column-safety", 1, a, b)
                                }
                                if let best = alive.max(by: { evaluated[$0.selected]!.0.bestFollowupLight < evaluated[$1.selected]!.0.bestFollowupLight }),
                                   let worst = alive.min(by: { evaluated[$0.selected]!.0.bestFollowupLight < evaluated[$1.selected]!.0.bestFollowupLight }) {
                                    let gain = evaluated[best.selected]!.0.bestFollowupLight-evaluated[worst.selected]!.0.bestFollowupLight
                                    if gain > 0 { followup = true; retain("same-value-followup", gain, best, worst) }
                                }
                            }
                            for full in whole { for small in five where small.selected & full.selected == small.selected {
                                let a = evaluated[small.selected]!.0, b = evaluated[full.selected]!.0
                                let gain = a.collectedPlusBestFollowup-b.collectedPlusBestFollowup
                                if !a.overflowAfterAnnouncedShower && gain > 0 {
                                    partial = true; retain("partial-beats-whole-with-followup", gain, small, full)
                                }
                                let immediateGain = a.collectedPlusImmediateBestFollowup-b.collectedPlusImmediateBestFollowup
                                if immediateGain > 0 {
                                    immediatePartial = true
                                    retain("partial-beats-whole-before-shower", immediateGain, small, full)
                                }
                            } }
                            if safety { summary.counts["statesWithSameValueShowerSafetyDifference", default: 0] += 1 }
                            if followup { summary.counts["statesWithSameValueNextClearDifference", default: 0] += 1 }
                            if partial { summary.counts["statesWherePartialHasHigherTwoClearPotential", default: 0] += 1 }
                            if immediatePartial { summary.counts["statesWherePartialHasHigherImmediateTwoClearPotential", default: 0] += 1 }
                            if immediateDifferent { summary.counts["statesWithSameValueImmediateClearDifference", default: 0] += 1 }
                        }
                        var available = alternatives.choices
                        if policy == "five-at-a-time-or-tap" {
                            if alternatives.complete { available = available.filter { $0.tap != nil || $0.selected.nonzeroBitCount == 5 } }
                            else { summary.counts["wholeOrTapFallbacks", default: 0] += 1 }
                        }
                        let selected = largest(available, game)!
                        let preserves = whole.contains { selected.selected != $0.selected && selected.selected & $0.selected == selected.selected }
                        summary.counts[selected.tap != nil ? "ordinaryTapCommits" : "traceCommits", default: 0] += 1
                        if preserves { summary.counts["commitsPreservingPartOfLargerComponent", default: 0] += 1 }
                        if preserves && selected.tap == nil && selected.selected.nonzeroBitCount == 5 {
                            summary.counts["tracedFiveFromLargerComponent", default: 0] += 1
                        }
                        commit(selected, &game); precondition(game.isValidSave)
                        let clearRestore = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                        precondition(clearRestore == game)
                        index += 1; clears += 1
                    }
                    precondition(index < 49, "Clear loop bound reached")
                }
                summary.rounds.append(Round(seed: seed, showers: game.turns, score: game.score, clears: clears, overflow: game.isOver))
            }
            summaries[policy] = summary
        }
        let fixtures = retained.keys.sorted().map { retained[$0]!.1 }
        for fixture in fixtures {
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(fixture.initial))
            precondition(restored == fixture.initial && restored.isValidSave)
            for branch in fixture.branches {
                precondition(outcome(branch.choice, restored).0 == branch.result)
                var game = restored
                let first = commit(branch.choice, &game)
                game.letStarsFall(); precondition(game.isValidSave)
                let second = branch.bestFollowup.map { commit($0, &game) } ?? 0
                precondition(first+second == branch.result.collectedPlusBestFollowup && game.isValidSave)
                var immediateGame = restored
                let immediateFirst = commit(branch.choice, &immediateGame)
                let immediateSecond = branch.immediateBestFollowup.map { commit($0, &immediateGame) } ?? 0
                precondition(immediateFirst+immediateSecond == branch.result.collectedPlusImmediateBestFollowup)
                precondition(immediateGame.turns == restored.turns && immediateGame.incoming == restored.incoming && immediateGame.isValidSave)
            }
        }
        struct Report: Codable {
            let seeds: [Int]; let showerCap: Int; let frontierCap: Int; let stateChoiceCap: Int
            let checks: [String]; let policies: [String: Summary]; let fixtures: [Fixture]
        }
        let report = Report(seeds: [0,15], showerCap: 24, frontierCap: 512, stateChoiceCap: 1024,
                            checks: checks, policies: summaries, fixtures: fixtures)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(data: try encoder.encode(report), encoding: .utf8)!)
    }
}
