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
