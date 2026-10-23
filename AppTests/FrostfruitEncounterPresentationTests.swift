import XCTest
import StarfallCore
@testable import Starfall

final class FrostfruitEncounterPresentationTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FrostfruitEncounterPresentation.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.set(false, forKey: "soundEnabled")
        defaults.set(false, forKey: "starfall.haptics")
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor private func historical() -> FallingSky {
        ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .frostfruitOrchard)
    }

    @MainActor private func repairedSilver() throws -> FallingSky {
        var game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .silverPools)
        _ = try XCTUnwrap(game.clear(Cell(0, 0)))
        XCTAssertEqual(game.outcome, .won)
        XCTAssertTrue(game.isValidSave)
        return game
    }

    @MainActor func testNewEntryAndRetainedReplaySelectTheirOwnObjectiveAndInstructions() throws {
        let retained = historical(), fresh = FallingSky.freshChallenge(.frostfruitOrchard)
        let bytes = try SkySaveArchive.encode(retained)
        XCTAssertEqual(fresh.challengeRevision, 8)
        XCTAssertEqual(fresh.displayTarget, 15_000)
        let entry = SkyEntryRequest.frostfruitOrchard.introduction(challenge: .frostfruitOrchard,
            replayingRevision: retained.challengeRevision, replayingTarget: retained.displayTarget)
        let currentReplay = SkyEntryRequest.replay.introduction(challenge: .frostfruitOrchard,
            replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
        let currentGuide = try XCTUnwrap(fresh.challengeGuideLine)
        XCTAssertEqual(entry.id, "frostfruit-orchard.patterns.entry.1")
        XCTAssertEqual(currentReplay.id, "frostfruit-orchard.patterns.replay.1")
        XCTAssertEqual(currentGuide.id, "guide.frostfruit-orchard.patterns.1")
        for text in [entry.text, currentReplay.text, currentGuide.text] {
            XCTAssertTrue(text.contains("Frostfruit Orchard"))
            XCTAssertTrue(text.contains("15,000 starlight"))
            XCTAssertTrue(text.contains("Violet square"))
            XCTAssertFalse(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("chain"))
        }
        for text in [entry.text, currentGuide.text] {
            XCTAssertTrue(text.contains("straight lines of 4 or more"))
            XCTAssertTrue(text.contains("automatically"))
        }
        XCTAssertTrue(entry.text.contains("saved round stays until you tap Begin"))
        XCTAssertTrue(currentReplay.text.contains("same Frostfruit Orchard opening"))
        let oldReplay = SkyEntryRequest.replay.introduction(challenge: .frostfruitOrchard,
            replayingRevision: retained.challengeRevision, replayingTarget: retained.displayTarget)
        XCTAssertEqual(oldReplay.id, "frostfruit-orchard.replay.1")
        XCTAssertEqual(retained.challengeGuideLine?.id, "guide.frostfruit-orchard.1")
        for text in [oldReplay.text, try XCTUnwrap(retained.challengeGuideLine).text,
                     try XCTUnwrap(retained.challengeHelpText)] {
            XCTAssertTrue(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("15,000"))
            XCTAssertFalse(text.contains("automatically"))
        }
        XCTAssertEqual(try SkySaveArchive.encode(retained), bytes)
    }

    @MainActor func testHelpUsesAutomaticFrostfruitRulesAndKeepsHistoricalAndOtherModesSeparate() throws {
        let fresh = FallingSky.freshChallenge(.frostfruitOrchard), retained = historical()
        let help = SkyHelpContext.selected(game: retained, entry: .frostfruitOrchard)
        XCTAssertEqual(help, SkyHelpContext(game: fresh))
        XCTAssertFalse(help.manualClears)
        XCTAssertTrue(help.automaticRecipes)
        XCTAssertEqual(help.automaticLineLength, 4)
        XCTAssertFalse(help.fullBoard)
        XCTAssertFalse(help.opalStorms)
        XCTAssertFalse(help.criticalMass)
        XCTAssertNil(help.practiceChapter)
        let text = try XCTUnwrap(help.restorationHelp)
        for fact in ["15,000 starlight", "grow in place", "Violet square earns 5,000",
                     "grown top cannot grow again", "ordered forecast", "straight lines of 4 or more"] {
            XCTAssertTrue(text.contains(fact), fact)
        }
        XCTAssertFalse(text.contains("chain"))
        XCTAssertTrue(SkyHelpContext.selected(game: retained, entry: .replay).manualClears)
        XCTAssertEqual(SkyHelpContext.selected(game: fresh, entry: .replay), help)
        XCTAssertTrue(SkyEntryRequest.frostfruitOrchard.modeChoices.isEmpty)
        XCTAssertNil(SkyEntryRequest.frostfruitOrchard.practiceChapter)
        XCTAssertFalse(StarfallChallenge.frostfruitOrchard.menuLabel.contains("18 starlight"))
        XCTAssertFalse(StarfallChallenge.frostfruitOrchard.menuHint.contains("18 starlight"))
        XCTAssertEqual(FallingSky.fullBoardLantern().challengeRevision, 6)
        XCTAssertEqual(FallingSky.fullBoardRibbon().challengeRevision, 7)
        XCTAssertTrue(FallingSky.fullBoardLantern().usesFullBoardRefill)
        XCTAssertTrue(FallingSky.fullBoardRibbon().usesFullBoardRefill)
        let sunwheel = FallingSky.freshChallenge(.sunwheelMill)
        XCTAssertEqual(sunwheel.challengeRevision, 0)
        XCTAssertTrue(sunwheel.supportsManualClears)
        XCTAssertTrue(sunwheel.challengeHelpText?.contains("18 starlight") == true)
    }

    @MainActor func testSharedMapAndPlacesGoalKeepsSavedEighteenBesideNewFifteenThousand() throws {
        var journey = WorldJourney()
        journey.record(try repairedSilver())
        journey.select(.frostfruitOrchard)
        XCTAssertTrue(journey.canEnter(.frostfruitOrchard))
        let originalJourney = journey
        var current = FallingSky.freshChallenge(.frostfruitOrchard)
        _ = try XCTUnwrap(current.nudge(from: Cell(2, 6), to: Cell(2, 5)))
        for retained in [historical(), current] {
            let bytes = try SkySaveArchive.encode(retained)
            let goal = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: retained))
            XCTAssertEqual(goal.newVisitTarget, 15_000)
            XCTAssertEqual(goal.newVisitLabel, "New visit objective: 15,000 starlight.")
            XCTAssertEqual(goal.retainedProgress, retained.restoration)
            XCTAssertEqual(goal.retainedLabel,
                "Saved round: \(SkyCopy.score(retained.displayScore)) of \(SkyCopy.score(try XCTUnwrap(retained.displayTarget))) starlight.")
            XCTAssertEqual(RestorationPresentation.selected(game: retained, entry: .frostfruitOrchard)?.progress,
                           StarlightRestoration(score: 0, target: 15_000))
            XCTAssertEqual(RestorationPresentation.selected(game: retained, entry: .replay)?.progress,
                           StarlightRestoration(score: 0, target: try XCTUnwrap(retained.displayTarget)))
            XCTAssertEqual(try SkySaveArchive.encode(retained), bytes)
            XCTAssertEqual(journey, originalJourney)
        }
    }

    @MainActor func testEntryPreviewAndCancellationKeepSavedRoundAndWorldUnchanged() throws {
        var current = FallingSky.freshChallenge(.frostfruitOrchard)
        _ = try XCTUnwrap(current.nudge(from: Cell(2, 6), to: Cell(2, 5)))
        for retained in [historical(), current] {
            let defaults = defaults()
            try SkySaveArchive.save(retained, to: defaults)
            let world = WorldJourneyStore(defaults: defaults)
            try world.record(repairedSilver())
            try world.select(.frostfruitOrchard)
            let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            let worldBytes = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                        clock: clock, feedback: SkyFeedbackRecorder())
            var flow = SkyFlowState(arguments: [])
            _ = flow.handle(.worldMap, hasSavedSky: true)
            XCTAssertEqual(flow.handle(.frostfruitOrchard, hasSavedSky: true), .staged)
            let id = try XCTUnwrap(flow.entryID)
            XCTAssertEqual(flow.entry?.previewGame(retaining: store.game), FallingSky.freshChallenge(.frostfruitOrchard))
            XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: flow.entry)?.progress,
                           StarlightRestoration(score: 0, target: 15_000))
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

    @MainActor func testBeginStartupGuideAndReplayUseTheActualFrostfruitEightOpening() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: SkyFeedbackRecorder())
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.frostfruitOrchard, hasSavedSky: false)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: false, entryID: flow.entryID), .began(.frostfruitOrchard))
        store.beginEntry(.frostfruitOrchard)
        let opening = FallingSky.freshChallenge(.frostfruitOrchard)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(store.guideLine.id, "guide.frostfruit-orchard.patterns.1")
        XCTAssertTrue(store.guideLine.text.contains("15,000"))
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        store.setSuspended(false)
        XCTAssertTrue(store.canReceiveInput)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(5, 0), Cell(5, 1)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        presenter.finish()
        let announced = store.forecast
        store.callShower()
        XCTAssertEqual(store.pending?.forecast, announced)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
        presenter.finish()
        XCTAssertEqual(store.game.turns, 1)
        XCTAssertEqual(store.game.board.compactMap { $0 }.filter(\.grown).count, 2)
        let continued = store.game
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
            clock: ManualRainClock(), feedback: SkyFeedbackRecorder())
        XCTAssertEqual(restored.game, continued)
        XCTAssertEqual(restored.game.challengeGuideLine?.id, "guide.frostfruit-orchard.patterns.1")
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertEqual(restored.game.challengeRevision, 8)
        XCTAssertFalse(restored.game.supportsManualClears)
        restored.setSuspended(true)
        store.setSuspended(true)
    }

    @MainActor func testHelpTradeoffMatchesActualGrownCapsAndTheUnchangedOrderedForecast() throws {
        let opening = FallingSky.freshChallenge(.frostfruitOrchard)
        var keepingRoom = opening, takingPoints = opening
        let setup = try XCTUnwrap(keepingRoom.nudge(from: Cell(5, 0), to: Cell(5, 1)))
        let clear = try XCTUnwrap(takingPoints.nudge(from: Cell(2, 6), to: Cell(2, 5)))
        XCTAssertEqual(setup.displayAward, 0)
        XCTAssertEqual(clear.displayAward, 5_000)
        XCTAssertEqual(clear.resolutionPhases.count, 1)
        XCTAssertEqual(clear.resolutionPhases.first?.recipes.map(\.shape), [.square])
        let firstClear = try XCTUnwrap(clear.resolutionPhases.first)
        XCTAssertTrue(firstClear.cleared.allSatisfy { firstClear.before[$0.row * 7 + $0.column]?.kind == .violet })
        XCTAssertEqual(keepingRoom.incoming, opening.incoming)
        XCTAssertEqual(takingPoints.incoming, opening.incoming)
        let matchingWave = try XCTUnwrap(keepingRoom.letStarsFall())
        let fillingWave = try XCTUnwrap(takingPoints.letStarsFall())
        XCTAssertEqual(matchingWave.forecast, fillingWave.forecast)
        XCTAssertEqual(matchingWave.arrivals.filter(\.grew).count, 2)
        XCTAssertTrue(fillingWave.arrivals.allSatisfy { !$0.grew })
        XCTAssertEqual((0..<2).map { SkyBoardSettling.height(keepingRoom.board, column: $0) }, [6, 6])
        XCTAssertEqual((0..<2).map { SkyBoardSettling.height(takingPoints.board, column: $0) }, [7, 7])
        XCTAssertEqual(keepingRoom.incoming, takingPoints.incoming)
        let accepting = try XCTUnwrap(keepingRoom.letStarsFall())
        let blocked = try XCTUnwrap(takingPoints.letStarsFall())
        XCTAssertEqual(accepting.arrivals.count, accepting.forecast.count)
        XCTAssertNil(accepting.blockedColumn)
        XCTAssertEqual(blocked.blockedColumn, 0)
        XCTAssertTrue(keepingRoom.isValidSave)
        XCTAssertTrue(takingPoints.isValidSave)
        let help = try XCTUnwrap(opening.challengeHelpText)
        XCTAssertTrue(help.contains("keeping room in the crowded columns"))
        XCTAssertTrue(help.contains("first shower then fills the two left columns"))
        XCTAssertTrue(help.contains("matching its color does not guarantee a landing"))
    }
}
