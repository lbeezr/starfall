extension StarfallExperimentStoreTests {
    @MainActor private func makeChargeStore() -> (StarfallExperimentStore, ExperimentRecorder, ManualRainClock) {
        let suite = "SupernovaTests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        let presenter = ExperimentRecorder(), clock = ManualRainClock()
        let store = StarfallExperimentStore(defaults: defaults,
            arguments: ["--starfalls-reset", "--supernova-fixture"], presenter: presenter, clock: clock)
        store.setSuspended(false)
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return (store, presenter, clock)
    }

    @MainActor func testLabChargeCommitsOnlyOnReleaseAndOnlyOnce() {
        let (store, _, _) = makeChargeStore()
        let before = store.game
        let ticket = store.prepareCharge(Cell(0, 4)); store.armCharge(ticket)
        XCTAssertEqual(store.chargeCell, Cell(0, 4)); XCTAssertEqual(store.game, before)
        var expected = before
        expected.clear(Cell(0, 4), charged: true)
        store.commitCharge(ticket)
        XCTAssertEqual(store.game, expected)
        XCTAssertNil(store.chargeCell)
        store.commitCharge(ticket); XCTAssertEqual(store.game, expected)
    }

    @MainActor func testLabCancellationAndUntimedAlternative() {
        let (store, _, _) = makeChargeStore()
        let before = store.game
        let ticket = store.prepareCharge(Cell(0, 4)); store.armCharge(ticket); store.cancelCharge(); store.commitCharge(ticket)
        XCTAssertEqual(store.game, before)
        var expected = before
        expected.clear(Cell(0, 4), charged: true)
        store.accessibleCharge(Cell(0, 4))
        XCTAssertEqual(store.game, expected)
    }

    @MainActor func testLabStaleIntentRejectedAcrossEveryStoreInterruption() {
        let interruptions: [(StarfallExperimentStore) -> Void] = [
            { $0.restart(sameSky: true) }, { $0.restart(sameSky: false) },
            { $0.setSuspended(true) }, { $0.setReducedMotion(true) },
            { $0.setPace(.brisk) }, { $0.startFirstLight() }, { $0.togglePause() },
            { $0.settlePresentation() }, { $0.callShower() },
        ]
        for (index, interrupt) in interruptions.enumerated() {
            let (store, presenter, _) = makeChargeStore()
            let ticket = store.prepareCharge(Cell(0, 4)); store.armCharge(ticket)
            interrupt(store)
            presenter.finish()
            let committed = store.game
            store.armCharge(ticket); store.commitCharge(ticket)
            XCTAssertNil(store.chargeCell, "Interruption \(index)")
            XCTAssertEqual(store.game, committed, "Interruption \(index)")
        }
    }

    @MainActor func testLabAutomaticRainCancelsBothPendingAndArmedIntent() {
        for armed in [false, true] {
            let (store, presenter, clock) = makeChargeStore()
            store.togglePause()
            let ticket = store.prepareCharge(Cell(0, 4))
            if armed { store.armCharge(ticket) }
            clock.advance(4); presenter.finish()
            let afterRain = store.game
            store.armCharge(ticket); store.commitCharge(ticket)
            XCTAssertNil(store.chargeCell)
            XCTAssertEqual(store.game, afterRain)
        }
    }

    @MainActor func testLabOlderFingerCannotArmCancelOrCommitNewerIntent() {
        let (store, _, _) = makeChargeStore()
        let before = store.game
        let older = store.prepareCharge(Cell(0, 4))
        let newer = store.prepareCharge(Cell(0, 5))
        XCTAssertNotEqual(older, newer)
        store.armCharge(older)
        XCTAssertNil(store.chargeCell)
        store.armCharge(newer)
        XCTAssertEqual(store.chargeCell, Cell(0, 5))
        store.cancelCharge(older); store.commitCharge(older)
        XCTAssertEqual(store.chargeCell, Cell(0, 5))
        XCTAssertEqual(store.game, before)
        store.commitCharge(newer)
        var expected = before
        expected.clear(Cell(0, 5), charged: true)
        XCTAssertEqual(store.game, expected)
    }
}
