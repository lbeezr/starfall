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
                        HStack(spacing: 12) {
                            Text(store.game.challenge?.title ?? "Starfall")
                                .font(StarfallTheme.Typography.gameTitle)
                            Spacer(minLength: 4)
                            Text(store.game.challenge.map { "\(store.game.score) / \($0.target)" } ?? "\(store.game.score)")
                                .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                                .accessibilityLabel(store.game.challenge.map { "\(store.game.score) of \($0.target) starlight collected" } ?? "\(store.game.score) starlight")
                                .accessibilityIdentifier("experiment.score")
                            Image(systemName: "sparkle").foregroundStyle(StarfallTheme.Colors.actionPrimary)
                            Button { settings = true } label: { Image(systemName: "gearshape") }
                                .accessibilityLabel("Settings").accessibilityIdentifier("experiment.settings")
                        }
                        .buttonStyle(StarfallGameButtonStyle())
                        forecast
                        board.frame(height: max(min(viewport.size.width - 24, StarfallTheme.Layout.contentWidth - 24), viewport.size.height - (largeText ? 310 : 202)))
                        if store.game.isOver {
                            Text(store.game.outcome == .won ? "First Light complete" : "This sky is full")
                                .font(StarfallTheme.Typography.gameTitle)
                                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("experiment.outcome")
                        }
                        controlLayout {
                            if !store.game.isOver {
                                Button { store.togglePause() } label: {
                                    Image(systemName: store.isPaused ? "play.fill" : "pause.fill")
                                }
                                .accessibilityLabel(store.isPaused ? (store.game.turns == 0 ? "Start sky" : "Resume sky") : "Pause sky")
                                .disabled(store.suspended).accessibilityIdentifier("experiment.pause")
                                Button("Next shower") { store.callShower() }
                                    .disabled(store.busy || store.suspended)
                                    .accessibilityHint("Bring the preview down now. Works while paused.")
                                    .accessibilityIdentifier("experiment.next")
                                if !largeText { Spacer(minLength: 0) }
                                Text("\(store.game.legalGroups.count) ready")
                                    .accessibilityLabel("\(store.game.legalGroups.count) matching groups ready")
                                    .accessibilityIdentifier("experiment.matches")
                            } else {
                                restartControls
                            }
                        }
                        .buttonStyle(StarfallGameButtonStyle())
                        Text(store.message)
                            .foregroundStyle(StarfallTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("experiment.message")
                    }
                    .font(StarfallTheme.Typography.gameDetail)
                    .padding(.horizontal, StarfallTheme.Spacing.medium)
                    .padding(.vertical, StarfallTheme.Spacing.small)
                    .frame(maxWidth: StarfallTheme.Layout.contentWidth)
                    .frame(maxWidth: .infinity)
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

    private var forecast: some View {
        HStack(spacing: 8) {
            Text("\(store.game.turns) \(store.game.turns == 1 ? "shower" : "showers")")
                .monospacedDigit().accessibilityIdentifier("experiment.turns")
            Spacer(minLength: 4)
            if !store.game.isOver {
                ForEach(store.forecast) { star in
                    Group {
                        if let kind = star.kind {
                            Text(kind.symbol).foregroundStyle(Color(kind.color))
                        } else {
                            Image(systemName: "moonphase.new.moon").foregroundStyle(.purple)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(star.kind?.label ?? "Dark star")
                    .accessibilityIdentifier("experiment.incoming.\(star.id % StarfallExperiment.maximumShowerSize)")
                }
                ShowerCountdown(deadline: store.nextShowerDate,
                                paused: store.isPaused || store.suspended,
                                arriving: store.pending?.arrivals.isEmpty == false)
            }
        }
        .font(StarfallTheme.Typography.gameDetail)
        .foregroundStyle(StarfallTheme.Colors.textSecondary)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("experiment.forecast")
    }

    private var board: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: StarfallTheme.Radius.board)
                        .fill(StarfallTheme.Colors.surface)
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
                : "Needs matching jewels worth three. Large jewels count as two")
        .accessibilityIdentifier("experiment.cell.\(cell.row).\(cell.column)")
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canClear)
    }

    private func cellLabel(_ cell: Cell) -> String {
        let position = "row \(7-cell.row), column \(cell.column+1)"
        guard let gem = store.game.gem(at: cell) else { return "Empty, \(position)" }
        guard let kind = gem.kind else { return "Dark star, \(position)" }
        let shade = store.game.isGrowthBlocked(at: cell) ? ", growth blocked by a dark star" : ""
        return "\(gem.grown ? "Large " : "")\(kind.label), \(position)\(shade)"
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
                        restartControls.buttonStyle(StarfallGameButtonStyle())
                    }
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
                    Text("After you start, a shower arrives every \(store.game.balance.pace.rawValue) seconds. Matching stars travel together. When no group is ready, a later shower brings a matching run to a low column when there is room. The preview shows what is coming. Landing places remain a surprise. Clearing does not delay the sky.")
                    Text("A star matching the small jewel on top grows it to value 2. A grown jewel cannot grow again, so the next star stacks above it.")
                    Text("Clear connected matching jewels worth at least 3. A large jewel counts as 2, so a large jewel beside one small match can clear. Collect their combined value as starlight.")
                    Text("An occasional dark star stops the jewels directly above, below, left and right from growing. Existing large jewels stay large. Clear any matching group touching it to dissolve it and free that space. Dark stars are not part of color matches and award no starlight.")
                    Text("Make room before a star reaches a full column. Pause to clear at your own pace. Call next shower brings the preview down immediately, even while paused. Settings and leaving the app freeze the sky; missed showers never accumulate. Replay a sky to try different choices.")
                }
                .font(StarfallTheme.Typography.body).padding(20)
                .fixedSize(horizontal: false, vertical: true)
            }
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle("Sky settings")
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
                Picker("Shower pace", selection: Binding(get: { store.game.balance.pace }, set: store.setPace)) {
                    ForEach(StarfallBalance.Pace.allCases, id: \.self) { pace in
                        Text(pace.title).tag(pace)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.pace")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Dark stars")
                Picker("Dark stars", selection: Binding(get: { store.game.balance.darkStars }, set: store.setDarkStarFrequency)) {
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
/// Only this small label refreshes with the clock; the board is event-driven.
private struct ShowerCountdown: View {
    let deadline: Date?
    let paused: Bool
    let arriving: Bool
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { context in
            Text(paused ? "Paused" : arriving ? "Falling…" : "\(max(1, Int(ceil((deadline ?? context.date).timeIntervalSince(context.date)))))s")
                .monospacedDigit()
                .foregroundStyle(StarfallTheme.Colors.actionPrimary)
                .accessibilityLabel(paused ? "Sky paused" : arriving ? "Stars arriving" : "Next shower approaching")
        }
    }
}
