import SwiftUI
import SpriteKit
import StarfallCore

// Historical experiment.* accessibility IDs remain stable for automation and assistive clients.
@MainActor struct FallingSkyView: View {
    private var tutorialExit: (() -> Void)?
    private var tutorialEndingAfter: SkyTutorial?
    @State private var store: FallingSkyStore
    @State private var interaction = SkyInteractionSession()
    private var trace: ConstellationTraceIntent { interaction.trace }
    @State private var menu: SkyMenuDestination?
    private var settings: Bool { menu != nil }
    @State private var flow: SkyFlowState
    // Map content is withdrawn during Entry/play; its presentation choice belongs
    // to this navigation lifetime rather than the recreated map subtree.
    @State private var worldMapList = false
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
    @Namespace private var matchingGroups

    init() {
        self.init(store: .forSkyFlowApp(), flow: SkyFlowState())
    }

    init(store: FallingSkyStore, flow: SkyFlowState, tutorialEndingAfter: SkyTutorial? = nil, tutorialExit: (() -> Void)? = nil) {
        self.tutorialEndingAfter = tutorialEndingAfter
        self.tutorialExit = tutorialExit
        _store = State(initialValue: store)
        _flow = State(initialValue: flow)
    }

    private var endingReady: Bool { store.tutorial == nil && flow.screen == .playing && store.game.isOver && !store.busy }
    private var ceremonyScreen: SkyFlowScreen? {
        if let handoff = flow.handoff { return handoff.source == .worldMap ? nil : handoff.source }
        if endingReady { return store.game.outcome == .won ? .won : .full }
        return flow.screen == .playing ? nil : flow.screen
    }
    private var showingCeremony: Bool { ceremonyScreen != nil }
    private var boardVisible: Bool { flow.screen == .playing }
    private var handoffKey: String { "\(flow.handoff?.id.description ?? "none")-\(scenePhase == .active)-\(quietMotion)" }
    private var entryChallenge: StarfallChallenge? {
        if let entry = flow.entry { return entry.selectedChallenge(replaying: store.game.challenge) }
        return store.game.challenge
    }
    private var quietMotion: Bool { reduceMotion || calmEffects || voiceOver }
    private var restoration: RestorationPresentation? {
        RestorationPresentation.selected(game: store.game, entry: flow.entry)
    }

    private func usesIslandTimer(size: CGSize, topInset: CGFloat) -> Bool {
        !store.game.usesFullBoardRefill && SkyShowerPlacement.usesIsland(hardware: SkyShowerPlacement.hardware, size: size,
                                     topInset: topInset, accessible: largeText || voiceOver)
    }

    var body: some View {
        lifecycleContent
        .alert(store.persistenceNotice?.title ?? "", isPresented: Binding(
            get: { store.persistenceNotice != nil && !settings },
            set: { if !$0 { store.dismissPersistenceNotice() } })) {
                Button(SkyCopy.text(.actionDone)) { store.dismissPersistenceNotice() }
            } message: {
                Text(store.persistenceNotice?.message ?? "")
            }
        .fullScreenCover(item: $menu, onDismiss: { if voiceOver && !showingCeremony { menuFocused = true } }) { destination in
            settingsView(destination)
        }
        .overlayPreferenceValue(StarlightAnchors.self) { anchors in
            GeometryReader { proxy in
                if !settings, !showingCeremony, let receipt = store.celebration,
                   let board = anchors[.board], let score = anchors[.score], let header = anchors[.header] {
                    StarlightCelebrationOverlay(event: receipt, board: proxy[board], score: proxy[score], header: proxy[header], quiet: quietMotion,
                                               lightDestination: anchors[.restorationLight].map { proxy[$0] },
                                               awardBounds: anchors[.award].map { proxy[$0] },
                                               constellationBounds: anchors[.constellationReturn].map { proxy[$0] },
                                               restorationChallenge: restoration?.challenge)
                        .id(receipt.id)
                }
            }.allowsHitTesting(false)
        }
    }

    /// Keep lifecycle observation separate from the scene expression for older compilers.
    private var lifecycleContent: some View {
        sceneContent
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
    }

    @ViewBuilder private var sceneContent: some View {
        if flow.screen == .worldMap {
            worldMap
        } else {
            gameContent
        }
    }

