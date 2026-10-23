import Foundation
import StarfallCore

let root = URL(fileURLWithPath: "/private/tmp/starfall-mastery-20261023")
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
func board(_ value: [StarfallGem?]) -> [Any] {
    value.map { star -> Any in
        guard let star else { return NSNull() }
        return ["id": star.id, "kind": String(describing: star.kind!), "grown": star.grown] as [String: Any]
    }
}
func goalA(_ phase: SkyResolutionPhase) -> [Int] {
    phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
        .filter { $0.grown && $0.kind != nil && !$0.isLight && $0.gravityKind == nil }.map(\.id).sorted()
}
func goalB(_ phases: [SkyResolutionPhase]) -> Bool {
    guard phases.count > 1 else { return false }
    for (a,b) in zip(phases, phases.dropFirst()) {
        let first = Set(a.cleared.compactMap { a.before[$0.row * 7 + $0.column]?.id })
        let second = Set(b.cleared.compactMap { b.before[$0.row * 7 + $0.column]?.id })
        if a.kind == .recipe && b.kind == .recipe && !first.isEmpty && !second.isEmpty && b.before == a.settled && first.isDisjoint(with: second) { return true }
    }
    return false
}
func cell(_ index: Int) -> Cell { Cell(index / 7, index % 7) }
func write(_ value: Any, _ name: String) throws {
    try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]).write(to: root.appendingPathComponent(name))
}
func phaseRecord(_ phase: SkyResolutionPhase) -> [String: Any] {
    ["kind": phase.kind.rawValue, "depth": phase.comboDepth, "before": board(phase.before), "settled": board(phase.settled),
     "clearedCells": phase.cleared.map { $0.row * 7 + $0.column }.sorted(), "clearedIDs": phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id }.sorted(),
     "grownClearedIDs": goalA(phase), "points": phase.award.displayPoints, "baseLight": phase.award.baseLight, "clearedStarCount": phase.award.clearedStarCount,
     "recipes": phase.recipes.map { ["shape": $0.shape.rawValue, "ids": $0.starIDs.sorted(), "cells": $0.cells.map { $0.row * 7 + $0.column }] }]
}
func audit(_ actions: [[Int]], name: String) throws {
    var game = FallingSky.freshChallenge(.firstLight)
    var records: [[String: Any]] = [], aIndices: [Int] = [], bIndices: [Int] = []
    for (index,action) in actions.enumerated() {
        precondition(!game.isOver)
        let before = game
        let turn: FallingSkyTurn
        if action.isEmpty { turn = game.letStarsFall()! } else { turn = game.nudge(from: cell(action[0]), to: cell(action[1]))! }
        let restored = try JSONDecoder().decode(FallingSky.self, from: encoder.encode(game))
        precondition(game.isValidSave && restored == game && restored.isValidSave)
        if turn.resolutionPhases.contains(where: { !goalA($0).isEmpty }) { aIndices.append(index) }
        if goalB(turn.resolutionPhases) { bIndices.append(index) }
        let causality = zip(turn.resolutionPhases,turn.resolutionPhases.dropFirst()).map { earlier,later -> [String: Any] in
            let earlierIDs=Set(earlier.cleared.compactMap { earlier.before[$0.row * 7 + $0.column]?.id })
            let laterIDs=Set(later.cleared.compactMap { later.before[$0.row * 7 + $0.column]?.id })
            let moved=laterIDs.filter { id in earlier.before.firstIndex(where:{$0?.id==id}) != later.before.firstIndex(where:{$0?.id==id}) }.sorted()
            return ["linkedBoards": later.before == earlier.settled, "distinctSurvivingIDs": earlierIDs.isDisjoint(with:laterIDs), "laterIngredientIDs": laterIDs.sorted(), "movedIngredientIDs": moved]
        }
        records.append(["actionIndex": index, "action": action, "showersBefore": before.turns, "showersAfter": game.turns,
                        "scoreBefore": before.displayScore, "scoreAfter": game.displayScore, "outcome": String(describing: game.outcome),
                        "validSave": game.isValidSave, "roundTripEqual": restored == game, "boardBefore": board(before.board), "boardAfter": board(game.board),
                        "phases": turn.resolutionPhases.map(phaseRecord), "causality": causality,
                        "grownArrivals": turn.arrivals.filter(\.grew).map { ["id": $0.gem.id, "cell": $0.cell.row * 7 + $0.cell.column] }])
    }
    let result: [String: Any] = ["source": "27252f66", "revision": game.challengeRevision, "actions": actions, "actionCount": actions.count,
          "showers": game.turns, "score": game.displayScore, "outcome": String(describing: game.outcome), "goalAActionIndices": aIndices, "goalBActionIndices": bIndices, "records": records]
    try write(result,name+".json")
    print("AUDIT \(name) score=\(game.displayScore) outcome=\(game.outcome) showers=\(game.turns) A=\(aIndices) B=\(bIndices)")
}
let plan = try JSONDecoder().decode([[[Int]]].self, from: Data(contentsOf: root.appendingPathComponent("golden-actions.json")))
var actions: [[Int]] = []
for (wave,moves) in plan.enumerated() { actions += moves; if wave < plan.count-1 { actions.append([]) } }
try audit(actions,name:"golden")
let initial=FallingSky.freshChallenge(.firstLight)
var opened=initial
let original=opened.nudge(from:cell(8),to:cell(9))!
let originalIDs=Set(original.resolutionPhases.flatMap { phase in phase.cleared.compactMap { phase.before[$0.row*7+$0.column]?.id } })
var options: [[String: Any]]=[]
for from in 0..<49 { for to in 0..<49 where abs(from/7-to/7)+abs(from%7-to%7)==1 {
    var game=initial
    if let turn=game.nudge(from:cell(from),to:cell(to)), turn.displayAward>0 {
        let ids=Set(turn.resolutionPhases.flatMap { phase in phase.cleared.compactMap { phase.before[$0.row*7+$0.column]?.id } })
        options.append(["action":[from,to],"points":turn.displayAward,"B":goalB(turn.resolutionPhases),"clearedOriginalOpeningIDs":ids.intersection(originalIDs).sorted(),"phases":turn.resolutionPhases.map(phaseRecord)])
    }
} }
try write(options,"opening-options.json")
print("OPENING options=\(options.count); originalIDs=\(originalIDs.sorted())")

