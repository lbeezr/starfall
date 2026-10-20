import XCTest

/// Uses reset-only Debug review data; all clears and navigation use native controls.
class RestorationInteractionScenarios: XCTestCase {
    var location: ReviewLocation { .seed }
    @MainActor func setSystemMotion(reduced: Bool) {
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

    enum ReviewLocation: String {
        case lantern, ribbon, kite, seed, silver, frostfruit
        var route: String {
            switch self {
            case .lantern: "firstLight"
            case .ribbon: "ribbonCrossing"
            case .kite: "kiteHarbor"
            case .seed: "seedMoon"
            case .silver: "silverPools"
            case .frostfruit: "frostfruitOrchard"
            }
        }
        var title: String {
            switch self {
            case .lantern: "Lantern Landing"
            case .ribbon: "Ribbon Crossing"
            case .kite: "Kite Harbor"
            case .seed: "Seed Moon"
            case .silver: "Silver Pools"
            case .frostfruit: "Frostfruit Orchard"
            }
        }
    }

    @MainActor func launch(score: Int, location selected: ReviewLocation? = nil, largestText: Bool = false, dense: Bool = false) -> XCUIApplication {
        let location = selected ?? self.location
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--world-legacy-review",
                               "--\(location.rawValue)-restoration-review=\(score)", "-calmEffects", "NO"]
        if self.location == .frostfruit { app.launchArguments.append("--world-silver-complete-review") }
        if dense { app.launchArguments.append("--restoration-dense") }
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let ready = score >= 18 ? app.staticTexts["experiment.outcome"] : app.buttons["experiment.cell.0.0"]
        XCTAssertTrue(ready.waitForExistence(timeout: 10))
        return app
    }

