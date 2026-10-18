import XCTest

final class GravityOpportunityNativeTests:XCTestCase {
    @MainActor private func launch(_ fixture:String,large:Bool=false)->XCUIApplication {
        continueAfterFailure=false
        let app=XCUIApplication()
        app.launchArguments=["--starfalls-reset","--gravity-fixture=\(fixture)"]
        if large {app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"]}
        app.launch()
        XCTAssertTrue(app.buttons["experiment.cell.0.3"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func ready(_ element:XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true AND hittable == true"),object:element).wait(timeout:8))
    }
    @MainActor private func score(_ value:Int,_ app:XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","\(value) starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:6))
    }
    @MainActor private func capture(_ name:String,_ app:XCUIApplication) {
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name=name;attachment.lifetime = .keepAlways;add(attachment)
    }
    @MainActor func testExtraCalmWavePairReachesFieldAndHigherFollowupThroughNativeInput() {
        let app=launch("naturalOffer");defer {app.terminate()}
        score(18,app)
        let magnets=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Attraction field'"))
        XCTAssertEqual(magnets.count,2)
        capture("extra-window-natural-pair",app)
        let next=app.buttons["experiment.next"];ready(next);next.tap()
        let first=app.buttons["experiment.cell.0.0"];ready(first);first.tap();score(21,app)
        ready(next);next.tap()
        let middle=app.buttons["experiment.cell.0.3"];ready(middle);middle.tap();score(24,app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","3 windows"),object:middle).wait(timeout:8))
        capture("extra-window-natural-collision",app)
        ready(next);next.tap();ready(middle)
        XCTAssertTrue(middle.label.contains("2 windows"));capture("extra-window-natural-choice",app)
        let higher=app.buttons["experiment.cell.1.2"];ready(higher);higher.tap();score(28,app)
        let followup=app.buttons["experiment.cell.0.1"];ready(followup);capture("extra-window-higher-followup",app)
        followup.tap();score(32,app)
        capture("extra-window-eight-light-outcome",app)
    }
    @MainActor func testAlternativeClearLargestTextSettingsBackgroundAndRetainedRestore() {
        let app=launch("naturalOpportunity",large:true);defer {app.terminate()}
        score(24,app);capture("extra-window-choice-largest-text",app)
        let first=app.buttons["experiment.cell.0.1"];ready(first);first.tap();score(27,app)
        let second=app.buttons["experiment.cell.1.2"];ready(second);second.tap();score(31,app)
        app.buttons["experiment.settings"].tap()
        let done=app.buttons["experiment.done"];XCTAssertTrue(done.waitForExistence(timeout:5));done.tap()
        XCUIDevice.shared.press(.home);app.activate();score(31,app)
        app.terminate();app.launchArguments=[];app.launch()
        let resume=app.buttons["sky.resume"];XCTAssertTrue(resume.waitForExistence(timeout:10));resume.tap()
        score(31,app);capture("extra-window-seven-light-restored",app)
    }
}
