import XCTest
import UIKit

final class ObservatoryInteractionTests: XCTestCase {
    @MainActor private func launch(dense: Bool = false, calm: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--observatory-review", "-landingPlace", "observatory"]
        if dense { app.launchArguments.append("--observatory-dense") }
        app.launchArguments += ["-calmEffects", calm ? "YES" : "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func capture(_ app: XCUIApplication, _ title: String) {
        let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        image.name = title; image.lifetime = .keepAlways; add(image)
    }
    @MainActor func testCelestialHUDGuideAndMenuPagesKeepTheRound() {
        let app = launch(); defer { app.terminate() }
        let menu = app.buttons["experiment.settings"]
        XCTAssertGreaterThanOrEqual(menu.frame.width, 44)
        XCTAssertEqual(app.staticTexts["experiment.message"].label, "Sunny. Tap a matching group to clear it. Small stars count as 1; grown stars count as 2. You need a total of 3. Dusk will eat 4 stars after 5 more showers with a touching star.")
        let before = app.otherElements["experiment.board"].value as? String
        capture(app, "Celestial-HUD-welcome")
        menu.tap()
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "Celestial-menu")
        app.skyMenuControl("experiment.help").tap()
        XCTAssertTrue(app.staticTexts["Tap a matching group"].waitForExistence(timeout: 5))
        capture(app, "Celestial-how-to-play")
        app.navigationBars.buttons["Sky menu"].tap()
        app.skyMenuControl("experiment.balance").tap()
        XCTAssertTrue(app.buttons["experiment.pace"].waitForExistence(timeout: 5))
        capture(app, "Celestial-balance")
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before)
        XCTAssertFalse(app.buttons["landing.lantern"].exists)
    }
    /// Captures overlap for visual read-through; AX labels alone do not prove visible text.
    @MainActor func testLargestTextHelpReadsThroughAndReturnsToUnchangedRound() {
        executionTimeAllowance = 240
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=64", "-calmEffects", "NO",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(menu.waitForExistence(timeout: 10))
        let before = app.otherElements["experiment.board"].value as? String
        XCTAssertNotNil(before)
        menu.tap()
        app.skyMenuControl("experiment.help").tap()
        let navigation = app.navigationBars["How to play"]
        XCTAssertTrue(navigation.waitForExistence(timeout: 5))
        let last = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@",
            "Restore Lantern Landing with 18 starlight.")).firstMatch
        var reachedEnd = false
        // The original 48-step budget was sampled on 16 Pro Max. On 17e,
        // XXXL still reaches the swaps section at step 47; preserve overlapping
        // read-through and the same final-line/state assertions on the narrower screen.
        let maximumReadingScrolls = app.frame.width < 420 ? 72 : 48
        for step in 0..<maximumReadingScrolls {
            XCTAssertEqual(app.state, .runningForeground)
            XCTAssertTrue(navigation.exists, "Remain in help after every scroll")
            XCTAssertTrue(app.buttons["experiment.done"].isHittable)
            capture(app, String(format: "help-largest-step-%02d", step))
            if last.exists, last.isHittable, last.frame.maxY <= app.frame.maxY - 40 {
                reachedEnd = true
                break
            }
            // Stay inside the reading area; never start a drag at the Home indicator.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
                .press(forDuration: 0.05,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)),
                       withVelocity: .slow, thenHoldForDuration: 0)
        }
        XCTAssertTrue(reachedEnd, "Reach the last line with bounded, overlapping reading-area scrolls")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        let next = app.buttons["experiment.next"]
        app.revealSkyMenuElement(next)
        XCTAssertTrue(next.isHittable); XCTAssertTrue(next.isEnabled)
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value BEGINSWITH %@", "1 showers,"),
            object: app.otherElements["experiment.board"]).wait(timeout: 6))
        capture(app, "help-largest-return-and-next-shower")
    }
    @MainActor func testActualCastSparseDenseAndProjectedCornerTaps() {
        for dense in [false,true] {
            let app = launch(dense: dense)
            capture(app, dense ? "Observatory-real-cast-dense" : "Observatory-real-cast-sparse")
            // Hitting a native coordinate at the projected far/right cell exercises actual event dispatch.
            let back = app.buttons["experiment.cell.\(dense ? 6 : 2).6"]
            XCTAssertTrue(back.isHittable)
            let value = Int((back.value as! String).split(separator: ";").last!.split(separator: " ")[0])!
            XCTAssertGreaterThanOrEqual(value, 3)
            let point = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: back.frame.midX, dy: back.frame.midY))
            point.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            let front = app.buttons["experiment.cell.0.0"]
            XCTAssertTrue(front.isHittable)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: front).wait(timeout: 5))
            let second = Int((front.value as! String).split(separator: ";").last!.split(separator: " ")[0])!
            XCTAssertGreaterThanOrEqual(second, 3)
            front.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value+second) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            capture(app, dense ? "Observatory-dense-after-corner-clears" : "Observatory-sparse-after-corner-clears")
            app.terminate()
        }
    }
    @MainActor func testCastSettingsDismissalAndBackgroundPreserveBoard() {
        let app = launch(); defer { app.terminate() }
        let initial = app.otherElements["experiment.board"].value as? String
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, initial)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, initial)
        capture(app,"Observatory-after-settings-background")
    }
}





