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

    @MainActor func testUnavailableIncidentalSampleDoesNotDestroyLiveTrace() throws {
        let game = ConstellationFixture.diagonalSix.game(), intent = ConstellationTraceIntent()
        let ticket = try XCTUnwrap(intent.begin(Cell(0,0), game: game, generation: 4, enabled: true))
        XCTAssertFalse(intent.visit(Cell(0,1), ticket: ticket, game: game, generation: 4, enabled: false))
        XCTAssertEqual(intent.path, [Cell(0,0)])
        for i in 1..<5 {
            XCTAssertTrue(intent.visit(Cell(i,i), ticket: ticket, game: game, generation: 4, enabled: true))
        }
        XCTAssertNotNil(intent.finish(ticket: ticket, game: game, generation: 4, enabled: true))
        let replacement = intent.begin(Cell(0,0), game: game, generation: 4, enabled: true)
        XCTAssertFalse(intent.visit(Cell(1,1), ticket: replacement, game: game, generation: 5, enabled: false))
        XCTAssertNil(intent.snapshot, "A lifecycle change still invalidates the entire contact")
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
            let axes = ConstellationTraceHitTesting.radii(cell, mapping: mapping)
            let width = mapping.frame(cell).width
            XCTAssertEqual(ConstellationTraceHitTesting.start(at: center, mapping: mapping, game: game), cell)
            XCTAssertEqual(ConstellationTraceHitTesting.start(at: CGPoint(x: center.x+width*0.49, y: center.y), mapping: mapping, game: game), cell,
                           "The native star target has no smaller circular dead rim")
            let left = CGPoint(x: center.x-axes.width*1.5, y: center.y+axes.height*0.98)
            let right = CGPoint(x: center.x+axes.width*1.5, y: left.y)
            XCTAssertTrue(ConstellationTraceHitTesting.cells(from: left, to: right, mapping: mapping, game: game).contains(cell))
            XCTAssertEqual(ConstellationTraceHitTesting.start(at: CGPoint(x: center.x+width*0.47, y: center.y), mapping: mapping, game: game), cell)
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
    @MainActor func testEdgeReleaseAlwaysTerminatesAndFinalMotionIsClassified() throws {
        for size in [CGSize(width:320,height:568), CGSize(width:440,height:956)] {
            let mapping = ObservatoryGeometry(size:size), game = ConstellationFixture.diagonalSix.game()
            let cell = Cell(0,0), center = mapping.viewPoint(cell)
            let start = CGPoint(x:center.x-mapping.frame(cell).width*0.48,y:center.y)
            let outside = CGPoint(x:start.x-7.9,y:start.y)
            XCTAssertEqual(ConstellationTraceHitTesting.start(at:start,mapping:mapping,game:game),cell)
            XCTAssertNil(mapping.cell(at:outside))
            var touch = ConstellationTouchSession()
            XCTAssertTrue(touch.begin(at:start))
            XCTAssertTrue(touch.move(to:outside))
            XCTAssertEqual(touch.finish(at:outside,mapping:mapping),.trace)
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

    @MainActor func testEarlyDrawingAndTapDriftKeepDistinctStickyIntent() {
        let mapping = ObservatoryGeometry(size: CGSize(width:390,height:844))
        let cell = Cell(0,3), origin = mapping.viewPoint(cell)
        for distance: CGFloat in [6,12,16,18] {
            var touch = ConstellationTouchSession()
            XCTAssertTrue(touch.begin(at:origin))
            let point = CGPoint(x:origin.x+distance,y:origin.y)
            XCTAssertTrue(touch.move(to:point), "Preview starts without waiting for tap slop")
            XCTAssertEqual(touch.finish(at:origin,mapping:mapping),.tap(cell))
        }
        var selected = ConstellationTouchSession()
        XCTAssertTrue(selected.begin(at:origin))
        selected.claimDrag()
        _ = selected.move(to:CGPoint(x:origin.x+6,y:origin.y))
        XCTAssertEqual(selected.finish(at:origin,mapping:mapping),.trace,
                       "Selected neighbors prevent partial drawings from becoming whole-group clears")
        XCTAssertTrue(selected.begin(at:origin))
        _ = selected.move(to:CGPoint(x:origin.x+19,y:origin.y))
        XCTAssertEqual(selected.finish(at:origin,mapping:mapping),.trace,
                       "A larger excursion remains drawing even on return")
    }

    @MainActor func testPhysicalContactTicketExpiresEvenWhenNextTouchUsesTheSameOrigin() {
        let mapping = ObservatoryGeometry(size: CGSize(width:390,height:844))
        let origin = mapping.viewPoint(Cell(1,2))
        var touch = ConstellationTouchSession()
        XCTAssertTrue(touch.begin(at:origin))
        let first = touch.sequence
        touch.cancel()
        XCTAssertNotEqual(touch.sequence,first)
        XCTAssertTrue(touch.begin(at:origin))
        let second = touch.sequence
        XCTAssertNotEqual(second,first)
        XCTAssertEqual(touch.finish(at:origin,mapping:mapping),.tap(Cell(1,2)))
        XCTAssertNotEqual(touch.sequence,second)
        XCTAssertTrue(touch.begin(at:origin))
        XCTAssertNotEqual(touch.sequence,second)
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

extension TraceInputPolishTests {
    @MainActor func testLogicalContactOwnsHoldAcrossTraceToSwapAndReleasesExactlyOnce() throws {
        let session = SkyInteractionSession(), game = SkyTechniqueExample.nudge.game()
        var releases: [UInt64] = []
        var acquired = 0
        XCTAssertTrue(session.acquireHold(at: Cell(0,0)) { _ in acquired += 1; return 7 })
        XCTAssertTrue(session.acquireHold(at: Cell(0,0)) { _ in acquired += 1; return 8 })
        XCTAssertEqual(acquired, 1)
        let pair = try XCTUnwrap((0..<7).flatMap { row in (0..<6).map { (Cell(row,$0),Cell(row,$0+1)) } }
            .first { game.canNudge(from: $0.0, to: $0.1) })
        session.armSwap(from: pair.0, to: pair.1, game: game, generation: 3)
        XCTAssertTrue(session.technique.swapping)
        XCTAssertEqual(session.holdTicket, 7)
        session.endContact(ticket: 7) { ticket in
            XCTAssertNil(session.holdTicket)
            XCTAssertFalse(session.technique.swapping)
            XCTAssertNil(session.trace.snapshot)
            releases.append(ticket!)
        }
        session.endContact(ticket: 7) { releases.append($0!) }
        XCTAssertEqual(releases, [7])
        XCTAssertTrue(session.acquireHold(at: pair.0) { _ in 8 })
        session.endContact(ticket: 7) { releases.append($0!) }
        XCTAssertEqual(session.holdTicket, 8, "A late terminal event cannot release the next session")
        session.invalidate { releases.append($0!) }
        XCTAssertEqual(releases, [7,8])
    }

    @MainActor func testLogicalCancellationClearsTraceEvenWhenHoldAdmissionFails() {
        let session = SkyInteractionSession(), game = ConstellationFixture.diagonalSix.game()
        _ = session.trace.begin(Cell(0,0), game: game, generation: 1, enabled: true)
        XCTAssertFalse(session.acquireHold(at: Cell(0,0)) { _ in nil })
        XCTAssertNil(session.trace.snapshot)
        let swapping = SkyTechniqueExample.nudge.game()
        session.armSwap(from: Cell(1,2), to: Cell(1,1), game: swapping, generation: 1)
        session.cancelContact { _ in XCTFail("No owned hold") }
        XCTAssertNil(session.technique.anchor)
        XCTAssertFalse(session.technique.swapping)
        session.invalidate { _ in XCTFail("No owned hold") }
        XCTAssertNil(session.technique.snapshot)
    }
}

extension TraceInputPolishTests {
    @MainActor func testLifecycleTeardownRetiresHeldTicketsAndOldRain() throws {
        for boundary in ["restart", "challenge", "balance", "suspension", "motion", "layout", "traceFixture", "gravityFixture"] {
            let suite = "Teardown.\(boundary).\(UUID())", defaults = UserDefaults(suiteName:suite)!
            defer { defaults.removePersistentDomain(forName:suite) }
            let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = TeardownFeedback()
            let store = FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset"],presenter:presenter,clock:clock,feedback:feedback)
            store.setSuspended(false); store.loadConstellationFixture(.diagonalSix); store.togglePause()
            let newPace: StarfallBalance.Pace = store.game.balance.pace == .gentle ? .steady : .gentle
            let oldRain = clock.action
            let hold = try XCTUnwrap(store.beginConstellationHold())
            func interrupt() {
                switch boundary {
                case "restart": store.restart(sameSky:true)
                case "challenge": store.startFirstLight()
                case "balance": store.setPace(newPace)
                case "suspension": store.setSuspended(true)
                case "motion": store.setReducedMotion(true)
                case "layout": store.scene.onLayout?()
                case "traceFixture": store.loadConstellationFixture(.overlap)
                default: store.loadGravityFixture(.opportunity)
                }
            }
            let stops = feedback.stops
            interrupt()
            XCTAssertEqual(feedback.stops, stops + 1, boundary)
            let committed = store.game, deadline = clock.deadline
            XCTAssertFalse(store.constellationTracing,boundary)
            oldRain?(); store.endConstellationHold(hold); presenter.finish()
            XCTAssertEqual(store.game,committed,boundary)
            XCTAssertEqual(clock.deadline,deadline,boundary)
            interrupt()
            XCTAssertEqual(store.game,committed,"Repeated interruption preserves committed state: \(boundary)")
            XCTAssertEqual(clock.deadline,deadline,"Repeated interruption preserves the chosen clock phase: \(boundary)")
        }
    }
}

@MainActor private final class TeardownFeedback: FallingSkyFeedbackProviding {
    var stops = 0
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {}
    func announce(_ message: String) {}
    func stopSounds() { stops += 1 }
}


extension TraceInputPolishTests {
    func testDirectionalSwapTargetsBeforeCellBoundaryAndToleratesWobble() {
        for size in [CGSize(width:320,height:568),CGSize(width:440,height:956),CGSize(width:834,height:1194)] {
            let mapping = ObservatoryGeometry(size:size), cell = Cell(1,2)
            let frame = mapping.frame(cell), origin = mapping.viewPoint(cell)
            let distance = SkySwapDwell.threshold(cell,mapping:mapping) * 1.1
            for direction: CGFloat in [-1,1] {
                let point = CGPoint(x:origin.x+distance*direction,y:origin.y+2)
                XCTAssertEqual(mapping.cell(at:point),cell)
                var dwell = SkySwapDwell()
                dwell.visit(origin:origin,point:point,mapping:mapping)
                XCTAssertEqual(dwell.target,Cell(1,2+Int(direction)))
                dwell.arm()
                let wobble = CGPoint(x:point.x,y:origin.y+frame.height*0.6)
                dwell.visit(origin:origin,point:wobble,mapping:mapping)
                XCTAssertTrue(dwell.eligible); XCTAssertEqual(dwell.target,Cell(1,2+Int(direction)))
                dwell.visit(origin:origin,point:origin,mapping:mapping)
                XCTAssertFalse(dwell.eligible); XCTAssertNil(dwell.target)
            }
        }
    }

    @MainActor func testOffCenterEllipseAndGapMissUseSharedRules() throws {
        let game = ConstellationFixture.horizontalFive.game()
        XCTAssertEqual(ConstellationTraceHitTesting.cells(from:.zero,to:.zero,
            mapping:ObservatoryGeometry(size:.zero),game:game),[])
        for size in [CGSize(width:320,height:568),CGSize(width:440,height:956),CGSize(width:834,height:1194)] {
            let mapping = ObservatoryGeometry(size:size)
            let a = mapping.viewPoint(Cell(0,0)), b = mapping.viewPoint(Cell(0,4))
            let offset = mapping.frame(Cell(0,0)).height*0.38
            let hits = ConstellationTraceHitTesting.cells(from:CGPoint(x:a.x,y:a.y+offset),
                to:CGPoint(x:b.x,y:b.y+offset),mapping:mapping,game:game)
            XCTAssertEqual(hits.filter { game.gem(at:$0)?.kind == .rose },(0..<5).map { Cell(0,$0) })
        }
        let gap = ConstellationFixture.singleGap.game(), intent = ConstellationTraceIntent()
        let ticket = try XCTUnwrap(intent.begin(Cell(0,0),game:gap,generation:1,enabled:true))
        for column in [1,2,3] { XCTAssertTrue(intent.visit(Cell(0,column),ticket:ticket,game:gap,generation:1,enabled:true)) }
        XCTAssertFalse(intent.visit(Cell(0,4),ticket:ticket,game:gap,generation:1,enabled:true))
        XCTAssertEqual(intent.count,4)
        XCTAssertTrue(intent.visit(Cell(0,5),ticket:ticket,game:gap,generation:1,enabled:true))
        XCTAssertNotNil(intent.finish(ticket:ticket,game:gap,generation:1,enabled:true))
    }
}
