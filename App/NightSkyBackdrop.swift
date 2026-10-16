import SwiftUI

/// Deterministic, static atmosphere. The parent continues to own content safe areas.
struct NightSkyBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [StarfallTheme.Colors.skyTop, StarfallTheme.Colors.skyBottom],
                               startPoint: .top, endPoint: .bottom)
                RadialGradient(colors: [StarfallTheme.Colors.ambientGlow, .clear],
                               center: .topTrailing, startRadius: 0,
                               endRadius: max(geometry.size.width, 1) * 0.8)
                Canvas { context, size in
                    for star in Self.stars {
                        let dot = Path(ellipseIn: CGRect(
                            x: size.width * star.x - star.radius,
                            y: size.height * star.y - star.radius,
                            width: star.radius * 2, height: star.radius * 2))
                        context.fill(dot, with: .color(StarfallTheme.Colors.ambientStar.opacity(star.opacity)))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private struct Star {
        let x: CGFloat
        let y: CGFloat
        let radius: CGFloat
        let opacity: Double
    }

    // Keep the central board field quiet. No random placement or redraw clock.
    private static let stars = [
        Star(x: 0.08, y: 0.05, radius: 0.7, opacity: 0.24),
        Star(x: 0.27, y: 0.03, radius: 0.6, opacity: 0.18),
        Star(x: 0.61, y: 0.06, radius: 0.8, opacity: 0.22),
        Star(x: 0.87, y: 0.04, radius: 0.9, opacity: 0.28),
        Star(x: 0.95, y: 0.15, radius: 0.6, opacity: 0.20),
        Star(x: 0.04, y: 0.27, radius: 0.8, opacity: 0.20),
        Star(x: 0.97, y: 0.45, radius: 0.7, opacity: 0.16),
        Star(x: 0.03, y: 0.64, radius: 0.6, opacity: 0.18),
        Star(x: 0.94, y: 0.76, radius: 0.9, opacity: 0.22),
        Star(x: 0.12, y: 0.88, radius: 0.7, opacity: 0.22),
        Star(x: 0.69, y: 0.95, radius: 0.6, opacity: 0.17),
        Star(x: 0.90, y: 0.92, radius: 0.8, opacity: 0.24)
    ]
}
