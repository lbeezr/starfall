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
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                                object: button).wait(timeout: 5), id)
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
            if lesson == "square" {
                XCTAssertEqual(app.staticTexts["tutorial.detail"].label,
                               "Swap the Aqua star into an exact square, then tap one of its four stars to collect it.")
            }
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
        let hint = app.buttons["tutorial.hint"], next = app.buttons["tutorial.next"]
        app.revealSkyControls([hint, next])
        assertVisible(hint, in: app)
        assertVisible(next, in: app)
        capture("square-largest-compact-actions")
        press(app,"experiment.settings"); press(app,"tutorial.done")
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
    }

    @MainActor func testGuideCoordinatesAndDisclosureMatchTheVisibleBoard() {
        let app = openHelp()
        defer { app.terminate() }
        press(app, "tutorial.chapter.match")
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Tap the star at row 7, column 1.")
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].label.contains("row 7, column 1"))
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)

        let hint = app.buttons["tutorial.hint"]
        XCTAssertEqual(hint.label, "Less")
        XCTAssertTrue(app.staticTexts["tutorial.detail"].exists)
        XCTAssertTrue(app.staticTexts["tutorial.coordinates"].label.contains("1 at the top"))
        assertVisible(hint, in: app)
        capture("tutorial-compact-actions-idle")
        let hintCenter = hint.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        hintCenter.press(forDuration: 1,
                         thenDragTo: hintCenter.withOffset(.init(dx: 0, dy: -160)),
                         withVelocity: .slow, thenHoldForDuration: 0)
        XCTAssertEqual(hint.label, "Less", "Releasing away from an action must cancel it")
        XCTAssertTrue(app.staticTexts["tutorial.detail"].exists)
        capture("tutorial-compact-actions-cancelled")
        hint.tap()
        XCTAssertEqual(hint.label, "Hint")
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCTAssertFalse(app.staticTexts["tutorial.coordinates"].exists)
        hint.tap()
        XCTAssertEqual(hint.label, "Less")
        XCTAssertTrue(app.staticTexts["tutorial.detail"].exists)
        capture("tutorial-match-disclosure-open")

        // Do not use the scroll helper: completion and progression must be
        // discoverable in the same viewport as the completed native move.
        let star = app.buttons["experiment.cell.0.0"]
        assertVisible(star, in: app)
        star.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Chapter complete"),
                                                object: app.staticTexts["tutorial.instruction"]).wait(timeout: 5))
        assertVisible(app.staticTexts["tutorial.instruction"], in: app)
        assertVisible(app.buttons["tutorial.retry"], in: app)
        assertVisible(app.buttons["tutorial.next"], in: app)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        capture("tutorial-match-complete-with-visible-progression")
        app.buttons["tutorial.next"].tap()
        XCTAssertEqual(app.staticTexts["tutorial.title"].label, "Grown stars")
        XCTAssertEqual(hint.label, "Less", "A new chapter starts with its detail visible")
        press(app, "experiment.settings")

        press(app, "tutorial.chapter.exchange")
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Swipe right from row 6, column 2.")
        XCTAssertTrue(app.buttons["experiment.cell.1.1"].label.contains("row 6, column 2"))
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        press(app, "experiment.settings")

        press(app, "tutorial.chapter.trace")
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label,
                       "Hold, then draw: 7,1 → 7,2 → 7,3 → 7,4 → 7,5. Release to collect.")
        for column in 0..<5 {
            XCTAssertTrue(app.buttons["experiment.cell.0.\(column)"].label.contains("row 7, column \(column + 1)"))
        }
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        capture("tutorial-trace-top-down-coordinates")
    }

    @MainActor func testShowerLessonExposesOnlyItsCurrentControl() {
        let app = openHelp()
        defer { app.terminate() }
        let boards = app.otherElements.matching(identifier: "experiment.board")
        XCTAssertEqual(boards.count, 0, "The covered retained sky must withdraw its board accessibility summary")
        press(app, "tutorial.chapter.showers")
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].waitForExistence(timeout: 5))
        XCTAssertEqual(boards.count, 1, "Only the active practice board owns board accessibility")
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Tap Next shower.")
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        press(app, "experiment.next")
        let pause = app.buttons["experiment.pause"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND enabled == true AND hittable == true"),
                                                object: pause).wait(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        pause.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Tap Pause."),
                                                object: app.staticTexts["tutorial.instruction"]).wait(timeout: 10))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("2 showers,") == true)
        press(app, "experiment.pause")
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Tap Next shower.")
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        press(app, "experiment.next")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Chapter complete"),
                                                object: app.staticTexts["tutorial.instruction"]).wait(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("3 showers,") == true)
        capture("tutorial-showers-complete-without-unrelated-controls")
        press(app, "experiment.settings")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                object: app.staticTexts["tutorial.title"]).wait(timeout: 5))
        XCTAssertEqual(boards.count, 0, "The index must not retain the dismissed practice board")
        press(app, "tutorial.done")
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(boards.count, 1, "The retained sky regains board accessibility when practice closes")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String,
                       "0 showers, 0 matching groups ready", "Practice must leave the retained round unchanged")
    }

    @MainActor private func assertVisible(_ element: XCUIElement, in app: XCUIApplication,
                                         file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.isHittable, file: file, line: line)
        XCTAssertTrue(app.frame.insetBy(dx: -1, dy: -1).contains(element.frame),
                      "\(element.identifier) must fit in the current viewport", file: file, line: line)
    }
}
