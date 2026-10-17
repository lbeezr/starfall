import XCTest
@testable import StarfallCore

final class WhiteConnectorTests: XCTestCase {
    // Layout-only fixtures, not production saves: the existing internal initializer
    // does not invent shower history for authored boards. Save tests use actual arrivals.
    private func fixture(_ placements: [(Cell, Jewel?)], light: Set<Cell> = [], grown: Set<Cell> = [],
                         incoming: [IncomingStar] = [.init(id: 0, kind: .violet, column: 6)]) -> FallingSky {
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        for (id, placement) in placements.enumerated() {
            let (cell, kind) = placement
            board[cell.row * 7 + cell.column] = .init(id: id, kind: kind, grown: grown.contains(cell), light: light.contains(cell))
        }
        return FallingSky(board: board, incoming: incoming, seed: 17, generation: .opalStorms)
    }

    func testSharedConnectorOffersExclusiveFamiliesAndValidTapAnchors() {
        let white = Cell(0, 1)
        let game = fixture([(Cell(0, 0), .aqua), (Cell(1, 0), .aqua), (white, nil),
                            (Cell(0, 2), .rose), (Cell(1, 2), .rose)], light: [white])
        let aqua = game.group(at: Cell(0, 0)), rose = game.group(at: Cell(0, 2))
        XCTAssertEqual(aqua.intersection(rose), [white])
        XCTAssertEqual(game.value(of: aqua), 3); XCTAssertEqual(game.value(of: rose), 3)
        XCTAssertEqual(game.legalGroups.count, 2)
        for group in game.legalGroups {
            XCTAssertFalse(game.gem(at: group[0])!.isLight)
            XCTAssertEqual(game.group(at: group[0]), Set(group))
            XCTAssertEqual(Set(group.compactMap { game.gem(at: $0)?.kind }).count, 1)
        }
        // A connector earlier in row order must not become an invalid bot/rotor anchor.
        let firstWhite = fixture([(Cell(0, 0), nil), (Cell(0, 1), .aqua), (Cell(0, 2), .aqua)], light: [Cell(0, 0)])
        XCTAssertEqual(firstWhite.legalGroups.first?.first, Cell(0, 1))
    }

    func testConnectorConsumptionForeclosesOtherFamilyAndWhiteTapIsFree() {
        let white = Cell(0, 1)
        var game = fixture([(Cell(0, 0), .aqua), (Cell(1, 0), .aqua), (white, nil),
                            (Cell(0, 2), .rose), (Cell(1, 2), .rose)], light: [white])
        let before = game
        XCTAssertNil(game.clear(white)); XCTAssertEqual(game, before)
        let result = game.clear(Cell(0, 0))!
        XCTAssertEqual(result.collected, 3); XCTAssertTrue(result.cleared.contains(white))
        XCTAssertEqual(game.gem(at: Cell(0, 2))?.kind, .rose)
        XCTAssertEqual(game.value(of: game.group(at: Cell(0, 2))), 2)
        XCTAssertTrue(game.legalGroups.isEmpty)
        XCTAssertEqual(result.forecast, before.incoming)
        XCTAssertEqual(game.incoming, before.incoming)
    }

    func testHoldingBridgeCanEarnMoreWithTheSameShowerAndClearCount() {
        let white = Cell(1, 1)
        let game = fixture([(Cell(0, 0), .rose), (Cell(1, 0), .amber),
                            (Cell(0, 1), .aqua), (white, nil),
                            (Cell(0, 2), .aqua), (Cell(1, 2), .amber)], light: [white],
                           incoming: [.init(id: 0, kind: .amber, column: 2)])
        XCTAssertEqual(game.value(of: game.group(at: Cell(0, 1))), 3)
        XCTAssertEqual(game.value(of: game.group(at: Cell(1, 0))), 3)
        var useNow = game
        XCTAssertEqual(useNow.clear(Cell(0, 1))?.collected, 3)
        useNow.letStarsFall()
        XCTAssertEqual(useNow.score, 3); XCTAssertEqual(useNow.value(of: useNow.group(at: Cell(0, 2))), 2)
        var hold = game
        hold.letStarsFall()
        XCTAssertEqual(hold.clear(Cell(1, 0))?.collected, 4)
        XCTAssertEqual(hold.score, 4)
        XCTAssertEqual(useNow.turns, hold.turns); XCTAssertEqual(useNow.occupiedCount, hold.occupiedCount)
    }

