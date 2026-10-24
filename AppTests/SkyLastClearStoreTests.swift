import XCTest
@testable import StarfallCore
@testable import Starfall

@MainActor private final class LastClearPresenter: FallingSkyPresenting {
    struct Pending { let phase: (Int) -> Void; let complete: () -> Void }
    var reduceMotion = false
    var pending: [Pending] = []
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) {
        pending.append(.init(phase: { _ in }, complete: completion))
    }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        pending.append(.init(phase: phaseBegan, complete: completion))
    }
}

final class SkyLastClearStoreTests: XCTestCase {
    @MainActor private func make(_ game: FallingSky) throws
        -> (FallingSkyStore, LastClearPresenter, ManualRainClock, UserDefaults) {
        let suite = "Starfall.LastClear.\(UUID())"
        let saved = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { saved.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: saved)
        let presenter = LastClearPresenter(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false)
        return (store, presenter, clock, saved)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, in store: FallingSkyStore) {
        XCTAssertTrue(store.performTechnique(.nudge(Cell(from / 7, from % 7), Cell(to / 7, to % 7)),
            snapshot: store.game, generation: store.constellationInputGeneration))
    }

    @MainActor func testWinningCapturePrecedesCallbacksAndReadingCannotChangeCommitOrReviveRetiredArt() throws {
        let (store, presenter, clock, saved) = try make(.freshChallenge(.silverPools))
        defer { store.setSuspended(true) }
        let opening = store.game
        XCTAssertNil(store.lastClear)
        exchange(9, 10, in: store)
        let recap = try XCTUnwrap(store.lastClear)
        XCTAssertEqual(recap.score.phases.map(\.points), [5_000, 14_000])
        XCTAssertEqual(recap.survivorCount, 1)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertNil(store.celebration)
        XCTAssertNil(clock.deadline)
        let committed = store.game, bytes = saved.data(forKey: SkySaveArchive.key)
        let world = saved.data(forKey: WorldJourneyStore.key)
        let mastery = saved.data(forKey: StoryMasteryStore.key)
        let late = try XCTUnwrap(presenter.pending.last)
        store.settlePresentation(reason: "terminal recap")
        for _ in 0..<3 {
            _ = SkyLastClearCopy.context(recap.context)
            _ = recap.phases.map(SkyLastClearCopy.ingredients)
            _ = SkyLastClearCopy.room(recap)
            store.setSuspended(true)
            store.setSuspended(false)
        }
        let generation = store.constellationInputGeneration
        late.phase(0); late.phase(1); late.complete()
        XCTAssertEqual(store.lastClear, recap)
        XCTAssertEqual(store.finalScoreExplanation, recap.score)
        XCTAssertEqual(store.finalSurvivorCount, recap.survivorCount)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(store.constellationInputGeneration, generation)
        XCTAssertEqual(saved.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(saved.data(forKey: WorldJourneyStore.key), world)
        XCTAssertEqual(saved.data(forKey: StoryMasteryStore.key), mastery)
        let cold = FallingSkyStore(defaults: saved, arguments: [], presenter: LastClearPresenter(), clock: ManualRainClock())
        XCTAssertEqual(cold.game, committed)
        XCTAssertNil(cold.lastClear)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, opening)
        XCTAssertNil(store.lastClear)
        late.phase(1); late.complete()
        XCTAssertNil(store.lastClear)
    }

