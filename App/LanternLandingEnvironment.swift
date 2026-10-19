import SwiftUI
import StarfallCore

/// A read-only presentation of the committed light. No timers or completion
/// callbacks can award light, finish the level, or change the saved sky.
@MainActor struct LanternLandingEnvironment: View {
    let restoration: StarlightRestoration
    let active: Bool
    let ambientActive: Bool
    let quiet: Bool
    var isTablet = false
    var isLandscape = false
    @State private var clock = LandingAmbientClock()
    private var running: Bool { active && ambientActive && !quiet }

    var body: some View {
        GeometryReader { geometry in
            let artwork = LanternLandingArtwork.selected(isTablet: isTablet, isLandscape: isLandscape, size: geometry.size)
            let layout = LanternLandingLayout(size: geometry.size, artwork: artwork)
            ZStack {
                StarfallTheme.Lantern.sky
                ForEach(StarlightRestoration.Milestone.allCases, id: \.rawValue) { stage in
                    // Every layer is the complete continuous painting. Reached
                    // layers stay opaque beneath the next whole-image crossfade.
                    Image(artwork.asset(for: stage)).resizable()
                        .frame(width: layout.imageFrame.width, height: layout.imageFrame.height)
                        .position(x: layout.imageFrame.midX, y: layout.imageFrame.midY)
                        .opacity(stage.rawValue <= restoration.milestone.rawValue ? 1 : 0)
                        .animation(active && !quiet ? .easeInOut(duration: StarfallTheme.Lantern.restorationDuration) : nil,
                                   value: restoration.milestone)
                }
                TimelineView(.animation(minimumInterval: 1 / 24, paused: !running)) { _ in
                    let phase = quiet ? 0 : clock.phase(at: ProcessInfo.processInfo.systemUptime)
                    Circle().fill(StarfallTheme.Observatory.lanternGlow)
                        .blur(radius: 13)
                        .frame(width: layout.light.width * 3, height: layout.light.height * 3)
                        .opacity(restoration.fraction * (0.10 + 0.025 * sin(phase / 2)))
                        .position(x: layout.light.midX, y: layout.light.midY)
                }
                Color.clear.frame(width: layout.light.width, height: layout.light.height)
                    .starlightAnchor(.lantern)
                    .position(x: layout.light.midX, y: layout.light.midY)
            }
            .clipped().allowsHitTesting(false).accessibilityHidden(true)
        }
        .onAppear { clock.setRunning(running, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: running) { _, value in clock.setRunning(value, at: ProcessInfo.processInfo.systemUptime) }
        .onDisappear { clock.setRunning(false, at: ProcessInfo.processInfo.systemUptime) }
        // Interruption disables the transaction as well as the ambient clock.
        // Resuming displays the latest state; there is no milestone queue.
        .transaction { if !active || quiet { $0.animation = nil; $0.disablesAnimations = true } }
    }
}

/// Each device composition keeps all five paintings registered to the same lantern.
enum LanternLandingArtwork: CaseIterable {
    case phone, tabletPortrait, tabletLandscape

    /// Landscape viewports with a tall scrolling canvas use the portrait painting,
    /// whose lantern stays above the board. Wide canvases use the wide painting.
    static func selected(isTablet: Bool, isLandscape: Bool, size: CGSize) -> Self {
        if isLandscape { return size.width < size.height ? .tabletPortrait : .tabletLandscape }
        return isTablet ? .tabletPortrait : .phone
    }

    func asset(for milestone: StarlightRestoration.Milestone) -> String {
        let prefix: String
        switch self {
        case .phone: prefix = "LanternLanding"
        case .tabletPortrait: prefix = "LanternLandingTabletPortrait"
        case .tabletLandscape: prefix = "LanternLandingTabletLandscape"
        }
        return prefix + String(format: "%03d", milestone.rawValue)
    }

    /// Pixel dimensions of the registered paintings in each packaged family.
    var sourceSize: CGSize {
        switch self {
        case .phone: CGSize(width: 887, height: 1774)
        case .tabletPortrait: CGSize(width: 1086, height: 1448)
        case .tabletLandscape: CGSize(width: 1448, height: 1086)
        }
    }

    /// Bounds in the complete source painting, before aspect-fill placement.
    var normalizedLight: CGRect {
        let center: CGPoint, width: CGFloat
        switch self {
        case .phone: center = CGPoint(x: 0.333, y: 0.080); width = 0.06
        case .tabletPortrait: center = CGPoint(x: 0.218, y: 0.079); width = 0.05
        case .tabletLandscape: center = CGPoint(x: 0.161, y: 0.316); width = 0.04
        }
        let height = width * sourceSize.width / sourceSize.height
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    /// The complete moth lantern, including its wings and stem. Aspect fill may
    /// crop the painting's outer edges, but preserves this registered focal region.
    var normalizedLantern: CGRect {
        switch self {
        case .phone: CGRect(x: 0.22, y: 0.025, width: 0.23, height: 0.12)
        case .tabletPortrait: CGRect(x: 0.13, y: 0.025, width: 0.17, height: 0.12)
        case .tabletLandscape: CGRect(x: 0.085, y: 0.23, width: 0.16, height: 0.215)
        }
    }
}

/// One aspect-fill transform owns both the whole painting and its light destination.
/// Gameplay/header geometry has no dependency on the scenery composition.
struct LanternLandingLayout {
    let size: CGSize
    let artwork: LanternLandingArtwork

    var imageFrame: CGRect {
        let source = artwork.sourceSize
        let scale = max(size.width / source.width, size.height / source.height)
        let image = CGSize(width: source.width * scale, height: source.height * scale)
        let focal = artwork.normalizedLantern
        return CGRect(x: origin(canvas: size.width, image: image.width, focalMin: focal.minX, focalMax: focal.maxX),
                      y: origin(canvas: size.height, image: image.height, focalMin: focal.minY, focalMax: focal.maxY),
                      width: image.width, height: image.height)
    }

    var light: CGRect { frame(artwork.normalizedLight) }
    var lantern: CGRect { frame(artwork.normalizedLantern) }

    private func frame(_ source: CGRect) -> CGRect {
        let image = imageFrame
        return CGRect(x: image.minX + image.width * source.minX,
                      y: image.minY + image.height * source.minY,
                      width: image.width * source.width, height: image.height * source.height)
    }

    private func origin(canvas: CGFloat, image: CGFloat, focalMin: CGFloat, focalMax: CGFloat) -> CGFloat {
        // Keep the centered composition whenever possible. Moving the entire
        // image within its overflow retains coverage and the shared light anchor.
        let minimum = max(canvas - image, -image * focalMin)
        let maximum = min(0, canvas - image * focalMax)
        let centered = (canvas - image) / 2
        guard minimum <= maximum else { return centered }
        return min(max(centered, minimum), maximum)
    }
}
