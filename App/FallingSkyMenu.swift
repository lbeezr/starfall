import SwiftUI
import StarfallCore

/// Settings receives value snapshots, bindings and narrow actions, never the store.
struct FallingSkyMenu: View {
    let paused: Bool
    let turns: Int
    let groups: Int
    let over: Bool
    let challenge: StarfallChallenge?
    let helpContext: SkyHelpContext
    let choiceSnapshot: FallingSky?
    let balance: StarfallBalance
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    let pause: () -> Void
    let restart: (Bool) -> Void
    let worldMap: () -> Void
    let learn: () -> Void
    let observatory: () -> Void
    let setBalance: (StarfallBalance) -> Void
    let done: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize

    init(paused: Bool, turns: Int, groups: Int, over: Bool, challenge: StarfallChallenge?,
         helpContext: SkyHelpContext, choiceSnapshot: FallingSky? = nil, balance: StarfallBalance,
         sound: Binding<Bool>, haptics: Binding<Bool>, calm: Binding<Bool>,
         pause: @escaping () -> Void, restart: @escaping (Bool) -> Void,
         worldMap: @escaping () -> Void, learn: @escaping () -> Void,
         observatory: @escaping () -> Void, setBalance: @escaping (StarfallBalance) -> Void,
         done: @escaping () -> Void) {
        self.paused = paused; self.turns = turns; self.groups = groups; self.over = over
        self.challenge = challenge; self.helpContext = helpContext; self.choiceSnapshot = choiceSnapshot
        self.balance = balance
        _sound = sound; _haptics = haptics; _calm = calm
        self.pause = pause; self.restart = restart; self.worldMap = worldMap; self.learn = learn
        self.observatory = observatory; self.setBalance = setBalance; self.done = done
    }

