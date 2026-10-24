import XCTest
import StarfallCore
@testable import Starfall

final class StoryIngredientInspectionTests: XCTestCase {
    private typealias Harness = (store: FallingSkyStore, presenter: FallingSkyRecorder,
                                clock: ManualRainClock, feedback: SkyFeedbackRecorder, defaults: UserDefaults)

    @MainActor private func make(_ game: FallingSky? = nil, tutorial: SkyTutorial? = nil) throws -> Harness {
        let suite = "Starfall.IngredientInspection.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        if let game { try SkySaveArchive.save(game, to: defaults) }
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: feedback, tutorial: tutorial)
        store.setSuspended(false)
        if tutorial == nil, !store.game.usesFullBoardRefill, store.isPaused { store.togglePause() }
        return (store, presenter, clock, feedback, defaults)
    }

    @MainActor private func inspect(_ cell: Cell, in fixture: Harness,
                                   file: StaticString = #filePath, line: UInt = #line) throws {
        let store = fixture.store, defaults = fixture.defaults
        let expected = try XCTUnwrap(SkyDialogueLibrary.ingredientInspection(at: cell, game: store.game), file: file, line: line)
        let game = store.game, forecast = store.forecast, journey = store.journey.journey
        let saved = defaults.data(forKey: SkySaveArchive.key)
        let world = defaults.data(forKey: WorldJourneyStore.key)
        let mastery = defaults.data(forKey: StoryMasteryStore.key)
        let deadline = fixture.clock.deadline, now = fixture.clock.now, cadence = store.nextShowerCadence
        let generation = store.constellationInputGeneration, paused = store.isPaused, suspended = store.suspended
        let tracing = store.constellationTracing, busy = store.busy
        let rendered = fixture.presenter.lastRendered, presentations = fixture.presenter.completions.count
        let clears = fixture.feedback.clears, stops = fixture.feedback.stops
        let announcements = fixture.feedback.announcements.count
        let celebration = store.celebration, finalLight = store.finalLight

        XCTAssertTrue(store.canReceiveInput, file: file, line: line)
        XCTAssertFalse(store.requestTap(cell), "Inspection is not a committed board action", file: file, line: line)
        XCTAssertEqual(store.guideLine, expected, file: file, line: line)
        XCTAssertTrue(store.dialogue.visible, file: file, line: line)
        XCTAssertEqual(fixture.feedback.announcements.count, announcements + 1, file: file, line: line)
        XCTAssertEqual(fixture.feedback.announcements.last, expected.spokenText, file: file, line: line)
        XCTAssertEqual(store.game, game, file: file, line: line)
        XCTAssertEqual(store.forecast, forecast, file: file, line: line)
        XCTAssertEqual(store.journey.journey, journey, file: file, line: line)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved, file: file, line: line)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world, file: file, line: line)
        XCTAssertEqual(defaults.data(forKey: StoryMasteryStore.key), mastery, file: file, line: line)
        XCTAssertEqual(fixture.clock.deadline, deadline, file: file, line: line)
        XCTAssertEqual(fixture.clock.now, now, file: file, line: line)
        XCTAssertEqual(store.nextShowerCadence, cadence, file: file, line: line)
        XCTAssertEqual(store.constellationInputGeneration, generation, file: file, line: line)
        XCTAssertEqual(store.isPaused, paused, file: file, line: line)
        XCTAssertEqual(store.suspended, suspended, file: file, line: line)
        XCTAssertEqual(store.constellationTracing, tracing, file: file, line: line)
        XCTAssertEqual(store.busy, busy, file: file, line: line)
        XCTAssertEqual(fixture.presenter.lastRendered, rendered, file: file, line: line)
        XCTAssertEqual(fixture.presenter.completions.count, presentations, file: file, line: line)
        XCTAssertEqual(fixture.feedback.clears, clears, file: file, line: line)
        XCTAssertEqual(fixture.feedback.stops, stops, file: file, line: line)
        XCTAssertEqual(store.celebration, celebration, file: file, line: line)
        XCTAssertEqual(store.finalLight, finalLight, file: file, line: line)
    }

    @MainActor func testSeedGrownIngredientHasTwoLightUnitsButStillOneActualStar() throws {
        let game = FallingSky.freshChallenge(.seedMoon)
        let grown = try XCTUnwrap(game.gem(at: Cell(0, 1)))
        let ordinary = try XCTUnwrap(game.gem(at: Cell(0, 0)))
        XCTAssertEqual(grown.id, 1)
        XCTAssertEqual(grown.kind, ordinary.kind)
        XCTAssertTrue(grown.grown)
        XCTAssertFalse(ordinary.grown)
        XCTAssertEqual(grown.value, 2)
        XCTAssertEqual(ordinary.value, 1)

        let grownLine = try XCTUnwrap(SkyDialogueLibrary.ingredientInspection(at: Cell(0, 1), game: game))
        let ordinaryLine = try XCTUnwrap(SkyDialogueLibrary.ingredientInspection(at: Cell(0, 0), game: game))
        let family = SkyPiece.description(for: .colored(.aqua))
        let controls = "Swipe neighbors into squares of 4, crosses of 5, or straight lines of 4 or more. Patterns pop automatically."
        XCTAssertEqual(grownLine.text, "\(family). Grown: 2 light units. \(controls)")
        XCTAssertEqual(ordinaryLine.text, "\(family). Small: 1 light unit. \(controls)")
        for line in [grownLine, ordinaryLine] {
            XCTAssertEqual(line.id, "guide.patterns-inspect-star.1")
            XCTAssertEqual(line.speaker, .spark)
            XCTAssertEqual(line.priority, .help)
            XCTAssertNil(line.seconds)
            XCTAssertFalse(line.text.contains("points"), "An ingredient does not predict a complete pattern award")
        }
    }

    @MainActor func testSeedInspectionPreservesLiveStateAndFollowsTheActuallyExchangedIngredients() throws {
        let fixture = try make(.freshChallenge(.seedMoon))
        defer { fixture.store.setSuspended(true) }
        XCTAssertNotNil(fixture.clock.deadline)
        try inspect(Cell(0, 1), in: fixture)
        try inspect(Cell(0, 0), in: fixture)

        let store = fixture.store, before = store.game
        var expected = before
        let turn = try XCTUnwrap(expected.nudge(from: Cell(0, 1), to: Cell(1, 1)))
        XCTAssertTrue(turn.resolutionPhases.isEmpty, "This documented Seed setup preserves the grown ingredient")
        XCTAssertTrue(store.requestInput(.swap(Cell(0, 1), Cell(1, 1)), snapshot: before,
                                         generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        fixture.presenter.finish()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game.gem(at: Cell(1, 1))?.id, 1)
        XCTAssertEqual(store.game.gem(at: Cell(1, 1))?.value, 2)
        XCTAssertEqual(store.game.gem(at: Cell(0, 1))?.kind, .rose)
        try inspect(Cell(1, 1), in: fixture)
        XCTAssertTrue(store.guideLine.text.contains("Grown: 2 light units"))
        try inspect(Cell(0, 1), in: fixture)
        XCTAssertTrue(store.guideLine.text.contains(SkyPiece.description(for: .colored(.rose))))
        XCTAssertTrue(store.guideLine.text.contains("Small: 1 light unit"))
        XCTAssertFalse(store.guideLine.text.contains("Grown"), "The old cell cannot keep the moved star’s facts")
    }

    @MainActor func testRetainedAndCurrentAutomaticModesUseTheirActualPatternThreshold() throws {
        var games: [FallingSky] = []
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in [3, 4] {
                games.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision))))
            }
        }
        games += [.fullBoardLantern(), .fullBoardRibbon()]
        games.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5))))
        for game in games {
            let line = try XCTUnwrap(SkyDialogueLibrary.ingredientInspection(at: Cell(0, 0), game: game))
            XCTAssertTrue(line.text.contains("Small: 1 light unit"))
            XCTAssertTrue(line.text.contains(game.challengeRevision == 3 ? "full lines of 7" : "straight lines of 4 or more"))
            XCTAssertFalse(line.text.contains(game.challengeRevision == 3 ? "straight lines of 4" : "full lines of 7"))
            XCTAssertTrue(line.text.contains("squares of 4, crosses of 5"))
            XCTAssertFalse(line.text.lowercased().contains("grow again"))
        }
    }

    @MainActor func testManualEmptyInvalidAndFinishedSkiesHaveNoAutomaticIngredientInspection() throws {
        let cell = Cell(0, 0)
        var manual = [FallingSky.freshSurvival(seed: 42), FallingSky(challenge: .firstLight), SkyTutorial.trace.game()]
        for revision in [1, 2] {
            manual.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision))))
        }
        for game in manual { XCTAssertNil(SkyDialogueLibrary.ingredientInspection(at: cell, game: game)) }
        let seed = FallingSky.freshChallenge(.seedMoon)
        for emptyOrInvalid in [Cell(6, 6), Cell(-1, 0), Cell(7, 0), Cell(0, 7)] {
            XCTAssertNil(SkyDialogueLibrary.ingredientInspection(at: emptyOrInvalid, game: seed))
        }
        var won = FallingSky.freshChallenge(.silverPools)
        XCTAssertNotNil(won.nudge(from: Cell(1, 2), to: Cell(1, 3)))
        XCTAssertEqual(won.outcome, .won)
        let survivor = try XCTUnwrap(won.board.firstIndex { $0 != nil })
        XCTAssertNil(SkyDialogueLibrary.ingredientInspection(at: Cell(survivor / 7, survivor % 7), game: won))
    }

    @MainActor func testFullBoardInspectionLeavesTheUntimedRoundAndSaveIntact() throws {
        for game in [FallingSky.fullBoardLantern(), .fullBoardRibbon()] {
            let fixture = try make(game)
            defer { fixture.store.setSuspended(true) }
            XCTAssertNil(fixture.clock.deadline)
            try inspect(Cell(0, 0), in: fixture)
            XCTAssertTrue(fixture.store.guideLine.text.contains("Small: 1 light unit"))
        }
    }

    @MainActor func testOpenSkyTapAndSelectiveTraceStillCommitTheirOriginalClears() throws {
        let tap = try make(tutorial: .match)
        defer { tap.store.setSuspended(true) }
        var tapped = tap.store.game
        XCTAssertNotNil(tapped.clear(Cell(0, 0)))
        XCTAssertTrue(tap.store.requestTap(Cell(0, 0)))
        XCTAssertEqual(tap.store.game, tapped)
        XCTAssertGreaterThan(tap.store.game.score, 0)
        XCTAssertFalse(tap.store.guideLine.id.hasPrefix("guide.patterns-inspect"))

        let trace = try make(tutorial: .trace)
        defer { trace.store.setSuspended(true) }
        let before = trace.store.game, path = (0..<5).map { Cell(0, $0) }
        var traced = before
        XCTAssertNotNil(traced.clearConstellation(path))
        trace.store.clearTracedConstellation(path, snapshot: before,
                                            generation: trace.store.constellationInputGeneration)
        XCTAssertEqual(trace.store.game, traced)
        XCTAssertEqual(trace.store.game.occupiedCount, 1)
        XCTAssertEqual(trace.store.game.gem(at: Cell(0, 5))?.id, before.gem(at: Cell(0, 5))?.id)
        XCTAssertEqual(trace.store.finalLight?.paths, [path])
        XCTAssertNil(trace.defaults.data(forKey: SkySaveArchive.key))
        XCTAssertNil(trace.defaults.data(forKey: WorldJourneyStore.key))
        XCTAssertNil(trace.defaults.data(forKey: StoryMasteryStore.key))
    }
}
