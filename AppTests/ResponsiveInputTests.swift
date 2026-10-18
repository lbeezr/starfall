import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class ResponsiveInputTests: XCTestCase {
    @MainActor func testIndependentClearsCompleteInEitherOrderWithoutLosingLatestSave() throws {
        for reversed in [false, true] {
            let suite = "ConcurrentClears.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
            store.setSuspended(false)
            let first = Cell(0, 0), second = Cell(2, 6)
            XCTAssertTrue(store.canClear(first)); XCTAssertTrue(store.canClear(second))
            store.clear(first)
            let afterFirst = store.game
            XCTAssertTrue(store.busy); XCTAssertFalse(store.canClear(first)); XCTAssertTrue(store.canClear(second))
            store.clear(first)
            XCTAssertEqual(store.game, afterFirst, "Moving columns cannot consume a second action")
            store.clear(second)
            XCTAssertEqual(presenter.completions.count, 2)
            let committed = store.game
            XCTAssertGreaterThan(committed.score, afterFirst.score)
            let callbacks = reversed ? presenter.completions.reversed().map { $0 } : presenter.completions
            callbacks[0](); XCTAssertTrue(store.busy)
            callbacks[1](); XCTAssertFalse(store.busy)
            callbacks[0](); XCTAssertEqual(store.game, committed)
            let saved = try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
            XCTAssertEqual(saved, committed)
        }
    }

    @MainActor func testClearDuringUnrelatedArrivalRetainsShowerAndRejectsStaleCompletions() throws {
        let suite = "ConcurrentArrival.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        store.callShower()
        let arrival = try XCTUnwrap(store.pending)
        let cell = try XCTUnwrap(store.game.legalGroups.compactMap(\.first).first { store.canClear($0) })
        XCTAssertFalse(arrival.arrivals.isEmpty)
        XCTAssertFalse(store.timingSnapshot.canClear, "Whole-board readiness remains false during arrival")
        XCTAssertGreaterThan(store.timingSnapshot.admittedTapGroups, 0,
                             "The timing probe must retain legal ready-column choices")
        let admitted = store.game.legalGroups.filter { $0.first.map(store.canClear) ?? false }
        XCTAssertEqual(store.timingSnapshot.admittedTapGroups, admitted.count)
        store.clear(cell)
        XCTAssertEqual(presenter.completions.count, 2)
        XCTAssertEqual(store.pending?.arrivals.map { $0.star.id }, arrival.arrivals.map { $0.star.id }, "HUD keeps the active shower through an independent clear")
        XCTAssertEqual(store.pending?.forecast, arrival.forecast)
        let latest = store.game
        presenter.completions[1](); XCTAssertTrue(store.busy)
        store.setSuspended(true)
        XCTAssertEqual(store.timingSnapshot.admittedTapGroups, 0)
        presenter.completions[0]()
        XCTAssertFalse(store.busy); XCTAssertEqual(store.game, latest)
        XCTAssertEqual(presenter.lastRendered, latest)
    }

    @MainActor func testWaitingFeedbackEndsWithItsColumnsAndStaleTraceCannotLeaveANewNotice() throws {
        let suite = "ResponsiveNotice.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        store.clear(Cell(0,0)); store.clear(Cell(2,6))
        store.explainSettling(at: Cell(6,0))
        XCTAssertEqual(store.inputMessage, "Stars settling…")
        XCTAssertEqual(store.dialogue.line?.text, "Stars settling…")
        XCTAssertEqual(store.dialogue.line?.speaker, .spark)
        presenter.completions[0]()
        XCTAssertTrue(store.busy, "Another column still presents independently")
        XCTAssertNil(store.inputMessage, "The touched column is ready, so its wait cue must end")
        presenter.completions[1]()
        store.loadConstellationFixture(.diagonalSix)
        let snapshot = store.game, ticket = store.constellationInputGeneration
        store.restart(sameSky: true)
        let restarted = store.game
        store.clearTracedConstellation((0..<5).map { Cell($0,$0) }, snapshot: snapshot, generation: ticket)
        XCTAssertEqual(store.game, restarted)
        XCTAssertNil(store.inputMessage, "A stale release cannot add feedback to another sky")
    }

    @MainActor func testGravityPresentationKeepsItsNecessaryWholeBoardReservation() throws {
        let suite = "ResponsiveGravity.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset","--gravity-fixture=opportunity"], presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false); store.clear(Cell(0,3))
        XCTAssertFalse(try XCTUnwrap(store.pending).gravityPhases.isEmpty)
        XCTAssertEqual(store.changingColumns, Set(0..<7))
        XCTAssertEqual(store.timingSnapshot.admittedTapGroups, 0)
        for column in 0..<7 { XCTAssertFalse(store.canContact(Cell(0,column))) }
        let committed = store.game
        store.clear(Cell(0,0)); XCTAssertEqual(store.game, committed)
        presenter.finish(); XCTAssertTrue(store.changingColumns.isEmpty)
        XCTAssertEqual(store.game, committed)
    }

    @MainActor func testDriftingOrdinaryTouchIsAnchoredAndNeverBecomesAnUnavailableTrace() {
        let mapping = ObservatoryGeometry(size: CGSize(width: 390, height: 844))
        let cell = Cell(0,0), origin = mapping.viewPoint(cell)
        for distance in [0,4,7,8,12,18] as [CGFloat] {
            var session = ConstellationTouchSession()
            XCTAssertTrue(session.begin(at: origin, traceEligible: false))
            let end = CGPoint(x: origin.x+distance, y: origin.y)
            XCTAssertFalse(session.move(to: end))
            XCTAssertEqual(session.finish(at: end, mapping: mapping), .tap(cell))
            XCTAssertEqual(session.finish(at: end, mapping: mapping), .cancel)
        }
        var session = ConstellationTouchSession()
        XCTAssertTrue(session.begin(at: origin, traceEligible: false))
        XCTAssertFalse(session.move(to: CGPoint(x: origin.x+20, y: origin.y)))
        XCTAssertTrue(session.canceled)
        XCTAssertEqual(session.finish(at: origin, mapping: mapping), .cancel)
        XCTAssertTrue(session.begin(at: origin))
        XCTAssertTrue(session.move(to: CGPoint(x: origin.x+8, y: origin.y)))
        XCTAssertTrue(session.move(to: CGPoint(x: origin.x+12, y: origin.y)))
        XCTAssertEqual(session.finish(at: origin, mapping: mapping), .tap(cell))
    }

    @MainActor func testReadyContactDuringAnotherClearFreezesRainAndRejectsStaleRelease() throws {
        let suite = "ResponsiveHold.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false); store.togglePause()
        store.clear(Cell(0,0))
        let cell = Cell(2,6)
        XCTAssertTrue(store.busy); XCTAssertTrue(store.canClear(cell))
        let ticket = try XCTUnwrap(store.beginConstellationHold(at: cell))
        let committed = store.game
        clock.advance(100); XCTAssertEqual(store.game, committed)
        presenter.finish(); XCTAssertEqual(store.game, committed)
        store.setSuspended(true); store.setSuspended(false)
        let replacement = try XCTUnwrap(store.beginConstellationHold(at: cell))
        store.endConstellationHold(ticket)
        XCTAssertTrue(store.constellationTracing, "An old release cannot end the new contact")
        store.endConstellationHold(replacement)
        XCTAssertFalse(store.constellationTracing)
        XCTAssertNotNil(clock.deadline)
    }

    /// A queried-ready target is only a snapshot. Rain may own its columns before contact.
    @MainActor func testShowerBetweenReadinessQueryAndContactDoesNotQueueAStaleClear() throws {
        for column in [4, 6] {
            let suite = "ReadinessContact.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
            let presenter = FallingSkyRecorder(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            store.setSuspended(false)
            let target = Cell(2, column)
            XCTAssertTrue(store.canClear(target), "The earlier visible query admits this match")
            store.togglePause()
            clock.advance(try XCTUnwrap(clock.deadline) - clock.now)
            let shower = try XCTUnwrap(store.pending)
            XCTAssertFalse(shower.arrivals.isEmpty)
            XCTAssertFalse(store.canClear(target), "Rain now owns some of this match's columns")
            let afterRain = store.game
            let hold = store.beginConstellationHold(at: target)
            if column == 4 {
                XCTAssertNil(hold, "Contact on the arriving column is rejected immediately")
            } else {
                XCTAssertNotNil(hold, "A stable origin can begin a trace while its tap group is unavailable")
            }
            store.endConstellationHold(hold)
            store.clear(target)
            XCTAssertEqual(store.game, afterRain, "A stale query cannot clear moving stars")
            XCTAssertEqual(store.inputMessage, "Stars settling…")
            XCTAssertEqual(presenter.completions.count, 1)
            presenter.finish()
            XCTAssertEqual(store.game, afterRain, "Settling must not execute a queued tap")
            XCTAssertNil(store.inputMessage)
            XCTAssertTrue(store.canClear(target))
            var expected = afterRain
            let reward = try XCTUnwrap(expected.clear(target)).collected
            XCTAssertGreaterThan(reward, 0)
            let freshHold = try XCTUnwrap(store.beginConstellationHold(at: target))
            store.endConstellationHold(freshHold)
            store.clear(target)
            XCTAssertEqual(store.game, expected, "A new contact clears the current committed group exactly once")
            XCTAssertEqual(presenter.completions.count, 2)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))), expected)
        }
    }

    @MainActor func testExplicitInputFailureHasReadableAndSpokenFeedbackWithoutACommit() {
        let suite = "ResponsiveAccessibleFeedback.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = ResponsiveFeedback()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"], presenter: FallingSkyRecorder(), clock: ManualRainClock(), feedback: feedback)
        store.setSuspended(false)
        let before = store.game
        store.explainInputFailure("Trace needs 5 matching stars")
        XCTAssertEqual(store.inputMessage, "Trace needs 5 matching stars")
        XCTAssertEqual(store.dialogue.line?.text, "Trace needs 5 matching stars")
        XCTAssertTrue(store.dialogue.visible)
        XCTAssertEqual(feedback.announcements, ["Trace needs 5 matching stars"])
        XCTAssertEqual(store.game, before)
    }

    @MainActor func testOlderClearCompletionDoesNotReplaceANewerResult() throws {
        let suite = "ResponsiveSpeech.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder(), feedback = ResponsiveFeedback()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock(), feedback: feedback)
        store.setSuspended(false)
        store.clear(Cell(0,0)); store.clear(Cell(2,6))
        XCTAssertEqual(presenter.completions.count, 2)
        presenter.completions[1]()
        let count = feedback.announcements.count
        let visible = store.dialogue.line?.text
        presenter.completions[0]()
        XCTAssertEqual(feedback.announcements.count, count)
        XCTAssertEqual(store.dialogue.line?.text, visible)
    }
}

