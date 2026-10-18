import XCTest
import SpriteKit
import StarfallCore
@testable import Starfall

final class SkyPhasePresentationTests: XCTestCase {
    private func sky(after showers: Int) -> FallingSky {
        var game = FallingSky(seed: 17, generation: .current)
        for _ in 0..<showers {
            XCTAssertNotNil(game.letStarsFall())
            for _ in 0..<49 {
                guard let cell = game.legalGroups.first?.first else { break }
                XCTAssertNotNil(game.clear(cell))
            }
        }
        XCTAssertTrue(game.isValidSave); XCTAssertFalse(game.isOver)
        return game
    }
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.Phases.\(UUID().uuidString)"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }
    func testWarningStormRecoveryAndLaterCycleFollowCommittedForecast() throws {
        for (turns, expected, announces) in [
            (0, "9 lighter showers before the storm.", false),
            (8, "1 lighter shower before the storm.", true),
            (9, "Storm: 3 heavy showers left.", true),
            (10, "Storm: 2 heavy showers left.", false),
            (11, "Storm: 1 heavy shower left.", false),
            (12, "9 lighter showers before the storm.", true),
            (20, "1 lighter shower before the storm.", true),
            (21, "Storm: 3 heavy showers left.", true)
        ] {
            var game = sky(after: turns)
            let cue = try XCTUnwrap(SkyPhaseCue(game: game))
            XCTAssertEqual(cue.text, expected); XCTAssertEqual(cue.announcesTransition, announces)
            let turn = try XCTUnwrap(game.letStarsFall())
            XCTAssertEqual(SkyPhaseCue(game: game, pending: turn), cue, "Arrival still displays its committed forecast")
            XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
            XCTAssertEqual(SkyPhaseCue(game: game)?.shower, turns + 2)
        }
        XCTAssertNil(SkyPhaseCue(game: FallingSky(seed: 17)))
        XCTAssertNil(SkyPhaseCue(game: FallingSky(challenge: .firstLight)))
    }
    @MainActor func testFreshSkyOptsInButOldRestoreAndReplayKeepOriginalRules() throws {
        let saved = defaults(), old = FallingSky(seed: 17)
        saved.set(try JSONEncoder().encode(old), forKey: SkySaveArchive.legacyKey)
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.game, old.adoptingFeedingDusk()); XCTAssertNil(store.phaseCue)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.generation, .legacy); XCTAssertNil(store.phaseCue)
        store.restart(sameSky: false)
        XCTAssertEqual(store.game.generation, .current); XCTAssertNotNil(store.phaseCue)
        store.startFirstLight()
        XCTAssertEqual(store.game.generation, .legacy); XCTAssertNil(store.phaseCue)
        let fresh = FallingSkyStore(defaults: defaults(), arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(fresh.game.generation, .current); XCTAssertNotNil(fresh.phaseCue)
    }
    @MainActor func testAutomaticTransitionSpeaksAtSettlementAndInterruptionRejectsStaleSpeech() throws {
        let saved = defaults(), original = sky(after: 8)
        saved.set(try SkySaveArchive.encode(original), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: clock, feedback: feedback)
        store.setSuspended(false); store.togglePause()
        clock.advance(store.showerInterval)
        XCTAssertEqual(store.game.turns, 9)
        XCTAssertEqual(store.phaseCue?.shower, 9); XCTAssertTrue(feedback.announcements.isEmpty)
        presenter.finish()
        XCTAssertEqual(store.phaseCue?.shower, 10)
        XCTAssertEqual(feedback.announcements, ["Nova. Storm: 3 heavy showers left. Showers get faster after the next shower."])
        clock.advance(store.showerInterval); presenter.finish()
        XCTAssertEqual(store.game.turns, 10); XCTAssertEqual(feedback.announcements.count, 1)
        store.setSuspended(true)
        let committed = store.game
        clock.advance(100); presenter.finish()
        XCTAssertEqual(store.game, committed); XCTAssertEqual(feedback.announcements.count, 1)
        let restored = FallingSkyStore(defaults: saved, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, committed); XCTAssertEqual(restored.phaseCue, store.phaseCue)
        XCTAssertTrue(restored.isPaused)
    }
    @MainActor func testLiveTraceUsesCoreFamilyThroughOpalAndRejectsAnotherColor() throws {
        let game = ConstellationFixture.opalTrace.game(), intent = ConstellationTraceIntent()
        let path = (0..<5).map { Cell($0, 2) }
        let ticket = try XCTUnwrap(intent.begin(path[0], game: game, generation: 1, enabled: true))
        for cell in path.dropFirst() {
            XCTAssertTrue(intent.visit(cell, ticket: ticket, game: game, generation: 1, enabled: true))
        }
        XCTAssertEqual(intent.count, 5); XCTAssertEqual(intent.value, 8)
        XCTAssertNotNil(intent.finish(ticket: ticket, game: game, generation: 1, enabled: true))
        let shared = ConstellationFixture.opalChoice.game()
        let rose = [Cell(3,1), Cell(3,2), Cell(2,3), Cell(2,4), Cell(2,5)]
        let branch = try XCTUnwrap(intent.begin(rose[0], game: shared, generation: 2, enabled: true))
        for cell in rose.dropFirst() { XCTAssertTrue(intent.visit(cell, ticket: branch, game: shared, generation: 2, enabled: true)) }
        XCTAssertFalse(intent.visit(Cell(3,5), ticket: branch, game: shared, generation: 2, enabled: true))
        XCTAssertEqual(intent.snapshot, shared, "A spatial miss must not replace the rose family")
        XCTAssertEqual(intent.count, 5)
        let preserved = try XCTUnwrap(intent.finish(ticket: branch, game: shared, generation: 2, enabled: true))
        XCTAssertFalse(preserved.path.contains(Cell(3,5)))
        XCTAssertNil(intent.begin(Cell(2,5), game: shared, generation: 2, enabled: true))
    }
    @MainActor func testCanceledManualWarningDoesNotSpeakAnObsoletePhase() throws {
        let saved = defaults()
        saved.set(try SkySaveArchive.encode(sky(after: 8)), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: ManualRainClock(), feedback: feedback)
        store.setSuspended(false); store.callShower()
        XCTAssertEqual(store.phaseCue?.shower, 9)
        store.setSuspended(true); presenter.finish()
        XCTAssertEqual(store.phaseCue?.shower, 10); XCTAssertTrue(feedback.announcements.isEmpty)
    }
}


