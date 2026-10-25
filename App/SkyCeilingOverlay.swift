import SwiftUI
import StarfallCore

/// A read-only account of room below the actual top edge. A full column is a
/// risk rather than a predicted loss: a matching arrival can still grow its top.
struct SkyCeilingSnapshot: Equatable {
    enum Pressure: Equatable { case oneSpace, full }

    struct Column: Identifiable, Equatable {
        let index: Int
        let centerX: CGFloat
        let spaces: Int
        let pressure: Pressure?
        var id: Int { index }
        var number: Int { index + 1 }

        var accessibilityDescription: String {
            if spaces == 0 {
                return SkyCopy.text(.ceilingHeadroomFull, values: ["column": String(number)])
            }
            if spaces == 1 {
                return SkyCopy.text(.ceilingHeadroomOne, values: ["column": String(number)])
            }
            return SkyCopy.text(.ceilingHeadroomMany,
                                values: ["column": String(number), "spaces": String(spaces)])
        }
    }

    let arena: CGRect
    let columns: [Column]
    let showsPressure: Bool
    var warnings: [Column] { columns.filter { $0.pressure != nil } }

    init?(game: FallingSky, mapping: LandingGeometry) {
        self.init(board: game.board, mapping: mapping,
                  showsPressure: !game.usesFullBoardRefill && !game.isOver)
    }

    init?(board: [StarfallGem?], mapping: LandingGeometry, showsPressure: Bool) {
        let arena = mapping.arenaFrame
        guard board.count == FallingSky.side * FallingSky.side,
              arena.minX.isFinite, arena.minY.isFinite,
              arena.width.isFinite, arena.height.isFinite,
              arena.width > 0, arena.height > 0 else { return nil }
        self.arena = arena
        self.showsPressure = showsPressure
        columns = (0..<FallingSky.side).map { column in
            let spaces = FallingSky.side - SkyBoardSettling.height(board, column: column)
            let pressure: Pressure? = showsPressure ? (spaces == 0 ? .full : spaces == 1 ? .oneSpace : nil) : nil
            return Column(index: column, centerX: mapping.viewPoint(Cell(6, column)).x,
                          spaces: spaces, pressure: pressure)
        }
    }
}

/// Scenery never supplies this boundary. This passive layer shares its geometry
/// with the stars and native cells, and owns no input, clock, animation or rule.
struct SkyCeilingOverlay: View {
    static let topClearance: CGFloat = 44
    static let baseMarkerHeight: CGFloat = 24
    /// The semantic boundary includes the complete scaled badge and its outer
    /// stroke, so reading layouts can reveal it below their pinned header.
    static func requiredTopClearance(markerHeight: CGFloat) -> CGFloat {
        max(topClearance, markerHeight + 12)
    }
    let game: FallingSky
    let mapping: LandingGeometry

    var body: some View {
        if let snapshot = SkyCeilingSnapshot(game: game, mapping: mapping) {
            let clearance = Self.requiredTopClearance(markerHeight: markerHeight)
            ZStack(alignment: .topLeading) {
                ceiling(snapshot)
                    .stroke(StarfallTheme.Colors.skyTop.opacity(0.94),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .accessibilityHidden(true)
                ceiling(snapshot)
                    .stroke(StarfallTheme.Colors.textPrimary.opacity(snapshot.showsPressure ? 0.86 : 0.52),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .accessibilityHidden(true)
                ForEach(snapshot.warnings) { column in
                    marker(column)
                        .position(x: column.centerX, y: snapshot.arena.minY - markerHeight / 2 - 8)
                        .accessibilityHidden(true)
                }
                Color.clear
                    .frame(width: snapshot.arena.width, height: clearance)
                    .position(x: snapshot.arena.midX, y: snapshot.arena.minY - clearance / 2)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(SkyCopy.text(snapshot.showsPressure ? .ceilingLabel : .ceilingBoardEdge))
                    .accessibilityValue(snapshot.showsPressure
                        ? snapshot.columns.map(\.accessibilityDescription).joined(separator: " ") : "")
                    .accessibilityHint(snapshot.showsPressure ? SkyCopy.text(.ceilingHint) : "")
                    .accessibilityIdentifier("sky.ceiling")
            }
            .frame(width: mapping.size.width, height: mapping.size.height)
            .allowsHitTesting(false)
            .transaction { $0.animation = nil }
        }
    }

    @ScaledMetric(relativeTo: .caption) private var markerHeight: CGFloat = SkyCeilingOverlay.baseMarkerHeight

    private func ceiling(_ snapshot: SkyCeilingSnapshot) -> Path {
        Path { path in
            let top = snapshot.arena.minY
            let bracket = min(10, mapping.starStep * 0.18)
            path.move(to: CGPoint(x: snapshot.arena.minX, y: top + bracket))
            path.addLine(to: CGPoint(x: snapshot.arena.minX, y: top))
            path.addLine(to: CGPoint(x: snapshot.arena.maxX, y: top))
            path.addLine(to: CGPoint(x: snapshot.arena.maxX, y: top + bracket))
            for column in 1..<FallingSky.side {
                let x = snapshot.arena.minX + CGFloat(column) * mapping.starStep
                path.move(to: CGPoint(x: x, y: top))
                path.addLine(to: CGPoint(x: x, y: top - 4))
            }
        }
    }

    private func marker(_ column: SkyCeilingSnapshot.Column) -> some View {
        let full = column.pressure == .full
        return HStack(spacing: 2) {
            Text(String(column.number))
            if full { Text("!") }
        }
        .font(StarfallTheme.Typography.skyCaption.weight(.bold))
        .monospacedDigit()
        .foregroundStyle(full ? StarfallTheme.Colors.onActionPrimary : StarfallTheme.Colors.textPrimary)
        .padding(.horizontal, 5)
        .frame(minHeight: markerHeight)
        .background {
            Capsule().fill(full ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.skyTop)
        }
        .overlay {
            Capsule().stroke(StarfallTheme.Colors.skyTop, lineWidth: 4)
            Capsule().stroke(full ? StarfallTheme.Colors.actionPrimary : StarfallTheme.Colors.textPrimary,
                             lineWidth: 1.5)
        }
        .fixedSize()
    }
}
