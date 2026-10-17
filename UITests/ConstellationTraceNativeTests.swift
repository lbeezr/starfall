import XCTest

final class ConstellationTraceNativeTests: XCTestCase {
    @MainActor private func launch(_ fixture:String = "diagonalSix", large:Bool = false) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--starfalls-reset","--constellation-fixture=\(fixture)"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func score(_ value:Int,_ app:XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","\(value) starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:6))
    }
    @MainActor private func drag(_ app:XCUIApplication,from:(Int,Int),to:(Int,Int)) {
        let start=app.buttons["experiment.cell.\(from.0).\(from.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let end=app.buttons["experiment.cell.\(to.0).\(to.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.1,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.1)
    }
    @MainActor func testNativeSwipeClearsChosenFiveAndLeavesSixth() {
        let app=launch();defer {app.terminate()}
        app.buttons["experiment.cell.0.0"].tap();score(0,app)
        drag(app,from:(0,0),to:(4,4));score(5,app)
        let rose=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'"))
        XCTAssertEqual(rose.count,1)
        let screenshot=XCTAttachment(screenshot:app.screenshot());screenshot.name="trace-five-from-six";screenshot.lifetime = .keepAlways;add(screenshot)
        app.terminate();app.launchArguments=[];app.launch();
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout:10));app.buttons["sky.resume"].tap();score(5,app)
    }
    @MainActor func testStationaryTouchHoldsShowerBeforeDragAndTapStillWorks() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        let start = app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let end = app.buttons["experiment.cell.4.4"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 5, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        score(5, app)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "touch-down-held-then-drawn"; capture.lifetime = .keepAlways; add(capture)
        app.terminate()
        let ordinary = launch("overlap")
        ordinary.buttons["experiment.cell.0.5"].tap(); score(5, ordinary)
        XCTAssertEqual(ordinary.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 2)
    }

    @MainActor func testShortTraceAndOutsideReleaseCancelThenOrdinaryTapWorks() {
        let app=launch();defer {app.terminate()}
        drag(app,from:(0,0),to:(3,3));score(0,app)
        let start=app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.1,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.1)))
        score(0,app)
        app.terminate()
        let normal=launch("five")
        normal.buttons["experiment.cell.0.3"].tap();score(0,normal)
        normal.terminate()
        let fresh=XCUIApplication();fresh.launchArguments=["--starfalls-reset","--starfalls-seed=5"];fresh.launch()
        fresh.buttons["experiment.next"].tap()
        let legal=fresh.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND value == '3 starlight connected'")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:legal).wait(timeout:5))
        legal.tap();score(3,fresh);fresh.terminate()
    }
    @MainActor func testBuildIDMenuAndLargestTextTrace() {
        let app=launch(large:true);defer {app.terminate()}
        drag(app,from:(0,0),to:(4,4));score(5,app)
        app.buttons["experiment.settings"].tap()
        let label=app.staticTexts["starfall.buildID"]
        for _ in 0..<4 where !label.isHittable {app.swipeUp()}
        XCTAssertTrue(label.exists);XCTAssertTrue(label.label.hasPrefix("dev."))
        let capture=XCTAttachment(screenshot:app.screenshot());capture.name="trace-build-id-menu";capture.lifetime = .keepAlways;add(capture)
        app.buttons["experiment.done"].tap();score(5,app)
    }

}


extension ConstellationTraceNativeTests {
    @MainActor func testOpalWhiteFirstIsFreeAndColoredTapSpendsSharedOrbs() {
        let app = launch("opalChoice"); defer { app.terminate() }
        score(24, app)
        let orb = app.buttons["experiment.cell.2.5"]
        XCTAssertTrue(orb.label.contains("White Opal Orb"))
        XCTAssertTrue((orb.value as? String)?.contains("1 starlight") == true)
        orb.tap(); score(24, app)
        app.buttons["experiment.cell.0.6"].tap(); score(29, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'")).count, 0)
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "opal-colored-tap-consumes-shared-orbs"
        capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        app.buttons["sky.resume"].tap(); score(29, app)
    }
    @MainActor func testStormWarningCountRecoveryAndMenuSuspension() {
        let app = launch("stormWarning"); defer { app.terminate() }
        let phase = app.descendants(matching: .any).matching(identifier: "sky.phase").firstMatch
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        XCTAssertTrue(phase.label.contains("1 lighter shower"))
        for expected in ["Storm · 3 heavy showers left", "Storm · 2 heavy showers left", "Storm · 1 heavy shower left", "Lighter showers · 9 showers"] {
            app.buttons["experiment.next"].tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: phase).wait(timeout: 8))
            if expected.contains("3 heavy") {
                let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-native-three-showers"
                capture.lifetime = .keepAlways; add(capture)
                app.buttons["experiment.settings"].tap()
                XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
                XCTAssertFalse(phase.exists)
                XCUIDevice.shared.press(.home); app.activate()
                // Activation may return before the restored sheet accepts touches.
                // Admit one tap only when its actual foreground control is ready.
                let done = app.buttons["experiment.done"]
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.state == .runningForeground && done.isHittable && done.isEnabled
                }, object: nil).wait(timeout: 5))
                done.tap()
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: done).wait(timeout: 5))
                XCTAssertTrue(phase.waitForExistence(timeout: 5)); XCTAssertEqual(phase.label, expected)
            }
        }
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-native-calmer-return"
        capture.lifetime = .keepAlways; add(capture)
    }
}

