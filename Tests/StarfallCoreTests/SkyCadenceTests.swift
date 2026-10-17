import XCTest
@testable import StarfallCore

final class SkyCadenceTests: XCTestCase {
    func testExactOpeningAndTwoCompleteCycleBoundaries() {
        for count in 0..<4 {
            let expected = SkyCadenceStep(delay: count == 0 ? 0.25 : 1.8, phase: .opening)
            XCTAssertEqual(SkyCadenceID.openingV1.step(committedShowers: count, pace: .brisk), expected)
            XCTAssertEqual(TimingCycleFixture.step(committedShowers: count), expected)
        }
        let delays: [Double] = [3, 3, 3, 3, 3, 3, 2.5, 2.5, 2.5, 3.5, 3.5, 3.5]
        let phases: [SkyCadenceStep.Phase] = [.steady, .steady, .steady, .steady, .steady, .steady,
                                              .faster, .faster, .faster, .breathing, .breathing, .breathing]
        for cycle in 0..<2 {
            var total = 0.0
            for slot in 0..<12 {
                let count = 4 + cycle * 12 + slot
                let step = TimingCycleFixture.step(committedShowers: count)
                XCTAssertEqual(step, .init(delay: delays[slot], phase: phases[slot], warnsFasterNext: slot == 5))
                XCTAssertEqual(SkyCadenceID.openingV1.step(committedShowers: count, pace: .brisk),
                               .init(delay: 3, phase: .steady))
                total += step.delay
            }
            XCTAssertEqual(total, 36)
        }
        XCTAssertEqual(TimingCycleFixture.step(committedShowers: 28), .init(delay: 3, phase: .steady))
    }

    func testBalanceAlwaysWinsOutsideOpening() {
        for pace in StarfallBalance.Pace.allCases {
            for count in 0...30 {
                XCTAssertEqual(SkyCadenceID.originalV1.step(committedShowers: count, pace: pace).delay, Double(pace.rawValue))
                if pace != .brisk, count >= 4 {
                    XCTAssertEqual(TimingCycleFixture.step(committedShowers: count, pace: pace),
                                   .init(delay: Double(pace.rawValue), phase: .steady))
                }
            }
        }
    }

    func testRoundTripReplayAndMatchedActionsLeaveGenerationUnchanged() throws {
        for seed in UInt64(0)..<50 {
            var game = FallingSky(seed: seed)
            var comparison = game
            for _ in 0..<30 where !game.isOver {
                let before = game.cadenceStep
                XCTAssertEqual(game.cadenceID, .openingV1)
                _ = TimingCycleFixture.step(committedShowers: comparison.turns, pace: comparison.balance.pace)
                if let cell = game.legalGroups.first?.first {
                    game.clear(cell); comparison.clear(cell)
                    XCTAssertEqual(game.cadenceStep, before)
                }
                game.letStarsFall(); comparison.letStarsFall()
                game = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                XCTAssertTrue(game.isValidSave)
                XCTAssertEqual(game, comparison)
            }
            XCTAssertEqual(game.replay(), FallingSky(seed: seed))
            let balance = StarfallBalance(pace: .gentle, darkStars: .none)
            game.setBalance(balance)
            let replay = game.replay()
            XCTAssertEqual(replay.balance, balance)
            XCTAssertEqual(replay.cadenceID, game.cadenceID)
            XCTAssertEqual(replay, FallingSky(seed: seed, balance: balance))
        }
    }

    func testMissingMarkerKeepsBothHistoricalTimingContracts() throws {
        for opening in [false, true] {
            let original = FallingSky(seed: 5, balance: .init(pace: .steady), openingCascade: opening)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
            json.removeValue(forKey: "savedCadence")
            for missingBalance in [false, true] {
                if missingBalance { json.removeValue(forKey: "savedBalance") }
                var restored = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
                XCTAssertTrue(restored.isValidSave)
                XCTAssertEqual(restored.cadenceID, opening ? .openingV1 : .originalV1)
                XCTAssertEqual(restored.automaticShowerDelay, opening ? 0.25 : 4)
                for _ in 0..<4 { restored.letStarsFall() }
                XCTAssertEqual(restored.automaticShowerDelay, 4)
                XCTAssertEqual(restored.replay().automaticShowerDelay, opening ? 0.25 : 4)
            }
        }
    }

    func testFirstLightRoundTripReplayAndBalanceRemainFixed() throws {
        var challenge = FallingSky(challenge: .firstLight)
        let fresh = challenge
        challenge.setBalance(.init(pace: .gentle, darkStars: .none))
        XCTAssertEqual(challenge, fresh)
        for _ in 0..<6 {
            XCTAssertEqual(challenge.cadenceStep, .init(delay: 4, phase: .steady))
            challenge.letStarsFall()
            challenge = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(challenge))
            XCTAssertTrue(challenge.isValidSave)
        }
        XCTAssertEqual(challenge.replay(), fresh)
    }

    func testHistoricalGenerationReplayAndTerminalCadenceFreeze() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky(seed: 5))) as? [String: Any])
        for key in ["savedCadence", "openingCascade", "cohesiveShowers", "savedBalance"] {
            json.removeValue(forKey: key)
        }
        // Seed-5 original independent-color initial forecast and RNG state.
        json["incoming"] = [["id": 0, "kind": 4, "column": 2], ["id": 1, "kind": 4, "column": 1], ["id": 2, "kind": 1, "column": 6]]
        json["random"] = ["state": UInt64(6018027440424182936)]
        json["remainingColumns"] = [0, 3, 4, 5]
        let fresh = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
        var historical = fresh
        for _ in 0..<100 where !historical.isOver { historical.letStarsFall() }
        XCTAssertTrue(historical.isOver)
        XCTAssertTrue(historical.isValidSave)
        XCTAssertEqual(historical.replay(), fresh)
        let terminal = historical
        XCTAssertNil(historical.letStarsFall())
        XCTAssertNil(historical.clear(Cell(0, 0)))
        XCTAssertEqual(historical, terminal)
        XCTAssertEqual(historical.cadenceStep, terminal.cadenceStep)
    }

    func testConflictingOrUnknownVersionCannotRestore() throws {
        let game = FallingSky(seed: 5)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        json["savedCadence"] = "originalV1"
        let conflicting = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(conflicting.isValidSave)
        json["savedCadence"] = "futureV99"
        XCTAssertThrowsError(try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json)))
    }
}
