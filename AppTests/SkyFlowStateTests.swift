import XCTest
import StarfallCore
@testable import Starfall

final class SkyFlowStateTests: XCTestCase {
    @MainActor private func make(legacyClock: Bool = false) -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.Entry.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        if legacyClock {
            defaults.set(try! SkySaveArchive.encode(FallingSky(seed: 5, balance: .init(pace: .steady), openingCascade: false)), forKey: FallingSkyStore.saveKey)
        }
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        return (FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock), presenter, clock, defaults)
    }

    @MainActor func testBrowsingAndCancelingEveryReplacementPreservesCommittedSave() throws {
        for challenge in [false, true] {
            let (store, presenter, clock, defaults) = make()
            if challenge { store.startFirstLight() }
            store.setSuspended(false)
            store.callShower(); presenter.finish()
            store.setSuspended(true)
            let original = store.game
            let core = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
            for action in [SkyFlowAction.start, .firstLight, .replay, .another] {
                var flow = SkyFlowState(arguments: action == .replay || action == .another ? ["--starfalls-reset"] : [])
                XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
                XCTAssertEqual(flow.screen, .entry)
                clock.advance(100)
                XCTAssertNil(clock.deadline)
                XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
                XCTAssertNil(flow.entry)
                XCTAssertEqual(store.game, original)
                XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), core)
                let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertEqual(restored.game, original)
            }
        }
    }

    @MainActor func testFreshEntryAndCancelNeverCreatesASave() {
        let (store, _, clock, defaults) = make()
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.start, hasSavedSky: false), .staged)
        XCTAssertEqual(flow.entry, .initial)
        XCTAssertEqual(flow.handle(.home, hasSavedSky: false), .home)
        clock.advance(100)
        XCTAssertFalse(store.hasSavedSky)
        XCTAssertNil(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertNil(flow.handle(.resume, hasSavedSky: false))
    }

    @MainActor func testCancelingCompletedSkyReplayKeepsTheSavedOutcome() throws {
        let (store, presenter, _, defaults) = make()
        store.startFirstLight(); store.setSuspended(false)
        for _ in 0..<40 where !store.game.isOver { store.callShower(); presenter.finish() }
        XCTAssertTrue(store.game.isOver)
        store.setSuspended(true)
        let original = store.game
        let core = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertEqual(flow.handle(.replay, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(store.game, original)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), core)
    }

    func testBeginRejectsDuplicateAndStaleEntryActions() throws {
        var flow = SkyFlowState(arguments: [])
        XCTAssertNil(flow.handle(.begin, hasSavedSky: true))
        XCTAssertEqual(flow.handle(.start, hasSavedSky: true), .staged)
        let oldID = try XCTUnwrap(flow.entryID)
        XCTAssertNil(flow.handle(.firstLight, hasSavedSky: true))
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
        XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: oldID))
        let currentID = try XCTUnwrap(flow.entryID)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: true, entryID: currentID), .began(.firstLight))
        XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: currentID))
        XCTAssertNil(flow.handle(.resume, hasSavedSky: true))
        XCTAssertNil(flow.entry)
        XCTAssertEqual(flow.screen, .playing)
    }

    @MainActor func testBeginKeepsInitialSeedAndExistingReplayGenerationContracts() throws {
        let (store, presenter, clock, defaults) = make()
        let initial = store.game
        store.beginEntry(.initial)
        XCTAssertEqual(store.game, initial)
        XCTAssertFalse(store.hasSavedSky)
        store.setSuspended(false); store.callShower(); presenter.finish(); store.setSuspended(true)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, initial)
        XCTAssertNil(clock.deadline)
        store.beginEntry(.firstLight)
        XCTAssertEqual(store.game, FallingSky(challenge: .firstLight))
        XCTAssertTrue(store.isPaused); XCTAssertTrue(store.suspended)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, FallingSky(challenge: .firstLight))
        store.beginEntry(.fresh)
        XCTAssertNil(store.game.challenge)
        XCTAssertTrue(store.game.hasOpeningCascade)
        XCTAssertEqual(store.game, FallingSky.freshSurvival(seed: store.game.seed, balance: store.game.balance))
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))), store.game)
    }

    @MainActor func testContinueRetainsPauseChoiceAndClockRemainder() {
        for paused in [false, true] {
            let (store, _, clock, _) = make(legacyClock: true)
            store.setSuspended(false)
            if !paused { store.togglePause(); clock.advance(0.1) }
            let before = clock.deadline.map { $0-clock.now }
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
            store.setSuspended(true)
            clock.advance(100)
            XCTAssertEqual(flow.handle(.resume, hasSavedSky: true), .continued)
            store.setSuspended(false)
            XCTAssertEqual(store.isPaused, paused)
            if let before { XCTAssertEqual(clock.deadline! - clock.now, before, accuracy: 0.0001) }
            else { XCTAssertNil(clock.deadline) }
            XCTAssertEqual(store.game.turns, 0)
        }
    }

    @MainActor func testOpeningContinuePreservesTheExistingResumeGrace() {
        let (store, _, clock, _) = make()
        store.setSuspended(false); store.togglePause()
        clock.advance(0.1)
        store.setSuspended(true); clock.advance(100)
        store.setSuspended(false)
        XCTAssertEqual(clock.deadline! - clock.now, 0.25, accuracy: 0.0001)
        XCTAssertEqual(store.game.turns, 0)
    }

    @MainActor func testSceneDetachmentSynchronouslyFreezesAndRejectsADueClock() throws {
        let (store, _, clock, _) = make()
        store.scene.onReadinessChanged?(true)
        store.setSuspended(false); store.togglePause()
        let staleRain = try XCTUnwrap(clock.action)
        store.scene.onReadinessChanged?(false)
        XCTAssertTrue(store.suspended)
        XCTAssertFalse(store.sceneReady)
        XCTAssertNil(clock.deadline)
        staleRain(); clock.advance(100)
        XCTAssertEqual(store.game.turns, 0)
        store.scene.onReadinessChanged?(true)
        XCTAssertTrue(store.suspended, "Readiness alone cannot start the clock")
    }

    func testEntryObjectiveDescribesPendingChoiceInsteadOfRetainedRound() {
        XCTAssertFalse(SkyEntryRequest.fresh.isChallenge(replayingChallenge: true))
        XCTAssertTrue(SkyEntryRequest.firstLight.isChallenge(replayingChallenge: false))
        XCTAssertTrue(SkyEntryRequest.replay.isChallenge(replayingChallenge: true))
        XCTAssertFalse(SkyEntryRequest.initial.isChallenge(replayingChallenge: false))
    }

    func testHandoffRequiresSettledReadyActiveAndModalFreeAdmission() throws {
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.start, hasSavedSky: false)
        _ = flow.handle(.begin, hasSavedSky: false, entryID: flow.entryID)
        let id = try XCTUnwrap(flow.handoff?.id)
        XCTAssertNil(flow.completeHandoff(id, ready: true, active: true, modal: false))
        flow.settleHandoff(id)
        XCTAssertNil(flow.completeHandoff(id, ready: false, active: true, modal: false))
        XCTAssertNil(flow.completeHandoff(id, ready: true, active: false, modal: false))
        XCTAssertNil(flow.completeHandoff(id, ready: true, active: true, modal: true))
        XCTAssertEqual(flow.completeHandoff(id, ready: true, active: true, modal: false), true)
        XCTAssertNil(flow.completeHandoff(id, ready: true, active: true, modal: false))
    }

    func testCanceledHandoffRejectsLateReadinessAndDoesNotReopenPlay() throws {
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.resume, hasSavedSky: true)
        let oldID = try XCTUnwrap(flow.handoff?.id)
        flow.showPreparation(oldID)
        XCTAssertTrue(try XCTUnwrap(flow.handoff).preparing)
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        flow.settleHandoff(oldID)
        XCTAssertNil(flow.completeHandoff(oldID, ready: true, active: true, modal: false))
        XCTAssertEqual(flow.screen, .welcome)
        _ = flow.handle(.resume, hasSavedSky: true)
        let newID = try XCTUnwrap(flow.handoff?.id)
        XCTAssertNotEqual(oldID, newID)
        flow.settleHandoff(oldID)
        XCTAssertFalse(try XCTUnwrap(flow.handoff).settled)
        flow.settleHandoff(newID)
        XCTAssertEqual(flow.completeHandoff(newID, ready: true, active: true, modal: false), false)
    }



    func testPreferencesNeverStageOrReplaceASkyAndAreBlockedDuringHandoff() {
        var flow = SkyFlowState(arguments: [])
        let initial = flow
        XCTAssertEqual(flow.handle(.preferences, hasSavedSky: true), .preferences)
        XCTAssertEqual(flow, initial)
        _ = flow.handle(.firstLight, hasSavedSky: true)
        let entry = flow
        XCTAssertEqual(flow.handle(.preferences, hasSavedSky: true), .preferences)
        XCTAssertEqual(flow, entry)
        _ = flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID)
        XCTAssertNil(flow.handle(.preferences, hasSavedSky: true))
    }

    func testWelcomeSummaryDistinguishesSavedModePauseAndCompletedSkies() {
        var game = FallingSky(challenge: .firstLight)
        let empty = SkyWelcomeSnapshot(game: game, hasSavedSky: false, paused: true)
        XCTAssertNil(empty.summary); XCTAssertFalse(empty.canContinue)
        let paused = SkyWelcomeSnapshot(game: game, hasSavedSky: true, paused: true)
        XCTAssertTrue(paused.canContinue)
        XCTAssertEqual(paused.summary, "First Light · 0 of 18 starlight · Automatic showers paused")
        let running = SkyWelcomeSnapshot(game: FallingSky(seed: 5), hasSavedSky: true, paused: false)
        XCTAssertEqual(running.summary, "Open sky · 0 starlight · Automatic showers")
        for _ in 0..<40 where !game.isOver { _ = game.letStarsFall() }
        let ended = SkyWelcomeSnapshot(game: game, hasSavedSky: true, paused: true)
        XCTAssertFalse(ended.canContinue); XCTAssertTrue(ended.ended)
        XCTAssertTrue(ended.summary?.contains("Sky full") == true)
    }

    func testCastEntranceKeepsCompleteRasterAndShadowInsideItsRegion() {
        for width: CGFloat in [240, 272, 327, 372, 430, 768] {
            for terminal in [false, true] {
                for welcome in [false, true] where !terminal || !welcome {
                    let formation = SkyCastFormation(width: width, terminal: terminal, welcome: welcome)
                    let region = CGRect(x: 0, y: 0, width: width, height: SkyCastFormation.height(terminal: terminal))
                    for star in formation.stars {
                        // Full raster is more conservative than the cutout silhouette.
                        let raster = CGRect(x: -star.side / 2 - 8, y: -star.side / 2 - 8,
                                            width: star.side + 16, height: star.side + 23)
                        for progress in stride(from: -0.1, through: 1.1, by: 0.025) {
                            let pose = star.pose(progress: progress)
                            let transform = CGAffineTransform(translationX: star.center.x, y: star.center.y + pose.offset)
                                .rotated(by: pose.rotation).scaledBy(x: pose.scale, y: pose.scale)
                            XCTAssertTrue(region.contains(raster.applying(transform)), "\(width), \(terminal), \(star.kind), \(progress)")
                        }
                    }
                }
            }
        }
    }

    func testResultSnapshotsExplainOrdinaryAndChallengeOverflowAfterRestore() throws {
        for challenge in [false, true] {
            var game = challenge ? FallingSky(challenge: .firstLight) : FallingSky(seed: 5)
            XCTAssertNil(SkyResultSnapshot(game: game))
            for _ in 0..<40 where !game.isOver { _ = game.letStarsFall() }
            let result = try XCTUnwrap(SkyResultSnapshot(game: game))
            XCTAssertFalse(result.won)
            XCTAssertEqual(result.target, challenge ? 18 : nil)
            let column = try XCTUnwrap(game.blockedColumn)
            XCTAssertTrue(result.reason.contains("Column \(column+1)"))
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(SkyResultSnapshot(game: restored), result)
            XCTAssertEqual(result.scoreLabel, challenge ? "0 of 18 starlight collected" : "0 starlight collected")
        }
    }

    func testResultSnapshotKeepsTheActualWinningScoreIncludingOvershoot() throws {
        var game = FallingSky(challenge: .firstLight)
        for _ in 0..<100 where !game.isOver {
            if let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
            else { _ = game.letStarsFall() }
        }
        let result = try XCTUnwrap(SkyResultSnapshot(game: game))
        XCTAssertTrue(result.won)
        XCTAssertGreaterThanOrEqual(result.score, 18)
        XCTAssertEqual(result.score, game.score)
        XCTAssertEqual(result.target, 18)
        XCTAssertEqual(result.reason, "First Light complete!")
    }
}

