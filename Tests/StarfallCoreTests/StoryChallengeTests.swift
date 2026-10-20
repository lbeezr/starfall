import XCTest
@testable import StarfallCore

final class StoryChallengeTests: XCTestCase {
    private func restored(_ game: FallingSky) throws -> FallingSky {
        try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    func testNewVisitsReviseOnlyFirstPairAndStartWithDistinctActualStars() throws {
        let lantern = FallingSky.freshChallenge(.firstLight)
        let ribbon = FallingSky.freshChallenge(.ribbonCrossing)
        XCTAssertEqual(lantern.challengeRevision, 1)
        XCTAssertEqual(ribbon.challengeRevision, 1)
        XCTAssertEqual(lantern.displayTarget, 150_000)
        XCTAssertEqual(ribbon.displayTarget, 220_000)
        XCTAssertEqual(lantern.automaticShowerDelay, 6)
        XCTAssertEqual(ribbon.automaticShowerDelay, 4)
        XCTAssertEqual(lantern.displayScore, 0)
        XCTAssertEqual(ribbon.displayScore, 0)
        XCTAssertEqual(lantern.occupiedCount, 8)
        XCTAssertEqual(ribbon.occupiedCount, 8)
        XCTAssertNotEqual(lantern.board, ribbon.board)
        XCTAssertNotEqual(lantern.incoming, ribbon.incoming)
        for game in [lantern, ribbon] {
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try restored(game), game)
            XCTAssertFalse(game.hasOpeningCascade)
            XCTAssertFalse(game.hasCriticalMass)
            XCTAssertFalse(game.hasPocketedDusk)
            XCTAssertNil(game.forecastPhase)
        }
        for challenge in [StarfallChallenge.kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard] {
            XCTAssertEqual(FallingSky.freshChallenge(challenge), FallingSky(challenge: challenge))
        }
    }

