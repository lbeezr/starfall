import GameKit
import UIKit

struct SkyRankingPlayer: Equatable {
    let id: String
    let name: String
}

@MainActor protocol SkyRankingClient: AnyObject {
    var player: SkyRankingPlayer? { get }
    var authenticationChanged: (() -> Void)? { get set }
    func authenticate(present: @escaping (UIViewController) -> Void)
    func submit(score: Int, playerID: String) async throws
    func standings(scope: SkyRankingScope) async throws -> SkyStandings
}

/// GameKit is the only online dependency. No app account or custom backend.
@MainActor final class GameCenterClient: SkyRankingClient {
    var authenticationChanged: (() -> Void)?
    private var observer: NSObjectProtocol?
    private var startedAuthentication = false

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .GKPlayerAuthenticationDidChangeNotificationName, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.authenticationChanged?() }
        }
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

    var player: SkyRankingPlayer? {
        let local = GKLocalPlayer.local
        guard local.isAuthenticated else { return nil }
        return SkyRankingPlayer(id: local.gamePlayerID, name: local.displayName)
    }

    func authenticate(present: @escaping (UIViewController) -> Void) {
        guard !startedAuthentication else { authenticationChanged?(); return }
        startedAuthentication = true
        GKLocalPlayer.local.authenticateHandler = { [weak self] controller, _ in
            Task { @MainActor [weak self] in
                if let controller { present(controller) }
                self?.authenticationChanged?()
            }
        }
    }

    func submit(score: Int, playerID: String) async throws {
        guard player?.id == playerID else { throw CancellationError() }
        try await GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                           leaderboardIDs: [SkyRankingRecords.leaderboardID])
    }

    func standings(scope: SkyRankingScope) async throws -> SkyStandings {
        let boards = try await GKLeaderboard.loadLeaderboards(IDs: [SkyRankingRecords.leaderboardID])
        guard let board = boards.first else { throw RankingError.notConfigured }
        let (local, entries, _) = try await board.loadEntries(
            for: scope == .friends ? .friendsOnly : .global, timeScope: .allTime,
            range: NSRange(location: 1, length: 25))
        func snapshot(_ entry: GKLeaderboard.Entry) -> SkyRankingEntry {
            SkyRankingEntry(id: entry.player.gamePlayerID, name: entry.player.displayName,
                            rank: entry.rank, score: entry.score)
        }
        return SkyStandings(updated: Date(), entries: entries.map(snapshot), local: local.map(snapshot))
    }
    enum RankingError: Error { case notConfigured }
}
