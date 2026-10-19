import XCTest

final class PacingCueUITests: XCTestCase {
    @MainActor private func countdown(calm: Bool) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset","--observatory-review","-calmEffects",calm ? "YES":"NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:10))
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.balance").tap()
        app.buttons["experiment.pace"].tap(); app.buttons["Gentle · 6 seconds"].tap()
        app.buttons["experiment.done"].tap()
        let board = app.otherElements["experiment.board"], original = board.value as? String
        let forecast = app.descendants(matching:.any)["experiment.arrivalCue"].firstMatch
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","Shower approaching"),object:forecast).wait(timeout:5.5))
        XCTAssertEqual(board.value as? String,original,"The cue must approach before the shower commits")
        capture(app,"countdown-approaching-\(calm ? "quiet" : "normal")")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value != %@",original!),object:board).wait(timeout:3))
        app.buttons["experiment.pause"].tap()
    }

    @MainActor func testQuietForecastApproachesBeforeTheShower() { countdown(calm:true) }
    @MainActor func testNormalForecastApproachesBeforeTheShower() { countdown(calm:false) }
    @MainActor func testSystemReduceMotionForecastApproachesBeforeTheShower() {
        let (preferences, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(true,on:motion); preferences.terminate()
        addTeardownBlock { @MainActor in
            let (preferences,motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original,on:motion); preferences.terminate()
        }
        countdown(calm:false)
    }

    override func setUpWithError() throws {
        // Sixteen native shower actions plus system Settings setup/restoration.
        executionTimeAllowance = 240
    }

    @MainActor private func launch(largest: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
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
        let cue = app.descendants(matching: .any)["experiment.message"].firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "experiment.message").count, 1)
        XCTAssertTrue(cue.label.contains(label), cue.label)
        XCTAssertTrue(cue.isHittable, "Cue must remain visible while lower controls are used")
        XCTAssertGreaterThanOrEqual(cue.frame.minY, 0)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
    }
    @MainActor private func flow(largest: Bool, reduced: Bool) throws {
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
        cue(app, "Showers get faster after the next shower.")
        if !largest { XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, initialCellFrame,
            "Cue changes must not resize the scene and settle a falling shower") }
        if !largest {
            let legal = app.buttons.matching(NSPredicate(format:
                "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
                "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
            XCTAssertTrue(legal.isHittable, "Resized board must retain native touch mapping")
            legal.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"),
                object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            cue(app, "Showers get faster after the next shower.")
        }
        capture(app, "pacing-warning-\(largest ? "largest" : "normal")-\(reduced ? "reduced" : "motion")")
        let menu = app.buttons["experiment.settings"]
        for _ in 0..<5 where !menu.isHittable { app.swipeDown() }
        XCTAssertTrue(menu.isHittable); menu.tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
            object: app.descendants(matching: .any)["experiment.message"].firstMatch).wait(timeout: 5))
        app.buttons["experiment.done"].tap()
        cue(app, "Showers get faster after the next shower.")
        advance(app)
        cue(app, "Showers are closer together now.")
        for _ in 1...2 { advance(app); cue(app, "Showers are closer together now.") }
        advance(app)
        cue(app, "More time between showers now.")
        if !largest { XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, initialCellFrame) }
        capture(app, "pacing-breathing-\(largest ? "largest" : "normal")-\(reduced ? "reduced" : "motion")")
        for _ in 1...3 { advance(app) }
        XCTAssertFalse(app.descendants(matching: .any)["sky.cadence"].firstMatch.exists)
    }
    @MainActor func testNormalMotionWarningFasterBreathing() throws { try flow(largest: false, reduced: false) }
    @MainActor func testLargestTextKeepsCueVisibleWithControls() throws { try flow(largest: true, reduced: false) }
    @MainActor func testSystemReduceMotionKeepsLabels() throws { try flow(largest: false, reduced: true) }
    @MainActor func testActiveForecastAndPhaseCueKeepSeparateSpace() throws {
        let app = launch(); defer { app.terminate() }
        for _ in 1...9 { advance(app) }
        cue(app, "Showers get faster after the next shower.")
        let cellFrame = app.buttons["experiment.cell.0.0"].frame
        app.buttons["experiment.pause"].tap()
        let forecast = app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch
        XCTAssertTrue(forecast.waitForExistence(timeout: 5))
        XCTAssertTrue(forecast.isHittable)
        XCTAssertFalse((forecast.value as? String ?? "").isEmpty)
        let phase = app.descendants(matching: .any)["experiment.message"].firstMatch
        XCTAssertTrue(phase.exists)
        XCTAssertGreaterThanOrEqual(phase.frame.minY, app.buttons["experiment.cell.0.0"].frame.maxY)
        XCTAssertEqual(forecast.frame.midY, app.buttons["experiment.settings"].frame.midY, accuracy: 1,
                       "The fallback forecast stays in the compact header")
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, cellFrame)
        capture(app, "pacing-active-forecast-and-phase")
    }
    @MainActor func testLargestClearUsesVisibleNativeCells() throws {
        let app = launch(largest: true); defer { app.terminate() }
        for _ in 1...9 { advance(app) }
        cue(app, "Showers get faster after the next shower.")
        let candidates = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
            "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match"))
        XCTAssertGreaterThan(candidates.count, 0, "The committed sky must retain a legal clear")
        var visible = candidates.allElementsBoundByIndex.filter { $0.isHittable }
        // Density text adds scrollable content below the board. Return to the
        // board as a player would; the timing cue must stay visible throughout.
        for _ in 0..<5 where visible.isEmpty {
            app.swipeDown()
            cue(app, "Showers get faster after the next shower.")
            visible = candidates.allElementsBoundByIndex.filter { $0.isHittable }
        }
        XCTAssertFalse(visible.isEmpty, "The scrolled board must offer a visible native clear")
        let target = try XCTUnwrap(visible.first)
        target.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"),
            object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        cue(app, "Showers get faster after the next shower.")
        capture(app, "pacing-largest-native-clear")
    }
}
