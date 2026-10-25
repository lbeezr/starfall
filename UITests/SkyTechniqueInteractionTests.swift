import XCTest

/// Native technique fixtures and current Story rounds use isolated saves and real gestures.
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
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("Square"))
        capture(app,"committed-square-feedback")
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
    @MainActor func testLongFastFlickPastBoardEdgeStillMovesOneNeighbor() {
        let app = launch("nudge"); defer { app.terminate() }
        let source = app.buttons["experiment.cell.1.2"]
        let start = source.coordinate(withNormalizedOffset:CGVector(dx:0.65,dy:0.5))
        let end = app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:2,dy:source.frame.midY))
        start.press(forDuration:0.05,thenDragTo:end,withVelocity:.fast,thenHoldForDuration:0)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Aqua"),object:app.buttons["experiment.cell.1.1"]).wait(timeout:5))
        XCTAssertTrue(app.buttons["experiment.cell.1.2"].label.contains("Mint"))
        score(0,app)
        tap("experiment.cell.0.0",app); score(4,app)
    }

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
    @MainActor func testUpwardFallBackExplainsGravityAndAllowsNextMove() {
        verifyUpwardFallBack(large: false)
    }

    @MainActor func testLargestTextUpwardFallBackKeepsFeedbackReadable() {
        verifyUpwardFallBack(large: true)
    }

    @MainActor private func verifyUpwardFallBack(large: Bool) {
        let app = launch("trace", large: large); defer { app.terminate() }
        let origin = app.buttons["experiment.cell.0.0"]
        let originalLabel = origin.label
        app.revealSkyControls([origin, app.buttons["experiment.cell.1.0"]])
        drag(app, from: (0, 0), to: (1, 0), hold: 0)
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "Pip. Gravity brought the star back. Try another direction."), object: message).wait(timeout: 5))
        app.revealSkyControls([message])
        XCTAssertTrue(message.isHittable)
        XCTAssertTrue(app.frame.contains(message.frame), "Read the complete explanation inside the viewport")
        XCTAssertEqual(origin.label, originalLabel)
        XCTAssertTrue(app.buttons["experiment.cell.1.0"].label.hasPrefix("Empty"))
        score(0, app)
        capture(app, large ? "gravity-fall-back-largest-text" : "gravity-fall-back")

        // A different direction changes the settled arrangement and retains its own feedback.
        app.revealSkyControls([app.buttons["experiment.cell.0.5"], app.buttons["experiment.cell.0.6"]])
        drag(app, from: (0, 5), to: (0, 6), hold: 0)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@",
            "Star moved"), object: message).wait(timeout: 5))
        XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.hasPrefix("Empty"))
        XCTAssertTrue(app.buttons["experiment.cell.0.6"].label.contains("Aqua"))
        score(0, app)
        app.revealSkyControls([origin, app.buttons["experiment.cell.0.4"]])
        drag(app, from: (0, 0), to: (0, 4), draw: true)
        score(5, app)
    }

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

    @MainActor func testSystemReduceMotionPreservesHeldTraceAndRapidSwap() {
        let (preferences, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(true,on:motion); preferences.terminate()
        addTeardownBlock { @MainActor in
            let (preferences,motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original,on:motion); preferences.terminate()
        }
        testFastSameColorStrokeSwapsOnceThenHoldDrawClearsOnlyFive()
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

extension SkyTechniqueInteractionTests {
    @MainActor func testCurrentLanternSkyCascadeKeepsSurvivorsAndNextInput() throws {
        executionTimeAllowance = 180
        try verifyCurrentLanternCascade(fullBoard: false)
    }

    @MainActor func testCurrentLanternFullBoardCascadeKeepsRefillAndNextInput() throws {
        executionTimeAllowance = 180
        try verifyCurrentLanternCascade(fullBoard: true)
    }

    @MainActor private func verifyCurrentLanternCascade(fullBoard: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        app.worldVisitControl("firstLight").tap()
        let falling = app.buttons["sky.lanternMode.fallingSky"]
        let full = app.buttons["sky.lanternMode.fullBoard"]
        app.revealSkyControls([falling, full])
        XCTAssertTrue(falling.isSelected)
        if fullBoard { full.tap() }
        XCTAssertEqual(full.isSelected, fullBoard)
        XCTAssertEqual(falling.isSelected, !fullBoard)
        app.revealSkyControls([fullBoard ? full : falling, app.buttons["sky.begin"]])
        tap("sky.begin", app)

        let board = app.otherElements["experiment.board"]
        let points = app.staticTexts["experiment.score"]
        let mode = fullBoard ? "Full Board" : "Falling Sky"
        let prefix = fullBoard ? "departure-full-board" : "departure-falling-sky"
        func pauseSky() {
            guard !fullBoard else { return }
            let menu = app.buttons["experiment.settings"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: menu).wait(timeout: 5))
            menu.tap()
            app.buttons["experiment.pause"].tap()
        }
        func waitForRound(_ score: Int, exchanges: Int) {
            let expected = "\(score.formatted()) of 150,000 starlight collected"
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                guard board.exists, points.label == expected,
                      let value = board.value as? String, !value.contains("Stars settling") else { return false }
                if fullBoard {
                    let blocked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND enabled == false"))
                    return value.hasPrefix("Exchanges: \(exchanges). Full Board.") && blocked.count == 0
                }
                return value.hasPrefix("0 showers") && app.buttons["experiment.next"].isEnabled
            }, object: nil).wait(timeout: 10), "Expected current \(mode), score \(score), exchange \(exchanges)")
            if fullBoard {
                XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
            } else {
                XCTAssertEqual(app.otherElements["sky.header"].value as? String, "Falling Sky")
            }
        }
        func cells() throws -> [String] {
            var result: [String] = []
            func visit(_ node: any XCUIElementSnapshot) {
                if node.elementType == .button, node.identifier.hasPrefix("experiment.cell.") {
                    result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
                }
                node.children.forEach(visit)
            }
            visit(try board.snapshot())
            XCTAssertEqual(result.count, 49)
            return result.sorted()
        }
        func occupiedCount() -> Int {
            app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND NOT (label BEGINSWITH 'Empty')")).count
        }
        func exchange(_ from: (Int, Int), _ to: (Int, Int)) {
            let source = app.buttons["experiment.cell.\(from.0).\(from.1)"]
            let target = app.buttons["experiment.cell.\(to.0).\(to.1)"]
            app.revealSkyControls([source, target])
            XCTAssertTrue(source.isEnabled && target.isEnabled)
            drag(app, from: from, to: to)
        }
        pauseSky(); waitForRound(0, exchanges: 0)
        XCTAssertEqual(occupiedCount(), fullBoard ? 49 : 24)
        let opening = try cells()
        let corner = app.buttons["experiment.cell.0.6"].label
        capture(app, prefix + "-current-opening")
        // Core's current Sky4 and FullBoard6 witnesses both commit two squares
        // for 5,000 + 10,000. Recorded motion must establish body departures;
        // post-state snapshots cannot establish their duration or appearance.
        exchange((1,1), (1,2)); waitForRound(15_000, exchanges: 1)
        XCTAssertEqual(occupiedCount(), fullBoard ? 49 : 16)
        XCTAssertEqual(app.buttons["experiment.cell.0.6"].label, corner)
        XCTAssertNotEqual(try cells(), opening)
        if !fullBoard {
            for column in [0,2,3,4] { XCTAssertTrue(app.buttons["experiment.cell.0.\(column)"].label.contains("Violet")) }
            XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.hasPrefix("Empty"))
        }
        let retained = try cells()
        capture(app, prefix + "-two-square-cascade-committed")
        tap("experiment.settings", app)
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home); app.activate()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningForeground && done.isEnabled && done.isHittable
        }, object: nil).wait(timeout: 8))
        done.tap(); waitForRound(15_000, exchanges: 1)
        XCTAssertEqual(try cells(), retained)
        app.terminate(); app.launchArguments = ["--sky-flow-review", "-calmEffects", "NO"]; app.launch()
        tap("sky.resume", app); waitForRound(15_000, exchanges: 1)
        XCTAssertEqual(try cells(), retained)
        exchange(fullBoard ? (3,6) : (0,0), fullBoard ? (4,6) : (0,1))
        waitForRound(fullBoard ? 34_000 : 20_000, exchanges: 2)
        XCTAssertEqual(occupiedCount(), fullBoard ? 49 : 12)
        XCTAssertNotEqual(try cells(), retained)
        capture(app, prefix + "-next-exchange-committed")
        tap("experiment.settings", app)
        app.skyMenuControl("experiment.replay").tap()
        tap("sky.begin", app)
        pauseSky(); waitForRound(0, exchanges: 0)
        XCTAssertEqual(try cells(), opening, "Same-round Replay restores its current mode and exact opening")
        capture(app, prefix + "-replayed-opening")
    }
}