extension ObservatoryInteractionTests {


    @MainActor func testSupportedOrientationsPreserveNativeTargets() {
        let orientations: [UIDeviceOrientation] = UIDevice.current.userInterfaceIdiom == .pad
            ? [.portrait, .landscapeLeft, .landscapeRight] : [.portrait]
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            let app = launch(dense: true)
            let landscape = orientation == .landscapeLeft || orientation == .landscapeRight
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                landscape ? app.frame.width > app.frame.height : app.frame.height > app.frame.width
            }, object: nil).wait(timeout: 5), "Wait for the actual application viewport to rotate")
            let middle = app.buttons["experiment.cell.3.3"]
            XCTAssertEqual(middle.frame.midX, app.frame.midX, accuracy: 1)
            XCTAssertFalse(app.buttons["landing.telescope"].exists)
            XCTAssertFalse(app.buttons["landing.lantern"].exists)
            let back = app.buttons["experiment.cell.6.6"]
            XCTAssertGreaterThanOrEqual(back.frame.width, 44)
            XCTAssertGreaterThanOrEqual(back.frame.height, 44)
            let value = Int((back.value as! String).split(separator: ";").last!.split(separator: " ")[0])!
            back.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            capture(app,"Observatory-native-orientation-\(orientation.rawValue)")
            app.terminate()
        }
    }

    @MainActor func testRetiredPalettePreferenceCannotChangeSceneryOrRound() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5", "-skyEnvironment", "aurora"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String,"0 showers, 0 matching groups ready")
        app.buttons["experiment.settings"].tap()
        XCTAssertFalse(app.buttons["sky.environment"].exists)
        XCTAssertTrue(app.staticTexts["Moonwake"].exists)
    }
}



