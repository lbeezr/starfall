import CoreGraphics
import Foundation
import StarfallCore

/// Shared artwork registration, playfield projection and native input coordinates.
struct ObservatoryGeometry {
    let size: CGSize
    static let artworkAspect: CGFloat = 863 / 1823
    static let floorTop: CGFloat = 0.245
    static let floorBottom: CGFloat = 0.735

    /// Keeps the registered terrace readable on wide windows; distant scenery fills outside it.
    /// A 350-point minimum preserves seven full-width targets on compact phones.
    /// Cap horizontal crop so the taller accessibility canvas keeps edge cells visible.
    var imageRect: CGRect {
        let width = min(size.width * 1.04, max(min(350, size.width), size.height * Self.artworkAspect))
        let height = width / Self.artworkAspect
        return CGRect(x: (size.width-width)/2, y: (size.height-height)/2, width: width, height: height)
    }
    private func imagePoint(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        let rect = imageRect
        return CGPoint(x: rect.minX + x*rect.width, y: rect.minY + y*rect.height)
    }
    private func edge(_ column: CGFloat, depth: CGFloat) -> CGPoint {
        let halfWidth = 0.45 + depth * 0.025
        return imagePoint(0.5 + (column/7-0.5)*halfWidth*2,
                          Self.floorTop + depth*(Self.floorBottom-Self.floorTop))
    }
    /// UIKit/SwiftUI coordinates. Row zero remains the bottom/front row.
    func polygon(_ cell: Cell) -> [CGPoint] {
        let back = CGFloat(6-cell.row)/7
        let front = CGFloat(7-cell.row)/7
        let column = CGFloat(cell.column)
        return [edge(column, depth: back), edge(column+1, depth: back),
                edge(column+1, depth: front), edge(column, depth: front)]
    }
    func frame(_ cell: Cell) -> CGRect {
        let points = polygon(cell)
        let xs = points.map(\.x), ys = points.map(\.y)
        return CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()!-xs.min()!, height: ys.max()!-ys.min()!)
    }
    func columnPolygon(_ column: Int) -> [CGPoint] {
        guard (0..<FallingSky.side).contains(column) else { return [] }
        let back = polygon(Cell(FallingSky.side - 1, column))
        let front = polygon(Cell(0, column))
        return [back[0], back[1], front[2], front[3]]
    }
    func viewPoint(_ cell: Cell) -> CGPoint {
        edge(CGFloat(cell.column)+0.5, depth: (CGFloat(6-cell.row)+0.5)/7)
    }
    func scenePoint(_ cell: Cell) -> CGPoint {
        let point = viewPoint(cell)
        return CGPoint(x: point.x, y: size.height-point.y)
    }
    /// Continuous inverse, useful for native geometry regression and boundary probes.
    func cell(at point: CGPoint) -> Cell? {
        let rect = imageRect
        guard rect.width > 0, rect.height > 0 else { return nil }
        let y = (point.y-rect.minY)/rect.height
        let depth = (y-Self.floorTop)/(Self.floorBottom-Self.floorTop)
        guard depth >= 0, depth < 1 else { return nil }
        let halfWidth = 0.45 + depth*0.025
        let x = (point.x-rect.minX)/rect.width
        let column = Int(floor(((x-0.5)/(halfWidth*2)+0.5)*7))
        guard (0..<7).contains(column) else { return nil }
        return Cell(6-Int(floor(depth*7)), column)
    }
}

enum ObservatoryProp { case telescope, lantern }

extension ObservatoryGeometry {
    func artworkPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        let rect = imageRect
        return CGPoint(x: rect.minX + x*rect.width, y: rect.minY + y*rect.height)
    }
    func propArtworkFrame(_ prop: ObservatoryProp) -> CGRect {
        // Registered placement: extracted alpha layers do not preserve source scale exactly.
        prop == .telescope ? CGRect(x: 0.02, y: 0.072, width: 0.27, height: 0.1184)
            : CGRect(x: 0.845, y: 0.740, width: 0.14, height: 0.106)
    }
    func propSourceFrame(_ prop: ObservatoryProp) -> CGRect {
        // Measured alpha >16 bounds, normalized to each original full-canvas PNG.
        prop == .telescope ? CGRect(x: 30.0/862, y: 113.0/1824, width: 347.0/862, height: 322.0/1824)
            : CGRect(x: 686.0/863, y: 1456.0/1823, width: 164.0/863, height: 262.0/1823)
    }
    func propFrame(_ prop: ObservatoryProp) -> CGRect {
        let bounds = propArtworkFrame(prop)
        let image = imageRect
        return CGRect(x: image.minX+bounds.minX*image.width, y: image.minY+bounds.minY*image.height,
                      width: max(44,bounds.width*image.width), height: max(44,bounds.height*image.height))
    }

}

/// Monotonic elapsed time: pausing excludes inactive time rather than catching up on resume.
struct ObservatoryAmbientClock {
    private var accumulated: TimeInterval = 0
    private var startedAt: TimeInterval?
    mutating func setRunning(_ running: Bool, at now: TimeInterval) {
        if running {
            if startedAt == nil { startedAt = now }
        } else if let start = startedAt {
            accumulated += max(0, now-start)
            startedAt = nil
        }
    }
    func phase(at now: TimeInterval) -> TimeInterval {
        accumulated + (startedAt.map { max(0, now-$0) } ?? 0)
    }
}
