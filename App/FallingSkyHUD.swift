import SwiftUI
import StarfallCore

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

/// Presentation reads the store's deadline. It never schedules or commits a shower.
@MainActor struct SkyShowerTrail: View {
    let deadline: Date?
    let interval: TimeInterval
    let paused: Bool
    let arriving: Bool
    let quiet: Bool

    var body: some View {
        // Resolve the shared cast outside the frame closure; no artwork generation per frame.
        let star = Image(uiImage: StarCast.image(for: .aqua))
        TimelineView(.periodic(from: .now, by: quiet ? 1 : 1.0/30)) { context in
            let remaining = max(0, deadline?.timeIntervalSince(context.date) ?? interval)
            let progress = arriving ? 1 : max(0, min(1, 1-remaining/interval))
            Canvas { drawing, size in
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
                drawing.drawLayer { halo in
                    halo.addFilter(.shadow(color: StarfallTheme.Colors.skyTop, radius: 2))
                    halo.draw(star, in: CGRect(x: head.x-12, y: head.y-12, width: 24, height: 24))
                }
            }
            .frame(width: StarfallTheme.Layout.showerTrailWidth, height: 28)
            .opacity(paused ? 0 : 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(paused ? "Sky paused" : arriving ? "Stars arriving" : remaining <= 1.25 ? "Shower approaching" : "Sky flowing")
            .accessibilityIdentifier("experiment.arrivalCue")
        }
    }
}

/// Contextual guide uses the real cast material; routine arrivals do not create chatter.
@MainActor struct SkyGuideCard<Actions: View>: View {
    let title: String
    let message: String
    var titleIdentifier = "sky.guide.title"
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
                    Text(title).font(StarfallTheme.Typography.skyHeading).accessibilityIdentifier(titleIdentifier)
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