@MainActor private final class ResponsiveFeedback: FallingSkyFeedbackProviding {
    var announcements: [String] = []
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {}
    func announce(_ message: String) { announcements.append(message) }
    func stopSounds() {}
}

extension ResponsiveInputTests {
    func testAdmissionReasonsKeepReadyColumnsIndependentAndGlobalRestrictionsConsistent() {
        let active = SkyInputPolicy(suspended: false, gameOver: false, showerDue: false,
                                    changingColumns: [0,1], presenting: true)
        XCTAssertEqual(active.receiving, .ready)
        XCTAssertEqual(active.wholeBoard, .settling([0,1]))
        XCTAssertEqual(active.reserving([0,6]), .settling([0]))
        XCTAssertEqual(active.reserving([6]), .ready)
        for (suspended, over, due, expected) in [
            (true,false,false,SkyInputAvailability.suspended),
            (false,true,false,.gameOver), (false,false,true,.showerDue)
        ] {
            let policy = SkyInputPolicy(suspended:suspended,gameOver:over,showerDue:due,
                                        changingColumns:[0],presenting:true)
            XCTAssertEqual(policy.receiving,expected)
            XCTAssertEqual(policy.wholeBoard,expected)
            XCTAssertEqual(policy.reserving([6]),expected)
        }
    }

