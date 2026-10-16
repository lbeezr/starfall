import XCTest

final class StarfallExperimentInteractionTests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls", "--starfalls-reset", "--starfalls-seed=5"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func showers(_ app: XCUIApplication) -> Int {
        Int(app.staticTexts["experiment.turns"].label.split(separator: " ")[0])!
    }
    @MainActor private func waitForShowers(_ count: Int, in app: XCUIApplication, timeout: TimeInterval = 12) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) >= count }, object: nil).wait(timeout: timeout))
    }
    @MainActor private func remainsPaused(_ app: XCUIApplication) {
        let initial = showers(app)
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) != initial }, object: nil)
        changed.isInverted = true
        XCTAssertTrue(changed.wait(timeout: 5))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
    }

    @MainActor func testAutomaticRainPauseGrowthClearReplayAndSettings() {
        let app = launch(); defer { app.terminate() }
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let initialPreview = app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label
        XCTAssertFalse(initialPreview.contains("column"))
        XCTAssertFalse(initialPreview.isEmpty)
        capture(app, "automatic-empty-preview")
        app.buttons["experiment.pause"].tap()
        waitForShowers(2, in: app)
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        app.buttons["experiment.pause"].tap()
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 40))
        // Snapshot while paused, then test rapid input early in a fresh interval.
        // XCTest hierarchy/screenshot work can otherwise consume the entire clear window.
        waitForShowers(showers(app) + 1, in: app)
        app.buttons["experiment.pause"].tap()
        let clearID = legal.identifier
        capture(app, "automatic-matchable")
        app.buttons["experiment.pause"].tap()
        app.buttons[clearID].doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        app.buttons["experiment.pause"].tap()
        capture(app, "automatic-after-clear-paused")
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        if calm.value as? String != "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let beforeCalm = showers(app)
        app.buttons["experiment.pause"].tap()
        waitForShowers(beforeCalm + 1, in: app)
        app.buttons["experiment.pause"].tap()
        capture(app, "automatic-calm-after-dismissal")
        let replay = app.buttons["experiment.replay"]
        reveal(replay, in: app); replay.tap()
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Start sky")
        XCTAssertEqual(app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label, initialPreview)
    }

    @MainActor func testBackgroundRelaunchAndAutomaticOverflow() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        waitForShowers(1, in: app)
        let before = showers(app)
        XCUIDevice.shared.press(.home)
        // Wait through more than a whole shower interval with the app suspended.
        let background = XCTNSPredicateExpectation(predicate: NSPredicate(value: false), object: nil)
        background.isInverted = true
        XCTAssertTrue(background.wait(timeout: 6))
        app.activate()
        XCTAssertLessThanOrEqual(showers(app), before + 1, "No catch-up burst on return")
        app.buttons["experiment.pause"].tap()
        let saved = showers(app)
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(showers(app), saved)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        app.buttons["experiment.pause"].tap()
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 120))
        XCTAssertFalse(app.buttons["experiment.pause"].isEnabled)
        capture(app, "automatic-overflow")
        let newSky = app.buttons["experiment.new"]
        reveal(newSky, in: app); newSky.tap()
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Start sky")
    }

    @MainActor func testDarkStarInfluenceRestoreAndAdjacentClear() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        if calm.value as? String == "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        app.buttons["experiment.pause"].tap()
        waitForShowers(6, in: app, timeout: 35)
        app.buttons["experiment.pause"].tap()
        let dark = app.buttons["experiment.cell.1.1"]
        let beside = app.buttons["experiment.cell.0.1"]
        XCTAssertTrue(dark.label.hasPrefix("Dark star"))
        XCTAssertTrue(beside.label.contains("growth blocked by a dark star"))
        XCTAssertEqual(beside.value as? String, "3 starlight connected")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Large ")).count > 0)
        for star in app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.incoming.")).allElementsBoundByIndex {
            XCTAssertFalse(star.label.contains("column"))
        }
        capture(app, "dark-star-and-shaded-neighbors")
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        XCTAssertTrue(dark.label.hasPrefix("Dark star"))
        XCTAssertTrue(beside.label.contains("growth blocked by a dark star"))
        app.buttons["experiment.pause"].tap()
        beside.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 3))
        app.buttons["experiment.pause"].tap()
        XCTAssertFalse(dark.label.hasPrefix("Dark star"))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "growth blocked by a dark star")).count, 0)
        capture(app, "dark-star-dissolved-by-adjacent-clear")
    }

    @MainActor func testBalanceControlsPreserveBoardPersistAndChangeArrivals() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        waitForShowers(1, in: app)
        app.buttons["experiment.pause"].tap()
        let occupied = app.buttons["experiment.cell.0.0"].label
        app.buttons["experiment.settings"].tap()
        let pace = app.buttons["experiment.pace"], frequency = app.buttons["experiment.darkFrequency"]
        XCTAssertTrue(pace.waitForExistence(timeout: 5))
        pace.tap(); app.buttons["Gentle · 6s"].tap()
        frequency.tap(); app.buttons["Frequent"].tap()
        XCTAssertTrue(app.staticTexts["experiment.balanceDetail"].label.contains("2–3 showers"))
        capture(app, "balance-gentle-frequent-settings")
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(showers(app), 1)
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].label, occupied)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let replay = app.buttons["experiment.replay"]
        reveal(replay, in: app); replay.tap()
        app.buttons["experiment.pause"].tap()
        let tooSoon = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) > 0 }, object: nil)
        tooSoon.isInverted = true
        XCTAssertTrue(tooSoon.wait(timeout: 4.5), "Gentle pace does not use the old four-second deadline")
        waitForShowers(3, in: app, timeout: 20)
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count > 0)
        capture(app, "balance-frequent-dark-star-shower-three")
        app.terminate(); app.launchArguments = ["--starfalls"]; app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Gentle"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Frequent"))
        app.buttons["experiment.resetBalance"].tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Steady"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Regular"))
        pace.tap(); app.buttons["Brisk · 3s"].tap()
        frequency.tap(); app.buttons["None"].tap()
        app.buttons["experiment.done"].tap()
        reveal(replay, in: app); replay.tap()
        app.buttons["experiment.pause"].tap()
        waitForShowers(4, in: app, timeout: 16)
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count, 0)
        capture(app, "balance-brisk-no-dark-stars")
    }
}

private extension XCTNSPredicateExpectation {
    func wait(timeout: TimeInterval) -> Bool { XCTWaiter.wait(for: [self], timeout: timeout) == .completed }
}
