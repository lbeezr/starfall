final class SupernovaLabInteractionTests: XCTestCase {
    @MainActor private func launchFixture() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.starfall.supernovalab")
        app.launchArguments = ["--starfalls-reset", "--supernova-fixture"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.4"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func score(_ app: XCUIApplication) -> String {
        app.staticTexts["experiment.score"].label
    }

    @MainActor private func waitForScoreChange(_ before: String, _ app: XCUIApplication) {
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", before),
            object: app.staticTexts["experiment.score"])
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
    }

    @MainActor func testLabNativeHoldReleaseAndOrdinaryTapProduceDifferentSurvivors() {
        let app = launchFixture(); defer { app.terminate() }
        let before = score(app)
        app.buttons["experiment.cell.0.4"].tap()
        waitForScoreChange(before, app)
        let ordinary = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).allElementsBoundByIndex.map { $0.label }
        app.terminate(); app.launch()
        app.buttons["experiment.cell.0.4"].press(forDuration: 0.9)
        waitForScoreChange(before, app)
        let charged = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).allElementsBoundByIndex.map { $0.label }
        XCTAssertNotEqual(ordinary, charged, "Charge transforms actual character identities")
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "supernova-lab-after-charge"; screenshot.lifetime = .keepAlways; add(screenshot)
    }

    @MainActor func testLabDragAwayCancelsWithoutFallingBackToTap() {
        let app = launchFixture(); defer { app.terminate() }
        let before = score(app)
        let cell = app.buttons["experiment.cell.0.4"]
        cell.press(forDuration: 0.9, thenDragTo: app.buttons["experiment.cell.2.4"])
        XCTAssertEqual(score(app), before)
        XCTAssertTrue(app.staticTexts["lab.chargeStatus"].label.contains("Hold five"))
    }

    @MainActor func testLabAutomaticShowerInvalidatesHeldIntent() {
        let app = launchFixture(); defer { app.terminate() }
        let before = score(app)
        app.buttons["experiment.pause"].tap()
        app.buttons["experiment.cell.0.4"].press(forDuration: 4.6)
        XCTAssertEqual(score(app), before, "Releasing after a shower cannot clear a new board")
        XCTAssertTrue(app.staticTexts["lab.chargeStatus"].label.contains("Hold five"))
        XCTAssertNotEqual(app.staticTexts["experiment.turns"].label, "9 showers")
    }

    @MainActor func testLabRapidTapsCommitOnlyOneClear() {
        let app = launchFixture(); defer { app.terminate() }
        app.buttons["experiment.cell.0.4"].doubleTap()
        XCTAssertEqual(score(app), "22 starlight")
    }
}
