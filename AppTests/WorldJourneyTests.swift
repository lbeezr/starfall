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

    @MainActor func testSilverRepairUnlocksFrostfruitAndItsCompletionPersistsWithoutUnlockingSunwheel() throws {
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
        orchard.setSuspended(false); orchard.clear(Cell(0, 0))
        XCTAssertEqual(orchard.game.outcome, .won)
        let restored = WorldJourneyStore(defaults: defaults).journey
        XCTAssertEqual(restored.completed, [.silverPools, .frostfruitOrchard])
        XCTAssertEqual(restored.selected, .frostfruitOrchard)
        XCTAssertFalse(restored.canEnter(.sunwheelMill))
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
}

extension WorldJourneyTests {
    @MainActor func testRevisedTraceSelectionReportsTheSameAwardAsCommit() throws {
        let game = FallingSky.freshChallenge(.ribbonCrossing)
        let path = [Cell(0, 0), Cell(1, 1), Cell(0, 2), Cell(0, 3), Cell(0, 4)]
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
