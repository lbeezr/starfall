final class BurstShowerPhaseTests: XCTestCase {

    @MainActor func testDoubleTapAtBurstWarningAndRecoveryAdvancesOneShower() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        app.launch(); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "8 showers")
        next.doubleTap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "9 showers",
            "An accidental double tap must not consume the first event shower as well")
        XCTAssertEqual(app.staticTexts["lab.phase"].label, "__BURST_THREE__")
        clearCanonicalBurstGroup(in: app)
        for shower in 10...11 {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            XCTAssertEqual(app.staticTexts["experiment.turns"].label, "\(shower) showers")
            clearCanonicalBurstGroup(in: app)
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        next.doubleTap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        XCTAssertEqual(app.staticTexts["experiment.turns"].label, "12 showers")
        XCTAssertEqual(app.staticTexts["lab.phase"].label, "Recovery · 9 calmer showers")
    }

    @MainActor func testLargestTextKeepsPhaseVisibleWhileAdvancingShower() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        let next = app.buttons["experiment.next"]
        for _ in 0..<8 where !next.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(next.isHittable)
        XCTAssertTrue(cue.isHittable, "The announced phase must stay visible while using lower controls")
        XCTAssertGreaterThanOrEqual(cue.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "__BURST_THREE__"), object: cue)], timeout: 5), .completed)
        XCTAssertTrue(cue.isHittable)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "phase-largest-text-controls"; capture.lifetime = .keepAlways; add(capture)
    }

    @MainActor func testWarningPressureRecoveryAndRestore() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        app.launch(); defer { app.terminate() }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        let next = app.buttons["experiment.next"]
        for remaining in stride(from: 3, through: 0, by: -1) {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            let expected = remaining == 0 ? "Recovery · 9 calmer showers"
                : "__BURST_COUNT__"
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", expected), object: cue)], timeout: 5), .completed)
__BURST_PREVIEW_CHECK__
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "phase-\(remaining)"; capture.lifetime = .keepAlways; add(capture)
            clearCanonicalBurstGroup(in: app)
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Recovery · 8 calmer showers"), object: cue)], timeout: 5), .completed)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
    }
}
