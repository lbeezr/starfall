import SwiftUI
import UIKit

@MainActor struct SkyLeaderboardView: View {
    @Bindable var leaderboard: SkyLeaderboard
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var visible = false

    var body: some View {
        List {
            Section {
                Text("The brightest skies").font(StarfallTheme.Typography.title)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Game Center · all-time best\nCompleted standard skies · starlight")
                    .font(StarfallTheme.Typography.supporting)
                if textSize.isAccessibilitySize { scopePicker.pickerStyle(.menu) }
                else { scopePicker.pickerStyle(.segmented) }
            }
            Section {
                status
                if leaderboard.loading { ProgressView("Updating rankings").accessibilityIdentifier("rankings.loading") }
                if let message = leaderboard.message { Text(message).accessibilityIdentifier("rankings.error") }
            }
            if leaderboard.player != nil, let standings = leaderboard.standings {
                Section {
                    if standings.entries.isEmpty {
                        Text(leaderboard.scope == .friends
                             ? "No friends have posted a score here yet. Explore Global while your circle grows."
                             : "No scores yet. A completed standard sky can be the first.")
                    }
                    ForEach(standings.entries) { entry in row(entry) }
                    if let local = standings.local, !standings.entries.contains(where: { $0.id == local.id }) {
                        row(local)
                    }
                } header: { Text(leaderboard.scope.rawValue) } footer: {
                    Text("Last updated \(standings.updated.formatted(date: .abbreviated, time: .shortened)). \(leaderboard.online && leaderboard.message == nil ? "" : "Positions may have changed.")")
                        .accessibilityIdentifier("rankings.updated")
                }
            }
            Section("On this device") {
                Text(leaderboard.records.localBest > 0
                     ? "Your best completed standard sky: \(leaderboard.records.localBest) starlight"
                     : "Your first completed standard sky will appear here.")
                    .accessibilityIdentifier("rankings.local")
                if let pending = leaderboard.account?.pending {
                    Text("\(pending) starlight saved · waiting to submit to Game Center.")
                        .accessibilityIdentifier("rankings.pending")
                }
                Text("You can play, restart and save without signing in or connecting. First Light and skies with changed balance stay local and aren’t ranked.")
                Text("Local records and your current sky stay on this device. Connecting shares eligible scores with Game Center; it doesn’t sync your saved game.")
            }
        }
        .scrollContentBackground(.hidden)
        .background(StarfallTheme.Colors.skyTop)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .navigationTitle("Rankings")
        .navigationBarTitleDisplayMode(.inline)
        .task { visible = true; leaderboard.start(); leaderboard.resume() }
        .onChange(of: leaderboard.scope) { leaderboard.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { leaderboard.resume() }
            else { leaderboard.suspend() }
        }
        .onDisappear { visible = false; leaderboard.cancelRequests() }
        .onChange(of: leaderboard.loading) { wasLoading, loading in
            guard wasLoading, !loading, visible, voiceOver, scenePhase == .active else { return }
            let summary = leaderboard.message ?? (leaderboard.standings?.local.map {
                "Rankings updated. Your rank is \($0.rank), with \($0.score) starlight."
            } ?? "Rankings updated.")
            UIAccessibility.post(notification: .announcement, argument: summary)
        }
        .sheet(item: $leaderboard.authenticationSheet) { sheet in
            GameCenterAuthenticationView(controller: sheet.controller)
        }
    }

    private var scopePicker: some View {
        Picker("Rankings", selection: $leaderboard.scope) {
            ForEach(SkyRankingScope.allCases) { Text($0.rawValue).tag($0) }
        }.accessibilityIdentifier("rankings.scope")
    }

    @ViewBuilder private var status: some View {
        if let player = leaderboard.player {
            Text("Signed in · \(player.name)")
            if !leaderboard.online {
                Label("Offline", systemImage: "wifi.slash").accessibilityIdentifier("rankings.offline")
                Text(leaderboard.standings == nil
                     ? "No saved standings yet. Rankings will be available when you reconnect. Your game is still available."
                     : "Showing saved standings. Positions may have changed.")
            } else {
                Button("Refresh rankings") { leaderboard.refresh() }
                    .accessibilityIdentifier("rankings.refresh")
            }
        } else {
            Text("Your sky, your pace").font(StarfallTheme.Typography.heading)
            Text("Connect to Game Center to see friends and global rankings. Keep playing without signing in; your scores stay on this device.")
                .accessibilityIdentifier("rankings.signedOut")
            if leaderboard.online {
                Button("Connect to Game Center") { leaderboard.connect() }
                    .accessibilityIdentifier("rankings.connect")
                Text("If you’ve declined sign-in, you can enable Game Center in iOS Settings.")
                    .font(StarfallTheme.Typography.supporting)
            } else {
                Label("Offline · play is still available", systemImage: "wifi.slash")
                    .accessibilityIdentifier("rankings.offline")
            }
        }
    }

    private func row(_ entry: SkyRankingEntry) -> some View {
        let isYou = entry.id == leaderboard.player?.id
        let layout = textSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: StarfallTheme.Spacing.small))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: StarfallTheme.Spacing.medium))
        return layout {
            Text("\(entry.rank). \(isYou ? "You · " : "")\(entry.name)")
                .fixedSize(horizontal: false, vertical: true)
            if !textSize.isAccessibilitySize { Spacer(minLength: StarfallTheme.Spacing.small) }
            Text(textSize.isAccessibilitySize ? "\(entry.score) starlight" : "\(entry.score)")
                .monospacedDigit().fixedSize()
        }
        .font(StarfallTheme.Typography.body)
        .foregroundStyle(isYou ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.textPrimary)
        .frame(minHeight: StarfallTheme.Layout.minimumTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rank \(entry.rank), \(isYou ? "You, " : "")\(entry.name), \(entry.score) starlight")
    }
}

/// UIKit is required only to present Apple's authentication controller unchanged.
private struct GameCenterAuthenticationView: UIViewControllerRepresentable {
    let controller: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { controller }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