extension SkyPhasePresentationTests {
    func testPresentationTicketsPreserveConcurrentReservationsAndRejectReplacedCompletions() throws {
        var game = FallingSky.freshSurvival(seed: 5)
        let first = try XCTUnwrap(game.letStarsFall())
        let second = try XCTUnwrap(game.letStarsFall())
        var ledger = SkyPresentationLedger()
        let a = ledger.begin(first), b = ledger.begin(second)
        XCTAssertEqual(ledger.changingColumns, first.changingColumns.union(second.changingColumns))
        XCTAssertEqual(ledger.pending?.forecast, first.forecast)
        XCTAssertTrue(ledger.complete(b)); XCTAssertFalse(ledger.complete(b))
        XCTAssertTrue(ledger.busy)
        XCTAssertEqual(ledger.changingColumns, first.changingColumns)
        XCTAssertTrue(ledger.isLatest(b)); XCTAssertFalse(ledger.isLatest(a))
        ledger.invalidate()
        let replacement = ledger.begin(second)
        XCTAssertFalse(ledger.complete(a)); XCTAssertFalse(ledger.complete(b))
        XCTAssertTrue(ledger.busy); XCTAssertTrue(ledger.isLatest(replacement))
        XCTAssertTrue(ledger.complete(replacement)); XCTAssertFalse(ledger.busy)
        XCTAssertNil(ledger.pending); XCTAssertTrue(ledger.changingColumns.isEmpty)
    }
}
