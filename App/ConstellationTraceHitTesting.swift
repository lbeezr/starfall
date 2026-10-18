import Foundation
import StarfallCore

/// Input geometry only: visits still pass through intent and committed core validation.
/// Analytic segment/circle intersections retain grazing hits even in coarse touch samples.
enum ConstellationTraceHitTesting {
    static func radius(_ cell: Cell, mapping: ObservatoryGeometry) -> CGFloat {
        let frame = mapping.frame(cell)
        return min(frame.width, frame.height) * 0.44
    }

    static func start(at point: CGPoint, mapping: ObservatoryGeometry, game: FallingSky) -> Cell? {
        // A draw starts on the same native target as a tap. A smaller circle
        // previously left a dead rim inside an otherwise usable star cell.
        guard let cell = mapping.cell(at: point), game.canStartConstellation(at: cell) else { return nil }
        return cell
    }

    static func cells(from start: CGPoint, to end: CGPoint,
                      mapping: ObservatoryGeometry, game: FallingSky) -> [Cell] {
        let dx = end.x-start.x, dy = end.y-start.y
        let lengthSquared = dx*dx + dy*dy
        var hits: [(cell: Cell, entry: CGFloat)] = []
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            guard let gem = game.gem(at: cell), !gem.isDark else { continue }
            let center = mapping.viewPoint(cell), radius = radius(cell, mapping: mapping)
            let ox = start.x-center.x, oy = start.y-center.y
            let distanceSquared = ox*ox + oy*oy
            if distanceSquared <= radius*radius {
                hits.append((cell, 0)); continue
            }
            guard lengthSquared > 0 else { continue }
            let dot = ox*dx + oy*dy
            let discriminant = dot*dot - lengthSquared*(distanceSquared-radius*radius)
            guard discriminant >= 0 else { continue }
            let entry = (-dot-sqrt(discriminant))/lengthSquared
            guard entry >= 0, entry <= 1 else { continue }
            hits.append((cell, entry))
        } }
        return hits.sorted {
            if $0.entry != $1.entry { return $0.entry < $1.entry }
            return $0.cell.row == $1.cell.row ? $0.cell.column < $1.cell.column : $0.cell.row < $1.cell.row
        }.map(\.cell)
    }
}
