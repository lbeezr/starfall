import XCTest

/// Native technique acceptance uses authored, non-saving boards and real gestures.
final class SkyTechniqueInteractionTests: XCTestCase {
    @MainActor private func launch(_ example: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--technique-review", "--technique-example=\(example)", "-calmEffects", "NO"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["technique.arrange"].waitForExistence(timeout: 10))
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
    @MainActor func testExactSquareThenGravityCreatesDeliberateRelay() {
        let app = launch("relay"); defer { app.terminate() }
        tap("technique.arrange", app)
        tap("experiment.cell.0.0", app)
        XCTAssertEqual(app.buttons["technique.activate"].label, "Clear square")
        capture(app,"technique-square-selected")
        tap("technique.activate",app); score(4,app)
        // Gravity creates the aqua square; it waits for another deliberate action.
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.contains("Aqua"))
        tap("experiment.cell.0.1", app)
        tap("technique.activate",app); score(8,app)
        XCTAssertTrue(app.staticTexts["technique.result"].label.contains("2-clear relay"))
        capture(app,"technique-relay-complete")
    }
    @MainActor func testNudgeWithButtonsAndSwipePreservesFourStarRecipe() {
        let app = launch("nudge"); defer { app.terminate() }
        tap("technique.arrange",app); tap("experiment.cell.1.2",app)
        tap("technique.move.left",app); score(0,app)
        tap("experiment.cell.0.0",app); tap("technique.activate",app); score(4,app)
        capture(app,"technique-nudge-square")
        tap("experiment.cell.1.2",app); tap("experiment.cell.1.3",app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Mint"),object:app.buttons["experiment.cell.0.3"]).wait(timeout:5))
        score(4,app)
        app.terminate()
        let swiping = launch("nudge"); defer { swiping.terminate() }
        tap("technique.arrange",swiping); drag(swiping,from:(1,2),to:(1,1),hold:0.6); score(0,swiping)
        tap("experiment.cell.0.0",swiping); tap("technique.activate",swiping); score(4,swiping)
    }
    @MainActor func testSwipeAndHoldSwapsWithoutArrangeAndEmptyDestinationFalls() {
        let app = launch("nudge"); defer { app.terminate() }
        let start = app.buttons["experiment.cell.1.2"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        let neighbor = app.buttons["experiment.cell.1.1"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        // A quick short swipe cannot become a swap or an ordinary tap.
        drag(app,from:(1,2),to:(1,1)); score(0,app)
        XCTAssertTrue(app.buttons["experiment.cell.1.2"].label.contains("Aqua"))
        start.press(forDuration:0.1,thenDragTo:neighbor,withVelocity:.slow,thenHoldForDuration:0.6)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        score(0,app)
        XCTAssertEqual(app.buttons["technique.arrange"].label,"Arrange stars")
        let mint = app.buttons["experiment.cell.1.2"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let empty = app.buttons["experiment.cell.1.3"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        mint.press(forDuration:0.1,thenDragTo:empty,withVelocity:.slow,thenHoldForDuration:0.6)
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
    @MainActor func testSettingsAndBackgroundCancelSelection() {
        let app = launch("relay"); defer { app.terminate() }
        tap("technique.arrange",app); tap("experiment.cell.0.0",app)
        tap("experiment.settings",app); tap("experiment.done",app)
        XCTAssertFalse(app.buttons["technique.activate"].exists); score(0,app)
        tap("technique.arrange",app); tap("experiment.cell.0.0",app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertFalse(app.buttons["technique.activate"].exists); score(0,app)
        tap("experiment.cell.0.0",app); tap("technique.activate",app); score(4,app)
    }
    @MainActor func testLargestTextRecipeActionsRemainReachable() {
        let app = launch("relay",large:true); defer { app.terminate() }
        tap("technique.arrange",app); tap("experiment.cell.0.0",app)
        drag(app,from:(0,2),to:(3,2))
        XCTAssertTrue(app.buttons["technique.activate"].exists,"Scrolling from an occupied star preserves the recipe selection")
        XCTAssertFalse(app.staticTexts["sky.inputStatus"].exists,"Ordinary scrolling is not an interrupted touch")
        tap("technique.activate",app,captureName:"technique-largest-text-selected-controls"); score(4,app)
        capture(app,"technique-largest-text")
    }
    @MainActor func testOverlappingRecipesOfferAnExplicitCrossChoice() {
        let app = launch("fork"); defer { app.terminate() }
        tap("technique.arrange",app); tap("experiment.cell.2.1",app)
        tap("technique.recipePicker",app)
        let cross = app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","Cross ·")).firstMatch
        XCTAssertTrue(cross.waitForExistence(timeout:5)); cross.tap()
        XCTAssertEqual(app.buttons["technique.activate"].label,"Clear cross")
        capture(app,"technique-fork-cross-choice")
        tap("technique.activate",app); score(5,app)
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
