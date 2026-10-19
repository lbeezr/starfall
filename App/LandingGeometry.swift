import CoreGraphics
import Foundation
import StarfallCore

/// One centered coordinate system for SpriteKit, native cells and gesture samples.
/// Scenery is composed around this rectangle and never changes gameplay geometry.
struct LandingGeometry {
    let size: CGSize
    var largeHeader = false
    private var valid: Bool { size.width.isFinite && size.height.isFinite && size.width > 0 && size.height > 0 }
    var starStep: CGFloat { arenaFrame.width / CGFloat(FallingSky.side) }
    var arenaFrame: CGRect {
        guard valid else { return .zero }
        let side = min(max(0, size.width-12), max(308, size.height-420), 620)
        return CGRect(x: (size.width-side)/2, y: (size.height-side)/2, width: side, height: side)
    }
    var crownFrame: CGRect {
        let board = arenaFrame
        return CGRect(x: board.minX+6, y: board.minY-(largeHeader ? 256 : 152), width: board.width-12, height: largeHeader ? 248 : 84)
    }
    var communicationContentFrame: CGRect {
        let board = arenaFrame
        return CGRect(x: board.minX+12, y: board.maxY+12, width: board.width-24, height: 128)
    }
    var accessibleCanvasEnd: CGFloat { arenaFrame.maxY + (largeHeader ? 112 : 20) }
    func actionFrame(_ index: Int) -> CGRect {
        let room = communicationContentFrame, width = (room.width-16)/2
        return CGRect(x: room.minX+CGFloat(index)*(width+16), y: room.maxY+8, width: width, height: 52)
    }
    /// Row zero is the bottom row in Core, while UIKit's y axis points downward.
    private func edge(_ column: Int, _ row: Int) -> CGPoint {
        let board = arenaFrame
        return CGPoint(x:board.minX+CGFloat(column)*starStep,y:board.minY+CGFloat(row)*starStep)
    }
    func polygon(_ cell: Cell) -> [CGPoint] {
        let row = 6-cell.row, column = cell.column
        return [edge(column,row),edge(column+1,row),edge(column+1,row+1),edge(column,row+1)]
    }
    func frame(_ cell: Cell) -> CGRect {
        let points = polygon(cell), first = points[0], last = points[2]
        return CGRect(x:first.x,y:first.y,width:last.x-first.x,height:last.y-first.y)
    }
    func columnPolygon(_ column: Int) -> [CGPoint] {
        guard (0..<FallingSky.side).contains(column) else { return [] }
        let back = polygon(Cell(6,column)), front = polygon(Cell(0,column))
        return [back[0],back[1],front[2],front[3]]
    }
    func viewPoint(_ cell: Cell) -> CGPoint { let rect = frame(cell); return CGPoint(x:rect.midX,y:rect.midY) }
    func scenePoint(_ cell: Cell) -> CGPoint { let point = viewPoint(cell); return CGPoint(x:point.x,y:size.height-point.y) }
    var arenaPerimeter: [CGPoint] { [polygon(Cell(6,0))[0],polygon(Cell(6,6))[1],polygon(Cell(0,6))[2],polygon(Cell(0,0))[3]] }
    func cell(at point: CGPoint) -> Cell? {
        let board = arenaFrame
        guard valid, starStep > 0, point.x >= board.minX, point.x < board.maxX,
              point.y >= board.minY, point.y < board.maxY else { return nil }
        return Cell(6-Int((point.y-board.minY)/starStep), Int((point.x-board.minX)/starStep))
    }
}

/// Monotonic elapsed time: pausing excludes inactive time rather than catching up.
struct LandingAmbientClock {
    private var accumulated: TimeInterval = 0
    private var startedAt: TimeInterval?
    mutating func setRunning(_ running: Bool, at now: TimeInterval) {
        if running {
            if startedAt == nil { startedAt = now }
        } else if let start = startedAt {
            accumulated += max(0, now-start); startedAt = nil
        }
    }
    func phase(at now: TimeInterval) -> TimeInterval {
        accumulated + (startedAt.map { max(0, now-$0) } ?? 0)
    }
}
