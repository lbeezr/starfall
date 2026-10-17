extension StarfallExperimentStoreTests {
    @MainActor func testPressureChoiceMattersWhenAutomaticRainBecomesDueDuringClear() {
        for (cell, loses) in [(Cell(__safeCell_row__, __safeCell_column__), false),
                              (Cell(__unsafeCell_row__, __unsafeCell_column__), true)] {
            let suite = "PressureDeadline.\(UUID())"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let presenter = ExperimentRecorder(), clock = ManualRainClock()
            let store = StarfallExperimentStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--shower-decision-fixture"], presenter: presenter, clock: clock)
            store.setSuspended(false); store.togglePause()
            clock.advance(3.9)
            store.clear(cell)
            XCTAssertTrue(store.busy)
            let afterClear = store.game
            clock.advance(0.1)
            XCTAssertEqual(store.game, afterClear, "Rain waits for the committed clear's presentation")
            if let other = store.game.legalGroups.first?.first { store.clear(other) }
            XCTAssertEqual(store.game, afterClear, "A second clear cannot preempt due rain")
            presenter.finish()
            XCTAssertEqual(store.game.turns, afterClear.turns + 1)
            XCTAssertEqual(store.game.isOver, loses)
            XCTAssertTrue(store.game.isValidSave)
        }
    }
}
