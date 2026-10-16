import Foundation

// Diagnostic only. Compile alongside an unchanged snapshot of the real Game.swift.
// A policy receives only this visible observation, never Game, seed, or refill RNG.
struct VisibleBoard {
    let board: [Jewel]
    let score: Int
    let moves: Int
    let actions: [Action]

    init(board: [Jewel], score: Int, moves: Int) {
        self.board = board
        self.score = score
        self.moves = moves
        let components = knownComponents(board.map(Optional.some))
        var origins = Array(repeating: -1, count: board.count)
        for (origin, group) in components.enumerated() {
            for index in group { origins[index] = origin }
        }
        actions = components.filter { $0.count >= 3 }.map { group in
            var settled = Array<Jewel?>(repeating: nil, count: board.count)
            var settledOrigins = Array(repeating: -1, count: board.count)
            let cleared = Set(group)
            for column in 0..<Game.side {
                var destinationRow = 0
                for row in 0..<Game.side {
                    let source = row * Game.side + column
                    if cleared.contains(source) { continue }
                    let destination = destinationRow * Game.side + column
                    settled[destination] = board[source]
                    settledOrigins[destination] = origins[source]
                    destinationRow += 1
                }
            }
            let next = knownComponents(settled).filter { $0.count >= 3 }
            let newlyJoined = next.filter { Set($0.map { settledOrigins[$0] }).count > 1 }
            return Action(cells: group, survivors: settled,
                          nextLargest: next.map(\.count).max() ?? 0,
                          nextGroups: next.count,
                          joinedLargest: newlyJoined.map(\.count).max() ?? 0)
        }
    }
}

struct Action {
    let cells: [Int]
    let survivors: [Jewel?]
    let nextLargest: Int
    let nextGroups: Int
    // A component containing survivors from >=2 separate original components.
    let joinedLargest: Int
    var anchor: Int { cells[0] }
    var size: Int { cells.count }
    // Deliberately pessimistic: unknown refill and recovery get no credit.
    var floor: Int { size + nextLargest }
    var cell: Cell { Cell(anchor / Game.side, anchor % Game.side) }
}

func knownComponents(_ board: [Jewel?]) -> [[Int]] {
    var seen = Set<Int>()
    var groups: [[Int]] = []
    for start in board.indices {
        guard let kind = board[start], !seen.contains(start) else { continue }
        seen.insert(start)
        var pending = [start]
        var group: [Int] = []
        while let index = pending.popLast() {
            group.append(index)
            let row = index / Game.side, column = index % Game.side
            let neighbors = [(row - 1, column), (row + 1, column),
                             (row, column - 1), (row, column + 1)]
            for (r, c) in neighbors where (0..<Game.side).contains(r) && (0..<Game.side).contains(c) {
                let neighbor = r * Game.side + c
                if !seen.contains(neighbor), board[neighbor] == kind {
                    seen.insert(neighbor)
                    pending.append(neighbor)
                }
            }
        }
        groups.append(group.sorted())
    }
    return groups
}

enum Policy: String, CaseIterable {
    case randomA = "random_legal_a"
    case randomB = "random_legal_b"
    case largest = "largest"
    case survivorTie = "largest_survivor_tie"
    case twoClear = "two_clear_floor"

    func choose(_ visible: VisibleBoard, random: inout SeededRandom) -> Int {
        let actions = visible.actions
        precondition(!actions.isEmpty)
        if self == .randomA || self == .randomB {
            // Rejection sampling: uniform over distinct legal groups, not cells.
            let count = UInt64(actions.count)
            let threshold = (0 &- count) % count
            var draw = random.next()
            while draw < threshold { draw = random.next() }
            return Int(draw % count)
        }
        let largest = firstBest(actions) { [$0.size] }
        // Never sacrifice an immediate win, or plan with only one move left.
        if self == .largest || visible.moves == 1 || actions[largest].size >= Game.target - visible.score {
            return largest
        }
        if self == .survivorTie {
            return firstBest(actions) { [$0.size, $0.nextLargest] }
        }
        return firstBest(actions) { [$0.floor, $0.size] }
    }
}

