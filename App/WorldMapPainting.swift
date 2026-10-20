import SwiftUI
import UIKit
import StarfallCore

/// One island's image, pointer and native target share a local coordinate map.
/// The source's transparent padding is retained and receives additional logical
/// clearance; no subject is cropped or stretched to fill a cell.
struct WorldMapIslandGeometry {
    let size: CGSize
    let artworkFrame: CGRect
    let pinFrame: CGRect
    let nameFrame: CGRect

    static func fittedCanvasSide(maximum: CGFloat, maximumNodeHeight: CGFloat?,
                                 registration: WorldMapIslandRegistration, measuredNameHeight: CGFloat) -> CGFloat {
        guard let height = maximumNodeHeight, height.isFinite, height > 0 else { return maximum }
        let fitted = min(height, (height - 8 - measuredNameHeight) / (1 - registration.canvasInset))
        return min(maximum, max(WorldMapLayout.minimumIslandSide, fitted))
    }

    init(registration: WorldMapIslandRegistration, canvasSide: CGFloat, nameSize: CGSize) {
        guard canvasSide.isFinite, canvasSide > 0,
              registration.sourceSize.width.isFinite, registration.sourceSize.width > 0,
              registration.sourceSize.height.isFinite, registration.sourceSize.height > 0,
              nameSize.width.isFinite, nameSize.height.isFinite else {
            size = .zero; artworkFrame = .zero; pinFrame = .zero; nameFrame = .zero
            return
        }
        let available = canvasSide * (1 - registration.canvasInset * 2)
        let scale = min(available / registration.sourceSize.width, available / registration.sourceSize.height)
        let imageSize = CGSize(width: registration.sourceSize.width * scale, height: registration.sourceSize.height * scale)
        let image = CGRect(x: (canvasSide - imageSize.width) / 2, y: (canvasSide - imageSize.height) / 2,
                           width: imageSize.width, height: imageSize.height)
        let tip = Self.point(registration.markerAnchor, in: image)
        let pin = CGRect(x: tip.x - WorldMapMarkerMetrics.pinSize.width / 2, y: tip.y - WorldMapMarkerMetrics.pinTipY,
                         width: WorldMapMarkerMetrics.pinSize.width, height: WorldMapMarkerMetrics.pinSize.height)
        let name = CGRect(x: (canvasSide - nameSize.width) / 2, y: image.maxY + 8,
                          width: nameSize.width, height: nameSize.height)
        let union = CGRect(x: 0, y: 0, width: canvasSide, height: canvasSide).union(pin).union(name)
        size = union.size
        artworkFrame = image.offsetBy(dx: -union.minX, dy: -union.minY)
        pinFrame = pin.offsetBy(dx: -union.minX, dy: -union.minY)
        nameFrame = name.offsetBy(dx: -union.minX, dy: -union.minY)
    }

    static func point(_ normalized: CGPoint, in frame: CGRect) -> CGPoint {
        CGPoint(x: frame.minX + normalized.x * frame.width, y: frame.minY + normalized.y * frame.height)
    }
}

/// The destination world is intentionally taller than a compact viewport.
/// Parents scroll this content; they never squeeze labels or terrain to make an
/// overview fit above the selected-place card.
struct WorldMapLayout {
    static let minimumIslandSide: CGFloat = 220
    static let minimumViewportHeight: CGFloat = 280
    /// Leave breathing room for focused targets and ordinary finger scrolling
    /// instead of requiring a nearly exact stop against a clipped edge.
    static let targetViewportInset: CGFloat = 12
    static let rowSpacing: CGFloat = 24
    static let verticalPadding: CGFloat = 16
    let size: CGSize
    let columns: Int
    let islandSide: CGFloat
    private let frames: [WorldLocation: CGRect]

    static func columnCount(width: CGFloat, count: Int) -> Int {
        count <= 1 || width < 700 ? 1 : width >= 1050 ? 3 : 2
    }

