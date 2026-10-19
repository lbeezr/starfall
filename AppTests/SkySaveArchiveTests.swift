import XCTest
import SpriteKit
import StarfallCore
@testable import Starfall

final class SkySaveArchiveTests: XCTestCase {
    @MainActor private func makeDefaults() -> UserDefaults {
        let suite = "Starfall.SaveArchive.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        addTeardownBlock { @MainActor in defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    private func opalSky() -> FallingSky {
        var game = FallingSky(seed: 17, balance: .init(darkStars: .none), generation: .current)
        for _ in 0..<5 {
            XCTAssertNotNil(game.letStarsFall())
            for _ in 0..<49 {
                guard !game.isOver, let first = game.legalGroups.first?.first else { break }
                XCTAssertNotNil(game.clear(first))
            }
            XCTAssertTrue(game.isValidSave)
        }
        XCTAssertTrue(game.incoming.contains(where: \.isLight))
        return game
    }

    @MainActor func testLegacyMigrationWaitsForActivationAndPreservesExactSkyAndOldBytes() throws {
        let defaults = makeDefaults()
        let original = FallingSky(seed: 17, openingCascade: false)
        let legacy = try JSONEncoder().encode(original)
        defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        XCTAssertTrue(store.hasSavedSky); XCTAssertEqual(store.game, original.adoptingFeedingDusk())
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        clock.advance(100)
        XCTAssertEqual(store.game, original.adoptingFeedingDusk()); XCTAssertNil(clock.deadline)
        store.setSuspended(false)
        let current = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(current), original.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, original.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        restored.setSuspended(false)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current, "Canonical migration is idempotent")
        var reference = original.adoptingFeedingDusk()
        for _ in 0..<8 where !reference.isOver {
            reference.letStarsFall(); store.callShower(); presenter.finish()
            XCTAssertEqual(store.game, reference)
        }
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
    }

    func testCurrentEnvelopePreservesWhiteIdentityAndRejectsWrongSchemasAndInvalidCore() throws {
        let game = opalSky()
        let data = try SkySaveArchive.encode(game)
        XCTAssertEqual(try SkySaveArchive.decode(data), game)
        XCTAssertEqual(try SkySaveArchive.encode(game), data)
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONEncoder().encode(FallingSky(seed: 17))))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        fields["schemaVersion"] = 99
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONSerialization.data(withJSONObject: fields)))
        fields["schemaVersion"] = SkySaveArchive.schemaVersion
        var core = try XCTUnwrap(fields["game"] as? [String: Any])
        core["savedGeneration"] = 99; fields["game"] = core
        XCTAssertThrowsError(try SkySaveArchive.decode(JSONSerialization.data(withJSONObject: fields)))
    }

    @MainActor func testRawModernSkyCannotMasqueradeAsLegacySave() throws {
        for game in [FallingSky(seed: 17, generation: .current), opalSky()] {
            let defaults = makeDefaults(), bytes = try JSONEncoder().encode(game)
            defaults.set(bytes, forKey: SkySaveArchive.legacyKey)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            let store = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertFalse(store.hasSavedSky)
            XCTAssertEqual(store.game.seed, 5)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), bytes)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
    }

    @MainActor func testPresentInvalidCurrentSaveNeverResurrectsLegacyRound() throws {
        let defaults = makeDefaults()
        let old = try JSONEncoder().encode(FallingSky(seed: 17))
        defaults.set(old, forKey: SkySaveArchive.legacyKey)
        let current = Data("broken".utf8)
        defaults.set(current, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertFalse(store.hasSavedSky); XCTAssertEqual(store.game.seed, 5)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), old)
        defaults.set(true, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults), "Wrong-type current presence also blocks downgrade")
    }

    @MainActor func testCurrentEnvelopeTakesPrecedenceAndInitializationDoesNotWrite() throws {
        let defaults = makeDefaults(), game = opalSky()
        let current = try SkySaveArchive.encode(game)
        let legacy = try JSONEncoder().encode(FallingSky(seed: 123))
        defaults.set(current, forKey: SkySaveArchive.key)
        defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertTrue(store.hasSavedSky); XCTAssertEqual(store.game, game.adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), current)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game.generation, .current)
        XCTAssertEqual(store.game.seed, game.seed)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
    }

}

