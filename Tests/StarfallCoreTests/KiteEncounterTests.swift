import XCTest
@testable import StarfallCore

final class KiteEncounterTests: XCTestCase {
    private let spaceMove = (Cell(2, 1), Cell(2, 0))
    private let pointsMove = (Cell(0, 4), Cell(1, 4))
    private let recovery = [
        (Cell(5, 1), Cell(4, 1)), (Cell(4, 1), Cell(3, 1)),
        (Cell(0, 4), Cell(0, 3)), (Cell(0, 3), Cell(0, 2)),
        (Cell(0, 2), Cell(0, 1))
    ]

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
    private func swap(_ move: (Cell, Cell), in game: inout FallingSky,
                      opening: FallingSky) throws -> FallingSkyTurn {
        let before = game
        var copy = try restored(before)
        let turn = try XCTUnwrap(game.nudge(from: move.0, to: move.1))
        let replayed = try XCTUnwrap(copy.nudge(from: move.0, to: move.1))
        XCTAssertEqual(turn.resolutionPhases, replayed.resolutionPhases)
        XCTAssertEqual(turn.settled, replayed.settled)
        XCTAssertEqual(turn.award, replayed.award)
        XCTAssertEqual(game, copy)
        XCTAssertEqual(game.incoming, before.incoming)
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(game.turns, before.turns)
        XCTAssertEqual(game.starsLanded, before.starsLanded)
        try assertSaved(game, opening: opening)
        return turn
    }

    @discardableResult
    private func shower(in game: inout FallingSky, opening: FallingSky) throws -> FallingSkyTurn {
        let before = game
        var copy = try restored(before)
        let turn = try XCTUnwrap(game.letStarsFall())
        let replayed = try XCTUnwrap(copy.letStarsFall())
        XCTAssertEqual(turn.forecast, before.incoming)
        XCTAssertEqual(turn.resolutionPhases, replayed.resolutionPhases)
        XCTAssertEqual(turn.arrivals.map(\.star), replayed.arrivals.map(\.star))
        XCTAssertEqual(turn.arrivals.map(\.cell), replayed.arrivals.map(\.cell))
        XCTAssertEqual(turn.arrivals.map(\.gem), replayed.arrivals.map(\.gem))
        XCTAssertEqual(turn.arrivals.map(\.grew), replayed.arrivals.map(\.grew))
        XCTAssertEqual(turn.blockedColumn, replayed.blockedColumn)
        XCTAssertEqual(game, copy)
        XCTAssertEqual(game.turns, before.turns + 1)
        try assertSaved(game, opening: opening)
        return turn
    }

