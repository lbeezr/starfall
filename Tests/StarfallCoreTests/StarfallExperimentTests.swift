import XCTest
@testable import StarfallCore

final class StarfallExperimentTests: XCTestCase {
    private func shower(_ kinds: [Jewel], columns: [Int] = [0, 0, 0]) -> [IncomingStar] {
        zip(kinds, columns).enumerated().map { IncomingStar(id: $0.offset, kind: $0.element.0, column: $0.element.1) }
    }
    private var empty: [StarfallGem?] { Array(repeating: nil, count: 49) }

    func testEmptyStartAndInvalidInputNeverAdvanceTheForecast() {
        var game = StarfallExperiment(seed: 42)
        let before = game
        XCTAssertEqual(game.occupiedCount, 0); XCTAssertTrue(StarfallExperiment.showerSizes.contains(game.incoming.count))
        XCTAssertTrue(game.isValidSave)
        XCTAssertNil(game.clear(Cell(0, 0))); XCTAssertNil(game.clear(Cell(-1, 7)))
        XCTAssertEqual(game, before)
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(turn.arrivals.map(\.star), before.incoming)
        XCTAssertEqual(game.turns, 1); XCTAssertEqual(game.starsLanded, before.incoming.count)
        XCTAssertEqual(game.score, 0); XCTAssertTrue(game.isValidSave)
    }

