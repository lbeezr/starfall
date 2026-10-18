
extension FallingSkyStoreTests {
    private var chosenTrace: [Cell] { [Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)] }

    @MainActor func testTraceCoreClearsOnlyChosenStarsAndPreservesPreviewReplay() throws {
        var game = ConstellationFixture.overlap.game()
        let initial = game, selected = Set(chosenTrace)
        let untraced = Set(initial.board.compactMap { $0 }.map(\.id)).subtracting(selected.compactMap { initial.gem(at: $0)?.id })
        let before = try JSONSerialization.jsonObject(with: JSONEncoder().encode(initial)) as! NSDictionary
        let turn = try XCTUnwrap(game.clearConstellation(chosenTrace))
        XCTAssertEqual(turn.collected, 5); XCTAssertEqual(turn.cleared, selected)
        XCTAssertEqual(Set(game.board.compactMap { $0 }.map(\.id)), untraced)
        XCTAssertEqual(game.incoming, initial.incoming); XCTAssertEqual(game.turns, initial.turns)
        XCTAssertTrue(game.isValidSave)
        let after = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! NSDictionary
        for key in ["random","remainingColumns"] { XCTAssertTrue((before[key] as? NSObject)?.isEqual(after[key]) == true) }
        var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        var control = game
        restored.letStarsFall(); control.letStarsFall(); XCTAssertEqual(restored, control)
    }

    @MainActor func testTraceCoreRejectsCountFamilyJumpsAndUnboundedWalksWithoutMutation() {
        let fixture = ConstellationFixture.overlap.game()
        let paths = [Array(chosenTrace.prefix(4)), [Cell(0,4),Cell(0,5),Cell(0,6),Cell(1,3),Cell(2,4)],
                     [Cell(0,4),Cell(1,4),Cell(2,4),Cell(1,5),Cell(1,6)],
                     [Cell(-1,4)]+chosenTrace, Array(repeating: Cell(0,4), count: 197)+chosenTrace]
        for path in paths {
            var game = fixture; XCTAssertNil(game.clearConstellation(path)); XCTAssertEqual(game, fixture)
        }
        var four = ConstellationFixture.fourGrown.game()
        let initial = four
        XCTAssertNil(four.clearConstellation((0..<4).map { Cell($0,$0) })); XCTAssertEqual(four, initial)
        var repeated = fixture
        let walk = [Cell(0,4),Cell(1,3),Cell(0,4),Cell(1,3),Cell(2,4),Cell(1,5),Cell(1,6)]
        XCTAssertEqual(repeated.clearConstellation(walk)?.collected, 5)
    }

    @MainActor func testTraceDarknessAndOrdinaryTapRemainSeparate() {
        var game = ConstellationFixture.darkness.game()
        let before = game
        XCTAssertNil(game.clearOrdinary(Cell(1,3))); XCTAssertEqual(game,before)
        XCTAssertEqual(game.clearConstellation(chosenTrace)?.collected,5)
        XCTAssertEqual(game.darkStarsCleared,1)
        XCTAssertTrue(game.gem(at: Cell(0,2))?.isDark == true)
        XCTAssertTrue(game.isValidSave)
        var opening = FallingSky(seed:5)
        opening.letStarsFall()
        XCTAssertEqual(opening.clearOrdinary(opening.orthogonalLegalGroups[0][0])?.collected,3)
    }

    @MainActor func testTraceIntentTicketsRevisitsAndInterruptionBoundaries() throws {
        for interruption in ["settings","pause","restart","fixture","motion","shower"] {
            let (store, presenter, _, _) = makeStore()
            store.loadConstellationFixture(.overlap)
            let intent = ConstellationTraceIntent(), source = store.game
            let ticket = try XCTUnwrap(intent.begin(chosenTrace[0], game: source, generation:store.constellationInputGeneration, enabled:store.canClear))
            for cell in chosenTrace.dropFirst() {
                XCTAssertTrue(intent.visit(cell,ticket:ticket,game:store.game,generation:store.constellationInputGeneration,enabled:store.canClear))
            }
            XCTAssertEqual(intent.count,5); XCTAssertEqual(intent.value,5)
            switch interruption {
            case "settings": store.setSuspended(true)
            case "pause": store.togglePause()
            case "restart": store.restart(sameSky:true)
            case "fixture": store.loadConstellationFixture(.overlap)
            case "motion": store.setReducedMotion(true)
            default: store.callShower()
            }
            let committed = store.game
            let outcome = intent.finish(ticket:ticket,game:store.game,generation:store.constellationInputGeneration,enabled:store.canClear)
            XCTAssertNil(outcome,interruption)
            store.clearTracedConstellation(chosenTrace,snapshot:source,generation:0)
            XCTAssertEqual(store.game,committed,interruption)
            presenter.finish()
        }
        let intent = ConstellationTraceIntent(), game = ConstellationFixture.five.game()
        let old = intent.begin(chosenTrace[0],game:game,generation:1,enabled:true)
        intent.cancel()
        let current = intent.begin(chosenTrace[0],game:game,generation:1,enabled:true)
        XCTAssertFalse(intent.visit(chosenTrace[1],ticket:old,game:game,generation:1,enabled:true))
        XCTAssertEqual(intent.count,1)
        XCTAssertTrue(intent.visit(chosenTrace[1],ticket:current,game:game,generation:1,enabled:true))
    }

    @MainActor func testTraceStoreCommitsOnceBeforeEffectsAndRestoresOnlyCommittedState() throws {
        let (store,presenter,_,defaults) = makeStore()
        store.loadConstellationFixture(.overlap)
        let source = store.game, ticket = store.constellationInputGeneration
        store.clear(Cell(1,3)); XCTAssertEqual(store.game,source)
        store.clearTracedConstellation(chosenTrace,snapshot:source,generation:ticket)
        XCTAssertEqual(store.game.score,5); XCTAssertTrue(store.busy)
        XCTAssertEqual(store.celebration?.level, .constellation)
        XCTAssertEqual(store.celebration?.path, chosenTrace)
        XCTAssertEqual(Set(store.celebration?.cells ?? []), Set(chosenTrace))
        let committed = store.game
        store.clearTracedConstellation(chosenTrace,snapshot:source,generation:ticket)
        XCTAssertEqual(store.game,committed)
        let restored = FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(restored.game,committed); XCTAssertTrue(restored.isPaused)
        presenter.finish(); XCTAssertFalse(store.busy)
    }

    @MainActor func testTraceVisualsHaveNoRestingSolutionAndStayBounded() {
        let scene = FallingSkyScene()
        scene.render(ConstellationFixture.overlap.game())
        var links = 0
        scene.enumerateChildNodes(withName:"//lab.trace.thread") { _,_ in links += 1 }
        scene.enumerateChildNodes(withName:"//lab.constellation.link") { _,_ in links += 1 }
        XCTAssertEqual(links,0)
        for _ in 0..<10 { scene.showConstellationTrace(chosenTrace,ready:true) }
        var sparks=0
        scene.enumerateChildNodes(withName:"//lab.trace.spark") { _,_ in sparks += 1 }
        XCTAssertEqual(sparks,5)
        scene.clearConstellationTrace()
        links=0
        scene.enumerateChildNodes(withName:"//lab.trace.thread") { _,_ in links += 1 }
        XCTAssertEqual(links,0)
    }
}
