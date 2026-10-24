import XCTest
import StarfallCore
@testable import Starfall

final class SavedRoundModeTests: XCTestCase {
    private func sky() throws -> FallingSky {
        var game = FallingSky.freshChallenge(.firstLight)
        _ = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        return game
    }

    private func fullBoard(revision: Int) throws -> FallingSky {
        var game = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision)))
        if revision == 5 {
            _ = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        } else {
            _ = try XCTUnwrap(game.nudge(from: Cell(3, 6), to: Cell(4, 6)))
        }
        return game
    }

    @MainActor private func snapshot(_ game: FallingSky?) throws -> WorldMapGoalSnapshot {
        try XCTUnwrap(WorldMapGoalSnapshot(journey: WorldJourney(), retainedRound: game))
    }

    @MainActor func testCurrentFallingSkyProgressNamesItsSavedMode() throws {
        let game = try sky(), goal = try snapshot(game)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.challengeRevision, 4)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertEqual(goal.retainedProgress, StarlightRestoration(score: 15_000, target: 150_000))
        XCTAssertEqual(goal.retainedLabel, "Saved Falling Sky progress: 15,000 of 150,000 starlight.")
        XCTAssertEqual(goal.newVisitLabel, "New visit objective: 150,000 starlight.")
    }

    @MainActor func testCurrentFullBoardProgressNamesItsSavedModeWithTheSameTarget() throws {
        let game = try fullBoard(revision: 6), goal = try snapshot(game)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.challengeRevision, 6)
        XCTAssertTrue(game.usesFullBoardRefill)
        XCTAssertEqual(goal.retainedProgress, StarlightRestoration(score: 42_000, target: 150_000))
        XCTAssertEqual(goal.retainedLabel, "Saved Full Board progress: 42,000 of 150,000 starlight.")
        XCTAssertEqual(goal.newVisitLabel, try snapshot(sky()).newVisitLabel)
    }

    @MainActor func testHistoricalFullBoardFiveKeepsItsModeAndExactProgress() throws {
        let game = try fullBoard(revision: 5), goal = try snapshot(game)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.challengeRevision, 5)
        XCTAssertTrue(game.usesFullBoardRefill)
        XCTAssertEqual(goal.retainedProgress, StarlightRestoration(score: 66_000, target: 150_000))
        XCTAssertEqual(goal.retainedLabel, "Saved Full Board progress: 66,000 of 150,000 starlight.")
        XCTAssertNil(game.masteryEnrollment)
    }

    @MainActor func testHistoricalManualRoundKeepsItsEighteenLightScale() throws {
        let game = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .firstLight)
        let goal = try snapshot(game)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertTrue(game.supportsManualClears)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertEqual(goal.retainedProgress, StarlightRestoration(score: 9, target: 18))
        XCTAssertEqual(goal.retainedLabel, "Saved Falling Sky progress: 9 of 18 starlight.")
        XCTAssertEqual(goal.newVisitTarget, 150_000)
    }

    @MainActor func testForeignAbsentAndSurvivalRoundsDoNotAdvertiseSavedModeProgress() throws {
        var journey = WorldJourney(legacyAccess: true)
        journey.select(.ribbonCrossing)
        let foreign = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: fullBoard(revision: 6)))
        XCTAssertEqual(foreign.newVisitTarget, 220_000)
        XCTAssertNil(foreign.retainedProgress)
        XCTAssertNil(foreign.retainedLabel)
        for game in [nil, FallingSky.freshSurvival(seed: 42)] {
            let goal = try snapshot(game)
            XCTAssertNil(goal.retainedProgress)
            XCTAssertNil(goal.retainedLabel)
        }
    }

    @MainActor func testWonAndLostRoundsDoNotAdvertiseContinueProgress() throws {
        var won = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        _ = try XCTUnwrap(won.clear(Cell(0, 0)))
        XCTAssertEqual(won.outcome, .won)
        var lost = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<40 where !lost.isOver { _ = lost.letStarsFall() }
        XCTAssertEqual(lost.outcome, .lost)
        for game in [won, lost] {
            XCTAssertTrue(game.isValidSave)
            let goal = try snapshot(game)
            XCTAssertNil(goal.retainedProgress)
            XCTAssertNil(goal.retainedLabel)
            XCTAssertEqual(goal.newVisitTarget, 150_000)
        }
    }

    @MainActor func testReadingRestoredLabelsPreservesCurrentAndHistoricalArchiveBytes() throws {
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .firstLight)
        for game in [try sky(), try fullBoard(revision: 6), try fullBoard(revision: 5), historical] {
            let suite = "Starfall.SavedRoundMode.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let key: String
            let archive: Data
            if game.challengeRevision == 5 {
                key = SkySaveArchive.fullBoardKey
                let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
                archive = try JSONSerialization.data(withJSONObject: ["schemaVersion": 14, "game": fields], options: .sortedKeys)
                defaults.set(archive, forKey: key)
            } else {
                key = SkySaveArchive.key
                try SkySaveArchive.save(game, to: defaults)
                archive = try XCTUnwrap(defaults.data(forKey: key))
            }
            let world = WorldJourneyStore(defaults: defaults)
            try world.select(.firstLight)
            let worldBytes = defaults.data(forKey: WorldJourneyStore.key)
            let restored = try XCTUnwrap(SkySaveArchive.load(from: defaults))
            let original = try XCTUnwrap(WorldMapGoalSnapshot(journey: world.journey, retainedRound: game))
            for _ in 0..<3 {
                let read = try XCTUnwrap(WorldMapGoalSnapshot(journey: world.journey, retainedRound: restored))
                XCTAssertEqual(read, original)
                XCTAssertNotNil(read.retainedLabel)
                XCTAssertEqual(defaults.data(forKey: key), archive)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
                XCTAssertEqual(restored.challengeRevision, game.challengeRevision)
                XCTAssertEqual(restored.replay(), game.replay())
            }
            if game.challengeRevision == 5 { XCTAssertNil(defaults.object(forKey: SkySaveArchive.key)) }
        }
    }
}
