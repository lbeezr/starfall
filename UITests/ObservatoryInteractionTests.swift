import XCTest
import UIKit

final class ObservatoryInteractionTests: XCTestCase {
    @MainActor private func launch(dense: Bool = false, calm: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--observatory-review"]
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
        XCTAssertLessThanOrEqual(menu.frame.width, 52)
        XCTAssertTrue(app.staticTexts["experiment.message"].label.contains("Match stars worth three"))
        let before = app.otherElements["experiment.board"].value as? String
        capture(app, "Celestial-HUD-welcome")
        menu.tap()
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "Celestial-menu")
        app.buttons["experiment.help"].tap()
        XCTAssertTrue(app.staticTexts["A little starlight"].waitForExistence(timeout: 5))
        capture(app, "Celestial-how-to-play")
        app.navigationBars.buttons["Sky menu"].tap()
        app.buttons["experiment.balance"].tap()
        XCTAssertTrue(app.buttons["experiment.pace"].waitForExistence(timeout: 5))
        capture(app, "Celestial-balance")
        app.buttons["experiment.done"].tap()
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, before)
        XCTAssertTrue(app.buttons["landing.lantern"].isHittable)
    }
    @MainActor func testActualCastSparseDenseAndProjectedCornerTaps() {
        for dense in [false,true] {
            let app = launch(dense: dense)
            capture(app, dense ? "Observatory-real-cast-dense" : "Observatory-real-cast-sparse")
            // Hitting a native coordinate at the projected far/right cell exercises actual event dispatch.
            let back = app.buttons["experiment.cell.\(dense ? 6 : 2).6"]
            XCTAssertTrue(back.isHittable)
            let value = Int((back.value as! String).split(separator: " ")[0])!
            XCTAssertGreaterThanOrEqual(value, 3)
            let point = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: back.frame.midX, dy: back.frame.midY))
            point.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
            let front = app.buttons["experiment.cell.0.0"]
            XCTAssertTrue(front.isHittable)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: front).wait(timeout: 5))
            let second = Int((front.value as! String).split(separator: " ")[0])!
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
    @MainActor func testLivingPropsRespondWithoutChangingBoardAndCancelOnMenu() {
        let app = launch(); defer { app.terminate() }
        let board = app.otherElements["experiment.board"]
        XCTAssertGreaterThan(board.frame.height,app.frame.height*0.95)
        let initial = board.value as? String
        for id in ["landing.telescope","landing.lantern"] {
            let prop = app.buttons[id]
            XCTAssertTrue(prop.isHittable)
            prop.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Responding"), object: prop).wait(timeout: 2))
            XCTAssertEqual(board.value as? String, initial)
            capture(app,id+"-responding")
            app.buttons["experiment.settings"].tap()
            app.buttons["experiment.done"].tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "At rest"), object: prop).wait(timeout: 3))
            XCTAssertEqual(board.value as? String, initial)
        }
        capture(app,"Observatory-fullscreen-living")
    }
}

extension ObservatoryInteractionTests {
    @MainActor func testCalmPropResponsesAndManualClearUseSameOutcomes() {
        let app = launch(calm: true); defer { app.terminate() }
        let initial = app.otherElements["experiment.board"].value as? String
        let telescope = app.buttons["landing.telescope"]
        telescope.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Responding"), object: telescope).wait(timeout: 2))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, initial)
        let first = app.buttons["experiment.cell.0.0"]
        let value = Int((first.value as! String).split(separator: " ")[0])!
        first.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        capture(app,"Observatory-calm-effects")
    }
}

extension ObservatoryInteractionTests {
    @MainActor func testRepeatedPropsBackgroundAndRestartRejectStaleResponses() {
        let app = launch(); defer { app.terminate() }
        let lantern = app.buttons["landing.lantern"]
        let telescope = app.buttons["landing.telescope"]
        lantern.doubleTap(); telescope.tap()
        XCTAssertEqual(telescope.value as? String, "Responding")
        XCTAssertEqual(lantern.value as? String, "At rest")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(lantern.waitForExistence(timeout: 5))
        XCTAssertEqual(lantern.value as? String, "At rest")
        XCTAssertEqual(telescope.value as? String, "At rest")
        telescope.tap()
        app.buttons["experiment.settings"].tap()
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertFalse(lantern.exists)
        app.buttons["experiment.replay"].tap()
        XCTAssertTrue(telescope.waitForExistence(timeout: 5))
        XCTAssertEqual(telescope.value as? String, "At rest")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Start sky")
        let next = app.buttons["experiment.next"]
        next.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        XCTAssertEqual(telescope.value as? String, "At rest")
    }

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
            for id in ["landing.telescope", "landing.lantern"] {
                let prop = app.buttons[id]
                XCTAssertTrue(prop.isHittable)
                XCTAssertGreaterThanOrEqual(prop.frame.width, 44)
                XCTAssertGreaterThanOrEqual(prop.frame.height, 44)
            }
            let back = app.buttons["experiment.cell.6.6"]
            XCTAssertGreaterThanOrEqual(back.frame.width, 44)
            XCTAssertGreaterThanOrEqual(back.frame.height, 44)
            let value = Int((back.value as! String).split(separator: " ")[0])!
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
        XCTAssertTrue(app.buttons["landing.telescope"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 starlight")
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String,"0 showers, 0 matching groups ready")
        app.buttons["experiment.settings"].tap()
        XCTAssertFalse(app.buttons["sky.environment"].exists)
        XCTAssertTrue(app.staticTexts["Moonlit Observatory"].exists)
    }
}

