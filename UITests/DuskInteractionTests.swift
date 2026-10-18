import XCTest

final class DuskInteractionTests: XCTestCase {
    @MainActor private func launch(_ fixture: String, extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--dusk-fixture=\(fixture)", "-calmEffects", "NO"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func ready(_ element: XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: element).wait(timeout: 7))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testFiveFeedsCollapseAndRestoreCommittedResult() {
        let app = launch("unfed"); defer { app.terminate() }
        let dusk = app.buttons["experiment.cell.0.3"], next = app.buttons["experiment.next"]
        XCTAssertTrue(dusk.label.contains("0 of 5 feeds"))
        XCTAssertFalse(app.staticTexts["dusk.cue"].exists)
        XCTAssertFalse(app.buttons["technique.arrange"].exists)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("5 feeding showers left"))
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("drained by Dusk"))
        capture(app,"dusk-unfed")
        ready(next); next.tap(); ready(next)
        XCTAssertTrue(dusk.label.contains("1 of 5 feeds"))
        next.tap(); ready(next)
        XCTAssertTrue(dusk.label.contains("2 of 5 feeds"))
        next.tap(); ready(next)
        XCTAssertTrue(dusk.label.contains("3 of 5 feeds"))
        next.tap(); ready(next)
        XCTAssertTrue(dusk.label.contains("4 of 5 feeds"))
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("1 feeding shower left"))
        capture(app,"dusk-imminent")
        app.buttons["experiment.settings"].tap()
        ready(app.buttons["experiment.done"]); app.buttons["experiment.done"].tap()
        XCUIDevice.shared.press(.home); app.activate(); ready(next)
        XCTAssertTrue(dusk.label.contains("4 of 5 feeds"))
        next.tap(); ready(next)
        XCTAssertFalse(dusk.label.hasPrefix("Dusk"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Amber"))
        XCTAssertFalse(app.staticTexts["dusk.cue"].exists)
        let committedBoard = app.otherElements["experiment.board"].value as? String
        let survivor = app.buttons["experiment.cell.0.2"].label
        capture(app,"dusk-consumed-and-settled")
        app.terminate(); app.launchArguments = ["--dialogue-review"]; app.launch()
        let resume=app.buttons["sky.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout:10)); resume.tap(); ready(next)
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertFalse(dusk.label.hasPrefix("Dusk"))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String,committedBoard)
        XCTAssertEqual(app.buttons["experiment.cell.0.2"].label,survivor)
    }
    @MainActor func testClearEarlyReleasesColorAndZeroRewardMatchStillClears() {
        let app = launch("imminent"); defer { app.terminate() }
        let amber=app.buttons["experiment.cell.0.2"]
        XCTAssertTrue(amber.label.contains("drained by Dusk"))
        XCTAssertTrue((amber.value as? String ?? "").contains("1 starlight if cleared"))
        ready(amber); amber.tap(); ready(app.buttons["experiment.next"])
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"1 starlight")
        XCTAssertFalse(app.buttons["experiment.cell.0.4"].label.contains("drained"))
        XCTAssertFalse(app.buttons["experiment.cell.0.3"].label.hasPrefix("Dusk"))
        capture(app,"dusk-cleared-color-restored")
        app.terminate(); app.launchArguments = ["--starfalls-reset","--dialogue-review","--dusk-fixture=zeroClear"]; app.launch()
        let mint=app.buttons["experiment.cell.0.1"]
        XCTAssertTrue(mint.waitForExistence(timeout:10)); ready(mint)
        XCTAssertTrue((mint.value as? String ?? "").contains("0 starlight if cleared"))
        mint.doubleTap(); ready(app.buttons["experiment.next"])
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.hasPrefix("Empty"))
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].label.hasPrefix("Empty"))
        capture(app,"dusk-valid-zero-clear")
    }
    @MainActor func testReducedMotionLargestTextKeepsThreatAndOutcomeReadable() {
        let (settings, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: motion); settings.terminate()
        defer {
            let (settings, motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: motion); settings.terminate()
        }
        let app = launch("imminent", extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        defer { app.terminate() }
        let cue = app.staticTexts["experiment.message"], next = app.buttons["experiment.next"]
        for _ in 0..<5 { if cue.isHittable && cue.frame.maxY <= app.frame.maxY { break }; app.swipeUp() }
        XCTAssertTrue(cue.isHittable)
        XCTAssertTrue(cue.label.contains("1 feeding shower left"))
        XCTAssertLessThanOrEqual(cue.frame.maxY,app.frame.maxY)
        capture(app,"dusk-imminent-largest-reduced")
        for _ in 0..<8 {
            if next.isHittable && next.frame.minY >= 0 && next.frame.maxY <= app.frame.maxY { break }
            if next.frame.maxY > app.frame.maxY { app.swipeUp() } else { app.swipeDown() }
        }
        ready(next); next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 7))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertFalse(app.buttons["experiment.cell.0.3"].label.hasPrefix("Dusk"))
        XCTAssertTrue(app.buttons["experiment.cell.1.2"].label.contains("Aqua"))
    }

}
