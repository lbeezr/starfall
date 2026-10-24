import SwiftUI
import StarfallCore

/// Navigation is presentation state; the Codable sky remains authoritative for outcomes.
enum SkyFlowScreen: Equatable {
    case welcome, entry, playing, won, full, worldMap

    static func initial(arguments: [String] = ProcessInfo.processInfo.arguments) -> Self {
        #if DEBUG
        if WorldMapReviewFixture.requested(arguments: arguments) != nil { return .worldMap }
        // Preserve reset-only native board fixtures. Flow acceptance uses the real
        // welcome route with --sky-flow-review; ordinary Debug/Release opens Welcome.
        if arguments.contains("--starfalls-reset"), !arguments.contains("--sky-flow-review") { return .playing }
        #endif
        return .welcome
    }
}
enum SkyFlowAction: Equatable {
    case start, firstLight, fullBoardLantern, ribbonCrossing, fullBoardRibbon, kiteHarbor, seedMoon, silverPools, frostfruitOrchard, sunwheelMill
    case begin, entryBack, resume, replay, another, home, preferences, worldMap, worldBack, tutorial, modePractice
    case onward(WorldLocation)
}

@MainActor struct SkyFlowCeremony: View {
    let screen: SkyFlowScreen
    let challenge: StarfallChallenge?
    let entry: SkyEntryRequest?
    let result: SkyResultSnapshot?
    let onward: SkyOnwardSnapshot?
    let welcome: SkyWelcomeSnapshot
    var mastery: SkyMasterySnapshot? = nil
    var finalLight: SkyFinalLightReceipt? = nil
    var scoreExplanation: SkyScoreExplanation? = nil
    var survivorCount: Int = 0
    let active: Bool
    let quiet: Bool
    let modal: Bool
    let restoredSceneryBounds: CGRect?
    let action: (SkyFlowAction) -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = StarfallTheme.Ceremony.titleSize
    @ScaledMetric(relativeTo: .largeTitle) private var resultTitleSize = StarfallTheme.Ceremony.resultTitleSize
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @AccessibilityFocusState private var headingFocused: Bool
    @AccessibilityFocusState private var preferencesFocused: Bool
    @State private var focusedOnEntry = false
    @State private var settled = false
    @State private var controls = false
    @State private var revealed = false
    @State private var burst: CGFloat = 0
    @State private var celebrating = true
    private var terminal: Bool { screen == .won || screen == .full }
    var visibleFinalLight: SkyFinalLightReceipt? { terminal ? finalLight : nil }
    private var motionKey: String { "\(active)-\(quiet)" }

