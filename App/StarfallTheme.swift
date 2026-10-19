import SwiftUI
import UIKit

/// The shared presentation system. Rules and SpriteKit jewel materials have
/// separate owners; screens compose these roles rather than invent local tokens.
enum StarfallTheme {
    enum Dialogue {
        static let surface = Color(red: 0.055, green: 0.055, blue: 0.145)
        static let brass = Color(red: 0.98, green: 0.78, blue: 0.43)
        static let ink = Colors.textPrimary
        static let portraitSide: CGFloat = 64
        static let portraitOverlap: CGFloat = 16
        static let corner: CGFloat = 24
    }
    enum Celebration {
        static let titleMaximumWidth: CGFloat = 330
        static let titleCapHeight: CGFloat = 50
        static let ordinaryAwardHeight: CGFloat = 42
        static let specialAwardHeight: CGFloat = 50
    }
    enum Colors {
        static let launchBackground = Color("LaunchBackground")
        static let skyTop = Palette.midnight
        static let skyBottom = Palette.plum
        static let surface = Palette.nightglass
        static let surfacePressed = Palette.litNightglass
        static let outline = Palette.slate
        static let textPrimary = Palette.moonlight
        static let textSecondary = Palette.lavender
        static let textDisabled = Palette.mutedLavender
        static let actionPrimary = Palette.ice
        static let actionPrimaryPressed = Palette.blueIce
        static let onActionPrimary = Palette.midnight
        static let actionDisabled = Palette.litNightglass
        static let focus = Palette.ice
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
        static let light = UIColor(red: 1, green: 0.96, blue: 0.76, alpha: 1)
        static let auraAlpha: CGFloat = 0.24
        static let rimAlpha: CGFloat = 0.90
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
        static let heading = Font.headline
        static let body = Font.body
        static let supporting = Font.subheadline
        static let status = Font.callout
        static let action = Font.headline
        static let gameTitle = Font.system(.headline, design: .rounded)
        static let celebrationTitle = Font.system(.title, design: .rounded).weight(.heavy)
        static let celebrationRelayCount = Font.system(.title3, design: .serif).weight(.bold)
        static let celebrationAward = Font.system(.largeTitle, design: .rounded).weight(.heavy)
        static let gameDetail = Font.subheadline
        static let skyCaption = Font.system(.caption, design: .rounded).weight(.medium)
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
        static let guidePropClearance: CGFloat = 76
        static let arrivalCueWidth: CGFloat = 56
        static let arrivalCueHeight: CGFloat = 3
        static let arrivalCueGlow: CGFloat = 6
        static let constellationSize = CGSize(width: 64, height: 24)
        static let borderWidth: CGFloat = 1
        static let focusWidth: CGFloat = 2
    }

    private enum Palette {
        static let midnight = Color(red: 9 / 255, green: 14 / 255, blue: 43 / 255)
        static let plum = Color(red: 46 / 255, green: 26 / 255, blue: 74 / 255)
        static let nightglass = Color(red: 29 / 255, green: 33 / 255, blue: 64 / 255)
        static let litNightglass = Color(red: 48 / 255, green: 54 / 255, blue: 82 / 255)
        static let moonlight = Color(red: 244 / 255, green: 241 / 255, blue: 255 / 255)
        static let lavender = Color(red: 197 / 255, green: 199 / 255, blue: 221 / 255)
        static let mutedLavender = Color(red: 164 / 255, green: 173 / 255, blue: 199 / 255)
        static let ice = Color(red: 176 / 255, green: 237 / 255, blue: 255 / 255)
        static let blueIce = Color(red: 144 / 255, green: 211 / 255, blue: 233 / 255)
        static let slate = Color(red: 102 / 255, green: 119 / 255, blue: 155 / 255)
    }
}

/// A common action contract: native Button semantics, a full hit shape, wrapping
/// Dynamic Type, and immediate solid-color state changes without scale or motion.
struct StarfallButtonStyle: ButtonStyle {
    enum Role { case primary, ceremonyPrimary, secondary, quiet }