func firstBest(_ actions: [Action], rank: (Action) -> [Int]) -> Int {
    var best = 0
    for index in actions.indices.dropFirst() {
        if rank(actions[best]).lexicographicallyPrecedes(rank(actions[index])) { best = index }
    }
    return best
}

struct RoundResult {
    let cohort: String
    let ordinal: Int
    let seed: UInt64
    let policy: Policy
    let won: Bool
    let score: Int
    let turns: Int
    let repairs: Int
    let forced: Int
    let smallerChoices: Int
    let choicesDifferentFromLargest: Int
}

struct Signals {
    var allTurns = 0
    var multipleChoices = 0
    var planningEligible = 0
    var strictSmallerFloor = 0
    var joinedSetup = 0
    var finalTwoGuarantee = 0
    var finalTwoSmallerOnlyGuarantee = 0
    var roundsWithStrictSetup = Set<UInt64>()

    var json: [String: Any] {
        ["turns": allTurns, "turns_with_multiple_groups": multipleChoices,
         "planning_eligible_turns": planningEligible,
         "strict_smaller_floor_turns": strictSmallerFloor,
         "strict_smaller_floor_rounds": roundsWithStrictSetup.count,
         "strict_smaller_floor_with_joined_survivors_turns": joinedSetup,
         "last_two_moves_known_win_turns": finalTwoGuarantee,
         "last_two_moves_known_win_requires_smaller_turns": finalTwoSmallerOnlyGuarantee]
    }
}

let legend: [Character: Jewel] = ["R": .rose, "A": .aqua, "T": .amber, "V": .violet, "M": .mint]
let glyphs: [Character] = ["R", "A", "T", "V", "M"]
func parse(_ rows: [String]) -> [Jewel] { rows.flatMap { $0.map { legend[$0]! } } }
func rows(_ board: [Jewel?]) -> [String] {
    (0..<Game.side).reversed().map { row in
        String((0..<Game.side).map { column in
            board[row * Game.side + column].map { glyphs[$0.rawValue] } ?? "?"
        })
    }
}
func actionJSON(_ action: Action) -> [String: Any] {
    ["anchor_bottom_zero_row_column": [action.cell.row, action.cell.column],
     "immediate": action.size, "known_next_largest": action.nextLargest,
     "known_next_group_count": action.nextGroups, "known_two_clear_floor": action.floor,
     "largest_joined_survivor_group": action.joinedLargest,
     "survivors_top_to_bottom": rows(action.survivors)]
}

