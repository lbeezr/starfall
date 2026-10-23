import XCTest
@testable import StarfallCore

final class FullBoardCascadePracticeTests: XCTestCase {
    private let chapters: [SkyTutorial] = [.fullBoardSurvivors, .fullBoardImmediate]

    private func randomState(_ game: FallingSky) throws -> Data {
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        return try JSONSerialization.data(withJSONObject: XCTUnwrap(fields["random"]), options: .sortedKeys)
    }

    private func perform(_ chapter: SkyTutorial) throws -> (FallingSky, FallingSkyTurn) {
        var game = chapter.game()
        let action = try XCTUnwrap(chapter.actions.first)
        let turn = try XCTUnwrap(action.perform(in: &game))
        return (game, turn)
    }

    func testChaptersStartAtTheSameActualFullBoardHistory() throws {
        var expected = FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
        let opening = try XCTUnwrap(expected.nudge(from: Cell(1,1), to: Cell(1,2)))
        XCTAssertEqual(opening.displayAward, 66_000)
        let arrangement = try XCTUnwrap(expected.nudge(from: Cell(0,1), to: Cell(0,2)))
        XCTAssertEqual(arrangement.displayAward, 0)
        XCTAssertTrue(arrangement.resolutionPhases.isEmpty)
        XCTAssertEqual(Array(SkyTutorial.allCases.drop(while: { $0 != .fullBoardRefill }).prefix(3)),
                       [.fullBoardRefill, .fullBoardSurvivors, .fullBoardImmediate])
        for chapter in chapters {
            XCTAssertEqual(chapter.game(), expected)
            XCTAssertEqual(chapter.actions.count, 1)
            XCTAssertFalse(chapter.allowsClock)
            XCTAssertEqual(chapter.game().challengeRevision, 5)
            XCTAssertEqual(chapter.game().displayScore, 66_000)
            XCTAssertEqual(chapter.game().turns, 2)
            XCTAssertEqual(chapter.game().score, 18)
            XCTAssertEqual(chapter.game().occupiedCount, 49)
            XCTAssertTrue(chapter.game().recipes.isEmpty)
            XCTAssertTrue(chapter.game().isValidSave)
        }
    }

