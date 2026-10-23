import XCTest
import StarfallCore
@testable import Starfall

final class SkyMasteryPresentationTests: XCTestCase {
    @MainActor func testBothFreshEntryPreviewsDiscloseTheirGoalsWithoutReplacingTheSavedRound() throws {
        let suite = "Starfall.MasteryPresentation.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let retained = FallingSky.freshChallenge(.sunwheelMill)
        try SkySaveArchive.save(retained, to: defaults)
        try WorldJourneyStore(defaults: defaults).select(.firstLight)
        let round = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        let world = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)

        for (action, request, goals) in [
            (SkyFlowAction.firstLight, SkyEntryRequest.firstLight, [StoryMasteryGoal.grownCollection, .cascade]),
            (.fullBoardLantern, .fullBoardLantern, [.cascade, .largeClear])
        ] {
            XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
            let snapshot = try XCTUnwrap(SkyMasterySnapshot.entry(request: request, retainedRound: retained))
            XCTAssertEqual(snapshot.identity.goals, goals)
            XCTAssertTrue(snapshot.earned.isEmpty)
            XCTAssertNil(snapshot.rank)
            XCTAssertNil(snapshot.completedRecord)
            XCTAssertEqual(snapshot.identifier, "sky.mastery.entry")
            XCTAssertTrue(snapshot.explanation.contains("Complete this repair for 1 star"))
            XCTAssertTrue(snapshot.explanation.contains("Stars never gate the next place"))
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), retained)
            XCTAssertNil(retained.masteryEnrollment)
        }
    }

    func testUnenrolledReplayAndOtherLocationsRemainCompletionOnly() throws {
        let historical = FallingSky(challenge: .firstLight)
        let retained = try [3, 4, 5, 6].map {
            FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: $0)))
        }
        for game in [historical] + retained {
            XCTAssertNil(SkyMasterySnapshot.entry(request: .replay, retainedRound: game))
            XCTAssertNil(SkyMasterySnapshot.current(game: game, context: .progress))
            XCTAssertNil(SkyMasterySnapshot.current(game: game, context: .result))
            XCTAssertNil(game.replay().masteryEnrollment)
        }
        let current = FallingSky.freshChallenge(.firstLight)
        for request in [SkyEntryRequest.initial, .fresh, .ribbonCrossing, .fullBoardRibbon,
                        .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard, .sunwheelMill] {
            XCTAssertNil(SkyMasterySnapshot.entry(request: request, retainedRound: current))
        }
    }

    func testPauseProgressUsesCommittedGoalsAndDoesNotAwardCompletedStars() throws {
        var sky = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(sky.enrollMastery(runID: UUID()))
        _ = try XCTUnwrap(sky.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        let skyProgress = try XCTUnwrap(SkyMasterySnapshot.current(game: sky, context: .progress))
        XCTAssertEqual(skyProgress.earned, [.cascade])
        XCTAssertEqual(skyProgress.goalState(.cascade), "Earned this run")
        XCTAssertEqual(skyProgress.goalState(.grownCollection), "Not yet this run")
        XCTAssertTrue(skyProgress.goalDetail(.cascade).contains("move or shower"))
        XCTAssertNil(skyProgress.ratingLabel)
        XCTAssertNil(SkyMasterySnapshot.current(game: sky, context: .result))

        var fullBoard = FallingSky.fullBoardLantern()
        XCTAssertTrue(fullBoard.enrollMastery(runID: UUID()))
        let turn = try XCTUnwrap(fullBoard.nudge(from: Cell(3, 6), to: Cell(4, 6)))
        XCTAssertEqual(turn.resolutionPhases.map { $0.cleared.count }, [6, 6, 4])
        let fullProgress = try XCTUnwrap(SkyMasterySnapshot.current(game: fullBoard, context: .progress))
        XCTAssertEqual(fullProgress.earned, [.cascade])
        XCTAssertEqual(fullProgress.goalState(.largeClear), "Not yet this run")
        XCTAssertTrue(fullProgress.goalDetail(.cascade).contains("gaps refill"))
        XCTAssertFalse(fullProgress.goalDetail(.cascade).contains("shower"))
        XCTAssertNil(fullProgress.rank)
        let replay = try XCTUnwrap(SkyMasterySnapshot.entry(request: .replay, retainedRound: fullBoard))
        XCTAssertEqual(replay.identity, fullProgress.identity)
        XCTAssertTrue(replay.earned.isEmpty, "Replay describes a fresh attempt under the retained contract")
    }

    func testWeakerCompletedRunShowsItsOwnStarsAndTheStrongerWholeSavedBest() throws {
        let stronger = try fullBoardWin(largeClear: true)
        let weaker = try fullBoardWin(largeClear: false)
        let best = try XCTUnwrap(stronger.completedMasteryRun)
        let current = try XCTUnwrap(weaker.completedMasteryRun)
        XCTAssertEqual(best.rank, 3)
        XCTAssertEqual(current.rank, 2)
        XCTAssertNotEqual(best.runID, current.runID)
        let snapshot = try XCTUnwrap(SkyMasterySnapshot.current(game: weaker, bestRecords: [best], context: .result))
        XCTAssertEqual(snapshot.completedRecord, current)
        XCTAssertEqual(snapshot.earned, [.cascade])
        XCTAssertEqual(snapshot.rank, 2)
        XCTAssertEqual(snapshot.ratingLabel, "2 of 3 stars earned")
        XCTAssertEqual(snapshot.bestRecord, best)
        XCTAssertTrue(try XCTUnwrap(snapshot.bestLabel).contains("3 of 3 stars from one completed run"))
        XCTAssertEqual(snapshot.goalState(.largeClear), "Not earned this run")
        XCTAssertTrue(snapshot.explanation.contains("Your repair is complete"))
        XCTAssertTrue(snapshot.explanation.contains("never block the next place"))
        XCTAssertEqual(SkyMasterySnapshot.best(in: [current, best], for: best.identity), best)
        XCTAssertEqual(SkyMasterySnapshot.best(in: [best, current], for: best.identity), best)
    }

    func testMapBestRowsKeepTheTwoModeContractsSeparateAndDoNotInventHistoricalStars() throws {
        let record = try XCTUnwrap(fullBoardWin(largeClear: true).completedMasteryRun)
        let rows = SkyMasteryBestSnapshot.lantern(records: [record])
        XCTAssertEqual(rows.map(\.id), ["fallingSky", "fullBoard"])
        XCTAssertEqual(rows.map { $0.identity.contentRevision }, [4, 6])
        XCTAssertNil(rows[0].record)
        XCTAssertEqual(rows[0].label, "Falling Sky: no result for these optional goals yet")
        XCTAssertEqual(rows[1].record, record)
        XCTAssertEqual(rows[1].label, "Full Board best: 3 of 3 stars")
        let sky = try XCTUnwrap(SkyMasterySnapshot.entry(request: .firstLight,
            retainedRound: .fullBoardLantern(), bestRecords: [record]))
        XCTAssertNil(sky.bestRecord)
        XCTAssertNil(sky.bestLabel)
        let mismatched = SkyMasterySnapshot(identity: sky.identity, completedRecord: record,
                                            bestRecord: record, context: .result)
        XCTAssertNil(mismatched.completedRecord)
        XCTAssertNil(mismatched.rank)
        XCTAssertNil(mismatched.bestRecord)
    }

    func testGoalCopyDistinguishesActualPhaseCountAndSavedRepairFailure() throws {
        let snapshot = try XCTUnwrap(SkyMasterySnapshot.entry(request: .fullBoardLantern,
                                                              retainedRound: .fullBoardLantern()))
        XCTAssertEqual(snapshot.goalLabel(.largeClear), "Clear 8 stars at once")
        XCTAssertTrue(snapshot.goalDetail(.largeClear).contains("at least 8 actual stars in one phase"))
        XCTAssertTrue(snapshot.goalDetail(.largeClear).contains("Simultaneous patterns count together"))
        XCTAssertFalse(snapshot.goalDetail(.largeClear).contains("6"))
        XCTAssertTrue(SkyCopy.text(.masterySaveFailedMessage).contains("Your repair is saved"))
        XCTAssertTrue(SkyCopy.text(.masterySaveFailedMessage).contains("before starting another round"))
        XCTAssertFalse(SkyCopy.text(.masterySaveFailedTitle).isEmpty)
        XCTAssertEqual(snapshot.identifier, "sky.mastery.entry")
    }

    private func fullBoardWin(largeClear: Bool) throws -> FallingSky {
        let actions: [(Int, Int)] = largeClear
            ? [(27, 34), (1, 2), (31, 32), (12, 13), (16, 17), (8, 9), (11, 12), (29, 30), (29, 36), (9, 16)]
            : [(1, 2), (27, 34), (5, 12), (0, 1), (16, 17), (24, 31), (25, 32),
               (1, 2), (1, 8), (7, 14), (37, 44), (2, 3), (2, 9), (33, 34),
               (18, 19), (16, 17), (18, 25), (18, 19), (1, 2), (4, 11), (32, 33)]
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        for (from, to) in actions {
            _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertTrue(game.isValidSave)
        return game
    }
}
