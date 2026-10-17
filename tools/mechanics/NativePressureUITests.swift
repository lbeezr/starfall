final class PressureShowerDecisionTests: XCTestCase {
    @MainActor func testSeedFiveColdOpeningMatchesCoreReplay() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.starfall.pressureshowerslab")
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch(); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        var choices = 0
        for shower in 1...20 {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            let count = Int(app.staticTexts["experiment.matches"].label.split(separator: " ").first ?? "0") ?? 0
            if shower == 1 { XCTAssertEqual(count, 1) }
            if count > 1 { choices += 1 }
            let legal = app.buttons.matching(NSPredicate(format: "value MATCHES %@", "([3-9]|[1-9][0-9]+) starlight connected")).allElementsBoundByIndex
            // Match the core sampler's canonical row/column order.
            let canonical = legal.sorted {
                let lhs = $0.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
                let rhs = $1.identifier.split(separator: ".").suffix(2).compactMap { Int($0) }
                return lhs.lexicographicallyPrecedes(rhs)
            }.first
            canonical?.tap()
        }
        XCTAssertEqual(choices, __COLD_CHOICES__, "Preserve this observed opening limitation in the native replay")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "__COLD_SCORE__ starlight"),
            object: app.staticTexts["experiment.score"])], timeout: 5), .completed)
    }

    @MainActor private func play(_ cell: String, expectedScore: String, expectLoss: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.starfall.pressureshowerslab")
        app.launchArguments = ["--starfalls-reset", "--shower-decision-fixture"]
        app.launch(); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        app.buttons[cell].tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedScore),
            object: app.staticTexts["experiment.score"])], timeout: 5), .completed,
            "The intended legal clear must actually commit before testing the shower")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = expectLoss ? "pressure-other-clear" : "pressure-tall-column-clear"
        capture.lifetime = .keepAlways; add(capture)
        next.tap()
        let outcome = app.staticTexts["experiment.outcome"]
        if expectLoss {
            XCTAssertTrue(outcome.waitForExistence(timeout: 5))
            XCTAssertEqual(outcome.label, "This sky is full")
        } else {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            XCTAssertFalse(outcome.exists)
        }
    }
    @MainActor func testTallColumnClearSurvivesAnnouncedShower() {
        play("experiment.cell.__safeCell_row__.__safeCell_column__", expectedScore: "__SAFE_SCORE__ starlight", expectLoss: false)
    }
    @MainActor func testOtherLegalClearOverflowsOnSameAnnouncedShower() {
        play("experiment.cell.__unsafeCell_row__.__unsafeCell_column__", expectedScore: "__UNSAFE_SCORE__ starlight", expectLoss: true)
    }
}
