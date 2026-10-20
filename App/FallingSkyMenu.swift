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

    var body: some View {
        NavigationStack {
            SkyMenuSurface {
                SkyMenuSection(challenge?.locationTitle ?? SkyCopy.text(.flowOpen)) {
                    if !over {
                        Button(action: pause) {
                            HStack(spacing: StarfallTheme.Spacing.small) {
                                ObservatoryIcon(paused ? .play : .pause, size: 20)
                                Text(paused ? (turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) : SkyCopy.text(.actionPause))
                            }
                        }
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .accessibilityIdentifier("experiment.pause")
                    }
                    Button { restart(true) } label: { SkyMenuRow(SkyCopy.text(.actionReplay), glyph: .replay) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("experiment.replay")
                    Button { restart(false) } label: { SkyMenuRow(SkyCopy.text(.actionNew), glyph: .freePlay) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("experiment.new")
                    Text(SkyCopy.text(.a11yBoardSummary, values: ["showers": String(turns), "groups": String(groups)]))
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("experiment.roundSummary")
                }
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                SkyMenuSection(SkyCopy.text(.menuExplore)) {
                    if challenge == nil {
                        NavigationLink { SkyMenuSurface { balanceControls }.navigationTitle(SkyCopy.text(.menuBalance)).toolbar { dismissal } }
                            label: { SkyMenuRow(SkyCopy.text(.menuBalance), glyph: .settings, disclosure: true) }
                            .buttonStyle(StarfallButtonStyle(role: .quiet))
                            .accessibilityIdentifier("experiment.balance")
                    }
                    Button(action: worldMap) { SkyMenuRow(SkyCopy.text(.worldTitle), glyph: .story, disclosure: true) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("sky.worldMap")
                    Button(action: learn) { SkyMenuRow(SkyCopy.text(.practiceTitle), glyph: .tutorial, disclosure: true) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("sky.learn")
                    NavigationLink { SkyHowToPlay(context: helpContext, done: done).toolbar { dismissal } } label: { SkyMenuRow(SkyCopy.text(.menuHelp), glyph: .help, disclosure: true) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("experiment.help")
                    Button(action: observatory) { SkyMenuRow(SkyCopy.text(.actionHome), glyph: .home) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("sky.home")
                }
                #if DEBUG
                SkyMenuSection("Development") {
                    NavigationLink { SkyDialogueStudio().toolbar { dismissal } }
                        label: { SkyMenuRow("Dialogue studio", glyph: .list, disclosure: true) }
                        .buttonStyle(StarfallButtonStyle(role: .quiet))
                        .accessibilityIdentifier("dialogue.studio.open")
                }
                #endif
                Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "dev.local")
                    .font(.caption).foregroundStyle(StarfallTheme.Colors.textSecondary)
                    .accessibilityIdentifier("starfall.buildID")
            }
            .navigationTitle(SkyCopy.text(.menuTitle)).navigationBarTitleDisplayMode(.inline)
            .toolbar { dismissal }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .preferredColorScheme(.dark)
        .presentationBackground(StarfallTheme.Colors.skyTop)
        .presentationDetents(textSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }

    private var dismissal: some ToolbarContent { SkyMenuDone(done: done) }

    private var balanceControls: some View {
        SkyMenuSection(SkyCopy.text(.balanceTitle)) {
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                Text(SkyCopy.text(.balancePaceDescription))
                Picker(SkyCopy.text(.balancePace), selection: Binding(get: { balance.pace }, set: { setBalance(StarfallBalance(pace: $0, darkStars: balance.darkStars)) })) {
                    ForEach(StarfallBalance.Pace.allCases, id: \.self) { pace in
                        Text(pace.title).tag(pace)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.pace")
            }
            if !helpContext.pocketedDusk {
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
                    Text(SkyCopy.text(.balanceDark))
                    Picker(SkyCopy.text(.balanceDark), selection: Binding(get: { balance.darkStars }, set: { setBalance(StarfallBalance(pace: balance.pace, darkStars: $0)) })) {
                        ForEach(StarfallBalance.DarkStarFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.title).tag(frequency)
                        }
                    }
                    .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.darkFrequency")
                }
                Text(balance.darkStars.detail)
                    .accessibilityIdentifier("experiment.balanceDetail")
            }
            Text(SkyCopy.text(.balanceExplanation))
            Button(SkyCopy.text(.balanceReset)) { setBalance(StarfallBalance()) }
                .buttonStyle(StarfallButtonStyle(role: .quiet))
                .disabled(balance == StarfallBalance())
                .accessibilityIdentifier("experiment.resetBalance")
        }
        .font(StarfallTheme.Typography.body)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension StarfallBalance.Pace {
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
