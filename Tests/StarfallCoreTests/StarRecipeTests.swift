import XCTest
@testable import StarfallCore

final class StarRecipeTests: XCTestCase {
    private func sky(_ rows: [String]) -> FallingSky {
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        let kinds: [Character: Jewel] = ["A": .aqua, "S": .amber, "P": .mint, "T": .rose, "N": .violet]
        var id = 0
        for (row, text) in rows.enumerated() {
            precondition(text.count == 7)
            for (column, key) in text.enumerated() where key != "." {
                board[row*7+column] = .init(id: id, kind: kinds[key]); id += 1
            }
        }
        return FallingSky(board: board, incoming: [.init(id: 100, kind: .rose, column: 6)])
    }

    func testConstellationCanStartOnAnyColoredStarWhileCompletionStillNeedsFiveOrSquare() {
        let five = sky(["AAAAA.."]), square = sky(["AA.....","AA....."])
        XCTAssertTrue(five.canStartConstellation(at: Cell(0,0)))
        XCTAssertTrue(square.canStartConstellation(at: Cell(0,0)))
        XCTAssertTrue(sky(["AAA...."]).canStartConstellation(at: Cell(0,0)))
        XCTAssertNil(sky(["AAA...."]).constellationCells(along:[Cell(0,0),Cell(0,1),Cell(0,2)]))
        XCTAssertFalse(square.canStartConstellation(at: Cell(6,6)))
        var board = square.board
        board[0] = .init(id:0,kind:nil,light:true)
        let white = FallingSky(board:board,incoming:square.incoming)
        XCTAssertFalse(white.canStartConstellation(at:Cell(0,0)), "Choose a colored family before crossing Opal")
    }

    func testSquareSpendsExactFourAndPreservesExtraIngredientsAndForecast() throws {
        var game = sky(["AAAA...", "AASPN.."])
        let before = game, recipe = try XCTUnwrap(game.recipes.first { $0.shape == .square })
        XCTAssertEqual(recipe.cells.count, 4)
        let turn = try XCTUnwrap(game.activate(recipe))
        XCTAssertEqual(turn.collected, 4)
        XCTAssertEqual(Set(before.board.compactMap { $0?.id }).subtracting(recipe.starIDs), Set(game.board.compactMap { $0?.id }))
        XCTAssertEqual(before.incoming, game.incoming); XCTAssertEqual(before.turns, game.turns)
        XCTAssertEqual(before.starsLanded, game.starsLanded)
        XCTAssertFalse(game.recipes.contains(recipe), "Stale identity cannot reactivate")
        let saved = game
        XCTAssertNil(game.activate(recipe)); XCTAssertEqual(game, saved)
    }

    func testCrossUsesAsymmetricGravityAndOrthogonalDarkRemoval() throws {
        var game = sky([".SAS...", ".AAA...", ".TAP...", "..N...."])
        let cross = try XCTUnwrap(game.recipes.first { $0.shape == .cross })
        let old = game
        XCTAssertEqual(game.activate(cross)?.collected, 5)
        XCTAssertEqual(game.gem(at: Cell(0,2))?.kind, .violet)
        XCTAssertEqual(game.gem(at: Cell(1,1))?.kind, .rose)
        XCTAssertEqual(game.gem(at: Cell(1,3))?.kind, .mint)
        XCTAssertEqual(game.incoming, old.incoming)
    }

    func testForkHasTwoExclusiveExactChoices() throws {
        let game = sky(["AAA....", "AAA...."])
        let recipes = game.recipes.filter { $0.shape == .square }
        XCTAssertEqual(recipes.count, 2)
        XCTAssertEqual(recipes[0].starIDs.intersection(recipes[1].starIDs).count, 2)
        var left = game, right = game
        left.activate(recipes[0]); right.activate(recipes[1])
        XCTAssertFalse(left.recipes.contains(recipes[1])); XCTAssertFalse(right.recipes.contains(recipes[0]))
        XCTAssertNotEqual(left.board, right.board)
        XCTAssertEqual(left.score, right.score)
    }

    func testNudgeCreatesRecipeWhileKeepingGrowthIdentityAndNoAutomaticClear() throws {
        var game = sky(["AAP....", "APA...."])
        XCTAssertTrue(game.recipes.isEmpty)
        let before = game
        XCTAssertNotNil(game.nudge(from: Cell(1,2), to: Cell(1,1)))
        XCTAssertEqual(game.recipes.filter { $0.shape == .square }.count, 1)
        XCTAssertEqual(game.score, 0); XCTAssertEqual(game.occupiedCount, before.occupiedCount)
        XCTAssertEqual(game.incoming, before.incoming)
        XCTAssertEqual(game.turns, before.turns)
        XCTAssertEqual(Set(game.board.compactMap { $0?.id }), Set(before.board.compactMap { $0?.id }))
    }

