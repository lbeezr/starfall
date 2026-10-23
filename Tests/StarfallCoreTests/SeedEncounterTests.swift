import XCTest
@testable import StarfallCore

final class SeedEncounterTests: XCTestCase {
    private let spend = [[4, 3], [0, 1], [1, 8], [2, 9]]
    private let preserve = [[1, 8], [17, 10], [1, 2], [2, 9], [7, 8]]

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
        let replayed = try XCTUnwrap(apply(&copy))
        XCTAssertEqual(turn.resolutionPhases, replayed.resolutionPhases)
        XCTAssertEqual(turn.settled, replayed.settled)
        XCTAssertEqual(turn.award, replayed.award)
        XCTAssertEqual(turn.arrivals.map(\.star), replayed.arrivals.map(\.star))
        XCTAssertEqual(turn.arrivals.map(\.gem), replayed.arrivals.map(\.gem))
        XCTAssertEqual(turn.arrivals.map(\.cell), replayed.arrivals.map(\.cell))
        XCTAssertEqual(turn.arrivals.map(\.grew), replayed.arrivals.map(\.grew))
        XCTAssertEqual(turn.blockedColumn, replayed.blockedColumn)
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

    private func assertLine(_ turn: FallingSkyTurn, ids: Set<Int>, grownIDs: Set<Int>,
                            light: Int, points: Int,
                            file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(turn.resolutionPhases.count, 1, file: file, line: line)
        let phase = try XCTUnwrap(turn.resolutionPhases.first, file: file, line: line)
        let ingredients = phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
        XCTAssertEqual(phase.kind, .recipe, file: file, line: line)
        XCTAssertEqual(phase.comboDepth, 1, file: file, line: line)
        XCTAssertEqual(phase.recipes.map(\.shape), [.line], file: file, line: line)
        XCTAssertEqual(Set(ingredients.map(\.id)), ids, file: file, line: line)
        XCTAssertEqual(Set(ingredients.filter(\.grown).map(\.id)), grownIDs, file: file, line: line)
        XCTAssertEqual(phase.award.baseLight, light, file: file, line: line)
        XCTAssertEqual(phase.award.clearedStarCount, ids.count, file: file, line: line)
        XCTAssertEqual(turn.collected, light, file: file, line: line)
        XCTAssertEqual(turn.displayAward, points, file: file, line: line)
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

    func testNewVisitOwnsRecipeFreeOpeningWithOneGrownIngredientAndElevenThousandGoal() throws {
        var game = FallingSky.freshChallenge(.seedMoon)
        let opening = game
        XCTAssertEqual(game.challenge, .seedMoon)
        XCTAssertEqual(game.challengeRevision, 4)
        XCTAssertEqual(game.displayTarget, 11_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.occupiedCount, 23)
        XCTAssertEqual(game.starsLanded, 24)
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<23))
        XCTAssertEqual(game.board.compactMap { $0 }.filter(\.grown).map(\.id), [1])
        XCTAssertEqual(game.gem(at: Cell(0, 1)), StarfallGem(id: 1, kind: .aqua, grown: true))
        XCTAssertEqual(heights(game), [3, 3, 3, 3, 3, 4, 4])
        XCTAssertEqual(game.seed, 42)
        XCTAssertEqual(game.balance, StarfallBalance(pace: .gentle, darkStars: .none))
        XCTAssertEqual(game.automaticShowerDelay, 6)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertTrue(game.supportsAutomaticRecipes)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertTrue(game.supportsArrangingStars)
        XCTAssertTrue(game.recipes.isEmpty)
        let symbols: [Jewel: Character] = [.aqua: "A", .rose: "R", .violet: "V", .mint: "M", .amber: "Y"]
        let rows = (0..<7).map { row in
            String((0..<7).map { column in game.gem(at: Cell(row, column))?.kind.flatMap { symbols[$0] } ?? "." })
        }
        XCTAssertEqual(rows, ["AAARAVY", "ARARAMV", "RMVARYM", ".....RA", ".......", ".......", "......."])
        for row in 0..<7 { for column in 0..<7 { XCTAssertNil(game.clear(Cell(row, column))) } }
        XCTAssertEqual(game, opening)
        try assertSaved(game, opening: opening)
    }

    func testSpendingAndPreservingTheSameGrownAquaGiveDifferentFirstPatternsAndSurvivors() throws {
        let opening = FallingSky.freshChallenge(.seedMoon)
        var spent = opening, preserved = opening
        let immediate = try commit(spend[0], in: &spent, opening: opening)
        try assertLine(immediate, ids: [0, 1, 2, 4], grownIDs: [1], light: 5, points: 6_000)
        XCTAssertEqual(heights(spent), [2, 2, 2, 2, 3, 4, 4])
        XCTAssertEqual(spent.board.compactMap { $0?.id }, [7, 8, 9, 10, 3, 5, 6, 14, 15, 16, 17, 11, 12, 13, 18, 19, 20, 21, 22])
        let moved = try commit(preserve[0], in: &preserved, opening: opening)
        XCTAssertEqual(moved.displayAward, 0)
        XCTAssertTrue(moved.resolutionPhases.isEmpty)
        XCTAssertEqual(preserved.displayScore, 0)
        XCTAssertEqual(preserved.occupiedCount, 23)
        XCTAssertEqual(preserved.gem(at: Cell(1, 1)), opening.gem(at: Cell(0, 1)))
        let later = try commit(preserve[1], in: &preserved, opening: opening)
        try assertLine(later, ids: [1, 7, 9, 11, 17], grownIDs: [1], light: 6, points: 8_000)
        XCTAssertEqual(heights(preserved), [2, 2, 2, 2, 2, 4, 4])
        XCTAssertEqual(preserved.board.compactMap { $0?.id }, [0, 8, 2, 3, 4, 5, 6, 14, 15, 16, 10, 18, 12, 13, 19, 20, 21, 22])
        XCTAssertNotEqual(spent.board, preserved.board)
        XCTAssertEqual(spent.outcome, .playing)
        XCTAssertEqual(preserved.outcome, .playing)
    }

    func testBothFullRoutesWinOnTheirEarnedActionAndKeepExactEveryActionRestoration() throws {
        let opening = FallingSky.freshChallenge(.seedMoon)
        for keep in [false, true] {
            var game = opening
            let actions = keep ? preserve : spend
            let awards = keep ? [0, 8_000, 0, 0, 5_000] : [6_000, 0, 0, 5_000]
            for (index, action) in actions.enumerated() {
                XCTAssertEqual(game.outcome, .playing)
                let turn = try commit(action, in: &game, opening: opening)
                XCTAssertEqual(turn.displayAward, awards[index])
                if awards[index] == 0 { XCTAssertTrue(turn.resolutionPhases.isEmpty) }
                if index == actions.count - 1 {
                    try assertLine(turn, ids: keep ? [8, 10, 14, 18] : [7, 9, 11, 17],
                                   grownIDs: [], light: 4, points: 5_000)
                }
            }
            XCTAssertEqual(game.displayScore, keep ? 13_000 : 11_000)
            XCTAssertEqual(game.turns, 0)
            XCTAssertEqual(heights(game), keep ? [2, 1, 1, 1, 1, 4, 4] : [2, 1, 1, 1, 2, 4, 4])
            XCTAssertEqual(game.board.compactMap { $0?.id }, keep
                ? [0, 2, 16, 3, 4, 5, 6, 15, 12, 13, 19, 20, 21, 22]
                : [8, 15, 16, 10, 3, 5, 6, 14, 18, 12, 13, 19, 20, 21, 22])
            try assertFinished(&game, opening: opening)
        }
    }

    func testOneIgnoredShowerGrowsOnlyMatchingTopRoseAndBothPlansStillFinish() throws {
        let opening = FallingSky.freshChallenge(.seedMoon)
        let definition = try XCTUnwrap(StoryChallengeDefinition(.seedMoon))
        for keep in [false, true] {
            var game = opening
            let turn = try commit([], in: &game, opening: opening)
            XCTAssertEqual(turn.arrivals.count, 5)
            XCTAssertEqual(turn.arrivals.filter(\.grew).map { $0.gem.id }, [18])
            XCTAssertEqual(turn.arrivals.filter { !$0.grew }.map { $0.gem.id }, [24, 25, 26, 27])
            XCTAssertTrue(turn.resolutionPhases.isEmpty)
            XCTAssertEqual(heights(game), [4, 4, 3, 4, 3, 5, 4])
            XCTAssertEqual(game.gem(at: Cell(2, 4)), StarfallGem(id: 18, kind: .rose, grown: true))
            XCTAssertEqual(game.gem(at: Cell(0, 1)), opening.gem(at: Cell(0, 1)))
            XCTAssertEqual(opening.gem(at: Cell(2, 1))?.kind, .mint)
            XCTAssertEqual(game.gem(at: Cell(3, 1)), StarfallGem(id: 26, kind: .aqua))
            XCTAssertEqual(game.incoming, definition.shower(number: 2))
            if keep {
                var setupFirst = opening
                let setup = try commit(preserve[0], in: &setupFirst, opening: opening)
                XCTAssertEqual(setup.displayAward, 0)
                XCTAssertTrue(setup.resolutionPhases.isEmpty)
                let afterSetup = try commit([], in: &setupFirst, opening: opening)
                XCTAssertEqual(afterSetup.arrivals.filter(\.grew).map { $0.gem.id }, [18])
                XCTAssertEqual(afterSetup.displayAward, 0)
                XCTAssertTrue(afterSetup.resolutionPhases.isEmpty)
                var showerFirst = game
                try commit(preserve[0], in: &showerFirst, opening: opening)
                XCTAssertEqual(setupFirst, showerFirst)
                for action in preserve.dropFirst() {
                    try commit(action, in: &setupFirst, opening: opening)
                }
                XCTAssertEqual(setupFirst.displayScore, 14_000)
                try assertFinished(&setupFirst, opening: opening)
            }
            let actions = keep ? preserve : spend
            let awards = keep ? [0, 8_000, 0, 0, 6_000] : [6_000, 0, 0, 5_000]
            for (index, action) in actions.enumerated() {
                XCTAssertEqual(game.outcome, .playing)
                let result = try commit(action, in: &game, opening: opening)
                XCTAssertEqual(result.displayAward, awards[index])
                if index == actions.count - 1 {
                    try assertLine(result, ids: keep ? [8, 10, 14, 18] : [7, 9, 11, 17],
                                   grownIDs: keep ? [18] : [], light: keep ? 5 : 4,
                                   points: keep ? 6_000 : 5_000)
                }
            }
            XCTAssertEqual(game.displayScore, keep ? 14_000 : 11_000)
            XCTAssertEqual(game.turns, 1)
            try assertFinished(&game, opening: opening)
        }
    }

    func testSeedSupplyKeepsTheFrozenFiveFamilyStreamWithoutBoardRetargeting() throws {
        let seed = try XCTUnwrap(StoryChallengeDefinition(.seedMoon))
        let lantern = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 4))
        XCTAssertEqual(seed.palette, [.aqua, .rose, .violet, .mint, .amber])
        for number in 1...140 {
            XCTAssertEqual(seed.shower(number: number), lantern.shower(number: number))
            XCTAssertEqual(seed.suppliedLight(after: number), number * 5)
        }
    }

    func testIgnoringAllPatternsCommitsOverflowAndRetainsItsLosingSave() throws {
        var game = FallingSky.freshChallenge(.seedMoon)
        let opening = game
        for _ in 0..<5 {
            XCTAssertEqual(game.outcome, .playing)
            try commit([], in: &game, opening: opening)
            XCTAssertEqual(game.displayScore, 0)
        }
        XCTAssertEqual(game.turns, 5)
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertNotNil(game.blockedColumn)
        let lost = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.nudge(from: Cell(0, 4), to: Cell(0, 3)))
        XCTAssertEqual(game, lost)
        try assertSaved(game, opening: opening)
    }

    func testHistoricalSeedRemainsManualEighteenLightAndReplaysItsOwnOpening() throws {
        var game = FallingSky(challenge: .seedMoon)
        let opening = game
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertEqual(game.displayTarget, 18)
        XCTAssertTrue(game.supportsManualClears)
        XCTAssertFalse(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.board.allSatisfy { $0 == nil })
        XCTAssertEqual(game.balance, StarfallChallenge.seedMoon.balance)
        XCTAssertNotEqual(game, FallingSky.freshChallenge(.seedMoon))
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

    func testSeedRejectsUnshippedAuthoredRevisionsAndPreservesUnauthoredLocations() throws {
        let game = FallingSky.freshChallenge(.seedMoon)
        for revision in [0, 1, 2, 3, 5] {
            XCTAssertNil(StoryChallengeDefinition(.seedMoon, revision: revision))
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded(game)) as? [String: Any])
            fields["savedChallengeRevision"] = revision
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave)
        }
        for (challenge, revision) in [(StarfallChallenge.frostfruitOrchard, 8), (.sunwheelMill, 0)] {
            XCTAssertEqual(FallingSky.freshChallenge(challenge).challengeRevision, revision)
            XCTAssertEqual(FallingSky(challenge: challenge).challengeRevision, 0)
            if revision == 0 {
                XCTAssertEqual(FallingSky.freshChallenge(challenge), FallingSky(challenge: challenge))
            }
        }
    }
}
