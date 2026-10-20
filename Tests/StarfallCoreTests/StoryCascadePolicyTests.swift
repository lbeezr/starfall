import XCTest
@testable import StarfallCore

/// Bounded deterministic policies establish reachability and compatibility, not
/// human timing, comprehension or enjoyment. Every action uses production Core.
final class StoryCascadePolicyTests: XCTestCase {
    private enum Action {
        case tap(Cell), swap(Cell, Cell)
        var isSwap: Bool { if case .swap = self { return true }; return false }
        func apply(_ game: inout FallingSky) -> FallingSkyTurn? {
            switch self {
            case .tap(let cell): return game.clear(cell)
            case .swap(let from, let to): return game.nudge(from: from, to: to)
            }
        }
    }
    private struct Choice {
        let action: Action
        let points: Int
        let stars: Int
        let setup: Bool
    }

    /// Prefer an immediate award. Only when none exists, choose an exchange that
    /// makes a useful ordinary clear. Ties retain row/column enumeration order.
    private func bestAction(_ game: FallingSky) -> Choice? {
        var best: Choice?
        func consider(_ action: Action, points: Int, stars: Int, setup: Bool = false) {
            if best == nil || points > best!.points || (points == best!.points && stars > best!.stars) {
                best = Choice(action: action, points: points, stars: stars, setup: setup)
            }
        }
        for group in game.legalGroups {
            var copy = game
            let turn = copy.clear(group[0])!
            consider(.tap(group[0]), points: turn.displayAward, stars: group.count)
        }
        var swaps: [(Cell, Cell)] = []
        for row in 0..<7 { for column in 0..<7 {
            let from = Cell(row, column)
            guard let first = game.gem(at: from) else { continue }
            for to in [Cell(row, column + 1), Cell(row + 1, column)] {
                guard let last = game.gem(at: to), first.kind != last.kind || first.grown != last.grown else { continue }
                swaps.append((from, to))
                var copy = game
                guard let turn = copy.nudge(from: from, to: to), turn.displayAward > 0 else { continue }
                consider(.swap(from, to), points: turn.displayAward, stars: turn.award!.clearedStarCount)
            }
        } }
        if best != nil { return best }
        for (from, to) in swaps {
            var copy = game
            guard copy.nudge(from: from, to: to) != nil else { continue }
            for group in copy.legalGroups {
                var future = copy
                let turn = future.clear(group[0])!
                consider(.swap(from, to), points: turn.displayAward, stars: group.count, setup: true)
            }
        }
        return best
    }

    private func roundTrip(_ game: FallingSky) throws -> FallingSky {
        XCTAssertTrue(game.isValidSave)
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(restored, game)
        XCTAssertTrue(restored.isValidSave)
        XCTAssertEqual(game.score + game.board.compactMap { $0 }.reduce(0) { $0 + $1.value }, game.starsLanded)
        return restored
    }

    func testEagerAndBankingPoliciesWinBothCurrentDefinitionsWithExactRestoredReceipts() throws {
        for (challenge, buffer, expectedShowers, expectedActions, expectedScore) in [
            (StarfallChallenge.firstLight, false, 24, 52, 150_000),
            (.firstLight, true, 21, 24, 154_000),
            (.ribbonCrossing, false, 36, 88, 221_000),
            (.ribbonCrossing, true, 33, 46, 221_000)
        ] {
            var game = FallingSky.freshChallenge(challenge)
            let opening = game
            var actions = 0, showerIncome = 0
            while !game.isOver && game.turns < 70 {
                for _ in 0..<50 where !game.isOver {
                    guard let choice = bestAction(game) else { break }
                    let height = (0..<7).map { SkyBoardSettling.height(game.board, column: $0) }.max()!
                    if buffer, (!choice.action.isSwap || choice.setup), game.occupiedCount <= 16, height < 6 { break }
                    let before = game
                    var copy = try roundTrip(before)
                    let turn = try XCTUnwrap(choice.action.apply(&game))
                    let restoredTurn = try XCTUnwrap(choice.action.apply(&copy))
                    XCTAssertEqual(restoredTurn.resolutionPhases, turn.resolutionPhases)
                    XCTAssertEqual(copy, game)
                    XCTAssertEqual(game.incoming, before.incoming)
                    XCTAssertEqual(game.turns, before.turns)
                    XCTAssertEqual(game.displayScore, before.displayScore + turn.displayAward)
                    XCTAssertEqual(turn.collected, turn.resolutionPhases.reduce(0) { $0 + $1.award.baseLight })
                    XCTAssertLessThanOrEqual(turn.resolutionPhases.count, 12)
                    actions += 1
                }
                if game.isOver { break }
                let forecast = game.incoming, points = game.displayScore
                let turn = try XCTUnwrap(game.letStarsFall())
                XCTAssertEqual(turn.forecast, forecast)
                XCTAssertEqual(game.displayScore, points + turn.displayAward)
                showerIncome += turn.displayAward
                game = try roundTrip(game)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, expectedShowers)
            XCTAssertEqual(actions, expectedActions)
            XCTAssertEqual(game.displayScore, expectedScore)
            XCTAssertEqual(game.replay(), opening)
            XCTAssertTrue(game.recipes.isEmpty)
            _ = try roundTrip(game)
            if challenge == .ribbonCrossing && buffer {
                XCTAssertEqual(showerIncome, 6_000, "Arrivals can form and commit a recipe without a player tap")
            }
        }
    }

    func testMixedSupplyUsesCommittedFiveStarForecastsAndRetainsCadence() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let definition = StoryChallengeDefinition(challenge)!
            for shower in 1...84 {
                let forecast = definition.shower(number: shower)
                XCTAssertEqual(forecast.count, 5)
                XCTAssertEqual(Set(forecast.map(\.column)).count, 5)
                XCTAssertEqual(Set(forecast.compactMap(\.kind)).count, 3)
                XCTAssertEqual(definition.suppliedLight(after: shower), shower * 5)
                XCTAssertEqual(Set(forecast.map(\.id)).count, 5)
            }
            let game = FallingSky.freshChallenge(challenge)
            XCTAssertEqual(game.automaticShowerDelay, challenge == .firstLight ? 6 : 4)
            XCTAssertEqual(game.incoming, definition.shower(number: 1))
            XCTAssertEqual(try roundTrip(game).replay(), game)
        }
    }

    func testIdleOverflowRetainsFullColumnPartialForecastAndTerminalReplay() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            var game = FallingSky.freshChallenge(challenge)
            let opening = game
            var last: FallingSkyTurn?
            for _ in 0..<10 where !game.isOver {
                last = game.letStarsFall()
                game = try roundTrip(game)
            }
            XCTAssertEqual(game.outcome, .lost)
            XCTAssertEqual(game.turns, 5)
            XCTAssertEqual(game.displayScore, 0)
            XCTAssertEqual(game.incoming, last?.forecast)
            XCTAssertTrue(last!.resolutionPhases.isEmpty)
            XCTAssertLessThan(last!.arrivals.count, last!.forecast.count)
            XCTAssertEqual(SkyBoardSettling.height(game.board, column: game.blockedColumn!), 7)
            XCTAssertEqual(game.replay(), opening)
            let ended = game
            XCTAssertNil(game.letStarsFall())
            XCTAssertNil(game.clear(Cell(0, 0)))
            XCTAssertEqual(game, ended)
        }
    }
}
