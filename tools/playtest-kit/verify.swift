import Foundation

// Focused reachability/answer-key check. Compile with a frozen real Game.swift.
let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let fixture = try JSONSerialization.jsonObject(with: data) as! [String: Any]
let example = fixture["example"] as! [String: Any]
let seed = UInt64(example["seed_provenance_only"] as! String)!
let glyphs: [Character: Jewel] = ["R": .rose, "A": .aqua, "T": .amber, "V": .violet, "M": .mint]
func board(_ rows: [String]) -> [Jewel?] { rows.reversed().flatMap { $0.map { glyphs[$0] } } }
func cell(_ pair: [Int]) -> Cell { Cell(pair[0], pair[1]) }
let expected = board(example["board_top_to_bottom"] as! [String]).map { $0! }
let path = example["prior_largest_policy_taps_bottom_zero"] as! [[Int]]
precondition(Game.side == 7 && Game.startingMoves == 18 && Game.target == 70 && Jewel.allCases.count == 5)
var game = Game(seed: seed)
for pair in path {
    let groups = game.legalGroups
    let maximum = groups.map(\.count).max()!
    let stableLargest = groups.first { $0.count == maximum }!
    precondition(stableLargest[0] == cell(pair), "Replay path must remain the recorded largest policy")
    precondition(game.tap(cell(pair)) != nil && game.isValidSave)
}
precondition(game.board == expected, "Recorded board is no longer reachable by the recorded path")
precondition(game.score == example["score"] as! Int && game.moves == example["moves"] as! Int)
precondition(game.score == 43 && game.moves == 9 && game.outcome == .playing)

let setup = (example["strict_smaller_setups"] as! [[String: Any]])[0]
let anchor = cell(setup["anchor_bottom_zero_row_column"] as! [Int])
let survivors = board(setup["survivors_top_to_bottom"] as! [String])
let known = Set((fixture["known_followup_cells_core"] as! [[Int]]).map(cell))
precondition(known.count == 9 && game.group(at: anchor).count == 3)
let unknown = survivors.indices.filter { survivors[$0] == nil }
precondition(unknown.count == 3)
let followup = known.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }[0]

// Every possible assignment to these three unknown slots preserves the nine.
for fill in 0..<125 {
    var complete = survivors.map { $0 ?? .rose }
    var code = fill
    for index in unknown { complete[index] = Jewel(rawValue: code % 5)!; code /= 5 }
    let fullBoard = Game(board: complete, moves: 8, score: 46)
    precondition(fullBoard.group(at: followup).isSuperset(of: known))
}
var planned = game
let turn = planned.tap(anchor)!
precondition(!turn.reshuffled && turn.cleared.count == 3 && planned.score == 46 && planned.moves == 8)
for index in survivors.indices {
    if let kind = survivors[index] { precondition(planned.board[index] == kind) }
}
let actualFollowup = planned.group(at: followup)
precondition(actualFollowup.isSuperset(of: known))
planned.tap(followup)
precondition(planned.score >= 55 && planned.moves == 7 && planned.isValidSave)

let largest = example["largest_action"] as! [String: Any]
let largestAnchor = cell(largest["anchor_bottom_zero_row_column"] as! [Int])
precondition(game.group(at: largestAnchor).count == 5)
var greedy = game
let greedyTurn = greedy.tap(largestAnchor)!
precondition(!greedyTurn.reshuffled && greedy.score == 48 && greedy.moves == 8)
let greedySurvivors = board(largest["survivors_top_to_bottom"] as! [String])
for index in greedySurvivors.indices {
    if let kind = greedySurvivors[index] { precondition(greedy.board[index] == kind) }
}

print("PASS: exact 9-tap real-core replay, score 43/moves 9, both first clears, known survivor positions, 125 refill assignments, and actual follow-up of \(actualFollowup.count) mint.")
