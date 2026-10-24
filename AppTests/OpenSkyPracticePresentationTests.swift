import XCTest
import StarfallCore
@testable import Starfall

final class OpenSkyPracticePresentationTests: XCTestCase {
    @MainActor private func defaults() throws -> UserDefaults {
        let suite = "Starfall.OpenSkyPractice.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor func testTraceInvitationLeavesTheWorkedRouteOptionalAndExplainsItsExactConsequence() throws {
        var run = SkyTutorialRun(.trace), game = SkyTutorial.trace.game()
        XCTAssertFalse(SkyTutorial.trace.showsDetailInitially)
        XCTAssertEqual(run.instruction(showingHint: false), SkyCopy.text(.practiceTracePrompt))
        XCTAssertTrue(run.instruction(showingHint: false).contains("Open Sky"))
        XCTAssertTrue(run.instruction(showingHint: false).contains("five of six Aqua stars"))
        XCTAssertFalse(run.instruction(showingHint: false).contains("7,1"))
        XCTAssertEqual(run.instruction(showingHint: true), try XCTUnwrap(run.next).instruction)
        XCTAssertTrue(run.instruction(showingHint: true).contains("7,1"))
        let action = SkyTutorial.Action.trace((1...5).map { Cell(0, $0) }), before = game
        _ = try XCTUnwrap(action.perform(in: &game))
        run.observe(action, before: before, after: game)
        XCTAssertTrue(run.complete)
        for hint in [false, true] {
            XCTAssertEqual(run.instruction(showingHint: hint), SkyCopy.text(.practiceTraceComplete))
            XCTAssertTrue(run.instruction(showingHint: hint).contains("One Aqua stays"))
        }
        XCTAssertFalse(run.showsPauseControl); XCTAssertFalse(run.showsShowerControl)
        XCTAssertEqual(SkyTutorial.trace.nextChapter, .diagonal)
        XCTAssertTrue(SkyTutorial.gap.showsDetailInitially)
        XCTAssertFalse(SkyTutorial.storySquare.showsDetailInitially)
        XCTAssertEqual(SkyTutorialRun(.storySquare).instruction(showingHint: false), SkyCopy.text(.practiceStorySquarePrompt))
    }

    @MainActor func testBothFiveStarChoicesKeepExactReturnSurvivorAndPlayerBytesThroughRetryAndRestore() throws {
        let savedGames = [FallingSky.freshSurvival(seed: 91), FallingSky.fullBoardRibbon(),
                          FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 3)))]
        for saved in savedGames {
            let defaults = try defaults()
            try SkySaveArchive.save(saved, to: defaults)
            try WorldJourneyStore(defaults: defaults).select(.firstLight)
            let round = defaults.data(forKey: SkySaveArchive.key), world = defaults.data(forKey: WorldJourneyStore.key)
            for indices in [Array(0..<5), Array(1...5)] {
                let presenter = FallingSkyRecorder(), clock = ManualRainClock()
                var writes = 0
                let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                            clock: clock, tutorial: .trace, archiveWriter: { _, _ in writes += 1 })
                store.setSuspended(false)
                let opening = store.game, path = indices.map { Cell(0, $0) }
                let selectedIDs = Set(path.compactMap { opening.gem(at: $0)?.id })
                let keptIDs = Set(opening.board.compactMap { $0?.id }).subtracting(selectedIDs)
                store.clearTracedConstellation(path, snapshot: opening, generation: store.constellationInputGeneration)
                XCTAssertTrue(try XCTUnwrap(store.tutorial).complete)
                XCTAssertFalse(try XCTUnwrap(store.tutorial).needsRetry)
                XCTAssertEqual(store.game.score, 5); XCTAssertEqual(store.game.occupiedCount, 1)
                XCTAssertEqual(Set(store.game.board.compactMap { $0?.id }), keptIDs)
                XCTAssertEqual(store.game.incoming, opening.incoming); XCTAssertEqual(store.game.turns, 0)
                let receipt = try XCTUnwrap(store.celebration)
                XCTAssertEqual(receipt.constellationPath, path)
                XCTAssertEqual(Set(receipt.cells), Set(path)); XCTAssertEqual(receipt.collected, 5)
                XCTAssertNil(clock.deadline)
                let oldCompletion = try XCTUnwrap(presenter.completions.last)
                store.loadTutorial(.trace)
                XCTAssertEqual(store.game, opening)
                XCTAssertFalse(try XCTUnwrap(store.tutorial).complete)
                XCTAssertNil(store.celebration)
                oldCompletion(); clock.advance(100)
                XCTAssertEqual(store.game, opening)
                store.setSuspended(true); store.setSuspended(false)
                XCTAssertEqual(store.game, opening)
                XCTAssertEqual(writes, 0)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertEqual(restored.game, saved)
                XCTAssertNil(restored.tutorial); XCTAssertNil(restored.celebration)
            }
        }
    }

    @MainActor func testShortTraceCommitsNothingAndDifferentLegalClearsRemainVisibleForRetry() throws {
        let defaults = try defaults(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock(), tutorial: .trace)
        store.setSuspended(false)
        let opening = store.game
        store.clearTracedConstellation((0..<4).map { Cell(0, $0) }, snapshot: opening, generation: store.constellationInputGeneration)
        XCTAssertEqual(store.game, opening); XCTAssertNil(store.celebration)
        XCTAssertEqual(store.tutorial?.step, 0); XCTAssertEqual(store.tutorial?.needsRetry, false)
        XCTAssertTrue(presenter.completions.isEmpty)
        for byTap in [false, true] {
            store.loadTutorial(.trace)
            if byTap { store.clear(Cell(0,0)) }
            else { store.clearTracedConstellation((0..<6).map { Cell(0, $0) }, snapshot: opening, generation: store.constellationInputGeneration) }
            XCTAssertEqual(store.game.score, 6); XCTAssertEqual(store.game.occupiedCount, 0)
            XCTAssertEqual(store.tutorial?.needsRetry, true); XCTAssertEqual(store.tutorial?.complete, false)
            XCTAssertEqual(try XCTUnwrap(store.tutorial).instruction(showingHint: false), SkyCopy.text(.practiceRetryMessage))
            XCTAssertEqual(try XCTUnwrap(store.celebration).collected, 6, "Legal play keeps its actual award even when the lesson asks for another choice")
            if byTap { XCTAssertTrue(try XCTUnwrap(store.celebration).constellationPath.isEmpty) }
            presenter.finish()
        }
        XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key))
    }

    @MainActor func testGapBranchAndRevisitPracticeKeepTheProductionWalkAndTheirOwnRubrics() throws {
        for chapter in [SkyTutorial.diagonal, .gap, .branch] {
            let defaults = try defaults(), presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock(), tutorial: chapter)
            store.setSuspended(false)
            guard case .trace(let path) = try XCTUnwrap(store.tutorial?.next) else { return XCTFail("Expected existing drawn practice") }
            let opening = store.game
            XCTAssertEqual(opening.constellationCells(along: path), Set(path))
            store.clearTracedConstellation(path, snapshot: opening, generation: store.constellationInputGeneration)
            XCTAssertEqual(store.tutorial?.complete, true)
            XCTAssertEqual(try XCTUnwrap(store.celebration).constellationPath, path)
            XCTAssertEqual(store.game.score, 5)
            XCTAssertEqual(store.game.incoming, opening.incoming)
            XCTAssertEqual(try XCTUnwrap(store.tutorial).instruction(showingHint: false), SkyCopy.text(.practiceComplete))
            presenter.finish()
            store.setSuspended(true)
            XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
            XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key))
        }
    }
}
