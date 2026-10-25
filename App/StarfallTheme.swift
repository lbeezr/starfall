import SwiftUI
import UIKit

/// The shared presentation system. Rules and SpriteKit jewel materials have
/// separate owners; screens compose these roles rather than invent local tokens.
enum StarfallTheme {
    enum Dialogue {
        static let surface = Colors.surface
        static let enamelHighlight = Colors.surfacePressed
        static let enamelShade = Colors.skyTop
        static let brass = Colors.actionPrimary
        static let rimShade = Colors.outline
        static let contactShadow = Color(Observatory.contactShadow)
        static let shadowRadius: CGFloat = 5
        static let shadowDrop: CGFloat = 3
        static let ink = Colors.textPrimary
        static let portraitSide: CGFloat = 64
        static let portraitOverlap: CGFloat = 16
        static let corner: CGFloat = 24
    }
    enum Celebration {
        static let titleCapHeight: CGFloat = 50
        static let minimumGlyphCapHeight: CGFloat = 24
        // Two readable crystal lines plus the existing label/clip clearance.
        static let practiceBandHeight = minimumGlyphCapHeight * 2 + Spacing.large
    }
    enum Colors {
        static let launchBackground = Color("LaunchBackground")
        static let skyTop = Palette.midnight
        static let skyBottom = Palette.plum
        static let surface = Palette.nightglass
        static let surfacePressed = Palette.litNightglass
        static let outline = Palette.softBrass
        static let textPrimary = Palette.moonlight
        static let textSecondary = Palette.lavender
        static let textDisabled = Palette.mutedLavender
        static let actionPrimary = Palette.brass
        static let actionPrimaryPressed = Palette.softBrass
        static let onActionPrimary = Palette.midnight
        static let actionDisabled = Palette.litNightglass
        static let focus = Palette.moonlight
        static let progressFill = Palette.ice
        static let progressTrack = Palette.slate
        static let positiveStatus = Palette.ice
        static let ambientStar = Palette.moonlight
        static let ambientGlow = Palette.ice.opacity(0.07)
    }

    /// Shared material roles for the Observatory scenery and contact shadows.
    enum Observatory {
        static let lanternGlow = Color(red: 1, green: 0.67, blue: 0.25)
        static let fogOpacity = 0.28
        static let contactShadow = UIColor(red: 0.035, green: 0.045, blue: 0.10, alpha: 0.46)
        static let softContactShadow = contactShadow.withAlphaComponent(0.23)
    }

    enum Dusk {
        static let corruption = SIMD4<Float>(0.48, 0.20, 0.76, 1)
        static let core = UIColor(red: 0.025, green: 0.015, blue: 0.065, alpha: 1)
        static let rim = UIColor(red: 0.74, green: 0.57, blue: 1, alpha: 1)
    }

    /// Celestial gravity materials and their finite formation/attraction cues.
    enum Gravity {
        static let magneticLight = UIColor(red: 1, green: 0.82, blue: 0.42, alpha: 1)
        static let orbitLight = UIColor(red: 0.40, green: 0.91, blue: 1, alpha: 1)
    }

    /// Authored camera contour for checked portrait profiles, selected by SkyShowerPlacement.
    enum IslandTimer {
        static let width: CGFloat = 148
        static let height: CGFloat = 50
        static let radius: CGFloat = 24
        static let top: CGFloat = 5
        static let cameraTop: CGFloat = 11
        static let cameraSize = CGSize(width: 126, height: 37)
    }

    enum GrownStar {
        static let auraAlpha: CGFloat = 0.24
        static let pulseAmplitude: CGFloat = 0.10
        static let pulsePeriod: TimeInterval = 2.8
    }

    enum SelectionCue {
        static let innerRadius: CGFloat = 0.39
        static let outerRadius: CGFloat = 0.52
        static let contactWidth: CGFloat = 2
        static let readyWidth: CGFloat = 3
        static let arrowWing: CGFloat = 0.12
        static let holdInnerRadius: CGFloat = 0.43
        static let holdOuterRadius: CGFloat = 0.64
        static let holdMarkCount = 12
        static let retainedHalfWidth: CGFloat = 0.18
        static let retainedBaseline: CGFloat = 0.40
        static let retainedBodyClearance: CGFloat = 0.04
        static let retainedLipHeight: CGFloat = 0.08
    }

    enum Typography {
        enum GuideTitleRole {
            case character, outcome

