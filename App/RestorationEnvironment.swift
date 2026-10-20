import SwiftUI
import StarfallCore

/// Read-only scenery. Committed challenge progress owns restoration; decoration
/// cannot award light, finish a round, or write a save.
@MainActor struct RestorationEnvironment: View {
    let presentation: RestorationPresentation
    let active: Bool
    let ambientActive: Bool
    let quiet: Bool
    var isTablet = false
    var isLandscape = false
    @State private var clock = LandingAmbientClock()
    private var running: Bool { active && ambientActive && !quiet }

    var body: some View {
        GeometryReader { geometry in
            let composition = RestorationComposition.selected(isTablet: isTablet, isLandscape: isLandscape, size: geometry.size)
            let artwork = RestorationArtwork(challenge: presentation.challenge, composition: composition)
            let layout = RestorationLayout(size: geometry.size, artwork: artwork)
            ZStack {
                StarfallTheme.Restoration.sky
                ForEach(StarlightRestoration.Milestone.allCases, id: \.rawValue) { stage in
                    // Reached layers stay opaque beneath the next complete-image
                    // crossfade. There are no independent regions or center masks.
                    let painting = RestorationLayout(size: geometry.size, artwork: artwork, milestone: stage)
                    Image(artwork.asset(for: stage)).resizable()
                        .frame(width: painting.imageFrame.width, height: painting.imageFrame.height)
                        .position(x: painting.imageFrame.midX, y: painting.imageFrame.midY)
                        .opacity(stage.rawValue <= presentation.progress.milestone.rawValue ? 1 : 0)
                        .animation(active && !quiet ? .easeInOut(duration: StarfallTheme.Restoration.restorationDuration) : nil,
                                   value: presentation.progress.milestone)
                }
                TimelineView(.animation(minimumInterval: 1 / 24, paused: !running)) { _ in
                    let phase = quiet ? 0 : clock.phase(at: ProcessInfo.processInfo.systemUptime)
                    Circle().fill(StarfallTheme.Observatory.lanternGlow)
                        .blur(radius: 13)
                        .frame(width: layout.light.width * 3, height: layout.light.height * 3)
                        .opacity(presentation.progress.fraction * (0.10 + 0.025 * sin(phase / 2)))
                        .position(x: layout.light.midX, y: layout.light.midY)
                }
                Color.clear.frame(width: layout.light.width, height: layout.light.height)
                    .starlightAnchor(.restorationLight)
                    .position(x: layout.light.midX, y: layout.light.midY)
                Color.clear.frame(width: layout.restoredSceneryBounds.width, height: layout.restoredSceneryBounds.height)
                    .starlightAnchor(.restorationScenery)
                    .position(x: layout.restoredSceneryBounds.midX, y: layout.restoredSceneryBounds.midY)
            }
            .clipped().allowsHitTesting(false).accessibilityHidden(true)
        }
        .onAppear { clock.setRunning(running, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: running) { _, value in clock.setRunning(value, at: ProcessInfo.processInfo.systemUptime) }
        .onDisappear { clock.setRunning(false, at: ProcessInfo.processInfo.systemUptime) }
        // No queued milestones: interruption displays the latest committed state.
        .transaction { if !active || quiet { $0.animation = nil; $0.disablesAnimations = true } }
    }
}

/// Landscape viewports with tall scrolling canvases keep the portrait composition
/// above the unchanged board. Wide canvases use the authored wide composition.
enum RestorationComposition: CaseIterable {
    case phone, tabletPortrait, tabletLandscape
    static func selected(isTablet: Bool, isLandscape: Bool, size: CGSize) -> Self {
        if isLandscape { return size.width < size.height ? .tabletPortrait : .tabletLandscape }
        return isTablet ? .tabletPortrait : .phone
    }
}

/// Asset registration is location data; whole-image placement has one owner.
struct RestorationArtwork {
    let challenge: StarfallChallenge
    let composition: RestorationComposition

    func asset(for milestone: StarlightRestoration.Milestone) -> String {
        let location: String
        switch challenge {
        case .firstLight: location = "LanternLanding"
        case .ribbonCrossing: location = "RibbonCrossing"
        case .kiteHarbor: location = "KiteHarbor"
        case .seedMoon: location = "SeedMoon"
        case .silverPools: location = "SilverPools"
        case .frostfruitOrchard: location = "FrostfruitOrchard"
        }
        let suffix: String
        switch composition {
        case .phone: suffix = ""
        case .tabletPortrait: suffix = "TabletPortrait"
        case .tabletLandscape: suffix = "TabletLandscape"
        }
        return location + suffix + String(format: "%03d", milestone.rawValue)
    }