extension ObservatoryInteractionTests {
    /// Xcode 27's service drives the actual screen reader. Older SDKs retain the other native checks.
    @MainActor func testVoiceOverSpeechActivationPropsClearAndMenuFocus() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let app = XCUIApplication()
        let vo = try ObservatoryVoiceOverDriver(test: self, app: app)
        _ = launch(); defer { app.terminate() }
        func focus(_ element: XCUIElement, expecting text: String) throws {
            try vo.focus(element, expecting: text)
        }
        func activate() { vo.activate() }
        try focus(app.buttons["experiment.cell.1.3"], expecting: "Dusk")
        try focus(app.buttons["experiment.cell.3.6"], expecting: "Empty, row 4, column 7")
        try focus(app.buttons["experiment.cell.1.1"], expecting: "Large")
        try focus(app.buttons["experiment.cell.0.0"], expecting: "Sunny, row 7, column 1")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight", "Exploration must not clear a group")
        XCTAssertTrue(vo.transcript.last?.contains("5 starlight") == true)
        let nextCell = try vo.service.moveForward().utterance
        vo.transcript.append(nextCell)
        XCTAssertTrue(nextCell.contains("row 7, column 2"))
        let previousCell = try vo.service.moveBackward().utterance
        vo.transcript.append(previousCell)
        XCTAssertTrue(previousCell.contains("Sunny, row 7, column 1"))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "5 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        try focus(app.buttons["experiment.settings"], expecting: "Sky menu"); activate()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        try focus(app.buttons["experiment.done"], expecting: "Done"); activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            ((try? vo.service.currentSpeech().utterance) ?? "").localizedCaseInsensitiveContains("Sky menu")
        }, object: nil).wait(timeout: 5))
        capture(app,"Observatory-actual-VoiceOver-after-menu")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }

    @MainActor func testVoiceOverLargestTextOverflowAndReplay() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let app = XCUIApplication()
        let vo = try ObservatoryVoiceOverDriver(test: self, app: app)
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        try vo.focus(app.buttons["experiment.cell.0.6"], expecting: "row 7, column 7")
        // Sequential VoiceOver navigation must reveal the guide outside the viewport.
        try vo.advance(to: "Next shower", limit: 12)
        let next = app.buttons["experiment.next"]
        let outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<40 {
            if outcome.exists { break }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            let before = app.otherElements["experiment.board"].value as? String
            try vo.choose(next, expecting: "Next shower")
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || app.otherElements["experiment.board"].value as? String != before
            }, object: nil).wait(timeout: 5))
        }
        XCTAssertEqual(outcome.label, "No room to land")
        try vo.focus(outcome, expecting: "No room to land")
        capture(app, "VoiceOver-largest-text-overflow")
        try vo.advance(to: "Replay this sky", limit: 6)
        try vo.choose(app.buttons["experiment.replay"], expecting: "Replay this sky")
        XCTAssertFalse(outcome.exists)
        try vo.choose(app.buttons["sky.begin"], expecting: "Begin")
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.pause"], expecting: "Pause sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        try vo.focus(app.buttons["experiment.next"], expecting: "Next shower")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }

    @MainActor func testVoiceOverAutomaticRainMenuAndBackground() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let app = XCUIApplication()
        let vo = try ObservatoryVoiceOverDriver(test: self, app: app)
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        try vo.choose(app.buttons["experiment.pause"], expecting: "Start sky")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !(app.otherElements["experiment.board"].value as? String ?? "0 showers").hasPrefix("0 showers")
        }, object: nil).wait(timeout: 15))
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        try vo.choose(app.buttons["experiment.pause"], expecting: "Pause sky")
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        let pausedBoard = app.otherElements["experiment.board"].value as? String
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, pausedBoard)
        try vo.focus(app.buttons["experiment.next"], expecting: "Next shower")
        capture(app, "VoiceOver-automatic-rain-paused-after-background")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }

    @MainActor func testVoiceOverFullFirstLightRoundRestoreAndReplay() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let app = XCUIApplication()
        let vo = try ObservatoryVoiceOverDriver(test: self, app: app)
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.challenge"], expecting: "First Light")
        try vo.choose(app.buttons["sky.begin"], expecting: "Begin")
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.pause"], expecting: "Pause sky")
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        let outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<50 {
            if outcome.exists { break }
            let next = app.buttons["experiment.next"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
            if legal.exists {
                let score = app.staticTexts["experiment.score"].label
                try vo.choose(legal, expecting: legal.label)
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.staticTexts["experiment.score"].label != score
                }, object: nil).wait(timeout: 5))
            } else {
                let before = app.otherElements["experiment.board"].value as? String
                try vo.choose(next, expecting: "Next shower")
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.otherElements["experiment.board"].value as? String != before
                }, object: nil).wait(timeout: 5))
            }
        }
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        try vo.focus(outcome, expecting: "Lantern Landing restored!")
        let score = app.staticTexts["experiment.score"].label
        capture(app, "VoiceOver-First-Light-complete")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        app.terminate(); app.launchArguments = []; app.launch()
        vo.resetFocus()
        try vo.choose(app.buttons["sky.resume"], expecting: "View last sky")
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        try vo.focus(outcome, expecting: "Lantern Landing restored!")
        try vo.choose(app.buttons["experiment.replay"], expecting: "Replay First Light")
        try vo.choose(app.buttons["sky.begin"], expecting: "Begin")
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.pause"], expecting: "Pause sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertFalse(outcome.exists)
        try vo.choose(app.buttons["experiment.next"], expecting: "Next shower")
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.new"], expecting: "New sky")
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Make room for the stars")
        capture(app, "VoiceOver-replayed-and-new-sky")
        #else
        throw XCTSkip("VoiceOver service requires Xcode 27")
        #endif
    }

}

