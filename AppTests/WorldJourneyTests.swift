import XCTest
import StarfallCore
@testable import Starfall

final class WorldJourneyTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.WorldTests.\(UUID())", value = UserDefaults(suiteName: suite)!
        addTeardownBlock { value.removePersistentDomain(forName: suite) }
        return value
    }
    @MainActor func testOldInstallKeepsFivePlacesWithoutInventingCompletion() throws {
        let defaults = defaults(), old = FallingSky(seed: 42, openingCascade: false)
        defaults.set(try JSONEncoder().encode(old), forKey: SkySaveArchive.legacyKey)
        let bytes = defaults.data(forKey: SkySaveArchive.legacyKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertTrue(store.journey.journey.legacyAccess)
        XCTAssertTrue(store.journey.journey.canEnter(.silverPools))
        XCTAssertFalse(store.journey.journey.canEnter(.frostfruitOrchard))
        XCTAssertFalse(store.journey.journey.canEnter(.sunwheelMill))
        XCTAssertTrue(store.journey.journey.completed.isEmpty)
        XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key))
        try store.journey.select(.seedMoon)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), bytes)
        XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.selected, .seedMoon)
        XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.legacyAccess)
    }
    @MainActor func testWinningCommitUnlocksBeforeAnimationAndInterruptedWriteRepairs() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder()
        let game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        try SkySaveArchive.save(game, to: defaults)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        XCTAssertFalse(store.journey.journey.canEnter(.ribbonCrossing))
        store.setSuspended(false); store.clear(Cell(0,0))
        XCTAssertFalse(presenter.completions.isEmpty)
        XCTAssertTrue(store.journey.journey.canEnter(.ribbonCrossing))
        XCTAssertEqual(store.journey.journey.completed, [.firstLight])
        let win = try XCTUnwrap(SkySaveArchive.load(from: defaults))
        XCTAssertEqual(win.outcome, .won)
        // Simulate termination between the independent round and world writes.
        defaults.removeObject(forKey: WorldJourneyStore.key)
        let repaired = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(repaired.journey.completed, [.firstLight])
        XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key), "Restore construction stays read-only")
        try repaired.record(win); try repaired.record(win)
        XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.completed.count, 1)
    }
    @MainActor func testRejectedWorldBytesArePreservedAndNeverOverwriteRound() throws {
        let defaults = defaults(), bad = Data("future schema".utf8)
        defaults.set(bad, forKey: WorldJourneyStore.key)
        let game = FallingSky.freshSurvival(seed: 29)
        try SkySaveArchive.save(game, to: defaults)
        let bytes = defaults.data(forKey: SkySaveArchive.key)
        let world = WorldJourneyStore(defaults: defaults)
        XCTAssertTrue(world.recovered); XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), bad)
        XCTAssertFalse(world.journey.canEnter(.ribbonCrossing), "A damaged record cannot invent prior-install access")
        try world.select(.hollowCrown)
        XCTAssertFalse(world.journey.canEnter(.hollowCrown))
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.rejectedKey), bad)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
    }
    @MainActor func testInspectingEveryDestinationPreservesRetainedRoundAndAccess() throws {
        let defaults = defaults()
        let game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        try SkySaveArchive.save(game, to: defaults)
        let roundBytes = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        let world = WorldJourneyStore(defaults: defaults)
        for location in WorldLocation.allCases {
            try world.select(location)
            let restored = WorldJourneyStore(defaults: defaults)
            XCTAssertEqual(world.journey.selected, location)
            XCTAssertEqual(restored.journey.selected, location, "Selection remains meaningful after relaunch")
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes, location.rawValue)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
            XCTAssertTrue(restored.journey.completed.isEmpty)
            XCTAssertFalse(restored.journey.legacyAccess)
            for destination in WorldLocation.allCases {
                XCTAssertEqual(restored.journey.canEnter(destination), destination == .firstLight,
                               "Inspecting \(location.rawValue) must not unlock \(destination.rawValue)")
            }
        }
    }
    @MainActor func testEveryTutorialUsesStoreActionsAndNeverWritesRoundOrWorld() throws {
        for chapter in SkyTutorial.allCases {
            let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
            try SkySaveArchive.save(FallingSky.freshSurvival(seed: 91), to: defaults)
            try WorldJourneyStore(defaults: defaults).select(.firstLight)
            let round = defaults.data(forKey: SkySaveArchive.key), world = defaults.data(forKey: WorldJourneyStore.key)
            var writes = 0
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
                                        tutorial: chapter, archiveWriter: { _, _ in writes += 1 })
            store.setSuspended(false)
            for action in chapter.actions {
                switch action {
                case .tap(let cell): store.clear(cell)
                case .swap(let from, let to):
                    XCTAssertTrue(store.performTechnique(.nudge(from,to), snapshot: store.game, generation: store.constellationInputGeneration))
                case .trace(let path): store.clearTracedConstellation(path, snapshot: store.game, generation: store.constellationInputGeneration)
                case .shower: store.callShower()
                case .pause, .resume: store.togglePause()
                case .automaticShower: clock.advance(store.showerInterval)
                }
                presenter.finish()
                XCTAssertFalse(store.tutorial?.needsRetry ?? true, chapter.rawValue)
            }
            XCTAssertTrue(store.tutorial?.complete ?? false, chapter.rawValue)
            XCTAssertNil(clock.deadline)
            let stale = presenter.completions.last
            store.loadTutorial(chapter)
            let restarted = store.game
            stale?(); clock.advance(100)
            XCTAssertEqual(store.game, restarted)
            store.setSuspended(true); store.setSuspended(false)
            XCTAssertEqual(store.tutorial?.step, 0)
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
        }
    }
    @MainActor func testTutorialBackgroundAndSkipRejectOldClockAndPendingInput() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock, tutorial: .showers)
        store.setSuspended(false); store.callShower(); presenter.finish(); store.togglePause()
        let rain = try XCTUnwrap(clock.action)
        store.setSuspended(true); let before = store.game
        rain(); clock.advance(100)
        XCTAssertEqual(store.game, before)
        store.loadTutorial(.square)
        store.setSuspended(false); rain()
        XCTAssertEqual(store.game, SkyTutorial.square.game())
        XCTAssertNil(clock.deadline); XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
    }

    @MainActor func testCurrentStoryPracticeInspectionRetryAndCompletionPreserveSavedJourney() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        try SkySaveArchive.save(FallingSky.freshChallenge(.ribbonCrossing),to:defaults)
        try WorldJourneyStore(defaults:defaults).select(.seedMoon)
        let roundBytes = try XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))
        let worldBytes = try XCTUnwrap(defaults.data(forKey:WorldJourneyStore.key))
        var writes = 0
        let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock,
                                   tutorial:.storySquare,archiveWriter:{ _,_ in writes += 1 })
        store.setSuspended(false)
        let opening = store.game
        XCTAssertEqual(opening,FallingSky.freshChallenge(.firstLight))
        XCTAssertEqual(opening.challengeRevision,4)
        XCTAssertFalse(opening.supportsManualClears)
        XCTAssertFalse(try XCTUnwrap(store.tutorial).showsShowerControl)
        XCTAssertFalse(try XCTUnwrap(store.tutorial).showsPauseControl)
        XCTAssertNil(clock.deadline)
        XCTAssertFalse(store.requestTap(Cell(1,2)),"Inspecting a star cannot perform the taught exchange")
        XCTAssertEqual(store.game,opening)
        XCTAssertEqual(store.tutorial,SkyTutorialRun(.storySquare))
        XCTAssertTrue(presenter.completions.isEmpty)

        XCTAssertTrue(store.requestInput(.swap(Cell(3,0),Cell(3,1)),snapshot:store.game,
                                        generation:store.constellationInputGeneration))
        XCTAssertNotEqual(store.game.board,opening.board)
        XCTAssertEqual(store.game.displayScore,0)
        XCTAssertTrue(store.tutorial?.needsRetry == true)
        XCTAssertFalse(store.tutorial?.complete ?? true)
        let wrongCompletion = try XCTUnwrap(presenter.completions.last)
        store.loadTutorial(.storySquare)
        wrongCompletion()
        XCTAssertEqual(store.game,opening,"Retry reconstructs the same current Story opening")
        XCTAssertEqual(store.tutorial,SkyTutorialRun(.storySquare))
        var expected = opening
        let turn = try XCTUnwrap(expected.nudge(from:Cell(1,2),to:Cell(1,1)))
        XCTAssertEqual(turn.resolutionPhases.count,2)
        XCTAssertEqual(turn.displayAward,15_000)
        XCTAssertTrue(store.requestInput(.swap(Cell(1,2),Cell(1,1)),snapshot:store.game,
                                        generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game,expected)
        XCTAssertEqual(store.game.displayScore,15_000)
        XCTAssertTrue(store.tutorial?.complete == true)
        XCTAssertEqual(store.game.outcome,.playing,"Practice completion is one setup, not a location repair")
        presenter.finish()
        clock.advance(100)
        XCTAssertEqual(store.game,expected)
        XCTAssertNil(clock.deadline)
        store.loadTutorial(.match)
        XCTAssertEqual(store.game,SkyTutorial.match.game())
        store.loadTutorial(.storySquare)
        XCTAssertEqual(store.game,opening)
        XCTAssertEqual(store.tutorial?.step,0)
        XCTAssertEqual(writes,0)
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.key),roundBytes)
        XCTAssertEqual(defaults.data(forKey:WorldJourneyStore.key),worldBytes)
        XCTAssertTrue(store.journey.journey.completed.isEmpty)
        store.setSuspended(true)
    }

    @MainActor func testCurrentStoryPracticeRetiresHeldBufferedAndPresentedWorkOnBackgroundAndRetry() throws {
        for background in [false,true] {
            let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
            try SkySaveArchive.save(FallingSky.freshSurvival(seed:91),to:defaults)
            try WorldJourneyStore(defaults:defaults).select(.firstLight)
            let roundBytes = defaults.data(forKey:SkySaveArchive.key), worldBytes = defaults.data(forKey:WorldJourneyStore.key)
            let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock,tutorial:.storySquare)
            store.setSuspended(false)
            let opening = store.game
            XCTAssertTrue(store.requestInput(.swap(Cell(3,0),Cell(3,1)),snapshot:opening,
                                            generation:store.constellationInputGeneration))
            let staleCompletion = try XCTUnwrap(presenter.completions.last)
            let staleSnapshot = store.game, staleGeneration = store.constellationInputGeneration
            let staleHold = try XCTUnwrap(store.beginResponsiveContact(at:Cell(1,2)))
            let decisive = SkyPlayerInput.swap(Cell(1,2),Cell(1,1))
            XCTAssertTrue(store.requestInput(decisive,snapshot:staleSnapshot,generation:staleGeneration))
            XCTAssertNotNil(store.bufferedInput,"The pending setup shares a still-presenting column")
            XCTAssertEqual(store.game,staleSnapshot)
            if background { store.setSuspended(true) }
            else { store.loadTutorial(.storySquare) }
            let interrupted = store.game, interruptedRun = store.tutorial
            XCTAssertNil(store.bufferedInput)
            XCTAssertFalse(store.constellationTracing)
            staleCompletion(); store.endConstellationHold(staleHold)
            if background { store.setSuspended(false) }
            XCTAssertFalse(store.requestInput(decisive,snapshot:staleSnapshot,generation:staleGeneration))
            clock.advance(100)
            XCTAssertEqual(store.game,interrupted)
            XCTAssertEqual(store.tutorial,interruptedRun)
            XCTAssertNil(clock.deadline)

            store.loadTutorial(.storySquare)
            XCTAssertEqual(store.game,opening)
            let currentHold = try XCTUnwrap(store.beginResponsiveContact(at:Cell(1,2)))
            store.endConstellationHold(staleHold)
            XCTAssertTrue(store.constellationTracing,"An old release cannot retire the new practice contact")
            store.endConstellationHold(currentHold)
            XCTAssertTrue(store.requestInput(decisive,snapshot:store.game,generation:store.constellationInputGeneration))
            presenter.finish()
            XCTAssertEqual(store.game.displayScore,15_000)
            XCTAssertTrue(store.tutorial?.complete == true)
            XCTAssertEqual(defaults.data(forKey:SkySaveArchive.key),roundBytes)
            XCTAssertEqual(defaults.data(forKey:WorldJourneyStore.key),worldBytes)
            XCTAssertTrue(store.journey.journey.completed.isEmpty)
            store.setSuspended(true)
        }
    }

    @MainActor func testSilverRepairUnlocksFrostfruitAndItsCompletionPersistsAndUnlocksSunwheel() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder()
        try SkySaveArchive.save(ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .silverPools), to: defaults)
        let silver = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        XCTAssertFalse(silver.journey.journey.canEnter(.frostfruitOrchard))
        silver.setSuspended(false); silver.clear(Cell(0, 0))
        XCTAssertTrue(silver.busy)
        XCTAssertEqual(silver.journey.journey.completed, [.silverPools])
        XCTAssertTrue(silver.journey.journey.canEnter(.frostfruitOrchard))
        XCTAssertEqual(silver.journey.journey.selected, .frostfruitOrchard)
        XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.canEnter(.frostfruitOrchard))
        presenter.finish()
        try SkySaveArchive.save(ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .frostfruitOrchard), to: defaults)
        let orchard = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        let lockedMill = try XCTUnwrap(WorldMapPresentation(journey: orchard.journey.journey,
                                                            selected: .sunwheelMill).destination(.sunwheelMill))
        XCTAssertFalse(lockedMill.canEnter)
        XCTAssertFalse(lockedMill.restored)
        orchard.setSuspended(false); orchard.clear(Cell(0, 0))
        XCTAssertEqual(orchard.game.outcome, .won)
        let restored = WorldJourneyStore(defaults: defaults).journey
        XCTAssertEqual(restored.completed, [.silverPools, .frostfruitOrchard])
        XCTAssertEqual(restored.selected, .sunwheelMill)
        XCTAssertTrue(restored.canEnter(.sunwheelMill))
        XCTAssertFalse(restored.canEnter(.bellChoir))
        let map = WorldMapPresentation(journey: restored, selected: restored.selected)
        let readyMill = try XCTUnwrap(map.destination(.sunwheelMill))
        XCTAssertTrue(readyMill.canEnter)
        XCTAssertFalse(readyMill.restored, "Unlocking must keep the mill's damaged island until its own repair")
        XCTAssertTrue(try XCTUnwrap(map.destination(.frostfruitOrchard)).restored)
        let millArtwork = try XCTUnwrap(WorldMapContent.production.islands.first { $0.location == .sunwheelMill })
        XCTAssertEqual(millArtwork.asset(restored: readyMill.restored), millArtwork.damagedAsset)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), orchard.game)
    }

    @MainActor func testEarnedSilverReviewRequiresResetDialogueAndOneValidRestorationSelection() throws {
        let flag = "--world-silver-complete-review"
        let valid = ["--starfalls-reset", "--dialogue-review", "--frostfruit-restoration-review=9", flag]
        for arguments in [valid, [flag], ["--starfalls-reset", flag],
                          ["--dialogue-review", "--frostfruit-restoration-review=9", flag],
                          ["--starfalls-reset", "--dialogue-review", flag],
                          ["--starfalls-reset", "--dialogue-review", "--frostfruit-restoration-review=19", flag],
                          valid + ["--silver-restoration-review=9"]] {
            let defaults = defaults()
            let store = FallingSkyStore(defaults: defaults, arguments: arguments,
                                        presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(store.journey.journey.completed, arguments == valid ? [.silverPools] : [])
            XCTAssertEqual(store.journey.journey.canEnter(.frostfruitOrchard), arguments == valid)
            XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key), "Review construction remains read-only")
            XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
        }
    }

    @MainActor func testSunwheelCompletionCommitsBeforeAnimationAndRecoversInterruptedWorldWrite() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder()
        let oldWorld = Data(#"{"version":1,"journey":{"completed":["frostfruitOrchard"],"selected":"frostfruitOrchard","legacyAccess":false}}"#.utf8)
        defaults.set(oldWorld, forKey: WorldJourneyStore.key)
        try SkySaveArchive.save(ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .sunwheelMill), to: defaults)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        XCTAssertTrue(store.journey.journey.canEnter(.sunwheelMill))
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), oldWorld, "Restore construction is read-only")
        store.setSuspended(false); store.clear(Cell(0, 0))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertEqual(store.journey.journey.completed, [.frostfruitOrchard, .sunwheelMill])
        XCTAssertEqual(store.journey.journey.selected, .sunwheelMill)
        XCTAssertFalse(store.journey.journey.canEnter(.bellChoir))
        let map = WorldMapPresentation(journey: store.journey.journey, selected: .sunwheelMill)
        let restoredMill = try XCTUnwrap(map.destination(.sunwheelMill))
        XCTAssertTrue(restoredMill.restored)
        XCTAssertTrue(restoredMill.canEnter)
        let millArtwork = try XCTUnwrap(WorldMapContent.production.islands.first { $0.location == .sunwheelMill })
        XCTAssertEqual(millArtwork.asset(restored: restoredMill.restored), millArtwork.restoredAsset)
        let committed = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(committed), store.game)
        // A termination after round persistence but before world persistence is repaired on read.
        defaults.set(oldWorld, forKey: WorldJourneyStore.key)
        let repaired = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(repaired.journey.completed, [.frostfruitOrchard, .sunwheelMill])
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), oldWorld)
        try repaired.record(store.game)
        let envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))) as? [String: Any])
        XCTAssertEqual(envelope["version"] as? Int, 1)
        XCTAssertEqual(SkySaveArchive.schemaVersion, 17)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), committed)
        presenter.finish()
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, FallingSky(challenge: .sunwheelMill))
        XCTAssertEqual(store.journey.journey.completed, [.frostfruitOrchard, .sunwheelMill])
    }

    @MainActor func testEarnedFrostfruitReviewRequiresResetDialogueAndOneValidRestorationSelection() throws {
        let flag = "--world-frostfruit-complete-review"
        let valid = ["--starfalls-reset", "--dialogue-review", "--sunwheel-restoration-review=9", flag]
        for arguments in [valid, [flag], ["--starfalls-reset", flag],
                          ["--dialogue-review", "--sunwheel-restoration-review=9", flag],
                          ["--starfalls-reset", "--dialogue-review", flag],
                          ["--starfalls-reset", "--dialogue-review", "--sunwheel-restoration-review=19", flag],
                          valid + ["--frostfruit-restoration-review=9"]] {
            let defaults = defaults()
            let store = FallingSkyStore(defaults: defaults, arguments: arguments,
                                        presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(store.journey.journey.completed, arguments == valid ? [.frostfruitOrchard] : [])
            XCTAssertEqual(store.journey.journey.canEnter(.sunwheelMill), arguments == valid)
            XCTAssertFalse(store.journey.journey.canEnter(.bellChoir))
            XCTAssertNil(defaults.data(forKey: WorldJourneyStore.key), "Review construction remains read-only")
            XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
        }
    }
}

