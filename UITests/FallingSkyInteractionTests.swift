import XCTest

final class FallingSkyInteractionTests: XCTestCase {
    @MainActor private func launch(calmEffects: Bool? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        if let calmEffects { app.launchArguments += ["-calmEffects", calmEffects ? "YES" : "NO"] }
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

    @MainActor private func observedShowers(_ app: XCUIApplication) -> Int? {
        let board = app.otherElements["experiment.board"]
        guard board.exists, let value = board.value as? String,
              let first = value.split(separator: " ").first else { return nil }
        return Int(first)
    }
    @MainActor private func showers(_ app: XCUIApplication) -> Int {
        guard let count = observedShowers(app) else {
            capture(app, "unreadable-board-count")
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "unreadable-board-count-hierarchy"; tree.lifetime = .keepAlways; add(tree)
            XCTFail("Expected a readable board shower count")
            return -1
        }
        return count
    }
    @MainActor private func waitForShowers(_ count: Int, in app: XCUIApplication, timeout: TimeInterval = 12) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let observed = self.observedShowers(app) else { return false }
            return observed >= count
        }, object: nil).wait(timeout: timeout))
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
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
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
            "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 5))
        // Resolve changing readiness once; pin the same native cell while waves continue.
        let target = legal.identifier
        XCTAssertTrue(target.hasPrefix("experiment.cell."))
        app.buttons[target].tap()
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
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("Clear matching stars"),
                      "Starting the sky now gives one brief bottom character message")
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
        let group = app.buttons.matching(NSPredicate(format: "value == %@", "3 toward a tap match")).firstMatch
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
            let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
            if legal.exists { legal.tap() }
            else { reveal(next, in: app); next.tap() }
        }
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertFalse(next.exists)
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        XCTAssertTrue(app.buttons["experiment.new"].isHittable)
        capture(app, "first-light-complete")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10)); app.buttons["sky.resume"].tap()
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertFalse(next.exists)
        let replay = app.buttons["experiment.replay"]
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        XCTAssertFalse(outcome.exists)
        app.buttons["sky.home"].tap()
        app.buttons["sky.start"].tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Make room for the stars")
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
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "No room to land")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertFalse(next.exists)
        capture(app, "first-light-overflow")
    }

    @MainActor func testFirstShowerIsPlayableAndManualInputStaysPaused() {
        let app = launch(); defer { app.terminate() }
        let empty = app.buttons["experiment.cell.6.6"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: empty).wait(timeout: 5))
        XCTAssertTrue(empty.label.hasPrefix("Empty")); empty.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@ AND label CONTAINS %@", "Tap matching stars connected", "Small stars count as 1", "grown stars as 2"), object: app.staticTexts["experiment.message"]).wait(timeout: 5))
        XCTAssertEqual(showers(app), 0)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let next = app.buttons["experiment.next"]
        reveal(next, in: app); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertEqual(showers(app), 1)
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
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
        let app = launch(calmEffects: false); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        reveal(next, in: app); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
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
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
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
        let shadedMatch = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@ AND value MATCHES %@", "experiment.cell.", "drained by Dusk", "([3-9]|[1-9][0-9]) toward a match, [0-9]+ starlight if cleared")).firstMatch
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
        let dark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dusk,")).firstMatch
        XCTAssertTrue(dark.exists)
        let darkID = dark.identifier
        let expectedScore = Int((beside.value as! String).split(separator: ";").last!.split(separator: " ")[0])!
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
        XCTAssertTrue(dark.label.hasPrefix("Dusk"))
        XCTAssertTrue(beside.label.contains("drained by Dusk"))
        beside.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(expectedScore) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 3))
        XCTAssertFalse(app.buttons[darkID].label.hasPrefix("Dusk"))
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
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dusk,")).count > 0)
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
        pace.tap(); app.buttons["Brisk · cycle"].tap()
        frequency.tap(); app.buttons["None"].tap()
        app.buttons["experiment.done"].tap()
        if !replay.exists { app.buttons["experiment.settings"].tap() }; reveal(replay, in: app); replay.tap()
        togglePause(app)
        waitForShowers(4, in: app, timeout: 16)
        togglePause(app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dusk,")).count, 0)
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
                XCTAssertTrue(guide.label.contains("count as 2"))
                capture(app, "paused-guide-production-growth")
            }
        }
        XCTAssertTrue(guide.label.contains("turn gray and earn no starlight"))
        let dark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dusk,"))
        XCTAssertEqual(dark.count, 1)
        let before = app.otherElements["experiment.board"].value as? String
        dark.firstMatch.tap()
        XCTAssertTrue(guide.label.contains("Clear a matching group beside me"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before)
        let remote = app.buttons["experiment.cell.0.0"]
        let remoteText = try XCTUnwrap(remote.value as? String)
        let remoteValue = try XCTUnwrap(Int(remoteText.split(separator: " ").first ?? ""))
        XCTAssertGreaterThanOrEqual(remoteValue, 3)
        remote.tap()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(remoteValue) starlight")
        // Result dialogue is published by the presentation completion, after the score commits.
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH %@", "Pip. +\(remoteValue) starlight."), object: guide).wait(timeout: 5), guide.label)
        XCTAssertFalse(guide.label.contains("dissolved"))
        XCTAssertEqual(dark.count, 1, "The unrelated clear does not remove the blocker")
        let adjacent = app.buttons["experiment.cell.0.1"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: adjacent).wait(timeout: 5))
        let adjacentText = try XCTUnwrap(adjacent.value as? String)
        let adjacentWeight = try XCTUnwrap(Int(adjacentText.split(separator: " ").first ?? ""))
        XCTAssertGreaterThanOrEqual(adjacentWeight, 3)
        let adjacentValue = try XCTUnwrap(Int(adjacentText.split(separator: ";").last!.split(separator: " ").first ?? ""))
        adjacent.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH %@", "Pip. +\(adjacentValue) starlight."), object: guide).wait(timeout: 5), guide.label)
        XCTAssertTrue(guide.label.contains("Dusk removed"))
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
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky")
        XCTAssertEqual(guide.label, "Twinkle. Your sky is waiting. Automatic showers are paused until you tap Resume sky.")
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
            return speech.contains("grew") && speech.contains("count as 2")
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


