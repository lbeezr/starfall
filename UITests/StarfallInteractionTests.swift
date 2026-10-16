import XCTest

/// Native input smoke test. This does not enable or validate VoiceOver.
final class StarfallInteractionTests: XCTestCase {
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
        // End muted regardless of a previous simulator preference.
        setSwitch(sound, to: "1")
        setSwitch(sound, to: "0")
        app.buttons["settings.done"].tap()
        XCTAssertTrue(waitFor(NSPredicate(format: "exists == false"), on: sound))
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
        reveal(play, in: app, scrollingUp: true)
        // These are real platform checks. No audit issues are suppressed.
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        play.tap()
        let moves = app.staticTexts["game.moves"]
        XCTAssertTrue(moves.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(moves.frame.height, 40,
                             "The system accessibility text preference must actually enlarge the headline")
        assertLabel(app, "game.moves", "18 moves")
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
        reveal(restart, in: app, scrollingUp: true)
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        restart.tap()
        assertLabel(app, "game.moves", "18 moves")

        let settings = app.buttons["game.settings"]
        reveal(settings, in: app, scrollingUp: false)
        settings.tap()
        let done = app.buttons["settings.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCTAssertTrue(done.isHittable)
        try app.performAccessibilityAudit(for: [.textClipped, .sufficientElementDescription, .hitRegion])
        attachScreenshot(app, name: "accessibility-large-text-settings")
        done.tap()
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
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
            // Small drags avoid skipping a whole board on the smallest iPhone.
            let startY = scrollingUp ? 0.75 : 0.25
            let endY = 0.50
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: startY))
                .press(forDuration: 0.05, thenDragTo:
                    scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: endY)))
        }
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
