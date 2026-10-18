import SwiftUI
import StarfallCore

/// A receipt for an already committed clear. Never encoded or used to award points.
struct StarlightCelebration: Equatable, Identifiable {
    enum Level: Equatable { case ordinary, brilliant, constellation, recipe(StarRecipe.Shape), relay(Int) }
    let id: UInt64
    let started: Date
    let collected: Int
    let total: Int
    let cells: [Cell]
    let path: [Cell]
    let level: Level
    static let duration: TimeInterval = 1.15
    var title: String? {
        switch level {
        case .ordinary: nil
        case .brilliant: "BRILLIANT!"
        case .constellation: "CONSTELLATION!"
        case .recipe(let shape): shape == .square ? "SQUARE!" : "CROSS!"
        case .relay(let depth): "\(depth)-CLEAR RELAY!"
        }
    }

    init?(id: UInt64, turn: FallingSkyTurn, from old: FallingSky, total: Int,
          path: [Cell] = [], recipe: StarRecipe? = nil, relayDepth: Int = 0, started: Date = .now) {
        guard turn.collected > 0 else { return nil }
        let cells = turn.cleared.filter { old.reward(of: [$0]) > 0 }
            .sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        guard !cells.isEmpty else { return nil }
        self.id = id; self.started = started; self.collected = turn.collected
        self.total = total; self.cells = cells
        // Only the validated input path supplied by the store names a constellation.
        self.path = recipe?.presentationPath ?? path
        if relayDepth > 1 { level = .relay(relayDepth) }
        else if let recipe { level = .recipe(recipe.shape) }
        else { level = path.isEmpty ? (turn.collected >= 8 ? .brilliant : .ordinary) : .constellation }
    }
}

