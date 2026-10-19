import XCTest

/// Uses reset-only Debug review data; all clears and navigation use native controls.
final class RibbonCrossingInteractionTests: XCTestCase {
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

    @MainActor private func launch(score: Int, lantern: Bool = false, largestText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review",
                               "--\(lantern ? "lantern" : "ribbon")-restoration-review=\(score)", "-calmEffects", "NO"]
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let ready = score >= 18 ? app.staticTexts["experiment.outcome"] : app.buttons["experiment.cell.0.0"]
        XCTAssertTrue(ready.waitForExistence(timeout: 10))
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

    @MainActor private func assertRestoration(_ percent: Int, score: Int, lantern: Bool = false, in app: XCUIApplication) {
        let restoration = app.descendants(matching: .any)[lantern ? "lantern.restoration" : "ribbon.restoration"].firstMatch
        let location = lantern ? "Lantern Landing" : "Ribbon Crossing"
        XCTAssertTrue(restoration.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(location), \(percent)% restored"),
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

    @MainActor private func clearTrio(_ identifier: String = "experiment.cell.0.0", in app: XCUIApplication) {
        let target = app.buttons[identifier]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value CONTAINS %@",
                                                                      "4 toward a tap match"), object: target).wait(timeout: 5))
        tap(identifier, in: app)
    }

    @MainActor private func pauseRunningSky(_ app: XCUIApplication) {
        tap("experiment.settings", in: app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Pause sky")
        tap("experiment.pause", in: app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor func testRibbonWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 14)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "ribbon-before-winning-clear-normal-motion")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Ribbon Crossing restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        // Compact viewports retain readable text and expose result actions by
        // scrolling the existing ceremony, just as accessibility text does.
        app.revealSkyControls([app.buttons["experiment.replay"]])
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        capture(app, "ribbon-restored-after-native-winning-clear-normal-motion")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Ribbon Crossing restored!")
        capture(app, "ribbon-restored-after-relaunch")

        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Ribbon Crossing opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(outcome.exists)
        capture(app, "ribbon-replay-reset-to-unrestored")
    }

    @MainActor func testRibbonPreviewCancellationRetainsLanternSaveUntilBegin() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 9, lantern: true)
        defer { app.terminate() }
        assertRestoration(50, score: 9, lantern: true, in: app)
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        XCTAssertNotNil(retained)

        tap("experiment.settings", in: app)
        app.skyMenuControl("experiment.ribbon-crossing").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        capture(app, "ribbon-entry-over-retained-half-restored-lantern")
        tap("sky.home", in: app)
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        assertRestoration(50, score: 9, lantern: true, in: app)
        XCTAssertEqual(board.value as? String, retained, "Preview and cancellation cannot replace the saved Lantern round")
        XCTAssertTrue(app.buttons["experiment.next"].exists, "The retained round stays paused")

        tap("experiment.settings", in: app)
        app.skyMenuControl("sky.home").tap()
        tap("sky.ribbon-crossing", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(app.descendants(matching: .any)["lantern.restoration"].firstMatch.exists)
        capture(app, "ribbon-begin-replaces-retained-lantern-with-unrestored-crossing")
    }

    @MainActor func testRibbonLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: true)
        let app = launch(score: 14, largestText: true)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "ribbon-largest-text-reduce-motion-before-clear")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Ribbon Crossing restored!")
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        capture(app, "ribbon-largest-text-reduce-motion-restored")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
    }

    @MainActor func testTabletRotationKeepsRibbonRestorationAndNativeInput() throws {
        // Registered only in the tablet matrix; the phone matrix excludes this method.
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This check targets the tablet portrait and landscape compositions")
        }
        executionTimeAllowance = 300
        setSystemMotion(reduced: false)
        XCUIDevice.shared.orientation = .portrait
        let app = launch(score: 5)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        let mappedIDs = ["experiment.cell.0.0", "experiment.cell.0.6", "experiment.cell.3.3",
                         "experiment.cell.6.0", "experiment.cell.6.6"]
        @MainActor func identities() -> [String] {
            mappedIDs.map { "\($0):\(app.buttons[$0].label):\(app.buttons[$0].value as? String ?? "")" }
        }
        @MainActor func assertMappedPlayfield(in app: XCUIApplication) {
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
            let bottomLeft = app.buttons[mappedIDs[0]].frame, bottomRight = app.buttons[mappedIDs[1]].frame
            let center = app.buttons[mappedIDs[2]].frame
            let topLeft = app.buttons[mappedIDs[3]].frame, topRight = app.buttons[mappedIDs[4]].frame
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
        @MainActor func rotate(to orientation: UIDeviceOrientation, in app: XCUIApplication) {
            XCUIDevice.shared.orientation = orientation
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == orientation.isLandscape
                    && (app.buttons["experiment.settings"].isHittable || app.buttons["experiment.replay"].isHittable)
            }, object: nil).wait(timeout: 8))
        }

        rotate(to: .portrait, in: app)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield(in: app)
        let initialFrames = mappedIDs.map { app.buttons[$0].frame }, initialIdentities = identities()
        let board = app.otherElements["experiment.board"]
        let initialBoard = board.value as? String
        XCTAssertNotNil(initialBoard)
        capture(app, "ribbon-tablet-portrait-before-rotation-normal-motion")

        rotate(to: .landscapeLeft, in: app)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, initialBoard, "Rotation cannot commit a shower or clear")
        XCTAssertEqual(identities(), initialIdentities)
        capture(app, "ribbon-tablet-landscape-retained-before-clear-normal-motion")
        clearTrio(in: app)
        assertRestoration(50, score: 9, in: app)
        let clearedBoard = board.value as? String, clearedIdentities = identities()
        capture(app, "ribbon-tablet-landscape-after-native-clear-normal-motion")

        rotate(to: .portrait, in: app)
        assertRestoration(50, score: 9, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, clearedBoard, "The landscape clear survives rotation")
        XCTAssertEqual(identities(), clearedIdentities)
        XCTAssertEqual(mappedIDs.map { app.buttons[$0].frame }, initialFrames)
        capture(app, "ribbon-tablet-portrait-retained-after-landscape-clear-normal-motion")
        clearTrio("experiment.cell.2.6", in: app)
        assertRestoration(72, score: 13, in: app)
        capture(app, "ribbon-tablet-portrait-after-second-native-clear-normal-motion")

        // Capture every authored state after the real-input/rotation checks.
        // Reset-only fixtures isolate each score without advancing ordinary saves.
        app.terminate()
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            let view = orientation.isLandscape ? "landscape" : "portrait"
            var baselineFrames: [CGRect] = []
            for (score, percent, milestone) in [(0, 0, 0), (5, 28, 25), (9, 50, 50), (14, 78, 75), (18, 100, 100)] {
                let sample = launch(score: score)
                defer { sample.terminate() }
                rotate(to: orientation, in: sample)
                if score < 18 {
                    assertRestoration(percent, score: score, in: sample)
                    assertMappedPlayfield(in: sample)
                    let frames = mappedIDs.map { sample.buttons[$0].frame }
                    if score == 0 { baselineFrames = frames }
                    else { XCTAssertEqual(frames, baselineFrames, "Restoration must not move the \(view) native cells") }
                } else {
                    XCTAssertEqual(sample.staticTexts["experiment.outcome"].label, "Ribbon Crossing restored!")
                    XCTAssertTrue(sample.staticTexts["experiment.score"].label.contains("18 of 18 starlight collected"))
                    XCTAssertFalse(sample.buttons["experiment.next"].exists)
                    XCTAssertTrue(sample.buttons["experiment.replay"].isHittable)
                }
                capture(sample, "ribbon-tablet-\(view)-scene-\(milestone)-score-\(score)-normal-motion")
            }
        }
    }
}