    func testSmallerConnectorClearProtectsAColumnWhereLargestLoses() {
        let white = Cell(0, 1)
        let placements: [(Cell, Jewel?)] = [
            (Cell(0, 0), .aqua), (Cell(1, 0), .aqua), (Cell(2, 0), .mint),
            (Cell(3, 0), .amber), (Cell(4, 0), .violet), (Cell(5, 0), .mint), (Cell(6, 0), .amber),
            (white, nil), (Cell(0, 2), .rose), (Cell(1, 2), .rose), (Cell(2, 2), .rose)]
        let incoming: [IncomingStar] = [.init(id: 0, kind: .rose, column: 0)]
        let game = fixture(placements, light: [white], incoming: incoming)
        var smaller = game, larger = game
        XCTAssertEqual(smaller.clear(Cell(0, 0))?.collected, 3)
        XCTAssertEqual(larger.clear(Cell(0, 2))?.collected, 4)
        smaller.letStarsFall(); larger.letStarsFall()
        XCTAssertFalse(smaller.isOver); XCTAssertTrue(larger.isOver)
        XCTAssertEqual(larger.blockedColumn, 0)
        var controlPlacements = placements
        controlPlacements[7].1 = .mint
        let control = fixture(controlPlacements, incoming: incoming)
        XCTAssertEqual(control.value(of: control.group(at: Cell(0, 0))), 2,
                       "An ordinary replacement has no life-saving left clear")
    }

    func testNoDiagonalWraparoundMixedFamilyOrWhiteOnlyClear() {
        let diagonal = fixture([(Cell(0, 0), .aqua), (Cell(0, 1), nil),
                                (Cell(0, 2), .mint), (Cell(1, 2), .aqua)], light: [Cell(0, 1)])
        XCTAssertEqual(diagonal.group(at: Cell(0, 0)), [Cell(0, 0), Cell(0, 1)])
        XCTAssertTrue(diagonal.legalGroups.isEmpty)
        let edge = fixture([(Cell(0, 0), .aqua), (Cell(0, 6), nil), (Cell(1, 6), .aqua)], light: [Cell(0, 6)])
        XCTAssertEqual(edge.group(at: Cell(0, 0)), [Cell(0, 0)])
        var whites = fixture([(Cell(0, 0), nil), (Cell(0, 1), nil), (Cell(0, 2), nil)],
                             light: [Cell(0, 0), Cell(0, 1), Cell(0, 2)])
        XCTAssertTrue(whites.legalGroups.isEmpty)
        let before = whites; XCTAssertNil(whites.clear(Cell(0, 1))); XCTAssertEqual(whites, before)
    }

