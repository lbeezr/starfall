import XCTest
@testable import StarfallCore

final class SkyTutorialTests: XCTestCase {
    func testEveryReferenceSequenceCommitsThroughProductionRules() throws {
        for chapter in SkyTutorial.allCases {
            var game = chapter.game(), run = SkyTutorialRun(chapter)
            XCTAssertFalse(chapter.actions.isEmpty, chapter.rawValue)
            for action in chapter.actions {
                let before = game
                switch action {
                case .pause, .resume: break
                default: XCTAssertNotNil(action.perform(in: &game), "\(chapter): \(action)")
                }
                run.observe(action, before: before, after: game)
                XCTAssertFalse(run.needsRetry, chapter.rawValue)
            }
            XCTAssertTrue(run.complete, chapter.rawValue)
            let expected: [SkyTutorial: (Int, Int, Int)] = [
                .storySquare: (8,16,0), .storyRoom: (4,42,5), .fullBoardRefill: (8,49,1),
                .fullBoardSurvivors: (26,49,3), .fullBoardImmediate: (26,49,3),
                .match: (3,1,0), .grown: (3,1,0), .exchange: (0,9,0), .emptySpace: (0,3,0),
                .trace: (5,1,0), .diagonal: (5,20,0), .gap: (5,0,0), .branch: (5,4,0),
                .square: (4,2,0), .cross: (5,4,0), .opal: (3,1,0), .relay: (8,0,0),
                .trim: (10,7,0), .dropIn: (7,0,0), .bank: (9,9,0), .fork: (9,11,0),
                .doubleSetup: (13,11,0), .showers: (0,9,3), .storm: (19,13,10),
                .room: (3,8,1), .restoration: (20,11,9)
            ]
            let result = try XCTUnwrap(expected[chapter])
            XCTAssertEqual(game.score, result.0, chapter.rawValue)
            XCTAssertEqual(game.occupiedCount, result.1, chapter.rawValue)
            XCTAssertEqual(game.turns, result.2, chapter.rawValue)
            if chapter == .restoration { XCTAssertEqual(game.outcome, .won) }
            if chapter == .storm { XCTAssertEqual(chapter.game().incoming.count, 5) }
        }
    }

