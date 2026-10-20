import XCTest
import StarfallCore
@testable import Starfall

final class RestorationFlowTests: XCTestCase {
    @MainActor private func make(saved game: FallingSky? = nil, arguments: [String] = []) throws
        -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.RestorationFlow.\(UUID().uuidString)"
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
                XCTAssertEqual(preview.progress, FallingSky.freshChallenge(choice).restoration)
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
            for source in StarfallChallenge.allCases where source != destination {
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
                let opening = FallingSky.freshChallenge(destination)
                XCTAssertEqual(store.game, opening)
                XCTAssertTrue(store.isPaused); XCTAssertTrue(store.suspended)
                XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
                oldRain(); oldCompletion(); clock.advance(100)
                XCTAssertEqual(store.game, opening)
                XCTAssertNil(clock.deadline)
                XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: id))
            }
        }
    }

    private struct LocationContract {
        let challenge: StarfallChallenge
        let prefix: String
        let title: String
        let guide: String
        let result: String
    }

    private let locations = [
        LocationContract(challenge: .firstLight, prefix: "lantern", title: "Lantern Landing",
                         guide: "guide.won.1", result: "First Light complete! Lantern Landing is restored."),
        LocationContract(challenge: .ribbonCrossing, prefix: "ribbon", title: "Ribbon Crossing",
                         guide: "guide.ribbon-won.1", result: "Ribbon Crossing complete! The cloud banks are connected again."),
        LocationContract(challenge: .kiteHarbor, prefix: "kite", title: "Kite Harbor",
                         guide: "guide.kite-won.1", result: "Kite Harbor complete! The fleet is aloft and ready to depart."),
        LocationContract(challenge: .seedMoon, prefix: "seed", title: "Seed Moon",
                         guide: "guide.seed-won.1", result: "Seed Moon complete! The sleeping seed has grown into a glowing shelter."),
        LocationContract(challenge: .silverPools, prefix: "silver", title: "Silver Pools",
                         guide: "guide.silver-won.1", result: "Silver Pools complete! One silver cascade now flows through every pool."),
        LocationContract(challenge: .frostfruitOrchard, prefix: "frostfruit", title: "Frostfruit Orchard",
                         guide: "guide.frostfruit-won.1", result: "Frostfruit Orchard complete! The crown has opened and luminous seeds drift through the winter garden."),
        LocationContract(challenge: .sunwheelMill, prefix: "sunwheel", title: "Sunwheel Mill",
                         guide: "guide.sunwheel-won.1", result: "Sunwheel Mill complete! The outlet is open and golden light flows onward.")
    ]

    @MainActor func testEachWinningClearCommitsBeforeSettlementAndRestoresWithoutClock() throws {
        for location in locations {
            for interrupted in [false, true] {
                let fixture = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: location.challenge)
                let (store, presenter, clock, defaults) = try make(saved: fixture)
                store.setSuspended(false)
                store.clear(Cell(0, 0))
                XCTAssertEqual(store.game.score, 18)
                XCTAssertEqual(store.game.outcome, .won)
                XCTAssertTrue(store.busy)
                XCTAssertEqual(store.guideLine.id, location.guide)
                let won = store.game
                XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), won)
                if interrupted { store.setSuspended(true) }
                presenter.finish(); store.setSuspended(false); clock.advance(100)
                XCTAssertEqual(store.game, won)
                XCTAssertNil(clock.deadline)
                let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertEqual(restored.game, won)
                XCTAssertEqual(restored.guideLine.id, location.guide)
                XCTAssertEqual(SkyResultSnapshot(game: restored.game)?.challenge, location.challenge)
                XCTAssertEqual(SkyResultSnapshot(game: restored.game)?.reason, location.result)
                restored.beginEntry(.replay)
                XCTAssertEqual(restored.game, FallingSky(challenge: location.challenge))
                XCTAssertEqual(restored.game.restoration?.fraction, 0)
                restored.beginEntry(.fresh)
                XCTAssertNil(restored.game.challenge)
                XCTAssertNil(restored.game.restoration)
                XCTAssertEqual(restored.game.balance, StarfallBalance())
                XCTAssertEqual(restored.game.cadenceID, .announcedCycleV1)
            }
        }
    }

    func testCopyAndHelpFollowSelectedIdentityForEntryReplayWinAndOverflow() throws {
        XCTAssertEqual(locations.map(\.challenge), StarfallChallenge.allCases)
        XCTAssertEqual(StarfallChallenge.sunwheelMill.welcomeIdentifier, "sky.sunwheel-mill")
        XCTAssertEqual(StarfallChallenge.sunwheelMill.menuIdentifier, "experiment.sunwheel-mill")
        XCTAssertEqual(StarfallChallenge.frostfruitOrchard.welcomeIdentifier, "sky.frostfruit-orchard")
        XCTAssertEqual(StarfallChallenge.frostfruitOrchard.menuIdentifier, "experiment.frostfruit-orchard")
        XCTAssertEqual(StarfallChallenge.silverPools.welcomeIdentifier, "sky.silver-pools")
        XCTAssertEqual(StarfallChallenge.silverPools.menuIdentifier, "experiment.silver-pools")
        XCTAssertEqual(StarfallChallenge.seedMoon.welcomeIdentifier, "sky.seed-moon")
        XCTAssertEqual(StarfallChallenge.seedMoon.menuIdentifier, "experiment.seed-moon")
        XCTAssertEqual(StarfallChallenge.kiteHarbor.welcomeIdentifier, "sky.kite-harbor")
        XCTAssertEqual(StarfallChallenge.kiteHarbor.menuIdentifier, "experiment.kite-harbor")
        XCTAssertEqual(StarfallChallenge.ribbonCrossing.welcomeIdentifier, "sky.ribbon-crossing")
        XCTAssertEqual(StarfallChallenge.ribbonCrossing.menuIdentifier, "experiment.ribbon-crossing")
        for location in locations {
            let challenge = location.challenge
            XCTAssertEqual(challenge.restorationIdentifier, "\(location.prefix).restoration")
            let selected = try XCTUnwrap(SkyEntryRequest.allCases.first { $0 != .replay && $0.selectedChallenge(replaying: nil) == challenge })
            let fresh = FallingSky.freshChallenge(challenge)
            for entry in [selected, .replay] {
                let line = entry.introduction(challenge: challenge)
                XCTAssertTrue(line.text.contains(location.title))
                let target = entry == .replay ? 18 : try XCTUnwrap(fresh.displayTarget)
                XCTAssertTrue(line.text.contains("\(SkyCopy.score(target)) starlight"))
            }
            let freshTarget = SkyCopy.score(try XCTUnwrap(fresh.displayTarget))
            XCTAssertTrue(fresh.challengeHelpText?.contains("\(freshTarget) starlight") == true)
            XCTAssertTrue(fresh.challengeGuideLine?.text.contains("\(freshTarget) starlight") == true)
            let freshReplay = SkyEntryRequest.replay.introduction(challenge: challenge,
                replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
            XCTAssertTrue(freshReplay.text.contains("\(freshTarget) starlight"))
            XCTAssertTrue(SkyEntryRequest.replay.introduction(challenge: challenge).text.contains("Your saved round stays until you tap Begin."))
            XCTAssertTrue(challenge.helpText.contains(location.title))
            XCTAssertTrue(challenge.helpText.contains("Swipe neighboring stars"))
            XCTAssertFalse(challenge.helpText.contains("no swaps"))
            XCTAssertEqual(challenge.restorationLabel(progress: .init(score: 9, target: 18)), "\(location.title), 50% restored")
            XCTAssertEqual(challenge.restorationLabel(progress: .init(score: 22, target: 18)), "\(location.title), 100% restored")
            var full = FallingSky(challenge: challenge)
            for _ in 0..<40 where !full.isOver { _ = full.letStarsFall() }
            let result = try XCTUnwrap(SkyResultSnapshot(game: full))
            XCTAssertFalse(result.won)
            XCTAssertEqual(result.challenge, challenge)
            XCTAssertEqual(result.target, 18)
            XCTAssertTrue(result.reason.contains("Column"))
            XCTAssertEqual(challenge.replayLabel, "Replay \(challenge.title)")
            XCTAssertEqual(SkyWelcomeSnapshot(game: progressed(challenge), hasSavedSky: true, paused: true).summary,
                           "\(challenge.title) · 9 of 18 starlight · Automatic showers paused")
        }
        XCTAssertTrue(StarfallChallenge.kiteHarbor.helpText.hasPrefix("Raise Kite Harbor’s sails with 18 starlight."))
        XCTAssertTrue(StarfallChallenge.silverPools.helpText.hasPrefix("Restore Silver Pools with 18 starlight."))
        XCTAssertTrue(StarfallChallenge.sunwheelMill.helpText.hasPrefix("Restore Sunwheel Mill with 18 starlight."))
        XCTAssertTrue(StarfallChallenge.frostfruitOrchard.helpText.hasPrefix("Restore Frostfruit Orchard with 18 starlight."))
        XCTAssertTrue(StarfallChallenge.seedMoon.helpText.hasPrefix("Wake Seed Moon with 18 starlight."))
    }

    @MainActor func testReviewFixturesRequireOneIsolatedResetChoiceAndUseRealScoring() throws {
        for location in locations {
            let prefix = "--\(location.prefix)-restoration-review="
            for score in [0, 5, 9, 14, 18] {
                let (store, presenter, _, _) = try make(arguments: ["--starfalls-reset", "--dialogue-review", prefix + "\(score)"])
                XCTAssertEqual(store.game.challenge, location.challenge)
                XCTAssertEqual(store.game.score, score)
                XCTAssertTrue(store.game.isValidSave)
                if score == 14 {
                    store.setSuspended(false); store.clear(Cell(0, 0)); presenter.finish()
                    XCTAssertEqual(store.game.score, 18)
                    XCTAssertEqual(store.game.outcome, .won)
                }
            }
            let retained = progressed(location.challenge)
            var invalid = [
                [prefix + "9"],
                ["--dialogue-review", prefix + "9"],
                ["--starfalls-reset", prefix + "9"],
                ["--starfalls-reset", "--dialogue-review", prefix + "-1"],
                ["--starfalls-reset", "--dialogue-review", prefix + "19"],
                ["--starfalls-reset", "--dialogue-review", prefix + "bad"],
                ["--starfalls-reset", "--dialogue-review", prefix + "9", prefix + "14"]
            ]
            for other in locations where other.challenge != location.challenge {
                invalid.append(["--starfalls-reset", "--dialogue-review", prefix + "9", "--\(other.prefix)-restoration-review=9"])
            }
            for arguments in invalid {
                let (store, _, _, defaults) = try make(saved: retained, arguments: arguments)
                XCTAssertEqual(store.game, arguments.contains("--starfalls-reset") ? FallingSky.freshSurvival(seed: 5) : retained)
                XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), retained)
            }
            let (dense, _, _, _) = try make(arguments: ["--starfalls-reset", "--dialogue-review", prefix + "9", "--restoration-dense"])
            XCTAssertEqual(dense.game.challenge, location.challenge)
            XCTAssertEqual(dense.game.occupiedCount, 49)
            XCTAssertTrue(dense.game.isValidSave)
        }
    }
    @MainActor func testV8RestorationMigratesActionsOnActivationAndKeepsOriginalBytes() throws {
        // Freeze the v8 inventory; newly added locations use the current envelope.
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools] {
            let original = progressed(challenge)
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
            fields.removeValue(forKey: "savedChallengeActions")
            let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 8, "game": fields], options: [.sortedKeys])
            let (_, _, _, defaults) = try make()
            defaults.set(bytes, forKey: SkySaveArchive.agingKey)
            let presenter = FallingSkyRecorder(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            XCTAssertEqual(store.game, original)
            XCTAssertTrue(store.game.canArrangeStars)
            XCTAssertTrue(SkyHelpContext(game: store.game).arranging)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
            store.setSuspended(false)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), original)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.agingKey), bytes)
            store.restart(sameSky: true)
            XCTAssertEqual(store.game, FallingSky(challenge: challenge))
            defaults.set(Data("broken".utf8), forKey: SkySaveArchive.key)
            XCTAssertNil(SkySaveArchive.load(from: defaults), "Never fall back to the old v8 round")
        }
    }

}
