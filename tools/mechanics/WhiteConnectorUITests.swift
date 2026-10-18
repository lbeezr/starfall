final class WhiteConnectorNativeTests: XCTestCase {
    @MainActor private func open(_ fixture: String, large: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--white-fixture=\(fixture)"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10))
        ready(app, boardOnly: large)
        return app
    }
    @MainActor private func ready(_ app: XCUIApplication, boardOnly: Bool = false) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: app.buttons[boardOnly ? "experiment.cell.0.0" : "experiment.next"]).wait(timeout: 6))
    }
    @MainActor private func score(_ value: Int, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"),
                                               object: app.staticTexts["experiment.score"]).wait(timeout: 6))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testWhiteIdentityExclusiveClearAndRestore() {
        let app = open("connection"); defer { app.terminate() }
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("counts as 1"))
        let white = app.buttons["experiment.cell.1.1"]
        XCTAssertTrue(white.label.contains("White connector"))
        XCTAssertEqual(white.value as? String, "Shared connector")
        XCTAssertEqual(app.buttons["experiment.cell.0.1"].value as? String, "3 light, spends white")
        capture(app, "white-connection-before")
        white.tap(); score(0, app)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("colored neighbor"))
        app.buttons["experiment.cell.0.1"].tap(); score(3, app); ready(app)
        XCTAssertTrue(app.buttons["experiment.cell.1.1"].label.contains("Empty"))
        XCTAssertEqual(app.buttons["experiment.cell.1.0"].value as? String, "1 starlight connected")
        capture(app, "white-connection-spent")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10)); score(3, app)
    }
    @MainActor func testWhiteHoldAndPressureBranches() {
        var app = open("connection")
        app.buttons["experiment.next"].tap(); ready(app)
        app.buttons["experiment.cell.1.0"].tap(); score(4, app); ready(app)
        capture(app, "white-held-connection-four"); app.terminate()
        app = open("pressure")
        capture(app, "white-pressure-before")
        app.buttons["experiment.cell.0.0"].tap(); score(3, app); ready(app)
        app.buttons["experiment.next"].tap(); ready(app)
        XCTAssertFalse(app.buttons["experiment.replay"].exists)
        capture(app, "white-smaller-survives"); app.terminate()
        app = open("pressure")
        app.buttons["experiment.cell.0.2"].tap(); score(4, app); ready(app)
        app.buttons["experiment.next"].tap()
        XCTAssertTrue(app.buttons["experiment.replay"].waitForExistence(timeout: 8))
        capture(app, "white-larger-overflows"); app.terminate()
    }
    @MainActor func testWhiteMenuBackgroundAndLargestText() {
        let app = open("connection", large: true); defer { app.terminate() }
        capture(app, "white-largest-text-before")
        app.buttons["experiment.settings"].tap()
        let fixture = app.buttons["white.fixture.pressure"]
        for _ in 0..<3 where !fixture.isHittable { app.swipeUp() }
        XCTAssertTrue(fixture.isHittable); fixture.tap()
        ready(app, boardOnly: true)
        XCUIDevice.shared.press(.home); app.activate(); ready(app, boardOnly: true)
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.contains("White connector"))
        app.buttons["experiment.cell.0.0"].tap(); score(3, app); ready(app, boardOnly: true)
        capture(app, "white-largest-text-after-native-tap")
    }

    @MainActor func testActualVoiceOverExplainsWhiteAndActivatesColoredAnchor() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        let service = XCUIDevice.shared.voiceOverService
        let wasEnabled = service.isEnabled
        addTeardownBlock { @MainActor in
            if !wasEnabled { try XCUIDevice.shared.voiceOverService.disable() }
            XCTAssertEqual(XCUIDevice.shared.voiceOverService.isEnabled, wasEnabled)
        }
        try service.enable()
        let app = open("connection")
        addTeardownBlock { @MainActor in app.terminate() }
        let white = app.buttons["experiment.cell.1.1"]
        var transcript = [NativeVoiceOverFocus.speech(afterTouching: white, containing: "White connector")]
        addTeardownBlock { @MainActor in
            let attachment = XCTAttachment(string: transcript.joined(separator: "\n"))
            attachment.name = "White-connector-actual-VoiceOver"; attachment.lifetime = .keepAlways; self.add(attachment)
        }
        XCTAssertTrue(transcript[0].contains("White connector"))
        white.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        score(0, app)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("colored neighbor"))
        let colored = app.buttons["experiment.cell.0.1"]
        let speech = NativeVoiceOverFocus.speech(afterTouching: colored, containing: "spends white")
        transcript.append(speech)
        XCTAssertTrue(speech.contains("3 light"), speech)
        XCTAssertTrue(speech.contains("spends white"), speech)
        colored.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        score(3, app); ready(app)
        capture(app, "white-voiceover-committed-clear")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }
}
