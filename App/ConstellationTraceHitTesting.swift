import Foundation
import StarfallCore

/// Input geometry only: visits still pass through intent and committed core validation.
/// Analytic segment/ellipse intersections retain grazing hits even in coarse touch samples.
enum ConstellationTraceHitTesting {
    static func radii(_ cell: Cell, mapping: LandingGeometry) -> CGSize {
        let frame = mapping.frame(cell)
        return CGSize(width: frame.width * 0.52, height: frame.height * 0.52)
    }

    static func start(at point: CGPoint, mapping: LandingGeometry, game: FallingSky) -> Cell? {
        // A draw starts on the same native target as a tap. A smaller circle
        // previously left a dead rim inside an otherwise usable star cell.
        guard let cell = mapping.cell(at: point), game.canStartConstellation(at: cell) else { return nil }
        return cell
    }

    static func cells(from start: CGPoint, to end: CGPoint,
                      mapping: LandingGeometry, game: FallingSky) -> [Cell] {
        let dx = end.x-start.x, dy = end.y-start.y
        var hits: [(cell: Cell, entry: CGFloat)] = []
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            guard let gem = game.gem(at: cell), !gem.isDark else { continue }
            let center = mapping.viewPoint(cell), axes = radii(cell, mapping: mapping)
            guard axes.width > 0, axes.height > 0 else { continue }
            let ox = (start.x-center.x)/axes.width, oy = (start.y-center.y)/axes.height
            let vx = dx/axes.width, vy = dy/axes.height
            let lengthSquared = vx*vx + vy*vy
            let distanceSquared = ox*ox + oy*oy
            if distanceSquared <= 1 {
                hits.append((cell, 0)); continue
            }
            guard lengthSquared > 0 else { continue }
            let dot = ox*vx + oy*vy
            let discriminant = dot*dot - lengthSquared*(distanceSquared-1)
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
