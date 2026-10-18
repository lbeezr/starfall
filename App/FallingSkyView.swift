import SwiftUI
import SpriteKit
import StarfallCore

// Historical experiment.* accessibility IDs remain stable for automation and assistive clients.
@MainActor struct FallingSkyView: View {
    @State private var store: FallingSkyStore
    @State private var interaction = SkyInteractionSession()
    private var trace: ConstellationTraceIntent { interaction.trace }
    private var technique: SkyTechniqueIntent { interaction.technique }
    @State private var menu: SkyMenuDestination?
    private var settings: Bool { menu != nil }
    @State private var flow: SkyFlowState
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
            VStack(spacing: 0) {
                GeometryReader { safeViewport in
                    if largeText {
                        ScrollView {
                            VStack(spacing: StarfallTheme.Spacing.small) {
                                playfield(insets: safeViewport.safeAreaInsets, compact: safeViewport.size.height < 750, allowsIsland: false)
                                    .frame(height: safeViewport.size.height)
                                if !showingCeremony && !settings {
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
                                  allowsIsland: true)
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
        .onAppear { store.terminalSpeech = .ceremony; updateSuspension(); store.settlePresentation(); updateMotion() }
        .onDisappear { invalidateInteraction(); store.setSuspended(true); store.terminalSpeech = .feedback }
        .onChange(of: store.constellationInputGeneration) { invalidateInteraction() }
        .onChange(of: store.game) {
            interaction.reconcile(with: store.game, release: store.endConstellationHold)
            store.scene.clearConstellationTrace()
        }
        .onChange(of: store.canClear) { _, enabled in if !enabled { cancelConstellation() } }
        .onChange(of: store.isPaused) { cancelConstellation() }
        .onChange(of: scenePhase) { invalidateInteraction(); updateSuspension() }
        .onChange(of: settings) { technique.cancel(); finishHandoffIfReady(); updateSuspension() }
        .onChange(of: store.sceneReady) { finishHandoffIfReady(); updateSuspension() }
        .onChange(of: flow) { cancelConstellation(); technique.cancel(); updateSuspension() }
        .onChange(of: endingReady) { updateSuspension() }
        .onChange(of: reduceMotion) { updateMotion() }
        .onChange(of: voiceOver) { updateMotion() }
        .onChange(of: calmEffects) { updateMotion() }
        .onChange(of: technique.preview) { refreshTechnique() }
        .onChange(of: reduceMotion) { invalidateInteraction() }
        .task(id: handoffKey) { await presentHandoff() }
        .sheet(item: $menu, onDismiss: { if voiceOver && !showingCeremony { menuFocused = true } }) { destination in
            settingsView(destination)
        }
    }

    /// The terrace owns its complete canvas. At accessibility sizes the guide is
    /// a sibling below it, so text growth cannot cover projected stars or props.
    private func playfield(insets: EdgeInsets, compact: Bool, allowsIsland: Bool) -> some View {
        GeometryReader { viewport in
            let island = allowsIsland && usesIslandTimer(size: viewport.size, topInset: insets.top)
            let front = ObservatoryGeometry(size: viewport.size).frame(Cell(0, 0)).maxY
            let footerHeight = max(0, viewport.size.height - front - insets.bottom
                - 2 * StarfallTheme.Spacing.small)
            ZStack {
                board.allowsHitTesting(!settings && !showingCeremony)
                if !showingCeremony && !settings {
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        compactHeader(island: island)
                            .starlightAnchor(.header)
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
            .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                GeometryReader { proxy in
                    if !settings, !showingCeremony, let receipt = store.celebration,
                       let board = anchors[.board], let score = anchors[.score], let header = anchors[.header] {
                        StarlightCelebrationOverlay(event: receipt, board: proxy[board], score: proxy[score], header: proxy[header], quiet: quietMotion)
                            .id(receipt.id)
                    }
                }.allowsHitTesting(false)
            }
            .accessibilityHidden(settings || showingCeremony)
        }
    }

    @ViewBuilder private func guide(compact: Bool, maximumHeight: CGFloat? = nil) -> some View {
        if !store.game.isOver {
            SkyDialogueOverlay(session: store.dialogue,
                               pausedLine: store.isPaused ? store.pausedGuideLine : nil,
                               active: scenePhase == .active && !settings && !showingCeremony,
                               next: store.nextDialogue, maximumHeight: maximumHeight) {
                controlLayout {
                    Button(store.game.turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) { store.togglePause() }
                        .disabled(store.suspended).accessibilityIdentifier("experiment.pause")
                    if !largeText { Spacer(minLength: 0) }
                    Button(SkyCopy.text(.actionNext)) { store.callShower() }
                        .disabled(store.busy || store.suspended).accessibilityIdentifier("experiment.next")
                }.buttonStyle(StarfallGameButtonStyle())
            }
            .padding(.trailing, largeText ? 0 : StarfallTheme.Layout.guidePropClearance)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func updateMotion() { store.setReducedMotion(reduceMotion || calmEffects || voiceOver) }

    private func compactHeader(island: Bool) -> some View {
        let quiet = quietMotion
        let celebrating = store.celebration != nil
        return HStack(spacing: StarfallTheme.Spacing.small) {
            HStack(spacing: StarfallTheme.Spacing.compact) {
                Image(systemName: "sparkle").foregroundStyle(StarfallTheme.Observatory.lanternGlow).accessibilityHidden(true)
                Text(store.game.challenge.map { "\(store.game.score) / \($0.target)" } ?? "\(store.game.score)")
                    .font(StarfallTheme.Typography.gameTitle).monospacedDigit()
                    .accessibilityLabel(store.game.challenge.map { SkyCopy.text(.resultChallengeScore, values: ["score": String(store.game.score), "target": String($0.target)]) } ?? SkyCopy.text(.welcomeScore, values: ["score": String(store.game.score)]))
                    .accessibilityIdentifier("experiment.score")
                    .accessibilityHint(SkyCopy.text(.a11yBoardHint, values: ["summary": boardSummary]))
            }
            .keyframeAnimator(initialValue: CGFloat(1), trigger: store.game.score) { content, scale in
                content.scaleEffect(quiet || !celebrating ? 1 : scale, anchor: .leading)
            } keyframes: { _ in
                LinearKeyframe(1, duration: 0.58)
                SpringKeyframe(1.14, duration: 0.12)
                CubicKeyframe(1, duration: 0.2)
            }
            .starlightAnchor(.score)
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
            .frame(minHeight: StarfallTheme.Layout.minimumTarget).allowsHitTesting(false)
            Spacer(minLength: 0)
            if !island { showerTrail(island: false) }
            Spacer(minLength: 0)
            Button { menu = .game } label: { SkyMenuGlyph() }
                .buttonStyle(StarfallGameButtonStyle())
                .disabled(scenePhase != .active || store.suspended)
                .accessibilityLabel(SkyCopy.text(.menuTitle)).accessibilityHint(SkyCopy.text(.menuHint))
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
                    ConstellationTraceSurface(size: geometry.size, enabled: !store.suspended && !store.game.isOver,
                                              generation: store.constellationInputGeneration,
                                              traceStart: { ConstellationTraceHitTesting.start(at: $0, mapping: mapping, game: store.game) },
                                              tap: tapBoardCell,
                                              begin: { beginConstellation($0, size: geometry.size) },
                                              move: { moveConstellation($0, size: geometry.size) },
                                              end: releaseConstellation, cancel: cancelConstellation,
                                              contact: { beginBoardContact($0, size: geometry.size) },
                                              feedback: store.explainInputFailure,
                                              hasSelectedNeighbor: { trace.count > 1 || technique.swapping },
                                              swapStart: { point in mapping.cell(at:point).map { store.game.canArrangeStars && store.game.gem(at:$0) != nil && store.canContact($0) } ?? false },
                                              beginSwap: { armDirectSwap($0,to:$1,generation:$2,size:geometry.size) },
                                              endSwap: { finishDirectSwap($0,size:geometry.size) })
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
            ForEach([-1, 1], id: \.self) { offset in
                let destination = Cell(cell.row, cell.column + offset)
                if snapshot.canNudge(from: cell, to: destination) {
                    Button(offset < 0 ? SkyCopy.text(.techniqueMoveLeft) : SkyCopy.text(.techniqueMoveRight)) {
                        cancelConstellation()
                        _ = store.performTechnique(.nudge(cell, destination), snapshot: snapshot, generation: generation)
                    }
                }
            }
        }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceAdd))) { accessibleTrace(cell) }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceRelease))) { releaseConstellation() }
        .accessibilityAction(named: Text(SkyCopy.text(.actionTraceCancel))) { cancelConstellation() }
        .accessibilityRotorEntry(id: cell, in: matchingGroups)
        .disabled(!store.canClear(cell) && !store.constellationTracing)
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
                           challenge: store.game.challenge != nil, criticalMass: store.game.hasCriticalMass, duskRule: store.game.duskRule, balance: store.game.balance,
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
    func tapBoardCell(_ cell: Cell) {
        cancelConstellation()
        store.clear(cell)
    }
    func refreshTechnique() {
        if technique.swapping { store.scene.showConstellationTrace(technique.preview, ready: true) }
    }

    func armDirectSwap(_ origin: CGPoint, to point: CGPoint, generation: UInt64, size: CGSize) -> Bool {
        let mapping=ObservatoryGeometry(size:size)
        guard store.constellationTracing, generation == store.constellationInputGeneration,
              let from=mapping.cell(at:origin), let to=mapping.cell(at:point),
              store.game.canNudge(from:from,to:to), store.canContact(from), store.canContact(to) else { return false }
        interaction.armSwap(from:from,to:to,game:store.game,generation:generation)
        refreshTechnique()
        store.traceStep(count:5)
        store.showInputFeedback(SkyCopy.text(.inputSwapReady))
        return technique.swapping
    }
    func finishDirectSwap(_ point: CGPoint, size: CGSize) {
        defer { cancelConstellation() }
        guard technique.swapping, let from=technique.anchor, let to=technique.swapDestination,
              ObservatoryGeometry(size:size).cell(at:point) != nil, let snapshot=technique.snapshot else { return }
        let generation=technique.generation
        technique.cancel()
        _ = store.performTechnique(.nudge(from,to),snapshot:snapshot,generation:generation)
    }
    func cancelConstellation() {
        interaction.cancelContact(release: store.endConstellationHold)
        store.scene.clearConstellationTrace()
    }
    func invalidateInteraction() {
        interaction.invalidate(release: store.endConstellationHold)
        store.scene.clearConstellationTrace()
    }
    func beginBoardContact(_ point: CGPoint, size: CGSize) -> Bool {
        cancelConstellation()
        guard let cell = ObservatoryGeometry(size: size).cell(at: point) else { return false }
        guard interaction.acquireHold(at: cell, using: store.beginConstellationHold) else {
            store.explainSettling(at: cell); return false
        }
        store.showInputFeedback(nil)
        store.scene.showContact(cell)
        return true
    }
    func beginConstellation(_ point: CGPoint, size: CGSize) {
        guard let cell = ConstellationTraceHitTesting.start(at: point, mapping: ObservatoryGeometry(size: size), game: store.game) else { return }
        _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canTrace([cell]))
        if trace.snapshot != nil {
            interaction.acquireHold(at: trace.path.first, using: store.beginConstellationHold)
        }
        trace.lastFinger = point
        refreshConstellation()
    }
    func moveConstellation(_ point: CGPoint, size: CGSize) {
        guard !technique.swapping else { return }
        guard trace.snapshot != nil else { return }
        let mapping = ObservatoryGeometry(size: size)
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
                // a different-family neighbor may yet arm a direct swap.
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
        technique.cancel()
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