    /// SwiftUI asks Layouts for unspecified and infinite maximum-size probes.
    /// Those are proposals, not actual viewport dimensions.
    static func resolvedWidth(_ proposed: CGFloat?, ideal: CGFloat = 375) -> CGFloat {
        guard let proposed, proposed.isFinite else { return ideal }
        return max(0, proposed)
    }

    static func islandSide(width: CGFloat, count: Int) -> CGFloat {
        guard width.isFinite, width > 0 else { return 0 }
        let columns = columnCount(width: width, count: count)
        let maximum: CGFloat = width < 700 || columns == 3 ? 300 : 320
        return min(maximum, max(0, (width - 32 - 24 * CGFloat(columns - 1)) / CGFloat(columns)))
    }

    /// Tablet rows share the available viewport. Below the measured minimum
    /// row budget, the world grows and remains scrollable instead of shrinking
    /// its native names or terrain.
    static func nodeHeightLimit(width: CGFloat, viewportHeight: CGFloat?, count: Int) -> CGFloat? {
        guard let height = viewportHeight, height.isFinite, height > 0 else { return nil }
        guard width >= 700, count > 0 else { return height }
        let columns = columnCount(width: width, count: count)
        let rows = (count + columns - 1) / columns
        let rowBudget = (height - verticalPadding * 2 - rowSpacing * CGFloat(rows - 1)) / CGFloat(rows)
        return max(minimumViewportHeight, rowBudget)
    }

    init(width: CGFloat, content: WorldMapContent, nodeSizes: [WorldLocation: CGSize], minimumHeight: CGFloat = 0) {
        columns = Self.columnCount(width: width, count: content.islands.count)
        let measuredSide = Self.islandSide(width: width, count: content.islands.count)
        islandSide = measuredSide
        guard width.isFinite, width > 0, !content.islands.isEmpty else { size = .zero; frames = [:]; return }
        let horizontalGap: CGFloat = 24
        let verticalGap = Self.rowSpacing
        let padding = Self.verticalPadding
        var remaining = content.islands.map(\.location)
        var rows: [[WorldLocation]] = []
        let startsWithSingle = columns == 2 && content.islands.count % 2 == 1
        while !remaining.isEmpty {
            let firstCount = startsWithSingle ? 1 : columns
            let count = min(rows.isEmpty ? firstCount : columns, remaining.count)
            let chunk = Array(remaining.prefix(count))
            remaining.removeFirst(count)
            let forward = rows.isEmpty || (startsWithSingle ? rows.count % 2 == 1 : rows.count % 2 == 0)
            rows.append(forward ? chunk : Array(chunk.reversed()))
        }
        // Progress travels upward; a one-island proof uses the same layout path.
        rows.reverse()
        let heights = rows.map { row in
            row.map { nodeSizes[$0]?.height ?? measuredSide }.max() ?? measuredSide
        }
        let naturalHeight = heights.reduce(0, +) + verticalGap * CGFloat(max(0, rows.count - 1)) + padding * 2
        let height = max(naturalHeight, minimumHeight.isFinite ? minimumHeight : 0)
        let rowGap = rows.count > 1 ? verticalGap + (height - naturalHeight) / CGFloat(rows.count - 1) : verticalGap
        var y = padding + (rows.count == 1 ? (height - naturalHeight) / 2 : 0)
        var placed: [WorldLocation: CGRect] = [:]
        for (index, row) in rows.enumerated() {
            let rowWidth = row.reduce(CGFloat(0)) { $0 + (nodeSizes[$1]?.width ?? measuredSide) }
                + horizontalGap * CGFloat(max(0, row.count - 1))
            let windingOffset: CGFloat = columns == 1 && content.islands.count > 1
                ? min(18, max(0, (width - rowWidth) / 2 - padding)) * (index.isMultiple(of: 2) ? -1 : 1) : 0
            var x = (width - rowWidth) / 2 + windingOffset
            for location in row {
                let node = nodeSizes[location] ?? CGSize(width: islandSide, height: islandSide)
                placed[location] = CGRect(x: x, y: y + (heights[index] - node.height) / 2,
                                          width: node.width, height: node.height)
                x += node.width + horizontalGap
            }
            y += heights[index] + rowGap
        }
        size = CGSize(width: width, height: height)
        frames = placed
    }