    func testWhiteArrivalsStackCannotGrowAndCanOverflowAFullColumn() {
        var game = FallingSky(board: Array(repeating: nil, count: 49), incoming: [
            .init(id: 0, kind: nil, column: 0, light: true), .init(id: 1, kind: nil, column: 0, light: true)], generation: .opalStorms)
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, false])
        XCTAssertEqual(game.occupiedCount, 2); XCTAssertTrue(game.isValidSave)
        XCTAssertTrue(game.board.compactMap { $0 }.allSatisfy { $0.isLight && !$0.isDark && !$0.grown && $0.value == 1 })
        var full = fixture((0..<7).map { (Cell($0, 0), $0 == 6 ? nil : Jewel.aqua) }, light: [Cell(6, 0)],
                           incoming: [.init(id: 0, kind: nil, column: 0, light: true)])
        full.letStarsFall()
        XCTAssertTrue(full.isOver); XCTAssertEqual(full.blockedColumn, 0)
        XCTAssertFalse(full.gem(at: Cell(6, 0))!.grown)
    }

    func testDarknessAndOrdinaryGrowthRetainTheirRoles() {
        let blocked = fixture([(Cell(0, 0), .aqua), (Cell(0, 1), nil), (Cell(1, 1), nil)], light: [Cell(1, 1)])
        XCTAssertTrue(blocked.isGrowthBlocked(at: Cell(0, 0)))
        XCTAssertFalse(blocked.isGrowthBlocked(at: Cell(1, 1)))
        var beside = fixture([(Cell(0, 0), .aqua), (Cell(1, 0), .aqua), (Cell(0, 1), nil), (Cell(0, 2), nil)], light: [Cell(0, 1)])
        XCTAssertEqual(beside.clear(Cell(0, 0))?.collected, 3)
        XCTAssertEqual(beside.darkStarsCleared, 1)
        var diagonal = fixture([(Cell(0, 0), .aqua), (Cell(1, 0), .aqua), (Cell(0, 1), nil),
                                (Cell(0, 2), .mint), (Cell(1, 2), nil)], light: [Cell(0, 1)])
        diagonal.clear(Cell(0, 0)); XCTAssertEqual(diagonal.darkStarsCleared, 0)
        var growth = FallingSky(board: Array(repeating: nil, count: 49), incoming: [
            .init(id: 0, kind: .aqua, column: 0), .init(id: 1, kind: nil, column: 1, light: true),
            .init(id: 2, kind: .aqua, column: 0)], generation: .opalStorms)
        growth.letStarsFall()
        XCTAssertTrue(growth.gem(at: Cell(0, 0))!.grown); XCTAssertTrue(growth.isValidSave)
    }

    func testValidWhiteSaveRestoresIdentityAndDeterministicContinuation() throws {
        var game = FallingSky(board: Array(repeating: nil, count: 49), incoming: [
            .init(id: 0, kind: .aqua, column: 0), .init(id: 1, kind: nil, column: 1, light: true),
            .init(id: 2, kind: .aqua, column: 2)], seed: 17, generation: .opalStorms)
        XCTAssertTrue(game.isValidSave)
        var incomingRestored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertTrue(incomingRestored.incoming[1].isLight)
        game.letStarsFall(); incomingRestored.letStarsFall()
        XCTAssertEqual(game, incomingRestored); XCTAssertTrue(game.isValidSave)
        var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertTrue(restored.gem(at: Cell(0, 1))!.isLight)
        XCTAssertFalse(restored.gem(at: Cell(0, 1))!.isDark)
        XCTAssertEqual(game.clear(Cell(0, 0))?.collected, 3)
        XCTAssertEqual(restored.clear(Cell(0, 0))?.collected, 3)
        for _ in 0..<10 where !game.isOver {
            game.letStarsFall(); restored.letStarsFall()
            XCTAssertEqual(game, restored); XCTAssertTrue(game.isValidSave)
            if let cell = game.legalGroups.first?.first {
                game.clear(cell); restored.clear(cell)
                XCTAssertEqual(game, restored); XCTAssertTrue(game.isValidSave)
            }
        }
    }

    func testMissingFlagsStayLegacyAndMalformedWhiteStatesReject() throws {
        let dark = try JSONDecoder().decode(StarfallGem.self, from: Data(#"{"id":0,"grown":false}"#.utf8))
        XCTAssertTrue(dark.isDark); XCTAssertFalse(dark.isLight)
        var game = FallingSky(board: Array(repeating: nil, count: 49), incoming: [.init(id: 0, kind: nil, column: 0, light: true)], generation: .opalStorms)
        game.letStarsFall()
        let data = try JSONEncoder().encode(game)
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var board = try XCTUnwrap(fields["board"] as? [Any])
        var first = try XCTUnwrap(board[0] as? [String: Any])
        first["grown"] = true; board[0] = first; fields["board"] = board
        XCTAssertFalse(try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields)).isValidSave)
        first["grown"] = false; first["kind"] = Jewel.aqua.rawValue; board[0] = first; fields["board"] = board
        XCTAssertFalse(try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields)).isValidSave)
    }
    func testSeededSelectiveOpalClearRetainsARealizedFollowUpChoice() throws {
        let original = ConstellationFixture.opalChoice.game()
        var selective = original, flood = original
        let path = [Cell(3,1), Cell(3,2), Cell(2,3), Cell(2,4), Cell(2,5)]
        XCTAssertEqual(selective.clearConstellation(path)?.collected, 5)
        XCTAssertEqual(flood.clear(Cell(0,6))?.collected, 5)
        XCTAssertEqual(selective.board.compactMap { $0 }.filter(\.isLight).count, 1)
        XCTAssertEqual(flood.board.compactMap { $0 }.filter(\.isLight).count, 0)
        XCTAssertEqual(selective.incoming, original.incoming)
        XCTAssertEqual(flood.incoming, original.incoming)
        for deliversForecast in [false, true] {
            var left = selective, right = flood
            if deliversForecast { left.letStarsFall(); right.letStarsFall() }
            let bestLeft = try XCTUnwrap(left.legalGroups.max { left.value(of: Set($0)) < left.value(of: Set($1)) }?.first)
            let bestRight = try XCTUnwrap(right.legalGroups.max { right.value(of: Set($0)) < right.value(of: Set($1)) }?.first)
            XCTAssertEqual(left.clear(bestLeft)?.collected, 4)
            XCTAssertEqual(right.clear(bestRight)?.collected, 3)
            XCTAssertEqual(left.score - original.score, 9)
            XCTAssertEqual(right.score - original.score, 8)
            XCTAssertTrue(left.isValidSave); XCTAssertTrue(right.isValidSave)
            XCTAssertFalse(left.isOver); XCTAssertFalse(right.isOver)
        }
    }

}
