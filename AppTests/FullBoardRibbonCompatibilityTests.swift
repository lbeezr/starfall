import XCTest
import StarfallCore
@testable import Starfall

final class FullBoardRibbonCompatibilityTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FullBoardRibbonCompatibility.\(UUID())"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }

    private func envelope(_ game: FallingSky, version: Int) throws -> Data {
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": fields], options: .sortedKeys)
    }

    private func retainedArchives() throws -> [(game: FallingSky, key: String, version: Int)] {
        var five = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        var six = FallingSky.fullBoardLantern()
        _ = try XCTUnwrap(five.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        _ = try XCTUnwrap(six.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        var lanternSky = FallingSky.freshChallenge(.firstLight)
        var ribbonSky = FallingSky.freshChallenge(.ribbonCrossing)
        _ = try XCTUnwrap(lanternSky.letStarsFall())
        _ = try XCTUnwrap(ribbonSky.letStarsFall())
        return [
            (five, SkySaveArchive.revisedFullBoardKey, 15),
            (six, SkySaveArchive.revisedFullBoardKey, 15),
            (lanternSky, SkySaveArchive.revisedFullBoardKey, 15),
            (ribbonSky, SkySaveArchive.revisedFullBoardKey, 15),
            (five, SkySaveArchive.fullBoardKey, 14),
            (lanternSky, SkySaveArchive.fullBoardKey, 14),
            (ribbonSky, SkySaveArchive.fullBoardKey, 14)
        ]
    }

    @MainActor func testV16RibbonRestoresExactCommittedRefillContinuationAndSameRoundReplay() throws {
        let opening = FallingSky.fullBoardRibbon()
        var game = opening
        let first = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(first.displayAward, 30_000)
        XCTAssertEqual(first.resolutionPhases.count, 3)
        XCTAssertEqual(game.occupiedCount, 49)
        let bytes = try SkySaveArchive.encode(game)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(SkySaveArchive.key, "starfall.accumulation.v16")
        XCTAssertEqual(fields["schemaVersion"] as? Int, 16)
        XCTAssertEqual(try SkySaveArchive.decode(bytes), game)
        XCTAssertEqual(try SkySaveArchive.encode(SkySaveArchive.decode(bytes)), bytes)

        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        defaults.set(bytes, forKey: SkySaveArchive.key)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        defer { store.setSuspended(true) }
        XCTAssertEqual(store.game, game)
        XCTAssertEqual(store.game.challengeRevision, 7)
        XCTAssertEqual(store.game.displayTarget, 220_000)
        XCTAssertTrue(store.game.usesFullBoardRefill)
        XCTAssertFalse(store.openingPending)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes, "Restore construction is read-only")
        store.setSuspended(false)
        XCTAssertNil(clock.deadline)

        var expected = game
        let next = try XCTUnwrap(expected.nudge(from: Cell(1, 4), to: Cell(1, 5)))
        XCTAssertEqual(next.displayAward, 5_000)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 4), Cell(1, 5)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected, "Restored continuation keeps identities, supply and seeded randomness")
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
        presenter.finish()

        let replayClock = ManualRainClock()
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: replayClock)
        defer { restored.setSuspended(true) }
        XCTAssertEqual(restored.game, expected)
        restored.setSuspended(false)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
        XCTAssertNil(replayClock.deadline)
        XCTAssertEqual(FallingSky.freshChallenge(.ribbonCrossing).challengeRevision, 4)
        XCTAssertFalse(FallingSky.freshChallenge(.ribbonCrossing).usesFullBoardRefill)
    }

    @MainActor func testV15AndV14RestoreTheirExactRetainedDefinitionsWithoutWritingOrUpgrading() throws {
        for archive in try retainedArchives() {
            let defaults = defaults(), bytes = try envelope(archive.game, version: archive.version)
            defaults.set(bytes, forKey: archive.key)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), archive.game)
            guard case .loaded(let inspected) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Expected retained revision \(archive.game.challengeRevision) at \(archive.key)")
            }
            XCTAssertEqual(inspected, archive.game)
            let challenge = try XCTUnwrap(archive.game.challenge)
            let definition = try XCTUnwrap(StoryChallengeDefinition(challenge,
                revision: archive.game.challengeRevision))
            XCTAssertEqual(inspected.replay(), FallingSky(definition: definition))
            XCTAssertEqual(inspected.replay().challengeRevision, archive.game.challengeRevision)
            XCTAssertEqual(defaults.data(forKey: archive.key), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key), "Retained loading remains read-only")
            XCTAssertThrowsError(try SkySaveArchive.decode(bytes), "The v16 decoder does not admit a historical envelope")

            try SkySaveArchive.save(inspected, to: defaults)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), archive.game)
            XCTAssertEqual(defaults.data(forKey: archive.key), bytes, "Writing the canonical save keeps original bytes")
        }
    }

    @MainActor func testRevisionSevenCannotEnterV15OrEarlierAndV15RequiresItsOwnSchema() throws {
        let ribbon = FallingSky.fullBoardRibbon()
        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        let lower = try envelope(retained, version: 14)
        for (key, version) in [(SkySaveArchive.revisedFullBoardKey, 15),
                               (SkySaveArchive.fullBoardKey, 14),
                               (SkySaveArchive.fourLineKey, 13)] {
            let defaults = defaults(), bytes = try envelope(ribbon, version: version)
            defaults.set(try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false)), forKey: SkySaveArchive.legacyKey)
            if key == SkySaveArchive.revisedFullBoardKey { defaults.set(lower, forKey: SkySaveArchive.fullBoardKey) }
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Revision 7 must be rejected at \(key)")
            }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
        for version in [14, 16] {
            let defaults = defaults(), bytes = try envelope(FallingSky.fullBoardLantern(), version: version)
            defaults.set(lower, forKey: SkySaveArchive.fullBoardKey)
            defaults.set(bytes, forKey: SkySaveArchive.revisedFullBoardKey)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("A v15 key cannot accept schema \(version)")
            }
            XCTAssertEqual(source, SkySaveArchive.revisedFullBoardKey)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.revisedFullBoardKey), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), lower)
        }
    }

    @MainActor func testInvalidV16AndV15PresenceBlocksFallbackAndRetainsRejectedPropertyListValues() throws {
        let v15 = try envelope(FallingSky.fullBoardLantern(), version: 15)
        let v14 = try envelope(FallingSky.freshChallenge(.firstLight), version: 14)
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        for source in [SkySaveArchive.key, SkySaveArchive.revisedFullBoardKey] {
            for rejected: Any in [Data("broken archive".utf8), true] {
                let defaults = defaults()
                defaults.set(v15, forKey: SkySaveArchive.revisedFullBoardKey)
                defaults.set(v14, forKey: SkySaveArchive.fullBoardKey)
                defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
                defaults.set(rejected, forKey: source)
                XCTAssertNil(SkySaveArchive.load(from: defaults))
                guard case .rejected(let actualSource) = SkySaveArchive.inspect(from: defaults) else {
                    return XCTFail("Invalid higher presence must block older history")
                }
                XCTAssertEqual(actualSource, source)
                XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                let world = WorldJourneyStore(defaults: defaults)
                XCTAssertFalse(world.journey.legacyAccess)
                XCTAssertTrue(world.journey.completed.isEmpty)
                XCTAssertFalse(world.journey.canEnter(.ribbonCrossing))
                XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))

                let replacement = FallingSky.fullBoardRibbon()
                try SkySaveArchive.save(replacement, to: defaults)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), replacement)
                let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
                XCTAssertEqual(recovery["sourceKey"] as? String, source)
                XCTAssertEqual(recovery["value"] as? NSObject, rejected as? NSObject)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), v14)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
                if source == SkySaveArchive.key {
                    XCTAssertEqual(defaults.data(forKey: SkySaveArchive.revisedFullBoardKey), v15)
                } else {
                    XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                }
            }
        }
    }

    @MainActor func testAdvancingTheArchiveKeyDoesNotGiveCurrentOrRetainedRoundsPreWorldAccess() throws {
        let ribbon = FallingSky.fullBoardRibbon()
        var archives = try retainedArchives().map { ($0.key, try envelope($0.game, version: $0.version)) }
        archives.append((SkySaveArchive.key, try SkySaveArchive.encode(ribbon)))
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        for (key, bytes) in archives {
            let defaults = defaults()
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            let world = WorldJourneyStore(defaults: defaults)
            XCTAssertFalse(world.journey.legacyAccess)
            XCTAssertTrue(world.journey.completed.isEmpty)
            XCTAssertTrue(world.journey.canEnter(.firstLight))
            XCTAssertFalse(world.journey.canEnter(.ribbonCrossing))
            XCTAssertFalse(world.journey.canEnter(.kiteHarbor))
            XCTAssertFalse(world.journey.canEnter(.silverPools))
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
            XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
            if key != SkySaveArchive.key { XCTAssertNil(defaults.object(forKey: SkySaveArchive.key)) }
            try world.record(ribbon)
            XCTAssertTrue(world.journey.completed.isEmpty, "An unfinished Ribbon round earns no repair")
            XCTAssertFalse(WorldJourneyStore(defaults: defaults).journey.canEnter(.kiteHarbor))
        }
    }

    @MainActor func testOnlyAnActualRibbonWinEarnsItsRepairAndRepairsAnInterruptedWorldWrite() throws {
        let defaults = defaults(), world = WorldJourneyStore(defaults: defaults)
        var game = FallingSky.fullBoardRibbon()
        let route = [(8, 9), (11, 12), (31, 38), (17, 24), (9, 16), (9, 10),
                     (1, 8), (1, 2), (1, 8), (9, 10), (10, 11), (22, 29),
                     (2, 3), (2, 9), (1, 8), (37, 38), (2, 3), (16, 17)]
        let scores = [30, 35, 40, 45, 50, 65, 80, 80, 85, 85, 90, 179, 179, 184, 199, 214, 214, 229]
        for (index, move) in route.enumerated() {
            _ = try XCTUnwrap(game.nudge(from: Cell(move.0 / 7, move.0 % 7),
                                       to: Cell(move.1 / 7, move.1 % 7)))
            XCTAssertEqual(game.displayScore, scores[index] * 1_000)
            try SkySaveArchive.save(game, to: defaults)
            try world.record(game)
            if index < route.count - 1 {
                XCTAssertNotEqual(game.outcome, .won)
                XCTAssertTrue(world.journey.completed.isEmpty)
                XCTAssertFalse(world.journey.canEnter(.kiteHarbor))
            }
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(world.journey.completed, [.ribbonCrossing])
        XCTAssertEqual(world.journey.selected, .kiteHarbor)
        XCTAssertTrue(world.journey.canEnter(.kiteHarbor))
        XCTAssertFalse(world.journey.canEnter(.seedMoon))
        XCTAssertFalse(world.journey.legacyAccess)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))) as? [String: Any])
        XCTAssertEqual(fields["version"] as? Int, 1)

        defaults.removeObject(forKey: WorldJourneyStore.key)
        let repaired = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(repaired.journey.completed, [.ribbonCrossing])
        XCTAssertTrue(repaired.journey.canEnter(.kiteHarbor))
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key), "Interrupted-write recovery is read-only until a commit")
        try repaired.record(game)
        try repaired.record(game)
        XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.completed, [.ribbonCrossing])
        XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
    }
}
