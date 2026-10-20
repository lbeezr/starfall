import SwiftUI
import StarfallCore

/// A value snapshot of selected Core rules. No store, save or clock side effects.
struct SkyHelpContext: Equatable {
    let criticalMass: Bool
    let pocketedDusk: Bool
    let duskRule: DuskRule
    let restorationChallenge: StarfallChallenge?
    let restorationHelp: String?
    let scaledPoints: Bool
    let automaticRecipes: Bool
    let manualClears: Bool
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
        restorationHelp = game.challengeHelpText
        scaledPoints = game.challengeRevision > 0
        automaticRecipes = game.supportsAutomaticRecipes
        manualClears = game.supportsManualClears
        opalStorms = game.generation != .legacy
    }

    var lessons: [SkyLesson] { !arranging ? [] : SkyLesson.allCases.filter { $0 != .opal || opalStorms } }

    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> Self {
        .init(game: entry?.previewGame(retaining: game) ?? game)
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

    var body: some View {
        NavigationStack {
            SkyPreferencesPage(sound: $sound, haptics: $haptics, calm: $calm,
                               context: context, done: done)
        }
        .skyMenuPresentation()
    }
}

/// The same preference rows are used before play and from the paused menu.
struct SkyPreferencesPage: View {
    @Binding var sound: Bool
    @Binding var haptics: Bool
    @Binding var calm: Bool
    let context: SkyHelpContext
    let done: () -> Void
    var back = false

    var body: some View {
        SkyMenuSurface(title: SkyCopy.text(.menuSettings), glyph: .settings, done: done, back: back) {
            SkyFeelSection(sound: $sound, haptics: $haptics, calm: $calm)
            SkyMenuRule()
            NavigationLink { SkyHowToPlay(context: context, done: done) } label: {
                SkyMenuRow(SkyCopy.text(.menuHelp), glyph: .help, disclosure: true)
            }
            .buttonStyle(StarfallButtonStyle(role: .quiet, expands: true))
            .accessibilityIdentifier("experiment.help")
        }
    }
}

/// Full-screen modal presentation owns focus and dismissal. The game owns its
/// scrim and instrument geometry, avoiding the system sheet's extra glass frame.
private struct SkyMenuPresentation: ViewModifier {
    @Environment(\.dynamicTypeSize) private var textSize

    func body(content: Content) -> some View {
        GeometryReader { viewport in
            content
                .frame(height: textSize.isAccessibilitySize ? viewport.size.height : min(540, viewport.size.height))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .background(Color.black.opacity(0.36).ignoresSafeArea())
        .tint(StarfallTheme.Colors.actionPrimary)
        .preferredColorScheme(.dark)
        .statusBarHidden()
        .presentationBackground(.clear)
    }
}

extension View {
    func skyMenuPresentation() -> some View { modifier(SkyMenuPresentation()) }

    @ViewBuilder func skyMenuNavigationBackground() -> some View {
        if #available(iOS 18.0, *) {
            containerBackground(.clear, for: .navigation)
        } else {
            background(Color.clear)
        }
    }
}

struct SkyHowToPlay: View {
    let context: SkyHelpContext
    let done: () -> Void
    var body: some View {
        SkyMenuSurface(title: SkyCopy.text(.menuHelp), glyph: .help, done: done, back: true) {
            SkyMenuSection(SkyCopy.text(.practiceTitle)) {
                NavigationLink { SkyTutorialView(done: done) } label: {
                    SkyMenuRow(SkyCopy.text(.practiceTitle), glyph: .tutorial, disclosure: true)
                }
                    .buttonStyle(StarfallButtonStyle(role: .quiet))
                    .accessibilityIdentifier("sky.learn")
                if !context.manualClears { Text(SkyCopy.text(.helpPracticeModes)) }
            }
            SkyMenuSection(SkyCopy.text(context.manualClears ? .helpTapTitle : .helpPatternsTitle)) {
                Text(SkyCopy.text(context.manualClears ? .helpTap : .helpPatternsControls))
                Text(SkyCopy.text(context.automaticRecipes ? .helpCascadeIdentity
                                  : context.scaledPoints ? .helpStoryIdentity : .helpIdentity))
            }
            if context.criticalMass {
                SkyMenuSection(SkyCopy.text(.massTitle)) {
                    Text(SkyCopy.text(.massHelp))
                    Text(SkyCopy.text(.massHelpCollapse))
                    Text(SkyCopy.text(.massHelpValue))
                }
            }
            if context.manualClears {
                SkyMenuSection(SkyCopy.text(.helpTraceTitle)) {
                    Text(SkyCopy.text(context.automaticRecipes ? .helpCascadeTrace : .helpTrace))
                    Text(SkyCopy.text(context.automaticRecipes ? .helpCascadeBranch : .helpBranch))
                    Text(SkyCopy.text(.helpAccessibleTrace))
                }
            }
            SkyMenuSection(SkyCopy.text(.helpShowerTitle)) {
                if context.automaticRecipes { Text(SkyCopy.text(.helpCascadeOpening)) }
                else if context.openingCascade { Text(SkyCopy.text(.helpOpening)) }
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
                    Text(SkyCopy.swapInstructions(manualClears: context.manualClears))
                    Text(SkyCopy.text(!context.manualClears ? .helpPatternsRecipe
                                      : context.automaticRecipes ? .helpCascadeRecipe : .helpRecipe))
                    Text(SkyCopy.text(context.automaticRecipes ? .helpCascadeChain : .helpRelay))
                }
            }
            SkyMenuSection(context.restorationChallenge?.helpTitle ?? SkyCopy.text(.helpChallengeTitle)) {
                Text(context.restorationHelp ?? FallingSky.freshChallenge(.firstLight).challengeHelpText ?? SkyCopy.text(.helpChallenge))
            }
        }
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

/// One reading instrument shared by menu, preferences, help and balance.
/// Header and dismissal stay reachable while only the body scrolls.
struct SkyMenuSurface<Content: View>: View {
    var title: String? = nil
    var glyph: ObservatoryGlyph = .settings
    var done: (() -> Void)? = nil
    var back = false
    var footerTitle: String? = nil
    var scrollsContent = true
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        VStack(spacing: 0) {
            if let title { header(title) }
            if scrollsContent {
                ScrollView { readingContent }
                    .scrollBounceBehavior(.basedOnSize)
            } else {
                readingContent
            }
            if let done {
                VStack(spacing: StarfallTheme.Spacing.small) {
                    SkyMenuRule()
                    Button(footerTitle ?? SkyCopy.text(.actionDone), action: done)
                        .buttonStyle(StarfallButtonStyle(role: .primary, expands: true))
                        .frame(minHeight: StarfallTheme.Layout.preferenceTarget)
                        .accessibilityIdentifier("experiment.done")
                }
                .padding(.horizontal, 32)
                .padding(.top, StarfallTheme.Spacing.small)
                .padding(.bottom, StarfallTheme.Spacing.section)
            }
        }
        .background { ObservatorySurface() }
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
        .padding(.horizontal, StarfallTheme.Spacing.small)
        .padding(.top, StarfallTheme.Spacing.small)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .toolbar(.hidden, for: .navigationBar)
        .skyMenuNavigationBackground()
    }