            // Secondary names grow modestly; primary outcomes retain full scaling.
            var maximumTextSize: DynamicTypeSize {
                self == .character ? .accessibility1 : .accessibility5
            }
        }

        static let displayBaseSize: CGFloat = 52
        static let title = Font.system(.title2, design: .serif).weight(.medium)
        static let heading = Font.system(.headline, design: .serif).weight(.semibold)
        static let body = Font.body
        static let supporting = Font.subheadline
        static let status = Font.callout
        static let action = Font.system(.headline, design: .serif).weight(.semibold)
        static let gameTitle = Font.system(.headline, design: .serif).weight(.semibold)
        static let hudGlyph = Font.system(size: Layout.hudSymbolSide, weight: .medium)
        static let celebrationTitle = Font.system(.title, design: .rounded).weight(.heavy)
        static let celebrationRelayCount = Font.system(.title3, design: .serif).weight(.bold)
        static let celebrationAward = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let gameDetail = Font.subheadline
        static let skyCaption = Font.system(.caption, design: .rounded).weight(.medium)
        static let instrumentScore = gameTitle
        static let instrumentTarget = gameTitle.weight(.regular)
        static let instrumentLabel = skyCaption
        static let instrumentNumber = instrumentLabel.weight(.semibold)
        static let skyHeading = Font.system(.headline, design: .serif)
        static let titleTracking: CGFloat = 0.8

        static func display(size: CGFloat) -> Font {
            .system(size: size, weight: .medium, design: .serif)
        }
    }

    enum Spacing {
        static let hairline: CGFloat = 2
        static let compact: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let page: CGFloat = 20
        static let section: CGFloat = 24
    }

    enum Radius {
        static let control: CGFloat = 16
        static let panel: CGFloat = 20
        static let board: CGFloat = 24
    }

    enum Layout {
        static let minimumTarget: CGFloat = 44
        // Native compact sheets scale their content slightly; retain a full
        // 44pt target after that presentation transform.
        static let preferenceTarget: CGFloat = 48
        // A point of breathing room keeps compact controls above the native minimum after layout.
        static let gameplayTarget = minimumTarget + 1
        static let hudSymbolSide: CGFloat = 24
        static let actionHeight: CGFloat = 52
        static let contentWidth: CGFloat = 560
        static let menuWidth: CGFloat = 480
        // A wide window must fit a useful board and an uncompressed reading column.
        static let wideGameMinimumWidth: CGFloat = 900
        static let wideGameMinimumHeight: CGFloat = 500
        static let wideGameSidebarWidth: CGFloat = 300
        static let wideGameBoardMaximum: CGFloat = 600
        static let brandMarkSize: CGFloat = 48
        static let boardSymbolSize: CGFloat = 24
        // 335pt board minus 12pt padding and 12pt gaps leaves >44pt per cell.
        static let accessibleBoardInset: CGFloat = 6
        static let progressHeight: CGFloat = 6
        static let showerTrailWidth: CGFloat = 132
        static let compactShowerTrailWidth: CGFloat = 96
        static let showerTrailHeadDiameter: CGFloat = 5
        // Exceptional clear wash, in shared board star steps.
        static let clearSourceLightRadius: ClosedRange<CGFloat> = 1.5...2
        static let guidePropClearance: CGFloat = 76
        static let arrivalCueWidth: CGFloat = 56
        static let arrivalCueHeight: CGFloat = 3
        static let arrivalCueGlow: CGFloat = 6
        static let constellationSize = CGSize(width: 64, height: 24)
        static let borderWidth: CGFloat = 1
        static let focusWidth: CGFloat = 2
    }

    private enum Palette {
        static let midnight = Color(red: 8 / 255, green: 15 / 255, blue: 26 / 255)
        static let plum = Color(red: 19 / 255, green: 25 / 255, blue: 43 / 255)
        static let nightglass = Color(red: 16 / 255, green: 28 / 255, blue: 44 / 255)
        static let litNightglass = Color(red: 29 / 255, green: 43 / 255, blue: 61 / 255)
        static let moonlight = Color(red: 240 / 255, green: 233 / 255, blue: 218 / 255)
        static let lavender = Color(red: 202 / 255, green: 200 / 255, blue: 196 / 255)
        static let mutedLavender = Color(red: 176 / 255, green: 170 / 255, blue: 159 / 255)
        static let brass = Color(red: 224 / 255, green: 191 / 255, blue: 123 / 255)
        static let softBrass = Color(red: 145 / 255, green: 126 / 255, blue: 89 / 255)
        static let ice = Color(red: 176 / 255, green: 237 / 255, blue: 255 / 255)
        static let blueIce = Color(red: 144 / 255, green: 211 / 255, blue: 233 / 255)
        static let slate = Color(red: 102 / 255, green: 119 / 255, blue: 155 / 255)
    }
}

