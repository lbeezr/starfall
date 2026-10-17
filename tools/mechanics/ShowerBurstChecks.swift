import Foundation

/// Candidate-only schedule contract, independent of whether a shower has an
/// eligible pairing column. A pressure phase does not promise a forced landing.
@main struct ShowerBurstChecks {
    static func main() throws {
        precondition(!StarfallExperiment.isPressureShower(0))
        for number in 1...120 {
            let position = (number - 1) % 12 + 1
            precondition(StarfallExperiment.isPressureShower(number) == (10...12).contains(position))
        }
        var phaseTransitions = 0
        for seed in UInt64(0)..<200 {
            var game = StarfallExperiment(seed: seed)
            for _ in 0..<60 where !game.isOver {
                let forecast = game.incoming
                let phase = StarfallExperiment.isPressureShower(game.turns + 1)
                if let cell = game.legalGroups.first?.first {
                    game.clear(cell)
                    precondition(game.incoming == forecast)
                    precondition(StarfallExperiment.isPressureShower(game.turns + 1) == phase)
                }
                let saved = try JSONEncoder().encode(game)
                var restored = try JSONDecoder().decode(StarfallExperiment.self, from: saved)
                game.letStarsFall()
                restored.letStarsFall()
                precondition(game == restored && game.isValidSave)
                if phase != StarfallExperiment.isPressureShower(game.turns + 1) {
                    phaseTransitions += 1
                }
            }
        }
        precondition(phaseTransitions > 0)
        print("PASS: 120 schedule positions; 200 seeded forecast/clear/save continuations; \(phaseTransitions) phase transitions")
    }
}