    @MainActor func tap(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        if !button.isHittable { app.revealSkyControls([button]) }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: button).wait(timeout: 5))
        button.tap()
    }

    @MainActor func assertRestoration(_ percent: Int, score: Int, location selected: ReviewLocation? = nil, in app: XCUIApplication) {
        let location = selected ?? self.location
        let restoration = app.descendants(matching: .any)["\(location.rawValue).restoration"].firstMatch
        XCTAssertTrue(restoration.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(location.title), \(percent)% restored"),
                                               object: restoration).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(score) of 18 starlight collected")
    }

    @MainActor func capture(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func clearTrio(_ identifier: String = "experiment.cell.0.0", in app: XCUIApplication) {
        let target = app.buttons[identifier]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND value CONTAINS %@",
                                                                      "4 toward a tap match"), object: target).wait(timeout: 5))
        tap(identifier, in: app)
    }

    @MainActor func pauseRunningSky(_ app: XCUIApplication) {
        tap("experiment.settings", in: app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Pause sky")
        tap("experiment.pause", in: app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor func exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 14)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "\(self.location.rawValue)-before-winning-clear-normal-motion")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "\(self.location.title) restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        // Compact viewports retain readable text and expose result actions by
        // scrolling the existing ceremony, just as accessibility text does.
        app.revealSkyControls([app.buttons["experiment.replay"]])
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        capture(app, "\(self.location.rawValue)-restored-after-native-winning-clear-normal-motion")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "\(self.location.title) restored!")
        capture(app, "\(self.location.rawValue)-restored-after-relaunch")

        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, self.location.title)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same \(self.location.title) opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(outcome.exists)
        capture(app, "\(self.location.rawValue)-replay-reset-to-unrestored")
    }

    @MainActor func exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 0, dense: true)
        defer { app.terminate() }
        assertRestoration(0, score: 0, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                       "experiment.cell.", "Empty,")).count, 0)
        capture(app, "\(self.location.rawValue)-dense-before-native-next-shower-normal-motion")

        let outcome = app.staticTexts["experiment.outcome"]
        let next = app.buttons["experiment.next"]
        let board = app.otherElements["experiment.board"]
        // Each of seven full columns can absorb at most one matching arrival
        // by growing its top star. Even one-star showers must overflow by eight.
        for _ in 0..<8 {
            if outcome.exists { break }
            app.revealSkyControls([next])
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                                   object: next).wait(timeout: 5))
            let priorBoard = board.value as? String
            XCTAssertNotNil(priorBoard)
            next.tap()
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                if outcome.exists { return true }
                guard let currentBoard = board.value as? String else { return false }
                return currentBoard != priorBoard
            }, object: nil).wait(timeout: 10), "Next shower must commit a shower or overflow; an unchanged state is a failure, not a reason to retry")
            if !outcome.exists { assertRestoration(0, score: 0, in: app) }
        }
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains(" 0 of 18 starlight collected"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertFalse(next.exists)
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertEqual(replay.label, "Replay \(self.location.title)")
        capture(app, "\(self.location.rawValue)-dense-native-overflow-zero-score-normal-motion")

        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, self.location.title)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same \(self.location.title) opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(outcome.exists)
        capture(app, "\(self.location.rawValue)-dense-overflow-replay-reset-to-unrestored")
    }

    @MainActor func exercisePreviewCancellationRetainsLocationsUntilBegin(_ previous: [ReviewLocation]) {
        executionTimeAllowance = 300
        setSystemMotion(reduced: false)
        for location in previous {
            let app = launch(score: 9, location: location)
            defer { app.terminate() }
            assertRestoration(50, score: 9, location: location, in: app)
            let board = app.otherElements["experiment.board"]
            let retained = board.value as? String
            XCTAssertNotNil(retained)

            tap("experiment.settings", in: app)
            app.worldVisitControl(self.location.route).tap()
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["sky.title"].label, self.location.title)
            XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
            XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
            capture(app, "\(self.location.rawValue)-entry-over-retained-half-restored-\(location.rawValue)")
            tap("sky.home", in: app)
            app.terminate()
            app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
            app.launch()
            tap("sky.resume", in: app)
            assertRestoration(50, score: 9, location: location, in: app)
            XCTAssertEqual(board.value as? String, retained, "Preview and cancellation cannot replace the saved \(location.title) round")
            XCTAssertTrue(app.buttons["experiment.next"].exists, "The retained round stays paused")

            tap("experiment.settings", in: app)
            app.skyMenuControl("sky.home").tap()
            app.worldVisitControl(self.location.route).tap()
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["sky.title"].label, self.location.title)
            tap("sky.begin", in: app)
            pauseRunningSky(app)
            assertRestoration(0, score: 0, in: app)
            XCTAssertFalse(app.descendants(matching: .any)["\(location.rawValue).restoration"].firstMatch.exists)
            capture(app, "\(self.location.rawValue)-begin-replaces-retained-\(location.rawValue)-with-unrestored-location")
        }
    }

    @MainActor func exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: true)
        let app = launch(score: 14, largestText: true)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "\(self.location.rawValue)-largest-text-reduce-motion-before-clear")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "\(self.location.title) restored!")
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        capture(app, "\(self.location.rawValue)-largest-text-reduce-motion-restored")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, self.location.title)
    }

    @MainActor func exerciseTabletRotationKeepsRestorationAndNativeInput() throws {
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
        capture(app, "\(self.location.rawValue)-tablet-portrait-before-rotation-normal-motion")

        rotate(to: .landscapeLeft, in: app)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, initialBoard, "Rotation cannot commit a shower or clear")
        XCTAssertEqual(identities(), initialIdentities)
        capture(app, "\(self.location.rawValue)-tablet-landscape-retained-before-clear-normal-motion")
        clearTrio(in: app)
        assertRestoration(50, score: 9, in: app)
        let clearedBoard = board.value as? String, clearedIdentities = identities()
        capture(app, "\(self.location.rawValue)-tablet-landscape-after-native-clear-normal-motion")

        rotate(to: .portrait, in: app)
        assertRestoration(50, score: 9, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, clearedBoard, "The landscape clear survives rotation")
        XCTAssertEqual(identities(), clearedIdentities)
        XCTAssertEqual(mappedIDs.map { app.buttons[$0].frame }, initialFrames)
        capture(app, "\(self.location.rawValue)-tablet-portrait-retained-after-landscape-clear-normal-motion")
        clearTrio("experiment.cell.2.6", in: app)
        assertRestoration(72, score: 13, in: app)
        capture(app, "\(self.location.rawValue)-tablet-portrait-after-second-native-clear-normal-motion")

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
                    XCTAssertEqual(sample.staticTexts["experiment.outcome"].label, "\(self.location.title) restored!")
                    XCTAssertTrue(sample.staticTexts["experiment.score"].label.contains("18 of 18 starlight collected"))
                    XCTAssertFalse(sample.buttons["experiment.next"].exists)
                    XCTAssertTrue(sample.buttons["experiment.replay"].isHittable)
                }
                capture(sample, "\(self.location.rawValue)-tablet-\(view)-scene-\(milestone)-score-\(score)-normal-motion")
                if score == 18 && orientation.isLandscape {
                    // The complete result can scroll on a short viewport. Verify
                    // its final action through the same visible-target contract.
                    let home = sample.buttons["sky.home"]
                    sample.revealSkyControls([home])
                    capture(sample, "\(self.location.rawValue)-tablet-landscape-final-result-action-visible")
                    tap("sky.home", in: sample)
                    XCTAssertTrue(sample.buttons["sky.worldMap"].waitForExistence(timeout: 5))
                }
            }
        }
    }

    @MainActor func exercisePhoneAllFiveStatesKeepNativeBoardFixed() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        var baseline: [CGRect] = []
        let ids = ["experiment.cell.0.0", "experiment.cell.0.6", "experiment.cell.6.0", "experiment.cell.6.6"]
        for (score, percent, milestone) in [(0, 0, 0), (5, 28, 25), (9, 50, 50), (14, 78, 75), (18, 100, 100)] {
            let app = launch(score: score)
            defer { app.terminate() }
            if score < 18 {
                assertRestoration(percent, score: score, in: app)
                let frames = ids.map { app.buttons[$0].frame }
                if score == 0 { baseline = frames }
                else { XCTAssertEqual(frames, baseline, "Restoration cannot move native cells") }
                XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
            } else {
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "\(self.location.title) restored!")
            }
            capture(app, "\(self.location.rawValue)-phone-scene-\(milestone)-score-\(score)-normal-motion")
        }
    }

    @MainActor func exerciseDenseRapidClearSurvivesSettingsAndBackground() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: false)
        let app = launch(score: 9, dense: true)
        defer { app.terminate() }
        assertRestoration(50, score: 9, in: app)
        let target = app.buttons["experiment.cell.0.0"]
        XCTAssertTrue((target.value as? String ?? "").contains("4 toward a tap match"))
        capture(app, "\(self.location.rawValue)-dense-before-rapid-clear")
        target.doubleTap()
        assertRestoration(72, score: 13, in: app)
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        XCTAssertNotNil(retained)
        capture(app, "\(self.location.rawValue)-dense-after-rapid-clear")
        tap("experiment.settings", in: app)
        tap("experiment.done", in: app)
        assertRestoration(72, score: 13, in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertRestoration(72, score: 13, in: app)
        XCTAssertEqual(board.value as? String, retained)
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        capture(app, "\(self.location.rawValue)-dense-retained-after-settings-background")
    }

    @MainActor func exerciseTabletDenseCompletionKeepsNativeInput() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This check targets tablet artwork with a full native board")
        }
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let app = launch(score: 14, dense: true)
            defer { app.terminate() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == orientation.isLandscape
                    && app.buttons["experiment.cell.0.0"].isHittable
            }, object: nil).wait(timeout: 8))
            assertRestoration(78, score: 14, in: app)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                           "experiment.cell.", "Empty,")).count, 0)
            let view = orientation.isLandscape ? "landscape" : "portrait"
            capture(app, "\(self.location.rawValue)-tablet-\(view)-dense-075-before-native-win")
            clearTrio(in: app)
            XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "\(self.location.title) restored!")
            XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18 of 18 starlight collected"))
            XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
            capture(app, "\(self.location.rawValue)-tablet-\(view)-100-after-native-win")
        }
    }
}
