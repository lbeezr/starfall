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

    @MainActor private func assertPausedAfterMenuDismisses(_ app: XCUIApplication) {
        // During the modal's dismissal both copies of this stable identifier can
        // briefly exist. Wait for the menu to leave before reading the board control.
        let paused = NSPredicate { _, _ in
            let buttons = app.buttons.matching(identifier: "experiment.pause")
            return !app.buttons["experiment.done"].exists && buttons.count == 1
                && buttons.element(boundBy: 0).label == "Resume sky"
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: paused, object: nil).wait(timeout: 5))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
    }

    @MainActor private func changePauseFromMenu(_ app: XCUIApplication, expectedTitle: String) {
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            done.exists && done.isHittable && app.frame.contains(done.frame)
        }, object: nil).wait(timeout: 5), "The menu must finish presenting before its action is tapped")
        let action = app.buttons["experiment.pause"]
        app.revealSkyControls([action])
        XCTAssertEqual(action.label, expectedTitle)
        XCTAssertTrue(action.isEnabled)
        XCTAssertGreaterThanOrEqual(action.frame.width, 48)
        XCTAssertGreaterThanOrEqual(action.frame.height, 48)
        action.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: done).wait(timeout: 5),
                      "A visible menu pause/resume choice must apply and dismiss the menu")
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication, up: Bool = true) {
        if app.scrollViews["dialogue.studio.scroll"].exists {
            revealStudioControls([element], in: app)
            return
        }
        if app.buttons["experiment.cell.0.0"].exists {
            app.revealSkyControls([element])
            return
        }
        for _ in 0..<6 where !element.isHittable { if up { app.swipeUp() } else { app.swipeDown() } }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor private func revealStudioControls(_ controls: [XCUIElement], in app: XCUIApplication) {
        let scroll = app.scrollViews["dialogue.studio.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        for control in controls { XCTAssertTrue(control.waitForExistence(timeout: 5)) }
        // The authored header and footer are outside this actual viewport.
        let viewport = scroll.frame.intersection(app.frame)
        for _ in 0..<8 {
            let bounds = controls.map(\.frame).reduce(CGRect.null) { $0.union($1) }
            if viewport.contains(bounds) {
                XCTAssertTrue(controls.allSatisfy(\.isHittable))
                return
            }
            guard bounds.height <= viewport.height else {
                XCTFail("Studio reading and actions must fit together in their viewport")
                return
            }
            let up = bounds.maxY > viewport.maxY
            let distance = min(viewport.height * 0.45,
                               max(24, up ? bounds.maxY - viewport.maxY + 8 : viewport.minY - bounds.minY + 8))
            // Use the outer page's padding, outside the nested paragraph reader.
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: up ? 0.75 : 0.25))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(CGVector(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTFail("Studio controls did not become fully visible")
    }

    @MainActor private func revealText(_ text: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        func visible() -> Bool {
            let frame = text.frame
            let studio = app.scrollViews["dialogue.studio.scroll"]
            if studio.exists { return !frame.isEmpty && studio.frame.intersection(app.frame).contains(frame) }
            let title = app.staticTexts["sky.menu.title"]
            let top = title.exists ? title.frame.maxY
                : app.navigationBars.firstMatch.exists ? app.navigationBars.firstMatch.frame.maxY : app.frame.minY
            return !frame.isEmpty && frame.minY >= top && frame.maxY <= app.frame.maxY
        }
        if app.scrollViews["dialogue.studio.scroll"].exists {
            let actions = [app.buttons["sky.dialogue.next"], app.buttons["sky.dialogue.close"]].filter(\.exists)
            revealStudioControls([text] + actions, in: app)
        } else if app.buttons["experiment.cell.0.0"].exists {
            // A center-screen swipe can be consumed as a game gesture.
            app.revealSkyControls([text])
        } else {
            for _ in 0..<6 where !visible() { app.swipeUp() }
        }
        XCTAssertTrue(visible(), "The complete noninteractive message must fit in the visible viewport")
    }

    @MainActor private func readBoundedMessage(in app: XCUIApplication, actions: [XCUIElement],
                                               capturePrefix: String = "dialogue-largest-text") {
        let message = app.staticTexts["experiment.message"]
        let reading = app.scrollViews["sky.dialogue.reading"]
        XCTAssertTrue(reading.waitForExistence(timeout: 5),
                      "A paragraph taller than its space needs a bounded reading area")
        if app.scrollViews["dialogue.studio.scroll"].exists {
            revealStudioControls([reading] + actions, in: app)
        } else {
            app.revealSkyControls([reading] + actions)
        }
        let viewport = reading.frame.intersection(app.frame)
        let initialText = message.label
        let initialHeight = message.frame.height
        let actionFrames = actions.map(\.frame)
        XCTAssertGreaterThan(viewport.height, 44, "The reader must expose usable text space")
        XCTAssertGreaterThanOrEqual(message.frame.minY, viewport.minY - 1)
        XCTAssertLessThan(message.frame.minY, viewport.maxY,
                          "The message's beginning must be visibly readable before scrolling")
        capture(app, capturePrefix + "-reading-beginning")

        for _ in 0..<12 where message.frame.maxY > viewport.maxY + 1 {
            let before = message.frame
            // A drag shortened to the remaining few points can stay inside the
            // native scroll view's pan slop. Keep a real drag; the scroll view
            // itself clamps at the content's end.
            let distance = max(24, min(viewport.height * 0.45, before.maxY - viewport.maxY + 8))
            let start = reading.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
            let after = message.frame
            XCTAssertLessThan(after.minY, before.minY, "The reading pane must scroll its text")
            XCTAssertLessThanOrEqual(before.minY - after.minY, viewport.height * 0.7,
                                    "Successive reading positions must overlap instead of skipping text")
            XCTAssertEqual(after.height, initialHeight, accuracy: 1,
                           "Reading must not shrink Dynamic Type text")
            for (action, frame) in zip(actions, actionFrames) {
                XCTAssertEqual(action.frame.minY, frame.minY, accuracy: 1,
                               "Reading text must not displace its controls")
            }
        }
        XCTAssertEqual(message.label, initialText, "The complete spoken text must remain intact")
        XCTAssertLessThanOrEqual(message.frame.maxY, viewport.maxY + 1)
        XCTAssertGreaterThan(message.frame.maxY, viewport.minY,
                             "The message's final line must be visibly readable")
        XCTAssertTrue(message.isHittable)
        for action in actions {
            XCTAssertTrue(action.isEnabled)
            XCTAssertTrue(action.isHittable)
            XCTAssertTrue(app.frame.contains(action.frame))
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            XCTAssertGreaterThanOrEqual(action.frame.width, 44)
            XCTAssertLessThanOrEqual(viewport.maxY, action.frame.minY)
        }
        capture(app, capturePrefix + "-reading-end")
    }

    @MainActor func testPausedGuideStartsCollapsedAndReopensWithoutHidingManualControls() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        let before = board.value as? String
        XCTAssertNotNil(before)
        let message = app.staticTexts["experiment.message"]
        let reopen = app.buttons["sky.dialogue.reopen"]
        XCTAssertTrue(reopen.waitForExistence(timeout: 5))
        XCTAssertFalse(message.exists, "A paused sky starts with the small portrait, without a permanent prose panel")
        let manual = [app.buttons["experiment.pause"], app.buttons["experiment.next"]]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            manual.allSatisfy { $0.isEnabled && $0.isHittable }
        }, object: nil).wait(timeout: 5))
        func assertControls() {
            for control in manual {
                XCTAssertTrue(control.isEnabled)
                XCTAssertTrue(control.isHittable)
                XCTAssertTrue(app.frame.contains(control.frame))
                XCTAssertGreaterThanOrEqual(control.frame.width, 44)
                XCTAssertGreaterThanOrEqual(control.frame.height, 44)
                XCTAssertGreaterThanOrEqual(control.frame.minY, app.buttons["experiment.cell.0.0"].frame.maxY)
            }
        }
        assertControls()
        XCTAssertGreaterThanOrEqual(reopen.frame.width, 44)
        XCTAssertGreaterThanOrEqual(reopen.frame.height, 44)
        capture(app, "dialogue-paused-collapsed-controls")
        reopen.tap()
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertTrue(message.label.hasPrefix("Sunny."))
        assertControls()
        let close = app.buttons["sky.dialogue.close"]
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: message).wait(timeout: 3))
        XCTAssertTrue(reopen.isHittable)
        assertControls()
        XCTAssertEqual(board.value as? String, before, "Reading and closing guidance must not change the paused round")
        capture(app, "dialogue-paused-closed-controls")
    }

    @MainActor func testBundledScriptSwitchesAllSpeakersAndKeepsPausedRound() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        let before = board.value as? String
        let text = app.staticTexts["experiment.message"]
        let initialGuide = app.buttons["sky.dialogue.reopen"]
        reveal(initialGuide, in: app); initialGuide.tap()
        XCTAssertTrue(text.waitForExistence(timeout: 5))
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
        let reopen = app.buttons["sky.dialogue.reopen"]
        reveal(reopen, in: app); reopen.tap()
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(message.frame.minY, app.buttons["experiment.cell.0.0"].frame.maxY)
        XCTAssertTrue(message.label.hasPrefix("Sunny."))
        let next = app.buttons["experiment.next"]
        readBoundedMessage(in: app, actions: [app.buttons["sky.dialogue.close"], app.buttons["experiment.pause"], next])
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
        XCTAssertTrue(app.staticTexts["experiment.message"].label.hasPrefix("Spark."))
        let continueScript = app.buttons["sky.dialogue.next"], closeScript = app.buttons["sky.dialogue.close"]
        readBoundedMessage(in: app, actions: [continueScript, closeScript],
                           capturePrefix: "dialogue-studio-largest-text-spark")
        XCTAssertEqual(continueScript.label, "Continue")
        XCTAssertEqual(closeScript.label, "Close")
        XCTAssertLessThanOrEqual(continueScript.frame.maxY, closeScript.frame.minY,
                                "Large dialogue actions stack rather than compressing their labels into narrow columns")
        XCTAssertEqual(continueScript.frame.minX, closeScript.frame.minX, accuracy: 1)
        XCTAssertEqual(continueScript.frame.width, closeScript.frame.width, accuracy: 1)
        XCTAssertEqual(continueScript.frame.height, closeScript.frame.height, accuracy: 1,
                       "Both full-width single-word labels must occupy one line at the same text size")
        capture(app, "dialogue-largest-text-spark")
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.isHittable)
        XCTAssertTrue(app.frame.contains(done.frame))
        done.tap()
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
        changePauseFromMenu(app, expectedTitle: "Pause sky")
        assertPausedAfterMenuDismisses(app)
        capture(app, "dialogue-motion-paused")
        let pausedShowers = showers()
        XCTAssertGreaterThanOrEqual(pausedShowers, 9)
        changePauseFromMenu(app, expectedTitle: "Resume sky")
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            showers() > pausedShowers
        }, object: nil).wait(timeout: 8), "Resuming from the modal must rearm rain when the scene is ready")
        capture(app, "dialogue-motion-resumed-from-menu")
        changePauseFromMenu(app, expectedTitle: "Pause sky")
        assertPausedAfterMenuDismisses(app)
    }

    @MainActor func testActiveMessageCanBeReopenedWithoutStoppingAutomaticShowers() {
        let app = launch(); defer { app.terminate() }
        // First Light has steady rain and no recurring Dusk/storm warnings.
        // Expiry/reopening needs a quiet message interval, not an assumption
        // that a live threat will stop replacing the current guidance.
        app.buttons["experiment.settings"].tap()
        app.worldVisitControl("firstLight").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        app.buttons["sky.begin"].tap()
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
        changePauseFromMenu(app, expectedTitle: "Pause sky")
        assertPausedAfterMenuDismisses(app)
        capture(app, "dialogue-return-to-paused")
    }
}
