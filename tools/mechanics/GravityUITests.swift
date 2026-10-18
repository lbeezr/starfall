final class GravityUITests: XCTestCase {
    @MainActor private func launch(_ fixture: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--starfalls-reset","--gravity-fixture=\(fixture)"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.3"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func ready(_ cell: XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true AND hittable == true"),object:cell).wait(timeout:8))
    }
    @MainActor private func capture(_ name: String) {
        let image=XCTAttachment(screenshot:XCUIScreen.main.screenshot()); image.name=name; image.lifetime = .keepAlways
        add(image)
    }
    @MainActor func testFloorCollisionOrbitClearAndRestore() {
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); capture("gravity-before"); middle.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Gravity hole"),object:middle).wait(timeout:8))
        ready(middle); capture("gravity-captured")
        let next=app.buttons["experiment.next"]; XCTAssertTrue(next.waitForExistence(timeout:5)); next.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","Sunny"),object:left).wait(timeout:8))
        capture("gravity-rotated"); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole")); capture("gravity-released")
        app.terminate(); app.launchArguments=[]; app.launch()
        let resume=app.buttons["sky.resume"]; XCTAssertTrue(resume.waitForExistence(timeout:10)); resume.tap()
        XCTAssertTrue(middle.waitForExistence(timeout:8)); XCTAssertFalse(middle.label.contains("Gravity hole"))
    }
    @MainActor func testTakeNowAndMenuDismissal() {
        let app=launch("takeNow"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole"))
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout:5)); app.buttons["Done"].tap()
        ready(left); capture("gravity-take-now")
    }
    @MainActor func testBackgroundPreservesOrbitAndThreeWindowsExpire() {
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        XCTAssertTrue(middle.label.contains("3 windows"))
        XCUIDevice.shared.press(.home); app.activate(); ready(middle)
        XCTAssertTrue(middle.label.contains("3 windows"))
        for remaining in [2,1,0] {
            let next=app.buttons["experiment.next"]; ready(next); next.tap(); ready(middle)
            if remaining > 0 { XCTAssertTrue(middle.label.contains("\(remaining) windows")) }
            else { XCTAssertFalse(middle.label.contains("Gravity hole")) }
        }
        capture("gravity-expired-after-background")
    }
    @MainActor func testLargestTextKeepsCaptiveAndMenuUsable() {
        let app=launch("takeNow",large:true), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        capture("gravity-largest-text")
        app.buttons["experiment.settings"].tap()
        let done=app.buttons["experiment.done"]; XCTAssertTrue(done.waitForExistence(timeout:5)); done.tap()
        let captive=app.buttons["experiment.cell.0.2"]; ready(captive); captive.tap(); ready(captive)
        XCTAssertFalse(middle.label.contains("Gravity hole"))
    }
    @MainActor func testSystemReduceMotionPreservesOrbitOutcome() {
        let (preferences,reduce)=NativeSystemMotionSettings.open()
        let original=reduce.value as? String
        if original != "1" { reduce.coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap() }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","1"),object:reduce).wait(timeout:5))
        defer {
            preferences.terminate()
            let (restoring,switchControl)=NativeSystemMotionSettings.open()
            if let original, switchControl.value as? String != original {
                switchControl.coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap()
            }
            if let original { XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@",original),object:switchControl).wait(timeout:5)) }
            restoring.terminate()
        }
        let app=launch("opportunity"), middle=app.buttons["experiment.cell.0.3"]
        ready(middle); middle.tap(); ready(middle)
        let next=app.buttons["experiment.next"]; ready(next); next.tap()
        let left=app.buttons["experiment.cell.0.2"]; ready(left)
        XCTAssertTrue(left.label.contains("Sunny")); left.tap(); ready(left)
        XCTAssertFalse(middle.label.contains("Gravity hole")); capture("gravity-system-reduce-motion")
    }

}
