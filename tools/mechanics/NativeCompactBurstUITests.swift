final class CompactBurstPhaseTests: XCTestCase {
    @MainActor func testCompactWarningSurgeRecoveryAndRestore() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        app.launch(); defer { app.terminate() }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(board.exists)
        XCTAssertTrue((board.value as? String)?.hasPrefix("8 showers,") == true)
        XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@", "experiment.incoming.")).count, 0,
            "The phase must work without restoring the forecast strip")
        let initialScore = app.staticTexts["experiment.score"].label
        let next = app.buttons["experiment.next"]
        for remaining in stride(from: 3, through: 0, by: -1) {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            let expected = remaining == 0 ? "Recovery · 9 calmer showers" : "__BURST_COUNT__"
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", expected), object: cue)], timeout: 5), .completed)
            XCTAssertTrue((board.value as? String)?.hasPrefix("\(12 - remaining) showers,") == true)
            XCTAssertLessThanOrEqual(cue.frame.maxY, board.frame.minY,
                "Phase information stays outside the active board")
            clearCanonicalBurstGroup(in: app)
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Recovery · 8 calmer showers"), object: cue)], timeout: 5), .completed)
        XCTAssertTrue((board.value as? String)?.hasPrefix("13 showers,") == true)
        let score = app.staticTexts["experiment.score"].label
        XCTAssertNotEqual(score, initialScore, "Native cell taps must still clear real groups")
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "compact-recovery"; capture.lifetime = .keepAlways; add(capture)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
    }

    @MainActor func testCompactLargestTextKeepsPhaseAboveReachableControls() {
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
        XCTAssertTrue(cue.isHittable)
        XCTAssertGreaterThanOrEqual(cue.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "__BURST_THREE__"), object: cue)], timeout: 5), .completed)
        XCTAssertTrue(cue.isHittable)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "compact-largest-text-phase"; capture.lifetime = .keepAlways; add(capture)
    }
}
