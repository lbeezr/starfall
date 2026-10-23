import XCTest
import StarfallCore
@testable import Starfall

final class SunwheelEncounterPresentationTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.SunwheelEncounterPresentation.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(false, forKey: "soundEnabled")
        defaults.set(false, forKey: "starfall.haptics")
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor private func historical() -> FallingSky {
        ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .sunwheelMill)
    }

    private func repairedFrostfruit() throws -> FallingSky {
        var game = FallingSky.freshChallenge(.frostfruitOrchard)
        _ = try XCTUnwrap(game.nudge(from: Cell(5, 0), to: Cell(5, 1)))
        _ = try XCTUnwrap(game.letStarsFall())
        _ = try XCTUnwrap(game.letStarsFall())
        for (from, to) in [(20, 19), (2, 9), (3, 10)] {
            _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertTrue(game.isValidSave)
        return game
    }

    @MainActor func testCurrentEntryGuideAndReplayKeepTheirTargetApartFromHistoricalEighteen() throws {
        let fresh = FallingSky.freshChallenge(.sunwheelMill), retained = historical()
        let bytes = try SkySaveArchive.encode(retained)
        XCTAssertEqual(fresh.challengeRevision, 9)
        XCTAssertEqual(fresh.displayTarget, 24_000)
        let entry = SkyEntryRequest.sunwheelMill.introduction(challenge: .sunwheelMill,
            replayingRevision: retained.challengeRevision, replayingTarget: retained.displayTarget)
        let replay = SkyEntryRequest.replay.introduction(challenge: .sunwheelMill,
            replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
        let guide = try XCTUnwrap(fresh.challengeGuideLine)
        XCTAssertEqual(entry.id, "sunwheel-mill.patterns.entry.1")
        XCTAssertEqual(replay.id, "sunwheel-mill.patterns.replay.1")
        XCTAssertEqual(guide.id, "guide.sunwheel-mill.patterns.1")
        for text in [entry.text, replay.text, guide.text] {
            XCTAssertTrue(text.contains("Sunwheel Mill"))
            XCTAssertTrue(text.contains("24,000 starlight"))
            XCTAssertFalse(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("Frostfruit"))
        }
        for text in [entry.text, guide.text] {
            XCTAssertTrue(text.contains("straight lines of 4 or more"))
            XCTAssertTrue(text.contains("automatically"))
        }
        XCTAssertTrue(entry.text.contains("saved round stays until you tap Begin"))
        XCTAssertTrue(replay.text.contains("same Sunwheel Mill opening"))
        let oldReplay = SkyEntryRequest.replay.introduction(challenge: .sunwheelMill,
            replayingRevision: retained.challengeRevision, replayingTarget: retained.displayTarget)
        XCTAssertEqual(oldReplay.id, "sunwheel-mill.replay.1")
        XCTAssertEqual(retained.challengeGuideLine?.id, "guide.sunwheel-mill.1")
        for text in [oldReplay.text, try XCTUnwrap(retained.challengeGuideLine).text,
                     try XCTUnwrap(retained.challengeHelpText)] {
            XCTAssertTrue(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("24,000"))
            XCTAssertFalse(text.contains("automatically"))
        }
        XCTAssertEqual(try SkySaveArchive.encode(retained), bytes)
    }

    @MainActor func testAutomaticHelpFollowsSunwheelRulesWithoutOfferingAnotherModeOrPractice() throws {
        let fresh = FallingSky.freshChallenge(.sunwheelMill), retained = historical()
        let help = SkyHelpContext.selected(game: retained, entry: .sunwheelMill)
        XCTAssertEqual(help, SkyHelpContext(game: fresh))
        XCTAssertFalse(help.manualClears)
        XCTAssertTrue(help.automaticRecipes)
        XCTAssertEqual(help.automaticLineLength, 4)
        XCTAssertFalse(help.fullBoard)
        XCTAssertFalse(help.opalStorms)
        XCTAssertFalse(help.criticalMass)
        XCTAssertNil(help.practiceChapter)
        let text = try XCTUnwrap(help.restorationHelp)
        XCTAssertTrue(text.contains("24,000 starlight"))
        XCTAssertTrue(text.contains("grown aqua"))
        XCTAssertTrue(text.contains("straight lines of 4 or more"))
        XCTAssertTrue(text.contains("forecast"))
        XCTAssertTrue(SkyHelpContext.selected(game: retained, entry: .replay).manualClears)
        XCTAssertEqual(SkyHelpContext.selected(game: fresh, entry: .replay), help)
        XCTAssertTrue(SkyEntryRequest.sunwheelMill.modeChoices.isEmpty)
        XCTAssertNil(SkyEntryRequest.sunwheelMill.practiceChapter)
        XCTAssertFalse(StarfallChallenge.sunwheelMill.menuLabel.contains("18 starlight"))
        XCTAssertFalse(StarfallChallenge.sunwheelMill.menuHint.contains("18 starlight"))
        XCTAssertEqual(FallingSky.fullBoardLantern().challengeRevision, 6)
        XCTAssertEqual(FallingSky.fullBoardRibbon().challengeRevision, 7)
        XCTAssertEqual(FallingSky.freshChallenge(.firstLight).challengeRevision, 4)
        XCTAssertEqual(FallingSky.freshChallenge(.ribbonCrossing).challengeRevision, 4)
        XCTAssertEqual(FallingSky.freshChallenge(.frostfruitOrchard).challengeRevision, 8)
    }

    @MainActor func testSharedMapAndPlacesSnapshotShowsCurrentGoalAlongsideTheRetainedScale() throws {
        var journey = WorldJourney()
        journey.record(try repairedFrostfruit())
        journey.select(.sunwheelMill)
        XCTAssertTrue(journey.canEnter(.sunwheelMill))
        let originalJourney = journey
        for retained in [historical(), FallingSky.freshChallenge(.sunwheelMill)] {
            let bytes = try SkySaveArchive.encode(retained)
            let goal = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: retained))
            XCTAssertEqual(goal.newVisitTarget, 24_000)
            XCTAssertEqual(goal.newVisitLabel, "New visit objective: 24,000 starlight.")
            XCTAssertEqual(goal.retainedProgress, retained.restoration)
            XCTAssertEqual(goal.retainedLabel,
                "Saved round: \(SkyCopy.score(retained.displayScore)) of \(SkyCopy.score(try XCTUnwrap(retained.displayTarget))) starlight.")
            XCTAssertEqual(RestorationPresentation.selected(game: retained, entry: .sunwheelMill)?.progress,
                           StarlightRestoration(score: 0, target: 24_000))
            XCTAssertEqual(RestorationPresentation.selected(game: retained, entry: .replay)?.progress,
                           StarlightRestoration(score: 0, target: try XCTUnwrap(retained.displayTarget)))
            XCTAssertEqual(try SkySaveArchive.encode(retained), bytes)
            XCTAssertEqual(journey, originalJourney)
        }
    }

    @MainActor func testEntryPreviewAndCancellationLeaveRetainedRoundAndEarnedWorldBytesUntouched() throws {
        for retained in [historical(), FallingSky.freshChallenge(.sunwheelMill)] {
            let defaults = defaults()
            try SkySaveArchive.save(retained, to: defaults)
            let world = WorldJourneyStore(defaults: defaults)
            try world.record(repairedFrostfruit())
            try world.select(.sunwheelMill)
            let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            let worldBytes = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                        clock: clock, feedback: SkyFeedbackRecorder())
            var flow = SkyFlowState(arguments: [])
            _ = flow.handle(.worldMap, hasSavedSky: true)
            XCTAssertEqual(flow.handle(.sunwheelMill, hasSavedSky: true), .staged)
            let id = try XCTUnwrap(flow.entryID)
            XCTAssertEqual(flow.entry?.previewGame(retaining: store.game), FallingSky.freshChallenge(.sunwheelMill))
            XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: flow.entry)?.progress,
                           StarlightRestoration(score: 0, target: 24_000))
            XCTAssertFalse(SkyHelpContext.selected(game: store.game, entry: flow.entry).manualClears)
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: id), .worldMap)
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: id))
            clock.advance(100)
            XCTAssertNil(clock.deadline)
            XCTAssertEqual(store.game, retained)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
        }
    }

    @MainActor func testStoreBeginsRestoresContinuesAndReplaysTheExactCurrentEncounter() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: SkyFeedbackRecorder())
        defer { store.setSuspended(true) }
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.sunwheelMill, hasSavedSky: false)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: false, entryID: flow.entryID), .began(.sunwheelMill))
        store.beginEntry(.sunwheelMill)
        let opening = FallingSky.freshChallenge(.sunwheelMill)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(store.game.occupiedCount, 26)
        XCTAssertEqual(store.game.gem(at: Cell(0, 0))?.id, 0)
        XCTAssertTrue(store.game.gem(at: Cell(0, 0))?.grown == true)
        XCTAssertEqual(store.guideLine.id, "guide.sunwheel-mill.patterns.1")
        XCTAssertTrue(store.guideLine.text.contains("24,000"))
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        store.setSuspended(false)
        XCTAssertTrue(store.canReceiveInput)
        var expected = opening
        let turn = try XCTUnwrap(expected.nudge(from: Cell(1, 2), to: Cell(1, 3)))
        XCTAssertEqual(turn.displayAward, 21_000)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 16_000])
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 2), Cell(1, 3)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), expected,
                       "Both phases commit before any presenter completion")
        let bytes = defaults.data(forKey: SkySaveArchive.key)
        let restoredPresenter = FallingSkyRecorder()
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: restoredPresenter,
            clock: ManualRainClock(), feedback: SkyFeedbackRecorder())
        defer { restored.setSuspended(true) }
        XCTAssertEqual(restored.game, expected)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertFalse(restored.openingPending)
        XCTAssertEqual(restored.game.challengeGuideLine?.id, "guide.sunwheel-mill.patterns.1")
        restored.setSuspended(false)
        let announced = expected.incoming
        _ = try XCTUnwrap(expected.letStarsFall())
        restored.callShower()
        XCTAssertEqual(restored.pending?.forecast, announced)
        XCTAssertEqual(restored.game, expected)
        restoredPresenter.finish()
        _ = try XCTUnwrap(expected.nudge(from: Cell(0, 0), to: Cell(1, 0)))
        XCTAssertTrue(restored.performTechnique(.nudge(Cell(0, 0), Cell(1, 0)),
            snapshot: restored.game, generation: restored.constellationInputGeneration))
        XCTAssertEqual(restored.game, expected)
        XCTAssertEqual(restored.game.displayScore, 26_000)
        XCTAssertEqual(restored.game.outcome, .won)
        XCTAssertTrue(restored.journey.journey.completed.contains(.sunwheelMill))
        XCTAssertFalse(restored.journey.journey.canEnter(.bellChoir))
        restoredPresenter.finish()
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertEqual(restored.game.challengeRevision, 9)
        XCTAssertFalse(restored.game.supportsManualClears)
        presenter.finish()
    }

    @MainActor func testHelpTradeoffMatchesTheGrownIngredientChainAndReceivingSpace() throws {
        let opening = FallingSky.freshChallenge(.sunwheelMill)
        var space = opening, sequence = opening
        let direct = try XCTUnwrap(space.nudge(from: Cell(2, 1), to: Cell(2, 0)))
        let chain = try XCTUnwrap(sequence.nudge(from: Cell(1, 2), to: Cell(1, 3)))
        XCTAssertEqual(direct.displayAward, 6_000)
        XCTAssertEqual(direct.resolutionPhases.count, 1)
        XCTAssertEqual(chain.displayAward, 21_000)
        XCTAssertEqual(chain.resolutionPhases.map(\.award.displayPoints), [5_000, 16_000])
        XCTAssertEqual(chain.resolutionPhases.map(\.comboDepth), [1, 2])
        XCTAssertEqual(chain.resolutionPhases.map { $0.recipes.map(\.shape) }, [[.line], [.line]])
        let followup = chain.resolutionPhases[1]
        let followupIDs = Set(followup.recipes.flatMap(\.starIDs))
        XCTAssertEqual(followupIDs, [0, 1, 3, 4, 23])
        XCTAssertTrue(followupIDs.isSubset(of: Set(opening.board.compactMap { $0?.id })))
        XCTAssertEqual(opening.gem(at: Cell(4, 2))?.id, 23)
        XCTAssertEqual(followup.before[2]?.id, 23, "The visible survivor falls four rows into the later line")
        XCTAssertTrue(followup.before[0]?.grown == true)
        XCTAssertEqual(SkyBoardSettling.height(space.board, column: 0), 3)
        XCTAssertEqual(SkyBoardSettling.height(sequence.board, column: 0), 6)
        XCTAssertEqual(space.incoming, opening.incoming)
        XCTAssertEqual(sequence.incoming, opening.incoming)
        let spaceFirst = try XCTUnwrap(space.letStarsFall())
        let sequenceFirst = try XCTUnwrap(sequence.letStarsFall())
        XCTAssertEqual(spaceFirst.forecast, sequenceFirst.forecast)
        XCTAssertNil(spaceFirst.blockedColumn)
        XCTAssertNil(sequenceFirst.blockedColumn)
        XCTAssertEqual(SkyBoardSettling.height(space.board, column: 0), 4)
        XCTAssertEqual(SkyBoardSettling.height(sequence.board, column: 0), 7)
        XCTAssertEqual(space.incoming, sequence.incoming)
        let accepting = try XCTUnwrap(space.letStarsFall())
        let blocked = try XCTUnwrap(sequence.letStarsFall())
        XCTAssertEqual(accepting.arrivals.count, accepting.forecast.count)
        XCTAssertNil(accepting.blockedColumn)
        XCTAssertEqual(blocked.blockedColumn, 0)
        XCTAssertEqual(blocked.arrivals.count, 3)
        XCTAssertTrue(space.isValidSave)
        XCTAssertTrue(sequence.isValidSave)
        let help = try XCTUnwrap(opening.challengeHelpText)
        for fact in ["four-star line earns 6,000", "opens four spaces", "rose supports instead earns 5,000",
                     "falls four rows", "five-star line", "16,000", "21,000 total in the same action",
                     "opens only one space", "same ordered forecast", "unless you make room"] {
            XCTAssertTrue(help.contains(fact), fact)
        }
    }
}