    var body: some View {
        GeometryReader { geometry in
            let layout = SkyCeremonyLayout(screen: screen, challenge: challenge,
                                           safeAreaTop: geometry.safeAreaInsets.top,
                                           restoredSceneryBounds: restoredSceneryBounds)
            ZStack {
                LinearGradient(colors: [StarfallTheme.Colors.skyTop.opacity(0.3), .clear,
                                        StarfallTheme.Colors.skyTop.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea().accessibilityHidden(true)
                if screen == .won && celebrating {
                    SkyCelebration(progress: burst).allowsHitTesting(false).accessibilityHidden(true)
                }
                if screen == .welcome {
                    observatoryHome(height: geometry.size.height)
                } else if terminal {
                    resultPresentation(layout: layout)
                } else {
                    VStack(spacing: 0) {
                        if screen == .entry { entryNavigation }
                        ScrollView {
                            VStack(spacing: layout.spacing) {
                                if layout.isRestoredResult {
                                    Spacer(minLength: layout.minimumTopSpace)
                                }
                                heading().accessibilityHidden(!active)
                                if textSize.isAccessibilitySize {
                                    revealedActions
                                    decorativeCast
                                } else {
                                    if !layout.isRestoredResult { Spacer(minLength: 0) }
                                    decorativeCast
                                    if !terminal { Spacer(minLength: 0) }
                                    revealedActions
                                }
                            }
                            .padding(StarfallTheme.Spacing.section)
                            .frame(maxWidth: StarfallTheme.Layout.menuWidth)
                            .frame(minHeight: max(0, geometry.size.height - StarfallTheme.Spacing.section
                                - (screen == .entry ? StarfallTheme.Layout.gameplayTarget + StarfallTheme.Spacing.small : 0)), alignment: .center)
                            .frame(maxWidth: .infinity)
                        }
                        .safeAreaPadding(.bottom, StarfallTheme.Spacing.section)
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
            }
        }
        // Child controls own identifiers. A GeometryReader identifier propagates
        // into icon-only buttons and replaces their explicit Settings/Back IDs.
        .task(id: motionKey) { await reveal() }
        .onDisappear { revealed = true }
        .onChange(of: modal) { old, new in
            if old && !new && voiceOver {
                if screen == .welcome { preferencesFocused = true } else { headingFocused = true }
            }
        }
        .task(id: active) {
            guard active, voiceOver, !focusedOnEntry else { return }
            focusedOnEntry = true
            await Task.yield()
            guard !Task.isCancelled else { return }
            headingFocused = true
        }
    }

    /// Preserve the restored vista when it fits, then yield decorative space
    /// before asking the player to scroll any full-sized result actions.
    private func resultPresentation(layout: SkyCeremonyLayout) -> some View {
        ViewThatFits(in: .vertical) {
            resultContent(layout: layout, compact: false)
                .fixedSize(horizontal: false, vertical: true)
            resultContent(layout: layout, compact: true)
                .fixedSize(horizontal: false, vertical: true)
            ScrollView {
                resultContent(layout: layout, compact: true)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .safeAreaPadding(.bottom, StarfallTheme.Spacing.section)
    }

    private func resultContent(layout: SkyCeremonyLayout, compact: Bool) -> some View {
        VStack(spacing: layout.spacing) {
            if layout.isRestoredResult && !compact {
                Color.clear.frame(height: layout.minimumTopSpace).accessibilityHidden(true)
            }
            heading().accessibilityHidden(!active)
            revealedActions
            if !compact && visibleFinalLight == nil { decorativeCast }
        }
        .padding(StarfallTheme.Spacing.section)
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
        .frame(maxWidth: .infinity)
    }

    /// Home is navigation in the world, not a character's dialogue bubble.
    /// Only the existing flow actions can stage or resume a retained round.
    private func observatoryHome(height: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                preferencesUtility
            }
            .padding(.horizontal, StarfallTheme.Spacing.page)
            .padding(.top, StarfallTheme.Spacing.small)
            ScrollView {
                VStack(spacing: StarfallTheme.Spacing.section) {
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        Text(SkyCopy.text(.flowBrand))
                            .font(textSize.isAccessibilitySize ? StarfallTheme.Typography.title : StarfallTheme.Typography.display(size: titleSize))
                            .foregroundStyle(StarfallTheme.Colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityLabel(SkyCopy.text(.flowWelcome))
                            .accessibilityIdentifier("sky.title")
                            .accessibilityFocused($headingFocused)
                        Text(SkyCopy.text(.homeObservatory))
                            .font(StarfallTheme.Typography.skyHeading)
                            .foregroundStyle(StarfallTheme.Ceremony.gold)
                    }
                    .multilineTextAlignment(.center)
                    .shadow(color: StarfallTheme.Colors.skyTop, radius: 5)
                    if !textSize.isAccessibilitySize {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            cast(compact: true)
                                .frame(height: SkyCastFormation.height(terminal: true))
                                .clipped()
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: SkyCastFormation.height(terminal: true))
                    }
                    VStack(spacing: StarfallTheme.Spacing.medium) {
                        modeButton(.story, title: SkyCopy.text(.homeStoryMode), promise: SkyCopy.text(.homeStoryPromise), action: .worldMap, id: "sky.worldMap")
                        modeButton(.freePlay, title: SkyCopy.text(.homeFreePlay), promise: SkyCopy.text(.homeOpenPromise), action: .start, id: "sky.start")
                        modeButton(.tutorial, title: SkyCopy.text(.homeTutorial), action: .tutorial, id: "sky.learn")
                    }
                    if let summary = welcome.summary {
                        VStack(spacing: StarfallTheme.Spacing.compact) {
                            Button { action(.resume) } label: {
                                HStack(spacing: StarfallTheme.Spacing.small) {
                                    ObservatoryIcon(welcome.ended ? .replay : .play, size: 20)
                                    Text(SkyCopy.text(welcome.ended ? .actionViewLast : .actionContinue))
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: StarfallTheme.Spacing.small)
                                    ObservatoryIcon(.next, size: 16)
                                }
                            }
                            .buttonStyle(StarfallButtonStyle(role: .compact, expands: true))
                            .accessibilityIdentifier("sky.resume")
                            Text(summary)
                                .font(StarfallTheme.Typography.supporting)
                                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.center)
                                .accessibilityIdentifier("sky.subtitle")
                        }
                    }
                }
                .frame(maxWidth: StarfallTheme.Layout.menuWidth)
                .padding(.horizontal, StarfallTheme.Spacing.section)
                .padding(.top, StarfallTheme.Spacing.medium)
                .padding(.bottom, StarfallTheme.Spacing.section)
                .frame(minHeight: max(0, height - 68), alignment: .bottom)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .allowsHitTesting(active)
        .disabled(!active)
        .accessibilityHidden(!active)
    }

    private func modeButton(_ mode: ObservatoryMode, title: String, promise: String? = nil, action choice: SkyFlowAction, id: String) -> some View {
        Button { action(choice) } label: {
            VStack(spacing: StarfallTheme.Spacing.compact) {
                ObservatoryModeLabel(mode: mode, title: title)
                if let promise {
                    Text(promise)
                        .font(StarfallTheme.Typography.supporting)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(StarfallButtonStyle(role: .ceremonyPrimary, expands: true))
        .accessibilityLabel(title)
        .accessibilityHint(promise ?? "")
        .accessibilityIdentifier(id)
    }

    private var preferencesUtility: some View {
        Button { action(.preferences) } label: { ObservatoryIcon(.settings) }
            .buttonStyle(StarfallUtilityButtonStyle())
            .accessibilityLabel(SkyCopy.text(.menuSettings))
            .accessibilityIdentifier("sky.preferences")
            .accessibilityFocused($preferencesFocused)
    }

    private var entryNavigation: some View {
        HStack {
            Button { action(.entryBack) } label: { ObservatoryIcon(.back) }
                .buttonStyle(StarfallUtilityButtonStyle())
                .accessibilityLabel(SkyCopy.text(.worldBack))
                .accessibilityIdentifier("sky.home")
            Spacer(minLength: 0)
            preferencesUtility
        }
        .padding(.horizontal, StarfallTheme.Spacing.page)
        .padding(.top, StarfallTheme.Spacing.small)
    }

    private var decorativeCast: some View {
        cast().frame(height: SkyCastFormation.height(terminal: terminal || screen == .entry)).clipped()
    }

    /// Result copy stays readable over the retained board and bright scenery.
    /// This fitted surface does not alter the painting or playable star layer.
    @ViewBuilder private func terminalReadingSurface<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if terminal {
            content().starfallPanel(inset: StarfallTheme.Spacing.medium)
        } else {
            content()
        }
    }

    private var revealedActions: some View {
        terminalReadingSurface {
            VStack(spacing: StarfallTheme.Spacing.large) {
                Text(dialogueLine.text)
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(dialogueLine.spokenText)
                    .accessibilityIdentifier(terminal ? "experiment.score" : "sky.subtitle")
                if let mastery, screen == .entry || screen == .won {
                    SkyMasteryView(snapshot: mastery)
                }
                if terminal, let scoreExplanation {
                    SkyScoreExplanationView(explanation: scoreExplanation, survivorCount: survivorCount)
                }
                if let visibleFinalLight {
                    SkyFinalLightView(receipt: visibleFinalLight, active: active, quiet: quiet)
                }
                actions
            }
        }
            .padding(.horizontal, StarfallTheme.Spacing.small)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 5)
            .opacity(controls ? 1 : 0)
            .offset(y: controls || quiet ? 0 : 24)
            .allowsHitTesting(controls && active)
            .disabled(!controls || !active)
            .accessibilityHidden(!controls || !active)
    }

    private func heading() -> some View {
        terminalReadingSurface {
            VStack(spacing: StarfallTheme.Spacing.medium) {
                Text(kicker)
                    .font(StarfallTheme.Typography.skyCaption).tracking(2)
                    .foregroundStyle(StarfallTheme.Colors.actionPrimary)
                Text(title)
                    .font(textSize.isAccessibilitySize ? StarfallTheme.Typography.title
                        : StarfallTheme.Typography.display(size: terminal ? resultTitleSize : titleSize))
                    .foregroundStyle(StarfallTheme.Ceremony.gold)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityLabel(title)
                    .accessibilityIdentifier(terminal ? "experiment.outcome" : "sky.title")
                    .accessibilityValue(terminal ? "\(result?.scoreLabel ?? ""). \(screen == .full ? result?.reason ?? "" : "")" : "")
                    .accessibilityFocused($headingFocused)
            }
            .multilineTextAlignment(.center)
            .shadow(color: StarfallTheme.Colors.skyTop, radius: 6)
        }
    }

    private var kicker: String {
        switch screen {
        case .welcome: SkyCopy.text(.flowBrand)
        case .entry: challenge?.entryKicker ?? SkyCopy.text(.flowOpen)
        case .won: challenge?.completionKicker ?? SkyCopy.text(.flowComplete)
        case .full: SkyCopy.text(.flowRoundOver)
        case .playing, .worldMap: ""
        }
    }
    private var title: String {
        switch screen {
        case .welcome: SkyCopy.text(.flowWelcome)
        case .entry: challenge?.locationTitle ?? SkyCopy.text(.flowEntry)
        case .won: challenge?.restoredTitle ?? SkyCopy.text(.flowWon)
        case .full: SkyCopy.text(.flowFull)
        case .playing, .worldMap: ""
        }
    }
    private var dialogueLine: SkyDialogueLine {
        switch screen {
        case .welcome:
            SkyDialogueLibrary.line("ceremony.welcome", values: ["summary": welcome.summary ?? ""])
        case .entry:
            (entry ?? .initial).introduction(challenge: challenge, replayingRevision: welcome.challengeRevision,
                                            replayingTarget: welcome.target)
        case .won, .full:
            SkyDialogueLibrary.line(screen == .won ? "ceremony.result" : "ceremony.full", values: ["score": result?.scoreLabel ?? SkyCopy.text(.resultScore, values: ["score": SkyCopy.score(welcome.score)]), "reason": result?.reason ?? ""])
        case .playing, .worldMap: SkyDialogueLibrary.line("guide.opening")
        }
    }

    private func cast(compact: Bool = false) -> some View {
        GeometryReader { geometry in
            let formation = SkyCastFormation(width: geometry.size.width,
                                             terminal: compact || terminal || screen == .entry,
                                             welcome: screen == .welcome && !compact)
            ZStack {
                if screen == .won, let hero = formation.stars.first {
                    Circle().fill(StarfallTheme.Ceremony.gold.opacity(0.15))
                        .blur(radius: 22).frame(width: 80, height: 80)
                        .position(hero.center)
                }
                ForEach(Array(formation.stars.enumerated()), id: \.offset) { index, star in
                    castStar(star, index: index).position(star.center)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
    private func castStar(_ star: SkyCastFormation.Star, index: Int) -> some View {
        let pose = star.pose(progress: settled || quiet ? 1 : 0)
        return Image(uiImage: StarCast.image(for: .init(kind: star.kind), expression: screen == .won ? .clearing : .idle))
            .resizable().scaledToFit().frame(width: star.side, height: star.side)
            .shadow(color: StarfallTheme.Colors.skyTop.opacity(0.4), radius: 8, y: 7)
            .scaleEffect(pose.scale)
            .rotationEffect(.radians(pose.rotation))
            .offset(y: pose.offset)
            .opacity(settled || quiet ? 1 : 0)
            .animation(quiet ? nil : .spring(response: StarfallTheme.Ceremony.settleDuration, dampingFraction: 0.68)
                .delay(Double(index) * 0.065), value: settled)
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: StarfallTheme.Spacing.small) {
            switch screen {
            case .welcome:
                EmptyView()
            case .entry:
                if let entry, !entry.modeChoices.isEmpty {
                    modeChoices(entry)
                }
                flowButton(SkyCopy.text(.actionBegin), action: .begin, id: "sky.begin", primary: true)
                if entry?.practiceChapter != nil {
                    flowButton(SkyCopy.text(.practiceTryMode), action: .modePractice, id: "sky.practiceMode")
                }
            case .won, .full:
                if screen == .won {
                    flowButton(onward?.label ?? SkyCopy.text(.worldReturn),
                               action: onward.map { SkyFlowAction.onward($0.destination) } ?? .worldMap,
                               id: "sky.worldMap", primary: true)
                } else if let challenge {
                    flowButton(challenge.replayLabel, action: .replay, id: "experiment.replay", primary: true)
                } else {
                    flowButton(SkyCopy.text(.actionNew), action: .another, id: "experiment.new", primary: true)
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: StarfallTheme.Spacing.small) {
                        resultSecondaryActions
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    VStack(spacing: StarfallTheme.Spacing.small) {
                        resultSecondaryActions
                    }
                }
                flowButton(SkyCopy.text(.actionHome), action: .home, id: "sky.home")
            case .playing, .worldMap: EmptyView()
            }
        }

    }

    private func modeChoices(_ selected: SkyEntryRequest) -> some View {
        let ribbon = selected.modeChallenge == .ribbonCrossing
        return SkyMenuChoiceGroup<SkyEntryRequest>(title: SkyCopy.text(ribbon ? .ribbonModeChoice : .lanternModeChoice),
            options: selected.modeChoices, selection: modeSelection(selected),
            identifier: ribbon ? "sky.ribbonMode" : "sky.lanternMode", optionTitle: modeTitle, optionID: modeID)
    }

    private func modeSelection(_ selected: SkyEntryRequest) -> Binding<SkyEntryRequest> {
        Binding(get: { entry ?? selected }, set: { choice in
            if let flowAction = choice.modeAction { action(flowAction) }
        })
    }

    private func modeTitle(_ choice: SkyEntryRequest) -> String {
        SkyCopy.text(choice.isFullBoardEntry ? .fullBoardMode : .fallingSkyMode)
    }

    private func modeID(_ choice: SkyEntryRequest) -> String {
        choice.isFullBoardEntry ? "fullBoard" : "fallingSky"
    }
    @ViewBuilder private var resultSecondaryActions: some View {
        if screen == .won {
            resultAction(SkyCopy.text(.actionNew), glyph: .freePlay, action: .another, id: "experiment.new")
            resultAction(challenge?.replayLabel ?? SkyCopy.text(.actionReplay), glyph: .replay, action: .replay, id: "experiment.replay")
        } else {
            if challenge == nil {
                resultAction(SkyCopy.text(.actionReplay), glyph: .replay, action: .replay, id: "experiment.replay")
            } else {
                resultAction(SkyCopy.text(.actionNew), glyph: .freePlay, action: .another, id: "experiment.new")
            }
            resultAction(SkyCopy.text(.worldReturn), glyph: .story, action: .worldMap, id: "sky.worldMap")
        }
    }
    private func resultAction(_ label: String, glyph: ObservatoryGlyph, action choice: SkyFlowAction, id: String) -> some View {
        Button { action(choice) } label: {
            HStack(spacing: StarfallTheme.Spacing.small) {
                ObservatoryIcon(glyph, size: 18)
                Text(label).fixedSize(horizontal: false, vertical: true)
            }
        }
        .buttonStyle(StarfallButtonStyle(role: .compact))
        .accessibilityIdentifier(id)
    }
    private func flowButton(_ label: String, action choice: SkyFlowAction, id: String, primary: Bool = false) -> some View {
        Button(label) { action(choice) }
            .buttonStyle(StarfallButtonStyle(role: primary ? .ceremonyPrimary : .quiet, expands: true))
            .accessibilityIdentifier(id)
    }

    /// The task belongs to this screen identity. It never mutates gameplay or starts a clock.
    private func reveal() async {
        if quiet || !active || revealed {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { settled = true; controls = true; burst = 1; celebrating = false; revealed = true }
            return
        }
        settled = true
        if terminal { controls = true }
        if screen == .won {
            withAnimation(.easeOut(duration: 1.2)) { burst = 1 }
        }
        do { try await Task.sleep(for: .seconds(StarfallTheme.Ceremony.actionsDelay)) }
        catch { return }
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.36)) { controls = true }
        revealed = true
        if celebrating {
            do { try await Task.sleep(for: .seconds(1.2 - StarfallTheme.Ceremony.actionsDelay)) }
            catch { return }
            celebrating = false
        }
    }
}

/// The scenery fills the safe area; the ceremony starts inside it. Keep the
/// restored landmark visible without tying clearance to a short scroll viewport.
struct SkyCeremonyLayout {
    let screen: SkyFlowScreen
    let challenge: StarfallChallenge?
    let safeAreaTop: CGFloat
    var restoredSceneryBounds: CGRect? = nil

    var isRestoredResult: Bool { screen == .won && challenge != nil }
    var spacing: CGFloat {
        isRestoredResult ? StarfallTheme.Spacing.medium : StarfallTheme.Spacing.section
    }
    var minimumTopSpace: CGFloat {
        guard isRestoredResult else { return 0 }
        let baseline = StarfallTheme.Ceremony.restoredSceneBottom - safeAreaTop
        // Anchors are already in ceremony coordinates, including the source
        // canvas's safe-area extension and any gameplay scroll offset.
        let scenicBottom = restoredSceneryBounds.map { $0.maxY + StarfallTheme.Spacing.medium } ?? baseline
        return max(0, max(baseline, scenicBottom) - StarfallTheme.Spacing.section - spacing)
    }
}

/// Finite analytic light burst, independent of the score and bounded to 28 sparks.
private struct SkyCelebration: View, Animatable {
    var progress: CGFloat
    var animatableData: CGFloat { get { progress } set { progress = newValue } }
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.42)
            for index in 0..<28 {
                let angle = Double(index) * 2.399
                let distance = progress * CGFloat(75 + index * 4)
                let x = center.x + cos(angle) * distance
                let y = center.y + sin(angle) * distance + progress * progress * 70
                let radius = CGFloat(index.isMultiple(of: 3) ? 3 : 1.5)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)),
                             with: .color(StarfallTheme.Ceremony.gold.opacity(Double(sin(progress * .pi)))))
            }
        }
    }
}