    func testEmptySpaceNudgeDropsAndRejectsInvalidMoves() {
        var game = sky(["..AA...", "..S....", "..A...."])
        let top = game.gem(at: Cell(2,2))
        XCTAssertNotNil(game.nudge(from: Cell(2,2), to: Cell(2,1)))
        XCTAssertEqual(game.gem(at: Cell(0,1)), top)
        for pair in [(Cell(0,2),Cell(1,3)),(Cell(0,0),Cell(0,1)),(Cell(-1,1),Cell(-1,2)),(Cell(0,2),Cell(-1,2)),(Cell(0,2),Cell(0,7)),(Cell(0,2),Cell(7,2))] {
            let old = game
            XCTAssertNil(game.nudge(from: pair.0, to: pair.1)); XCTAssertEqual(game, old)
        }
    }

    func testSelectionValidatesWalkDistinctCountAndSquareException() {
        let game = sky(["AAAPP..", "AAPP..."])
        XCTAssertNotNil(game.selectedClearCells(along: [Cell(0,0),Cell(0,1),Cell(1,1),Cell(1,0)]))
        XCTAssertNil(game.selectedClearCells(along: [Cell(0,0),Cell(0,1),Cell(0,2),Cell(1,1)]), "Four non-square stars do not clear")
        XCTAssertNotNil(game.selectedClearCells(along: [Cell(0,0),Cell(0,1),Cell(0,2),Cell(1,1),Cell(1,0)]))
        XCTAssertNil(game.selectedClearCells(along: Array(repeating: Cell(0,0), count: 5)))
        XCTAssertNil(game.selectedClearCells(along: [Cell(0,0),Cell(0,4)]))
        XCTAssertNil(game.selectedClearCells(along: Array(repeating: Cell(0,0), count: 197)))
    }