/// The production route, unlike the historical paused-board reset fixtures above.
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
        let hardware = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? ""
        if ["iPhone17,2", "iPhone18,3"].contains(hardware) {
            XCTAssertEqual(cue.frame.width,148,accuracy:1,"A calibrated full canvas must use the Island contour")
            XCTAssertEqual(cue.frame.height,50,accuracy:1)
            XCTAssertLessThan(cue.frame.maxY,app.staticTexts["experiment.score"].frame.minY)
        }
        let initialY = cue.frame.minY
        XCTAssertFalse((cue.value as? String ?? "").isEmpty, "The curve names its committed forecast")
        XCTAssertGreaterThanOrEqual(cue.frame.minY, 0)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
        XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
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

final class GravityUITests: XCTestCase {
    @MainActor private func launch(_ fixture: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--starfalls-reset","--gravity-fixture=\(fixture)"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.3"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func ready(_ cell: XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true AND hittable == true"),object:cell).wait(timeout:8))
    }
    @MainActor private func capture(_ name: String) {
        let image=XCTAttachment(screenshot:XCUIScreen.main.screenshot()); image.name=name; image.lifetime = .keepAlways
        add(image)
    }
    @MainActor func testFloorCollisionOrbitClearAndRestore() {
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle)
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Attraction field"))
        capture("gravity-before"); middle.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Gravity hole"),object:middle).wait(timeout:8))
        ready(middle); capture("gravity-captured")
        let next=app.buttons["experiment.next"]; XCTAssertTrue(next.waitForExistence(timeout:5)); next.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Sunny"),object:left).wait(timeout:8))
        capture("gravity-rotated"); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole")); capture("gravity-released")
        app.terminate(); app.launchArguments=[]; app.launch()
        let resume=app.buttons["sky.resume"]; XCTAssertTrue(resume.waitForExistence(timeout:10)); resume.tap()
        XCTAssertTrue(middle.waitForExistence(timeout:8)); XCTAssertFalse(middle.label.contains("Gravity hole"))
    }
    @MainActor func testTakeNowAndMenuDismissal() {
        let app=launch("takeNow"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole"))
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout:5)); app.buttons["Done"].tap()
        ready(left); capture("gravity-take-now")
    }
    @MainActor func testBackgroundPreservesOrbitAndThreeWindowsExpire() {
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        XCTAssertTrue(middle.label.contains("after 3 more showers"))
        XCUIDevice.shared.press(.home); app.activate(); ready(middle)
        XCTAssertTrue(middle.label.contains("after 3 more showers"))
        for remaining in [2,1,0] {
            let next=app.buttons["experiment.next"]; ready(next); next.tap(); ready(middle)
            if remaining > 0 { XCTAssertTrue(middle.label.contains("after \(remaining) more shower")) }
            else { XCTAssertFalse(middle.label.contains("Gravity hole")) }
        }
        capture("gravity-expired-after-background")
    }
    @MainActor func testLargestTextKeepsCaptiveAndMenuUsable() {
        let app=launch("takeNow",large:true), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        capture("gravity-largest-text")
        app.buttons["experiment.settings"].tap()
        let done=app.buttons["experiment.done"]; XCTAssertTrue(done.waitForExistence(timeout:5)); done.tap()
        let captive=app.buttons["experiment.cell.0.2"]; ready(captive); captive.tap(); ready(captive)
        XCTAssertFalse(middle.label.contains("Gravity hole"))
    }
    @MainActor func testSystemReduceMotionPreservesOrbitOutcome() {
        let (preferences,reduce)=NativeSystemMotionSettings.open()
        let original=reduce.value as? String
        if original != "1" { reduce.coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap() }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","1"),object:reduce).wait(timeout:5))
        defer {
            preferences.terminate()
            let (restoring,switchControl)=NativeSystemMotionSettings.open()
            if let original, switchControl.value as? String != original {
                switchControl.coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap()
            }
            if let original { XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@",original),object:switchControl).wait(timeout:5)) }
            restoring.terminate()
        }
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        let next=app.buttons["experiment.next"]; ready(next); next.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left)
        XCTAssertTrue(left.label.contains("Sunny")); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole")); capture("gravity-system-reduce-motion")
    }

}

final class GravityTraceUITests: XCTestCase {
    @MainActor func testNativeTraceSpendsFiveCaptivesAndPreservesSixth() {
        continueAfterFailure=false
        let app=XCUIApplication(); app.launchArguments=["--starfalls-reset","--gravity-fixture=trace"]; app.launch()
        let middle=app.buttons["experiment.cell.0.3"]
        XCTAssertTrue(middle.waitForExistence(timeout:10)); middle.tap()
        let start=app.buttons["experiment.cell.0.2"], end=app.buttons["experiment.cell.4.2"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:start).wait(timeout:8))
        start.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).press(forDuration:0.4,
            thenDragTo:end.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)),withVelocity:.slow,thenHoldForDuration:0.1)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","13 starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:8))
        XCTAssertFalse(middle.label.contains("Gravity hole"))
        XCTAssertTrue(start.label.contains("Spark"),"The sixth, untraced aqua settles after release")
        let capture=XCTAttachment(screenshot:XCUIScreen.main.screenshot());capture.name="gravity-trace-release";capture.lifetime = .keepAlways;add(capture)
    }
}
