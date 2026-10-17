import SwiftUI
import StarfallCore
import Darwin

/// Authored vector constellation, sharp at every display scale; no new raster pipeline.
struct SkyMenuGlyph: View {
    var body: some View {
        Canvas { context, size in
            let points = [CGPoint(x: size.width*0.15, y: size.height*0.65),
                          CGPoint(x: size.width*0.45, y: size.height*0.25),
                          CGPoint(x: size.width*0.8, y: size.height*0.55)]
            var path = Path(); path.addLines(points)
            context.stroke(path, with: .color(StarfallTheme.Colors.actionPrimary.opacity(0.7)), lineWidth: 1)
            for point in points {
                context.fill(Path(ellipseIn: CGRect(x: point.x-2, y: point.y-2, width: 4, height: 4)),
                             with: .color(StarfallTheme.Colors.textPrimary))
            }
        }.frame(width: 24, height: 24).accessibilityHidden(true)
    }
}

/// Camera geometry has no public layout rect. Only a checked hardware profile
/// may draw outside the safe area; every other device keeps the complete HUD forecast.
enum SkyShowerPlacement {
    static let hardware: String = {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        #else
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
        #endif
    }()

    static func usesIsland(hardware: String, size: CGSize, topInset: CGFloat, accessible: Bool) -> Bool {
        // iPhone 17 portrait profile, verified in Simulator. Physical fit remains an RC check.
        hardware == "iPhone18,3" && !accessible && abs(size.width - 402) < 1
            && size.height > size.width && abs(topInset - 62) < 1
    }
}

/// Presentation reads the store's deadline. It never schedules or commits a shower.
@MainActor struct SkyShowerTrail: View {
    let deadline: Date?
    let interval: TimeInterval
    let paused: Bool
    let arriving: Bool
    let quiet: Bool
    var island = false
    var forecast: [IncomingStar] = []