enum StarlightAnchor: Hashable { case board, score, header }
struct StarlightAnchors: PreferenceKey {
    static var defaultValue: [StarlightAnchor: Anchor<CGRect>] { [:] }
    static func reduce(value: inout [StarlightAnchor: Anchor<CGRect>], nextValue: () -> [StarlightAnchor: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    /// Adds one role without replacing anchors registered by descendants (score inside header).
    func starlightAnchor(_ role: StarlightAnchor) -> some View {
        transformAnchorPreference(key: StarlightAnchors.self, value: .bounds) { anchors, anchor in
            anchors[role] = anchor
        }
    }
}

/// Only this small subtree ticks. Board projection and the real header anchor share
/// the overlay's coordinate space; no screen-size assumptions or per-frame state writes.
struct StarlightCelebrationOverlay: View {
    let event: StarlightCelebration
    let board: CGRect
    let score: CGRect
    let header: CGRect
    let quiet: Bool
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: quiet)) { timeline in
            let age = quiet ? 0.3 : max(0, timeline.date.timeIntervalSince(event.started))
            let fade = quiet ? 1 : min(1, max(0, (StarlightCelebration.duration - age) / 0.22))
            ZStack(alignment: .topLeading) {
                if !quiet {
                    Canvas { context, _ in draw(in: &context, age: age) }
                }
                // At large text sizes use available header-adjacent space and native wrapping.
                VStack(spacing: StarfallTheme.Spacing.compact) {
                    if showsTitle, let title = event.title {
                        Text(title)
                            .font(StarfallTheme.Typography.celebrationTitle)
                            .foregroundStyle(StarfallTheme.Observatory.lanternGlow)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text("+\(event.collected)")
                        .font(StarfallTheme.Typography.celebrationAward)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .monospacedDigit()
                }
                .multilineTextAlignment(.center)
                .shadow(color: StarfallTheme.Colors.skyTop, radius: 3)
                .shadow(color: StarfallTheme.Observatory.lanternGlow.opacity(0.6), radius: quiet ? 0 : 8)
                .frame(width: calloutWidth)
                .scaleEffect(quiet ? 1 : 1 + 0.12 * sin(min(1, max(0, age - 0.06) / 0.22) * .pi))
                .offset(x: calloutX, y: calloutY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .opacity(fade)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var mapping: ObservatoryGeometry { ObservatoryGeometry(size: board.size) }
    private var hasSkyRoom: Bool { mapping.frame(Cell(6, 3)).minY + board.minY - header.maxY >= 88 }
    private var showsTitle: Bool { !textSize.isAccessibilitySize && hasSkyRoom }
    private var usesLocalAward: Bool { !textSize.isAccessibilitySize && !hasSkyRoom }
    private var calloutWidth: CGFloat { usesLocalAward ? 128 : max(1, board.width - 32) }
    private var awardOrigin: CGPoint {
        let points = event.cells.map(location)
        return CGPoint(x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
                       y: points.map(\.y).reduce(0, +) / CGFloat(points.count))
    }
    private var calloutX: CGFloat {
        usesLocalAward ? max(board.minX + 8, min(board.maxX - 136, awardOrigin.x - 64)) : board.minX + 16
    }
    private var calloutY: CGFloat {
        if textSize.isAccessibilitySize { return mapping.frame(Cell(0, 3)).maxY + board.minY + 8 }
        if usesLocalAward { return awardOrigin.y - 48 }
        return max(header.maxY + 8, mapping.frame(Cell(6, 3)).minY + board.minY - 80)
    }

    private func location(_ cell: Cell) -> CGPoint {
        let local = ObservatoryGeometry(size: board.size).viewPoint(cell)
        return CGPoint(x: local.x + board.minX, y: local.y + board.minY)
    }

    private func draw(in context: inout GraphicsContext, age: Double) {
        guard age < StarlightCelebration.duration else { return }
        let points = event.cells.map(location)
        let origin = CGPoint(x: points.map(\.x).reduce(0, +) / CGFloat(points.count),
                             y: points.map(\.y).reduce(0, +) / CGFloat(points.count))
        let gold = StarfallTheme.Observatory.lanternGlow
        let cyan = StarfallTheme.Colors.actionPrimary
        let strong = event.level != .ordinary
        let step = ObservatoryGeometry(size: board.size).imageRect.width / 7.7
        if age < 0.5 {
            let release = min(1, max(0, (age - 0.08) / 0.4))
            var pulse = context
            pulse.opacity = (1 - release) * (strong ? 0.95 : 0.6)
            // One finite budget per clear, independent of the selected star count.
            for index in 0..<(strong ? 24 : 10) {
                let angle = Double(index) * 2.39996
                let reach = Double((index * 7) % 13) / 12
                let distance = step * (0.08 + 0.35 * reach + release * (0.5 + 1.6 * reach))
                let point = CGPoint(x: origin.x + cos(angle) * distance, y: origin.y + sin(angle) * distance * 0.72)
                glint(in: &pulse, at: point, radius: index.isMultiple(of: 3) ? 4 : 2, color: index.isMultiple(of: 2) ? gold : cyan)
            }
            if !event.path.isEmpty {
                var outline = Path()
                outline.addLines(event.path.map(location))
                pulse.stroke(outline, with: .color(.white), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        // Six packets maximum. All represent one committed award, not individual points.
        let destination = CGPoint(x: score.midX, y: score.midY)
        for (index, point) in points.prefix(6).enumerated() {
            let t = min(1, max(0, (age - 0.15 - Double(index) * 0.025) / 0.48))
            guard t > 0, t < 1 else { continue }
            let control = CGPoint(x: point.x - board.width * 0.18, y: destination.y + (point.y - destination.y) * 0.35)
            func along(_ progress: Double) -> CGPoint {
                let u = 1 - progress
                return CGPoint(x: u*u*point.x + 2*u*progress*control.x + progress*progress*destination.x,
                               y: u*u*point.y + 2*u*progress*control.y + progress*progress*destination.y)
            }
            var tail = Path()
            tail.addLines((0...12).map { along(max(0, t - 0.22 + Double($0) / 12 * 0.22)) })
            var glow = context
            glow.addFilter(.shadow(color: cyan, radius: 4))
            glow.stroke(tail, with: .color(index.isMultiple(of: 2) ? cyan : gold), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            glint(in: &glow, at: along(t), radius: strong ? 5 : 3.5, color: .white)
        }
        if age > 0.58 {
            let t = min(1, (age - 0.58) / 0.5)
            var bloom = context
            bloom.opacity = sin(t * .pi) * 0.9
            bloom.addFilter(.shadow(color: gold, radius: 5))
            let bounds = score.insetBy(dx: -8 - 5*t, dy: -3 - 3*t)
            bloom.stroke(Path(roundedRect: bounds, cornerRadius: 18), with: .color(gold), lineWidth: 1.5)
            glint(in: &bloom, at: CGPoint(x: score.maxX + 8, y: score.minY), radius: 5, color: gold)
        }
    }

    private func glint(in context: inout GraphicsContext, at point: CGPoint, radius: CGFloat, color: Color) {
        var star = Path()
        star.move(to: CGPoint(x: point.x, y: point.y - radius))
        star.addLines([CGPoint(x: point.x + radius*0.3, y: point.y - radius*0.3), CGPoint(x: point.x + radius, y: point.y),
                       CGPoint(x: point.x + radius*0.3, y: point.y + radius*0.3), CGPoint(x: point.x, y: point.y + radius),
                       CGPoint(x: point.x - radius*0.3, y: point.y + radius*0.3), CGPoint(x: point.x - radius, y: point.y),
                       CGPoint(x: point.x - radius*0.3, y: point.y - radius*0.3)])
        star.closeSubpath()
        context.fill(star, with: .color(color))
    }
}
