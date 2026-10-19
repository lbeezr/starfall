import Foundation
import StarfallCore

#if DEBUG
// Explicit reset-only Debug review sample; absent from Release initialization.
@MainActor enum ObservatoryReviewFixture {
    static func game(dense: Bool, score: Int = 0) -> FallingSky {
        let base = FallingSky(seed: 5)
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
                if row == 1 && column == 3 { kind = nil }
                let grown = row == 1 && column == 1
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
