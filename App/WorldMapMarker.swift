import SwiftUI
import StarfallCore

enum WorldMapMarkerMetrics {
    static let pinSize = CGSize(width: 32, height: 32 * 58 / 44)
    static let pinTipY: CGFloat = 32 * 56 / 44
}

/// One native control owns the complete island and its name. Artwork, pin and
/// nameplate are visual children, never nested or competing hit targets.
struct WorldMapMarker<Content: View>: View {
    let presentation: WorldMapDestinationPresentation
    let selected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action, label: content)
        .buttonStyle(WorldMapMarkerButtonStyle())
        .accessibilityLabel(presentation.title)
        .accessibilityValue(presentation.status)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("world.node.\(presentation.location.id)")
    }
}

private struct WorldMapMarkerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .brightness(configuration.isPressed && isEnabled ? 0.10 : 0)
        .frame(minWidth: StarfallTheme.Layout.gameplayTarget,
               minHeight: StarfallTheme.Layout.gameplayTarget)
        .contentShape(Rectangle())
        .overlay {
            if isFocused {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(StarfallTheme.Colors.focus, lineWidth: StarfallTheme.Layout.focusWidth)
            }
        }
        .transaction { $0.animation = nil }
    }
}

struct WorldMapNameplate: View {
    let title: String
    let selected: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let edge = selected ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.outline
        let ink = isEnabled ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textDisabled
        Text(title)
                .font(StarfallTheme.Typography.skyHeading)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(ink)
                .padding(.horizontal, StarfallTheme.Spacing.small)
                .padding(.vertical, StarfallTheme.Spacing.compact + 2)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(StarfallTheme.Colors.surface)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(edge, lineWidth: selected || contrast == .increased ? 2 : 1)
                            if selected {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .inset(by: 4)
                                    .strokeBorder(StarfallTheme.Colors.textPrimary, lineWidth: 1)
                            }
                        }
                        .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                }
    }
}

struct WorldMapMarkerPin: View {
    // The entire island is a 44pt+ native target. This pin is decoration and can
    // retain a modest visual size without reducing the input area.
    let glyph: ObservatoryGlyph
    let selected: Bool
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let edge = selected ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.outline
        let surface = StarfallTheme.Colors.surface
        ZStack(alignment: .top) {
            WorldMapPinShape()
                .fill(LinearGradient(colors: [selected ? StarfallTheme.Colors.actionPrimary : surface, surface],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    WorldMapPinShape()
                        .stroke(edge, lineWidth: selected || contrast == .increased ? 2 : 1.25)
                }
                .shadow(color: selected ? StarfallTheme.Colors.actionPrimary.opacity(0.42) : .black.opacity(0.3),
                        radius: selected ? 5 : 2, y: 1)
            Circle()
                .fill(surface)
                .overlay {
                    Circle().strokeBorder(selected ? StarfallTheme.Colors.textPrimary : edge, lineWidth: 1)
                }
                .overlay {
                    ObservatoryIcon(glyph, size: 17)
                        .foregroundStyle(isEnabled ? StarfallTheme.Colors.textPrimary : StarfallTheme.Colors.textDisabled)
                }
                .frame(width: 25, height: 25)
                .padding(.top, 4)
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Normalized from the fixed 44 × 58-point pin canvas. Its tip is (22, 56);
/// the two-point exterior margin keeps the stroke inside the visual bounds.
private struct WorldMapPinShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 44, y: rect.minY + y * rect.height / 58)
        }
        return Path { path in
            path.move(to: point(22, 2))
            path.addCurve(to: point(41, 22), control1: point(33, 2), control2: point(41, 10))
            path.addCurve(to: point(33, 41), control1: point(41, 30), control2: point(37, 35))
            path.addCurve(to: point(22, 56), control1: point(29, 47), control2: point(24, 52))
            path.addCurve(to: point(11, 41), control1: point(20, 52), control2: point(15, 47))
            path.addCurve(to: point(3, 22), control1: point(7, 35), control2: point(3, 30))
            path.addCurve(to: point(22, 2), control1: point(3, 10), control2: point(11, 2))
            path.closeSubpath()
        }
    }
}