    @MainActor func testPausedExplicitActionsAndDueShowerUseSharedAdmissionReasons() throws {
        let suite = "AdmissionMatrix.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense:false)),forKey:FallingSkyStore.saveKey)
        let clock = ManualRainClock(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock)
        let cell = Cell(0,0)
        XCTAssertEqual(store.clearAvailability(cell),.suspended)
        XCTAssertEqual(store.traceAvailability([cell]),.suspended)
        store.setSuspended(false)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.clearAvailability(cell),.ready)
        XCTAssertEqual(store.traceAvailability([cell]),.ready)
        XCTAssertEqual(store.traceAvailability([]),.emptySelection)
        store.togglePause()
        store.clear(cell)
        XCTAssertEqual(store.clearAvailability(cell),.settling([0]))
        XCTAssertEqual(store.traceAvailability([cell]),.settling([0]))
        XCTAssertEqual(store.clearAvailability(Cell(2,6)),.ready)
        clock.advance(try XCTUnwrap(clock.deadline)-clock.now)
        XCTAssertEqual(store.clearAvailability(Cell(2,6)),.showerDue)
        XCTAssertEqual(store.traceAvailability([Cell(2,6)]),.showerDue)
        let before = store.game
        XCTAssertNil(store.beginConstellationHold(at:Cell(2,6)))
        store.clear(Cell(2,6))
        XCTAssertEqual(store.game,before)
        presenter.finish()
        XCTAssertEqual(store.game.turns,before.turns+1,"Only the deferred shower commits; input is never replayed")
    }
}

