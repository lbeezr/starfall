extension StarfallExperimentStoreTests {
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
