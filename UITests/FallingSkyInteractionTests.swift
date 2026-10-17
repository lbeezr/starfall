import XCTest

final class FallingSkyInteractionTests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func togglePause(_ app: XCUIApplication) {
        if app.buttons["sky.begin"].exists {
            app.buttons["sky.begin"].tap()
            XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
            return
        }
        if !app.buttons["experiment.pause"].exists {
            let menu = app.buttons["experiment.settings"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: menu).wait(timeout: 5))
            menu.tap()
        }
        let pause = app.buttons["experiment.pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        pause.tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
    }

    @MainActor private func resumeRestoredPaused(_ app: XCUIApplication) {
        let resume = app.buttons["sky.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10)); resume.tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor private func showers(_ app: XCUIApplication) -> Int {
        Int((app.otherElements["experiment.board"].value as! String).split(separator: " ")[0])!
    }
    @MainActor private func waitForShowers(_ count: Int, in app: XCUIApplication, timeout: TimeInterval = 12) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) >= count }, object: nil).wait(timeout: timeout))
    }
    @MainActor private func remainsPaused(_ app: XCUIApplication) {
        let initial = showers(app)
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) != initial }, object: nil)
        changed.isInverted = true
        XCTAssertTrue(changed.wait(timeout: 5))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<4 where !element.isHittable { app.swipeUp() }
    }

    @MainActor private func startFirstLight(_ app: XCUIApplication) {
        app.buttons["experiment.settings"].tap()
        let challenge = app.skyMenuControl("experiment.challenge")
        XCTAssertTrue(challenge.waitForExistence(timeout: 5)); challenge.tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Gather a little light.")
        app.buttons["sky.begin"].tap()
        togglePause(app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
    }

    @MainActor func testOpeningCascadeAllowsNativeClearBeforeLastWave() {
        // Exercise real falling animations; restore the user's system preference afterward.
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let originalMotion = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(originalMotion, on: toggle)
            settings.terminate()
        }
        preferences.terminate()
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        if calm.value as? String == "1" {
            calm.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: calm).wait(timeout: 5))
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(showers(app), 0)
        capture(app, "cascade-empty-before-start")
        togglePause(app)
        let legal = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true",
            "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 5))
        legal.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"),
            object: app.staticTexts["experiment.score"]).wait(timeout: 2))
        XCTAssertLessThan(showers(app), 4, "A real native tap clears before the cascade's final wave")
        capture(app, "cascade-clear-before-last-wave")
        waitForShowers(4, in: app)
        capture(app, "cascade-completed")
        // Rapid input remains bounded and does not consume a shower or invalidate the round.
        app.buttons["experiment.cell.0.0"].doubleTap()
        app.buttons["experiment.settings"].tap()
        let retained = app.staticTexts["experiment.roundSummary"].label
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
        XCTAssertFalse(retained.isEmpty)
    }

    @MainActor func testCompactHUDMenuSuspendsWithoutChangingPauseChoice() {
        let app = launch(); defer { app.terminate() }
        togglePause(app)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.staticTexts["experiment.message"].exists)
        XCTAssertFalse(app.staticTexts["experiment.turns"].exists)
        XCTAssertFalse(app.staticTexts["experiment.matches"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.exists)
        XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
        waitForShowers(1, in: app)
        let cue = app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch
        XCTAssertTrue(cue.exists)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Shower approaching"), object: cue).wait(timeout: 8))
        capture(app, "compact-hud-active-arrival-cue")
        app.buttons["experiment.settings"].tap()
        let pause = app.buttons["experiment.pause"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertEqual(pause.label, "Pause sky")
        let summary = app.staticTexts["experiment.roundSummary"]
        let retained = summary.label
        let changes = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", retained), object: summary)
        changes.isInverted = true
        XCTAssertTrue(changes.wait(timeout: 5), "Opening the menu freezes the sky")
        app.buttons["experiment.done"].tap()
        let before = showers(app)
        waitForShowers(before + 1, in: app)
        XCTAssertFalse(pause.exists, "Dismissing the menu resumes a running sky without leaving a pause control on the board")
        togglePause(app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        capture(app, "compact-hud-paused")
    }

    @MainActor func testCompactPlayfieldKeepsControlsVisible() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        XCTAssertGreaterThan(board.frame.height, app.frame.height * 0.70)
        XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
        XCTAssertTrue(app.buttons["experiment.pause"].isHittable)
        XCTAssertTrue(app.buttons["experiment.next"].isHittable)
        capture(app, "compact-sky-opening")
        app.buttons["experiment.next"].tap()
        waitForShowers(1, in: app)
        let group = app.buttons.matching(NSPredicate(format: "value == %@", "3 starlight connected")).firstMatch
        XCTAssertTrue(group.waitForExistence(timeout: 5)); group.tap()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "3 starlight")
        capture(app, "compact-sky-cleared")
    }

    @MainActor func testFirstLightGoalCompletionRestoreReplayAndSurvival() {
        let app = launch(); defer { app.terminate() }
        startFirstLight(app)
        let next = app.buttons["experiment.next"]
        let outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<50 {
            if outcome.exists { break }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in outcome.exists || next.isEnabled }, object: nil).wait(timeout: 5))
            if outcome.exists { break }
            let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
            if legal.exists { legal.tap() }
            else { reveal(next, in: app); next.tap() }
        }
        XCTAssertEqual(outcome.label, "First Light complete")
        XCTAssertFalse(next.exists)
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        XCTAssertTrue(app.buttons["experiment.new"].isHittable)
        capture(app, "first-light-complete")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10)); app.buttons["sky.resume"].tap()
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "First Light complete")
        XCTAssertFalse(next.exists)
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Gather a little light.")
        XCTAssertFalse(outcome.exists)
        app.buttons["sky.home"].tap()
        app.buttons["sky.start"].tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Let the night in.")
    }

    @MainActor func testFirstLightCanOverflowWithoutCompletingGoal() {
        let app = launch(); defer { app.terminate() }
        startFirstLight(app)
        let next = app.buttons["experiment.next"]
        for _ in 0..<40 {
            if app.staticTexts["experiment.outcome"].exists { break }
            reveal(next, in: app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            next.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.staticTexts["experiment.outcome"].exists || next.isEnabled
            }, object: nil).wait(timeout: 5))
        }
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "This sky is full")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertFalse(next.exists)
        capture(app, "first-light-overflow")
    }

    @MainActor func testFirstShowerIsPlayableAndManualInputStaysPaused() {
        let app = launch(); defer { app.terminate() }
        let empty = app.buttons["experiment.cell.6.6"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: empty).wait(timeout: 5))
        XCTAssertTrue(empty.label.hasPrefix("Empty")); empty.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Large stars count as one star", "worth two light"), object: app.staticTexts["experiment.message"]).wait(timeout: 5))
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let next = app.buttons["experiment.next"]
        reveal(next, in: app); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertEqual(showers(app), 1)
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.exists); legal.doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        remainsPaused(app)
        capture(app, "first-shower-clear-paused")
    }

    @MainActor func testLargestTextSettingsFeedbackAndDismissal() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let settings = app.buttons["experiment.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10)); settings.tap()
        for id in ["experiment.sound", "experiment.haptics", "experiment.calm"] {
            let control = app.switches[id]
            reveal(control, in: app)
            XCTAssertTrue(control.isHittable)
            if control.value as? String != "1" { control.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: control).wait(timeout: 3))
        }
        capture(app, "falling-sky-largest-text-settings")
        app.buttons["experiment.done"].tap()
        let pause = app.buttons["experiment.pause"]
        reveal(pause, in: app); XCTAssertTrue(pause.isHittable)
        let next = app.buttons["experiment.next"]
        reveal(next, in: app); XCTAssertTrue(next.isHittable)
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertEqual(showers(app), 1)
        capture(app, "falling-sky-largest-text-game")
        app.terminate(); app.launchArguments = []; app.launch()
        resumeRestoredPaused(app)
        XCTAssertTrue(settings.waitForExistence(timeout: 10)); settings.tap()
        for id in ["experiment.sound", "experiment.haptics", "experiment.calm"] {
            let control = app.switches[id]
            reveal(control, in: app)
            XCTAssertEqual(control.value as? String, "1")
            control.tap() // Leave optional feedback and Calm effects off after the check.
        }
        app.buttons["experiment.done"].tap()
    }

    @MainActor func testSystemReduceMotionKeepsManualPlayWorking() {
        continueAfterFailure = false
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String
        if original != "1" {
            // Settings exposes the entire labelled row as a switch; target its thumb.
            reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: reduce).wait(timeout: 5))
        defer {
            // Relaunch Settings so a returning-app transition cannot swallow the restoration tap.
            preferences.terminate()
            let (restoringPreferences, restoringSwitch) = NativeSystemMotionSettings.open()
            if let original {
                if restoringSwitch.value as? String != original {
                    restoringSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
                }
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", original), object: restoringSwitch).wait(timeout: 5))
            }
            restoringPreferences.terminate()
        }
        let app = launch(); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        reveal(next, in: app); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.exists); legal.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        capture(app, "falling-sky-system-reduce-motion")
    }

    @MainActor func testAutomaticRainThenPausedClearReplayAndSettings() {
        let app = launch(); defer { app.terminate() }
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertFalse(app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch.exists)
        capture(app, "automatic-empty-preview")
        togglePause(app)
        waitForShowers(2, in: app)
        togglePause(app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        togglePause(app)
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 40))
        // Freeze the matchable board immediately; another shower can remove
        // the queried group or fill the sky before the snapshot is captured.
        togglePause(app)
        let clearID = legal.identifier
        capture(app, "automatic-matchable")
        // Keep the queried cells committed while XCTest locates/activates them.
        // Automatic arrivals were exercised above and resume again below.
        app.buttons[clearID].doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        capture(app, "automatic-after-clear-paused")
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        app.revealSkyMenuElement(calm)
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        if calm.value as? String != "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let beforeCalm = showers(app)
        togglePause(app)
        waitForShowers(beforeCalm + 1, in: app)
        togglePause(app)
        capture(app, "automatic-calm-after-dismissal")
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
    }

    @MainActor func testBackgroundRelaunchAndAutomaticOverflow() {
        // The inner terminal wait alone permits 120s, plus background/UI work.
        executionTimeAllowance = 240
        let app = launch(); defer { app.terminate() }
        togglePause(app)
        waitForShowers(1, in: app)
        let before = showers(app)
        XCUIDevice.shared.press(.home)
        // Wait through more than a whole shower interval with the app suspended.
        let background = XCTNSPredicateExpectation(predicate: NSPredicate(value: false), object: nil)
        background.isInverted = true
        XCTAssertTrue(background.wait(timeout: 6))
        app.activate()
        XCTAssertLessThanOrEqual(showers(app), before + 1, "No catch-up burst on return")
        togglePause(app)
        let saved = showers(app)
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        resumeRestoredPaused(app)
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(showers(app), saved)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        togglePause(app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 120))
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        capture(app, "automatic-overflow")
        let newSky = app.buttons["experiment.new"]
        if !newSky.exists { app.buttons["experiment.settings"].tap() }; reveal(newSky, in: app); newSky.tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
    }

    @MainActor func testDarkStarInfluenceRestoreAndAdjacentClear() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        app.revealSkyMenuElement(calm)
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        if calm.value as? String == "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        let shadedMatch = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@ AND value MATCHES %@", "experiment.cell.", "growth blocked by a dark star", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        let next = app.buttons["experiment.next"]
        for _ in 0..<25 {
            if shadedMatch.exists { break }
            reveal(next, in: app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            next.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        }
        XCTAssertTrue(shadedMatch.exists)
        let beside = app.buttons[shadedMatch.identifier]
        let dark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).firstMatch
        XCTAssertTrue(dark.exists)
        let darkID = dark.identifier
        let expectedScore = Int((beside.value as! String).split(separator: " ")[0])!
        for star in app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.incoming.")).allElementsBoundByIndex {
            XCTAssertFalse(star.label.contains("column"))
        }
        capture(app, "dark-star-and-shaded-neighbors")
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        resumeRestoredPaused(app)
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        XCTAssertTrue(dark.label.hasPrefix("Dark star"))
        XCTAssertTrue(beside.label.contains("growth blocked by a dark star"))
        beside.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(expectedScore) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 3))
        XCTAssertFalse(app.buttons[darkID].label.hasPrefix("Dark star"))
        capture(app, "dark-star-dissolved-by-adjacent-clear")
    }

    @MainActor func testBalanceControlsPreserveBoardPersistAndChangeArrivals() {
        let app = launch(); defer { app.terminate() }
        togglePause(app)
        waitForShowers(1, in: app)
        togglePause(app)
        let occupied = app.buttons["experiment.cell.0.0"].label
        let pausedBoard = app.otherElements["experiment.board"].value as? String
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.balance").tap()
        let pace = app.buttons["experiment.pace"], frequency = app.buttons["experiment.darkFrequency"]
        XCTAssertTrue(pace.waitForExistence(timeout: 5))
        pace.tap(); app.buttons["Gentle · 6s"].tap()
        frequency.tap(); app.buttons["Frequent"].tap()
        XCTAssertTrue(app.staticTexts["experiment.balanceDetail"].label.contains("2–3 showers"))
        capture(app, "balance-gentle-frequent-settings")
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, pausedBoard)
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].label, occupied)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        togglePause(app)
        // The opening is independent of the selected ongoing pace.
        waitForShowers(4, in: app, timeout: 12)
        waitForShowers(5, in: app, timeout: 10)
        togglePause(app)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count > 0)
        capture(app, "balance-frequent-dark-star-shower-three")
        app.terminate(); app.launchArguments = ["--starfalls"]; app.launch()
        resumeRestoredPaused(app)
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.balance").tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Gentle"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Frequent"))
        app.buttons["experiment.resetBalance"].tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Brisk"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Regular"))
        pace.tap(); app.buttons["Brisk · 3s"].tap()
        frequency.tap(); app.buttons["None"].tap()
        app.buttons["experiment.done"].tap()
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        togglePause(app)
        waitForShowers(4, in: app, timeout: 16)
        togglePause(app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count, 0)
        capture(app, "balance-brisk-no-dark-stars")
    }
}