    func testLanternOffersIndependentClearOrBankForGrownHarvest() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertEqual(opening.legalGroups.count, 2)
        var immediate = opening, banked = opening
        let first = try XCTUnwrap(immediate.clear(Cell(0, 0)))
        XCTAssertEqual(first.collected, 5)
        XCTAssertEqual(first.displayAward, 7_000)
        XCTAssertEqual(first.award?.clearedStarCount, 5)
        XCTAssertEqual(first.award?.bonus, 2_000)
        XCTAssertEqual(banked.clear(Cell(0, 4))?.displayAward, 3_000)
        XCTAssertEqual(banked.incoming, opening.incoming)
        banked.letStarsFall()
        let grown = try XCTUnwrap(banked.clear(Cell(0, 0)))
        XCTAssertEqual(grown.collected, 8)
        XCTAssertEqual(grown.award?.clearedStarCount, 5)
        XCTAssertEqual(grown.displayAward, 10_000)
        XCTAssertEqual(banked.score, 11)
        XCTAssertEqual(banked.displayScore, 13_000)
        XCTAssertTrue(banked.isValidSave)
        XCTAssertNotEqual(immediate.board, banked.board)
    }

    func testRibbonUsefulSwapTraceAndOrdinaryAlternativeHaveDifferentSurvivors() throws {
        let opening = FallingSky.freshChallenge(.ribbonCrossing)
        let path = [Cell(0, 0), Cell(1, 1), Cell(0, 2), Cell(0, 3), Cell(0, 4)]
        let selected = try XCTUnwrap(opening.constellationCells(along: path))
        XCTAssertEqual(selected.count, 5)
        XCTAssertGreaterThan(Set(path.map { opening.group(at: $0) }).count, 1)
        var traced = opening, arranged = opening, ordinary = opening
        let trace = try XCTUnwrap(traced.clearConstellation(path))
        XCTAssertEqual(trace.displayAward, 7_000)
        XCTAssertEqual(opening.displayReward(of: selected), trace.displayAward)
        let movedID = opening.gem(at: Cell(1, 1))?.id
        XCTAssertNotNil(arranged.nudge(from: Cell(1, 1), to: Cell(0, 1)))
        XCTAssertEqual(arranged.displayScore, 0)
        let group = arranged.group(at: Cell(0, 0))
        XCTAssertEqual(group.count, 5)
        XCTAssertTrue(group.contains { arranged.gem(at: $0)?.id == movedID })
        XCTAssertEqual(arranged.clear(Cell(0, 0))?.displayAward, 7_000)
        XCTAssertEqual(ordinary.clear(Cell(0, 2))?.displayAward, 3_000)
        XCTAssertNotEqual(ordinary.board, traced.board)
        XCTAssertEqual(ordinary.incoming, traced.incoming)
        for game in [traced, arranged, ordinary] { XCTAssertTrue(game.isValidSave) }
    }

    func testSameIngredientsHaveSameTapTraceAwardAndNoSelectionOrSwapIncome() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        let path = [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 1), Cell(1, 0)]
        var tapped = opening, traced = opening
        let a = try XCTUnwrap(tapped.clear(Cell(0, 0)))
        let b = try XCTUnwrap(traced.clearConstellation(path))
        XCTAssertEqual(a.cleared, b.cleared)
        XCTAssertEqual(a.award, b.award)
        XCTAssertEqual(tapped, traced)
        let committed = traced
        XCTAssertNil(traced.clearConstellation(path))
        XCTAssertEqual(traced, committed)
        for _ in 0..<10 {
            _ = traced.constellationCells(along: path)
            _ = traced.recipes
            _ = traced.displayReward(of: Set(path))
        }
        XCTAssertEqual(traced, committed)
        traced.nudge(from: Cell(0, 4), to: Cell(0, 5))
        XCTAssertEqual(traced.displayScore, committed.displayScore)
    }

    func testBonusCannotBeIncreasedBySplittingAndDependsOnDistinctStarsNotGrowth() {
        for count in 4...49 {
            let whole = SkyScoreAward(baseLight: count, clearedStarCount: count)
            XCTAssertEqual(whole.displayPoints, count * 1_000 + (count - 3) * 1_000)
            for left in 2...(count - 2) {
                let split = SkyScoreAward(baseLight: left, clearedStarCount: left).displayPoints
                    + SkyScoreAward(baseLight: count - left, clearedStarCount: count - left).displayPoints
                XCTAssertGreaterThanOrEqual(whole.displayPoints, split)
            }
        }
        XCTAssertEqual(SkyScoreAward(baseLight: 4, clearedStarCount: 2).displayPoints, 4_000)
        XCTAssertEqual(SkyScoreAward(baseLight: 98, clearedStarCount: 49).displayPoints, 144_000)
    }

    func testTapOnlyPoliciesCompleteBothRepairsAndRoundTripEveryCommittedStep() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for largest in [false, true] {
                var game = FallingSky.freshChallenge(challenge)
                let opening = game
                for _ in 0..<160 where !game.isOver {
                    while !game.isOver {
                        let groups = game.legalGroups
                        let group = largest ? groups.max { game.value(of: Set($0)) < game.value(of: Set($1)) } : groups.first
                        guard let cell = group?.first else { break }
                        let before = game.displayScore
                        let turn = try XCTUnwrap(game.clear(cell))
                        XCTAssertEqual(game.displayScore, before + turn.displayAward)
                        XCTAssertTrue(game.isValidSave)
                        XCTAssertEqual(try restored(game), game)
                    }
                    if !game.isOver {
                        let preview = game.incoming
                        let turn = try XCTUnwrap(game.letStarsFall())
                        XCTAssertEqual(turn.forecast, preview)
                        XCTAssertEqual(turn.displayAward, 0)
                        XCTAssertTrue(game.isValidSave)
                        XCTAssertEqual(try restored(game), game)
                    }
                }
                XCTAssertEqual(game.outcome, .won, "\(challenge), largest \(largest)")
                XCTAssertGreaterThan(game.turns, 20)
                XCTAssertGreaterThanOrEqual(game.displayScore, try XCTUnwrap(game.displayTarget))
                XCTAssertEqual(game.restoration?.milestone, .complete)
                XCTAssertEqual(game.replay(), opening)
                let finished = game
                XCTAssertNil(game.letStarsFall())
                XCTAssertNil(game.clear(Cell(0, 0)))
                XCTAssertEqual(game, finished)
            }
        }
    }

    func testRestoredDifferentActionsKeepForecastCadenceAndReplayExact() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            var game = FallingSky.freshChallenge(challenge)
            for _ in 0..<18 where !game.isOver {
                if let cell = game.legalGroups.first?.first { game.clear(cell) }
                game.letStarsFall()
            }
            var copy = try restored(game)
            XCTAssertEqual(copy.incoming, game.incoming)
            XCTAssertEqual(copy.automaticShowerDelay, game.automaticShowerDelay)
            for _ in 0..<12 where !game.isOver {
                if let cell = game.legalGroups.last?.first {
                    XCTAssertEqual(game.clear(cell)?.award, copy.clear(cell)?.award)
                }
                game.letStarsFall(); copy.letStarsFall()
                XCTAssertEqual(copy, game)
            }
            XCTAssertEqual(copy.replay(), FallingSky.freshChallenge(challenge))
        }
    }

    func testLanternAllowsMissedOpeningShowersAndClearingEveryThirdShower() throws {
        for (initialWait, frequency) in [(1, 1), (2, 1), (0, 3)] {
            var game = FallingSky.freshChallenge(.firstLight)
            for _ in 0..<90 where !game.isOver {
                if game.turns >= initialWait, game.turns.isMultiple(of: frequency) {
                    while !game.isOver, let cell = game.legalGroups.last?.first {
                        game.clear(cell)
                        XCTAssertTrue(game.isValidSave)
                    }
                }
                if !game.isOver {
                    game.letStarsFall()
                    XCTAssertTrue(game.isValidSave)
                    game = try restored(game)
                }
            }
            XCTAssertEqual(game.outcome, .won, "wait \(initialWait), frequency \(frequency)")
            XCTAssertLessThanOrEqual(game.turns, 60)
            XCTAssertGreaterThanOrEqual(game.displayScore, 150_000)
        }
    }

    func testAuthoredSupplyRejectsForgedDuskAccountingAndChangedPreview() throws {
        let game = FallingSky.freshChallenge(.firstLight)
        let darkAccounting = try changed(game) { fields in
            var board = fields["board"] as! [Any]
            board[8] = NSNull()
            fields["board"] = board
            fields["darkStarsCleared"] = 1
        }
        XCTAssertFalse(darkAccounting.isValidSave, "No Dusk ever enters this revision")
        let preview = try changed(game) { fields in
            var incoming = fields["incoming"] as! [[String: Any]]
            incoming[0]["column"] = 6
            fields["incoming"] = incoming
        }
        XCTAssertFalse(preview.isValidSave, "A committed authored preview cannot be retargeted")
        let missingOpeningLight = try changed(game) { fields in
            fields["starsLanded"] = 0
            fields["board"] = Array(repeating: NSNull(), count: 49)
        }
        XCTAssertFalse(missingOpeningLight.isValidSave)
    }

    func testLegacyEighteenPointWinRemainsWonAndReplaysLegacyContent() throws {
        for challenge in StarfallChallenge.allCases {
            var game = FallingSky(challenge: challenge)
            let opening = game
            for _ in 0..<30 where !game.isOver {
                game.letStarsFall()
                while !game.isOver, let cell = game.legalGroups.first?.first { game.clear(cell) }
            }
            let copy = try restored(game)
            XCTAssertEqual(copy.challengeRevision, 0)
            XCTAssertEqual(copy.outcome, .won)
            XCTAssertEqual(copy.displayScore, copy.score)
            XCTAssertEqual(copy.displayTarget, 18)
            XCTAssertEqual(copy.replay(), opening)
            XCTAssertEqual(copy.adoptingCurrentChallengeActions(), copy)
            XCTAssertTrue(copy.isValidSave)
        }
    }

    func testRejectsMissingMisplacedFutureAndUnboundedScoreStateWithoutOverflow() throws {
        let game = FallingSky.freshChallenge(.firstLight)
        let mutations: [(inout [String: Any]) -> Void] = [
            { $0["savedChallengeRevision"] = 2 },
            { $0["savedChallengeRevision"] = 0 },
            { $0.removeValue(forKey: "savedChallengeRevision") },
            { $0.removeValue(forKey: "storyScoreLedger") },
            { $0["challenge"] = "silverPools" },
            { $0.removeValue(forKey: "challenge") },
            { $0["score"] = Int.max },
            { $0["turns"] = Int.max },
            { $0["storyScoreLedger"] = ["clearCounts": [Int.max]] },
            { $0["storyScoreLedger"] = ["clearCounts": Array(repeating: Int.max, count: 50)] },
            { $0["storyScoreLedger"] = ["clearCounts": Array(repeating: -1, count: 50)] },
            { $0["savedChallengeActions"] = 0 }
        ]
        for mutate in mutations {
            let invalid = try changed(game, mutate)
            _ = invalid.displayScore
            XCTAssertFalse(invalid.isValidSave)
        }
        var cleared = game
        cleared.clear(Cell(0, 0))
        let forged = try changed(cleared) { fields in
            var counts = Array(repeating: 0, count: 50)
            counts[49] = 1
            fields["storyScoreLedger"] = ["clearCounts": counts]
        }
        XCTAssertFalse(forged.isValidSave)
        XCTAssertTrue(cleared.isValidSave)
    }

    func testIdleOverflowAndNewOpeningAccountingRemainValidAfterRestore() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            var game = FallingSky.freshChallenge(challenge)
            for _ in 0..<80 where !game.isOver { game.letStarsFall() }
            XCTAssertEqual(game.outcome, .lost)
            XCTAssertEqual(game.displayScore, 0)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try restored(game), game)
        }
    }
}
