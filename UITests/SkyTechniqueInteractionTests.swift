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
    @MainActor private func drag(_ app: XCUIApplication, from: (Int,Int), to: (Int,Int), hold: TimeInterval = 0.1, draw: Bool = false) {
        let start = app.buttons["experiment.cell.\(from.0).\(from.1)"].coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: 0.5))
        let end = app.buttons["experiment.cell.\(to.0).\(to.1)"].coordinate(withNormalizedOffset: CGVector(dx: 0.5,dy: 0.5))
        start.press(forDuration: draw ? 0.4 : 0.05,thenDragTo: end,withVelocity: .slow,thenHoldForDuration: hold)
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
    @MainActor func testImmediateSwipeSwapsWithoutArrangeAndEmptyDestinationFalls() {
        let app = launch("nudge"); defer { app.terminate() }
        let start = app.buttons["experiment.cell.1.2"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
        let neighbor = app.buttons["experiment.cell.1.1"].coordinate(withNormalizedOffset: CGVector(dx:0.5,dy:0.5))
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
        drag(app,from:(0,0),to:(0,3),draw:true); score(0,app)
        drag(app,from:(0,0),to:(0,4),draw:true); score(5,app)
        XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.contains("Aqua"))
        capture(app,"technique-five-selected-one-retained")
    }
    @MainActor func testSettingsAndBackgroundLeaveGesturesReadyWithoutRetoggling() {
        let app = launch("nudge"); defer { app.terminate() }
        tap("experiment.settings",app)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        tap("experiment.done",app)
        XCUIDevice.shared.press(.home); app.activate()
        let source = app.buttons["experiment.cell.1.2"]
        let resumed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningForeground && source.isEnabled && source.isHittable
        }, object: nil).wait(timeout: 5)
        if !resumed { capture(app,"gesture-resume-unavailable") }
        XCTAssertTrue(resumed, app.debugDescription)
        drag(app,from:(1,2),to:(1,1),hold:0.2)
        let swapped = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5)
        if !swapped { capture(app,"gesture-resume-swap-missing") }
        XCTAssertTrue(swapped, app.debugDescription)
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
        XCTAssertEqual(app.buttons["experiment.cell.0.5"].value as? String,"4 toward a tap match")
        capture(app,"technique-rescue-after")
    }

}


extension SkyTechniqueInteractionTests {
    @MainActor func testQuickDirectionalSwapDoesNotRequireDestinationCell() {
        let app = launch("nudge"); defer { app.terminate() }
        let cell = app.buttons["experiment.cell.1.2"]
        let start = cell.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let end = cell.coordinate(withNormalizedOffset:CGVector(dx:0.18,dy:0.55))
        start.press(forDuration:0.05,thenDragTo:end,withVelocity:.fast,thenHoldForDuration:0)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        score(0,app)
        capture(app,"short-directional-swap")
    }
}

extension SkyTechniqueInteractionTests {
    @MainActor func testFourDirectionSwapsAndHeldDestinationNeverDrawOrRepeat() {
        let app = launch("nudge"); defer { app.terminate() }
        for (from,to,name) in [((1,2),(1,1),"Aqua"),((1,1),(1,2),"Aqua"),
                               ((0,2),(1,2),"Mint"),((1,2),(0,2),"Mint")] {
            let source = app.buttons["experiment.cell.\(from.0).\(from.1)"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:source).wait(timeout:5))
            drag(app,from:from,to:to,hold:0.5)
            let target = app.buttons["experiment.cell.\(to.0).\(to.1)"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@ AND enabled == true",name),object:target).wait(timeout:5))
            score(0,app)
        }
        capture(app,"four-direction-exchanges")
        app.buttons["experiment.cell.0.0"].tap(); score(3,app)
    }

    @MainActor func testFastSameColorStrokeSwapsOnceThenHoldDrawClearsOnlyFive() {
        let app = launch("trace"); defer { app.terminate() }
        drag(app,from:(0,0),to:(0,4),hold:0.5)
        score(0,app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Aqua'")).count,6)
        drag(app,from:(0,0),to:(0,4),draw:true)
        score(5,app)
        XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.contains("Aqua"))
        capture(app,"held-five-after-same-color-swipe")
    }
}

extension SkyTechniqueInteractionTests {
    @MainActor func testHoldWithoutCompleteConstellationNeverFallsBackToSwapOrTap() {
        let app = launch("nudge"); defer { app.terminate() }
        drag(app,from:(1,2),to:(1,1),draw:true)
        score(0,app)
        XCTAssertTrue(app.buttons["experiment.cell.1.2"].label.contains("Aqua"))
        XCTAssertTrue(app.buttons["experiment.cell.1.1"].label.contains("Mint"))
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("Trace 5 matching stars"))
        drag(app,from:(1,2),to:(1,1))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        score(0,app)
    }
}

extension SkyTechniqueInteractionTests {
    @MainActor func testVerticalSwipesOwnTheBoardAtLargestTextSize() {
        let app = launch("nudge",large:true); defer { app.terminate() }
        drag(app,from:(0,2),to:(1,2))
        let upper = app.buttons["experiment.cell.1.2"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@ AND enabled == true","Mint"),object:upper).wait(timeout:5))
        drag(app,from:(1,2),to:(0,2))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Mint"),object:app.buttons["experiment.cell.0.2"]).wait(timeout:5))
        score(0,app)
        capture(app,"vertical-swaps-largest-text")
    }
}
