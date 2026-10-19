import XCTest

final class SkyLessonInteractionTests: XCTestCase {
    @MainActor private func openHelp(large: Bool = false, calm: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=64", "-calmEffects", calm ? "YES" : "NO"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:10))
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("sky.learn").tap()
        return app
    }
    @MainActor private func press(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id]
        if id.hasPrefix("tutorial.chapter.") { app.revealSkyMenuElement(button) }
        // A partly exposed lazy row can be hittable while its tap lands outside
        // the visible sheet. Bring the whole target into the viewport first.
        app.revealSkyControls([button])
        XCTAssertTrue(button.isHittable); XCTAssertTrue(button.isEnabled)
        // Accessibility frames subtract floating-point coordinates; preserve the 44-point requirement.
        if !id.hasPrefix("experiment.cell.") { XCTAssertGreaterThanOrEqual(button.frame.height,44 - 1e-9, id) }
        button.tap()
    }
    @MainActor private func swapSquare(_ app: XCUIApplication) {
        let from = app.buttons["experiment.cell.1.2"], to = app.buttons["experiment.cell.1.1"]
        app.revealSkyControls([from,to])
        from.coordinate(withNormalizedOffset: .init(dx:0.5,dy:0.5)).press(forDuration:0.05,
            thenDragTo:to.coordinate(withNormalizedOffset:.init(dx:0.5,dy:0.5)), withVelocity:.slow, thenHoldForDuration:0.1)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@ AND enabled == true","Aqua"),object:to).wait(timeout:5))
    }
    @MainActor private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor func testEveryExampleUsesExplicitMovesAndReturnsToUnchangedRound() {
        executionTimeAllowance = 240
        let app = openHelp(); defer { app.terminate() }
        for (lesson, gains) in [("square",[0,4]),("cross",[5]),("opal",[3]),("relay",[4,8])] {
            press(app,"tutorial.chapter."+lesson)
            XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
            // Lesson content can register before its animated navigation toolbar
            // accepts input. Wait for that readiness without suppressing motion.
            XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
            capture(lesson+"-before")
            for score in gains {
                if lesson == "square", score == 0 { swapSquare(app) }
                else { press(app, lesson == "cross" ? "experiment.cell.1.1" : lesson == "relay" && score == 8 ? "experiment.cell.0.1" : "experiment.cell.0.0") }
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(score) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
                capture(lesson+"-score-\(score)")
            }
            XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Chapter complete")
            press(app,"tutorial.retry")
            XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
            press(app,"experiment.settings")
        }
        press(app,"tutorial.done")
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String,"0 showers, 0 matching groups ready")
        app.buttons["experiment.next"].tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value != %@","0 showers, 0 matching groups ready"),object:app.otherElements["experiment.board"]).wait(timeout:5))
    }
    @MainActor func testSystemReduceMotionExamplesKeepTheSameOutcomes() {
        let (preferences, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: motion); preferences.terminate()
        addTeardownBlock { @MainActor in
            let (preferences, motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: motion); preferences.terminate()
        }
        testEveryExampleUsesExplicitMovesAndReturnsToUnchangedRound()
    }
    @MainActor func testLargestTextQuietExampleSurvivesBackgroundAndDismissal() {
        let app = openHelp(large:true,calm:true); defer { app.terminate() }
        press(app,"tutorial.chapter.square")
        capture("square-largest-before")
        swapSquare(app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
        press(app,"experiment.cell.0.0")
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"4 starlight")
        capture("square-largest-complete")
        press(app,"experiment.settings"); press(app,"tutorial.done")
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
    }
}