extension XCTNSPredicateExpectation {
    func wait(timeout: TimeInterval) -> Bool { XCTWaiter.wait(for: [self], timeout: timeout) == .completed }
}

/// One navigation owner for system-motion acceptance and normal-animation review setup.
enum NativeSystemMotionSettings {
    @MainActor static func set(_ enabled: Bool, on toggle: XCUIElement) {
        let value = enabled ? "1" : "0"
        if toggle.value as? String != value {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: toggle).wait(timeout: 5))
    }

    @MainActor static func open() -> (XCUIApplication, XCUIElement) {
        let preferences = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        preferences.launch()
        let reduce = preferences.switches["Reduce Motion"]
        if !reduce.exists {
            let accessibility = preferences.buttons["Accessibility"]
            for _ in 0..<4 where !accessibility.isHittable { preferences.swipeUp() }
            XCTAssertTrue(accessibility.isHittable); accessibility.tap()
            let motion = preferences.buttons["Motion"].firstMatch
            XCTAssertTrue(motion.waitForExistence(timeout: 5)); motion.tap()
        }
        XCTAssertTrue(reduce.waitForExistence(timeout: 5))
        return (preferences, reduce)
    }
}

extension FallingSkyInteractionTests {
    @MainActor func testPausedGuideReportsGrowthDarkOutcomesAndRestore() throws {
        let app = launch()
        addTeardownBlock { @MainActor in app.terminate() }
        let guide = app.staticTexts["experiment.message"]
        let next = app.buttons["experiment.next"]
        for number in 1...6 {
            reveal(next, in: app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            next.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            XCTAssertEqual(showers(app), number)
            if number == 3 {
                XCTAssertTrue(guide.label.contains("grew"))
                XCTAssertTrue(guide.label.contains("worth 2"))
                capture(app, "paused-guide-production-growth")
            }
        }
        XCTAssertTrue(guide.label.contains("A dark star blocks nearby growth"))
        let dark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,"))
        XCTAssertEqual(dark.count, 1)
        let before = app.otherElements["experiment.board"].value as? String
        dark.firstMatch.tap()
        XCTAssertTrue(guide.label.contains("Clear a matching group beside the dark star"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before)
        let remote = app.buttons["experiment.cell.0.0"]
        let remoteText = try XCTUnwrap(remote.value as? String)
        let remoteValue = try XCTUnwrap(Int(remoteText.split(separator: " ").first ?? ""))
        XCTAssertGreaterThanOrEqual(remoteValue, 3)
        remote.tap()
        XCTAssertTrue(guide.label.hasPrefix("+\(remoteValue) starlight."))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(remoteValue) starlight")
        XCTAssertFalse(guide.label.contains("dissolved"))
        XCTAssertEqual(dark.count, 1, "The unrelated clear does not remove the blocker")
        let adjacent = app.buttons["experiment.cell.0.1"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: adjacent).wait(timeout: 5))
        let adjacentText = try XCTUnwrap(adjacent.value as? String)
        let adjacentValue = try XCTUnwrap(Int(adjacentText.split(separator: " ").first ?? ""))
        XCTAssertGreaterThanOrEqual(adjacentValue, 3)
        adjacent.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertTrue(guide.label.hasPrefix("+\(adjacentValue) starlight."))
        XCTAssertTrue(guide.label.contains("Dark star dissolved"))
        XCTAssertEqual(dark.count, 0)
        let total = remoteValue + adjacentValue
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(total) starlight")
        let summary = guide.label
        capture(app, "paused-guide-production-dark-dissolved")
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(guide.waitForExistence(timeout: 5)); XCTAssertEqual(guide.label, summary)
        XCUIDevice.shared.press(.home); app.activate()
        let resume = app.buttons["experiment.pause"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: resume).wait(timeout: 5))
        XCTAssertEqual(guide.label, summary)
        app.terminate(); app.launchArguments = []; app.launch()
        resumeRestoredPaused(app)
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        XCTAssertTrue(guide.label.contains("Sky paused"))
        XCTAssertFalse(guide.label.contains("+"), "Transient text is not saved with the round")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(total) starlight")
    }

