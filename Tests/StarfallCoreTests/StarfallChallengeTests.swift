import XCTest
@testable import StarfallCore

final class StarfallChallengeTests: XCTestCase {
    func testEachChallengeCanBeCompletedRestoredAndReplayedWithItsOwnIdentity() throws {
        for challenge in StarfallChallenge.allCases {
            var game = FallingSky(challenge: challenge)
            let opening = game
            XCTAssertEqual(game.challenge, challenge)
            XCTAssertEqual(game.score, 0); XCTAssertEqual(game.outcome, .playing)
            for _ in 0..<30 where !game.isOver {
                game.letStarsFall()
                while !game.isOver, let cell = game.legalGroups.first?.first { game.clear(cell) }
                XCTAssertTrue(game.isValidSave)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertGreaterThanOrEqual(game.score, 18)
            XCTAssertEqual(game.restoration?.milestone, .complete)
            let completed = game
            XCTAssertNil(game.letStarsFall()); XCTAssertNil(game.clear(Cell(0, 0)))
            XCTAssertEqual(game, completed)
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(restored, game); XCTAssertEqual(restored.outcome, .won)
            XCTAssertEqual(restored.replay(), opening)
            XCTAssertEqual(restored.replay().challenge, challenge)
        }
    }

    func testChallengesShareFixedRulesButKeepDistinctEncodedIdentity() throws {
        let lantern = FallingSky(challenge: .firstLight)
        XCTAssertEqual(StarfallChallenge.firstLight.rawValue, "firstLight")
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.firstLight), Data(#""firstLight""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.ribbonCrossing), Data(#""ribbonCrossing""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.kiteHarbor), Data(#""kiteHarbor""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.seedMoon), Data(#""seedMoon""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.silverPools), Data(#""silverPools""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.frostfruitOrchard), Data(#""frostfruitOrchard""#.utf8))
        XCTAssertEqual(try JSONEncoder().encode(StarfallChallenge.sunwheelMill), Data(#""sunwheelMill""#.utf8))
        XCTAssertEqual(StarfallChallenge.allCases.count, 7)
        for challenge in StarfallChallenge.allCases {
            let game = FallingSky(challenge: challenge)
            XCTAssertEqual(game.board, lantern.board)
            XCTAssertEqual(game.incoming, lantern.incoming)
            if challenge != .firstLight { XCTAssertNotEqual(game, lantern) }
            XCTAssertEqual(challenge.target, 18)
            XCTAssertEqual(game.seed, 42)
            XCTAssertEqual(game.generation, .legacy)
            XCTAssertEqual(game.cadenceID, .originalV1)
            XCTAssertFalse(game.hasOpeningCascade)
            XCTAssertFalse(game.hasCriticalMass)
            XCTAssertFalse(game.hasPocketedDusk)
            XCTAssertEqual(game.duskRule, .legacy)
            XCTAssertTrue(game.isValidSave)
        }
    }

    func testEachChallengeHasFixedBalanceNoDarkStarsAndOverflowFailure() {
        for challenge in StarfallChallenge.allCases {
            var game = FallingSky(challenge: challenge)
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
    }

    func testGoalCompletionTakesPrecedenceOverOverflowForEveryChallenge() {
        for challenge in StarfallChallenge.allCases {
            XCTAssertEqual(challenge.outcome(score: 18, overflowed: true), .won)
            XCTAssertEqual(challenge.outcome(score: 22, overflowed: false), .won)
            XCTAssertEqual(challenge.outcome(score: 17, overflowed: true), .lost)
            XCTAssertEqual(challenge.outcome(score: 17, overflowed: false), .playing)
        }
    }

    func testRejectsChallengeSaveWithDifferentBalanceOrSeedOrUnknownIdentity() throws {
        for challenge in StarfallChallenge.allCases {
            let game = FallingSky(challenge: challenge)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
            json["seed"] = 43
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertFalse(restored.isValidSave)
            json["seed"] = game.seed
            json["savedBalance"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(StarfallBalance()))
            let wrongBalance = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertFalse(wrongBalance.isValidSave)
            json["savedBalance"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(challenge.balance))
            json["challenge"] = "futureCrossing"
            XCTAssertThrowsError(try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json)))
        }
    }
    func testEveryChallengeAdoptsActionsWithoutChangingHistoryOrContinuation() throws {
        for challenge in StarfallChallenge.allCases {
            var fresh = FallingSky(challenge: challenge)
            XCTAssertTrue(fresh.supportsArrangingStars)
            for _ in 0..<4 { fresh.letStarsFall() }
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(fresh)) as? [String: Any])
            fields.removeValue(forKey: "savedChallengeActions")
            let oldBytes = try JSONSerialization.data(withJSONObject: fields)
            let old = try JSONDecoder().decode(FallingSky.self, from: oldBytes)
            XCTAssertFalse(old.canArrangeStars)
            XCTAssertTrue(old.isValidSave)
            let migrated = old.adoptingCurrentChallengeActions()
            XCTAssertEqual(migrated, fresh)
            XCTAssertEqual(migrated.adoptingCurrentChallengeActions(), migrated)
            XCTAssertEqual(old.replay().challengeActionVersion, 0)
            XCTAssertEqual(migrated.replay(), FallingSky(challenge: challenge))
            var reference = old, updated = migrated
            reference.letStarsFall(); updated.letStarsFall()
            XCTAssertEqual(updated, reference.adoptingCurrentChallengeActions())
            let cell = try XCTUnwrap(migrated.board.enumerated().first { $0.element != nil }.map { Cell($0.offset / 7, $0.offset % 7) })
            var arranged = migrated
            let target = Cell(cell.row, cell.column == 6 ? 5 : cell.column + 1)
            XCTAssertEqual(arranged.nudge(from: cell, to: target)?.collected, 0)
            XCTAssertEqual(arranged.incoming, migrated.incoming)
            XCTAssertEqual(arranged.turns, migrated.turns)
            XCTAssertTrue(arranged.isValidSave)
            XCTAssertEqual(try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(arranged)), arranged)
        }
    }

    func testEveryChallengeUsesExactSquareAndCrossSelections() throws {
        for challenge in StarfallChallenge.allCases {
            for lesson in [SkyLesson.square, .cross] {
                var example = lesson.game()
                if lesson == .square { lesson.moves[0].perform(in: &example) }
                var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(example)) as? [String: Any])
                fields["challenge"] = challenge.rawValue
                fields["savedChallengeActions"] = 1
                var game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
                let before = game
                let turn = try XCTUnwrap(lesson.moves.last?.perform(in: &game))
                XCTAssertEqual(turn.collected, lesson == .square ? 4 : 5)
                XCTAssertEqual(game.incoming, before.incoming)
                XCTAssertEqual(game.occupiedCount, before.occupiedCount - turn.cleared.count)
            }
        }
    }

    func testUnknownOrMisplacedActionVersionRejectsSave() throws {
        for base in [FallingSky(challenge: .firstLight), FallingSky.freshSurvival(seed: 42)] {
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as? [String: Any])
            fields["savedChallengeActions"] = base.challenge == nil ? 1 : 99
            let game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(game.isValidSave)
        }
    }

}