/// Explicit setup for normal-motion review on a disposable QA simulator, selected separately.
final class ObservatoryReviewSetupTests: XCTestCase {
    @MainActor func testNormalSystemMotionForAnimationReview() throws {
        continueAfterFailure = false
        #if compiler(>=6.4)
        if #available(iOS 27.0, *) {
            // Explicit normal-mode matrix setup on a disposable QA simulator only.
            // A preceding VoiceOver test can otherwise leave hosted motion checks skipped.
            let service = XCUIDevice.shared.voiceOverService
            if service.isEnabled { try service.disable() }
            XCTAssertFalse(service.isEnabled)
        }
        #endif
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        if reduce.value as? String != "0" {
            reduce.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"), object: reduce).wait(timeout: 5))
        preferences.terminate()
    }
}


#if compiler(>=6.4)
/// Actual screen-reader exploration and activation, with restoration even after an assertion fails.
@available(iOS 27.0, *)
@MainActor private final class ObservatoryVoiceOverDriver {
    let app: XCUIApplication
    let service = XCUIDevice.shared.voiceOverService
    var transcript: [String] = []
    private var focused: XCUIElement?
    private var focusedIdentifier: String?

    init(test: XCTestCase, app: XCUIApplication) throws {
        self.app = app
        let wasEnabled = service.isEnabled
        test.addTeardownBlock { @MainActor in
            let attachment = XCTAttachment(string: self.transcript.joined(separator: "\n"))
            attachment.name = "Observatory-actual-VoiceOver-speech"
            attachment.lifetime = .keepAlways
            test.add(attachment)
            if !wasEnabled { try self.service.disable() }
            XCTAssertEqual(self.service.isEnabled, wasEnabled)
        }
        try service.enable()
        XCTAssertTrue(service.isEnabled)
    }

    func resetFocus() {
        focused = nil
        focusedIdentifier = nil
    }

    func focus(_ element: XCUIElement, expecting text: String) throws {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        let speech: String
        if focusedIdentifier == element.identifier {
            // Revisit an already-focused control through native navigation. This
            // requests fresh speech and lets VoiceOver reveal offscreen controls.
            transcript.append("Previous: " + (try service.moveBackward().utterance))
            speech = try service.moveForward().utterance
        } else {
            speech = NativeVoiceOverFocus.speech(afterTouching: element, containing: text)
        }
        transcript.append(speech)
        focused = element
        focusedIdentifier = element.identifier
        XCTAssertTrue(speech.localizedCaseInsensitiveContains(text), "Unexpected VoiceOver focus: \(speech)")
    }

    func advance(to text: String, limit: Int) throws {
        for _ in 0..<limit {
            let speech = try service.moveForward().utterance
            transcript.append(speech)
            if speech.localizedCaseInsensitiveContains(text) { return }
        }
        XCTFail("VoiceOver navigation did not reach \(text): \(transcript.suffix(limit))")
    }

    func activate() {
        // XCTest's coordinate gestures target the explored element. An app-center
        // double tap re-targets empty floor in this harness; it does not verify activation.
        focused!.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
    }

    func choose(_ element: XCUIElement, expecting text: String) throws {
        try focus(element, expecting: text)
        activate()
    }
}
#endif


extension XCUIApplication {
    /// Menu rows are lazily created; reach them through the same scroll a player uses.
    @MainActor func skyMenuControl(_ identifier: String) -> XCUIElement {
        let control = buttons[identifier]
        revealSkyMenuElement(control)
        return control
    }
    @MainActor func revealSkyMenuElement(_ control: XCUIElement) {
        for _ in 0..<4 where !control.isHittable { swipeUp() }
    }
}