extension SkySaveArchiveTests {
    @MainActor func testV4MigrationPreservesGenerationForecastReplayAndBytes() throws {
        for generation in [SkyGeneration.legacy, .opalStorms] {
            let defaults = makeDefaults()
            var game = FallingSky(seed:19,generation:generation)
            for _ in 0..<5 { game.letStarsFall(); for group in game.legalGroups { if let cell = group.first { game.clear(cell) } } }
            let gameJSON = try JSONSerialization.jsonObject(with:JSONEncoder().encode(game))
            let bytes = try JSONSerialization.data(withJSONObject:["schemaVersion":4,"game":gameJSON])
            defaults.set(bytes,forKey:SkySaveArchive.previousKey)
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:ManualRainClock())
            XCTAssertEqual(store.game,game.adoptingFeedingDusk()); XCTAssertTrue(store.isPaused)
            XCTAssertNil(defaults.object(forKey:SkySaveArchive.key))
            store.setSuspended(false)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))),game.adoptingFeedingDusk())
            XCTAssertEqual(defaults.data(forKey:SkySaveArchive.previousKey),bytes)
            game = game.adoptingFeedingDusk(); game.letStarsFall(); store.callShower(); presenter.finish(); XCTAssertEqual(store.game,game)
            store.restart(sameSky:true); XCTAssertEqual(store.game.generation,generation)
            defaults.set(Data("broken".utf8),forKey:SkySaveArchive.key)
            XCTAssertNil(SkySaveArchive.load(from:defaults))
        }
    }
    @MainActor func testMalformedV4DoesNotFallbackAndV4CannotAdmitGravity() throws {
        let defaults = makeDefaults()
        defaults.set(try JSONEncoder().encode(FallingSky(seed:1)),forKey:SkySaveArchive.legacyKey)
        for game in [GravityFixture.opportunity.game()] {
            let json = try JSONSerialization.jsonObject(with:JSONEncoder().encode(game))
            defaults.set(try JSONSerialization.data(withJSONObject:["schemaVersion":4,"game":json]),forKey:SkySaveArchive.previousKey)
            XCTAssertNil(SkySaveArchive.load(from:defaults))
        }
        defaults.set(true,forKey:SkySaveArchive.previousKey)
        XCTAssertNil(SkySaveArchive.load(from:defaults))
    }
}


extension SkySaveArchiveTests {
    @MainActor func testRejectedArchivesSurviveActivationRestartAndSubsequentWrites() throws {
        for key in [SkySaveArchive.key, SkySaveArchive.patientFeedingKey, SkySaveArchive.legacyKey] {
            for value: Any in [Data("broken".utf8), true] {
                let defaults = makeDefaults()
                defaults.set(value, forKey: key)
                guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail("Expected rejection") }
                XCTAssertEqual(source, key)
                let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertFalse(store.hasSavedSky)
                XCTAssertEqual(store.rejectedSaveKey, key)
                XCTAssertNil(defaults.object(forKey: SkySaveArchive.rejectedKey), "Initialization remains read-only")
                store.setSuspended(false)
                let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
                XCTAssertEqual(recovery["sourceKey"] as? String, key)
                XCTAssertEqual(recovery["value"] as? NSObject, value as? NSObject)
                XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
                store.restart(sameSky: true)
                XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey) as NSDictionary?, recovery as NSDictionary)
                XCTAssertFalse(store.saveFailed)
            }
        }
    }

    @MainActor func testFailedEncodingLeavesCurrentAndRecoverySlotsUntouched() throws {
        let defaults = makeDefaults(), game = FallingSky.freshSurvival(seed: 1)
        defaults.set(Data("broken".utf8), forKey: SkySaveArchive.key)
        let original = defaults.data(forKey: SkySaveArchive.key)
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        fields["score"] = -1
        let invalid = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertThrowsError(try SkySaveArchive.save(invalid, to: defaults))
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), original)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.rejectedKey))
    }

    @MainActor func testMissingValidAndUnsupportedArchivesHaveDistinctResults() throws {
        let defaults = makeDefaults()
        guard case .missing = SkySaveArchive.inspect(from: defaults) else { return XCTFail("Expected empty slot") }
        let game = FallingSky.freshSurvival(seed: 1)
        try SkySaveArchive.save(game, to: defaults)
        guard case .loaded(let restored) = SkySaveArchive.inspect(from: defaults) else { return XCTFail("Expected saved sky") }
        XCTAssertEqual(restored, game)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.rejectedKey))
        let future = try JSONSerialization.data(withJSONObject: ["schemaVersion": 99, "game": JSONSerialization.jsonObject(with: JSONEncoder().encode(game))])
        defaults.set(future, forKey: SkySaveArchive.key)
        try SkySaveArchive.save(game, to: defaults)
        XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey)?["value"] as? Data, future)
    }
}

