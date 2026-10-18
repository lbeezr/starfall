import SwiftUI
import StarfallCore

/// Settings receives value snapshots, bindings and narrow actions, never the store.
struct FallingSkyMenu: View {
    let paused: Bool
    let turns: Int
    let groups: Int
    let over: Bool
    let challenge: Bool
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
                            Label(paused ? (turns == 0 ? "Start sky" : "Resume sky") : "Pause sky",
                                  systemImage: paused ? "play.fill" : "pause.fill")
                        }.accessibilityIdentifier("experiment.pause")
                    }
                    Button { restart(true) } label: { Label("Replay this sky", systemImage: "arrow.counterclockwise") }
                        .accessibilityIdentifier("experiment.replay")
                    Button { restart(false) } label: { Label("New sky", systemImage: "sparkles") }
                        .accessibilityIdentifier("experiment.new")
                } header: { Text("Moonlit Observatory") } footer: {
                    Text("\(turns) showers · \(groups) matching groups ready")
                        .accessibilityIdentifier("experiment.roundSummary")
                }
                Section {
                    Button(action: observatory) { Label("Back to Observatory", systemImage: "moon.stars") }
                        .accessibilityIdentifier("sky.home")
                }
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                Section {
                    if !challenge {
                        NavigationLink { Form { balanceControls }.navigationTitle("Sky balance").toolbar { dismissal } }
                            label: { Label("Sky balance", systemImage: "slider.horizontal.3") }
                            .accessibilityIdentifier("experiment.balance")
                        Button(action: firstLight) { Label("First Light · 18 starlight", systemImage: "star.circle") }
                            .accessibilityHint("Reviews First Light before you choose Begin")
                            .accessibilityIdentifier("experiment.challenge")
                    }
                    NavigationLink { SkyHowToPlay().toolbar { dismissal } } label: { Label("How to play", systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("experiment.help")
                } header: { Text("Explore") } footer: {
                    Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "dev.local")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("starfall.buildID")
                }
            }
            .scrollContentBackground(.hidden)
            .background(StarfallTheme.Colors.skyTop)
            .navigationTitle("Sky menu").navigationBarTitleDisplayMode(.inline)
            .toolbar { dismissal }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .presentationDetents([.large])
    }

    private var dismissal: some ToolbarContent { SkyMenuDone(done: done) }

    private var balanceControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try a balance").font(.headline).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                Text("Shower pace after the opening")
                Picker("Shower pace", selection: Binding(get: { balance.pace }, set: { setBalance(StarfallBalance(pace: $0, darkStars: balance.darkStars)) })) {
                    ForEach(StarfallBalance.Pace.allCases, id: \.self) { pace in
                        Text(pace.title).tag(pace)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.pace")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Dark stars")
                Picker("Dark stars", selection: Binding(get: { balance.darkStars }, set: { setBalance(StarfallBalance(pace: balance.pace, darkStars: $0)) })) {
                    ForEach(StarfallBalance.DarkStarFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.title).tag(frequency)
                    }
                }
                .pickerStyle(.menu).labelsHidden().accessibilityIdentifier("experiment.darkFrequency")
            }
            Text(balance.darkStars.detail)
                .accessibilityIdentifier("experiment.balanceDetail")
            Text("Changes keep your board and current preview. Existing dark stars stay. Replay this sky to start fresh with this balance.")
            Button("Reset balance") { setBalance(StarfallBalance()) }
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
        case .gentle: "Gentle · 6s"
        case .steady: "Steady · 4s"
        case .brisk: "Brisk · cycle"
        }
    }
}

private extension StarfallBalance.DarkStarFrequency {
    var title: String {
        switch self {
        case .none: "None"
        case .occasional: "Occasional"
        case .regular: "Regular"
        case .frequent: "Frequent"
        }
    }
    var detail: String {
        guard let gap = showerGap else { return "No new dark stars after the current preview." }
        return "One dark star every \(gap.lowerBound)–\(gap.upperBound) showers. A fresh sky starts with one in shower \(gap.upperBound)."
    }
}