extension ObservatoryInteractionTests {
    @MainActor func testLargestTextKeepsPropsAndPausedControlsReachable() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--observatory-review", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        let initialShowers = Int((app.otherElements["experiment.board"].value as! String).split(separator: " ")[0])!
        capture(app, "Observatory-largest-text-initial-board")
        let guide = app.staticTexts["experiment.message"]
        let front = app.buttons["experiment.cell.0.0"]
        XCTAssertGreaterThanOrEqual(guide.frame.minY, front.frame.maxY,
                                   "The growing guide must occupy space below projected stars")
        let edge = app.buttons["experiment.cell.0.0"]
        XCTAssertGreaterThanOrEqual(edge.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(edge.frame.maxX, app.frame.maxX)
        let value = Int((edge.value as! String).split(separator: " ")[0])!
        edge.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))

        for id in ["landing.telescope", "landing.lantern", "experiment.next"] {
            let target = app.buttons[id]
            for _ in 0..<5 where !target.isHittable { app.swipeUp() }
            XCTAssertTrue(target.isHittable)
            if id.hasPrefix("landing.") {
                XCTAssertFalse(target.frame.intersects(app.buttons["experiment.next"].frame))
                target.tap()
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Responding"), object: target).wait(timeout: 2))
                capture(app,"Observatory-largest-text-"+id)
            } else {
                target.tap()
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: target).wait(timeout: 5))
                XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("\(initialShowers+1) showers") == true)
            }
        }
        let name = app.staticTexts["sky.guide.title"]
        let next = app.buttons["experiment.next"]
        XCTAssertEqual(name.label, "Sunny")
        XCTAssertLessThan(name.frame.height, next.frame.height,
                          "The secondary name must not dominate the full-size action label")
        XCTAssertGreaterThanOrEqual(next.frame.height, 44)
        XCTAssertLessThanOrEqual(name.frame.height, 44, "The secondary label stays within a compact single-line footprint")
        XCTAssertFalse(guide.label.isEmpty)
        capture(app, "Observatory-largest-text-refined-guide")
        for _ in 0..<5 where !app.buttons["experiment.settings"].isHittable { app.swipeDown() }
        app.buttons["experiment.settings"].tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
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
        try focus(app.buttons["experiment.cell.1.3"], expecting: "Dark star, Dusk")
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
        try focus(app.buttons["landing.telescope"], expecting: "Observatory telescope"); activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Responding"), object: app.buttons["landing.telescope"]).wait(timeout: 2))
        try focus(app.buttons["landing.lantern"], expecting: "Observatory lantern"); activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "Responding"), object: app.buttons["landing.lantern"]).wait(timeout: 2))
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
        XCTAssertEqual(outcome.label, "This sky is full")
        try vo.focus(outcome, expecting: "This sky is full")
        capture(app, "VoiceOver-largest-text-overflow")
        try vo.advance(to: "Replay this sky", limit: 6)
        try vo.choose(app.buttons["experiment.replay"], expecting: "Replay this sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        XCTAssertFalse(outcome.exists)
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
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        let outcome = app.staticTexts["experiment.outcome"]
        for _ in 0..<50 {
            if outcome.exists { break }
            let next = app.buttons["experiment.next"]
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
            let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
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
        XCTAssertEqual(outcome.label, "First Light complete")
        try vo.focus(outcome, expecting: "First Light complete")
        let score = app.staticTexts["experiment.score"].label
        capture(app, "VoiceOver-First-Light-complete")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        app.terminate(); app.launchArguments = []; app.launch()
        vo.resetFocus()
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        try vo.focus(outcome, expecting: "First Light complete")
        try vo.choose(app.buttons["experiment.replay"], expecting: "Replay this sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertFalse(outcome.exists)
        try vo.choose(app.buttons["experiment.next"], expecting: "Next shower")
        try vo.choose(app.buttons["experiment.settings"], expecting: "Sky menu")
        try vo.choose(app.buttons["experiment.new"], expecting: "New sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
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
