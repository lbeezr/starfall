import XCTest
@testable import StarfallCore

final class FrostfruitEncounterTests: XCTestCase {
    private let safe = [[35,36], [], [], [20,19], [2,9], [3,10]]
    private let immediate = [[20,19], [], [2,9], [3,10]]
    private let ignored = [[], [20,19], [2,9], [3,10]]
    private let firstPreview = [IncomingStar(id: 0, kind: .aqua, column: 5),
                                IncomingStar(id: 1, kind: .amber, column: 0),
                                IncomingStar(id: 2, kind: .aqua, column: 1),
                                IncomingStar(id: 3, kind: .mint, column: 3),
                                IncomingStar(id: 4, kind: .rose, column: 4)]
    private let secondPreview = [IncomingStar(id: 5, kind: .amber, column: 2),
                                 IncomingStar(id: 6, kind: .violet, column: 6),
                                 IncomingStar(id: 7, kind: .violet, column: 5),
                                 IncomingStar(id: 8, kind: .rose, column: 0),
                                 IncomingStar(id: 9, kind: .mint, column: 1)]

    private func heights(_ game: FallingSky) -> [Int] {
        (0..<7).map { SkyBoardSettling.height(game.board, column: $0) }
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        let copy = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(copy, game)
        XCTAssertTrue(copy.isValidSave)
        XCTAssertEqual(copy.replay(), game.replay())
        return copy
    }