    /// The accessible award occupies the apron below the stars. Keep that
    /// reserve inside the clipped canvas before laying out the reading guide.
    static func readingCanvas(viewport: CGSize, accessible: Bool) -> (size: CGSize, visibleHeight: CGFloat) {
        let size = CGSize(width: viewport.width, height: max(900, viewport.height))
        return (size, LandingGeometry(size: size, largeHeader: accessible).accessibleCanvasEnd)
    }

    private var gameContent: some View {
        ZStack {
            SkyBackdrop().ignoresSafeArea()
            VStack(spacing: 0) {
                GeometryReader { safeViewport in
                    let canvasHeight = safeViewport.size.height + safeViewport.safeAreaInsets.top + safeViewport.safeAreaInsets.bottom
                    let landscape = safeViewport.size.width > canvasHeight
                    if store.tutorial != nil && !largeText && !landscape {
                        tutorialPlayfield(viewport: safeViewport.size)
                    } else if largeText || (landscape && canvasHeight < 700) || store.tutorial != nil {
                        // Reading-heavy layouts keep chrome at the viewport edge and
                        // give the unchanged star canvas its own scrollable space.
                        VStack(spacing: 0) {
                            if !showingCeremony && !settings {
                                edgeHeader(island: false)
                                    .padding(.horizontal, StarfallTheme.Spacing.medium)
                                    .padding(.top, StarfallTheme.Spacing.compact)
                                // Manual walks and automatic patterns share fixed
                                // protected sky outside the scrolling playfield.
                                Color.clear.frame(height: 80)
                                    .starlightAnchor(.constellationReturn)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false).accessibilityHidden(true)
                            }
                            GeometryReader { readingViewport in
                                ScrollView {
                                    let canvas = Self.readingCanvas(viewport: safeViewport.size, accessible: largeText)
                                    VStack(spacing: StarfallTheme.Spacing.small) {
                                        board(expanded: true, landscape: landscape)
                                            .frame(height: canvas.size.height)
                                            .frame(height: canvas.visibleHeight, alignment: .top).clipped()
                                            .allowsHitTesting(!settings && !showingCeremony)
                                            .accessibilityHidden(settings || showingCeremony)
                                        if !showingCeremony && !settings {
                                            guide(compact: false, maximumHeight: max(240, readingViewport.size.height - 2 * StarfallTheme.Spacing.medium))
                                                .padding(.horizontal, StarfallTheme.Spacing.medium)
                                                .padding(.bottom, StarfallTheme.Spacing.medium)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                }.scrollBounceBehavior(.basedOnSize)
                            }
                        }
                    } else {
                        playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750,
                                  allowsIsland: true, landscape: landscape).ignoresSafeArea()
                    }
                }
            }
            .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                if let ceremonyScreen {
                    GeometryReader { geometry in
                        let entryID = flow.entryID
                        SkyFlowCeremony(screen: ceremonyScreen,
                                        challenge: entryChallenge,
                                        entry: flow.entry,
                                        result: endingReady ? SkyResultSnapshot(game: store.game) : nil,
                                        onward: endingReady && store.hasSavedSky
                                            ? SkyOnwardSnapshot(game: store.game, journey: store.journey.journey) : nil,
                                        welcome: SkyWelcomeSnapshot(game: store.game, hasSavedSky: store.hasSavedSky, paused: store.isPaused),
                                        mastery: flow.entry.map {
                                            SkyMasterySnapshot.entry(request: $0, retainedRound: store.game, bestRecords: store.mastery.records)
                                        } ?? SkyMasterySnapshot.current(game: store.game, bestRecords: store.mastery.records, context: .result),
                                        finalLight: endingReady ? store.finalLight : nil,
                                        active: scenePhase == .active && flow.handoff == nil && !settings, quiet: quietMotion, modal: settings,
                                        restoredSceneryBounds: anchors[.restorationScenery].map { geometry[$0] },
                                        action: { handleFlowAction($0, entryID: entryID) })
                            // Ceremony owns inactive AX elements. An extra hidden(false)
                            // container here masks native child hit results on iPad.
                            .id(String(describing: ceremonyScreen))
                            .opacity(flow.handoff != nil && handoffLeaving ? 0 : 1)
                            .allowsHitTesting(flow.handoff == nil && !settings)
                    }
                }
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
                .observatoryReadingPanel()
                .accessibilityIdentifier("sky.preparing")
                .zIndex(2)
            }
        }
    }

    /// Practice keeps the lesson and its progression visible. Crop only unused
    /// scenery around the existing canvas; SpriteKit and native cells retain the
    /// exact same coordinate mapping and full-sized stars.
    private func tutorialPlayfield(viewport: CGSize) -> some View {
        let canvas = Self.readingCanvas(viewport: viewport, accessible: false).size
        let arena = LandingGeometry(size: canvas).arenaFrame
        // The pressure row uses space above the board. Give it one control row
        // from the reading shelf so the ceiling and top stars stay in view.
        let pressureClearance = store.pressureCue == nil ? 0 : StarfallTheme.Layout.minimumTarget
        let topClearance = SkyCeilingOverlay.topClearance
        let additionalCeilingSpace = max(0, topClearance - StarfallTheme.Spacing.medium)
        let awardHeight = StarfallTheme.Celebration.practiceBandHeight
        let readingHeight = max(128, min(260, viewport.height * 0.42) - pressureClearance - additionalCeilingSpace
                                - awardHeight - StarfallTheme.Spacing.small)
        return VStack(spacing: StarfallTheme.Spacing.small) {
            // Keep forecast reflow from moving the stars when the total grows.
            edgeHeader(island: false, stacked: true)
                .padding(.horizontal, StarfallTheme.Spacing.medium)
            Color.clear.frame(height: awardHeight)
                .starlightAnchor(.award)
                .starlightAnchor(.constellationReturn)
                .allowsHitTesting(false).accessibilityHidden(true)
            ScrollView {
                board(expanded: true, landscape: false)
                    .frame(height: canvas.height)
                    .offset(y: -max(0, arena.minY - topClearance))
                    .frame(height: arena.height + topClearance + StarfallTheme.Spacing.medium, alignment: .top)
                    .clipped()
            }
            .defaultScrollAnchor(.bottom)
            .scrollBounceBehavior(.basedOnSize)
            guide(compact: true, maximumHeight: readingHeight)
                .padding(.horizontal, StarfallTheme.Spacing.medium)
        }
        .padding(.vertical, StarfallTheme.Spacing.small)
    }

    /// Stars retain one centered mapping; interface placement follows the viewport.
    private func playfield(insets: EdgeInsets, compact: Bool, allowsIsland: Bool, landscape: Bool) -> some View {
        GeometryReader { viewport in
            let mapping = LandingGeometry(size: viewport.size)
            let island = allowsIsland && usesIslandTimer(size: viewport.size, topInset: insets.top)
            let readingHeight = max(80, viewport.size.height - mapping.arenaFrame.maxY - insets.bottom - 20)
            ZStack {
                board(expanded: false, landscape: landscape).allowsHitTesting(!settings && !showingCeremony)
                if !showingCeremony && !settings {
                    VStack(spacing: 0) {
                        edgeHeader(island: island)
                            .padding(.top, insets.top + StarfallTheme.Spacing.compact)
                        Spacer(minLength: 0)
                        guide(compact: compact, maximumHeight: readingHeight, narrow: viewport.size.width < 390)
                            .frame(maxWidth: StarfallTheme.Layout.menuWidth, alignment: .bottom)
                            .padding(.bottom, insets.bottom + StarfallTheme.Spacing.small)
                    }
                    .padding(.horizontal, StarfallTheme.Spacing.medium)
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

    private func edgeHeader(island: Bool, stacked: Bool = false) -> some View {
        VStack(spacing: StarfallTheme.Spacing.compact) {
            if largeText || stacked {
                stackedHeader(island: island)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StarfallTheme.Spacing.small) {
                        scoreLabel
                        Spacer(minLength: StarfallTheme.Spacing.small)
                        if !island { showerTrail(island: false) }
                        skyMenuButton
                    }
                    stackedHeader(island: island)
                }
            }
            if store.game.challenge == .firstLight || store.game.challenge == .ribbonCrossing {
                StarfallStatusText(text: SkyCopy.text(store.game.usesFullBoardRefill ? .fullBoardRefill : .fallingSkyMode))
                    .shadow(color: StarfallTheme.Colors.skyTop, radius: 2)
                    .accessibilityIdentifier(store.game.challenge == .ribbonCrossing ? "ribbon.mode" : "lantern.mode")
                    .allowsHitTesting(false)
            }
            if !store.game.isOver && !store.game.usesFullBoardRefill && !store.forecast.isEmpty {
                SkyForecastDestinations(forecast: store.forecast, arriving: store.showerCountdown.arriving)
                    .shadow(color: StarfallTheme.Colors.skyTop, radius: 2)
            }
            if let pressure = store.pressureCue {
                StarfallStatusText(text: pressure.text)
                    .shadow(color: StarfallTheme.Colors.skyTop, radius: 2)
                    .accessibilityIdentifier("sky.pressure")
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity)
        .starlightAnchor(.header)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sky.header")
    }

    private func stackedHeader(island: Bool) -> some View {
        VStack(spacing: StarfallTheme.Spacing.compact) {
            HStack(alignment: .top) {
                scoreLabel
                Spacer(minLength: StarfallTheme.Spacing.small)
                skyMenuButton
            }
            if !island { showerTrail(island: false, width: 160) }
        }
    }

    @ViewBuilder private func guide(compact: Bool, maximumHeight: CGFloat? = nil, narrow: Bool = false, externalControls: Bool = false) -> some View {
        if let run = store.tutorial {
            VStack(spacing: StarfallTheme.Spacing.medium) {
                let hasControls = run.showsPauseControl || run.showsShowerControl
                SkyTutorialGuide(run: run, constrained: maximumHeight != nil, endingAfter: tutorialEndingAfter,
                                 finalLight: store.finalLight, active: scenePhase == .active && !settings, quiet: quietMotion,
                                 retry: { store.loadTutorial(run.chapter) },
                                 next: { chapter in store.loadTutorial(chapter) }, exit: { tutorialExit?() })
                    .frame(height: maximumHeight.map {
                        max(128, $0 - (hasControls ? StarfallTheme.Layout.preferenceTarget + StarfallTheme.Spacing.medium : 0))
                    })
                if !externalControls && hasControls {
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            if run.showsPauseControl { pauseControl }
                            if run.showsShowerControl { showerControl }
                        }.fixedSize(horizontal: true, vertical: false)
                        VStack {
                            if run.showsPauseControl { pauseControl }
                            if run.showsShowerControl { showerControl }
                        }
                    }.buttonStyle(StarfallButtonStyle(role: .compact))
                }
            }
        } else if !store.game.isOver {
            SkyDialogueOverlay(session: store.dialogue,
                               pausedLine: store.isPaused ? store.pausedGuideLine : nil,
                               active: scenePhase == .active && !settings && !showingCeremony,
                               next: store.nextDialogue, maximumHeight: maximumHeight, compact: narrow,
                               embedded: false, externalControls: externalControls, embeddedInk: StarfallTheme.Colors.textPrimary) {
                if store.isPaused && !externalControls && !store.game.usesFullBoardRefill {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: StarfallTheme.Spacing.small) { pauseControl; showerControl }
                            .fixedSize(horizontal: true, vertical: false)
                        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) { pauseControl; showerControl }
                    }
                    .buttonStyle(StarfallButtonStyle(role: .compact))
                }
            }
        }
    }
    private var pauseControl: some View {
        Button { store.togglePause() } label: {
            HStack(spacing: StarfallTheme.Spacing.small) {
                ObservatoryIcon(store.isPaused ? .play : .pause, size: 16)
                Text(store.isPaused ? (store.game.turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) : SkyCopy.text(.actionPause))
            }
        }
            .disabled(store.suspended).accessibilityIdentifier("experiment.pause")
    }
    private var showerControl: some View {
        Button { store.callShower() } label: {
            HStack(spacing: StarfallTheme.Spacing.small) {
                ObservatoryIcon(.next, size: 16)
                Text(SkyCopy.text(.actionNext))
            }
        }
            .disabled(store.busy || store.suspended).accessibilityIdentifier("experiment.next")
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private var scoreLabel: some View {
        // Committed values update immediately. The displayed receipt's packet
        // arrival owns the decorative acknowledgement, including cancellation.
        SkyScoreInstrument(score: store.game.displayScore, target: store.game.displayTarget,
                               restorationLabel: restoration.map { $0.challenge.restorationLabel(progress: $0.progress) },
                               restorationIdentifier: restoration?.challenge.restorationIdentifier,
                               hint: SkyCopy.text(.a11yBoardHint, values: ["summary": boardSummary]))
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget).allowsHitTesting(false)
    }
    private var skyMenuButton: some View {
        Button { if let tutorialExit { tutorialExit() } else { menu = .game } } label: {
            ObservatoryIcon(tutorialExit == nil ? .pause : .close, size: 20)
        }
            .buttonStyle(StarfallUtilityButtonStyle())
            .disabled(scenePhase != .active || store.suspended)
            .accessibilityLabel(tutorialExit == nil ? SkyCopy.text(.menuTitle) : SkyCopy.text(.practiceExit))
            .accessibilityHint(SkyCopy.text(tutorialExit == nil ? .menuHint : .practiceExitHint))
            .accessibilityIdentifier("experiment.settings").accessibilityFocused($menuFocused)
    }

    @ViewBuilder private func showerTrail(island: Bool, width: CGFloat = StarfallTheme.Layout.showerTrailWidth) -> some View {
        if !store.game.usesFullBoardRefill {
            SkyShowerTrail(readCountdown: { store.showerCountdown },
                           quiet: quietMotion, island: island, width: width, forecast: store.forecast)
        }
    }

    /// A full-screen menu can detach the scene. Apply the player's pause choice
    /// synchronously, then restore suspension before dismissal; normal scene
    /// readiness admission owns restarting the clock.
    private func togglePauseFromMenu() {
        guard scenePhase == .active, flow.screen == .playing, !showingCeremony, !store.game.isOver else { return }
        store.setSuspended(false)
        store.togglePause()
        store.setSuspended(true)
        menu = nil
    }

    private func board(expanded: Bool, landscape: Bool) -> some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ZStack {
                    let scenery = restoration ?? RestorationPresentation(challenge: .firstLight,
                        progress: StarlightRestoration(score: 18, target: 18))
                    RestorationEnvironment(presentation: scenery,
                                           active: scenePhase == .active && !settings && store.persistenceNotice == nil,
                                           ambientActive: !showingCeremony && !store.isPaused,
                                           quiet: quietMotion || reduceTransparency, isTablet: UIDevice.current.userInterfaceIdiom == .pad,
                                           isLandscape: landscape,
                                           award: !settings && !showingCeremony && RestorationAwardResponse.supports(restoration?.challenge) ? store.celebration : nil,
                                           awardQuiet: quietMotion)
                        .id("\(scenery.challenge.rawValue).\(environmentGeneration)")
                    if environmentContrast == .increased || reduceTransparency {
                        Color.black.opacity(0.28).allowsHitTesting(false).accessibilityHidden(true)
                    }
                    SpriteView(scene: store.scene, options: [.allowsTransparency])
                        .opacity(boardVisible ? (endingReady ? 0.22 : 1) : 0)
                        .animation(quietMotion ? nil : .easeOut(duration: StarfallTheme.Ceremony.handoffDuration), value: boardVisible)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    let mapping = LandingGeometry(size: geometry.size)
                    if boardVisible && !endingReady {
                        SkyCeilingOverlay(game: store.game, mapping: mapping)
                            .accessibilityHidden(settings || showingCeremony)
                    }
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
                                              swap: commitDirectSwap,
                                              cancelDrawing: { trace.cancel(); store.scene.clearConstellationTrace() },
                                              drawingEnabled: store.game.supportsManualClears)
                    }
                }

            }
            .starlightAnchor(.board)
            // Keep the group unlabelled: a label here replaces leaf star labels
            // during touch exploration. Terrace context belongs to the score hint.
            .accessibilityElement(children: boardAccessible ? .contain : .ignore)
            .accessibilityValue(boardAccessible ? boardSummary : "")
            .accessibilityIdentifier(boardAccessible ? "experiment.board" : "")
            .modifier(MatchingGroupsRotor(enabled: boardAccessible && store.game.supportsManualClears,
                                          cells: store.game.supportsManualClears ? store.game.legalGroups.compactMap(\.first) : [],
                                          namespace: matchingGroups, label: cellLabel))
            .accessibilityHidden(!boardAccessible)
        }
    }

    private var boardAccessible: Bool { !settings && !showingCeremony }

    private var boardSummary: String {
        let summary = SkyCopy.boardSummary(showers: store.game.turns, groups: store.game.legalGroups.count,
                             manualClears: store.game.supportsManualClears, automaticLineLength: store.game.automaticLineLength,
                             fullBoard: store.game.usesFullBoardRefill)
        return store.busy ? summary + " " + SkyCopy.text(.statusSettling) : summary
    }

    private func cellButton(_ cell: Cell) -> some View {
        let group = store.game.supportsManualClears ? store.game.group(at: cell) : []
        let value = store.game.value(of: group)
        let reward = store.game.displayReward(of: group)
        let snapshot = store.game
        let generation = store.constellationInputGeneration
        return Button { tapBoardCell(cell) } label: {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(cellLabel(cell))
        .accessibilityValue(!store.game.supportsManualClears ? SkyCopy.text(.a11yPatternsValue)
            : store.game.gem(at: cell)?.isLight == true
            ? (store.game.isDrained(at: cell) ? SkyCopy.text(.a11yOrbDrained) : SkyCopy.text(.a11yOrb))
            : reward != value ? SkyCopy.text(.a11yGroupReward, values: ["value": String(value), "reward": reward.formatted()]) : SkyCopy.text(.a11yGroupValue, values: ["value": String(value)]))
        .accessibilityHint(!store.game.supportsManualClears ? SkyCopy.text(.a11yPatternsHint)
            : store.game.gem(at: cell)?.gravityKind == .hole
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
            if snapshot.supportsManualClears {
                Button(SkyCopy.text(.actionTraceAdd)) { accessibleTrace(cell) }
                Button(SkyCopy.text(.actionTraceRelease)) { releaseConstellation() }
                Button(SkyCopy.text(.actionTraceCancel)) { cancelConstellation() }
            }
        }
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canReceiveInput)
    }

    private func gravityConsequence(_ cell: Cell) -> String {
        guard let preview = store.game.gravityPreview(at: cell), let field = preview.orbit,
              store.game.orbit == nil else { return SkyCopy.text(.a11yNoHole) }
        let position = SkyCopy.boardPosition(field.center)
        return SkyCopy.text(.a11yHolePreview, values: ["position": SkyCopy.position(row: position.row, column: position.column), "count": String(field.slots.count)])
    }

    private func cellLabel(_ cell: Cell) -> String {
        let coordinate = SkyCopy.boardPosition(cell)
        let position = SkyCopy.position(row: coordinate.row, column: coordinate.column)
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
        return SkyCopy.text(.a11yStar, values: ["size": gem.grown ? SkyCopy.text(.a11yGrown) : "", "description": SkyPiece.description(for: .init(gem)), "position": position, "state": captive + shade + mass])
    }

    private func updateSuspension() {
        store.setSuspended(scenePhase != .active || settings || store.persistenceNotice != nil || showingCeremony || flow.handoff != nil || !store.sceneReady)
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
        if case .onward(let destination) = action {
            guard (try? flow.openOnward(destination, game: store.game, journey: store.journey.journey,
                                       hasSavedSky: store.hasSavedSky, terminalReady: endingReady,
                                       active: scenePhase == .active,
                                       modal: settings || store.persistenceNotice != nil,
                                       select: store.journey.select)) == true else { return }
            store.setSuspended(true)
            menu = nil
            return
        }
        let previousFlow = flow
        guard scenePhase == .active,
              let effect = flow.handle(action, hasSavedSky: store.hasSavedSky, entryID: entryID) else { return }
        switch effect {
        case .worldMap:
            store.setSuspended(true)
        case .tutorial:
            menu = .tutorial
            return
        case .modePractice(let chapter):
            menu = .practice(chapter)
            return
        case .preferences:
            menu = .welcome
            return
        case .staged, .home:
            store.setSuspended(true)
        case .began(let request):
            store.setSuspended(true)
            guard store.beginEntry(request) else {
                // Entry consumption is reversible when persistence retains the
                // prior winning receipt for an explicit retry.
                flow = previousFlow
                return
            }
            environmentGeneration += 1
        case .continued:
            // Returning to the board does not change the player's pause choice.
            updateSuspension()
        }
        menu = nil
    }

    private var worldMap: some View {
        WorldMapView(journey: store.journey.journey, list: $worldMapList, quiet: quietMotion || settings, recovered: store.journey.recovered,
                         accessible: !settings,
                         goal: WorldMapGoalSnapshot(journey: store.journey.journey,
                                                    retainedRound: store.hasSavedSky ? store.game : nil),
                           masteryRecords: store.mastery.records,
                         select: { location in try? store.journey.select(location) },
                         enter: { challenge in
                             guard let location = WorldLocation(rawValue: challenge.rawValue),
                                   store.journey.journey.canEnter(location) else { return }
                             handleFlowAction(challenge.flowAction)
                         }, resume: canResumeMapLocation ? { handleFlowAction(.resume) } : nil,
                         learn: { menu = .tutorial }, done: { handleFlowAction(.worldBack) })
    }

    private var canResumeMapLocation: Bool {
        store.hasSavedSky && !store.game.isOver && store.game.challenge != nil
            && store.journey.journey.selected.challenge == store.game.challenge
    }

    @ViewBuilder private func settingsView(_ destination: SkyMenuDestination) -> some View {
        switch destination {
        case .tutorial:
            SkyTutorialView(done: { menu = nil })
                .skyMenuPresentation()
        case .practice(let chapter):
            SkyTutorialView(initial: chapter, returnsAfterLesson: true, done: { menu = nil })
                .skyMenuPresentation()
        case .welcome:
            SkyWelcomePreferences(sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                                  context: .selected(game: store.game, entry: flow.entry), done: { menu = nil })
        case .game:
            FallingSkyMenu(paused: store.isPaused, turns: store.game.turns,
                           groups: store.game.legalGroups.count, over: store.game.isOver,
                           challenge: store.game.challenge, helpContext: .init(game: store.game),
                           choiceSnapshot: store.game.usesFullBoardRefill ? store.game : nil,
                           mastery: SkyMasterySnapshot.current(game: store.game, bestRecords: store.mastery.records, context: .progress),
                           balance: store.game.balance,
                           sound: $store.soundEnabled, haptics: $store.hapticsEnabled, calm: $calmEffects,
                           pause: togglePauseFromMenu,
                           restart: { same in handleFlowAction(same ? .replay : .another) },
                           worldMap: { handleFlowAction(.worldMap) }, learn: { menu = .tutorial },
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

private struct MatchingGroupsRotor: ViewModifier {
    let enabled: Bool
    let cells: [Cell]
    let namespace: Namespace.ID
    let label: (Cell) -> String

    @ViewBuilder func body(content: Content) -> some View {
        if enabled {
            content.accessibilityRotor(SkyCopy.text(.a11yMatchingGroups)) {
                ForEach(cells, id: \.self) { cell in
                    AccessibilityRotorEntry(Text(label(cell)), id: cell, in: namespace)
                }
            }
        } else {
            content
        }
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
        let previousCount = trace.count
        for cell in ConstellationTraceHitTesting.cells(from: previous, to: point, mapping: mapping, game: store.game) {
            if trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path + [cell])) {
                refreshConstellation()
            }
            if trace.snapshot == nil {
                // The physical contact still owns its clock hold until terminal delivery;
                // drawing never falls back to a swap or an ordinary tap.
                store.scene.clearConstellationTrace(); return
            }
        }
        // A coarse sample may cross several stars. Send one cue for its final selection.
        if trace.count > previousCount, let snapshot = trace.snapshot {
            store.traceStep(path: trace.path, snapshot: snapshot, generation: trace.generation,
                            holdTicket: interaction.holdTicket)
        }
        trace.lastFinger = point
        store.scene.moveConstellationTip(point)
    }
    func refreshConstellation() {
        store.scene.showConstellationTrace(trace.path, ready: store.game.constellationCells(along:trace.path) != nil,
                                          source: trace.snapshot)
        if trace.count > 0 {
            let ready = store.game.constellationCells(along: trace.path) != nil
            let value = store.game.displayReward(of: Set(trace.path))
            store.showInputFeedback(ready ? SkyCopy.text(.inputTraceReady, values: ["count": String(trace.count), "score": value.formatted()]) : SkyCopy.text(.inputTraceProgress, values: ["count": String(trace.count)]))
        }
    }
    func releaseConstellation() {
        let hadTrace = trace.snapshot != nil
        let outcome = trace.finish(ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace(trace.path))
        store.scene.clearConstellationTrace()
        let hold = interaction.holdTicket
        defer { interaction.endContact(ticket: hold, release: store.endConstellationHold) }
        guard let outcome else {
            if hadTrace { store.explainInputFailure(SkyCopy.text(store.game.supportsArrangingStars ? .inputTraceShort : .inputTraceChallengeShort)) }
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

private enum SkyMenuDestination: Hashable, Identifiable {
    case game, welcome, tutorial
    case practice(SkyTutorial)
    var id: Self { self }
}
