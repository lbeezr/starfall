import XCTest
@testable import StarfallCore

final class GameTests: XCTestCase {
    private var checker: [Jewel] { (0..<49).map { Jewel(rawValue: (($0 / 7) + ($0 % 7)) % 5)! } }
    func testSeedsAreStableAndPlayable() {
        for seed in UInt64(0)..<200 {
            let first = Game(seed: seed)
            XCTAssertEqual(first, Game(seed: seed)); XCTAssertTrue(first.hasMove)
            XCTAssertEqual(first.board.count, 49); XCTAssertTrue(first.isValidSave)
        }
    }
    func testOrthogonalOnlyAndInvalidTapDoesNotSpendMove() {
        var game = Game(board: checker)
        let before = game
        XCTAssertEqual(game.group(at: Cell(0, 0)).count, 1)
        XCTAssertNil(game.tap(Cell(0, 0))); XCTAssertEqual(game, before)
        XCTAssertNil(game.tap(Cell(-1, 0))); XCTAssertNil(game.tap(Cell(7, 7)))
    }
    func testClearGravityAndRefill() {
        var board = checker
        board[0] = .rose; board[7] = .rose; board[14] = .rose
        board[46] = .mint; board[47] = .mint; board[48] = .mint
        var game = Game(board: board)
        let turn = game.tap(Cell(0, 0))!
        XCTAssertEqual(turn.cleared.count, 3)
        XCTAssertEqual(game.score, 3); XCTAssertEqual(game.moves, 17)
        XCTAssertEqual(game.jewel(at: Cell(0, 0)), board[21])
        XCTAssertEqual(game.jewel(at: Cell(1, 0)), board[28])
        XCTAssertEqual(game.board.count, 49)
    }
    func testWinTakesPriorityOnFinalMoveAndLocksInput() {
        var game = Game(board: Array(repeating: .mint, count: 49), moves: 1, score: 21)
        XCTAssertNotNil(game.tap(Cell(0, 0))); XCTAssertEqual(game.outcome, .won)
        let won = game; XCTAssertNil(game.tap(Cell(0, 0))); XCTAssertEqual(game, won)
    }
    func testLossAndNoFurtherMoves() {
        var board = checker; board[0] = .rose; board[1] = .rose; board[2] = .rose
        var game = Game(board: board, moves: 1)
        XCTAssertNotNil(game.tap(Cell(0, 0))); XCTAssertEqual(game.outcome, .lost)
        XCTAssertNil(game.tap(Cell(0, 0)))
    }
    func testSaveRoundTripAndFutureRandomness() throws {
        var game = Game(seed: 42)
        let data = try JSONEncoder().encode(game)
        var restored = try JSONDecoder().decode(Game.self, from: data)
        XCTAssertEqual(game, restored)
        XCTAssertEqual(game.legalGroups, restored.legalGroups)
        for row in 0..<7 { for col in 0..<7 {
            if game.group(at: Cell(row, col)).count >= 3 {
                game.tap(Cell(row, col)); restored.tap(Cell(row, col))
                XCTAssertEqual(game, restored); return
            }
        } }
        XCTFail("Expected playable board")
    }
    func testEveryLiveBoardHasMoveAcrossManyGames() {
        for seed in UInt64(0)..<100 {
            var game = Game(seed: seed)
            while game.outcome == .playing {
                XCTAssertTrue(game.hasMove)
                let cell = (0..<49).map { Cell($0 / 7, $0 % 7) }.first { game.group(at: $0).count >= 3 }!
                XCTAssertNotNil(game.tap(cell)); XCTAssertTrue(game.isValidSave)
            }
        }
    }
    func testDiagonalDoesNotConnect() {
        var board = checker
        board[0] = .mint; board[8] = .mint; board[16] = .mint
        let game = Game(board: board)
        XCTAssertEqual(game.group(at: Cell(0, 0)), [Cell(0, 0)])
    }
    func testLegalGroupsAreUniqueAndOrderedAcrossDisconnectedSameColorGroups() {
        var board = Array(repeating: Jewel.aqua, count: 49)
        let first = [Cell(0, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)]
        let last = [Cell(5, 5), Cell(5, 6), Cell(6, 6)]
        let excluded = [Cell(3, 3), Cell(3, 4), Cell(6, 0)]
        for cell in first + last { board[cell.row * 7 + cell.column] = .rose }
        board[3 * 7 + 3] = .mint; board[3 * 7 + 4] = .mint
        board[6 * 7] = .amber
        let aqua = (0..<49).map { Cell($0 / 7, $0 % 7) }
            .filter { !(first + last + excluded).contains($0) }
        let game = Game(board: board)

        XCTAssertEqual(game.legalGroups, [first, aqua, last])
        XCTAssertEqual(Set(game.legalGroups.flatMap { $0 }).count, 46)
        XCTAssertTrue(game.hasMove)
    }
    func testLegalGroupsHandleWholeBoardDeadBoardAndTerminalBoard() {
        let cells = (0..<49).map { Cell($0 / 7, $0 % 7) }
        let wholeBoard = Game(board: Array(repeating: .mint, count: 49))
        XCTAssertEqual(wholeBoard.legalGroups, [cells])
        XCTAssertTrue(Game(board: checker).legalGroups.isEmpty)
        XCTAssertFalse(Game(board: checker).hasMove)

        var terminal = Game(board: wholeBoard.board, moves: 0, score: 70)
        XCTAssertEqual(terminal.legalGroups, [cells])
        XCTAssertNil(terminal.tap(cells[0]))
    }
    func testEveryEnumeratedGroupIsOneEquivalentMoveAndEnumerationDoesNotChangeRandomness() throws {
        for seed in UInt64(0)..<30 {
            let game = Game(seed: seed)
            let groups = game.legalGroups
            let uniqueCells = Set(groups.flatMap { $0 })
            XCTAssertEqual(uniqueCells.count, groups.reduce(0) { $0 + $1.count })
            for cells in groups {
                var firstTap = game, lastTap = game
                let first = try XCTUnwrap(cells.first), last = try XCTUnwrap(cells.last)
                XCTAssertEqual(firstTap.tap(first)?.cleared, Set(cells))
                XCTAssertEqual(lastTap.tap(last)?.cleared, Set(cells))
                XCTAssertEqual(firstTap, lastTap)
            }
            XCTAssertEqual(game, Game(seed: seed))
            let allClearable = Set((0..<49).map { Cell($0 / 7, $0 % 7) }
                .filter { game.group(at: $0).count >= 3 })
            XCTAssertEqual(uniqueCells, allClearable)
        }
    }
    func testDeadBoardRecoveryIsFreeAndBounded() {
        var board = checker
        board[0] = .rose; board[7] = .rose; board[14] = .rose
        var game = Game(board: board, seed: 1)
        let turn = game.tap(Cell(0, 0))!
        XCTAssertTrue(turn.reshuffled); XCTAssertTrue(game.hasMove)
        XCTAssertEqual(game.moves, 17); XCTAssertEqual(game.score, 3)
    }
    func testGeneratorGoldenValues() {
        var random = SeededRandom(seed: 0)
        XCTAssertEqual(random.next(), 0xE220A8397B1DCDAF)
        XCTAssertEqual(random.next(), 0x6E789E6AA1B965F4)
        XCTAssertEqual(random.next(), 0x06C45D188009454F)
    }
    func testRestoreAfterRandomnessAdvanced() throws {
        var game = Game(seed: 93)
        for _ in 0..<3 {
            let cell = (0..<49).map { Cell($0 / 7, $0 % 7) }.first { game.group(at: $0).count >= 3 }!
            game.tap(cell)
        }
        var restored = try JSONDecoder().decode(Game.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(game, restored)
        let next = (0..<49).map { Cell($0 / 7, $0 % 7) }.first { game.group(at: $0).count >= 3 }!
        game.tap(next); restored.tap(next); XCTAssertEqual(game, restored)
    }
    func testMalformedSaveRejected() {
        let game = Game(board: checker, moves: -1)
        XCTAssertFalse(game.isValidSave)
    }
    func testSaveValidationRejectsImpossibleScoresAndMoveCounts() {
        let board = Game(seed: 42).board
        let invalid: [(moves: Int, score: Int)] = [
            (-1, 3), (19, 0), (Int.min, 0), (Int.max, 0),
            (18, -1), (18, 3), (17, 0), (17, 2), (17, 50),
            (16, 5), (16, 99), (0, 53), (0, 119), (0, Int.max)
        ]
        for fixture in invalid {
            XCTAssertFalse(Game(board: board, moves: fixture.moves, score: fixture.score).isValidSave,
                           "Accepted impossible save: \(fixture)")
        }
        let valid: [(moves: Int, score: Int)] = [
            (18, 0), (17, 3), (17, 49), (16, 70), (0, 54), (0, 69), (0, 70), (0, 118)
        ]
        for fixture in valid {
            XCTAssertTrue(Game(board: board, moves: fixture.moves, score: fixture.score).isValidSave,
                          "Rejected valid rule bounds: \(fixture)")
        }
    }
    func testSaveValidationChecksBoardSizeBeforeTraversingAndAllowsDeadTerminalBoards() throws {
        let data = try JSONEncoder().encode(Game(seed: 42))
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        for count in [0, 48, 50] {
            var malformed = object
            malformed["board"] = Array(repeating: Jewel.rose.rawValue, count: count)
            let decoded = try JSONDecoder().decode(Game.self, from: JSONSerialization.data(withJSONObject: malformed))
            XCTAssertFalse(decoded.isValidSave)
        }
        XCTAssertFalse(Game(board: checker).isValidSave)
        XCTAssertTrue(Game(board: checker, moves: 0, score: 54).isValidSave)
        XCTAssertTrue(Game(board: checker, moves: 0, score: 70).isValidSave)
    }
    /// Contract used by native relaunch tests to distinguish saved and fresh boards.
    func testNativePersistenceFixture() {
        var saved = Game(seed: 42)
        XCTAssertEqual(saved.group(at: Cell(1, 1)).count, 3)
        XCTAssertEqual(Game(seed: 43).group(at: Cell(1, 1)).count, 2)
        saved.tap(Cell(1, 1))
        XCTAssertEqual(saved.group(at: Cell(1, 2)).count, 4)
        saved.tap(Cell(1, 2))
        XCTAssertEqual(saved.score, 7)
        XCTAssertEqual(saved.moves, 16)
    }

    func testRestoreEveryTurnThroughTerminalState() throws {
        var uninterrupted = Game(seed: 42)
        var restored = uninterrupted
        while uninterrupted.outcome == .playing {
            restored = try JSONDecoder().decode(Game.self, from: JSONEncoder().encode(restored))
            XCTAssertTrue(restored.isValidSave)
            XCTAssertEqual(restored, uninterrupted)
            let cell = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
                .first { uninterrupted.group(at: $0).count >= 3 })
            uninterrupted.tap(cell)
            restored.tap(cell)
            XCTAssertEqual(restored, uninterrupted)
        }
        restored = try JSONDecoder().decode(Game.self, from: JSONEncoder().encode(restored))
        XCTAssertTrue(restored.isValidSave)
        XCTAssertEqual(restored, uninterrupted)
        XCTAssertNil(restored.tap(Cell(0, 0)))
    }

