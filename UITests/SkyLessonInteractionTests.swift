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
        app.skyMenuControl("experiment.help").tap()
        return app
    }
    @MainActor private func press(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id]
        for _ in 0..<8 where !button.isHittable { app.swipeUp() }
        // A partly exposed lazy row can be hittable while its tap lands outside
        // the visible sheet. Bring the whole target into the viewport first.
        app.revealSkyControls([button])
        XCTAssertTrue(button.isHittable); XCTAssertTrue(button.isEnabled)
        // Accessibility frames subtract floating-point coordinates; preserve the 44-point requirement.
        XCTAssertGreaterThanOrEqual(button.frame.height,44 - 1e-9, id)
        button.tap()
    }
    @MainActor private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor func testEveryExampleUsesExplicitMovesAndReturnsToUnchangedRound() {
        let app = openHelp(); defer { app.terminate() }
        for (lesson, gains) in [("square",[0,4]),("cross",[5]),("opal",[3]),("relay",[4,8])] {
            press(app,"lesson.open."+lesson)
            XCTAssertEqual(app.staticTexts["lesson.score"].label,"0 starlight in this example")
            // Lesson content can register before its animated navigation toolbar
            // accepts input. Wait for that readiness without suppressing motion.
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.buttons["experiment.done"].isHittable
            }, object: nil).wait(timeout: 5))
            capture(lesson+"-before")
            for score in gains {
                press(app,"lesson.advance")
                XCTAssertEqual(app.staticTexts["lesson.score"].label,"\(score) starlight in this example")
                capture(lesson+"-score-\(score)")
            }
            XCTAssertFalse(app.buttons["lesson.advance"].exists)
            press(app,"lesson.retry")
            XCTAssertEqual(app.staticTexts["lesson.score"].label,"0 starlight in this example")
            app.navigationBars.buttons["How to play"].tap()
        }
        app.buttons["experiment.done"].tap()
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
        press(app,"lesson.open.square")
        capture("square-largest-before")
        press(app,"lesson.advance")
        XCTAssertEqual(app.staticTexts["lesson.score"].label,"0 starlight in this example")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout:5))
        press(app,"lesson.advance")
        XCTAssertEqual(app.staticTexts["lesson.score"].label,"4 starlight in this example")
        capture("square-largest-complete")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
    }
}