    func nodeFrame(_ location: WorldLocation) -> CGRect { frames[location] ?? .zero }
}

struct WorldMapPainting: View {
    let journey: WorldJourney
    let selected: WorldLocation
    let quiet: Bool
    let select: (WorldLocation) -> Void
    var maximumNodeHeight: CGFloat? = nil
    var content: WorldMapContent = .production

    var body: some View {
        WorldMapScene(content: content, presentation: WorldMapPresentation(journey: journey, selected: selected),
                      quiet: quiet, maximumNodeHeight: maximumNodeHeight, select: select)
    }
}

/// A declarative read-only scene: independently placed islands, native routes
/// and marker controls. The parent supplies scrolling and reserved card space.
struct WorldMapScene: View {
    let content: WorldMapContent
    let presentation: WorldMapPresentation
    let quiet: Bool
    let maximumNodeHeight: CGFloat?
    let select: (WorldLocation) -> Void

    var body: some View {
        WorldMapLayerLayout(content: content, maximumNodeHeight: maximumNodeHeight) {
            ForEach(content.islands) { artwork in
                if let destination = presentation.destination(artwork.location) {
                    WorldMapIslandNode(artwork: artwork, presentation: destination,
                                       selected: presentation.selected == artwork.location,
                                       maximumNodeHeight: maximumNodeHeight, action: { select(artwork.location) })
                        .id(artwork.location)
                }
            }
        }
        .backgroundPreferenceValue(WorldMapArtworkAnchors.self) { anchors in
            GeometryReader { geometry in
                Canvas { context, _ in
                    for connection in content.connections {
                        guard let sourceAnchor = anchors[connection.source], let destinationAnchor = anchors[connection.destination],
                              let source = content.islands.first(where: { $0.location == connection.source }),
                              let destination = content.islands.first(where: { $0.location == connection.destination }) else { continue }
                        let route = WorldMapRouteGeometry.path(source: geometry[sourceAnchor], destination: geometry[destinationAnchor],
                                                               sourceRegistration: source.registration, destinationRegistration: destination.registration)
                        let restored = presentation.destination(connection.source)?.restored == true
                        // Keep individual route dots legible over bright nebula
                        // without changing the path or moving any native target.
                        context.stroke(route, with: .color(StarfallTheme.Colors.skyTop.opacity(0.85)),
                                       style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 7]))
                        context.stroke(route, with: .color(restored ? StarfallTheme.Colors.actionPrimary.opacity(0.90)
                                                                 : StarfallTheme.Colors.textPrimary.opacity(0.65)),
                                       style: StrokeStyle(lineWidth: restored ? 2 : 1.5, lineCap: .round, dash: [2, 7]))
                    }
                }
                .allowsHitTesting(false).accessibilityHidden(true)
            }
        }
    }
}

private struct WorldMapLayerLayout: Layout {
    let content: WorldMapContent
    let maximumNodeHeight: CGFloat?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(width: WorldMapLayout.resolvedWidth(proposal.width), subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = WorldMapLayout.resolvedWidth(bounds.width)
        let world = layout(width: width, subviews: subviews)
        let nodeHeight = WorldMapLayout.nodeHeightLimit(width: width, viewportHeight: maximumNodeHeight, count: content.islands.count)
        for (index, artwork) in content.islands.enumerated() where index < subviews.count {
            let frame = world.nodeFrame(artwork.location)
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                 anchor: .topLeading, proposal: ProposedViewSize(width: world.islandSide, height: nodeHeight))
        }
    }

    private func layout(width: CGFloat, subviews: Subviews) -> WorldMapLayout {
        let side = WorldMapLayout.islandSide(width: width, count: content.islands.count)
        let nodeHeight = WorldMapLayout.nodeHeightLimit(width: width, viewportHeight: maximumNodeHeight, count: content.islands.count)
        let sizes = Dictionary(uniqueKeysWithValues: content.islands.enumerated().compactMap { index, artwork in
            index < subviews.count ? (artwork.location, subviews[index].sizeThatFits(ProposedViewSize(width: side, height: nodeHeight))) : nil
        })
        return WorldMapLayout(width: width, content: content, nodeSizes: sizes)
    }
}

