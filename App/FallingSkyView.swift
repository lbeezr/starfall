import SwiftUI
import SpriteKit
import UIKit
import StarfallCore

// Historical experiment.* accessibility IDs remain stable for automation and assistive clients.
@MainActor struct FallingSkyView: View {
    @State private var store = FallingSkyStore.forSkyFlowApp()
    @State private var trace = ConstellationTraceIntent()
    @State private var traceFeedback = ConstellationTraceFeedback()
    @State private var menu: SkyMenuDestination?
    private var settings: Bool { menu != nil }
    @State private var flow = SkyFlowState()
    @State private var environmentGeneration = 0
    @State private var handoffLeaving = false
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

    private var endingReady: Bool { flow.screen == .playing && store.game.isOver && !store.busy }
    private var ceremonyScreen: SkyFlowScreen? {
        if let handoff = flow.handoff { return handoff.source }
        if endingReady { return store.game.outcome == .won ? .won : .full }
        return flow.screen == .playing ? nil : flow.screen
    }
    private var showingCeremony: Bool { ceremonyScreen != nil }
    private var boardVisible: Bool { flow.screen == .playing }
    private var handoffKey: String { "\(flow.handoff?.id.description ?? "none")-\(scenePhase == .active)-\(quietMotion)" }
    private var entryChallenge: Bool {
        flow.entry?.isChallenge(replayingChallenge: store.game.challenge != nil) ?? (store.game.challenge != nil)
    }
    private var quietMotion: Bool { reduceMotion || calmEffects || voiceOver }

    // Reserve the longest cue from round start: phase changes must not resize
    // SpriteKit and settle an in-flight shower. Old skies and fixed paces keep their layout.
    private var reservesTimingCueSpace: Bool {
        store.game.cadenceID.isAnnouncedCycle && store.game.challenge == nil
            && store.game.balance.pace == .brisk
    }

    private var cadenceCueCopy: SkyCadenceCueCopy? {
        guard !showingCeremony, !store.game.isOver, store.game.challenge == nil else { return nil }
        return SkyCadenceCueCopy(step: store.nextShowerCadence)
    }