    var body: some View {
        NavigationStack {
            SkyMenuSurface(title: SkyCopy.text(.menuTitle), glyph: .pause, done: done,
                           footerTitle: SkyCopy.text(.actionReturn)) {
                SkyMenuSection(challenge?.locationTitle ?? SkyCopy.text(.flowOpen)) {
                    if helpContext.fullBoard {
                        Text(SkyCopy.text(.fullBoardMode))
                            .font(StarfallTheme.Typography.skyHeading)
                        Text(SkyCopy.text(.fullBoardPace))
                    }
                    if !over && !helpContext.fullBoard {
                        Button(action: pause) {
                            HStack(spacing: StarfallTheme.Spacing.small) {
                                ObservatoryIcon(paused ? .play : .pause, size: 20)
                                Text(paused ? (turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) : SkyCopy.text(.actionPause))
                            }
                        }
                        .buttonStyle(StarfallButtonStyle(role: .compact, expands: true))
                        .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
                        .accessibilityIdentifier("experiment.pause")
                    }
                    if textSize.isAccessibilitySize {
                        VStack(spacing: StarfallTheme.Spacing.small) { roundActions }
                    } else {
                        HStack(spacing: StarfallTheme.Spacing.small) { roundActions }
                    }
                    Text(SkyCopy.boardSummary(showers: turns, groups: groups, manualClears: helpContext.manualClears,
                                             automaticLineLength: helpContext.automaticLineLength, fullBoard: helpContext.fullBoard))
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("experiment.roundSummary")
                }
                SkyMenuRule()
                VStack(spacing: StarfallTheme.Spacing.compact) {
                    if let choiceSnapshot, SkyFullBoardChoiceAnalysis.supports(choiceSnapshot) {
                        NavigationLink {
                            SkyFullBoardChoicesView(game: choiceSnapshot, done: done)
                        } label: {
                            SkyMenuRow(SkyCopy.text(.fullBoardChoicesTitle), glyph: .help, disclosure: true)
                        }
                        .accessibilityIdentifier("fullBoard.choices.open")
                    }
                    NavigationLink {
                        SkyPreferencesPage(sound: $sound, haptics: $haptics, calm: $calm,
                                           context: helpContext, done: done, back: true)
                    } label: {
                        SkyMenuRow(SkyCopy.text(.menuSettings), glyph: .settings, disclosure: true)
                    }
                    .accessibilityIdentifier("experiment.preferences")
                    if challenge == nil {
                        NavigationLink {
                            SkyMenuSurface(title: SkyCopy.text(.menuBalance), glyph: .freePlay, done: done, back: true) {
                                balanceControls
                            }
                        } label: {
                            SkyMenuRow(SkyCopy.text(.menuBalance), glyph: .freePlay, disclosure: true)
                        }
                        .accessibilityIdentifier("experiment.balance")
                    }
                    Button(action: worldMap) { SkyMenuRow(SkyCopy.text(.worldTitle), glyph: .story, disclosure: true) }
                        .accessibilityIdentifier("sky.worldMap")
                    Button(action: learn) { SkyMenuRow(SkyCopy.text(.practiceTitle), glyph: .tutorial, disclosure: true) }
                        .accessibilityIdentifier("sky.learn")
                    NavigationLink { SkyHowToPlay(context: helpContext, done: done) } label: {
                        SkyMenuRow(SkyCopy.text(.menuHelp), glyph: .help, disclosure: true)
                    }
                    .accessibilityIdentifier("experiment.help")
                    Button(action: observatory) { SkyMenuRow(SkyCopy.text(.actionHome), glyph: .home) }
                        .accessibilityIdentifier("sky.home")
                }
                .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                #if DEBUG
                SkyMenuRule()
                NavigationLink {
                    SkyMenuSurface(title: "Dialogue studio", glyph: .list, done: done, back: true, scrollsContent: false) {
                        SkyDialogueStudio()
                    }
                } label: {
                    SkyMenuRow("Dialogue studio", glyph: .list, disclosure: true)
                }
                .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                .accessibilityIdentifier("dialogue.studio.open")
                #endif
                Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "dev.local")
                    .font(StarfallTheme.Typography.skyCaption).foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier("starfall.buildID")
            }
        }
        .skyMenuPresentation()
    }

    @ViewBuilder private var roundActions: some View {
        Button { restart(true) } label: {
            Label { Text(SkyCopy.text(.actionReplay)) } icon: { ObservatoryIcon(.replay, size: 18) }
        }
        .buttonStyle(StarfallButtonStyle(role: .compact, expands: true))
        .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
        .accessibilityIdentifier("experiment.replay")
        Button { restart(false) } label: {
            Label { Text(SkyCopy.text(.actionNew)) } icon: { ObservatoryIcon(.freePlay, size: 18) }
        }
        .buttonStyle(StarfallButtonStyle(role: .compact, expands: true))
        .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
        .accessibilityIdentifier("experiment.new")
    }

    private var balanceControls: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.large) {
            SkyMenuChoiceGroup(title: SkyCopy.text(.balancePace), options: StarfallBalance.Pace.allCases,
                               selection: Binding(get: { balance.pace }, set: { setBalance(StarfallBalance(pace: $0, darkStars: balance.darkStars)) }),
                               identifier: "experiment.pace", optionTitle: { $0.title }, optionID: { $0.interfaceID },
                               shortTitle: { $0.shortTitle })
            Text(balance.pace.title)
                .font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textPrimary)
                .accessibilityIdentifier("experiment.pace.summary")
            Text(SkyCopy.text(.balancePaceDescription))
                .font(StarfallTheme.Typography.supporting)
                .foregroundStyle(StarfallTheme.Colors.textSecondary)
            if !helpContext.pocketedDusk {
                SkyMenuRule()
                SkyMenuChoiceGroup(title: SkyCopy.text(.balanceDark), options: StarfallBalance.DarkStarFrequency.allCases,
                                   selection: Binding(get: { balance.darkStars }, set: { setBalance(StarfallBalance(pace: balance.pace, darkStars: $0)) }),
                                   identifier: "experiment.darkFrequency", optionTitle: { $0.title }, optionID: { $0.rawValue })
                Text(balance.darkStars.detail)
                    .font(StarfallTheme.Typography.supporting)
                    .foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier("experiment.balanceDetail")
            }
            SkyMenuRule()
            Text(SkyCopy.text(.balanceExplanation))
                .font(StarfallTheme.Typography.supporting)
                .fixedSize(horizontal: false, vertical: true)
            Button(SkyCopy.text(.balanceReset)) { setBalance(StarfallBalance()) }
                .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
                .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
                .disabled(balance == StarfallBalance())
                .accessibilityIdentifier("experiment.resetBalance")
        }
        .font(StarfallTheme.Typography.body)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension StarfallBalance.Pace {
    var shortTitle: String {
        switch self {
        case .gentle: SkyCopy.text(.balanceGentleShort)
        case .steady: SkyCopy.text(.balanceSteadyShort)
        case .brisk: SkyCopy.text(.balanceBriskShort)
        }
    }
    var interfaceID: String {
        switch self {
        case .gentle: "gentle"
        case .steady: "steady"
        case .brisk: "brisk"
        }
    }
    var title: String {
        switch self {
        case .gentle: SkyCopy.text(.balanceGentle)
        case .steady: SkyCopy.text(.balanceSteady)
        case .brisk: SkyCopy.text(.balanceBrisk)
        }
    }
}

private extension StarfallBalance.DarkStarFrequency {
    var title: String {
        switch self {
        case .none: SkyCopy.text(.balanceNone)
        case .occasional: SkyCopy.text(.balanceOccasional)
        case .regular: SkyCopy.text(.balanceRegular)
        case .frequent: SkyCopy.text(.balanceFrequent)
        }
    }
    var detail: String {
        guard let gap = showerGap else { return SkyCopy.text(.balanceNoDark) }
        return SkyCopy.text(.balanceDarkFrequency, values: ["minimum": String(gap.lowerBound), "maximum": String(gap.upperBound)])
    }
}
