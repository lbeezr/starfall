import XCTest
import StarfallCore
@testable import Starfall

final class SkyFlowStateTests: XCTestCase {
    func testWorldMapIsAPageAndReturnsToItsOriginWithoutBeginningARound() {
        for arguments in [[], ["--starfalls-reset"]] {
            var flow = SkyFlowState(arguments: arguments)
            let origin = flow.screen
            XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
            XCTAssertEqual(flow.screen, .worldMap)
            XCTAssertNil(flow.entry); XCTAssertNil(flow.handoff)
            XCTAssertNil(flow.handle(.worldMap, hasSavedSky: true))
            XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), origin == .playing ? .continued : .home)
            XCTAssertEqual(flow.screen, origin)
            _ = flow.handle(.worldMap, hasSavedSky: true)
            XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
            XCTAssertEqual(flow.screen, .entry)
            XCTAssertNil(flow.handle(.worldBack, hasSavedSky: true))
        }
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.worldMap, hasSavedSky: true)
        XCTAssertEqual(flow.handle(.resume, hasSavedSky: true), .continued)
        XCTAssertEqual(flow.screen, .playing)
        XCTAssertEqual(flow.handoff?.source, .worldMap)
        XCTAssertEqual(flow.handoff?.startsClock, false)
        XCTAssertNil(flow.entry)
    }
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
            for action in [SkyFlowAction.start, .firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard, .replay, .another] {
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
        XCTAssertNil(SkyEntryRequest.fresh.selectedChallenge(replaying: .firstLight))
        XCTAssertEqual(SkyEntryRequest.firstLight.selectedChallenge(replaying: nil), .firstLight)
        XCTAssertEqual(SkyEntryRequest.ribbonCrossing.selectedChallenge(replaying: .firstLight), .ribbonCrossing)
        XCTAssertEqual(SkyEntryRequest.kiteHarbor.selectedChallenge(replaying: .ribbonCrossing), .kiteHarbor)
        XCTAssertEqual(SkyEntryRequest.silverPools.selectedChallenge(replaying: .seedMoon), .silverPools)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .silverPools), .silverPools)
        XCTAssertEqual(SkyEntryRequest.frostfruitOrchard.selectedChallenge(replaying: .silverPools), .frostfruitOrchard)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .frostfruitOrchard), .frostfruitOrchard)
        XCTAssertEqual(SkyEntryRequest.seedMoon.selectedChallenge(replaying: .kiteHarbor), .seedMoon)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .seedMoon), .seedMoon)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .kiteHarbor), .kiteHarbor)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .firstLight), .firstLight)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .ribbonCrossing), .ribbonCrossing)
        XCTAssertNil(SkyEntryRequest.initial.selectedChallenge(replaying: nil))
    }

    func testReplayIntroductionExplainsThePendingModeAndReplacementBoundary() {
        for challenge in [false, true] {
            let replay = SkyEntryRequest.replay.introduction(challenge: challenge ? .firstLight : nil)
            XCTAssertTrue(replay.text.contains("Your saved round stays until you tap Begin."))
            XCTAssertTrue(replay.text.contains(challenge ? "same First Light opening" : "current sky settings"))
            for entry in [SkyEntryRequest.initial, .fresh, .firstLight] {
                let fresh = entry.introduction(challenge: challenge ? .firstLight : nil)
                XCTAssertNotEqual(replay.id, fresh.id)
                XCTAssertTrue(fresh.text.contains(challenge ? "18 starlight" : "each shower"))
            }
        }
    }

    @MainActor func testWinningClearSavesFinalScoreBeforeSettlementAndSurvivesInterruption() throws {
        for interrupted in [false, true] {
            let (store, presenter, clock, defaults) = make()
            store.startFirstLight(); store.setSuspended(false)
            for _ in 0..<100 where !store.game.isOver {
                if let cell = store.game.legalGroups.first?.first { store.clear(cell) }
                else { store.callShower() }
                if !store.game.isOver { presenter.finish() }
            }
            XCTAssertEqual(store.game.outcome, .won)
            XCTAssertTrue(store.busy, "Core commits the final clear before presentation settles")
            let committed = store.game
            let archive = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
            XCTAssertEqual(store.game.restoration?.milestone, .complete)
            XCTAssertEqual(store.game.restoration?.score, committed.score)
            XCTAssertEqual(try SkySaveArchive.decode(archive), committed)
            XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), archive, "Reading restoration never writes an archive")
            if interrupted { store.setSuspended(true) }
            presenter.finish()
            XCTAssertFalse(store.busy)
            store.setSuspended(false); clock.advance(100); presenter.finish()
            XCTAssertEqual(store.game, committed)
            XCTAssertNil(clock.deadline)
            let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(SkyResultSnapshot(game: restored.game), SkyResultSnapshot(game: committed))
            XCTAssertEqual(restored.game.restoration, committed.restoration)
            XCTAssertEqual(restored.game.restoration?.milestone, .complete)
        }
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
        XCTAssertTrue(ended.summary?.contains("Round over") == true)
    }

    func testRestoredResultLeavesTheFullCanvasLandmarkBandClearAcrossSafeAreas() {
        for challenge in StarfallChallenge.allCases {
            // Covers flat/landscape, tablet and notched phone safe areas. The
            // clearance also applies when the scene's canvas scrolls to 900 pt.
            for safeAreaTop: CGFloat in [0, 20, 24, 44, 59, 62] {
                let layout = SkyCeremonyLayout(screen: .won, challenge: challenge, safeAreaTop: safeAreaTop)
                let headingTop = safeAreaTop + StarfallTheme.Spacing.section
                    + layout.minimumTopSpace + layout.spacing
                XCTAssertEqual(headingTop, 230, accuracy: 0.001,
                               "The restored landmark must remain above the result heading")
                XCTAssertGreaterThanOrEqual(layout.minimumTopSpace, 0)
            }
        }
        let insetBeyondLandmark = SkyCeremonyLayout(screen: .won, challenge: .ribbonCrossing, safeAreaTop: 250)
        XCTAssertEqual(insetBeyondLandmark.minimumTopSpace, 0)
    }

    func testScenicResultReflowIsLimitedToSuccessfulRestoration() {
        for screen in [SkyFlowScreen.welcome, .entry, .playing, .won, .full] {
            for challenge: StarfallChallenge? in [nil] + StarfallChallenge.allCases.map(Optional.some) {
                let layout = SkyCeremonyLayout(screen: screen, challenge: challenge, safeAreaTop: 59)
                let restored = screen == .won && challenge != nil
                XCTAssertEqual(layout.isRestoredResult, restored)
                XCTAssertEqual(layout.spacing, restored ? StarfallTheme.Spacing.medium : StarfallTheme.Spacing.section)
                if !restored { XCTAssertEqual(layout.minimumTopSpace, 0) }
            }
        }
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
            XCTAssertTrue(game.board.contains(nil), "A blocked arrival need not fill every column")
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
        XCTAssertEqual(result.reason, "First Light complete! Lantern Landing is restored.")
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
        XCTAssertEqual(SkyHelpContext(game: fresh).lessons, SkyLesson.allCases)
        XCTAssertEqual(SkyHelpContext(game: retained).lessons, [.square, .cross, .relay])
        XCTAssertEqual(SkyHelpContext(game: challenge).lessons, [.square, .cross, .relay])
        let dusk = SkyHelpContext(game: retained)
        XCTAssertFalse(dusk.criticalMass); XCTAssertFalse(dusk.challenge); XCTAssertEqual(dusk.duskRule, .patientFeeding)
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.firstLight, hasSavedSky: true)
        let staged = flow
        _ = SkyHelpContext.selected(game: retained, entry: flow.entry)
        XCTAssertEqual(flow, staged)
    }
}
