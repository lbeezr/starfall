import XCTest
@testable import StarfallCore

final class StoryCascadeTests: XCTestCase {
    private func revisionTwo(_ challenge: StarfallChallenge) -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(challenge, revision: 2)!)
    }
    private func restored(_ game: FallingSky) throws -> FallingSky {
        try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    private func board(_ rows: [String]) -> [StarfallGem?] {
        let colors: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var result = Array<StarfallGem?>(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, color) in text.enumerated() where color != "." {
                result[row * 7 + column] = StarfallGem(id: id, kind: colors[color]!)
                id += 1
            }
        }
        return result
    }

    private func nearWinning(_ position: [StarfallGem?], showers: Int) throws -> FallingSky {
        let opening = revisionTwo(.firstLight)
        let definition = StoryChallengeDefinition(.firstLight, revision: 2)!
        let delivered = definition.initialLight + definition.suppliedLight(after: showers)
        XCTAssertEqual(delivered - position.compactMap { $0 }.reduce(0) { $0 + $1.value }, 147)
        let encodedBoard = try JSONSerialization.jsonObject(with: JSONEncoder().encode(position))
        let forecast = try JSONSerialization.jsonObject(with: JSONEncoder().encode(definition.shower(number: showers + 1)))
        var counts = Array(repeating: 0, count: 50)
        counts[3] = 49
        var tiers: [[String: Any]] = Array(repeating: ["light": 0, "clearCounts": Array(repeating: 0, count: 50)], count: 5)
        tiers[0] = ["light": 147, "clearCounts": counts]
        return try changed(opening) {
            $0["board"] = encodedBoard
            $0["turns"] = showers
            $0["starsLanded"] = delivered
            $0["score"] = 147
            $0["incoming"] = forecast
            $0["storyScoreLedger"] = ["clearCounts": counts, "cascadeTiers": tiers]
        }
    }

    func testRetainedPairHasMixedRecipeFreeOpeningsWhileOtherLocationsStayHistorical() throws {
        for (challenge, count) in [(StarfallChallenge.firstLight, 24), (.ribbonCrossing, 25)] {
            let game = revisionTwo(challenge)
            XCTAssertEqual(game.challengeRevision, 2)
            XCTAssertTrue(game.supportsAutomaticRecipes)
            XCTAssertEqual(game.occupiedCount, count)
            XCTAssertEqual(game.score, 0)
            XCTAssertEqual(game.displayScore, 0)
            XCTAssertGreaterThanOrEqual(Set(game.board.compactMap { $0?.kind }).count, challenge == .firstLight ? 3 : 4)
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertFalse(game.legalGroups.isEmpty)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try restored(game), game)
            XCTAssertEqual(game.replay(), game)
        }
        for challenge in StarfallChallenge.allCases where ![.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon].contains(challenge) {
            XCTAssertEqual(FallingSky.freshChallenge(challenge), FallingSky(challenge: challenge))
            XCTAssertFalse(FallingSky.freshChallenge(challenge).supportsAutomaticRecipes)
        }
        XCTAssertFalse(FallingSky.freshSurvival(seed: 42).supportsAutomaticRecipes)
    }

    func testOpeningSwapCommitsCausalTwoAndThreePhaseReceiptsWithExactConservation() throws {
        for (challenge, amounts) in [(StarfallChallenge.firstLight, [5_000, 10_000]),
                                     (.ribbonCrossing, [5_000, 10_000, 15_000])] {
            var game = revisionTwo(challenge)
            let before = game
            let turn = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
            XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), amounts)
            XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), Array(1...amounts.count))
            XCTAssertTrue(turn.resolutionPhases.allSatisfy { $0.kind == .recipe })
            XCTAssertEqual(turn.collected, amounts.count * 4)
            XCTAssertEqual(turn.displayAward, amounts.reduce(0, +))
            XCTAssertEqual(turn.award?.comboBonus, amounts.reduce(0, +) - amounts.count * 5_000)
            XCTAssertEqual(turn.award?.clearedStarCount, amounts.count * 4)
            XCTAssertTrue(turn.cleared.isEmpty, "Each phase owns its own coordinates")
            XCTAssertEqual(game.displayScore, turn.displayAward)
            XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, game.starsLanded)
            XCTAssertEqual(game.incoming, before.incoming)
            XCTAssertEqual(game.turns, before.turns)
            XCTAssertEqual(game.starsLanded, before.starsLanded)
            var spent: Set<Int> = []
            for (index, phase) in turn.resolutionPhases.enumerated() {
                let ids = Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id })
                XCTAssertTrue(spent.isDisjoint(with: ids))
                spent.formUnion(ids)
                XCTAssertEqual(ids, Set(phase.recipes.flatMap(\.starIDs)))
                if index > 0 {
                    XCTAssertEqual(phase.before, turn.resolutionPhases[index - 1].settled)
                }
            }
            XCTAssertEqual(game.board, turn.resolutionPhases.last?.settled)
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try restored(game), game)
            XCTAssertEqual(game.replay(), before)
        }
    }

    func testSimultaneousOverlappingRecipesSpendDistinctUnionAndLeaveMatchingNeighbor() {
        let start = board(["AAAA...", "AAA...."])
        let phases = SkyRecipeResolution.resolve(start)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phases[0].recipes.count, 2)
        XCTAssertEqual(phases[0].cleared.count, 6)
        XCTAssertEqual(phases[0].award.baseLight, 6)
        XCTAssertEqual(phases[0].award.displayPoints, 9_000)
        XCTAssertEqual(phases[0].settled.compactMap { $0 }.map(\.id), [3])
        XCTAssertTrue(SkyRecipeResolution.resolve(board(["AAAAAAA"])).isEmpty,
                      "An ordinary ready group remains a manual choice")
    }

    func testCrossResolvesExactFiveWithoutSpendingAdjacentDifferentFamily() {
        let start = board([".RARR..", ".AAA...", "..A...."])
        let phases = SkyRecipeResolution.resolve(start)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phases[0].recipes.map(\.shape), [.cross])
        XCTAssertEqual(phases[0].award.baseLight, 5)
        XCTAssertEqual(phases[0].award.displayPoints, 7_000)
        XCTAssertEqual(phases[0].settled.compactMap { $0 }.count, 3)
    }

    func testSelectiveTraceAndWholeTapShareReceiptWhenTheySpendSameIngredients() throws {
        let opening = revisionTwo(.firstLight)
        let path = [Cell(3, 0), Cell(2, 0), Cell(1, 0), Cell(0, 0), Cell(0, 1)]
        XCTAssertEqual(Set(path), opening.group(at: Cell(0, 0)))
        var tapped = opening, traced = opening
        let tap = try XCTUnwrap(tapped.clear(Cell(0, 0)))
        let trace = try XCTUnwrap(traced.clearConstellation(path))
        XCTAssertEqual(tap.resolutionPhases, trace.resolutionPhases)
        XCTAssertEqual(tap.award, trace.award)
        XCTAssertEqual(tapped, traced)
        XCTAssertEqual(trace.resolutionPhases.first?.cleared, Set(path))
        XCTAssertEqual(trace.resolutionPhases.first?.kind, .manual)
        XCTAssertEqual(opening.displayReward(of: Set(path)), trace.displayAward)
        XCTAssertNil(traced.clearConstellation(path))
        XCTAssertNil(opening.constellationCells(along: [Cell(0, 0), Cell(0, 1), Cell(1, 2), Cell(1, 3)]))
        XCTAssertTrue(traced.isValidSave)
    }

    func testComboUsesCausalDepthAndCapsAtFiveWithoutMultiplyingConservedLight() {
        for depth in 1...12 {
            let award = SkyScoreAward(baseLight: 6, clearedStarCount: 4, comboDepth: depth)
            XCTAssertEqual(award.baseLight, 6)
            XCTAssertEqual(award.sizeBonus, 1_000)
            XCTAssertEqual(award.displayPoints, 7_000 * min(depth, 5))
            XCTAssertEqual(award.comboBonus, 7_000 * (min(depth, 5) - 1))
        }
        let first = SkyScoreAward(baseLight: 4, clearedStarCount: 4)
        let nextAction = SkyScoreAward(baseLight: 4, clearedStarCount: 4)
        XCTAssertEqual(first.comboBonus + nextAction.comboBonus, 0)
    }

    func testTierValidationRequiresGrownLightForTwoActualStarClear() {
        var impossible = StoryScoreLedger(automaticRecipes: true)
        impossible.record(SkyScoreAward(baseLight: 2, clearedStarCount: 2))
        XCTAssertFalse(impossible.isValid(light: 2, target: 150_000, automaticRecipes: true))
        var grown = StoryScoreLedger(automaticRecipes: true)
        grown.record(SkyScoreAward(baseLight: 3, clearedStarCount: 2))
        XCTAssertTrue(grown.isValid(light: 3, target: 150_000, automaticRecipes: true))
    }

    func testTierValidationRejectsMissingForgedUnboundedAndUncausedAwards() throws {
        let game = revisionTwo(.ribbonCrossing)
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["savedChallengeRevision"] = 4 },
            { $0["savedChallengeRevision"] = 1 },
            { $0["score"] = Int.max },
            { $0["turns"] = Int.max },
            { $0["board"] = [] },
            { $0["storyScoreLedger"] = ["clearCounts": Array(repeating: 0, count: 50)] },
            { fields in
                var ledger = fields["storyScoreLedger"] as! [String: Any]
                var tiers = ledger["cascadeTiers"] as! [[String: Any]]
                tiers[4]["light"] = Int.max
                ledger["cascadeTiers"] = tiers
                fields["storyScoreLedger"] = ledger
            },
            { fields in
                var ledger = fields["storyScoreLedger"] as! [String: Any]
                ledger["cascadeTiers"] = []
                fields["storyScoreLedger"] = ledger
            }
        ]
        for mutate in mutations {
            let invalid = try changed(game, mutate)
            _ = invalid.displayScore
            XCTAssertFalse(invalid.isValidSave)
        }
        var played = game
        _ = played.nudge(from: Cell(1, 1), to: Cell(1, 2))
        let uncaused = try changed(played) { fields in
            var ledger = fields["storyScoreLedger"] as! [String: Any]
            var tiers = ledger["cascadeTiers"] as! [[String: Any]]
            tiers.swapAt(0, 4)
            ledger["cascadeTiers"] = tiers
            fields["storyScoreLedger"] = ledger
        }
        XCTAssertFalse(uncaused.isValidSave, "Later phases cannot exist without the preceding clear")
        XCTAssertTrue(played.isValidSave)
    }

    func testRawRevisionOneDecodeReplayAndContinuationKeepManualRecipes() throws {
        let original = FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 1)!)
        var copy = try restored(original)
        XCTAssertFalse(copy.supportsAutomaticRecipes)
        XCTAssertFalse(copy.recipes.isEmpty)
        XCTAssertEqual(copy.replay(), original)
        let tap = try XCTUnwrap(copy.clear(Cell(0, 0)))
        XCTAssertTrue(tap.resolutionPhases.isEmpty)
        XCTAssertEqual(tap.displayAward, 7_000)
        XCTAssertTrue(copy.isValidSave)
        XCTAssertEqual(try restored(copy), copy)
        XCTAssertNotEqual(copy.replay(), FallingSky.freshChallenge(.firstLight))
    }

    func testWinningFirstPhaseFinishesItsCausalChainAndRestoresAsWon() throws {
        let opening = revisionTwo(.firstLight)
        var position = opening.board
        for (offset, kind) in [Jewel.rose, .aqua, .rose].enumerated() {
            position[3 * 7 + 3 + offset] = .init(id: 24 + offset, kind: kind)
        }
        var game = try nearWinning(position, showers: 30)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .playing)
        let turn = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertGreaterThanOrEqual(147_000 + turn.resolutionPhases[0].award.displayPoints, 150_000)
        XCTAssertEqual(game.displayScore, 162_000)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.isValidSave)
        let copy = try restored(game)
        XCTAssertEqual(copy, game)
        XCTAssertEqual(copy.replay(), opening)
        let final = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertNil(game.clear(Cell(0, 0)))
        XCTAssertEqual(game, final)
    }

    func testShowerCanWinAfterGrowthAndKeepsNextCommittedForecastValid() throws {
        var position = board(["RAAVRVR", "V..RVRV", "R..VRVR", "V..RV.."])
        position[1]!.grown = true
        position[2]!.grown = true
        var game = try nearWinning(position, showers: 29)
        XCTAssertTrue(game.isValidSave)
        XCTAssertTrue(game.recipes.isEmpty)
        let before = game, forecast = game.incoming
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.count, 5)
        XCTAssertEqual(turn.arrivals.filter(\.grew).count, 1)
        XCTAssertEqual(turn.forecast, forecast)
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        XCTAssertEqual(turn.resolutionPhases[0].kind, .recipe)
        XCTAssertEqual(turn.collected, 6)
        XCTAssertEqual(turn.displayAward, 7_000)
        XCTAssertEqual(game.displayScore, 154_000)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.incoming, StoryChallengeDefinition(.firstLight, revision: 2)!.shower(number: 31))
        XCTAssertNotEqual(game.incoming, before.incoming)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(try restored(game), game)
        XCTAssertEqual(game.replay(), revisionTwo(.firstLight))
    }
}
