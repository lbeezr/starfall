import Foundation

/// Compile with either core. Capture with baseline, verify with the candidate.
@main struct ShowerCompatibility {
    struct Replay: Codable {
        let saved: StarfallExperiment
        let continuation: [StarfallExperiment]
    }

    static func advance(_ game: inout StarfallExperiment) {
        game.letStarsFall()
        if let group = game.legalGroups.first { game.clear(group[0]) }
        precondition(game.isValidSave)
    }

    static func main() throws {
        let path = URL(fileURLWithPath: CommandLine.arguments[1])
        if CommandLine.arguments.contains("--capture") {
            var fixtures: [Replay] = []
            for frequency in StarfallBalance.DarkStarFrequency.allCases {
                for seed in UInt64(0)..<40 {
                    var game = StarfallExperiment(seed: seed, balance: .init(darkStars: frequency))
                    for _ in 0..<6 { advance(&game) }
                    let saved = game
                    var continuation: [StarfallExperiment] = []
                    for _ in 0..<12 { advance(&game); continuation.append(game) }
                    fixtures.append(.init(saved: saved, continuation: continuation))
                }
            }
            var challenge = StarfallExperiment(challenge: .firstLight)
            let initial = challenge
            var continuation: [StarfallExperiment] = []
            for _ in 0..<12 { advance(&challenge); continuation.append(challenge) }
            fixtures.append(.init(saved: initial, continuation: continuation))
            try JSONEncoder().encode(fixtures).write(to: path)
        } else {
            let fixtures = try JSONDecoder().decode([Replay].self, from: Data(contentsOf: path))
            for fixture in fixtures {
                var game = fixture.saved
                precondition(game.isValidSave)
                for expected in fixture.continuation {
                    advance(&game)
                    precondition(game == expected, "Existing save changed its future sequence")
                }
            }
            // New candidate saves must retain their generation choice after restore.
            for seed in UInt64(0)..<200 {
                var game = StarfallExperiment(seed: seed)
                game.letStarsFall()
                precondition(!game.legalGroups.isEmpty, "Opening stays playable")
                if seed == 0 {
                    var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! [String: Any]
                    object["pairedShowers"] = true
                    object.removeValue(forKey: "cohesiveShowers")
                    let invalid = try JSONDecoder().decode(StarfallExperiment.self,
                        from: JSONSerialization.data(withJSONObject: object))
                    precondition(!invalid.isValidSave, "Contradictory generation markers must be rejected")
                }
                for _ in 0..<30 {
                    let data = try JSONEncoder().encode(game)
                    var restored = try JSONDecoder().decode(StarfallExperiment.self, from: data)
                    precondition(restored == game && restored.isValidSave)
                    let forecast = game.incoming
                    if let cell = game.legalGroups.first?.first {
                        game.clear(cell); restored.clear(cell)
                        precondition(game.incoming == forecast, "Clear rewrote the announced shower")
                    }
                    advance(&game); advance(&restored)
                    precondition(game == restored, "Candidate continuation changed after restore")
                }
            }
            print("PASS: \(fixtures.count) baseline saves × 12 continuations; 200 candidate round-trip/opening/preview samples")
        }
    }
}