    private func usesIslandTimer(size: CGSize, topInset: CGFloat) -> Bool {
        SkyShowerPlacement.usesIsland(hardware: SkyShowerPlacement.hardware, size: size,
                                     topInset: topInset, accessible: largeText || voiceOver)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                GeometryReader { safeViewport in
                    if largeText {
                        ScrollView {
                            VStack(spacing: StarfallTheme.Spacing.small) {
                                playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750, island: false)
                                    .frame(height: safeViewport.size.height)
                                if !showingCeremony {
                                    if !settings, let cue = store.phaseCue {
                                        SkyPhaseLabel(cue: cue).padding(.horizontal, StarfallTheme.Spacing.medium)
                                    }
                                    guide(compact: safeViewport.size.height < 750)
                                        .accessibilityHidden(settings)
                                        .padding(.horizontal, StarfallTheme.Spacing.medium)
                                        .padding(.bottom, safeViewport.safeAreaInsets.bottom + StarfallTheme.Spacing.small)
                                }
                            }
                        }
                        .ignoresSafeArea()
                    } else {
                        playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750,
                                  island: usesIslandTimer(size: safeViewport.size, topInset: safeViewport.safeAreaInsets.top))
                            .ignoresSafeArea()
                    }
                }
            }
            if let ceremonyScreen {
                let entryID = flow.entryID
                SkyFlowCeremony(screen: ceremonyScreen,
                                challenge: entryChallenge,
                                result: endingReady ? SkyResultSnapshot(game: store.game) : nil,
                                welcome: SkyWelcomeSnapshot(game: store.game, hasSavedSky: store.hasSavedSky, paused: store.isPaused),
                                active: scenePhase == .active && flow.handoff == nil && !settings, quiet: quietMotion, modal: settings,
                                action: { handleFlowAction($0, entryID: entryID) })
                    .id(String(describing: ceremonyScreen))
                    .opacity(flow.handoff != nil && handoffLeaving ? 0 : 1)
                    .allowsHitTesting(flow.handoff == nil && !settings)
                    .accessibilityHidden(flow.handoff != nil || settings)
                    .zIndex(1)
            }
            if flow.handoff?.preparing == true {
                VStack(spacing: StarfallTheme.Spacing.medium) {
                    if !quietMotion {
                        ProgressView().controlSize(.large).tint(StarfallTheme.Ceremony.gold)
                            .accessibilityHidden(true)
                    }
                    Text("Preparing your sky…").font(StarfallTheme.Typography.title)
                    Button("Back to Observatory") { handleFlowAction(.home) }
                        .buttonStyle(StarfallButtonStyle(role: .primary))
                        .accessibilityIdentifier("sky.preparing.back")
                }
                .padding(StarfallTheme.Spacing.large)
                .background(StarfallTheme.Colors.skyTop, in: RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel))
                .accessibilityIdentifier("sky.preparing")
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(!settings)
        .tint(StarfallTheme.Colors.actionPrimary)
        .onAppear { store.terminalSpeech = .ceremony; updateSuspension(); store.settlePresentation(); updateMotion() }
        .onDisappear { cancelConstellation(); store.setSuspended(true); store.terminalSpeech = .feedback }
        .onChange(of: store.constellationInputGeneration) { cancelConstellation() }
        .onChange(of: store.game) { cancelConstellation() }
        .onChange(of: store.canClear) { _, enabled in if !enabled { cancelConstellation() } }
        .onChange(of: store.isPaused) { cancelConstellation() }
        .onChange(of: scenePhase) { updateSuspension() }
        .onChange(of: settings) { finishHandoffIfReady(); updateSuspension() }
        .onChange(of: store.sceneReady) { finishHandoffIfReady(); updateSuspension() }
        .onChange(of: flow) { cancelConstellation(); updateSuspension() }
        .onChange(of: endingReady) { updateSuspension() }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .task(id: handoffKey) { await presentHandoff() }
        .sheet(item: $menu, onDismiss: { if voiceOver && !showingCeremony { menuFocused = true } }) { destination in
            settingsView(destination)
        }
    }

    /// The terrace owns its complete canvas. At accessibility sizes the guide is
    /// a sibling below it, so text growth cannot cover projected stars or props.
    private func playfield(insets: EdgeInsets, compact: Bool, island: Bool) -> some View {
        GeometryReader { viewport in
            let front = ObservatoryGeometry(size: viewport.size).frame(Cell(0, 0)).maxY
            let footerHeight = max(0, viewport.size.height - front - insets.bottom
                - 2 * StarfallTheme.Spacing.small)
            ZStack {
                board.allowsHitTesting(!settings && !showingCeremony)
                if !showingCeremony {
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        // Stable HUD space; the scenery and scene retain the complete window.
                        if reservesTimingCueSpace {
                            ZStack(alignment: .leading) {
                                SkyCadenceCue(copy: SkyCadenceCueCopy(step: .init(delay: 3, phase: .steady, warnsFasterNext: true))!)
                                    .hidden().accessibilityHidden(true).accessibilityIdentifier("sky.cadence.measurement")
                                if !settings, let copy = cadenceCueCopy {
                                    SkyCadenceCue(copy: copy)
                                }
                            }
                        }
                        compactHeader(island: island)
                        if !settings, !largeText, let cue = store.phaseCue { SkyPhaseLabel(cue: cue) }
                        Spacer(minLength: 0)
                        if !largeText { guide(compact: compact, maximumHeight: footerHeight) }
                    }
                    .padding(.horizontal, StarfallTheme.Spacing.medium)
                    .padding(.top, insets.top)
                    .padding(.bottom, insets.bottom + StarfallTheme.Spacing.small)
                }
            }
            .overlay(alignment: .top) {
                if island && !showingCeremony && !settings {
                    showerTrail(island: true)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityHidden(settings || showingCeremony)
        }
    }

    @ViewBuilder private func guide(compact: Bool, maximumHeight: CGFloat? = nil) -> some View {
        if store.isPaused && !store.game.isOver {
            SkyGuideCard(title: "Sunny",
                         message: store.message, showsPortrait: !compact, maximumHeight: maximumHeight) {
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

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private func compactHeader(island: Bool) -> some View {
        HStack(spacing: StarfallTheme.Spacing.small) {
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Image(systemName: "sparkle").foregroundStyle(StarfallTheme.Observatory.lanternGlow).accessibilityHidden(true)
                Text(store.game.challenge.map { "\(store.game.score) / \($0.target)" } ?? "\(store.game.score)")
                    .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                    .accessibilityLabel(store.game.challenge.map { "\(store.game.score) of \($0.target) starlight collected" } ?? "\(store.game.score) starlight")
                    .accessibilityIdentifier("experiment.score")
                    .accessibilityHint("Starfall terrace, seven columns. Row one is the farthest row. \(store.game.turns) showers, \(store.game.legalGroups.count) matching groups ready")
            }
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget).allowsHitTesting(false)
            Spacer(minLength: 0)
            if !island { showerTrail(island: false) }
            Spacer(minLength: 0)
            Button { menu = .game } label: { SkyMenuGlyph() }
                .buttonStyle(StarfallGameButtonStyle())
                .disabled(scenePhase != .active || store.suspended)
                .accessibilityLabel("Sky menu").accessibilityHint("Pause, settings and how to play")
                .accessibilityIdentifier("experiment.settings").accessibilityFocused($menuFocused)
        }
    }

    private func showerTrail(island: Bool) -> some View {
        SkyShowerTrail(deadline: store.nextShowerDate, interval: store.showerInterval,
                       paused: store.isPaused || store.suspended || store.game.isOver,
                       arriving: store.pending?.arrivals.isEmpty == false,
                       quiet: quietMotion, island: island, forecast: store.forecast)
    }

    /// Menu suspension must be released before applying a player pause choice.
    /// Both operations are synchronous on the main actor; no clock event can interleave.
    private func togglePauseFromMenu() {
        guard scenePhase == .active, flow.screen == .playing, !showingCeremony, store.sceneReady else { return }
        store.setSuspended(scenePhase != .active)
        store.togglePause()
        menu = nil
    }

    private var board: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    ObservatoryEnvironment(active: scenePhase == .active && !settings && !showingCeremony,
                                           reducedMotion: reduceMotion || calmEffects || voiceOver || reduceTransparency)
                        .id(environmentGeneration)
                    if environmentContrast == .increased || reduceTransparency {
                        Color.black.opacity(0.28).allowsHitTesting(false).accessibilityHidden(true)
                    }
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .opacity(boardVisible ? 1 : 0)
                        .animation(quietMotion ? nil : .easeOut(duration: StarfallTheme.Ceremony.handoffDuration), value: boardVisible)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    let mapping = ObservatoryGeometry(size: geometry.size)
                    if endingReady, let column = store.game.blockedColumn {
                        Path { path in
                            path.addLines(mapping.columnPolygon(column)); path.closeSubpath()
                        }
                        .fill(StarfallTheme.Ceremony.gold.opacity(0.12))
                        .overlay {
                            Path { path in
                                path.addLines(mapping.columnPolygon(column)); path.closeSubpath()
                            }.stroke(StarfallTheme.Ceremony.gold.opacity(0.8), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }
                        .allowsHitTesting(false).accessibilityHidden(true)
                    }
                    if !settings && !showingCeremony {
                    ForEach((0..<7).reversed(), id: \.self) { row in
                        ForEach(0..<7, id: \.self) { column in
                            let cell = Cell(row, column)
                            let frame = mapping.frame(cell)
                            cellButton(cell)
                                .accessibilityHidden(settings || showingCeremony)
                                .frame(width: frame.width, height: frame.height)
                                .contentShape(ObservatoryCellShape(points: mapping.polygon(cell).map {
                                    CGPoint(x: $0.x-frame.minX, y: $0.y-frame.minY)
                                }))
                                .position(x: frame.midX, y: frame.midY)
                        }
                    }
                    ConstellationTraceSurface(size: geometry.size, enabled: store.canClear,
                                              generation: store.constellationInputGeneration,
                                              traceStart: { ConstellationTraceHitTesting.start(at: $0, mapping: mapping, game: store.game) },
                                              tap: { cell in cancelConstellation(); store.clear(cell) },
                                              begin: { beginConstellation($0, size: geometry.size) },
                                              move: { moveConstellation($0, size: geometry.size) },
                                              end: releaseConstellation, cancel: cancelConstellation)
                    }
                }

            }
            // Keep the group unlabelled: a label here replaces leaf star labels
            // during touch exploration. Terrace context belongs to the score hint.
            .accessibilityElement(children: .contain)
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
        return Button { cancelConstellation(); store.clear(cell) } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(cell))
        .accessibilityValue(store.game.gem(at: cell)?.isLight == true ? "1 starlight, choose a colored star to start" : "\(value) starlight connected")
        .accessibilityHint(store.game.gem(at: cell)?.gravityKind == .hole
            ? "Clear a matching group containing a captive to close this hole"
            : store.game.gem(at: cell)?.gravityKind == .magnet
            ? "Clear beside it to dissolve it. Clear between a pair to form a hole"
            : store.game.orbit?.slots.contains(cell) == true
            ? "A legal clear containing this captive closes the hole and releases the others"
            : store.game.gem(at: cell)?.isDark == true
            ? "Clear a matching group directly beside this dark star to dissolve it"
            : store.game.gem(at: cell)?.isLight == true
                ? "Start on a colored star to include this orb in that color’s match or constellation. Using it spends it."
            : value >= 3
                ? (store.game.darkStarsBeside(group).isEmpty ? "Tap to clear this ordinary match" : "Tap to clear this ordinary match and adjacent dark stars")
                : "Needs three light horizontally or vertically, or five actual matching stars linked sideways or diagonally")
        .accessibilityCustomContent("Gravity consequence", gravityConsequence(cell))
        .accessibilityIdentifier("experiment.cell.\(cell.row).\(cell.column)")
        .accessibilityAction(named: Text("Add to constellation")) { accessibleTrace(cell) }
        .accessibilityAction(named: Text("Release constellation")) { releaseConstellation() }
        .accessibilityAction(named: Text("Cancel constellation")) { cancelConstellation() }
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canClear)
    }

    private func gravityConsequence(_ cell: Cell) -> String {
        guard let preview = store.game.gravityPreview(at: cell), let field = preview.orbit,
              store.game.orbit == nil else { return "No new hole" }
        return "Forms a hole at row \(7-field.center.row), column \(field.center.column+1), holding \(field.slots.count) stars"
    }

    private func cellLabel(_ cell: Cell) -> String {
        let position = "row \(7-cell.row), column \(cell.column+1)"
        guard let gem = store.game.gem(at: cell) else { return "Empty, \(position)" }
        if let role = gem.gravityKind {
            return role == .hole ? "Gravity hole, \(store.game.orbit?.windowsRemaining ?? 0) windows left, \(position)" : "Magnetic star, \(position)"
        }
        let shade = store.game.isGrowthBlocked(at: cell) ? ", growth blocked by a dark star" : ""
        let captive = store.game.orbit?.slots.contains(cell) == true ? "Captive, " : ""
        return "\(captive)\(gem.grown ? "Large " : "")\(StarCast.character(for: .init(gem)).description), \(position)\(shade)"
    }

    private func updateSuspension() {
        store.setSuspended(scenePhase != .active || settings || showingCeremony || !store.sceneReady)
    }

    private func finishHandoffIfReady() {
        guard let id = flow.handoff?.id,
              let startsClock = flow.completeHandoff(id, ready: store.sceneReady, active: scenePhase == .active, modal: settings) else { return }
        updateSuspension()
        if startsClock && !store.game.isOver && store.isPaused { store.togglePause() }
    }

    private func presentHandoff() async {
        guard let handoff = flow.handoff else { handoffLeaving = false; return }
        if quietMotion || scenePhase != .active || handoff.settled {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { handoffLeaving = true; flow.settleHandoff(handoff.id) }
        } else {
            handoffLeaving = false
            withAnimation(.easeOut(duration: StarfallTheme.Ceremony.handoffDuration)) { handoffLeaving = true }
            do { try await Task.sleep(for: .seconds(StarfallTheme.Ceremony.handoffDuration)) }
            catch { return }
            guard !Task.isCancelled else { return }
            flow.settleHandoff(handoff.id)
        }
        finishHandoffIfReady()
        guard flow.handoff?.id == handoff.id else { return }
        do { try await Task.sleep(for: .seconds(2)) } catch { return }
        guard !Task.isCancelled, flow.handoff?.id == handoff.id, !store.sceneReady else { return }
        flow.showPreparation(handoff.id)
        #if DEBUG
        print("Starfall: scene preparation still pending for handoff \(handoff.id)")
        #endif
    }

    private func handleFlowAction(_ action: SkyFlowAction, entryID: UInt64? = nil) {
        guard scenePhase == .active,
              let effect = flow.handle(action, hasSavedSky: store.hasSavedSky, entryID: entryID) else { return }
        switch effect {
        case .preferences:
            menu = .welcome
            return
        case .staged, .home:
            store.setSuspended(true)
        case .began(let request):
            store.setSuspended(true)
            store.beginEntry(request)
            environmentGeneration += 1
        case .continued:
            // Returning to the board does not change the player's pause choice.
            updateSuspension()
        }
        menu = nil
    }

    @ViewBuilder private func settingsView(_ destination: SkyMenuDestination) -> some View {
        switch destination {
        case .welcome:
            SkyWelcomePreferences(sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                                  done: { menu = nil })
        case .game:
            FallingSkyMenu(paused: store.isPaused, turns: store.game.turns,
                           groups: store.game.legalGroups.count, over: store.game.isOver,
                           challenge: store.game.challenge != nil, balance: store.game.balance,
                           sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                           pause: togglePauseFromMenu,
                           restart: { same in handleFlowAction(same ? .replay : .another) },
                           firstLight: { handleFlowAction(.firstLight) },
                           observatory: { handleFlowAction(.home) },
                           setBalance: store.setBalance, done: { menu = nil })
        }
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


private extension FallingSkyView {
    func cancelConstellation() {
        trace.cancel(); store.constellationTracing = false; store.scene.clearConstellationTrace()
    }
    func beginConstellation(_ point: CGPoint, size: CGSize) {
        cancelConstellation()
        guard let cell = ConstellationTraceHitTesting.start(at: point, mapping: ObservatoryGeometry(size: size), game: store.game) else { return }
        _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        store.constellationTracing = trace.snapshot != nil
        trace.lastFinger = point
        refreshConstellation()
    }
    func moveConstellation(_ point: CGPoint, size: CGSize) {
        guard trace.snapshot != nil else { return }
        let mapping = ObservatoryGeometry(size: size)
        guard mapping.cell(at: point) != nil else { cancelConstellation(); return }
        let previous = trace.lastFinger ?? point
        for cell in ConstellationTraceHitTesting.cells(from: previous, to: point, mapping: mapping, game: store.game) {
            let count = trace.count
            if trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear) {
                refreshConstellation()
                if trace.count > count { traceFeedback.step(count: trace.count, enabled: store.hapticsEnabled && !reduceMotion && !calmEffects && !voiceOver) }
            }
            if trace.snapshot == nil { cancelConstellation(); return }
        }
        trace.lastFinger = point
        store.scene.moveConstellationTip(point)
    }
    func refreshConstellation() { store.scene.showConstellationTrace(trace.path, ready: trace.count >= 5) }
    func releaseConstellation() {
        let outcome = trace.finish(ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        store.scene.clearConstellationTrace()
        guard let outcome else { store.constellationTracing = false; return }
        store.clearTracedConstellation(outcome.path, snapshot: outcome.snapshot, generation: outcome.generation)
        store.constellationTracing = false
        // Commit synchronously first; effects never choose or delay the cleared set.
        if store.game != outcome.snapshot { store.scene.constellationBurst(outcome.path) }
    }
    func accessibleTrace(_ cell: Cell) {
        if trace.snapshot == nil {
            _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        } else {
            _ = trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        }
        store.constellationTracing = trace.snapshot != nil
        refreshConstellation()
        UIAccessibility.post(notification: .announcement, argument: trace.count > 0
            ? "\(trace.count) stars worth \(trace.value) starlight. \(trace.count >= 5 ? "Ready to release." : "Five stars needed.")"
            : "Choose a neighboring matching star. Trace canceled.")
    }
}

@MainActor private final class ConstellationTraceFeedback {
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let ready = UIImpactFeedbackGenerator(style: .rigid)
    func step(count: Int, enabled: Bool) {
        guard enabled else { return }
        if count == 5 { ready.impactOccurred(intensity: 0.8) }
        else { impact.impactOccurred(intensity: min(0.85, 0.2+Double(count)*0.1)) }
        impact.prepare(); ready.prepare()
    }
}

private enum SkyMenuDestination: Identifiable {
    case game, welcome
    var id: Self { self }
}
