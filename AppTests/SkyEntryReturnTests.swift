import XCTest
import StarfallCore
@testable import Starfall

final class SkyEntryReturnTests: XCTestCase {
    private enum InjectedFailure: Error { case write }

    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.EntryReturn.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor private struct RetainedRound {
        let game: FallingSky
        let paused: Bool
        let journey: WorldJourney
        let records: [StoryMasteryRecord]
        let roundBytes: Data?
        let worldBytes: Data?
        let bestBytes: Data?

        init(_ store: FallingSkyStore, defaults: UserDefaults) {
            game = store.game; paused = store.isPaused
            journey = store.journey.journey; records = store.mastery.records
            roundBytes = defaults.data(forKey: SkySaveArchive.key)
            worldBytes = defaults.data(forKey: WorldJourneyStore.key)
            bestBytes = defaults.data(forKey: StoryMasteryStore.key)
        }

        func assertUnchanged(_ store: FallingSkyStore, defaults: UserDefaults,
                             file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(store.game, game, file: file, line: line)
            XCTAssertEqual(store.isPaused, paused, file: file, line: line)
            XCTAssertEqual(store.journey.journey, journey, file: file, line: line)
            XCTAssertEqual(store.mastery.records, records, file: file, line: line)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes, file: file, line: line)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes, file: file, line: line)
            XCTAssertEqual(defaults.data(forKey: StoryMasteryStore.key), bestBytes, file: file, line: line)
        }
    }

    private func fullBoardWinner() throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        for (from, to) in [(27,34),(1,2),(31,32),(12,13),(16,17),
                           (8,9),(11,12),(29,30),(29,36),(9,16)] {
            _ = try XCTUnwrap(game.nudge(from: Cell(from/7,from%7), to: Cell(to/7,to%7)))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        return game
    }

    func testDirectEntryBackReturnsToPlayWithoutAnAdmissionHandoff() throws {
        for action in [SkyFlowAction.replay, .another, .firstLight] {
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            XCTAssertEqual(flow.screen, .playing)
            XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
            let id = try XCTUnwrap(flow.entryID)
            XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true))
            XCTAssertEqual(flow.screen, .entry)
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: id), .continued)
            XCTAssertEqual(flow.screen, .playing)
            XCTAssertNil(flow.entry); XCTAssertNil(flow.entryID); XCTAssertNil(flow.handoff)
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: id))
            XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: id))
            XCTAssertNil(flow.handle(.resume, hasSavedSky: true), "Returning never requires Home's Continue action")
            XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
            XCTAssertNotEqual(flow.entryID, id)
            let next = flow
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: id))
            XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: id))
            XCTAssertEqual(flow, next)
        }
    }

    @MainActor func testReplayAndNewCancellationPreservePauseAndTheFrozenClockRemainder() throws {
        for paused in [false, true] {
            for action in [SkyFlowAction.replay, .another] {
                let defaults = defaults(), clock = ManualRainClock()
                try SkySaveArchive.save(FallingSky(seed: 5, balance: .init(pace: .steady), openingCascade: false), to: defaults)
                let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
                store.setSuspended(false)
                if !paused { store.togglePause(); clock.advance(0.1) }
                let remainder = clock.deadline.map { $0-clock.now }
                let staleRain = clock.action
                let retained = RetainedRound(store, defaults: defaults)
                var flow = SkyFlowState(arguments: ["--starfalls-reset"])
                XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
                store.setSuspended(true)
                XCTAssertNil(clock.deadline)
                staleRain?(); clock.advance(100)
                retained.assertUnchanged(store, defaults: defaults)
                XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .continued)
                XCTAssertNil(flow.handoff, "Cancellation cannot restart admission or reset the shower clock")
                store.setSuspended(false)
                retained.assertUnchanged(store, defaults: defaults)
                if let remainder {
                    XCTAssertEqual(try XCTUnwrap(clock.deadline)-clock.now, remainder, accuracy: 0.0001)
                } else { XCTAssertNil(clock.deadline) }
                store.setSuspended(true)
            }
        }
    }

    @MainActor func testBothModesKeepEnrolledProgressWhenReplayNewAndModePreviewsAreCanceled() throws {
        for request in [SkyEntryRequest.firstLight, .fullBoardLantern] {
            let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            XCTAssertTrue(store.beginEntry(request))
            store.setSuspended(false)
            XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)), snapshot: store.game,
                                                generation: store.constellationInputGeneration))
            presenter.finish()
            XCTAssertEqual(store.game.masteryProgress?.earned, [.cascade])
            XCTAssertNotNil(store.game.masteryEnrollment)
            XCTAssertTrue(store.isPaused)
            let retained = RetainedRound(store, defaults: defaults)
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            for action in [SkyFlowAction.replay, .another, .firstLight] {
                XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
                store.setSuspended(true)
                var id = try XCTUnwrap(flow.entryID)
                if action == .firstLight {
                    XCTAssertEqual(flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: id), .staged)
                    XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: id))
                    id = try XCTUnwrap(flow.entryID)
                    XCTAssertEqual(flow.entry, .fullBoardLantern)
                }
                clock.advance(100)
                XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: id), .continued)
                XCTAssertEqual(flow.screen, .playing)
                XCTAssertNil(flow.handoff)
                store.setSuspended(false)
                retained.assertUnchanged(store, defaults: defaults)
                XCTAssertEqual(store.game.masteryProgress?.earned, [.cascade])
                XCTAssertNil(clock.deadline)
            }
            store.setSuspended(true)
        }
    }

    @MainActor func testWonAndLostRoundCancellationReturnsToTheSameCommittedResult() throws {
        var lost = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(lost.enrollMastery(runID: UUID()))
        for _ in 0..<5 { _ = try XCTUnwrap(lost.letStarsFall()) }
        XCTAssertEqual(lost.outcome, .lost)
        for game in [try fullBoardWinner(), lost] {
            let defaults = defaults(), clock = ManualRainClock()
            try SkySaveArchive.save(game, to: defaults)
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
            store.setSuspended(false); store.setSuspended(true)
            let retained = RetainedRound(store, defaults: defaults)
            let result = try XCTUnwrap(SkyResultSnapshot(game: store.game))
            let optionalResult = SkyMasterySnapshot.current(game: store.game, bestRecords: store.mastery.records, context: .result)
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            for action in [SkyFlowAction.replay, .another] {
                XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
                clock.advance(100)
                XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .continued)
                XCTAssertEqual(flow.screen, .playing, "The view derives the won/full ceremony from this retained game")
                XCTAssertNil(flow.handoff)
                XCTAssertEqual(SkyResultSnapshot(game: store.game), result)
                XCTAssertEqual(SkyMasterySnapshot.current(game: store.game, bestRecords: store.mastery.records, context: .result), optionalResult)
                retained.assertUnchanged(store, defaults: defaults)
                XCTAssertNil(clock.deadline)
            }
        }
    }

    func testMapAndExplicitHomeKeepTheirSeparateReturnDestinations() throws {
        for arguments in [[], ["--starfalls-reset"]] {
            var flow = SkyFlowState(arguments: arguments)
            let origin = flow.screen
            XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
            XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
            let oldID = try XCTUnwrap(flow.entryID)
            XCTAssertEqual(flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: oldID), .staged)
            XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: oldID))
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
            XCTAssertEqual(flow.screen, .worldMap)
            XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), origin == .playing ? .continued : .home)
            XCTAssertEqual(flow.screen, origin)
            XCTAssertNil(flow.handoff)
        }
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.replay, hasSavedSky: true), .staged)
        let id = try XCTUnwrap(flow.entryID)
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(flow.screen, .welcome)
        XCTAssertNil(flow.entry); XCTAssertNil(flow.entryID); XCTAssertNil(flow.handoff)
        XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: id))
        XCTAssertEqual(flow.handle(.start, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .home)
        XCTAssertEqual(flow.screen, .welcome)
    }

    func testPracticeAndPreferencesPreserveTheRememberedRoundOrigin() {
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
        let entry = flow
        XCTAssertEqual(flow.handle(.modePractice, hasSavedSky: true, entryID: flow.entryID), .modePractice(.storyRoom))
        XCTAssertEqual(flow, entry)
        XCTAssertEqual(flow.handle(.preferences, hasSavedSky: true), .preferences)
        XCTAssertEqual(flow, entry)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .continued)
        XCTAssertEqual(flow.screen, .playing)
        XCTAssertNil(flow.handoff)
    }

    @MainActor func testRejectedBeginRollbackKeepsEntryCancelableWithoutDiscardingTheWinningReceipt() throws {
        let game = try fullBoardWinner(), defaults = defaults()
        try SkySaveArchive.save(game, to: defaults)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                   clock: ManualRainClock(), masteryWriter: { _, _ in throw InjectedFailure.write })
        let retained = RetainedRound(store, defaults: defaults)
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.replay, hasSavedSky: true), .staged)
        let entry = flow, id = try XCTUnwrap(flow.entryID)
        guard case .began(let request) = flow.handle(.begin, hasSavedSky: true, entryID: id) else {
            return XCTFail("Expected the valid staged request")
        }
        XCTAssertFalse(store.beginEntry(request))
        flow = entry // The production view rolls back Entry consumption after rejection.
        XCTAssertEqual(flow.entryID, id)
        XCTAssertNil(flow.handoff)
        XCTAssertTrue(store.masterySaveFailed)
        retained.assertUnchanged(store, defaults: defaults)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: id), .continued)
        XCTAssertEqual(flow.screen, .playing)
        retained.assertUnchanged(store, defaults: defaults)
    }
}
