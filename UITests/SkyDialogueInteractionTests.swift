import XCTest

final class SkyDialogueInteractionTests: XCTestCase {
    @MainActor private func launch(large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--observatory-review", "-calmEffects", "NO"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        for _ in 0..<6 where !element.isHittable { if up { app.swipeUp() } else { app.swipeDown() } }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor private func revealText(_ text: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        func visible() -> Bool {
            let frame = text.frame
            let top = app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : app.frame.minY
            return !frame.isEmpty && frame.minY >= top && frame.maxY <= app.frame.maxY
        }
        for _ in 0..<6 where !visible() { app.swipeUp() }
        XCTAssertTrue(visible(), "The complete noninteractive message must fit in the visible viewport")
    }

    @MainActor func testBundledScriptSwitchesAllSpeakersAndKeepsPausedRound() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        let before = board.value as? String
        let text = app.staticTexts["experiment.message"]
        XCTAssertTrue(text.label.hasPrefix("Sunny."))
        XCTAssertGreaterThan(text.frame.minY, app.buttons["experiment.cell.0.0"].frame.maxY)
        capture(app, "dialogue-paused")
        app.buttons["experiment.settings"].tap()
        XCTAssertFalse(app.staticTexts["experiment.message"].exists,
                       "The gameplay message must leave the accessibility tree under a modal")
        XCTAssertEqual(app.buttons.matching(identifier: "experiment.pause").count, 1,
                       "Only the menu's pause control may be exposed")
        let studio = app.buttons["dialogue.studio.open"]
        reveal(studio, in: app); studio.tap()
        XCTAssertTrue(app.staticTexts["experiment.message"].waitForExistence(timeout: 5))
        capture(app, "dialogue-studio-open")
        for speaker in ["Sunny", "Spark", "Pip", "Twinkle", "Nova", "Dusk"] {
            let message = app.staticTexts["experiment.message"]
            revealText(message, in: app)
            XCTAssertTrue(message.label.hasPrefix(speaker + "."), message.label)
            XCTAssertEqual(app.staticTexts.matching(identifier: "experiment.message").count, 1)
            capture(app, "dialogue-" + speaker.lowercased())
            if speaker != "Dusk" { app.buttons["sky.dialogue.next"].tap() }
        }
        app.buttons["sky.dialogue.close"].tap()
        XCTAssertFalse(app.staticTexts["experiment.message"].exists)
        let reopen = app.buttons["sky.dialogue.reopen"]
        XCTAssertGreaterThanOrEqual(reopen.frame.width, 44)
        reopen.tap()
        XCTAssertTrue(app.staticTexts["experiment.message"].label.hasPrefix("Dusk."))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(board.waitForExistence(timeout: 5)); XCTAssertEqual(board.value as? String, before)
        app.buttons["experiment.next"].tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                               object: app.buttons["experiment.next"]).wait(timeout: 5))
        let committed = board.value as? String
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(board.value as? String, committed)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: app.buttons["experiment.next"]).wait(timeout: 5))
    }

    @MainActor func testLargestTextChatReflowsBelowBoardAndPreviewRemainsUsable() {
        let app = launch(large: true); defer { app.terminate() }
        let message = app.staticTexts["experiment.message"]
        XCTAssertGreaterThanOrEqual(message.frame.minY, app.buttons["experiment.cell.0.0"].frame.maxY)
        revealText(message, in: app)
        XCTAssertTrue(message.label.hasPrefix("Sunny."))
        let next = app.buttons["experiment.next"]
        reveal(next, in: app)
        XCTAssertGreaterThanOrEqual(next.frame.height, 44)
        capture(app, "dialogue-largest-text")
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        let menu = app.buttons["experiment.settings"]
        reveal(menu, in: app, up: false); menu.tap()
        let studio = app.buttons["dialogue.studio.open"]
        reveal(studio, in: app); studio.tap()
        reveal(app.buttons["sky.dialogue.next"], in: app)
        app.buttons["sky.dialogue.next"].tap()
        revealText(app.staticTexts["experiment.message"], in: app)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.hasPrefix("Spark."))
        capture(app, "dialogue-largest-text-spark")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
    }

    @MainActor func testNormalMotionForecastCompletesSeveralAutomaticCycles() {
        continueAfterFailure = false
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: toggle)
            settings.terminate()
        }
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--starfalls-seed=5", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        app.buttons["experiment.pause"].tap()
        let board = app.otherElements["experiment.board"]
        func showers() -> Int { Int((board.value as? String ?? "").split(separator: " ").first ?? "") ?? -1 }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in showers() >= 4 }, object: nil).wait(timeout: 12))
        capture(app, "dialogue-motion-first-regular-cycle")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in showers() >= 9 }, object: nil).wait(timeout: 25))
        XCTAssertTrue(app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch.exists)
        capture(app, "dialogue-motion-several-cycles")
        app.buttons["experiment.settings"].tap()
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        capture(app, "dialogue-motion-paused")
    }

    @MainActor func testActiveMessageCanBeReopenedWithoutStoppingAutomaticShowers() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(message.waitForExistence(timeout: 3))
        capture(app, "dialogue-active")
        let reopen = app.buttons["sky.dialogue.reopen"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 10))
        let board = app.otherElements["experiment.board"]
        let before = board.value as? String
        reopen.tap()
        XCTAssertTrue(message.waitForExistence(timeout: 3))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value != %@", before ?? ""), object: board).wait(timeout: 8))
        app.buttons["experiment.settings"].tap()
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        capture(app, "dialogue-return-to-paused")
    }
}
