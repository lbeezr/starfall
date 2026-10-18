import Foundation

/// App-local records; never changes the deterministic game/save format.
struct SkyRankingRecords: Codable {
    static let key = "starfall.rankings.v1"
    static let leaderboardID = "com.starfall.prototype.standardSky.v1"
    struct Account: Codable {
        var pending: Int?
        var submitted: Int = 0
        var friends: SkyStandings?
        var global: SkyStandings?
    }
    var localBest = 0
    var accounts: [String: Account] = [:]

    mutating func record(score: Int, playerID: String?) {
        guard score > 0 else { return }
        localBest = max(localBest, score)
        guard let playerID, !playerID.isEmpty else { return }
        var account = accounts[playerID] ?? Account()
        if score > account.submitted { account.pending = max(account.pending ?? 0, score) }
        accounts[playerID] = account
    }

    mutating func acknowledge(score: Int, playerID: String) {
        guard var account = accounts[playerID] else { return }
        account.submitted = max(account.submitted, score)
        if let pending = account.pending, pending <= score { account.pending = nil }
        accounts[playerID] = account
    }

    var isValid: Bool {
        localBest >= 0 && accounts.allSatisfy { id, account in
            !id.isEmpty && account.submitted >= 0 && (account.pending.map { $0 > 0 } ?? true)
                && [account.friends, account.global].compactMap { $0 }.allSatisfy(\.isValid)
        }
    }
}

enum SkyRankingScope: String, CaseIterable, Identifiable, Codable {
    case friends = "Friends", global = "Global"
    var id: Self { self }
}
struct SkyRankingEntry: Codable, Equatable, Identifiable {
    let id: String
    let name: String
    let rank: Int
    let score: Int
}
struct SkyStandings: Codable, Equatable {
    let updated: Date
    let entries: [SkyRankingEntry]
    let local: SkyRankingEntry?
    var isValid: Bool {
        entries.count <= 26 && Set(entries.map(\.id)).count == entries.count
            && (entries + [local].compactMap { $0 }).allSatisfy { !$0.id.isEmpty && $0.rank > 0 && $0.score >= 0 }
    }
}
