import XCTest
@testable import StarfallCore

final class FallingSkyPacingTests: XCTestCase {
    func testOpeningSchedulePreservesSeededWavesAndRoundTrips() throws {
        for seed in UInt64(0)..<200 {
            var game = FallingSky(seed: seed)
            var legacy = FallingSky(seed: seed, openingCascade: false)
            XCTAssertEqual(game.occupiedCount, 0)
            XCTAssertEqual(game.automaticShowerDelay, 0.25)
            for turn in 1...8 {
                XCTAssertEqual(game.incoming, legacy.incoming)
                game.letStarsFall(); legacy.letStarsFall()
                XCTAssertEqual(game.board, legacy.board)
                XCTAssertEqual(game.automaticShowerDelay, turn < 4 ? 1.8 : 3)
                XCTAssertEqual(game.isOpeningCascade, turn < 4)
                game = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                XCTAssertTrue(game.isValidSave)
                if turn == 1 {
                    let cell = try XCTUnwrap(game.legalGroups.first?.first)
                    game.clear(cell); legacy.clear(cell)
                }
            }
        }
    }

    func testHistoricalEmptySkyAndFirstLightKeepOriginalCadence() throws {
        let fresh = FallingSky(seed: 5, balance: .init(pace: .steady), openingCascade: false)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(fresh)) as? [String: Any])
        XCTAssertNil(json["openingCascade"])
        for removeBalance in [false, true] {
            if removeBalance { json.removeValue(forKey: "savedBalance") }
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: json))
            XCTAssertFalse(restored.isOpeningCascade)
            XCTAssertEqual(restored.automaticShowerDelay, 4)
            XCTAssertEqual(restored.incoming, fresh.incoming)
        }
        var challenge = FallingSky(challenge: .firstLight)
        for _ in 0..<5 {
            XCTAssertFalse(challenge.isOpeningCascade)
            XCTAssertEqual(challenge.automaticShowerDelay, 4)
            challenge.letStarsFall()
        }
    }

    func testOpeningAndTwentyTwoShowerOpportunitySample() {
        var first: [Int] = [], clears: [Int] = [], stalls = 0
        for seed in UInt64(0)..<200 {
            var game = FallingSky(seed: seed)
            var firstMatch = 0, count = 0, dry = 0
            for shower in 1...22 where !game.isOver {
                game.letStarsFall()
                if !game.legalGroups.isEmpty {
                    if firstMatch == 0 { firstMatch = shower }
                    // A simple player clears at most one group between showers.
                    game.clear(game.legalGroups[0][0]); count += 1; dry = 0
                } else { dry += 1; stalls = max(stalls, dry) }
            }
            first.append(firstMatch == 0 ? 23 : firstMatch); clears.append(count)
        }
        XCTAssertEqual(first.max(), 1, "Every sampled sky offers a first-shower clear")
        XCTAssertGreaterThanOrEqual(clears.min()!, 6, "Avoid nearly idle 22-shower rounds")
        XCTAssertLessThanOrEqual(stalls, 2, "Dry boards should recover quickly while there is room")
        print("PACING seeds=200 firstMean=\(Double(first.reduce(0,+))/200) firstMax=\(first.max()!) clearsMean=\(Double(clears.reduce(0,+))/200) clearsMin=\(clears.min()!) dryMax=\(stalls)")
    }
    func testIdleSkiesStillReachOverflow() {
        var longest = 0
        for seed in UInt64(0)..<200 {
            var game = FallingSky(seed: seed)
            for _ in 0..<100 where !game.isOver { game.letStarsFall() }
            XCTAssertTrue(game.isOver)
            XCTAssertTrue(game.isValidSave)
            longest = max(longest, game.turns)
        }
        print("IDLE_OVERFLOW latestShower=\(longest)")
    }

    func testHistoricalSaveRetainsOriginalShowerSequence() throws {
        // Captured by compiling the pre-pacing core at ee6e2d2, seed 5, six showers.
        let data = Data(#"{"starsLanded":17,"random":{"state":878018370613331936},"incoming":[{"kind":2,"column":4,"id":30},{"kind":3,"column":5,"id":31}],"turns":6,"score":0,"seed":5,"darkStarsCleared":0,"remainingColumns":[2,6],"savedBalance":{"darkStars":"regular","pace":4},"board":[{"id":6,"grown":false,"kind":1},{"id":1,"kind":4,"grown":true},{"grown":false,"id":0,"kind":4},{"grown":false,"kind":1,"id":4},{"grown":false,"id":5,"kind":2},{"grown":false,"id":3,"kind":0},{"grown":false,"kind":1,"id":2},{"kind":3,"id":12,"grown":true},{"grown":false,"id":16},{"kind":2,"grown":false,"id":13},{"kind":2,"grown":false,"id":11},{"kind":1,"grown":false,"id":7},{"kind":2,"grown":false,"id":10},{"kind":4,"grown":false,"id":8},null,null,null,{"kind":0,"grown":false,"id":14},null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"showersUntilDark":2}"#.utf8)
        var game = try JSONDecoder().decode(FallingSky.self, from: data)
        for expected in ["4:2,5:3", "6:2,2:4", "2:3,6:1,0:1", "5:-1"] {
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(game.incoming.map { "\($0.column):\($0.kind?.rawValue ?? -1)" }.joined(separator: ","), expected)
            game.letStarsFall()
        }
    }

}
