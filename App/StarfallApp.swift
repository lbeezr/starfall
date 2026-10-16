import SwiftUI
import SpriteKit
import StarfallCore

@main struct StarfallApp: App {
    var body: some Scene { WindowGroup { StarfallView() } }
}


struct StarfallView: View {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var matchingGroups

    private var usesAccessibleBoard: Bool {
        #if DEBUG
        // Native structural coverage uses the same controls. This does not
        // enable VoiceOver or claim to test its focus and spoken behavior.
        voiceOver || ProcessInfo.processInfo.arguments.contains("--accessibility-board")
        #else
        voiceOver
        #endif
    }

    var body: some View {
        ZStack {
            NightSkyBackdrop()
            Group {
                if store.playing { gameView } else { menu }
            }
            .accessibilityHidden(store.settings)
        }
        .preferredColorScheme(.dark)
        .onChange(of: reduceMotion, initial: true) { _, value in store.updateReducedMotion(value || store.calmEffects) }
        .onChange(of: store.calmEffects) { _, value in store.updateReducedMotion(value || reduceMotion) }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.settlePresentation() }
        }
        .sheet(isPresented: $store.settings) { settingsView }
    }

    private var settingsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.section) {
                    VStack(spacing: StarfallTheme.Spacing.page) {
                        settingsToggle("Gentle sound", isOn: $store.soundEnabled, identifier: "settings.sound")
                        settingsToggle("Calm effects", isOn: $store.calmEffects, identifier: "settings.calm")
                    }
                    .starfallPanel()

                    // Unbounded scrolling provides natural text height. Do not
                    // turn these statements into row-sized accessibility elements.
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.large) {
                        Text("No timer.")
                        Text("No purchases or ads.")
                        Text("Your game stays on this device.")
                    }
                    .font(StarfallTheme.Typography.body)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                }
                .padding(StarfallTheme.Spacing.page)
                .frame(maxWidth: StarfallTheme.Layout.contentWidth)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
            }
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle("Settings")
            .toolbar {
                Button { store.settings = false } label: {
                    Text("Done")
                        .font(StarfallTheme.Typography.action)
                        .frame(minWidth: StarfallTheme.Layout.minimumTarget, minHeight: StarfallTheme.Layout.minimumTarget)
                }.accessibilityIdentifier("settings.done")
            }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        // Keep one reading surface at every text size, without an expansion step.
        .presentationDetents([.large])
    }
    @ViewBuilder
    private func settingsToggle(_ title: String, isOn: Binding<Bool>, identifier: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            // Give large labels the full row rather than competing with a
            // trailing switch. Native Toggle semantics and state stay intact.
            Toggle(isOn: isOn) {
                Text(title).font(StarfallTheme.Typography.body)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.button)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget)
            .accessibilityIdentifier(identifier)
        } else {
            Toggle(isOn: isOn) {
                Text(title).font(StarfallTheme.Typography.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .toggleStyle(.switch)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget)
            .accessibilityIdentifier(identifier)
        }
    }
    // Keep ordinary layouts centered and allow larger text to scroll instead of
    // shrinking the board or compressing essential controls below the viewport.
    private var menu: some View {
        GeometryReader { geometry in
            ScrollView {
                menuContent
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .contentShape(Rectangle())
            }
        }
    }
    private var menuContent: some View {
        VStack(spacing: StarfallTheme.Spacing.page) {
            VStack(spacing: StarfallTheme.Spacing.small) {
                Text("✦")
                    .font(.system(size: StarfallTheme.Layout.brandMarkSize))
                    .foregroundStyle(StarfallTheme.Colors.ambientStar)
                    .accessibilityHidden(true)
                StarfallTitle(style: .display)
                Text("A little pocket of moonlight")
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)

            if store.game.moves < Game.startingMoves { savedRoundSummary }

            Button(store.game.moves < Game.startingMoves ? "Continue" : "Play") { store.start() }
                .accessibilityIdentifier("menu.play")
                .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))

            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.medium) {
                Text("\(Game.target) starlight · \(Game.startingMoves) moves")
                    .font(StarfallTheme.Typography.heading)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Text("Tap 3 or more matching starshards connected horizontally or vertically.")
                    .font(StarfallTheme.Typography.body)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                Text("1 shard = 1 starlight. No timer. Groups of one or two spend no move.")
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .starfallPanel()

            Button("Settings") { store.settings = true }
                .buttonStyle(StarfallButtonStyle(role: .quiet))
                .accessibilityIdentifier("menu.settings")
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .padding(StarfallTheme.Spacing.page)
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
    }

    private var savedRoundSummary: some View {
        VStack(spacing: StarfallTheme.Spacing.small) {
            Text(store.game.outcome == .playing ? "Your sky is waiting" : outcomeTitle)
                .font(StarfallTheme.Typography.heading)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
            StarfallStatusText(text: store.game.outcome == .playing
                              ? "\(store.game.score) of \(Game.target) starlight · \(store.game.moves) \(store.game.moves == 1 ? "move" : "moves") left"
                              : "\(store.game.score) starlight released")
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("menu.saved-round")
    }
    private var gameView: some View {
        GeometryReader { geometry in
            ScrollView {
                gameContent
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
        }
    }
    private var gameContent: some View {
        VStack(spacing: StarfallTheme.Spacing.large) {
            if dynamicTypeSize.isAccessibilitySize {
                StarfallTitle()
            }
            HStack {
                Button("Menu") { store.playing = false }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .disabled(store.busy).accessibilityIdentifier("game.menu")
                Spacer()
                if !dynamicTypeSize.isAccessibilitySize {
                    StarfallTitle()
                    Spacer()
                }
                Button { store.settings = true } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(StarfallButtonStyle(role: .quiet))
                .accessibilityLabel("Settings").accessibilityIdentifier("game.settings")
            }
            StarlightHUD(score: store.game.score, moves: store.game.moves)
            ZStack {
                RoundedRectangle(cornerRadius: StarfallTheme.Radius.board, style: .continuous).fill(StarfallTheme.Colors.surface)
                    // A frame marker only: coordinate taps still reach the SpriteKit view.
                    .accessibilityElement().accessibilityLabel("Jewel board")
                    .accessibilityIdentifier("game.board").accessibilityHidden(usesAccessibleBoard)
                SpriteView(scene: store.scene, options: [.allowsTransparency])
                    .clipShape(RoundedRectangle(cornerRadius: StarfallTheme.Radius.board, style: .continuous))
                    .opacity(usesAccessibleBoard ? 0 : 1)
                    .accessibilityHidden(true)
                if usesAccessibleBoard { accessibleBoard }
            }
            .aspectRatio(1, contentMode: .fit)
            if usesAccessibleBoard && store.game.outcome == .playing {
                StarfallStatusText(text: "Use the Matching groups rotor to find a group, or explore each starshard.")
            }
            roundFeedback
            restartButton
            Spacer(minLength: 0)
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .padding(StarfallTheme.Spacing.page).frame(maxWidth: StarfallTheme.Layout.contentWidth)
    }

    private var outcomeTitle: String {
        store.game.outcome == .won ? "Sky illuminated" : "Out of moves"
    }

    @ViewBuilder
    private var roundFeedback: some View {
        if store.game.outcome == .playing {
            statusMessage
        } else {
            VStack(spacing: StarfallTheme.Spacing.small) {
                Text(outcomeTitle)
                    .font(StarfallTheme.Typography.title)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("game.outcome")
                StarfallStatusText(text: store.game.outcome == .won
                                   ? "\(store.game.score) starlight released"
                                   : "\(store.game.score) of \(Game.target) starlight released",
                                   emphasis: store.game.outcome == .won ? .positive : .supporting)
                    .accessibilityIdentifier("game.result-detail")
                statusMessage
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .starfallPanel(inset: StarfallTheme.Spacing.large)
        }
    }

    private var statusMessage: some View {
        StarfallStatusText(text: store.message)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: StarfallTheme.Layout.minimumTarget)
            .accessibilityLabel(store.message)
            .accessibilityIdentifier("game.message")
    }

    private var restartButton: some View {
        Button("New game") { store.restart() }
            .buttonStyle(StarfallButtonStyle(role: store.game.outcome == .playing ? .secondary : .primary,
                                            expands: store.game.outcome != .playing))
            .disabled(store.busy)
            .accessibilityIdentifier("game.restart")
    }
    private var accessibleBoard: some View {
        VStack(spacing: StarfallTheme.Spacing.hairline) {
            ForEach((0..<Game.side).reversed(), id: \.self) { row in
                HStack(spacing: StarfallTheme.Spacing.hairline) {
                    ForEach(0..<Game.side, id: \.self) { column in
                        let cell = Cell(row, column)
                        let kind = store.game.jewel(at: cell)!
                        let groupSize = store.game.group(at: cell).count
                        Button { store.tap(cell) } label: {
                            Text(kind.symbol)
                                // This is a shape, not reading text; growing it with
                                // Dynamic Type would merge neighboring silhouettes.
                                .font(.system(size: StarfallTheme.Layout.boardSymbolSize))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .foregroundStyle(Color(kind.color))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(kind.label), row \(Game.side-row), column \(column+1)")
                        .accessibilityValue("\(groupSize) connected")
                        .accessibilityHint(groupSize >= 3
                                           ? "Clear \(groupSize) starshards for one move"
                                           : "At least 3 are needed. No move will be spent")
                        .accessibilityIdentifier("game.cell.\(row).\(column)")
                        .accessibilityRotorEntry(id: cell, in: matchingGroups)
                        .disabled(store.busy || store.game.outcome != .playing)
                    }
                }
            }
        }
        .padding(StarfallTheme.Layout.accessibleBoardInset)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Starshard board")
        .accessibilityRotor("Matching groups") {
            ForEach(matchingGroupChoices) { choice in
                AccessibilityRotorEntry(
                    Text("\(choice.kind.label), \(choice.count) starshards, row \(Game.side - choice.id.row), column \(choice.id.column + 1)"),
                    id: choice.id, in: matchingGroups)
            }
        }
    }

    private struct MatchingGroupChoice: Identifiable {
        let id: Cell
        let kind: Jewel
        let count: Int
    }

    private var matchingGroupChoices: [MatchingGroupChoice] {
        guard store.game.outcome == .playing, !store.busy else { return [] }
        return store.game.legalGroups.compactMap { group in
            guard let cell = group.first, let kind = store.game.jewel(at: cell) else { return nil }
            return MatchingGroupChoice(id: cell, kind: kind, count: group.count)
        }
    }
}
