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

    func testRevisionTwoEagerAndBankingPoliciesRetainExactRestoredReceipts() throws {
        for (challenge, buffer, expectedShowers, expectedActions, expectedScore) in [
            (StarfallChallenge.firstLight, false, 24, 52, 150_000),
            (.firstLight, true, 21, 24, 154_000),
            (.ribbonCrossing, false, 36, 88, 221_000),
            (.ribbonCrossing, true, 33, 46, 221_000)
        ] {
            var game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: 2)!)
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

    func testRevisionTwoMixedSupplyUsesCommittedForecastsAndRetainsCadence() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let definition = StoryChallengeDefinition(challenge, revision: 2)!
            for shower in 1...84 {
                let forecast = definition.shower(number: shower)
                XCTAssertEqual(forecast.count, 5)
                XCTAssertEqual(Set(forecast.map(\.column)).count, 5)
                XCTAssertEqual(Set(forecast.compactMap(\.kind)).count, 3)
                XCTAssertEqual(definition.suppliedLight(after: shower), shower * 5)
                XCTAssertEqual(Set(forecast.map(\.id)).count, 5)
            }
            let game = FallingSky(definition: definition)
            XCTAssertEqual(game.automaticShowerDelay, challenge == .firstLight ? 6 : 4)
            XCTAssertEqual(game.incoming, definition.shower(number: 1))
            XCTAssertEqual(try roundTrip(game).replay(), game)
        }
    }

    func testRevisionTwoIdleOverflowRetainsFullColumnPartialForecastAndTerminalReplay() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            var game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: 2)!)
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
    /// Recorded from bounded square-building search, with at most four exchanges
    /// between showers. These are production actions, not injected board states.
    private func revisionThreeWitness(for challenge: StarfallChallenge) -> [[(Int, Int)]] {
        if challenge == .firstLight {
            return [
            [(8, 9), (5, 12), (17, 18), (7, 8)],
            [(1, 2), (7, 8), (17, 16), (0, 7)],
            [(18, 19), (18, 17), (10, 17), (12, 13)],
            [(11, 12), (9, 10), (4, 11), (11, 12)],
            [(16, 17), (3, 4), (10, 11), (0, 1)],
            [(15, 16), (28, 29), (1, 8), (15, 22)],
            [(8, 9), (2, 3), (1, 2), (12, 11)],
            [(5, 6), (4, 5), (16, 17), (19, 18)],
            [(2, 3), (34, 33), (12, 19), (3, 4)],
            [(0, 1), (4, 5), (7, 8), (1, 2)],
            [(10, 11), (7, 8), (8, 9)],
            [(18, 17), (15, 16), (1, 2), (3, 4)],
            [(3, 2), (18, 17), (11, 10), (10, 9)],
            [(33, 32), (12, 13), (34, 33), (26, 33)],
            [(19, 26), (12, 19), (27, 34), (10, 11)],
            [(4, 5), (34, 33)],
            [(20, 19), (3, 10), (11, 12), (15, 16)],
            [(2, 9), (7, 14), (7, 8), (35, 36)],
            [(10, 11), (7, 8), (8, 9), (28, 29)],
            [(28, 29)],
            [(12, 19), (4, 5), (4, 11), (11, 18)],
            [(5, 6), (6, 13), (10, 11), (12, 13)],
            [(0, 1), (1, 8), (17, 16), (15, 16)],
            ]
        }
        return [
            [(8, 9), (11, 12), (18, 19), (5, 6)],
            [(3, 10), (10, 11)],
            [],
            [(7, 8), (10, 11), (9, 10)],
            [(21, 22), (14, 15), (17, 16), (10, 9)],
            [(8, 9), (9, 10), (12, 19), (11, 12)],
            [(26, 27), (26, 25), (19, 20), (34, 33)],
            [(19, 20), (20, 27), (3, 4), (4, 5)],
            [(5, 12), (4, 5), (1, 8), (1, 2)],
            [(2, 3), (14, 15), (8, 15), (15, 22)],
            [(3, 10), (3, 4), (7, 14), (1, 8)],
            [(4, 3), (2, 3), (1, 2), (3, 4)],
            [(2, 9), (7, 8), (8, 9), (26, 25)],
            [(2, 3), (5, 6), (4, 5), (19, 26)],
            [(13, 20), (20, 27), (23, 24), (3, 4)],
            [(10, 11), (23, 22), (1, 2), (3, 4)],
            [(2, 3), (24, 25), (13, 20), (20, 19)],
            [(4, 11), (27, 26), (3, 10), (19, 18)],
            [(5, 12), (9, 10), (13, 12), (12, 11)],
            [(16, 17), (10, 11), (11, 12), (9, 10)],
            [(0, 7), (7, 8)],
            [(14, 15), (8, 15), (12, 11), (10, 11)],
            [(9, 10), (8, 9), (9, 16), (8, 9)],
            [(9, 10), (27, 26), (4, 11), (18, 19)],
            [(27, 26), (26, 25), (9, 10), (11, 18)],
            [(19, 18), (11, 10), (4, 5), (3, 4)],
            [(15, 16), (9, 10), (3, 4)],
            [(0, 1), (2, 3), (4, 5), (5, 6)],
            [(4, 11), (4, 5)],
            [(21, 22), (0, 1), (3, 4), (3, 10)],
            [(10, 9), (11, 12), (6, 13), (20, 27)],
            [(13, 20), (1, 2), (2, 3), (14, 15)],
            [(0, 7), (7, 14)],
        ]
    }

    func testRevisionThreeRecordedSwapPlansWinAndRestoreEveryCommittedAction() throws {
        for (challenge, expectedShowers, expectedActions, expectedScore) in [
            (StarfallChallenge.firstLight, 22, 86, 154_000),
            (.ribbonCrossing, 32, 118, 220_000)
        ] {
            var game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: 3)!)
            XCTAssertEqual(game.challengeRevision, 3)
            let opening = game
            let witness = revisionThreeWitness(for: challenge)
            var actionCount = 0
            for (showersBefore, exchanges) in witness.enumerated() {
                XCTAssertEqual(game.turns, showersBefore)
                XCTAssertLessThanOrEqual(exchanges.count, 4)
                for (fromIndex, toIndex) in exchanges {
                    let from = Cell(fromIndex / 7, fromIndex % 7)
                    let to = Cell(toIndex / 7, toIndex % 7)
                    let before = game
                    var restored = try roundTrip(game)
                    let turn = try XCTUnwrap(game.nudge(from: from, to: to))
                    let restoredTurn = try XCTUnwrap(restored.nudge(from: from, to: to))
                    XCTAssertEqual(restoredTurn.resolutionPhases, turn.resolutionPhases)
                    XCTAssertEqual(restored, game)
                    XCTAssertEqual(game.incoming, before.incoming)
                    XCTAssertEqual(game.turns, before.turns)
                    XCTAssertEqual(game.displayScore, before.displayScore + turn.displayAward)
                    XCTAssertTrue(turn.resolutionPhases.allSatisfy { $0.kind == .recipe })
                    XCTAssertTrue(game.recipes.isEmpty)
                    game = try roundTrip(game)
                    actionCount += 1
                }
                if game.isOver {
                    XCTAssertEqual(showersBefore, witness.count - 1)
                    break
                }
                let forecast = game.incoming
                let turn = try XCTUnwrap(game.letStarsFall())
                XCTAssertEqual(turn.forecast, forecast)
                game = try roundTrip(game)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.turns, expectedShowers)
            XCTAssertEqual(actionCount, expectedActions)
            XCTAssertEqual(game.displayScore, expectedScore)
            XCTAssertEqual(game.replay(), opening)
        }
    }


}
