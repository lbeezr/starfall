import Foundation

/// Compile alongside Sources/StarfallCore/*.swift; no app, SDK, or dependencies.
@main struct BalanceSample {
    struct Result: Codable {
        let policy: String
        var rounds = 0, score = 0, clears = 0, showers = 0, ended = 0
        var choiceStates = 0, decisionStates = 0, consequentialChoices = 0
        var playableShowers = 0, dryShowers = 0, longestDryRun = 0
        var groupCountTotal = 0, maximumGroups = 0, highColumnChoices = 0
        var exampleSeeds: [UInt64] = []
    }
    struct Report: Codable {
        let seedCount: Int
        let showerLimit: Int
        let method: String
        let results: [Result]
    }
    static func height(_ game: FallingSky, _ column: Int) -> Int {
        (0..<7).filter { game.gem(at: Cell($0, column)) != nil }.count
    }
    static func pressure(_ game: FallingSky) -> Int {
        (0..<7).reduce(0) { $0 + height(game, $1) * height(game, $1) }
    }
    static func main() throws {
        let seeds = 200, limit = 60
        var results: [Result] = []
        for policy in ["idle", "all", "first", "largest", "pressure", "preview-aware"] {
            var result = Result(policy: policy)
            for seed in UInt64(0)..<UInt64(seeds) {
                var game = FallingSky(seed: seed)
                var dryRun = 0
                for _ in 0..<limit where !game.isOver {
                    game.letStarsFall()
                    guard !game.isOver else { continue }
                    result.playableShowers += 1
                    let available = game.legalGroups.count
                    result.groupCountTotal += available
                    result.maximumGroups = max(result.maximumGroups, available)
                    if available == 0 {
                        result.dryShowers += 1; dryRun += 1
                        result.longestDryRun = max(result.longestDryRun, dryRun)
                    } else { dryRun = 0 }
                    guard policy != "idle" else { continue }
                    for _ in 0..<(policy == "all" ? 25 : 1) {
                        let groups = game.legalGroups
                        guard !groups.isEmpty else { break }
                        result.decisionStates += 1
                        if groups.count > 1 { result.choiceStates += 1 }
                        let tallest = (0..<7).map { height(game, $0) }.max()!
                        // A useful high-column choice must differ between legal moves;
                        // merely touching the tallest column is not a decision.
                        let touchesTallest = groups.map { group in
                            group.contains { height(game, $0.column) == tallest }
                        }
                        if touchesTallest.contains(true) && touchesTallest.contains(false) {
                            result.highColumnChoices += 1
                        }
                        let candidates = groups.map { group -> (cell: Cell, value: Int, pressure: Int, nextOver: Bool) in
                            var trial = game
                            let value = trial.clear(group[0])!.collected
                            let pressure = Self.pressure(trial)
                            trial.letStarsFall()
                            return (group[0], value, pressure, trial.isOver)
                        }
                        if candidates.contains(where: { $0.nextOver }) && candidates.contains(where: { !$0.nextOver }) {
                            result.consequentialChoices += 1
                            if result.exampleSeeds.count < 5 && !result.exampleSeeds.contains(seed) { result.exampleSeeds.append(seed) }
                        }
                        // Canonical group order breaks ties, keeping every policy reproducible.
                        var chosen = candidates[0]
                        for candidate in candidates.dropFirst() {
                            let better: Bool
                            switch policy {
                            case "largest": better = candidate.value > chosen.value
                            case "pressure": better = candidate.pressure < chosen.pressure
                            case "preview-aware":
                                better = candidate.nextOver != chosen.nextOver ? !candidate.nextOver : candidate.pressure < chosen.pressure
                            default: better = false
                            }
                            if better { chosen = candidate }
                        }
                        game.clear(chosen.cell); result.clears += 1
                    }
                }
                result.rounds += 1; result.score += game.score; result.showers += game.turns
                if game.isOver { result.ended += 1 }
            }
            results.append(result)
        }
        let report = Report(seedCount: seeds, showerLimit: limit,
            method: "At most one clear after each shower except all, which clears every available group (bounded to 25 iterations on a 49-cell board). Fixed seeds 0...199. Candidate comparison uses the already announced preview; future previews can depend on the board. Capped survivors are censored, not completed rounds. No human reaction time or animation/input gate simulation. Preview-aware policy sees landing columns, which the player cannot see; it is an upper-bound diagnostic, not a player model.", results: results)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        print(String(data: try encoder.encode(report), encoding: .utf8)!)
    }
}
