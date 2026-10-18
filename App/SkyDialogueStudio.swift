#if DEBUG
import SwiftUI

/// Author preview only: no store, clock, save, rule or external-service capability.
@MainActor struct SkyDialogueStudio: View {
    @State private var session = SkyDialogueSession()
    @State private var selected = "studio.cast"
    @State private var values: [String: String] = [:]
    @State private var contentError: String?
    private var catalog: SkyDialogueCatalog { SkyDialogueLibrary.catalog }
    private var tokens: [String] {
        let source = catalog.scripts.first { $0.id == selected }!
        return source.lines.reduce(into: Set<String>()) { $0.formUnion((try? SkyDialogueCatalog.placeholders(in: $1.text)) ?? []) }.sorted()
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.section) {
                Text("Character chat").font(StarfallTheme.Typography.title)
                Text("Preview the bundled scripts at the current text size. This does not change your sky.")
                    .font(StarfallTheme.Typography.supporting)
                Picker("Script", selection: $selected) {
                    ForEach(catalog.scripts) { script in Text(script.id).tag(script.id) }
                }
                .accessibilityIdentifier("dialogue.studio.script")
                ForEach(tokens, id: \.self) { key in
                    TextField(key, text: Binding(get: { values[key] ?? "" }, set: { values[key] = $0 }))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("dialogue.studio.value." + key)
                }
                if let contentError {
                    Text(contentError).foregroundStyle(StarfallTheme.Dialogue.ink)
                        .accessibilityIdentifier("dialogue.studio.error")
                }
                Button("Play script", action: play)
                    .accessibilityIdentifier("dialogue.studio.play")
                    .buttonStyle(StarfallButtonStyle(role: .primary))
                SkyDialogueOverlay(session: session, pausedLine: nil, active: true, next: session.next) { EmptyView() }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: StarfallTheme.Spacing.medium) {
                    ForEach(SkySpeaker.allCases, id: \.self) { speaker in
                        VStack {
                            SkyDialoguePortrait(speaker: speaker)
                            Text(speaker.name).font(StarfallTheme.Typography.skyCaption)
                        }
                    }
                }
            }
            .padding(StarfallTheme.Spacing.large)
        }
        .background(StarfallTheme.Colors.skyTop)
        .navigationTitle("Dialogue studio")
        .onAppear(perform: play)
    }
    private func play() {
        // Example facts only. Player-facing wording still comes from the catalogue.
        let defaults = ["score": "18", "dark": "Dusk", "growth": "A star grew", "arrival": "One star arrived",
                        "stars": "5", "feeds": "5", "depth": "2", "shape": "Square",
                        "release": "The hole releases its stars after 3 more showers.",
                        "swallowed": "I swallowed 3 stars.", "phase": "Storm: 3 heavy showers left.",
                        "cadence": "Showers are closer together now.", "summary": "Open sky · 0 starlight · Automatic showers paused",
                        "reason": "First Light complete!", "detail": "A star grew.", "context": "More time between showers now."]
        let substitutions = Dictionary(uniqueKeysWithValues: tokens.map { key in (key, values[key] ?? defaults[key] ?? key) })
        session.reset(); contentError = nil
        do { session.play(try catalog.script(selected, values: substitutions)) }
        catch { contentError = "Cannot preview \(selected): \(error)" }

    }
}
#endif
