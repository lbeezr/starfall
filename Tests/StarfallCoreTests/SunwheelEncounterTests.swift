import XCTest
@testable import StarfallCore

final class SunwheelEncounterTests: XCTestCase {
    private let space = [[15,14], [], [], [17,18], [9,10]]
    private let sequence = [[9,10], [], [0,7]]
    private let direct = [[2,9], [], [0,7], [3,10]]
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
            return value.nudge(from: Cell(action[0]/7,action[0]%7), to: Cell(action[1]/7,action[1]%7))
        }
        let turn = try XCTUnwrap(apply(&game))
        let repeated = try XCTUnwrap(apply(&copy))
        XCTAssertEqual(turn.resolutionPhases, repeated.resolutionPhases)
        XCTAssertEqual(turn.arrivals.map(\.star), repeated.arrivals.map(\.star))
        XCTAssertEqual(turn.arrivals.map(\.gem), repeated.arrivals.map(\.gem))
        XCTAssertEqual(turn.arrivals.map(\.cell), repeated.arrivals.map(\.cell))
        XCTAssertEqual(turn.arrivals.map(\.grew), repeated.arrivals.map(\.grew))
        XCTAssertEqual(turn.blockedColumn, repeated.blockedColumn)
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(game, copy)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0+$1.value }, game.starsLanded)
        XCTAssertEqual(game.replay(), before.replay())
        if !action.isEmpty {
            XCTAssertEqual(game.incoming, before.incoming)
            if before.usesFullBoardRefill {
                XCTAssertEqual(game.turns, before.turns+1)
                XCTAssertEqual(game.starsLanded, before.starsLanded+turn.collected)
            } else {
                XCTAssertEqual(game.turns, before.turns)
                XCTAssertEqual(game.starsLanded, before.starsLanded)
            }
        }
        return turn
    }

    @discardableResult private func run(_ path: [[Int]], scores: [Int]) throws -> FallingSky {
        var game = FallingSky.freshChallenge(.sunwheelMill)
        for (index, action) in path.enumerated() {
            try commit(action, in: &game)
            XCTAssertEqual(game.displayScore, scores[index])
            XCTAssertEqual(game.challengeRevision, 9)
        }
        return game
    }

    private func ids(_ phase: SkyResolutionPhase) -> Set<Int> {
        Set(phase.cleared.compactMap { phase.before[$0.row*7+$0.column]?.id })
    }

    func testNewVisitHasItsOwnRecipeFreePressureBoardAndOneSharedGrownIngredient() throws {
        let game = FallingSky.freshChallenge(.sunwheelMill)
        XCTAssertEqual(game.challenge, .sunwheelMill)
        XCTAssertEqual(game.challengeRevision, 9)
        XCTAssertEqual(game.displayTarget, 24_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.seed, 42)
        XCTAssertEqual(game.balance, .init(pace: .gentle, darkStars: .none))
        XCTAssertEqual(game.automaticShowerDelay, 6)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertTrue(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.canArrangeStars)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertEqual(game.occupiedCount, 26)
        XCTAssertEqual(game.starsLanded, 27)
        XCTAssertEqual(heights(game), [7,5,5,3,2,2,2])
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<26))
        XCTAssertEqual(game.board.compactMap { $0 }.filter(\.grown).map(\.id), [0])
        XCTAssertEqual(game.gem(at: Cell(0,0)), StarfallGem(id: 0, kind: .aqua, grown: true))
        XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertEqual(game.incoming, firstPreview)
        let symbols: [Jewel: Character] = [.aqua:"A", .rose:"R", .violet:"V", .mint:"M", .amber:"Y"]
        let rows = (0..<7).map { row in
            String((0..<7).map { game.gem(at: Cell(row,$0))?.kind.flatMap { symbols[$0] } ?? "." })
        }
        XCTAssertEqual(rows, ["AARAAMV", "AMARYRA", "RARA...", "AAR....", "MRA....", "V......", "M......"])
        XCTAssertEqual(try restored(game).replay(), game)
    }

    func testTheSameGrownAquaCanBuyFourSpacesOrAMoreValuableVisibleSequence() throws {
        let opening = FallingSky.freshChallenge(.sunwheelMill)
        var room = opening, points = opening
        let vertical = try commit([15,14], in: &room)
        let chain = try commit([9,10], in: &points)
        let spacePhase = try XCTUnwrap(vertical.resolutionPhases.first)
        XCTAssertEqual(vertical.resolutionPhases.count, 1)
        XCTAssertEqual(ids(spacePhase), [0,7,15,18])
        XCTAssertEqual(spacePhase.award.baseLight, 5)
        XCTAssertEqual(spacePhase.award.clearedStarCount, 4)
        XCTAssertEqual(vertical.displayAward, 6_000)
        XCTAssertEqual(heights(room), [3,5,5,3,2,2,2])
        XCTAssertEqual(chain.displayAward, 21_000)
        XCTAssertEqual(points.score, 10)
        XCTAssertEqual(heights(points), [6,4,0,2,1,2,2])
        let spent = chain.resolutionPhases.reduce(into: Set<Int>()) { $0.formUnion(ids($1)) }
        XCTAssertEqual(ids(spacePhase).intersection(spent), [0])
        XCTAssertEqual(room.incoming, points.incoming)
        XCTAssertEqual(room.outcome, .playing)
        XCTAssertEqual(points.outcome, .playing)
    }

    func testSupportSequenceUsesOnlyOriginalVisibleSurvivorsAndAwardsTheGrownIngredientAtDepthTwo() throws {
        var game = FallingSky.freshChallenge(.sunwheelMill)
        let visible = Set(game.board.compactMap { $0?.id })
        let turn = try commit([9,10], in: &game)
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        let support = turn.resolutionPhases[0], followUp = turn.resolutionPhases[1]
        XCTAssertEqual(support.recipes.map(\.shape), [.line])
        XCTAssertEqual(followUp.recipes.map(\.shape), [.line])
        XCTAssertEqual(ids(support), [2,10,16,20])
        XCTAssertEqual(ids(followUp), [0,1,3,4,23])
        XCTAssertTrue(ids(support).isSubset(of: visible))
        XCTAssertTrue(ids(followUp).isSubset(of: visible))
        XCTAssertEqual(followUp.before, support.settled)
        XCTAssertEqual(support.before[4*7+2]?.id, 23)
        XCTAssertEqual(support.settled[2]?.id, 23)
        XCTAssertTrue(ids(followUp).isSubset(of: Set(support.settled.compactMap { $0?.id })))
        XCTAssertTrue(support.refillArrivals.isEmpty)
        XCTAssertTrue(followUp.refillArrivals.isEmpty)
        XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), [1,2])
        XCTAssertEqual(support.award.displayPoints, 5_000)
        XCTAssertEqual(followUp.award.baseLight, 6)
        XCTAssertEqual(followUp.award.clearedStarCount, 5)
        XCTAssertEqual(followUp.award.sizeBonus, 2_000)
        XCTAssertEqual(followUp.award.comboBonus, 8_000)
        XCTAssertEqual(followUp.award.displayPoints, 16_000)
        XCTAssertEqual(followUp.before[0]?.id, 0)
        XCTAssertEqual(followUp.before[0]?.grown, true)
        let ordinary = SkyScoreAward(baseLight: 5, clearedStarCount: 5, comboDepth: 2)
        XCTAssertEqual(followUp.award.displayPoints - ordinary.displayPoints, 2_000)
    }

    func testTheSameSecondPreviewFitsSpaceFirstButReallyBlocksUntreatedSequenceFirst() throws {
        var room = try run([[15,14], []], scores: [6_000,6_000])
        var untreated = try run([[9,10], []], scores: [21_000,21_000])
        XCTAssertEqual(heights(room)[0], 4)
        XCTAssertEqual(heights(untreated)[0], 7)
        XCTAssertEqual(room.incoming, secondPreview)
        XCTAssertEqual(untreated.incoming, secondPreview)
        let fits = try commit([], in: &room)
        let blocks = try commit([], in: &untreated)
        XCTAssertEqual(fits.forecast, blocks.forecast)
        XCTAssertEqual(fits.arrivals.map { $0.star.id }, [5,6,7,8,9])
        XCTAssertEqual(blocks.arrivals.map { $0.star.id }, [5,6,7])
        XCTAssertTrue(fits.arrivals.allSatisfy { !$0.grew })
        XCTAssertEqual(heights(room)[0], 5)
        XCTAssertNil(fits.blockedColumn)
        XCTAssertEqual(room.outcome, .playing)
        XCTAssertEqual(blocks.blockedColumn, 0)
        XCTAssertEqual(untreated.gem(at: Cell(6,0))?.kind, .amber)
        XCTAssertEqual(untreated.gem(at: Cell(6,0))?.grown, false)
        XCTAssertEqual(untreated.outcome, .lost)
        XCTAssertEqual(untreated.displayScore, 21_000)
        XCTAssertEqual(untreated.incoming, secondPreview)
        XCTAssertTrue(blocks.resolutionPhases.isEmpty)
    }

    func testAllThreeFixedPlansWinTheActualObjectiveWithExactRestorableConsequences() throws {
        for (path, scores, light, showers, occupied) in [
            (space, [6_000,6_000,6_000,6_000,25_000], 15, 2, 22),
            (sequence, [21_000,21_000,26_000], 14, 1, 18),
            (direct, [8_000,8_000,13_000,24_000], 17, 1, 15)
        ] {
            let game = try run(path, scores: scores)
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.score, light)
            XCTAssertEqual(game.turns, showers)
            XCTAssertEqual(game.occupiedCount, occupied)
            XCTAssertEqual(game.restoration?.milestone, .complete)
            XCTAssertEqual(try restored(game).replay(), FallingSky.freshChallenge(.sunwheelMill))
        }
    }

    func testSpaceFirstCanArrangeAnOverlappingSupportAndVisibleFollowUpForNineteenThousand() throws {
        var game = try run(Array(space.prefix(3)), scores: [6_000,6_000,6_000])
        let forecast = game.incoming
        let preparation = try commit([17,18], in: &game)
        XCTAssertEqual(preparation.displayAward, 0)
        XCTAssertEqual(game.incoming, forecast)
        let visible = Set(game.board.compactMap { $0?.id })
        let finish = try commit([9,10], in: &game)
        XCTAssertEqual(finish.displayAward, 19_000)
        XCTAssertEqual(finish.resolutionPhases.count, 2)
        let support = finish.resolutionPhases[0], followUp = finish.resolutionPhases[1]
        XCTAssertEqual(support.recipes.map(\.shape), [.cross,.line])
        XCTAssertEqual(ids(support), [2,10,14,16,20,31])
        XCTAssertEqual(support.award.clearedStarCount, 6)
        XCTAssertEqual(support.award.displayPoints, 9_000)
        XCTAssertEqual(followUp.recipes.map(\.shape), [.line])
        XCTAssertEqual(ids(followUp), [1,3,4,23])
        XCTAssertEqual(followUp.award.displayPoints, 10_000)
        XCTAssertEqual(followUp.before, support.settled)
        XCTAssertTrue(ids(support).isSubset(of: visible))
        XCTAssertTrue(ids(followUp).isSubset(of: visible))
        XCTAssertEqual(game.displayScore, 25_000)
        XCTAssertEqual(game.outcome, .won)
    }

    func testSpendingTheGrownLineBeforeTheSupportStillLeavesASquareAndElevenThousandRecovery() throws {
        var game = FallingSky.freshChallenge(.sunwheelMill)
        let direct = try commit([2,9], in: &game)
        XCTAssertEqual(direct.displayAward, 8_000)
        XCTAssertEqual(ids(try XCTUnwrap(direct.resolutionPhases.first)), [0,1,3,4,9])
        try commit([], in: &game)
        let square = try commit([0,7], in: &game)
        XCTAssertEqual(square.displayAward, 5_000)
        XCTAssertEqual(square.resolutionPhases.first?.recipes.map(\.shape), [.square])
        XCTAssertEqual(ids(try XCTUnwrap(square.resolutionPhases.first)), [7,15,18,19])
        XCTAssertEqual(game.displayScore, 13_000)
        XCTAssertEqual(game.outcome, .playing)
        let finish = try commit([3,10], in: &game)
        let phase = try XCTUnwrap(finish.resolutionPhases.first)
        XCTAssertEqual(finish.resolutionPhases.count, 1)
        XCTAssertEqual(phase.recipes.map(\.shape), [.cross,.line])
        XCTAssertEqual(ids(phase), [2,10,12,16,20,22,31])
        XCTAssertEqual(phase.award.clearedStarCount, 7)
        XCTAssertEqual(phase.award.baseLight, 7)
        XCTAssertEqual(finish.displayAward, 11_000)
        XCTAssertEqual(game.displayScore, 24_000)
        XCTAssertEqual(game.outcome, .won)
    }

    func testBothWonAndBlockedRoundsLockActionsAndReplayTheirExactOpening() throws {
        for original in [try run(sequence, scores: [21_000,21_000,26_000]),
                         try run([[9,10], [], []], scores: [21_000,21_000,21_000])] {
            var game = original
            XCTAssertNil(game.letStarsFall())
            XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertNil(game.clear(Cell(0,0)))
            XCTAssertNil(game.clearConstellation([Cell(0,0),Cell(0,1),Cell(1,1),Cell(1,2),Cell(2,2)]))
            XCTAssertEqual(game, original)
            XCTAssertEqual(try restored(game).replay(), FallingSky.freshChallenge(.sunwheelMill))
        }
    }

    func testHistoricalSunwheelKeepsItsManualEighteenLightRoundAndCompleteReplay() throws {
        let opening = FallingSky(challenge: .sunwheelMill)
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
        XCTAssertNotEqual(game.replay(), FallingSky.freshChallenge(.sunwheelMill))
    }

    func testOnlySunwheelNineIsAddedAndAllOtherSavedDefinitionSelectionsRemainExact() throws {
        XCTAssertEqual(StoryChallengeDefinition.currentRevision, 4)
        XCTAssertEqual(StoryChallengeDefinition.maximumSupportedRevision, 9)
        XCTAssertNotNil(StoryChallengeDefinition(.sunwheelMill, revision: 9))
        for revision in 1...8 { XCTAssertNil(StoryChallengeDefinition(.sunwheelMill, revision: revision)) }
        XCTAssertNil(StoryChallengeDefinition(.sunwheelMill, revision: 10))
        for challenge in StarfallChallenge.allCases where challenge != .sunwheelMill {
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 9))
        }
        for (challenge, revision, target) in [(StarfallChallenge.firstLight,4,150_000), (.ribbonCrossing,4,220_000),
                                             (.kiteHarbor,4,17_000), (.seedMoon,4,11_000), (.silverPools,4,12_000),
                                             (.frostfruitOrchard,8,15_000)] {
            let game = FallingSky.freshChallenge(challenge)
            XCTAssertEqual(game.challengeRevision, revision)
            XCTAssertEqual(game.displayTarget, target)
            XCTAssertEqual(try restored(game).replay(), game)
        }
        for (challenge, revision, award) in [(StarfallChallenge.firstLight,5,66_000), (.firstLight,6,15_000),
                                            (.ribbonCrossing,7,30_000)] {
            let original = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision)))
            var game = original
            XCTAssertEqual(try commit([8,9], in: &game).displayAward, award)
            XCTAssertEqual(try restored(game).replay(), original)
        }
    }

    func testSaveValidationRejectsForeignRevisionsForecastSupplyLedgerAndIdentityCorruption() throws {
        let game = try run([[9,10], []], scores: [21_000,21_000])
        let data = try JSONEncoder().encode(game)
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["savedChallengeRevision"] = 8 },
            { $0["savedChallengeRevision"] = 10 },
            { $0["challenge"] = "frostfruitOrchard" },
            { $0["seed"] = 43 },
            { $0["incoming"] = [] },
            { $0["turns"] = Int.max },
            { $0["starsLanded"] = game.starsLanded+1 },
            { $0["score"] = game.score+1 },
            { $0.removeValue(forKey: "storyScoreLedger") },
            { $0["storyScoreLedger"] = ["clearCounts": []] },
            { $0["fullBoardSupply"] = ["suppliedStars": 0, "refillingPhases": 0] },
            { fields in var board = fields["board"] as! [Any]; var first = board[0] as! [String: Any]; first["id"] = (board[1] as! [String: Any])["id"]; board[0] = first; fields["board"] = board },
            { fields in var board = fields["board"] as! [Any]; var first = board[0] as! [String: Any]; first["grown"] = true; board[0] = first; fields["board"] = board }
        ]
        for (index, mutate) in mutations.enumerated() {
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            mutate(&fields)
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave, "Mutation \(index)")
        }
    }
}
