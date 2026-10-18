import XCTest

final class CriticalMassInteractionTests: XCTestCase {
    @MainActor private func launch(extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--critical-mass-review", "-calmEffects", "NO"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func ready(_ element: XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: element).wait(timeout: 8))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testWarningSwallowRestoreAndSettings() {
        let app = launch(); defer { app.terminate() }
        let star = app.buttons["experiment.cell.0.2"], next = app.buttons["experiment.next"]
        XCTAssertTrue(star.label.contains("Stage 3"))
        XCTAssertTrue(star.label.contains("implodes in 1 shower"))
        capture(app, "critical-mass-warning")
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap(); ready(next)
        XCTAssertTrue(star.label.contains("implodes in 1 shower"))
        XCUIDevice.shared.press(.home); app.activate(); ready(next)
        XCTAssertTrue(star.label.contains("Stage 3"))
        next.tap(); ready(next)
        XCTAssertTrue(star.label.hasPrefix("Empty"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        capture(app, "critical-mass-settled")
        let committed = app.otherElements["experiment.board"].value as? String
        app.terminate(); app.launchArguments = ["--dialogue-review"]; app.launch()
        let resume = app.buttons["sky.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10)); resume.tap()
        XCTAssertTrue(next.waitForExistence(timeout: 10)); ready(next)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, committed)
    }
    @MainActor func testRescueRemainsARealScoringTap() {
        let app = launch(); defer { app.terminate() }
        let star = app.buttons["experiment.cell.0.2"]
        ready(star); star.doubleTap(); ready(app.buttons["experiment.next"])
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "4 starlight")
        XCTAssertTrue(star.label.hasPrefix("Empty"))
        capture(app, "critical-mass-rescue")
    }
    @MainActor func testLargestTextCalmKeepsWarningAndHelpUsable() {
        let app = launch(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-calmEffects", "YES"])
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Stage 3"))
        capture(app, "critical-mass-largest-text")
        app.buttons["experiment.settings"].tap()
        let help = app.buttons["experiment.help"]
        for _ in 0..<6 {
            if help.exists && help.isHittable { break }
            app.swipeUp()
        }
        ready(help); help.tap()
        let text = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Every star, including Opal, ages")).firstMatch
        for _ in 0..<12 {
            if text.exists && text.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(text.exists); XCTAssertTrue(text.isHittable)
        capture(app, "critical-mass-help-largest-text")
        app.buttons["experiment.done"].tap()
        let next = app.buttons["experiment.next"]
        for _ in 0..<5 {
            if next.isHittable { break }
            app.swipeUp()
        }
        ready(next)
        capture(app, "critical-mass-largest-text-controls")
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Stage 3"))
    }
    @MainActor func testSystemReduceMotionPreservesImplosionOutcome() {
        let (settings, motion) = NativeSystemMotionSettings.open()
        let original = motion.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: motion); settings.terminate()
        defer {
            let (settings, motion) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: motion); settings.terminate()
        }
        let app = launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Stage 3"))
        let next = app.buttons["experiment.next"]
        ready(next); next.tap(); ready(next)
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.hasPrefix("Empty"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        capture(app, "critical-mass-system-reduce-motion")
    }

}
