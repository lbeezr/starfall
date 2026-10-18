import SwiftUI

/// Both menu surfaces bind the existing preference owners; neither creates a store.
struct SkyFeelSection: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    var body: some View {
        Section("Feel & atmosphere") {
            SkyPreferenceToggle(title: "Sound", symbol: "speaker.wave.2", value: $sound, identifier: "experiment.sound")
            SkyPreferenceToggle(title: "Haptics", symbol: "waveform", value: $haptics, identifier: "experiment.haptics")
            SkyPreferenceToggle(title: "Calm effects", symbol: "moon", value: $calm, identifier: "experiment.calm")
        }
    }
}

struct SkyWelcomePreferences: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    let done: () -> Void
    var body: some View {
        NavigationStack {
            Form {
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                Section {
                    NavigationLink { SkyHowToPlay().toolbar { SkyMenuDone(done: done) } }
                        label: { Label("How to play", systemImage: "questionmark.circle") }
                        .accessibilityIdentifier("experiment.help")
                }
            }
            .scrollContentBackground(.hidden).background(StarfallTheme.Colors.skyTop)
            .navigationTitle("Settings & help").navigationBarTitleDisplayMode(.inline)
            .toolbar { SkyMenuDone(done: done) }
        }
        .tint(StarfallTheme.Colors.actionPrimary).presentationDetents([.large])
    }
}

struct SkyMenuDone: ToolbarContent {
    let done: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done", action: done).accessibilityIdentifier("experiment.done")
        }
    }
}

struct SkyHowToPlay: View {
    var body: some View {
        List {
            Section("A little starlight") {
                Text("Tap ordinary matches worth three light. To draw a constellation, swipe through at least five distinct matching stars, each beside the last, including diagonals. Lift to release only the stars you traced. You may retrace your path to branch; a star counts once. Large stars count as one star and score two light. Lift before five or leave the board to cancel.")
                Text("A grown star beside one small match is enough. Each family has its own face and shape.")
            }
            Section("Follow the sky") {
                Text("New skies open with a quick cascade. Start clearing as each wave settles; your selected shower pace follows the opening.")
                Text("The comet trail fills toward the next shower. Clear space before a column fills. Clearing never delays the sky.")
                Text("A matching arrival grows a small star. A grown star cannot grow again; the next star stacks above it.")
            }
            Section("Attraction and holes") {
                Text("Clear the space between two attraction fields to bring their forces together. The convergence forms a hole that holds up to four nearby colored stars. Each shower rotates those stars, opening new matches. Clear a group containing a captive to close the hole, or wait three windows for it to release them. Clear beside a lone magnet to dissolve it. Attraction and holes give no light; Opal stays free.")
            }
            Section("Opal Orb") {
                Text("The round white Opal Orb can join any one color. Start on a colored star, then include the orb in that color’s ordinary match or traced constellation. It is worth one light, never grows, and is spent when cleared. Other colors do not join the same clear.")
            }
            Section("Storms") {
                Text("Fresh skies alternate nine calmer showers with three heavier storm showers. The warning and remaining count follow the next shower. Clearing never delays a storm. Calmer skies can still fill a column.")
                Text("Saved older skies and their replays keep their original showers. Choose New sky to try Opals, storms and attraction fields.")
            }
            Section("Dark stars") {
                Text("Dark stars stop their four immediate neighbors from growing. Clear a matching group beside one to dissolve it. Dark stars award no starlight.")
            }
            Section("Take your time") {
                Text("Pause to clear at your pace, or call one shower with Next shower. The menu and leaving the app freeze the sky. Missed showers never accumulate.")
                Text("First Light is a short 18-starlight challenge with steady showers and no dark stars, Opals, attraction fields or storms.")
            }
        }.navigationTitle("How to play")
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
