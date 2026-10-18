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
    @MainActor func testExtraCalmWavePairReachesFieldAndTwoClearsThroughNativeInput() {
        let app=launch("naturalOffer");defer {app.terminate()}
        score(18,app)
        let magnets=app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Attraction field'"))
        XCTAssertEqual(magnets.count,2)
        capture("extra-window-natural-pair",app)
        let next=app.buttons["experiment.next"];ready(next);next.tap()
        let first=app.buttons["experiment.cell.0.0"];ready(first);first.tap();score(21,app)
        ready(next);next.tap()
        let middle=app.buttons["experiment.cell.0.3"];ready(middle);middle.tap();score(24,app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","after 3 more showers"),object:middle).wait(timeout:8))
        capture("extra-window-natural-collision",app)
        ready(next);next.tap();ready(middle)
        XCTAssertTrue(middle.label.contains("after 2 more showers"));capture("extra-window-natural-choice",app)
        let higher=app.buttons["experiment.cell.1.2"];ready(higher);higher.tap();score(26,app)
        let followup=app.buttons["experiment.cell.0.1"];ready(followup);capture("extra-window-second-clear",app)
        followup.tap();score(30,app)
        capture("extra-window-six-light-outcome",app)
    }
    @MainActor func testAlternativeClearLargestTextSettingsBackgroundAndRetainedRestore() {
        let app=launch("naturalOpportunity",large:true);defer {app.terminate()}
        score(24,app);capture("extra-window-choice-largest-text",app)
        let first=app.buttons["experiment.cell.0.1"];ready(first);first.tap();score(26,app)
        let second=app.buttons["experiment.cell.1.2"];ready(second);second.tap();score(30,app)
        app.buttons["experiment.settings"].tap()
        let done=app.buttons["experiment.done"];XCTAssertTrue(done.waitForExistence(timeout:5));done.tap()
        XCUIDevice.shared.press(.home);app.activate();score(30,app)
        app.terminate();app.launchArguments=[];app.launch()
        let resume=app.buttons["sky.resume"];XCTAssertTrue(resume.waitForExistence(timeout:10));resume.tap()
        score(30,app);capture("extra-window-six-light-restored",app)
    }
}


final class GravityRetirementNativeTests: XCTestCase {
    @MainActor private func ready(_ button: XCUIElement) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 8))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testOldOrbitRestoreReleasesStarsAndPreservesRound() {
        continueAfterFailure = false
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--starfalls-reset", "--gravity-fixture=opportunity", "-calmEffects", "NO"]
        app.launch()
        let middle = app.buttons["experiment.cell.0.3"]
        XCTAssertTrue(middle.waitForExistence(timeout: 10)); ready(middle); middle.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS 'Gravity hole'"), object: middle).wait(timeout: 8))
        ready(middle); app.terminate(); app.launchArguments = []; app.launch()
        let resume = app.buttons["sky.resume"]; XCTAssertTrue(resume.waitForExistence(timeout: 10)); resume.tap()
        XCTAssertTrue(middle.waitForExistence(timeout: 8)); ready(middle)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "3 starlight")
        let specials = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND (label CONTAINS 'Attraction field' OR label CONTAINS 'Gravity hole')"))
        XCTAssertEqual(specials.count, 0)
        capture(app, "retired-orbit-restored")
        let next = app.buttons["experiment.next"]; ready(next); next.tap(); ready(next)
        XCTAssertEqual(specials.count, 0)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]; XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        ready(next); capture(app, "retired-orbit-ordinary-shower")
    }
    @MainActor func testOldPairRestoreRemovesBothFieldsWithoutLosingScore() {
        continueAfterFailure = false
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--starfalls-reset", "--gravity-fixture=naturalOffer", "-calmEffects", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "18 starlight")
        app.terminate(); app.launchArguments = []; app.launch()
        let resume = app.buttons["sky.resume"]; XCTAssertTrue(resume.waitForExistence(timeout: 10)); resume.tap()
        let next = app.buttons["experiment.next"]; XCTAssertTrue(next.waitForExistence(timeout: 8)); ready(next)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "18 starlight")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND (label CONTAINS 'Attraction field' OR label CONTAINS 'Gravity hole')")).count, 0)
        capture(app, "retired-pair-restored")
    }
}
