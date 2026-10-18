import XCTest

/// Native technique acceptance uses authored, non-saving boards and real gestures.
final class SkyTechniqueInteractionTests: XCTestCase {
    @MainActor private func launch(_ example: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--technique-review", "--technique-example=\(example)", "-calmEffects", "NO"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        XCTAssertFalse(app.staticTexts["dusk.cue"].exists)
        XCTAssertFalse(app.staticTexts["sky.inputStatus"].exists)
        let board = app.otherElements["experiment.board"]
        XCTAssertGreaterThan(board.frame.width,app.frame.width * 0.95)
        XCTAssertGreaterThan(board.frame.height,app.frame.height * 0.95)
        return app
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication, captureName: String? = nil) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<6 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), "Native target \(id): \(button.frame), viewport: \(app.frame)")
        if let captureName { capture(app,captureName) }
        button.tap()
    }
    @MainActor private func score(_ value: Int, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 6))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor private func drag(_ app: XCUIApplication, from: (Int,Int), to: (Int,Int), hold: TimeInterval = 0.1) {
        let start = app.buttons["experiment.cell.\(from.0).\(from.1)"].coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: 0.5))
        let end = app.buttons["experiment.cell.\(to.0).\(to.1)"].coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: 0.5))
        start.press(forDuration: 0.1,thenDragTo: end,withVelocity: .slow,thenHoldForDuration: hold)
    }
    @MainActor func testTapRecipesRelayWithoutAnyModeOrMenuToggle() {
        let app = launch("relay"); defer { app.terminate() }
        tap("experiment.cell.0.0",app); score(4,app)
        tap("experiment.cell.0.1",app); score(8,app)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("2-clear relay"))
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        capture(app,"gesture-only-relay")
        tap("experiment.settings",app)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        tap("experiment.done",app)
    }
    @MainActor func testEmptyOpeningKeepsShowerControlsWithoutModeToggle() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset","--starfalls-seed=5","-calmEffects","NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout:10))
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        tap("experiment.next",app)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
    }
    @MainActor func testSwipeAndHoldSwapsWithoutArrangeAndEmptyDestinationFalls() {
        let app = launch("nudge"); defer { app.terminate() }
        let start = app.buttons["experiment.cell.1.2"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        let neighbor = app.buttons["experiment.cell.1.1"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        // A quick short swipe cannot become a swap or an ordinary tap.
        start.press(forDuration:0.05,thenDragTo:neighbor,withVelocity:.fast,thenHoldForDuration:0)
        score(0,app)
        XCTAssertTrue(app.buttons["experiment.cell.1.2"].label.contains("Aqua"))
        start.press(forDuration:0.1,thenDragTo:neighbor,withVelocity:.slow,thenHoldForDuration:0.2)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        score(0,app)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        let mint = app.buttons["experiment.cell.1.2"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let empty = app.buttons["experiment.cell.1.3"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        mint.press(forDuration:0.1,thenDragTo:empty,withVelocity:.slow,thenHoldForDuration:0.2)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Mint"),object:app.buttons["experiment.cell.0.3"]).wait(timeout:5))
        score(0,app)
        capture(app,"direct-swipe-hold-empty-fall")
        // Normal taps still clear the newly constructed square.
        tap("experiment.cell.0.0",app); score(4,app)
    }
    @MainActor func testSwipeSpendsFiveFromSixAndShortTraceCancels() {
        let app = launch("trace"); defer { app.terminate() }
        app.buttons["experiment.cell.0.0"].twoFingerTap(); score(0,app)
        drag(app,from:(0,0),to:(0,3)); score(0,app)
        drag(app,from:(0,0),to:(0,4)); score(5,app)
        XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.contains("Aqua"))
        capture(app,"technique-five-selected-one-retained")
    }
    @MainActor func testSettingsAndBackgroundLeaveGesturesReadyWithoutRetoggling() {
        let app = launch("nudge"); defer { app.terminate() }
        tap("experiment.settings",app)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        tap("experiment.done",app)
        XCUIDevice.shared.press(.home); app.activate()
        drag(app,from:(1,2),to:(1,1),hold:0.2)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        tap("experiment.cell.0.0",app); score(4,app)
        XCTAssertFalse(app.buttons["technique.activate"].exists)
    }

    @MainActor func testRescueCreatesHeadroomDissolvesDarkAndKeepsTheBank() {
        let app = launch("rescue"); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.3"].label.contains("Dusk"))
        capture(app,"technique-rescue-before")
        tap("experiment.cell.0.0",app); score(3,app)
        XCTAssertTrue(app.buttons["experiment.cell.0.3"].label.hasPrefix("Empty"))
        XCTAssertTrue(app.buttons["experiment.cell.5.0"].label.hasPrefix("Empty"))
        XCTAssertEqual(app.buttons["experiment.cell.0.5"].value as? String,"4 starlight connected")
        capture(app,"technique-rescue-after")
    }

}
