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
    @MainActor func testCollisionSavedBeforeAnimationRestorePausedAndNativeKeyUntouched() throws {
        let (store,defaults,presenter,_)=make()
        let sentinel=Data("normal save sentinel".utf8)
        defaults.set(sentinel,forKey:"starfall.accumulation.v3")
        store.clear(Cell(0,3))
        XCTAssertTrue(store.busy); XCTAssertNotNil(store.game.orbit)
        let saved=try XCTUnwrap(GravitySave.restore(try XCTUnwrap(defaults.data(forKey:FallingSkyStore.saveKey))))
        XCTAssertEqual(saved,store.game)
        let restored=FallingSkyStore(defaults:defaults,arguments:[])
        XCTAssertEqual(restored.game,saved); XCTAssertTrue(restored.isPaused)
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
        XCTAssertTrue(store.message.contains("captive"))
    }
    @MainActor func testCurrentAndLegacyProductionKeysStayUntouched() {
        let (store,defaults,presenter,_)=make()
        let sentinel=Data("production save sentinel".utf8)
        for key in [SkySaveArchive.key,SkySaveArchive.legacyKey] { defaults.set(sentinel,forKey:key) }
        store.clear(Cell(0,3)); presenter.finish(); store.callShower(); presenter.finish()
        for key in [SkySaveArchive.key,SkySaveArchive.legacyKey] { XCTAssertEqual(defaults.data(forKey:key),sentinel) }
    }

}
