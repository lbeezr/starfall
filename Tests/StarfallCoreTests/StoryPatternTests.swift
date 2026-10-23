import XCTest
@testable import StarfallCore

final class StoryPatternTests: XCTestCase {
    private func board(_ rows: [String], grown: Bool = false) -> [StarfallGem?] {
        let kinds: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var result = Array<StarfallGem?>(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                result[row * 7 + column] = .init(id: id, kind: kinds[symbol]!, grown: grown)
                id += 1
            }
        }
        return result
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) throws -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        try edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
    }

    private func position(_ board: [StarfallGem?], score: Int, ledger: StoryScoreLedger,
                          showers: Int = 0) throws -> FallingSky {
        let definition = StoryChallengeDefinition(.firstLight, revision: 3)!
        return try changed(FallingSky(definition: definition)) {
            $0["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(board))
            $0["score"] = score
            $0["storyScoreLedger"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ledger))
            $0["turns"] = showers
            $0["starsLanded"] = definition.initialLight + definition.suppliedLight(after: showers)
            $0["incoming"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(definition.shower(number: showers + 1)))
        }
    }

    func testCurrentAndRetainedPairUseFiveFamiliesAndDeliberateOpeningSwaps() throws {
        for revision in [3, 4] {
        for (challenge, count, chain) in [(StarfallChallenge.firstLight, 24, [5_000, 10_000]),
                                         (.ribbonCrossing, 25, [5_000, 10_000, 15_000])] {
            let game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: revision)!)
            XCTAssertEqual(game.challengeRevision, revision)
            XCTAssertFalse(game.supportsManualClears)
            XCTAssertTrue(game.supportsAutomaticRecipes)
            XCTAssertEqual(game.occupiedCount, count)
            XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
            XCTAssertTrue(game.recipes.isEmpty)
            XCTAssertTrue(game.legalGroups.isEmpty)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try restored(game), game)
            XCTAssertEqual(game.replay(), game)
            var scoringSwaps = 0
            for row in 0..<7 { for column in 0..<7 {
                let a = Cell(row, column)
                guard let first = game.gem(at: a) else { continue }
                for b in [Cell(row, column + 1), Cell(row + 1, column)] {
                    guard let second = game.gem(at: b), first.kind != second.kind else { continue }
                    var copy = game
                    if let turn = copy.nudge(from: a, to: b), turn.displayAward > 0 { scoringSwaps += 1 }
                }
            } }
            XCTAssertEqual(scoringSwaps, revision == 3 ? 3 : 4)
            var played = game
            let turn = try XCTUnwrap(played.nudge(from: Cell(1, 1), to: Cell(1, 2)))
            XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), chain)
            XCTAssertTrue(turn.resolutionPhases.allSatisfy { $0.kind == .recipe })
            XCTAssertEqual(turn.displayAward, chain.reduce(0, +))
            XCTAssertEqual(played.incoming, game.incoming)
            XCTAssertEqual(played.score + played.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, played.starsLanded)
            XCTAssertTrue(played.isValidSave)
            XCTAssertEqual(try restored(played), played)
        }
        }
    }

    func testEveryManualClearAndSelectionPathRejectsWithoutMutation() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        let before = game
        let path = [Cell(1, 0), Cell(0, 0), Cell(0, 1), Cell(1, 2), Cell(2, 3)]
        XCTAssertEqual(Set(path.compactMap { game.gem(at: $0)?.kind }), [.aqua])
        XCTAssertGreaterThanOrEqual(game.value(of: game.group(at: Cell(0, 0))), 3)
        XCTAssertFalse(game.canStartConstellation(at: path[0]))
        XCTAssertFalse(game.isValidConstellationPrefix(path))
        XCTAssertNil(game.constellationCells(along: path))
        XCTAssertTrue(game.constellationGroup(at: path[0]).isEmpty)
        XCTAssertNil(game.selectedClearCells(along: path))
        XCTAssertEqual(game.displayReward(of: Set(path)), 0)
        for cell in path { XCTAssertNil(game.clear(cell)) }
        XCTAssertNil(game.clearConstellation(path))
        XCTAssertNil(game.clearSelected(path))
        let recipe = try XCTUnwrap(StarRecipe.find(in: board(["AA.....", "AA....."])).first)
        XCTAssertNil(game.activate(recipe))
        XCTAssertEqual(game, before)
    }

    func testFullRowsAndColumnsNeedSevenActualStarsAndStayVersioned() {
        for position in [board(["AAAAAAA"]), board(Array(repeating: "A......", count: 7))] {
            XCTAssertTrue(StarRecipe.find(in: position).isEmpty)
            let phases = SkyRecipeResolution.resolve(position, lineLength: 7)
            XCTAssertEqual(phases.count, 1)
            XCTAssertEqual(phases.first?.recipes.map(\.shape), [.line])
            XCTAssertEqual(phases.first?.cleared.count, 7)
            XCTAssertEqual(phases.first?.award.displayPoints, 11_000)
            XCTAssertTrue(phases.first?.settled.allSatisfy { $0 == nil } == true)
            XCTAssertEqual(SkyTutorial.walk(phases[0].recipes[0]), phases[0].recipes[0].cells)
        }
        for position in [board(["AAAAAA."], grown: true),
                         board(Array(repeating: "A......", count: 6), grown: true),
                         board(["AAAAAAR"]), board(["AAA.AAA"])] {
            XCTAssertTrue(SkyRecipeResolution.resolve(position, lineLength: 7).isEmpty)
        }
        let grown = SkyRecipeResolution.resolve(board(["AAAAAAA"], grown: true), lineLength: 7)
        XCTAssertEqual(grown.first?.award.clearedStarCount, 7)
        XCTAssertEqual(grown.first?.award.baseLight, 14)
        XCTAssertEqual(grown.first?.award.displayPoints, 18_000)
    }

    func testOverlappingLinesAndSquareSpendTheDistinctUnionOnce() throws {
        let squareAndRow = SkyRecipeResolution.resolve(board(["AAAAAAA", "AA....."]), lineLength: 7)
        XCTAssertEqual(squareAndRow.count, 1)
        XCTAssertEqual(Set(try XCTUnwrap(squareAndRow.first).recipes.map(\.shape)), [.line, .square])
        XCTAssertEqual(squareAndRow.first?.cleared.count, 9)
        XCTAssertEqual(squareAndRow.first?.award.displayPoints, 15_000)
        let rows = ["AAAAAAA"] + Array(repeating: "A......", count: 6)
        let intersecting = SkyRecipeResolution.resolve(board(rows), lineLength: 7)
        XCTAssertEqual(intersecting.count, 1)
        XCTAssertEqual(intersecting.first?.recipes.count, 2)
        XCTAssertEqual(intersecting.first?.cleared.count, 13)
        XCTAssertEqual(intersecting.first?.award.displayPoints, 23_000)
        XCTAssertEqual(Set(try XCTUnwrap(intersecting.first).recipes.flatMap(\.starIDs)).count, 13)
    }

    func testFallingSurvivorsCanCompleteFullLineAtCausalDepthTwo() {
        let position = board(["RRAAAAA", "RR.....", "AA....."])
        let phases = SkyRecipeResolution.resolve(position, lineLength: 7)
        XCTAssertEqual(phases.map(\.comboDepth), [1, 2])
        XCTAssertEqual(phases.map { $0.recipes.map(\.shape) }, [[.square], [.line]])
        XCTAssertEqual(phases.map(\.award.displayPoints), [5_000, 22_000])
        XCTAssertEqual(phases[1].before, phases[0].settled)
        XCTAssertEqual(phases[1].cleared.count, 7)
        XCTAssertTrue(phases[1].settled.allSatisfy { $0 == nil })
        XCTAssertEqual(SkyRecipeResolution.resolve(position).count, 1, "Retained revision two does not discover lines")
    }

    func testCommittedLineSwapConservesLightAndRestoresExactReceipt() throws {
        let position = board(["AAAAAAR", "......A"])
        var ledger = StoryScoreLedger(automaticRecipes: true)
        for _ in 0..<4 { ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4)) }
        var game = try changed(FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 3)!)) {
            $0["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(position))
            $0["score"] = 16
            $0["storyScoreLedger"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ledger))
        }
        XCTAssertTrue(game.isValidSave)
        var copy = try restored(game)
        let turn = try XCTUnwrap(game.nudge(from: Cell(0, 6), to: Cell(1, 6)))
        let replayed = try XCTUnwrap(copy.nudge(from: Cell(0, 6), to: Cell(1, 6)))
        XCTAssertEqual(turn.resolutionPhases, replayed.resolutionPhases)
        XCTAssertEqual(turn.displayAward, 11_000)
        XCTAssertEqual(game.displayScore, 31_000)
        XCTAssertEqual(game.score, 23)
        XCTAssertEqual(game.occupiedCount, 1)
        XCTAssertEqual(game, copy)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(try restored(game), game)
    }

    func testSeventhArrivalAboveGrownColumnResolvesBeforeTheNextShower() throws {
        let fresh = FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 3)!)
        let first = try XCTUnwrap(fresh.incoming.first)
        XCTAssertEqual(Set(fresh.incoming.map(\.column)).count, 5)
        var board = Array<StarfallGem?>(repeating: nil, count: 49)
        for row in 0..<6 { board[row * 7 + first.column] = .init(id: row, kind: first.kind, grown: true) }
        var ledger = StoryScoreLedger(automaticRecipes: true)
        for _ in 0..<3 { ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4)) }
        var game = try position(board, score: 12, ledger: ledger)
        XCTAssertTrue(game.isValidSave)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.count, 5)
        XCTAssertFalse(turn.arrivals[0].grew)
        XCTAssertEqual(turn.arrivals[0].cell, Cell(6, first.column))
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.line]])
        XCTAssertEqual(turn.collected, 13)
        XCTAssertEqual(turn.displayAward, 17_000)
        XCTAssertNil(game.blockedColumn)
        XCTAssertEqual(game.outcome, .playing)
        XCTAssertEqual(game.occupiedCount, 4)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(try restored(game), game)
    }

    func testLaterOverflowPreservesPartialShowerWithoutResolvingEarlierLine() throws {
        let fresh = FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 3)!)
        let first = fresh.incoming[0], blocked = fresh.incoming[1]
        XCTAssertNotEqual(first.column, blocked.column)
        let otherKinds = Jewel.allCases.filter { $0 != first.kind }
        var board = Array<StarfallGem?>(repeating: nil, count: 49)
        for row in 0..<6 { board[row * 7 + first.column] = .init(id: row, kind: first.kind, grown: true) }
        for row in 0..<7 {
            board[row * 7 + blocked.column] = .init(id: 6 + row, kind: otherKinds[row % 2], grown: row == 6)
        }
        var ledger = StoryScoreLedger(automaticRecipes: true)
        ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4))
        var game = try position(board, score: 4, ledger: ledger)
        XCTAssertTrue(game.isValidSave)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.count, 1)
        XCTAssertTrue(turn.resolutionPhases.isEmpty)
        XCTAssertEqual(turn.displayAward, 0)
        XCTAssertEqual(game.blockedColumn, blocked.column)
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertEqual(game.score, 4)
        XCTAssertEqual(game.recipes.map(\.shape), [.line], "Overflow preserves the ordered partial shower")
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(try restored(game), game)
        XCTAssertEqual(game.incoming, fresh.incoming)
        XCTAssertNil(game.letStarsFall())
    }

    func testFullLineCanFinishRoundAndItsTerminalSaveCannotReopen() throws {
        var ledger = StoryScoreLedger(automaticRecipes: true)
        for _ in 0..<29 { ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4)) }
        var game = try position(board(["AAAAAAR", "......A"]), score: 116, ledger: ledger, showers: 20)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.displayScore, 145_000)
        let turn = try XCTUnwrap(game.nudge(from: Cell(0, 6), to: Cell(1, 6)))
        XCTAssertEqual(turn.displayAward, 11_000)
        XCTAssertEqual(game.displayScore, 156_000)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertTrue(game.isValidSave)
        var copy = try restored(game)
        XCTAssertEqual(copy, game)
        XCTAssertNil(copy.letStarsFall())
        XCTAssertNil(copy.nudge(from: Cell(0, 6), to: Cell(0, 5)))
        XCTAssertNil(copy.clear(Cell(0, 6)))
        XCTAssertEqual(copy, game)
        XCTAssertEqual(copy.replay(), FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 3)!))
    }

    func testRevisionThreeRejectsManualSizeReceiptsAndUnknownRevisions() throws {
        for count in [2, 3] {
            var ledger = StoryScoreLedger(automaticRecipes: true)
            ledger.record(SkyScoreAward(baseLight: 3, clearedStarCount: count))
            XCTAssertTrue(ledger.isValid(light: 3, target: 150_000, automaticRecipes: true))
            XCTAssertFalse(ledger.isValid(light: 3, target: 150_000, automaticRecipes: true, manualClears: false))
        }
        let current = FallingSky.freshChallenge(.firstLight)
        let unknown = try changed(current) { $0["savedChallengeRevision"] = 5 }
        XCTAssertFalse(unknown.isValidSave)
        XCTAssertNil(StoryChallengeDefinition(.firstLight, revision: 5))
        for revision in [1, 2] {
            let retained = FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: revision)!)
            XCTAssertTrue(retained.supportsManualClears)
            XCTAssertFalse(retained.legalGroups.isEmpty)
            XCTAssertEqual(try restored(retained).replay(), retained)
            XCTAssertNotEqual(retained.replay(), current)
        }
        for challenge in StarfallChallenge.allCases where ![.firstLight, .ribbonCrossing, .kiteHarbor].contains(challenge) {
            XCTAssertTrue(FallingSky.freshChallenge(challenge).supportsManualClears)
        }
        XCTAssertTrue(FallingSky.freshSurvival(seed: 42).supportsManualClears)
    }

    func testShuffledSupplyHasBoundedFamilyRunsAndBalancedIndependentColumns() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let definition = try XCTUnwrap(StoryChallengeDefinition(challenge))
            let showers = (1...140).map { definition.shower(number: $0) }
            for (index, shower) in showers.enumerated() {
                XCTAssertEqual(shower.count, 5)
                XCTAssertEqual(Set(shower.map(\.column)).count, 5)
                XCTAssertGreaterThanOrEqual(Set(shower.compactMap(\.kind)).count, 3)
                XCTAssertEqual(shower.map(\.id), Array((index * 5)..<(index * 5 + 5)))
                XCTAssertEqual(shower, definition.shower(number: index + 1))
            }
            for index in stride(from: 0, to: showers.count, by: 2) {
                let kinds = showers[index..<(index + 2)].flatMap { $0.compactMap(\.kind) }
                for kind in Jewel.allCases { XCTAssertEqual(kinds.filter { $0 == kind }.count, 2) }
            }
            for index in stride(from: 0, to: showers.count, by: 7) {
                let columns = showers[index..<(index + 7)].flatMap { $0.map(\.column) }
                for column in 0..<7 { XCTAssertEqual(columns.filter { $0 == column }.count, 5) }
            }
            let kinds = showers.flatMap { $0.compactMap(\.kind) }
            for index in 2..<kinds.count {
                XCTAssertFalse(kinds[index] == kinds[index - 1] && kinds[index] == kinds[index - 2])
            }
            for kind in Jewel.allCases {
                let indices = kinds.indices.filter { kinds[$0] == kind }
                for pair in zip(indices, indices.dropFirst()) {
                    XCTAssertLessThanOrEqual(pair.1 - pair.0 - 1, 14, "Two copies and distinct endpoints bound absence")
                }
            }
            XCTAssertNotEqual(Array(showers[0].map(\.column)), Array(showers[7].map(\.column)))
            let late = definition.shower(number: Int.max / 6 - 2)
            XCTAssertEqual(late.count, 5)
            XCTAssertEqual(Set(late.map(\.id)).count, 5)
            XCTAssertTrue(late.allSatisfy { $0.id >= 0 && (0..<7).contains($0.column) })
        }
    }
}
