import SwiftUI
import StarfallCore

/// A read-only presentation of the committed light. No timers or completion
/// callbacks can award light, finish the level, or change the saved sky.
@MainActor struct LanternLandingEnvironment: View {
    let restoration: StarlightRestoration
    let active: Bool
    let ambientActive: Bool
    let quiet: Bool
    var largeHeader = false
    @State private var clock = LandingAmbientClock()
    private var running: Bool { active && ambientActive && !quiet }

    var body: some View {
        GeometryReader { geometry in
            let layout = LanternLandingLayout(size: geometry.size, largeHeader: largeHeader)
            ZStack {
                StarfallTheme.Lantern.sky
                // The quiet center is common to all states. Cropping source
                // regions at render time preserves the approved registered art.
                LanternArtworkRegion(asset: "LanternLanding000", source: 0.30...0.75)
                    .opacity(0.72)
                ForEach([0, 25, 50, 75, 100], id: \.self) { stage in
                    let visible = restoration.milestone.rawValue == stage
                    ZStack {
                        region(stage, source: 0...0.31, frame: layout.dock, fade: .bottom)
                        region(stage, source: 0.73...1, frame: layout.rail, fade: .top)
                    }
                    .opacity(visible ? 1 : 0)
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

    private func region(_ stage: Int, source: ClosedRange<CGFloat>, frame: CGRect, fade: VerticalEdge) -> some View {
        LanternArtworkRegion(asset: String(format: "LanternLanding%03d", stage), source: source)
            .mask {
                LinearGradient(stops: fade == .bottom
                    ? [.init(color: .white, location: 0), .init(color: .white, location: 0.85), .init(color: .clear, location: 1)]
                    : [.init(color: .clear, location: 0), .init(color: .white, location: 0.20), .init(color: .white, location: 1)],
                               startPoint: .top, endPoint: .bottom)
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
    }
}

/// One asset per milestone; only the required registered region is displayed.
/// The dock and rail can occupy different margins without stretching their art.
private struct LanternArtworkRegion: View {
    let asset: String
    let source: ClosedRange<CGFloat>
    var body: some View {
        GeometryReader { geometry in
            let sourceHeight = source.upperBound - source.lowerBound
            let scale = max(geometry.size.width, geometry.size.height / (2 * sourceHeight))
            Image(asset).resizable()
                .frame(width: scale, height: scale * 2)
                .offset(x: (geometry.size.width - scale) / 2, y: -source.lowerBound * scale * 2)
        }.clipped()
    }
}

struct LanternLandingLayout {
    let size: CGSize
    var largeHeader = false
    private var board: CGRect { LandingGeometry(size: size, largeHeader: largeHeader).arenaFrame }
    var usesWings: Bool { board.minX >= 140 }
    var dock: CGRect {
        if usesWings {
            let width = board.minX + 10
            return CGRect(x: 0, y: max(0, board.minY - width * 0.15), width: width, height: width * 0.62)
        }
        // Preserve phone width but keep the deck above the first playable row
        // on portrait tablets. The final few points are the transparent fade.
        let width = min(size.width, max(180, board.minY / 0.60))
        return CGRect(x: (size.width - width) / 2, y: 0, width: width, height: width * 0.62)
    }
    var rail: CGRect {
        if usesWings {
            let width = board.minX + 10
            return CGRect(x: size.width - width, y: size.height - width * 0.54, width: width, height: width * 0.54)
        }
        let height = min(size.width * 0.54, max(0, size.height - board.maxY - 20))
        return CGRect(x: 0, y: size.height - height, width: size.width, height: height)
    }
    var light: CGRect {
        CGRect(x: dock.minX + dock.width * 0.292, y: dock.minY + dock.height * 0.213,
               width: dock.width * 0.06, height: dock.width * 0.06)
    }
}
