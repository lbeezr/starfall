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
            let mapping = LandingGeometry(size: size)
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
        let mapping = LandingGeometry(size: CGSize(width: 414, height: 896))
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
    @MainActor func testOutwardSwipeExplainsDirectionOnceAndNextContactStillSwaps() {
        for size in [CGSize(width:320,height:568), CGSize(width:440,height:956), CGSize(width:1024,height:1366)] {
            let mapping = LandingGeometry(size:size)
            for (source,neighbor,dx,dy) in [(Cell(3,0),Cell(3,1),-1.0,0.0),
                                          (Cell(3,6),Cell(3,5),1.0,0.0),
                                          (Cell(6,3),Cell(5,3),0.0,-1.0),
                                          (Cell(0,3),Cell(1,3),0.0,1.0)] {
                let surface = ConstellationTraceSurface.Surface()
                var feedback: [String] = [], swaps = 0, taps = 0, draws = 0
                surface.updateInput(.init(size:size,enabled:true,generation:7,traceStart:{ _ in source },
                    tap:{ _ in taps += 1 },begin:{ _ in draws += 1 },move:{ _ in draws += 1 },end:{ draws += 1 },cancel:{},
                    feedback:{ feedback.append($0) },swapStart:{ _ in true },swap:{ from,to,_ in
                        XCTAssertEqual(from,source); XCTAssertEqual(to,neighbor); swaps += 1
                    }))
                let origin = mapping.viewPoint(source)
                let outward = CGPoint(x:origin.x+dx*40,y:origin.y+dy*40)
                surface.beginInput(at:origin)
                let oldTicket = surface.session.sequence
                surface.moveInput(to:outward)
                surface.endInput(at:outward)
                surface.armDrawing(ticket:oldTicket,generation:7)
                XCTAssertEqual(feedback,["That direction leaves the sky. Swipe inward."])
                XCTAssertEqual(swaps,0); XCTAssertEqual(taps,0); XCTAssertEqual(draws,0)
                surface.beginInput(at:origin)
                surface.endInput(at:mapping.viewPoint(neighbor))
                XCTAssertEqual(swaps,1); XCTAssertEqual(feedback.count,1)
            }
        }
    }

    @MainActor func testFinalOnlyFlickBeyondBoardKeepsOneCardinalNeighbor() {
        for size in [CGSize(width:320,height:568), CGSize(width:440,height:956), CGSize(width:1024,height:1366)] {
            let mapping = LandingGeometry(size:size), source = Cell(3,3), center = mapping.viewPoint(source)
            let origin = CGPoint(x:center.x + mapping.frame(source).width*0.35, y:center.y-3)
            let destinations: [(CGPoint,Cell)] = [
                (CGPoint(x:-40,y:origin.y+7),Cell(3,2)),
                (CGPoint(x:size.width+40,y:origin.y-7),Cell(3,4)),
                (CGPoint(x:origin.x+7,y:-40),Cell(4,3)),
                (CGPoint(x:origin.x-7,y:size.height+40),Cell(2,3))
            ]
            for (end,destination) in destinations {
                let surface = ConstellationTraceSurface.Surface()
                var swaps: [(Cell,Cell)] = [], taps = 0, draws = 0
                surface.updateInput(.init(size:size,enabled:true,generation:9,traceStart:{ _ in source },
                    tap:{ _ in taps += 1 },begin:{ _ in draws += 1 },move:{ _ in draws += 1 },end:{ draws += 1 },cancel:{},
                    swapStart:{ _ in true },swap:{ from,to,_ in swaps.append((from,to)) }))
                surface.beginInput(at:origin)
                let ticket = surface.session.sequence
                surface.endInput(at:end)
                surface.moveInput(to:center)
                surface.armDrawing(ticket:ticket,generation:9)
                XCTAssertEqual(swaps.count,1)
                XCTAssertEqual(swaps.first?.0,source); XCTAssertEqual(swaps.first?.1,destination)
                XCTAssertEqual(taps,0); XCTAssertEqual(draws,0)
            }
        }
    }

    @MainActor func testOutwardDestinationsStayDistinctFromHeldExitsAndNonfiniteCancellation() {
        let mapping = LandingGeometry(size:.init(width:390,height:844))
        for (source,end) in [(Cell(0,0),CGPoint(x:-40,y:800)), (Cell(3,6),CGPoint(x:1000,y:400)),
                             (Cell(6,3),CGPoint(x:200,y:-1000)), (Cell(0,3),CGPoint(x:200,y:2000))] {
            var input = ConstellationTouchSession()
            let origin = mapping.viewPoint(source)
            // Keep the intended outward axis unambiguous at edge cells.
            let point = source.column == 0 || source.column == 6 ? CGPoint(x:end.x,y:origin.y) : CGPoint(x:origin.x,y:end.y)
            XCTAssertTrue(input.begin(at:origin,swapEligible:true))
            XCTAssertEqual(input.move(to:point,mapping:mapping),.blockedSwap)
            XCTAssertEqual(input.finish(at:point,mapping:mapping),.none)
        }
        for point in [CGPoint(x:CGFloat.nan,y:0),CGPoint(x:0,y:CGFloat.infinity),CGPoint(x:-40,y:200)] {
            var input = ConstellationTouchSession()
            XCTAssertTrue(input.begin(at:mapping.viewPoint(Cell(3,3)),swapEligible:true))
            XCTAssertTrue(input.armTrace(ticket:input.sequence))
            XCTAssertEqual(input.move(to:point,mapping:mapping),.cancel)
            XCTAssertEqual(input.finish(at:point,mapping:mapping),.none)
        }
        for point in [CGPoint(x:CGFloat.nan,y:0),CGPoint(x:0,y:CGFloat.infinity)] {
            var input = ConstellationTouchSession()
            XCTAssertTrue(input.begin(at:mapping.viewPoint(Cell(3,3)),swapEligible:true))
            XCTAssertEqual(input.move(to:point,mapping:mapping),.cancel)
        }
    }

    @MainActor func testEdgeReleaseCancelsAndFinalOnlySampleSwapsOnce() {
        for size in [CGSize(width:320,height:568), CGSize(width:440,height:956)] {
            let mapping = LandingGeometry(size:size), surface = ConstellationTraceSurface.Surface()
            let cell = Cell(0,0), center = mapping.viewPoint(cell)
            let start = CGPoint(x:center.x-mapping.frame(cell).width*0.48,y:center.y)
            var swaps = 0, taps = 0
            surface.updateInput(.init(size:size,enabled:true,generation:1,traceStart:{ _ in cell },
                tap:{ _ in taps += 1 },begin:{ _ in },move:{ _ in },end:{},cancel:{},
                swapStart:{ _ in true },swap:{ _,_,_ in swaps += 1 }))
            surface.beginInput(at:start)
            surface.endInput(at:CGPoint(x:start.x-7.9,y:start.y))
            XCTAssertEqual(swaps,0); XCTAssertEqual(taps,0)
            surface.beginInput(at:center)
            surface.endInput(at:mapping.viewPoint(Cell(0,1)))
            XCTAssertEqual(swaps,1, "Final-only movement still commits")
            surface.endInput(at:center)
            XCTAssertEqual(swaps,1); XCTAssertEqual(taps,0)
            surface.beginInput(at:center); surface.endInput(at:center)
            XCTAssertEqual(taps,1)
        }
    }

    @MainActor func testHoldTicketsRejectStaleReleasesAndPreserveExactRemainingTime() throws {
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
        XCTAssertEqual(try XCTUnwrap(clock.deadline)-clock.now,0.1,accuracy:0.001)
        let second = try XCTUnwrap(store.beginConstellationHold())
        store.endConstellationHold(first)
        XCTAssertTrue(store.constellationTracing); XCTAssertNil(clock.deadline)
        store.endConstellationHold(second)
        let resumed = clock.deadline
        store.endConstellationHold(second)
        XCTAssertEqual(clock.deadline,resumed)
        clock.advance(0.1); XCTAssertEqual(store.game.turns,source.turns+1)
    }

    func testStationaryHoldLocksDrawingAndMovementCannotLaterArmIt() {
        let mapping = LandingGeometry(size:CGSize(width:390,height:844))
        let cell = Cell(1,2), origin = mapping.viewPoint(cell)
        var touch = ConstellationTouchSession()
        XCTAssertTrue(touch.begin(at:origin,swapEligible:true))
        XCTAssertEqual(touch.move(to:CGPoint(x:origin.x+7,y:origin.y),mapping:mapping),.none)
        XCTAssertTrue(touch.armTrace(ticket:touch.sequence))
        XCTAssertEqual(touch.move(to:mapping.viewPoint(Cell(1,3)),mapping:mapping),.trace)
        XCTAssertEqual(touch.finish(at:origin,mapping:mapping),.trace, "A held selection never taps on return")
        XCTAssertTrue(touch.begin(at:origin,swapEligible:true))
        let stale = touch.sequence
        _ = touch.move(to:CGPoint(x:origin.x+9,y:origin.y),mapping:mapping)
        _ = touch.move(to:origin,mapping:mapping)
        XCTAssertFalse(touch.armTrace(ticket:stale), "Excursion cannot become a hold after returning")
        XCTAssertEqual(touch.move(to:mapping.viewPoint(Cell(1,3)),mapping:mapping),.swap(cell,Cell(1,3)))
        XCTAssertFalse(touch.armTrace(ticket:stale))
        XCTAssertEqual(touch.finish(at:origin,mapping:mapping),.none)
    }

    @MainActor func testPhysicalContactTicketExpiresEvenWhenNextTouchUsesTheSameOrigin() {
        let mapping = LandingGeometry(size: CGSize(width:390,height:844))
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
    @MainActor func testLogicalContactReleasesExactlyOnceBeforeReentrantAcquisition() throws {
        let session = SkyInteractionSession(), game = SkyTechniqueExample.nudge.game()
        var releases: [UInt64] = []
        var acquired = 0
        XCTAssertTrue(session.acquireHold(at: Cell(0,0)) { _ in acquired += 1; return 7 })
        XCTAssertTrue(session.acquireHold(at: Cell(0,0)) { _ in acquired += 1; return 8 })
        XCTAssertEqual(acquired, 1)
        let pair = try XCTUnwrap((0..<7).flatMap { row in (0..<6).map { (Cell(row,$0),Cell(row,$0+1)) } }
            .first { game.canNudge(from: $0.0, to: $0.1) })
        XCTAssertEqual(session.holdTicket, 7)
        session.endContact(ticket: 7) { ticket in
            XCTAssertNil(session.holdTicket)
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
        session.cancelContact { _ in XCTFail("No owned hold") }
        session.invalidate { _ in XCTFail("No owned hold") }
        XCTAssertNil(session.trace.snapshot)
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
    func testFourDirectionsCommitBeforeBoundaryOnceRegardlessOfLaterMotion() {
        for size in [CGSize(width:320,height:568),CGSize(width:440,height:956),CGSize(width:834,height:1194)] {
            let mapping = LandingGeometry(size:size), cell = Cell(2,2), origin = mapping.viewPoint(cell)
            let distance = ConstellationTouchSession.swapThreshold(cell,mapping:mapping) * 1.1
            for (dx,dy,to) in [(CGFloat(-1),CGFloat(0),Cell(2,1)),(1,0,Cell(2,3)),(0,-1,Cell(3,2)),(0,1,Cell(1,2))] {
                let point = CGPoint(x:origin.x+distance*dx,y:origin.y+distance*dy)
                XCTAssertEqual(mapping.cell(at:point),cell)
                var touch = ConstellationTouchSession()
                XCTAssertTrue(touch.begin(at:origin,swapEligible:true))
                XCTAssertEqual(touch.move(to:point,mapping:mapping),.swap(cell,to))
                XCTAssertEqual(touch.move(to:origin,mapping:mapping),.none)
                XCTAssertEqual(touch.move(to:mapping.viewPoint(Cell(4,4)),mapping:mapping),.none)
                XCTAssertEqual(touch.finish(at:point,mapping:mapping),.none)
                XCTAssertFalse(touch.armTrace(ticket:touch.sequence))
            }
        }
    }

    @MainActor func testOffCenterEllipseAndGapMissUseSharedRules() throws {
        let game = ConstellationFixture.horizontalFive.game()
        XCTAssertEqual(ConstellationTraceHitTesting.cells(from:.zero,to:.zero,
            mapping:LandingGeometry(size:.zero),game:game),[])
        for size in [CGSize(width:320,height:568),CGSize(width:440,height:956),CGSize(width:834,height:1194)] {
            let mapping = LandingGeometry(size:size)
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


extension TraceInputPolishTests {
    @MainActor func testZeroDurationContactsCannotStarveOpeningRegularRetainedOrChallengeRain() throws {
        var regular = FallingSky.freshSurvival(seed: 5)
        for _ in 0..<4 { XCTAssertNotNil(regular.letStarsFall()) }
        for game in [FallingSky.freshSurvival(seed: 5), regular, DuskFixture.unfed.game(), FallingSky(challenge: .firstLight)] {
            let suite = "ExactContacts.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
            let clock = ManualRainClock(), presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock, feedback: SkyFeedbackRecorder())
            store.setSuspended(false); store.togglePause()
            let initialTurns = store.game.turns, deadline = try XCTUnwrap(clock.deadline)
            clock.advance(deadline - 0.2)
            for _ in 0..<12 {
                let ticket = try XCTUnwrap(store.beginConstellationHold(at: Cell(6,6)))
                store.endConstellationHold(ticket)
                XCTAssertEqual(try XCTUnwrap(clock.deadline), deadline, accuracy: 0.000001,
                               "A contact with no held time must not manufacture grace")
                clock.advance(0.01)
            }
            clock.advance(0.09)
            XCTAssertEqual(store.game.turns, initialTurns + 1)
        }
    }

    @MainActor func testPauseAndBackgroundKeepTheirGraceAfterAContactHold() throws {
        for background in [false, true] {
            let suite = "ContactInterrupt.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let game = FallingSky(seed: 5, openingCascade: false)
            defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
            store.setSuspended(false); store.togglePause()
            clock.advance(try XCTUnwrap(clock.deadline)-0.1)
            let stale = try XCTUnwrap(store.beginConstellationHold(at: Cell(6,6)))
            if background { store.setSuspended(true) } else { store.togglePause() }
            store.endConstellationHold(stale)
            XCTAssertNil(clock.deadline)
            if background { store.setSuspended(false) } else { store.togglePause() }
            XCTAssertEqual(try XCTUnwrap(clock.deadline)-clock.now, 0.5, accuracy: 0.001)
        }
    }
}


extension TraceInputPolishTests {
    @MainActor func testProductionSurfaceSwapsMatchingStarsBeforeReleaseAndNeverDraws() throws {
        let size = CGSize(width:390,height:844), mapping = LandingGeometry(size:size)
        var game = SkyTechniqueExample.trace.game()
        let before = game, surface = ConstellationTraceSurface.Surface()
        var swaps = 0, draws = 0, taps = 0
        surface.updateInput(.init(size:size,enabled:true,generation:4,traceStart:{ _ in Cell(0,0) },
            tap:{ _ in taps += 1 },begin:{ _ in draws += 1 },move:{ _ in draws += 1 },end:{ draws += 1 },cancel:{},
            swapStart:{ _ in true },swap:{ from,to,_ in
                XCTAssertNotNil(game.nudge(from:from,to:to)); swaps += 1
            }))
        let origin = mapping.viewPoint(Cell(0,0)), target = mapping.viewPoint(Cell(0,1))
        surface.beginInput(at:origin)
        let hold = surface.session.sequence
        surface.moveInput(to:target)
        XCTAssertEqual(game.gem(at:Cell(0,1))?.id,before.gem(at:Cell(0,0))?.id, "Committed while contact is still down")
        XCTAssertNotNil(surface.session.origin)
        surface.armDrawing(ticket:hold,generation:4)
        surface.moveInput(to:mapping.viewPoint(Cell(0,5)))
        surface.endInput(at:target)
        XCTAssertEqual(swaps,1); XCTAssertEqual(draws,0); XCTAssertEqual(taps,0)
        XCTAssertEqual(game.score,0)
    }

    @MainActor func testHoldTimerUsesCurrentTicketAndCancelledHoldsCannotDraw() async throws {
        let size = CGSize(width:390,height:844), origin = LandingGeometry(size:size).viewPoint(Cell(0,0))
        let surface = ConstellationTraceSurface.Surface()
        var draws = 0, taps = 0
        surface.updateInput(.init(size:size,enabled:true,generation:1,traceStart:{ _ in Cell(0,0) },
            tap:{ _ in taps += 1 },begin:{ _ in draws += 1 },move:{ _ in },end:{},cancel:{},swapStart:{ _ in true }))
        surface.beginInput(at:origin)
        let old = surface.session.sequence
        XCTAssertEqual(draws,0)
        surface.cancelInput()
        surface.beginInput(at:origin)
        surface.armDrawing(ticket:old,generation:1)
        surface.armDrawing(ticket:surface.session.sequence,generation:0)
        XCTAssertEqual(draws,0)
        let deadline = ContinuousClock.now + .seconds(2)
        while draws == 0 && ContinuousClock.now < deadline { try await Task.sleep(for:.milliseconds(20)) }
        XCTAssertEqual(draws,1)
        surface.endInput(at:origin)
        XCTAssertEqual(taps,0,"Releasing a stationary held star cannot clear a tap group")
    }
}


extension TraceInputPolishTests {
    func testHoldOnNonTracingSwappableStarStillCannotFallBackToExchange() {
        let mapping = LandingGeometry(size:CGSize(width:390,height:844))
        let origin = mapping.viewPoint(Cell(1,2))
        var contact = ConstellationTouchSession()
        XCTAssertTrue(contact.begin(at:origin,traceEligible:false,swapEligible:true))
        XCTAssertTrue(contact.armTrace(ticket:contact.sequence))
        XCTAssertEqual(contact.move(to:mapping.viewPoint(Cell(1,3)),mapping:mapping),.trace)
        XCTAssertEqual(contact.finish(at:origin,mapping:mapping),.trace)
    }

    @MainActor func testPendingHoldCannotSurviveSurfaceReconfiguration() {
        for boundary in ["generation", "size", "disabled", "detach", "multitouch"] {
            let size = CGSize(width:390,height:844), surface = ConstellationTraceSurface.Surface()
            let origin = LandingGeometry(size:size).viewPoint(Cell(0,0))
            var drawings = 0
            func input(size:CGSize = CGSize(width:390,height:844), enabled:Bool = true, generation:UInt64 = 1) -> ConstellationTraceSurface {
                .init(size:size,enabled:enabled,generation:generation,traceStart:{ _ in Cell(0,0) },
                    tap:{ _ in XCTFail("Interrupted holds cannot tap") },begin:{ _ in drawings += 1 },move:{ _ in },end:{},cancel:{})
            }
            surface.updateInput(input()); surface.beginInput(at:origin)
            let ticket = surface.session.sequence
            switch boundary {
            case "generation": surface.updateInput(input(generation:2))
            case "size": surface.updateInput(input(size:CGSize(width:844,height:390)))
            case "disabled": surface.updateInput(input(enabled:false))
            case "detach": surface.willMove(toWindow:nil)
            default: surface.cancelInput()
            }
            surface.armDrawing(ticket:ticket,generation:1)
            surface.endInput(at:origin)
            XCTAssertEqual(drawings,0,boundary)
        }
    }
}
