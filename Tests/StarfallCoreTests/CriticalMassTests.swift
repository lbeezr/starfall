import XCTest
@testable import StarfallCore

final class CriticalMassTests: XCTestCase {
    private func fixture(_ stars: [(Cell, Jewel?, Bool, Int)], arrivalColumn: Int = 6) throws -> FallingSky {
        var board = [StarfallGem?](repeating: nil, count: 49)
        for (id, item) in stars.enumerated() {
            board[item.0.row * 7 + item.0.column] = .init(id: id, kind: item.1, light: item.2)
        }
        let base = FallingSky(board: board, incoming: [.init(id: 50, kind: .violet, column: arrivalColumn)], generation: .current)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as? [String: Any])
        var rows = try XCTUnwrap(object["board"] as? [Any])
        for item in stars {
            let index = item.0.row * 7 + item.0.column
            var star = rows[index] as! [String: Any]
            if item.3 > 0 { star["savedStellarAge"] = item.3 }
            rows[index] = star
        }
        object["board"] = rows; object["turns"] = 10
        object["savedCriticalMassRule"] = CriticalMassRule.version; object["unscoredStarlight"] = 0
        let game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(game.isValidSave)
        return game
    }

    func testBirthExclusionBuriedAndOpalAgeAndFullWarningWindow() throws {
        var game = try fixture([(Cell(0,2), .aqua, false, 2), (Cell(1,2), .amber, false, 5), (Cell(0,3), nil, true, 5)])
        game.letStarsFall()
        XCTAssertEqual(game.gem(at: Cell(0,2))?.massStage, 2)
        XCTAssertEqual(game.gem(at: Cell(1,2))?.massStage, 3)
        XCTAssertEqual(game.gem(at: Cell(0,3))?.massStage, 3)
        XCTAssertEqual(game.gem(at: Cell(0,6))?.stellarAge, 0)
        for _ in 0..<2 { XCTAssertTrue(try XCTUnwrap(game.letStarsFall()).stellarCollapses.isEmpty) }
        XCTAssertEqual(game.gem(at: Cell(1,2))?.stellarAge, 8)
        XCTAssertFalse(try XCTUnwrap(game.letStarsFall()).stellarCollapses.isEmpty)
        XCTAssertTrue(game.isValidSave)
    }

    func testSimultaneousOverlapConsumesOnceWithoutChainAndBeforeArrival() throws {
        var game = try fixture([(Cell(0,2), .aqua, false, 8), (Cell(0,3), .amber, false, 8),
                                (Cell(0,4), nil, true, 0), (Cell(0,5), .mint, false, 0)], arrivalColumn: 3)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.stellarCollapses.count, 2)
        XCTAssertEqual(game.lostStarlight, 3)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.gem(at: Cell(0,3))?.kind, .violet, "Arrival follows collapse")
        XCTAssertEqual(game.gem(at: Cell(0,5))?.kind, .mint, "Consumed Opal does not chain into mint")
        XCTAssertEqual(turn.gravityPhases.map(\.event), [.removal, .settling])
        XCTAssertTrue(game.isValidSave)
    }

    func testIsolatedOldStarCollapsesAndFullColumnGetsHeadroom() throws {
        var game = try fixture((0..<7).map { (Cell($0,2), $0 == 6 ? Jewel.aqua : .amber, false, $0 == 6 ? 8 : 0) }, arrivalColumn: 2)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.stellarCollapses.count, 1); XCTAssertNil(turn.blockedColumn)
        XCTAssertEqual(game.lostStarlight, 2); XCTAssertTrue(game.isValidSave)
        var isolated = try fixture([(Cell(0,0), .aqua, false, 8)])
        XCTAssertEqual(isolated.letStarsFall()?.stellarCollapses.first?.consumed, [])
        XCTAssertEqual(isolated.lostStarlight, 1); XCTAssertTrue(isolated.isValidSave)
    }

    func testRescueAndExchangePreserveValueAgeAndAnnouncedForecast() throws {
        var game = try fixture([(Cell(0,2), .aqua, false, 8), (Cell(0,3), .aqua, false, 0), (Cell(0,4), nil, true, 0)])
        let preview = game.incoming
        XCTAssertEqual(game.value(of: [Cell(0,2)]), 1, "Age must not make one star a legal clear")
        XCTAssertNil(game.clear(Cell(0,6)))
        XCTAssertEqual(game.gem(at: Cell(0,2))?.stellarAge, 8)
        let turn = try XCTUnwrap(game.clear(Cell(0,2)))
        XCTAssertEqual(turn.collected, 3); XCTAssertEqual(game.lostStarlight, 0)
        XCTAssertEqual(game.incoming, preview)
        XCTAssertTrue(try XCTUnwrap(game.letStarsFall()).stellarCollapses.isEmpty)
        var exchange = try fixture([(Cell(0,2), .aqua, false, 8), (Cell(0,3), .amber, false, 0)])
        let id = exchange.gem(at: Cell(0,2))?.id
        let moved = try XCTUnwrap(exchange.nudge(from: Cell(0,2), to: Cell(0,3)))
        XCTAssertTrue(moved.stellarAffectedColumns.isSuperset(of: [2,3]))
        XCTAssertEqual(exchange.gem(at: Cell(0,3))?.id, id)
        XCTAssertEqual(exchange.gem(at: Cell(0,3))?.stellarAge, 8)
    }

    func testMatchingGrowthAtWarningDoesNotResetAgeOrBecomeASoloClear() throws {
        var game = try fixture([(Cell(0,2), .violet, false, 5)], arrivalColumn: 2)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.first?.grew, true)
        XCTAssertEqual(game.gem(at: Cell(0,2))?.stellarAge, 6)
        XCTAssertEqual(game.gem(at: Cell(0,2))?.value, 2)
        XCTAssertNil(game.clear(Cell(0,2)))
        XCTAssertTrue(game.isValidSave)
    }

    func testYoungFullColumnStillLosesAndTerminalInputDoesNotAge() throws {
        var game = try fixture((0..<7).map { (Cell($0,2), Jewel.amber, false, 0) }, arrivalColumn: 2)
        XCTAssertEqual(game.letStarsFall()?.blockedColumn, 2)
        XCTAssertEqual(game.outcome, .lost)
        let terminal = game
        XCTAssertNil(game.letStarsFall()); XCTAssertNil(game.clear(Cell(0,2)))
        XCTAssertEqual(game, terminal); XCTAssertTrue(game.isValidSave)
    }

    func testRoundTripReplayHistoricalAndMalformedAges() throws {
        let game = CriticalMassFixture.game()
        var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        var original = game
        XCTAssertEqual(restored, original)
        for _ in 0..<8 where !original.isOver {
            original.letStarsFall(); restored.letStarsFall()
            XCTAssertEqual(original, restored); XCTAssertTrue(original.isValidSave)
        }
        XCTAssertEqual(game.replay(), FallingSky(seed: game.seed, balance: game.balance, openingCascade: false, generation: .current, criticalMass: true))
        XCTAssertFalse(FallingSky(challenge: .firstLight).hasCriticalMass)
        for invalidAge in [-1, 0, 9, Int.max] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
            var board = object["board"] as! [Any]; var gem = board[2] as! [String: Any]
            gem["savedStellarAge"] = invalidAge; board[2] = gem; object["board"] = board
            let malformed = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertFalse(malformed.isValidSave)
        }
        for invalidTurn in [Int.min, -1, 1, Int.max] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
            object["turns"] = invalidTurn
            let malformed = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertFalse(malformed.isValidSave)
        }
        for marker in [0, 2, Int.max] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
            object["savedCriticalMassRule"] = marker
            let malformed = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
            XCTAssertFalse(malformed.isValidSave)
        }
        let old = DuskFixture.imminent.game(rule: .patientFeeding)
        XCTAssertFalse(old.hasCriticalMass)
        var replayed = old; XCTAssertEqual(replayed.letStarsFall()?.duskCollapses.count, 1)
    }

    func testSeededPoliciesStayValidAndHaveNoDuskSupply() {
        var idleTurns = 0, activeTurns = 0, idleLoss = 0, activeLoss = 0
        for seed in 1...40 {
            for collect in [false, true] {
                var game = FallingSky(seed: UInt64(seed), generation: .current, criticalMass: true)
                for _ in 0..<100 where !game.isOver {
                    if collect {
                        for _ in 0..<49 {
                            guard let first = game.legalGroups.first?.first else { break }
                            XCTAssertNotNil(game.clear(first))
                        }
                    }
                    XCTAssertFalse(game.incoming.contains(where: \.isDark))
                    game.letStarsFall(); XCTAssertTrue(game.isValidSave, "seed \(seed)")
                }
                if collect { activeTurns += game.turns; activeLoss += game.lostStarlight }
                else { idleTurns += game.turns; idleLoss += game.lostStarlight }
            }
        }
        print("CRITICAL_MASS seeds=40 cap=100 idleTurns=\(idleTurns) activeTurns=\(activeTurns) idleLost=\(idleLoss) activeLost=\(activeLoss)")
    }
    func testFreshSurvivalSelectsLongerCycleWithoutChangingSeededRuleHistory() throws {
        for seed in UInt64(0)..<8 {
            var fresh = FallingSky.freshSurvival(seed: seed)
            var retained = FallingSky(seed: seed, generation: .current, cadence: .announcedCycleV2, criticalMass: true).disablingAutomaticAging()
            XCTAssertFalse(fresh.hasCriticalMass)
            XCTAssertEqual(fresh.cadenceID, .announcedCycleV1)
            for _ in 0..<40 {
                // Cadence is the sole saved-state difference, including RNG and future preview.
                var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(retained)) as? [String: Any])
                object["savedCadence"] = fresh.cadenceID.rawValue
                let normalized = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
                XCTAssertEqual(fresh, normalized)
                XCTAssertTrue(fresh.isValidSave && retained.isValidSave)
                if fresh.isOver { break }
                fresh.letStarsFall(); retained.letStarsFall()
                if let cell = fresh.legalGroups.first?.first {
                    XCTAssertEqual(fresh.clear(cell)?.collected, retained.clear(cell)?.collected)
                }
            }
        }
        for pace in StarfallBalance.Pace.allCases {
            let balance = StarfallBalance(pace: pace, darkStars: .none)
            XCTAssertEqual(FallingSky.freshSurvival(seed: 64, balance: balance).balance, balance)
        }
    }

    func testBothCriticalCadencesRoundTripAndReplayTheirOwnVersion() throws {
        for cadence: SkyCadenceID in [.announcedCycleV1, .announcedCycleV2] {
            let initial = FallingSky(seed: 64, generation: .current, cadence: cadence, criticalMass: true)
            var game = initial
            for _ in 0..<12 where !game.isOver { game.letStarsFall() }
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(restored, game)
            XCTAssertEqual(restored.cadenceID, cadence)
            XCTAssertEqual(restored.replay(), initial)
        }
        XCTAssertEqual(FallingSky(challenge: .firstLight).cadenceID, .originalV1)
        XCTAssertFalse(FallingSky(challenge: .firstLight).hasCriticalMass)
    }

}

