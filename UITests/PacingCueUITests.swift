import XCTest

final class PacingCueUITests: XCTestCase {
    // Exporter changes only this marker; normal production has no B launch route.
    static let isCandidateExport = false

    @MainActor private func launch(_ policy: String = "B", largest: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5", "--pacing-policy=\(policy)"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<5 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }
    @MainActor private func advance(_ app: XCUIApplication) {
        let next = app.buttons["experiment.next"]
        reveal(next, app: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor private func cue(_ app: XCUIApplication, _ label: String) {
        let cue = app.descendants(matching: .any)["sky.cadence"].firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "sky.cadence").count, 1)
        XCTAssertEqual(cue.label, label)
        XCTAssertTrue(cue.isHittable, "Cue must remain visible while lower controls are used")
        XCTAssertGreaterThanOrEqual(cue.frame.minY, 0)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
    }
    @MainActor private func flow(largest: Bool, reduced: Bool) throws {
        guard Self.isCandidateExport else { throw XCTSkip("B is available only in the explicit candidate export") }
        let (preferences, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(reduced, on: motion)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (preferences, motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: motion)
            preferences.terminate()
        }
        let app = launch(largest: largest); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        reveal(calm, app: app)
        if calm.value as? String == "1" { calm.coordinate(withNormalizedOffset: .init(dx: 0.9, dy: 0.5)).tap() }
        app.buttons["experiment.done"].tap()
        XCTAssertFalse(app.descendants(matching: .any)["sky.cadence"].firstMatch.exists)
        let initialCellFrame = app.buttons["experiment.cell.0.0"].frame
        for _ in 1...9 { advance(app) }
        cue(app, "Faster after next shower")
        if !largest { XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, initialCellFrame,
            "Cue changes must not resize the scene and settle a falling shower") }
        if !largest {
            let legal = app.buttons.matching(NSPredicate(format:
                "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
                "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
            XCTAssertTrue(legal.isHittable, "Resized board must retain native touch mapping")
            legal.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"),
                object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            cue(app, "Faster after next shower")
        }
        capture(app, "pacing-warning-\(largest ? "largest" : "normal")-\(reduced ? "reduced" : "motion")")
        let menu = app.buttons["experiment.settings"]
        for _ in 0..<5 where !menu.isHittable { app.swipeDown() }
        XCTAssertTrue(menu.isHittable); menu.tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
            object: app.descendants(matching: .any)["sky.cadence"].firstMatch).wait(timeout: 5))
        app.buttons["experiment.done"].tap()
        cue(app, "Faster after next shower")
        advance(app)
        cue(app, "Faster passage. Showers are closer together")
        for _ in 1...2 { advance(app); cue(app, "Faster passage. Showers are closer together") }
        advance(app)
        cue(app, "Breathing window. More time between showers")
        if !largest { XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, initialCellFrame) }
        capture(app, "pacing-breathing-\(largest ? "largest" : "normal")-\(reduced ? "reduced" : "motion")")
        for _ in 1...3 { advance(app) }
        XCTAssertFalse(app.descendants(matching: .any)["sky.cadence"].firstMatch.exists)
    }
    @MainActor func testNormalMotionWarningFasterBreathing() throws { try flow(largest: false, reduced: false) }
    @MainActor func testLargestTextKeepsCueVisibleWithControls() throws { try flow(largest: true, reduced: false) }
    @MainActor func testSystemReduceMotionKeepsLabels() throws { try flow(largest: false, reduced: true) }
    @MainActor func testBaselineHasNoPhaseCue() {
        let app = launch("A"); defer { app.terminate() }
        for _ in 1...13 { advance(app) }
        XCTAssertFalse(app.descendants(matching: .any)["sky.cadence"].firstMatch.exists)
    }
    @MainActor func testActiveCandidateForecastAndPhaseCueKeepSeparateSpace() throws {
        guard Self.isCandidateExport else { throw XCTSkip("Requires the explicit candidate export") }
        let app = launch(); defer { app.terminate() }
        for _ in 1...9 { advance(app) }
        cue(app, "Faster after next shower")
        let cellFrame = app.buttons["experiment.cell.0.0"].frame
        app.buttons["experiment.pause"].tap()
        let forecast = app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch
        XCTAssertTrue(forecast.waitForExistence(timeout: 5))
        XCTAssertTrue(forecast.isHittable)
        XCTAssertFalse((forecast.value as? String ?? "").isEmpty)
        let phase = app.descendants(matching: .any)["sky.cadence"].firstMatch
        XCTAssertTrue(phase.exists)
        XCTAssertLessThanOrEqual(phase.frame.maxY, forecast.frame.minY)
        XCTAssertEqual(forecast.frame.midY, app.buttons["experiment.settings"].frame.midY, accuracy: 1,
                       "B's reserved cue slot uses the conservative header forecast")
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, cellFrame)
        capture(app, "pacing-active-forecast-and-phase")
    }
    @MainActor func testLargestCandidateClearUsesVisibleNativeCells() throws {
        guard Self.isCandidateExport else { throw XCTSkip("Requires the explicit candidate export") }
        let app = launch(largest: true); defer { app.terminate() }
        for _ in 1...9 { advance(app) }
        cue(app, "Faster after next shower")
        let candidates = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
            "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected"))
        let visible = candidates.allElementsBoundByIndex.filter { $0.isHittable }
        XCTAssertFalse(visible.isEmpty, "The scrolled board must offer a visible native clear")
        let target = try XCTUnwrap(visible.first)
        target.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"),
            object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        cue(app, "Faster after next shower")
        capture(app, "pacing-largest-native-clear")
    }
}