// One disposable, fixture-specific search: change the first action to consume
// the opening's rose follow-up directly, then perturb the recorded plan once.
// No board edits, inverse-prefix undo, target change or supply substitution.
let began=Date()
let maximumAttempts=256, maximumSeconds=180.0
var summaries:[[String:Any]]=[]
var uniquePaths:[[[Int]]]=[]
var pathIndices:[String:Int]=[:]
var bestScore=0, found=false
for attempt in 0..<maximumAttempts {
    if Date().timeIntervalSince(began) >= maximumSeconds { break }
    var game=initial
    var chosen:[[Int]]=[]
    var sawA=false, sawB=false
    func commit(_ action:[Int]) -> Bool {
        if game.isOver { return false }
        let turn: FallingSkyTurn?
        if action.isEmpty { turn=game.letStarsFall() }
        else { turn=game.nudge(from:cell(action[0]),to:cell(action[1])) }
        guard let turn else { return false }
        chosen.append(action)
        sawA = sawA || turn.resolutionPhases.contains { !goalA($0).isEmpty }
        sawB = sawB || goalB(turn.resolutionPhases)
        return true
    }
    precondition(commit([1,2]))
    // All alternatives irreversibly consume the old second phase IDs in one
    // phase. Missing earliest A is not claimed: the opening has no grown stars.
    for (index,action) in actions.dropFirst().enumerated() where !game.isOver {
        if attempt>0 && index == (attempt-1)%actions.count {
            if attempt<=actions.count { continue }
            if attempt<=actions.count*2 { _=commit([]); if game.isOver { break } }
            else {
                // Adjacent legal action perturbation; deterministic flat order.
                let legal=(0..<49).flatMap { from in (0..<49).filter { to in game.canNudge(from:cell(from),to:cell(to)) }.map { [from,$0] } }
                if !legal.isEmpty { _=commit(legal[(attempt*17)%legal.count]) }
                if game.isOver { break }
            }
        }
        _=commit(action)
    }
    // If the changed route survives the old endpoint below target, use at most
    // 16 further unchanged showers and four highest-award legal swaps per wave.
    // Vary only deterministic tie ordering, never a committed forecast.
    for _ in 0..<16 where !game.isOver {
        for _ in 0..<4 where !game.isOver {
            var options:[(Int,[Int])]=[]
            for from in 0..<49 { for to in 0..<49 where abs(from/7-to/7)+abs(from%7-to%7)==1 {
                var copy=game
                if let turn=copy.nudge(from:cell(from),to:cell(to)),turn.displayAward>0 {
                    options.append((turn.displayAward + (!sawB && goalB(turn.resolutionPhases) ? 20000 : 0),[from,to]))
                }
            } }
            guard let maximum=options.map({$0.0}).max() else { break }
            let ties=options.filter{$0.0==maximum}
            _=commit(ties[attempt%ties.count].1)
        }
        if !game.isOver { _=commit([]) }
    }
    let pathKey=chosen.map { $0.isEmpty ? "fall" : "\($0[0])>\($0[1])" }.joined(separator:";")
    let pathIndex:Int
    if let existing=pathIndices[pathKey] { pathIndex=existing }
    else { pathIndex=uniquePaths.count;pathIndices[pathKey]=pathIndex;uniquePaths.append(chosen) }
    let summary:[String:Any] = ["attempt":attempt,"uniquePathIndex":pathIndex,"actions":chosen.count,"showers":game.turns,"score":game.displayScore,"outcome":String(describing:game.outcome),"A":sawA,"B":sawB]
    summaries.append(summary)
    if game.displayScore>bestScore { bestScore=game.displayScore;try write(chosen,"search-best-actions.json") }
    if game.outcome == .won {
        try audit(chosen,name:"alternative-win-\(attempt)")
        if sawA && sawB { found=true; break }
    }
}
try write(uniquePaths,"search-unique-paths.json")
try write(["source":"27252f66","maximumAttempts":maximumAttempts,"maximumSeconds":maximumSeconds,"extraShowersCap":16,"extraSwapsPerShowerCap":4,"completedAttempts":summaries.count,"uniqueChosenPaths":uniquePaths.count,"elapsedSeconds":Date().timeIntervalSince(began),"jointAlternativeFound":found,"bestScore":bestScore,"attempts":summaries],"search-summary.json")
print("SEARCH attempts=\(summaries.count) jointWin=\(found) best=\(bestScore) elapsed=\(Date().timeIntervalSince(began))")