private struct WorldMapArtworkAnchors: PreferenceKey {
    static var defaultValue: [WorldLocation: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [WorldLocation: Anchor<CGRect>], nextValue: () -> [WorldLocation: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, next in next })
    }
}

struct WorldMapRouteGeometry {
    static func path(source: CGRect, destination: CGRect, sourceRegistration: WorldMapIslandRegistration,
                     destinationRegistration: WorldMapIslandRegistration) -> Path {
        guard !source.isEmpty, !destination.isEmpty else { return Path() }
        let horizontal = abs(destination.midX - source.midX) > abs(destination.midY - source.midY)
        let forward = horizontal ? destination.midX > source.midX : destination.midY > source.midY
        let startPort = horizontal ? (forward ? sourceRegistration.trailingPort : sourceRegistration.leadingPort)
            : (forward ? sourceRegistration.lowerPort : sourceRegistration.upperPort)
        let endPort = horizontal ? (forward ? destinationRegistration.leadingPort : destinationRegistration.trailingPort)
            : (forward ? destinationRegistration.upperPort : destinationRegistration.lowerPort)
        let start = WorldMapIslandGeometry.point(startPort, in: source)
        let end = WorldMapIslandGeometry.point(endPort, in: destination)
        let middle = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        return Path { path in
            path.move(to: start)
            path.addCurve(to: end,
                          control1: horizontal ? CGPoint(x: middle.x, y: start.y) : CGPoint(x: start.x, y: middle.y),
                          control2: horizontal ? CGPoint(x: middle.x, y: end.y) : CGPoint(x: end.x, y: middle.y))
        }
    }
}

struct WorldMapIslandNode: View {
    let artwork: WorldMapIslandArtwork
    let presentation: WorldMapDestinationPresentation
    let selected: Bool
    var maximumNodeHeight: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        WorldMapMarker(presentation: presentation, selected: selected, action: action) {
            WorldMapIslandLayout(registration: artwork.registration, maximumNodeHeight: maximumNodeHeight) {
                WorldMapAsset(name: artwork.asset(restored: presentation.restored))
                    .anchorPreference(key: WorldMapArtworkAnchors.self, value: .bounds) { [artwork.location: $0] }
                WorldMapMarkerPin(glyph: presentation.glyph, selected: selected)
                WorldMapNameplate(title: presentation.title, selected: selected)
            }
        }
    }
}

