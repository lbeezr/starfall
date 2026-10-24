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
    @MainActor private func openInitialGuide(_ app: XCUIApplication) {
        let reopen = app.buttons["sky.dialogue.reopen"]
        app.revealSkyControls([reopen])
        reopen.tap()
        XCTAssertTrue(app.staticTexts["experiment.message"].waitForExistence(timeout: 5))
    }
    @MainActor private func drag(_ app:XCUIApplication,from:(Int,Int),to:(Int,Int)) {
        let before = app.otherElements["experiment.board"].value as? String
        XCTAssertNotNil(before)
        app.revealSkyControls([app.buttons["experiment.cell.\(from.0).\(from.1)"], app.buttons["experiment.cell.\(to.0).\(to.1)"]])
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before, "Preparing a paused trace must not change the sky")
        let start=app.buttons["experiment.cell.\(from.0).\(from.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        let end=app.buttons["experiment.cell.\(to.0).\(to.1)"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.4,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.1)
    }
    @MainActor func testNativeSwipeClearsChosenFiveAndLeavesSixth() {
        let app=launch();defer {app.terminate()}
        app.buttons["experiment.cell.0.0"].tap();score(0,app)
        // Begin near the native target's rim, outside the old inset start circle.
        let start = app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset:CGVector(dx:0.04,dy:0.5))
        let end = app.buttons["experiment.cell.4.4"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5))
        start.press(forDuration:0.4,thenDragTo:end,withVelocity:.fast,thenHoldForDuration:0)
        score(5,app)
        let rose=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'"))
        XCTAssertEqual(rose.count,1)
        XCTAssertTrue(app.buttons["experiment.cell.5.5"].label.contains("Twinkle"), "The untraced sixth star stays in its original column")
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
        start.press(forDuration:0.4,thenDragTo:app.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.1)))
        score(0,app)
        app.terminate()
        let normal=launch("five")
        normal.buttons["experiment.cell.0.3"].tap();score(0,normal)
        normal.terminate()
        let fresh=XCUIApplication();fresh.launchArguments=["--starfalls-reset","--starfalls-seed=5"];fresh.launch()
        fresh.buttons["experiment.next"].tap()
        let legal=fresh.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND value == '3 toward a tap match'")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:legal).wait(timeout:5))
        legal.tap();score(3,fresh);fresh.terminate()
    }
    @MainActor func testNativeGapSwipeAndRepeatedAttempt() {
        let app=launch("singleGap");defer {app.terminate()}
        drag(app,from:(0,0),to:(0,2));score(0,app)
        drag(app,from:(0,0),to:(0,5));score(5,app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count,0)
        for column in 0...5 { XCTAssertTrue(app.buttons["experiment.cell.0.\(column)"].label.hasPrefix("Empty")) }
        let image=XCTAttachment(screenshot:app.screenshot());image.name="one-gap-clear";image.lifetime = .keepAlways;add(image)
    }

    @MainActor func testHorizontalTraceAndOrdinaryTapKeepDistinctCommittedSelections() {
        let horizontal = launch("horizontalFive")
        defer { horizontal.terminate() }
        let before = XCTAttachment(screenshot: horizontal.screenshot())
        before.name = "constellation-horizontal-before-held-stroke"; before.lifetime = .keepAlways; add(before)
        drag(horizontal, from: (0,0), to: (0,4)); score(5, horizontal)
        XCTAssertEqual(horizontal.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 0)
        for column in 0..<5 { XCTAssertTrue(horizontal.buttons["experiment.cell.0.\(column)"].label.hasPrefix("Empty")) }
        // These captures are committed-state checkpoints. External motion review
        // must establish the actual drawing, its duration and its disappearance.
        let traced = XCTAttachment(screenshot: horizontal.screenshot())
        traced.name = "constellation-horizontal-committed"; traced.lifetime = .keepAlways; add(traced)
        horizontal.terminate()

        let ordinary = launch("overlap"); defer { ordinary.terminate() }
        ordinary.buttons["experiment.cell.0.5"].tap(); score(5, ordinary)
        XCTAssertEqual(ordinary.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 2)
        XCTAssertTrue(ordinary.buttons["experiment.cell.1.3"].label.contains("Twinkle"))
        XCTAssertTrue(ordinary.buttons["experiment.cell.1.4"].label.contains("Twinkle"))
        let tapped = XCTAttachment(screenshot: ordinary.screenshot())
        tapped.name = "constellation-ordinary-tap-committed"; tapped.lifetime = .keepAlways; add(tapped)
    }

    @MainActor func testTracedSelectionAllowsNextClearAndSurvivesLifecycle() {
        let app = launch(); defer { app.terminate() }
        drag(app, from: (0,0), to: (4,4)); score(5, app)
        XCTAssertTrue(app.buttons["experiment.cell.5.5"].label.contains("Twinkle"))
        // No receipt-expiry wait precedes this following ordinary clear. Native
        // command latency is not proof that it occurred within the 1.4s receipt.
        let next = app.buttons["experiment.cell.0.1"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        next.tap(); score(20, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Spark'")).count, 0)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 1)
        let survivor = app.buttons["experiment.cell.0.5"].label
        XCTAssertTrue(survivor.contains("Twinkle"), "The sixth star falls after its Aqua supports clear")
        let board = app.otherElements["experiment.board"].value as? String
        XCTAssertNotNil(board)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningForeground && done.isHittable && done.isEnabled
        }, object: nil).wait(timeout: 8))
        done.tap(); score(20, app)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
        XCTAssertEqual(app.buttons["experiment.cell.0.5"].label, survivor)
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        app.buttons["sky.resume"].tap(); score(20, app)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
        XCTAssertEqual(app.buttons["experiment.cell.0.5"].label, survivor)
        let restored = XCTAttachment(screenshot: app.screenshot())
        restored.name = "constellation-follow-up-restored"; restored.lifetime = .keepAlways; add(restored)
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.replay").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        app.buttons["sky.begin"].tap(); score(0, app)
    }
    @MainActor func testNativeOffCenterStrokeAcquiresFive() {
        let app=launch("horizontalFive");defer {app.terminate()}
        let start=app.buttons["experiment.cell.0.0"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.88))
        let end=app.buttons["experiment.cell.0.4"].coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.88))
        start.press(forDuration:0.4,thenDragTo:end,withVelocity:.slow,thenHoldForDuration:0.1)
        score(5,app)
    }

    @MainActor func testLargestTextCalmTraceKeepsCommittedSelectionAndNextInput() {
        let app = launch(large: true); defer { app.terminate() }
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("experiment.preferences").tap()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        app.revealSkyMenuElement(calm)
        app.revealSkyControls([calm])
        let originalCalm = calm.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: calm)
        XCTAssertEqual(calm.value as? String, "1")
        let preference = XCTAttachment(screenshot: app.screenshot())
        preference.name = "constellation-largest-text-calm-selected"; preference.lifetime = .keepAlways; add(preference)
        app.buttons["experiment.done"].tap()
        defer {
            app.buttons["experiment.settings"].tap()
            app.skyMenuControl("experiment.preferences").tap()
            XCTAssertTrue(calm.waitForExistence(timeout: 5))
            app.revealSkyMenuElement(calm)
            app.revealSkyControls([calm])
            NativeSystemMotionSettings.set(originalCalm, on: calm)
            app.buttons["experiment.done"].tap()
        }
        drag(app, from: (0,0), to: (4,4)); score(5, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 1)
        XCTAssertTrue(app.buttons["experiment.cell.5.5"].label.contains("Twinkle"))
        // The checkpoint preserves the actual AX3XL viewport for review. It
        // does not assert that a static figure rendered or outlasted capture IO.
        let traced = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        traced.name = "constellation-largest-text-calm-selected-five"; traced.lifetime = .keepAlways; add(traced)
        let next = app.buttons["experiment.cell.0.1"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        next.tap(); score(20, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Spark'")).count, 0)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Twinkle'")).count, 1)
        XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.contains("Twinkle"))
        let followUp = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        followUp.name = "constellation-largest-text-calm-next-input"; followUp.lifetime = .keepAlways; add(followUp)
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
        XCTAssertEqual(orb.value as? String, "Earns no starlight; still connects matching stars")
        orb.tap(); score(24, app)
        // Feeding Dusk drains both shared orbs; the three colored stars still pay.
        app.buttons["experiment.cell.0.6"].tap(); score(27, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'")).count, 0)
        let capture = XCTAttachment(screenshot: app.screenshot()); capture.name = "opal-colored-tap-consumes-shared-orbs"
        capture.lifetime = .keepAlways; add(capture)
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        app.buttons["sky.resume"].tap(); score(27, app)
    }
    @MainActor func testStormWarningCountRecoveryAndMenuSuspension() {
        let app = launch("stormWarning"); defer { app.terminate() }
        openInitialGuide(app)
        let phase = app.descendants(matching: .any).matching(identifier: "experiment.message").firstMatch
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        XCTAssertTrue(phase.label.contains("1 lighter shower"))
        for expected in ["Storm: 3 heavy showers left.", "Storm: 2 heavy showers left.", "Storm: 1 heavy shower left.", "9 lighter showers before the storm."] {
            app.buttons["experiment.next"].tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", expected), object: phase).wait(timeout: 8))
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
                XCTAssertTrue(phase.waitForExistence(timeout: 5)); XCTAssertTrue(phase.label.contains(expected), phase.label)
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
        // The retained sky adopts feeding Dusk: one traced star is drained.
        drag(app, from: (0,2), to: (4,2)); score(19, app)
        XCTAssertEqual(orbs.count, 1)
        app.buttons["experiment.cell.0.2"].tap(); score(19, app)
        let after = XCTAttachment(screenshot: app.screenshot()); after.name = "opal-native-selected-trace"
        after.lifetime = .keepAlways; add(after)
    }
    @MainActor func testLargestTextPhaseReflowsAndCeremoniesHideTheCue() {
        let app = launch("stormWarning", large: true); defer { app.terminate() }
        openInitialGuide(app)
        let phase = app.descendants(matching: .any).matching(identifier: "experiment.message").firstMatch
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
        let guide = app.descendants(matching: .any).matching(identifier: "sky.dialogue").firstMatch
        for cell in ["experiment.cell.2.5", "experiment.cell.6.0"] {
            app.revealSkyControls([app.buttons[cell]])
            app.buttons[cell].tap()
            score(24, app)
            XCTAssertTrue(guide.waitForExistence(timeout: 5))
            for column in 0..<7 {
                XCTAssertGreaterThanOrEqual(guide.frame.minY,
                    app.buttons["experiment.cell.0.\(column)"].frame.maxY,
                    "Long corrective copy must not cover the front row")
            }
            let actionButtons = [app.buttons["experiment.next"], app.buttons["experiment.pause"]]
            let actionFrames = actionButtons.map(\.frame)
            let front = app.buttons["experiment.cell.0.0"], frontY = front.frame.minY
            let boardValue = app.otherElements["experiment.board"].value as? String
            XCTAssertNotNil(boardValue)
            app.readSkyGuideToEnd(actions: actionButtons)
            let translation = front.frame.minY - frontY
            for (button, original) in zip(actionButtons, actionFrames) {
                XCTAssertEqual(button.frame.minY, original.minY + translation, accuracy: 1,
                               "Page scrolling moves board and actions together; inner guide scrolling moves neither")
                XCTAssertEqual(button.frame.width, original.width, accuracy: 1)
                XCTAssertEqual(button.frame.height, original.height, accuracy: 1)
            }
            XCTAssertEqual(app.otherElements["experiment.board"].value as? String, boardValue)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = "bounded-guide-read-to-end-\(cell)"; capture.lifetime = .keepAlways; add(capture)
        }
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testOpalPlanningTwoTapOrdersKeepTheirDistinctRewards() {
        for amberFirst in [true, false] {
            let app = launch("opalPlanning")
            score(27, app)
            let orbs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'"))
            XCTAssertEqual(orbs.count, 1)
            app.buttons[amberFirst ? "experiment.cell.1.1" : "experiment.cell.0.3"].tap()
            score(29, app)
            XCTAssertEqual(orbs.count, amberFirst ? 1 : 0)
            let next = app.buttons[amberFirst ? "experiment.cell.0.3" : "experiment.cell.1.1"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value == %@", amberFirst ? "4 toward a tap match" : "3 toward a tap match"), object: next).wait(timeout: 5))
            let before = XCTAttachment(screenshot: app.screenshot())
            before.name = amberFirst ? "planning-preserved-opal-follow-up" : "planning-spent-opal-follow-up"
            before.lifetime = .keepAlways; add(before)
            next.tap(); score(amberFirst ? 33 : 32, app)
            XCTAssertEqual(orbs.count, 0)
            app.terminate()
        }
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testTinyEdgeReleaseResumesAutomaticSkyAndOrdinaryInput() {
        let app = launch(); defer { app.terminate() }
        app.buttons["experiment.pause"].tap()
        let star = app.buttons["experiment.cell.0.0"], frame = star.frame
        let radius = min(frame.width,frame.height)*0.44
        let offset = CGVector(dx:-(radius*0.99),dy:0)
        let start = star.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).withOffset(offset)
        start.press(forDuration:0.15,thenDragTo:start.withOffset(CGVector(dx:-7.9,dy:0)),withVelocity:.slow,thenHoldForDuration:0)
        score(0,app)
        let mint = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Pip'"))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in mint.count > 0 },object:nil).wait(timeout:8),
            "An off-board release below drag slop must relinquish the hold and allow the pending shower")
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout:5))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testAutomaticStormCountsRecoverWithoutManualShowersOrClears() {
        let app = launch("stormWarning"); defer { app.terminate() }
        score(22, app)
        openInitialGuide(app)
        let phase = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "1 lighter shower"), object: phase).wait(timeout: 5))
        app.buttons["experiment.pause"].tap()
        for expected in ["Storm: 3 heavy showers left.", "Storm: 2 heavy showers left.", "Storm: 1 heavy shower left.", "9 lighter showers before the storm."] {
            // A phase can last 1.7 seconds; a remote screenshot took 2.26 seconds.
            // Observe the complete sequence before doing any capture work.
            app.waitForSkyGuide(containing: expected, timeout: 8)
        }
        score(22, app)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "automatic-storm-recovered"
        capture.lifetime = .keepAlways; add(capture)
    }
    @MainActor func testInputRecoversAfterMultitouchBackgroundAndSupportedRotation() {
        let app = launch(); defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        app.buttons["experiment.cell.2.2"].pinch(withScale:0.8,velocity:-1)
        score(0,app)
        drag(app,from:(0,0),to:(3,3)); score(0,app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout:10)); score(0,app)
        // Phones intentionally support portrait only; iPad supports live canvas resizing.
        if app.frame.width > 600 {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in
                app.frame.width > app.frame.height
            },object:nil).wait(timeout:8))
        }
        drag(app,from:(0,0),to:(4,4)); score(5,app)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout:5)); XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in done.isHittable },object:nil).wait(timeout:8))
        done.tap(); score(5,app)
        for identifier in ["experiment.settings", "experiment.cell.0.0", "experiment.cell.6.6", "experiment.pause", "experiment.next"] {
            let control = app.buttons[identifier]
            app.revealSkyControls([control])
            XCTAssertTrue(control.isHittable,identifier)
            XCTAssertGreaterThanOrEqual(control.frame.minX,app.frame.minX,identifier)
            XCTAssertLessThanOrEqual(control.frame.maxX,app.frame.maxX,identifier)
            XCTAssertGreaterThanOrEqual(control.frame.minY,app.frame.minY,identifier)
            XCTAssertLessThanOrEqual(control.frame.maxY,app.frame.maxY,identifier)
        }
        let tree = XCTAttachment(string:app.debugDescription); tree.name = "resized-native-control-frames"
        tree.lifetime = .keepAlways; add(tree)
        // Full device capture avoids app-window cropping during interface rotation.
        let capture = XCTAttachment(screenshot:XCUIScreen.main.screenshot()); capture.name = "trace-after-interruption-and-resize"
        capture.lifetime = .keepAlways; add(capture)
    }
}


