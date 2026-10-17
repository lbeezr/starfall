import Foundation

/// Find a visible column-pressure choice, not an arbitrary score difference.
@main struct PressureDecisionFixture {
    struct Fixture: Codable {
        let state: StarfallExperiment
        let safeCell: Cell
        let unsafeCell: Cell
        let safePressure: Int
        let unsafePressure: Int
        let tallestHeight: Int
        let safeCollected: Int
        let unsafeCollected: Int
        let seed5ChoiceShowersBy20: Int
        let seed5ScoreAfter20: Int
    }
    static func main() throws {
        var opening = StarfallExperiment(seed: 5)
        var openingChoices = 0
        for _ in 0..<20 {
            opening.letStarsFall()
            if opening.legalGroups.count > 1 { openingChoices += 1 }
            if let group = opening.legalGroups.first { opening.clear(group[0]) }
            precondition(opening.isValidSave && !opening.isOver)
        }
        for seed in UInt64(0)..<200 {
            var game = StarfallExperiment(seed: seed)
            for _ in 0..<60 where !game.isOver {
                game.letStarsFall()
                guard !game.isOver else { break }
                let groups = game.legalGroups
                let tallest = (0..<7).map { BalanceSample.height(game, $0) }.max()!
                let options = groups.map { group -> (Cell, Int, Bool, Bool, Int) in
                    var trial = game
                    let collected = trial.clear(group[0])!.collected
                    let reducedPressure = BalanceSample.pressure(trial)
                    let touchesTallest = group.contains { BalanceSample.height(game, $0.column) == tallest }
                    trial.letStarsFall()
                    precondition(trial.isValidSave)
                    return (group[0], reducedPressure, trial.isOver, touchesTallest, collected)
                }
                for safe in options where !safe.2 && safe.3 {
                    for unsafe in options where unsafe.2 && !unsafe.3 && safe.1 < unsafe.1 {
                        precondition(game.isValidSave)
                        let fixture = Fixture(state: game, safeCell: safe.0, unsafeCell: unsafe.0,
                            safePressure: safe.1, unsafePressure: unsafe.1, tallestHeight: tallest,
                            safeCollected: safe.4, unsafeCollected: unsafe.4,
                            seed5ChoiceShowersBy20: openingChoices, seed5ScoreAfter20: opening.score)
                        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
                        print(String(data: try encoder.encode(fixture), encoding: .utf8)!)
                        return
                    }
                }
                if let group = groups.first { game.clear(group[0]) }
            }
        }
        fatalError("No visible tall-column survival choice in the bounded sample")
    }
}
