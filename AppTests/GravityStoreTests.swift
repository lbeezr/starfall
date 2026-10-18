import XCTest
import StarfallCore
@testable import Starfall

final class GravityStoreTests: XCTestCase {
    @MainActor private func make(_ fixture: GravityFixture = .opportunity) -> (FallingSkyStore,UserDefaults,FallingSkyRecorder,ManualRainClock) {
        let suite="GravityTests.\(UUID())"
        let defaults=UserDefaults(suiteName:suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName:suite) }
        let presenter=FallingSkyRecorder(), clock=ManualRainClock()
        let store=FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset","--gravity-fixture=\(fixture.rawValue)"],presenter:presenter,clock:clock)
        store.setSuspended(false)
        return (store,defaults,presenter,clock)
    }
    @MainActor func testCollisionSavedBeforeAnimationRestorePausedAndLegacyKeyUntouched() throws {
        let (store,defaults,presenter,_)=make()
        let sentinel=Data("normal save sentinel".utf8)
        defaults.set(sentinel,forKey:"starfall.accumulation.v3")
        store.clear(Cell(0,3))
        XCTAssertTrue(store.busy); XCTAssertNotNil(store.game.orbit)
        let saved=try XCTUnwrap(try? SkySaveArchive.decode(try XCTUnwrap(defaults.data(forKey:FallingSkyStore.saveKey))))
        XCTAssertEqual(saved,store.game)
        let restored=FallingSkyStore(defaults:defaults,arguments:[])
        XCTAssertEqual(restored.game,saved.removingGravity().adoptingFeedingDusk()); XCTAssertTrue(restored.isPaused)
        XCTAssertEqual(defaults.data(forKey:"starfall.accumulation.v3"),sentinel)
        presenter.finish(); XCTAssertFalse(store.busy)
    }
    @MainActor func testDueRainWaitsForCollisionAndDoesNotCatchUp() {
        let (store,_,presenter,clock)=make()
        store.togglePause(); store.clear(Cell(0,3)); let initial=store.game.turns
        clock.advance(60)
        XCTAssertEqual(store.game.turns,initial)
        presenter.finish()
        XCTAssertEqual(store.game.turns,initial+1)
        XCTAssertEqual(store.game.orbit?.windowsRemaining,2)
        presenter.finish(); XCTAssertEqual(store.game.turns,initial+1)
    }
    @MainActor func testFixtureRestartBackgroundAndMotionRejectStalePhases() throws {
        let (store,defaults,presenter,clock)=make()
        store.clear(Cell(0,3)); let stale=try XCTUnwrap(presenter.completions.last)
        store.loadGravityFixture(.takeNow); let fixture=store.game
        stale(); XCTAssertEqual(store.game,fixture); XCTAssertFalse(store.busy)
        store.clear(Cell(0,3)); store.callShower(); store.setSuspended(true)
        let held=store.game; clock.advance(60); presenter.finish(); XCTAssertEqual(store.game,held)
        store.setSuspended(false); store.setReducedMotion(true)
        presenter.finish(); XCTAssertEqual(store.game,held)
        store.restart(sameSky:true); let restarted=store.game
        stale(); XCTAssertEqual(store.game,restarted); XCTAssertNil(restarted.orbit)
        XCTAssertNotNil(defaults.data(forKey:FallingSkyStore.saveKey))
    }
    @MainActor func testManualOrbitAndCaptiveClearDoNotStartClock() {
        let (store,_,presenter,clock)=make(.takeNow)
        store.clear(Cell(0,3)); presenter.finish(); store.clear(Cell(0,2)); presenter.finish()
        XCTAssertNil(store.game.orbit); XCTAssertEqual(store.game.score,6)
        XCTAssertNil(clock.deadline)
    }
    @MainActor func testInvalidHoleTapAndRapidClearCannotSpendTwice() {
        let (store,_,presenter,_)=make()
        store.clear(Cell(0,3)); let formed=store.game
        store.clear(Cell(0,3)); XCTAssertEqual(store.game,formed)
        presenter.finish(); store.clear(Cell(0,3))
        XCTAssertEqual(store.game,formed)
        XCTAssertEqual(store.message, "Clear a matching group that includes a trapped star. The hole will close and free the others.")
    }
    @MainActor func testPreviousAndLegacySaveBytesStayUntouched() {
        let (store,defaults,presenter,_)=make()
        let sentinel=Data("production save sentinel".utf8)
        for key in [SkySaveArchive.previousKey,SkySaveArchive.legacyKey] { defaults.set(sentinel,forKey:key) }
        store.clear(Cell(0,3)); presenter.finish(); store.callShower(); presenter.finish()
        for key in [SkySaveArchive.previousKey,SkySaveArchive.legacyKey] { XCTAssertEqual(defaults.data(forKey:key),sentinel) }
    }

}

final class GravityTraceStoreTests: XCTestCase {
    @MainActor func testOrbitInvalidatesTraceTicketAndSnapshot() throws {
        let suite="GravityTrace.\(UUID())"
        let defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let presenter=FallingSkyRecorder(), clock=ManualRainClock()
        let store=FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset","--gravity-fixture=supports"],presenter:presenter,clock:clock)
        store.setSuspended(false); store.clear(Cell(1,3)); presenter.finish()
        let before=store.game, ticket=store.constellationInputGeneration
        store.callShower(); presenter.finish()
        let rotated=store.game
        XCTAssertNotEqual(ticket,store.constellationInputGeneration)
        store.clearTracedConstellation([Cell(0,0)],snapshot:before,generation:ticket)
        XCTAssertEqual(store.game,rotated)
        let intent=ConstellationTraceIntent()
        XCTAssertNil(intent.begin(Cell(0,0),game:rotated,generation:store.constellationInputGeneration,enabled:false))
    }
    @MainActor func testSelectedCaptiveClosesHoleThroughCanonicalTraceResolution() throws {
        var game=GravityFixture.trace.game()
        game.clear(Cell(0,3))
        let before=game
        let path=(0..<5).map { Cell($0,2) }
        let selected=Set(path)
        XCTAssertNotNil(game.orbit)
        let untouched=Set(before.board.compactMap { $0 }.filter { gem in
            !selected.contains(where: { before.gem(at:$0)?.id == gem.id }) && gem.gravityKind != .hole
        }.map(\.id))
        let turn=try XCTUnwrap(game.clearConstellation(path))
        XCTAssertNil(game.orbit)
        XCTAssertEqual(turn.collected,10)
        XCTAssertEqual(Set(game.board.compactMap { $0?.id }),untouched)
        XCTAssertEqual(game.incoming,before.incoming)
        XCTAssertTrue(game.isValidSave)
    }
}