extension ConstellationTraceNativeTests {
    @MainActor func testCurrentStormOrbitChoiceThroughTwoNativeTapOrders() {
        for preserve in [true, false] {
            let app = launch("opalStormPlanning")
            score(30, app)
            let hole = app.buttons["experiment.cell.1.5"]
            XCTAssertTrue(hole.label.contains("Gravity hole"))
            let orbs = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'White Opal Orb'"))
            XCTAssertEqual(orbs.count, 1)
            if preserve {
                let capture = XCTAttachment(screenshot: app.screenshot())
                capture.name = "current-opal-orbit-choice-initial"; capture.lifetime = .keepAlways; add(capture)
            }
            let first = app.buttons[preserve ? "experiment.cell.0.4" : "experiment.cell.0.1"]
            XCTAssertTrue(first.isHittable); first.tap(); score(33, app)
            let next = app.buttons["experiment.cell.0.4"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value == %@", preserve ? "5 toward a tap match; 2 starlight if cleared" : "3 toward a tap match"), object: next).wait(timeout: 6))
            XCTAssertEqual(orbs.count, preserve ? 1 : 0)
            XCTAssertEqual(hole.label.contains("Gravity hole"), !preserve)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = preserve ? "current-opal-released-follow-up" : "current-opal-spent-follow-up"
            capture.lifetime = .keepAlways; add(capture)
            XCTAssertTrue(next.isHittable); next.tap(); score(preserve ? 35 : 36, app)
            XCTAssertEqual(orbs.count, preserve ? 1 : 0)
            app.terminate()
        }
    }
}

extension ConstellationTraceNativeTests {
    @MainActor func testCurrentOrbitFollowUpGuideReadsToEndWithoutMovingActionsOrBoard() {
        for preserve in [true, false] {
            let app = launch("opalStormPlanning")
            score(30, app)
            app.buttons[preserve ? "experiment.cell.0.4" : "experiment.cell.0.1"].tap()
            score(33, app)
            let next = app.buttons["experiment.cell.0.4"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value == %@", preserve ? "5 toward a tap match; 2 starlight if cleared" : "3 toward a tap match"), object: next).wait(timeout: 6))
            let guide = app.descendants(matching: .any).matching(identifier: "sky.dialogue").firstMatch
            let message = app.staticTexts["experiment.message"]
            XCTAssertTrue(message.label.contains(preserve ? "The hole closed" : "after 2 more showers."), message.label)
            XCTAssertTrue(message.label.contains("Showers are closer together now."), message.label)
            XCTAssertTrue(message.label.hasSuffix("Dusk will eat \(preserve ? 4 : 3) stars after 5 more showers with a touching star."), message.label)
            let board = app.otherElements["experiment.board"], boardValue = board.value as? String
            XCTAssertNotNil(boardValue)
            let actionButtons = [app.buttons["experiment.next"], app.buttons["experiment.pause"]]
            let actionFrames = actionButtons.map(\.frame)
            for column in 0..<7 {
                XCTAssertGreaterThanOrEqual(guide.frame.minY, app.buttons["experiment.cell.0.\(column)"].frame.maxY)
            }
            let front = app.buttons["experiment.cell.0.0"], frontY = front.frame.minY
            app.readSkyGuideToEnd(actions: actionButtons)
            let translation = front.frame.minY - frontY
            for (button, original) in zip(actionButtons, actionFrames) {
                XCTAssertEqual(button.frame.minY, original.minY + translation, accuracy: 1)
                XCTAssertEqual(button.frame.width, original.width, accuracy: 1)
                XCTAssertEqual(button.frame.height, original.height, accuracy: 1)
            }
            XCTAssertEqual(board.value as? String, boardValue)
            let capture = XCTAttachment(screenshot: app.screenshot())
            capture.name = preserve ? "current-orbit-release-guide-ending" : "current-orbit-retained-guide-ending"
            capture.lifetime = .keepAlways; add(capture)
            app.revealSkyControls([next])
            XCTAssertTrue(next.isHittable); next.tap(); score(preserve ? 35 : 36, app)
            app.terminate()
        }
    }
}