    private var readingContent: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.large) {
            content
        }
        .font(StarfallTheme.Typography.body)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 32)
        .padding(.vertical, StarfallTheme.Spacing.medium)
    }

    private func header(_ title: String) -> some View {
        VStack(spacing: StarfallTheme.Spacing.small) {
            HStack(alignment: .center, spacing: StarfallTheme.Spacing.small) {
                if back {
                    Button { dismiss() } label: { ObservatoryIcon(.back, size: 20) }
                        .buttonStyle(StarfallUtilityButtonStyle())
                        .frame(minWidth: StarfallTheme.Layout.preferenceTarget,
                               minHeight: StarfallTheme.Layout.preferenceTarget)
                        .accessibilityLabel(SkyCopy.text(.worldBack))
                        .accessibilityIdentifier("sky.menu.back")
                } else {
                    ObservatoryIcon(glyph, size: 24)
                        .foregroundStyle(StarfallTheme.Ceremony.gold)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(textSize.isAccessibilitySize ? StarfallTheme.Typography.skyHeading : StarfallTheme.Typography.title)
                    .foregroundStyle(StarfallTheme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("sky.menu.title")
                Spacer(minLength: 0)
            }
            SkyMenuRule()
        }
        .padding(.horizontal, 32)
        .padding(.top, StarfallTheme.Spacing.section)
        .padding(.bottom, StarfallTheme.Spacing.small)
    }
}

/// An engraved separator, never an additional card or touch target.
struct SkyMenuRule: View {
    var body: some View {
        Rectangle()
            .fill(StarfallTheme.Colors.outline.opacity(0.55))
            .frame(height: 1)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
    }
}

/// Selected choices remain visible and preserve native button semantics. Each
/// selection writes through the caller's existing binding, never a local copy.
struct SkyMenuChoiceGroup<Value: Hashable>: View {
    let title: String
    let options: [Value]
    @Binding var selection: Value
    let identifier: String
    let optionTitle: (Value) -> String
    let optionID: (Value) -> String
    var shortTitle: ((Value) -> String)? = nil
    @Environment(\.dynamicTypeSize) private var textSize
    private var vertical: Bool { textSize.isAccessibilitySize || options.count > 3 }

    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            Text(title)
                .font(StarfallTheme.Typography.skyHeading)
                .foregroundStyle(StarfallTheme.Ceremony.gold)
                .accessibilityAddTraits(.isHeader)
            Group {
                if vertical {
                    VStack(spacing: StarfallTheme.Spacing.small) { choices }
                } else {
                    HStack(alignment: .top, spacing: StarfallTheme.Spacing.small) { choices }
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(identifier)
        }
    }

    private var choices: some View {
        ForEach(options, id: \.self) { option in
            Button { selection = option } label: {
                Group {
                    if vertical {
                        HStack(spacing: StarfallTheme.Spacing.small) {
                            choiceLabel(option)
                            Spacer(minLength: 0)
                        }
                    } else {
                        VStack(spacing: StarfallTheme.Spacing.compact) { choiceLabel(option) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(StarfallButtonStyle(role: .compact, expands: true,
                                            showsCompactSurface: selection == option))
            .accessibilityLabel(optionTitle(option))
            .accessibilityAddTraits(selection == option ? .isSelected : [])
            .accessibilityIdentifier(identifier + "." + optionID(option))
        }
    }

    @ViewBuilder private func choiceLabel(_ option: Value) -> some View {
        ObservatoryIcon(.check, size: 16)
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .opacity(selection == option ? 1 : 0)
        Text(shortTitle?(option) ?? optionTitle(option))
            .font(StarfallTheme.Typography.supporting)
            .fixedSize(horizontal: false, vertical: true)
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
        .frame(maxWidth: .infinity, minHeight: StarfallTheme.Layout.preferenceTarget, alignment: .leading)
        .multilineTextAlignment(.leading)
    }
}
