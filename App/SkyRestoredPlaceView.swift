import SwiftUI
import StarfallCore

/// A completed place is scenery to revisit, not a replacement round. The native
/// header owns navigation; the existing painting owns its registered composition.
@MainActor struct SkyRestoredPlaceView: View {
    let snapshot: SkyRestoredPlaceSnapshot
    let active: Bool
    let quiet: Bool
    let back: () -> Void

    var body: some View {
        GeometryReader { viewport in
            VStack(spacing: 0) {
                header
                painting(isTablet: UIDevice.current.userInterfaceIdiom == .pad,
                         isLandscape: viewport.size.width > viewport.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(StarfallTheme.Colors.skyTop)
        .foregroundStyle(StarfallTheme.Colors.textPrimary)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("world.restored.page")
    }

    /// One native control subtree reflows instead of creating alternate buttons.
    var header: some View {
        Header(title: snapshot.challenge.locationTitle, back: back)
    }

    private struct Header: View {
        let title: String
        let back: () -> Void

        var body: some View {
            // The same viewport utility composition as Map/reader navigation:
            // one full target, with text wrapping in the actual remaining width.
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.large) {
                Button(action: back) {
                    ObservatoryIcon(.back, size: 20)
                }
                .buttonStyle(StarfallUtilityButtonStyle())
                .accessibilityLabel(SkyCopy.text(.worldBack))
                .accessibilityIdentifier("world.restored.back")

                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                    Text(title)
                        .font(StarfallTheme.Typography.title)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("world.restored.title")
                    Text(SkyCopy.text(.worldRestored))
                        .font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textSecondary)
                        .accessibilityIdentifier("world.restored.status")
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(StarfallTheme.Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(StarfallTheme.Colors.skyTop)
        }
    }

    /// The same production painting is inspectable without any game, board,
    /// delivery receipt or input capability. Its actual remaining bounds choose
    /// the registered crop; the outer viewport supplies device orientation.
    func painting(isTablet: Bool, isLandscape: Bool) -> some View {
        GeometryReader { slot in
            RestorationEnvironment(presentation: snapshot.presentation,
                                   active: active, ambientActive: true, quiet: quiet,
                                   isTablet: isTablet, isLandscape: isLandscape,
                                   award: nil)
                .frame(width: slot.size.width, height: slot.size.height)
                .clipped()
                // Painting bleed keeps its registered pixels, while the passive
                // semantic element describes only the visible viewport.
                .contentShape(.accessibility, Rectangle())
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(snapshot.challenge.locationTitle)
                .accessibilityValue(SkyCopy.text(.worldRestored))
                .accessibilityIdentifier("world.restored.art")
        }
    }
}
