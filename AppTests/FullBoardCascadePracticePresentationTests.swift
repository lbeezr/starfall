import XCTest
import StarfallCore
@testable import Starfall

final class FullBoardCascadePracticePresentationTests: XCTestCase {
    @MainActor func testComparisonStartsAtTheSameRealArrangementAndBothModesStayAvailable() throws {
        var expected = FallingSky.fullBoardLantern()
        _ = try XCTUnwrap(expected.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        _ = try XCTUnwrap(expected.nudge(from: Cell(0, 1), to: Cell(0, 2)))
        XCTAssertEqual(expected.displayScore, 66_000)
        XCTAssertEqual(SkyTutorial.fullBoardSurvivors.game(), expected)
        XCTAssertEqual(SkyTutorial.fullBoardImmediate.game(), expected)
        for chapter in [SkyTutorial.fullBoardSurvivors, .fullBoardImmediate] {
            let run = SkyTutorialRun(chapter)
            XCTAssertEqual(run.step, 0)
            XCTAssertFalse(run.complete)
            XCTAssertFalse(chapter.allowsClock)
            XCTAssertEqual(chapter.actions.count, 1)
            XCTAssertEqual(chapter.game().occupiedCount, 49)
        }
        XCTAssertFalse(FallingSky.freshChallenge(.firstLight).usesFullBoardRefill)
        XCTAssertTrue(FallingSky.fullBoardLantern().usesFullBoardRefill)
        XCTAssertEqual(SkyCopy.text(.fullBoardCompareClears), "Compare clears")
        for retained in [FallingSky.freshChallenge(.firstLight), .fullBoardLantern()] {
            let suite = "Starfall.CascadeComparison.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            try SkySaveArchive.save(retained, to: defaults)
            try WorldJourneyStore(defaults: defaults).select(.firstLight)
            let round = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            let world = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
            let presenter = FallingSkyRecorder(), clock = ManualRainClock()
            var writes = 0
            let practice = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
                                           tutorial: .fullBoardSurvivors, archiveWriter: { _, _ in writes += 1 })
            practice.setSuspended(false)
            for chapter in [SkyTutorial.fullBoardSurvivors, .fullBoardImmediate] {
                practice.loadTutorial(chapter)
                XCTAssertEqual(practice.game, expected)
                let action = try XCTUnwrap(practice.tutorial?.next)
                guard case .swap(let from, let to) = action else { return XCTFail("Comparison uses an ordinary exchange") }
                XCTAssertTrue(practice.requestInput(.swap(from, to), snapshot: practice.game,
                                                    generation: practice.constellationInputGeneration))
                presenter.finish()
                XCTAssertTrue(practice.tutorial?.complete == true)
                let stale = presenter.completions.last
                practice.loadTutorial(chapter)
                stale?(); clock.advance(100)
                XCTAssertEqual(practice.game, expected)
                XCTAssertEqual(practice.tutorial?.step, 0)
                XCTAssertNil(clock.deadline)
                XCTAssertEqual(writes, 0)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), retained)
                XCTAssertTrue(practice.journey.journey.completed.isEmpty)
            }
            practice.setSuspended(true)
        }
    }

    @MainActor func testComparisonTitlesAndScopedFinishPreserveTheGenericTutorialSequence() {
        XCTAssertEqual(SkyTutorial.fullBoardSurvivors.title, "Keep a follow-up")
        XCTAssertEqual(SkyTutorial.fullBoardImmediate.title, "Compare the larger clear")
        XCTAssertEqual(SkyTutorial.fullBoardRefill.nextChapter, .fullBoardSurvivors)
        XCTAssertEqual(SkyTutorial.fullBoardSurvivors.nextChapter, .fullBoardImmediate)
        XCTAssertEqual(SkyTutorial.fullBoardImmediate.nextChapter, .match)
        XCTAssertEqual(SkyTutorial.fullBoardSurvivors.nextChapter(endingAfter: .fullBoardImmediate), .fullBoardImmediate)
        XCTAssertNil(SkyTutorial.fullBoardImmediate.nextChapter(endingAfter: .fullBoardImmediate))
        XCTAssertEqual(SkyTutorial.fullBoardImmediate.nextChapter(endingAfter: nil), .match)
        XCTAssertEqual(SkyTutorial.storyRoom.nextChapter, .fullBoardRefill)
        XCTAssertEqual(SkyTutorial.match.nextChapter, .grown)
        XCTAssertEqual(SkyTutorial.allCases.first, .storySquare)
    }

    @MainActor func testComparisonPromptsKeepWorkedPositionsBehindHintAndWrongRouteAsksForRetry() throws {
        let examples: [(SkyTutorial, SkyCopy.Key, String)] = [
            (.fullBoardSurvivors, .practiceFullBoardSurvivorsPrompt, "Swipe up from row 7, column 4."),
            (.fullBoardImmediate, .practiceFullBoardImmediatePrompt, "Swipe up from row 6, column 2.")
        ]
        for (chapter, prompt, answer) in examples {
            var run = SkyTutorialRun(chapter), game = chapter.game()
            XCTAssertFalse(chapter.showsDetailInitially)
            XCTAssertEqual(run.instruction(showingHint: false), SkyCopy.text(prompt))
            XCTAssertFalse(run.instruction(showingHint: false).contains("row"))
            XCTAssertEqual(run.instruction(showingHint: true), answer)
            XCTAssertFalse(run.showsShowerControl)
            XCTAssertFalse(run.showsPauseControl)
            let alternativeChapter: SkyTutorial = chapter == .fullBoardSurvivors ? .fullBoardImmediate : .fullBoardSurvivors
            let alternative = try XCTUnwrap(alternativeChapter.actions.first), before = game
            _ = try XCTUnwrap(alternative.perform(in: &game))
            run.observe(alternative, before: before, after: game)
            XCTAssertTrue(run.needsRetry)
            XCTAssertEqual(run.instruction(showingHint: false), SkyCopy.text(.practiceRetryMessage))
            XCTAssertEqual(run.instruction(showingHint: true), SkyCopy.text(.practiceRetryMessage))
            XCTAssertEqual(SkyTutorialRun(chapter).instruction(showingHint: false), SkyCopy.text(prompt))
        }
    }

    @MainActor func testFollowUpCompletionExplainsVisibleSurvivorsAndTheirActualChainAward() throws {
        var run = SkyTutorialRun(.fullBoardSurvivors), game = SkyTutorial.fullBoardSurvivors.game()
        let visibleIDs = Set(game.board.compactMap { $0?.id })
        let turn = try advance(&run, game: &game)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 10_000])
        XCTAssertEqual(turn.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.square], [.line]])
        let followUp = try XCTUnwrap(turn.resolutionPhases.last)
        XCTAssertTrue(Set(followUp.recipes.flatMap(\.starIDs)).isSubset(of: visibleIDs))
        XCTAssertEqual(game.displayScore, 81_000)
        for showingHint in [false, true] {
            let completion = run.instruction(showingHint: showingHint)
            XCTAssertEqual(completion, SkyCopy.text(.practiceFullBoardSurvivorsComplete))
            for fact in ["5,000", "already visible", "line", "10,000", "15,000 total", "Keeping those ingredients"] {
                XCTAssertTrue(completion.contains(fact), fact)
            }
        }
    }

    @MainActor func testLargerFirstClearCompletionNamesTwoSquaresAndTheDifferentEarnedTotal() throws {
        var run = SkyTutorialRun(.fullBoardImmediate), game = SkyTutorial.fullBoardImmediate.game()
        let turn = try advance(&run, game: &game)
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        let clear = try XCTUnwrap(turn.resolutionPhases.first)
        XCTAssertEqual(clear.recipes.map(\.shape), [.square, .square])
        XCTAssertEqual(clear.cleared.count, 8)
        XCTAssertEqual(turn.displayAward, 13_000)
        XCTAssertEqual(game.displayScore, 79_000)
        var comparisonRun = SkyTutorialRun(.fullBoardSurvivors), comparisonGame = SkyTutorial.fullBoardSurvivors.game()
        let comparison = try advance(&comparisonRun, game: &comparisonGame)
        XCTAssertEqual(spentIDs(turn).count, 8)
        XCTAssertEqual(spentIDs(comparison).count, 8)
        XCTAssertNotEqual(spentIDs(turn), spentIDs(comparison), "The choice changes which visible ingredients survive")
        XCTAssertEqual(turn.resolutionPhases.flatMap(\.refillArrivals).count, 8)
        XCTAssertEqual(comparison.resolutionPhases.flatMap(\.refillArrivals).count, 8)
        for showingHint in [false, true] {
            let completion = run.instruction(showingHint: showingHint)
            XCTAssertEqual(completion, SkyCopy.text(.practiceFullBoardImmediateComplete))
            for fact in ["Two squares", "eight stars together", "13,000", "later line", "15,000", "what survived"] {
                XCTAssertTrue(completion.contains(fact), fact)
            }
        }
    }

    private func spentIDs(_ turn: FallingSkyTurn) -> Set<Int> {
        Set(turn.resolutionPhases.flatMap { phase in
            phase.cleared.compactMap { phase.before[$0.row * FallingSky.side + $0.column]?.id }
        })
    }

    @MainActor private func advance(_ run: inout SkyTutorialRun, game: inout FallingSky) throws -> FallingSkyTurn {
        let action = try XCTUnwrap(run.next), before = game
        let turn = try XCTUnwrap(action.perform(in: &game))
        run.observe(action, before: before, after: game)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(run.needsRetry)
        return turn
    }
}