    /// Light and focal registration use the completed painting as their reference.
    var sourceSize: CGSize { sourceSize(for: .complete) }

    func sourceSize(for milestone: StarlightRestoration.Milestone) -> CGSize {
        // Register generated pixels exactly; fitting never resamples the source files.
        if challenge == .frostfruitOrchard && composition == .tabletPortrait && milestone == .threeQuarters {
            return CGSize(width: 1086, height: 1449)
        }
        if challenge == .silverPools && composition == .tabletLandscape {
            switch milestone {
            case .quarter, .half, .complete: return CGSize(width: 1447, height: 1087)
            case .unrestored, .threeQuarters: return CGSize(width: 1446, height: 1087)
            }
        }
        if challenge == .seedMoon && composition == .tabletLandscape {
            switch milestone {
            case .unrestored, .quarter, .half: return CGSize(width: 1446, height: 1087)
            case .threeQuarters, .complete: return CGSize(width: 1447, height: 1087)
            }
        }
        switch composition {
        case .phone: return CGSize(width: 887, height: 1774)
        case .tabletPortrait: return CGSize(width: 1086, height: 1448)
        case .tabletLandscape: return CGSize(width: 1448, height: 1086)
        }
    }

    var normalizedLight: CGRect {
        let center: CGPoint, width: CGFloat
        switch challenge {
        case .ribbonCrossing:
            switch composition {
            case .phone: center = CGPoint(x: 0.476, y: 0.248); width = 0.035
            case .tabletPortrait: center = CGPoint(x: 0.315, y: 0.160); width = 0.03
            case .tabletLandscape: center = CGPoint(x: 0.214, y: 0.219); width = 0.025
            }
        case .firstLight:
            switch composition {
            case .phone: center = CGPoint(x: 0.333, y: 0.080); width = 0.06
            case .tabletPortrait: center = CGPoint(x: 0.218, y: 0.079); width = 0.05
            case .tabletLandscape: center = CGPoint(x: 0.161, y: 0.316); width = 0.04
            }
        case .kiteHarbor:
            switch composition {
            case .phone: center = CGPoint(x: 0.326, y: 0.064); width = 0.045
            case .tabletPortrait: center = CGPoint(x: 0.254, y: 0.133); width = 0.045
            case .tabletLandscape: center = CGPoint(x: 0.092, y: 0.115); width = 0.03
            }
        case .frostfruitOrchard:
            // The central crown receives light and opens at completion.
            switch composition {
            case .phone: center = CGPoint(x: 0.438, y: 0.190); width = 0.045
            case .tabletPortrait: center = CGPoint(x: 0.396, y: 0.098); width = 0.04
            case .tabletLandscape: center = CGPoint(x: 0.254, y: 0.235); width = 0.04
            }
        case .silverPools:
            switch composition {
            case .phone: center = CGPoint(x: 0.26, y: 0.042); width = 0.035
            case .tabletPortrait: center = CGPoint(x: 0.22, y: 0.035); width = 0.03
            case .tabletLandscape: center = CGPoint(x: 0.154, y: 0.085); width = 0.03
            }
        case .seedMoon:
            // The fixed seed/root receives light before the canopy grows. The
            // portrait tablet uses its root seam below the native header.
            switch composition {
            case .phone: center = CGPoint(x: 0.301, y: 0.214); width = 0.045
            case .tabletPortrait: center = CGPoint(x: 0.160, y: 0.214); width = 0.024
            case .tabletLandscape: center = CGPoint(x: 0.170, y: 0.355); width = 0.03
            }
        }
        let height = width * sourceSize.width / sourceSize.height
        return CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }

