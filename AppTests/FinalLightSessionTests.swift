import XCTest
@testable import StarfallCore
@testable import Starfall

@MainActor private final class FinalLightPresenter: FallingSkyPresenting {
    struct Presentation { let phase: (Int) -> Void; let complete: () -> Void }
    var reduceMotion = false
    var presentations: [Presentation] = []
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) {
        presentations.append(.init(phase: { _ in }, complete: completion))
    }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        presentations.append(.init(phase: phaseBegan, complete: completion))
    }
    func finish() { presentations.last?.complete() }
}

final class FinalLightSessionTests: XCTestCase {
    private func defaults() throws -> UserDefaults {
        let suite = "Starfall.FinalLight.\(UUID())"
        let value = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { value.removePersistentDomain(forName: suite) }
        return value
    }

    @MainActor private func make(_ game: FallingSky? = nil, fixture: ConstellationFixture? = nil,
                                 tutorial: SkyTutorial? = nil)
    throws -> (FallingSkyStore, FinalLightPresenter, ManualRainClock, UserDefaults) {
        let saved = try defaults()
        if let game { try SkySaveArchive.save(game, to: saved) }
        let presenter = FinalLightPresenter(), clock = ManualRainClock()
        let arguments = fixture.map { ["--starfalls-reset", "--constellation-fixture=\($0.rawValue)"] } ?? []
        let store = FallingSkyStore(defaults: saved, arguments: arguments, presenter: presenter,
                                    clock: clock, tutorial: tutorial)
        store.setSuspended(false)
        return (store, presenter, clock, saved)
    }

