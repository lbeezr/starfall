final class GravityTraceUITests: XCTestCase {
    @MainActor func testNativeTraceSpendsFiveCaptivesAndPreservesSixth() {
        continueAfterFailure=false
        let app=XCUIApplication(); app.launchArguments=["--starfalls-reset","--gravity-fixture=trace"]; app.launch()
        let middle=app.buttons["experiment.cell.0.3"]
        XCTAssertTrue(middle.waitForExistence(timeout:10)); middle.tap()
        let start=app.buttons["experiment.cell.0.2"], end=app.buttons["experiment.cell.4.2"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:start).wait(timeout:8))
        start.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).press(forDuration:0.1,
            thenDragTo:end.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)),withVelocity:.slow,thenHoldForDuration:0.1)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","13 starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:8))
        XCTAssertFalse(middle.label.contains("Gravity hole"))
        XCTAssertTrue(start.label.contains("Spark"),"The sixth, untraced aqua settles after release")
        let capture=XCTAttachment(screenshot:XCUIScreen.main.screenshot());capture.name="gravity-trace-release";capture.lifetime = .keepAlways;add(capture)
    }
}