    @MainActor func testVoiceOverReadsPausedGrowthFeedback() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        let service = XCUIDevice.shared.voiceOverService
        let wasEnabled = service.isEnabled
        addTeardownBlock { @MainActor in
            if !wasEnabled { try XCUIDevice.shared.voiceOverService.disable() }
            XCTAssertEqual(XCUIDevice.shared.voiceOverService.isEnabled, wasEnabled)
        }
        try service.enable()
        let app = launch()
        addTeardownBlock { @MainActor in app.terminate() }
        let next = app.buttons["experiment.next"]
        var transcript: [String] = []
        for number in 1...3 {
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            let speech = NativeVoiceOverFocus.speech(afterTouching: next, containing: "Next shower")
            transcript.append(speech)
            XCTAssertTrue(speech.contains("Next shower"))
            next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
            waitForShowers(number, in: app, timeout: 5)
            XCTAssertEqual(showers(app), number)
        }
        app.staticTexts["experiment.message"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        var speech = ""
        let result = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            speech = (try? service.currentSpeech().utterance) ?? ""
            return speech.contains("grew") && speech.contains("worth 2")
        }, object: nil).wait(timeout: 5)
        transcript.append(speech)
        let attachment = XCTAttachment(string: transcript.joined(separator: "\n"))
        attachment.name = "Production-paused-guide-focused-VoiceOver"; attachment.lifetime = .keepAlways; add(attachment)
        XCTAssertTrue(result, "Focused guide speech: \(speech)")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }
}

