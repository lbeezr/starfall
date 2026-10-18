import Foundation
import UIKit

extension SkyLeaderboard {
    @MainActor static func forApp() -> SkyLeaderboard {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--starfalls-reset"),
           let arg = args.first(where: { $0.hasPrefix("--rankings-review=") }) {
            return SkyLeaderboardFixture.make(state: String(arg.dropFirst("--rankings-review=".count)))
        }
        #endif
        return SkyLeaderboard()
    }
}

#if DEBUG
/// Native QA only: isolated records, fake transport and no connection monitor.
@MainActor private enum SkyLeaderboardFixture {
    static func make(state: String) -> SkyLeaderboard {
        let defaults = UserDefaults(suiteName: "Starfall.RankingsReview")!
        defaults.removePersistentDomain(forName: "Starfall.RankingsReview")
        let signedIn = state != "signedout" && state != "signedout-offline"
        let client = ReviewClient(signedIn: signedIn)
        if signedIn, state != "uncached" {
            var records = SkyRankingRecords()
            records.record(score: 46, playerID: "review.you")
            records.acknowledge(score: 42, playerID: "review.you")
            records.accounts["review.you"]?.friends = client.snapshot(.friends)
            records.accounts["review.you"]?.global = client.snapshot(.global)
            defaults.set(try? JSONEncoder().encode(records), forKey: SkyRankingRecords.key)
        }
        let result = SkyLeaderboard(defaults: defaults, client: client, monitorsConnection: false)
        result.connectionChanged(state == "online" || state == "signedout")
        return result
    }
    private final class ReviewClient: SkyRankingClient {
        var player: SkyRankingPlayer?
        var authenticationChanged: (() -> Void)?
        init(signedIn: Bool) { player = signedIn ? SkyRankingPlayer(id: "review.you", name: "Stargazer") : nil }
        func authenticate(present: @escaping (UIViewController) -> Void) { authenticationChanged?() }
        func submit(score: Int, playerID: String) async throws { throw URLError(.notConnectedToInternet) }
        func standings(scope: SkyRankingScope) async throws -> SkyStandings { snapshot(scope) }
        func snapshot(_ scope: SkyRankingScope) -> SkyStandings {
            let local = SkyRankingEntry(id: "review.you", name: "Stargazer", rank: scope == .friends ? 1 : 129, score: 42)
            let entries = scope == .friends ? [local, SkyRankingEntry(id: "review.iris", name: "Iris", rank: 2, score: 39)]
                : [SkyRankingEntry(id: "review.moon", name: "Moonbeam", rank: 1, score: 184)]
            return SkyStandings(updated: Date(timeIntervalSince1970: 1792243560), entries: entries, local: local)
        }
    }
}
#endif

// Keep new native review rounds out of the player's normal saved sky.
extension FallingSkyStore {
    @MainActor static func forApp() -> FallingSkyStore {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--sky-flow-review") {
            let defaults = UserDefaults(suiteName: "Starfall.SkyFlowReview")!
            return FallingSkyStore(defaults: defaults, arguments: args)
        }
        if args.contains("--starfalls-reset"),
           let state = args.first(where: { $0.hasPrefix("--rankings-review=") }) {
            let defaults = UserDefaults(suiteName: "Starfall.RankingsGameReview." + String(state.dropFirst("--rankings-review=".count)))!
            return FallingSkyStore(defaults: defaults, arguments: args)
        }
        #endif
        return FallingSkyStore()
    }
}