    @MainActor private func exchange(_ from: Cell, _ to: Cell, in store: FallingSkyStore) throws -> FallingSkyTurn {
        let before = store.game
        var expected = before
        let turn = try XCTUnwrap(expected.nudge(from: from, to: to))
        XCTAssertTrue(store.performTechnique(.nudge(from, to), snapshot: before,
                                             generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        return turn
    }

    @MainActor func testWinningFinalPhaseIsCapturedBeforeCallbacksAndSurvivesTerminalCleanupButNotColdRestore() throws {
        let (store, presenter, clock, saved) = try make(.freshChallenge(.silverPools))
        defer { store.setSuspended(true) }
        let opening = store.game
        XCTAssertNil(store.finalLight)
        let turn = try exchange(Cell(1,2), Cell(1,3), in: store)
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertNil(store.celebration, "No animation phase callback has run")
        let signature = try XCTUnwrap(store.finalLight)
        let final = try XCTUnwrap(turn.resolutionPhases.last)
        XCTAssertEqual(signature.paths, final.recipes.map(\.presentationPath))
        XCTAssertEqual(Set(signature.cells), final.cleared)
        XCTAssertNil(clock.deadline)
        let committed = store.game, bytes = saved.data(forKey: SkySaveArchive.key)
        let world = saved.data(forKey: WorldJourneyStore.key)
        let late = try XCTUnwrap(presenter.presentations.last)
        store.settlePresentation(reason: "terminal")
        late.phase(0); late.phase(1); late.complete()
        XCTAssertEqual(store.finalLight, signature)
        XCTAssertNil(store.celebration)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(saved.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(saved.data(forKey: WorldJourneyStore.key), world)
        let restored = FallingSkyStore(defaults: saved, arguments: [], presenter: FinalLightPresenter(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, committed)
        XCTAssertNil(restored.finalLight)
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, opening)
        XCTAssertNil(store.finalLight)
        late.phase(1); late.complete()
        XCTAssertNil(store.finalLight)
    }

    @MainActor func testManualGapRevisitsAndDrainedSelectedStarsKeepTheExactWalk() throws {
        let branch = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,3), Cell(0,4), Cell(1,5), Cell(1,6)]
        let cases: [(ConstellationFixture, [Cell])] = [
            (.singleGap, [0,1,2,3,5].map { Cell(0,$0) }), (.overlap, branch), (.darkness, branch)
        ]
        for (fixture, path) in cases {
            let (store, presenter, _, _) = try make(fixture: fixture)
            defer { store.setSuspended(true) }
            let before = store.game
            store.clearTracedConstellation(path, snapshot: before, generation: store.constellationInputGeneration)
            let signature = try XCTUnwrap(store.finalLight)
            XCTAssertEqual(signature.paths, [path])
            XCTAssertEqual(Set(signature.cells), Set(path))
            XCTAssertEqual(signature.cells.count, Set(path).count)
            if fixture == .darkness {
                XCTAssertTrue(path.contains { before.isDrained(at: $0) })
                XCTAssertTrue(signature.cells.allSatisfy { before.gem(at: $0)?.isDark == false })
            }
            presenter.finish()
            store.cancelCelebration()
            XCTAssertEqual(store.finalLight, signature)
        }
    }

    @MainActor func testNoAwardSetupAndLaterFullSkyLossKeepTheLastEarnedFigure() throws {
        let (store, presenter, clock, saved) = try make(fixture: .diagonalSix)
        defer { store.setSuspended(true) }
        let path = (0..<5).map { Cell($0,$0) }
        store.clearTracedConstellation(path, snapshot: store.game, generation: store.constellationInputGeneration)
        presenter.finish()
        let signature = try XCTUnwrap(store.finalLight)
        let index = try XCTUnwrap(store.game.board.firstIndex { $0 != nil })
        let from = Cell(index / 7, index % 7), to = Cell(index / 7, index % 7 == 6 ? 5 : index % 7 + 1)
        let setup = try exchange(from, to, in: store)
        XCTAssertEqual(setup.collected, 0)
        presenter.finish()
        XCTAssertEqual(store.finalLight, signature)
        for _ in 0..<100 where !store.game.isOver {
            let before = store.game
            var expected = before
            let rain = try XCTUnwrap(expected.letStarsFall())
            XCTAssertEqual(rain.collected, 0)
            store.callShower()
            XCTAssertEqual(store.game, expected)
            presenter.finish()
            XCTAssertEqual(store.finalLight, signature)
        }
        XCTAssertEqual(store.game.outcome, .lost)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(saved.data(forKey: SkySaveArchive.key))), store.game)
        store.setSuspended(true)
        XCTAssertEqual(store.finalLight, signature, "Loss carries last earned light, never the overflowing arrivals")
    }

    @MainActor func testPositiveNonshapeTapRemovesAnEarlierDrawingInsteadOfMislabelingIt() throws {
        let (store, presenter, _, _) = try make(fixture: .diagonalSix)
        defer { store.setSuspended(true) }
        store.clearTracedConstellation((0..<5).map { Cell($0,$0) }, snapshot: store.game,
                                      generation: store.constellationInputGeneration)
        presenter.finish()
        XCTAssertNotNil(store.finalLight)
        let group = try XCTUnwrap(store.game.legalGroups.first { store.game.recipe(matching: Set($0)) == nil })
        let before = store.game
        store.clear(try XCTUnwrap(group.first))
        XCTAssertGreaterThan(store.game.displayScore, before.displayScore)
        XCTAssertNotNil(store.celebration)
        XCTAssertNil(store.finalLight)
        presenter.finish()
        XCTAssertNil(store.finalLight)
    }

    @MainActor func testEverySimultaneousFinalRecipeSurvivesWithoutJoiningPathsOrApplyingTheManualBudget() throws {
        let (practice, presenter, _, _) = try make(tutorial: .fullBoardImmediate)
        defer { practice.setSuspended(true) }
        let turn = try exchange(Cell(1,1), Cell(2,1), in: practice)
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        XCTAssertEqual(phase.recipes.count, 2)
        XCTAssertEqual(practice.finalLight?.paths, phase.recipes.map(\.presentationPath))
        XCTAssertEqual(practice.finalLight?.paths.count, 2)
        presenter.finish()

        // Geometry/resource fixture through the unchanged resolver, not a claim
        // that an all-Aqua board is a reachable authored Story opening.
        let board = (0..<49).map { Optional(StarfallGem(id: $0, kind: .aqua)) }
        let phases = SkyRecipeResolution.resolve(board, lineLength: 4)
        let dense = try XCTUnwrap(phases.last)
        let session = SkyLightReceiptSession()
        let source = FallingSky(board: board, incoming: [.init(id: 49, kind: .rose, column: 0)])
        let denseTurn = FallingSkyTurn(resolutionPhases: phases, cleared: [], collected: dense.award.baseLight,
            settled: dense.settled, forecast: [], arrivals: [], blockedColumn: nil)
        session.capture(denseTurn, from: source, to: source, path: [], recipe: nil)
        let all = try XCTUnwrap(session.lastEarned)
        XCTAssertEqual(all.paths, dense.recipes.map(\.presentationPath))
        XCTAssertEqual(all.paths.count, 75)
        XCTAssertEqual(all.paths.flatMap { $0 }.count, 478)
        XCTAssertEqual(all.cells.count, 49)
        XCTAssertEqual(all.identity, .colored(.aqua))
    }

    @MainActor func testManualWalkLimitUsesProductionValidationAndDoesNotCollapseRevisits() throws {
        let source = ConstellationFixture.singleGap.game().adoptingFeedingDusk()
        let repeated = Array(repeating: [Cell(0,1), Cell(0,0)], count: 96).flatMap { $0 }
        let path = repeated + [Cell(0,1), Cell(0,2), Cell(0,3), Cell(0,5)]
        XCTAssertEqual(path.count, ConstellationReturnLayout.maximumWalkEntries)
        var game = source
        let turn = try XCTUnwrap(game.clearConstellation(path))
        let session = SkyLightReceiptSession()
        session.capture(turn, from: source, to: game, path: path, recipe: nil)
        XCTAssertEqual(session.lastEarned?.paths, [path])
        XCTAssertEqual(session.lastEarned?.cells.count, 5)
        session.capture(turn, from: source, to: game, path: path + [Cell(0,3)], recipe: nil)
        XCTAssertNil(session.lastEarned, "A positive transaction with an invalid supplied walk cannot reuse old geometry")
    }

    @MainActor func testPracticeRoundGenerationResetsOnRetryAndChapterChangeWithoutWritingTheRetainedRoundOrWorld() throws {
        let saved = try defaults(), retained = FallingSky.fullBoardRibbon()
        try SkySaveArchive.save(retained, to: saved)
        try WorldJourneyStore(defaults: saved).select(.firstLight)
        let bytes = saved.data(forKey: SkySaveArchive.key), world = saved.data(forKey: WorldJourneyStore.key)
        let presenter = FinalLightPresenter(), clock = ManualRainClock()
        var writes = 0
        let practice = FallingSkyStore(defaults: saved, arguments: [], presenter: presenter, clock: clock,
            tutorial: .trace, archiveWriter: { _, _ in writes += 1 })
        practice.setSuspended(false)
        defer { practice.setSuspended(true) }
        func draw() throws -> SkyFinalLightReceipt {
            practice.clearTracedConstellation((0..<5).map { Cell(0,$0) }, snapshot: practice.game,
                                             generation: practice.constellationInputGeneration)
            return try XCTUnwrap(practice.finalLight)
        }
        let first = try draw(), late = try XCTUnwrap(presenter.presentations.last)
        XCTAssertTrue(try XCTUnwrap(practice.tutorial).complete)
        practice.loadTutorial(.trace)
        XCTAssertNil(practice.finalLight)
        let second = try draw()
        XCTAssertEqual(second.roundGeneration, first.roundGeneration + 1)
        XCTAssertNotEqual(second.id, first.id)
        late.phase(0); late.complete()
        XCTAssertEqual(practice.finalLight, second)
        practice.loadTutorial(.gap)
        XCTAssertNil(practice.finalLight)
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(saved.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(saved.data(forKey: WorldJourneyStore.key), world)
        XCTAssertNil(clock.deadline)
        let restored = FallingSkyStore(defaults: saved, arguments: [], presenter: FinalLightPresenter(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, retained)
        XCTAssertNil(restored.finalLight)
    }

    @MainActor func testChallengeAndDebugFixtureReplacementAdvanceGenerationButRoutineSettlementDoesNot() throws {
        let (store, presenter, _, _) = try make(.freshChallenge(.firstLight))
        defer { store.setSuspended(true) }
        _ = try exchange(Cell(1,1), Cell(1,2), in: store)
        let initial = try XCTUnwrap(store.finalLight)
        store.settlePresentation()
        store.setReducedMotion(true)
        XCTAssertEqual(store.finalLight, initial)
        store.startChallenge(.ribbonCrossing)
        XCTAssertNil(store.finalLight)
        _ = try exchange(Cell(1,1), Cell(1,2), in: store)
        let next = try XCTUnwrap(store.finalLight)
        XCTAssertEqual(next.roundGeneration, initial.roundGeneration + 1)
        presenter.finish()
        store.loadConstellationFixture(.singleGap)
        XCTAssertNil(store.finalLight)
        let path = [0,1,2,3,5].map { Cell(0,$0) }
        store.clearTracedConstellation(path, snapshot: store.game, generation: store.constellationInputGeneration)
        XCTAssertEqual(store.finalLight?.roundGeneration, next.roundGeneration + 1)
        store.loadGravityFixture(.opportunity)
        XCTAssertNil(store.finalLight)
    }

    @MainActor func testLiveReceiptExpiryLeavesTheEarnedRecordAndNewRoundRetiresBoth() async throws {
        let source = FallingSky.freshChallenge(.firstLight)
        var game = source
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
        let session = SkyLightReceiptSession()
        session.capture(turn, from: source, to: game, path: [], recipe: nil)
        let retained = try XCTUnwrap(session.lastEarned)
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        session.publish(.init(id: session.nextSequence(), phase: phase,
            cumulativeAward: turn.displayAward, total: game.displayScore))
        XCTAssertNotNil(session.current)
        let deadline = ContinuousClock.now + .seconds(3)
        while session.current != nil && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertNil(session.current)
        XCTAssertEqual(session.lastEarned, retained)
        session.beginRound()
        XCTAssertNil(session.current); XCTAssertNil(session.lastEarned)
        XCTAssertEqual(session.roundGeneration, retained.roundGeneration + 1)
    }
}
