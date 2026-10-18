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
        store.clear(cell)
        XCTAssertEqual(presenter.completions.count, 2)
        XCTAssertEqual(store.pending?.arrivals.map { $0.star.id }, arrival.arrivals.map { $0.star.id }, "HUD keeps the active shower through an independent clear")
        XCTAssertEqual(store.pending?.forecast, arrival.forecast)
        let latest = store.game
        presenter.completions[1](); XCTAssertTrue(store.busy)
        store.setSuspended(true)
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
        XCTAssertFalse(session.move(to: CGPoint(x: origin.x+8, y: origin.y)))
        XCTAssertTrue(session.move(to: CGPoint(x: origin.x+12, y: origin.y)))
        XCTAssertEqual(session.finish(at: origin, mapping: mapping), .trace)
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

    @MainActor func testExplicitInputFailureHasReadableAndSpokenFeedbackWithoutACommit() {
        let suite = "ResponsiveAccessibleFeedback.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let feedback = ResponsiveFeedback()
        let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset"], presenter: FallingSkyRecorder(), clock: ManualRainClock(), feedback: feedback)
        store.setSuspended(false)
        let before = store.game
        store.explainInputFailure("Trace needs 5 matching stars")
        XCTAssertEqual(store.inputMessage, "Trace needs 5 matching stars")
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
