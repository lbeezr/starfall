import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class SkyRestoredPlaceStoreTests: XCTestCase {
    private let highRoute = [(27,34), (1,2), (31,32), (12,13), (16,17),
                             (8,9), (11,12), (29,30), (29,36), (9,16)]

    @MainActor private func defaults() throws -> UserDefaults {
        let suite = "Starfall.RestoredPlace.\(UUID())"
        let value = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { value.removePersistentDomain(forName: suite) }
        return value
    }

    private func currentWinner() throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        for (from, to) in highRoute {
            _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertNotNil(game.completedMasteryRun)
        return game
    }

    @MainActor private func historicalWinner() throws -> FallingSky {
        var game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        _ = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        return game
    }

    @MainActor private func make(completed: FallingSky, retained: FallingSky) throws
        -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let saved = try defaults()
        // Genuine completion uses the production archive-before-projections order.
        try SkySaveArchive.save(completed, to: saved)
        try WorldJourneyStore(defaults: saved).record(completed)
        try StoryMasteryStore(defaults: saved).record(completed)
        try SkySaveArchive.save(retained, to: saved)
        try WorldJourneyStore(defaults: saved).select(.firstLight)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false)
        return (store, presenter, clock, saved)
    }

    @MainActor private func exchange(_ move: (Int, Int), in store: FallingSkyStore,
                                    presenter: FallingSkyRecorder) {
        XCTAssertTrue(store.performTechnique(.nudge(Cell(move.0 / 7, move.0 % 7), Cell(move.1 / 7, move.1 % 7)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        presenter.finish()
    }

    @MainActor private struct Retained {
        let game: FallingSky
        let paused: Bool
        let remaining: TimeInterval
        let deadline: TimeInterval?
        let generation: UInt64
        let journey: WorldJourney
        let records: [StoryMasteryRecord]
        let lastClear: SkyLastClearSnapshot?
        let finalLight: SkyFinalLightReceipt?
        let roundBytes: Data?
        let worldBytes: Data?
        let masteryBytes: Data?

        init(_ store: FallingSkyStore, clock: ManualRainClock, saved: UserDefaults) {
            game = store.game; paused = store.isPaused
            remaining = store.showerCountdown.remaining; deadline = clock.deadline
            generation = store.constellationInputGeneration
            journey = store.journey.journey; records = store.mastery.records
            lastClear = store.lastClear; finalLight = store.finalLight
            roundBytes = saved.data(forKey: SkySaveArchive.key)
            worldBytes = saved.data(forKey: WorldJourneyStore.key)
            masteryBytes = saved.data(forKey: StoryMasteryStore.key)
        }

        func assertUnchanged(_ store: FallingSkyStore, clock: ManualRainClock, saved: UserDefaults,
                             checkClock: Bool = true, file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(store.game, game, file: file, line: line)
            XCTAssertEqual(store.isPaused, paused, file: file, line: line)
            XCTAssertEqual(store.constellationInputGeneration, generation, file: file, line: line)
            XCTAssertEqual(store.journey.journey, journey, file: file, line: line)
            XCTAssertEqual(store.mastery.records, records, file: file, line: line)
            XCTAssertEqual(store.lastClear, lastClear, file: file, line: line)
            XCTAssertEqual(store.finalLight, finalLight, file: file, line: line)
            XCTAssertEqual(saved.data(forKey: SkySaveArchive.key), roundBytes, file: file, line: line)
            XCTAssertEqual(saved.data(forKey: WorldJourneyStore.key), worldBytes, file: file, line: line)
            XCTAssertEqual(saved.data(forKey: StoryMasteryStore.key), masteryBytes, file: file, line: line)
            if checkClock {
                XCTAssertEqual(clock.deadline, deadline, file: file, line: line)
                XCTAssertEqual(store.showerCountdown.remaining, remaining, file: file, line: line)
            }
        }
    }

    /// Exercises this component's real hosting lifecycle. It deliberately does
    /// not claim to invoke FallingSkyView's private Map/modal callback; native
    /// tests own that route and its physical Back action.
    @MainActor private func host(_ snapshot: SkyRestoredPlaceSnapshot,
                                 whileHidden: () throws -> Void) throws {
        var backs = 0
        let view = SkyRestoredPlaceView(snapshot: snapshot, active: true, quiet: false, back: { backs += 1 })
        let controller = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        controller.view.layoutIfNeeded()
        controller.rootView = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: { backs += 1 })
        controller.view.layoutIfNeeded()
        window.isHidden = true
        try whileHidden()
        window.isHidden = false
        controller.rootView = SkyRestoredPlaceView(snapshot: snapshot, active: true, quiet: true, back: { backs += 1 })
        controller.view.layoutIfNeeded()
        XCTAssertEqual(backs, 0, "Rendering, hiding and quiet changes cannot dismiss or mutate a round")
    }

    @MainActor func testMasteryOnlyWithoutWorldCompletionDoesNotAdmitAViewer() throws {
        let saved = try defaults(), winner = try currentWinner()
        // Populate only the independent best store, leaving round/world absent.
        try StoryMasteryStore(defaults: saved).record(winner)
        XCTAssertEqual(StoryMasteryStore(defaults: saved).records.count, 1)
        let journey = WorldJourneyStore(defaults: saved).journey
        XCTAssertTrue(journey.completed.isEmpty)
        XCTAssertTrue(journey.canEnter(.firstLight))
        XCTAssertNil(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
        XCTAssertNil(saved.data(forKey: WorldJourneyStore.key))
        XCTAssertNil(saved.data(forKey: SkySaveArchive.key))
    }

    @MainActor func testReaderLifecyclePreservesBothOppositeRetainedModesAndTheExistingFrozenRemainder() throws {
        for fullBoard in [false, true] {
            for paused in [false, true] {
                let completed: FallingSky
                if fullBoard { completed = try historicalWinner() }
                else { completed = try currentWinner() }
                XCTAssertNotEqual(completed.usesFullBoardRefill, fullBoard)
                var opening = fullBoard ? FallingSky.fullBoardLantern() : FallingSky.freshChallenge(.firstLight)
                XCTAssertTrue(opening.enrollMastery(runID: UUID()))
                let (store, presenter, clock, saved) = try make(completed: completed, retained: opening)
                defer { store.setSuspended(true) }
                exchange(fullBoard ? (27,34) : (8,9), in: store, presenter: presenter)
                XCTAssertEqual(store.game.displayScore, fullBoard ? 42_000 : 15_000)
                XCTAssertNotNil(store.lastClear)
                XCTAssertEqual(store.game.usesFullBoardRefill, fullBoard)
                if !paused { store.togglePause(); clock.advance(0.1) }
                let liveRemainder = clock.deadline.map { $0 - clock.now }, staleRain = clock.action
                var flow = SkyFlowState(arguments: ["--starfalls-reset"])
                XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
                store.setSuspended(true)
                let before = Retained(store, clock: clock, saved: saved), map = flow
                XCTAssertNil(before.deadline)
                let snapshot = try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: store.journey.journey))
                XCTAssertEqual(snapshot.presentation.progress.fraction, 1)
                XCTAssertLessThan(try XCTUnwrap(store.game.restoration).fraction, 1,
                                  "The viewer's completed painting must not borrow this unfinished round")
                try host(snapshot) {
                    store.setSuspended(true) // Same suspended Map owner during background.
                    staleRain?(); clock.advance(100)
                    before.assertUnchanged(store, clock: clock, saved: saved)
                }
                XCTAssertEqual(flow, map)
                before.assertUnchanged(store, clock: clock, saved: saved)
                XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), .continued)
                store.setSuspended(false)
                before.assertUnchanged(store, clock: clock, saved: saved, checkClock: false)
                if let liveRemainder {
                    XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, liveRemainder, accuracy: 0.0001)
                } else { XCTAssertNil(clock.deadline) }
                XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(saved.data(forKey: SkySaveArchive.key))), store.game)
            }
        }
    }

    @MainActor func testWinningResultAndLastClearSurviveReadOnlyViewingAndReturnToTheSameResult() throws {
        var opening = FallingSky.fullBoardLantern()
        XCTAssertTrue(opening.enrollMastery(runID: UUID()))
        let (store, presenter, clock, saved) = try make(completed: historicalWinner(), retained: opening)
        defer { store.setSuspended(true) }
        for move in highRoute { exchange(move, in: store, presenter: presenter) }
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertEqual(store.game.displayScore, 156_000)
        XCTAssertEqual(store.lastClear?.score.total, 58_000)
        XCTAssertNotNil(store.finalLight)
        XCTAssertFalse(store.mastery.records.isEmpty)
        try store.journey.select(.firstLight)
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        store.setSuspended(true)
        let before = Retained(store, clock: clock, saved: saved)
        let result = SkyResultSnapshot(game: store.game)
        let snapshot = try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: store.journey.journey))
        try host(snapshot) { clock.advance(100); before.assertUnchanged(store, clock: clock, saved: saved) }
        before.assertUnchanged(store, clock: clock, saved: saved)
        XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), .continued)
        XCTAssertEqual(flow.screen, .playing, "The existing ceremony derives this retained terminal result")
        XCTAssertEqual(SkyResultSnapshot(game: store.game), result)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(store.lastClear, before.lastClear)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(before.roundBytes)) as? [String: Any])
        XCTAssertEqual(fields["schemaVersion"] as? Int, 19)
    }

    @MainActor func testRevisitEntryCancellationRetainsTheRoundAndOnlyBeginReplacesIt() throws {
        var opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(opening.enrollMastery(runID: UUID()))
        let (store, presenter, clock, saved) = try make(completed: currentWinner(), retained: opening)
        defer { store.setSuspended(true) }
        exchange((8,9), in: store, presenter: presenter)
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        store.setSuspended(true)
        let before = Retained(store, clock: clock, saved: saved)
        let snapshot = try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: store.journey.journey))
        XCTAssertTrue(snapshot.matches(store.journey.journey))
        // Apply existing flow effects explicitly; actual Revisit/Back/Begin
        // controls and the new modal callback are native interaction coverage.
        XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
        let canceledID = try XCTUnwrap(flow.entryID)
        XCTAssertEqual(flow.entry, .firstLight)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: canceledID), .worldMap)
        XCTAssertEqual(flow.screen, .worldMap)
        before.assertUnchanged(store, clock: clock, saved: saved)
        XCTAssertEqual(flow.handle(.fullBoardLantern, hasSavedSky: true), .staged)
        let beginID = try XCTUnwrap(flow.entryID)
        XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: canceledID))
        before.assertUnchanged(store, clock: clock, saved: saved)
        guard case .began(let request) = flow.handle(.begin, hasSavedSky: true, entryID: beginID) else {
            return XCTFail("Expected the current explicit Begin")
        }
        XCTAssertEqual(request, .fullBoardLantern)
        XCTAssertTrue(store.beginEntry(request))
        var expected = FallingSky.fullBoardLantern()
        XCTAssertTrue(expected.enrollMastery(runID: try XCTUnwrap(store.game.masteryEnrollment).runID))
        XCTAssertEqual(store.game, expected)
        XCTAssertTrue(store.game.usesFullBoardRefill)
        XCTAssertEqual(store.game.displayScore, 0)
        XCTAssertNil(store.lastClear)
        XCTAssertNil(store.finalLight)
        XCTAssertEqual(store.journey.journey, before.journey)
        XCTAssertEqual(store.mastery.records, before.records)
    }
}
