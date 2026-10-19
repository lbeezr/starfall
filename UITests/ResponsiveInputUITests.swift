import XCTest

final class ResponsiveInputUITests: XCTestCase {
    @MainActor private func launch(_ fixture: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "-calmEffects", "NO"]
        app.launchArguments += fixture == "ordinary" ? ["--observatory-review"] : ["--constellation-fixture=diagonalSix"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func score(_ expected: Int, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(expected) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
    }

    @MainActor func testSevenPointOrdinaryDriftClearsOnceAtNormalAndLargestText() {
        for large in [false, true] {
            let app = launch("ordinary", large: large); defer { app.terminate() }
            let cell = app.buttons["experiment.cell.0.0"]
            let expected = Int((cell.value as! String).split(separator: ";").last!.split(separator: " ")[0])!
            XCTAssertGreaterThanOrEqual(expected, 3)
            let origin = cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            origin.press(forDuration: 0.1, thenDragTo: origin.withOffset(CGVector(dx: 7, dy: 0)))
            score(expected, app)
        }
    }

    @MainActor func testIncompleteTraceExplainsCancellationAndNextTapStillWorks() {
        let app = launch("trace"); defer { app.terminate() }
        let first = app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let fourth = app.buttons["experiment.cell.3.3"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        first.press(forDuration: 0.4, thenDragTo: fourth, withVelocity: .slow, thenHoldForDuration: 0.1)
        score(0, app)
        let status = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Trace 5 matching stars"), object: status).wait(timeout: 3))
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = "responsive-incomplete-trace"; image.lifetime = .keepAlways; add(image)
        first.press(forDuration: 0.4, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)), withVelocity: .slow, thenHoldForDuration: 0.1)
        score(0, app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "left the board"), object: status).wait(timeout: 3))
        app.buttons["experiment.settings"].tap(); app.buttons["experiment.done"].tap()
        XCTAssertFalse(status.label.contains("left the board"))
        XCTAssertFalse(app.staticTexts["sky.inputStatus"].exists)
        app.buttons["experiment.cell.0.0"].tap(); score(0, app)
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        app.buttons["experiment.pause"].tap()
        let active = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        active.name = "responsive-active-play"; active.lifetime = .keepAlways; add(active)
    }

    @MainActor func testOutwardSwipesExplainTheEdgeAndNextTapClears() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset","--observatory-review","--observatory-dense","-calmEffects","NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout:10))
        let board = app.otherElements["experiment.board"], original = board.value as? String
        for (cell,dx,dy) in [("3.0",-1.0,0.0),("3.6",1.0,0.0),("6.3",0.0,-1.0),("0.3",0.0,1.0)] {
            let button = app.buttons["experiment.cell."+cell]
            XCTAssertTrue(button.isHittable)
            let origin = button.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
            let distance = min(button.frame.width,button.frame.height)*0.4
            origin.press(forDuration:0.05,thenDragTo:origin.withOffset(CGVector(dx:dx*distance,dy:dy*distance)),withVelocity:.fast,thenHoldForDuration:0)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","That direction leaves the sky. Swipe inward."),object:app.staticTexts["experiment.message"]).wait(timeout:3))
            XCTAssertEqual(board.value as? String,original)
            score(0,app)
        }
        let image = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        image.name = "outward-swipe-feedback"; image.lifetime = .keepAlways; add(image)
        // This dense fixture includes the touching grown Amber: four stars worth five.
        app.buttons["experiment.cell.0.0"].tap(); score(5,app)
        XCTAssertFalse(app.staticTexts["experiment.message"].label.contains("Swipe inward"))
    }
}