extension ObservatoryInteractionTests {
    @MainActor func testVoiceOverOpalIdentityActivationAndStormCue() throws {
        #if compiler(>=6.4)
        guard #available(iOS 27.0, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
        continueAfterFailure = false
        let sky = XCUIApplication()
        let vo = try ObservatoryVoiceOverDriver(test: self, app: sky)
        sky.launchArguments = ["--starfalls-reset", "--constellation-fixture=opalChoice"]
        sky.launch(); defer { sky.terminate() }
        XCTAssertTrue(sky.buttons["experiment.cell.2.5"].waitForExistence(timeout: 10))
        try vo.focus(sky.buttons["experiment.cell.2.5"], expecting: "White Opal Orb")
        XCTAssertTrue(vo.transcript.last?.contains("1 starlight") == true)
        vo.activate()
        XCTAssertEqual(sky.staticTexts["experiment.score"].label, "24 starlight")
        try vo.focus(sky.buttons["experiment.cell.0.6"], expecting: "Violet")
        vo.activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "29 starlight"), object: sky.staticTexts["experiment.score"]).wait(timeout: 5))
        let phase = sky.descendants(matching: .any).matching(identifier: "experiment.message").firstMatch
        try vo.focus(phase, expecting: "Sunny")
        try vo.choose(sky.buttons["experiment.settings"], expecting: "Sky menu")
        XCTAssertTrue(sky.buttons["experiment.done"].waitForExistence(timeout: 5)); XCTAssertFalse(phase.exists)
        try vo.choose(sky.buttons["experiment.done"], expecting: "Done")
        XCTAssertTrue(phase.waitForExistence(timeout: 5))
        sky.terminate(); vo.resetFocus()
        sky.launchArguments = ["--starfalls-reset", "--constellation-fixture=stormWarning"]
        sky.launch()
        XCTAssertTrue(sky.buttons["experiment.next"].waitForExistence(timeout: 10))
        try vo.focus(phase, expecting: "1 lighter shower")
        try vo.choose(sky.buttons["experiment.next"], expecting: "Next shower")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Storm: 3 heavy showers left."), object: phase).wait(timeout: 5))
        try vo.focus(phase, expecting: "Storm")
        let capture = XCTAttachment(screenshot: sky.screenshot()); capture.name = "opal-storm-actual-voiceover"
        capture.lifetime = .keepAlways; add(capture)
        #else
        throw XCTSkip("VoiceOver service requires Swift 6.4")
        #endif
    }
}

/// Five shipping worlds share the same native input surface and save contract.
final class LandingPlaceInteractionTests: XCTestCase {
    private let places = ["observatory","cloudsea","hearth","grotto","archive"]

