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


extension TraceInputPolishTests {
    @MainActor func testEdgeReleaseBelowDragThresholdAlwaysTerminatesAndFinalMotionIsClassified() throws {
        for size in [CGSize(width:320,height:568), CGSize(width:440,height:956)] {
            let mapping = ObservatoryGeometry(size:size), game = ConstellationFixture.diagonalSix.game()
            let cell = Cell(0,0), center = mapping.viewPoint(cell)
            let radius = ConstellationTraceHitTesting.radius(cell,mapping:mapping)
            let start = CGPoint(x:center.x-radius*0.99,y:center.y)
            let outside = CGPoint(x:start.x-7.9,y:start.y)
            XCTAssertEqual(ConstellationTraceHitTesting.start(at:start,mapping:mapping,game:game),cell)
            XCTAssertNil(mapping.cell(at:outside))
            var touch = ConstellationTouchSession()
            XCTAssertTrue(touch.begin(at:start))
            XCTAssertFalse(touch.move(to:outside))
            XCTAssertEqual(touch.finish(at:outside,mapping:mapping),.cancel)
            XCTAssertNil(touch.origin)
            XCTAssertEqual(touch.finish(at:center,mapping:mapping),.cancel,"Duplicate terminal event cannot tap")
            XCTAssertTrue(touch.begin(at:center))
            XCTAssertEqual(touch.finish(at:mapping.viewPoint(Cell(4,4)),mapping:mapping),.trace,
                "The final sample can cross drag slop without a preceding move callback")
            XCTAssertNil(touch.origin)
            XCTAssertTrue(touch.begin(at:center))
            touch.cancel()
            XCTAssertEqual(touch.finish(at:center,mapping:mapping),.cancel)
            XCTAssertTrue(touch.begin(at:center))
            XCTAssertEqual(touch.finish(at:center,mapping:mapping),.tap(cell))
            XCTAssertTrue(touch.begin(at:center))
            XCTAssertFalse(touch.begin(at:center),"A second touch admission cancels the session")
            XCTAssertNil(touch.origin)
        }
    }

    @MainActor func testHoldTicketsRejectStaleReleasesAndRetainNearDeadlineGrace() throws {
        let suite = "Starfall.TraceHold.\(UUID().uuidString)"
        let local = UserDefaults(suiteName:suite)!
        defer { local.removePersistentDomain(forName:suite) }
        let clock = ManualRainClock(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults:local,arguments:["--starfalls-reset"],presenter:presenter,clock:clock)
        store.setSuspended(false); store.loadConstellationFixture(.diagonalSix); store.togglePause()
        let source = store.game
        let deadline = try XCTUnwrap(clock.deadline)
        clock.advance(max(0,deadline-clock.now-0.1))
        let staleClock = clock.action
        let first = try XCTUnwrap(store.beginConstellationHold())
        XCTAssertNil(store.beginConstellationHold())
        clock.advance(100); staleClock?()
        XCTAssertEqual(store.game,source); XCTAssertNil(clock.deadline)
        store.endConstellationHold(first)
        XCTAssertEqual(try XCTUnwrap(clock.deadline)-clock.now,0.5,accuracy:0.001)
        let second = try XCTUnwrap(store.beginConstellationHold())
        store.endConstellationHold(first)
        XCTAssertTrue(store.constellationTracing); XCTAssertNil(clock.deadline)
        store.endConstellationHold(second)
        let resumed = clock.deadline
        store.endConstellationHold(second)
        XCTAssertEqual(clock.deadline,resumed)
        clock.advance(0.5); XCTAssertEqual(store.game.turns,source.turns+1)
    }

    @MainActor func testSurfaceConfigurationChangesReleaseHoldBeforeReplacement() throws {
        for boundary in ["size","generation","disabled","detached","multitouch"] {
            let suite = "Starfall.TraceBoundary.\(UUID().uuidString)", clock = ManualRainClock()
            let defaults = UserDefaults(suiteName:suite)!
            defer { defaults.removePersistentDomain(forName:suite) }
            let store = FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset"],presenter:FallingSkyRecorder(),clock:clock)
            store.setSuspended(false); store.loadConstellationFixture(.diagonalSix); store.togglePause()
            let before = store.game, ticket = try XCTUnwrap(store.beginConstellationHold())
            let surface = ConstellationTraceSurface.Surface()
            func input(size:CGSize = CGSize(width:440,height:956), enabled:Bool = true, generation:UInt64 = 1) -> ConstellationTraceSurface {
                .init(size:size,enabled:enabled,generation:generation,traceStart:{ _ in Cell(0,0) },tap:{ _ in },begin:{ _ in },move:{ _ in },end:{ },cancel:{ store.endConstellationHold(ticket) })
            }
            surface.updateInput(input())
            surface.updateInput(input())
            XCTAssertTrue(store.constellationTracing,"Equivalent redraw must not cancel")
            switch boundary {
            case "size":surface.updateInput(input(size:CGSize(width:956,height:440)))
            case "generation":surface.updateInput(input(generation:2))
            case "disabled":surface.updateInput(input(enabled:false))
            case "detached":surface.willMove(toWindow:nil)
            default:surface.cancelInput() // Same terminal route as UIKit's second-touch guard.
            }
            XCTAssertFalse(store.constellationTracing,boundary)
            XCTAssertNotNil(clock.deadline,boundary)
            XCTAssertEqual(store.game,before,boundary)
        }
    }
}


extension TraceInputPolishTests {
    @MainActor func testStoreInterruptionsInvalidateHeldOwnershipWithoutLateResume() throws {
        for boundary in ["pause","background","restart","motion","fixture"] {
            let suite = "Starfall.HeldInterruption.\(UUID().uuidString)"
            let local = UserDefaults(suiteName:suite)!
            defer { local.removePersistentDomain(forName:suite) }
            let clock = ManualRainClock(), presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults:local,arguments:["--starfalls-reset"],presenter:presenter,clock:clock)
            store.setSuspended(false); store.loadConstellationFixture(.diagonalSix); store.togglePause()
            let old = try XCTUnwrap(store.beginConstellationHold())
            switch boundary {
            case "pause":store.togglePause()
            case "background":store.setSuspended(true)
            case "restart":store.restart(sameSky:true)
            case "motion":store.setReducedMotion(true)
            default:store.loadConstellationFixture(.overlap)
            }
            XCTAssertFalse(store.constellationTracing,boundary)
            let deadline = clock.deadline
            store.endConstellationHold(old)
            XCTAssertEqual(clock.deadline,deadline,"Late release must preserve the interruption's clock decision")
            if boundary != "motion" {
                let committed = store.game
                clock.advance(100); presenter.finish()
                XCTAssertEqual(store.game,committed,boundary)
            }
        }
    }
}
