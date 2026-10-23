import XCTest
import StarfallCore
@testable import Starfall

final class FullBoardChoicePresentationTests: XCTestCase {
    @MainActor func testPostOpeningOptionsDescribeDifferentFirstPatternsAndTopDownSwipes() throws {
        var game = legacyFullBoard()
        try play(8, 9, in: &game)
        let choices = game.fullBoardChoices()
        XCTAssertEqual(choices.count, 2)
        let square = SkyFullBoardChoicePresentation(choice: choices[0])
        let line = SkyFullBoardChoicePresentation(choice: choices[1])
        XCTAssertEqual(square.title(number: 1), "Option 1: clear now")
        XCTAssertEqual(line.title(number: 2), "Option 2: clear now")
        XCTAssertEqual(square.pattern, "Square · 4 stars in the first clear")
        XCTAssertEqual(line.pattern, "Line · 4 stars in the first clear")
        XCTAssertEqual(square.instructions, ["1. Swipe up from row 7, column 4."])
        XCTAssertEqual(line.instructions, ["1. Swipe right from row 5, column 2."])
        XCTAssertFalse(square.isSetup)
        XCTAssertFalse(line.isSetup)
        XCTAssertFalse(square.pattern.contains("15,000"), "The description covers the visible first pattern only")
    }

    @MainActor func testAwkwardBoardDescribesTheArrangementAndClearInOrder() throws {
        var game = legacyFullBoard()
        for move in [(8, 9), (3, 10), (5, 12), (33, 40), (24, 31)] {
            try play(move.0, move.1, in: &game)
        }
        XCTAssertEqual(game.displayScore, 106_000)
        let choices = game.fullBoardChoices()
        XCTAssertEqual(choices.count, 1)
        let setup = SkyFullBoardChoicePresentation(choice: try XCTUnwrap(choices.first))
        XCTAssertTrue(setup.isSetup)
        XCTAssertEqual(setup.title(number: 1), "Option 1: set up, then clear")
        XCTAssertEqual(setup.pattern, "Square · 4 stars in the first clear")
        XCTAssertEqual(setup.instructions, [
            "1. Swipe right from row 7, column 2.",
            "2. Swipe up from row 6, column 2."
        ])
        let explanation = SkyCopy.text(.fullBoardChoiceSetupExplanation)
        XCTAssertTrue(explanation.contains("first exchange"))
        XCTAssertTrue(explanation.contains("without clearing"))
        XCTAssertTrue(explanation.contains("next exchange creates this pattern"))
    }

    @MainActor func testAdviceCopyExplainsItsVisiblePatternScopeAndBoundedEmptyResult() {
        XCTAssertEqual(SkyCopy.text(.fullBoardChoicesTitle), "Find a move")
        let explanation = SkyCopy.text(.fullBoardChoicesExplanation)
        XCTAssertTrue(explanation.contains("stars visible now"))
        XCTAssertTrue(explanation.contains("first pattern"))
        XCTAssertTrue(explanation.contains("Survivors and refills can continue"))
        XCTAssertTrue(explanation.contains("leaves your round unchanged"))
        let empty = SkyCopy.text(.fullBoardChoicesEmpty)
        XCTAssertTrue(empty.contains("within two exchanges"))
        XCTAssertTrue(empty.contains("still rearrange"))
        XCTAssertFalse(empty.contains("impossible"))
        XCTAssertEqual(SkyCopy.text(.fullBoardChoiceShowSwipes), "Show swipes")
        XCTAssertEqual(SkyCopy.text(.fullBoardChoiceHideSwipes), "Hide swipes")
    }

    @MainActor func testOnlyAnUnfinishedFullBoardSnapshotOffersTheRoute() throws {
        var fullBoard = legacyFullBoard()
        XCTAssertTrue(SkyFullBoardChoiceAnalysis.supports(fullBoard))
        XCTAssertFalse(SkyFullBoardChoiceAnalysis.supports(FallingSky.freshSurvival(seed: 42)))
        for challenge in StarfallChallenge.allCases {
            XCTAssertFalse(SkyFullBoardChoiceAnalysis.supports(FallingSky.freshChallenge(challenge)))
            XCTAssertFalse(SkyFullBoardChoiceAnalysis.supports(FallingSky(challenge: challenge)))
        }
        for move in [(8, 9), (8, 15), (5, 12), (31, 38), (1, 8)] {
            try play(move.0, move.1, in: &fullBoard)
        }
        XCTAssertEqual(fullBoard.outcome, .won)
        XCTAssertFalse(SkyFullBoardChoiceAnalysis.supports(fullBoard))
    }

    @MainActor func testDetachedAnalysisKeepsTheSnapshotAndCanceledRequestDoesNotPublishAnEmptyResult() async throws {
        var game = legacyFullBoard()
        try play(8, 9, in: &game)
        let before = game
        let result = await SkyFullBoardChoiceAnalysis.load(game)
        XCTAssertEqual(result, game.fullBoardChoices())
        XCTAssertEqual(game, before)
        let cancelled = Task { await SkyFullBoardChoiceAnalysis.load(game) }
        cancelled.cancel()
        let abandoned = await cancelled.value
        XCTAssertNil(abandoned, "A canceled page must discard advice rather than announce no short plan")
        XCTAssertEqual(game, before)
    }

    @MainActor func testCurrentFullBoardAdviceUsesTheActualFirstPatternWithoutChangingItsRound() throws {
        let game = FallingSky.fullBoardLantern()
        XCTAssertEqual(game.challengeRevision, 6)
        XCTAssertTrue(SkyFullBoardChoiceAnalysis.supports(game))
        let before = game
        let choice = try XCTUnwrap(game.fullBoardChoices().first)
        let presentation = SkyFullBoardChoicePresentation(choice: choice)
        XCTAssertFalse(presentation.pattern.isEmpty)
        XCTAssertEqual(presentation.instructions.count, choice.exchanges.count)
        var played = game
        var last: FallingSkyTurn?
        for exchange in choice.exchanges {
            last = try XCTUnwrap(played.nudge(from: exchange.from, to: exchange.to))
        }
        XCTAssertEqual(last?.resolutionPhases.first?.recipes, choice.recipes)
        XCTAssertEqual(game, before)
        XCTAssertTrue(played.isValidSave)
    }

    private func legacyFullBoard() -> FallingSky {
        FallingSky(definition: StoryChallengeDefinition(.firstLight, revision: 5)!)
    }

    private func play(_ from: Int, _ to: Int, in game: inout FallingSky) throws {
        _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7),
                                   to: Cell(to / 7, to % 7)))
    }
}