    func testMatchingArrivalGrowsOnceAndTheNextStarStacks() {
        var game = StarfallExperiment(board: empty, incoming: shower([.rose, .rose, .rose]))
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, true, false])
        XCTAssertEqual(game.gem(at: Cell(0, 0))?.value, 2)
        XCTAssertEqual(game.gem(at: Cell(1, 0))?.value, 1)
        XCTAssertEqual(game.occupiedCount, 2)
        XCTAssertEqual(game.score, 0, "Growth is collected later, never scored on arrival")
        XCTAssertEqual(game.legalGroups, [[Cell(0, 0), Cell(1, 0)]])
        XCTAssertEqual(game.clear(Cell(0, 0))?.collected, 3, "A grown jewel counts as two toward a clear")
    }

    func testTwoSmallJewelsOrOneGrownJewelCannotClear() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose)
        board[1] = .init(id: 1, kind: .rose)
        board[2] = .init(id: 2, kind: .mint, grown: true)
        var game = StarfallExperiment(board: board, incoming: shower([.aqua, .aqua, .aqua]))
        let before = game
        XCTAssertNil(game.clear(Cell(0, 0))); XCTAssertNil(game.clear(Cell(0, 2)))
        XCTAssertTrue(game.legalGroups.isEmpty); XCTAssertEqual(game, before)
    }

    func testDifferentColorsStackWithoutReplacingExistingJewels() {
        var game = StarfallExperiment(board: empty, incoming: shower([.rose, .aqua, .mint]))
        game.letStarsFall()
        XCTAssertEqual((0..<3).compactMap { game.gem(at: Cell($0, 0))?.kind }, [.rose, .aqua, .mint])
        XCTAssertEqual(game.occupiedCount, 3)
    }

    func testForecastVisitsEveryColumnBeforeRepeating() {
        var game = StarfallExperiment(seed: 42)
        var columns: [Int] = []
        while columns.count < 21 {
            columns += game.incoming.map(\.column)
            game.letStarsFall()
        }
        for start in stride(from: 0, to: 21, by: 7) {
            XCTAssertEqual(Set(columns[start..<(start+7)]), Set(0..<7))
        }
    }

    func testClearScoresGrownValuesAndGravityPreservesSurvivorIdentity() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose, grown: true)
        board[7] = .init(id: 1, kind: .rose)
        board[14] = .init(id: 2, kind: .rose)
        board[21] = .init(id: 3, kind: .mint, grown: true)
        var game = StarfallExperiment(board: board, incoming: shower([.aqua, .violet, .amber], columns: [6, 6, 6]))
        let turn = game.clear(Cell(0, 0))!
        XCTAssertEqual(turn.cleared, [Cell(0, 0), Cell(1, 0), Cell(2, 0)])
        XCTAssertEqual(turn.collected, 4); XCTAssertEqual(game.score, 4)
        XCTAssertEqual(turn.settled[0], board[21]); XCTAssertEqual(game.gem(at: Cell(0, 0)), board[21])
        XCTAssertEqual(game.turns, 0); XCTAssertTrue(turn.arrivals.isEmpty)
        XCTAssertTrue((1..<7).allSatisfy { game.gem(at: Cell($0, 0)) == nil }, "There is no automatic refill")
    }

    func testOrthogonalOnlyAndEmptyCellsNeverConnect() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose)
        board[8] = .init(id: 1, kind: .rose)
        board[16] = .init(id: 2, kind: .rose)
        let game = StarfallExperiment(board: board, incoming: shower([.aqua, .aqua, .aqua]))
        XCTAssertEqual(game.group(at: Cell(0, 0)), [Cell(0, 0)])
        XCTAssertTrue(game.group(at: Cell(6, 6)).isEmpty)
        XCTAssertTrue(game.legalGroups.isEmpty)
    }

    func testOverflowStopsAtTheBlockedStarAndLocksBothActions() {
        var board = empty
        for row in 0..<7 { board[row * 7] = .init(id: row, kind: row.isMultiple(of: 2) ? .mint : .rose) }
        var game = StarfallExperiment(board: board, incoming: shower([.aqua, .rose, .amber], columns: [1, 0, 2]))
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.count, 1)
        XCTAssertEqual(turn.blockedColumn, 0); XCTAssertTrue(game.isOver)
        XCTAssertNotNil(game.gem(at: Cell(0, 1))); XCTAssertNil(game.gem(at: Cell(0, 2)))
        let ended = game
        XCTAssertNil(game.letStarsFall()); XCTAssertNil(game.clear(Cell(0, 0)))
        XCTAssertEqual(game, ended)
    }

    func testFullColumnCanAcceptOneMatchingGrowthBeforeOverflowing() {
        var board = empty
        for row in 0..<7 { board[row * 7] = .init(id: row, kind: .mint) }
        var game = StarfallExperiment(board: board, incoming: shower([.mint, .mint, .mint]))
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.count, 1); XCTAssertTrue(turn.arrivals[0].grew)
        XCTAssertEqual(game.gem(at: Cell(6, 0))?.value, 2)
        XCTAssertEqual(game.blockedColumn, 0)
    }

    func testClearingBeforeTheShowerCanPreventForecastOverflow() {
        var board = empty
        for row in 0..<7 { board[row * 7] = .init(id: row, kind: row < 3 ? .rose : .mint) }
        let forecast = shower([.aqua, .violet, .amber])
        var waiting = StarfallExperiment(board: board, incoming: forecast)
        waiting.letStarsFall(); XCTAssertTrue(waiting.isOver)
        var clearing = StarfallExperiment(board: board, incoming: forecast)
        clearing.clear(Cell(0, 0))
        XCTAssertEqual(clearing.incoming, forecast)
        XCTAssertEqual(clearing.occupiedCount, 4)
        clearing.letStarsFall()
        XCTAssertFalse(clearing.isOver); XCTAssertEqual(clearing.occupiedCount, 7)
        XCTAssertEqual(clearing.score, 3)
    }

    func testClearLeavesForecastAndFutureRandomSequenceUntouched() {
        var game = StarfallExperiment(seed: 5)
        for _ in 0..<20 where game.legalGroups.isEmpty && !game.isOver { game.letStarsFall() }
        let cell = game.legalGroups.first!.first!
        var waiting = game
        let preview = game.incoming, showers = game.turns
        let turn = game.clear(cell)!
        XCTAssertEqual(turn.forecast, preview); XCTAssertTrue(turn.arrivals.isEmpty)
        XCTAssertEqual(game.incoming, preview); XCTAssertEqual(game.turns, showers)
        game.letStarsFall(); waiting.letStarsFall()
        XCTAssertFalse(waiting.isOver)
        XCTAssertEqual(game.incoming, waiting.incoming)
    }

    func testSeededShowersVaryAcrossAllFourSizesAndHaveUniqueIDs() {
        var sizes: Set<Int> = []
        for seed in UInt64(0)..<50 {
            var game = StarfallExperiment(seed: seed)
            var ids: Set<Int> = []
            for _ in 0..<10 {
                sizes.insert(game.incoming.count)
                for star in game.incoming { XCTAssertTrue(ids.insert(star.id).inserted) }
                game.letStarsFall()
                XCTAssertTrue(game.isValidSave)
            }
        }
        XCTAssertEqual(sizes, [1, 2, 3, 5])
    }

    func testDarkStarsStackWithoutGrowingOrJoiningColorMatches() {
        var game = StarfallExperiment(board: empty, incoming: [
            .init(id: 0, kind: nil, column: 0), .init(id: 1, kind: nil, column: 0),
            .init(id: 2, kind: .rose, column: 0)])
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, false, false])
        XCTAssertEqual(game.occupiedCount, 3)
        XCTAssertTrue(game.group(at: Cell(0, 0)).isEmpty)
        XCTAssertEqual(game.gem(at: Cell(0, 0))?.value, 0)
        let before = game
        XCTAssertNil(game.clear(Cell(0, 0))); XCTAssertEqual(game, before)
    }

    func testDarkStarBlocksOnlyOrthogonalGrowthWithoutShrinkingExistingJewels() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose)
        board[1] = .init(id: 1, kind: nil)
        board[2] = .init(id: 2, kind: .mint, grown: true)
        var game = StarfallExperiment(board: board, incoming: [
            .init(id: 3, kind: .rose, column: 0), .init(id: 4, kind: .rose, column: 0)])
        XCTAssertTrue(game.isGrowthBlocked(at: Cell(0, 0)))
        XCTAssertTrue(game.isGrowthBlocked(at: Cell(0, 2)))
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, true], "The new top is diagonal to the dark star, so it can grow")
        XCTAssertEqual(game.gem(at: Cell(0, 0))?.value, 1)
        XCTAssertEqual(game.gem(at: Cell(1, 0))?.value, 2)
        XCTAssertEqual(game.gem(at: Cell(0, 2))?.value, 2)
        XCTAssertFalse(game.isGrowthBlocked(at: Cell(1, 0)))
        XCTAssertEqual(game.legalGroups.first, [Cell(0, 0), Cell(1, 0)], "Shaded jewels still match")
    }

    func testDarkStarAffectsLaterArrivalsInTheSameShower() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose)
        var game = StarfallExperiment(board: board, incoming: [
            .init(id: 1, kind: nil, column: 1), .init(id: 2, kind: .rose, column: 0)])
        let turn = game.letStarsFall()!
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, false])
        XCTAssertEqual(game.gem(at: Cell(1, 0))?.kind, .rose)
    }

    func testAdjacentClearDissolvesDarkStarsOnceWithoutAChainOrExtraScore() {
        var board = empty
        for column in 0..<3 { board[column] = .init(id: column, kind: .rose) }
        board[3] = .init(id: 3, kind: nil)
        board[10] = .init(id: 4, kind: nil) // diagonal: survives, then falls
        board[7] = .init(id: 5, kind: .mint, grown: true)
        var game = StarfallExperiment(board: board, incoming: shower([.aqua, .aqua, .aqua]))
        let forecast = game.incoming
        let turn = game.clear(Cell(0, 0))!
        XCTAssertEqual(turn.cleared, [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(0, 3)])
        XCTAssertEqual(game.darkStarsCleared, 1); XCTAssertEqual(game.score, 3)
        XCTAssertEqual(game.gem(at: Cell(0, 3))?.id, 4)
        XCTAssertEqual(game.gem(at: Cell(0, 0)), board[7])
        XCTAssertEqual(game.incoming, forecast); XCTAssertEqual(game.turns, 0)
        XCTAssertFalse(game.isGrowthBlocked(at: Cell(0, 0)))
    }

    func testOneDarkStarTouchingSeveralGroupCellsIsCountedOnce() {
        var board = empty
        board[0] = .init(id: 0, kind: .rose)
        board[1] = .init(id: 1, kind: .rose)
        board[7] = .init(id: 2, kind: .rose)
        board[8] = .init(id: 3, kind: nil)
        var game = StarfallExperiment(board: board, incoming: shower([.aqua, .aqua, .aqua]))
        XCTAssertEqual(game.clear(Cell(0, 0))?.cleared.count, 4)
        XCTAssertEqual(game.darkStarsCleared, 1); XCTAssertEqual(game.score, 3)
        XCTAssertEqual(game.occupiedCount, 0)
    }

    func testShadedFullColumnCannotAbsorbAnArrival() {
        var board = empty
        for row in 0..<7 {
            board[row * 7] = .init(id: row, kind: .mint)
            board[row * 7 + 1] = .init(id: 7 + row, kind: row == 6 ? nil : .aqua)
        }
        var game = StarfallExperiment(board: board, incoming: [.init(id: 14, kind: .mint, column: 0)])
        XCTAssertTrue(game.letStarsFall()!.arrivals.isEmpty)
        XCTAssertEqual(game.blockedColumn, 0)
    }

    func testDarkStarsStartAtSixthShowerThenOccurEveryFourToSixShowers() {
        for seed in UInt64(0)..<50 {
            var game = StarfallExperiment(seed: seed)
            var lastDark: Int?
            for number in 1...25 where !game.isOver {
                let dark = game.incoming.filter(\.isDark)
                XCTAssertLessThanOrEqual(dark.count, 1)
                if !dark.isEmpty {
                    if let lastDark { XCTAssertTrue((4...6).contains(number - lastDark)) }
                    else { XCTAssertEqual(number, 6) }
                    lastDark = number
                }
                game.letStarsFall()
                while let cell = game.legalGroups.first?.first, !game.isOver { game.clear(cell) }
                XCTAssertTrue(game.isValidSave)
            }
            XCTAssertNotNil(lastDark)
        }
    }

    func testReplayAndSaveRestorePreserveFutureShowers() throws {
        for seed in UInt64(0)..<50 {
            var game = StarfallExperiment(seed: seed)
            var replay = StarfallExperiment(seed: seed)
            for _ in 0..<50 where !game.isOver {
                if let cell = game.legalGroups.first?.first { game.clear(cell); replay.clear(cell) }
                else { game.letStarsFall(); replay.letStarsFall() }
                XCTAssertEqual(game, replay); XCTAssertTrue(game.isValidSave)
                let restored = try JSONDecoder().decode(StarfallExperiment.self, from: JSONEncoder().encode(game))
                XCTAssertEqual(game, restored)
                replay = restored
            }
        }
    }

    func testEveryDarkFrequencyHonorsItsFirstArrivalAndGap() {
        for frequency in StarfallBalance.DarkStarFrequency.allCases {
            for seed in UInt64(0)..<20 {
                var game = StarfallExperiment(seed: seed, balance: .init(darkStars: frequency))
                var lastDark: Int?
                for number in 1...30 where !game.isOver {
                    let dark = game.incoming.filter(\.isDark)
                    XCTAssertLessThanOrEqual(dark.count, 1)
                    if !dark.isEmpty {
                        guard let gap = frequency.showerGap else { XCTFail("Dark stars are off"); break }
                        if let lastDark { XCTAssertTrue(gap.contains(number - lastDark)) }
                        else { XCTAssertEqual(number, gap.upperBound) }
                        lastDark = number
                    }
                    game.letStarsFall()
                    while let cell = game.legalGroups.first?.first, !game.isOver { game.clear(cell) }
                    XCTAssertTrue(game.isValidSave)
                }
                if frequency == .none { XCTAssertNil(lastDark) } else { XCTAssertNotNil(lastDark) }
            }
        }
    }

    func testChangingFrequencyKeepsBoardAndPreviewThenStopsNewDarkStars() {
        var game = StarfallExperiment(seed: 5)
        for _ in 0..<5 { game.letStarsFall() }
        XCTAssertTrue(game.incoming.contains(where: \.isDark))
        let old = game
        game.setBalance(.init(darkStars: .none))
        XCTAssertEqual(game.board, old.board); XCTAssertEqual(game.incoming, old.incoming)
        XCTAssertEqual(game.score, old.score); XCTAssertEqual(game.turns, old.turns)
        XCTAssertTrue(game.isValidSave)
        XCTAssertTrue(game.letStarsFall()!.arrivals.contains { $0.gem.isDark })
        for _ in 0..<30 where !game.isOver {
            XCTAssertFalse(game.incoming.contains(where: \.isDark))
            while let cell = game.legalGroups.first?.first, !game.isOver { game.clear(cell) }
            game.letStarsFall()
            XCTAssertTrue(game.isValidSave)
        }
    }

    func testPaceChangesDoNotChangeFutureShowerSequence() {
        var reference = StarfallExperiment(seed: 5), changed = reference
        changed.setBalance(.init(pace: .gentle))
        for _ in 0..<25 where !reference.isOver {
            XCTAssertEqual(changed.incoming, reference.incoming)
            reference.letStarsFall(); changed.letStarsFall()
            XCTAssertEqual(changed.board, reference.board)
            if let cell = reference.legalGroups.first?.first { reference.clear(cell); changed.clear(cell) }
        }
    }

    func testAllBalancesReplayAndRestoreDeterministically() throws {
        for pace in StarfallBalance.Pace.allCases {
            for frequency in StarfallBalance.DarkStarFrequency.allCases {
                let balance = StarfallBalance(pace: pace, darkStars: frequency)
                var game = StarfallExperiment(seed: 5, balance: balance), replay = game
                for _ in 0..<30 where !game.isOver {
                    if let cell = game.legalGroups.first?.first { game.clear(cell); replay.clear(cell) }
                    else { game.letStarsFall(); replay.letStarsFall() }
                    XCTAssertEqual(game, replay); XCTAssertTrue(game.isValidSave)
                    replay = try JSONDecoder().decode(StarfallExperiment.self, from: JSONEncoder().encode(game))
                    XCTAssertEqual(replay.balance, balance)
                    XCTAssertEqual(replay, game)
                }
            }
        }
    }

    func testPreTuningSaveKeepsItsBoardAndFutureSequence() throws {
        var original = StarfallExperiment(seed: 5)
        for _ in 0..<6 { original.letStarsFall() }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        json.removeValue(forKey: "savedBalance")
        var restored = try JSONDecoder().decode(StarfallExperiment.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(restored.balance, StarfallBalance())
        XCTAssertEqual(restored.board, original.board); XCTAssertTrue(restored.isValidSave)
        for _ in 0..<10 where !original.isOver {
            XCTAssertEqual(restored.incoming, original.incoming)
            original.letStarsFall(); restored.letStarsFall()
            XCTAssertEqual(restored.board, original.board)
        }
    }

    func testRejectsMalformedOrFloatingSavedBoard() throws {
        var game = StarfallExperiment(seed: 42)
        game.letStarsFall()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        json["score"] = 99
        var decoded = try JSONDecoder().decode(StarfallExperiment.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(decoded.isValidSave)
        json["score"] = 0
        var board = try XCTUnwrap(json["board"] as? [Any])
        let source = try XCTUnwrap(board.indices.first { !(board[$0] is NSNull) })
        let column = source % 7
        board[42 + column] = board[source]; board[source] = NSNull()
        json["board"] = board
        decoded = try JSONDecoder().decode(StarfallExperiment.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(decoded.isValidSave)
    }
}