#if compiler(>=6.4)
@available(iOS 27.0, *)
@MainActor enum NativeVoiceOverFocus {
    /// One exploration touch, then bounded observation of asynchronous focused speech.
    static func speech(afterTouching element: XCUIElement, containing text: String) -> String {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        var speech = ""
        _ = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            speech = (try? XCUIDevice.shared.voiceOverService.currentSpeech().utterance) ?? ""
            return speech.localizedCaseInsensitiveContains(text)
        }, object: nil).wait(timeout: 5)
        return speech
    }
}
#endif


final class ConstellationTraceNativeTests: XCTestCase {
    @MainActor private func launch(_ fixture:String = "diagonalSix", large:Bool = false) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--starfalls-reset","--constellation-fixture=\(fixture)"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func score(_ value:Int,_ app:XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","\(value) starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:6))
    }
    @MainActor private func drag(_ app:XCUIApplication,from:(Int,Int),to:(Int,Int)) {
        let start=app.buttons["experiment.cell.\(from.0).\(from.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let end=app.buttons["experiment.cell.\(to.0).\(to.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.1)
    }
    @MainActor func testNativeSwipeClearsChosenFiveAndLeavesSixth() {
        let app=launch();defer {app.terminate()}
        app.buttons["experiment.cell.0.0"].tap();score(0,app)
        drag(app,from:(0,0),to:(4,4));score(5,app)
        let rose=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'"))
        XCTAssertEqual(rose.count,1)
        let screenshot=XCTAttachment(screenshot:app.screenshot());screenshot.name="trace-five-from-six";screenshot.lifetime = .keepAlways;add(screenshot)
        app.terminate();app.launchArguments=[];app.launch();
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout:10));app.buttons["sky.resume"].tap();score(5,app)
    }
    @MainActor func testNativeTraceHeldAcrossAutomaticDeadlineCannotCommitStaleSelection() {
        // A real gesture crosses the production clock deadline; hosted tests own exact timing.
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        let initial = Int((board.value as! String).split(separator: " ")[0])!
        let start = app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        let end = app.buttons["experiment.cell.4.4"].coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        let resume = app.buttons["experiment.pause"]
        XCTAssertTrue(resume.isEnabled)
        resume.tap()
        start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 3.2)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (Int((board.value as? String ?? "").split(separator: " ").first ?? "") ?? 0) > initial
        }, object: nil).wait(timeout: 6))
        score(0, app)
        app.buttons["experiment.settings"].tap()
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "trace-deadline-rejected"; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor func testShortTraceAndOutsideReleaseCancelThenOrdinaryTapWorks() {
        let app=launch();defer {app.terminate()}
        drag(app,from:(0,0),to:(3,3));score(0,app)
        let start=app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.1,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.1)))
        score(0,app)
        app.terminate()
        let normal=launch("five")
        normal.buttons["experiment.cell.0.3"].tap();score(0,normal)
        normal.terminate()
        let fresh=XCUIApplication();fresh.launchArguments=["--starfalls-reset","--starfalls-seed=5"];fresh.launch()
        fresh.buttons["experiment.next"].tap()
        let legal=fresh.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND value == '3 starlight connected'")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:legal).wait(timeout:5))
        legal.tap();score(3,fresh);fresh.terminate()
    }
    @MainActor func testBuildIDMenuAndLargestTextTrace() {
        let app=launch(large:true);defer {app.terminate()}
        drag(app,from:(0,0),to:(4,4));score(5,app)
        app.buttons["experiment.settings"].tap()
        let label=app.staticTexts["starfall.buildID"]
        for _ in 0..<4 where !label.isHittable {app.swipeUp()}
        XCTAssertTrue(label.exists);XCTAssertTrue(label.label.hasPrefix("dev."))
        let capture=XCTAttachment(screenshot:app.screenshot());capture.name="trace-build-id-menu";capture.lifetime = .keepAlways;add(capture)
        app.buttons["experiment.done"].tap();score(5,app)
    }

}

