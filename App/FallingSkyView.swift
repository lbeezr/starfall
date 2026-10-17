import SwiftUI
import SpriteKit
import StarfallCore

// Historical experiment.* accessibility IDs remain stable for automation and assistive clients.
@MainActor struct FallingSkyView: View {
    @State private var store = FallingSkyStore()
    @State private var settings = false
    @State private var environmentGeneration = 0
    @AccessibilityFocusState private var menuFocused: Bool
    @AppStorage("calmEffects") private var calmEffects = false
    @Environment(\.colorSchemeContrast) private var environmentContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
        GeometryReader { safeViewport in
            if largeText {
                ScrollView {
                    playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750)
                        .frame(height: max(StarfallTheme.Layout.accessibleObservatoryHeight, safeViewport.size.height))
                }
                .ignoresSafeArea()
            } else {
                playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750).ignoresSafeArea()
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(!settings)
        .tint(StarfallTheme.Colors.actionPrimary)
        .onAppear { store.setSuspended(false); store.settlePresentation(); updateMotion() }
        .onDisappear { store.setSuspended(true) }
        .onChange(of: scenePhase) { _, phase in store.setSuspended(phase != .active || settings) }
        .onChange(of: settings) { _, shown in store.setSuspended(shown || scenePhase != .active) }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .sheet(isPresented: $settings, onDismiss: { if voiceOver { menuFocused = true } }) { settingsView }
    }

    /// Accessibility-size controls get room below the terrace instead of covering its props.
    /// The canvas keeps one coordinate system while native scrolling brings each target into view.
    private func playfield(insets: EdgeInsets, compact: Bool) -> some View {
        ZStack {
            board
            VStack(spacing: StarfallTheme.Spacing.small) {
                compactHeader
                Spacer(minLength: 0)
                if store.game.isOver {
                    SkyGuideCard(title: store.game.outcome == .won ? "First Light complete" : "This sky is full",
                                 message: store.message, titleIdentifier: "experiment.outcome") {
                        restartControls.buttonStyle(StarfallGameButtonStyle())
                    }
                    .padding(.trailing, largeText ? 0 : StarfallTheme.Layout.guidePropClearance)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if store.isPaused {
                    SkyGuideCard(title: "Sunny",
                                 message: store.message, showsPortrait: !compact) {
                        controlLayout {
                            Button(store.game.turns == 0 ? "Start sky" : "Resume sky") { store.togglePause() }
                                .disabled(store.suspended).accessibilityIdentifier("experiment.pause")
                            if !largeText { Spacer(minLength: 0) }
                            Button("Next shower") { store.callShower() }
                                .disabled(store.busy || store.suspended).accessibilityIdentifier("experiment.next")
                        }.buttonStyle(StarfallGameButtonStyle())
                    }
                    .padding(.trailing, largeText ? 0 : StarfallTheme.Layout.guidePropClearance)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(.horizontal, StarfallTheme.Spacing.medium)
            .padding(.top, insets.top)
            .padding(.bottom, insets.bottom + StarfallTheme.Spacing.small)
        }
        .accessibilityHidden(settings)
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private var compactHeader: some View {
        HStack(spacing: StarfallTheme.Spacing.small) {
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Image(systemName: "sparkle").foregroundStyle(StarfallTheme.Observatory.lanternGlow).accessibilityHidden(true)
                Text(store.game.challenge.map { "\(store.game.score) / \($0.target)" } ?? "\(store.game.score)")
                    .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                    .accessibilityLabel(store.game.challenge.map { "\(store.game.score) of \($0.target) starlight collected" } ?? "\(store.game.score) starlight")
                    .accessibilityIdentifier("experiment.score")
            }
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget).allowsHitTesting(false)
            Spacer(minLength: 0)
            SkyShowerTrail(deadline: store.nextShowerDate, interval: store.showerInterval,
                           paused: store.isPaused || store.suspended || store.game.isOver,
                           arriving: store.pending?.arrivals.isEmpty == false,
                           quiet: reduceMotion || calmEffects || voiceOver)
            Spacer(minLength: 0)
            Button { settings = true } label: { SkyMenuGlyph() }
                .buttonStyle(StarfallGameButtonStyle())
                .disabled(scenePhase != .active || store.suspended)
                .accessibilityLabel("Sky menu").accessibilityHint("Pause, settings and how to play")
                .accessibilityIdentifier("experiment.settings").accessibilityFocused($menuFocused)
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
                    ObservatoryEnvironment(active: scenePhase == .active && !settings,
                                           reducedMotion: reduceMotion || calmEffects || voiceOver || reduceTransparency)
                        .id(environmentGeneration)
                    if environmentContrast == .increased || reduceTransparency {
                        Color.black.opacity(0.28).allowsHitTesting(false).accessibilityHidden(true)
                    }
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .allowsHitTesting(false).accessibilityHidden(true)
                    let mapping = ObservatoryGeometry(size: geometry.size)
                    if !settings {
                    ForEach((0..<7).reversed(), id: \.self) { row in
                        ForEach(0..<7, id: \.self) { column in
                            let cell = Cell(row, column)
                            let frame = mapping.frame(cell)
                            cellButton(cell)
                                .accessibilityHidden(settings)
                                .frame(width: frame.width, height: frame.height)
                                .contentShape(ObservatoryCellShape(points: mapping.polygon(cell).map {
                                    CGPoint(x: $0.x-frame.minX, y: $0.y-frame.minY)
                                }))
                                .position(x: frame.midX, y: frame.midY)
                        }
                    }
                    }
                }

            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Starfall terrace, seven columns. Row one is the farthest row.")
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
            Button("Replay this sky") { environmentGeneration += 1; store.restart(sameSky: true); settings = false }
                .accessibilityIdentifier("experiment.replay")
            if !largeText { Spacer() }
            Button("New sky") { environmentGeneration += 1; store.restart(sameSky: false); settings = false }
                .accessibilityIdentifier("experiment.new")
        }
    }

    private var settingsView: some View {
        FallingSkyMenu(paused: store.isPaused, turns: store.game.turns,
                       groups: store.game.legalGroups.count, over: store.game.isOver,
                       challenge: store.game.challenge != nil, balance: store.game.balance,
                       sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                       pause: togglePauseFromMenu,
                       restart: { same in environmentGeneration += 1; store.restart(sameSky: same); settings = false },
                       firstLight: { environmentGeneration += 1; store.startFirstLight(); settings = false },
                       setBalance: store.setBalance, done: { settings = false })
    }
}

private struct ObservatoryCellShape: Shape {
    let points: [CGPoint]
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines(points)
        path.closeSubpath()
        return path
    }
}
