import XCTest
import CoreGraphics
import StarfallCore
@testable import Starfall

final class SkyCeilingOverlayTests: XCTestCase {
    func testHeadroomSeparatesOrdinaryNearCeilingAndFullColumns() throws {
        let snapshot = try XCTUnwrap(SkyCeilingSnapshot(
            board: board(heights: [5, 6, 7, 0, 1, 3, 4]),
            mapping: LandingGeometry(size: CGSize(width: 393, height: 852)), showsPressure: true))
        XCTAssertEqual(snapshot.columns.map(\.spaces), [2, 1, 0, 7, 6, 4, 3])
        XCTAssertEqual(snapshot.warnings.map(\.number), [2, 3])
        XCTAssertEqual(snapshot.warnings.map(\.pressure), [.oneSpace, .full])
        XCTAssertEqual(snapshot.columns[2].accessibilityDescription, "Column 3: full, at risk.")
        XCTAssertEqual(snapshot.columns[1].accessibilityDescription, "Column 2: 1 space left.")
        XCTAssertEqual(snapshot.columns[0].accessibilityDescription, "Column 1: 2 spaces left.")
    }

    func testBoundaryAndColumnMarkersShareTheTopRowMappingAcrossLayouts() throws {
        for size in [CGSize(width: 320, height: 640), CGSize(width: 393, height: 852),
                     CGSize(width: 667, height: 900), CGSize(width: 744, height: 1133),
                     CGSize(width: 1133, height: 744)] {
            let mapping = LandingGeometry(size: size)
            let snapshot = try XCTUnwrap(SkyCeilingSnapshot(
                board: board(heights: Array(repeating: 7, count: 7)), mapping: mapping, showsPressure: true))
            XCTAssertEqual(snapshot.arena.minY, mapping.frame(Cell(6, 0)).minY)
            XCTAssertEqual(snapshot.arena.maxY, mapping.frame(Cell(0, 0)).maxY)
            for column in snapshot.columns {
                XCTAssertEqual(column.centerX, mapping.viewPoint(Cell(6, column.index)).x)
                XCTAssertEqual(mapping.cell(at: CGPoint(x: column.centerX, y: snapshot.arena.minY + 1)),
                               Cell(6, column.index))
            }
        }
    }

    func testFullBoardAndTerminalPresentationKeepTheBoundaryWithoutFalseRisk() throws {
        let mapping = LandingGeometry(size: CGSize(width: 393, height: 852))
        let fullBoard = FallingSky.fullBoardLantern()
        XCTAssertTrue(fullBoard.usesFullBoardRefill)
        let snapshot = try XCTUnwrap(SkyCeilingSnapshot(game: fullBoard, mapping: mapping))
        XCTAssertEqual(snapshot.arena, mapping.arenaFrame)
        XCTAssertEqual(snapshot.columns.map(\.spaces), Array(repeating: 0, count: 7))
        XCTAssertTrue(snapshot.warnings.isEmpty)

        var falling = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<4 { _ = try XCTUnwrap(falling.letStarsFall()) }
        XCTAssertFalse(try XCTUnwrap(SkyCeilingSnapshot(game: falling, mapping: mapping)).warnings.isEmpty)
        _ = try XCTUnwrap(falling.letStarsFall())
        XCTAssertNotNil(falling.blockedColumn)
        let terminal = try XCTUnwrap(SkyCeilingSnapshot(game: falling, mapping: mapping))
        XCTAssertEqual(terminal.arena, mapping.arenaFrame)
        XCTAssertTrue(terminal.warnings.isEmpty)
    }

    func testInvalidGeometryAndMalformedBoardsHaveNoPresentation() {
        let empty = board(heights: Array(repeating: 0, count: 7))
        for size in [CGSize.zero, CGSize(width: 0, height: 852),
                     CGSize(width: CGFloat.infinity, height: 852), CGSize(width: 393, height: CGFloat.nan)] {
            XCTAssertNil(SkyCeilingSnapshot(board: empty, mapping: LandingGeometry(size: size), showsPressure: true))
        }
        XCTAssertNil(SkyCeilingSnapshot(board: [], mapping: LandingGeometry(size: CGSize(width: 393, height: 852)),
                                       showsPressure: true))
    }

    private func board(heights: [Int]) -> [StarfallGem?] {
        var result: [StarfallGem?] = Array(repeating: nil, count: 49)
        for (column, height) in heights.enumerated() {
            for row in 0..<height {
                result[row * 7 + column] = StarfallGem(id: row * 7 + column, kind: .aqua)
            }
        }
        return result
    }
}