extension FallingSkyStore {
    @MainActor static func forSkyFlowApp(arguments: [String] = ProcessInfo.processInfo.arguments) -> FallingSkyStore {
        let defaults = SkyDefaults.forApp(arguments: arguments)
        #if DEBUG
        if let fixture = WorldMapReviewFixture.requested(arguments: arguments) {
            let reviewDefaults = try! fixture.prepareIsolatedDefaults()
            return FallingSkyStore(defaults: reviewDefaults, arguments: arguments.filter { $0 != "--starfalls-reset" })
        }
        if arguments.contains("--sky-flow-review"),
           !arguments.contains("--technique-review"), !arguments.contains("--dialogue-review"),
           !arguments.contains(WorldMapReviewFixture.marker),
           arguments.contains("--starfalls-reset") {
            // Fixture mutation belongs to store creation, never preference-domain selection.
            if arguments.contains("--save-rejection-review") {
                defaults.removePersistentDomain(forName: "Starfall.SkyFlowReview")
                defaults.set(Data("unreadable review save".utf8), forKey: SkySaveArchive.key)
                return FallingSkyStore(defaults: defaults, arguments: arguments.filter { $0 != "--starfalls-reset" })
            }
            if arguments.contains("--save-failure-review") {
                var failedOnce = false
                return FallingSkyStore(defaults: defaults, arguments: arguments, archiveWriter: { game, defaults in
                    if !failedOnce { failedOnce = true; throw SkySaveArchive.Failure.unsupportedOrInvalid }
                    try SkySaveArchive.save(game, to: defaults)
                })
            }
        }
        #endif
        return FallingSkyStore(defaults: defaults, arguments: arguments)
    }
}