extension WorldJourneyTests {
    @MainActor func testV9WorldEraRoundDoesNotGrantLegacyAccessWhenArchiveKeyAdvances() throws {
        let defaults = defaults()
        let old = FallingSky(challenge: .firstLight)
        let core = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old))
        defaults.set(try JSONSerialization.data(withJSONObject: ["schemaVersion": 9, "game": core]), forKey: SkySaveArchive.worldKey)
        let journey = WorldJourneyStore(defaults: defaults).journey
        XCTAssertFalse(journey.legacyAccess)
        XCTAssertTrue(journey.completed.isEmpty)
        XCTAssertFalse(journey.canEnter(.ribbonCrossing))
    }

    @MainActor func testRetainedAuthoredRoundDoesNotGrantPreWorldAccessWhenArchiveKeyAdvances() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for (revision, version, key) in [(1, 10, SkySaveArchive.storyKey), (2, 11, SkySaveArchive.cascadeKey),
                                              (3, 12, SkySaveArchive.patternKey), (4, 13, SkySaveArchive.fourLineKey)] {
                let defaults = defaults()
                let definition = try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision))
                let old = FallingSky(definition: definition)
                let core = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old))
                let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": core])
                defaults.set(bytes, forKey: key)
                // Older pre-world bytes cannot override a retained world-era round.
                defaults.set(try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false)),
                             forKey: SkySaveArchive.legacyKey)
                let journey = WorldJourneyStore(defaults: defaults).journey
                XCTAssertFalse(journey.legacyAccess)
                XCTAssertTrue(journey.completed.isEmpty)
                XCTAssertTrue(journey.canEnter(.firstLight))
                XCTAssertFalse(journey.canEnter(.ribbonCrossing))
                XCTAssertFalse(journey.canEnter(.silverPools))
                XCTAssertEqual(defaults.data(forKey: key), bytes)
                XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
                XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
            }
        }
    }
}

extension WorldJourneyTests {
    @MainActor func testRevisedTraceSelectionReportsTheSameAwardAsCommit() throws {
        for revision in [1, 2] {
            let definition = try XCTUnwrap(StoryChallengeDefinition(.ribbonCrossing, revision: revision))
            let game = FallingSky(definition: definition)
            let path = revision == 1
                ? [Cell(0, 0), Cell(1, 1), Cell(0, 2), Cell(0, 3), Cell(0, 4)]
                : [Cell(0, 3), Cell(1, 3), Cell(1, 2), Cell(2, 2), Cell(3, 2)]
            let intent = ConstellationTraceIntent()
            let ticket = try XCTUnwrap(intent.begin(path[0], game: game, generation: 1, enabled: true))
            for cell in path.dropFirst() {
                XCTAssertTrue(intent.visit(cell, ticket: ticket, game: game, generation: 1, enabled: true))
            }
            var committed = game
            let turn = try XCTUnwrap(committed.clearConstellation(path))
            XCTAssertEqual(intent.count, 5)
            XCTAssertEqual(intent.value, 7_000)
            XCTAssertEqual(intent.value, turn.displayAward)
            XCTAssertEqual(game.displayScore, 0, "A selection never awards points")
        }
    }
}
