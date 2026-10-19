import XCTest
import StarfallCore
@testable import Starfall

final class RibbonCrossingFlowTests: XCTestCase {
    @MainActor private func make(saved game: FallingSky? = nil, arguments: [String] = []) throws
        -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.RibbonFlow.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        if let game { defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key) }
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: arguments, presenter: presenter, clock: clock)
        return (store, presenter, clock, defaults)
    }

    private func progressed(_ challenge: StarfallChallenge) -> FallingSky {
        var game = FallingSky(challenge: challenge)
        for _ in 0..<40 where game.score < 9 && !game.isOver {
            if let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
            else { _ = game.letStarsFall() }
        }
        XCTAssertEqual(game.score, 9)
        return game
    }

    @MainActor func testCrossLocationPreviewsAndCancelKeepTheCommittedRoundAndBytes() throws {
        for retainedChallenge in StarfallChallenge.allCases {
            let retained = progressed(retainedChallenge)
            let (store, _, clock, defaults) = try make(saved: retained)
            let saved = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            for choice in StarfallChallenge.allCases {
                var flow = SkyFlowState(arguments: [])
                XCTAssertEqual(flow.handle(choice.flowAction, hasSavedSky: true), .staged)
                let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
                XCTAssertEqual(preview.challenge, choice)
                XCTAssertEqual(preview.progress, StarlightRestoration(score: 0, target: 18))
                XCTAssertEqual(SkyHelpContext.selected(game: store.game, entry: flow.entry).restorationChallenge, choice)
                XCTAssertTrue(flow.entry?.introduction(challenge: choice).text.contains(choice.locationTitle) == true)
                clock.advance(100)
                XCTAssertEqual(store.game, retained)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
                XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
                let restored = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
                XCTAssertEqual(restored.challenge, retainedChallenge)
                XCTAssertEqual(restored.progress, retained.restoration)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
            }
            var replay = SkyFlowState(arguments: ["--starfalls-reset"])
            XCTAssertEqual(replay.handle(.replay, hasSavedSky: true), .staged)
            XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: replay.entry)?.challenge, retainedChallenge)
            XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: replay.entry)?.progress.fraction, 0)
            var open = SkyFlowState(arguments: [])
            XCTAssertEqual(open.handle(.start, hasSavedSky: true), .staged)
            XCTAssertNil(RestorationPresentation.selected(game: store.game, entry: open.entry))
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
        }
    }

    @MainActor func testCrossLocationBeginCommitsOnceAndRejectsOldClockAndPresentation() throws {
        for destination in StarfallChallenge.allCases {
            let source: StarfallChallenge = destination == .firstLight ? .ribbonCrossing : .firstLight
            let (store, presenter, clock, defaults) = try make(saved: progressed(source))
            store.setSuspended(false); store.togglePause()
            let oldRain = try XCTUnwrap(clock.action)
            store.callShower()
            let oldCompletion = try XCTUnwrap(presenter.completions.last)
            store.setSuspended(true)
            let retained = store.game
            var flow = SkyFlowState(arguments: [])
            _ = flow.handle(source.flowAction, hasSavedSky: true)
            let staleID = try XCTUnwrap(flow.entryID)
            _ = flow.handle(.home, hasSavedSky: true)
            _ = flow.handle(destination.flowAction, hasSavedSky: true)
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: staleID))
            XCTAssertEqual(store.game, retained)
            let id = try XCTUnwrap(flow.entryID)
            guard case .began(let request) = flow.handle(.begin, hasSavedSky: true, entryID: id) else {
                return XCTFail("Expected the explicit Begin boundary")
            }
            store.beginEntry(request)
            let opening = FallingSky(challenge: destination)
            XCTAssertEqual(store.game, opening)
            XCTAssertTrue(store.isPaused); XCTAssertTrue(store.suspended)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
            oldRain(); oldCompletion(); clock.advance(100)
            XCTAssertEqual(store.game, opening)
            XCTAssertNil(clock.deadline)
            XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: id))
        }
    }

    @MainActor func testRibbonWinningClearCommitsBeforeSettlementAndRestoresWithoutClock() throws {
        for interrupted in [false, true] {
            let fixture = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .ribbonCrossing)
            let (store, presenter, clock, defaults) = try make(saved: fixture)
            store.setSuspended(false)
            store.clear(Cell(0, 0))
            XCTAssertEqual(store.game.score, 18)
            XCTAssertEqual(store.game.outcome, .won)
            XCTAssertTrue(store.busy)
            XCTAssertEqual(store.guideLine.id, "guide.ribbon-won.1")
            XCTAssertFalse(store.guideLine.text.contains("Lantern"))
            let won = store.game
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), won)
            if interrupted { store.setSuspended(true) }
            presenter.finish(); store.setSuspended(false); clock.advance(100)
            XCTAssertEqual(store.game, won)
            XCTAssertNil(clock.deadline)
            let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, won)
            XCTAssertEqual(restored.guideLine.id, "guide.ribbon-won.1")
            XCTAssertEqual(SkyResultSnapshot(game: restored.game)?.challenge, .ribbonCrossing)
            XCTAssertEqual(SkyResultSnapshot(game: restored.game)?.reason,
                           "Ribbon Crossing complete! The cloud banks are connected again.")
            restored.beginEntry(.replay)
            XCTAssertEqual(restored.game, FallingSky(challenge: .ribbonCrossing))
            XCTAssertEqual(restored.game.restoration?.fraction, 0)
            restored.beginEntry(.fresh)
            XCTAssertNil(restored.game.challenge)
            XCTAssertNil(restored.game.restoration)
            XCTAssertEqual(restored.game.balance, StarfallBalance())
            XCTAssertEqual(restored.game.cadenceID, .announcedCycleV1)
        }
    }

    func testRibbonCopyAndHelpFollowSelectedIdentityForEntryReplayWinAndOverflow() throws {
        let challenge = StarfallChallenge.ribbonCrossing
        XCTAssertEqual(challenge.welcomeIdentifier, "sky.ribbon-crossing")
        XCTAssertEqual(challenge.menuIdentifier, "experiment.ribbon-crossing")
        XCTAssertEqual(challenge.restorationIdentifier, "ribbon.restoration")
        for entry in [SkyEntryRequest.ribbonCrossing, .replay] {
            let line = entry.introduction(challenge: challenge)
            XCTAssertTrue(line.text.contains("Ribbon Crossing"))
            XCTAssertTrue(line.text.contains("18 starlight"))
            XCTAssertFalse(line.text.contains("Lantern"))
        }
        XCTAssertTrue(SkyEntryRequest.replay.introduction(challenge: challenge).text.contains("Your saved round stays until you tap Begin."))
        XCTAssertTrue(challenge.helpText.hasPrefix("Reconnect Ribbon Crossing with 18 starlight."))
        XCTAssertEqual(challenge.restorationLabel(progress: .init(score: 9, target: 18)), "Ribbon Crossing, 50% restored")
        var full = FallingSky(challenge: challenge)
        for _ in 0..<40 where !full.isOver { _ = full.letStarsFall() }
        let result = try XCTUnwrap(SkyResultSnapshot(game: full))
        XCTAssertFalse(result.won)
        XCTAssertEqual(result.challenge, challenge)
        XCTAssertEqual(result.target, 18)
        XCTAssertTrue(result.reason.contains("Column"))
        XCTAssertEqual(challenge.replayLabel, "Replay Ribbon Crossing")
        XCTAssertEqual(SkyWelcomeSnapshot(game: progressed(challenge), hasSavedSky: true, paused: true).summary,
                       "Ribbon Crossing · 9 of 18 starlight · Automatic showers paused")
    }

    @MainActor func testRibbonReviewFixturesRequireIsolatedResetAndUseRealScoring() throws {
        for score in [0, 5, 9, 14, 18] {
            let (store, presenter, _, _) = try make(arguments: ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=\(score)"])
            XCTAssertEqual(store.game.challenge, .ribbonCrossing)
            XCTAssertEqual(store.game.score, score)
            XCTAssertTrue(store.game.isValidSave)
            if score == 14 {
                store.setSuspended(false); store.clear(Cell(0, 0)); presenter.finish()
                XCTAssertEqual(store.game.score, 18)
                XCTAssertEqual(store.game.outcome, .won)
            }
        }
        let retained = progressed(.firstLight)
        for arguments in [
            ["--ribbon-restoration-review=9"],
            ["--dialogue-review", "--ribbon-restoration-review=9"],
            ["--starfalls-reset", "--ribbon-restoration-review=9"],
            ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=-1"],
            ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=19"],
            ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=bad"],
            ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=9", "--lantern-restoration-review=9"]
        ] {
            let (store, _, _, defaults) = try make(saved: retained, arguments: arguments)
            XCTAssertEqual(store.game, arguments.contains("--starfalls-reset") ? FallingSky.freshSurvival(seed: 5) : retained)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), retained)
        }
        let (dense, _, _, _) = try make(arguments: ["--starfalls-reset", "--dialogue-review", "--ribbon-restoration-review=9", "--restoration-dense"])
        XCTAssertEqual(dense.game.occupiedCount, 49)
        XCTAssertTrue(dense.game.isValidSave)
    }
}