/// The whole entrance stays inside its decorative region, including spring overshoot.
/// Positions and poses have one owner; text/actions never need an overflow exception.
struct SkyCastFormation {
    struct Star {
        let kind: Jewel
        let side: CGFloat
        let center: CGPoint
        let terminal: Bool
        struct Pose { let scale: CGFloat; let rotation: Double; let offset: CGFloat }
        func pose(progress: CGFloat) -> Pose {
            let initialScale: CGFloat = terminal ? 0.7 : 0.45
            return Pose(scale: initialScale + (1 - initialScale) * progress,
                        rotation: Double(1 - progress) * -.pi / 15,
                        offset: (terminal ? -8 : -20) * (1 - progress))
        }
    }
    let width: CGFloat
    let terminal: Bool
    let welcome: Bool
    static func height(terminal: Bool) -> CGFloat { terminal ? 110 : 250 }
    var stars: [Star] {
        let hero = min(width * 0.4, terminal ? 66 : 132)
        let mint: CGFloat = terminal ? 42 : 74, rose: CGFloat = terminal ? 44 : 78
        var values = [
            Star(kind: .amber, side: hero, center: CGPoint(x: width * 0.5, y: terminal ? 52 : 88), terminal: terminal),
            Star(kind: .mint, side: mint, center: CGPoint(x: max(width * 0.18, mint / 2 + 16), y: terminal ? 61 : 142), terminal: terminal),
            Star(kind: .rose, side: rose, center: CGPoint(x: min(width * 0.82, width - rose / 2 - 16), y: terminal ? 56 : 126), terminal: terminal)
        ]
        if welcome { values.append(Star(kind: .aqua, side: 72, center: CGPoint(x: width * 0.5, y: 188), terminal: terminal)) }
        return values
    }
}