    let role: Role
    var expands = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: StarfallTheme.Radius.control, style: .continuous)
        configuration.label
            .font(StarfallTheme.Typography.action)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, role == .quiet ? StarfallTheme.Spacing.small : StarfallTheme.Spacing.large)
            .padding(.vertical, role == .quiet ? StarfallTheme.Spacing.compact : StarfallTheme.Spacing.small)
            .frame(minWidth: StarfallTheme.Layout.minimumTarget,
                   maxWidth: expands ? .infinity : nil,
                   minHeight: role == .quiet ? StarfallTheme.Layout.minimumTarget : StarfallTheme.Layout.actionHeight)
            .foregroundStyle(foreground)
            .background(background(pressed: configuration.isPressed), in: shape)
            .overlay {
                shape.strokeBorder(isFocused ? StarfallTheme.Colors.focus : StarfallTheme.Colors.outline,
                                   lineWidth: isFocused ? StarfallTheme.Layout.focusWidth
                                   : (role == .secondary ? StarfallTheme.Layout.borderWidth : 0))
            }
            .contentShape(shape)
            // Native VoiceOver and keyboard focus effects remain enabled.
            .transaction { $0.animation = nil }
    }

    private var foreground: Color {
        guard isEnabled else { return StarfallTheme.Colors.textDisabled }
        return role == .primary || role == .ceremonyPrimary ? StarfallTheme.Colors.onActionPrimary : StarfallTheme.Colors.actionPrimary
    }

    private func background(pressed: Bool) -> Color {
        guard isEnabled else {
            return role == .quiet ? .clear : StarfallTheme.Colors.actionDisabled
        }
        switch role {
        case .primary:
            return pressed ? StarfallTheme.Colors.actionPrimaryPressed : StarfallTheme.Colors.actionPrimary
        case .ceremonyPrimary:
            return pressed ? StarfallTheme.Ceremony.goldPressed : StarfallTheme.Ceremony.gold
        case .secondary:
            return pressed ? StarfallTheme.Colors.surfacePressed : StarfallTheme.Colors.surface
        case .quiet:
            return pressed ? StarfallTheme.Colors.surfacePressed : .clear
        }
    }
}

private struct StarfallPanelStyle: ViewModifier {
    let inset: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(inset)
            .background {
                RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel, style: .continuous)
                    .fill(StarfallTheme.Colors.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel, style: .continuous)
                            .strokeBorder(StarfallTheme.Colors.outline,
                                          lineWidth: contrast == .increased ? StarfallTheme.Layout.focusWidth
                                          : StarfallTheme.Layout.borderWidth)
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
    }
}

extension View {
    /// Passive containment only: no clipping, accessibility grouping, or input.
    func starfallPanel(inset: CGFloat = StarfallTheme.Spacing.page) -> some View {
        modifier(StarfallPanelStyle(inset: inset))
    }
}

/// Read-only supporting feedback. IDs and labels remain at the call site, and
/// each Text keeps its own measured accessibility bounds.
struct StarfallStatusText: View {
    enum Emphasis { case supporting, positive }
    let text: String
    var emphasis: Emphasis = .supporting

    var body: some View {
        Text(text)
            .font(StarfallTheme.Typography.status)
            .foregroundStyle(emphasis == .positive ? StarfallTheme.Colors.positiveStatus : StarfallTheme.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
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
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(StarfallTheme.Typography.gameDetail.weight(.medium))
            .foregroundStyle(isEnabled ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.textDisabled)
            .padding(.horizontal, StarfallTheme.Spacing.small)
            .frame(minWidth: StarfallTheme.Layout.minimumTarget, minHeight: StarfallTheme.Layout.minimumTarget)
            .background(configuration.isPressed ? StarfallTheme.Colors.surfacePressed : .clear,
                        in: RoundedRectangle(cornerRadius: StarfallTheme.Radius.control))
            .contentShape(Rectangle())
    }
}

extension StarfallTheme {
    enum Ceremony {
        static let handoffDuration = 0.24
        static let gold = Color("CeremonyGold")
        static let goldPressed = Color(red: 0.90, green: 0.76, blue: 0.48)
        static let titleSize: CGFloat = 46
        static let resultTitleSize: CGFloat = 36
        static let settleDuration = 0.65
        static let actionsDelay = 0.36
    }
}