    @MainActor func testSeparateClearsReplaceWholeSnapshotAndNoClearDoesNotBecomeLastAction() throws {
        let (store, presenter, _, saved) = try make(.freshChallenge(.silverPools))
        defer { store.setSuspended(true) }
        exchange(2, 9, in: store)
        let first = try XCTUnwrap(store.lastClear)
        XCTAssertEqual(first.score.total, 7_000)
        presenter.pending.last?.complete()
        exchange(23, 22, in: store)
        let second = try XCTUnwrap(store.lastClear)
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(second.score.total, 5_000)
        XCTAssertEqual(second.phases.count, 1)
        XCTAssertEqual(second.survivorCount, 0)
        XCTAssertEqual(store.game.displayScore, 12_000)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(saved.data(forKey: SkySaveArchive.key))), store.game)

        let session = SkyLightReceiptSession()
        let old = FallingSky.freshChallenge(.silverPools)
        var game = old
        let turn = try XCTUnwrap(game.nudge(from: Cell(0,2), to: Cell(1,2)))
        session.capture(turn, from: old, to: game, path: [], recipe: nil)
        let retained = session.lastClear
        let setup = FallingSkyTurn(cleared: [], collected: 0, settled: game.board,
                                  forecast: game.incoming, arrivals: [], blockedColumn: nil)
        session.capture(setup, from: game, to: game, path: [], recipe: nil)
        XCTAssertEqual(session.lastClear, retained)
        session.cancel()
        XCTAssertEqual(session.lastClear, retained)
    }

    @MainActor func testGenuineZeroLightReplacesNumericAndBoardRecordWithoutMislabelingLastEarnedGeometry() throws {
        let session = SkyLightReceiptSession()
        let old = ConstellationFixture.singleGap.game()
        var game = old
        let path = [0,1,2,3,5].map { Cell(0,$0) }
        let positive = try XCTUnwrap(game.clearConstellation(path))
        session.capture(positive, from: old, to: game, path: path, recipe: nil)
        let first = try XCTUnwrap(session.lastClear), earned = session.lastEarned
        let dusk = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var cleared = dusk
        let zero = try XCTUnwrap(cleared.clear(Cell(0,1)))
        session.capture(zero, from: dusk, to: cleared, path: [], recipe: nil)
        let replacement = try XCTUnwrap(session.lastClear)
        XCTAssertNotEqual(replacement.id, first.id)
        XCTAssertEqual(replacement.score.total, 0)
        XCTAssertEqual(replacement.phases[0].cleared.count, 4)
        XCTAssertEqual(replacement.resultingOccupiedCount, 0)
        XCTAssertEqual(replacement.phases[0].drained, Set([Cell(0,1), Cell(0,2)]))
        XCTAssertEqual(session.lastScore, replacement.score)
        XCTAssertEqual(session.lastEarned, earned, "The separately labeled Last earned light keeps its positive meaning")
        XCTAssertTrue(SkyLastClearCopy.ingredients(replacement.phases[0]).contains("Gray stars were drained by Dusk"))
        session.beginRound()
        XCTAssertNil(session.lastClear)
        XCTAssertNil(session.lastEarned)
    }

    @MainActor func testPausedLiveReadingPreservesDeadlineSaveAndImmutablePriorClearDuringEntryCancellation() throws {
        let (store, presenter, clock, saved) = try make(.freshChallenge(.kiteHarbor))
        defer { store.setSuspended(true) }
        exchange(15, 14, in: store)
        presenter.pending.last?.complete()
        let recap = try XCTUnwrap(store.lastClear)
        let before = store.timingSnapshot
        let bytes = saved.data(forKey: SkySaveArchive.key), world = saved.data(forKey: WorldJourneyStore.key)
        let mastery = saved.data(forKey: StoryMasteryStore.key)
        var flow = SkyFlowState(practice: .fullBoardRefill)
        _ = flow.handle(.another, hasSavedSky: true)
        let entry = try XCTUnwrap(flow.entryID)
        _ = flow.handle(.entryBack, hasSavedSky: true, entryID: entry)
        XCTAssertEqual(flow.screen, .playing)
        for phase in recap.phases { XCTAssertFalse(SkyLastClearCopy.ingredients(phase).isEmpty) }
        XCTAssertNotNil(SkyLastClearCopy.room(recap))
        XCTAssertEqual(store.lastClear, recap)
        XCTAssertEqual(store.timingSnapshot.game, before.game)
        XCTAssertEqual(store.timingSnapshot.paused, before.paused)
        XCTAssertEqual(store.timingSnapshot.cadence, before.cadence)
        XCTAssertEqual(store.timingSnapshot.scheduledDeadline, before.scheduledDeadline)
        XCTAssertEqual(store.constellationInputGeneration, before.inputGeneration)
        XCTAssertEqual(clock.deadline, before.scheduledDeadline)
        XCTAssertEqual(saved.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(saved.data(forKey: WorldJourneyStore.key), world)
        XCTAssertEqual(saved.data(forKey: StoryMasteryStore.key), mastery)
    }
}