    var body: some View {
        // Resolve the shared cast outside the frame closure; no artwork generation per frame.
        let miniatures = forecast.prefix(FallingSky.maximumShowerSize).map {
            Image(uiImage: StarCast.image(for: $0.kind))
        }
        TimelineView(.periodic(from: .now, by: quiet ? 1 : 1.0/30)) { context in
            let remaining = max(0, deadline?.timeIntervalSince(context.date) ?? interval)
            let progress = arriving ? 1 : max(0, min(1, 1-remaining/interval))
            Canvas { drawing, size in
                if island {
                    drawIsland(in: &drawing, size: size, progress: progress, miniatures: miniatures)
                    return
                }
                let inset: CGFloat = 12
                let start = CGPoint(x: inset, y: size.height/2)
                let end = CGPoint(x: size.width-inset, y: start.y)
                let head = CGPoint(x: start.x+(end.x-start.x)*progress, y: start.y)
                var track = Path(); track.move(to: start); track.addLine(to: end)
                drawing.stroke(track, with: .color(StarfallTheme.Colors.skyTop.opacity(0.9)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                drawing.stroke(track, with: .color(StarfallTheme.Colors.textSecondary.opacity(0.48)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                var tail = Path(); tail.move(to: start); tail.addLine(to: head)
                let light = GraphicsContext.Shading.linearGradient(
                    Gradient(colors: [StarfallTheme.Colors.actionPrimary.opacity(0.12), StarfallTheme.Colors.actionPrimary, StarfallTheme.Colors.textPrimary]),
                    startPoint: start, endPoint: CGPoint(x: max(start.x+1, head.x), y: head.y))
                drawing.drawLayer { glow in
                    glow.addFilter(.blur(radius: 3))
                    glow.stroke(tail, with: light, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                }
                drawing.stroke(tail, with: light, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                if !quiet {
                    // Eight analytic particles: no random state, allocation pool, emitter or completions.
                    for index in 0..<8 {
                        let age = (progress*3 + Double(index)/8).truncatingRemainder(dividingBy: 1)
                        let x = head.x-CGFloat(age)*42
                        guard x > start.x else { continue }
                        let drift = sin(Double(index)*2.4+age*5)*age*8
                        let radius: CGFloat = index.isMultiple(of: 3) ? 1.3 : 0.8
                        let point = CGPoint(x: x, y: head.y+drift)
                        let dust = CGRect(x: point.x-radius, y: point.y-radius, width: radius*2, height: radius*2)
                        drawing.fill(Path(ellipseIn: dust), with: .color((index.isMultiple(of: 2) ? StarfallTheme.Observatory.lanternGlow : StarfallTheme.Colors.actionPrimary).opacity((1-age)*0.9)))
                    }
                }
                drawForecast(in: &drawing, miniatures: miniatures, progress: progress,
                             spacing: 16 / (end.x - start.x), diameter: 14) { fraction in
                    CGPoint(x: start.x + (end.x - start.x) * fraction, y: start.y)
                }
            }
            .frame(width: island ? StarfallTheme.IslandTimer.width : StarfallTheme.Layout.showerTrailWidth,
                   height: island ? StarfallTheme.IslandTimer.height : 28)
            .opacity(paused ? 0 : 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(paused ? "Sky paused" : arriving ? "Stars arriving" : remaining <= 1.25 ? "Shower approaching" : "Sky flowing")
            .accessibilityValue(forecast.map {
                StarCast.character(for: $0.kind).description
            }.joined(separator: ", then "))
            .accessibilityIdentifier("experiment.arrivalCue")
        }
    }

    /// The upper capsule contour is sampled by distance; head and trail share one mapping.
    /// Only the calibrated placement policy can select this authored camera profile.
    private func drawIsland(in drawing: inout GraphicsContext, size: CGSize, progress: Double, miniatures: [Image]) {
        let camera = CGRect(x: (size.width - StarfallTheme.IslandTimer.cameraSize.width) / 2,
                            y: StarfallTheme.IslandTimer.cameraTop,
                            width: StarfallTheme.IslandTimer.cameraSize.width,
                            height: StarfallTheme.IslandTimer.cameraSize.height)
        drawing.fill(Path(roundedRect: camera, cornerRadius: camera.height / 2), with: .color(.black))
        let radius = StarfallTheme.IslandTimer.radius
        let top = StarfallTheme.IslandTimer.top
        let left = CGPoint(x: radius + 4, y: top + radius)
        let right = CGPoint(x: size.width - radius - 4, y: left.y)
        let arc = CGFloat.pi * radius / 2
        let straight = right.x - left.x
        let length = 2 * arc + straight
        func point(_ fraction: CGFloat) -> CGPoint {
            let distance = min(1, max(0, fraction)) * length
            if distance < arc {
                let angle = CGFloat.pi + distance / radius
                return CGPoint(x: left.x + cos(angle) * radius, y: left.y + sin(angle) * radius)
            }
            if distance <= arc + straight {
                return CGPoint(x: left.x + distance - arc, y: top)
            }
            let angle = -CGFloat.pi / 2 + (distance - arc - straight) / radius
            return CGPoint(x: right.x + cos(angle) * radius, y: right.y + sin(angle) * radius)
        }
        func path(to fraction: CGFloat) -> Path {
            Path { path in
                path.move(to: point(0))
                for step in 1...96 { path.addLine(to: point(fraction * CGFloat(step) / 96)) }
            }
        }
        let fraction = CGFloat(progress)
        let tail = path(to: fraction)
        let light = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [StarfallTheme.Colors.actionPrimary.opacity(0.4),
                              StarfallTheme.Colors.actionPrimary, StarfallTheme.Colors.textSecondary]),
            startPoint: point(0), endPoint: point(1))
        drawing.stroke(path(to: 1), with: .color(StarfallTheme.Colors.progressTrack.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        if !quiet {
            drawing.drawLayer { glow in
                glow.addFilter(.blur(radius: 2))
                glow.stroke(tail, with: light, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
        }
        drawing.stroke(tail, with: light, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        drawForecast(in: &drawing, miniatures: miniatures, progress: progress,
                     spacing: 0.105, diameter: 10, point: point)
    }

    private func drawForecast(in drawing: inout GraphicsContext, miniatures: [Image], progress: Double,
                              spacing: CGFloat, diameter: CGFloat, point: (CGFloat) -> CGPoint) {
        // First committed arrival leads right; following stars trail in the same order.
        // Fixed spacing keeps the complete preview visible at the start of the countdown.
        let trainLength = CGFloat(max(0, miniatures.count - 1)) * spacing
        let lead = trainLength + (1 - trainLength) * CGFloat(progress)
        for (index, miniature) in miniatures.enumerated() {
            let center = point(lead - CGFloat(index) * spacing)
            drawing.draw(miniature, in: CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2,
                                              width: diameter, height: diameter))
        }
    }

}

/// Contextual guide uses the real cast material; routine arrivals do not create chatter.
@MainActor struct SkyGuideCard<Actions: View>: View {
    let title: String
    let message: String
    var titleIdentifier = "sky.guide.title"
    var titleRole: StarfallTheme.Typography.GuideTitleRole = .character
    var showsPortrait = true
    @ViewBuilder let actions: Actions
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        VStack(alignment: .leading, spacing: StarfallTheme.Spacing.small) {
            HStack(alignment: .top, spacing: StarfallTheme.Spacing.medium) {
                if showsPortrait && !textSize.isAccessibilitySize {
                    Image(uiImage: StarCast.image(for: .amber, expression: .idle))
                        .resizable().scaledToFit().frame(width: 48, height: 48)
                        .background(Circle().fill(StarfallTheme.Observatory.lanternGlow.opacity(0.12)))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: StarfallTheme.Spacing.compact) {
                    Text(title).font(StarfallTheme.Typography.skyHeading)
                        .dynamicTypeSize(...titleRole.maximumTextSize)
                        .accessibilityIdentifier(titleIdentifier)
                        .foregroundStyle(StarfallTheme.Observatory.lanternGlow)
                    Text(message).font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("experiment.message")
                }
            }
            actions
        }
        .padding(StarfallTheme.Spacing.medium)
        .background(StarfallTheme.Colors.skyTop.opacity(0.95), in: RoundedRectangle(cornerRadius: StarfallTheme.Radius.panel))
        .overlay(alignment: .top) {
            LinearGradient(colors: [.clear, StarfallTheme.Observatory.lanternGlow.opacity(0.7), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 1).padding(.horizontal, StarfallTheme.Spacing.large)
        }
        .frame(maxWidth: StarfallTheme.Layout.menuWidth)
    }
}
