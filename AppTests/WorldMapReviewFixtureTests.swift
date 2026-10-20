import XCTest
import StarfallCore
@testable import Starfall

#if DEBUG
final class WorldMapReviewFixtureTests: XCTestCase {
    @MainActor private func preserveReviewDomain() -> UserDefaults {
        let suite = WorldMapReviewFixture.suiteName
        let defaults = UserDefaults(suiteName: suite)!
        let previous = defaults.persistentDomain(forName: suite)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suite)
            if let previous { defaults.setPersistentDomain(previous, forName: suite) }
        }
        return defaults
    }

    @MainActor func testReviewAdmissionRequiresExplicitResetMarkerAndExactlyOneKnownState() throws {
        let defaults = preserveReviewDomain()
        defaults.set("keep review data", forKey: "fixture.guard")
        let original = try SkySaveArchive.encode(FallingSky.freshSurvival(seed: 91))
        defaults.set(original, forKey: SkySaveArchive.key)
        let domain = NSDictionary(dictionary: defaults.persistentDomain(forName: WorldMapReviewFixture.suiteName)!)
        let marker = WorldMapReviewFixture.marker
        let selector = WorldMapReviewFixture.statePrefix + "fresh"
        let invalid = [
            [], [selector], ["--starfalls-reset", selector], [marker, selector],
            ["--starfalls-reset", marker], ["--starfalls-reset", marker, "--world-map-state="],
            ["--starfalls-reset", marker, "--world-map-state=unknown"],
            ["--starfalls-reset", marker, "--world-map-state=allFive"],
            ["--starfalls-reset", marker, selector, selector],
            ["--starfalls-reset", marker, selector, "--world-map-state=retained"]
        ]
        for arguments in invalid {
            XCTAssertNil(WorldMapReviewFixture.requested(arguments: arguments), "\(arguments)")
            XCTAssertNotEqual(SkyFlowScreen.initial(arguments: arguments), .worldMap)
            if arguments.contains(marker) {
                let selected = SkyDefaults.forApp(arguments: arguments)
                XCTAssertEqual(selected.string(forKey: "fixture.guard"), "keep review data")
                let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
                XCTAssertTrue(store.suspended)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), original)
            } else {
                XCTAssertTrue(SkyDefaults.forApp(arguments: arguments) === UserDefaults.standard)
            }
            XCTAssertEqual(NSDictionary(dictionary: defaults.persistentDomain(forName: WorldMapReviewFixture.suiteName)!), domain)
        }
        for fixture in WorldMapReviewFixture.allCases {
            XCTAssertEqual(WorldMapReviewFixture.requested(arguments: [
                "--starfalls-reset", marker, WorldMapReviewFixture.statePrefix + fixture.rawValue
            ]), fixture)
        }
    }

    @MainActor func testEveryReviewStateRestoresCommittedJourneyThroughProductionReaders() throws {
        let defaults = preserveReviewDomain()
        let cases: [(WorldMapReviewFixture, Set<WorldLocation>, WorldLocation, StarfallChallenge?, Outcome?, Bool)] = [
            (.fresh, [], .firstLight, nil, nil, false),
            (.twoRepairs, [.firstLight, .ribbonCrossing], .kiteHarbor, .ribbonCrossing, .won, false),
            (.allReady, [.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard, .sunwheelMill], .sunwheelMill, .sunwheelMill, .won, false),
            (.locked, [], .frostfruitOrchard, nil, nil, false),
            (.unbuilt, [], .bellChoir, nil, nil, false),
            (.retained, [.firstLight, .ribbonCrossing], .kiteHarbor, .kiteHarbor, .playing, false),
            (.recovery, [.firstLight], .ribbonCrossing, .firstLight, .won, true)
        ]
        for (fixture, completed, selection, challenge, outcome, recovered) in cases {
            let arguments = ["--starfalls-reset", WorldMapReviewFixture.marker,
                             WorldMapReviewFixture.statePrefix + fixture.rawValue]
            let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
            XCTAssertEqual(SkyFlowScreen.initial(arguments: arguments), .worldMap)
            XCTAssertEqual(store.journey.journey.completed, completed, fixture.rawValue)
            XCTAssertEqual(store.journey.journey.selected, selection, fixture.rawValue)
            XCTAssertEqual(store.journey.recovered, recovered, fixture.rawValue)
            XCTAssertFalse(store.journey.journey.legacyAccess)
            XCTAssertTrue(store.journey.journey.isValid)
            XCTAssertTrue(store.game.isValidSave)
            XCTAssertTrue(store.suspended); XCTAssertTrue(store.isPaused)
            XCTAssertEqual(store.hasSavedSky, challenge != nil)
            XCTAssertEqual(store.game.challenge, challenge)
            if let outcome { XCTAssertEqual(store.game.outcome, outcome) }
            if challenge != nil {
                XCTAssertEqual(store.game.challengeRevision, 0, "Review repairs and retained rounds preserve their historical definition")
                XCTAssertEqual(store.game.displayTarget, 18)
            }
            if fixture == .retained { XCTAssertEqual(store.game.score, 9) }
            if fixture == .locked {
                XCTAssertNotNil(selection.challenge)
                XCTAssertFalse(store.journey.journey.canEnter(selection))
            }
            if fixture == .unbuilt {
                XCTAssertNil(selection.challenge)
                XCTAssertFalse(store.journey.journey.canEnter(selection))
            }
            if fixture == .allReady {
                XCTAssertEqual(store.journey.journey.completed.count, 7)
                XCTAssertTrue(WorldLocation.allCases.filter { $0.challenge != nil }
                    .allSatisfy(store.journey.journey.canEnter))
                XCTAssertFalse(store.journey.journey.canEnter(.bellChoir))
            }
            let roundBytes = defaults.data(forKey: SkySaveArchive.key)
            let worldBytes = defaults.data(forKey: WorldJourneyStore.key)
            let restored = FallingSkyStore(defaults: defaults, arguments: [],
                                          presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, store.game)
            XCTAssertEqual(restored.journey.journey, store.journey.journey)
            XCTAssertEqual(restored.journey.recovered, recovered)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes, "Restore is read-only")
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes, "Restore is read-only")
            if recovered {
                XCTAssertEqual(worldBytes, WorldMapReviewFixture.rejectedWorldBytes)
                try store.journey.select(.kiteHarbor)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.rejectedKey), worldBytes)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes)
                XCTAssertEqual(store.journey.journey.completed, [.firstLight])
            }
        }
    }

    @MainActor func testMapEntryKeepsHistoricalRepairUntilBeginSelectsCurrentDefinition() throws {
        let defaults = preserveReviewDomain()
        let arguments = ["--starfalls-reset", WorldMapReviewFixture.marker, "--world-map-state=twoRepairs"]
        for (challenge, target) in [(StarfallChallenge.firstLight, 150_000), (.ribbonCrossing, 220_000)] {
            let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
            let location = try XCTUnwrap(WorldLocation(rawValue: challenge.rawValue))
            try store.journey.select(location)
            let retained = store.game
            let journey = store.journey.journey
            let roundBytes = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            let worldBytes = try XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))
            XCTAssertEqual(retained.challenge, .ribbonCrossing)
            XCTAssertEqual(retained.challengeRevision, 0)
            XCTAssertEqual(retained.displayTarget, 18)
            XCTAssertEqual(retained.outcome, .won)
            XCTAssertEqual(journey.completed, [.firstLight, .ribbonCrossing])

            var flow = SkyFlowState(arguments: arguments)
            XCTAssertEqual(flow.handle(challenge.flowAction, hasSavedSky: true), .staged)
            let pending = try XCTUnwrap(flow.entry)
            XCTAssertTrue(pending.introduction(challenge: challenge).text.contains(SkyCopy.score(target)))
            XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
            XCTAssertEqual(store.game, retained)
            XCTAssertEqual(store.journey.journey, journey)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)

            XCTAssertEqual(flow.handle(challenge.flowAction, hasSavedSky: true), .staged)
            guard case .began(let request)? = flow.handle(.begin, hasSavedSky: true, entryID: flow.entryID) else {
                XCTFail("The current destination must pass the explicit Begin boundary")
                return
            }
            store.beginEntry(request)
            XCTAssertEqual(store.game.challenge, challenge)
            XCTAssertEqual(store.game.challengeRevision, 1)
            XCTAssertEqual(store.game.displayTarget, target)
            XCTAssertEqual(store.game.displayScore, 0)
            XCTAssertTrue(store.game.isValidSave)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
            XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), roundBytes)
            XCTAssertEqual(store.journey.journey, journey)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes,
                           "Beginning a new visit neither removes nor earns a repair")
        }
    }

    @MainActor func testReviewPreparationPlayAndPreferenceWritesNeverTouchOrdinaryDefaults() throws {
        let review = preserveReviewDomain()
        let ordinary = UserDefaults.standard
        let keys = [SkySaveArchive.key, SkySaveArchive.worldKey, WorldJourneyStore.key, SkySaveArchive.rejectedKey,
                    WorldJourneyStore.rejectedKey, "soundEnabled", "starfall.haptics", "calmEffects"]
        let before = keys.map { ordinary.object(forKey: $0) as? NSObject }
        let arguments = ["--starfalls-reset", WorldMapReviewFixture.marker, "--world-map-state=retained"]
        let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
        store.soundEnabled = false; store.hapticsEnabled = false
        SkyDefaults.forApp(arguments: arguments).set(true, forKey: "calmEffects")
        try store.journey.select(.silverPools)
        store.startFirstLight()
        XCTAssertEqual(SkySaveArchive.load(from: review)?.challenge, .firstLight)
        XCTAssertEqual(WorldJourneyStore(defaults: review).journey.selected, .silverPools)
        XCTAssertEqual(review.object(forKey: "soundEnabled") as? Bool, false)
        XCTAssertEqual(review.object(forKey: "starfall.haptics") as? Bool, false)
        XCTAssertEqual(review.object(forKey: "calmEffects") as? Bool, true)
        for (index, key) in keys.enumerated() {
            XCTAssertEqual(ordinary.object(forKey: key) as? NSObject, before[index], key)
        }
        let restored = FallingSkyStore.forSkyFlowApp(arguments: [WorldMapReviewFixture.marker])
        XCTAssertEqual(restored.game, store.game)
        XCTAssertEqual(restored.journey.journey.selected, .silverPools)
        XCTAssertEqual(SkyFlowScreen.initial(arguments: [WorldMapReviewFixture.marker]), .welcome)
    }

    @MainActor func testMapReviewMarkerCannotResetAnotherReviewOrInjectItsSaveFailure() throws {
        let mapDefaults = preserveReviewDomain()
        let otherSuite = "Starfall.SkyFlowReview"
        let otherDefaults = UserDefaults(suiteName: otherSuite)!
        let previous = otherDefaults.persistentDomain(forName: otherSuite)
        addTeardownBlock {
            otherDefaults.removePersistentDomain(forName: otherSuite)
            if let previous { otherDefaults.setPersistentDomain(previous, forName: otherSuite) }
        }
        otherDefaults.set("keep the other review", forKey: "fixture.guard")
        let otherDomain = NSDictionary(dictionary: otherDefaults.persistentDomain(forName: otherSuite)!)
        for failureFlag in ["--save-rejection-review", "--save-failure-review"] {
            let original = try SkySaveArchive.encode(FallingSky.freshSurvival(seed: 91))
            mapDefaults.set(original, forKey: SkySaveArchive.key)
            let arguments = ["--starfalls-reset", WorldMapReviewFixture.marker,
                             "--world-map-state=unknown", "--sky-flow-review", failureFlag]
            let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
            XCTAssertEqual(mapDefaults.data(forKey: SkySaveArchive.key), original,
                           "A rejected map-state request cannot mutate either review during initialization")
            XCTAssertEqual(NSDictionary(dictionary: otherDefaults.persistentDomain(forName: otherSuite)!), otherDomain)
            store.startFirstLight()
            XCTAssertFalse(store.saveFailed, "The other review's failure injector must not attach to the map store")
            XCTAssertEqual(SkySaveArchive.load(from: mapDefaults)?.challenge, .firstLight)
            XCTAssertEqual(NSDictionary(dictionary: otherDefaults.persistentDomain(forName: otherSuite)!), otherDomain)
        }
    }
}
#endif
