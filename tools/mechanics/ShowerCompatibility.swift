import Foundation

/// Compile with either core. Capture with baseline, verify with the candidate.
@main struct ShowerCompatibility {
    struct Replay: Codable {
        let label: String
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
                    for legacy in [false, true] {
                        var game = StarfallExperiment(seed: seed, balance: .init(darkStars: frequency))
                        if legacy {
                            // Synthetic older-generation save: retain its committed preview,
                            // then let the pinned baseline own all subsequent RNG and rules.
                            var fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! [String: Any]
                            fields.removeValue(forKey: "cohesiveShowers")
                            game = try JSONDecoder().decode(StarfallExperiment.self,
                                from: JSONSerialization.data(withJSONObject: fields))
                        }
                        for _ in 0..<6 { advance(&game) }
                        let saved = game
                        var continuation: [StarfallExperiment] = []
                        for _ in 0..<12 { advance(&game); continuation.append(game) }
                        fixtures.append(.init(label: legacy ? "marker-absent" : "current", saved: saved,
                                              continuation: continuation))
                    }
                }
            }
            var challenge = StarfallExperiment(challenge: .firstLight)
            let initial = challenge
            var continuation: [StarfallExperiment] = []
            for _ in 0..<80 { advance(&challenge); continuation.append(challenge) }
            precondition(challenge.isOver, "Challenge fixture must reach its terminal outcome")
            fixtures.append(.init(label: "first-light", saved: initial, continuation: continuation))
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
            // A newly created challenge also stays identical, including its opening
            // and terminal no-ops. Ignore only the candidate's unused generation marker.
            let challengeFixture = fixtures.first { $0.label == "first-light" }!
            func withoutCandidateMarker(_ game: StarfallExperiment) throws -> StarfallExperiment {
                var fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! [String: Any]
                fields.removeValue(forKey: "pairedShowers")
                return try JSONDecoder().decode(StarfallExperiment.self,
                    from: JSONSerialization.data(withJSONObject: fields))
            }
            var challenge = StarfallExperiment(challenge: .firstLight)
            let normalizedOpening = try withoutCandidateMarker(challenge)
            precondition(normalizedOpening == challengeFixture.saved)
            for expected in challengeFixture.continuation {
                advance(&challenge)
                let normalized = try withoutCandidateMarker(challenge)
                precondition(normalized == expected,
                             "New First Light changed under candidate generation")
            }
            precondition(challenge.isOver)

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
            print("PASS: 160 current + 160 marker-absent baseline saves × 12 continuations; restored and new First Light × 80 steps through terminal; 200 candidate round-trip/opening/preview samples")
        }
    }
}