/// The production route, unlike the historical paused-board reset fixtures above.
final class SkyFlowInteractionTests: XCTestCase {
    @MainActor private func requireNormalMotion() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let originalMotion = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(originalMotion, on: toggle); settings.terminate()
        }
    }

    @MainActor private func launch(largest: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--starfalls-seed=5", "-calmEffects", "NO"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.staticTexts["sky.title"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<8 where !button.isHittable {
            if button.frame.maxY > app.frame.maxY - 44 { app.swipeUp() }
            else if button.frame.minY < app.frame.minY + 80 { app.swipeDown() }
            else { break }
        }
        XCTAssertTrue(button.isHittable); button.tap()
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        // Avoid this runtime's rotated element-crop transform on landscape iPad.
        let screenshot = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let image = XCTAttachment(screenshot: screenshot); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor private func pause(_ app: XCUIApplication) {
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }
    @MainActor func testWelcomeEntryBackgroundAndAnotherSky() {
        requireNormalMotion()
        let app = launch(); defer { app.terminate() }
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "flow-welcome")
        tap("sky.start", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Let the night in.")
        XCTAssertFalse(app.buttons["experiment.settings"].exists)
        capture(app, "flow-entry")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        pause(app)
        if (board.value as? String)?.hasPrefix("0 showers") == true {
            tap("experiment.next", app)
        }
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 5)); legal.doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        let retained = board.value as? String
        tap("experiment.settings", app); tap("sky.home", app)
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 5))
        capture(app, "flow-resume-welcome")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.resume", app)
        XCTAssertEqual(board.value as? String, retained)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        tap("experiment.settings", app); tap("experiment.new", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "flow-another-entry")
    }
    @MainActor func testFirstLightWinReplayAndFullSky() {
        // Two bounded rounds (up to 50 + 40 native actions), then a persisted ending relaunch.
        executionTimeAllowance = 240
        requireNormalMotion()
        let app = launch(); defer { app.terminate() }
        tap("sky.firstLight", app); tap("sky.begin", app); pause(app)
        let next = app.buttons["experiment.next"], outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<50 {
            if outcome.exists { break }
            let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in outcome.exists || next.isEnabled }, object: nil).wait(timeout: 5))
            if outcome.exists { break }
            if legal.exists { legal.tap() } else { tap("experiment.next", app) }
        }
        XCTAssertEqual(outcome.label, "First Light complete")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable, "Result actions remain usable during the celebration")
        capture(app, "flow-win")
        tap("experiment.replay", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Gather a little light.")
        tap("sky.begin", app); pause(app)
        for _ in 0..<40 {
            if outcome.exists { break }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in outcome.exists || next.isEnabled }, object: nil).wait(timeout: 5))
            if !outcome.exists { tap("experiment.next", app) }
        }
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "This sky is full")
        XCTAssertTrue(app.staticTexts["sky.result.reason"].label.contains("had no room for the next star"))
        XCTAssertEqual(app.buttons["experiment.replay"].label, "Try First Light again")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("of 18"))
        capture(app, "flow-full")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        tap("sky.resume", app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "This sky is full")
        tap("experiment.new", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Let the night in.")
        capture(app, "flow-fresh-after-full")
    }

    @MainActor func testResultActionsRemainHittableAboveTheVisibleFinalBoard() {
        continueAfterFailure = false
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--observatory-review", "--observatory-dense"]
        app.launch()
        tap("sky.start", app); tap("sky.begin", app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "This sky is full")
        capture(app, "result-input-over-visible-board")
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        tap("experiment.replay", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
    }

    @MainActor func testEntryCancellationAndTerminationRetainThePlayedSky() {
        let app = launch(); defer { app.terminate() }
        tap("sky.start", app); tap("sky.begin", app); pause(app)
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        tap("experiment.next", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        let score = app.staticTexts["experiment.score"].label
        func assertRetained() {
            XCTAssertEqual(board.value as? String, retained)
            XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
            XCTAssertTrue(next.exists, "Continue preserves the intentional pause")
        }
        for choice in ["experiment.new", "experiment.replay", "experiment.challenge"] {
            tap("experiment.settings", app)
            // Form may not materialize an offscreen Explore row until scrolled.
            if choice == "experiment.challenge" {
                for _ in 0..<6 where !app.buttons[choice].exists { app.swipeUp() }
            }
            tap(choice, app)
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
            tap("sky.home", app); tap("sky.resume", app)
            assertRetained()
        }
        tap("experiment.settings", app); tap("sky.home", app)
        tap("sky.firstLight", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Gather a little light.")
        capture(app, "entry-staged-over-retained-sky")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        tap("sky.resume", app)
        assertRetained()
        capture(app, "entry-cancel-retained-sky")
    }

    @MainActor func testReducedMotionEntryAndReplayKeepExplicitBegin() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: toggle); settings.terminate()
        }
        let app = launch(); defer { app.terminate() }
        tap("sky.firstLight", app)
        let begin = app.buttons["sky.begin"]
        XCTAssertGreaterThanOrEqual(begin.frame.height, 44)
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "flow-reduced-entry")
        tap("sky.begin", app); pause(app)
        tap("experiment.next", app)
        tap("experiment.settings", app); tap("experiment.replay", app)
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "flow-reduced-replay")
    }
    @MainActor func testWelcomePreferencesShareValuesWithPlayAndDoNotCreateASave() {
        let app = launch(); defer { app.terminate() }
        tap("sky.preferences", app)
        XCTAssertFalse(app.buttons["sky.start"].exists)
        let sound = app.switches["experiment.sound"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        let original = sound.value as? String
        let nativeSwitch = sound.switches.firstMatch
        XCTAssertTrue(nativeSwitch.isHittable)
        nativeSwitch.tap()
        capture(app, "welcome-preferences")
        let selected = original == "1" ? "0" : "1"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", selected), object: sound).wait(timeout: 3))
        tap("experiment.help", app)
        XCTAssertTrue(app.navigationBars["How to play"].waitForExistence(timeout: 5))
        capture(app, "welcome-help-before-begin")
        tap("experiment.done", app)
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        tap("sky.firstLight", app); tap("sky.begin", app); pause(app)
        tap("experiment.settings", app)
        XCTAssertEqual(sound.value as? String, selected)
        sound.switches.firstMatch.tap() // Restore the review preference; normal defaults were never used.
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["sky.savedSummary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["sky.savedSummary"].label.contains("First Light"))
        XCTAssertTrue(app.staticTexts["sky.savedSummary"].label.contains("Paused"))
        capture(app, "welcome-retained-challenge-summary")
    }

    @MainActor func testLandscapeWelcomeEntryAndPreferences() throws {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch(); defer { app.terminate() }
        guard app.frame.width >= 700 else { throw XCTSkip("Tablet landscape coverage; iPhone supports portrait only") }
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height && app.frame.contains(app.buttons["sky.start"].frame)
        }, object: nil).wait(timeout: 5))
        XCTAssertGreaterThan(app.frame.width, app.frame.height, "Run this supported-landscape check on iPad")
        capture(app, "tablet-landscape-welcome")
        let preferences = app.buttons["sky.preferences"]
        // This runtime returned false isHittable while native activation succeeded.
        // Assert real navigation through preferences, Entry and play instead.
        preferences.tap()
        XCTAssertTrue(app.switches["experiment.sound"].waitForExistence(timeout: 5))
        app.buttons["experiment.done"].tap()
        app.buttons["sky.firstLight"].tap()
        let begin = app.buttons["sky.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        capture(app, "tablet-landscape-entry")
        begin.tap()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))

    }

    @MainActor func testLargestTextWelcomeEntryAndBackRemainReachable() {
        let app = launch(largest: true); defer { app.terminate() }
        capture(app, "flow-largest-welcome-actions-first")
        tap("sky.preferences", app)
        XCTAssertTrue(app.switches["experiment.sound"].waitForExistence(timeout: 5))
        capture(app, "flow-largest-welcome-preferences")
        tap("experiment.done", app)
        tap("sky.firstLight", app)
        capture(app, "flow-largest-entry")
        tap("sky.home", app)
        XCTAssertFalse(app.buttons["sky.resume"].exists, "Canceling an unbegun round must not create a save")
        tap("sky.firstLight", app)
        tap("sky.begin", app)
        pause(app)
        tap("experiment.settings", app)
        tap("experiment.done", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
    }

}