    private func clearedIDs(_ phase: SkyResolutionPhase) -> Set<Int> {
        Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id })
    }

    func testNewVisitHasDistinctRecipeFreeOpeningAndOnlyAutomaticPatternControls() throws {
        var game = FallingSky.freshChallenge(.kiteHarbor)
        let opening = game
        let definition = try XCTUnwrap(StoryChallengeDefinition(.kiteHarbor))
        XCTAssertEqual(definition.revision, 4)
        XCTAssertEqual(game.challenge, .kiteHarbor)
        XCTAssertEqual(game.challengeRevision, 4)
        XCTAssertEqual(game.displayTarget, 17_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.seed, 42)
        XCTAssertEqual(game.balance, StarfallBalance(pace: .gentle, darkStars: .none))
        XCTAssertEqual(game.automaticShowerDelay, 6)
        XCTAssertEqual(game.automaticLineLength, 4)
        XCTAssertTrue(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.supportsArrangingStars)
        XCTAssertFalse(game.supportsManualClears)
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.legalGroups.isEmpty)
        XCTAssertEqual(game.occupiedCount, 24)
        XCTAssertEqual(game.starsLanded, 24)
        XCTAssertEqual(game.board.compactMap { $0?.id }, Array(0..<24))
        XCTAssertTrue(game.board.compactMap { $0 }.allSatisfy { !$0.grown })
        XCTAssertEqual(heights(game), [6, 6, 3, 3, 2, 2, 2])
        let symbols: [Jewel: Character] = [.aqua: "A", .rose: "R", .violet: "V", .mint: "M", .amber: "Y"]
        let rows = (0..<7).map { row in
            String((0..<7).map { column in game.gem(at: Cell(row, column))?.kind.flatMap { symbols[$0] } ?? "." })
        }
        XCTAssertEqual(rows, ["AVAARAA", "ARMYAMY", "RAVR...", "AM.....", "MY.....", "VR.....", "......."])
        for row in 0..<7 { for column in 0..<7 { XCTAssertNil(game.clear(Cell(row, column))) } }
        XCTAssertEqual(game, opening)
        try assertSaved(game, opening: opening)
    }

    func testOpeningChoicesTradeImmediatePointsForDifferentSurvivorsAndHeadroom() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        for spaceFirst in [true, false] {
            var game = opening
            let turn = try swap(spaceFirst ? spaceMove : pointsMove, in: &game, opening: opening)
            let phase = try XCTUnwrap(turn.resolutionPhases.first)
            XCTAssertEqual(turn.resolutionPhases.count, 1)
            XCTAssertEqual(phase.kind, .recipe)
            XCTAssertEqual(phase.comboDepth, 1)
            XCTAssertEqual(phase.recipes.map(\.shape), [.line])
            let spent: Set<Int> = spaceFirst ? [0, 7, 15, 18] : [2, 3, 5, 6, 11]
            XCTAssertEqual(clearedIDs(phase), spent)
            XCTAssertEqual(Set(game.board.compactMap { $0?.id }), Set(0..<24).subtracting(spent))
            XCTAssertEqual(turn.collected, spaceFirst ? 4 : 5)
            XCTAssertEqual(turn.displayAward, spaceFirst ? 5_000 : 7_000)
            XCTAssertEqual(heights(game), spaceFirst ? [2, 6, 3, 3, 2, 2, 2] : [6, 6, 2, 2, 1, 1, 1])
            if spaceFirst {
                XCTAssertEqual(game.gem(at: Cell(0, 0))?.id, 20)
                XCTAssertEqual(game.gem(at: Cell(1, 0))?.id, 22)
            } else {
                XCTAssertEqual(game.gem(at: Cell(0, 4))?.id, 4)
                XCTAssertEqual(game.gem(at: Cell(0, 4))?.kind, .rose)
            }
            XCTAssertEqual(game.outcome, .playing)
        }
    }

    func testEitherOpeningChoiceCanRecoverAfterOneIdenticalShowerAndFinishImmediately() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        let definition = try XCTUnwrap(StoryChallengeDefinition(.kiteHarbor))
        for spaceFirst in [true, false] {
            var game = opening
            try swap(spaceFirst ? spaceMove : pointsMove, in: &game, opening: opening)
            let arrivals = try shower(in: &game, opening: opening)
            XCTAssertEqual(arrivals.arrivals.count, 5)
            XCTAssertTrue(arrivals.resolutionPhases.isEmpty)
            XCTAssertEqual(arrivals.arrivals.filter(\.grew).count, spaceFirst ? 0 : 1)
            XCTAssertEqual(game.incoming, definition.shower(number: 2))
            XCTAssertEqual(heights(game), spaceFirst ? [3, 7, 3, 4, 3, 3, 2] : [7, 7, 2, 3, 1, 2, 1])
            let rose = try XCTUnwrap(game.board.compactMap { $0 }.first { $0.id == 4 })
            XCTAssertEqual(rose.kind, .rose)
            XCTAssertEqual(rose.grown, !spaceFirst)
            if !spaceFirst {
                let grown = try XCTUnwrap(arrivals.arrivals.first(where: \.grew))
                XCTAssertEqual(grown.gem.id, 4)
                XCTAssertEqual(grown.star, opening.incoming[4])
            }
            let other = try swap(spaceFirst ? pointsMove : spaceMove, in: &game, opening: opening)
            XCTAssertEqual(other.resolutionPhases.map(\.comboDepth), [1])
            XCTAssertEqual(other.displayAward, spaceFirst ? 7_000 : 5_000)
            XCTAssertEqual(game.displayScore, 12_000)
            XCTAssertEqual(heights(game), spaceFirst ? [3, 7, 2, 3, 2, 2, 1] : [3, 7, 2, 3, 1, 2, 1])
            XCTAssertEqual(game.outcome, .playing)
            for (index, move) in recovery.enumerated() {
                let turn = try swap(move, in: &game, opening: opening)
                if index < recovery.count - 1 {
                    XCTAssertTrue(turn.resolutionPhases.isEmpty)
                    XCTAssertEqual(turn.displayAward, 0)
                    XCTAssertEqual(game.outcome, .playing)
                } else {
                    XCTAssertEqual(turn.resolutionPhases.count, 1)
                    let phase = try XCTUnwrap(turn.resolutionPhases.first)
                    XCTAssertEqual(phase.comboDepth, 1)
                    XCTAssertEqual(phase.recipes.map(\.shape), [.line])
                    XCTAssertEqual(clearedIDs(phase), [4, 8, 14, 23])
                    XCTAssertEqual(phase.award.baseLight, spaceFirst ? 4 : 5)
                    XCTAssertEqual(turn.displayAward, spaceFirst ? 5_000 : 6_000)
                }
            }
            XCTAssertEqual(game.displayScore, spaceFirst ? 17_000 : 18_000)
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.restoration?.milestone, .complete)
            XCTAssertEqual(game.turns, 1)
            XCTAssertEqual(heights(game), spaceFirst ? [3, 3, 2, 3, 2, 2, 1] : [3, 3, 2, 3, 1, 2, 1])
            let finished = game
            XCTAssertNil(game.letStarsFall())
            XCTAssertNil(game.nudge(from: Cell(0, 0), to: Cell(0, 1)))
            XCTAssertNil(game.clear(Cell(0, 0)))
            XCTAssertEqual(game, finished)
            try assertSaved(game, opening: opening)
        }
    }

    func testSupplyMatchesFrozenLanternStreamIndependentlyOfOpeningAndActions() throws {
        let kite = try XCTUnwrap(StoryChallengeDefinition(.kiteHarbor))
        let lantern = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 4))
        XCTAssertEqual(kite.palette, [.aqua, .rose, .violet, .mint, .amber])
        XCTAssertEqual(kite.shower(number: 1), [
            IncomingStar(id: 0, kind: .aqua, column: 5), IncomingStar(id: 1, kind: .amber, column: 0),
            IncomingStar(id: 2, kind: .aqua, column: 1), IncomingStar(id: 3, kind: .mint, column: 3),
            IncomingStar(id: 4, kind: .rose, column: 4)
        ])
        for number in 1...140 {
            XCTAssertEqual(kite.shower(number: number), lantern.shower(number: number))
            XCTAssertEqual(kite.suppliedLight(after: number), number * 5)
        }
    }

    func testIgnoringCrowdedColumnsFillsSeventhCellThenCommitsRealOverflow() throws {
        var game = FallingSky.freshChallenge(.kiteHarbor)
        let opening = game
        let first = try shower(in: &game, opening: opening)
        XCTAssertEqual(first.arrivals.count, 5)
        XCTAssertNil(game.blockedColumn)
        XCTAssertEqual(heights(game)[0...1], [7, 7])
        XCTAssertEqual(game.outcome, .playing)
        let announced = game.incoming
        let second = try shower(in: &game, opening: opening)
        XCTAssertEqual(second.arrivals.count, 3)
        XCTAssertEqual(second.blockedColumn, 0)
        XCTAssertTrue(second.resolutionPhases.isEmpty)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertEqual(game.incoming, announced)
        let lost = game
        XCTAssertNil(game.letStarsFall())
        XCTAssertNil(game.nudge(from: spaceMove.0, to: spaceMove.1))
        XCTAssertEqual(game, lost)
    }

    func testHistoricalKiteSaveAndReplayKeepManualEighteenLightRules() throws {
        var game = FallingSky(challenge: .kiteHarbor)
        let opening = game
        XCTAssertEqual(game.challengeRevision, 0)
        XCTAssertEqual(game.displayTarget, 18)
        XCTAssertTrue(game.supportsManualClears)
        XCTAssertFalse(game.supportsAutomaticRecipes)
        XCTAssertTrue(game.board.allSatisfy { $0 == nil })
        XCTAssertEqual(game.balance, StarfallChallenge.kiteHarbor.balance)
        XCTAssertNotEqual(game, FallingSky.freshChallenge(.kiteHarbor))
        for _ in 0..<30 where !game.isOver {
            try shower(in: &game, opening: opening)
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

    func testKiteNeverClaimsUnshippedRevisionsAndRejectsTheirSaveMarkers() throws {
        let game = FallingSky.freshChallenge(.kiteHarbor)
        for revision in [0, 1, 2, 3, 5] {
            XCTAssertNil(StoryChallengeDefinition(.kiteHarbor, revision: revision))
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded(game)) as? [String: Any])
            fields["savedChallengeRevision"] = revision
            let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(invalid.isValidSave)
        }
        for challenge in [StarfallChallenge.seedMoon, .silverPools, .frostfruitOrchard, .sunwheelMill] {
            XCTAssertEqual(FallingSky.freshChallenge(challenge), FallingSky(challenge: challenge))
        }
    }
}