extension CriticalMassTests {
    func testRetiringAgingPreservesCommittedRoundAndNeverCollapsesAgain() throws {
        for seed in UInt64(0)..<20 {
            var old = FallingSky(seed: seed, generation: .current, criticalMass: true)
            for _ in 0..<16 where !old.isOver {
                if let cell = old.legalGroups.first?.first { _ = old.clear(cell) }
                old.letStarsFall()
            }
            var calm = old.disablingAutomaticAging()
            XCTAssertFalse(calm.hasCriticalMass)
            XCTAssertTrue(calm.hasPocketedDusk)
            XCTAssertEqual(calm.disablingAutomaticAging(), calm)
            XCTAssertEqual(calm.adoptingFeedingDusk(), calm)
            XCTAssertEqual(calm.score, old.score)
            XCTAssertEqual(calm.lostStarlight, old.lostStarlight)
            XCTAssertEqual(calm.incoming, old.incoming)
            XCTAssertEqual(calm.board.map { $0?.id }, old.board.map { $0?.id })
            XCTAssertEqual(calm.board.map { $0?.grown }, old.board.map { $0?.grown })
            XCTAssertTrue(calm.isValidSave)
            XCTAssertTrue(calm.board.allSatisfy { ($0?.stellarAge ?? 0) == 0 })
            var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(calm))
            XCTAssertEqual(calm, restored)
            for _ in 0..<40 where !calm.isOver {
                if let cell = calm.legalGroups.first?.first { _ = calm.clear(cell); _ = restored.clear(cell) }
                XCTAssertTrue(try XCTUnwrap(calm.letStarsFall()).stellarCollapses.isEmpty)
                restored.letStarsFall()
                XCTAssertEqual(calm, restored)
                XCTAssertTrue(calm.isValidSave)
                XCTAssertTrue(calm.board.allSatisfy { ($0?.stellarAge ?? 0) == 0 })
                XCTAssertFalse(calm.incoming.contains(where: \.isDark))
                XCTAssertEqual(calm.lostStarlight, old.lostStarlight)
            }
            XCTAssertTrue(calm.replay().isValidSave)
            XCTAssertFalse(calm.replay().hasCriticalMass)
        }
        let challenge = FallingSky(challenge: .firstLight)
        XCTAssertEqual(challenge.disablingAutomaticAging(), challenge)
        let dusk = DuskFixture.imminent.game()
        XCTAssertEqual(dusk.disablingAutomaticAging(), dusk)
    }
}

extension CriticalMassTests {
    func testSameFamilyVerticalExchangeKeepsDistinctAgesAndContinuation() throws {
        var game = try fixture([(Cell(0,2),.aqua,false,2),(Cell(1,2),.aqua,false,8)])
        let young = game.gem(at:Cell(0,2)), old = game.gem(at:Cell(1,2))
        XCTAssertNotNil(game.nudge(from:Cell(0,2),to:Cell(1,2)))
        XCTAssertEqual(game.gem(at:Cell(1,2)),young)
        XCTAssertEqual(game.gem(at:Cell(0,2)),old)
        XCTAssertTrue(game.isValidSave)
        var restored = try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
        game.letStarsFall(); restored.letStarsFall()
        XCTAssertEqual(game,restored)
    }
}
