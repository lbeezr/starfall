import XCTest
import StarfallCore
@testable import Starfall

final class SkyHeadroomGuideTests: XCTestCase {
    private typealias Harness = (store: FallingSkyStore, presenter: FallingSkyRecorder,
                                clock: ManualRainClock, feedback: SkyFeedbackRecorder, defaults: UserDefaults)
    private let spaceMove = (Cell(2, 1), Cell(2, 0))
    private let pointsMove = (Cell(0, 4), Cell(1, 4))
    private let spaceText = "4 more spaces above the stars in column 1."
    private let pointsText = "5 more spaces above the stars in columns 3, 4, 5, 6, 7."
    private let refillText = "Refill added 8 stars; the board is full."

    @MainActor private func make(_ game: FallingSky, quiet: Bool = false) throws -> Harness {
        let suite = "Starfall.HeadroomGuide.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        presenter.reduceMotion = quiet
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: feedback)
        store.setSuspended(false)
        if !game.usesFullBoardRefill, store.isPaused { store.togglePause() }
        feedback.announcements.removeAll()
        return (store, presenter, clock, feedback, defaults)
    }

    /// Independently measures the occupied top, rather than reusing the feedback model.
    private func heights(_ game: FallingSky) -> [Int] {
        (0..<7).map { column in
            (0..<7).reversed().first { game.gem(at: Cell($0, column)) != nil }.map { $0 + 1 } ?? 0
        }
    }

    private func result(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky) -> SkyDialogueLine {
        SkyDialogueLibrary.result(for: turn, from: old, to: game, tracedCount: 0,
                                 recipe: nil, relayDepth: 0, techniqueResult: "Star moved. What can you line up?")
    }

    private func assertLine(_ actual: SkyDialogueLine, preserves original: SkyDialogueLine,
                            scoreText: String, suffix: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(actual.text, original.text + " " + scoreText + " " + suffix, file: file, line: line)
        XCTAssertEqual(actual.id, original.id, file: file, line: line)
        XCTAssertEqual(actual.speaker, original.speaker, file: file, line: line)
        XCTAssertEqual(actual.priority, original.priority, file: file, line: line)
        XCTAssertEqual(actual.seconds, original.seconds, file: file, line: line)
        XCTAssertTrue(actual.isValid, file: file, line: line)
    }

    @discardableResult @MainActor private func exchange(_ move: (Cell, Cell), in fixture: Harness,
                                                       file: StaticString = #filePath, line: UInt = #line) throws -> FallingSkyTurn {
        let before = fixture.store.game
        var expected = before
        let turn = try XCTUnwrap(expected.nudge(from: move.0, to: move.1), file: file, line: line)
        XCTAssertTrue(fixture.store.requestInput(.swap(move.0, move.1), snapshot: before,
                                                generation: fixture.store.constellationInputGeneration), file: file, line: line)
        XCTAssertEqual(fixture.store.game, expected, file: file, line: line)
        XCTAssertEqual(SkySaveArchive.load(from: fixture.defaults), expected, file: file, line: line)
        return turn
    }

    @MainActor func testKiteChoicesPublishTheirExactDifferentRoomBeforeMotionWithoutChangingTheClockOrSupply() throws {
        let opening = FallingSky.freshChallenge(.kiteHarbor)
        XCTAssertEqual(heights(opening), [6, 6, 3, 3, 2, 2, 2])
        for quiet in [false, true] {
            for spaceFirst in [true, false] {
                let fixture = try make(opening, quiet: quiet)
                defer { fixture.store.setSuspended(true) }
                let store = fixture.store
                fixture.clock.advance(1.25)
                let deadline = try XCTUnwrap(fixture.clock.deadline), now = fixture.clock.now
                let forecast = store.forecast, world = store.journey.journey
                let worldBytes = fixture.defaults.data(forKey: WorldJourneyStore.key)
                let masteryBytes = fixture.defaults.data(forKey: StoryMasteryStore.key)
                let turn = try exchange(spaceFirst ? spaceMove : pointsMove, in: fixture)
                XCTAssertEqual(turn.displayAward, spaceFirst ? 5_000 : 7_000)
                XCTAssertEqual(heights(store.game), spaceFirst ? [2, 6, 3, 3, 2, 2, 2] : [6, 6, 2, 2, 1, 1, 1])
                let original = SkyDialogueLibrary.line("guide.automatic-recipe", values: ["score": spaceFirst ? "5,000" : "7,000"])
                assertLine(store.guideLine, preserves: original,
                           scoreText: spaceFirst
                            ? "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points."
                            : "5 stars · 5 light. 5,000 base + 2,000 size = 7,000 points.",
                           suffix: spaceFirst ? spaceText : pointsText)
                XCTAssertEqual(store.dialogue.line, store.guideLine, "Committed room is visible before presentation completion")
                XCTAssertEqual(fixture.feedback.announcements, [store.guideLine.spokenText])
                XCTAssertEqual(store.forecast, forecast)
                XCTAssertEqual(store.game.incoming, forecast)
                XCTAssertEqual(fixture.clock.deadline, deadline)
                XCTAssertEqual(fixture.clock.now, now)
                XCTAssertEqual(store.journey.journey, world)
                XCTAssertEqual(fixture.defaults.data(forKey: WorldJourneyStore.key), worldBytes)
                XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), masteryBytes)
                XCTAssertNil(store.game.masteryEnrollment)

                let committed = store.game, copy = store.guideLine, revision = store.dialogue.revision
                let saved = try XCTUnwrap(fixture.defaults.data(forKey: SkySaveArchive.key))
                XCTAssertEqual(saved, try SkySaveArchive.encode(committed))
                fixture.presenter.finish(); fixture.presenter.finish()
                XCTAssertFalse(store.busy)
                XCTAssertEqual(store.game, committed)
                XCTAssertEqual(store.guideLine, copy)
                XCTAssertEqual(store.dialogue.revision, revision)
                XCTAssertEqual(fixture.feedback.announcements, [copy.spokenText], "Motion completion cannot repeat the room message")
                XCTAssertEqual(fixture.clock.deadline, deadline)
                XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), saved)

                var control = try SkySaveArchive.decode(saved)
                let next = try XCTUnwrap(control.letStarsFall())
                fixture.clock.advance(deadline - fixture.clock.now)
                XCTAssertEqual(store.game, control, "Feedback cannot consume RNG or change the ordinary next shower")
                XCTAssertEqual(store.pending?.arrivals, next.arrivals)
                XCTAssertEqual(store.pending?.resolutionPhases, next.resolutionPhases)
                XCTAssertEqual(store.pending?.forecast, forecast)
                XCTAssertNil(store.pending?.blockedColumn)
                fixture.presenter.finish()
                XCTAssertEqual(store.forecast, control.incoming)
                XCTAssertEqual(SkySaveArchive.load(from: fixture.defaults), control)
                XCTAssertEqual(store.journey.journey, world)
                XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), masteryBytes)
            }
        }
    }

    @MainActor func testKiteRecoveryAppendsNewRoomBeforeTheExistingFullColumnRecoveryExactlyOnce() throws {
        for quiet in [false, true] {
            var game = FallingSky.freshChallenge(.kiteHarbor)
            XCTAssertNotNil(game.nudge(from: pointsMove.0, to: pointsMove.1))
            XCTAssertNotNil(game.letStarsFall())
            XCTAssertEqual(heights(game), [7, 7, 2, 3, 1, 2, 1])
            let fixture = try make(game, quiet: quiet)
            defer { fixture.store.setSuspended(true) }
            let turn = try exchange(spaceMove, in: fixture)
            XCTAssertEqual(turn.displayAward, 5_000)
            XCTAssertEqual(fixture.store.game.displayScore, 12_000)
            XCTAssertEqual(heights(fixture.store.game), [3, 7, 2, 3, 1, 2, 1])
            XCTAssertEqual(fixture.store.pressureCue?.text, "Column 2 is full.")
            let original = SkyDialogueLibrary.line("guide.automatic-recipe", values: ["score": "5,000"])
            assertLine(fixture.store.guideLine, preserves: original,
                       scoreText: "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points.",
                       suffix: spaceText + " Column 1 has room again.")
            let line = fixture.store.guideLine
            XCTAssertEqual(fixture.feedback.announcements, [line.spokenText])
            fixture.presenter.finish(); fixture.presenter.finish()
            XCTAssertEqual(fixture.feedback.announcements, [line.spokenText])
            XCTAssertEqual(fixture.store.guideLine, line)
        }
    }

    @MainActor func testNoClearSetupAndActualGrowthKeepTheirExistingFactsWithoutAnOpenedRoomPromise() throws {
        let fixture = try make(.freshChallenge(.seedMoon))
        defer { fixture.store.setSuspended(true) }
        let deadline = fixture.clock.deadline, forecast = fixture.store.forecast
        let setup = try exchange((Cell(0, 1), Cell(1, 1)), in: fixture)
        XCTAssertTrue(setup.resolutionPhases.isEmpty)
        XCTAssertTrue(setup.cleared.isEmpty)
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertEqual(fixture.store.guideLine.id, "guide.technique.1")
        XCTAssertEqual(fixture.store.guideLine.text, "Star moved. What can you line up?")
        XCTAssertEqual(fixture.clock.deadline, deadline)
        XCTAssertEqual(fixture.store.forecast, forecast)

        var game = FallingSky.freshChallenge(.kiteHarbor)
        XCTAssertNotNil(game.nudge(from: pointsMove.0, to: pointsMove.1))
        let before = game
        let growth = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(growth.arrivals.filter(\.grew).count, 1)
        XCTAssertTrue(growth.cleared.isEmpty)
        XCTAssertTrue(growth.resolutionPhases.isEmpty)
        let line = result(growth, from: before, to: game)
        XCTAssertEqual(line.id, "guide.patterns-growth.1")
        XCTAssertEqual(line.text, "Oh! A star grew. Grown stars carry twice the starlight, but each still counts as one star in a square, cross or straight line.")
        XCTAssertFalse(line.text.contains("more space"))
        XCTAssertFalse(line.text.contains("room again"))
    }

    @MainActor func testFullBoardReportsEightActualRefillsInsteadOfTemporaryRoomAndRetainsCoreMastery() throws {
        var opening = FallingSky.fullBoardLantern()
        XCTAssertTrue(opening.enrollMastery(runID: UUID(uuidString: "690AC72C-9CB2-4649-BD52-F13B53941BC9")!))
        for quiet in [false, true] {
            let fixture = try make(opening, quiet: quiet)
            defer { fixture.store.setSuspended(true) }
            let world = fixture.store.journey.journey
            let worldBytes = fixture.defaults.data(forKey: WorldJourneyStore.key)
            let masteryBytes = fixture.defaults.data(forKey: StoryMasteryStore.key)
            let turn = try exchange((Cell(1, 1), Cell(1, 2)), in: fixture)
            XCTAssertEqual(turn.resolutionPhases.map(\.cleared.count), [4, 4])
            XCTAssertEqual(turn.resolutionPhases.map(\.refillArrivals.count), [4, 4])
            XCTAssertEqual(turn.displayAward, 15_000)
            XCTAssertEqual(fixture.store.game.occupiedCount, 49)
            XCTAssertEqual(heights(fixture.store.game), Array(repeating: 7, count: 7))
            XCTAssertTrue(fixture.store.forecast.isEmpty)
            XCTAssertNil(fixture.clock.deadline)
            let original = SkyDialogueLibrary.line("guide.cascade", values: ["depth": "2", "score": "15,000"])
            assertLine(fixture.store.guideLine, preserves: original,
                       scoreText: "8 stars · 8 light. 8,000 base + 2,000 size + 5,000 chain = 15,000 points. Diamond marks: 2 survivors fell into later patterns.",
                       suffix: refillText)
            XCTAssertFalse(fixture.store.guideLine.text.contains("more spaces"))
            XCTAssertFalse(fixture.store.guideLine.text.contains("room again"))
            var expected = opening
            XCTAssertNotNil(expected.nudge(from: Cell(1, 1), to: Cell(1, 2)))
            XCTAssertEqual(fixture.store.game.masteryEnrollment, opening.masteryEnrollment)
            XCTAssertEqual(fixture.store.game.masteryProgress, expected.masteryProgress)
            XCTAssertEqual(fixture.store.journey.journey, world)
            XCTAssertEqual(fixture.defaults.data(forKey: WorldJourneyStore.key), worldBytes)
            XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), masteryBytes)
            let line = fixture.store.guideLine
            XCTAssertEqual(fixture.feedback.announcements, [line.spokenText])
            fixture.presenter.finish(); fixture.presenter.finish()
            XCTAssertEqual(fixture.feedback.announcements, [line.spokenText])
            XCTAssertNil(fixture.clock.deadline)
            fixture.clock.advance(100)
            fixture.store.callShower()
            XCTAssertEqual(fixture.store.game, expected)
            XCTAssertEqual(SkySaveArchive.load(from: fixture.defaults), expected)
        }
    }

    @MainActor func testSuspensionAndColdRestoreCannotRecreateTheCommittedRoomMessageFromAStaleCompletion() throws {
        for quiet in [false, true] {
            let fixture = try make(.freshChallenge(.kiteHarbor), quiet: quiet)
            defer { fixture.store.setSuspended(true) }
            try exchange(spaceMove, in: fixture)
            let stale = try XCTUnwrap(fixture.presenter.completions.last)
            let committed = fixture.store.game
            let saved = fixture.defaults.data(forKey: SkySaveArchive.key)
            fixture.store.setSuspended(true)
            let line = fixture.store.guideLine, revision = fixture.store.dialogue.revision
            let announcements = fixture.feedback.announcements
            stale(); fixture.clock.advance(30); stale()
            XCTAssertEqual(fixture.store.game, committed)
            XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), saved)
            XCTAssertEqual(fixture.store.guideLine, line)
            XCTAssertEqual(fixture.store.dialogue.revision, revision)
            XCTAssertEqual(fixture.feedback.announcements, announcements)
            XCTAssertNil(fixture.clock.deadline)

            let clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
            let restored = FallingSkyStore(defaults: fixture.defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: clock, feedback: feedback)
            restored.setSuspended(false)
            defer { restored.setSuspended(true) }
            XCTAssertEqual(restored.game, committed)
            XCTAssertEqual(restored.guideLine.id, "guide.restore.1")
            XCTAssertFalse(restored.guideLine.text.contains("more spaces"))
            XCTAssertFalse(restored.guideLine.text.contains("room again"))
            XCTAssertTrue(feedback.announcements.isEmpty)
            XCTAssertTrue(restored.isPaused)
            XCTAssertNil(clock.deadline)
            XCTAssertNil(restored.celebration)
            XCTAssertNil(restored.finalLight)

            fixture.store.restart(sameSky: true)
            let replay = fixture.store.game, replayLine = fixture.store.guideLine
            let replaySaved = fixture.defaults.data(forKey: SkySaveArchive.key)
            stale()
            XCTAssertEqual(replay, FallingSky.freshChallenge(.kiteHarbor))
            XCTAssertEqual(fixture.store.game, replay)
            XCTAssertEqual(fixture.store.guideLine, replayLine)
            XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), replaySaved)
            XCTAssertEqual(fixture.feedback.announcements, announcements)
        }
    }

    @MainActor func testNewerIngredientHelpRejectsDuplicateOldCompletionAfterTheClearActuallySettles() throws {
        let fixture = try make(.freshChallenge(.kiteHarbor))
        defer { fixture.store.setSuspended(true) }
        try exchange(spaceMove, in: fixture)
        XCTAssertEqual(fixture.feedback.announcements.count, 1)
        let current = fixture.store.game, deadline = fixture.clock.deadline
        let staleCompletion = try XCTUnwrap(fixture.presenter.completions.last)
        let saved = fixture.defaults.data(forKey: SkySaveArchive.key)
        let world = fixture.defaults.data(forKey: WorldJourneyStore.key)
        let mastery = fixture.defaults.data(forKey: StoryMasteryStore.key)
        XCTAssertFalse(fixture.store.canContact(Cell(0, 2)), "An automatic recipe reserves the whole committed phase")
        fixture.presenter.finish()
        XCTAssertFalse(fixture.store.busy)
        XCTAssertTrue(fixture.store.canContact(Cell(0, 2)), "Actual settlement admits the newer inspection")
        XCTAssertEqual(fixture.feedback.announcements.count, 1)
        let help = try XCTUnwrap(SkyDialogueLibrary.ingredientInspection(at: Cell(0, 2), game: current))
        XCTAssertFalse(fixture.store.requestTap(Cell(0, 2)), "Ingredient inspection is not another committed action")
        XCTAssertEqual(fixture.store.dialogue.line, help)
        XCTAssertEqual(fixture.feedback.announcements.count, 2)
        XCTAssertEqual(fixture.feedback.announcements.last, help.spokenText)
        XCTAssertEqual(fixture.store.game, current)
        XCTAssertEqual(fixture.clock.deadline, deadline)
        XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), saved)
        XCTAssertEqual(fixture.defaults.data(forKey: WorldJourneyStore.key), world)
        XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), mastery)
        let revision = fixture.store.dialogue.revision, announcements = fixture.feedback.announcements
        staleCompletion(); staleCompletion()
        XCTAssertEqual(fixture.store.dialogue.line, help)
        XCTAssertEqual(fixture.store.dialogue.revision, revision)
        XCTAssertEqual(fixture.feedback.announcements, announcements)
        XCTAssertEqual(fixture.store.game, current)
        XCTAssertEqual(fixture.clock.deadline, deadline)
        XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), saved)
        XCTAssertEqual(fixture.defaults.data(forKey: WorldJourneyStore.key), world)
        XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), mastery)
    }

    @MainActor func testActualWinAndOverflowRetainTerminalPrecedenceWithoutRoomOrRefillPromises() throws {
        for ceremony in [false, true] {
            let fixture = try make(.freshChallenge(.silverPools))
            defer { fixture.store.setSuspended(true) }
            fixture.store.terminalSpeech = ceremony ? .ceremony : .feedback
            let before = fixture.store.game
            let turn = try exchange((Cell(1, 2), Cell(1, 3)), in: fixture)
            XCTAssertEqual(fixture.store.game.outcome, .won)
            XCTAssertEqual(fixture.store.game.displayScore, 19_000)
            let original = SkyDialogueLibrary.line("guide.silver-won", values: ["score": "19,000"])
            XCTAssertEqual(fixture.store.guideLine, original)
            XCTAssertEqual(result(turn, from: before, to: fixture.store.game), original)
            fixture.presenter.finish(); fixture.presenter.finish()
            XCTAssertEqual(fixture.feedback.announcements, ceremony ? [] : [original.spokenText])
            XCTAssertNil(fixture.clock.deadline)
            XCTAssertEqual(fixture.store.journey.journey.completed, [.silverPools])
        }

        var crowded = FallingSky.freshChallenge(.kiteHarbor)
        XCTAssertNotNil(crowded.letStarsFall())
        let fixture = try make(crowded)
        defer { fixture.store.setSuspended(true) }
        fixture.store.callShower()
        XCTAssertEqual(fixture.store.game.outcome, .lost)
        XCTAssertEqual(fixture.store.game.displayScore, 0)
        let original = SkyDialogueLibrary.line("guide.full", values: ["score": "0"])
        XCTAssertEqual(fixture.store.guideLine, original)
        fixture.presenter.finish(); fixture.presenter.finish()
        XCTAssertEqual(fixture.feedback.announcements, [original.spokenText])
        XCTAssertNil(fixture.clock.deadline)
        XCTAssertTrue(fixture.store.journey.journey.completed.isEmpty)
    }
}