extension SkyFlowStateTests {
    func testHelpUsesCurrentOrPendingRulesWithoutCommittingEntry() {
        let retained = FallingSky(seed: 28).adoptingFeedingDusk()
        let fresh = FallingSky.freshSurvival(seed: 28)
        let challenge = FallingSky(challenge: .firstLight)
        for game in [retained, fresh, challenge] {
            for entry in [SkyEntryRequest?.none, .initial, .replay] {
                XCTAssertEqual(SkyHelpContext.selected(game: game, entry: entry), SkyHelpContext(game: game))
            }
            let new = SkyHelpContext.selected(game: game, entry: .fresh)
            XCTAssertFalse(new.criticalMass); XCTAssertTrue(new.pocketedDusk); XCTAssertFalse(new.challenge); XCTAssertTrue(new.opalStorms)
            let firstLight = SkyHelpContext.selected(game: game, entry: .firstLight)
            XCTAssertTrue(firstLight.challenge); XCTAssertFalse(firstLight.criticalMass)
            XCTAssertFalse(firstLight.openingCascade); XCTAssertFalse(firstLight.opalStorms)
        }
        let dusk = SkyHelpContext(game: retained)
        XCTAssertFalse(dusk.criticalMass); XCTAssertFalse(dusk.challenge); XCTAssertEqual(dusk.duskRule, .patientFeeding)
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.firstLight, hasSavedSky: true)
        let staged = flow
        _ = SkyHelpContext.selected(game: retained, entry: flow.entry)
        XCTAssertEqual(flow, staged)
    }
}