/// A common action contract: native Button semantics, a full hit shape, wrapping
/// Dynamic Type, and immediate material state changes without scale or motion.
struct StarfallButtonStyle: ButtonStyle {
    enum Role { case primary, ceremonyPrimary, secondary, compact, quiet }

    let role: Role
    var expands = false
    /// Choices keep compact geometry in every state and reveal only the selected surface.
    var showsCompactSurface = true
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: StarfallTheme.Radius.control, style: .continuous)
        Group {
            if role == .quiet {
                configuration.label
                    .padding(.horizontal, StarfallTheme.Spacing.small)
                    .padding(.vertical, StarfallTheme.Spacing.compact)
                    .frame(minWidth: StarfallTheme.Layout.minimumTarget,
                           maxWidth: expands ? .infinity : nil,
                           minHeight: StarfallTheme.Layout.minimumTarget)
                    .background(configuration.isPressed && isEnabled ? StarfallTheme.Colors.surfacePressed : .clear, in: shape)
            } else if role == .compact || role == .secondary {
                configuration.label
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, StarfallTheme.Spacing.medium)
                    .padding(.vertical, StarfallTheme.Spacing.small)
                    .frame(minWidth: StarfallTheme.Layout.preferenceTarget,
                           maxWidth: expands ? .infinity : nil,
                           minHeight: StarfallTheme.Layout.preferenceTarget)
                    .background {
                        if showsCompactSurface || configuration.isPressed && isEnabled {
                            ObservatoryCompactActionSurface(pressed: configuration.isPressed && isEnabled, enabled: isEnabled)
                        }
                    }
            } else {
                ObservatoryActionLayout(expands: expands) {
                    configuration.label.fixedSize(horizontal: false, vertical: true)
                }
                .background {
                    ObservatorySurface(skin: .action, pressed: configuration.isPressed && isEnabled,
                                       enabled: isEnabled)
                }
            }
        }
            .font(StarfallTheme.Typography.action)
            .multilineTextAlignment(.center)
            .foregroundStyle(foreground)
            .overlay {
                if isFocused {
                    shape.strokeBorder(StarfallTheme.Colors.focus, lineWidth: StarfallTheme.Layout.focusWidth)
                }
            }
            .contentShape(Rectangle())
            // Native VoiceOver and keyboard focus effects remain enabled.
            .transaction { $0.animation = nil }
    }

    private var foreground: Color {
        guard isEnabled else { return StarfallTheme.Colors.textDisabled }
        return role == .quiet || (role == .compact && !showsCompactSurface)
            ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.textPrimary
    }
}

/// Keep one natural-size caption, dropping decoration before words. A caller
/// chooses iconOnly when the glyph conveys this action in context. Otherwise
/// natural text width propagates to the parent's stack/scroll layout.
/// The enclosing Button owns the complete spoken action.
struct StarfallActionLabel: View {
    let title: String
    let glyph: ObservatoryGlyph
    var rotation: Double = 0
    var iconOnly = false

    var body: some View {
        if iconOnly {
            icon
        } else {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: StarfallTheme.Spacing.small) {
                    icon
                    Text(title).fixedSize(horizontal: true, vertical: false)
                }
                .fixedSize(horizontal: true, vertical: false)
                Text(title).fixedSize(horizontal: true, vertical: false)
            }
        }
    }

    private var icon: some View {
        ObservatoryIcon(glyph, size: 20)
            .rotationEffect(.degrees(rotation))
    }
}

private struct StarfallPanelStyle: ViewModifier {
    let inset: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(inset)
            .background { ObservatoryCompactSurface() }
    }
}

