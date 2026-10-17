
final class ConstellationNativeTests: XCTestCase {
    @MainActor private func open(_ fixture: String? = "five", large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        if let fixture { app.launchArguments += ["--constellation-fixture=\(fixture)"] }
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func score(_ value: Int, _ app: XCUIApplication) {
        let label = app.staticTexts["experiment.score"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: label).wait(timeout: 6))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testFiveStarTapWholeGroupAndRelaunchRestore() {
        let app = open(); defer { app.terminate() }
        let cell = app.buttons["experiment.cell.1.3"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5)); XCTAssertTrue(cell.isHittable)
        if __CANDIDATE__ { XCTAssertTrue((cell.value as? String)?.contains("5 matching stars, 5 starlight") == true) }
        capture(app, "constellation-five-before")
        cell.tap()
        score(__CANDIDATE__ ? 5 : 0, app)
        capture(app, "constellation-five-after")
        app.terminate(); app.launchArguments = []; app.launch()
        score(__CANDIDATE__ ? 5 : 0, app)
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 5))
    }
    @MainActor func testDarknessAndOverlapAndFourGrown() {
        for (fixture, expected) in [("darkness",5),("overlap",7),("fourGrown",0)] {
            let app = open(fixture)
            app.buttons[fixture == "fourGrown" ? "experiment.cell.0.0" : "experiment.cell.1.3"].tap()
            score(__CANDIDATE__ ? expected : 0, app)
            if fixture == "darkness" && __CANDIDATE__ {
                XCTAssertTrue(app.buttons["experiment.cell.0.2"].label.contains("Dusk"))
                XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("Dark star dissolved"))
            }
            app.terminate()
        }
    }
    @MainActor func testMenuFixtureDismissalBackgroundAndNormalOpening() {
        let app = open(nil); defer { app.terminate() }
        app.buttons["experiment.next"].tap()
        let cell = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND value CONTAINS '3 starlight' ")).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: cell).wait(timeout: 6))
        cell.tap(); score(3, app)
        app.buttons["experiment.settings"].tap()
        let example = app.buttons["lab.fixture.five"]
        for _ in 0..<3 where !example.isHittable { app.swipeUp() }
        XCTAssertTrue(example.isHittable); example.tap(); score(0, app)
        XCTAssertTrue(app.buttons["experiment.cell.1.3"].waitForExistence(timeout: 5))
        app.buttons["experiment.cell.1.3"].tap()
        score(__CANDIDATE__ ? 5 : 0, app)
        XCUIDevice.shared.press(.home)
        app.activate()
        score(__CANDIDATE__ ? 5 : 0, app)
        XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
    }
    @MainActor func testLargestTextFixtureInput() {
        let app = open("five", large: true); defer { app.terminate() }
        let cell = app.buttons["experiment.cell.1.3"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5)); XCTAssertTrue(cell.isHittable)
        cell.tap(); score(__CANDIDATE__ ? 5 : 0, app)
        capture(app, "constellation-largest-text-clear")
    }
}

extension ConstellationNativeTests {
    @MainActor func testSystemReduceMotionFiveStarClear() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String
        if original != "1" { reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap() }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "1"), object: reduce).wait(timeout: 5))
        defer {
            preferences.terminate()
            let (restoredPreferences, restored) = NativeSystemMotionSettings.open()
            if let original, restored.value as? String != original {
                restored.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            }
            if let original { XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", original), object: restored).wait(timeout: 5)) }
            restoredPreferences.terminate()
        }
        let app = open(); defer { app.terminate() }
        app.buttons["experiment.cell.1.3"].tap()
        score(__CANDIDATE__ ? 5 : 0, app)
        capture(app, "constellation-system-reduce-motion")
    }

    @MainActor func testActualVoiceOverSpeaksCountValueAndActivatesConstellation() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        let service = XCUIDevice.shared.voiceOverService
        let original = service.isEnabled
        addTeardownBlock { @MainActor in
            if !original { try XCUIDevice.shared.voiceOverService.disable() }
            XCTAssertEqual(XCUIDevice.shared.voiceOverService.isEnabled, original)
        }
        try service.enable()
        let app = open(); addTeardownBlock { @MainActor in app.terminate() }
        let cell = app.buttons["experiment.cell.1.3"]
        let expected = __CANDIDATE__ ? "5 matching stars" : "1 starlight"
        cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        var utterances: [String] = []
        let spoken = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let utterance = (try? service.currentSpeech().utterance) ?? ""
            if !utterance.isEmpty && utterances.last != utterance { utterances.append(utterance) }
            let combined = utterances.joined(separator: "\n")
            return combined.contains(expected) && (!__CANDIDATE__ || combined.contains("5 starlight"))
        }, object: nil).wait(timeout: 8)
        let speech = utterances.joined(separator: "\n")
        let attachment = XCTAttachment(string: speech)
        attachment.name = "Constellation-focused-VoiceOver"; attachment.lifetime = .keepAlways; add(attachment)
        XCTAssertTrue(spoken, speech)
        XCTAssertTrue(speech.contains(expected), speech)
        if __CANDIDATE__ { XCTAssertTrue(speech.contains("5 starlight"), speech) }
        cell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        score(__CANDIDATE__ ? 5 : 0, app)
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }
}