    func testRecipeCountsActualIngredientsKeepsGrownValueAndDissolvesAdjacentDarkStar() throws {
        var board: [StarfallGem?] = Array(repeating:nil,count:49)
        board[0] = .init(id:0,kind:.aqua,grown:true)
        board[1] = .init(id:1,kind:.aqua)
        board[7] = .init(id:2,kind:.aqua)
        board[8] = .init(id:3,kind:.aqua)
        board[2] = .init(id:4,kind:nil)
        var game = FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)])
        let recipe = try XCTUnwrap(game.recipes.first)
        XCTAssertEqual(recipe.starIDs.count,4)
        let turn = try XCTUnwrap(game.activate(recipe))
        XCTAssertEqual(turn.collected,5)
        XCTAssertEqual(turn.cleared.count,5)
        XCTAssertEqual(game.darkStarsCleared,1)
        XCTAssertEqual(game.occupiedCount,0)
    }

    func testFirstLightRejectsExtraActionsWithoutMutation() {
        var game = FallingSky(challenge: .firstLight)
        game.letStarsFall()
        let old = game
        XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
        XCTAssertNil(game.clearSelected([Cell(0,0)])); XCTAssertEqual(game, old)
    }

    func testSeededActionsRoundTripValidateAndPreservePreviewContinuation() throws {
        for seed in 0..<30 {
            var game = FallingSky(seed: UInt64(seed))
            for _ in 0..<12 where !game.isOver {
                game.letStarsFall()
                if let recipe = game.recipes.first { game.activate(recipe) }
                else if let first = game.legalGroups.first?.first { game.clear(first) }
                for row in 0..<7 {
                    if let column = (0..<6).first(where: { game.canNudge(from: Cell(row,$0), to: Cell(row,$0+1)) }) {
                        game.nudge(from: Cell(row,column), to: Cell(row,column+1)); break
                    }
                }
                XCTAssertTrue(game.isValidSave)
                var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                XCTAssertEqual(restored, game)
                var next = game; next.letStarsFall(); restored.letStarsFall()
                XCTAssertEqual(next, restored)
            }
        }
    }

    func testTrimBeatsWholeClearOverTwoImmediateActions() throws {
        let base = SkyTechniqueExample.trim.game()
        let recipe = try XCTUnwrap(base.recipes.first { $0.shape == .square && Set($0.cells).contains(Cell(2,0)) && Set($0.cells).contains(Cell(1,1)) })
        var selected=base, whole=base
        selected.activate(recipe); whole.clear(recipe.cells[0])
        func best(_ g:FallingSky)->Int { g.legalGroups.map { cells in var copy=g;return copy.clear(cells[0])!.collected }.max() ?? 0 }
        XCTAssertGreaterThan(selected.score+best(selected),whole.score+best(whole))
    }

    func testBankAndForkOrdersHaveDifferentConsequences() throws {
        let bank=SkyTechniqueExample.bank.game()
        let square=try XCTUnwrap(bank.recipes.first { $0.shape == .square && $0.cells.contains(Cell(0,0)) })
        let cross=try XCTUnwrap(bank.recipes.first { $0.shape == .cross && $0.cells.contains(Cell(3,2)) })
        var squareFirst=bank, crossFirst=bank
        squareFirst.activate(square); crossFirst.activate(cross)
        XCTAssertNotEqual(squareFirst.recipes.contains { $0.id == cross.id },crossFirst.recipes.contains { $0.id == square.id })
        let fork=SkyTechniqueExample.fork.game()
        let a=try XCTUnwrap(fork.recipes.first { $0.shape == .square && $0.cells.contains(Cell(1,0)) })
        let b=try XCTUnwrap(fork.recipes.first { $0.shape == .cross })
        XCTAssertFalse(a.starIDs.isDisjoint(with:b.starIDs))
        var first=fork,second=fork;first.activate(a);second.activate(b)
        XCTAssertNotEqual(first.board,second.board)
        func best(_ game: FallingSky) -> Int { game.legalGroups.map { cells in var copy=game; return copy.clear(cells[0])!.collected }.max() ?? 0 }
        XCTAssertGreaterThan(first.score+best(first),second.score+best(second), "The smaller fork preserves the useful follow-up")
    }

    func testRelayCreatesSecondRecipeWithoutAutomaticallySpendingIt() throws {
        var game=SkyTechniqueExample.relay.game()
        let square=try XCTUnwrap(game.recipes.first { $0.cells.contains(Cell(0,0)) })
        let old=Set(game.recipes.map(\.id))
        XCTAssertEqual(game.activate(square)?.collected,4)
        let next=try XCTUnwrap(game.recipes.first { !old.contains($0.id) })
        XCTAssertEqual(game.score,4)
        XCTAssertEqual(game.activate(next)?.collected,4)
        XCTAssertEqual(game.score,8); XCTAssertEqual(game.occupiedCount,0)
    }

    func testDoubleSetupMakesTwoDisjointNewRecipes() throws {
        var game=SkyTechniqueExample.doubleSetup.game()
        let first=try XCTUnwrap(game.recipes.first { $0.shape == .cross && $0.cells.contains(Cell(0,1)) })
        let old=Set(game.recipes.map(\.id)); game.activate(first)
        let created=game.recipes.filter { !old.contains($0.id) }
        XCTAssertTrue(created.contains { a in created.contains { b in a.id != b.id && a.starIDs.isDisjoint(with:b.starIDs) } })
        let lower=try XCTUnwrap(created.first { $0.cells.contains(Cell(0,1)) })
        let upper=try XCTUnwrap(created.first { $0.cells.contains(Cell(3,3)) })
        var lowerFirst=game, upperFirst=game
        lowerFirst.activate(lower); upperFirst.activate(upper)
        XCTAssertFalse(lowerFirst.recipes.contains { $0.id == upper.id })
        XCTAssertTrue(upperFirst.recipes.contains { $0.id == lower.id })
    }

    func testDropInAndRescueUseTheExistingClearAndDarkAdjacency() throws {
        var drop=SkyTechniqueExample.dropIn.game()
        XCTAssertTrue(drop.recipes.isEmpty)
        XCTAssertEqual(drop.clear(Cell(0,2))?.collected,3)
        XCTAssertFalse(drop.recipes.isEmpty)
        var missedDrop=SkyTechniqueExample.dropIn.game()
        XCTAssertEqual(missedDrop.clear(Cell(0,0))?.collected,3)
        XCTAssertTrue(missedDrop.recipes.isEmpty)
        var rescue=SkyTechniqueExample.rescue.game()
        var largerFirst=rescue
        let banked=try XCTUnwrap(rescue.recipes.first)
        XCTAssertEqual(largerFirst.clear(Cell(0,5))?.collected,4)
        XCTAssertEqual(rescue.gem(at:Cell(0,3))?.isDark,true)
        XCTAssertEqual(rescue.clear(Cell(0,0))?.collected,3)
        XCTAssertNil(rescue.gem(at:Cell(0,3)))
        XCTAssertEqual(rescue.darkStarsCleared,1)
        XCTAssertNil(rescue.gem(at:Cell(5,0)), "Rescue lowers the crowded column")
        XCTAssertNotNil(largerFirst.gem(at:Cell(5,0)), "The larger remote clear leaves that column full-height")
        XCTAssertEqual(largerFirst.gem(at:Cell(0,3))?.isDark,true)
        XCTAssertTrue(rescue.recipes.contains { $0.id == banked.id }, "The useful next clear survives")
    }
}

