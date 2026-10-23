import XCTest
@testable import StarfallCore

final class StoryFourStarLineTests: XCTestCase {
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

    private func restored(_ game: FallingSky) throws -> FallingSky {
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(restored, game)
        XCTAssertTrue(restored.isValidSave)
        return restored
    }

    /// Account for the unused opening light with a valid automatic clear receipt.
    /// Fixtures change neither the definition nor its announced shower.
    private func position(_ board: [StarfallGem?], revision: Int = 4) throws -> FallingSky {
        let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision))
        let score = definition.initialLight - board.compactMap { $0 }.reduce(0) { $0 + $1.value }
        var ledger = StoryScoreLedger(automaticRecipes: true)
        ledger.record(.init(baseLight: score, clearedStarCount: score))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky(definition: definition))) as? [String: Any])
        fields["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(board))
        fields["score"] = score
        fields["storyScoreLedger"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ledger))
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    func testCurrentDefinitionChangesOnlyTheLineThresholdAndRetainsHistoricalReplays() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let previous = try XCTUnwrap(StoryChallengeDefinition(challenge, revision: 3))
            let current = try XCTUnwrap(StoryChallengeDefinition(challenge))
            XCTAssertEqual(current.revision, 4)
            XCTAssertEqual(current.seed, previous.seed)
            XCTAssertEqual(current.palette, previous.palette)
            XCTAssertEqual(current.balance, previous.balance)
            XCTAssertEqual(current.target, previous.target)
            XCTAssertEqual(current.initialBoard, previous.initialBoard)
            for number in 1...140 {
                XCTAssertEqual(current.shower(number: number), previous.shower(number: number))
                XCTAssertEqual(current.suppliedLight(after: number), previous.suppliedLight(after: number))
            }
            for revision in 1...4 {
                let opening = FallingSky(definition: StoryChallengeDefinition(challenge, revision: revision)!)
                XCTAssertEqual(opening.automaticLineLength, revision == 4 ? 4 : revision == 3 ? 7 : nil)
                XCTAssertEqual(opening.supportsManualClears, revision < 3)
                XCTAssertEqual(opening.automaticShowerDelay, challenge == .firstLight ? 6 : 4)
                XCTAssertEqual(try restored(opening).replay(), opening)
                var played = opening
                _ = played.nudge(from: Cell(1, 1), to: Cell(1, 2))
                _ = played.letStarsFall()
                XCTAssertEqual(try restored(played).replay(), opening)
            }
            XCTAssertEqual(FallingSky.freshChallenge(challenge).challengeRevision, 4)
            XCTAssertNil(FallingSky(challenge: challenge).automaticLineLength)
        }
        XCTAssertNil(FallingSky.freshSurvival(seed: 42).automaticLineLength)
    }

    func testEveryFourThroughSevenStarRunIsOneMaximalLineAtEveryOffset() throws {
        for count in 4...7 {
            for offset in 0...(7 - count) {
                for horizontal in [true, false] {
                    var position = Array<StarfallGem?>(repeating: nil, count: 49)
                    let cells = (offset..<(offset + count)).map { horizontal ? Cell(3, $0) : Cell($0, 4) }
                    for (id, cell) in cells.enumerated() { position[cell.row * 7 + cell.column] = .init(id: id, kind: .mint) }
                    let recipes = StarRecipe.find(in: position, lineLength: 4)
                    XCTAssertEqual(recipes.count, 1)
                    XCTAssertEqual(recipes.first?.shape, .line)
                    XCTAssertEqual(recipes.first?.cells, cells)
                    XCTAssertEqual(recipes.first?.starIDs.count, count)
                    let phases = SkyRecipeResolution.resolve(position, lineLength: 4)
                    XCTAssertEqual(phases.count, 1)
                    XCTAssertEqual(phases.first?.award.clearedStarCount, count)
                    XCTAssertEqual(phases.first?.award.displayPoints, (2 * count - 3) * 1_000)
                }
            }
        }
    }

    func testThreeGrownStarsGapsMixedFamiliesAndDiagonalsDoNotBecomeLines() {
        for position in [board(["AAA...."], grown: true),
                         board(["A......", "A......", "A......"], grown: true),
                         board(["AA.AA.."]), board(["AAARRR."]),
                         board(["A......", ".A.....", "..A....", "...A..."])] {
            XCTAssertTrue(StarRecipe.find(in: position, lineLength: 4).isEmpty)
            XCTAssertTrue(SkyRecipeResolution.resolve(position, lineLength: 4).isEmpty)
        }
        let grown = SkyRecipeResolution.resolve(board(["AAAA..."], grown: true), lineLength: 4)
        XCTAssertEqual(grown.first?.award.clearedStarCount, 4)
        XCTAssertEqual(grown.first?.award.baseLight, 8)
        XCTAssertEqual(grown.first?.award.displayPoints, 9_000)
        for shape in [board(["AA.....", "AA....."]), board([".A.....", "AAA....", ".A....."])] {
            XCTAssertEqual(StarRecipe.find(in: shape, lineLength: 4), StarRecipe.find(in: shape))
        }
    }

    func testOverlappingFourStarLinesAndSquareSpendTheirUnionOnce() throws {
        let phases = SkyRecipeResolution.resolve(board(["AAAA...", "AA.....", "A......", "A......"]), lineLength: 4)
        let phase = try XCTUnwrap(phases.first)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phase.recipes.filter { $0.shape == .line }.count, 2)
        XCTAssertEqual(phase.recipes.filter { $0.shape == .square }.count, 1)
        XCTAssertEqual(phase.cleared.count, 8)
        XCTAssertEqual(Set(phase.recipes.flatMap(\.starIDs)).count, 8)
        XCTAssertEqual(phase.award.baseLight, 8)
        XCTAssertEqual(phase.award.displayPoints, 13_000)
        XCTAssertTrue(phase.settled.allSatisfy { $0 == nil })
    }

    func testFallingSurvivorsCompleteFiveStarLineAtTheUnchangedCausalDepth() {
        let position = board(["RRAAA..", "RR.....", "AA....."])
        let phases = SkyRecipeResolution.resolve(position, lineLength: 4)
        XCTAssertEqual(phases.map(\.comboDepth), [1, 2])
        XCTAssertEqual(phases.map { $0.recipes.map(\.shape) }, [[.square], [.line]])
        XCTAssertEqual(phases.map(\.award.displayPoints), [5_000, 14_000])
        XCTAssertEqual(phases[1].before, phases[0].settled)
        XCTAssertTrue(phases[1].settled.allSatisfy { $0 == nil })
        XCTAssertEqual(SkyRecipeResolution.resolve(position, lineLength: 7).count, 1)
    }

    func testCommittedFourStarSwapUsesSavedThresholdAndRestoresItsExactReceipt() throws {
        for revision in [3, 4] {
            var game = try position(board(["AAAR...", "...A..."]), revision: revision)
            XCTAssertTrue(game.isValidSave)
            let before = game
            var copy = try restored(game)
            let turn = try XCTUnwrap(game.nudge(from: Cell(0, 3), to: Cell(1, 3)))
            let restoredTurn = try XCTUnwrap(copy.nudge(from: Cell(0, 3), to: Cell(1, 3)))
            XCTAssertEqual(restoredTurn.resolutionPhases, turn.resolutionPhases)
            XCTAssertEqual(copy, game)
            XCTAssertEqual(turn.displayAward, revision == 4 ? 5_000 : 0)
            XCTAssertEqual(turn.award?.clearedStarCount, revision == 4 ? 4 : nil)
            XCTAssertEqual(game.incoming, before.incoming)
            XCTAssertEqual(game.turns, before.turns)
            XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, game.starsLanded)
            XCTAssertEqual(try restored(game), game)
        }
    }

    func testSaveValidationRejectsPendingFourStarLineOnlyForCurrentRules() throws {
        let pending = board(["AAAA..."])
        XCTAssertTrue(try position(pending, revision: 3).isValidSave)
        XCTAssertFalse(try position(pending).isValidSave)
    }

    func testFreshLanternCanEarnAnActualFourStarLineAfterTwoOpeningSwaps() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        let forecast = game.incoming
        XCTAssertEqual(try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2))).displayAward, 15_000)
        var copy = try restored(game)
        let turn = try XCTUnwrap(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        let copiedTurn = try XCTUnwrap(copy.nudge(from: Cell(0, 0), to: Cell(0, 1)))
        XCTAssertEqual(copiedTurn.resolutionPhases, turn.resolutionPhases)
        XCTAssertEqual(copy, game)
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        XCTAssertEqual(turn.resolutionPhases.first?.recipes.map(\.shape), [.line])
        XCTAssertEqual(turn.resolutionPhases.first?.recipes.first?.cells, (1...4).map { Cell(0, $0) })
        XCTAssertEqual(turn.award?.clearedStarCount, 4)
        XCTAssertEqual(turn.displayAward, 5_000)
        XCTAssertEqual(game.displayScore, 20_000)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.incoming, forecast)
        XCTAssertEqual(try restored(game), game)
    }

    func testFourthArrivalAboveGrownTripleResolvesOnlyAfterTheCompleteShower() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        let first = try XCTUnwrap(opening.incoming.first)
        var position = Array<StarfallGem?>(repeating: nil, count: 49)
        for row in 0..<3 { position[row * 7 + first.column] = .init(id: row, kind: first.kind, grown: true) }
        var game = try self.position(position)
        XCTAssertTrue(game.isValidSave)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.forecast, opening.incoming)
        XCTAssertEqual(turn.arrivals.count, 5)
        XCTAssertFalse(turn.arrivals[0].grew)
        XCTAssertEqual(turn.arrivals[0].cell, Cell(3, first.column))
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.line]])
        XCTAssertEqual(turn.collected, 7)
        XCTAssertEqual(turn.displayAward, 8_000)
        XCTAssertEqual(game.occupiedCount, 4)
        XCTAssertNil(game.blockedColumn)
        XCTAssertEqual(game.outcome, .playing)
        XCTAssertEqual(try restored(game), game)
    }

    func testPartialOverflowKeepsItsUnresolvedFourStarLineAndTerminalSave() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        let first = opening.incoming[0], blocked = opening.incoming[1]
        let otherKinds = Jewel.allCases.filter { $0 != first.kind }
        var position = Array<StarfallGem?>(repeating: nil, count: 49)
        for row in 0..<3 { position[row * 7 + first.column] = .init(id: row, kind: first.kind, grown: true) }
        for row in 0..<7 {
            position[row * 7 + blocked.column] = .init(id: row + 3, kind: otherKinds[row % 2], grown: row == 6)
        }
        var game = try self.position(position)
        XCTAssertTrue(game.isValidSave)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.count, 1)
        XCTAssertTrue(turn.resolutionPhases.isEmpty)
        XCTAssertEqual(turn.displayAward, 0)
        XCTAssertEqual(game.blockedColumn, blocked.column)
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertEqual(game.recipes.map(\.shape), [.line])
        XCTAssertEqual(try restored(game), game)
        XCTAssertEqual(game.incoming, opening.incoming)
        XCTAssertNil(game.letStarsFall())
        XCTAssertEqual(game.replay(), opening)
    }
}