private struct WorldMapIslandLayout: Layout {
    let registration: WorldMapIslandRegistration
    let maximumNodeHeight: CGFloat?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        geometry(side: WorldMapLayout.resolvedWidth(proposal.width, ideal: 300), proposedHeight: proposal.height, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 3 else { return }
        let map = geometry(side: WorldMapLayout.resolvedWidth(proposal.width, ideal: 300), proposedHeight: proposal.height, subviews: subviews)
        for (index, frame) in [map.artworkFrame, map.pinFrame, map.nameFrame].enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                 anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func geometry(side: CGFloat, proposedHeight: CGFloat?, subviews: Subviews) -> WorldMapIslandGeometry {
        guard subviews.count == 3 else {
            return WorldMapIslandGeometry(registration: registration, canvasSide: side, nameSize: .zero)
        }
        // Measure at the smallest allowed canvas first. A wider final label can
        // only be shorter, so fitting never relies on shrinking native text.
        let narrowNameWidth = max(44, min(side, WorldMapLayout.minimumIslandSide) - 32)
        let maximumNameHeight = subviews[2].sizeThatFits(ProposedViewSize(width: narrowNameWidth, height: nil)).height
        let heightLimit = [maximumNodeHeight, proposedHeight].compactMap { $0 }.filter { $0.isFinite && $0 > 0 }.min()
        let fittedSide = WorldMapIslandGeometry.fittedCanvasSide(maximum: side, maximumNodeHeight: heightLimit,
                                                                 registration: registration, measuredNameHeight: maximumNameHeight)
        let nameWidth = min(240, max(44, fittedSide - 32))
        let nameSize = subviews.count == 3 ? subviews[2].sizeThatFits(ProposedViewSize(width: nameWidth, height: nil)) : .zero
        return WorldMapIslandGeometry(registration: registration, canvasSide: fittedSide, nameSize: nameSize)
    }
}

/// Missing production assets stay visibly absent during the native component
/// proof. A legacy full-page painting is never substituted for an island.
private struct WorldMapAsset: View {
    private let image: UIImage?
    var fills = false
    init(name: String, fills: Bool = false) { image = UIImage(named: name); self.fills = fills }
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().aspectRatio(contentMode: fills ? .fill : .fit)
            }
            else { Color.clear }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Independent scenery fills the actual viewport, regardless of island layout.
/// Only the cloud/glint subtree receives frame updates; islands and hit targets
/// do not move and asset loading stays outside that timeline.
struct WorldMapBackdrop: View {
    let quiet: Bool
    var body: some View {
        GeometryReader { geometry in
            SkyBackdrop()
            WorldMapAsset(name: "WorldMapSky", fills: true)
                .frame(width: geometry.size.width, height: geometry.size.height)
            WorldMapAtmosphere(quiet: quiet)
        }
        .clipped().allowsHitTesting(false).accessibilityHidden(true)
    }
}

private struct WorldMapAtmosphere: View {
    let quiet: Bool
    private let cloud = UIImage(named: "WorldMapCloud")
    @Environment(\.scenePhase) private var scenePhase
    @State private var clock = LandingAmbientClock()
    private var running: Bool { scenePhase == .active && !quiet }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: !running)) { _ in
            let phase = quiet ? 0 : clock.phase(at: ProcessInfo.processInfo.systemUptime)
            GeometryReader { geometry in
                if let cloud {
                    ForEach(0..<3) { index in
                        Image(uiImage: cloud).resizable().scaledToFit()
                            .frame(width: geometry.size.width * 0.72)
                            .opacity(index == 1 ? 0.24 : 0.35)
                            .position(x: geometry.size.width * (index == 1 ? 0.78 : 0.18) + CGFloat(sin(phase / 18 + Double(index))) * 14,
                                      y: geometry.size.height * (0.18 + CGFloat(index) * 0.31))
                    }
                }
                Canvas { context, size in
                    for (index, point) in [CGPoint(x: 0.15, y: 0.12), CGPoint(x: 0.82, y: 0.48), CGPoint(x: 0.30, y: 0.88)].enumerated() {
                        let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                        let star = Path(ellipseIn: CGRect(x: center.x - 1.5, y: center.y - 1.5, width: 3, height: 3))
                        context.fill(star, with: .color(StarfallTheme.Colors.ambientStar.opacity(0.35 + 0.15 * sin(phase / 3 + Double(index)))))
                    }
                }
            }
        }
        .onAppear { clock.setRunning(running, at: ProcessInfo.processInfo.systemUptime) }
        .onChange(of: running) { _, value in clock.setRunning(value, at: ProcessInfo.processInfo.systemUptime) }
        .onDisappear { clock.setRunning(false, at: ProcessInfo.processInfo.systemUptime) }
    }
}
