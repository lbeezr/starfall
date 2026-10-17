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
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        app.buttons["experiment.settings"].tap()
        app.buttons["experiment.pause"].tap()
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
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.balance").tap()
        let pace = app.buttons["experiment.pace"], frequency = app.buttons["experiment.darkFrequency"]
        XCTAssertTrue(pace.waitForExistence(timeout: 5))
        pace.tap(); app.buttons["Gentle · 6s"].tap()
        frequency.tap(); app.buttons["Frequent"].tap()
        XCTAssertTrue(app.staticTexts["experiment.balanceDetail"].label.contains("2–3 showers"))
        capture(app, "balance-gentle-frequent-settings")
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(showers(app), 1)
        XCTAssertEqual(app.buttons["experiment.cell.0.0"].label, occupied)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        togglePause(app)
        let tooSoon = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) > 0 }, object: nil)
        tooSoon.isInverted = true
        XCTAssertTrue(tooSoon.wait(timeout: 4.5), "Gentle pace does not use the old four-second deadline")
        waitForShowers(3, in: app, timeout: 20)
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
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Steady"))
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
        for _ in 0..<8 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.isHittable); button.tap()
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor private func pause(_ app: XCUIApplication) {
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }
    @MainActor func testWelcomeEntryBackgroundAndAnotherSky() {
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
        pause(app)
        tap("experiment.settings", app); tap("experiment.new", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "flow-another-entry")
    }
    @MainActor func testFirstLightWinReplayAndFullSky() {
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
        capture(app, "flow-full")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        tap("sky.resume", app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "This sky is full")
        tap("experiment.new", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Let the night in.")
        capture(app, "flow-fresh-after-full")
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
    @MainActor func testLargestTextWelcomeEntryAndBackRemainReachable() {
        let app = launch(largest: true); defer { app.terminate() }
        tap("sky.firstLight", app)
        capture(app, "flow-largest-entry")
        tap("sky.home", app)
        tap("sky.resume", app)
        pause(app)
        tap("experiment.settings", app)
        tap("experiment.done", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
    }

}
