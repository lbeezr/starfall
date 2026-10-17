import SwiftUI
import SpriteKit
import StarfallCore

@MainActor struct StarfallExperimentView: View {
    @State private var store = StarfallExperimentStore()
    @State private var settings = false
    @AppStorage("calmEffects") private var calmEffects = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var largeText: Bool { dynamicTypeSize.isAccessibilitySize }
    private var controlLayout: AnyLayout {
        largeText ? AnyLayout(VStackLayout(alignment: .leading, spacing: StarfallTheme.Spacing.small))
            : AnyLayout(HStackLayout(spacing: StarfallTheme.Spacing.medium))
    }
    @Namespace private var matchingGroups

    var body: some View {
        ZStack {
            NightSkyBackdrop()
            GeometryReader { viewport in
                ScrollView {
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        compactHeader
                        board
                            .frame(minHeight: min(viewport.size.width - 24, StarfallTheme.Layout.contentWidth - 24))
                            .layoutPriority(1)
                        if store.game.isOver {
                            Text(store.game.outcome == .won ? "First Light complete" : "This sky is full")
                                .font(StarfallTheme.Typography.gameTitle)
                                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("experiment.outcome")
                            restartControls.buttonStyle(StarfallGameButtonStyle())
                            Text(store.message)
                                .font(StarfallTheme.Typography.gameDetail)
                                .foregroundStyle(StarfallTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("experiment.message")
                        } else if store.isPaused {
                            controlLayout {
                                Button(store.game.turns == 0 ? "Start sky" : "Resume sky") { store.togglePause() }
                                    .disabled(store.suspended)
                                    .accessibilityIdentifier("experiment.pause")
                                if !largeText { Spacer(minLength: 0) }
                                Button("Next shower") { store.callShower() }
                                    .disabled(store.busy || store.suspended)
                                    .accessibilityHint("Bring down one shower while staying paused.")
                                    .accessibilityIdentifier("experiment.next")
                            }
                            .buttonStyle(StarfallGameButtonStyle())
                        }
                    }
                    .font(StarfallTheme.Typography.gameDetail)
                    .padding(.horizontal, StarfallTheme.Spacing.medium)
                    .padding(.vertical, StarfallTheme.Spacing.small)
                    .frame(maxWidth: StarfallTheme.Layout.contentWidth)
                    .frame(maxWidth: .infinity, minHeight: viewport.size.height, alignment: .top)
                }
            }
            .accessibilityHidden(settings)
        }
        .preferredColorScheme(.dark)
        .tint(StarfallTheme.Colors.actionPrimary)
        .onAppear { store.setSuspended(false); store.settlePresentation(); updateMotion() }
        .onDisappear { store.setSuspended(true) }
        .onChange(of: scenePhase) { _, phase in store.setSuspended(phase != .active || settings) }
        .onChange(of: settings) { _, shown in store.setSuspended(shown || scenePhase != .active) }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .sheet(isPresented: $settings) { settingsView }
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private var compactHeader: some View {
        HStack(spacing: StarfallTheme.Spacing.small) {
            Image(systemName: "sparkle")
                .foregroundStyle(StarfallTheme.Colors.actionPrimary).accessibilityHidden(true)
            Text(store.game.challenge.map { "\(store.game.score) / \($0.target)" } ?? "\(store.game.score)")
                .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel(store.game.challenge.map { "\(store.game.score) of \($0.target) starlight collected" } ?? "\(store.game.score) starlight")
                .accessibilityIdentifier("experiment.score")
            Spacer(minLength: StarfallTheme.Spacing.small)
            Button { settings = true } label: { Image(systemName: "ellipsis") }
                .buttonStyle(StarfallGameButtonStyle())
                .disabled(scenePhase != .active || store.suspended)
                .accessibilityLabel("Sky menu").accessibilityHint("Pause, settings and how to play")
                .accessibilityIdentifier("experiment.settings")
        }
    }

    /// Menu suspension must be released before applying a player pause choice.
    /// Both operations are synchronous on the main actor; no clock event can interleave.
    private func togglePauseFromMenu() {
        store.setSuspended(scenePhase != .active)
        store.togglePause()
        settings = false
    }

    private var board: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: StarfallTheme.Radius.board)
                        .fill(StarfallTheme.Colors.surface)
                    VStack {
                        SkyArrivalCue(deadline: store.nextShowerDate,
                                      paused: store.isPaused || store.suspended || store.game.isOver,
                                      arriving: store.pending?.arrivals.isEmpty == false,
                                      reducedMotion: reduceMotion || calmEffects || voiceOver)
                            .padding(.top, StarfallTheme.Spacing.small)
                        Spacer(minLength: 0)
                    }
                    .allowsHitTesting(false)
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .allowsHitTesting(false).accessibilityHidden(true)
                    VStack(spacing: 0) {
                        ForEach((0..<7).reversed(), id: \.self) { row in
                            HStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { column in cellButton(Cell(row, column)) }
                            }
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.35 / 7.7)
                    .padding(.vertical, geometry.size.height * 0.35 / 7.7)
                }
                .clipShape(RoundedRectangle(cornerRadius: StarfallTheme.Radius.board))
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Starfall board, seven columns. Row one is the top.")
            .accessibilityValue("\(store.game.turns) showers, \(store.game.legalGroups.count) matching groups ready")
            .accessibilityIdentifier("experiment.board")
            .accessibilityRotor("Matching groups") {
                ForEach(store.game.legalGroups.compactMap(\.first), id: \.self) { cell in
                    AccessibilityRotorEntry(Text(cellLabel(cell)), id: cell, in: matchingGroups)
                }
            }
        }
    }

    private func cellButton(_ cell: Cell) -> some View {
        let group = store.game.group(at: cell)
        let value = store.game.value(of: group)
        return Button { store.clear(cell) } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(cell))
        .accessibilityValue("\(value) starlight connected")
        .accessibilityHint(store.game.gem(at: cell)?.isDark == true
            ? "Clear a matching group directly beside this dark star to dissolve it"
            : value >= 3
                ? (store.game.darkStarsBeside(group).isEmpty ? "Clear this group to make room" : "Clear this group and dissolve the dark stars beside it")
                : "Needs matching stars worth three. Grown stars count as two")
        .accessibilityIdentifier("experiment.cell.\(cell.row).\(cell.column)")
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canClear)
    }

    private func cellLabel(_ cell: Cell) -> String {
        let position = "row \(7-cell.row), column \(cell.column+1)"
        guard let gem = store.game.gem(at: cell) else { return "Empty, \(position)" }
        guard let kind = gem.kind else { return "\(StarCast.character(for: nil).description), \(position)" }
        let shade = store.game.isGrowthBlocked(at: cell) ? ", growth blocked by a dark star" : ""
        return "\(gem.grown ? "Large " : "")\(StarCast.character(for: kind).description), \(position)\(shade)"
    }

    private var restartControls: some View {
        controlLayout {
            Button("Replay this sky") { store.restart(sameSky: true); settings = false }
                .accessibilityIdentifier("experiment.replay")
            if !largeText { Spacer() }
            Button("New sky") { store.restart(sameSky: false); settings = false }
                .accessibilityIdentifier("experiment.new")
        }
    }

    private var settingsView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !store.game.isOver {
                        Button(store.isPaused ? (store.game.turns == 0 ? "Start sky" : "Resume sky") : "Pause sky") {
                            togglePauseFromMenu()
                        }
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .disabled(scenePhase != .active)
                        .accessibilityIdentifier("experiment.pause")
                        restartControls.buttonStyle(StarfallGameButtonStyle())
                    }
                    if let challenge = store.game.challenge {
                        Text(challenge.title).font(StarfallTheme.Typography.heading)
                    }
                    Text("\(store.game.turns) showers · \(store.game.legalGroups.count) matching groups ready")
                        .accessibilityIdentifier("experiment.roundSummary")
                    if store.game.challenge == nil {
                        Button("Start First Light · 18 starlight") {
                            store.startFirstLight(); settings = false
                        }
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .accessibilityHint("Starts a new challenge round, replacing the current sky. Reach 18 starlight to win.")
                        .accessibilityIdentifier("experiment.challenge")
                        Text("Try one short challenge. Starts a new round with steady showers and no dark stars.")
                        balanceControls
                    } else {
                        Text("First Light: collect 18 starlight. Steady showers and no dark stars. Replay repeats the challenge; New sky returns to survival.")
                    }
                    Toggle("Gentle sound", isOn: $store.soundEnabled)
                        .accessibilityIdentifier("experiment.sound")
                    Toggle("Haptic feedback", isOn: $store.hapticsEnabled)
                        .accessibilityIdentifier("experiment.haptics")
                    Toggle("Calm effects", isOn: $calmEffects)
                        .accessibilityIdentifier("experiment.calm")
                    Text("How to play").font(.headline).accessibilityAddTraits(.isHeader)
                    Text("Each star family has its own shape and face. Point counts identify the family, not its value: a small star is worth 1; a grown star is worth 2.")
                    Text("After you start, a shower arrives every \(store.game.balance.pace.rawValue) seconds. Matching stars travel together. When no group is ready, a later shower brings a matching run to a low column when there is room. A soft light at the top of the board signals an approaching shower. Colors and landing places remain a surprise. Clearing does not delay the sky.")
                    Text("A star matching the small star on top grows it to value 2. A grown star cannot grow again, so the next star stacks above it.")
                    Text("Clear connected matching stars worth at least 3. A grown star counts as 2, so a grown star beside one small match can clear. Collect their combined value as starlight.")
                    Text("An occasional dark star stops the stars directly above, below, left and right from growing. Existing grown stars stay large. Clear any matching group touching it to dissolve it and free that space. Dark stars are not part of color matches and award no starlight.")
                    Text("Make room before a star reaches a full column. Open the menu to pause and clear at your own pace. While paused, Next shower brings down one shower immediately. The menu and leaving the app freeze the sky; missed showers never accumulate. Replay a sky to try different choices.")
                }
                .font(StarfallTheme.Typography.body).padding(20)
                .fixedSize(horizontal: false, vertical: true)
            }
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle("Sky menu")
            .toolbar { Button("Done") { settings = false }.accessibilityIdentifier("experiment.done") }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .presentationDetents([.large])
    }

    private var balanceControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try a balance").font(.headline).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                Text("Shower pace")
                Picker("Shower pace", selection: Binding(get: { store.game.balance.pace }, set: { store.setPace($0) })) {
                    ForEach(StarfallBalance.Pace.allCases, id: \.self) { pace in
                        Text(pace.title).tag(pace)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.pace")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Dark stars")
                Picker("Dark stars", selection: Binding(get: { store.game.balance.darkStars }, set: { store.setDarkStarFrequency($0) })) {
                    ForEach(StarfallBalance.DarkStarFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.darkFrequency")
            }
            Text(store.game.balance.darkStars.detail)
                .accessibilityIdentifier("experiment.balanceDetail")
            Text("Changes keep your board and current preview. Existing dark stars stay. Replay this sky to start fresh with this balance.")
            Button("Reset balance") { store.setBalance(StarfallBalance()) }
                .buttonStyle(StarfallButtonStyle(role: .quiet))
                .disabled(store.game.balance == StarfallBalance())
                .accessibilityIdentifier("experiment.resetBalance")
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension StarfallBalance.Pace {
    var title: String {
        switch self {
        case .gentle: "Gentle · 6s"
        case .steady: "Steady · 4s"
        case .brisk: "Brisk · 3s"
        }
    }
}

private extension StarfallBalance.DarkStarFrequency {
    var title: String {
        switch self {
        case .none: "None"
        case .occasional: "Occasional"
        case .regular: "Regular"
        case .frequent: "Frequent"
        }
    }
    var detail: String {
        guard let gap = showerGap else { return "No new dark stars after the current preview." }
        return "One dark star every \(gap.lowerBound)–\(gap.upperBound) showers. A fresh sky starts with one in shower \(gap.upperBound)."
    }
}
/// Only this small cue refreshes with the clock; the board stays event-driven.
private struct SkyArrivalCue: View {
    let deadline: Date?
    let paused: Bool
    let arriving: Bool
    let reducedMotion: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            let approaching = !paused && !arriving && deadline.map { $0.timeIntervalSince(context.date) <= 1.25 } == true
            let visible = !paused && (arriving || approaching)
            Capsule()
                .fill(StarfallTheme.Colors.actionPrimary.opacity(visible ? 0.65 : 0.12))
                .frame(width: StarfallTheme.Layout.arrivalCueWidth, height: StarfallTheme.Layout.arrivalCueHeight)
                .shadow(color: StarfallTheme.Colors.actionPrimary.opacity(visible ? 0.35 : 0),
                        radius: StarfallTheme.Layout.arrivalCueGlow)
                .animation(reducedMotion ? nil : .easeInOut(duration: 0.3), value: visible)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(paused ? "Sky paused" : arriving ? "Stars arriving" : approaching ? "Shower approaching" : "Sky flowing")
                .accessibilityIdentifier("experiment.arrivalCue")
        }
    }
}
