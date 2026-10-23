import XCTest
import StarfallCore
@testable import Starfall

final class FullBoardRevisionSixCompatibilityTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FullBoardRevisionSix.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    private func revisionFive() throws -> FallingSky {
        FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
    }

    private func envelope(_ game: FallingSky, version: Int) throws -> Data {
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": fields], options: .sortedKeys)
    }

    @MainActor func testV14RevisionFiveContinuesItsExactNextMoveAndReplayUntilAnExplicitNewVisit() throws {
        let defaults = defaults(), opening = try revisionFive()
        var retained = opening
        _ = try XCTUnwrap(retained.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual(retained.displayScore, 66_000)
        let bytes = try envelope(retained, version: 14)
        defaults.set(bytes, forKey: SkySaveArchive.fullBoardKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        XCTAssertEqual(store.game, retained)
        XCTAssertTrue(store.hasSavedSky)
        XCTAssertFalse(store.openingPending)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key), "Reading v14 must not write v15")
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), bytes)
        store.setSuspended(false)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), retained)
        XCTAssertNil(clock.deadline)

        var expected = retained
        let reference = try XCTUnwrap(expected.nudge(from: Cell(0, 3), to: Cell(1, 3)))
        XCTAssertEqual(reference.displayAward, 15_000)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0, 3), Cell(1, 3)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), expected)
        presenter.finish()
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(store.game.challengeRevision, 5)
        XCTAssertEqual(SkyEntryRequest.replay.previewGame(retaining: retained), opening)
        XCTAssertEqual(SkyEntryRequest.fullBoardLantern.previewGame(retaining: retained), FallingSky.fullBoardLantern())
        XCTAssertEqual(store.game, opening, "Previewing a new visit cannot upgrade the retained round")
        store.beginEntry(.fullBoardLantern)
        XCTAssertEqual(store.game, try enrolledMasteryOpening(.fullBoardLantern(), matching: store.game))
        XCTAssertEqual(store.game.challengeRevision, 6)
        store.beginEntry(.firstLight)
        XCTAssertEqual(store.game, try enrolledMasteryOpening(.freshChallenge(.firstLight), matching: store.game))
        XCTAssertEqual(store.game.challengeRevision, 4)
        XCTAssertFalse(store.game.usesFullBoardRefill)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), bytes)
        store.setSuspended(true)
    }

    @MainActor func testV15CurrentSixRoundTripsAndReplaysWithoutChangingOrdinaryFallingSky() throws {
        let opening = FallingSky.fullBoardLantern()
        XCTAssertEqual(opening.challengeRevision, 6)
        XCTAssertTrue(opening.usesFullBoardRefill)
        XCTAssertEqual(opening.occupiedCount, 49)
        XCTAssertEqual(opening.displayTarget, 150_000)
        var game = opening
        let turn = try XCTUnwrap(game.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertGreaterThan(turn.displayAward, 0)
        XCTAssertTrue(game.isValidSave)
        let bytes = try SkySaveArchive.encode(game)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(fields["schemaVersion"] as? Int, 19)
        XCTAssertEqual(try SkySaveArchive.decode(bytes), game)
        XCTAssertEqual(try SkySaveArchive.encode(SkySaveArchive.decode(bytes)), bytes)
        let defaults = defaults()
        defaults.set(bytes, forKey: SkySaveArchive.key)
        let clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: clock)
        XCTAssertEqual(store.game, game)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        store.setSuspended(false)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertNil(clock.deadline)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), opening)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(FallingSky.freshChallenge(.firstLight).challengeRevision, 4)
        XCTAssertFalse(FallingSky.freshChallenge(.firstLight).usesFullBoardRefill)
        store.setSuspended(true)
    }

    @MainActor func testV14ReaderRejectsRevisionSixAndWrongSchemaWhileV13StillRejectsFive() throws {
        let current = FallingSky.fullBoardLantern(), historical = try revisionFive()
        for (key, bytes) in [
            (SkySaveArchive.fullBoardKey, try envelope(current, version: 14)),
            (SkySaveArchive.fullBoardKey, try envelope(historical, version: 15)),
            (SkySaveArchive.fourLineKey, try envelope(historical, version: 13))
        ] {
            let defaults = defaults()
            defaults.set(try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false)), forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail(key) }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
        for game in [FallingSky.freshChallenge(.firstLight), historical] {
            let defaults = defaults(), bytes = try envelope(game, version: 14)
            defaults.set(bytes, forKey: SkySaveArchive.fullBoardKey)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), bytes)
        }
    }

    @MainActor func testInvalidHigherArchivesBlockFallbackAndPreserveTheirRejectedValues() throws {
        let historical = try revisionFive()
        let v14 = try envelope(historical, version: 14)
        let v13 = try envelope(FallingSky.freshChallenge(.firstLight), version: 13)
        for source in [SkySaveArchive.key, SkySaveArchive.fullBoardKey] {
            for rejected: Any in [Data("broken archive".utf8), true] {
                let defaults = defaults()
                defaults.set(v14, forKey: SkySaveArchive.fullBoardKey)
                defaults.set(v13, forKey: SkySaveArchive.fourLineKey)
                defaults.set(rejected, forKey: source)
                XCTAssertNil(SkySaveArchive.load(from: defaults))
                guard case .rejected(let actualSource) = SkySaveArchive.inspect(from: defaults) else {
                    return XCTFail("The present invalid archive must block older history")
                }
                XCTAssertEqual(actualSource, source)
                XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                try SkySaveArchive.save(FallingSky.fullBoardLantern(), to: defaults)
                let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
                XCTAssertEqual(recovery["sourceKey"] as? String, source)
                XCTAssertEqual(recovery["value"] as? NSObject, rejected as? NSObject)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fourLineKey), v13)
                if source == SkySaveArchive.key {
                    XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fullBoardKey), v14)
                } else {
                    XCTAssertEqual(defaults.object(forKey: source) as? NSObject, rejected as? NSObject)
                }
                XCTAssertEqual(SkySaveArchive.load(from: defaults), FallingSky.fullBoardLantern())
            }
        }
    }

    @MainActor func testV14AndV15RoundsDoNotAcquirePreWorldAccessWhenTheCurrentKeyAdvances() throws {
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        let v14Games = [FallingSky.freshChallenge(.firstLight), try revisionFive()]
        var archives = try v14Games.map { (SkySaveArchive.fullBoardKey, try envelope($0, version: 14)) }
        archives.append((SkySaveArchive.key, try SkySaveArchive.encode(FallingSky.fullBoardLantern())))
        for (key, bytes) in archives {
            let defaults = defaults()
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            let world = WorldJourneyStore(defaults: defaults)
            XCTAssertFalse(world.journey.legacyAccess)
            XCTAssertTrue(world.journey.completed.isEmpty)
            XCTAssertTrue(world.journey.canEnter(.firstLight))
            XCTAssertFalse(world.journey.canEnter(.ribbonCrossing))
            XCTAssertFalse(world.journey.canEnter(.silverPools))
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
            XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
            if key != SkySaveArchive.key { XCTAssertNil(defaults.object(forKey: SkySaveArchive.key)) }
        }
    }

    @MainActor func testReplayCopyFollowsBothRetainedFullBoardDefinitionsAndKeepsSkyCopySeparate() throws {
        for revision in [5, 6] {
            let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision))
            XCTAssertTrue(definition.usesFullBoardRefill)
            let line = SkyEntryRequest.replay.introduction(challenge: .firstLight,
                replayingRevision: revision, replayingTarget: 150_000)
            XCTAssertTrue(line.text.contains("Full Board"))
            XCTAssertTrue(line.text.contains("saved round stays"))
            XCTAssertTrue(line.text.contains("150,000"))
        }
        let sky = SkyEntryRequest.replay.introduction(challenge: .firstLight,
            replayingRevision: 4, replayingTarget: 150_000)
        XCTAssertFalse(sky.text.contains("Full Board"))
        XCTAssertEqual(FallingSky.freshChallenge(.firstLight).challengeRevision, 4)
    }
}
