import XCTest

/// Native presentation acceptance for the ordinary First Light challenge. The
/// review board is reset-only Debug data in the existing isolated review suite.
final class LanternLandingInteractionTests: XCTestCase {
    @MainActor private func setSystemMotion(reduced: Bool) {
        let (preferences, toggle) = NativeSystemMotionSettings.open()
        let original = toggle.value as? String == "1"
        NativeSystemMotionSettings.set(reduced, on: toggle)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, restored) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: restored)
            settings.terminate()
        }
    }

    @MainActor private func launch(score: Int, largestText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review",
                               "--lantern-restoration-review=\(score)", "-calmEffects", "NO"]
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let target = score >= 18 ? app.staticTexts["experiment.outcome"] : app.buttons["experiment.cell.0.0"]
        XCTAssertTrue(target.waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func tap(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        if !button.isHittable { app.revealSkyControls([button]) }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: button).wait(timeout: 5))
        button.tap()
    }

    @MainActor private func assertRestoration(_ percent: Int, score: Int, in app: XCUIApplication) {
        let restoration = app.descendants(matching: .any)["lantern.restoration"].firstMatch
        XCTAssertTrue(restoration.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "\(percent)% restored"),
                                               object: restoration).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(score) of 18 starlight collected")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor private func clearAmberTrio(in app: XCUIApplication) {
        let target = app.buttons["experiment.cell.0.0"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value CONTAINS %@",
                                                                      "4 toward a tap match"), object: target).wait(timeout: 5))
        tap("experiment.cell.0.0", in: app)
    }

    @MainActor private func pauseRunningSky(_ app: XCUIApplication) {
        tap("experiment.settings", in: app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Pause sky")
        tap("experiment.pause", in: app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor func testFiveMilestonesKeepNativePlayfieldGeometryWithNormalMotion() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        var baseline: [String: CGRect] = [:]
        for (score, percent, milestone) in [(0, 0, 0), (5, 28, 25), (9, 50, 50), (14, 78, 75), (18, 100, 100)] {
            let app = launch(score: score)
            if score < 18 {
                assertRestoration(percent, score: score, in: app)
                XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
                for (row, column) in [(0, 0), (0, 6), (3, 3), (6, 0), (6, 6)] {
                    let identifier = "experiment.cell.\(row).\(column)"
                    let cell = app.buttons[identifier]
                    XCTAssertTrue(cell.exists)
                    if score == 0 { baseline[identifier] = cell.frame }
                    else { XCTAssertEqual(cell.frame, baseline[identifier], "Restoration must not shift native cells") }
                }
                XCTAssertTrue(app.buttons["experiment.settings"].isHittable)
            } else {
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Lantern Landing restored!")
                XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
            }
            capture(app, "lantern-scene-\(milestone)-score-\(score)-normal-motion")
            app.terminate()
        }
    }

    @MainActor func testClearRestorationSurvivesSettingsBackgroundRelaunchAndEntryCancellation() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 5)
        defer { app.terminate() }
        assertRestoration(28, score: 5, in: app)
        clearAmberTrio(in: app)
        assertRestoration(50, score: 9, in: app)
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        XCTAssertNotNil(retained)
        capture(app, "lantern-clear-to-half-restored-normal-motion")

        tap("experiment.settings", in: app)
        tap("experiment.done", in: app)
        XCTAssertEqual(board.value as? String, retained)
        assertRestoration(50, score: 9, in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertRestoration(50, score: 9, in: app)
        XCTAssertEqual(board.value as? String, retained)

        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        assertRestoration(50, score: 9, in: app)
        XCTAssertEqual(board.value as? String, retained)
        XCTAssertTrue(app.buttons["experiment.next"].exists, "Restore preserves the intentional pause")

        tap("experiment.settings", in: app)
        app.skyMenuControl("experiment.replay").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same First Light opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "lantern-entry-over-retained-half-restored-sky")
        tap("sky.home", in: app)
        tap("sky.resume", in: app)
        assertRestoration(50, score: 9, in: app)
        XCTAssertEqual(board.value as? String, retained, "Browsing First Light must not replace a saved round")
    }

    @MainActor func testNativeWinningClearPersistsRestorationAndReplayStartsAtZero() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 14)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "lantern-before-winning-clear-normal-motion")
        clearAmberTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        capture(app, "lantern-restored-after-native-winning-clear-normal-motion")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        capture(app, "lantern-restored-after-relaunch")

        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same First Light opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(outcome.exists)
        capture(app, "lantern-replay-reset-to-unrestored")
    }

    @MainActor func testLargestTextReduceMotionWinningClearKeepsResultActionsUsable() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: true)
        let app = launch(score: 14, largestText: true)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "lantern-largest-text-reduce-motion-before-clear")
        clearAmberTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        capture(app, "lantern-largest-text-reduce-motion-restored")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
    }

    @MainActor func testTabletRotationKeepsRestorationAndNativeInput() throws {
        // Listed in the tablet-only native matrix for the two bespoke iPad
        // compositions. Supported phone landscape is verified separately.
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This check targets the tablet portrait and landscape compositions")
        }
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        XCUIDevice.shared.orientation = .portrait
        let app = launch(score: 5)
        defer {
            app.terminate()
            XCUIDevice.shared.orientation = .portrait
        }
        let mappedIDs = ["experiment.cell.0.0", "experiment.cell.0.6", "experiment.cell.3.3",
                         "experiment.cell.6.0", "experiment.cell.6.6"]
        @MainActor func identities() -> [String] {
            mappedIDs.map { identifier in
                let cell = app.buttons[identifier]
                return "\(identifier):\(cell.label):\(cell.value as? String ?? "")"
            }
        }
        @MainActor func assertMappedPlayfield() {
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
            let bottomLeft = app.buttons["experiment.cell.0.0"].frame
            let bottomRight = app.buttons["experiment.cell.0.6"].frame
            let topLeft = app.buttons["experiment.cell.6.0"].frame
            let topRight = app.buttons["experiment.cell.6.6"].frame
            let center = app.buttons["experiment.cell.3.3"].frame
            XCTAssertLessThan(topLeft.midY, bottomLeft.midY, "Core row zero stays at the bottom")
            XCTAssertLessThan(bottomLeft.midX, bottomRight.midX)
            XCTAssertEqual(bottomLeft.width, bottomLeft.height, accuracy: 1)
            XCTAssertEqual(topLeft.midX, bottomLeft.midX, accuracy: 1)
            XCTAssertEqual(topRight.midX, bottomRight.midX, accuracy: 1)
            XCTAssertEqual(center.midX, (bottomLeft.midX + bottomRight.midX) / 2, accuracy: 1)
            XCTAssertEqual(center.midY, (topLeft.midY + bottomLeft.midY) / 2, accuracy: 1)
            for identifier in mappedIDs + ["experiment.settings", "experiment.pause", "experiment.next"] {
                let control = app.buttons[identifier]
                XCTAssertTrue(control.isHittable, "Native target remains reachable: \(identifier)")
                XCTAssertTrue(app.frame.contains(control.frame), "Native target remains within the viewport: \(identifier)")
            }
        }
        @MainActor func rotate(to orientation: UIDeviceOrientation) {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == orientation.isLandscape
                    && app.buttons["experiment.settings"].isHittable
            }, object: nil).wait(timeout: 8))
        }

        rotate(to: .portrait)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield()
        let initialFrames = mappedIDs.map { app.buttons[$0].frame }
        let initialIdentities = identities()
        let board = app.otherElements["experiment.board"]
        let initialBoard = board.value as? String
        XCTAssertNotNil(initialBoard)
        capture(app, "lantern-tablet-portrait-before-rotation-normal-motion")

        rotate(to: .landscapeLeft)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield()
        XCTAssertEqual(board.value as? String, initialBoard, "Rotation cannot commit a shower or clear")
        XCTAssertEqual(identities(), initialIdentities, "The same native cells keep their stars after rotation")
        capture(app, "lantern-tablet-landscape-retained-before-clear-normal-motion")
        clearAmberTrio(in: app)
        assertRestoration(50, score: 9, in: app)
        let clearedBoard = board.value as? String
        let clearedIdentities = identities()
        capture(app, "lantern-tablet-landscape-after-native-clear-normal-motion")

        rotate(to: .portrait)
        assertRestoration(50, score: 9, in: app)
        assertMappedPlayfield()
        XCTAssertEqual(board.value as? String, clearedBoard, "The landscape clear survives the return to portrait")
        XCTAssertEqual(identities(), clearedIdentities)
        XCTAssertEqual(mappedIDs.map { app.buttons[$0].frame }, initialFrames,
                       "Returning to portrait restores the same native coordinate mapping")
        capture(app, "lantern-tablet-portrait-retained-after-landscape-clear-normal-motion")

        let aqua = app.buttons["experiment.cell.2.6"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value CONTAINS %@",
                                                                      "4 toward a tap match"), object: aqua).wait(timeout: 5))
        tap("experiment.cell.2.6", in: app)
        assertRestoration(72, score: 13, in: app)
        capture(app, "lantern-tablet-portrait-after-second-native-clear-normal-motion")
    }
}