extension ResponsiveInputTests {
    @MainActor func testTraceSpeechUsesInjectedFeedbackAndRejectsExpiredHoldOrGeneration() throws {
        let suite = "TraceSpeech.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let feedback = TracePolicyFeedback()
        let store = FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset"],presenter:FallingSkyRecorder(),clock:ManualRainClock(),feedback:feedback)
        store.setSuspended(false); store.loadConstellationFixture(.diagonalSix)
        let game = store.game, saved = defaults.data(forKey:FallingSkyStore.saveKey)
        let first = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        let generation = store.constellationInputGeneration
        store.announceTraceSelection(count:1,value:1,ready:false,generation:generation,holdTicket:first)
        store.announceTraceSelection(count:5,value:7,ready:true,generation:generation,holdTicket:first)
        XCTAssertEqual(feedback.announcements, [
            "Stars selected: 1. Starlight if cleared: 1. Trace 5 matching stars, or a 4-star square in Open sky.",
            "Stars selected: 5. Starlight if cleared: 7. Ready to release."
        ])
        store.endConstellationHold(first)
        store.announceTraceSelection(count:1,value:1,ready:false,generation:generation,holdTicket:first)
        let second = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        store.announceTraceSelection(count:5,value:5,ready:true,generation:generation,holdTicket:first)
        XCTAssertEqual(feedback.announcements.count,2,"Neither released nor replaced selections may announce")
        store.announceTraceSelection(count:0,value:0,ready:false,generation:generation,holdTicket:second)
        XCTAssertEqual(feedback.announcements.last,"Trace canceled. Choose a touching matching star.")
        XCTAssertEqual(store.game,game); XCTAssertEqual(defaults.data(forKey:FallingSkyStore.saveKey),saved)
        store.restart(sameSky:true)
        store.announceTraceSelection(count:5,value:5,ready:true,generation:generation,holdTicket:second)
        store.setSuspended(true)
        store.announceTraceSelection(count:0,value:0,ready:false,generation:store.constellationInputGeneration,holdTicket:nil)
        XCTAssertEqual(feedback.announcements.count,3,"Restart/settings cannot add stale speech")
    }

    @MainActor func testTraceHapticsSharePreferencesAndRequireLiveInputOwnership() throws {
        let suite = "TraceHaptics.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let feedback = TracePolicyFeedback()
        let store = FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset"],presenter:FallingSkyRecorder(),clock:ManualRainClock(),feedback:feedback)
        store.setSuspended(false); store.loadConstellationFixture(.diagonalSix)
        store.traceStep(count:2)
        XCTAssertTrue(feedback.steps.isEmpty)
        let hold = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        store.traceStep(count:2)
        store.hapticsEnabled=false; store.traceStep(count:3)
        store.endConstellationHold(hold); store.traceStep(count:4)
        store.setReducedMotion(true); store.hapticsEnabled=true
        XCTAssertNotNil(store.beginConstellationHold(at:Cell(0,0)))
        store.traceStep(count:5)
        store.setSuspended(true); store.traceStep(count:6)
        XCTAssertEqual(feedback.steps,[2,3,5])
        XCTAssertEqual(feedback.enabled,[true,false,false])
    }
}

@MainActor private final class TracePolicyFeedback: FallingSkyFeedbackProviding {
    var announcements: [String] = []
    var steps: [Int] = []
    var enabled: [Bool] = []
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {}
    func announce(_ message: String) { announcements.append(message) }
    func traceStep(count: Int, enabled: Bool) { steps.append(count); self.enabled.append(enabled) }
    func stopSounds() {}
}
