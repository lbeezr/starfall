import XCTest
import StarfallCore
@testable import Starfall

final class SkyModeDiscoveryPresentationTests: XCTestCase {
    @MainActor func testModeDiscoveriesKeepTheWorkedSwipeBehindTheHint() throws {
        XCTAssertEqual(Array(SkyTutorial.allCases.prefix(5)), [.storySquare, .storyRoom, .fullBoardRefill, .fullBoardSurvivors, .fullBoardImmediate])
        XCTAssertEqual(SkyCopy.text(.practiceTryMode), "Try this mode")
        let discoveries: [(SkyTutorial, SkyCopy.Key, String)] = [
            (.storyRoom, .practiceStoryRoomPrompt, "Swipe right from row 7, column 2."),
            (.fullBoardRefill, .practiceFullBoardRefillPrompt, "Swipe right from row 6, column 2.")
        ]
        for (chapter, prompt, answer) in discoveries {
            let run = SkyTutorialRun(chapter)
            XCTAssertFalse(chapter.showsDetailInitially)
            XCTAssertEqual(run.instruction(showingHint: false), SkyCopy.text(prompt))
            XCTAssertFalse(run.instruction(showingHint: false).contains("row"))
            XCTAssertNotEqual(run.instruction(showingHint: false), answer)
            XCTAssertEqual(run.instruction(showingHint: true), answer)
            XCTAssertEqual(try XCTUnwrap(run.next).instruction, answer)
            XCTAssertFalse(run.showsShowerControl)
            XCTAssertFalse(run.showsPauseControl)
        }
        XCTAssertEqual(SkyTutorial.storyRoom.title, "Falling Sky: make room")
        XCTAssertEqual(SkyTutorial.fullBoardRefill.title, "Full Board: follow a refill")
        for key in [SkyCopy.Key.practiceIntro, .helpPracticeModes] {
            let text = SkyCopy.text(key)
            XCTAssertTrue(text.contains("Falling Sky"))
            XCTAssertTrue(text.contains("Full Board"))
            XCTAssertTrue(text.contains("Your saved sky and world stay unchanged."))
        }
    }

    @MainActor func testSkyDiscoveryExplainsTheMadeSpaceBeforeCallingTheShower() throws {
        var run = SkyTutorialRun(.storyRoom), game = SkyTutorial.storyRoom.game()
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 1), 7)
        let clear = try advance(&run, game: &game)
        XCTAssertEqual(clear.resolutionPhases.flatMap(\.cleared).count, 4)
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 1), 3)
        XCTAssertFalse(run.complete)
        XCTAssertTrue(run.showsShowerControl)
        XCTAssertEqual(run.instruction(showingHint: false), SkyCopy.text(.practiceStoryRoomAfterClear))
        XCTAssertTrue(run.instruction(showingHint: false).contains("four spaces in the threatened column"))
        XCTAssertEqual(run.instruction(showingHint: true), SkyCopy.text(.practiceShower))

        _ = try advance(&run, game: &game)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(game.isOver)
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 1), 4)
        XCTAssertFalse(run.showsShowerControl)
        for hint in [false, true] {
            XCTAssertEqual(run.instruction(showingHint: hint), SkyCopy.text(.practiceStoryRoomComplete))
            XCTAssertTrue(run.instruction(showingHint: hint).contains("the next shower fit"))
        }
    }

    @MainActor func testFullBoardDiscoveryExplainsRefillAfterTheCommittedReaction() throws {
        var run = SkyTutorialRun(.fullBoardRefill), game = SkyTutorial.fullBoardRefill.game()
        XCTAssertTrue(game.usesFullBoardRefill)
        let turn = try advance(&run, game: &game)
        XCTAssertEqual(turn.resolutionPhases.count, 3)
        XCTAssertEqual(turn.resolutionPhases.flatMap(\.refillArrivals).count, 18)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertTrue(run.complete)
        XCTAssertFalse(run.showsShowerControl)
        XCTAssertFalse(run.showsPauseControl)
        for hint in [false, true] {
            let completion = run.instruction(showingHint: hint)
            XCTAssertEqual(completion, SkyCopy.text(.practiceFullBoardRefillComplete))
            XCTAssertTrue(completion.contains("Survivors fell and new stars refilled the gaps"))
            XCTAssertTrue(completion.contains("49 stars"))
            XCTAssertFalse(completion.contains("next shower"))
        }
        XCTAssertTrue(SkyTutorial.fullBoardRefill.detail.contains("no showers or ceiling pressure"))
    }

    @MainActor func testChangedDiscoverySetupAsksForRetryAndRetryStartsWithoutTheAnswer() throws {
        for chapter in [SkyTutorial.storyRoom, .fullBoardRefill] {
            var run = SkyTutorialRun(chapter), game = chapter.game()
            let before = game, alternative = SkyTutorial.Action.swap(Cell(3, 0), Cell(3, 1))
            _ = try XCTUnwrap(alternative.perform(in: &game))
            run.observe(alternative, before: before, after: game)
            XCTAssertTrue(run.needsRetry, chapter.rawValue)
            for hint in [false, true] {
                XCTAssertEqual(run.instruction(showingHint: hint), SkyCopy.text(.practiceRetryMessage))
            }
            let retry = SkyTutorialRun(chapter)
            XCTAssertFalse(retry.chapter.showsDetailInitially)
            XCTAssertFalse(retry.needsRetry)
            XCTAssertEqual(retry.step, 0)
            XCTAssertNotEqual(retry.instruction(showingHint: false), retry.instruction(showingHint: true))
        }
    }

    @MainActor private func advance(_ run: inout SkyTutorialRun, game: inout FallingSky) throws -> FallingSkyTurn {
        let action = try XCTUnwrap(run.next), before = game
        let turn = try XCTUnwrap(action.perform(in: &game))
        run.observe(action, before: before, after: game)
        XCTAssertFalse(run.needsRetry)
        return turn
    }
}
