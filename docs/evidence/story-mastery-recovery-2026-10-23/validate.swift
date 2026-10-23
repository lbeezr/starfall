import Foundation

enum WitnessError: Error { case invalid(String) }

@main struct ValidateRecovery {
    static func require(_ value: @autoclosure () -> Bool, _ message: String) throws {
        if !value() { throw WitnessError.invalid(message) }
    }

    static func main() throws {
        let arguments = CommandLine.arguments
        try require(arguments.count >= 3, "usage: validator actions.json output.json [--require-win]")
        let actions = try JSONDecoder().decode([[Int]].self, from: Data(contentsOf: URL(fileURLWithPath: arguments[1])))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        func object<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(with: encoder.encode(value))
        }
        func cell(_ index: Int) -> Cell { Cell(index / 7, index % 7) }
        let declinedIDs: Set<Int> = [2, 8, 15, 22]
        var game = FallingSky.freshChallenge(.firstLight)
        let opening = game
        try require(game.challengeRevision == 4 && game.automaticLineLength == 4, "current Lantern rules")
        try require(actions.first == [1, 2], "literal irreversible declined opening")
        var grownActions: [Int] = [], laterChains: [Int] = [], swaps = 0
        var records: [[String: Any]] = []
        for (index, action) in actions.enumerated() {
            try require(game.outcome == .playing, "action after terminal outcome at \(index)")
            let before = game
            var copy = try JSONDecoder().decode(FallingSky.self, from: encoder.encode(before))
            let turn: FallingSkyTurn
            let copied: FallingSkyTurn
            if action.isEmpty {
                guard let first = game.letStarsFall(), let second = copy.letStarsFall() else {
                    throw WitnessError.invalid("rejected shower at \(index)")
                }
                turn = first; copied = second
                try require(game.turns == before.turns + 1, "shower count")
                try require(turn.forecast == before.incoming, "exact committed forecast")
            } else {
                try require(action.count == 2 && action.allSatisfy { (0..<49).contains($0) }, "cell bounds")
                let from = cell(action[0]), to = cell(action[1])
                try require(abs(from.row - to.row) + abs(from.column - to.column) == 1, "adjacency")
                try require(before.gem(at: from) != nil && before.canNudge(from: from, to: to), "occupied legal source")
                guard let first = game.nudge(from: from, to: to), let second = copy.nudge(from: from, to: to) else {
                    throw WitnessError.invalid("rejected exchange at \(index)")
                }
                turn = first; copied = second; swaps += 1
                try require(game.turns == before.turns && game.incoming == before.incoming, "swap preserves clock and supply")
            }
            try require(game == copy && turn.resolutionPhases == copied.resolutionPhases, "decoded-prestate determinism")
            try require(turn.arrivals.map(\.cell) == copied.arrivals.map(\.cell), "arrival cells")
            try require(turn.arrivals.map(\.star) == copied.arrivals.map(\.star), "arrival forecast stars")
            try require(turn.arrivals.map(\.gem) == copied.arrivals.map(\.gem), "arrival gems")
            try require(turn.arrivals.map(\.grew) == copied.arrivals.map(\.grew), "arrival growth")
            try require(game.isValidSave, "valid committed save")
            let restored = try JSONDecoder().decode(FallingSky.self, from: encoder.encode(game))
            try require(restored == game && restored.isValidSave, "committed Codable equality")
            try require(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value } == game.starsLanded, "physical conservation")
            try require(game.displayScore == before.displayScore + turn.displayAward, "exact award increment")
            try require(declinedIDs.isDisjoint(with: game.board.compactMap { $0?.id }), "declined ingredients never return")
            if index == 0 {
                try require(turn.resolutionPhases.count == 1 && turn.displayAward == 5_000, "one-phase declined opening")
                let phase = turn.resolutionPhases[0]
                try require(Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id }) == declinedIDs, "consumed opening identities")
            }
            var grownIDs: [Int] = []
            for phase in turn.resolutionPhases {
                try require(phase.kind == .recipe && !phase.cleared.isEmpty, "automatic nonempty phase")
                try require(StarRecipe.find(in: phase.before, lineLength: game.automaticLineLength) == phase.recipes, "all ready recipes belong to this phase")
                grownIDs += phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }.filter {
                    $0.grown && $0.kind != nil && !$0.isLight && $0.gravityKind == nil && $0.value == 2
                }.map(\.id)
            }
            if !grownIDs.isEmpty { grownActions.append(index) }
            var causal = false
            for (earlier, later) in zip(turn.resolutionPhases, turn.resolutionPhases.dropFirst()) {
                let firstIDs = Set(earlier.cleared.compactMap { earlier.before[$0.row * 7 + $0.column]?.id })
                let nextIDs = Set(later.cleared.compactMap { later.before[$0.row * 7 + $0.column]?.id })
                try require(later.before == earlier.settled && later.comboDepth == earlier.comboDepth + 1, "linked consecutive phases")
                try require(firstIDs.isDisjoint(with: nextIDs) && nextIDs.isSubset(of: Set(earlier.before.compactMap { $0?.id })), "distinct surviving ingredients")
                try require(nextIDs.contains { id in
                    earlier.before.firstIndex { $0?.id == id } != later.before.firstIndex { $0?.id == id }
                }, "settling moves later ingredients")
                try require(later.recipes.allSatisfy { recipe in !earlier.recipes.contains { $0.starIDs == recipe.starIDs } }, "later recipe was absent")
                causal = true
            }
            if causal && before.turns >= 1 { laterChains.append(index) }
            if index == 0 || !grownIDs.isEmpty || causal || game.isOver {
                var phases: [[String: Any]] = []
                for phase in turn.resolutionPhases {
                    phases.append(["depth": phase.comboDepth, "before": try object(phase.before), "settled": try object(phase.settled),
                                   "clearedCells": phase.cleared.map { $0.row * 7 + $0.column }.sorted(),
                                   "clearedIDs": phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id }.sorted(),
                                   "points": phase.award.displayPoints])
                }
                records.append(["actionIndex": index, "action": action, "showersBefore": before.turns,
                                "scoreBefore": before.displayScore, "scoreAfter": game.displayScore,
                                "grownClearedIDs": grownIDs.sorted(), "laterB": causal && before.turns >= 1, "phases": phases])
            }
        }
        if arguments.contains("--require-win") {
            try require(game.outcome == .won && game.displayScore >= 150_000, "unchanged target win")
            try require(!grownActions.isEmpty && !laterChains.isEmpty, "both goals in this completed run")
        }
        if game.isOver {
            let terminal = game
            try require(game.nudge(from: Cell(0, 0), to: Cell(0, 1)) == nil && game.letStarsFall() == nil, "post-terminal input rejected")
            try require(game == terminal, "post-terminal state preserved")
        }
        try require(game.replay() == opening, "same-round replay retains original opening")
        let report: [String: Any] = ["actionCount": actions.count, "swaps": swaps, "showers": game.turns,
                                   "score": game.displayScore, "outcome": String(describing: game.outcome),
                                   "grownActionIndices": grownActions, "laterBActionIndices": laterChains,
                                   "validSave": game.isValidSave, "perActionDeterminismAndRoundTrips": true,
                                   "actions": actions, "selectedRecords": records]
        try JSONSerialization.data(withJSONObject: report, options: [.sortedKeys]).write(to: URL(fileURLWithPath: arguments[2]))
        print("VALIDATED actions=\(actions.count) swaps=\(swaps) showers=\(game.turns) score=\(game.displayScore) outcome=\(game.outcome) A=\(grownActions) delayedB=\(laterChains)")
    }
}
