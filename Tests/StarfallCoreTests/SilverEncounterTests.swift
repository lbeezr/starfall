import XCTest
@testable import StarfallCore

final class SilverEncounterTests: XCTestCase {
    private let chain = [9, 10]
    private let immediate = [2, 9]
    private let recovery = [23, 22]

    private func encoded(_ game: FallingSky) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(game)
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        try JSONDecoder().decode(FallingSky.self, from: encoded(game))
    }

    private func heights(_ game: FallingSky) -> [Int] {
        (0..<7).map { column in (0..<7).filter { game.gem(at: Cell($0, column)) != nil }.count }
    }

    private func assertSaved(_ game: FallingSky, opening: FallingSky,
                             file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertTrue(game.isValidSave, file: file, line: line)
        let copy = try restored(game)
        XCTAssertEqual(copy, game, file: file, line: line)
        XCTAssertEqual(try encoded(copy), try encoded(game), file: file, line: line)
        XCTAssertEqual(copy.replay(), opening, file: file, line: line)
        XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value },
                       game.starsLanded, file: file, line: line)
    }

    @discardableResult
    private func commit(_ action: [Int], in game: inout FallingSky,
                        opening: FallingSky) throws -> FallingSkyTurn {
        let before = game
        var copy = try restored(before)
        func apply(_ game: inout FallingSky) -> FallingSkyTurn? {
            if action.isEmpty { return game.letStarsFall() }
            return game.nudge(from: Cell(action[0] / 7, action[0] % 7),
                              to: Cell(action[1] / 7, action[1] % 7))
        }
        let turn = try XCTUnwrap(apply(&game))
        let repeated = try XCTUnwrap(apply(&copy))
        XCTAssertEqual(turn.resolutionPhases, repeated.resolutionPhases)
        XCTAssertEqual(turn.settled, repeated.settled)
        XCTAssertEqual(turn.award, repeated.award)
        XCTAssertEqual(turn.arrivals.map(\.star), repeated.arrivals.map(\.star))
        XCTAssertEqual(turn.arrivals.map(\.gem), repeated.arrivals.map(\.gem))
        XCTAssertEqual(turn.arrivals.map(\.cell), repeated.arrivals.map(\.cell))
        XCTAssertEqual(turn.arrivals.map(\.grew), repeated.arrivals.map(\.grew))
        XCTAssertEqual(turn.blockedColumn, repeated.blockedColumn)
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(game, copy)
        if !action.isEmpty {
            XCTAssertEqual(game.incoming, before.incoming)
            XCTAssertEqual(game.turns, before.turns)
            XCTAssertEqual(game.starsLanded, before.starsLanded)
        }
        try assertSaved(game, opening: opening)
        return turn
    }

    private func assertLine(_ phase: SkyResolutionPhase, ids: Set<Int>, kind: Jewel,
                            depth: Int, points: Int,
                            file: StaticString = #filePath, line: UInt = #line) {
        let ingredients = phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
        XCTAssertEqual(phase.kind, .recipe, file: file, line: line)
        XCTAssertEqual(phase.comboDepth, depth, file: file, line: line)
        XCTAssertEqual(phase.recipes.map(\.shape), [.line], file: file, line: line)
        XCTAssertEqual(phase.recipes.map(\.starIDs), [ids], file: file, line: line)
        XCTAssertEqual(Set(ingredients.map(\.id)), ids, file: file, line: line)
        XCTAssertTrue(ingredients.allSatisfy { $0.kind == kind && !$0.grown }, file: file, line: line)
        XCTAssertEqual(phase.award.baseLight, ids.count, file: file, line: line)
        XCTAssertEqual(phase.award.clearedStarCount, ids.count, file: file, line: line)
        XCTAssertEqual(phase.award.displayPoints, points, file: file, line: line)
        XCTAssertTrue(phase.refillArrivals.isEmpty, file: file, line: line)
        XCTAssertEqual(phase.refilled, phase.settled, file: file, line: line)
    }

    private func assertChain(_ turn: FallingSkyTurn,
                             file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(turn.resolutionPhases.count, 2, file: file, line: line)
        let support = try XCTUnwrap(turn.resolutionPhases.first, file: file, line: line)
        let followUp = try XCTUnwrap(turn.resolutionPhases.last, file: file, line: line)
        assertLine(support, ids: [2, 10, 16, 20], kind: .rose, depth: 1, points: 5_000,
                   file: file, line: line)
        assertLine(followUp, ids: [0, 1, 3, 4, 23], kind: .aqua, depth: 2, points: 14_000,
                   file: file, line: line)
        XCTAssertEqual(support.cleared, Set((0..<4).map { Cell($0, 2) }), file: file, line: line)
        XCTAssertEqual(support.before[4 * 7 + 2], StarfallGem(id: 23, kind: .aqua), file: file, line: line)
        XCTAssertEqual(support.settled[2], StarfallGem(id: 23, kind: .aqua), file: file, line: line)
        XCTAssertEqual(StarRecipe.find(in: support.before, lineLength: 4), support.recipes,
                       file: file, line: line)
        XCTAssertEqual(support.settled, followUp.before, file: file, line: line)
        XCTAssertEqual(StarRecipe.find(in: support.settled, lineLength: 4), followUp.recipes,
                       file: file, line: line)
        XCTAssertEqual(followUp.cleared, Set((0..<5).map { Cell(0, $0) }), file: file, line: line)
        XCTAssertEqual(turn.collected, 9, file: file, line: line)
        XCTAssertEqual(turn.displayAward, 19_000, file: file, line: line)
    }

    private func assertFinished(_ game: inout FallingSky, opening: FallingSky) throws {
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.restoration?.milestone, .complete)
        let finished = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertNil(game.clear(Cell(0, 0)))
        XCTAssertEqual(game, finished)
        try assertSaved(game, opening: opening)
    }

    func testNewVisitOwnsRecipeFreeOrdinaryOpeningAndTwelveThousandGoal() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        XCTAssertEqual(game.challenge, .silverPools)
        XCTAssertEqual(game.challengeRevision, 4)
        XCTAssertEqual(game.displayTarget, 12_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.occupiedCount, 24)
        XCTAssertEqual(game.starsLanded, 24)
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<24))
        XCTAssertTrue(game.board.compactMap { $0 }.allSatisfy { !$0.grown })
        XCTAssertEqual(heights(game), [5, 5, 5, 3, 2, 2, 2])
        XCTAssertEqual(game.seed, 42)
        XCTAssertEqual(game.balance, StarfallBalance(pace: .gentle, darkStars: .none))
        XCTAssertEqual(game.automaticShowerDelay, 6)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertTrue(game.supportsAutomaticRecipes)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertTrue(game.supportsArrangingStars)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertTrue(game.recipes.isEmpty)
        let symbols: [Jewel: Character] = [.aqua: "A", .rose: "R", .violet: "V", .mint: "M", .amber: "Y"]
        let rows = (0..<7).map { row in
            String((0..<7).map { column in game.gem(at: Cell(row, column))?.kind.flatMap { symbols[$0] } ?? "." })
        }
        XCTAssertEqual(rows, ["AARAAMV", "VMARYRA", "MVRA...", "YAR....", "MRA....", ".......", "......."])
        for row in 0..<7 { for column in 0..<7 { XCTAssertNil(game.clear(Cell(row, column))) } }
        XCTAssertEqual(game, opening)
        try assertSaved(game, opening: opening)
    }

    func testPlanningTheSupportDropsASurvivorFourRowsIntoACausalWinningLine() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        let turn = try commit(chain, in: &game, opening: opening)
        try assertChain(turn)
        XCTAssertEqual(game.displayScore, 19_000)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(heights(game), [4, 4, 0, 2, 1, 2, 2])
        XCTAssertEqual(game.board.compactMap { $0?.id }, [7, 8, 9, 11, 5, 6, 14, 15, 17, 12, 13, 18, 19, 21, 22])
        try assertFinished(&game, opening: opening)
    }

    func testImmediateLineNeedsAnIndependentRecoveryAndLeavesDifferentSurvivors() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        let first = try commit(immediate, in: &game, opening: opening)
        XCTAssertEqual(first.resolutionPhases.count, 1)
        assertLine(try XCTUnwrap(first.resolutionPhases.first), ids: [0, 1, 3, 4, 9],
                   kind: .aqua, depth: 1, points: 7_000)
        XCTAssertEqual(game.displayScore, 7_000)
        XCTAssertEqual(game.outcome, .playing)
        XCTAssertEqual(heights(game), [4, 4, 4, 2, 1, 2, 2])
        let second = try commit(recovery, in: &game, opening: opening)
        XCTAssertEqual(second.resolutionPhases.count, 1)
        assertLine(try XCTUnwrap(second.resolutionPhases.first), ids: [2, 16, 20, 22],
                   kind: .rose, depth: 1, points: 5_000)
        XCTAssertEqual(game.displayScore, 12_000)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.board.compactMap { $0?.id }, [7, 8, 10, 11, 5, 6, 14, 15, 17, 12, 13, 18, 19, 21, 23])
        var planned = opening
        try commit(chain, in: &planned, opening: opening)
        XCTAssertEqual(heights(planned), heights(game))
        XCTAssertNotEqual(planned.board, game.board)
        XCTAssertEqual(planned.gem(at: Cell(0, 3)), StarfallGem(id: 9, kind: .aqua))
        XCTAssertEqual(planned.gem(at: Cell(3, 1)), StarfallGem(id: 22, kind: .rose))
        XCTAssertEqual(game.gem(at: Cell(0, 3)), StarfallGem(id: 10, kind: .rose))
        XCTAssertEqual(game.gem(at: Cell(3, 1)), StarfallGem(id: 23, kind: .aqua))
        try assertFinished(&game, opening: opening)
    }

    func testOneShowerBeforeEitherChoiceOrBetweenIndependentClearsStillAllowsCompletion() throws {
        let opening = FallingSky.freshChallenge(.silverPools)
        let routes: [([[Int]], [Int])] = [
            ([[], chain], [0, 19_000]),
            ([[], immediate, recovery], [0, 7_000, 5_000]),
            ([immediate, [], recovery], [7_000, 0, 5_000])
        ]
        var recovered: [FallingSky] = []
        for (actions, awards) in routes {
            var game = opening
            for (index, action) in actions.enumerated() {
                XCTAssertEqual(game.outcome, .playing)
                let turn = try commit(action, in: &game, opening: opening)
                XCTAssertEqual(turn.displayAward, awards[index])
                if action.isEmpty {
                    XCTAssertEqual(turn.arrivals.count, 5)
                    XCTAssertEqual(turn.arrivals.map { $0.gem.id }, [24, 25, 26, 27, 28])
                    XCTAssertTrue(turn.arrivals.allSatisfy { !$0.grew })
                    XCTAssertTrue(turn.resolutionPhases.isEmpty)
                } else if action == chain {
                    try assertChain(turn)
                } else {
                    XCTAssertEqual(turn.resolutionPhases.count, 1)
                    assertLine(try XCTUnwrap(turn.resolutionPhases.first),
                               ids: action == immediate ? [0, 1, 3, 4, 9] : [2, 16, 20, 22],
                               kind: action == immediate ? .aqua : .rose, depth: 1, points: awards[index])
                }
            }
            XCTAssertEqual(game.displayScore, actions.contains(chain) ? 19_000 : 12_000)
            XCTAssertEqual(game.turns, 1)
            XCTAssertEqual(heights(game), [5, 5, 0, 3, 2, 3, 2])
            if !actions.contains(chain) { recovered.append(game) }
            try assertFinished(&game, opening: opening)
        }
        XCTAssertEqual(recovered.count, 2)
        XCTAssertEqual(recovered.first, recovered.last)
    }

    func testSilverSupplyKeepsTheFrozenFiveFamilyStreamWithoutBoardRetargeting() throws {
        let silver = try XCTUnwrap(StoryChallengeDefinition(.silverPools))
        let lantern = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 4))
        XCTAssertEqual(silver.palette, [.aqua, .rose, .violet, .mint, .amber])
        for number in 1...140 {
            XCTAssertEqual(silver.shower(number: number), lantern.shower(number: number))
            XCTAssertEqual(silver.suppliedLight(after: number), number * 5)
        }
    }

    func testIgnoringPatternsOverflowsOnFourthShowerAndRetainsItsLosingSave() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let opening = game
        for index in 0..<4 {
            XCTAssertEqual(game.outcome, .playing)
            let turn = try commit([], in: &game, opening: opening)
            XCTAssertEqual(turn.arrivals.count, index == 3 ? 0 : 5)
            XCTAssertTrue(turn.resolutionPhases.isEmpty)
            XCTAssertEqual(game.displayScore, 0)
        }
        XCTAssertEqual(game.turns, 4)
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertEqual(game.blockedColumn, 0)
        XCTAssertEqual(heights(game), [7, 7, 7, 5, 4, 5, 3])
        let lost = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertEqual(game, lost)
        try assertSaved(game, opening: opening)
    }

    func testHistoricalSilverRemainsManualEighteenLightAndReplaysItsOwnOpening() throws {
        var game = FallingSky(challenge: .silverPools)
        let opening = game
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertEqual(game.displayTarget, 18)
        XCTAssertTrue(game.supportsManualClears)
        XCTAssertFalse(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.board.allSatisfy { $0 == nil })
        XCTAssertEqual(game.balance, StarfallChallenge.silverPools.balance)
        XCTAssertNotEqual(game, FallingSky.freshChallenge(.silverPools))
        for _ in 0..<30 where !game.isOver {
            try commit([], in: &game, opening: opening)
            while !game.isOver, let cell = game.legalGroups.first?.first {
                var copy = try restored(game)
                XCTAssertEqual(game.clear(cell)?.collected, copy.clear(cell)?.collected)
                XCTAssertEqual(game, copy)
                try assertSaved(game, opening: opening)
            }
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, game.score)
        XCTAssertEqual(game.displayTarget, 18)
        XCTAssertEqual(game.replay(), opening)
    }

    func testSilverRejectsUnshippedAuthoredRevisionsAndPreservesUnauthoredLocations() throws {
        let game = FallingSky.freshChallenge(.silverPools)
        for revision in [0, 1, 2, 3, 5, 6] {
            XCTAssertNil(StoryChallengeDefinition(.silverPools, revision: revision))
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded(game)) as? [String: Any])
            fields["savedChallengeRevision"] = revision
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave)
        }
        for challenge in [StarfallChallenge.frostfruitOrchard, .sunwheelMill] {
            XCTAssertEqual(FallingSky.freshChallenge(challenge), FallingSky(challenge: challenge))
        }
    }
}
