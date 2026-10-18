/// Captures normal restore of the hosted bridge's committed lab save; no gesture claim.
final class TraceChoiceCaptureTests: XCTestCase {
    @MainActor func testCaptureStagedBoard() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Fixture observation is simulator-only")
        #else
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        let score = environment["STARFALL_CHOICE_SCORE"] ?? environment["TEST_RUNNER_STARFALL_CHOICE_SCORE"] ?? "__INITIAL_SCORE__"
        let app = XCUIApplication(bundleIdentifier: "com.starfall.constellations.candidate")
        app.terminate(); app.launchArguments = []; app.launch()
        addTeardownBlock { @MainActor in app.terminate() }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(score) starlight"),
                                               object: app.staticTexts["experiment.score"]).wait(timeout: 6))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Selected-choice-native-board"; screenshot.lifetime = .keepAlways; add(screenshot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Selected-choice-native-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        #endif
    }
}
