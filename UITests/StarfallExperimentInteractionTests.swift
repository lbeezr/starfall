import XCTest

final class StarfallExperimentInteractionTests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls", "--starfalls-reset", "--starfalls-seed=5"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.invite"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func ready(_ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["experiment.invite"])
            .wait(timeout: 6))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
    }

    @MainActor func testPreviewGrowthClearReplayAndSettings() {
        let app = launch(); defer { app.terminate() }
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "0 showers")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let initialPreview = app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label
        XCTAssertTrue(initialPreview.contains("column"))
        capture(app, "starfalls-empty-preview")
        app.buttons["experiment.cell.0.0"].tap()
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "0 showers")
        app.buttons["experiment.invite"].doubleTap()
        ready(app)
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "1 showers")
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        for _ in 0..<10 {
            if legal.exists { break }
            app.buttons["experiment.invite"].tap(); ready(app)
        }
        XCTAssertTrue(legal.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "value 2")).firstMatch.exists)
        capture(app, "starfalls-grown-and-matchable")
        legal.tap(); ready(app)
        XCTAssertNotEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        capture(app, "starfalls-after-clear")
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists, "Settings must hide the underlying board from accessibility navigation")
        if calm.value as? String != "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.invite"].waitForExistence(timeout: 5))
        ready(app)
        let beforeCalm = Int(app.staticTexts["experiment.turns"].label.split(separator: " ")[0])!
        app.buttons["experiment.invite"].doubleTap(); ready(app)
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "\(beforeCalm + 1) showers")
        capture(app, "starfalls-calm-after-dismissal")
        let replay = app.buttons["experiment.replay"]
        reveal(replay, in: app); replay.tap()
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "0 showers")
        XCTAssertEqual(app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label, initialPreview)
    }

    @MainActor func testBackgroundRelaunchAndOverflow() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.invite"].tap(); ready(app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "1 showers")
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.invite"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "1 showers")
        let outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<25 {
            if outcome.exists { break }
            app.buttons["experiment.invite"].tap()
            let settled = NSPredicate(format: "enabled == true OR exists == false")
            if !outcome.waitForExistence(timeout: 1.3) {
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: settled, object: app.buttons["experiment.invite"]).wait(timeout: 5))
            }
        }
        XCTAssertTrue(outcome.exists); XCTAssertFalse(app.buttons["experiment.invite"].isEnabled)
        capture(app, "starfalls-overflow")
        let newSky = app.buttons["experiment.new"]
        reveal(newSky, in: app); newSky.tap()
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "0 showers")
    }
}

private extension XCTNSPredicateExpectation {
    func wait(timeout: TimeInterval) -> Bool { XCTWaiter.wait(for: [self], timeout: timeout) == .completed }
}