/// The rendered object stays small; scenic protection fits inside the clear target.
struct StarfallUtilityButtonStyle: ButtonStyle {
    enum Backdrop { case clear, scenery }
    var backdrop: Backdrop = .clear
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        return configuration.label
            .foregroundStyle(isEnabled ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textDisabled)
            .frame(width: 24, height: 24)
            .shadow(color: .black.opacity(0.5), radius: 1.5, y: 1)
            .background {
                if pressed {
                    Circle().fill(StarfallTheme.Colors.surfacePressed).padding(-StarfallTheme.Spacing.small)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .starfallSceneryProtection(backdrop == .scenery)
            .frame(width: StarfallTheme.Layout.preferenceTarget, height: StarfallTheme.Layout.preferenceTarget)
            .overlay {
                if isFocused {
                    Circle().strokeBorder(StarfallTheme.Colors.focus, lineWidth: StarfallTheme.Layout.focusWidth)
                        .padding(StarfallTheme.Spacing.compact).allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .transaction { $0.animation = nil }
    }
}

extension View {
    /// Passive containment only: no clipping, accessibility grouping, or input.
    func starfallPanel(inset: CGFloat = StarfallTheme.Spacing.page) -> some View {
        modifier(StarfallPanelStyle(inset: inset))
    }

    /// Fitted instrument protection; visual outsets never enlarge native layout.
    func starfallSceneryProtection(_ enabled: Bool = true) -> some View {
        modifier(StarfallSceneryProtection(enabled: enabled))
    }
}

private struct StarfallSceneryProtection: ViewModifier {
    let enabled: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let opaque = reduceTransparency || contrast == .increased
        return content.background {
            if enabled {
                RoundedRectangle(cornerRadius: StarfallTheme.Spacing.small, style: .continuous)
                    .fill(StarfallTheme.Colors.surface.opacity(opaque ? 1 : 0.82))
                    .padding(-StarfallTheme.Spacing.small)
                    .blur(radius: opaque ? 0 : 3)
                    .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
    }
}

/// Read-only supporting feedback. Callers supply facts and optional native IDs;
/// the Text owns its semantics before passive decorative protection.
struct StarfallStatusText: View {
    enum Emphasis { case supporting, positive }
    enum Role { case message, instrument }
    let text: String
    var emphasis: Emphasis = .supporting
    var role: Role = .message
    var accessibilityText: String? = nil
    var nativeIdentifier: String? = nil

    private var statusFont: Font {
        role == .instrument ? StarfallTheme.Typography.instrumentLabel : StarfallTheme.Typography.status
    }

    private var styledText: some View {
        Text(text)
            .font(statusFont)
            .foregroundStyle(emphasis == .positive ? StarfallTheme.Colors.positiveStatus : StarfallTheme.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private var semanticText: some View {
        if nativeIdentifier != nil || accessibilityText != nil {
            styledText.accessibilityRepresentation {
                if let nativeIdentifier {
                    Text(text).font(statusFont).accessibilityLabel(accessibilityText ?? text)
                        .accessibilityIdentifier(nativeIdentifier)
                } else {
                    Text(text).font(statusFont).accessibilityLabel(accessibilityText ?? text)
                }
            }
        } else {
            styledText
        }
    }

    var body: some View {
        semanticText.starfallSceneryProtection(role == .instrument)
    }
}

struct StarfallTitle: View {
    enum Style { case display, navigation }
    var style: Style = .navigation
    @ScaledMetric(relativeTo: .largeTitle) private var displaySize = StarfallTheme.Typography.displayBaseSize

    var body: some View {
        Text("Starfall")
            .font(style == .display ? StarfallTheme.Typography.display(size: displaySize) : StarfallTheme.Typography.title)
            .tracking(StarfallTheme.Typography.titleTracking)
            .foregroundStyle(StarfallTheme.Colors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

/// A settled fraction, shared with the HUD without importing game rules. The
/// constellation is a second rendering of the same value, never a new objective.
struct StarfallProgressStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        let fraction = min(max(configuration.fractionCompleted ?? 0, 0), 1)
        return HStack(spacing: StarfallTheme.Spacing.medium) {
            GeometryReader { geometry in
                Capsule()
                    .fill(StarfallTheme.Colors.progressTrack)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(StarfallTheme.Colors.progressFill)
                            .frame(width: geometry.size.width * CGFloat(fraction))
                    }
            }
            .frame(height: StarfallTheme.Layout.progressHeight)

            Canvas { context, size in
                let points = [
                    CGPoint(x: 0.05, y: 0.72), CGPoint(x: 0.25, y: 0.25),
                    CGPoint(x: 0.50, y: 0.60), CGPoint(x: 0.72, y: 0.15),
                    CGPoint(x: 0.95, y: 0.38)
                ].map { CGPoint(x: $0.x * size.width, y: $0.y * size.height) }
                var trace = Path()
                trace.addLines(points)
                context.stroke(trace, with: .color(StarfallTheme.Colors.progressTrack), lineWidth: 1)
                context.stroke(trace.trimmedPath(from: 0, to: CGFloat(fraction)),
                               with: .color(StarfallTheme.Colors.progressFill), lineWidth: 1.5)
                for point in points {
                    let star = Path(ellipseIn: CGRect(x: point.x - 1.8, y: point.y - 1.8,
                                                     width: 3.6, height: 3.6))
                    context.fill(star, with: .color(StarfallTheme.Colors.progressFill.opacity(0.3 + 0.7 * fraction)))
                }
            }
            .frame(width: StarfallTheme.Layout.constellationSize.width,
                   height: StarfallTheme.Layout.constellationSize.height)
            .accessibilityHidden(true)
        }
        .transaction { $0.animation = nil }
    }
}

/// Compact gameplay chrome retains a full native touch target at every text size.
struct StarfallGameButtonStyle: ButtonStyle {
    enum Role: Equatable {
        case gameplay
        case forecast(selected: Bool)
    }
    enum Backdrop: Equatable { case clear, scenery }

    var role: Role = .gameplay
    var backdrop: Backdrop = .clear
    var tint = StarfallTheme.Colors.actionPrimary
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var focused
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        let shape = RoundedRectangle(cornerRadius: isForecast ? StarfallTheme.Spacing.small : 10)
        return configuration.label
            .font(role == .gameplay ? StarfallTheme.Typography.gameDetail.weight(.medium) : StarfallTheme.Typography.instrumentLabel)
            .foregroundStyle(ink)
            .saturation(isForecast && !isEnabled ? 0.25 : 1)
            .padding(.horizontal, isForecast ? 0 : StarfallTheme.Spacing.small)
            // Reserve the same selection-mark space in every forecast state,
            // including when large native digits make the target taller.
            .padding(.bottom, isForecast ? StarfallTheme.Spacing.small : 0)
            .frame(minWidth: minimumTarget, minHeight: minimumTarget)
            .background {
                if pressed || reduceTransparency || contrast == .increased {
                    shape.fill(pressed ? StarfallTheme.Colors.surfacePressed : StarfallTheme.Colors.surface)
                }
            }
            .starfallSceneryProtection(backdrop == .scenery)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Capsule().fill(ink)
                        .frame(width: StarfallTheme.Spacing.large, height: StarfallTheme.Layout.focusWidth)
                        .padding(.bottom, StarfallTheme.Spacing.compact)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .overlay {
                if focused {
                    shape.strokeBorder(StarfallTheme.Colors.focus, lineWidth: StarfallTheme.Layout.focusWidth)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
            .transaction { $0.animation = nil }
    }

    private var isForecast: Bool {
        if case .forecast = role { return true }
        return false
    }

    private var isSelected: Bool {
        if case .forecast(let selected) = role { return selected }
        return false
    }

    private var minimumTarget: CGFloat {
        switch role {
        case .gameplay: StarfallTheme.Layout.gameplayTarget
        case .forecast: StarfallTheme.Layout.minimumTarget
        }
    }

    private var ink: Color {
        guard isEnabled else { return StarfallTheme.Colors.textDisabled }
        switch role {
        case .gameplay: return tint
        case .forecast(let selected):
            return selected ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textSecondary
        }
    }
}

extension StarfallTheme {
    enum Ceremony {
        /// Full-canvas landmark band left visible above a restored-result heading.
        static let restoredSceneBottom: CGFloat = 230
        static let handoffDuration = 0.24
        static let gold = Color("CeremonyGold")
        static let goldPressed = Color(red: 0.90, green: 0.76, blue: 0.48)
        static let titleSize: CGFloat = 46
        static let resultTitleSize: CGFloat = 36
        static let settleDuration = 0.65
        static let actionsDelay = 0.36
    }
}

extension StarfallTheme {
    enum Restoration {
        static let sky = Color(red: 0.018, green: 0.033, blue: 0.105)
        static let restorationDuration: TimeInterval = 0.85
        static let hudOpacity = 0.68
    }

    enum Landing {
        static let nightCenter = Color(red: 0.025, green: 0.045, blue: 0.105)
        static let distantStar = Color(red: 0.68, green: 0.72, blue: 0.94)
        static let crownInset: CGFloat = 28
        static let flowingApronInset: CGFloat = 32
        static let portraitSide: CGFloat = 44
    }
}
