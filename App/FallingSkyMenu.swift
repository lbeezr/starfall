import SwiftUI
import StarfallCore

/// Settings receives value snapshots, bindings and narrow actions, never the store.
struct FallingSkyMenu: View {
    let paused: Bool
    let turns: Int
    let groups: Int
    let over: Bool
    let challenge: Bool
    let criticalMass: Bool
    let helpContext: SkyHelpContext
    let balance: StarfallBalance
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    let pause: () -> Void
    let restart: (Bool) -> Void
    let firstLight: () -> Void
    let observatory: () -> Void
    let setBalance: (StarfallBalance) -> Void
    let done: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if !over {
                        Button(action: pause) {
                            Label(paused ? (turns == 0 ? SkyCopy.text(.actionStart) : SkyCopy.text(.actionResume)) : SkyCopy.text(.actionPause),
                                  systemImage: paused ? "play.fill" : "pause.fill")
                        }.accessibilityIdentifier("experiment.pause")
                    }
                    Button { restart(true) } label: { Label(SkyCopy.text(.actionReplay), systemImage: "arrow.counterclockwise") }
                        .accessibilityIdentifier("experiment.replay")
                    Button { restart(false) } label: { Label(SkyCopy.text(.actionNew), systemImage: "sparkles") }
                        .accessibilityIdentifier("experiment.new")
                } header: { Text(SkyCopy.text(.menuObservatory)) } footer: {
                    Text(SkyCopy.text(.a11yBoardSummary, values: ["showers": String(turns), "groups": String(groups)]))
                        .accessibilityIdentifier("experiment.roundSummary")
                }
                Section {
                    Button(action: observatory) { Label(SkyCopy.text(.actionHome), systemImage: "moon.stars") }
                        .accessibilityIdentifier("sky.home")
                }
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                Section {
                    if !challenge {
                        NavigationLink { Form { balanceControls }.navigationTitle(SkyCopy.text(.menuBalance)).toolbar { dismissal } }
                            label: { Label(SkyCopy.text(.menuBalance), systemImage: "slider.horizontal.3") }
                            .accessibilityIdentifier("experiment.balance")
                        Button(action: firstLight) { Label(SkyCopy.text(.menuFirstLight), systemImage: "star.circle") }
                            .accessibilityHint(SkyCopy.text(.menuFirstLightHint))
                            .accessibilityIdentifier("experiment.challenge")
                    }
                    NavigationLink { SkyHowToPlay(context: helpContext).toolbar { dismissal } } label: { Label(SkyCopy.text(.menuHelp), systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("experiment.help")
                } header: { Text(SkyCopy.text(.menuExplore)) } footer: {
                    Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "dev.local")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("starfall.buildID")
                }
                #if DEBUG
                Section("Development") {
                    NavigationLink { SkyDialogueStudio().toolbar { dismissal } }
                        label: { Label("Dialogue studio", systemImage: "bubble.left.and.bubble.right") }
                        .accessibilityIdentifier("dialogue.studio.open")
                }
                #endif
            }
            .scrollContentBackground(.hidden)
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle(SkyCopy.text(.menuTitle)).navigationBarTitleDisplayMode(.inline)
            .toolbar { dismissal }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .presentationDetents([.large])
    }

    private var dismissal: some ToolbarContent { SkyMenuDone(done: done) }

    private var balanceControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(SkyCopy.text(.balanceTitle)).font(.headline).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                Text(SkyCopy.text(.balancePaceDescription))
                Picker(SkyCopy.text(.balancePace), selection: Binding(get: { balance.pace }, set: { setBalance(StarfallBalance(pace: $0, darkStars: balance.darkStars)) })) {
                    ForEach(StarfallBalance.Pace.allCases, id: \.self) { pace in
                        Text(pace.title).tag(pace)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.pace")
            }
            if !criticalMass {
                VStack(alignment: .leading, spacing: 8) {
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
        .font(.subheadline)
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
