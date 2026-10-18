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
enum SkyFlowAction { case start, firstLight, begin, resume, replay, another, home }

@MainActor struct SkyFlowCeremony: View {
    let screen: SkyFlowScreen
    let challenge: Bool
    let score: Int
    let hasSavedSky: Bool
    let lastSkyEnded: Bool
    let active: Bool
    let quiet: Bool
    let action: (SkyFlowAction) -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = StarfallTheme.Ceremony.titleSize
    @State private var settled = false
    @State private var controls = false
    @State private var revealed = false
    @State private var burst: CGFloat = 0
    private var terminal: Bool { screen == .won || screen == .full }
    private var motionKey: String { "\(active)-\(quiet)" }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [StarfallTheme.Colors.skyTop.opacity(0.3), .clear,
                                        StarfallTheme.Colors.skyTop.opacity(0.85)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea().accessibilityHidden(true)
                ScrollView {
                    VStack(spacing: StarfallTheme.Spacing.section) {
                        heading
                        Spacer(minLength: 0)
                        cast
                            .frame(height: 220)
                            .clipped()
                        Spacer(minLength: 0)
                        actions
                            .opacity(controls ? 1 : 0)
                            .offset(y: controls || quiet ? 0 : 24)
                            .allowsHitTesting(controls && active)
                            .disabled(!controls || !active)
                            .accessibilityHidden(!controls || !active)
                    }
                    .padding(StarfallTheme.Spacing.section)
                    .frame(maxWidth: StarfallTheme.Layout.menuWidth)
                    .frame(minHeight: geometry.size.height, alignment: .center)
                    .frame(maxWidth: .infinity)
                }
                .scrollBounceBehavior(.basedOnSize)
                if screen == .won {
                    SkyCelebration(progress: burst).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
        }
        .accessibilityIdentifier("sky.flow.\(String(describing: screen))")
        .task(id: motionKey) { await reveal() }
        .onDisappear { revealed = true }
    }

    private var heading: some View {
        VStack(spacing: StarfallTheme.Spacing.medium) {
            Text(kicker.uppercased())
                .font(StarfallTheme.Typography.skyCaption).tracking(2)
                .foregroundStyle(StarfallTheme.Colors.actionPrimary)
            Text(title)
                .font(StarfallTheme.Typography.display(size: titleSize))
                .foregroundStyle(StarfallTheme.Ceremony.gold)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(screen == .won ? "First Light complete" : screen == .full ? "This sky is full" : title)
                .accessibilityIdentifier(terminal ? "experiment.outcome" : "sky.title")
            Text(message).font(StarfallTheme.Typography.supporting)
                .accessibilityIdentifier(terminal ? "experiment.score" : "sky.subtitle")
                .accessibilityLabel(terminal ? (challenge ? "\(score) of 18 starlight collected" : "\(score) starlight") : message)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.center)
        .shadow(color: StarfallTheme.Colors.skyTop, radius: 6)
    }

    private var kicker: String {
        switch screen {
        case .welcome: "The Observatory"
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
        case .entry: challenge ? "Gather 18 starlight before the sky fills." : "Clear matching stars. Make room for more."
        case .won: "\(score) starlight, gathered by you."
        case .full: "\(score) starlight gathered. Every sky tells a different story."
        case .playing: ""
        }
    }

    private var cast: some View {
        GeometryReader { geometry in
            let heroSize = min(geometry.size.width * 0.4, 132)
            ZStack {
                if screen == .won {
                    Circle().fill(StarfallTheme.Ceremony.gold.opacity(0.15))
                        .blur(radius: 22).frame(width: 180, height: 180)
                        .position(x: geometry.size.width * 0.5, y: 78)
                }
                castStar(.amber, side: heroSize, index: 0)
                    .position(x: geometry.size.width * 0.5, y: 72)
                castStar(.mint, side: 74, index: 1)
                    .position(x: geometry.size.width * 0.18, y: 134)
                castStar(.rose, side: 78, index: 2)
                    .position(x: geometry.size.width * 0.82, y: 113)
                if screen == .welcome || screen == .full {
                    castStar(.aqua, side: 72, index: 3)
                        .position(x: geometry.size.width * 0.5, y: 180)
                }
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
    private func castStar(_ kind: Jewel, side: CGFloat, index: Int) -> some View {
        Image(uiImage: StarCast.image(for: kind, expression: screen == .won ? .clearing : .idle))
            .resizable().scaledToFit().frame(width: side, height: side)
            .shadow(color: StarfallTheme.Colors.skyTop.opacity(0.4), radius: 8, y: 7)
            .offset(y: settled || quiet ? 0 : screen == .full ? -8 : -230)
            .rotationEffect(.degrees(settled || quiet || screen == .full ? 0 : -18))
            .opacity(settled || quiet || screen == .full ? 1 : 0)
            .animation(quiet ? nil : .spring(response: StarfallTheme.Ceremony.settleDuration, dampingFraction: 0.68)
                .delay(Double(index) * 0.065), value: settled)
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: StarfallTheme.Spacing.small) {
            switch screen {
            case .welcome:
                if hasSavedSky {
                    flowButton(lastSkyEnded ? "View last sky" : "Resume sky", action: .resume, id: "sky.resume", primary: true)
                }
                flowButton("Start a sky", action: .start, id: "sky.start", primary: !hasSavedSky)
                flowButton("Try First Light", action: .firstLight, id: "sky.firstLight")
                Text("Always here. Even offline.")
                    .font(StarfallTheme.Typography.skyCaption).foregroundStyle(StarfallTheme.Colors.textSecondary)
            case .entry:
                Text(challenge ? "One small challenge" : "No need to hurry")
                    .font(StarfallTheme.Typography.title).foregroundStyle(StarfallTheme.Ceremony.gold)
                flowButton("Begin", action: .begin, id: "sky.begin", primary: true)
                flowButton("Back to Observatory", action: .home, id: "sky.home")
            case .won, .full:
                if screen == .won {
                    flowButton("Start another sky", action: .another, id: "experiment.new", primary: true)
                    flowButton("Play First Light again", action: .replay, id: "experiment.replay")
                } else {
                    flowButton("Try this sky again", action: .replay, id: "experiment.replay", primary: true)
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
            withTransaction(transaction) { settled = true; controls = true; burst = 1; revealed = true }
            return
        }
        settled = true
        if terminal { controls = true }
        if screen == .won { withAnimation(.easeOut(duration: 1.2)) { burst = 1 } }
        do { try await Task.sleep(for: .seconds(StarfallTheme.Ceremony.actionsDelay)) }
        catch { return }
        guard !Task.isCancelled else { return }
        withAnimation(.easeOut(duration: 0.36)) { controls = true }
        revealed = true
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
