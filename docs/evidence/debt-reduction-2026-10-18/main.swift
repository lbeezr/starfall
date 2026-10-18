import Foundation
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
var samples = (0...4).flatMap { generation in
    [UInt64(5), 28, 180].map { FallingSky(seed: $0, generation: SkyGeneration(rawValue: generation)!) }
}
samples += GravityFixture.allCases.map { $0.game() }
samples += [DuskFixture.unfed.game(), DuskFixture.imminent.game(rule: .patientFeeding), CriticalMassFixture.game()]
samples += [FallingSky.freshSurvival(seed: 5), FallingSky.freshSurvival(seed: 28), FallingSky(challenge: .firstLight)]
func emit(_ game: FallingSky) throws {
    let data = try encoder.encode(game)
    let restored = try JSONDecoder().decode(FallingSky.self, from: data)
    precondition(restored == game)
    print(data.base64EncodedString())
}
for initial in samples {
    for migrated in [false, true] {
        var game = migrated ? initial.removingGravity().adoptingFeedingDusk() : initial
        for _ in 0..<24 {
            try emit(game)
            if game.isOver { break }
            if let cell = game.legalGroups.first?.first { game.clear(cell) }
            game.letStarsFall()
        }
        try emit(game.replay())
    }
}
