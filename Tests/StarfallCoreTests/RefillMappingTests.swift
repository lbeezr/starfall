import XCTest
@testable import StarfallCore

final class RefillMappingTests: XCTestCase {
    private var checker: [Jewel] {
        (0..<(Game.side * Game.side)).map {
            Jewel(rawValue: ($0 / Game.side + $0 % Game.side) % 5)!
        }
    }

    func testInterleavedClearsPreserveExactSourcesDespiteRepeatedColors() {
        // This structural fixture isolates mapping from legal-group discovery.
        // Every color is identical, so color matching cannot establish identity.
        let settled = Game(board: Array(repeating: .aqua, count: 49))
        let cleared: Set<Cell> = [Cell(0, 0), Cell(2, 0), Cell(5, 0), Cell(6, 1)]
        let mapping = RefillMapping(turn: Turn(cleared: cleared, reshuffled: false), settled: settled)
        let firstColumn = mapping.pieces.filter { $0.destination.column == 0 }
        XCTAssertEqual(firstColumn.map(\.origin), [
            .survivor(source: Cell(1, 0)), .survivor(source: Cell(3, 0)),
            .survivor(source: Cell(4, 0)), .survivor(source: Cell(6, 0)),
            .refill, .refill, .refill
        ])
        let secondColumn = mapping.pieces.filter { $0.destination.column == 1 }
        XCTAssertEqual(secondColumn.last?.origin, .refill)
        for piece in secondColumn.dropLast() {
            XCTAssertEqual(piece.origin, .survivor(source: piece.destination))
        }
        for piece in mapping.pieces where piece.destination.column >= 2 {
            XCTAssertEqual(piece.origin, .survivor(source: piece.destination))
        }
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .refill }.count, cleared.count)
    }

    func testLegalTurnMapsEachFinalJewelAndOnlyVerticalSurvivors() throws {
        var board = checker
        for row in 0..<3 { board[row * Game.side] = .rose }
        // Keep an untouched legal group so this fixture does not need recovery.
        board[46] = .mint; board[47] = .mint; board[48] = .mint
        var game = Game(board: board)
        let old = game
        let turn = try XCTUnwrap(game.tap(Cell(0, 0)))
        XCTAssertFalse(turn.reshuffled)
        let mapping = RefillMapping(turn: turn, settled: game)
        XCTAssertEqual(mapping.pieces.count, 49)
        XCTAssertEqual(Set(mapping.pieces.map(\.destination)).count, 49)
        XCTAssertEqual(mapping.pieces.map(\.destination), (0..<7).flatMap { column in
            (0..<7).map { Cell($0, column) }
        })
        var sources: Set<Cell> = []
        for piece in mapping.pieces {
            XCTAssertEqual(piece.jewel, game.jewel(at: piece.destination))
            switch piece.origin {
            case let .survivor(source):
                XCTAssertEqual(source.column, piece.destination.column)
                XCTAssertGreaterThanOrEqual(source.row, piece.destination.row)
                XCTAssertFalse(turn.cleared.contains(source))
                XCTAssertTrue(sources.insert(source).inserted)
                XCTAssertEqual(piece.jewel, old.jewel(at: source))
            case .refill:
                XCTAssertEqual(piece.destination.column, 0)
                XCTAssertGreaterThanOrEqual(piece.destination.row, 4)
            case .recovery:
                XCTFail("Fixture has a preserved legal group")
            }
        }
        XCTAssertEqual(sources.count, 49 - turn.cleared.count)
    }

    func testFullBoardClearContainsOnlyNewRefillsEvenOnWinningTurn() throws {
        var game = Game(board: Array(repeating: .mint, count: 49), moves: 1, score: 21)
        let turn = try XCTUnwrap(game.tap(Cell(0, 0)))
        XCTAssertEqual(game.outcome, .won)
        let mapping = RefillMapping(turn: turn, settled: game)
        XCTAssertEqual(mapping.pieces.count, 49)
        XCTAssertTrue(mapping.pieces.allSatisfy { $0.origin == .refill })
        XCTAssertEqual(mapping.pieces.first?.destination, Cell(0, 0))
        XCTAssertEqual(mapping.pieces.last?.destination, Cell(6, 6))
        for piece in mapping.pieces {
            XCTAssertEqual(piece.jewel, game.jewel(at: piece.destination))
        }
    }

    func testActualFreeRecoveryMarksExactlyThreeOverwrittenDestinations() throws {
        var board = checker
        for row in 0..<3 { board[row * Game.side] = .rose }
        var game = Game(board: board, seed: 1)
        let old = game
        let turn = try XCTUnwrap(game.tap(Cell(0, 0)))
        XCTAssertTrue(turn.reshuffled)
        let mapping = RefillMapping(turn: turn, settled: game)
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .recovery }.map(\.destination),
                       [Cell(0, 0), Cell(0, 1), Cell(0, 2)])
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .refill }.count, 3)
        XCTAssertEqual(game.score, 3)
        XCTAssertEqual(game.moves, 17)
        for piece in mapping.pieces {
            XCTAssertEqual(piece.jewel, game.jewel(at: piece.destination))
            if case let .survivor(source) = piece.origin {
                XCTAssertEqual(piece.jewel, old.jewel(at: source))
            }
        }
    }

    func testRecoveryIsAReplacementEvenIfColorIsUnchangedOrRefillWasOverwritten() {
        // Structural recovery fixture, not a legal tap on this monochrome board.
        let old = Game(board: Array(repeating: .rose, count: 49))
        let settled = old
        // Column zero has no survivors: recovery overwrites an ordinary refill there.
        // Columns one and two had same-color survivors: they are still replacements.
        let cleared = Set((0..<7).map { Cell($0, 0) })
        let mapping = RefillMapping(turn: Turn(cleared: cleared, reshuffled: true), settled: settled)
        for column in 0..<3 {
            let piece = mapping.pieces.first { $0.destination == Cell(0, column) }
            XCTAssertEqual(piece?.origin, .recovery)
            XCTAssertEqual(piece?.jewel, .rose)
            XCTAssertEqual(piece?.jewel, old.jewel(at: Cell(0, column)))
        }
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .refill }.count, 6)
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .survivor(source: Cell(1, 1)) }.count, 1)
    }

    func testClearSetInsertionOrderCannotChangePresentationOrder() {
        let cells = [Cell(0, 0), Cell(2, 0), Cell(5, 0), Cell(6, 1)]
        let settled = Game(board: checker)
        let forward = RefillMapping(turn: Turn(cleared: Set(cells), reshuffled: false), settled: settled)
        let reverse = RefillMapping(turn: Turn(cleared: Set(cells.reversed()), reshuffled: false), settled: settled)
        XCTAssertEqual(forward, reverse)
    }

    func testRepeatedMappingPreservesCommittedGameAndFutureSeededTurns() throws {
        var presented = Game(seed: 42)
        var control = presented
        for _ in 0..<6 {
            let cell = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
                .first { control.group(at: $0).count >= 3 })
            let turn = try XCTUnwrap(presented.tap(cell))
            XCTAssertNotNil(control.tap(cell))
            let committed = presented
            let first = RefillMapping(turn: turn, settled: presented)
            for _ in 0..<3 {
                XCTAssertEqual(first, RefillMapping(turn: turn, settled: presented))
            }
            // Game equality includes its private saved RNG state as well as board/score/moves.
            XCTAssertEqual(presented, committed)
            XCTAssertEqual(presented, control)
        }
    }
}
