import XCTest

final class PacingCueUITests: XCTestCase {
    @MainActor private func countdown(calm: Bool, systemReduced: Bool = false) {
        continueAfterFailure = false
        let (preferences, motion) = NativeSystemMotionSettings.open()
        let originalMotion = motion.value as? String == "1"
        NativeSystemMotionSettings.set(systemReduced, on: motion)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (preferences, motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(originalMotion, on: motion)
            preferences.terminate()
        }
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset","--observatory-review","-calmEffects",calm ? "YES":"NO"]
        app.launch(); defer { app.terminate() }
        let variant = systemReduced ? "system-reduced" : (calm ? "quiet" : "normal")
        // Read the complete native facts only while paused, so diagnostics do not
        // consume the running interval before the approaching-shower assertion.
        let attachPausedState: (String) -> Void = { stage in
            let cue = try? app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch.snapshot()
            let forecast = try? app.descendants(matching: .any)["sky.forecast.destinations"].firstMatch.snapshot()
            let board = try? app.otherElements["experiment.board"].snapshot()
            let state = XCTAttachment(string: """
                stage=\(stage)
                calmEffects=\(calm)
                systemReduceMotion=\(systemReduced)
                cue.label=\(cue?.label ?? "<unavailable>")
                cue.value=\(String(describing: cue?.value))
                forecast.value=\(String(describing: forecast?.value))
                board.value=\(String(describing: board?.value))
                """)
            state.name = "countdown-\(stage)-\(variant)-state"
            state.lifetime = .keepAlways
            self.add(state)
        }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:10))
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.balance").tap()
        let gentle = app.buttons["experiment.pace.gentle"]
        app.revealSkyControls([gentle])
        gentle.tap()
        app.buttons["experiment.done"].tap()
        let board = app.otherElements["experiment.board"], original = board.value as? String
        capture(app, "countdown-initial-paused-\(variant)")
        attachPausedState("initial-paused")
        app.buttons["experiment.pause"].tap()
        capture(app, "countdown-running-\(variant)")
        app.waitForApproachingShower(timeout: 5.5)
        XCTAssertEqual(board.value as? String,original,"The cue must approach before the shower commits")
        capture(app,"countdown-approaching-\(variant)")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value != %@",original!),object:board).wait(timeout:3))
        capture(app, "countdown-committed-\(variant)")
        // Compact running skies expose pause through the menu, not the guide.
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !app.buttons["experiment.done"].exists && app.buttons["experiment.pause"].label == "Resume sky"
        }, object: nil).wait(timeout: 5))
        capture(app, "countdown-paused-after-modal-\(variant)")
        attachPausedState("paused-after-modal")
    }

    @MainActor func testQuietForecastApproachesBeforeTheShower() { countdown(calm:true) }
    @MainActor func testNormalForecastApproachesBeforeTheShower() { countdown(calm:false) }
    @MainActor func testSystemReduceMotionForecastApproachesBeforeTheShower() {
        countdown(calm:false, systemReduced:true)
    }

    @MainActor override func setUpWithError() throws {
        try super.setUpWithError()
        XCUIDevice.shared.orientation = .portrait
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
        app.revealSkyControls([element])
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
    @MainActor private func clearMatch(_ app: XCUIApplication) throws {
        let candidates = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
            "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match"))
        let targetID = try XCTUnwrap(candidates.allElementsBoundByIndex.first?.identifier)
        let target = app.buttons[targetID]
        let board = app.otherElements["experiment.board"]
        let committed = board.value as? String
        let score = app.staticTexts["experiment.score"].label
        app.revealSkyControls([target])
        XCTAssertEqual(board.value as? String, committed, "Revealing a native cell cannot play a move")
        target.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["experiment.score"].label != score
        }, object: nil).wait(timeout: 5))
        XCTAssertEqual((board.value as? String)?.split(separator: " ").first,
                       committed?.split(separator: " ").first, "Clears cannot advance the cadence")
    }
    @MainActor private func cue(_ app: XCUIApplication, _ label: String) {
        let cue = app.descendants(matching: .any)["experiment.message"].firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "experiment.message").count, 1)
        XCTAssertTrue(cue.label.contains(label), cue.label)
        app.readSkyGuideToEnd(actions: [app.buttons["experiment.pause"], app.buttons["experiment.next"]])
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
        app.skyMenuControl("experiment.preferences").tap()
        let calm = app.switches["experiment.calm"]
        app.revealSkyMenuElement(calm)
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
        app.revealSkyControls([menu])
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
        // Keep playing while the cadence returns to steady; an idle full column
        // correctly ends the current survival rules before this timing sample ends.
        for _ in 1...3 { try clearMatch(app); advance(app) }
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String ?? "").hasPrefix("16 showers,"))
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
        let header = app.otherElements["sky.header"]
        if forecast.frame.height < 40 {
            XCTAssertTrue(header.frame.contains(forecast.frame), "Fallback forecast stays inside the header")
            XCTAssertFalse(forecast.frame.intersects(app.buttons["experiment.settings"].frame),
                           "The compact forecast and menu have separate space, whether on one row or two")
        } else {
            XCTAssertEqual(forecast.frame.width, 148, accuracy: 1)
            XCTAssertEqual(forecast.frame.height, 50, accuracy: 1)
            XCTAssertLessThanOrEqual(forecast.frame.maxY, header.frame.minY,
                                     "A calibrated island forecast stays above the header")
        }
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].frame, cellFrame)
        capture(app, "pacing-active-forecast-and-phase")
    }
    @MainActor func testLargestClearUsesVisibleNativeCells() throws {
        let app = launch(largest: true); defer { app.terminate() }
        for _ in 1...9 { advance(app) }
        cue(app, "Showers get faster after the next shower.")
        // The current accessible layout flows the guide below the board. Read it,
        // then return to a fully visible native cell without changing the sky.
        try clearMatch(app)
        cue(app, "Showers get faster after the next shower.")
        capture(app, "pacing-largest-native-clear")
    }
}
