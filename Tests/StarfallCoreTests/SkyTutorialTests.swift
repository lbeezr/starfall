import XCTest
@testable import StarfallCore

final class SkyTutorialTests: XCTestCase {
    func testEveryReferenceSequenceCommitsThroughProductionRules() throws {
        for chapter in SkyTutorial.allCases {
            var game = chapter.game(), run = SkyTutorialRun(chapter)
            XCTAssertFalse(chapter.actions.isEmpty, chapter.rawValue)
            for action in chapter.actions {
                let before = game
                switch action {
                case .pause, .resume: break
                default: XCTAssertNotNil(action.perform(in: &game), "\(chapter): \(action)")
                }
                run.observe(action, before: before, after: game)
                XCTAssertFalse(run.needsRetry, chapter.rawValue)
            }
            XCTAssertTrue(run.complete, chapter.rawValue)
            let expected: [SkyTutorial: (Int, Int, Int)] = [
                .match: (3,1,0), .grown: (3,1,0), .exchange: (0,9,0), .emptySpace: (0,3,0),
                .trace: (5,1,0), .diagonal: (5,20,0), .gap: (5,0,0), .branch: (5,4,0),
                .square: (4,2,0), .cross: (5,4,0), .opal: (3,1,0), .relay: (8,0,0),
                .trim: (10,7,0), .dropIn: (7,0,0), .bank: (9,9,0), .fork: (9,11,0),
                .doubleSetup: (13,11,0), .showers: (0,9,3), .storm: (19,13,10),
                .room: (3,8,1), .restoration: (20,11,9)
            ]
            let result = try XCTUnwrap(expected[chapter])
            XCTAssertEqual(game.score, result.0, chapter.rawValue)
            XCTAssertEqual(game.occupiedCount, result.1, chapter.rawValue)
            XCTAssertEqual(game.turns, result.2, chapter.rawValue)
            if chapter == .restoration { XCTAssertEqual(game.outcome, .won) }
            if chapter == .storm { XCTAssertEqual(chapter.game().incoming.count, 5) }
        }
    }

    func testWrongMethodCannotCompleteGestureLessonAndEquivalentTapsWork() {
        var game = SkyTutorial.trace.game(), run = SkyTutorialRun(.trace)
        let before = game; _ = game.clear(Cell(0,0))
        run.observe(.tap(Cell(0,0)), before: before, after: game)
        XCTAssertTrue(run.needsRetry); XCTAssertFalse(run.complete)
        game = SkyTutorial.match.game(); run = SkyTutorialRun(.match)
        let original = game; _ = game.clear(Cell(0,2))
        run.observe(.tap(Cell(0,2)), before: original, after: game)
        XCTAssertTrue(run.complete)
    }

    func testWorldProgressDistinguishesUnavailableLockedRestoredAndLegacyAccess() throws {
        var progress = WorldJourney()
        XCTAssertEqual(WorldLocation.allCases.count, 12)
        XCTAssertTrue(progress.canEnter(.firstLight)); XCTAssertFalse(progress.canEnter(.ribbonCrossing))
        for challenge in StarfallChallenge.allCases {
            var game = FallingSky(challenge: challenge)
            for _ in 0..<100 where !game.isOver {
                if let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
                else { _ = game.letStarsFall() }
            }
            XCTAssertEqual(game.outcome, .won)
            let location = try XCTUnwrap(WorldLocation(rawValue: challenge.rawValue))
            XCTAssertTrue(progress.canEnter(location))
            progress.record(game); progress.record(game)
            XCTAssertTrue(progress.completed.contains(location))
        }
        XCTAssertEqual(progress.completed.count, 5)
        XCTAssertFalse(progress.canEnter(.frostfruitOrchard))
        let legacy = WorldJourney(legacyAccess: true)
        XCTAssertTrue(legacy.canEnter(.silverPools)); XCTAssertTrue(legacy.completed.isEmpty)
        XCTAssertFalse(legacy.canEnter(.hollowCrown))
        XCTAssertEqual(try JSONDecoder().decode(WorldJourney.self, from: JSONEncoder().encode(progress)), progress)
    }
}
