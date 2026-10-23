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

    func testEntryBackReturnsToMapAndPreservesItsOriginalDestination() throws {
        let destinations: [SkyFlowAction] = [.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard]
        for arguments in [[], ["--starfalls-reset"]] {
            var flow = SkyFlowState(arguments: arguments)
            let origin = flow.screen
            XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
            for destination in destinations {
                XCTAssertEqual(flow.handle(destination, hasSavedSky: true), .staged)
                let entryID = try XCTUnwrap(flow.entryID)
                XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true), "Unidentified callbacks cannot cancel Entry")
                XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: entryID), .worldMap)
                XCTAssertEqual(flow.screen, .worldMap)
                XCTAssertNil(flow.entry); XCTAssertNil(flow.entryID); XCTAssertNil(flow.handoff)
                XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: entryID))
                XCTAssertNil(flow.handle(.entryBack, hasSavedSky: true, entryID: entryID))
            }
            XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), origin == .playing ? .continued : .home)
            XCTAssertEqual(flow.screen, origin)
            XCTAssertNil(flow.handoff, "Map cancellation does not start a replacement or restart the clock")
        }
    }

    func testEntryBackRejectsOldEntryCallbacksAndCannotCancelABegunSky() throws {
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.worldMap, hasSavedSky: false)
        _ = flow.handle(.firstLight, hasSavedSky: false)
        let oldID = try XCTUnwrap(flow.entryID)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: false, entryID: oldID), .worldMap)
        _ = flow.handle(.firstLight, hasSavedSky: false)
        let currentID = try XCTUnwrap(flow.entryID)
        XCTAssertNotEqual(currentID, oldID)
        let staged = flow
        XCTAssertNil(flow.handle(.entryBack, hasSavedSky: false, entryID: oldID))
        XCTAssertNil(flow.handle(.begin, hasSavedSky: false, entryID: oldID))
        XCTAssertEqual(flow, staged)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: false, entryID: currentID), .began(.firstLight))
        let handoff = flow
        XCTAssertNil(flow.handle(.entryBack, hasSavedSky: false, entryID: currentID))
        XCTAssertEqual(flow, handoff)
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(flow.handle(.start, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .home)
        XCTAssertEqual(flow.screen, .welcome, "A later Free Play choice must not inherit a canceled map origin")
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
            for action in [SkyFlowAction.start, .firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard, .sunwheelMill, .replay, .another] {
                var flow = SkyFlowState(arguments: action == .replay || action == .another ? ["--starfalls-reset"] : [])
                XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
                XCTAssertEqual(flow.screen, .entry)
                clock.advance(100)
                XCTAssertNil(clock.deadline)
                XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .home)
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
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: false, entryID: flow.entryID), .home)
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
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .home)
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
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.firstLight))
        XCTAssertTrue(store.isPaused); XCTAssertTrue(store.suspended)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.firstLight))
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
        XCTAssertEqual(SkyEntryRequest.sunwheelMill.selectedChallenge(replaying: .frostfruitOrchard), .sunwheelMill)
        XCTAssertEqual(SkyEntryRequest.replay.selectedChallenge(replaying: .sunwheelMill), .sunwheelMill)
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
                XCTAssertTrue(fresh.text.contains(challenge ? "\(SkyCopy.score(150_000)) starlight" : "each shower"))
            }
        }
    }

    @MainActor func testWinningClearSavesFinalScoreBeforeSettlementAndSurvivesInterruption() throws {
        for interrupted in [false, true] {
            let (store, presenter, clock, defaults) = make()
            store.startFirstLight(); store.setSuspended(false)
            // Current recipes require arranging as well as clearing; drive real
            // actions and leave the winning presentation deliberately unfinished.
            for _ in 0..<160 where !store.game.isOver {
                if let (from, to) = storyScoringChoice(store.game) {
                    if let to {
                        XCTAssertTrue(store.performTechnique(.nudge(from, to), snapshot: store.game,
                                                             generation: store.constellationInputGeneration))
                    } else { store.clear(from) }
                } else { store.callShower() }
                if !store.game.isOver { presenter.finish() }
            }
            XCTAssertEqual(store.game.outcome, .won)
            XCTAssertTrue(store.busy, "Core commits the final clear before presentation settles")
            let committed = store.game
            let archive = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
            XCTAssertEqual(store.game.restoration?.milestone, .complete)
            XCTAssertEqual(store.game.restoration?.score, committed.displayScore)
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

    @MainActor func testOnwardSnapshotRequiresRecordedWinAndNamesOnlyItsImmediateReadySuccessor() throws {
        for legacy in [false, true] {
            for location in WorldLocation.allCases where location.challenge != nil {
                var win = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: location.challenge)
                XCTAssertNotNil(win.clear(Cell(0, 0)))
                XCTAssertEqual(win.outcome, .won)
                var journey = WorldJourney(legacyAccess: legacy)
                XCTAssertNil(SkyOnwardSnapshot(game: win, journey: journey), "An unrecorded repair cannot offer onward travel")
                journey.record(win)
                journey.select(.hollowCrown)
                let next = WorldLocation.allCases.dropFirst(location.number).first
                let onward = SkyOnwardSnapshot(game: win, journey: journey)
                XCTAssertEqual(onward?.destination, next.flatMap { $0.challenge == nil ? nil : $0 })
                if let onward {
                    XCTAssertEqual(onward.label, "Visit \(onward.destination.title)")
                    let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(win))
                    journey.record(restored)
                    XCTAssertEqual(SkyOnwardSnapshot(game: restored, journey: journey), onward,
                                   "Restored and repeated wins ignore the browsed selection")
                    var successorWin = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: onward.destination.challenge)
                    XCTAssertNotNil(successorWin.clear(Cell(0, 0)))
                    journey.record(successorWin)
                    XCTAssertNil(SkyOnwardSnapshot(game: win, journey: journey), "Never skip an already restored successor")
                } else {
                    XCTAssertEqual(location, .sunwheelMill, "Unbuilt Bell Choir retains the generic map path")
                }
            }
        }
    }

    @MainActor func testOnwardSnapshotRejectsPlayingLostFreePlayAndInvalidWinningSkies() throws {
        var win = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        XCTAssertNotNil(win.clear(Cell(0, 0)))
        var journey = WorldJourney(); journey.record(win)
        var lost = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<40 where !lost.isOver { _ = lost.letStarsFall() }
        XCTAssertEqual(lost.outcome, .lost)
        for game in [FallingSky.freshChallenge(.firstLight), .freshSurvival(seed: 5), lost] {
            XCTAssertNil(SkyOnwardSnapshot(game: game, journey: journey))
        }
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(win)) as? [String: Any])
        fields["starsLanded"] = 0
        let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertFalse(invalid.isValidSave)
        XCTAssertEqual(invalid.outcome, .won)
        XCTAssertNil(SkyOnwardSnapshot(game: invalid, journey: journey))
    }

    @MainActor private func makeOnwardWin() throws -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let (_, _, _, defaults) = make()
        try SkySaveArchive.save(ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight), to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false); store.clear(Cell(0, 0)); presenter.finish(); store.setSuspended(true)
        XCTAssertEqual(store.game.outcome, .won)
        return (store, presenter, clock, defaults)
    }

    @MainActor func testOnwardRejectsStaleCoveredUnsettledAndDuplicateIntentsWithoutWrites() throws {
        let (store, _, _, defaults) = try makeOnwardWin()
        let round = store.game, archive = defaults.data(forKey: SkySaveArchive.key)
        let journey = store.journey.journey, journeyBytes = defaults.data(forKey: WorldJourneyStore.key)
        for (saved, ready, active, modal, destination) in [
            (false, true, true, false, WorldLocation.ribbonCrossing),
            (true, false, true, false, .ribbonCrossing), (true, true, false, false, .ribbonCrossing),
            (true, true, true, true, .ribbonCrossing), (true, true, true, false, .kiteHarbor)
        ] {
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            let before = flow
            XCTAssertFalse(flow.openOnward(destination, game: round, journey: journey, hasSavedSky: saved,
                                          terminalReady: ready, active: active, modal: modal,
                                          select: { _ in XCTFail("Rejected intent must not write selection") }))
            XCTAssertEqual(flow, before)
        }
        var staleJourney = journey
        var successor = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .ribbonCrossing)
        XCTAssertNotNil(successor.clear(Cell(0, 0))); staleJourney.record(successor)
        var playing = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertFalse(playing.openOnward(.ribbonCrossing, game: round, journey: staleJourney, hasSavedSky: true,
                                         terminalReady: true, active: true, modal: false,
                                         select: { _ in XCTFail("A stale offer must be recomputed") }))
        var map = playing; _ = map.handle(.worldMap, hasSavedSky: true)
        var entry = map; _ = entry.handle(.ribbonCrossing, hasSavedSky: true)
        var handoff = SkyFlowState(arguments: [])
        _ = handoff.handle(.firstLight, hasSavedSky: true)
        _ = handoff.handle(.begin, hasSavedSky: true, entryID: handoff.entryID)
        for var flow in [SkyFlowState(arguments: []), map, entry, handoff] {
            let before = flow
            XCTAssertFalse(flow.openOnward(.ribbonCrossing, game: round, journey: journey, hasSavedSky: true,
                                          terminalReady: true, active: true, modal: false,
                                          select: { _ in XCTFail("Covered/duplicate intent must not write") }))
            XCTAssertNil(flow.handle(.onward(.ribbonCrossing), hasSavedSky: true), "Unvalidated intents cannot bypass admission")
            XCTAssertEqual(flow, before)
        }
        XCTAssertEqual(store.game, round); XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), journeyBytes)
    }

    @MainActor func testOnwardSelectionFailureDoesNotPublishFlowOrChangeTheRound() throws {
        enum SelectionFailure: Error { case failed }
        let (store, _, clock, defaults) = try makeOnwardWin()
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        let before = flow, round = store.game, journey = store.journey.journey
        let archive = defaults.data(forKey: SkySaveArchive.key), journeyBytes = defaults.data(forKey: WorldJourneyStore.key)
        var attempts = 0
        XCTAssertThrowsError(try flow.openOnward(.ribbonCrossing, game: round, journey: journey, hasSavedSky: true,
                                                terminalReady: true, active: true, modal: false, select: { _ in
            attempts += 1
            throw SelectionFailure.failed
        }))
        XCTAssertEqual(attempts, 1); XCTAssertEqual(flow, before)
        XCTAssertEqual(store.game, round); XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), journeyBytes)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testOnwardMapEntryCancellationRetainsTheWonRoundUntilBegin() throws {
        let (store, _, clock, defaults) = try makeOnwardWin()
        let round = store.game, archive = defaults.data(forKey: SkySaveArchive.key)
        // A prior browser selection must not decide the named continuation.
        try store.journey.select(.silverPools)
        var flow = SkyFlowState(arguments: ["--starfalls-reset"])
        XCTAssertTrue(try flow.openOnward(.ribbonCrossing, game: store.game, journey: store.journey.journey,
                                         hasSavedSky: store.hasSavedSky, terminalReady: !store.busy,
                                         active: true, modal: false, select: store.journey.select))
        XCTAssertEqual(flow.screen, .worldMap); XCTAssertEqual(store.journey.journey.selected, .ribbonCrossing)
        XCTAssertEqual(flow.handle(.ribbonCrossing, hasSavedSky: true), .staged)
        let entryID = try XCTUnwrap(flow.entryID)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: entryID), .worldMap)
        XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), .continued)
        XCTAssertEqual(flow.screen, .playing); XCTAssertNil(flow.handoff)
        clock.advance(100)
        XCTAssertEqual(store.game, round); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertNil(clock.deadline)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, round)
        XCTAssertEqual(SkyOnwardSnapshot(game: restored.game, journey: restored.journey.journey)?.destination, .ribbonCrossing)
        XCTAssertTrue(try flow.openOnward(.ribbonCrossing, game: store.game, journey: store.journey.journey,
                                         hasSavedSky: true, terminalReady: true, active: true, modal: false,
                                         select: store.journey.select))
        _ = flow.handle(.ribbonCrossing, hasSavedSky: true)
        XCTAssertEqual(store.game, round); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID), .began(.ribbonCrossing))
        store.beginEntry(.ribbonCrossing)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.ribbonCrossing))
        XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), archive)
    }

    @MainActor func testWorldMapNewVisitGoalsUseEveryCurrentReadyDefinition() throws {
        var journey = WorldJourney(legacyAccess: true)
        for challenge in [StarfallChallenge.silverPools, .frostfruitOrchard] {
            var win = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: challenge)
            XCTAssertNotNil(win.clear(Cell(0, 0)))
            journey.record(win)
        }
        let targets: [(StarfallChallenge, Int)] = [
            (.firstLight, 150_000), (.ribbonCrossing, 220_000), (.kiteHarbor, 17_000),
            (.seedMoon, 11_000), (.silverPools, 12_000), (.frostfruitOrchard, 15_000), (.sunwheelMill, 18)
        ]
        for (challenge, target) in targets {
            journey.select(try XCTUnwrap(WorldLocation(rawValue: challenge.rawValue)))
            let goal = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: nil))
            XCTAssertEqual(goal.newVisitTarget, target)
            XCTAssertEqual(goal.newVisitLabel, "New visit objective: \(SkyCopy.score(target)) starlight.")
            XCTAssertNil(goal.retainedProgress)
            XCTAssertNil(goal.retainedLabel)
        }
    }

    @MainActor func testWorldMapRetainedGoalsKeepHistoricalAndCurrentPointScales() throws {
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .firstLight)
        var lantern = FallingSky.freshChallenge(.firstLight)
        var ribbon = FallingSky.freshChallenge(.ribbonCrossing)
        XCTAssertNotNil(lantern.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertNotNil(ribbon.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        for (game, score, retainedTarget, newTarget) in [
            (historical, 9, 18, 150_000), (lantern, 15_000, 150_000, 150_000),
            (ribbon, 30_000, 220_000, 220_000)
        ] {
            var journey = WorldJourney(legacyAccess: true)
            let challenge = try XCTUnwrap(game.challenge)
            journey.select(try XCTUnwrap(WorldLocation(rawValue: challenge.rawValue)))
            let goal = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: game))
            XCTAssertEqual(goal.retainedProgress, StarlightRestoration(score: score, target: retainedTarget))
            XCTAssertEqual(goal.newVisitTarget, newTarget)
            XCTAssertEqual(goal.retainedLabel,
                           "Saved round: \(SkyCopy.score(score)) of \(SkyCopy.score(retainedTarget)) starlight.")
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(WorldMapGoalSnapshot(journey: journey, retainedRound: restored), goal,
                           "Reading a restored round cannot substitute today's objective")
        }
    }

    @MainActor func testWorldMapGoalsExcludeUnrelatedEndedAndAbsentRoundProgress() throws {
        var journey = WorldJourney(legacyAccess: true)
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .firstLight)
        journey.select(.ribbonCrossing)
        let otherPlace = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: historical))
        XCTAssertEqual(otherPlace.newVisitTarget, 220_000)
        XCTAssertNil(otherPlace.retainedProgress, "Another destination's score must not follow map selection")
        journey.select(.firstLight)
        XCTAssertNil(try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: nil)).retainedProgress)
        XCTAssertNil(try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: .freshSurvival(seed: 5))).retainedProgress)
        var full = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<40 where !full.isOver { _ = full.letStarsFall() }
        XCTAssertEqual(full.outcome, .lost)
        XCTAssertNil(try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: full)).retainedProgress)
        var won = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        XCTAssertNotNil(won.clear(Cell(0, 0)))
        journey.record(won); journey.select(.firstLight)
        XCTAssertTrue(journey.completed.contains(.firstLight))
        let completed = try XCTUnwrap(WorldMapGoalSnapshot(journey: journey, retainedRound: won))
        XCTAssertNil(completed.retainedProgress, "A completed result must not advertise Continue progress")
        XCTAssertEqual(completed.newVisitTarget, 150_000, "A restored place stays revisitable with current rules")
    }

    @MainActor func testWorldMapGoalsMakeNoPlayablePromiseForLockedOrUnbuiltPlaces() {
        var journey = WorldJourney()
        for location in [WorldLocation.ribbonCrossing, .frostfruitOrchard, .bellChoir, .hollowCrown] {
            journey.select(location)
            let round = location.challenge.map(FallingSky.freshChallenge)
            XCTAssertFalse(journey.canEnter(location))
            XCTAssertNil(WorldMapGoalSnapshot(journey: journey, retainedRound: round))
        }
    }

    @MainActor func testKitePreviewAndCancelKeepHistoricalRoundUntilNewBegin() throws {
        let (_, _, _, defaults) = make()
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .kiteHarbor)
        try SkySaveArchive.save(historical, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        let journey = store.journey.journey
        let worldBytes = defaults.data(forKey: WorldJourneyStore.key)
        var selected = WorldJourney(legacyAccess: true); selected.select(.kiteHarbor)
        let goals = try XCTUnwrap(WorldMapGoalSnapshot(journey: selected, retainedRound: store.game))
        XCTAssertEqual(goals.newVisitTarget, 17_000)
        XCTAssertEqual(goals.retainedProgress, StarlightRestoration(score: 9, target: 18))
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        for _ in 0..<2 {
            XCTAssertEqual(flow.handle(.kiteHarbor, hasSavedSky: true), .staged)
            let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
            XCTAssertEqual(preview.challenge, .kiteHarbor)
            XCTAssertEqual(preview.progress, StarlightRestoration(score: 0, target: 17_000))
            XCTAssertEqual(store.game, historical)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
        }
        clock.advance(100)
        XCTAssertNil(clock.deadline)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game, historical)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
        XCTAssertEqual(flow.handle(.kiteHarbor, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID), .began(.kiteHarbor))
        store.beginEntry(.kiteHarbor)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.kiteHarbor))
        XCTAssertEqual(store.game.challengeRevision, 4)
        XCTAssertEqual(store.game.displayTarget, 17_000)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey, "Starting a new visit cannot earn a repair")
        XCTAssertTrue(store.isPaused)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testKiteRepairUnlocksSeedOnlyAfterACommittedWin() throws {
        var ribbon = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .ribbonCrossing)
        XCTAssertNotNil(ribbon.clear(Cell(0, 0)))
        XCTAssertEqual(ribbon.outcome, .won)
        var journey = WorldJourney(); journey.record(ribbon)
        XCTAssertFalse(journey.legacyAccess)
        XCTAssertTrue(journey.canEnter(.kiteHarbor))
        XCTAssertFalse(journey.canEnter(.seedMoon))
        var kite = FallingSky.freshChallenge(.kiteHarbor)
        XCTAssertNotNil(kite.nudge(from: Cell(2, 1), to: Cell(2, 0)))
        journey.record(kite)
        XCTAssertFalse(journey.canEnter(.seedMoon), "A useful opening clear is not a completed repair")
        XCTAssertNotNil(kite.letStarsFall())
        XCTAssertNotNil(kite.nudge(from: Cell(0, 4), to: Cell(1, 4)))
        for (from, to) in [(Cell(5, 1), Cell(4, 1)), (Cell(4, 1), Cell(3, 1)),
                           (Cell(0, 4), Cell(0, 3)), (Cell(0, 3), Cell(0, 2)),
                           (Cell(0, 2), Cell(0, 1))] {
            XCTAssertNotNil(kite.nudge(from: from, to: to))
            XCTAssertTrue(kite.isValidSave)
        }
        XCTAssertEqual(kite.displayScore, 17_000)
        XCTAssertEqual(kite.outcome, .won)
        journey.record(kite)
        XCTAssertTrue(journey.completed.contains(.kiteHarbor))
        XCTAssertTrue(journey.canEnter(.seedMoon))
        XCTAssertEqual(journey.selected, .seedMoon)
        let completed = journey
        journey.record(kite)
        XCTAssertEqual(journey, completed, "A restored winning round cannot duplicate progression")
    }

    @MainActor func testSeedPreviewAndCancelKeepHistoricalRoundUntilNewBegin() throws {
        let (_, _, _, defaults) = make()
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .seedMoon)
        try SkySaveArchive.save(historical, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        let journey = store.journey.journey
        let worldBytes = defaults.data(forKey: WorldJourneyStore.key)
        var selected = WorldJourney(legacyAccess: true); selected.select(.seedMoon)
        let goals = try XCTUnwrap(WorldMapGoalSnapshot(journey: selected, retainedRound: store.game))
        XCTAssertEqual(goals.newVisitTarget, 11_000)
        XCTAssertEqual(goals.retainedProgress, StarlightRestoration(score: 9, target: 18))
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        for _ in 0..<2 {
            XCTAssertEqual(flow.handle(.seedMoon, hasSavedSky: true), .staged)
            let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
            XCTAssertEqual(preview.challenge, .seedMoon)
            XCTAssertEqual(preview.progress, StarlightRestoration(score: 0, target: 11_000))
            XCTAssertEqual(store.game, historical)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
        }
        clock.advance(100)
        XCTAssertNil(clock.deadline)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game, historical)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
        XCTAssertEqual(flow.handle(.seedMoon, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID), .began(.seedMoon))
        store.beginEntry(.seedMoon)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.seedMoon))
        XCTAssertEqual(store.game.challengeRevision, 4)
        XCTAssertEqual(store.game.displayScore, 0)
        XCTAssertEqual(store.game.gem(at: Cell(0, 1))?.id, 1)
        XCTAssertTrue(store.game.gem(at: Cell(0, 1))?.grown == true)
        XCTAssertEqual(store.game.displayTarget, 11_000)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey, "Starting a new visit cannot earn a repair")
        XCTAssertTrue(store.isPaused)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testSeedRepairUnlocksSilverOnlyAfterACommittedWin() throws {
        var kite = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .kiteHarbor)
        XCTAssertNotNil(kite.clear(Cell(0, 0)))
        XCTAssertEqual(kite.outcome, .won)
        var journey = WorldJourney(); journey.record(kite)
        XCTAssertFalse(journey.legacyAccess)
        XCTAssertTrue(journey.canEnter(.seedMoon))
        XCTAssertFalse(journey.canEnter(.silverPools))
        var seed = FallingSky.freshChallenge(.seedMoon)
        XCTAssertNotNil(seed.nudge(from: Cell(0, 4), to: Cell(0, 3)))
        XCTAssertEqual(seed.displayScore, 6_000)
        journey.record(seed)
        XCTAssertFalse(journey.canEnter(.silverPools), "Collecting the grown ingredient is not a complete repair")
        for (from, to) in [(Cell(0, 0), Cell(0, 1)), (Cell(0, 1), Cell(1, 1)),
                           (Cell(0, 2), Cell(1, 2))] {
            XCTAssertNotNil(seed.nudge(from: from, to: to))
            XCTAssertTrue(seed.isValidSave)
        }
        XCTAssertEqual(seed.displayScore, 11_000)
        XCTAssertEqual(seed.outcome, .won)
        journey.record(seed)
        XCTAssertTrue(journey.completed.contains(.seedMoon))
        XCTAssertTrue(journey.canEnter(.silverPools))
        XCTAssertEqual(journey.selected, .silverPools)
        let completed = journey
        journey.record(seed)
        XCTAssertEqual(journey, completed, "A restored winning round cannot duplicate progression")
    }

    @MainActor func testSilverPreviewAndCancelKeepHistoricalRoundUntilNewBegin() throws {
        let (_, _, _, defaults) = make()
        let historical = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .silverPools)
        try SkySaveArchive.save(historical, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        let archive = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        let journey = store.journey.journey
        let worldBytes = defaults.data(forKey: WorldJourneyStore.key)
        var selected = WorldJourney(legacyAccess: true); selected.select(.silverPools)
        let goals = try XCTUnwrap(WorldMapGoalSnapshot(journey: selected, retainedRound: store.game))
        XCTAssertEqual(goals.newVisitTarget, 12_000)
        XCTAssertEqual(goals.retainedProgress, StarlightRestoration(score: 9, target: 18))
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        for _ in 0..<2 {
            XCTAssertEqual(flow.handle(.silverPools, hasSavedSky: true), .staged)
            let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
            XCTAssertEqual(preview.challenge, .silverPools)
            XCTAssertEqual(preview.progress, StarlightRestoration(score: 0, target: 12_000))
            XCTAssertEqual(store.game, historical)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
        }
        clock.advance(100)
        XCTAssertNil(clock.deadline)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game, historical)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
        XCTAssertEqual(flow.handle(.silverPools, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID), .began(.silverPools))
        store.beginEntry(.silverPools)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.silverPools))
        XCTAssertEqual(store.game.challengeRevision, 4)
        XCTAssertEqual(store.game.displayScore, 0)
        XCTAssertEqual(store.game.occupiedCount, 24)
        XCTAssertTrue(store.game.board.compactMap { $0 }.allSatisfy { !$0.grown })
        XCTAssertEqual(store.game.displayTarget, 12_000)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(store.journey.journey, journey, "Starting a new visit cannot earn a repair")
        XCTAssertTrue(store.isPaused)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testSilverRepairUnlocksFrostfruitOnlyAfterACommittedWin() throws {
        var seed = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .seedMoon)
        XCTAssertNotNil(seed.clear(Cell(0, 0)))
        XCTAssertEqual(seed.outcome, .won)
        var journey = WorldJourney(); journey.record(seed)
        XCTAssertFalse(journey.legacyAccess)
        XCTAssertTrue(journey.canEnter(.silverPools))
        XCTAssertFalse(journey.canEnter(.frostfruitOrchard))
        var silver = FallingSky.freshChallenge(.silverPools)
        XCTAssertNotNil(silver.nudge(from: Cell(0, 2), to: Cell(1, 2)))
        XCTAssertEqual(silver.displayScore, 7_000)
        journey.record(silver)
        XCTAssertFalse(journey.canEnter(.frostfruitOrchard), "The immediate clear is not a completed repair")
        let final = try XCTUnwrap(silver.nudge(from: Cell(3, 2), to: Cell(3, 1)))
        XCTAssertEqual(final.resolutionPhases.map(\.comboDepth), [1], "This separate action does not continue the first clear's chain")
        XCTAssertTrue(silver.isValidSave)
        XCTAssertEqual(silver.displayScore, 12_000)
        XCTAssertEqual(silver.outcome, .won)
        journey.record(silver)
        XCTAssertTrue(journey.completed.contains(.silverPools))
        XCTAssertTrue(journey.canEnter(.frostfruitOrchard))
        XCTAssertEqual(journey.selected, .frostfruitOrchard)
        let completed = journey
        journey.record(silver)
        XCTAssertEqual(journey, completed, "A restored winning round cannot duplicate progression")
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
        let openings = [FallingSky(challenge: .firstLight),
                        FallingSky.freshChallenge(.firstLight),
                        FallingSky.freshChallenge(.ribbonCrossing)]
        for opening in openings {
            var game = opening
            for _ in 0..<256 where !game.isOver {
                if let (from, to) = storyScoringChoice(game) {
                    if let to { _ = game.nudge(from: from, to: to) }
                    else { _ = game.clear(from) }
                } else { _ = game.letStarsFall() }
            }
            let result = try XCTUnwrap(SkyResultSnapshot(game: game))
            let target = try XCTUnwrap(game.displayTarget)
            XCTAssertTrue(result.won)
            XCTAssertGreaterThanOrEqual(result.score, target)
            XCTAssertEqual(result.score, game.displayScore)
            XCTAssertEqual(result.target, target)
            XCTAssertEqual(result.scoreLabel, "\(SkyCopy.score(game.displayScore)) of \(SkyCopy.score(target)) starlight collected")
            XCTAssertEqual(result.reason, game.challenge?.resultReason)
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(SkyResultSnapshot(game: restored), result)
            var journey = WorldJourney(); journey.record(game); journey.select(.hollowCrown)
            let onward = try XCTUnwrap(SkyOnwardSnapshot(game: game, journey: journey))
            XCTAssertEqual(onward.destination, game.challenge == .firstLight ? .ribbonCrossing : .kiteHarbor)
            XCTAssertEqual(SkyOnwardSnapshot(game: restored, journey: journey), onward)
            let welcome = SkyWelcomeSnapshot(game: restored, hasSavedSky: true, paused: true)
            XCTAssertEqual(welcome.score, result.score)
            XCTAssertEqual(welcome.target, result.target)
            XCTAssertTrue(welcome.summary?.contains("\(SkyCopy.score(result.score)) of \(SkyCopy.score(target)) starlight") == true)
        }
    }
}

