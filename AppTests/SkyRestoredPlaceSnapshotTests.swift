import XCTest
import StarfallCore
@testable import Starfall

final class SkyRestoredPlaceSnapshotTests: XCTestCase {
    private func currentWinner() throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        // Existing HIGH10 production route, not a new search or injected score.
        for (from, to) in [(27,34), (1,2), (31,32), (12,13), (16,17),
                           (8,9), (11,12), (29,30), (29,36), (9,16)] {
            _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, 156_000)
        return game
    }

    @MainActor private func historicalWinner(_ challenge: StarfallChallenge = .firstLight) throws -> FallingSky {
        var game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: challenge)
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertEqual(game.outcome, .playing)
        _ = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        return game
    }

    @MainActor func testGenuineCurrentAndHistoricalRepairsSelectTheSameCompletePaintingWithoutAnEarnedScore() throws {
        var admitted: [SkyRestoredPlaceSnapshot] = []
        for winner in [try currentWinner(), try historicalWinner()] {
            var journey = WorldJourney()
            journey.record(winner)
            XCTAssertEqual(journey.completed, [.firstLight])
            journey.select(.firstLight)
            let snapshot = try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
            XCTAssertEqual(snapshot.id, .firstLight)
            XCTAssertEqual(snapshot.location, .firstLight)
            XCTAssertEqual(snapshot.challenge, .firstLight)
            XCTAssertEqual(snapshot.presentation.challenge, .firstLight)
            XCTAssertEqual(snapshot.presentation.progress, StarlightRestoration(score: 1, target: 1))
            XCTAssertEqual(snapshot.presentation.progress.fraction, 1)
            XCTAssertEqual(snapshot.presentation.progress.milestone, .complete)
            XCTAssertTrue(snapshot.matches(journey))
            admitted.append(snapshot)
        }
        XCTAssertEqual(admitted[0], admitted[1], "The place identity does not retain a round's mode or awarded score")
        XCTAssertEqual(Set(admitted).count, 1)
    }

    func testReadyAndLegacyAccessWithoutAGenuineRepairCannotAdmitRestoredViewing() {
        for journey in [WorldJourney(), WorldJourney(legacyAccess: true)] {
            XCTAssertTrue(journey.canEnter(.firstLight))
            XCTAssertTrue(journey.completed.isEmpty)
            XCTAssertNil(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
        }
        let legacy = WorldJourney(legacyAccess: true)
        XCTAssertTrue(legacy.canEnter(.silverPools), "Access migration is deliberately weaker than completion")
    }

    @MainActor func testOtherCompletedPlacesAndAMismatchedSelectionDoNotExpandTheLanternSlice() throws {
        var journey = WorldJourney()
        journey.record(try historicalWinner())
        journey.record(try historicalWinner(.ribbonCrossing))
        XCTAssertTrue(journey.completed.contains(.ribbonCrossing))
        for location in WorldLocation.allCases where location != .firstLight {
            journey.select(location)
            XCTAssertNil(SkyRestoredPlaceSnapshot(location: location, journey: journey), location.rawValue)
            XCTAssertNil(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey), location.rawValue)
        }
        journey.select(.firstLight)
        XCTAssertNotNil(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
    }

    @MainActor func testMatchesRevalidatesSelectionAndCompletionWithoutConsumingThePlace() throws {
        var journey = WorldJourney()
        journey.record(try historicalWinner())
        journey.select(.firstLight)
        let snapshot = try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
        let admitted = journey
        journey.select(.ribbonCrossing)
        XCTAssertFalse(snapshot.matches(journey))
        XCTAssertFalse(snapshot.matches(WorldJourney()))
        XCTAssertFalse(snapshot.matches(WorldJourney(legacyAccess: true)))
        journey.select(.firstLight)
        XCTAssertTrue(snapshot.matches(journey))
        XCTAssertEqual(journey, admitted, "Reading and matching do not mutate the durable journey")
    }
}