/// Production forecast layouts: verifies lifecycle and fallback, not physical camera fit.
final class ShowerForecastInteractionTests: XCTestCase {
    @MainActor func testCadenceForecastMenuBackgroundAndSafeAreaFallback() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5", "-calmEffects", "NO"]
        app.launch()
        let start = app.buttons["experiment.pause"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let cue = app.descendants(matching: .any)["experiment.arrivalCue"].firstMatch
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        let initialY = cue.frame.minY
        XCTAssertFalse((cue.value as? String ?? "").isEmpty, "The curve names its committed forecast")
        XCTAssertEqual(cue.frame.midY, app.buttons["experiment.settings"].frame.midY, accuracy: 1,
                       "The adopted cadence reserves stable cue space and uses the safe header forecast")
        XCTAssertGreaterThanOrEqual(initialY, 0)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.value as? String != "0 showers, 0 matching groups ready"
        }, object: nil).wait(timeout: 8))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "island-timer-active"; screenshot.lifetime = .keepAlways; add(screenshot)
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(menu.isHittable); menu.tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        XCTAssertFalse(cue.isHittable, "The header forecast stays behind the modal menu")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists, "Menu hides gameplay input")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.frame.minY, initialY, accuracy: 1)
        app.terminate()
        app.launchArguments = ["--starfalls-reset", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.frame.midY, app.buttons["experiment.settings"].frame.midY, accuracy: 1,
                       "Accessibility text retains the safe-area header forecast")
    }
}

