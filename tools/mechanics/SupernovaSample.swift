import Foundation

/// Offline candidate only. Compile through run-supernova.py, never in the app.
@main struct SupernovaSample {
    struct Result: Codable {
        struct Example: Codable {
            let state: FallingSky
            let cell: Cell
            let tapValue: Int
            let chargeValue: Int
            let tapOverflow: Bool
            let chargeOverflow: Bool
        }
        let policy: String
        var rounds = 0, showers = 0, score = 0, ended = 0
        var clears = 0, chargedClears = 0, chargeChoices = 0
        var differingFollowups = 0, chargeBetterFollowups = 0, tapBetterFollowups = 0
        var recoloredSurvivors = 0
        var tapBetterValue = 0, chargeBetterValue = 0
        var tapSavesNextShower = 0, chargeSavesNextShower = 0
        var tapExamples: [Example] = []
    }

    static func check(_ condition: @autoclosure () -> Bool, _ message: String) {
        precondition(condition(), message)
    }

    static func clearableValue(_ game: FallingSky) -> Int {
        game.legalGroups.reduce(0) { $0 + game.value(of: Set($1)) }
    }

    static func regressionChecks() throws {
        var board = [StarfallGem?](repeating: nil, count: 49)
        // Five rose stars across the bottom. Aqua above the middle and a grown
        // amber above its neighbor are perimeter survivors; a diagonal mint is not.
        for column in 0..<5 { board[column] = .init(id: column, kind: .rose) }
        board[7 + 2] = .init(id: 5, kind: .aqua)
        board[7 + 3] = .init(id: 6, kind: .amber, grown: true)
        board[5] = .init(id: 7, kind: nil)
        board[7 + 5] = .init(id: 8, kind: .mint)
        var game = FallingSky(board: board, incoming: [.init(id: 10, kind: .violet, column: 6)])
        let forecast = game.incoming
        let turn = game.clear(Cell(0, 0), charged: true)!
        check(turn.collected == 5 && game.score == 5, "Charge awards only cleared value")
        check(game.darkStarsCleared == 1, "Ordinary adjacent-Dusk removal still applies")
        #if ROTATE
        check(game.gem(at: Cell(0, 2)) == .init(id: 5, kind: .amber), "Perimeter rotates identity")
        check(game.gem(at: Cell(0, 3)) == .init(id: 6, kind: .violet, grown: true), "Growth and ID survive rotation")
        check(game.legalGroups.isEmpty, "Rotation does not invent a shared-color match")
        #else
        check(game.gem(at: Cell(0, 2)) == .init(id: 5, kind: .rose), "Perimeter changes identity")
        check(game.gem(at: Cell(0, 3)) == .init(id: 6, kind: .rose, grown: true), "Growth and ID survive recoloring")
        check(game.legalGroups.count == 1, "Created match waits for deliberate input")
        #endif
        check(game.gem(at: Cell(0, 5)) == .init(id: 8, kind: .mint), "Diagonal is untouched before settling")
        check(game.incoming == forecast && game.turns == 0, "Clear preserves announced forecast and clock")

        var small = FallingSky(seed: 42)
        small.letStarsFall()
        let before = small
        check(small.clear(small.legalGroups[0][0], charged: true) == nil, "Three-point opening cannot charge")
        check(small == before, "Rejected charge is mutation-free")
        check(small.clear(small.legalGroups[0][0]) != nil, "Ordinary tap remains available")
        check(small.clear(Cell(-1, 0), charged: true) == nil, "Out-of-bounds charge is safe")
    }

    static func main() throws {
        try regressionChecks()
        var results: [Result] = []
        for policy in ["tap", "charge", "followup-choice"] {
            var result = Result(policy: policy)
            for seed in UInt64(0)..<200 {
                var game = FallingSky(seed: seed)
                for _ in 0..<60 where !game.isOver {
                    game.letStarsFall()
                    // Clear all available groups. Each clear removes at least two
                    // occupied cells, so 25 is a conservative bound on a 49-cell board.
                    for _ in 0..<25 where !game.isOver {
                        guard let group = game.legalGroups.first else { break }
                        var tap = game
                        tap.clear(group[0])
                        var charge = game
                        let eligible = charge.clear(group[0], charged: true) != nil
                        if eligible {
                            result.chargeChoices += 1
                            if tap.board != charge.board { result.differingFollowups += 1 }
                            if charge.legalGroups.count > tap.legalGroups.count { result.chargeBetterFollowups += 1 }
                            if charge.legalGroups.count < tap.legalGroups.count { result.tapBetterFollowups += 1 }
                            let tapValue = clearableValue(tap), chargeValue = clearableValue(charge)
                            if tapValue > chargeValue { result.tapBetterValue += 1 }
                            if chargeValue > tapValue { result.chargeBetterValue += 1 }
                            var nextTap = tap, nextCharge = charge
                            nextTap.letStarsFall(); nextCharge.letStarsFall()
                            check(nextTap.isValidSave && nextCharge.isValidSave, "Both counterfactual showers preserve invariants")
                            if !nextTap.isOver && nextCharge.isOver { result.tapSavesNextShower += 1 }
                            if nextTap.isOver && !nextCharge.isOver { result.chargeSavesNextShower += 1 }
                            if policy == "tap", result.tapExamples.count < 3,
                               tapValue > chargeValue || (!nextTap.isOver && nextCharge.isOver) {
                                result.tapExamples.append(.init(state: game, cell: group[0],
                                    tapValue: tapValue, chargeValue: chargeValue,
                                    tapOverflow: nextTap.isOver, chargeOverflow: nextCharge.isOver))
                            }
                        }
                        let useCharge = eligible && (policy == "charge" ||
                            (policy == "followup-choice" && charge.legalGroups.count > tap.legalGroups.count))
                        if useCharge {
                            let priorKinds = Dictionary(uniqueKeysWithValues: game.board.compactMap { $0 }.map { ($0.id, $0.kind) })
                            result.recoloredSurvivors += charge.board.compactMap { $0 }.filter {
                                priorKinds[$0.id] != $0.kind
                            }.count
                            result.chargedClears += 1
                        }
                        game = useCharge ? charge : tap
                        result.clears += 1
                        check(game.isValidSave, "Committed candidate obeys save invariants")
                        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                        check(restored == game, "Candidate round-trips exactly")
                        var continued = game, replay = restored
                        continued.letStarsFall(); replay.letStarsFall()
                        check(continued == replay, "Restored RNG and forecast continuation agree")
                    }
                    check(game.isValidSave, "Showers obey save invariants, including overflow")
                }
                result.rounds += 1; result.showers += game.turns; result.score += game.score
                if game.isOver { result.ended += 1 }
            }
            results.append(result)
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(data: try encoder.encode(results), encoding: .utf8)!)
    }
}
