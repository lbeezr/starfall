import XCTest
import StarfallCore
@testable import Starfall

final class FrostfruitEncounterCompatibilityTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FrostfruitEncounterCompatibility.\(UUID())"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }

    private func envelope(_ game: FallingSky, version: Int) throws -> Data {
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": fields], options: .sortedKeys)
    }

    private func retainedGames() throws -> [FallingSky] {
        var ribbon = FallingSky.fullBoardRibbon()
        var five = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        var six = FallingSky.fullBoardLantern()
        _ = try XCTUnwrap(ribbon.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        _ = try XCTUnwrap(five.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        _ = try XCTUnwrap(six.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        var lanternSky = FallingSky.freshChallenge(.firstLight)
        var ribbonSky = FallingSky.freshChallenge(.ribbonCrossing)
        _ = try XCTUnwrap(lanternSky.letStarsFall())
        _ = try XCTUnwrap(ribbonSky.letStarsFall())
        return [ribbon, five, six, lanternSky, ribbonSky]
    }

    @MainActor func testV17FrostfruitRestoresGrownCapsAndExactContinuationBeforeSameRoundReplay() throws {
        let opening = FallingSky.freshChallenge(.frostfruitOrchard)
        var game = opening
        _ = try XCTUnwrap(game.nudge(from: Cell(5, 0), to: Cell(5, 1)))
        _ = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(game.challengeRevision, 8)
        XCTAssertEqual(game.displayTarget, 15_000)
        XCTAssertFalse(game.usesFullBoardRefill)
        XCTAssertEqual(game.gem(at: Cell(5, 0))?.id, 29)
        XCTAssertEqual(game.gem(at: Cell(5, 1))?.id, 28)
        XCTAssertEqual(game.gem(at: Cell(5, 0))?.grown, true)
        XCTAssertEqual(game.gem(at: Cell(5, 1))?.grown, true)
        let bytes = try SkySaveArchive.encode(game)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(SkySaveArchive.key, "starfall.accumulation.v18")
        XCTAssertEqual(fields["schemaVersion"] as? Int, 18)
        XCTAssertEqual(try SkySaveArchive.decode(bytes), game)
        XCTAssertEqual(try SkySaveArchive.encode(SkySaveArchive.decode(bytes)), bytes)

        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        defaults.set(bytes, forKey: SkySaveArchive.key)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        defer { store.setSuspended(true) }
        XCTAssertEqual(store.game, game)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes, "Restore construction is read-only")
        XCTAssertFalse(store.openingPending)
        store.setSuspended(false)
        XCTAssertTrue(store.isPaused)
        XCTAssertNil(clock.deadline)
        var expected = game
        let next = try XCTUnwrap(expected.nudge(from: Cell(2, 6), to: Cell(2, 5)))
        XCTAssertEqual(next.displayAward, 5_000)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(2, 6), Cell(2, 5)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected, "The restored move retains the same grown stars, forecast and randomness")
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
        presenter.finish()

        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        defer { restored.setSuspended(true) }
        XCTAssertEqual(restored.game, expected)
        restored.setSuspended(false)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(restored.game.occupiedCount, 30)
        XCTAssertEqual(restored.game.displayScore, 0)
        XCTAssertTrue(restored.game.board.compactMap { $0 }.allSatisfy { !$0.grown })
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
    }

    @MainActor func testHistoricalFrostfruitKeepsManualEighteenContinueAndReplayUntilAnExplicitNewVisit() throws {
        let opening = FallingSky(challenge: .frostfruitOrchard)
        var retained = opening
        _ = try XCTUnwrap(retained.letStarsFall())
        let bytes = try envelope(retained, version: 16), defaults = defaults()
        defaults.set(bytes, forKey: SkySaveArchive.ribbonFullBoardKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        defer { store.setSuspended(true) }
        XCTAssertEqual(store.game, retained)
        XCTAssertEqual(store.game.challengeRevision, 0)
        XCTAssertTrue(store.game.supportsManualClears)
        XCTAssertEqual(store.game.displayTarget, 18)
        XCTAssertEqual(store.game.replay(), opening)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), bytes)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        store.setSuspended(false)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
        store.beginEntry(.frostfruitOrchard)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.frostfruitOrchard))
        XCTAssertEqual(store.game.challengeRevision, 8)
        XCTAssertFalse(store.game.supportsManualClears)
        XCTAssertEqual(store.game.displayTarget, 15_000)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), bytes)
    }

    @MainActor func testV16RetainsRibbonLanternAndSkyDefinitionsAndOriginalBytes() throws {
        for game in try retainedGames() {
            let bytes = try envelope(game, version: 16), defaults = defaults()
            defaults.set(bytes, forKey: SkySaveArchive.ribbonFullBoardKey)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
            guard case .loaded(let inspected) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Expected retained revision \(game.challengeRevision)")
            }
            XCTAssertEqual(inspected, game)
            let challenge = try XCTUnwrap(game.challenge)
            let definition = try XCTUnwrap(StoryChallengeDefinition(challenge, revision: game.challengeRevision))
            XCTAssertEqual(inspected.replay(), FallingSky(definition: definition))
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key), "Retained loading is read-only")
            XCTAssertThrowsError(try SkySaveArchive.decode(bytes))
            try SkySaveArchive.save(inspected, to: defaults)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), game)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), bytes)
        }
    }

    @MainActor func testFrostfruitEightCannotEnterOlderEnvelopesAndV16RequiresItsOwnSchema() throws {
        let frostfruit = FallingSky.freshChallenge(.frostfruitOrchard)
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        for (key, version) in [(SkySaveArchive.ribbonFullBoardKey, 16),
                               (SkySaveArchive.revisedFullBoardKey, 15),
                               (SkySaveArchive.fullBoardKey, 14),
                               (SkySaveArchive.fourLineKey, 13)] {
            let defaults = defaults(), bytes = try envelope(frostfruit, version: version)
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Revision 8 must be rejected at \(key)")
            }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
        for version in [15, 17] {
            let defaults = defaults(), bytes = try envelope(FallingSky.fullBoardRibbon(), version: version)
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: SkySaveArchive.ribbonFullBoardKey)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("A v16 key cannot accept schema \(version)")
            }
            XCTAssertEqual(source, SkySaveArchive.ribbonFullBoardKey)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), bytes)
        }
    }

    @MainActor func testRevisionEightCannotBeForgedForAnyOtherLocation() throws {
        let frostfruit = FallingSky.freshChallenge(.frostfruitOrchard)
        for challenge in StarfallChallenge.allCases where challenge != .frostfruitOrchard {
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 8))
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(frostfruit)) as? [String: Any])
            fields["challenge"] = challenge.rawValue
            let foreign = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(foreign.isValidSave)
            XCTAssertThrowsError(try SkySaveArchive.encode(foreign))
            let bytes = try envelope(foreign, version: 17), defaults = defaults()
            defaults.set(try envelope(FallingSky.fullBoardRibbon(), version: 16), forKey: SkySaveArchive.ribbonFullBoardKey)
            defaults.set(bytes, forKey: SkySaveArchive.key)
            XCTAssertThrowsError(try SkySaveArchive.decode(bytes))
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Foreign revision 8 must block fallback")
            }
            XCTAssertEqual(source, SkySaveArchive.key)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        }
    }

    @MainActor func testInvalidV17AndV16PresenceBlocksFallbackAndPreservesRejectedValues() throws {
        let v16 = try envelope(FallingSky.fullBoardRibbon(), version: 16)
        let v15 = try envelope(FallingSky.fullBoardLantern(), version: 15)
        for source in [SkySaveArchive.key, SkySaveArchive.ribbonFullBoardKey] {
            for rejected: Any in [Data("broken archive".utf8), true] {
                let defaults = defaults()
                defaults.set(v16, forKey: SkySaveArchive.ribbonFullBoardKey)
                defaults.set(v15, forKey: SkySaveArchive.revisedFullBoardKey)
                defaults.set(rejected, forKey: source)
                XCTAssertNil(SkySaveArchive.load(from: defaults))
                guard case .rejected(let actualSource) = SkySaveArchive.inspect(from: defaults) else {
                    return XCTFail("Invalid higher presence must block older history")
                }
                XCTAssertEqual(actualSource, source)
                XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                let world = WorldJourneyStore(defaults: defaults)
                XCTAssertTrue(world.journey.completed.isEmpty)
                XCTAssertFalse(world.journey.canEnter(.frostfruitOrchard))
                XCTAssertFalse(world.journey.canEnter(.sunwheelMill))
                let replacement = FallingSky.freshChallenge(.frostfruitOrchard)
                try SkySaveArchive.save(replacement, to: defaults)
                let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
                XCTAssertEqual(recovery["sourceKey"] as? String, source)
                XCTAssertEqual(recovery["value"] as? NSObject, rejected as? NSObject)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), replacement)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.revisedFullBoardKey), v15)
                if source == SkySaveArchive.key {
                    XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), v16)
                } else {
                    XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                }
            }
        }
    }

    @MainActor func testNewAndRetainedArchivesDoNotInventFrostfruitSunwheelOrPreWorldAccess() throws {
        let frostfruit = FallingSky.freshChallenge(.frostfruitOrchard)
        var archives = try retainedGames().map { (SkySaveArchive.ribbonFullBoardKey, try envelope($0, version: 16)) }
        archives.append((SkySaveArchive.key, try SkySaveArchive.encode(frostfruit)))
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        for (key, bytes) in archives {
            let defaults = defaults()
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            let world = WorldJourneyStore(defaults: defaults)
            XCTAssertFalse(world.journey.legacyAccess)
            XCTAssertTrue(world.journey.completed.isEmpty)
            XCTAssertFalse(world.journey.canEnter(.frostfruitOrchard))
            XCTAssertFalse(world.journey.canEnter(.sunwheelMill))
            XCTAssertFalse(world.journey.canEnter(.silverPools))
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
            XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
            if key != SkySaveArchive.key { XCTAssertNil(defaults.object(forKey: SkySaveArchive.key)) }
            try world.record(frostfruit)
            XCTAssertTrue(world.journey.completed.isEmpty, "An unfinished Frostfruit round earns no repair")
            XCTAssertFalse(WorldJourneyStore(defaults: defaults).journey.canEnter(.sunwheelMill))
        }
    }

    @MainActor func testOnlyAnActualFrostfruitWinUnlocksSunwheelAndRepairsAnInterruptedWorldWrite() throws {
        let defaults = defaults(), world = WorldJourneyStore(defaults: defaults)
        var game = FallingSky.freshChallenge(.frostfruitOrchard)
        let route = [[35, 36], [], [], [20, 19], [2, 9], [3, 10]]
        let scores = [0, 0, 0, 6_000, 13_000, 18_000]
        for (index, move) in route.enumerated() {
            if move.isEmpty {
                _ = try XCTUnwrap(game.letStarsFall())
            } else {
                _ = try XCTUnwrap(game.nudge(from: Cell(move[0] / 7, move[0] % 7),
                                           to: Cell(move[1] / 7, move[1] % 7)))
            }
            XCTAssertEqual(game.displayScore, scores[index])
            try SkySaveArchive.save(game, to: defaults)
            try world.record(game)
            if index < route.count - 1 {
                XCTAssertNotEqual(game.outcome, .won)
                XCTAssertTrue(world.journey.completed.isEmpty)
                XCTAssertFalse(world.journey.canEnter(.sunwheelMill))
            }
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(world.journey.completed, [.frostfruitOrchard])
        XCTAssertEqual(world.journey.selected, .sunwheelMill)
        XCTAssertTrue(world.journey.canEnter(.sunwheelMill))
        XCTAssertFalse(world.journey.canEnter(.bellChoir))
        XCTAssertFalse(world.journey.legacyAccess)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))) as? [String: Any])
        XCTAssertEqual(fields["version"] as? Int, 1)

        defaults.removeObject(forKey: WorldJourneyStore.key)
        let repaired = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(repaired.journey.completed, [.frostfruitOrchard])
        XCTAssertTrue(repaired.journey.canEnter(.sunwheelMill))
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key), "Interrupted-write recovery remains read-only until a commit")
        try repaired.record(game)
        try repaired.record(game)
        XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.completed, [.frostfruitOrchard])
        XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
    }
}