extension StarRecipeTests {
    func testOpalRecipesShareCurrentFamilyRulesAndDoNotTreatDuskAsOpal() throws {
        var board:[StarfallGem?]=Array(repeating:nil,count:49)
        board[0] = .init(id:0,kind:.aqua);board[1] = .init(id:1,kind:nil,light:true)
        board[7] = .init(id:2,kind:.aqua,grown:true);board[8] = .init(id:3,kind:.aqua)
        var game=FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)])
        let recipe=try XCTUnwrap(game.recipes.first)
        XCTAssertEqual(recipe.starIDs.count,4)
        XCTAssertEqual(game.activate(recipe)?.collected,5)
        board[1] = .init(id:1,kind:nil)
        game=FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)])
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.canNudge(from:Cell(0,0),to:Cell(0,1)))
        board[0] = .init(id:0,kind:nil,light:true)
        game=FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)])
        XCTAssertTrue(game.canNudge(from:Cell(0,0),to:Cell(0,1)),"Dusk and Opal have different identities")
    }
    func testCurrentGenerationNudgesPreserveValidatedContinuationAndNoRetiredGravity() throws {
        for seed in 0..<30 {
            var game=FallingSky(seed:UInt64(seed),generation:.current,duskRule:.feeding)
            for _ in 0..<18 where !game.isOver {
                game.letStarsFall()
                if let first=game.legalGroups.first?.first { game.clear(first) }
                let before=game
                outer: for row in 0..<7 { for col in 0..<6 {
                    if let turn=game.nudge(from:Cell(row,col),to:Cell(row,col+1)) {
                        XCTAssertEqual(turn.exchange?.from,Cell(row,col))
                        XCTAssertEqual(game.incoming,before.incoming)
                        XCTAssertEqual(game.cadenceStep,before.cadenceStep)
                        break outer
                    }
                } }
                XCTAssertTrue(game.isValidSave)
                var restored=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
                var next=game;next.letStarsFall();restored.letStarsFall()
                XCTAssertEqual(next,restored)
                XCTAssertFalse(restored.board.contains { $0?.gravityKind != nil })
            }
        }
    }
}

extension StarRecipeTests {
    func testFeedingDuskChangesRecipeRewardAndExchangeReservesInfluenceColumns() throws {
        var board:[StarfallGem?]=Array(repeating:nil,count:49)
        board[0] = .init(id:0,kind:.aqua);board[1] = .init(id:1,kind:nil,light:true)
        board[7] = .init(id:2,kind:.aqua);board[8] = .init(id:3,kind:.aqua)
        board[2] = .init(id:4,kind:nil)
        let base=FallingSky(board:board,incoming:[.init(id:100,kind:.rose,column:6)]).adoptingFeedingDusk()
        var cleared=base
        let recipe=try XCTUnwrap(base.recipes.first)
        XCTAssertEqual(cleared.activate(recipe)?.collected,3)
        XCTAssertEqual(cleared.lostStarlight,1);XCTAssertEqual(cleared.darkStarsCleared,1)
        var moved=base
        let turn=try XCTUnwrap(moved.nudge(from:Cell(0,2),to:Cell(0,3)))
        XCTAssertTrue(turn.duskAffectedColumns.contains(1))
        XCTAssertFalse(moved.isDrained(at:Cell(0,1)))
        XCTAssertEqual(moved.score,0);XCTAssertEqual(moved.lostStarlight,0)
        XCTAssertEqual(moved.incoming,base.incoming)
    }
}


extension StarRecipeTests {
    func testFourDirectionExchangesPreserveIdentityAndNeverAutoClear() throws {
        let authored = sky(["AAAAAAA","ASAPAAA","AAAAAAA"])
        var saved = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(authored)) as? [String:Any])
        saved["turns"] = 10
        let before = try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:saved))
        XCTAssertTrue(before.isValidSave)
        for to in [Cell(1,1),Cell(1,3),Cell(0,2),Cell(2,2)] {
            var game = before
            let source = try XCTUnwrap(game.gem(at:Cell(1,2)))
            let target = try XCTUnwrap(game.gem(at:to))
            let turn = try XCTUnwrap(game.nudge(from:Cell(1,2),to:to))
            XCTAssertEqual(game.gem(at:to),source)
            XCTAssertEqual(game.gem(at:Cell(1,2)),target)
            XCTAssertTrue(turn.cleared.isEmpty); XCTAssertEqual(game.score,before.score)
            XCTAssertEqual(game.incoming,before.incoming); XCTAssertEqual(game.turns,before.turns)
            XCTAssertTrue(game.isValidSave)
            var restored = try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
            game.letStarsFall(); restored.letStarsFall()
            XCTAssertEqual(restored,game)
        }
    }

    func testUpIntoEmptySpaceFallsBackButStillReportsExchange() throws {
        var game = sky(["A......"])
        let before = game
        let turn = try XCTUnwrap(game.nudge(from:Cell(0,0),to:Cell(1,0)))
        XCTAssertNotNil(turn.exchange)
        XCTAssertEqual(game,before, "Gravity remains authoritative after the upward move")
    }
}
