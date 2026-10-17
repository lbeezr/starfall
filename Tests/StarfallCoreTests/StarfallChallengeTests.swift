import XCTest
@testable import StarfallCore

final class StarfallChallengeTests: XCTestCase {
    func testFirstLightCanBeCompletedAndLocksFurtherInput() throws {
        var game = FallingSky(challenge: .firstLight)
        XCTAssertEqual(game.challenge, .firstLight)
        XCTAssertEqual(game.score, 0); XCTAssertEqual(game.outcome, .playing)
        for _ in 0..<30 where !game.isOver {
            game.letStarsFall()
            while !game.isOver, let cell = game.legalGroups.first?.first { game.clear(cell) }
            XCTAssertTrue(game.isValidSave)
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertGreaterThanOrEqual(game.score, 18)
        let completed = game
        XCTAssertNil(game.letStarsFall()); XCTAssertNil(game.clear(Cell(0, 0)))
        XCTAssertEqual(game, completed)
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(restored, game); XCTAssertEqual(restored.outcome, .won)
    }

    func testChallengeHasFixedBalanceAndNoDarkStars() {
        var game = FallingSky(challenge: .firstLight)
        let original = game
        game.setBalance(.init(pace: .brisk, darkStars: .frequent))
        XCTAssertEqual(game, original)
        for _ in 0..<40 where !game.isOver {
            XCTAssertFalse(game.incoming.contains(where: \.isDark))
            game.letStarsFall()
        }
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertTrue(game.isValidSave)
    }

    func testGoalCompletionTakesPrecedenceOverOverflow() {
        XCTAssertEqual(StarfallChallenge.firstLight.outcome(score: 18, overflowed: true), .won)
        XCTAssertEqual(StarfallChallenge.firstLight.outcome(score: 17, overflowed: true), .lost)
        XCTAssertEqual(StarfallChallenge.firstLight.outcome(score: 17, overflowed: false), .playing)
    }

    func testRejectsChallengeSaveWithDifferentBalanceOrSeed() throws {
        let game = FallingSky(challenge: .firstLight)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        json["seed"] = 43
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(restored.isValidSave)
        json["seed"] = game.seed
        json["savedBalance"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(StarfallBalance()))
        let wrongBalance = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(wrongBalance.isValidSave)
    }
}