final class GravityOpportunityStoreTests:XCTestCase {
    @MainActor func testNewSkyUsesCandidateWhileRetainedReplayKeepsOlderGravityRules() throws {
        let suite="GravitySupply.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        var original=FallingSky(seed:421,generation:.gravityOrbits)
        for _ in 0..<4 {original.letStarsFall()}
        let bytes=try SkySaveArchive.encode(original)
        defaults.set(bytes,forKey:SkySaveArchive.key)
        let store=FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(store.game,original.removingGravity().adoptingFeedingDusk())
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.key),bytes)
        store.restart(sameSky:true)
        XCTAssertEqual(store.game.generation,.current)
        store.restart(sameSky:false)
        XCTAssertEqual(store.game.generation,.current)
        store.startFirstLight();store.restart(sameSky:true)
        XCTAssertEqual(store.game.generation,.legacy)
        XCTAssertEqual(store.game.challenge,.firstLight)
    }

    @MainActor func testV4CannotAdmitEitherGravityGenerationEvenBeforeSpecialsArrive() throws {
        let suite="GravityEnvelope.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        for generation in [SkyGeneration.gravityOrbits,.gravityOpportunities,.standardSky] {
            let game=FallingSky(seed:1,generation:generation)
            let object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(game))
            defaults.set(try JSONSerialization.data(withJSONObject:["schemaVersion":4,"game":object]),forKey:SkySaveArchive.previousKey)
            XCTAssertNil(SkySaveArchive.load(from:defaults))
        }
    }

    @MainActor func testReachableChoicePersistsBeforeFeedbackAndRejectsStaleInput() throws {
        let suite="GravityChoice.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer {defaults.removePersistentDomain(forName:suite)}
        let presenter=FallingSkyRecorder()
        let store=FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset","--gravity-fixture=naturalOpportunity"],presenter:presenter,clock:ManualRainClock())
        store.setSuspended(false)
        let before=store.game
        store.clear(Cell(1,2));XCTAssertEqual(store.game.score,26)
        let committed=store.game
        store.clear(Cell(1,2));XCTAssertEqual(store.game,committed)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))),committed)
        let restored=FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(restored.game,committed.removingGravity().adoptingFeedingDusk())
        XCTAssertEqual(committed.incoming,before.incoming)
        let stale=try XCTUnwrap(presenter.completions.last)
        store.setSuspended(true);store.restart(sameSky:true)
        let restarted=store.game;stale();XCTAssertEqual(store.game,restarted)
        XCTAssertEqual(restarted.generation,.current)
    }
}


final class GravityRetirementStoreTests: XCTestCase {
    @MainActor func testResumeRetiresGravityReadOnlyThenPersistsBeforePlay() throws {
        for fixture in [GravityFixture.opportunity, .supports, .naturalOffer] {
            var original = fixture.game()
            if fixture == .opportunity { original.clear(Cell(0, 3)) }
            if fixture == .supports { original.clear(Cell(1, 3)) }
            let suite = "GravityRetirement.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let bytes = try SkySaveArchive.encode(original)
            defaults.set(bytes, forKey: SkySaveArchive.key)
            let clock = ManualRainClock(), presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            let expected = original.removingGravity().adoptingFeedingDusk()
            XCTAssertTrue(store.hasSavedSky); XCTAssertTrue(store.isPaused); XCTAssertTrue(store.suspended)
            XCTAssertEqual(store.game, expected)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes, "Discarded view stores must not write a migration")
            store.setSuspended(false)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
            XCTAssertNil(clock.deadline)
            store.callShower(); let committed = store.game
            let stale = try XCTUnwrap(presenter.completions.last)
            store.setSuspended(true); clock.advance(100); stale()
            XCTAssertEqual(store.game, committed); XCTAssertNil(store.game.orbit)
            XCTAssertFalse(store.game.board.contains { $0?.gravityKind != nil })
            let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, committed)
            store.restart(sameSky: true)
            XCTAssertEqual(store.game.generation, .standardSky)
            XCTAssertEqual(store.game.seed, original.seed)
            XCTAssertEqual(store.game.balance, original.balance)
            XCTAssertNil(store.game.orbit)
        }
    }

    @MainActor func testInvalidGravitySaveIsRejectedBeforeRetirement() throws {
        let suite = "GravityRetirement.Invalid.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var old = GravityFixture.opportunity.game(); old.clear(Cell(0, 3))
        let data = try SkySaveArchive.encode(old)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var game = try XCTUnwrap(object["game"] as? [String: Any])
        game["score"] = 9000; object["game"] = game
        let malformed = try JSONSerialization.data(withJSONObject: object)
        defaults.set(malformed, forKey: SkySaveArchive.key)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertFalse(store.hasSavedSky); XCTAssertEqual(store.game.generation, .standardSky)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), malformed)
    }
}
