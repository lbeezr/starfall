import Foundation
import StarfallCore

#if DEBUG
// Explicit reset-only Debug review sample; absent from Release initialization.
@MainActor enum ObservatoryReviewFixture {
    /// Retained production rules for native Continue/Replay checks. No board or
    /// archive injection: ordinary activation and player actions own persistence.
    static func fullBoardV5(arguments: [String]) -> FallingSky? {
        let marker = "--full-board-v5-review"
        guard arguments.contains("--starfalls-reset"), arguments.contains("--dialogue-review"),
              arguments.filter({ $0 == marker }).count == 1 else { return nil }
        let conflictingMarkers = ["--observatory-review", "--technique-review", "--sky-flow-review",
                                  WorldMapReviewFixture.marker, "--world-legacy-review",
                                  "--world-silver-complete-review", "--world-frostfruit-complete-review",
                                  "--critical-mass-review"]
        let conflictingPrefixes = StarfallChallenge.allCases.map(\.restorationReviewArgumentPrefix)
            + ["--constellation-fixture=", "--technique-example=", "--gravity-fixture=", "--dusk-fixture="]
        guard !arguments.contains(where: { argument in
            conflictingMarkers.contains(argument) || conflictingPrefixes.contains(where: argument.hasPrefix)
        }) else { return nil }
        return FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    static func game(dense: Bool, score: Int = 0, challenge: StarfallChallenge? = nil) -> FallingSky {
        let base = challenge.map(FallingSky.init(challenge:)) ?? FallingSky(seed: 5)
        var object = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as! [String: Any]
        var board: [Any] = Array(repeating: NSNull(), count: 49)
        let height = dense ? 7 : 3
        var id = 0, value = 0
        for row in 0..<height {
            for column in 0..<7 {
                var kind: Jewel? = Jewel.allCases[(row+column)%5]
                // Independent three-star groups at front/back corners for projected coordinate taps.
                if row == 0 && column < 3 { kind = .amber }
                if row == height-1 && column >= 4 { kind = .aqua }
                if challenge == nil && row == 1 && column == 3 { kind = nil }
                if challenge != nil && row == 1 && column == 1 { kind = .mint }
                // Restoration challenges have no Dusk. The bottom-left trio awards four light,
                // allowing the 14-point review to finish through an ordinary tap.
                let grown = row == (challenge == nil ? 1 : 0) && column == 1
                var gem: [String: Any] = ["id": id, "grown": grown]
                if let kind { gem["kind"] = kind.rawValue }
                board[row*7+column] = gem
                value += kind == nil ? 1 : (grown ? 2 : 1)
                id += 1
            }
        }
        object["board"] = board
        object["starsLanded"] = value + score
        object["turns"] = (value+score+4)/5
        object["score"] = score
        object["darkStarsCleared"] = 0
        let game = try! JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        precondition(game.isValidSave)
        return game
    }
}

#endif