extension SkySaveArchiveTests {
    @MainActor func testSemanticallyInvalidCurrentSkyRejectsWithoutLegacyFallbackOrWrites() throws {
        for duplicate in [false, true] {
            let defaults = makeDefaults()
            let game = FallingSky.freshSurvival(seed: 5)
            var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: SkySaveArchive.encode(game)) as? [String: Any])
            var fields = try XCTUnwrap(envelope["game"] as? [String: Any])
            if duplicate {
                var forecast = try XCTUnwrap(fields["incoming"] as? [[String: Any]])
                forecast[1]["id"] = forecast[0]["id"]; fields["incoming"] = forecast
            } else { fields["blockedColumn"] = 6 }
            envelope["game"] = fields
            let rejected = try JSONSerialization.data(withJSONObject: envelope)
            defaults.set(rejected, forKey: SkySaveArchive.key)
            defaults.set(try JSONEncoder().encode(FallingSky(seed: 99)), forKey: SkySaveArchive.legacyKey)
            XCTAssertThrowsError(try SkySaveArchive.decode(rejected))
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertFalse(store.hasSavedSky); XCTAssertEqual(store.rejectedSaveKey, SkySaveArchive.key)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), rejected)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.rejectedKey))
            store.setSuspended(false)
            XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey)?["value"] as? Data, rejected)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        }
    }
}

extension SkySaveArchiveTests {
    @MainActor func testRejectionNoticeAcknowledgementIsReadOnlyAndDoesNotEraseBackupIntent() throws {
        let defaults = makeDefaults(), broken = Data("broken".utf8)
        defaults.set(broken, forKey: SkySaveArchive.key)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.persistenceNotice, .rejected)
        XCTAssertTrue(try XCTUnwrap(store.persistenceNotice).message.contains("No older round"))
        store.dismissPersistenceNotice()
        XCTAssertNil(store.persistenceNotice); XCTAssertFalse(store.hasSavedSky)
        XCTAssertEqual(store.rejectedSaveKey, SkySaveArchive.key)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), broken)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.rejectedKey))
        store.setSuspended(false)
        XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey)?["value"] as? Data, broken)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertNil(restored.persistenceNotice); XCTAssertTrue(restored.hasSavedSky)
    }

    @MainActor func testSaveFailureNoticeIsBoundedPreservesPreviousSaveAndRearmsOnlyAfterSuccess() throws {
        let defaults = makeDefaults(), original = FallingSky.freshSurvival(seed: 28)
        try SkySaveArchive.save(original, to: defaults)
        let bytes = defaults.data(forKey: SkySaveArchive.key)
        var shouldFail = true
        let clock = ManualRainClock(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
            archiveWriter: { game, defaults in
                if shouldFail { throw SkySaveArchive.Failure.unsupportedOrInvalid }
                try SkySaveArchive.save(game, to: defaults)
            })
        XCTAssertNil(store.persistenceNotice)
        store.setSuspended(false)
        XCTAssertEqual(store.persistenceNotice, .failed); XCTAssertTrue(store.saveFailed)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        // Match the view's modal interruption, then reject stale clock/presentation work.
        store.togglePause()
        let staleRain = try XCTUnwrap(clock.action)
        store.callShower()
        XCTAssertFalse(presenter.completions.isEmpty)
        store.setSuspended(true)
        let committed = store.game
        clock.advance(100); staleRain(); presenter.finish()
        XCTAssertEqual(store.game, committed); XCTAssertNil(clock.deadline)
        store.dismissPersistenceNotice(); store.setSuspended(false)
        XCTAssertNil(store.persistenceNotice, "An ongoing failure cannot trap acknowledgement in a retry loop")
        XCTAssertTrue(store.saveFailed)
        shouldFail = false; store.setSuspended(true); store.setSuspended(false)
        XCTAssertFalse(store.saveFailed); XCTAssertNil(store.persistenceNotice)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        shouldFail = true; store.setSuspended(true); store.setSuspended(false)
        XCTAssertEqual(store.persistenceNotice, .failed, "A new failure after success gets a new acknowledgement")
    }
}


extension SkySaveArchiveTests {
    @MainActor func testTerminalGravityRestorePreservesLossAcrossMigrationActivationAndRelaunch() throws {
        for generation in [SkyGeneration.gravityOrbits, .gravityOpportunities] {
            for key in [SkySaveArchive.key, SkySaveArchive.gravityKey] {
                let defaults = makeDefaults()
                var original = FallingSky(seed: 0, generation: generation)
                for _ in 0..<100 where !original.isOver { original.letStarsFall() }
                XCTAssertTrue(original.isValidSave); XCTAssertEqual(original.outcome, .lost)
                let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(original))
                let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": key == SkySaveArchive.key ? 8 : 5, "game": json])
                defaults.set(bytes, forKey: key)
                let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertTrue(store.hasSavedSky); XCTAssertNil(store.persistenceNotice)
                XCTAssertEqual(store.game.outcome, .lost); XCTAssertEqual(store.game.blockedColumn, original.blockedColumn)
                XCTAssertEqual(store.game.score, original.score); XCTAssertTrue(store.game.isValidSave)
                XCTAssertEqual(defaults.data(forKey: key), bytes, "Restore construction remains read-only")
                store.setSuspended(false)
                let canonical = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
                XCTAssertEqual(try SkySaveArchive.decode(canonical), store.game)
                let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
                XCTAssertTrue(restored.hasSavedSky); XCTAssertEqual(restored.game, store.game)
                XCTAssertNil(restored.persistenceNotice)
                restored.restart(sameSky: true)
                XCTAssertFalse(restored.game.isOver); XCTAssertTrue(restored.game.isValidSave)
            }
        }
    }
}