    @MainActor private func launch(place: String? = nil, large: Bool = false, score: Int = 0, calm: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset","--observatory-review","--observatory-dense","-calmEffects",calm ? "YES":"NO"]
        if let place { app.launchArguments += ["-landingPlace",place] }
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName","UICTContentSizeCategoryAccessibilityXXXL"] }
        if score > 0 { app.launchArguments += ["--night-score=\(score)"] }
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:10))
        return app
    }
    @MainActor private func capture(_ name: String) {
        let image = XCTAttachment(screenshot:XCUIScreen.main.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor private func select(_ place: String, app: XCUIApplication) {
        app.buttons["experiment.settings"].tap()
        app.skyMenuControl("landing.locations").tap()
        let choice = app.buttons["landing.choose."+place]
        app.revealSkyMenuElement(choice)
        XCTAssertTrue(choice.isHittable); choice.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","Selected"),object:choice).wait(timeout:3))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout:5))
    }
    @MainActor func testAllWorldsKeepTheRoundAndCenteredCellsAcrossOrientations() {
        let orientations: [UIDeviceOrientation] = UIDevice.current.userInterfaceIdiom == .pad ? [.portrait,.landscapeLeft] : [.portrait]
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            let app = launch()
            let board = app.otherElements["experiment.board"], score = app.staticTexts["experiment.score"]
            let original = board.value as? String
            for place in places {
                select(place,app:app)
                XCTAssertEqual(board.value as? String,original)
                XCTAssertEqual(score.label,"0 starlight")
                let middle = app.buttons["experiment.cell.3.3"]
                XCTAssertEqual(middle.frame.midX,app.frame.midX,accuracy:1)
                XCTAssertEqual(middle.frame.midY,app.frame.midY,accuracy:2)
                for id in ["experiment.settings","experiment.next","experiment.pause","experiment.cell.0.0","experiment.cell.6.6"] {
                    let control = app.buttons[id]
                    XCTAssertTrue(control.isHittable,id)
                    XCTAssertTrue(app.frame.contains(control.frame),id)
                    XCTAssertGreaterThanOrEqual(control.frame.width,44,id)
                    XCTAssertGreaterThanOrEqual(control.frame.height,44,id)
                }
                XCTAssertFalse(app.buttons["landing.telescope"].exists)
                XCTAssertFalse(app.buttons["landing.lantern"].exists)
                XCTAssertTrue(app.descendants(matching:.any)["experiment.arrivalCue"].exists)
                capture("Night-world-\(place)-\(orientation.rawValue)")
            }
            // Actual native coordinate dispatch at opposite corners, after scenery replacement.
            var total = 0
            for cell in ["6.6","0.0"] {
                let button = app.buttons["experiment.cell."+cell]
                let points = Int((button.value as! String).split(separator:" ")[0])!
                XCTAssertGreaterThanOrEqual(points,3); total += points
                button.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).tap()
                XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","\(total) starlight"),object:score).wait(timeout:5))
            }
            let committed = board.value as? String
            XCUIDevice.shared.press(.home);app.activate()
            XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout:5))
            XCTAssertEqual(board.value as? String,committed)
            app.terminate()
        }
    }
    @MainActor func testLargeScoresAndLargestTextReflowWithoutCoveringStars() {
        XCUIDevice.shared.orientation = .portrait
        for (score,large) in [(100000,false),(1234567890,false),(100000,true)] {
            let app = launch(large:large,score:score,calm:true)
            let counter = app.staticTexts["experiment.score"], menu = app.buttons["experiment.settings"]
            XCTAssertEqual(counter.label,"\(score) starlight")
            XCTAssertGreaterThan(counter.frame.width,40)
            XCTAssertTrue(app.frame.contains(counter.frame))
            XCTAssertTrue(menu.isHittable)
            XCTAssertFalse(counter.frame.intersects(menu.frame))
            XCTAssertLessThanOrEqual(app.otherElements["sky.header"].frame.maxY,app.buttons["experiment.cell.6.6"].frame.minY)
            capture("Night-score-\(score)-large-\(large)")
            let next = app.buttons["experiment.next"]
            for _ in 0..<8 where !next.isHittable {
                let guide = app.staticTexts["experiment.message"]
                let startY = guide.frame.minY < app.frame.maxY-100
                    ? min(app.frame.maxY-60,max(app.frame.midY,guide.frame.minY+60))
                    : app.buttons["experiment.cell.6.3"].frame.minY-16
                app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:app.frame.midX,dy:startY))
                    .press(forDuration:0.05,thenDragTo:app.coordinate(withNormalizedOffset:.zero).withOffset(CGVector(dx:app.frame.midX,dy:100)))
            }
            XCTAssertTrue(next.isHittable)
            XCTAssertGreaterThanOrEqual(next.frame.height,44)
            capture("Night-controls-large-\(large)")
            app.terminate()
        }
    }
    @MainActor func testQuietWorldsKeepNativeCornerClearOutcome() {
        for place in places {
            let app = launch(place:place,calm:true)
            let button = app.buttons["experiment.cell.0.0"]
            let points = Int((button.value as! String).split(separator:" ")[0])!
            button.coordinate(withNormalizedOffset:CGVector(dx:0.5,dy:0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","\(points) starlight"),object:app.staticTexts["experiment.score"]).wait(timeout:5))
            capture("Night-quiet-\(place)")
            app.terminate()
        }
    }
}
