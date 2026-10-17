/// Native presentation checks for the existing committed-message boundary.
final class ObservatoryFeedbackTests: XCTestCase {
    @MainActor func testPausedGrowthClearInterruptionAndQuietActivePlay() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        addTeardownBlock { @MainActor in app.terminate() }
        app.launch()
        let guide = app.staticTexts["experiment.message"]
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        XCTAssertTrue(guide.label.contains("Sky paused"))
        let next = app.buttons["experiment.next"]
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label CONTAINS %@", "grew"), object: guide).wait(timeout: 5))
        XCTAssertTrue(guide.label.contains("worth 2"))
        let clear = app.buttons["experiment.cell.0.0"]
        XCTAssertEqual(clear.value as? String, "4 starlight connected")
        clear.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label BEGINSWITH %@", "+4 starlight."), object: guide).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "23 starlight")
        let summary = guide.label
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Paused-committed-clear-feedback"; image.lifetime = .keepAlways; add(image)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5)); XCTAssertEqual(guide.label, summary)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(guide.label, summary)
        let resume = app.buttons["experiment.pause"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true"), object: resume).wait(timeout: 5),
            "Foreground input resumes only after store suspension clears")
        resume.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == false"), object: guide).wait(timeout: 5), "Flowing play stays quiet")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        XCTAssertTrue(guide.label.contains("Your sky is paused"))
        XCTAssertFalse(guide.label.contains("+4"), "Transient outcome text is not saved")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "23 starlight")
    }
}

extension ObservatoryFeedbackTests {
    @MainActor func testLargestTextKeepsGrowthFeedbackAndManualActionReachable() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        addTeardownBlock { @MainActor in app.terminate() }
        app.launch()
        let guide = app.staticTexts["experiment.message"]
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        let next = app.buttons["experiment.next"]
        for _ in 0..<8 where !next.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(next.isHittable); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label CONTAINS %@", "grew"), object: guide).wait(timeout: 5))
        XCTAssertLessThan(guide.frame.height, app.frame.height, "The outcome remains readable without shrinking text")
        for _ in 0..<8 where !next.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(next.isHittable)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Paused-growth-feedback-largest-text"; image.lifetime = .keepAlways; add(image)
    }
}

extension ObservatoryFeedbackTests {
    @MainActor func testOpeningInvalidTapAndFirstLightKeepTheirOwnGuidance() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        addTeardownBlock { @MainActor in app.terminate() }
        app.launch()
        let guide = app.staticTexts["experiment.message"]
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        let empty = app.buttons["experiment.cell.6.6"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true"), object: empty).wait(timeout: 5))
        XCTAssertTrue(empty.label.hasPrefix("Empty")); empty.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label CONTAINS %@", "Large stars count as 2"), object: guide).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers,") == true)
        app.buttons["experiment.settings"].tap()
        let challenge = app.buttons["experiment.challenge"]
        XCTAssertTrue(challenge.waitForExistence(timeout: 5)); challenge.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label CONTAINS %@", "Collect 18 starlight"), object: guide).wait(timeout: 5))
    }
}
