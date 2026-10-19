import SwiftUI

/// A solid scenic surround behind the registered official location artwork.
struct SkyBackdrop: View {
    var body: some View {
        LinearGradient(colors: [StarfallTheme.Colors.skyTop, StarfallTheme.Landing.nightCenter, StarfallTheme.Colors.skyTop],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}