// Local checks verify the study's additional geometry, not an alternative rules engine.
func verifyStudy() {
    precondition(Game.side == 7 && Game.startingMoves == 18 && Game.target == 70)
    precondition(Jewel.allCases.count == 5)
    let lesson = parse(["RTTVMRA", "RVVMRAT", "ARMRATV", "ARRATVM", "ATATVMR", "RVRARAR", "RTMMMMM"])
    let visible = VisibleBoard(board: lesson, score: 60, moves: 2)
    precondition(visible.actions.map(\.size) == [3, 3, 5])
    precondition(visible.actions.map(\.nextLargest) == [7, 4, 3])
    var independentRandom = SeededRandom(seed: 0xABCA)
    precondition(Policy.twoClear.choose(visible, random: &independentRandom) == 0)
    precondition(Policy.twoClear.choose(VisibleBoard(board: lesson, score: 65, moves: 1), random: &independentRandom) == 2)
    precondition(Policy.twoClear.choose(VisibleBoard(board: lesson, score: 65, moves: 2), random: &independentRandom) == 2)
    let relabeled: [Jewel] = [.mint, .violet, .aqua, .rose, .amber]
    let transferred = (0..<Game.side).flatMap { row in
        (0..<Game.side).reversed().map { column in
            relabeled[lesson[row * Game.side + column].rawValue]
        }
    }
    let transfer = VisibleBoard(board: transferred, score: 60, moves: 2)
    let transferredChoice = transfer.actions[Policy.twoClear.choose(transfer, random: &independentRandom)]
    precondition(transferredChoice.cell == Cell(2, 6) && transferredChoice.size == 3 && transferredChoice.nextLargest == 7)
    let action = visible.actions[0]
    let unknown = action.survivors.indices.filter { action.survivors[$0] == nil }
    precondition(unknown.count == 3)
    for fill in 0..<125 {
        var complete = action.survivors.map { $0 ?? .rose }
        var code = fill
        for index in unknown { complete[index] = Jewel(rawValue: code % 5)!; code /= 5 }
        let fixture = Game(board: complete, moves: 1, score: 63)
        precondition(fixture.legalGroups.contains { $0.count >= 7 })
    }
    // Run the actual core for the lesson as well; a known follow-up must survive refill.
    for seed: UInt64 in 0..<125 {
        var game = Game(board: lesson, moves: 2, score: 60, seed: seed)
        let turn = game.tap(action.cell)!
        precondition(!turn.reshuffled && game.score == 63 && game.moves == 1)
        for index in action.survivors.indices {
            if let known = action.survivors[index] { precondition(game.board[index] == known) }
        }
        let next = game.legalGroups.max { $0.count < $1.count }!
        precondition(next.count >= 7)
        game.tap(next[0])
        precondition(game.outcome == .won)
    }
}

func aggregate(_ results: [RoundResult]) -> [String: Any] {
    let count = results.count
    let wins = results.filter(\.won)
    func mean(_ values: [Int]) -> Double { Double(values.reduce(0, +)) / Double(values.count) }
    let sortedScores = results.map(\.score).sorted()
    return ["rounds": count, "wins": wins.count,
            "win_percent": 100 * Double(wins.count) / Double(count),
            "mean_terminal_score": mean(results.map(\.score)),
            "mean_turns": mean(results.map(\.turns)),
            "mean_winning_turns": mean(wins.map(\.turns)),
            "terminal_score_min": sortedScores.first!,
            "terminal_score_p10": sortedScores[count / 10],
            "terminal_score_median": Double(sortedScores[(count - 1) / 2] + sortedScores[count / 2]) / 2,
            "terminal_score_p90": sortedScores[9 * count / 10],
            "terminal_score_max": sortedScores.last!,
            "rounds_with_repair": results.filter { $0.repairs > 0 }.count,
            "post_turn_repairs": results.map(\.repairs).reduce(0, +),
            "turns": results.map(\.turns).reduce(0, +),
            "forced_choice_turns": results.map(\.forced).reduce(0, +),
            "smaller_group_choices": results.map(\.smallerChoices).reduce(0, +),
            "choices_different_from_largest": results.map(\.choicesDifferentFromLargest).reduce(0, +)]
}

func paired(_ candidate: [RoundResult], _ baseline: [RoundResult]) -> [String: Any] {
    precondition(candidate.count == baseline.count)
    var both = 0, candidateOnly = 0, baselineOnly = 0, neither = 0
    for (a, b) in zip(candidate, baseline) {
        precondition(a.seed == b.seed && a.cohort == b.cohort)
        switch (a.won, b.won) {
        case (true, true): both += 1
        case (true, false): candidateOnly += 1
        case (false, true): baselineOnly += 1
        case (false, false): neither += 1
        }
    }
    return ["both_win": both, "candidate_only_win": candidateOnly,
            "largest_only_win": baselineOnly, "both_lose": neither,
            "win_percentage_point_difference": 100 * Double(candidateOnly - baselineOnly) / Double(candidate.count)]
}

