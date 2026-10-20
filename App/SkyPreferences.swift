import SwiftUI
import StarfallCore

/// A value snapshot of selected Core rules. No store, save or clock side effects.
struct SkyHelpContext: Equatable {
    let criticalMass: Bool
    let pocketedDusk: Bool
    let duskRule: DuskRule
    let restorationChallenge: StarfallChallenge?
    var challenge: Bool { restorationChallenge != nil }
    let arranging: Bool
    let openingCascade: Bool
    let opalStorms: Bool

    init(game: FallingSky) {
        pocketedDusk = game.hasPocketedDusk
        criticalMass = game.hasCriticalMass; duskRule = game.duskRule
        arranging = game.supportsArrangingStars
        openingCascade = game.hasOpeningCascade
        restorationChallenge = game.challenge
        opalStorms = game.generation != .legacy
    }

    var lessons: [SkyLesson] { !arranging ? [] : SkyLesson.allCases.filter { $0 != .opal || opalStorms } }

    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> Self {
        switch entry {
        case .fresh: .init(game: .freshSurvival(seed: game.seed, balance: game.balance))
        case .firstLight: .init(game: FallingSky(challenge: .firstLight))
        case .ribbonCrossing: .init(game: FallingSky(challenge: .ribbonCrossing))
        case .kiteHarbor: .init(game: FallingSky(challenge: .kiteHarbor))
        case .seedMoon: .init(game: FallingSky(challenge: .seedMoon))
        case .silverPools: .init(game: FallingSky(challenge: .silverPools))
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
        SkyMenuSection(SkyCopy.text(.preferencesTitle)) {
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
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        NavigationStack {
            SkyMenuSurface {
                SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
                NavigationLink { SkyHowToPlay(context: context, done: done).toolbar { SkyMenuDone(done: done) } }
                    label: { SkyMenuRow(SkyCopy.text(.menuHelp), glyph: .help, disclosure: true) }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .accessibilityIdentifier("experiment.help")
            }
            .navigationTitle(SkyCopy.text(.menuSettings)).navigationBarTitleDisplayMode(.inline)
            .toolbar { SkyMenuDone(done: done) }
        }
        .tint(StarfallTheme.Colors.actionPrimary)
        .preferredColorScheme(.dark)
        .presentationBackground(StarfallTheme.Colors.skyTop)
        .presentationDetents(textSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationContentInteraction(.scrolls)
        .presentationDragIndicator(.visible)
    }
}

struct SkyMenuDone: ToolbarContent {
    let done: () -> Void
    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(SkyCopy.text(.actionDone), action: done)
                .font(StarfallTheme.Typography.action)
                .accessibilityIdentifier("experiment.done")
        }
    }
}

struct SkyHowToPlay: View {
    let context: SkyHelpContext
    let done: () -> Void
    var body: some View {
        SkyMenuSurface {
            SkyMenuSection(SkyCopy.text(.practiceTitle)) {
                NavigationLink { SkyTutorialView(done: done) } label: {
                    SkyMenuRow(SkyCopy.text(.practiceTitle), glyph: .tutorial, disclosure: true)
                }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .accessibilityIdentifier("sky.learn")
            }
            SkyMenuSection(SkyCopy.text(.helpTapTitle)) {
                Text(SkyCopy.text(.helpTap))
                Text(SkyCopy.text(.helpIdentity))
            }
            if context.criticalMass {
                SkyMenuSection(SkyCopy.text(.massTitle)) {
                    Text(SkyCopy.text(.massHelp))
                    Text(SkyCopy.text(.massHelpCollapse))
                    Text(SkyCopy.text(.massHelpValue))
                }
            }
            SkyMenuSection(SkyCopy.text(.helpTraceTitle)) {
                Text(SkyCopy.text(.helpTrace))
                Text(SkyCopy.text(.helpBranch))
                Text(SkyCopy.text(.helpAccessibleTrace))
            }
            SkyMenuSection(SkyCopy.text(.helpShowerTitle)) {
                if context.openingCascade { Text(SkyCopy.text(.helpOpening)) }
                Text(SkyCopy.text(.helpForecast))
                Text(SkyCopy.text(.helpGrowth))
            }
            if context.opalStorms {
                SkyMenuSection(SkyCopy.text(.helpOpalTitle)) {
                    Text(SkyCopy.text(.helpOpal))
                }
                SkyMenuSection(SkyCopy.text(.helpStormTitle)) {
                    Text(SkyCopy.text(.helpStorm))
                    Text(SkyCopy.text(.helpRetained))
                }
            }
            if !context.pocketedDusk && !context.challenge {
                SkyMenuSection(SkyCopy.text(.helpDuskTitle)) {
                    if context.duskRule == .legacy {
                        Text(SkyCopy.text(.helpDarkLegacy))
                    } else {
                        Text(SkyCopy.text(.helpDusk, values: ["feeds": String(context.duskRule.feedingShowers)]))
                        Text(SkyCopy.text(.helpDuskClear))
                    }
                }
            }
            SkyMenuSection(SkyCopy.text(.helpPauseTitle)) {
                Text(SkyCopy.text(.helpPause))
            }
            if context.arranging {
                SkyMenuSection(SkyCopy.text(.helpArrangeTitle)) {
                    Text(SkyCopy.text(.helpSwap))
                    Text(SkyCopy.text(.helpRecipe))
                    Text(SkyCopy.text(.helpRelay))
                }
            }
            SkyMenuSection(context.restorationChallenge?.helpTitle ?? SkyCopy.text(.helpChallengeTitle)) {
                Text(context.restorationChallenge?.helpText ?? SkyCopy.text(.helpChallenge))
            }
        }.navigationTitle(SkyCopy.text(.menuHelp))
    }
}

/// The authored treatment keeps the native toggle's value and accessibility semantics.
struct SkyPreferenceToggle: View {
    let title: String
    let symbol: String
    @Binding var value: Bool
    let identifier: String
    var body: some View {
        Toggle(isOn: $value) {
            HStack(spacing: StarfallTheme.Spacing.medium) {
                ObservatoryIcon(systemName: symbol, size: 20)
                    .foregroundStyle(StarfallTheme.Dialogue.brass)
                Text(title).fixedSize(horizontal: false, vertical: true)
            }
        }
            .toggleStyle(ObservatoryToggleStyle())
            .frame(minHeight: StarfallTheme.Layout.minimumTarget)
            .accessibilityIdentifier(identifier)
    }
}

/// One scrolling reading instrument shared by settings, help and balance.
/// The system sheet owns its bottom anchoring and the navigation bar owns Done.
struct SkyMenuSurface<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: StarfallTheme.Spacing.section) {
                content
            }
            .font(StarfallTheme.Typography.body)
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .frame(maxWidth: StarfallTheme.Layout.menuWidth, alignment: .leading)
            .observatoryReadingPanel()
            .padding(StarfallTheme.Spacing.small)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(StarfallTheme.Colors.skyTop)
        .toolbarBackground(StarfallTheme.Colors.skyTop, for: .navigationBar)
    }
}

struct SkyMenuSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.medium) {
            Text(title)
                .font(StarfallTheme.Typography.skyHeading)
                .foregroundStyle(StarfallTheme.Dialogue.brass)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SkyMenuRow: View {
    let title: String
    let glyph: ObservatoryGlyph
    var disclosure = false

    init(_ title: String, glyph: ObservatoryGlyph, disclosure: Bool = false) {
        self.title = title
        self.glyph = glyph
        self.disclosure = disclosure
    }

    var body: some View {
        HStack(spacing: StarfallTheme.Spacing.medium) {
            ObservatoryIcon(glyph, size: 20)
                .foregroundStyle(StarfallTheme.Dialogue.brass)
            Text(title).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: StarfallTheme.Spacing.small)
            if disclosure { ObservatoryIcon(.next, size: 16) }
        }
        .frame(maxWidth: .infinity, minHeight: StarfallTheme.Layout.minimumTarget, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}
