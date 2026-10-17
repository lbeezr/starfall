extension StarfallExperimentStoreTests {
    @MainActor func testBurstArrivalInterruptionsPreserveCommitAndRejectStaleCallbacks() throws {
        // Entering the event and leaving its last shower exercise opposite
        // forecast boundaries. Interrupt before presentation completes.
        for completed in [9, 11] {
            for interruption in ["background", "pause", "motion"] {
                let suite = "BurstArrival.\(UUID())"
                let defaults = UserDefaults(suiteName: suite)!
                defer { defaults.removePersistentDomain(forName: suite) }
                let clock = ManualRainClock(), presenter = ExperimentRecorder()
                let store = StarfallExperimentStore(defaults: defaults,
                    arguments: ["--starfalls-reset", "--shower-phase-fixture"], presenter: presenter, clock: clock)
                store.setSuspended(false)
                while store.game.turns < completed {
                    store.callShower(); presenter.finish()
                    if let cell = store.game.legalGroups.first?.first {
                        store.clear(cell); presenter.finish()
                    }
                }
                let announced = store.forecast
                store.togglePause()
                let oldDeadline = try XCTUnwrap(clock.action)
                clock.advance(4)
                let oldCompletion = try XCTUnwrap(presenter.completions.last)
                let committed = store.game
                XCTAssertEqual(committed.turns, completed + 1)
                XCTAssertFalse(committed.isOver)
                XCTAssertTrue(store.busy)
                XCTAssertEqual(store.forecast, announced)
                XCTAssertFalse(try XCTUnwrap(store.pending).arrivals.isEmpty)
                switch interruption {
                case "background": store.setSuspended(true)
                case "pause": store.togglePause()
                default: store.setReducedMotion(true)
                }
                XCTAssertFalse(store.busy)
                XCTAssertNil(store.pending)
                XCTAssertEqual(store.game, committed)
                XCTAssertEqual(store.forecast, committed.incoming)
                oldDeadline(); oldCompletion()
                XCTAssertEqual(store.game, committed)
                XCTAssertFalse(store.busy)
                let restored = StarfallExperimentStore(defaults: defaults, arguments: [],
                    presenter: ExperimentRecorder(), clock: ManualRainClock())
                XCTAssertEqual(restored.game, committed)
                XCTAssertEqual(restored.forecast, committed.incoming)
                XCTAssertTrue(restored.isPaused)
                if interruption != "motion" {
                    clock.advance(100)
                    XCTAssertEqual(store.game, committed)
                    if interruption == "background" { store.setSuspended(false) }
                    else { store.togglePause() }
                }
                clock.advance(3.9)
                XCTAssertEqual(store.game, committed, "No catch-up or early event shower")
                var expected = committed
                expected.letStarsFall()
                clock.advance(0.1)
                XCTAssertEqual(store.game, expected)
                XCTAssertTrue(store.busy)
                oldDeadline(); oldCompletion()
                XCTAssertEqual(store.game, expected)
                XCTAssertTrue(store.busy, "Stale completion cannot finish a newer arrival")
                presenter.finish()
                XCTAssertFalse(store.busy)
                XCTAssertTrue(store.game.isValidSave)
                store.setSuspended(true)
            }
        }
    }

    @MainActor func testDueBurstShowerRejectsRepeatedInputDuringClearAndArrival() throws {
        for completed in [9, 11] {
            let suite = "BurstInput.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let clock = ManualRainClock(), presenter = ExperimentRecorder()
            let store = StarfallExperimentStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--shower-phase-fixture"], presenter: presenter, clock: clock)
            store.setSuspended(false)
            while store.game.turns < completed {
                store.callShower(); presenter.finish()
                if store.game.turns < completed, let cell = store.game.legalGroups.first?.first {
                    store.clear(cell); presenter.finish()
                }
            }
            let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
            let forecast = store.game.incoming
            store.togglePause(); clock.advance(3.9)
            store.clear(cell)
            XCTAssertTrue(store.busy)
            XCTAssertEqual(store.game.incoming, forecast, "A clear cannot rewrite the event forecast")
            let cleared = store.game
            clock.advance(0.1)
            for _ in 0..<5 { store.callShower(); store.clear(cell) }
            XCTAssertEqual(store.game, cleared, "Repeated input cannot preempt due rain during a clear")
            var expected = cleared
            expected.letStarsFall()
            presenter.finish()
            XCTAssertEqual(store.game, expected)
            XCTAssertEqual(store.forecast, forecast, "The arriving shower retains its announced forecast")
            for _ in 0..<5 { store.callShower(); store.clear(cell) }
            XCTAssertEqual(store.game, expected, "Repeated input cannot commit another event shower during arrival")
            presenter.finish()
            XCTAssertEqual(store.game.turns, completed + 1)
            XCTAssertEqual(store.forecast, store.game.incoming)
            XCTAssertTrue(store.game.isValidSave)
            store.setSuspended(true); clock.advance(100); presenter.finish()
            XCTAssertEqual(store.game, expected)
        }
    }

    @MainActor func testBurstAutomaticAndManualForecastsAgreeAcrossSuspensionAndRestore() throws {
        let suites = ["BurstAuto.\(UUID())", "BurstManual.\(UUID())"]
        let defaults = suites.map { UserDefaults(suiteName: $0)! }
        defer { for (suite, value) in zip(suites, defaults) { value.removePersistentDomain(forName: suite) } }
        let clocks = [ManualRainClock(), ManualRainClock()]
        let presenters = [ExperimentRecorder(), ExperimentRecorder()]
        let stores = (0..<2).map { index in
            StarfallExperimentStore(defaults: defaults[index],
                arguments: ["--starfalls-reset", "--shower-phase-fixture"],
                presenter: presenters[index], clock: clocks[index])
        }
        stores.forEach { $0.setSuspended(false) }
        stores[0].togglePause()
        for turn in 9...12 {
            clocks[0].advance(4)
            stores[1].callShower()
            XCTAssertEqual(stores[0].game, stores[1].game)
            XCTAssertEqual(stores[0].game.turns, turn)
            XCTAssertFalse(stores[0].game.isOver)
__BURST_STORE_CHECK__
            XCTAssertEqual(stores[0].pending?.forecast, stores[1].pending?.forecast)
            presenters.forEach { $0.finish() }
            for index in 0..<2 {
                if let cell = stores[index].game.legalGroups.first?.first {
                    stores[index].clear(cell); presenters[index].finish()
                }
            }
            let before = stores[0].game
            stores[0].setSuspended(true); clocks[0].advance(100)
            XCTAssertEqual(stores[0].game, before)
            stores[0].setSuspended(false)
            let restored = StarfallExperimentStore(defaults: defaults[0], arguments: [],
                presenter: ExperimentRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, before)
            XCTAssertTrue(restored.isPaused)
        }
        XCTAssertEqual(StarfallExperiment.showerPhase(for: stores[0].game.turns + 1), .preparation(remaining: 9))
        stores[0].restart(sameSky: true); presenters[0].finish(); clocks[0].advance(100)
        XCTAssertEqual(stores[0].game.turns, 0)
    }
}