    func testSmallerSquareLetsActualSurvivorsFormTheHigherScoringLine() throws {
        let chapter = SkyTutorial.fullBoardSurvivors
        let before = chapter.game()
        XCTAssertEqual(chapter.actions, [.swap(Cell(0,3), Cell(1,3))])
        let (game, turn) = try perform(chapter)
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.square], [.line]])
        XCTAssertEqual(turn.resolutionPhases.map(\.cleared.count), [4, 4])
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(turn.resolutionPhases.map(\.comboDepth), [1, 2])
        XCTAssertEqual(turn.displayAward, 15_000)
        XCTAssertEqual(game.displayScore, 81_000)
        let first = try XCTUnwrap(turn.resolutionPhases.first)
        let second = try XCTUnwrap(turn.resolutionPhases.last)
        let initialIDs = Set(before.board.compactMap { $0?.id })
        let firstIDs = Set(first.recipes.flatMap(\.starIDs))
        let secondIDs = Set(second.recipes.flatMap(\.starIDs))
        XCTAssertEqual(firstIDs, [10, 18, 31, 32])
        XCTAssertEqual(secondIDs, [53, 55, 62, 64])
        XCTAssertTrue(firstIDs.union(secondIDs).isSubset(of: initialIDs))
        XCTAssertTrue(secondIDs.isSubset(of: Set(first.settled.compactMap { $0?.id })))
        XCTAssertEqual(second.before, first.refilled)
        XCTAssertEqual(first.refillArrivals.map(\.gem.id), [67, 68, 69, 70])
        XCTAssertTrue(secondIDs.isDisjoint(with: Set(first.refillArrivals.map(\.gem.id))))
        XCTAssertEqual(second.refillArrivals.map(\.gem.id), [71, 72, 73, 74])
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertTrue(game.isValidSave)
    }

    func testLargerImmediateClearSpendsEightVisibleStarsInTwoSimultaneousSquares() throws {
        let chapter = SkyTutorial.fullBoardImmediate
        let before = chapter.game()
        XCTAssertEqual(chapter.actions, [.swap(Cell(1,1), Cell(2,1))])
        let (game, turn) = try perform(chapter)
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        let phase = try XCTUnwrap(turn.resolutionPhases.first)
        XCTAssertEqual(phase.recipes.map(\.shape), [.square, .square])
        XCTAssertEqual(phase.cleared.count, 8)
        XCTAssertEqual(phase.comboDepth, 1)
        XCTAssertEqual(phase.award.displayPoints, 13_000)
        XCTAssertEqual(turn.displayAward, 13_000)
        XCTAssertEqual(game.displayScore, 79_000)
        let spent = Set(phase.recipes.flatMap(\.starIDs))
        XCTAssertEqual(spent, [21, 23, 28, 43, 44, 52, 53, 55])
        XCTAssertTrue(spent.isSubset(of: Set(before.board.compactMap { $0?.id })))
        XCTAssertEqual(phase.refillArrivals.map(\.gem.id), Array(67...74))
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertTrue(game.isValidSave)
    }

    func testBothChoicesSpendTheSameLightAndDrawTheSameEightReplacementStars() throws {
        let opening = SkyTutorial.fullBoardSurvivors.game()
        let (survivors, survivorTurn) = try perform(.fullBoardSurvivors)
        let (immediate, immediateTurn) = try perform(.fullBoardImmediate)
        let survivorSupply = survivorTurn.resolutionPhases.flatMap(\.refillArrivals).map(\.gem)
        let immediateSupply = immediateTurn.resolutionPhases.flatMap(\.refillArrivals).map(\.gem)
        XCTAssertEqual(survivorSupply.sorted { $0.id < $1.id }, immediateSupply.sorted { $0.id < $1.id })
        XCTAssertEqual(survivorSupply.count, 8)
        XCTAssertEqual(immediateSupply.count, 8)
        XCTAssertEqual(survivors.score - opening.score, 8)
        XCTAssertEqual(immediate.score - opening.score, 8)
        XCTAssertEqual(survivors.score, 26)
        XCTAssertEqual(immediate.score, 26)
        XCTAssertEqual(survivors.starsLanded, 75)
        XCTAssertEqual(immediate.starsLanded, 75)
        XCTAssertEqual(try randomState(survivors), try randomState(immediate))
        XCTAssertNotEqual(try randomState(survivors), try randomState(opening))
        XCTAssertEqual(survivors.displayScore - immediate.displayScore, 2_000)
        XCTAssertNotEqual(survivors.board, immediate.board)
    }

    func testRunsCompleteTheirOwnChoiceAndPreserveTheOtherActualResultForRetry() throws {
        for chapter in chapters {
            let opening = chapter.game()
            var game = opening, run = SkyTutorialRun(chapter)
            let expected = try XCTUnwrap(run.next)
            XCTAssertNotNil(expected.perform(in: &game))
            run.observe(expected, before: opening, after: game)
            XCTAssertTrue(run.complete)
            XCTAssertFalse(run.needsRetry)
            XCTAssertNil(run.next)

            game = opening
            run = SkyTutorialRun(chapter)
            let other: SkyTutorial = chapter == .fullBoardSurvivors ? .fullBoardImmediate : .fullBoardSurvivors
            let alternative = try XCTUnwrap(other.actions.first)
            XCTAssertNotNil(alternative.perform(in: &game))
            let actualResult = game
            run.observe(alternative, before: opening, after: game)
            XCTAssertTrue(run.needsRetry)
            XCTAssertFalse(run.complete)
            XCTAssertNil(run.next)
            XCTAssertEqual(game, actualResult)
            XCTAssertEqual(game.displayScore, other == .fullBoardImmediate ? 79_000 : 81_000)
            XCTAssertEqual(chapter.game(), opening)
            XCTAssertEqual(SkyTutorialRun(chapter).step, 0)
            XCTAssertFalse(SkyTutorialRun(chapter).needsRetry)
        }
    }

    func testNeitherLessonOutcomeCompletesARestoration() throws {
        let originalJourney = WorldJourney()
        for chapter in chapters {
            let (game, _) = try perform(chapter)
            XCTAssertEqual(game.outcome, .playing)
            var journey = originalJourney
            journey.record(game)
            XCTAssertEqual(journey, originalJourney)
        }
        XCTAssertEqual(SkyTutorial.fullBoardSurvivors.game(), SkyTutorial.fullBoardImmediate.game())
    }

    func testBothChoicesHaveOrdinaryCompleteWinningContinuations() throws {
        let continuations: [(SkyTutorial, [(Int, Int)], Int, Int)] = [
            (.fullBoardSurvivors,
             [(5,12), (8,15), (33,40), (24,31), (5,6), (25,26), (11,18),
              (11,12), (37,44), (23,30), (2,3), (3,10), (47,48), (32,33)], 17, 78),
            (.fullBoardImmediate,
             [(5,12), (0,7), (7,8), (12,13), (26,33), (14,15), (15,22), (1,2),
              (22,29), (31,38), (17,18), (16,17), (1,8), (3,4), (28,29)], 18, 74)
        ]
        for (chapter, continuation, turns, physicalLight) in continuations {
            var (game, _) = try perform(chapter)
            for (from, to) in continuation {
                XCTAssertNotNil(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
                XCTAssertEqual(game.occupiedCount, 49)
                XCTAssertTrue(game.recipes.isEmpty)
                XCTAssertTrue(game.isValidSave)
            }
            XCTAssertEqual(game.outcome, .won)
            XCTAssertEqual(game.displayScore, 154_000)
            XCTAssertEqual(game.turns, turns)
            XCTAssertEqual(game.score, physicalLight)
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(restored, game)
            XCTAssertEqual(restored.replay(), FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!))
            XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertNil(game.letStarsFall())
        }
    }
}