    /// Keep the identifying prop (or crossing seam) inside the viewport while
    /// moving only the complete image within its existing aspect-fill overflow.
    var normalizedFocal: CGRect {
        switch challenge {
        case .ribbonCrossing:
            switch composition {
            case .phone: return CGRect(x: 0.43, y: 0.20, width: 0.10, height: 0.08)
            // Keep the upper cloud bank and seam visible on wide scrolling canvases.
            case .tabletPortrait: return CGRect(x: 0.27, y: 0.05, width: 0.10, height: 0.15)
            case .tabletLandscape: return CGRect(x: 0.18, y: 0.035, width: 0.08, height: 0.23)
            }
        case .firstLight:
            switch composition {
            case .phone: return CGRect(x: 0.22, y: 0.025, width: 0.23, height: 0.12)
            case .tabletPortrait: return CGRect(x: 0.13, y: 0.025, width: 0.17, height: 0.12)
            case .tabletLandscape: return CGRect(x: 0.085, y: 0.23, width: 0.16, height: 0.215)
            }
        case .kiteHarbor:
            // Register the lead boat and its star, including enough upper sky to
            // preserve the mast when a large-text canvas crops the whole image.
            switch composition {
            case .phone: return CGRect(x: 0.18, y: 0.035, width: 0.23, height: 0.175)
            case .tabletPortrait: return CGRect(x: 0.10, y: 0.015, width: 0.24, height: 0.23)
            case .tabletLandscape: return CGRect(x: 0.035, y: 0.025, width: 0.18, height: 0.28)
            }
        case .frostfruitOrchard:
            // Protect the central crown’s closed/open seed-release beat.
            switch composition {
            case .phone: return CGRect(x: 0.34, y: 0.14, width: 0.20, height: 0.095)
            case .tabletPortrait: return CGRect(x: 0.32, y: 0.045, width: 0.16, height: 0.11)
            case .tabletLandscape: return CGRect(x: 0.20, y: 0.14, width: 0.11, height: 0.17)
            }
        case .silverPools:
            // The held droplet and released thread are the protected final beat;
            // the surrounding garden may continue behind native interface surfaces.
            switch composition {
            case .phone: return CGRect(x: 0.12, y: 0.008, width: 0.28, height: 0.09)
            case .tabletPortrait: return CGRect(x: 0.10, y: 0.008, width: 0.25, height: 0.09)
            case .tabletLandscape: return CGRect(x: 0.055, y: 0.005, width: 0.20, height: 0.28)
            }
        case .seedMoon:
            // Protect the canopy and its seed recipient through the result handoff.
            switch composition {
            case .phone: return CGRect(x: 0.06, y: 0.03, width: 0.48, height: 0.20)
            case .tabletPortrait: return CGRect(x: 0.085, y: 0.02, width: 0.215, height: 0.22)
            case .tabletLandscape: return CGRect(x: 0.05, y: 0.11, width: 0.245, height: 0.275)
            }
        }
    }

}

/// A single aspect-fill transform owns painting, light, and landmark coordinates.
/// Gameplay/header geometry never depends on the scenery composition.
struct RestorationLayout {
    let size: CGSize
    let artwork: RestorationArtwork
    let milestone: StarlightRestoration.Milestone

    /// The default completed-state transform owns the persistent light/scenery
    /// anchors. Each painting can select its own pixels without moving those anchors.
    init(size: CGSize, artwork: RestorationArtwork, milestone: StarlightRestoration.Milestone = .complete) {
        self.size = size
        self.artwork = artwork
        self.milestone = milestone
    }

    var imageFrame: CGRect {
        let source = artwork.sourceSize(for: milestone)
        let scale = max(size.width / source.width, size.height / source.height)
        let image = CGSize(width: source.width * scale, height: source.height * scale)
        let focal = artwork.normalizedFocal
        return CGRect(x: origin(canvas: size.width, image: image.width, focalMin: focal.minX, focalMax: focal.maxX),
                      y: origin(canvas: size.height, image: image.height, focalMin: focal.minY, focalMax: focal.maxY),
                      width: image.width, height: image.height)
    }

    var light: CGRect { frame(artwork.normalizedLight) }
    var focal: CGRect { frame(artwork.normalizedFocal) }
    /// The same image transform protects the identifying landmark from result UI.
    var restoredSceneryBounds: CGRect { focal }

    private func frame(_ source: CGRect) -> CGRect {
        let image = imageFrame
        return CGRect(x: image.minX + image.width * source.minX,
                      y: image.minY + image.height * source.minY,
                      width: image.width * source.width, height: image.height * source.height)
    }

    private func origin(canvas: CGFloat, image: CGFloat, focalMin: CGFloat, focalMax: CGFloat) -> CGFloat {
        let minimum = max(canvas - image, -image * focalMin)
        let maximum = min(0, canvas - image * focalMax)
        let centered = (canvas - image) / 2
        guard minimum <= maximum else { return centered }
        return min(max(centered, minimum), maximum)
    }
}
