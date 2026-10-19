import XCTest
@testable import StarfallCore

final class StarlightRestorationTests: XCTestCase {
    func testFirstLightMilestonesRequireTheirCommittedThreshold() {
        let samples: [(Int, StarlightRestoration.Milestone)] = [
            (0, .unrestored), (4, .unrestored), (5, .quarter), (8, .quarter),
            (9, .half), (13, .half), (14, .threeQuarters), (17, .threeQuarters),
            (18, .complete), (23, .complete)
        ]
        for (score, milestone) in samples {
            let progress = StarlightRestoration(score: score, target: StarfallChallenge.firstLight.target)
            XCTAssertEqual(progress.milestone, milestone, "Score \(score)")
            XCTAssertEqual(progress.fraction, Double(min(score, 18)) / 18, accuracy: 0.000001)
            XCTAssertEqual(progress.score, score)
            XCTAssertEqual(progress.target, 18)
        }
        XCTAssertEqual(StarlightRestoration.Milestone.allCases.map(\.rawValue), [0, 25, 50, 75, 100])
    }

    func testFractionClampsWithoutChangingTheReportedScore() {
        let below = StarlightRestoration(score: -1, target: 18)
        XCTAssertEqual(below.score, -1)
        XCTAssertEqual(below.fraction, 0)
        XCTAssertEqual(below.milestone, .unrestored)
        let above = StarlightRestoration(score: Int.max, target: 18)
        XCTAssertEqual(above.score, Int.max)
        XCTAssertEqual(above.fraction, 1)
        XCTAssertEqual(above.milestone, .complete)
        XCTAssertEqual(StarlightRestoration(score: Int.max - 1, target: Int.max).milestone, .threeQuarters)
    }

    func testMilestonesUseTheProvidedTarget() {
        let expected: [StarlightRestoration.Milestone] = [.unrestored, .unrestored, .quarter, .half, .threeQuarters, .complete]
        for score in expected.indices {
            XCTAssertEqual(StarlightRestoration(score: score, target: 5).milestone, expected[score])
        }
    }

    func testOnlyChallengesHaveRestorationAndReplayStartsUnrestored() throws {
        XCTAssertNil(FallingSky(seed: 42).restoration)
        XCTAssertNil(FallingSky.freshSurvival(seed: 42).restoration)
        var game = FallingSky(challenge: .firstLight)
        XCTAssertEqual(game.restoration?.milestone, .unrestored)
        advance(&game, untilScore: StarfallChallenge.firstLight.target)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.restoration?.milestone, .complete)
        let progress = try XCTUnwrap(game.restoration)
        XCTAssertEqual(progress.score, game.score)
        XCTAssertEqual(progress.fraction, 1)
        let replay = game.replay()
        XCTAssertEqual(replay, FallingSky(challenge: .firstLight))
        XCTAssertEqual(replay.restoration, StarlightRestoration(score: 0, target: 18))
    }

    func testReadingAndRestoringProgressDoesNotAlterCommittedSave() throws {
        var game = FallingSky(challenge: .firstLight)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        for goal in [9, StarfallChallenge.firstLight.target] {
            advance(&game, untilScore: goal)
            XCTAssertTrue(game.isValidSave)
            let before = try encoder.encode(game)
            let progress = try XCTUnwrap(game.restoration)
            _ = progress.milestone
            _ = progress.fraction
            XCTAssertEqual(try encoder.encode(game), before)
            let restored = try JSONDecoder().decode(FallingSky.self, from: before)
            XCTAssertTrue(restored.isValidSave)
            XCTAssertEqual(restored.restoration, progress)
            XCTAssertEqual(try encoder.encode(restored), before)
            XCTAssertEqual(restored, game)
        }
    }

    private func advance(_ game: inout FallingSky, untilScore goal: Int) {
        for _ in 0..<100 where game.score < goal && !game.isOver {
            if let cell = game.legalGroups.first?.first { game.clear(cell) }
            else { game.letStarsFall() }
        }
        XCTAssertGreaterThanOrEqual(game.score, goal)
    }
}
