import Foundation
import Observation
import Network
import UIKit

/// Network/authentication work is independent of the game's clock, presenter and save.
@MainActor @Observable final class SkyLeaderboard {
    private(set) var player: SkyRankingPlayer?
    private(set) var online = false
    private(set) var loading = false
    private(set) var message: String?
    private(set) var records: SkyRankingRecords
    var scope: SkyRankingScope = .friends
    var authenticationSheet: AuthenticationSheet?
    struct AuthenticationSheet: Identifiable {
        let id = UUID()
        let controller: UIViewController
    }
    @ObservationIgnored private let client: any SkyRankingClient
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let monitorsConnection: Bool
    @ObservationIgnored private let requestTimeout: Duration
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var timeout: Task<Void, Never>?
    @ObservationIgnored private var ticket = UUID()
    @ObservationIgnored private var monitor: NWPathMonitor?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var active = true
    @ObservationIgnored private var availableAuthentication: UIViewController?

    init(defaults: UserDefaults = .standard, client: (any SkyRankingClient)? = nil, monitorsConnection: Bool = true, requestTimeout: Duration = .seconds(15)) {
        self.defaults = defaults
        self.monitorsConnection = monitorsConnection
        self.requestTimeout = requestTimeout
        self.client = client ?? GameCenterClient()
        if let data = defaults.data(forKey: SkyRankingRecords.key),
           let decoded = try? JSONDecoder().decode(SkyRankingRecords.self, from: data), decoded.isValid {
            records = decoded
        } else { records = SkyRankingRecords() }
        player = self.client.player
    }
    deinit { task?.cancel(); timeout?.cancel(); monitor?.cancel() }

    var account: SkyRankingRecords.Account? { player.flatMap { records.accounts[$0.id] } }
    var standings: SkyStandings? { scope == .friends ? account?.friends : account?.global }

    func start() {
        guard !started else { return }
        started = true
        client.authenticationChanged = { [weak self] in self?.authenticationChanged() }
        guard monitorsConnection else { return }
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in self?.connectionChanged(connected) }
        }
        monitor.start(queue: DispatchQueue(label: "Starfall.rankings.connection"))
        if defaults.bool(forKey: "starfall.gameCenter.enabled") {
            client.authenticate { [weak self] in self?.availableAuthentication = $0 }
        }
    }

    func connect() {
        guard online else { return }
        defaults.set(true, forKey: "starfall.gameCenter.enabled")
        if let availableAuthentication {
            authenticationSheet = AuthenticationSheet(controller: availableAuthentication)
            return
        }
        client.authenticate { [weak self] controller in
            guard let self else { return }
            availableAuthentication = controller
            if active { authenticationSheet = AuthenticationSheet(controller: controller) }
        }
    }

    func authenticationChanged() {
        let current = client.player
        if current != player { invalidate(); player = current; authenticationSheet = nil }
        if current != nil { availableAuthentication = nil }
        refresh()
    }

    func connectionChanged(_ connected: Bool) {
        guard online != connected else { return }
        online = connected
        if connected { authenticationChanged() }
        else { invalidate(); message = nil }
    }

    /// Called synchronously after a committed eligible terminal turn, never by animation.
    var currentPlayerID: String? { client.player?.id }

    func record(_ result: SkyRankedResult) {
        // Re-read identity: an account change can precede its notification.
        let current = client.player
        if current != player { invalidate(); player = current }
        records.record(score: result.score, playerID: result.playerID)
        persist()
        refresh()
    }

    func refresh() {
        invalidate()
        guard active, online, let player, client.player?.id == player.id else { return }
        let id = player.id, requestedScope = scope, request = ticket
        let pending = records.accounts[id]?.pending
        loading = true; message = nil
        task = Task { [weak self] in
            guard let self else { return }
            if let pending {
                do {
                    try await client.submit(score: pending, playerID: id)
                    guard isCurrent(request, id: id) else { return }
                    records.acknowledge(score: pending, playerID: id); persist()
                } catch {
                    guard isCurrent(request, id: id) else { return }
                    message = "Your score is saved on this device. Submission will retry when you reconnect or refresh."
                }
            }
            do {
                let result = try await client.standings(scope: requestedScope)
                guard isCurrent(request, id: id), result.isValid else { return }
                var account = records.accounts[id] ?? SkyRankingRecords.Account()
                if requestedScope == .friends { account.friends = result } else { account.global = result }
                records.accounts[id] = account; persist()
            } catch {
                guard isCurrent(request, id: id) else { return }
                message = "Couldn’t update rankings. Any standings shown are from the last successful update. Your game is still available."
            }
            guard isCurrent(request, id: id) else { return }
            loading = false; timeout?.cancel(); timeout = nil
        }
        // A slow service cannot leave a permanent spinner. Late completions are rejected.
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: self?.requestTimeout ?? .seconds(15)) } catch { return }
            guard let self, isCurrent(request, id: id) else { return }
            invalidate()
            message = "Game Center is taking too long. Your game and pending scores are saved. Try refreshing later."
        }
    }

    func cancelRequests() { invalidate() }
    func resume() { active = true; authenticationChanged() }
    func suspend() { active = false; invalidate() }

    private func isCurrent(_ request: UUID, id: String) -> Bool {
        !Task.isCancelled && ticket == request && player?.id == id && client.player?.id == id && online
    }
    private func invalidate() {
        ticket = UUID(); task?.cancel(); task = nil; timeout?.cancel(); timeout = nil; loading = false
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(records) { defaults.set(data, forKey: SkyRankingRecords.key) }
    }
}
