import XCTest
import StarfallCore
@testable import Starfall

final class SunwheelEncounterCompatibilityTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.SunwheelEncounterCompatibility.\(UUID())"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }

    private func envelope(_ game: FallingSky, version: Int) throws -> Data {
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": fields], options: .sortedKeys)
    }

    private func retainedGames() throws -> [FallingSky] {
        var frostfruit = FallingSky.freshChallenge(.frostfruitOrchard)
        _ = try XCTUnwrap(frostfruit.nudge(from: Cell(5, 0), to: Cell(5, 1)))
        _ = try XCTUnwrap(frostfruit.letStarsFall())
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
        return [frostfruit, ribbon, five, six, lanternSky, ribbonSky]
    }

    @MainActor func testV18SunwheelRestoresExactShowerAndWinningContinuationBeforeSameRoundReplay() throws {
        let opening = FallingSky.freshChallenge(.sunwheelMill)
        XCTAssertEqual(opening.gem(at: Cell(0, 0))?.id, 0)
        XCTAssertEqual(opening.gem(at: Cell(0, 0))?.grown, true)
        var game = opening
        let first = try XCTUnwrap(game.nudge(from: Cell(1, 2), to: Cell(1, 3)))
        XCTAssertEqual(first.displayAward, 21_000)
        XCTAssertEqual(first.resolutionPhases.count, 2)
        XCTAssertFalse(game.board.compactMap { $0 }.contains { $0.id == 0 })
        XCTAssertEqual(game.challengeRevision, 9)
        XCTAssertEqual(game.displayTarget, 24_000)
        XCTAssertFalse(game.usesFullBoardRefill)
        let bytes = try SkySaveArchive.encode(game)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(SkySaveArchive.key, "starfall.accumulation.v19")
        XCTAssertEqual(fields["schemaVersion"] as? Int, 19)
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
        let shower = try XCTUnwrap(expected.letStarsFall())
        XCTAssertEqual(shower.arrivals.count, 5)
        XCTAssertNil(shower.blockedColumn)
        store.callShower()
        XCTAssertEqual(store.game, expected, "Restored continuation keeps the exact forecast, identities and random state")
        XCTAssertEqual(store.pending?.forecast, shower.forecast)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
        presenter.finish()
        let finish = try XCTUnwrap(expected.nudge(from: Cell(0, 0), to: Cell(1, 0)))
        XCTAssertEqual(finish.displayAward, 5_000)
        XCTAssertEqual(expected.displayScore, 26_000)
        XCTAssertEqual(expected.outcome, .won)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0, 0), Cell(1, 0)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
        XCTAssertEqual(store.journey.journey.completed, [.sunwheelMill])
        presenter.finish()

        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        defer { restored.setSuspended(true) }
        XCTAssertEqual(restored.game, expected)
        restored.setSuspended(false)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(restored.game.occupiedCount, 26)
        XCTAssertEqual(restored.game.displayScore, 0)
        XCTAssertEqual(restored.game.board.compactMap { $0 }.filter(\.grown).map(\.id), [0])
        XCTAssertEqual(restored.journey.journey.completed, [.sunwheelMill])
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
    }

    @MainActor func testHistoricalSunwheelKeepsManualEighteenContinueAndReplayUntilAnExplicitNewVisit() throws {
        let opening = FallingSky(challenge: .sunwheelMill)
        var retained = opening
        _ = try XCTUnwrap(retained.letStarsFall())
        let bytes = try envelope(retained, version: 17), defaults = defaults()
        defaults.set(bytes, forKey: SkySaveArchive.frostfruitEncounterKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        defer { store.setSuspended(true) }
        XCTAssertEqual(store.game, retained)
        XCTAssertEqual(store.game.challengeRevision, 0)
        XCTAssertTrue(store.game.supportsManualClears)
        XCTAssertEqual(store.game.displayTarget, 18)
        XCTAssertEqual(store.game.replay(), opening)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), bytes)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        store.setSuspended(false)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
        store.beginEntry(.sunwheelMill)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.sunwheelMill))
        XCTAssertEqual(store.game.challengeRevision, 9)
        XCTAssertFalse(store.game.supportsManualClears)
        XCTAssertEqual(store.game.displayTarget, 24_000)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), bytes)
    }

    @MainActor func testV17RetainsFrostfruitAndBothLanternRibbonModesWithoutUpgradingOrWriting() throws {
        for game in try retainedGames() {
            let bytes = try envelope(game, version: 17), defaults = defaults()
            defaults.set(bytes, forKey: SkySaveArchive.frostfruitEncounterKey)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
            guard case .loaded(let inspected) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Expected retained revision \(game.challengeRevision)")
            }
            XCTAssertEqual(inspected, game)
            let challenge = try XCTUnwrap(game.challenge)
            let definition = try XCTUnwrap(StoryChallengeDefinition(challenge, revision: game.challengeRevision))
            XCTAssertEqual(inspected.replay(), FallingSky(definition: definition))
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key), "Retained loading is read-only")
            XCTAssertThrowsError(try SkySaveArchive.decode(bytes))
            try SkySaveArchive.save(inspected, to: defaults)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), game)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), bytes)
        }
    }

    @MainActor func testSunwheelNineCannotEnterEarlierEnvelopesAndEveryRetainedBoundaryStaysBounded() throws {
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        let sunwheel = FallingSky.freshChallenge(.sunwheelMill)
        let rejected = [
            (sunwheel, SkySaveArchive.frostfruitEncounterKey, 17),
            (sunwheel, SkySaveArchive.ribbonFullBoardKey, 16),
            (sunwheel, SkySaveArchive.revisedFullBoardKey, 15),
            (FallingSky.freshChallenge(.frostfruitOrchard), SkySaveArchive.ribbonFullBoardKey, 16),
            (FallingSky.fullBoardRibbon(), SkySaveArchive.revisedFullBoardKey, 15),
            (FallingSky.fullBoardLantern(), SkySaveArchive.fullBoardKey, 14)
        ]
        for (game, key, version) in rejected {
            let defaults = defaults(), bytes = try envelope(game, version: version)
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Revision \(game.challengeRevision) must be rejected at \(key)")
            }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
        for version in [16, 18] {
            let defaults = defaults(), bytes = try envelope(FallingSky.freshChallenge(.frostfruitOrchard), version: version)
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: SkySaveArchive.frostfruitEncounterKey)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("A v17 key cannot accept schema \(version)")
            }
            XCTAssertEqual(source, SkySaveArchive.frostfruitEncounterKey)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), bytes)
        }
    }

    @MainActor func testForeignRevisionNineIsRejectedBeforeSaveCanChangeTheArchiveOrRecoverySlot() throws {
        let sunwheel = FallingSky.freshChallenge(.sunwheelMill)
        for challenge in StarfallChallenge.allCases where challenge != .sunwheelMill {
            XCTAssertNil(StoryChallengeDefinition(challenge, revision: 9))
            var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(sunwheel)) as? [String: Any])
            fields["challenge"] = challenge.rawValue
            let foreign = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
            XCTAssertFalse(foreign.isValidSave)
            XCTAssertThrowsError(try SkySaveArchive.encode(foreign))
            let bytes = try envelope(foreign, version: 18), defaults = defaults()
            let oldRecovery = ["sourceKey": "older rejected value", "value": true] as [String: Any]
            defaults.set(oldRecovery, forKey: SkySaveArchive.rejectedKey)
            defaults.set(try envelope(FallingSky.freshChallenge(.frostfruitOrchard), version: 17), forKey: SkySaveArchive.frostfruitEncounterKey)
            defaults.set(bytes, forKey: SkySaveArchive.key)
            XCTAssertThrowsError(try SkySaveArchive.decode(bytes))
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else {
                return XCTFail("Foreign revision 9 must block fallback")
            }
            XCTAssertEqual(source, SkySaveArchive.key)
            XCTAssertThrowsError(try SkySaveArchive.save(foreign, to: defaults))
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
            let retainedRecovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
            XCTAssertEqual(retainedRecovery as NSDictionary, oldRecovery as NSDictionary)
        }
    }

    @MainActor func testInvalidV18AndV17PresenceBlocksFallbackAndPreservesRejectedValues() throws {
        let v17 = try envelope(FallingSky.freshChallenge(.frostfruitOrchard), version: 17)
        let v16 = try envelope(FallingSky.fullBoardRibbon(), version: 16)
        for source in [SkySaveArchive.key, SkySaveArchive.frostfruitEncounterKey] {
            for rejected: Any in [Data("broken archive".utf8), true] {
                let defaults = defaults()
                defaults.set(v17, forKey: SkySaveArchive.frostfruitEncounterKey)
                defaults.set(v16, forKey: SkySaveArchive.ribbonFullBoardKey)
                defaults.set(rejected, forKey: source)
                XCTAssertNil(SkySaveArchive.load(from: defaults))
                guard case .rejected(let actualSource) = SkySaveArchive.inspect(from: defaults) else {
                    return XCTFail("Invalid higher presence must block older history")
                }
                XCTAssertEqual(actualSource, source)
                XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                let world = WorldJourneyStore(defaults: defaults)
                XCTAssertTrue(world.journey.completed.isEmpty)
                XCTAssertFalse(world.journey.canEnter(.sunwheelMill))
                XCTAssertFalse(world.journey.canEnter(.bellChoir))
                let replacement = FallingSky.freshChallenge(.sunwheelMill)
                try SkySaveArchive.save(replacement, to: defaults)
                let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
                XCTAssertEqual(recovery["sourceKey"] as? String, source)
                XCTAssertEqual(recovery["value"] as? NSObject, rejected as? NSObject)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), replacement)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.ribbonFullBoardKey), v16)
                if source == SkySaveArchive.key {
                    XCTAssertEqual(defaults.data(forKey: SkySaveArchive.frostfruitEncounterKey), v17)
                } else {
                    XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                }
            }
        }
    }

    @MainActor func testV18AndV17RoundsDoNotAcquireCompletionOrPreWorldAccess() throws {
        let sunwheel = FallingSky.freshChallenge(.sunwheelMill)
        var archives = try retainedGames().map { (SkySaveArchive.frostfruitEncounterKey, try envelope($0, version: 17)) }
        archives.append((SkySaveArchive.key, try SkySaveArchive.encode(sunwheel)))
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        for (key, bytes) in archives {
            let defaults = defaults()
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            let world = WorldJourneyStore(defaults: defaults)
            XCTAssertFalse(world.journey.legacyAccess)
            XCTAssertTrue(world.journey.completed.isEmpty)
            XCTAssertFalse(world.journey.canEnter(.sunwheelMill))
            XCTAssertFalse(world.journey.canEnter(.bellChoir))
            XCTAssertFalse(world.journey.canEnter(.silverPools))
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
            XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
            if key != SkySaveArchive.key { XCTAssertNil(defaults.object(forKey: SkySaveArchive.key)) }
            try world.record(sunwheel)
            XCTAssertTrue(world.journey.completed.isEmpty, "An unfinished Sunwheel round earns no completion")
            XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.completed.isEmpty)
        }
    }

    @MainActor func testOnlyAnActualSunwheelWinRecordsCompletionAndRepairsAnInterruptedWorldWrite() throws {
        let defaults = defaults(), world = WorldJourneyStore(defaults: defaults)
        var game = FallingSky.freshChallenge(.sunwheelMill)
        let route = [[15, 14], [], [], [17, 18], [9, 10]]
        let scores = [6_000, 6_000, 6_000, 6_000, 25_000]
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
        XCTAssertEqual(world.journey.completed, [.sunwheelMill])
        XCTAssertEqual(world.journey.selected, .sunwheelMill)
        XCTAssertTrue(world.journey.canEnter(.sunwheelMill))
        XCTAssertFalse(world.journey.canEnter(.bellChoir))
        XCTAssertFalse(world.journey.legacyAccess)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(defaults.data(forKey: WorldJourneyStore.key))) as? [String: Any])
        XCTAssertEqual(fields["version"] as? Int, 1)

        defaults.removeObject(forKey: WorldJourneyStore.key)
        let repaired = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(repaired.journey.completed, [.sunwheelMill])
        XCTAssertTrue(repaired.journey.canEnter(.sunwheelMill))
        XCTAssertFalse(repaired.journey.canEnter(.bellChoir))
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key), "Interrupted-write recovery remains read-only until a commit")
        try repaired.record(game)
        try repaired.record(game)
        XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.completed, [.sunwheelMill])
        XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
    }
}
