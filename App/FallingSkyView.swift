import SwiftUI
import SpriteKit
import StarfallCore

// Historical experiment.* accessibility IDs remain stable for automation and assistive clients.
@MainActor struct FallingSkyView: View {
    @State private var store: FallingSkyStore
    @State private var interaction = SkyInteractionSession()
    private var trace: ConstellationTraceIntent { interaction.trace }
    @State private var menu: SkyMenuDestination?
    private var settings: Bool { menu != nil }
    @State private var flow: SkyFlowState
    @State private var environmentGeneration = 0
    @State private var handoffLeaving = false
    @AccessibilityFocusState private var menuFocused: Bool
    @AppStorage("calmEffects") private var calmEffects = false
    @AppStorage(LandingPlace.preferenceKey) private var savedPlace = LandingPlace.moonwake.rawValue
    private var place: LandingPlace { LandingPlace.restored(savedPlace) }
    @Environment(\.colorSchemeContrast) private var environmentContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var largeText: Bool { dynamicTypeSize.isAccessibilitySize }
    @Namespace private var matchingGroups

    init() {
        self.init(store: .forSkyFlowApp(), flow: SkyFlowState())
    }

    init(store: FallingSkyStore, flow: SkyFlowState) {
        _store = State(initialValue: store)
        _flow = State(initialValue: flow)
    }

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

    private func usesIslandTimer(size: CGSize, topInset: CGFloat) -> Bool {
        SkyShowerPlacement.usesIsland(hardware: SkyShowerPlacement.hardware, size: size,
                                     topInset: topInset, accessible: largeText || voiceOver)
    }