extension ConstellationTraceNativeTests {
    @MainActor func testOpalWhiteFirstIsFreeAndColoredTapSpendsSharedOrbs() {
        let app = launch("opalChoice"); defer { app.terminate() }
        score(24, app)
        let orb = app.buttons["experiment.cell.2.5"]
        XCTAssertTrue(orb.label.contains("White Opal Orb"))
        XCTAssertTrue((orb.value as? String)?.contains("1 starlight") == true)
        orb.tap(); score(24, app)
        app.buttons["experiment.cell.0.6"].tap(); score(29, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'")).count, 0)
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "opal-colored-tap-consumes-shared-orbs"
        capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        app.buttons["sky.resume"].tap(); score(29, app)
    }
    @MainActor func testStormWarningCountRecoveryAndMenuSuspension() {
        let app = launch("stormWarning"); defer { app.terminate() }
        let phase = app.descendants(matching: .any).matching(identifier: "sky.phase").firstMatch
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        XCTAssertTrue(phase.label.contains("1 lighter shower"))
        for expected in ["Storm · 3 heavy showers left", "Storm · 2 heavy showers left", "Storm · 1 heavy shower left", "Lighter showers · 9 showers"] {
            app.buttons["experiment.next"].tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: phase).wait(timeout: 8))
            if expected.contains("3 heavy") {
                let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-native-three-showers"
                capture.lifetime = .keepAlways; add(capture)
                app.buttons["experiment.settings"].tap()
                XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
                XCTAssertFalse(phase.exists)
                XCUIDevice.shared.press(.home); app.activate()
                // Activation may return before the restored sheet accepts touches.
                // Admit one tap only when its actual foreground control is ready.
                let done = app.buttons["experiment.done"]
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.state == .runningForeground && done.isHittable && done.isEnabled
                }, object: nil).wait(timeout: 5))
                done.tap()
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: done).wait(timeout: 5))
                XCTAssertTrue(phase.waitForExistence(timeout: 5)); XCTAssertEqual(phase.label, expected)
            }
        }
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-native-calmer-return"
        capture.lifetime = .keepAlways; add(capture)
    }
}

