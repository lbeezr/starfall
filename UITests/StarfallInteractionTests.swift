import XCTest

/// Native input smoke test. This does not enable or validate VoiceOver.
final class StarfallInteractionTests: XCTestCase {
    /// Real fast input and cancelled drag delivery, without relying on rule shortcuts.
    @MainActor
    func testRapidTapInvalidTapAndCancelledDrag() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        defer { app.terminate() }
        let board = app.descendants(matching: .any)["game.board"].firstMatch
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        tapBoard(app, row: 0, column: 0)
        assertLabel(app, "game.moves", "18 moves")
        let legal = board.coordinate(withNormalizedOffset: CGVector(
            dx: 0.5 - 2.0 / 7.7, dy: 0.5 + 2.0 / 7.7))
        let elsewhere = board.coordinate(withNormalizedOffset: CGVector(
            dx: 0.5 + 2.0 / 7.7, dy: 0.5 + 2.0 / 7.7))
        legal.press(forDuration: 0.1, thenDragTo: elsewhere)
        assertLabel(app, "game.moves", "18 moves")
        legal.doubleTap()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
        attachScreenshot(app, name: "rapid-input-settled")
    }

    /// Exercises the production accessible controls; does not enable VoiceOver itself.
    @MainActor
    func testAccessibleBoardControlsClearAndExplainInvalidGroups() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--accessibility-board"]
        app.launch()
        defer { app.terminate() }
        let valid = app.buttons["game.cell.1.1"]
        XCTAssertTrue(valid.waitForExistence(timeout: 10))
        XCTAssertGreaterThanOrEqual(valid.frame.width, 44)
        XCTAssertGreaterThanOrEqual(valid.frame.height, 44)
        XCTAssertTrue(valid.label.contains("row 6, column 2"))
        app.buttons["game.cell.0.0"].tap()
        assertLabel(app, "game.moves", "18 moves")
        valid.tap()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        attachScreenshot(app, name: "accessible-board-post-clear")
    }

    @MainActor
    func testLargestTextSettingsDirectAuditAndDismissal() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--reset-save", "--seed=42",
                               "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        defer { app.terminate() }
        let settings = app.buttons["menu.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        reveal(settings, in: app, scrollingUp: true, fullyVisible: true)
        settings.tap()
        let done = app.buttons["settings.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        attachScreenshot(app, name: "settings-direct-largest-text")
        try auditSettings(app, screenshotName: "settings-footer-fully-visible")
        done.tap()
        XCTAssertTrue(waitFor(NSPredicate(format: "exists == false"), on: done))
    }

    @MainActor
    func testRealBoardTapAndNavigation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        // Seed 42 is the existing demo; no pre-applied clear or gameplay bypass.
        app.launchArguments = ["--demo"]
        app.launch()
        defer { app.terminate() }

        let board = app.descendants(matching: .any)["game.board"].firstMatch
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        assertLabel(app, "game.moves", "18 moves")
        assertLabel(app, "game.score", "0 of 70 jewels cleared")
        XCTAssertGreaterThan(board.frame.width, 100)
        XCTAssertEqual(board.frame.width, board.frame.height, accuracy: 2)

        // Seed 42's first legal group is row 1, column 1 (zero-based, bottom up).
        // Match JewelScene's 7.7-cell layout, flipping SpriteKit's y axis.
        // This is a physical coordinate tap, not an accessibility button action.
        let point = board.coordinate(withNormalizedOffset: CGVector(
            dx: 0.5 - 2.0 / 7.7, dy: 0.5 + 2.0 / 7.7))
        point.tap()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        assertLabel(app, "game.message", "+3 starlight")
        let menu = app.buttons["game.menu"]
        XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: menu))
        attachScreenshot(app, name: "real-touch-post-clear")

        menu.tap()
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 5))
        XCTAssertEqual(play.label, "Continue")
        play.tap()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")

        app.buttons["game.settings"].tap()
        let sound = app.switches["settings.sound"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["game.menu"].exists,
                       "The modal must keep underlying gameplay out of accessibility navigation")
        // End muted regardless of a previous simulator preference.
        setSwitch(sound, to: "1")
        setSwitch(sound, to: "0")
        attachScreenshot(app, name: "settings-default-medium")
        // Exercise the supported expansion gesture before auditing the complete
        // Settings surface. Keep the compact presentation as visual evidence.
        let sheetNavigation = app.navigationBars["Settings"]
        sheetNavigation.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            .press(forDuration: 0.05, thenDragTo:
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)))
        let settingsScroll = app.scrollViews.containing(.any, identifier: "settings.sound").firstMatch
        XCTAssertGreaterThan(settingsScroll.frame.height, app.frame.height * 0.8)
        try auditSettings(app)
        attachScreenshot(app, name: "settings-default-text")
        app.buttons["settings.done"].tap()
        XCTAssertTrue(waitFor(NSPredicate(format: "exists == false"), on: sound))
        XCTAssertTrue(app.buttons["game.menu"].exists)
        assertLabel(app, "game.moves", "17 moves")
        app.buttons["game.settings"].tap()
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(NSPredicate(format: "value == %@", "0"), on: sound),
                      "Sound must remain muted when Settings is reopened")
        app.buttons["settings.done"].tap()

        app.buttons["game.restart"].tap()
        assertLabel(app, "game.moves", "18 moves")
        assertLabel(app, "game.score", "0 of 70 jewels cleared")
        assertLabel(app, "game.message", "A fresh sky. Find your first cluster")
        attachScreenshot(app, name: "real-touch-restarted")
    }

    @MainActor
    func testSavedGameRelaunchAndCalmResume() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--reset-save", "--seed=42"]
        app.launch()
        defer { app.terminate() }
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        assertLabel(app, "game.moves", "18 moves")
        app.terminate()

        // If Play failed to save the untouched board, this launch would use seed 43.
        // Its group at (1,1) has only two jewels: the real tap below would spend no move.
        app.launchArguments = ["--seed=43"]
        app.launch()
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        tapBoard(app, row: 1, column: 1)
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        app.terminate()

        app.launch()
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        XCTAssertEqual(play.label, "Continue")
        play.tap()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        // XCTest waits for idle: this verifies settled background/resume, not a rapid
        // interruption inside the clear animation's 480 ms presentation window.
        XCUIDevice.shared.press(.home)
        app.activate()
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
        attachScreenshot(app, name: "saved-game-resumed")

        app.buttons["game.settings"].tap()
        let calm = app.switches["settings.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        setSwitch(calm, to: "1")
        app.buttons["settings.done"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        app.buttons["game.settings"].tap()
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        XCTAssertTrue(waitFor(NSPredicate(format: "value == %@", "1"), on: calm))
        app.buttons["settings.done"].tap()
        // This four-jewel group is present after seed 42's first clear. Check that
        // the restored board accepts another move while Calm effects is enabled.
        tapBoard(app, row: 1, column: 2)
        assertLabel(app, "game.moves", "16 moves")
        assertLabel(app, "game.score", "7 of 70 jewels cleared")
        XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
        attachScreenshot(app, name: "saved-game-calm-turn")
        // Leave the shared simulator preference as it was for the original smoke test.
        app.buttons["game.settings"].tap()
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        setSwitch(calm, to: "0")
        app.buttons["settings.done"].tap()
    }

    /// Deterministic legal replays reach the penultimate board; only the final turn
    /// is real screen input. This exercises terminal UI, not natural-play balance.
    @MainActor
    func testTerminalOutcomesPersistAndRestart() throws {
        executionTimeAllowance = 180
        continueAfterFailure = false
        let app = XCUIApplication()
        defer { app.terminate() }
        let cases = [
            (seed: 6, row: 5, column: 3, score: 70, moves: 2,
             outcome: "Sky illuminated", message: "You lit the sky!", image: "terminal-won-restored"),
            (seed: 12, row: 0, column: 0, score: 73, moves: 0,
             outcome: "Sky illuminated", message: "You lit the sky!", image: "terminal-last-move-won-restored"),
            (seed: 0, row: 0, column: 0, score: 64, moves: 0,
             outcome: "Out of moves", message: "A lovely attempt. Try a fresh sky", image: "terminal-lost-restored")
        ]
        for fixture in cases {
            app.launchArguments = ["--reset-save", "--endgame-seed=\(fixture.seed)"]
            app.launch()
            let play = app.buttons["menu.play"]
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            play.tap()
            XCTAssertFalse(app.staticTexts["game.outcome"].exists)
            tapBoard(app, row: fixture.row, column: fixture.column)
            assertLabel(app, "game.outcome", fixture.outcome)
            assertLabel(app, "game.message", fixture.message)
            assertLabel(app, "game.score", "\(fixture.score) of 70 jewels cleared")
            assertLabel(app, "game.moves", "\(fixture.moves) moves")
            let progress = app.descendants(matching: .any)["game.progress"].firstMatch
            XCTAssertEqual(progress.value as? String, "\(min(fixture.score, 70)) of 70")
            // A second screen tap must neither spend a move nor change terminal copy.
            tapBoard(app, row: fixture.row, column: fixture.column)
            assertLabel(app, "game.score", "\(fixture.score) of 70 jewels cleared")
            assertLabel(app, "game.moves", "\(fixture.moves) moves")
            assertLabel(app, "game.message", fixture.message)
            app.terminate()

            // No fixture arguments: the terminal state must come from the real save.
            app.launchArguments = []
            app.launch()
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            XCTAssertEqual(play.label, "Continue")
            play.tap()
            assertLabel(app, "game.outcome", fixture.outcome)
            assertLabel(app, "game.message", fixture.message)
            assertLabel(app, "game.score", "\(fixture.score) of 70 jewels cleared")
            assertLabel(app, "game.moves", "\(fixture.moves) moves")
            attachScreenshot(app, name: fixture.image)
            app.buttons["game.restart"].tap()
            assertLabel(app, "game.moves", "18 moves")
            assertLabel(app, "game.score", "0 of 70 jewels cleared")
            assertLabel(app, "game.message", "A fresh sky. Find your first cluster")
            XCTAssertFalse(app.staticTexts["game.outcome"].exists)
            app.terminate()
        }
    }

    /// Uses the system Dynamic Type launch preference and Apple's native audit.
    /// This does not enable VoiceOver or substitute a simulated screen-reader mode.
    @MainActor
    func testLargestTextLayoutAndAccessibilityAudit() throws {
        executionTimeAllowance = 180
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--reset-save", "--seed=42",
                               "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        defer { app.terminate() }
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        logMenuLayout(app, stage: "before-reveal")
        reveal(play, in: app, scrollingUp: true)
        logMenuLayout(app, stage: "after-reveal")
        attachScreenshot(app, name: "accessibility-large-text-menu-before-audit")
        // These are real platform checks. No audit issues are suppressed.
        try auditMenu(app)
        play.tap()
        let moves = app.staticTexts["game.moves"]
        XCTAssertTrue(moves.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(moves.frame.height, 40,
                             "The system accessibility text preference must actually enlarge the headline")
        assertLabel(app, "game.moves", "18 moves")
        let progress = app.descendants(matching: .any)["game.progress"].firstMatch
        XCTAssertTrue(progress.exists)
        XCTAssertGreaterThanOrEqual(progress.frame.height, 44)
        XCTAssertGreaterThanOrEqual(progress.frame.width, 44)
        XCTAssertEqual(progress.value as? String, "0 of 70")
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        attachScreenshot(app, name: "accessibility-large-text-game")

        let board = app.descendants(matching: .any)["game.board"].firstMatch
        reveal(board, in: app, scrollingUp: true, fullyVisible: true)
        XCTAssertGreaterThan(board.frame.width, 300, "Text growth must not shrink the puzzle board")
        XCTAssertEqual(board.frame.width, board.frame.height, accuracy: 2)
        tapBoard(app, row: 1, column: 1)
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        let restart = app.buttons["game.restart"]
        reveal(restart, in: app, scrollingUp: true, fullyVisible: true)
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        // The audit may scroll content while inspecting it. Locate the live
        // control again before delivering the real restart tap.
        reveal(restart, in: app, scrollingUp: true, fullyVisible: true)
        attachScreenshot(app, name: "accessibility-restart-ready")
        print("RESTART_READY frame=\(restart.frame) enabled=\(restart.isEnabled) hittable=\(restart.isHittable)")
        restart.tap()
        assertLabel(app, "game.moves", "18 moves")

        let settings = app.buttons["game.settings"]
        reveal(settings, in: app, scrollingUp: false)
        settings.tap()
        let done = app.buttons["settings.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        // Retain the actual Settings layout even if a later audit finds an issue.
        attachScreenshot(app, name: "accessibility-large-text-settings")
        // Keep platform-reported bounds alongside the image: a visually readable
        // label can still have an undersized accessibility frame. This is
        // diagnostic evidence only; the native audit remains unsuppressed.
        print("SETTINGS_ACCESSIBILITY_TREE_BEGIN\n\(app.debugDescription)\nSETTINGS_ACCESSIBILITY_TREE_END")
        for label in ["Gentle sound", "Calm effects"] {
            let text = app.staticTexts[label].firstMatch
            if text.exists {
                print("SETTINGS_LABEL_BOUNDS \(label): \(text.frame), hittable=\(text.isHittable)")
            }
        }
        try auditSettings(app)
        let calm = app.descendants(matching: .any)["settings.calm"].firstMatch
        XCTAssertTrue(calm.exists)
        XCTAssertTrue(calm.isHittable)
        // Native styles may expose a selected button or a switch value. Both
        // are actual platform state, not an app-provided testing flag.
        let enabled = NSPredicate(format: "selected == true OR value == '1'")
        let disabled = NSPredicate(format: "selected == false AND (value == nil OR value != '1')")
        // Preferences persist independently of --reset-save. Normalize through
        // the real control so this flow is independent of preceding test order.
        if enabled.evaluate(with: calm) {
            calm.tap()
            expectation(for: disabled, evaluatedWith: calm)
            waitForExpectations(timeout: 5)
        }
        XCTAssertTrue(disabled.evaluate(with: calm))
        calm.tap()
        expectation(for: enabled, evaluatedWith: calm)
        waitForExpectations(timeout: 5)
        try auditSettings(app)
        calm.tap()
        expectation(for: disabled, evaluatedWith: calm)
        waitForExpectations(timeout: 5)
        try auditSettings(app)
        done.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
    }

    /// Real aqua-cluster input with the experimental pre-rendered material.
    /// Still captures prove appearance and settled state, not animation timing.
    @MainActor
    func testCrystalPilotRealTap() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--reset-save", "--seed=0", "--crystal-pilot"]
        app.launch()
        defer { app.terminate() }
        let play = app.buttons["menu.play"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        app.buttons["menu.settings"].tap()
        let calm = app.switches["settings.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        setSwitch(calm, to: "0")
        app.buttons["settings.done"].tap()
        play.tap()
        let board = app.descendants(matching: .any)["game.board"].firstMatch
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        assertLabel(app, "game.score", "0 of 70 jewels cleared")
        assertLabel(app, "game.moves", "18 moves")
        attachScreenshot(app, name: "crystal-pilot-before-tap")
        // Core seed 0 contains three connected aqua jewels at (5,3).
        tapBoard(app, row: 5, column: 3)
        assertLabel(app, "game.moves", "17 moves")
        assertLabel(app, "game.score", "3 of 70 jewels cleared")
        XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
        attachScreenshot(app, name: "crystal-pilot-after-tap")
    }

    @MainActor
    private func logMenuLayout(_ app: XCUIApplication, stage: String) {
        print("MENU_LAYOUT_BEGIN stage=\(stage) appFrame=\(app.frame)")
        let scroll = app.scrollViews.firstMatch
        if scroll.exists {
            print("MENU_SCROLL frame=\(scroll.frame) value=\(String(describing: scroll.value))")
        }
        // XCUI does not expose contentOffset. These element frames record the
        // actual content position relative to the viewport before/after scrolling.
        let elements: [(String, XCUIElement)] = [
            ("title", app.staticTexts["Starfall"].firstMatch),
            ("instructions", app.staticTexts["Clear 70 jewels in 18 moves.\nTap groups of 3 or more matching jewels\nconnected horizontally or vertically."].firstMatch),
            ("instruction-goal", app.staticTexts["Clear 70 jewels in 18 moves."].firstMatch),
            ("instruction-group", app.staticTexts["Tap groups of 3 or more matching jewels"].firstMatch),
            ("instruction-connection", app.staticTexts["connected horizontally or vertically."].firstMatch),
            ("play", app.buttons["menu.play"]),
            ("settings", app.buttons["menu.settings"])
        ]
        for (name, element) in elements {
            print("MENU_ELEMENT name=\(name) exists=\(element.exists)")
            if element.exists {
                print("MENU_BOUNDS name=\(name) frame=\(element.frame) hittable=\(element.isHittable) label=\(element.label)")
            }
        }
        print("MENU_TREE_BEGIN\n\(app.debugDescription)\nMENU_TREE_END")
        print("MENU_LAYOUT_END stage=\(stage)")
    }

    @MainActor
    private func auditMenu(_ app: XCUIApplication) throws {
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion]) { issue in
            print("MENU_AUDIT_ISSUE type=\(issue.auditType.rawValue) compact=\(issue.compactDescription)")
            print("MENU_AUDIT_DETAILS \(issue.detailedDescription)")
            if let element = issue.element, element.exists {
                print("MENU_AUDIT_ELEMENT label=\(element.label) frame=\(element.frame) identifier=\(element.identifier)")
                print("MENU_AUDIT_ELEMENT_DEBUG \(element.debugDescription)")
            }
            self.logMenuLayout(app, stage: "audit-issue")
            return false // Diagnostics only. Every issue still fails the audit.
        }
    }

    @MainActor
    private func auditSettings(_ app: XCUIApplication, screenshotName: String? = nil) throws {
        // Reveal the final information paragraph before auditing this reading
        // position. Keep every audit type; earlier clipping causes are unproven.
        let scroll = app.scrollViews.containing(.any, identifier: "settings.sound").firstMatch
        let footer = app.staticTexts["Your game stays on this device."]
        XCTAssertTrue(scroll.exists)
        XCTAssertTrue(footer.exists)
        for _ in 0..<8 {
            if scroll.frame.insetBy(dx: 0, dy: 2).contains(footer.frame) { break }
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.75))
                .press(forDuration: 0.05, thenDragTo:
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.50)))
        }
        XCTAssertTrue(scroll.frame.insetBy(dx: 0, dy: 2).contains(footer.frame),
                      "Settings information must be fully reachable before its audit")
        if let screenshotName { attachScreenshot(app, name: screenshotName) }
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion]) { issue in
            print("SETTINGS_AUDIT_ISSUE type=\(issue.auditType.rawValue)")
            print("compact=\(issue.compactDescription)")
            print("details=\(issue.detailedDescription)")
            if let element = issue.element {
                print("elementExists=\(element.exists)")
                if element.exists {
                    print("elementType=\(element.elementType) identifier=\(element.identifier)")
                    print("label=\(element.label) frame=\(element.frame) value=\(String(describing: element.value))")
                }
            } else {
                print("element=nil")
            }
            return false // Log only. Every reported issue still fails acceptance.
        }
    }

    /// Each fixture starts from the real seed-0 board and taps a different kind.
    /// Hosted tests independently verify the five kind/group mappings and assets.
    @MainActor
    func testStarshardFamilyPilotAllFiveRealTaps() throws {
        executionTimeAllowance = 240
        continueAfterFailure = false
        let app = XCUIApplication()
        defer { app.terminate() }
        let fixtures = [
            (kind: "rose", row: 0, column: 0, count: 3),
            (kind: "aqua", row: 5, column: 3, count: 3),
            (kind: "amber", row: 3, column: 6, count: 3),
            (kind: "violet", row: 3, column: 1, count: 4),
            (kind: "mint", row: 3, column: 4, count: 3)
        ]
        for fixture in fixtures {
            app.launchArguments = ["--reset-save", "--seed=0", "--starshard-family-pilot"]
            app.launch()
            let play = app.buttons["menu.play"]
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            app.buttons["menu.settings"].tap()
            let calm = app.switches["settings.calm"]
            XCTAssertTrue(calm.waitForExistence(timeout: 5))
            setSwitch(calm, to: "0")
            app.buttons["settings.done"].tap()
            play.tap()
            assertLabel(app, "game.moves", "18 moves")
            assertLabel(app, "game.score", "0 of 70 jewels cleared")
            attachScreenshot(app, name: "family-\(fixture.kind)-before")
            tapBoard(app, row: fixture.row, column: fixture.column)
            assertLabel(app, "game.moves", "17 moves")
            assertLabel(app, "game.score", "\(fixture.count) of 70 jewels cleared")
            XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
            attachScreenshot(app, name: "family-\(fixture.kind)-settled")
            app.buttons["game.restart"].tap()
            assertLabel(app, "game.moves", "18 moves")
            assertLabel(app, "game.score", "0 of 70 jewels cleared")
            app.terminate()
        }
    }

    /// Calm terminal flows use the existing legal-replay fixture and real final tap.
    /// Background/resume is settled-state coverage; hosted tests cancel mid-turn.
    @MainActor
    func testStarshardFamilyPilotCalmTerminalResumeAndRestart() throws {
        executionTimeAllowance = 180
        continueAfterFailure = false
        let app = XCUIApplication()
        defer { app.terminate() }
        let fixtures = [
            (seed: 6, row: 5, column: 3, score: 70, moves: 2, outcome: "Sky illuminated"),
            (seed: 0, row: 0, column: 0, score: 64, moves: 0, outcome: "Out of moves")
        ]
        for fixture in fixtures {
            app.launchArguments = ["--reset-save", "--endgame-seed=\(fixture.seed)", "--starshard-family-pilot"]
            app.launch()
            let play = app.buttons["menu.play"]
            XCTAssertTrue(play.waitForExistence(timeout: 10))
            app.buttons["menu.settings"].tap()
            let calm = app.switches["settings.calm"]
            XCTAssertTrue(calm.waitForExistence(timeout: 5))
            setSwitch(calm, to: "1")
            app.buttons["settings.done"].tap()
            play.tap()
            tapBoard(app, row: fixture.row, column: fixture.column)
            assertLabel(app, "game.outcome", fixture.outcome)
            assertLabel(app, "game.score", "\(fixture.score) of 70 jewels cleared")
            assertLabel(app, "game.moves", "\(fixture.moves) moves")
            XCTAssertTrue(waitFor(NSPredicate(format: "enabled == true"), on: app.buttons["game.menu"]))
            XCUIDevice.shared.press(.home); app.activate()
            assertLabel(app, "game.outcome", fixture.outcome)
            attachScreenshot(app, name: "family-calm-\(fixture.seed)-resumed")
            app.buttons["game.restart"].tap()
            assertLabel(app, "game.moves", "18 moves")
            assertLabel(app, "game.score", "0 of 70 jewels cleared")
            XCTAssertFalse(app.staticTexts["game.outcome"].exists)
            app.buttons["game.settings"].tap()
            XCTAssertTrue(calm.waitForExistence(timeout: 5))
            setSwitch(calm, to: "0")
            app.buttons["settings.done"].tap()
            app.terminate()
        }
    }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication,
                        scrollingUp: Bool, fullyVisible: Bool = false,
                        file: StaticString = #filePath, line: UInt = #line) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<12 {
            let visible = element.isHittable && (!fullyVisible ||
                scroll.frame.insetBy(dx: 0, dy: 2).contains(element.frame))
            if visible { return }
            // Small drags avoid skipping a whole board. Stay inside the content:
            // the outermost 30pt belongs to the native scrollbar's hit region.
            let startY = scrollingUp ? 0.75 : 0.25
            let endY = 0.50
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: startY))
                .press(forDuration: 0.05, thenDragTo:
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: endY)))
        }
        print("REVEAL_FAILED id=\(element.identifier) element=\(element.frame) scroll=\(scroll.frame) hittable=\(element.isHittable)")
        print(app.debugDescription)
        attachScreenshot(app, name: "unreachable-\(element.identifier)")
        XCTFail("Control must be reachable at the largest text size: \(element.identifier)",
                file: file, line: line)
    }

    @MainActor
    private func tapBoard(_ app: XCUIApplication, row: Int, column: Int) {
        let board = app.descendants(matching: .any)["game.board"].firstMatch
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        board.coordinate(withNormalizedOffset: CGVector(
            dx: 0.5 + Double(column - 3) / 7.7,
            dy: 0.5 - Double(row - 3) / 7.7)).tap()
    }

    @MainActor
    private func setSwitch(_ control: XCUIElement, to expected: String,
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(waitFor(NSPredicate(format: "hittable == true AND enabled == true"), on: control),
                      "Settings switch must be ready for input", file: file, line: line)
        XCTAssertTrue(["0", "1"].contains(control.value as? String ?? ""),
                      "Expected a binary sound switch", file: file, line: line)
        if (control.value as? String) != expected {
            // SwiftUI Form may expose the whole labeled row as the switch frame.
            // Tap the trailing control, not the center of the text/row.
            let frame = control.frame
            control.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: frame.width - min(25, frame.width / 2),
                                     dy: frame.height / 2)).tap()
        }
        XCTAssertTrue(waitFor(NSPredicate(format: "value == %@", expected), on: control),
                      "Expected switch value \(expected); actual: \(String(describing: control.value)); frame: \(control.frame)",
                      file: file, line: line)
    }

    @MainActor
    private func assertLabel(_ app: XCUIApplication, _ id: String, _ label: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        let element = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(waitFor(NSPredicate(format: "label == %@", label), on: element),
                      "Expected \(id) to read \(label); actual: \(element.exists ? element.label : "<missing>")",
                      file: file, line: line)
    }

    private func waitFor(_ predicate: NSPredicate, on object: Any) -> Bool {
        XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: object)],
                      timeout: 5) == .completed
    }

    @MainActor
    private func attachScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
