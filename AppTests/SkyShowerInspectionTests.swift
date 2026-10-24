import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkyShowerInspectionTests: XCTestCase {
    private typealias Source = SkyForecastInspection.Source
    private typealias Harness = (store: FallingSkyStore, presenter: FallingSkyRecorder,
                                clock: ManualRainClock, feedback: SkyFeedbackRecorder, defaults: UserDefaults)

    private func source(_ game: FallingSky, generation: UInt64 = 1,
                        forecast: [IncomingStar]? = nil, arriving: Bool = false) throws -> Source {
        try XCTUnwrap(Source(game: game, generation: generation, forecast: forecast ?? game.incoming,
                             arriving: arriving))
    }

    private func inspect(_ game: FallingSky) throws -> SkyShowerInspection {
        try XCTUnwrap(SkyShowerInspection(source: source(game)))
    }

    @discardableResult private func exchange(_ from: Int, _ to: Int,
                                             in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
    }

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) throws -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        try edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    @MainActor private func make(_ game: FallingSky) throws -> Harness {
        let suite = "Starfall.ShowerInspection.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: feedback)
        store.setSuspended(false)
        if store.isPaused { store.togglePause() }
        return (store, presenter, clock, feedback, defaults)
    }

    @MainActor private func source(_ store: FallingSkyStore) throws -> Source {
        try XCTUnwrap(Source(game: store.game, generation: store.constellationInputGeneration,
                             forecast: store.forecast, arriving: store.showerCountdown.arriving))
    }

    func testFreshFrostfruitOpeningNamesFiveActualPlacementsAtTheirReceivingCells() throws {
        let game = FallingSky.freshChallenge(.frostfruitOrchard)
        let preview = try inspect(game)
        XCTAssertEqual(preview.steps.map(\.id), [0, 1, 2, 3, 4])
        XCTAssertEqual(preview.steps.map(\.star), game.incoming)
        XCTAssertEqual(preview.steps.map(\.effect), [
            .landed(Cell(4, 5), .init(id: 30, kind: .aqua)),
            .landed(Cell(6, 0), .init(id: 31, kind: .amber)),
            .landed(Cell(6, 1), .init(id: 32, kind: .aqua)),
            .landed(Cell(3, 3), .init(id: 33, kind: .mint)),
            .landed(Cell(4, 4), .init(id: 34, kind: .rose))
        ])
        XCTAssertTrue(preview.phases.isEmpty)
        XCTAssertFalse(preview.prearrivalChanges)
        XCTAssertNil(preview.blockedColumn)
        XCTAssertEqual(game.occupiedCount, 30)
        XCTAssertEqual(game.turns, 0)
    }

    func testCapPreparationChangesTheSameForecastToGrowthWithoutInventingNewBodies() throws {
        var prepared = FallingSky.freshChallenge(.frostfruitOrchard), points = prepared
        try exchange(35, 36, in: &prepared)
        try exchange(20, 19, in: &points)
        XCTAssertEqual(prepared.incoming, points.incoming)
        let preview = try inspect(prepared), alternative = try inspect(points)
        XCTAssertEqual(preview.steps.map(\.effect), [
            .landed(Cell(4, 5), .init(id: 30, kind: .aqua)),
            .grew(Cell(5, 0), .init(id: 29, kind: .amber, grown: true)),
            .grew(Cell(5, 1), .init(id: 28, kind: .aqua, grown: true)),
            .landed(Cell(3, 3), .init(id: 33, kind: .mint)),
            .landed(Cell(4, 4), .init(id: 34, kind: .rose))
        ])
        XCTAssertEqual(preview.steps[1].star.id, 1)
        XCTAssertNotEqual(preview.steps[1].id, 29, "Incoming identity differs from the existing body it grows")
        XCTAssertTrue(alternative.steps.allSatisfy { if case .landed = $0.effect { return true }; return false })
        XCTAssertTrue(preview.phases.isEmpty)
        var committed = prepared
        let turn = try XCTUnwrap(committed.letStarsFall())
        XCTAssertEqual(turn.arrivals.map { $0.gem.id }, [30, 29, 28, 33, 34])
        XCTAssertEqual(turn.arrivals.map(\.grew), [false, true, true, false, false])
        XCTAssertEqual(committed.occupiedCount, 33)
        XCTAssertEqual(prepared.occupiedCount, 30)
    }

    func testSecondShowerDistinguishesTheBlockedStarFromUnattemptedSuffixAndRealRecovery() throws {
        var prepared = FallingSky.freshChallenge(.frostfruitOrchard), untreated = prepared
        try exchange(35, 36, in: &prepared)
        try exchange(20, 19, in: &untreated)
        XCTAssertNotNil(prepared.letStarsFall())
        XCTAssertNotNil(untreated.letStarsFall())
        XCTAssertEqual(prepared.incoming, untreated.incoming)
        let fits = try inspect(prepared), blocked = try inspect(untreated)
        XCTAssertEqual(blocked.steps.map(\.id), [5, 6, 7, 8, 9])
        XCTAssertEqual(blocked.blockedColumn, 0)
        XCTAssertEqual(blocked.steps[3].effect, .blocked)
        XCTAssertEqual(blocked.steps[4].effect, .notReached)
        XCTAssertTrue(blocked.phases.isEmpty)
        XCTAssertNil(fits.blockedColumn)
        XCTAssertFalse(fits.steps.contains { $0.effect == .blocked || $0.effect == .notReached })
        var losing = untreated
        let actual = try XCTUnwrap(losing.letStarsFall())
        XCTAssertEqual(actual.arrivals.map { $0.star.id }, [5, 6, 7])
        XCTAssertEqual(losing.outcome, .lost)
        XCTAssertEqual(losing.displayScore, 5_000)
        try exchange(2, 9, in: &untreated)
        XCTAssertEqual(untreated.incoming, prepared.incoming)
        let recovered = try inspect(untreated)
        XCTAssertNil(recovered.blockedColumn)
        XCTAssertFalse(recovered.steps.contains { $0.effect == .blocked || $0.effect == .notReached })
        XCTAssertNotNil(untreated.letStarsFall())
        XCTAssertEqual(untreated.outcome, .playing)
        try exchange(3, 10, in: &untreated)
        XCTAssertEqual(untreated.displayScore, 17_000)
        XCTAssertEqual(untreated.outcome, .won)
    }

    func testRepeatedColumnArrivalsLandThenGrowThatBodyThenStackAboveIt() throws {
        // Existing Core mechanical fixture; no naturally reached history is claimed.
        let forecast = (0..<3).map { IncomingStar(id: $0, kind: .rose, column: 0) }
        let game = FallingSky(board: Array(repeating: nil, count: 49), incoming: forecast)
        XCTAssertTrue(game.isValidSave)
        let preview = try inspect(game)
        XCTAssertEqual(preview.steps.map(\.effect), [
            .landed(Cell(0, 0), .init(id: 0, kind: .rose)),
            .grew(Cell(0, 0), .init(id: 0, kind: .rose, grown: true)),
            .landed(Cell(1, 0), .init(id: 2, kind: .rose))
        ])
        XCTAssertEqual(preview.steps.map(\.id), [0, 1, 2])
        var actual = game
        XCTAssertNotNil(actual.letStarsFall())
        XCTAssertEqual(actual.occupiedCount, 2)
        XCTAssertEqual(actual.gem(at: Cell(0, 0))?.value, 2)
        XCTAssertEqual(actual.score, 0, "Growing light is not collected yet")
    }

    func testFullColumnAllowsMatchingGrowthBeforeBlockingTheNextMatchingStar() throws {
        var board = Array<StarfallGem?>(repeating: nil, count: 49)
        for row in 0..<7 { board[row * 7] = .init(id: row, kind: .mint) }
        let forecast = (0..<3).map { IncomingStar(id: $0 + 10, kind: .mint, column: 0) }
        // A labeled invariant-valid legacy position, not an injected production save.
        let game = try changed(FallingSky(board: board, incoming: forecast)) { $0["turns"] = 2 }
        XCTAssertTrue(game.isValidSave)
        let preview = try inspect(game)
        XCTAssertEqual(preview.steps.map(\.effect), [
            .grew(Cell(6, 0), .init(id: 6, kind: .mint, grown: true)), .blocked, .notReached
        ])
        XCTAssertEqual(preview.blockedColumn, 0)
        XCTAssertTrue(preview.phases.isEmpty)
    }

    func testGrowthAndEveryRecipePhaseComeFromTheSameActualWinningTransaction() throws {
        let game = try growthRecipePosition()
        XCTAssertTrue(game.isValidSave)
        let preview = try inspect(game)
        XCTAssertEqual(preview.steps.count, 5)
        XCTAssertEqual(preview.steps.filter { if case .grew = $0.effect { return true }; return false }.count, 1)
        var actual = game
        let turn = try XCTUnwrap(actual.letStarsFall())
        XCTAssertEqual(preview.phases, turn.resolutionPhases)
        XCTAssertEqual(preview.phases.count, 1)
        XCTAssertEqual(preview.phases[0].kind, .recipe)
        XCTAssertEqual(preview.phases[0].award.baseLight, 6)
        XCTAssertEqual(turn.displayAward, 7_000)
        XCTAssertEqual(actual.outcome, .won)
        XCTAssertEqual(actual.displayScore, 154_000)
        XCTAssertNotEqual(actual.incoming, game.incoming)
        XCTAssertEqual(preview.steps.map(\.star), game.incoming, "Do not expose the generated following forecast")
        XCTAssertEqual(preview.phases[0].recipes, turn.resolutionPhases[0].recipes)
    }

    func testRetainedPreludeIsDisclosedAndArrivalsUseItsActuallyChangedBoard() throws {
        for game in [DuskFixture.imminent.game(rule: .patientFeeding), CriticalMassFixture.game()] {
            XCTAssertTrue(game.isValidSave)
            let preview = try inspect(game)
            var actual = game
            let turn = try XCTUnwrap(actual.letStarsFall())
            XCTAssertFalse(turn.presentationPhases.isEmpty)
            XCTAssertNotEqual(turn.settled, game.board)
            XCTAssertTrue(preview.prearrivalChanges)
            XCTAssertEqual(preview.steps.count, turn.arrivals.count)
            for (step, arrival) in zip(preview.steps, turn.arrivals) {
                XCTAssertEqual(step.star, arrival.star)
                XCTAssertEqual(step.effect, arrival.grew ? .grew(arrival.cell, arrival.gem) : .landed(arrival.cell, arrival.gem))
            }
            XCTAssertEqual(preview.phases, turn.resolutionPhases)
        }
    }

    func testOnlyAnExactUnfinishedNextForecastCanBeEvaluatedAcrossCurrentAndRetainedRules() throws {
        let opening = FallingSky.freshChallenge(.frostfruitOrchard)
        XCTAssertNil(SkyShowerInspection(source: try source(opening, arriving: true)))
        XCTAssertNil(SkyShowerInspection(source: try source(opening, forecast: Array(opening.incoming.reversed()))))
        var altered = opening.incoming
        altered[0] = .init(id: altered[0].id, kind: .rose, column: altered[0].column)
        XCTAssertNil(SkyShowerInspection(source: try source(opening, forecast: altered)))
        let corrupt = try changed(opening) { $0["starsLanded"] = 0 }
        XCTAssertFalse(corrupt.isValidSave)
        XCTAssertNil(SkyShowerInspection(source: try source(corrupt)))
        for game in [FallingSky.freshSurvival(seed: 42), FallingSky(challenge: .frostfruitOrchard),
                     FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 3)))] {
            let preview = try inspect(game)
            XCTAssertEqual(preview.steps.map(\.star), game.incoming)
        }
        for game in [FallingSky.fullBoardLantern(), FallingSky.fullBoardRibbon(),
                     FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))] {
            XCTAssertNil(Source(game: game, generation: 1, forecast: opening.incoming, arriving: false))
        }
        var won = FallingSky.freshChallenge(.silverPools)
        try exchange(9, 10, in: &won)
        XCTAssertEqual(won.outcome, .won)
        XCTAssertNil(Source(game: won, generation: 1, forecast: won.incoming, arriving: false))
    }

    func testSnapshotMatchRetiresOnExchangeGenerationOrderArrivalOrUnavailableState() throws {
        let opening = FallingSky.freshChallenge(.frostfruitOrchard)
        let original = try source(opening), preview = try XCTUnwrap(SkyShowerInspection(source: original))
        var rearranged = opening
        try exchange(35, 36, in: &rearranged)
        XCTAssertEqual(rearranged.incoming, opening.incoming)
        XCTAssertTrue(preview.matches(original))
        XCTAssertFalse(preview.matches(nil))
        for current in [try source(rearranged), try source(opening, generation: 2),
                        try source(opening, forecast: Array(opening.incoming.reversed())),
                        try source(opening, arriving: true)] {
            XCTAssertFalse(preview.matches(current))
        }
        let repeated = try XCTUnwrap(SkyShowerInspection(source: original))
        XCTAssertNotEqual(preview.id, repeated.id)
        XCTAssertEqual(preview.steps.map(\.effect), repeated.steps.map(\.effect))
        XCTAssertEqual(preview.phases, repeated.phases)
    }

    @MainActor func testRepeatedInspectionPreservesLiveDeadlineSaveWorldAndActualSeededContinuation() throws {
        let fixture = try make(.freshChallenge(.frostfruitOrchard))
        defer { fixture.store.setSuspended(true) }
        let store = fixture.store
        fixture.clock.advance(1.25)
        let context = try source(store), game = store.game, forecast = store.forecast
        let bytes = fixture.defaults.data(forKey: SkySaveArchive.key)
        let world = fixture.defaults.data(forKey: WorldJourneyStore.key)
        let mastery = fixture.defaults.data(forKey: StoryMasteryStore.key)
        let journey = store.journey.journey, generation = store.constellationInputGeneration
        let deadline = try XCTUnwrap(fixture.clock.deadline), remainder = store.showerCountdown.remaining
        let presentations = fixture.presenter.completions.count, rendered = fixture.presenter.lastRendered
        let clears = fixture.feedback.clears, stops = fixture.feedback.stops, announcements = fixture.feedback.announcements
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = try encoder.encode(game)
        var snapshots: [SkyShowerInspection] = []
        for _ in 0..<3 { snapshots.append(try XCTUnwrap(SkyShowerInspection(source: context))) }
        XCTAssertEqual(Set(snapshots.map(\.id)).count, 3)
        XCTAssertEqual(store.game, game)
        XCTAssertEqual(try encoder.encode(store.game), encoded)
        XCTAssertEqual(store.forecast, forecast)
        XCTAssertEqual(store.journey.journey, journey)
        XCTAssertEqual(store.constellationInputGeneration, generation)
        XCTAssertEqual(fixture.clock.deadline, deadline)
        XCTAssertEqual(store.showerCountdown.remaining, remainder)
        XCTAssertEqual(fixture.presenter.completions.count, presentations)
        XCTAssertEqual(fixture.presenter.lastRendered, rendered)
        XCTAssertEqual(fixture.feedback.clears, clears)
        XCTAssertEqual(fixture.feedback.stops, stops)
        XCTAssertEqual(fixture.feedback.announcements, announcements)
        XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(fixture.defaults.data(forKey: WorldJourneyStore.key), world)
        XCTAssertEqual(fixture.defaults.data(forKey: StoryMasteryStore.key), mastery)
        XCTAssertFalse(store.constellationTracing)
        XCTAssertNil(store.bufferedInput)
        var control = try SkySaveArchive.decode(try XCTUnwrap(bytes))
        let expected = try XCTUnwrap(control.letStarsFall())
        fixture.clock.advance(deadline - fixture.clock.now)
        XCTAssertEqual(store.game, control)
        XCTAssertEqual(store.pending?.arrivals, expected.arrivals)
        XCTAssertEqual(store.pending?.resolutionPhases, snapshots[0].phases)
        XCTAssertTrue(store.showerCountdown.arriving)
        XCTAssertNil(SkyShowerInspection(source: try source(store)), "The displayed shower is already committed")
        XCTAssertFalse(snapshots[0].matches(try source(store)))
        fixture.presenter.finish()
        XCTAssertEqual(SkySaveArchive.load(from: fixture.defaults), control)
        XCTAssertEqual(store.forecast, control.incoming)
        let following = try XCTUnwrap(control.letStarsFall())
        store.callShower()
        XCTAssertEqual(store.game, control, "Preview creation cannot consume the following RNG continuation")
        XCTAssertEqual(store.pending?.arrivals, following.arrivals)
    }

    @MainActor func testRealBackgroundAndSameOpeningReplayInvalidateSnapshotWithoutReplayingIt() throws {
        let fixture = try make(.freshChallenge(.frostfruitOrchard))
        defer { fixture.store.setSuspended(true) }
        let store = fixture.store, initial = try source(store)
        let preview = try XCTUnwrap(SkyShowerInspection(source: initial))
        fixture.clock.advance(1)
        let before = store.game, bytes = fixture.defaults.data(forKey: SkySaveArchive.key)
        let remaining = store.showerCountdown.remaining
        store.setSuspended(true)
        XCTAssertFalse(preview.matches(try source(store)))
        XCTAssertNil(fixture.clock.deadline)
        fixture.clock.advance(20)
        store.setSuspended(false)
        XCTAssertEqual(store.game, before)
        XCTAssertEqual(fixture.defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(store.showerCountdown.remaining, remaining, accuracy: 0.000001)
        XCTAssertFalse(preview.matches(try source(store)))
        store.restart(sameSky: true)
        let sameOpening = store.game, firstReplay = try source(store)
        let replayPreview = try XCTUnwrap(SkyShowerInspection(source: firstReplay))
        store.restart(sameSky: true)
        XCTAssertEqual(store.game, sameOpening)
        XCTAssertFalse(replayPreview.matches(try source(store)))
        XCTAssertEqual(store.game.turns, 0)
        XCTAssertEqual(fixture.presenter.completions.count, 0)
    }

    /// Existing StoryCascadeTests fixture: valid retained revision-two accounting,
    /// not a claim that this authored position was reached through normal play.
    private func growthRecipePosition() throws -> FallingSky {
        let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 2))
        let colors: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet]
        var board = Array<StarfallGem?>(repeating: nil, count: 49), nextID = 0
        for (row, text) in ["RAAVRVR", "V..RVRV", "R..VRVR", "V..RV.."].enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                board[row * 7 + column] = .init(id: nextID, kind: colors[symbol]!)
                nextID += 1
            }
        }
        board[1]!.grown = true
        board[2]!.grown = true
        let showers = 29, delivered = definition.initialLight + definition.suppliedLight(after: 29)
        XCTAssertEqual(delivered - board.compactMap { $0 }.reduce(0) { $0 + $1.value }, 147)
        var counts = Array(repeating: 0, count: 50)
        counts[3] = 49
        var tiers: [[String: Any]] = Array(repeating: ["light": 0, "clearCounts": Array(repeating: 0, count: 50)], count: 5)
        tiers[0] = ["light": 147, "clearCounts": counts]
        return try changed(FallingSky(definition: definition)) {
            $0["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(board))
            $0["turns"] = showers
            $0["starsLanded"] = delivered
            $0["score"] = 147
            $0["incoming"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(definition.shower(number: showers + 1)))
            $0["storyScoreLedger"] = ["clearCounts": counts, "cascadeTiers": tiers]
        }
    }
}