extension ConstellationTraceNativeTests {
    @MainActor func testNativeTraceIncludesOneOpalAndPreservesTheOther() {
        let app = launch("opalTrace"); defer { app.terminate() }
        score(12, app)
        let orbs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'"))
        XCTAssertEqual(orbs.count, 2)
        let before = XCTAttachment(screenshot: app.screenshot()); before.name = "opal-native-before-trace"
        before.lifetime = .keepAlways; add(before)
        drag(app, from: (0,2), to: (4,2)); score(20, app)
        XCTAssertEqual(orbs.count, 1)
        app.buttons["experiment.cell.0.2"].tap(); score(20, app)
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "opal-native-selected-trace"
        after.lifetime = .keepAlways; add(after)
    }
    @MainActor func testLargestTextPhaseReflowsAndCeremoniesHideTheCue() {
        let app = launch("stormWarning", large: true); defer { app.terminate() }
        let phase = app.descendants(matching: .any).matching(identifier: "sky.phase").firstMatch
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        for _ in 0..<5 where !phase.isHittable || phase.frame.maxY > app.frame.maxY - 44 { app.swipeUp() }
        XCTAssertTrue(phase.isHittable)
        let layout = XCTAttachment(screenshot: app.screenshot()); layout.name = "storm-largest-text-before-frame-check"
        layout.lifetime = .keepAlways; add(layout)
        let frames = XCTAttachment(string: app.debugDescription); frames.name = "storm-largest-text-tree"
        frames.lifetime = .keepAlways; add(frames)
        XCTAssertGreaterThanOrEqual(phase.frame.minX, 0)
        XCTAssertLessThanOrEqual(phase.frame.maxX, app.frame.width)
        // The container's AX union includes overscanned decorative SpriteKit nodes.
        // Protect actual native play targets, not that expanded decorative union.
        for column in 0..<7 {
            XCTAssertGreaterThanOrEqual(phase.frame.minY, app.buttons["experiment.cell.0.\(column)"].frame.maxY)
        }
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-largest-text-reflow"
        capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launchArguments = ["--starfalls-reset", "--sky-flow-review"]
        app.launch()
        XCTAssertTrue(app.buttons["sky.start"].waitForExistence(timeout: 10)); XCTAssertFalse(phase.exists)
        app.buttons["sky.start"].tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5)); XCTAssertFalse(phase.exists)
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testLongPausedGuidanceStaysBelowFrontStars() {
        let app = launch("opalChoice"); defer { app.terminate() }
        let guide = app.descendants(matching: .any).matching(identifier: "sky.guide").firstMatch
        for cell in ["experiment.cell.2.5", "experiment.cell.6.0"] {
            app.buttons[cell].tap()
            score(24, app)
            XCTAssertTrue(guide.waitForExistence(timeout: 5))
            for column in 0..<7 {
                XCTAssertGreaterThanOrEqual(guide.frame.minY,
                    app.buttons["experiment.cell.0.\(column)"].frame.maxY,
                    "Long corrective copy must not cover the front row")
            }
            XCTAssertTrue(app.buttons["experiment.next"].isHittable)
            XCTAssertTrue(app.buttons["experiment.pause"].isHittable)
            XCTAssertLessThanOrEqual(guide.frame.maxY, app.frame.maxY)
            let actions = [app.buttons["experiment.next"].frame, app.buttons["experiment.pause"].frame]
            let introduction = app.scrollViews.containing(.staticText, identifier: "experiment.message").firstMatch
            XCTAssertTrue(introduction.exists, "Long guidance must retain its complete scrollable text")
            introduction.swipeUp()
            XCTAssertEqual(app.buttons["experiment.next"].frame, actions[0])
            XCTAssertEqual(app.buttons["experiment.pause"].frame, actions[1])
            XCTAssertTrue(app.buttons["experiment.next"].isHittable)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "bounded-guide-read-to-end-\(cell)"; capture.lifetime = .keepAlways; add(capture)
        }
    }
}