    @discardableResult private func commit(_ action: [Int], in game: inout FallingSky) throws -> FallingSkyTurn {
        let before = game
        var copy = try restored(before)
        func apply(_ value: inout FallingSky) -> FallingSkyTurn? {
            if action.isEmpty { return value.letStarsFall() }
            return value.nudge(from: Cell(action[0]/7, action[0]%7), to: Cell(action[1]/7, action[1]%7))
        }
        let turn = try XCTUnwrap(apply(&game))
        let repeated = try XCTUnwrap(apply(&copy))
        XCTAssertEqual(turn.resolutionPhases, repeated.resolutionPhases)
        XCTAssertEqual(turn.arrivals.map(\.star), repeated.arrivals.map(\.star))
        XCTAssertEqual(turn.arrivals.map(\.gem), repeated.arrivals.map(\.gem))
        XCTAssertEqual(turn.arrivals.map(\.cell), repeated.arrivals.map(\.cell))
        XCTAssertEqual(turn.arrivals.map(\.grew), repeated.arrivals.map(\.grew))
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(turn.blockedColumn, repeated.blockedColumn)
        XCTAssertEqual(game, copy)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, game.starsLanded)
        XCTAssertEqual(game.replay(), before.replay())
        if !action.isEmpty {
            XCTAssertEqual(game.incoming, before.incoming)
            XCTAssertEqual(game.turns, before.turns)
            XCTAssertEqual(game.starsLanded, before.starsLanded)
        }
        return turn
    }

    @discardableResult private func run(_ actions: [[Int]], scores: [Int]) throws -> FallingSky {
        var game = FallingSky.freshChallenge(.frostfruitOrchard)
        for (index, action) in actions.enumerated() {
            try commit(action, in: &game)
            XCTAssertEqual(game.displayScore, scores[index])
            XCTAssertEqual(game.challengeRevision, 8)
        }
        return game
    }

    func testNewVisitHasAnExplicitThirtyStarPressureEncounterWithoutChangingOtherVisits() throws {
        let game = FallingSky.freshChallenge(.frostfruitOrchard)
        XCTAssertEqual(StoryChallengeDefinition.currentRevision, 4)
        XCTAssertEqual(StoryChallengeDefinition.maximumSupportedRevision, 8)
        XCTAssertEqual(game.challenge, .frostfruitOrchard)
        XCTAssertEqual(game.challengeRevision, 8)
        XCTAssertEqual(game.displayTarget, 15_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.seed, 42)
        XCTAssertEqual(game.balance, .init(pace: .gentle, darkStars: .none))
        XCTAssertEqual(game.automaticShowerDelay, 6)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertTrue(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.canArrangeStars)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertEqual(game.occupiedCount, 30)
        XCTAssertEqual(game.starsLanded, 30)
        XCTAssertEqual(heights(game), [6,6,4,3,4,4,3])
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<30))
        XCTAssertTrue(game.board.compactMap { $0 }.allSatisfy { !$0.grown })
        XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertEqual(game.incoming, firstPreview)
        let symbols: [Jewel: Character] = [.aqua: "A", .rose: "R", .violet: "V", .mint: "M", .amber: "Y"]
        let rows = (0..<7).map { row in
            String((0..<7).map { game.gem(at: Cell(row,$0))?.kind.flatMap { symbols[$0] } ?? "." })
        }
        XCTAssertEqual(rows, ["AARAAMV", "VMARVVV", "MVRAVAV", "YRY.AR.", "VM.....", "AY.....", "......."])
        XCTAssertEqual(try restored(game), game)
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools] {
            XCTAssertEqual(FallingSky.freshChallenge(challenge).challengeRevision, 4)
        }
        XCTAssertEqual(FallingSky.freshChallenge(.sunwheelMill), FallingSky(challenge: .sunwheelMill))
        XCTAssertEqual(FallingSky.fullBoardLantern().challengeRevision, 6)
        XCTAssertEqual(FallingSky.fullBoardRibbon().challengeRevision, 7)
    }

    func testCapPreparationTradesImmediatePointsForRoomInTheActuallyThreatenedColumns() throws {
        var prepared = FallingSky.freshChallenge(.frostfruitOrchard)
        var points = prepared
        let setup = try commit([35,36], in: &prepared)
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertTrue(setup.resolutionPhases.isEmpty)
        XCTAssertEqual(prepared.gem(at: Cell(5,0))?.id, 29)
        XCTAssertEqual(prepared.gem(at: Cell(5,1))?.id, 28)
        let reward = try commit([20,19], in: &points)
        XCTAssertEqual(reward.displayAward, 5_000)
        XCTAssertEqual(reward.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.square]])
        XCTAssertEqual(reward.resolutionPhases.first?.recipes.first?.starIDs, [11,12,18,20])
        XCTAssertEqual(heights(points), [6,6,4,3,2,2,3])
        let compressed = try commit([], in: &prepared)
        let landed = try commit([], in: &points)
        XCTAssertEqual(compressed.forecast, landed.forecast)
        XCTAssertEqual(compressed.forecast, firstPreview)
        XCTAssertEqual(compressed.arrivals.map(\.grew), [false,true,true,false,false])
        XCTAssertEqual(compressed.arrivals.map { $0.gem.id }, [30,29,28,33,34])
        XCTAssertEqual(landed.arrivals.map(\.grew), [false,false,false,false,false])
        XCTAssertEqual(heights(prepared), [6,6,4,4,5,5,3])
        XCTAssertEqual(heights(points), [7,7,4,4,3,3,3])
        XCTAssertEqual(prepared.occupiedCount, 33)
        XCTAssertEqual(points.occupiedCount, 31)
        XCTAssertEqual(prepared.incoming, secondPreview)
        XCTAssertEqual(points.incoming, secondPreview)
        XCTAssertEqual(prepared.outcome, .playing)
        XCTAssertEqual(points.outcome, .playing)
    }

    func testSameSecondShowerFitsPreparedRoomButCommitsOverflowWithoutPressureRecovery() throws {
        var prepared = try run([[35,36], []], scores: [0,0])
        var untreated = try run([[20,19], []], scores: [5_000,5_000])
        let fits = try commit([], in: &prepared)
        let blocks = try commit([], in: &untreated)
        XCTAssertEqual(fits.forecast, secondPreview)
        XCTAssertEqual(blocks.forecast, secondPreview)
        XCTAssertEqual(fits.arrivals.map { $0.star.id }, [5,6,7,8,9])
        XCTAssertEqual(fits.arrivals.map { $0.gem.id }, [23,20,37,38,39])
        XCTAssertEqual(fits.arrivals.map(\.grew), [true,true,false,false,false])
        XCTAssertEqual(heights(prepared), [7,7,4,4,5,6,3])
        XCTAssertNil(fits.blockedColumn)
        XCTAssertEqual(prepared.outcome, .playing)
        XCTAssertEqual(blocks.arrivals.map { $0.star.id }, [5,6,7])
        XCTAssertEqual(blocks.arrivals.map(\.grew), [true,false,false])
        XCTAssertEqual(blocks.blockedColumn, 0)
        XCTAssertEqual(untreated.gem(at: Cell(6,0))?.kind, .amber)
        XCTAssertFalse(try XCTUnwrap(untreated.gem(at: Cell(6,0))).grown)
        XCTAssertEqual(untreated.outcome, .lost)
        XCTAssertEqual(untreated.displayScore, 5_000)
        XCTAssertEqual(untreated.incoming, secondPreview)
        XCTAssertTrue(blocks.resolutionPhases.isEmpty)
    }

    func testARealRecoveryClearOpensBothFullColumnsBeforeThatSameSecondPreview() throws {
        var game = try run([[20,19], []], scores: [5_000,5_000])
        XCTAssertEqual(Array(heights(game).prefix(2)), [7,7])
        let announced = game.incoming
        let recovery = try commit([2,9], in: &game)
        XCTAssertEqual(recovery.displayAward, 7_000)
        XCTAssertEqual(recovery.resolutionPhases.first?.recipes.first?.starIDs, [0,1,3,4,9])
        XCTAssertEqual(Array(heights(game).prefix(2)), [6,6])
        XCTAssertEqual(game.incoming, announced)
        let shower = try commit([], in: &game)
        XCTAssertEqual(shower.forecast, secondPreview)
        XCTAssertEqual(shower.arrivals.count, 5)
        XCTAssertNil(shower.blockedColumn)
        XCTAssertEqual(game.outcome, .playing)
        try commit([3,10], in: &game)
        XCTAssertEqual(game.displayScore, 17_000)
        XCTAssertEqual(game.outcome, .won)
    }

    func testBothContrastingPlansCompleteTheActualObjectiveAndPreserveSurvivorAccounting() throws {
        let prepared = try run(safe, scores: [0,0,0,6_000,13_000,18_000])
        let points = try run(immediate, scores: [5_000,5_000,12_000,17_000])
        XCTAssertEqual(prepared.outcome, .won)
        XCTAssertEqual(points.outcome, .won)
        XCTAssertEqual(prepared.turns, 2)
        XCTAssertEqual(points.turns, 1)
        XCTAssertEqual(prepared.score, 14)
        XCTAssertEqual(points.score, 13)
        XCTAssertEqual(prepared.occupiedCount, 23)
        XCTAssertEqual(points.occupiedCount, 22)
        XCTAssertEqual(Set(prepared.board.compactMap { $0 }.filter(\.grown).map(\.id)), [23,28,29])
        XCTAssertEqual(prepared.restoration?.milestone, .complete)
        XCTAssertEqual(points.restoration?.milestone, .complete)
        XCTAssertEqual(try restored(prepared).replay(), FallingSky.freshChallenge(.frostfruitOrchard))
        XCTAssertEqual(try restored(points).replay(), FallingSky.freshChallenge(.frostfruitOrchard))
    }

    func testIgnoringTheOpeningShowerStillAllowsTheImmediateRecoveryAndSameCompleteResult() throws {
        let recovered = try run(ignored, scores: [0,5_000,12_000,17_000])
        let planned = try run(immediate, scores: [5_000,5_000,12_000,17_000])
        XCTAssertEqual(recovered.outcome, .won)
        XCTAssertEqual(recovered, planned)
    }

    func testOnlyExposedMatchingCapsGrowAndTheirSavedValueDoesNotIncreaseAgainWhileBuried() throws {
        var game = try run([[35,36], []], scores: [0,0])
        for id in [28,29] {
            let cap = try XCTUnwrap(game.board.compactMap { $0 }.first { $0.id == id })
            XCTAssertTrue(cap.grown)
            XCTAssertEqual(cap.value, 2)
        }
        XCTAssertFalse(try XCTUnwrap(game.board.compactMap { $0 }.first { $0.id == 1 }).grown)
        try commit([], in: &game)
        for id in [28,29] {
            let cap = try XCTUnwrap(game.board.compactMap { $0 }.first { $0.id == id })
            XCTAssertTrue(cap.grown)
            XCTAssertEqual(cap.value, 2)
        }
        XCTAssertFalse(try XCTUnwrap(game.board.compactMap { $0 }.first { $0.id == 1 }).grown)
    }

    func testWonAndLostRoundsLockInputButReplayTheirOriginalDefinition() throws {
        for original in [try run(immediate, scores: [5_000,5_000,12_000,17_000]),
                         try run([[20,19], [], []], scores: [5_000,5_000,5_000])] {
            var game = original
            XCTAssertNil(game.letStarsFall())
            XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertNil(game.clear(Cell(0,0)))
            XCTAssertNil(game.clearConstellation([Cell(0,0),Cell(0,1),Cell(1,1),Cell(1,2),Cell(2,2)]))
            XCTAssertEqual(game, original)
            XCTAssertEqual(try restored(game).replay(), FallingSky.freshChallenge(.frostfruitOrchard))
        }
    }

    func testHistoricalFrostfruitKeepsItsEighteenLightOpeningControlsAndCompleteReplay() throws {
        let opening = FallingSky(challenge: .frostfruitOrchard)
        var game = opening
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertEqual(game.displayTarget, 18)
        XCTAssertEqual(game.occupiedCount, 0)
        XCTAssertTrue(game.supportsManualClears)
        XCTAssertFalse(game.supportsAutomaticRecipes)
        XCTAssertEqual(game.balance, .init(pace: .steady, darkStars: .none))
        for _ in 0..<30 where !game.isOver {
            try commit([], in: &game)
            while !game.isOver, let cell = game.legalGroups.first?.first {
                XCTAssertNotNil(game.clear(cell))
                XCTAssertTrue(game.isValidSave)
            }
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(try restored(game).replay(), opening)
        XCTAssertNotEqual(game.replay(), FallingSky.freshChallenge(.frostfruitOrchard))
    }

    func testUnsupportedDefinitionsAndCorruptedForecastLedgerOrSupplyAreRejected() throws {
        XCTAssertNotNil(StoryChallengeDefinition(.frostfruitOrchard, revision: 8))
        for revision in 1...7 { XCTAssertNil(StoryChallengeDefinition(.frostfruitOrchard, revision: revision)) }
        for challenge in StarfallChallenge.allCases where challenge != .frostfruitOrchard {
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 8))
        }
        XCTAssertNil(StoryChallengeDefinition(.frostfruitOrchard, revision: 9))
        let game = try run([[35,36], []], scores: [0,0])
        let data = try JSONEncoder().encode(game)
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["savedChallengeRevision"] = 7 },
            { $0["savedChallengeRevision"] = 9 },
            { $0["challenge"] = "sunwheelMill" },
            { $0["seed"] = 43 },
            { $0["incoming"] = [] },
            { $0["turns"] = 0 },
            { $0["starsLanded"] = game.starsLanded + 1 },
            { $0.removeValue(forKey: "storyScoreLedger") },
            { $0["storyScoreLedger"] = ["clearCounts": []] },
            { $0["fullBoardSupply"] = ["suppliedStars": 0, "refillingPhases": 0] },
            { fields in var board = fields["board"] as! [Any]; var first = board[0] as! [String: Any]; first["id"] = 1; board[0] = first; fields["board"] = board }
        ]
        for (index, mutate) in mutations.enumerated() {
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            mutate(&fields)
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave, "Mutation \(index)")
        }
    }
}
