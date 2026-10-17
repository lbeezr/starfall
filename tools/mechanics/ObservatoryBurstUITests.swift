final class ObservatoryBurstPhaseTests: XCTestCase {
    @MainActor func testPhaseBoundariesAndProjectedClearsSurviveMenuAndRestore() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        app.launch(); defer { app.terminate() }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue((board.value as? String)?.hasPrefix("8 showers,") == true)
        let initialScore = app.staticTexts["experiment.score"].label
        let next = app.buttons["experiment.next"]
        for remaining in stride(from: 3, through: 0, by: -1) {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            let expected = remaining == 0 ? "Recovery · 9 calmer showers" : "__BURST_COUNT__"
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", expected), object: cue)], timeout: 5), .completed)
            XCTAssertLessThanOrEqual(cue.frame.maxY, app.buttons["experiment.cell.6.3"].frame.minY,
                "Phase information stays above the projected landing surface")
            clearCanonicalBurstGroup(in: app)
        }
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Recovery · 8 calmer showers"), object: cue)], timeout: 5), .completed)
        let score = app.staticTexts["experiment.score"].label
        XCTAssertNotEqual(score, initialScore)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Observatory-phase-recovery"; capture.lifetime = .keepAlways; add(capture)
        app.buttons["experiment.settings"].tap()
        let done = app.buttons["experiment.done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        XCTAssertEqual(cue.label, "Recovery · 8 calmer showers")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
    }

    @MainActor func testLargestTextKeepsPhaseVisibleAtManualControls() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        let next = app.buttons["experiment.next"]
        for _ in 0..<8 where !next.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(next.isHittable)
        XCTAssertEqual(cue.label, "__BURST_WARNING__")
        XCTAssertLessThan(cue.frame.height, 120, "Short phase copy preserves room for play at maximum text")
        XCTAssertGreaterThanOrEqual(cue.frame.minY, app.frame.minY)
        XCTAssertLessThanOrEqual(cue.frame.maxY, app.frame.maxY)
        next.tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "__BURST_THREE__"), object: cue)], timeout: 5), .completed)
        XCTAssertLessThan(cue.frame.height, 120)
        let capture = XCTAttachment(screenshot: app.screenshot())
        capture.name = "Observatory-phase-largest-text"; capture.lifetime = .keepAlways; add(capture)
    }
}

extension ObservatoryBurstPhaseTests {
    @MainActor func testVoiceOverReadsWarningAndActivatesManualShower() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let service = XCUIDevice.shared.voiceOverService
        let wasEnabled = service.isEnabled
        // XCTest aborts can bypass Swift defer. Register service restoration first.
        addTeardownBlock { @MainActor in
            if !wasEnabled { try XCUIDevice.shared.voiceOverService.disable() }
            XCTAssertEqual(XCUIDevice.shared.voiceOverService.isEnabled, wasEnabled)
        }
        try service.enable()
        XCTAssertTrue(service.isEnabled)
        let app = XCUIApplication(bundleIdentifier: "__LAB_BUNDLE__")
        app.launchArguments = ["--starfalls-reset", "--shower-phase-fixture"]
        addTeardownBlock { @MainActor in app.terminate() }
        app.launch()
        var transcript: [String] = []
        defer {
            let attachment = XCTAttachment(string: transcript.joined(separator: "\n"))
            attachment.name = "Observatory-phase-VoiceOver-speech"; attachment.lifetime = .keepAlways; add(attachment)
        }
        func awaitSpeech(_ accepts: @escaping (String) -> Bool) {
            var latest = ""
            let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                latest = (try? service.currentSpeech().utterance) ?? ""
                return accepts(latest)
            }, object: nil)
            let result = XCTWaiter.wait(for: [expectation], timeout: 5)
            transcript.append(latest)
            let attachment = XCTAttachment(string: transcript.joined(separator: "\n"))
            attachment.name = "VoiceOver-speech-before-assertion"; attachment.lifetime = .keepAlways; add(attachment)
            XCTAssertEqual(result, .completed, "Unexpected VoiceOver speech: \(latest)")
        }
        let cue = app.staticTexts["lab.phase"]
        XCTAssertTrue(cue.waitForExistence(timeout: 10))
        cue.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        awaitSpeech { $0.localizedCaseInsensitiveContains("after this shower") }
        let next = app.buttons["experiment.next"]
        next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        awaitSpeech { $0.localizedCaseInsensitiveContains("Next shower") }
        // Double-tap at the focused native control, matching the player's gesture.
        next.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "__BURST_THREE__"), object: cue)], timeout: 5), .completed)
        cue.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        awaitSpeech {
            $0.localizedCaseInsensitiveContains("Surge") && $0.localizedCaseInsensitiveContains("five")
                && ($0.contains("3") || $0.localizedCaseInsensitiveContains("three"))
        }
        let guide = app.staticTexts["experiment.message"]
        guide.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        awaitSpeech { $0.localizedCaseInsensitiveContains("grew") && $0.localizedCaseInsensitiveContains("worth 2") }
        // currentSpeech() documents focused-element speech. It cannot prove
        // delivery of an unsolicited UIAccessibility announcement.
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }
}
