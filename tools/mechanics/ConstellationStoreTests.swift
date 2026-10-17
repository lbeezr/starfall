
extension FallingSkyStoreTests {
    @MainActor func testConstellationFixtureClearCommitRestoreAndRapidInput() throws {
        let (store, presenter, _, defaults) = makeStore()
        store.loadConstellationFixture(.five)
        let initial = store.game
        XCTAssertTrue(initial.isValidSave)
        store.clear(Cell(1,3))
        if __CANDIDATE__ {
            XCTAssertEqual(store.game.score, 5)
            XCTAssertTrue(store.busy)
            let committed = store.game
            store.clear(Cell(0,4)); XCTAssertEqual(store.game, committed)
            let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, committed); XCTAssertTrue(restored.isPaused)
            XCTAssertEqual(restored.game.incoming, initial.incoming)
            presenter.finish(); XCTAssertFalse(store.busy)
        } else {
            XCTAssertEqual(store.game, initial); XCTAssertFalse(store.busy)
        }
    }

    @MainActor func testConstellationExamplesRejectFourCountAndClearWholeOverlap() {
        let (store, presenter, _, _) = makeStore()
        for fixture in ConstellationFixture.allCases { XCTAssertTrue(fixture.game().isValidSave) }
        store.loadConstellationFixture(.fourGrown)
        let four = store.game
        store.clear(Cell(0,0)); XCTAssertEqual(store.game, four)
        store.loadConstellationFixture(.overlap)
        store.clear(Cell(1,3))
        XCTAssertEqual(store.game.score, __CANDIDATE__ ? 7 : 0)
        presenter.finish()
        store.loadConstellationFixture(.darkness)
        store.clear(Cell(1,3))
        XCTAssertEqual(store.game.score, __CANDIDATE__ ? 5 : 0)
        XCTAssertEqual(store.game.darkStarsCleared, __CANDIDATE__ ? 1 : 0)
        XCTAssertTrue(store.game.gem(at: Cell(0,2))?.isDark == true)
    }

    @MainActor func testConstellationPendingClearInterruptionRejectsStaleCompletion() throws {
        guard __CANDIDATE__ else { return }
        for interruption in ["background", "pause", "motion", "fixture", "restart"] {
            let (store, presenter, clock, defaults) = makeStore()
            store.loadConstellationFixture(.five)
            store.togglePause()
            let staleClock = clock.action
            store.clear(Cell(1,3))
            let completion = try XCTUnwrap(presenter.completions.last)
            XCTAssertEqual(store.game.score, 5)
            switch interruption {
            case "background": store.setSuspended(true)
            case "pause": store.togglePause()
            case "motion": store.setReducedMotion(true)
            case "fixture": store.loadConstellationFixture(.fourGrown)
            default: store.restart(sameSky: true)
            }
            let expected = store.game
            completion()
            // A motion change settles presentation but deliberately preserves the live rain deadline.
            if interruption == "motion" {
                XCTAssertNotNil(clock.deadline)
            } else { staleClock?() }
            XCTAssertEqual(store.game, expected, interruption)
            XCTAssertFalse(store.busy, interruption)
            let saved = try JSONDecoder().decode(FallingSky.self, from: XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
            XCTAssertEqual(saved, expected); XCTAssertTrue(saved.isValidSave)
        }
    }

    @MainActor func testConstellationSceneLinksBoundedAndAbsentOnEmptyBoard() {
        guard __CANDIDATE__ else { return }
        let scene = FallingSkyScene()
        let five = ConstellationFixture.five.game()
        for _ in 0..<4 { scene.render(five) }
        var links = 0
        scene.enumerateChildNodes(withName: "//lab.constellation.link") { _, _ in links += 1 }
        XCTAssertEqual(links, 4)
        let four = ConstellationFixture.fourGrown.game()
        XCTAssertLessThan(four.group(at: Cell(0,0)).count, 5)
        scene.render(four)
        links = 0
        scene.enumerateChildNodes(withName: "//lab.constellation.link") { _, _ in links += 1 }
        XCTAssertEqual(links, four.legalGroups.filter { $0.count >= 5 }.reduce(0) { $0 + $1.count-1 })
        scene.render(FallingSky(seed: 5))
        links = 0
        scene.enumerateChildNodes(withName: "//lab.constellation.link") { _, _ in links += 1 }
        XCTAssertEqual(links, 0)
    }
}
