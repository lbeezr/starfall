final class BurstShowerPhaseTests: XCTestCase {
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
            let legal = app.buttons.matching(NSPredicate(format: "value MATCHES %@",
                "([3-9]|[1-9][0-9]+) starlight connected")).allElementsBoundByIndex
            let canonical = legal.sorted {
                let lhs = $0.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
                let rhs = $1.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
                return lhs.lexicographicallyPrecedes(rhs)
            }.first
            canonical?.tap()
        }
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.label, "Recovery · 9 calmer showers")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(cue.label, "Recovery · 9 calmer showers")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "Recovery · 9 calmer showers")
    }
}
