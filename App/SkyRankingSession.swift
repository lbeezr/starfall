import Foundation
import CryptoKit
import StarfallCore

struct SkyRankedResult: Codable {
    let score: Int
    let playerID: String?
}

/// Sidecar bound to the exact saved core bytes. Old/mismatched saves stay playable,
/// but cannot acquire ranking eligibility merely by decoding successfully.
struct SkyRankingSession: Codable {
    static let key = "starfall.rankingSession.v1"
    var digest = ""
    var eligible: Bool
    var completed = false
    var result: SkyRankedResult?

    static func fingerprint(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    static func restore(defaults: UserDefaults, gameData: Data) -> Self {
        guard let data = defaults.data(forKey: key),
              let session = try? JSONDecoder().decode(Self.self, from: data),
              session.digest == fingerprint(gameData),
              let game = try? JSONDecoder().decode(FallingSky.self, from: gameData), game.isValidSave,
              session.completed == game.isOver,
              !session.eligible || (game.challenge == nil && game.balance == StarfallBalance()),
              session.result.map({ session.completed && session.eligible && $0.score == game.score && $0.score > 0 }) ?? true
        else { return Self(eligible: false) }
        return session
    }
}