extension SkyFlowStateTests {
    func testHelpUsesCurrentOrPendingRulesWithoutCommittingEntry() throws {
        let retained = FallingSky(seed: 28).adoptingFeedingDusk()
        let fresh = FallingSky.freshSurvival(seed: 28)
        let challenge = FallingSky(challenge: .firstLight)
        var sources = [retained, fresh, challenge, FallingSky(challenge: .ribbonCrossing)]
        for location in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...3 {
                sources.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(location, revision: revision))))
            }
            sources.append(FallingSky.freshChallenge(location))
        }
        for game in sources {
            let saved = try SkySaveArchive.encode(game)
            for entry in [SkyEntryRequest?.none, .initial, .replay] {
                let context = SkyHelpContext.selected(game: game, entry: entry)
                XCTAssertEqual(context, SkyHelpContext(game: game))
                XCTAssertEqual(context.manualClears, game.challenge == nil || game.challengeRevision < 3)
                XCTAssertEqual(context.automaticRecipes, game.challenge != nil && game.challengeRevision >= 2)
                XCTAssertEqual(context.automaticLineLength,
                               game.challengeRevision == 3 ? 7 : game.challengeRevision == 4 ? 4 : nil)
            }
            let new = SkyHelpContext.selected(game: game, entry: .fresh)
            XCTAssertFalse(new.criticalMass); XCTAssertTrue(new.pocketedDusk); XCTAssertFalse(new.challenge); XCTAssertTrue(new.opalStorms)
            XCTAssertTrue(new.manualClears); XCTAssertFalse(new.automaticRecipes); XCTAssertNil(new.automaticLineLength)
            for (request, location, target) in [
                (SkyEntryRequest.firstLight, StarfallChallenge.firstLight, 150_000),
                (.ribbonCrossing, .ribbonCrossing, 220_000)
            ] {
                var flow = SkyFlowState(arguments: [])
                XCTAssertEqual(flow.handle(location.flowAction, hasSavedSky: true), .staged)
                XCTAssertEqual(flow.entry, request)
                let staged = flow
                let selected = SkyHelpContext.selected(game: game, entry: flow.entry)
                XCTAssertEqual(selected.restorationChallenge, location)
                XCTAssertTrue(selected.challenge); XCTAssertFalse(selected.criticalMass)
                XCTAssertFalse(selected.openingCascade); XCTAssertFalse(selected.opalStorms)
                XCTAssertTrue(selected.scaledPoints)
                XCTAssertFalse(selected.manualClears); XCTAssertTrue(selected.automaticRecipes)
                XCTAssertEqual(selected.automaticLineLength, 4)
                XCTAssertTrue(selected.restorationHelp?.contains(SkyCopy.score(target)) == true)
                XCTAssertEqual(flow, staged, "Reading pending Help cannot commit or change the selected Entry")
            }
            var replay = SkyFlowState(arguments: [])
            XCTAssertEqual(replay.handle(.resume, hasSavedSky: true), .continued)
            let ticket = try XCTUnwrap(replay.handoff?.id)
            replay.settleHandoff(ticket)
            _ = replay.completeHandoff(ticket, ready: true, active: true, modal: false)
            XCTAssertEqual(replay.handle(.replay, hasSavedSky: true), .staged)
            XCTAssertEqual(replay.entry, .replay)
            let stagedReplay = replay
            XCTAssertEqual(SkyHelpContext.selected(game: game, entry: replay.entry), SkyHelpContext(game: game))
            XCTAssertEqual(replay, stagedReplay, "Reading Replay Help retains the pending same-round choice")
            XCTAssertEqual(try SkySaveArchive.encode(game), saved, "Help previews preserve the retained round")
        }
        XCTAssertFalse(SkyHelpContext(game: challenge).scaledPoints)
        XCTAssertTrue(SkyHelpContext(game: challenge).restorationHelp?.contains("18 starlight") == true)
        XCTAssertEqual(SkyHelpContext(game: fresh).lessons, SkyLesson.allCases)
        XCTAssertEqual(SkyHelpContext(game: retained).lessons, [.square, .cross, .relay])
        XCTAssertEqual(SkyHelpContext(game: challenge).lessons, [.square, .cross, .relay])
        let dusk = SkyHelpContext(game: retained)
        XCTAssertFalse(dusk.criticalMass); XCTAssertFalse(dusk.challenge); XCTAssertEqual(dusk.duskRule, .patientFeeding)
    }
}
