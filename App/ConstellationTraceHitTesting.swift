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
        guard mapping.cell(at: point) != nil else { return nil }
        let candidates = (0..<7).flatMap { row in (0..<7).map { Cell(row, $0) } }
            .filter { game.constellationGroup(at:$0).count >= 5 || (game.challenge == nil && game.gem(at:$0)?.kind != nil && game.recipes(containing:$0).contains { $0.shape == .square }) }
        return candidates.compactMap { cell -> (Cell, CGFloat)? in
            let center = mapping.viewPoint(cell)
            let distance = CGFloat(hypot(point.x-center.x, point.y-center.y))
            return distance <= radius(cell, mapping: mapping) ? (cell, distance) : nil
        }.min { $0.1 < $1.1 }?.0
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
