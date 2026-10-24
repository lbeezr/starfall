import SwiftUI
import StarfallCore

/// A static affine fit of the retained earned paths, never a new recipe or award.
struct SkyFinalLightLayout {
    let paths: [[CGPoint]]
    let starPoints: [CGPoint]
    let bounds: CGRect
    let scale: CGFloat

    init?(receipt: SkyFinalLightReceipt, size: CGSize) {
        let maximumEntries = max(ConstellationReturnLayout.maximumWalkEntries,
                                 PatternReturnLayout.maximumPatterns * PatternReturnLayout.maximumPathEntries)
        guard size.width.isFinite, size.height.isFinite, size.width >= 16, size.height >= 16,
              !receipt.paths.isEmpty, receipt.paths.count <= PatternReturnLayout.maximumPatterns,
              receipt.paths.allSatisfy({ $0.count > 1 }),
              receipt.paths.reduce(0, { $0 + $1.count }) <= maximumEntries,
              !receipt.cells.isEmpty, receipt.cells.count <= ConstellationReturnLayout.maximumStars,
              Set(receipt.cells).count == receipt.cells.count,
              Set(receipt.paths.flatMap { $0 }) == Set(receipt.cells),
              receipt.cells.allSatisfy({ (0..<FallingSky.side).contains($0.row) && (0..<FallingSky.side).contains($0.column) }) else { return nil }
        func point(_ cell: Cell) -> CGPoint {
            CGPoint(x: CGFloat(cell.column), y: CGFloat(FallingSky.side - 1 - cell.row))
        }
        let source = receipt.cells.map(point)
        guard let left = source.map(\.x).min(), let right = source.map(\.x).max(),
              let top = source.map(\.y).min(), let bottom = source.map(\.y).max() else { return nil }
        let center = CGPoint(x: (left + right) / 2, y: (top + bottom) / 2)
        scale = min((size.width - 12) / max(1, right - left), (size.height - 12) / max(1, bottom - top))
        let fittedScale = scale
        func fit(_ cell: Cell) -> CGPoint {
            let source = point(cell)
            return CGPoint(x: size.width / 2 + (source.x - center.x) * fittedScale,
                           y: size.height / 2 + (source.y - center.y) * fittedScale)
        }
        paths = receipt.paths.map { $0.map(fit) }
        starPoints = receipt.cells.map(fit)
        bounds = CGRect(x: size.width / 2 - (right - left) * scale / 2,
                        y: size.height / 2 - (bottom - top) * scale / 2,
                        width: (right - left) * scale, height: (bottom - top) * scale)
    }
}

/// A session-only signature stays readable after moving light has finished.
/// It has no animation or delayed callback to restart on resume, and no reward
/// capability. Inactive presentation withdraws both the drawing and caption.
@MainActor struct SkyFinalLightView: View {
    let receipt: SkyFinalLightReceipt
    let active: Bool
    let quiet: Bool
    var identifier = "sky.finalLight"
    @Environment(\.dynamicTypeSize) private var textSize

    var body: some View {
        Group {
            if active {
                let layout = textSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: StarfallTheme.Spacing.compact))
                    : AnyLayout(HStackLayout(spacing: StarfallTheme.Spacing.small))
                layout {
                    Canvas { context, size in
                        if let drawing = SkyFinalLightLayout(receipt: receipt, size: size) {
                            Self.draw(in: &context, layout: drawing, identity: receipt.identity)
                        }
                    }
                    .frame(width: textSize.isAccessibilitySize ? 120 : 88,
                           height: textSize.isAccessibilitySize ? 64 : 56)
                    .accessibilityHidden(true)
                    Text(SkyCopy.text(.finalLightCaption))
                        .font(StarfallTheme.Typography.skyCaption)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(SkyCopy.text(.finalLightCaption))
                .accessibilityIdentifier(identifier)
            }
        }
        .allowsHitTesting(false)
        // Both modes intentionally retain the same static figure. Earlier play
        // keeps its normal motion; this signature never replays light delivery.
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }

    static func draw(in context: inout GraphicsContext, layout: SkyFinalLightLayout, identity: SkyIdentity) {
        let tint = Color(StarCast.Identity(identity).color)
        var outline = Path()
        for points in layout.paths {
            guard let first = points.first else { continue }
            outline.move(to: first)
            for point in points.dropFirst() { outline.addLine(to: point) }
        }
        context.stroke(outline, with: .color(tint.opacity(0.8)),
                       style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        context.stroke(outline, with: .color(StarfallTheme.Colors.textPrimary),
                       style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
        for point in layout.starPoints {
            var glint = Path()
            glint.move(to: CGPoint(x: point.x, y: point.y - 2.5))
            glint.addLines([CGPoint(x: point.x + 0.7, y: point.y - 0.7),
                            CGPoint(x: point.x + 2.5, y: point.y),
                            CGPoint(x: point.x + 0.7, y: point.y + 0.7),
                            CGPoint(x: point.x, y: point.y + 2.5),
                            CGPoint(x: point.x - 0.7, y: point.y + 0.7),
                            CGPoint(x: point.x - 2.5, y: point.y),
                            CGPoint(x: point.x - 0.7, y: point.y - 0.7)])
            glint.closeSubpath()
            context.fill(glint, with: .color(StarfallTheme.Colors.textPrimary))
        }
    }
}