extension SkySaveArchiveTests {
    /// Generated by the unmodified 016822a Core at score 9, using seed 42 and
    /// first-legal clears. Keep these historical bytes independent of today's encoder.
    private var preRibbonFirstLightV8: Data {
        Data(#"{"game":{"board":[null,null,{"grown":false,"id":9,"kind":2},null,{"grown":false,"id":8,"kind":2},{"grown":false,"id":11,"kind":0},{"grown":false,"id":12,"kind":0},null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"challenge":"firstLight","cohesiveShowers":true,"darkStarsCleared":0,"incoming":[{"column":1,"id":20,"kind":1},{"column":6,"id":21,"kind":1}],"random":{"state":11643393128411363081},"remainingColumns":[0,1,2,3,4,5],"savedBalance":{"darkStars":"none","pace":4},"score":9,"seed":42,"showersUntilDark":0,"starsLanded":13,"turns":4},"schemaVersion":8}"#.utf8)
    }

    @MainActor func testPreRibbonV8FirstLightKeepsExactBytesIdentityPreviewAndReplay() throws {
        let bytes = preRibbonFirstLightV8
        let defaults = makeDefaults()
        defaults.set(bytes, forKey: SkySaveArchive.key)
        let retained = try SkySaveArchive.decode(bytes)
        XCTAssertEqual(retained.challenge, .firstLight)
        XCTAssertEqual(retained.score, 9)
        XCTAssertEqual(retained.restoration?.milestone, .half)
        XCTAssertEqual(try SkySaveArchive.encode(retained), bytes)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.game, retained)
        XCTAssertTrue(store.isPaused)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: .ribbonCrossing))
        XCTAssertEqual(preview.challenge, .ribbonCrossing)
        XCTAssertEqual(preview.progress.score, 0)
        XCTAssertEqual(store.game, retained)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(retained.replay(), FallingSky(challenge: .firstLight))
        var reference = FallingSky(challenge: .firstLight)
        for _ in 0..<40 where reference.score < 9 && !reference.isOver {
            if let cell = reference.legalGroups.first?.first { _ = reference.clear(cell) }
            else { _ = reference.letStarsFall() }
        }
        XCTAssertEqual(reference, retained)
        var restored = retained
        for _ in 0..<10 where !reference.isOver {
            XCTAssertEqual(restored.incoming, reference.incoming)
            if let cell = reference.legalGroups.first?.first {
                _ = reference.clear(cell); _ = restored.clear(cell)
            } else {
                _ = reference.letStarsFall(); _ = restored.letStarsFall()
            }
            XCTAssertEqual(restored, reference)
        }
    }

    @MainActor func testRibbonV8RoundTripAndUnknownChallengeNeverFallBackOrLoseRejectedBytes() throws {
        let game = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .ribbonCrossing)
        let bytes = try SkySaveArchive.encode(game)
        XCTAssertEqual(try SkySaveArchive.decode(bytes), game)
        XCTAssertEqual(try SkySaveArchive.decode(bytes).replay(), FallingSky(challenge: .ribbonCrossing))
        var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(envelope["schemaVersion"] as? Int, 8)
        var core = try XCTUnwrap(envelope["game"] as? [String: Any])
        core["challenge"] = "futureCrossing"; envelope["game"] = core
        let rejected = try JSONSerialization.data(withJSONObject: envelope)
        XCTAssertThrowsError(try SkySaveArchive.decode(rejected))
        let defaults = makeDefaults()
        let old = try JSONEncoder().encode(FallingSky(seed: 17, openingCascade: false))
        defaults.set(old, forKey: SkySaveArchive.legacyKey)
        defaults.set(rejected, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.persistenceNotice, .rejected)
        XCTAssertFalse(store.hasSavedSky)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), rejected)
        store.startChallenge(.ribbonCrossing)
        let recovery = try XCTUnwrap(defaults.dictionary(forKey: SkySaveArchive.rejectedKey))
        XCTAssertEqual(recovery["sourceKey"] as? String, SkySaveArchive.key)
        XCTAssertEqual(recovery["value"] as? Data, rejected)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), old)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
    }
}
