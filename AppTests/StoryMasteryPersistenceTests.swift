import XCTest
import StarfallCore
@testable import Starfall

final class StoryMasteryPersistenceTests: XCTestCase {
    private enum InjectedFailure: Error { case write }
    private let high = [(27,34), (1,2), (31,32), (12,13), (16,17),
                        (8,9), (11,12), (29,30), (29,36), (9,16)]
    private let line = [(1,2), (27,34), (5,12), (0,1), (16,17), (24,31), (25,32),
                        (1,2), (1,8), (7,14), (37,44), (2,3), (2,9), (33,34),
                        (18,19), (16,17), (18,25), (18,19), (1,2), (4,11), (32,33)]

    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.StoryMasteryPersistence.\(UUID())"
        let value = UserDefaults(suiteName: suite)!
        addTeardownBlock { @MainActor in value.removePersistentDomain(forName: suite) }
        return value
    }

    private func fullBoardWin(strong: Bool = true, enrolled: Bool = true, runID: UUID = UUID()) throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        if enrolled { XCTAssertTrue(game.enrollMastery(runID: runID)) }
        for (from, to) in (strong ? high : line) {
            _ = try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        if enrolled { XCTAssertEqual(game.completedMasteryRun?.rank, strong ? 3 : 2) }
        return game
    }

    private func skyWin(runID: UUID = UUID()) throws -> FallingSky {
        var game = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(game.enrollMastery(runID: runID))
        for (index, wave) in StoryPatternPlan.lantern.waves.enumerated() {
            for move in wave {
                _ = try XCTUnwrap(game.nudge(from: Cell(move.from / 7, move.from % 7),
                                           to: Cell(move.to / 7, move.to % 7)))
            }
            if index < StoryPatternPlan.lantern.waves.count - 1 { _ = try XCTUnwrap(game.letStarsFall()) }
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.completedMasteryRun?.rank, 3)
        return game
    }

    private func roundEnvelope(_ game: FallingSky, version: Int) throws -> Data {
        let fields = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": fields], options: .sortedKeys)
    }

    private func bestEnvelope(_ records: [StoryMasteryRecord], version: Int = 1) throws -> Data {
        let fields = try records.map { try JSONSerialization.jsonObject(with: JSONEncoder().encode($0)) }
        return try JSONSerialization.data(withJSONObject: ["version": version, "records": fields], options: .sortedKeys)
    }

    /// Invariant-valid aggregate proofs isolate persistence ranks and no-union
    /// semantics. These are not claims about reachable authored action histories.
    private func aggregateFullBoardWin(cascade: Bool, large: Bool) throws -> FallingSky {
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        var counts = Array(repeating: 0, count: 50)
        var tierCounts = Array(repeating: Array(repeating: 0, count: 50), count: 5)
        var tierLight = Array(repeating: 0, count: 5)
        let fours = large ? 28 : cascade ? 29 : 30
        for index in 0..<fours {
            let tier = cascade && index == fours-1 ? 1 : 0
            counts[4] += 1; tierCounts[tier][4] += 1; tierLight[tier] += 4
        }
        if large { counts[8] = 1; tierCounts[0][8] = 1; tierLight[0] += 8 }
        let light = tierLight.reduce(0,+)
        var random = SeededRandom(seed: 42)
        for _ in 0..<light { _ = random.next() }
        fields["score"] = light
        fields["starsLanded"] = 49+light
        fields["turns"] = tierCounts[0].reduce(0,+)
        fields["storyScoreLedger"] = ["clearCounts": counts, "cascadeTiers": (0..<5).map {
            ["light": tierLight[$0], "clearCounts": tierCounts[$0]] as [String: Any]
        }] as [String: Any]
        fields["fullBoardSupply"] = ["suppliedStars": light, "refillingPhases": counts.reduce(0,+)]
        fields["random"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(random))
        let proof = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertTrue(proof.isValidSave)
        XCTAssertEqual(proof.outcome, .won)
        return proof
    }

    @MainActor private func exchange(_ move: (Int, Int), in store: FallingSkyStore,
                                     presenter: FallingSkyRecorder) {
        XCTAssertTrue(store.performTechnique(.nudge(Cell(move.0/7,move.0%7), Cell(move.1/7,move.1%7)),
                                            snapshot: store.game, generation: store.constellationInputGeneration))
        presenter.finish()
    }

    @MainActor func testV19PreservesEnrolledProgressWhileRetainedV18ContinueAndReplayStayUnenrolled() throws {
        var enrolled = FallingSky.freshChallenge(.firstLight)
        let runID = UUID()
        XCTAssertTrue(enrolled.enrollMastery(runID: runID))
        _ = try XCTUnwrap(enrolled.nudge(from: Cell(1,1), to: Cell(1,2)))
        XCTAssertEqual(enrolled.masteryProgress?.earned, [.cascade])
        let bytes = try SkySaveArchive.encode(enrolled)
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(SkySaveArchive.key, "starfall.accumulation.v19")
        XCTAssertEqual(fields["schemaVersion"] as? Int, 19)
        XCTAssertEqual(try SkySaveArchive.decode(bytes), enrolled)
        XCTAssertEqual(try SkySaveArchive.decode(bytes).masteryEnrollment?.runID, runID)

        let defaults = defaults(), old = FallingSky.fullBoardLantern()
        let retained = try roundEnvelope(old, version: 18)
        defaults.set(retained, forKey: SkySaveArchive.preMasteryKey)
        let loaded = try XCTUnwrap(SkySaveArchive.load(from: defaults))
        XCTAssertEqual(loaded, old)
        XCTAssertNil(loaded.masteryEnrollment)
        XCTAssertNil(loaded.replay(masteryRunID: UUID()).masteryEnrollment)
        XCTAssertNil(loaded.completedMasteryRun)
        XCTAssertFalse(WorldJourneyStore(defaults: defaults).journey.legacyAccess)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.preMasteryKey), retained)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
    }

    @MainActor func testEveryHistoricalEnvelopeRejectsEnrollmentAndBlocksFallbackWithoutChangingBytes() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        let legacy = try JSONEncoder().encode(FallingSky(seed: 42, openingCascade: false))
        let versions = [(SkySaveArchive.preMasteryKey,18), (SkySaveArchive.frostfruitEncounterKey,17),
                        (SkySaveArchive.ribbonFullBoardKey,16), (SkySaveArchive.revisedFullBoardKey,15),
                        (SkySaveArchive.fullBoardKey,14), (SkySaveArchive.fourLineKey,13),
                        (SkySaveArchive.patternKey,12), (SkySaveArchive.cascadeKey,11),
                        (SkySaveArchive.storyKey,10), (SkySaveArchive.worldKey,9),
                        (SkySaveArchive.agingKey,8), (SkySaveArchive.patientFeedingKey,7),
                        (SkySaveArchive.feedingKey,6), (SkySaveArchive.gravityKey,5), (SkySaveArchive.previousKey,4)]
        for (key, version) in versions {
            let defaults = defaults(), bytes = try roundEnvelope(game, version: version)
            defaults.set(legacy, forKey: SkySaveArchive.legacyKey)
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults))
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail(key) }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.legacyKey), legacy)
            XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        }
    }

    @MainActor func testMalformedCurrentEnrollmentIsStrictlyRejectedAndPreservedBeforeReplacement() throws {
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: UUID()))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        var enrollment = try XCTUnwrap(fields["masteryEnrollment"] as? [String: Any])
        var identity = try XCTUnwrap(enrollment["identity"] as? [String: Any])
        identity["goalSetRevision"] = 99
        enrollment["identity"] = identity
        fields["masteryEnrollment"] = enrollment
        let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 19, "game": fields])
        let defaults = defaults(), previous = try roundEnvelope(FallingSky.fullBoardLantern(), version: 18)
        defaults.set(previous, forKey: SkySaveArchive.preMasteryKey)
        defaults.set(true, forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults), "A wrong-type current object blocks valid retained bytes")
        guard case .rejected(let wrongTypeSource) = SkySaveArchive.inspect(from: defaults) else {
            return XCTFail("Expected wrong-type current rejection")
        }
        XCTAssertEqual(wrongTypeSource, SkySaveArchive.key)
        XCTAssertEqual(defaults.object(forKey: SkySaveArchive.key) as? Bool, true)
        defaults.set(bytes, forKey: SkySaveArchive.key)
        XCTAssertThrowsError(try SkySaveArchive.decode(bytes))
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail("Expected strict rejection") }
        XCTAssertEqual(source, SkySaveArchive.key)
        try SkySaveArchive.save(game, to: defaults)
        XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey)?["value"] as? Data, bytes)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.preMasteryKey), previous)
    }

    @MainActor func testWholeBestKeepsFirstEqualRankPromotesHigherAndSeparatesModeIdentities() throws {
        let lower = try fullBoardWin(strong: false), equalLower = try fullBoardWin(strong: false)
        let higher = try fullBoardWin(), equalHigher = try fullBoardWin(), sky = try skyWin()
        let identity = try XCTUnwrap(lower.masteryEnrollment?.identity)
        let defaults = defaults()
        var writes = 0
        let store = StoryMasteryStore(defaults: defaults, writer: { data, defaults in
            writes += 1; try StoryMasteryStore.write(data, to: defaults)
        })
        for game in [lower, equalLower] {
            try SkySaveArchive.save(game, to: defaults)
            try store.record(game)
        }
        XCTAssertEqual(store.best(for: identity)?.runID, lower.masteryEnrollment?.runID)
        XCTAssertEqual(writes, 1)
        for game in [higher, lower, equalHigher, sky] {
            try SkySaveArchive.save(game, to: defaults)
            try store.record(game)
        }
        XCTAssertEqual(store.best(for: identity), higher.completedMasteryRun)
        XCTAssertEqual(writes, 3)
        XCTAssertEqual(store.records.count, 2)
        XCTAssertEqual(store.best(for: try XCTUnwrap(sky.masteryEnrollment?.identity)), sky.completedMasteryRun)
        XCTAssertEqual(StoryMasteryStore(defaults: defaults).records, store.records)
        XCTAssertFalse(store.needsPersistence)
    }

    @MainActor func testReadOnlyCrashRepairRetainsDirtyBestAcrossWriterFailureWithoutSuppressingRepair() throws {
        let game = try fullBoardWin(), defaults = defaults()
        try SkySaveArchive.save(game, to: defaults)
        let round = defaults.data(forKey: SkySaveArchive.key)
        let world = WorldJourneyStore(defaults: defaults)
        XCTAssertEqual(world.journey.completed, [.firstLight])
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
        var fail = true, writes = 0
        let store = StoryMasteryStore(defaults: defaults, writer: { data, defaults in
            writes += 1
            if fail { throw InjectedFailure.write }
            try StoryMasteryStore.write(data, to: defaults)
        })
        XCTAssertEqual(store.records, [try XCTUnwrap(game.completedMasteryRun)])
        XCTAssertTrue(store.needsPersistence)
        XCTAssertEqual(writes, 0)
        XCTAssertNil(defaults.object(forKey: StoryMasteryStore.key))
        try world.record(game)
        XCTAssertThrowsError(try store.record(game))
        XCTAssertTrue(store.needsPersistence)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
        XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.canEnter(.ribbonCrossing))
        XCTAssertNil(defaults.object(forKey: StoryMasteryStore.key))
        let relaunched = StoryMasteryStore(defaults: defaults)
        XCTAssertEqual(relaunched.records, store.records)
        XCTAssertTrue(relaunched.needsPersistence)
        fail = false
        try store.record(game)
        try store.record(game)
        XCTAssertEqual(writes, 2)
        XCTAssertFalse(store.needsPersistence)
        XCTAssertEqual(StoryMasteryStore(defaults: defaults).records, store.records)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
    }

    @MainActor func testInvalidBestEnvelopesAreQuarantinedWithoutPoisoningTheRoundOrWorld() throws {
        let win = try fullBoardWin(), proof = try XCTUnwrap(win.completedMasteryRun)
        let ordinary = try fullBoardWin(enrolled: false)
        var invalid = try XCTUnwrap(JSONSerialization.jsonObject(with: bestEnvelope([proof])) as? [String: Any])
        var records = try XCTUnwrap(invalid["records"] as? [[String: Any]])
        var badGame = try XCTUnwrap(records[0]["game"] as? [String: Any])
        var badEnrollment = try XCTUnwrap(badGame["masteryEnrollment"] as? [String: Any])
        badEnrollment["identity"] = ["challenge": "ribbonCrossing", "contentRevision": 6, "goalSetRevision": 1]
        badGame["masteryEnrollment"] = badEnrollment
        records[0]["game"] = badGame
        invalid["records"] = records
        let values: [Any] = [Data("broken best".utf8), true, try bestEnvelope([proof], version: 2),
                             try bestEnvelope([proof, proof]), try bestEnvelope([proof, proof, proof]),
                             try JSONSerialization.data(withJSONObject: invalid)]
        for raw in values {
            let defaults = defaults()
            try SkySaveArchive.save(ordinary, to: defaults)
            let bytes = defaults.data(forKey: SkySaveArchive.key)
            defaults.set(raw, forKey: StoryMasteryStore.key)
            let store = StoryMasteryStore(defaults: defaults)
            XCTAssertTrue(store.recovered)
            XCTAssertTrue(store.records.isEmpty)
            XCTAssertFalse(store.needsPersistence)
            XCTAssertEqual(defaults.object(forKey: StoryMasteryStore.key) as? NSObject, raw as? NSObject)
            XCTAssertNil(defaults.object(forKey: StoryMasteryStore.rejectedKey))
            XCTAssertEqual(SkySaveArchive.load(from: defaults), ordinary)
            XCTAssertEqual(WorldJourneyStore(defaults: defaults).journey.completed, [.firstLight])
            try SkySaveArchive.save(win, to: defaults)
            try store.record(win)
            XCTAssertEqual(defaults.object(forKey: StoryMasteryStore.rejectedKey) as? NSObject, raw as? NSObject)
            XCTAssertEqual(StoryMasteryStore(defaults: defaults).records, [proof])
            XCTAssertNotEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        }
    }

    @MainActor func testIgnoringSavedRecordsAndSubmittingUnenrolledPlayingOrLostRoundsWritesNoBest() throws {
        let defaults = defaults(), winner = try fullBoardWin()
        try SkySaveArchive.save(winner, to: defaults)
        try StoryMasteryStore(defaults: defaults).record(winner)
        let retained = defaults.data(forKey: StoryMasteryStore.key)
        var writes = 0
        let store = StoryMasteryStore(defaults: defaults, ignoreSaved: true, writer: { _, _ in writes += 1 })
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertFalse(store.needsPersistence)
        var playing = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(playing.enrollMastery(runID: UUID()))
        var lost = playing
        for _ in 0..<5 { _ = try XCTUnwrap(lost.letStarsFall()) }
        XCTAssertEqual(lost.outcome, .lost)
        for game in [try fullBoardWin(enrolled: false), playing, lost] { try store.record(game) }
        XCTAssertEqual(writes, 0)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertEqual(defaults.data(forKey: StoryMasteryStore.key), retained)
    }

    @MainActor func testAggregateWholeRunProofsNeverUnionDifferentTwoStarAttempts() throws {
        let plain = try aggregateFullBoardWin(cascade: false, large: false)
        let cascade = try aggregateFullBoardWin(cascade: true, large: false)
        let large = try aggregateFullBoardWin(cascade: false, large: true)
        let both = try aggregateFullBoardWin(cascade: true, large: true)
        let defaults = defaults(), store = StoryMasteryStore(defaults: defaults)
        let identity = try XCTUnwrap(plain.masteryEnrollment?.identity)
        XCTAssertEqual([plain,cascade,large,both].compactMap(\.completedMasteryRun).map(\.rank), [1,2,2,3])
        for game in [plain,cascade,large] {
            try SkySaveArchive.save(game, to: defaults)
            try store.record(game)
        }
        XCTAssertEqual(store.best(for: identity), cascade.completedMasteryRun)
        XCTAssertEqual(store.best(for: identity)?.earned, [.cascade])
        XCTAssertEqual(StoryMasteryStore(defaults: defaults).best(for: identity), cascade.completedMasteryRun)
        try SkySaveArchive.save(both, to: defaults)
        try store.record(both)
        XCTAssertEqual(store.best(for: identity), both.completedMasteryRun)
        XCTAssertEqual(store.best(for: identity)?.earned, [.cascade,.largeClear])
    }

    @MainActor func testOnlyProductionBeginEnrollsAndReplayResetsAnEnrolledAttempt() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        XCTAssertNil(store.game.masteryEnrollment)
        store.startFirstLight(); XCTAssertNil(store.game.masteryEnrollment)
        store.startFullBoardLantern(); XCTAssertNil(store.game.masteryEnrollment)
        store.restart(sameSky: true); XCTAssertNil(store.game.masteryEnrollment)
        for choice in [SkyEntryRequest.firstLight, .fullBoardLantern] {
            XCTAssertTrue(store.beginEntry(choice))
            let enrollment = try XCTUnwrap(store.game.masteryEnrollment)
            XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
            store.setSuspended(false)
            exchange((8,9), in: store, presenter: presenter)
            XCTAssertEqual(store.game.masteryProgress?.earned, [.cascade])
            XCTAssertTrue(store.beginEntry(.replay))
            XCTAssertEqual(store.game.masteryEnrollment?.identity, enrollment.identity)
            XCTAssertNotEqual(store.game.masteryEnrollment?.runID, enrollment.runID)
            XCTAssertTrue(try XCTUnwrap(store.game.masteryProgress).earned.isEmpty)
            store.setSuspended(true)
        }
        store.startFullBoardRibbon(); XCTAssertNil(store.game.masteryEnrollment)
        XCTAssertTrue(store.mastery.records.isEmpty)
        XCTAssertNil(defaults.object(forKey: StoryMasteryStore.key))
    }

    @MainActor func testRestoredWinnerProjectsReadOnlyAndFailedBestBlocksReplacementUntilRetry() throws {
        let winner = try fullBoardWin(), defaults = defaults()
        try SkySaveArchive.save(winner, to: defaults)
        let round = defaults.data(forKey: SkySaveArchive.key)
        var fail = true, writes = 0
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                   clock: ManualRainClock(), masteryWriter: { data, defaults in
            writes += 1
            if fail { throw InjectedFailure.write }
            try StoryMasteryStore.write(data, to: defaults)
        })
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(store.game, winner)
        XCTAssertEqual(store.mastery.records, [try XCTUnwrap(winner.completedMasteryRun)])
        XCTAssertTrue(store.mastery.needsPersistence)
        XCTAssertNil(defaults.object(forKey: StoryMasteryStore.key))
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
        store.setSuspended(false)
        XCTAssertTrue(store.masterySaveFailed)
        XCTAssertEqual(store.persistenceNotice, .masteryFailed)
        XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.canEnter(.ribbonCrossing))
        XCTAssertFalse(store.beginEntry(.firstLight))
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, winner)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
        XCTAssertNil(defaults.object(forKey: StoryMasteryStore.key))
        fail = false
        XCTAssertTrue(store.beginEntry(.replay))
        XCTAssertFalse(store.masterySaveFailed)
        XCTAssertFalse(store.mastery.needsPersistence)
        XCTAssertEqual(store.mastery.records, [try XCTUnwrap(winner.completedMasteryRun)])
        XCTAssertNotEqual(store.game.masteryEnrollment?.runID, winner.masteryEnrollment?.runID)
        XCTAssertTrue(try XCTUnwrap(store.game.masteryProgress).earned.isEmpty)
        XCTAssertEqual(store.game.displayScore, 0)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
        XCTAssertGreaterThan(writes, 1)
        store.setSuspended(true)
    }

    @MainActor func testFailedAuthoritativeWinningWriteCannotAwardBestOrRepair() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder()
        var rejectWin = true, bestWrites = 0
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                   clock: ManualRainClock(), archiveWriter: { game, defaults in
            if game.outcome == .won && rejectWin { throw InjectedFailure.write }
            try SkySaveArchive.save(game, to: defaults)
        }, masteryWriter: { data, defaults in
            bestWrites += 1; try StoryMasteryStore.write(data, to: defaults)
        })
        XCTAssertTrue(store.beginEntry(.fullBoardLantern))
        store.setSuspended(false)
        for move in high.dropLast() { exchange(move, in: store, presenter: presenter) }
        let durable = try XCTUnwrap(SkySaveArchive.load(from: defaults))
        XCTAssertEqual(durable.displayScore, 98_000)
        exchange(try XCTUnwrap(high.last), in: store, presenter: presenter)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertTrue(store.saveFailed)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), durable)
        XCTAssertEqual(bestWrites, 0)
        XCTAssertTrue(store.mastery.records.isEmpty)
        XCTAssertFalse(WorldJourneyStore(defaults: defaults).journey.completed.contains(.firstLight))
        XCTAssertFalse(store.beginEntry(.firstLight))
        XCTAssertEqual(SkySaveArchive.load(from: defaults), durable)
        rejectWin = false
        XCTAssertTrue(store.beginEntry(.replay))
        XCTAssertEqual(bestWrites, 1)
        XCTAssertEqual(store.mastery.records.count, 1)
        XCTAssertTrue(WorldJourneyStore(defaults: defaults).journey.completed.contains(.firstLight))
        XCTAssertEqual(store.game.displayScore, 0)
        store.setSuspended(true)
    }

    @MainActor func testPracticeAndResetReviewCannotSubmitOptionalRecordsOrReplacePlayerBytes() throws {
        let winner = try fullBoardWin(), defaults = defaults()
        try SkySaveArchive.save(winner, to: defaults)
        try StoryMasteryStore(defaults: defaults).record(winner)
        try WorldJourneyStore(defaults: defaults).record(winner)
        let round = defaults.data(forKey: SkySaveArchive.key)
        let best = defaults.data(forKey: StoryMasteryStore.key)
        let world = defaults.data(forKey: WorldJourneyStore.key)
        let presenter = FallingSkyRecorder()
        var writes = 0
        let practice = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                       clock: ManualRainClock(), tutorial: .fullBoardRefill,
                                       archiveWriter: { _, _ in writes += 1 },
                                       masteryWriter: { _, _ in writes += 1 })
        practice.setSuspended(false)
        for action in SkyTutorial.fullBoardRefill.actions {
            switch action {
            case .swap(let from, let to):
                XCTAssertTrue(practice.requestInput(.swap(from,to), snapshot: practice.game,
                                                   generation: practice.constellationInputGeneration))
            case .shower: practice.callShower()
            default: XCTFail("This practice uses production exchanges and showers")
            }
            presenter.finish()
        }
        XCTAssertTrue(practice.tutorial?.complete == true)
        XCTAssertTrue(practice.mastery.records.isEmpty)
        XCTAssertNil(practice.game.masteryEnrollment)
        practice.setSuspended(true)
        #if DEBUG
        let review = FallingSkyStore(defaults: defaults,
                                    arguments: ["--starfalls-reset", "--dialogue-review", "--full-board-v5-review"],
                                    presenter: FallingSkyRecorder(), clock: ManualRainClock(),
                                    archiveWriter: { _, _ in writes += 1 }, masteryWriter: { _, _ in writes += 1 })
        XCTAssertEqual(review.game.challengeRevision, 5)
        XCTAssertNil(review.game.masteryEnrollment)
        XCTAssertTrue(review.mastery.records.isEmpty)
        #endif
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
        XCTAssertEqual(defaults.data(forKey: StoryMasteryStore.key), best)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
    }
}
