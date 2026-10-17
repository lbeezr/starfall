import SwiftUI
import StarfallCore

/// Navigation is presentation state; the Codable sky remains authoritative for outcomes.
enum SkyFlowScreen: Equatable {
    case welcome, entry, playing, won, full

    static func initial(arguments: [String] = ProcessInfo.processInfo.arguments) -> Self {
        #if DEBUG
        // Preserve reset-only native board fixtures. Flow acceptance uses the real
        // welcome route with --sky-flow-review; ordinary Debug/Release opens Welcome.
        if arguments.contains("--starfalls-reset"), !arguments.contains("--sky-flow-review") { return .playing }
        #endif
        return .welcome
    }
}
enum SkyFlowAction: Equatable { case start, firstLight, begin, resume, replay, another, home, preferences }

@MainActor struct SkyFlowCeremony: View {
    let screen: SkyFlowScreen
    let challenge: Bool
    let result: SkyResultSnapshot?
    let welcome: SkyWelcomeSnapshot
    let active: Bool
    let quiet: Bool
    let modal: Bool
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
    private var motionKey: String { "\(active)-\(quiet)" }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [StarfallTheme.Colors.skyTop.opacity(0.3), .clear,
                                        StarfallTheme.Colors.skyTop.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea().accessibilityHidden(true)
                if screen == .won && celebrating {
                    SkyCelebration(progress: burst).allowsHitTesting(false).accessibilityHidden(true)
                }
                ScrollView {
                    VStack(spacing: StarfallTheme.Spacing.section) {
                        heading
                        if textSize.isAccessibilitySize {
                            revealedActions
                            decorativeCast
                        } else {
                            Spacer(minLength: 0)
                            decorativeCast
                            if !terminal { Spacer(minLength: 0) }
                            revealedActions
                        }
                    }
                    .padding(StarfallTheme.Spacing.section)
                    .frame(maxWidth: StarfallTheme.Layout.menuWidth)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .accessibilityIdentifier("sky.flow.\(String(describing: screen))")
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

    private var decorativeCast: some View {
        cast.frame(height: SkyCastFormation.height(terminal: terminal)).clipped()
    }
    private var revealedActions: some View {
        actions
            .opacity(controls ? 1 : 0)
            .offset(y: controls || quiet ? 0 : 24)
            .allowsHitTesting(controls && active)
            .disabled(!controls || !active)
            .accessibilityHidden(!controls || !active)
    }

    private var heading: some View {
        VStack(spacing: StarfallTheme.Spacing.medium) {
            Text(kicker.uppercased())
                .font(StarfallTheme.Typography.skyCaption).tracking(2)
                .foregroundStyle(StarfallTheme.Colors.actionPrimary)
            Text(title)
                .font(StarfallTheme.Typography.display(size: terminal ? resultTitleSize : titleSize))
                .foregroundStyle(StarfallTheme.Ceremony.gold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(screen == .won ? "First Light complete" : screen == .full ? "This sky is full" : title)
                .accessibilityIdentifier(terminal ? "experiment.outcome" : "sky.title")
                .accessibilityValue(terminal ? "\(result?.scoreLabel ?? ""). \(screen == .full ? result?.reason ?? "" : "")" : "")
                .accessibilityFocused($headingFocused)
            Text(message).font(StarfallTheme.Typography.supporting)
                .accessibilityIdentifier(terminal ? "experiment.score" : "sky.subtitle")
                .accessibilityLabel(result?.scoreLabel ?? message)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if screen == .welcome, let summary = welcome.summary {
                Text(summary).font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sky.savedSummary")
            }
            if screen == .full, let result {
                Text(result.reason).font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("sky.result.reason")
            }
        }
        .multilineTextAlignment(.center)
        .shadow(color: StarfallTheme.Colors.skyTop, radius: 6)
        .padding(terminal ? StarfallTheme.Spacing.medium : 0)
        .background {
            if terminal {
                RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel).fill(StarfallTheme.Colors.skyTop.opacity(0.88))
            }
        }
    }

    private var kicker: String {
        switch screen {
        case .welcome: "Starfall"
        case .entry: challenge ? "First Light" : "An open sky"
        case .won: "First Light · complete"
        case .full: "A moment to begin again"
        case .playing: ""
        }
    }
    private var title: String {
        switch screen {
        case .welcome: "A sky of your own."
        case .entry: challenge ? "Gather a little light." : "Let the night in."
        case .won: "You lit the sky."
        case .full: "This sky is full."
        case .playing: ""
        }
    }
    private var message: String {
        switch screen {
        case .welcome: "A little wonder. A little room to breathe."
        case .entry: challenge ? "Collect 18 starlight before a column overflows." : "Clear connected matching stars worth 3 or more starlight."
        case .won, .full: result?.scoreLabel ?? "\(welcome.score) starlight"
        case .playing: ""
        }
    }

    private var cast: some View {
        GeometryReader { geometry in
            let formation = SkyCastFormation(width: geometry.size.width, terminal: terminal, welcome: screen == .welcome)
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
                if welcome.canContinue {
                    flowButton("Continue sky", action: .resume, id: "sky.resume", primary: true)
                }
                flowButton("Start a sky", action: .start, id: "sky.start", primary: !welcome.canContinue)
                if welcome.hasSavedSky && welcome.ended {
                    flowButton("View last sky", action: .resume, id: "sky.resume")
                }
                flowButton("Try First Light", action: .firstLight, id: "sky.firstLight")
                Button { action(.preferences) } label: {
                    Label("Settings & help", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                .accessibilityIdentifier("sky.preferences").accessibilityFocused($preferencesFocused)
            case .entry:
                Text(challenge ? "One small challenge" : "Automatic showers · pause anytime")
                    .font(StarfallTheme.Typography.title).foregroundStyle(StarfallTheme.Ceremony.gold)
                flowButton("Begin", action: .begin, id: "sky.begin", primary: true)
                flowButton("Back to Observatory", action: .home, id: "sky.home")
            case .won, .full:
                if screen == .won {
                    flowButton("Start another sky", action: .another, id: "experiment.new", primary: true)
                    flowButton("Play First Light again", action: .replay, id: "experiment.replay")
                } else {
                    flowButton(challenge ? "Try First Light again" : "Try this sky again", action: .replay, id: "experiment.replay", primary: true)
                    flowButton("Start a fresh sky", action: .another, id: "experiment.new")
                }
                flowButton("Back to Observatory", action: .home, id: "sky.home")
            case .playing: EmptyView()
            }
        }
        .padding(terminal || screen == .entry ? StarfallTheme.Spacing.large : 0)
        .background {
            if terminal || screen == .entry {
                RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel)
                    .fill(StarfallTheme.Colors.skyTop.opacity(0.97))
            }
        }
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
    @MainActor static func forSkyFlowApp() -> FallingSkyStore {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--sky-flow-review") {
            return FallingSkyStore(defaults: UserDefaults(suiteName: "Starfall.SkyFlowReview")!, arguments: arguments)
        }
        #endif
        return FallingSkyStore()
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
