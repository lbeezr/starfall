import XCTest

final class StarfallExperimentInteractionTests: XCTestCase {
    @MainActor private func launch() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func showers(_ app: XCUIApplication) -> Int {
        Int(app.staticTexts["experiment.turns"].label.split(separator: " ")[0])!
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
        let challenge = app.buttons["experiment.challenge"]
        XCTAssertTrue(challenge.waitForExistence(timeout: 5)); challenge.tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
    }

    @MainActor func testCompactPlayfieldKeepsControlsVisible() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        XCTAssertGreaterThan(board.frame.height, app.frame.height * 0.60)
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
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
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
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "First Light complete")
        XCTAssertFalse(next.exists)
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertFalse(outcome.exists)
        remainsPaused(app)
        let newSky = app.buttons["experiment.new"]
        if !newSky.exists { app.buttons["experiment.settings"].tap() }; reveal(newSky, in: app); newSky.tap()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
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
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertFalse(next.exists)
        capture(app, "first-light-overflow")
    }

    @MainActor func testFirstShowerIsPlayableAndManualInputStaysPaused() {
        let app = launch(); defer { app.terminate() }
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
        let preferences = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        preferences.launch()
        let reduce = preferences.switches["Reduce Motion"]
        if !reduce.exists {
            let accessibility = preferences.buttons["Accessibility"]
            for _ in 0..<4 where !accessibility.isHittable { preferences.swipeUp() }
            accessibility.tap()
            preferences.buttons["Motion"].firstMatch.tap()
        }
        XCTAssertTrue(reduce.waitForExistence(timeout: 5))
        let original = reduce.value as? String
        if original != "1" {
            // Settings exposes the entire labelled row as a switch; target its thumb.
            reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: reduce).wait(timeout: 5))
        defer {
            preferences.activate()
            if reduce.value as? String != original {
                reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            }
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

    @MainActor func testAutomaticRainPauseGrowthClearReplayAndSettings() {
        let app = launch(); defer { app.terminate() }
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let initialPreview = app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label
        XCTAssertFalse(initialPreview.contains("column"))
        XCTAssertFalse(initialPreview.isEmpty)
        capture(app, "automatic-empty-preview")
        app.buttons["experiment.pause"].tap()
        waitForShowers(2, in: app)
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        app.buttons["experiment.pause"].tap()
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 40))
        // Freeze the matchable board immediately; another shower can remove
        // the queried group or fill the sky before the snapshot is captured.
        app.buttons["experiment.pause"].tap()
        let clearID = legal.identifier
        capture(app, "automatic-matchable")
        app.buttons["experiment.pause"].tap()
        app.buttons[clearID].doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        app.buttons["experiment.pause"].tap()
        capture(app, "automatic-after-clear-paused")
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        if calm.value as? String != "1" { calm.tap() }
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        let beforeCalm = showers(app)
        app.buttons["experiment.pause"].tap()
        waitForShowers(beforeCalm + 1, in: app)
        app.buttons["experiment.pause"].tap()
        capture(app, "automatic-calm-after-dismissal")
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Start sky")
        XCTAssertEqual(app.descendants(matching: .any)["experiment.incoming.0"].firstMatch.label, initialPreview)
    }

    @MainActor func testBackgroundRelaunchAndAutomaticOverflow() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        waitForShowers(1, in: app)
        let before = showers(app)
        XCUIDevice.shared.press(.home)
        // Wait through more than a whole shower interval with the app suspended.
        let background = XCTNSPredicateExpectation(predicate: NSPredicate(value: false), object: nil)
        background.isInverted = true
        XCTAssertTrue(background.wait(timeout: 6))
        app.activate()
        XCTAssertLessThanOrEqual(showers(app), before + 1, "No catch-up burst on return")
        app.buttons["experiment.pause"].tap()
        let saved = showers(app)
        app.terminate()
        app.launchArguments = ["--starfalls"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(showers(app), saved)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        remainsPaused(app)
        app.buttons["experiment.pause"].tap()
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 120))
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        capture(app, "automatic-overflow")
        let newSky = app.buttons["experiment.new"]
        if !newSky.exists { app.buttons["experiment.settings"].tap() }; reveal(newSky, in: app); newSky.tap()
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Start sky")
    }

    @MainActor func testDarkStarInfluenceRestoreAndAdjacentClear() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        let calm = app.switches["experiment.calm"]
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
        app.buttons["experiment.pause"].tap()
        waitForShowers(1, in: app)
        app.buttons["experiment.pause"].tap()
        let occupied = app.buttons["experiment.cell.0.0"].label
        app.buttons["experiment.settings"].tap()
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
        app.buttons["experiment.pause"].tap()
        let tooSoon = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.showers(app) > 0 }, object: nil)
        tooSoon.isInverted = true
        XCTAssertTrue(tooSoon.wait(timeout: 4.5), "Gentle pace does not use the old four-second deadline")
        waitForShowers(3, in: app, timeout: 20)
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count > 0)
        capture(app, "balance-frequent-dark-star-shower-three")
        app.terminate(); app.launchArguments = ["--starfalls"]; app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Gentle"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Frequent"))
        app.buttons["experiment.resetBalance"].tap()
        XCTAssertTrue((pace.label + String(describing: pace.value)).contains("Steady"))
        XCTAssertTrue((frequency.label + String(describing: frequency.value)).contains("Regular"))
        pace.tap(); app.buttons["Brisk · 3s"].tap()
        frequency.tap(); app.buttons["None"].tap()
        app.buttons["experiment.done"].tap()
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        app.buttons["experiment.pause"].tap()
        waitForShowers(4, in: app, timeout: 16)
        app.buttons["experiment.pause"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star,")).count, 0)
        capture(app, "balance-brisk-no-dark-stars")
    }
}

private extension XCTNSPredicateExpectation {
    func wait(timeout: TimeInterval) -> Bool { XCTWaiter.wait(for: [self], timeout: timeout) == .completed }
}
