extension ObservatoryFeedbackTests {
    @MainActor func testDarkArrivalRemovalAndUnrelatedClearFeedback() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        addTeardownBlock { @MainActor in app.terminate() }
        app.launch()
        let guide = app.staticTexts["experiment.message"]
        XCTAssertTrue(guide.waitForExistence(timeout: 10))
        func waitForGuide(_ part: String) {
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
                format: "label CONTAINS %@", part), object: guide).wait(timeout: 5))
        }
        func clear(_ row: Int, _ column: Int, value: Int) {
            let cell = app.buttons["experiment.cell.\(row).\(column)"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
                format: "enabled == true"), object: cell).wait(timeout: 5))
            XCTAssertEqual(cell.value as? String, "\(value) starlight connected")
            cell.tap(); waitForGuide("+\(value) starlight.")
        }
        let next = app.buttons["experiment.next"]
        next.tap(); waitForGuide("grew")
        clear(0, 0, value: 4)
        next.tap(); waitForGuide("A dark star blocks nearby growth")
        clear(0, 1, value: 4)
        next.tap(); waitForGuide("grew")
        clear(0, 2, value: 3); waitForGuide("Dark star dissolved")
        let dark = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Dark star, Dusk"))
        XCTAssertEqual(dark.count, 1)
        clear(3, 4, value: 3)
        XCTAssertFalse(guide.label.localizedCaseInsensitiveContains("dissolved"))
        XCTAssertEqual(dark.count, 1, "The unrelated clear leaves a dark star")
        let score = app.staticTexts["experiment.score"].label
        let state = app.otherElements["experiment.board"].value as? String
        dark.firstMatch.tap(); waitForGuide("Clear a matching group beside the dark star")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, state)
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Paused-dark-star-guidance"; image.lifetime = .keepAlways; add(image)
    }
}