    /// Contract for DEBUG native endgame replays, including both terminal save states.
    func testNativeTerminalReplayFixtures() throws {
        let fixtures: [(UInt64, Cell, Int, Int, Outcome)] = [
            (6, Cell(5, 3), 70, 2, .won), (0, Cell(0, 0), 64, 0, .lost)
        ]
        for (seed, finalCell, score, moves, outcome) in fixtures {
            var game = Game(seed: seed)
            var finalTap: Cell?
            for _ in 0..<Game.startingMoves {
                let cell = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
                    .first { game.group(at: $0).count >= 3 })
                var next = game
                next.tap(cell)
                if next.outcome != .playing { finalTap = cell; break }
                game = next
            }
            XCTAssertEqual(finalTap, finalCell)
            XCTAssertEqual(game.outcome, .playing)
            XCTAssertNotNil(game.tap(finalCell))
            XCTAssertEqual(game.outcome, outcome)
            XCTAssertEqual(game.score, score)
            XCTAssertEqual(game.moves, moves)
            var restored = try JSONDecoder().decode(Game.self, from: JSONEncoder().encode(game))
            XCTAssertTrue(restored.isValidSave)
            XCTAssertEqual(restored, game)
            XCTAssertNil(restored.tap(finalCell))
            XCTAssertEqual(restored, game)
        }
    }

}