    func testStorySquareUsesCurrentOpeningAndResolvesItsActualSurvivorChain() throws {
        let opening = SkyTutorial.storySquare.game()
        XCTAssertEqual(SkyTutorial.allCases.first, .storySquare)
        XCTAssertEqual(opening, FallingSky.freshChallenge(.firstLight))
        XCTAssertFalse(SkyTutorial.storySquare.allowsClock)
        XCTAssertFalse(opening.supportsManualClears)
        XCTAssertEqual(opening.automaticLineLength, 4)
        XCTAssertEqual(opening.occupiedCount, 24)
        XCTAssertTrue(opening.recipes.isEmpty)

        var game = opening, run = SkyTutorialRun(.storySquare)
        let action = try XCTUnwrap(run.next)
        XCTAssertEqual(action, .swap(Cell(1,2), Cell(1,1)))
        let turn = try XCTUnwrap(action.perform(in: &game))
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.square], [.square]])
        XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), [1, 2])
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(turn.resolutionPhases.map(\.cleared), [
            Set([Cell(0,0), Cell(0,1), Cell(1,0), Cell(1,1)]),
            Set([Cell(0,1), Cell(0,2), Cell(1,1), Cell(1,2)])
        ])
        let firstPhase = try XCTUnwrap(turn.resolutionPhases.first)
        let secondPhase = try XCTUnwrap(turn.resolutionPhases.dropFirst().first)
        XCTAssertEqual(secondPhase.before, firstPhase.settled)
        XCTAssertEqual(turn.displayAward, 15_000)
        XCTAssertTrue(turn.arrivals.isEmpty)
        XCTAssertEqual(game.score, 8, "Physical starlight stays distinct from displayed chain points")
        XCTAssertEqual(game.displayScore, 15_000)
        XCTAssertEqual(game.occupiedCount, 16)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.starsLanded, opening.starsLanded)
        XCTAssertEqual(game.incoming, opening.incoming)
        let survivorIDs: [Int?] = [
            14, nil, 16, 3, 4, 5, 6,
            21, nil, 23, 10, 11, 12, 13,
            nil, nil, nil, 17, 18, 19, 20
        ] + Array(repeating: nil, count: 28)
        XCTAssertEqual(game.board.map { $0?.id }, survivorIDs)
        XCTAssertTrue(game.isValidSave)
        XCTAssertFalse(game.isOver, "Completing practice is not completing a restoration round")

        run.observe(action, before: opening, after: game)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(run.needsRetry)
        XCTAssertNil(run.next)
    }

    func testStorySquareNonScoringExchangeKeepsItsResultAndRetryRestoresOpening() throws {
        let opening = SkyTutorial.storySquare.game()
        var game = opening, run = SkyTutorialRun(.storySquare)
        let alternative = SkyTutorial.Action.swap(Cell(3,0), Cell(3,1))
        let turn = try XCTUnwrap(alternative.perform(in: &game))
        XCTAssertNotEqual(game.board, opening.board)
        XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.occupiedCount, 24)
        XCTAssertTrue(turn.resolutionPhases.isEmpty)
        XCTAssertEqual(turn.displayAward, 0)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.incoming, opening.incoming)

        run.observe(alternative, before: opening, after: game)
        XCTAssertTrue(run.needsRetry)
        XCTAssertFalse(run.complete)
        XCTAssertNil(run.next)

        var retry = SkyTutorial.storySquare.game(), retriedRun = SkyTutorialRun(.storySquare)
        XCTAssertEqual(retry, opening)
        XCTAssertFalse(retriedRun.needsRetry)
        XCTAssertEqual(retriedRun.step, 0)
        let action = try XCTUnwrap(retriedRun.next)
        let before = retry
        let result = try XCTUnwrap(action.perform(in: &retry))
        retriedRun.observe(action, before: before, after: retry)
        XCTAssertTrue(retriedRun.complete)
        XCTAssertEqual(result.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(retry.score, 8)
        XCTAssertEqual(retry.displayScore, 15_000)
        XCTAssertEqual(retry.turns, 0)
        XCTAssertEqual(retry.incoming, opening.incoming)
    }

    func testStorySquareTapsCannotClearOrCompleteTheSwapLesson() {
        let opening = SkyTutorial.storySquare.game()
        for cell in [Cell(0,0), Cell(1,2)] {
            var game = opening, run = SkyTutorialRun(.storySquare)
            let tap = SkyTutorial.Action.tap(cell)
            XCTAssertNil(tap.perform(in: &game))
            XCTAssertEqual(game, opening)
            run.observe(tap, before: opening, after: game)
            XCTAssertFalse(run.complete)
            XCTAssertEqual(run.step, 0)
        }
    }

    func testStoryRoomRecoversTheCurrentLanternColumnBeforeReceivingItsSameShower() throws {
        let chapter = SkyTutorial.storyRoom, opening = chapter.game()
        var production = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<4 { _ = try XCTUnwrap(production.letStarsFall()) }
        XCTAssertEqual(opening, production)
        XCTAssertFalse(chapter.allowsClock)
        XCTAssertFalse(opening.supportsManualClears)
        XCTAssertEqual(opening.challengeRevision, 4)
        XCTAssertEqual(opening.occupiedCount, 41)
        XCTAssertEqual((0..<7).filter { opening.gem(at: Cell($0, 1)) != nil }.count, 7)

        var game = opening, run = SkyTutorialRun(chapter)
        let recovery = try XCTUnwrap(run.next)
        XCTAssertEqual(recovery, .swap(Cell(0,1), Cell(0,2)))
        let clear = try XCTUnwrap(recovery.perform(in: &game))
        run.observe(recovery, before: opening, after: game)
        XCTAssertEqual(clear.resolutionPhases.map(\.award.displayPoints), [5_000])
        XCTAssertTrue(clear.resolutionPhases.flatMap(\.refillArrivals).isEmpty)
        XCTAssertEqual(game.incoming, opening.incoming, "The clear preserves the shower the player must receive")
        XCTAssertEqual(game.occupiedCount, 37)
        XCTAssertEqual((0..<7).filter { game.gem(at: Cell($0, 1)) != nil }.count, 3)
        XCTAssertEqual(run.step, 1)
        XCTAssertEqual(run.next, .shower)
        XCTAssertFalse(run.complete, "The player still chooses to receive the announced shower")

        let recovered = game, shower = try XCTUnwrap(run.next)
        let arrival = try XCTUnwrap(shower.perform(in: &game))
        run.observe(shower, before: recovered, after: game)
        XCTAssertNil(arrival.blockedColumn)
        XCTAssertEqual(arrival.arrivals.map(\.star), opening.incoming)
        XCTAssertEqual(game.displayScore, 5_000)
        XCTAssertEqual(game.occupiedCount, 42)
        XCTAssertEqual(game.turns, 5)
        XCTAssertEqual(game.outcome, .playing)
        XCTAssertTrue(game.isValidSave)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(run.needsRetry)
    }

    func testStoryRoomDecliningRecoveryBlocksTheSameFifthShower() throws {
        let opening = SkyTutorial.storyRoom.game()
        var game = opening, run = SkyTutorialRun(.storyRoom)
        let turn = try XCTUnwrap(SkyTutorial.Action.shower.perform(in: &game))
        run.observe(.shower, before: opening, after: game)
        XCTAssertEqual(turn.blockedColumn, 1)
        XCTAssertEqual(game.blockedColumn, 1)
        XCTAssertTrue(game.isOver)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertTrue(game.isValidSave)
        XCTAssertFalse(run.complete)
        XCTAssertTrue(run.needsRetry)
        XCTAssertEqual(SkyTutorial.storyRoom.game(), opening)
    }

    func testFullBoardDiscoveryUsesItsActualClearFallRefillAndCausalContinuation() throws {
        let chapter = SkyTutorial.fullBoardRefill, opening = chapter.game()
        XCTAssertEqual(opening, FallingSky.fullBoardLantern())
        XCTAssertFalse(chapter.allowsClock)
        XCTAssertFalse(opening.supportsManualClears)
        XCTAssertEqual(opening.occupiedCount, 49)
        var game = opening, run = SkyTutorialRun(chapter)
        let action = try XCTUnwrap(run.next)
        XCTAssertEqual(action, .swap(Cell(1,1), Cell(1,2)))
        let turn = try XCTUnwrap(action.perform(in: &game))
        run.observe(action, before: opening, after: game)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), [1, 2])
        for phase in turn.resolutionPhases {
            XCTAssertEqual(phase.refillArrivals.count, phase.cleared.count)
            XCTAssertEqual(phase.refilled.compactMap { $0 }.count, 49)
            XCTAssertLessThan(phase.settled.compactMap { $0 }.count, 49)
            XCTAssertTrue(phase.refillArrivals.allSatisfy { $0.gem.id >= 49 })
        }
        let first = try XCTUnwrap(turn.resolutionPhases.first)
        let survivor = try XCTUnwrap(first.before[14])
        XCTAssertEqual(first.settled[0]?.id, survivor.id, "A surviving star falls into the cleared square before refill")
        for (earlier, later) in zip(turn.resolutionPhases, turn.resolutionPhases.dropFirst()) {
            XCTAssertEqual(later.before, earlier.refilled)
        }
        XCTAssertEqual(game.board, turn.resolutionPhases.last?.refilled)
        XCTAssertEqual(game.displayScore, 15_000)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertEqual(game.turns, 1)
        XCTAssertEqual(game.outcome, .playing, "Discovery completion does not repair the location")
        XCTAssertTrue(game.isValidSave)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(run.needsRetry)
    }

    func testModeDiscoveriesRejectUnproductiveOrInvalidActionsAndRetryExactly() throws {
        for chapter in [SkyTutorial.storyRoom, .fullBoardRefill] {
            let opening = chapter.game()
            var game = opening, run = SkyTutorialRun(chapter)
            let setup = SkyTutorial.Action.swap(Cell(0,0), Cell(0,1))
            let turn = try XCTUnwrap(setup.perform(in: &game))
            XCTAssertTrue(turn.resolutionPhases.isEmpty)
            XCTAssertNotEqual(game.board, opening.board)
            XCTAssertEqual(game.displayScore, 0)
            run.observe(setup, before: opening, after: game)
            XCTAssertFalse(run.complete)
            XCTAssertTrue(run.needsRetry)

            for invalid in [SkyTutorial.Action.tap(Cell(0,0)), .swap(Cell(0,0), Cell(1,1))] {
                var untouched = opening, invalidRun = SkyTutorialRun(chapter)
                XCTAssertNil(invalid.perform(in: &untouched))
                XCTAssertEqual(untouched, opening)
                invalidRun.observe(invalid, before: opening, after: untouched)
                XCTAssertFalse(invalidRun.complete)
                XCTAssertEqual(invalidRun.step, 0)
            }

            game = chapter.game(); run = SkyTutorialRun(chapter)
            XCTAssertEqual(game, opening)
            XCTAssertFalse(run.needsRetry)
            XCTAssertEqual(run.step, 0)
            for action in chapter.actions {
                let before = game
                XCTAssertNotNil(action.perform(in: &game))
                run.observe(action, before: before, after: game)
            }
            XCTAssertTrue(run.complete)
            XCTAssertFalse(run.needsRetry)
        }
    }

    func testWrongMethodCannotCompleteGestureLessonAndEquivalentTapsWork() {
        var game = SkyTutorial.trace.game(), run = SkyTutorialRun(.trace)
        let before = game; _ = game.clear(Cell(0,0))
        run.observe(.tap(Cell(0,0)), before: before, after: game)
        XCTAssertTrue(run.needsRetry); XCTAssertFalse(run.complete)
        game = SkyTutorial.match.game(); run = SkyTutorialRun(.match)
        let original = game; _ = game.clear(Cell(0,2))
        run.observe(.tap(Cell(0,2)), before: original, after: game)
        XCTAssertTrue(run.complete)
    }

    func testWorldProgressDistinguishesUnavailableLockedRestoredAndLegacyAccess() throws {
        var progress = WorldJourney()
        XCTAssertEqual(WorldLocation.allCases.count, 12)
        XCTAssertTrue(progress.canEnter(.firstLight)); XCTAssertFalse(progress.canEnter(.ribbonCrossing))
        for challenge in StarfallChallenge.allCases {
            var game = FallingSky(challenge: challenge)
            for _ in 0..<100 where !game.isOver {
                if let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
                else { _ = game.letStarsFall() }
            }
            XCTAssertEqual(game.outcome, .won)
            let location = try XCTUnwrap(WorldLocation(rawValue: challenge.rawValue))
            XCTAssertTrue(progress.canEnter(location))
            progress.record(game); progress.record(game)
            XCTAssertTrue(progress.completed.contains(location))
        }
        XCTAssertEqual(progress.completed.count, 7)
        XCTAssertTrue(progress.canEnter(.frostfruitOrchard))
        XCTAssertTrue(progress.canEnter(.sunwheelMill))
        XCTAssertFalse(progress.canEnter(.bellChoir))
        let legacy = WorldJourney(legacyAccess: true)
        XCTAssertTrue(legacy.canEnter(.silverPools)); XCTAssertTrue(legacy.completed.isEmpty)
        XCTAssertFalse(legacy.canEnter(.frostfruitOrchard))
        XCTAssertFalse(legacy.canEnter(.sunwheelMill))
        XCTAssertFalse(legacy.canEnter(.hollowCrown))
        XCTAssertEqual(try JSONDecoder().decode(WorldJourney.self, from: JSONEncoder().encode(progress)), progress)
    }

    func testLegacyWorldArchivePreservesOnlyItsFiveOriginalLocationsUntilSilverIsRepaired() throws {
        let bytes = Data(#"{"completed":[],"selected":"silverPools","legacyAccess":true}"#.utf8)
        var progress = try JSONDecoder().decode(WorldJourney.self, from: bytes)
        for location in [WorldLocation.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools] {
            XCTAssertTrue(progress.canEnter(location))
        }
        XCTAssertFalse(progress.canEnter(.frostfruitOrchard))
        XCTAssertEqual(progress.selected, .silverPools)
        var silver = FallingSky(challenge: .silverPools)
        progress.record(silver)
        XCTAssertFalse(progress.canEnter(.frostfruitOrchard), "An unfinished round cannot unlock the new location")
        for _ in 0..<100 where !silver.isOver {
            if let cell = silver.legalGroups.first?.first { _ = silver.clear(cell) }
            else { _ = silver.letStarsFall() }
        }
        XCTAssertEqual(silver.outcome, .won)
        progress.record(silver)
        XCTAssertEqual(progress.completed, [.silverPools])
        XCTAssertEqual(progress.selected, .frostfruitOrchard)
        XCTAssertTrue(progress.canEnter(.frostfruitOrchard))
        XCTAssertFalse(progress.canEnter(.sunwheelMill))
        let restored = try JSONDecoder().decode(WorldJourney.self, from: JSONEncoder().encode(progress))
        XCTAssertEqual(restored, progress)
        XCTAssertTrue(restored.canEnter(.frostfruitOrchard))
    }

    func testSunwheelRequiresCommittedFrostfruitRepairAndCannotUnlockUnbuiltBellChoir() throws {
        var progress = WorldJourney(legacyAccess: true)
        var orchard = FallingSky(challenge: .frostfruitOrchard)
        progress.record(orchard)
        XCTAssertFalse(progress.canEnter(.sunwheelMill))
        for _ in 0..<100 where !orchard.isOver {
            if let cell = orchard.legalGroups.first?.first { _ = orchard.clear(cell) }
            else { _ = orchard.letStarsFall() }
        }
        XCTAssertEqual(orchard.outcome, .won)
        progress.record(orchard)
        XCTAssertEqual(progress.completed, [.frostfruitOrchard])
        XCTAssertTrue(progress.canEnter(.sunwheelMill))
        XCTAssertEqual(progress.selected, .sunwheelMill)
        var mill = FallingSky(challenge: .sunwheelMill)
        for _ in 0..<100 where !mill.isOver {
            if let cell = mill.legalGroups.first?.first { _ = mill.clear(cell) }
            else { _ = mill.letStarsFall() }
        }
        progress.record(mill)
        XCTAssertEqual(mill.outcome, .won)
        XCTAssertEqual(progress.completed, [.frostfruitOrchard, .sunwheelMill])
        XCTAssertEqual(progress.selected, .sunwheelMill)
        XCTAssertFalse(progress.canEnter(.bellChoir))
        XCTAssertNil(WorldLocation.bellChoir.challenge)
        XCTAssertEqual(try JSONDecoder().decode(WorldJourney.self, from: JSONEncoder().encode(progress)), progress)
    }

    func testPreviouslySavedFrostfruitCompletionMakesSunwheelReadyWithoutInventingNewWins() throws {
        let bytes = Data(#"{"completed":["frostfruitOrchard"],"selected":"frostfruitOrchard","legacyAccess":false}"#.utf8)
        let retained = try JSONDecoder().decode(WorldJourney.self, from: bytes)
        XCTAssertTrue(retained.isValid)
        XCTAssertTrue(retained.canEnter(.sunwheelMill))
        XCTAssertEqual(retained.selected, .frostfruitOrchard)
        XCTAssertEqual(retained.completed, [.frostfruitOrchard])
        XCTAssertFalse(retained.canEnter(.bellChoir))
        let unbuilt = Data(#"{"completed":["bellChoir"],"selected":"bellChoir","legacyAccess":false}"#.utf8)
        XCTAssertFalse(try JSONDecoder().decode(WorldJourney.self, from: unbuilt).isValid)
    }
}