extension ConstellationTraceNativeTests {
    @MainActor func testNativeTraceIncludesOneOpalAndPreservesTheOther() {
        let app = launch("opalTrace"); defer { app.terminate() }
        score(12, app)
        let orbs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'"))
        XCTAssertEqual(orbs.count, 2)
        let before = XCTAttachment(screenshot: app.screenshot()); before.name = "opal-native-before-trace"
        before.lifetime = .keepAlways; add(before)
        drag(app, from: (0,2), to: (4,2)); score(20, app)
        XCTAssertEqual(orbs.count, 1)
        app.buttons["experiment.cell.0.2"].tap(); score(20, app)
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "opal-native-selected-trace"
        after.lifetime = .keepAlways; add(after)
    }
    @MainActor func testLargestTextPhaseReflowsAndCeremoniesHideTheCue() {
        let app = launch("stormWarning", large: true); defer { app.terminate() }
        let phase = app.descendants(matching: .any).matching(identifier: "sky.phase").firstMatch
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        for _ in 0..<5 where !phase.isHittable || phase.frame.maxY > app.frame.maxY - 44 { app.swipeUp() }
        XCTAssertTrue(phase.isHittable)
        let layout = XCTAttachment(screenshot: app.screenshot()); layout.name = "storm-largest-text-before-frame-check"
        layout.lifetime = .keepAlways; add(layout)
        let frames = XCTAttachment(string: app.debugDescription); frames.name = "storm-largest-text-tree"
        frames.lifetime = .keepAlways; add(frames)
        XCTAssertGreaterThanOrEqual(phase.frame.minX, 0)
        XCTAssertLessThanOrEqual(phase.frame.maxX, app.frame.width)
        // The container's AX union includes overscanned decorative SpriteKit nodes.
        // Protect actual native play targets, not that expanded decorative union.
        for column in 0..<7 {
            XCTAssertGreaterThanOrEqual(phase.frame.minY, app.buttons["experiment.cell.0.\(column)"].frame.maxY)
        }
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "storm-largest-text-reflow"
        capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launchArguments = ["--starfalls-reset", "--sky-flow-review"]
        app.launch()
        XCTAssertTrue(app.buttons["sky.start"].waitForExistence(timeout: 10)); XCTAssertFalse(phase.exists)
        app.buttons["sky.start"].tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5)); XCTAssertFalse(phase.exists)
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testLongPausedGuidanceStaysBelowFrontStars() {
        let app = launch("opalChoice"); defer { app.terminate() }
        let guide = app.descendants(matching: .any).matching(identifier: "sky.guide").firstMatch
        for cell in ["experiment.cell.2.5", "experiment.cell.6.0"] {
            app.buttons[cell].tap()
            score(24, app)
            XCTAssertTrue(guide.waitForExistence(timeout: 5))
            for column in 0..<7 {
                XCTAssertGreaterThanOrEqual(guide.frame.minY,
                    app.buttons["experiment.cell.0.\(column)"].frame.maxY,
                    "Long corrective copy must not cover the front row")
            }
            XCTAssertTrue(app.buttons["experiment.next"].isHittable)
            XCTAssertTrue(app.buttons["experiment.pause"].isHittable)
            XCTAssertLessThanOrEqual(guide.frame.maxY, app.frame.maxY)
            let actions = [app.buttons["experiment.next"].frame, app.buttons["experiment.pause"].frame]
            let introduction = app.scrollViews.containing(.staticText, identifier: "experiment.message").firstMatch
            if introduction.exists {
                introduction.swipeUp()
            } else {
                // A larger viewport can fit the complete introduction without scrolling.
                let message = app.staticTexts["experiment.message"]
                XCTAssertTrue(message.isHittable)
                XCTAssertGreaterThanOrEqual(message.frame.minY, guide.frame.minY)
                XCTAssertLessThanOrEqual(message.frame.maxY, actions.map(\.minY).min()!)
            }
            XCTAssertEqual(app.buttons["experiment.next"].frame, actions[0])
            XCTAssertEqual(app.buttons["experiment.pause"].frame, actions[1])
            XCTAssertTrue(app.buttons["experiment.next"].isHittable)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "bounded-guide-read-to-end-\(cell)"; capture.lifetime = .keepAlways; add(capture)
        }
    }
}
