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
                Section("Build") {
                    Text(Bundle.main.object(forInfoDictionaryKey: "StarfallBuildID") as? String ?? "dev.local")
                        .font(.caption).foregroundStyle(.secondary)
                        .accessibilityIdentifier("starfall.buildID")
                }
                Section {
                    Button(action: observatory) { Label("Back to Observatory", systemImage: "moon.stars") }
                        .accessibilityIdentifier("sky.home")
                }
                Section("Feel & atmosphere") {
                    SkyPreferenceToggle(title: "Sound", symbol: "speaker.wave.2", value: $sound, identifier: "experiment.sound")
                    SkyPreferenceToggle(title: "Haptics", symbol: "waveform", value: $haptics, identifier: "experiment.haptics")
                    SkyPreferenceToggle(title: "Calm effects", symbol: "moon", value: $calm, identifier: "experiment.calm")
                }
                Section("Explore") {
                    if !challenge {
                        NavigationLink { Form { balanceControls }.navigationTitle("Sky balance").toolbar { dismissal } }
                            label: { Label("Sky balance", systemImage: "slider.horizontal.3") }
                            .accessibilityIdentifier("experiment.balance")
                        Button(action: firstLight) { Label("First Light · 18 starlight", systemImage: "star.circle") }
                            .accessibilityHint("Starts a new challenge, replacing this sky")
                            .accessibilityIdentifier("experiment.challenge")
                    }
                    NavigationLink { howToPlay.toolbar { dismissal } } label: { Label("How to play", systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("experiment.help")
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

    private var dismissal: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", action: done).accessibilityIdentifier("experiment.done")
        }
    }

    private var howToPlay: some View {
        List {
            Section("A little starlight") {
                Text("Tap ordinary matches worth three light. To draw a constellation, swipe through at least five distinct matching stars, each beside the last, including diagonals. Lift to release only the stars you traced. You may retrace your path to branch; a star counts once. Large stars count as one star and score two light. Lift before five or leave the board to cancel.")
                Text("A grown star beside one small match is enough. Each family has its own face and shape.")
            }
            Section("Follow the sky") {
                Text("The comet trail fills toward the next shower. Clear space before a column fills. Clearing never delays the sky.")
                Text("A matching arrival grows a small star. A grown star cannot grow again; the next star stacks above it.")
            }
            Section("Dark stars") {
                Text("Dark stars stop their four immediate neighbors from growing. Clear a matching group beside one to dissolve it. Dark stars award no starlight.")
            }
            Section("Take your time") {
                Text("Pause to clear at your pace, or call one shower with Next shower. The menu and leaving the app freeze the sky. Missed showers never accumulate.")
                Text("First Light is a short 18-starlight challenge with steady showers and no dark stars.")
            }
        }.navigationTitle("How to play")
    }

    private var balanceControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Try a balance").font(.headline).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 8) {
                Text("Shower pace")
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
        case .brisk: "Brisk · 3s"
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

/// Large reading sizes get a whole native toggle row rather than a squeezed switch.
private struct SkyPreferenceToggle: View {
    let title: String
    let symbol: String
    @Binding var value: Bool
    let identifier: String
    @Environment(\.dynamicTypeSize) private var size
    var body: some View {
        Group {
            if size.isAccessibilitySize {
                Toggle(isOn: $value) { Label(title, systemImage: symbol).frame(maxWidth: .infinity, alignment: .leading) }
                    .toggleStyle(.button)
            } else {
                Toggle(isOn: $value) { Label(title, systemImage: symbol) }.toggleStyle(.switch)
            }
        }.frame(minHeight: StarfallTheme.Layout.minimumTarget)
            .accessibilityIdentifier(identifier)
    }
}