    var body: some View {
        ZStack {
            LandingBackdrop(place: place).ignoresSafeArea()
            VStack(spacing: 0) {
                GeometryReader { safeViewport in
                    // The playfield expands through safe-area insets. Classify that
                    // same canvas so a small iPad is not mistaken for a short phone.
                    let canvasHeight = safeViewport.size.height + safeViewport.safeAreaInsets.top + safeViewport.safeAreaInsets.bottom
                    if largeText || canvasHeight < 740 {
                        let height = max(largeText ? 1200 : 900, safeViewport.size.height)
                        let mapping = LandingGeometry(size: CGSize(width: safeViewport.size.width, height: height), largeHeader: largeText)
                        ScrollView {
                            VStack(spacing: 0) {
                                playfield(insets: safeViewport.safeAreaInsets, compact: false, allowsIsland: false, expanded: true)
                                    .frame(height: height)
                                    .frame(height: mapping.accessibleCanvasEnd, alignment: .top).clipped()
                                if !showingCeremony && !settings {
                                    guide(compact: false)
                                        .padding(StarfallTheme.Landing.flowingApronInset)
                                        .frame(maxWidth: .infinity)
                                        .padding(.bottom, safeViewport.safeAreaInsets.bottom)
                                }
                            }
                        }.ignoresSafeArea()
                    } else {
                        playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750,
                                  allowsIsland: true).ignoresSafeArea()
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
                    // Ceremony owns inactive AX elements. An extra hidden(false)
                    // container here masks native child hit results on iPad.
                    .id(String(describing: ceremonyScreen))
                    .opacity(flow.handoff != nil && handoffLeaving ? 0 : 1)
                    .allowsHitTesting(flow.handoff == nil && !settings)
                    .zIndex(1)
            }
            if flow.handoff?.preparing == true {
                VStack(spacing: StarfallTheme.Spacing.medium) {
                    if !quietMotion {
                        ProgressView().controlSize(.large).tint(StarfallTheme.Ceremony.gold)
                            .accessibilityHidden(true)
                    }
                    Text(SkyCopy.text(.flowPreparing)).font(StarfallTheme.Typography.title)
                    Button(SkyCopy.text(.actionHome)) { handleFlowAction(.home) }
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
        .onAppear { CrystalCelebrationArtwork.shared.prewarm(); store.terminalSpeech = .ceremony; updateSuspension(); store.settlePresentation(); updateMotion() }
        .onDisappear { invalidateInteraction(); store.setSuspended(true); store.terminalSpeech = .feedback }
        .onChange(of: store.constellationInputGeneration) { invalidateInteraction() }
        .onChange(of: store.game) {
            interaction.reconcile(with: store.game, release: store.endConstellationHold)
            store.scene.clearConstellationTrace()
        }
        .onChange(of: store.canClear) { _, enabled in if !enabled { cancelConstellation() } }
        .onChange(of: store.isPaused) { cancelConstellation() }
        .onChange(of: scenePhase) { invalidateInteraction(); updateSuspension() }
        .onChange(of: store.persistenceNotice) { invalidateInteraction(); finishHandoffIfReady(); updateSuspension() }
        .onChange(of: settings) { finishHandoffIfReady(); updateSuspension() }
        .onChange(of: store.sceneReady) { finishHandoffIfReady(); updateSuspension() }
        .onChange(of: flow) { cancelConstellation(); updateSuspension() }
        .onChange(of: endingReady) { updateSuspension() }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .onChange(of: reduceMotion) { invalidateInteraction() }
        .task(id: handoffKey) { await presentHandoff() }
        .alert(store.persistenceNotice?.title ?? "", isPresented: Binding(
            get: { store.persistenceNotice != nil && !settings },
            set: { if !$0 { store.dismissPersistenceNotice() } })) {
                Button(SkyCopy.text(.actionDone)) { store.dismissPersistenceNotice() }
            } message: {
                Text(store.persistenceNotice?.message ?? "")
            }
        .sheet(item: $menu, onDismiss: { if voiceOver && !showingCeremony { menuFocused = true } }) { destination in
            settingsView(destination)
        }
        .overlayPreferenceValue(StarlightAnchors.self) { anchors in
            GeometryReader { proxy in
                if !settings, !showingCeremony, let receipt = store.celebration,
                   let board = anchors[.board], let score = anchors[.score], let header = anchors[.header] {
                    StarlightCelebrationOverlay(event: receipt, board: proxy[board], score: proxy[score], header: proxy[header], quiet: quietMotion)
                        .id(receipt.id)
                }
            }.allowsHitTesting(false)
        }
    }

    /// One centered canvas owns the stars. Accessible dialogue reflows below it.
    private func playfield(insets: EdgeInsets, compact: Bool, allowsIsland: Bool, expanded: Bool = false) -> some View {
        GeometryReader { viewport in
            let mapping = LandingGeometry(size: viewport.size, largeHeader: expanded && largeText)
            let crown = mapping.crownFrame
            let room = mapping.communicationContentFrame
            let island = allowsIsland && usesIslandTimer(size: viewport.size, topInset: insets.top)
            ZStack {
                board(expanded: expanded).allowsHitTesting(!settings && !showingCeremony)
                if !showingCeremony && !settings {
                    VStack(spacing: 4) {
                        ViewThatFits(in: .horizontal) {
                            HStack { scoreLabel; Spacer(minLength: 12); skyMenuButton }
                            VStack(alignment: .leading, spacing: 4) { scoreLabel; skyMenuButton }
                        }
                        if !island { showerTrail(island: false, width: min(280, crown.width)) }
                    }
                    .frame(width: crown.width, height: crown.height)
                    .starlightAnchor(.header).accessibilityElement(children: .contain)
                    .accessibilityIdentifier("sky.header")
                    .position(x: crown.midX, y: crown.midY)
                    if !expanded {
                        guide(compact: compact, maximumHeight: room.height, narrow: room.width < 280, externalControls: true)
                            .frame(width: room.width, height: room.height, alignment: .center)
                            .position(x: room.midX, y: room.midY)
                        if !store.game.isOver {
                            registered(landingAction(0), in: mapping.actionFrame(0))
                            registered(landingAction(1), in: mapping.actionFrame(1))
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                if island && !showingCeremony && !settings {
                    showerTrail(island: true).allowsHitTesting(false)
                }
            }
            .accessibilityHidden(settings || showingCeremony)
        }
    }

    @ViewBuilder private func guide(compact: Bool, maximumHeight: CGFloat? = nil, narrow: Bool = false, externalControls: Bool = false) -> some View {
        if !store.game.isOver {
            SkyDialogueOverlay(session: store.dialogue,
                               pausedLine: store.isPaused ? store.pausedGuideLine : nil,
                               active: scenePhase == .active && !settings && !showingCeremony,
                               next: store.nextDialogue, maximumHeight: maximumHeight, compact: narrow,
                               embedded: true, externalControls: externalControls, embeddedInk: StarfallTheme.Landing.ink(place)) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StarfallTheme.Spacing.medium) { pauseControl; showerControl }
                        .fixedSize(horizontal: true, vertical: false)
                    VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) { pauseControl; showerControl }
                }.buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Landing.ink(place)))
            }
        }
    }
    private var pauseControl: some View {
        Button(store.isPaused ? (store.game.turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) : SkyCopy.text(.actionPause)) { store.togglePause() }
            .disabled(store.suspended).accessibilityIdentifier("experiment.pause")
    }
    private var showerControl: some View {
        Button(SkyCopy.text(.actionNext)) { store.callShower() }
            .disabled(store.busy || store.suspended).accessibilityIdentifier("experiment.next")
    }

    private func registered<Content: View>(_ content: Content, in frame: CGRect) -> some View {
        content.frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }

    private func landingAction(_ index: Int) -> some View {
        Group {
            if store.dialogue.visible && store.dialogue.scriptID != nil {
                if index == 0 && store.dialogue.hasNext {
                    Button(SkyCopy.text(.actionNextLine), action: store.nextDialogue)
                        .accessibilityIdentifier("sky.dialogue.next")
                } else if index == 1 {
                    Button(SkyCopy.text(.actionClose)) { store.dialogue.dismiss() }
                        .accessibilityIdentifier("sky.dialogue.close")
                }
            } else if index == 0 { pauseControl }
            else { showerControl }
        }
        .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Landing.ink(place)))
        .multilineTextAlignment(.center)
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private var scoreLabel: some View {
        let quiet = quietMotion
        let celebrating = store.celebration != nil
        return
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Image(systemName: "sparkle").font(StarfallTheme.Typography.hudGlyph).foregroundStyle(StarfallTheme.Observatory.lanternGlow).accessibilityHidden(true)
                Text(store.game.challenge.map { "\(store.game.score.formatted()) / \($0.target.formatted())" } ?? store.game.score.formatted())
                    .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                    .accessibilityLabel(store.game.challenge.map { SkyCopy.text(.resultChallengeScore, values: ["score": String(store.game.score), "target": String($0.target)]) } ?? SkyCopy.text(.welcomeScore, values: ["score": String(store.game.score)]))
                    .accessibilityIdentifier("experiment.score")
                    .accessibilityHint(SkyCopy.text(.a11yBoardHint, values: ["summary": boardSummary]))
            }
            .keyframeAnimator(initialValue: CGFloat(1), trigger: store.game.score) { content, scale in
                content.scaleEffect(quiet || !celebrating ? 1 : scale, anchor: .leading)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 0.58)
                SpringKeyframe(1.1 + 0.12 * (store.celebration?.energy ?? 0), duration: 0.12)
                CubicKeyframe(1, duration: 0.2)
            }
            .starlightAnchor(.score)
            .foregroundStyle(StarfallTheme.Landing.ink(place))
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget).allowsHitTesting(false)
    }
    private var skyMenuButton: some View {
        Button { menu = .game } label: { Text("Menu") }
            .buttonStyle(StarfallGameButtonStyle(tint: StarfallTheme.Landing.ink(place)))
            .disabled(scenePhase != .active || store.suspended)
            .accessibilityLabel(SkyCopy.text(.menuTitle)).accessibilityHint(SkyCopy.text(.menuHint))
            .accessibilityIdentifier("experiment.settings").accessibilityFocused($menuFocused)
    }

    private func showerTrail(island: Bool, width: CGFloat = StarfallTheme.Layout.showerTrailWidth) -> some View {
        SkyShowerTrail(deadline: store.nextShowerDate, interval: store.showerInterval,
                       paused: store.isPaused || store.suspended || store.game.isOver,
                       arriving: store.pending?.arrivals.isEmpty == false,
                       quiet: quietMotion, island: island, width: width, forecast: store.forecast)
    }

    /// Menu suspension must be released before applying a player pause choice.
    /// Both operations are synchronous on the main actor; no clock event can interleave.
    private func togglePauseFromMenu() {
        guard scenePhase == .active, flow.screen == .playing, !showingCeremony, store.sceneReady else { return }
        store.setSuspended(scenePhase != .active)
        store.togglePause()
        menu = nil
    }

    private func board(expanded: Bool) -> some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    LandingEnvironment(place: place, active: scenePhase == .active && !settings && store.persistenceNotice == nil && !showingCeremony && !store.isPaused,
                                           reducedMotion: reduceMotion || calmEffects || voiceOver || reduceTransparency, largeHeader: expanded && largeText)
                        .id("\(environmentGeneration).\(place.rawValue)")
                    if environmentContrast == .increased || reduceTransparency {
                        Color.black.opacity(0.28).allowsHitTesting(false).accessibilityHidden(true)
                    }
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .opacity(boardVisible ? 1 : 0)
                        .animation(quietMotion ? nil : .easeOut(duration: StarfallTheme.Ceremony.handoffDuration), value: boardVisible)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    let mapping = LandingGeometry(size: geometry.size)
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
                    ConstellationTraceSurface(size: geometry.size, enabled: !store.suspended && !store.game.isOver,
                                              generation: store.constellationInputGeneration,
                                              traceStart: { ConstellationTraceHitTesting.start(at: $0, mapping: mapping, game: store.game) },
                                              tap: tapBoardCell,
                                              begin: { beginConstellation($0, size: geometry.size) },
                                              move: { moveConstellation($0, size: geometry.size) },
                                              end: releaseConstellation, cancel: cancelConstellation,
                                              contact: { beginBoardContact($0, size: geometry.size) },
                                              feedback: store.explainInputFailure,
                                              swapStart: { point in mapping.cell(at:point).map { store.game.canArrangeStars && store.game.gem(at:$0) != nil && store.canReceiveInput } ?? false },
                                              swap: commitDirectSwap)
                    }
                }

            }
            .starlightAnchor(.board)
            // Keep the group unlabelled: a label here replaces leaf star labels
            // during touch exploration. Terrace context belongs to the score hint.
            .accessibilityElement(children: .contain)
            .accessibilityValue(boardSummary)
            .accessibilityIdentifier("experiment.board")
            .accessibilityRotor(SkyCopy.text(.a11yMatchingGroups)) {
                ForEach(store.game.legalGroups.compactMap(\.first), id: \.self) { cell in
                    AccessibilityRotorEntry(Text(cellLabel(cell)), id: cell, in: matchingGroups)
                }
            }
        }
    }

    private var boardSummary: String {
        SkyCopy.text(.a11yBoardSummary, values: ["showers": String(store.game.turns), "groups": String(store.game.legalGroups.count)])
    }

    private func cellButton(_ cell: Cell) -> some View {
        let group = store.game.group(at: cell)
        let value = store.game.value(of: group)
        let reward = store.game.reward(of: group)
        let snapshot = store.game
        let generation = store.constellationInputGeneration
        return Button { tapBoardCell(cell) } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(cell))
        .accessibilityValue(store.game.gem(at: cell)?.isLight == true
            ? (store.game.isDrained(at: cell) ? SkyCopy.text(.a11yOrbDrained) : SkyCopy.text(.a11yOrb))
            : reward != value ? SkyCopy.text(.a11yGroupReward, values: ["value": String(value), "reward": String(reward)]) : SkyCopy.text(.a11yGroupValue, values: ["value": String(value)]))
        .accessibilityHint(store.game.gem(at: cell)?.gravityKind == .hole
            ? SkyCopy.text(.a11yHoleHint)
            : store.game.gem(at: cell)?.gravityKind == .magnet
            ? SkyCopy.text(.a11yFieldHint)
            : store.game.orbit?.slots.contains(cell) == true
            ? SkyCopy.text(.a11yTrappedHint)
            : store.game.gem(at: cell)?.isDark == true
            ? SkyCopy.text(.a11yDarkHint)
            : store.game.gem(at: cell)?.isLight == true
                ? SkyCopy.text(.a11yOrbHint)
            : value >= 3
                ? (store.game.darkStarsBeside(group).isEmpty ? SkyCopy.text(.a11yClearHint) : SkyCopy.text(.a11yClearDarkHint))
                : SkyCopy.text(.a11yMatchHint))
        .accessibilityCustomContent(Text(SkyCopy.text(.a11yGravityConsequence)), Text(gravityConsequence(cell)))
        .accessibilityCustomContent(Text(SkyCopy.text(.a11yDuskConsequence)), Text(DuskWarning.consequence(game: store.game, cell: cell)))
        .accessibilityIdentifier("experiment.cell.\(cell.row).\(cell.column)")
        .accessibilityActions {
            ForEach(0..<4, id: \.self) { direction in
                let destination = [Cell(cell.row, cell.column-1), Cell(cell.row, cell.column+1),
                                   Cell(cell.row+1, cell.column), Cell(cell.row-1, cell.column)][direction]
                if snapshot.canNudge(from: cell, to: destination) {
                    let title: SkyCopy.Key = [.techniqueMoveLeft, .techniqueMoveRight, .techniqueMoveUp, .techniqueMoveDown][direction]
                    Button(SkyCopy.text(title)) {
                        cancelConstellation()
                        _ = store.requestInput(.swap(cell, destination), snapshot: snapshot, generation: generation)
                    }
                }
            }
        }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceAdd))) { accessibleTrace(cell) }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceRelease))) { releaseConstellation() }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceCancel))) { cancelConstellation() }
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canReceiveInput)
    }

    private func gravityConsequence(_ cell: Cell) -> String {
        guard let preview = store.game.gravityPreview(at: cell), let field = preview.orbit,
              store.game.orbit == nil else { return SkyCopy.text(.a11yNoHole) }
        return SkyCopy.text(.a11yHolePreview, values: ["position": SkyCopy.position(row: 7-field.center.row, column: field.center.column+1), "count": String(field.slots.count)])
    }

    private func cellLabel(_ cell: Cell) -> String {
        let position = SkyCopy.position(row: 7-cell.row, column: cell.column+1)
        guard let gem = store.game.gem(at: cell) else { return SkyCopy.text(.a11yEmpty, values: ["position": position]) }
        if let role = gem.gravityKind {
            return role == .hole ? SkyCopy.text(.a11yHole, values: ["release": SkyCopy.count(.orbitReleaseOne, .orbitReleaseMany, store.game.orbit?.windowsRemaining ?? 0), "position": position]) : SkyCopy.text(.a11yField, values: ["position": position])
        }
        if gem.isDark && store.game.duskRule != .legacy {
            return SkyCopy.text(.duskLabel, values: ["fed": String(gem.duskFeeds), "feeds": String(store.game.duskRule.feedingShowers), "position": position, "consequence": DuskWarning.consequence(game: store.game, cell: cell)])
        }
        let shade = store.game.isDrained(at: cell) ? SkyCopy.text(.duskGray)
            : store.game.isGrowthBlocked(at: cell) ? SkyCopy.text(.duskBlocked) : ""
        let mass = CriticalMassPresentation.consequence(game: store.game, cell: cell)
        let captive = store.game.orbit?.slots.contains(cell) == true ? SkyCopy.text(.a11yTrapped) : ""
        return SkyCopy.text(.a11yStar, values: ["size": gem.grown ? SkyCopy.text(.a11yGrown) : "", "description": StarCast.character(for: .init(gem)).description, "position": position, "state": captive + shade + mass])
    }

    private func updateSuspension() {
        store.setSuspended(scenePhase != .active || settings || store.persistenceNotice != nil || showingCeremony || !store.sceneReady)
    }

    private func finishHandoffIfReady() {
        guard let id = flow.handoff?.id,
              let startsClock = flow.completeHandoff(id, ready: store.sceneReady, active: scenePhase == .active, modal: settings || store.persistenceNotice != nil) else { return }
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
                                  context: .selected(game: store.game, entry: flow.entry), done: { menu = nil })
        case .game:
            FallingSkyMenu(paused: store.isPaused, turns: store.game.turns,
                           groups: store.game.legalGroups.count, over: store.game.isOver,
                           challenge: store.game.challenge != nil, helpContext: .init(game: store.game), balance: store.game.balance,
                           sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                           place: Binding(get: { place }, set: { savedPlace = $0.rawValue }),
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
    func tapBoardCell(_ cell: Cell) {
        cancelConstellation()
        store.requestTap(cell)
    }
    func commitDirectSwap(from: Cell, to: Cell, generation: UInt64) {
        defer { cancelConstellation() }
        guard store.constellationTracing, generation == store.constellationInputGeneration else { return }
        let snapshot = store.game
        _ = store.requestInput(.swap(from, to), snapshot: snapshot, generation: generation)
    }
    func cancelConstellation() {
        interaction.cancelContact(release: store.endConstellationHold)
        store.scene.clearConstellationTrace()
    }
    func invalidateInteraction() {
        store.cancelBufferedInput()
        interaction.invalidate(release: store.endConstellationHold)
        store.scene.clearConstellationTrace()
    }
    func beginBoardContact(_ point: CGPoint, size: CGSize) -> Bool {
        cancelConstellation()
        guard let cell = LandingGeometry(size: size).cell(at: point) else { return false }
        guard interaction.acquireHold(at: cell, using: store.beginResponsiveContact) else {
            store.explainSettling(at: cell); return false
        }
        store.showInputFeedback(nil)
        store.scene.showContact(cell, drawingEligible: store.game.canStartConstellation(at: cell) && store.canTrace([cell]))
        return true
    }
    func beginConstellation(_ point: CGPoint, size: CGSize) {
        guard let cell = ConstellationTraceHitTesting.start(at: point, mapping: LandingGeometry(size: size), game: store.game) else {
            store.explainInputFailure(SkyCopy.text(.inputTraceStart)); return
        }
        guard store.canTrace([cell]) else { store.explainSettling(at: cell); return }
        _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace([cell]))
        if trace.snapshot != nil {
            interaction.acquireHold(at: trace.path.first, using: store.beginConstellationHold)
        }
        trace.lastFinger = point
        refreshConstellation()
        if trace.snapshot != nil { store.traceArmed() }
    }
    func moveConstellation(_ point: CGPoint, size: CGSize) {
        guard trace.snapshot != nil else { return }
        let mapping = LandingGeometry(size: size)
        guard mapping.cell(at: point) != nil else { cancelConstellation(); store.explainInputFailure(SkyCopy.text(.inputTraceOffBoard)); return }
        let previous = trace.lastFinger ?? point
        for cell in ConstellationTraceHitTesting.cells(from: previous, to: point, mapping: mapping, game: store.game) {
            let count = trace.count
            if trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path + [cell])) {
                refreshConstellation()
                if trace.count > count { store.traceStep(count: trace.count) }
            }
            if trace.snapshot == nil {
                // The physical contact still owns its clock hold until terminal delivery;
                // drawing never falls back to a swap or an ordinary tap.
                store.scene.clearConstellationTrace(); return
            }
        }
        trace.lastFinger = point
        store.scene.moveConstellationTip(point)
    }
    func refreshConstellation() {
        store.scene.showConstellationTrace(trace.path, ready: store.game.constellationCells(along:trace.path) != nil)
        if trace.count > 0 {
            let ready = store.game.constellationCells(along: trace.path) != nil
            let value = store.game.reward(of: Set(trace.path))
            store.showInputFeedback(ready ? SkyCopy.text(.inputTraceReady, values: ["count": String(trace.count), "score": String(value)]) : SkyCopy.text(.inputTraceProgress, values: ["count": String(trace.count)]))
        }
    }
    func releaseConstellation() {
        let hadTrace = trace.snapshot != nil
        let outcome = trace.finish(ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path))
        store.scene.clearConstellationTrace()
        let hold = interaction.holdTicket
        defer { interaction.endContact(ticket: hold, release: store.endConstellationHold) }
        guard let outcome else {
            if hadTrace { store.explainInputFailure(SkyCopy.text(store.game.challenge == nil ? .inputTraceShort : .inputTraceChallengeShort)) }
            return
        }
        store.clearTracedConstellation(outcome.path, snapshot: outcome.snapshot, generation: outcome.generation)
        // Commit synchronously first; effects never choose or delay the cleared set.

    }
    func accessibleTrace(_ cell: Cell) {
        if trace.snapshot == nil {
            _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path.isEmpty ? [cell] : trace.path + [cell]))
        } else {
            _ = trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path.isEmpty ? [cell] : trace.path + [cell]))
        }
        if trace.snapshot != nil {
            interaction.acquireHold(at: trace.path.first, using: store.beginConstellationHold)
        }
        refreshConstellation()
        store.announceTraceSelection(count: trace.count, value: trace.value,
                                     ready: store.game.constellationCells(along: trace.path) != nil,
                                     generation: store.constellationInputGeneration,
                                     holdTicket: interaction.holdTicket)
    }
}

private enum SkyMenuDestination: Identifiable {
    case game, welcome
    var id: Self { self }
}
