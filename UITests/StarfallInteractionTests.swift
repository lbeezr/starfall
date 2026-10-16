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
    private func setSwitch(_ control: XCUIElement, to expected: String,
                           file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(waitFor(NSPredicate(format: "hittable == true AND enabled == true"), on: control),
                      "Sound switch must be ready for input", file: file, line: line)
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
                      "Expected sound value \(expected); actual: \(String(describing: control.value)); frame: \(control.frame)",
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
