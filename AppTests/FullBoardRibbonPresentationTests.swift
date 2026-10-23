import XCTest
import StarfallCore
@testable import Starfall

final class FullBoardRibbonPresentationTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FullBoardRibbonPresentation.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    private func lantern(_ revision: Int) throws -> FallingSky {
        FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision)))
    }

    @MainActor func testRibbonModeCatalogueKeepsNewSkyVisitAndBothLanternChoices() {
        let retained = FallingSky.fullBoardLantern()
        for entry in [SkyEntryRequest.ribbonCrossing, .fullBoardRibbon] {
            XCTAssertEqual(entry.modeChallenge, .ribbonCrossing)
            XCTAssertEqual(entry.modeChoices, [.ribbonCrossing, .fullBoardRibbon])
            XCTAssertEqual(entry.selectedChallenge(replaying: .firstLight), .ribbonCrossing)
            XCTAssertNil(entry.practiceChapter)
        }
        XCTAssertEqual(SkyEntryRequest.ribbonCrossing.modeAction, .ribbonCrossing)
        XCTAssertEqual(SkyEntryRequest.fullBoardRibbon.modeAction, .fullBoardRibbon)
        XCTAssertFalse(SkyEntryRequest.ribbonCrossing.isFullBoardEntry)
        XCTAssertTrue(SkyEntryRequest.fullBoardRibbon.isFullBoardEntry)
        let sky = SkyEntryRequest.ribbonCrossing.previewGame(retaining: retained)
        let full = SkyEntryRequest.fullBoardRibbon.previewGame(retaining: retained)
        XCTAssertEqual(sky, FallingSky.freshChallenge(.ribbonCrossing))
        XCTAssertEqual(sky.challengeRevision, 4)
        XCTAssertFalse(sky.usesFullBoardRefill)
        XCTAssertEqual(full, FallingSky.fullBoardRibbon())
        XCTAssertEqual(full.challengeRevision, 7)
        XCTAssertEqual(full.displayTarget, 220_000)
        XCTAssertEqual(full.occupiedCount, 49)
        XCTAssertEqual(SkyEntryRequest.firstLight.modeChoices, [.firstLight, .fullBoardLantern])
        XCTAssertEqual(SkyEntryRequest.fullBoardLantern.modeChoices, [.firstLight, .fullBoardLantern])
        XCTAssertTrue(SkyEntryRequest.replay.modeChoices.isEmpty)
        XCTAssertEqual(StarfallChallenge.ribbonCrossing.flowAction, .ribbonCrossing,
                       "The ordinary location action still stages Falling Sky first")
    }

    func testRibbonSelectionRejectsStaleIDsAndOtherLocationModesAndCancelsToItsMapOrigin() throws {
        for arguments in [[], ["--starfalls-reset"]] {
            var flow = SkyFlowState(arguments: arguments)
            let origin = flow.screen
            _ = flow.handle(.worldMap, hasSavedSky: true)
            XCTAssertEqual(flow.handle(.ribbonCrossing, hasSavedSky: true), .staged)
            let skyID = try XCTUnwrap(flow.entryID)
            let skyEntry = flow
            XCTAssertNil(flow.handle(.fullBoardRibbon, hasSavedSky: true))
            XCTAssertNil(flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: skyID))
            XCTAssertNil(flow.handle(.firstLight, hasSavedSky: true, entryID: skyID))
            XCTAssertEqual(flow, skyEntry)
            XCTAssertEqual(flow.handle(.fullBoardRibbon, hasSavedSky: true, entryID: skyID), .staged)
            let fullID = try XCTUnwrap(flow.entryID)
            XCTAssertNotEqual(fullID, skyID)
            let fullEntry = flow
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: skyID))
            XCTAssertNil(flow.handle(.ribbonCrossing, hasSavedSky: true, entryID: skyID))
            XCTAssertNil(flow.handle(.fullBoardRibbon, hasSavedSky: true, entryID: fullID))
            XCTAssertNil(flow.handle(.modePractice, hasSavedSky: true, entryID: fullID))
            XCTAssertEqual(flow, fullEntry)
            XCTAssertEqual(flow.handle(.ribbonCrossing, hasSavedSky: true, entryID: fullID), .staged)
            XCTAssertEqual(flow.entry, .ribbonCrossing)
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: fullID))
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
            XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), origin == .playing ? .continued : .home)
            XCTAssertEqual(flow.screen, origin)
            XCTAssertNil(flow.handoff)
        }
        var lanternFlow = SkyFlowState(arguments: [])
        _ = lanternFlow.handle(.firstLight, hasSavedSky: true)
        let lanternEntry = lanternFlow
        XCTAssertNil(lanternFlow.handle(.ribbonCrossing, hasSavedSky: true, entryID: lanternFlow.entryID))
        XCTAssertNil(lanternFlow.handle(.fullBoardRibbon, hasSavedSky: true, entryID: lanternFlow.entryID))
        XCTAssertEqual(lanternFlow, lanternEntry)
        var replay = SkyFlowState(arguments: ["--starfalls-reset"])
        _ = replay.handle(.replay, hasSavedSky: true)
        let retainedReplay = replay
        XCTAssertNil(replay.handle(.fullBoardRibbon, hasSavedSky: true, entryID: replay.entryID))
        XCTAssertEqual(replay, retainedReplay)
    }

    @MainActor func testBrowsingBothRibbonModesPreservesEveryRetainedRoundAndWorldByteForByte() throws {
        let retainedRounds = try [lantern(5), lantern(6)]
            + [FallingSky.freshChallenge(.ribbonCrossing), .fullBoardRibbon()]
        for retained in retainedRounds {
            let defaults = defaults()
            try SkySaveArchive.save(retained, to: defaults)
            try WorldJourneyStore(defaults: defaults).select(.firstLight)
            let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            let world = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
            var flow = SkyFlowState(arguments: [])
            _ = flow.handle(.worldMap, hasSavedSky: true)
            _ = flow.handle(.ribbonCrossing, hasSavedSky: true)
            for action in [SkyFlowAction.fullBoardRibbon, .ribbonCrossing, .fullBoardRibbon] {
                XCTAssertEqual(flow.handle(action, hasSavedSky: true, entryID: flow.entryID), .staged)
                let entry = try XCTUnwrap(flow.entry)
                let preview = entry.previewGame(retaining: store.game)
                XCTAssertEqual(preview.challenge, .ribbonCrossing)
                XCTAssertEqual(preview.challengeRevision, entry.isFullBoardEntry ? 7 : 4)
                XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: entry)?.progress.score, 0)
                XCTAssertEqual(SkyHelpContext.selected(game: store.game, entry: entry).fullBoard, entry.isFullBoardEntry)
                clock.advance(100)
                XCTAssertEqual(store.game, retained)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                XCTAssertNil(clock.deadline)
            }
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
            XCTAssertEqual(store.game, retained)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
        }
    }

    @MainActor func testBeginCommitsRibbonRefillsBeforePresentationAndRestoreReplayKeepRevisionSeven() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.ribbonCrossing, hasSavedSky: false)
        _ = flow.handle(.fullBoardRibbon, hasSavedSky: false, entryID: flow.entryID)
        guard case .began(let request) = flow.handle(.begin, hasSavedSky: false, entryID: flow.entryID) else {
            return XCTFail("Begin must consume the selected Ribbon mode")
        }
        XCTAssertEqual(request, .fullBoardRibbon)
        store.beginEntry(request)
        let opening = FallingSky.fullBoardRibbon()
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertEqual(store.dialogue.line?.id, "guide.full-board-ribbon.1")
        store.setSuspended(false)
        XCTAssertTrue(store.canReceiveInput)
        store.callShower(); store.togglePause(); clock.advance(100)
        XCTAssertEqual(store.game, opening)
        XCTAssertNil(clock.deadline)
        XCTAssertTrue(store.forecast.isEmpty)
        XCTAssertNil(store.pressureCue)
        var expected = opening
        let turn = try XCTUnwrap(expected.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(turn.displayAward, 30_000)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 1), Cell(1, 2)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), expected)
        XCTAssertEqual(expected.occupiedCount, 49)
        XCTAssertNil(clock.deadline)
        let bytes = defaults.data(forKey: SkySaveArchive.key)
        let restoredClock = ManualRainClock()
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: restoredClock)
        XCTAssertEqual(restored.game, expected)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertFalse(restored.openingPending)
        XCTAssertEqual(restored.dialogue.line?.id, "guide.full-board-ribbon-restore.1")
        XCTAssertTrue(restored.message.contains("Ribbon Crossing"))
        restored.setSuspended(false)
        XCTAssertNil(restoredClock.deadline)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertEqual(restored.dialogue.line?.id, "guide.full-board-ribbon.1")
        restored.beginEntry(.ribbonCrossing)
        XCTAssertEqual(restored.game, FallingSky.freshChallenge(.ribbonCrossing))
        XCTAssertEqual(restored.game.challengeRevision, 4)
        XCTAssertFalse(restored.game.usesFullBoardRefill)
        restored.togglePause()
        XCTAssertNotNil(restoredClock.deadline, "A new Falling Sky Ribbon visit retains its normal shower clock")
        restored.setSuspended(true)
        presenter.finish()
        store.setSuspended(true)
    }

    @MainActor func testRibbonEntryReplayGuideWelcomeAndHelpUseItsLocationAndObjective() throws {
        let ribbon = FallingSky.fullBoardRibbon()
        let entry = SkyEntryRequest.fullBoardRibbon.introduction(challenge: .firstLight,
            replayingRevision: 5, replayingTarget: 150_000)
        let replay = SkyEntryRequest.replay.introduction(challenge: .ribbonCrossing,
            replayingRevision: ribbon.challengeRevision, replayingTarget: ribbon.displayTarget)
        let guide = try XCTUnwrap(ribbon.challengeGuideLine)
        let help = SkyHelpContext(game: ribbon)
        XCTAssertEqual(entry.id, "full-board-ribbon.entry.1")
        XCTAssertEqual(replay.id, "full-board-ribbon.replay.1")
        XCTAssertEqual(guide.id, "guide.full-board-ribbon.1")
        for text in [entry.text, replay.text, guide.text, try XCTUnwrap(help.restorationHelp)] {
            XCTAssertTrue(text.contains("Ribbon Crossing"))
            XCTAssertTrue(text.contains("220,000"))
            XCTAssertFalse(text.contains("Lantern"))
            XCTAssertFalse(text.contains("150,000"))
        }
        XCTAssertTrue(entry.text.contains("No timed showers or ceiling loss"))
        XCTAssertTrue(entry.text.contains("saved round stays until you tap Begin"))
        XCTAssertTrue(replay.text.contains("same Full Board Ribbon Crossing opening and refill sequence"))
        XCTAssertTrue(guide.text.contains("Plan where the survivors fall"))
        XCTAssertTrue(help.fullBoardMenuInstructions.contains("Return to Ribbon Crossing on the World Map"))
        XCTAssertFalse(help.fullBoardMenuInstructions.contains("Lantern"))
        let welcome = try XCTUnwrap(SkyWelcomeSnapshot(game: ribbon, hasSavedSky: true, paused: true).summary)
        XCTAssertTrue(welcome.contains("Ribbon Crossing · Full Board"))
        XCTAssertTrue(welcome.contains("220,000"))
        XCTAssertTrue(welcome.contains("no timed showers"))
        XCTAssertFalse(welcome.contains("Paused"))
        XCTAssertFalse(welcome.contains("Lantern"))
    }

    @MainActor func testLanternHistoryKeepsItsCopyAndPracticeWhileRibbonOffersNoLanternLesson() throws {
        for revision in [5, 6] {
            let game = try lantern(revision)
            let replay = SkyEntryRequest.replay.introduction(challenge: game.challenge,
                replayingRevision: game.challengeRevision, replayingTarget: game.displayTarget)
            XCTAssertEqual(replay.id, "full-board-lantern.replay.1")
            XCTAssertTrue(replay.text.contains("150,000"))
            XCTAssertEqual(game.challengeGuideLine?.id, "guide.full-board-lantern.1")
            XCTAssertEqual(game.fullBoardRestoreGuideID, "guide.full-board-restore")
            XCTAssertEqual(game.fullBoardWelcomeTitle, "Lantern Landing · Full Board")
            XCTAssertEqual(SkyHelpContext(game: game).practiceChapter, .fullBoardRefill)
            XCTAssertTrue(SkyFullBoardChoicesView(game: game, done: {}).offersPractice)
        }
        XCTAssertEqual(SkyHelpContext(game: FallingSky.freshChallenge(.firstLight)).practiceChapter, .storyRoom)
        for game in [FallingSky.fullBoardRibbon(), .freshChallenge(.ribbonCrossing)] {
            XCTAssertNil(SkyHelpContext(game: game).practiceChapter)
            XCTAssertFalse(SkyFullBoardChoicesView(game: game, done: {}).offersPractice)
        }
        let sky = FallingSky.freshChallenge(.ribbonCrossing)
        XCTAssertEqual(sky.challengeGuideLine?.id, "guide.ribbon-crossing.patterns.1")
        XCTAssertNil(sky.fullBoardRestoreGuideID)
        XCTAssertNil(sky.fullBoardWelcomeTitle)
        XCTAssertFalse(SkyHelpContext(game: sky).fullBoard)
        XCTAssertTrue(sky.challengeHelpText?.contains("announced shower") == true)
    }

    @MainActor func testRibbonFindAMoveUsesItsOwnImmutableBoardAndFirstVisiblePattern() async throws {
        let game = FallingSky.fullBoardRibbon()
        XCTAssertTrue(SkyFullBoardChoiceAnalysis.supports(game))
        let before = try SkySaveArchive.encode(game)
        let analysis = await SkyFullBoardChoiceAnalysis.load(game)
        let choices = try XCTUnwrap(analysis)
        XCTAssertFalse(choices.isEmpty)
        for choice in choices {
            let presentation = SkyFullBoardChoicePresentation(choice: choice)
            XCTAssertEqual(presentation.instructions.count, choice.exchanges.count)
            var played = game
            var last: FallingSkyTurn?
            for exchange in choice.exchanges {
                last = try XCTUnwrap(played.nudge(from: exchange.from, to: exchange.to))
            }
            XCTAssertEqual(last?.resolutionPhases.first?.recipes, choice.recipes)
            XCTAssertTrue(played.isValidSave)
        }
        XCTAssertEqual(try SkySaveArchive.encode(game), before)
        XCTAssertEqual(game, FallingSky.fullBoardRibbon())
    }
}
