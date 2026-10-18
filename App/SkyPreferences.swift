import SwiftUI
import StarfallCore

/// A value snapshot of selected Core rules. No store, save or clock side effects.
struct SkyHelpContext: Equatable {
    let criticalMass: Bool
    let pocketedDusk: Bool
    let duskRule: DuskRule
    let challenge: Bool
    let openingCascade: Bool
    let opalStorms: Bool

    init(game: FallingSky) {
        pocketedDusk = game.hasPocketedDusk
        criticalMass = game.hasCriticalMass; duskRule = game.duskRule
        challenge = game.challenge != nil; openingCascade = game.hasOpeningCascade
        opalStorms = game.generation != .legacy
    }

    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> Self {
        switch entry {
        case .fresh: .init(game: .freshSurvival(seed: game.seed, balance: game.balance))
        case .firstLight: .init(game: FallingSky(challenge: .firstLight))
        case .initial, .replay, nil: .init(game: game)
        }
    }
}

/// Both menu surfaces bind the existing preference owners; neither creates a store.
struct SkyFeelSection: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    var body: some View {
        Section(SkyCopy.text(.preferencesTitle)) {
            SkyPreferenceToggle(title: SkyCopy.text(.preferencesSound), symbol: "speaker.wave.2", value: $sound, identifier: "experiment.sound")
            SkyPreferenceToggle(title: SkyCopy.text(.preferencesHaptics), symbol: "waveform", value: $haptics, identifier: "experiment.haptics")
            SkyPreferenceToggle(title: SkyCopy.text(.preferencesCalm), symbol: "moon", value: $calm, identifier: "experiment.calm")
        }
    }
}

struct SkyWelcomePreferences: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    let context: SkyHelpContext
    let done: () -> Void
    var body: some View {
        NavigationStack {
            Form {
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                Section {
                    NavigationLink { SkyHowToPlay(context: context).toolbar { SkyMenuDone(done: done) } }
                        label: { Label(SkyCopy.text(.menuHelp), systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("experiment.help")
                }
            }
            .scrollContentBackground(.hidden).background(StarfallTheme.Colors.skyTop)
            .navigationTitle(SkyCopy.text(.menuSettings)).navigationBarTitleDisplayMode(.inline)
            .toolbar { SkyMenuDone(done: done) }
        }
        .tint(StarfallTheme.Colors.actionPrimary).presentationDetents([.large])
    }
}

struct SkyMenuDone: ToolbarContent {
    let done: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(SkyCopy.text(.actionDone), action: done).accessibilityIdentifier("experiment.done")
        }
    }
}

struct SkyHowToPlay: View {
    let context: SkyHelpContext
    var body: some View {
        List {
            Section(SkyCopy.text(.helpTapTitle)) {
                Text(SkyCopy.text(.helpTap))
                Text(SkyCopy.text(.helpIdentity))
            }
            if context.criticalMass {
                Section(SkyCopy.text(.massTitle)) {
                    Text(SkyCopy.text(.massHelp))
                    Text(SkyCopy.text(.massHelpCollapse))
                    Text(SkyCopy.text(.massHelpValue))
                }
            }
            Section(SkyCopy.text(.helpTraceTitle)) {
                Text(SkyCopy.text(.helpTrace))
                Text(SkyCopy.text(.helpBranch))
                Text(SkyCopy.text(.helpAccessibleTrace))
            }
            Section(SkyCopy.text(.helpShowerTitle)) {
                if context.openingCascade { Text(SkyCopy.text(.helpOpening)) }
                Text(SkyCopy.text(.helpForecast))
                Text(SkyCopy.text(.helpGrowth))
            }
            if context.opalStorms {
                Section(SkyCopy.text(.helpOpalTitle)) {
                    Text(SkyCopy.text(.helpOpal))
                }
                Section(SkyCopy.text(.helpStormTitle)) {
                    Text(SkyCopy.text(.helpStorm))
                    Text(SkyCopy.text(.helpRetained))
                }
            }
            if !context.pocketedDusk && !context.challenge {
                Section(SkyCopy.text(.helpDuskTitle)) {
                    if context.duskRule == .legacy {
                        Text(SkyCopy.text(.helpDarkLegacy))
                    } else {
                        Text(SkyCopy.text(.helpDusk, values: ["feeds": String(context.duskRule.feedingShowers)]))
                        Text(SkyCopy.text(.helpDuskClear))
                    }
                }
            }
            Section(SkyCopy.text(.helpPauseTitle)) {
                Text(SkyCopy.text(.helpPause))
            }
            if !context.challenge {
                Section(SkyCopy.text(.helpArrangeTitle)) {
                    Text(SkyCopy.text(.helpSwap))
                    Text(SkyCopy.text(.helpRecipe))
                    Text(SkyCopy.text(.helpRelay))
                }
            }
            Section(SkyCopy.text(.helpChallengeTitle)) {
                Text(SkyCopy.text(.helpChallenge))
            }
        }.navigationTitle(SkyCopy.text(.menuHelp))
    }
}

/// Large reading sizes get a whole native toggle row rather than a squeezed switch.
struct SkyPreferenceToggle: View {
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