func writeJSON(_ value: Any, to url: URL) throws {
    let data = try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
    try data.write(to: url)
}

func runStudy(output: URL) throws {
    let count = 1_000
    // Frozen before execution. No parameter fitting or searching of seed ranges.
    let cohorts: [(String, [UInt64])] = [
        ("sequential", (0..<count).map { UInt64($0) }),
        ("dispersed_holdout", (count..<(2 * count)).map {
            UInt64($0) &* 0x9E3779B97F4A7C15 &+ 0xD1B54A32D192ED03
        })
    ]
    var results: [RoundResult] = []
    var signals: [String: Signals] = [:]
    var examples: [[String: Any]] = []
    var floorClaimsChecked = 0
    var decisionsChecked = 0
    for policy in Policy.allCases {
        // Policy randomness is a separate fixed stream across rounds. It has no
        // dependence on a game seed or on any observed/hidden game random state.
        var policyRandom = SeededRandom(seed: policy == .randomB ? 0xF1357AEA2E62A9C5 : 0xA24BAED4963EE407)
        for (cohort, seeds) in cohorts {
            var cohortSignals = Signals()
            for (ordinal, seed) in seeds.enumerated() {
                var game = Game(seed: seed)
                var repairs = 0, forced = 0, smaller = 0, different = 0
                var path: [[Int]] = []
                while game.outcome == .playing {
                    precondition(game.isValidSave)
                    let visible = VisibleBoard(board: game.board, score: game.score, moves: game.moves)
                    precondition(visible.actions.map(\.cells) == game.legalGroups.map { $0.map { $0.row * Game.side + $0.column } })
                    let largestIndex = firstBest(visible.actions) { [$0.size] }
                    let largest = visible.actions[largestIndex]
                    let bestLargestFloor = visible.actions.filter { $0.size == largest.size }.map(\.floor).max()!
                    let strictSetups = visible.actions.filter { $0.size < largest.size && $0.floor > bestLargestFloor }
                    if visible.actions.count == 1 { forced += 1 }
                    if policy == .largest {
                        cohortSignals.allTurns += 1
                        if visible.actions.count > 1 { cohortSignals.multipleChoices += 1 }
                        if game.moves >= 2 && largest.size < Game.target - game.score {
                            cohortSignals.planningEligible += 1
                            if !strictSetups.isEmpty {
                                cohortSignals.strictSmallerFloor += 1
                                cohortSignals.roundsWithStrictSetup.insert(seed)
                                if strictSetups.contains(where: { $0.joinedLargest >= 3 }) { cohortSignals.joinedSetup += 1 }
                                if examples.count < 4 && strictSetups.contains(where: { $0.joinedLargest >= 3 }) {
                                    examples.append([
                                        "cohort": cohort, "seed_provenance_only": String(seed),
                                        "prior_largest_policy_taps_bottom_zero": path,
                                        "score": game.score, "moves": game.moves,
                                        "board_top_to_bottom": rows(game.board.map(Optional.some)),
                                        "best_floor_among_current_largest_actions": bestLargestFloor,
                                        "largest_action": actionJSON(largest),
                                        "strict_smaller_setups": strictSetups.map(actionJSON)
                                    ])
                                }
                            }
                            if game.moves == 2 && visible.actions.contains(where: { $0.floor >= Game.target - game.score }) {
                                cohortSignals.finalTwoGuarantee += 1
                                if bestLargestFloor < Game.target - game.score { cohortSignals.finalTwoSmallerOnlyGuarantee += 1 }
                            }
                        }
                    }
                    let choice = policy.choose(visible, random: &policyRandom)
                    let action = visible.actions[choice]
                    if action.size < largest.size { smaller += 1 }
                    if choice != largestIndex { different += 1 }
                    let beforeScore = game.score, beforeMoves = game.moves
                    let turn = game.tap(action.cell)!
                    precondition(turn.cleared.count == action.size)
                    precondition(game.score == beforeScore + action.size && game.moves == beforeMoves - 1)
                    precondition(game.isValidSave)
                    if action.nextLargest >= 3 {
                        precondition(!turn.reshuffled)
                        precondition((game.legalGroups.map(\.count).max() ?? 0) >= action.nextLargest)
                        floorClaimsChecked += 1
                    }
                    if !turn.reshuffled {
                        for index in action.survivors.indices {
                            if let known = action.survivors[index] { precondition(game.board[index] == known) }
                        }
                    }
                    if turn.reshuffled { repairs += 1 }
                    decisionsChecked += 1
                    path.append([action.cell.row, action.cell.column])
                }
                results.append(RoundResult(cohort: cohort, ordinal: ordinal, seed: seed, policy: policy,
                                           won: game.outcome == .won, score: game.score,
                                           turns: Game.startingMoves - game.moves, repairs: repairs,
                                           forced: forced, smallerChoices: smaller,
                                           choicesDifferentFromLargest: different))
            }
            if policy == .largest { signals[cohort] = cohortSignals }
        }
    }
    var overall: [String: Any] = [:], byCohort: [String: Any] = [:], pairs: [String: Any] = [:]
    let largestResults = results.filter { $0.policy == .largest }
    for policy in Policy.allCases {
        let selected = results.filter { $0.policy == policy }
        overall[policy.rawValue] = aggregate(selected)
        if policy != .largest { pairs[policy.rawValue] = paired(selected, largestResults) }
    }
    for (cohort, _) in cohorts {
        var values: [String: Any] = [:]
        let baseline = largestResults.filter { $0.cohort == cohort }
        for policy in Policy.allCases {
            let selected = results.filter { $0.policy == policy && $0.cohort == cohort }
            var value = aggregate(selected)
            if policy != .largest { value["paired_vs_largest"] = paired(selected, baseline) }
            values[policy.rawValue] = value
        }
        byCohort[cohort] = values
    }
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    try writeJSON(["rounds": results.count, "rounds_per_policy": 2 * count,
                   "decisions_checked": decisionsChecked,
                   "known_followup_claims_checked": floorClaimsChecked,
                   "overall": overall, "cohorts": byCohort,
                   "paired_vs_largest": pairs,
                   "signals_on_largest_policy_path": signals.mapValues(\.json)],
                  to: output.appendingPathComponent("summary.json"))
    try writeJSON(examples, to: output.appendingPathComponent("reachable-examples.json"))
    var csv = "cohort,ordinal,seed,policy,won,terminal_score,turns,repairs,forced_choice_turns,smaller_group_choices,choices_different_from_largest\n"
    for r in results {
        csv += "\(r.cohort),\(r.ordinal),\(r.seed),\(r.policy.rawValue),\(r.won ? 1 : 0),\(r.score),\(r.turns),\(r.repairs),\(r.forced),\(r.smallerChoices),\(r.choicesDifferentFromLargest)\n"
    }
    try csv.write(to: output.appendingPathComponent("rounds.csv"), atomically: true, encoding: .utf8)
    print("PASS: 125 exhaustive lesson fills; 125 real-core lesson runs; \(results.count) rounds; \(decisionsChecked) checked turns; \(floorClaimsChecked) survivor guarantees.")
    for policy in Policy.allCases {
        let selected = results.filter { $0.policy == policy }
        print("\(policy.rawValue): \(selected.filter(\.won).count)/\(selected.count) wins")
    }
}

verifyStudy()
if CommandLine.arguments.count == 2 && CommandLine.arguments[1] == "--verify" {
    print("PASS: study geometry, terminal decisions, 125 exhaustive lesson fills, and 125 real-core lesson runs.")
} else if CommandLine.arguments.count == 2 {
    try runStudy(output: URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true))
} else {
    fputs("Usage: gameplay-study OUTPUT_DIRECTORY | --verify\n", stderr)
    exit(2)
}
