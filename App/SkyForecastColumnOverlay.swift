import SwiftUI
import StarfallCore

/// A static, unfilled locator on the same column edges as stars and native cells.
@MainActor struct SkyForecastColumnOverlay: View {
    let entry: SkyForecastSnapshot.Entry
    let mapping: LandingGeometry

    var columnBounds: CGRect? {
        guard (1...FallingSky.side).contains(entry.column) else { return nil }
        let points = mapping.columnPolygon(entry.column - 1)
        guard points.count == 4, points.allSatisfy({ $0.x.isFinite && $0.y.isFinite }),
              let minX = points.map(\.x).min(), let maxX = points.map(\.x).max(),
              let minY = points.map(\.y).min(), let maxY = points.map(\.y).max(),
              maxX > minX, maxY > minY else { return nil }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let bounds = columnBounds {
                let points = mapping.columnPolygon(entry.column - 1).map {
                    CGPoint(x: $0.x - bounds.minX, y: $0.y - bounds.minY)
                }
                let outline = Path { path in
                    path.addLines(points)
                    path.closeSubpath()
                }
                ZStack {
                    outline.stroke(StarfallTheme.Colors.skyTop,
                                   style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [5, 5]))
                    outline.stroke(StarfallTheme.Colors.textPrimary,
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [5, 5]))
                }
                .frame(width: bounds.width, height: bounds.height)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(SkyCopy.text(.forecastSelectedColumn, values: ["column": String(entry.column)]))
                .accessibilityValue(String(entry.column))
                .accessibilityIdentifier("sky.forecast.column")
                .position(x: bounds.midX, y: bounds.midY)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
        .transaction { $0.animation = nil; $0.disablesAnimations = true }
    }
}
