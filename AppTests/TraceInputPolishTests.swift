import XCTest
import StarfallCore
@testable import Starfall

final class TraceInputPolishTests: XCTestCase {
    private var chosenTrace: [Cell] { [Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)] }
    @MainActor func testSpatialMissesPreserveWalkButStaleInputStillCancels() throws {
        let game = ConstellationFixture.overlap.game(), intent = ConstellationTraceIntent()
        let ticket = try XCTUnwrap(intent.begin(chosenTrace[0], game: game, generation: 4, enabled: true))
        for miss in [Cell(1,4), Cell(6,6), Cell(1,6)] {
            XCTAssertFalse(intent.visit(miss, ticket: ticket, game: game, generation: 4, enabled: true))
            XCTAssertEqual(intent.path, [chosenTrace[0]])
            XCTAssertEqual(intent.snapshot, game)
        }
        for cell in chosenTrace.dropFirst() {
            XCTAssertTrue(intent.visit(cell, ticket: ticket, game: game, generation: 4, enabled: true))
        }
        XCTAssertEqual(intent.count, 5)
        XCTAssertNotNil(intent.finish(ticket: ticket, game: game, generation: 4, enabled: true))
        let next = intent.begin(chosenTrace[0], game: game, generation: 4, enabled: true)
        XCTAssertFalse(intent.visit(Cell(1,4), ticket: next, game: game, generation: 4, enabled: true))
        XCTAssertFalse(intent.visit(chosenTrace[1], ticket: next, game: game, generation: 5, enabled: true))
        XCTAssertNil(intent.snapshot)
    }

    @MainActor func testContinuousSamplingFindsCoarseAndGrazingHitsAtDifferentSizes() {
        let game = ConstellationFixture.diagonalSix.game()
        for size in [CGSize(width: 320, height: 568), CGSize(width: 414, height: 896), CGSize(width: 440, height: 956)] {
            let mapping = ObservatoryGeometry(size: size)
            let cells = ConstellationTraceHitTesting.cells(from: mapping.viewPoint(Cell(0,0)),
                to: mapping.viewPoint(Cell(4,4)), mapping: mapping, game: game)
            XCTAssertEqual(cells.filter { game.gem(at: $0)?.kind == .rose }, (0..<5).map { Cell($0,$0) })
            XCTAssertFalse(cells.contains(Cell(5,5)))
            let cell = Cell(2,2), center = mapping.viewPoint(cell)
            let radius = ConstellationTraceHitTesting.radius(cell, mapping: mapping)
            XCTAssertEqual(ConstellationTraceHitTesting.start(at: center, mapping: mapping, game: game), cell)
            XCTAssertNil(ConstellationTraceHitTesting.start(at: CGPoint(x: center.x+radius*1.02, y: center.y), mapping: mapping, game: game))
            let left = CGPoint(x: center.x-radius*1.5, y: center.y+radius*0.98)
            let right = CGPoint(x: center.x+radius*1.5, y: left.y)
            XCTAssertTrue(ConstellationTraceHitTesting.cells(from: left, to: right, mapping: mapping, game: game).contains(cell))
            XCTAssertEqual(ConstellationTraceHitTesting.start(at: CGPoint(x: center.x+radius*0.98, y: center.y), mapping: mapping, game: game), cell)
            XCTAssertNil(ConstellationTraceHitTesting.start(at: mapping.viewPoint(Cell(6,0)), mapping: mapping, game: game))
        }
    }

    @MainActor func testCurvedExcursionAndBranchRetracingKeepExactlyTheChosenStars() throws {
        let game = ConstellationFixture.diagonalSix.game()
        let mapping = ObservatoryGeometry(size: CGSize(width: 414, height: 896))
        let expected = (0..<5).map { Cell($0,$0) }
        var points = [mapping.viewPoint(Cell(0,0)), mapping.viewPoint(Cell(0,1)), mapping.viewPoint(Cell(0,0))]
        for cell in expected.dropFirst() {
            let end = mapping.viewPoint(cell), start = points.last!
            points.append(CGPoint(x: (start.x+end.x)/2+6, y: (start.y+end.y)/2+4))
            points.append(end)
        }
        let intent = ConstellationTraceIntent()
        let ticket = try XCTUnwrap(intent.begin(expected[0], game: game, generation: 1, enabled: true))
        for index in 1..<points.count {
            for cell in ConstellationTraceHitTesting.cells(from: points[index-1], to: points[index], mapping: mapping, game: game) {
                _ = intent.visit(cell, ticket: ticket, game: game, generation: 1, enabled: true)
            }
        }
        let outcome = try XCTUnwrap(intent.finish(ticket: ticket, game: game, generation: 1, enabled: true))
        XCTAssertEqual(Set(outcome.path), Set(expected))
        var committed = game
        XCTAssertEqual(committed.clearConstellation(outcome.path)?.collected, 5)
        XCTAssertNotNil(committed.board.compactMap { $0 }.first { $0.id == game.gem(at: Cell(5,5))?.id })

        let branch = ConstellationTraceIntent(), source = ConstellationFixture.overlap.game()
        let sequence = try XCTUnwrap(branch.begin(Cell(0,4), game: source, generation: 1, enabled: true))
        for cell in [Cell(1,3), Cell(2,4), Cell(1,3), Cell(0,4), Cell(1,5), Cell(1,6)] {
            XCTAssertTrue(branch.visit(cell, ticket: sequence, game: source, generation: 1, enabled: true))
        }
        XCTAssertEqual(branch.count, 5)
        XCTAssertEqual(Set(try XCTUnwrap(branch.finish(ticket: sequence, game: source, generation: 1, enabled: true)).path), Set(chosenTrace))
    }

}
