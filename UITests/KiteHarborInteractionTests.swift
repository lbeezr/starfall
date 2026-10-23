import XCTest

/// Uses reset-only Debug review data; all clears and navigation use native controls.
final class KiteHarborInteractionTests: XCTestCase {
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

    private enum ReviewLocation: String {
        case lantern, ribbon, kite
        var title: String {
            switch self {
            case .lantern: "Lantern Landing"
            case .ribbon: "Ribbon Crossing"
            case .kite: "Kite Harbor"
            }
        }
    }

    @MainActor private func launch(score: Int, location: ReviewLocation = .kite, largestText: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--world-legacy-review",
                               "--\(location.rawValue)-restoration-review=\(score)", "-calmEffects", "NO"]
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

    @MainActor private func assertRestoration(_ percent: Int, score: Int, location: ReviewLocation = .kite,
                                            target: Int = 18, in app: XCUIApplication) {
        let restoration = app.descendants(matching: .any)["\(location.rawValue).restoration"].firstMatch
        XCTAssertTrue(restoration.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(location.title), \(percent)% restored"),
                                               object: restoration).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "\(score.formatted()) of \(target.formatted()) starlight collected")
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

    @MainActor func testKiteWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        let app = launch(score: 14)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "kite-before-winning-clear-normal-motion")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Kite Harbor restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        // Compact viewports retain readable text and expose result actions by
        // scrolling the existing ceremony, just as accessibility text does.
        app.revealSkyControls([app.buttons["experiment.replay"]])
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        capture(app, "kite-restored-after-native-winning-clear-normal-motion")

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Kite Harbor restored!")
        capture(app, "kite-restored-after-relaunch")

        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Kite Harbor opening"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, in: app)
        XCTAssertFalse(outcome.exists)
        capture(app, "kite-replay-reset-to-unrestored")
    }

    @MainActor func testKitePreviewCancellationRetainsBothExistingLocationsUntilBegin() {
        executionTimeAllowance = 300
        setSystemMotion(reduced: false)
        for location in [ReviewLocation.lantern, .ribbon] {
            let app = launch(score: 9, location: location)
            defer { app.terminate() }
            assertRestoration(50, score: 9, location: location, in: app)
            let board = app.otherElements["experiment.board"]
            let retained = board.value as? String
            XCTAssertNotNil(retained)

            tap("experiment.settings", in: app)
            app.worldVisitControl("kiteHarbor").tap()
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
            XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("17,000 starlight"))
            XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
            capture(app, "kite-entry-over-retained-half-restored-\(location.rawValue)")
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
            app.worldVisitControl("kiteHarbor").tap()
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
            tap("sky.begin", in: app)
            pauseRunningSky(app)
            assertRestoration(0, score: 0, target: 17_000, in: app)
            XCTAssertFalse(app.descendants(matching: .any)["\(location.rawValue).restoration"].firstMatch.exists)
            capture(app, "kite-begin-replaces-retained-\(location.rawValue)-with-unrestored-harbor")
        }
    }

    @MainActor func testKiteLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: true)
        let app = launch(score: 14, largestText: true)
        defer { app.terminate() }
        assertRestoration(78, score: 14, in: app)
        capture(app, "kite-largest-text-reduce-motion-before-clear")
        clearTrio(in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Kite Harbor restored!")
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        capture(app, "kite-largest-text-reduce-motion-restored")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
    }

    @MainActor func testTabletRotationKeepsKiteRestorationAndNativeInput() throws {
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
        capture(app, "kite-tablet-portrait-before-rotation-normal-motion")

        rotate(to: .landscapeLeft, in: app)
        assertRestoration(28, score: 5, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, initialBoard, "Rotation cannot commit a shower or clear")
        XCTAssertEqual(identities(), initialIdentities)
        capture(app, "kite-tablet-landscape-retained-before-clear-normal-motion")
        clearTrio(in: app)
        assertRestoration(50, score: 9, in: app)
        let clearedBoard = board.value as? String, clearedIdentities = identities()
        capture(app, "kite-tablet-landscape-after-native-clear-normal-motion")

        rotate(to: .portrait, in: app)
        assertRestoration(50, score: 9, in: app)
        assertMappedPlayfield(in: app)
        XCTAssertEqual(board.value as? String, clearedBoard, "The landscape clear survives rotation")
        XCTAssertEqual(identities(), clearedIdentities)
        XCTAssertEqual(mappedIDs.map { app.buttons[$0].frame }, initialFrames)
        capture(app, "kite-tablet-portrait-retained-after-landscape-clear-normal-motion")
        clearTrio("experiment.cell.2.6", in: app)
        assertRestoration(72, score: 13, in: app)
        capture(app, "kite-tablet-portrait-after-second-native-clear-normal-motion")

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
                    XCTAssertEqual(sample.staticTexts["experiment.outcome"].label, "Kite Harbor restored!")
                    XCTAssertTrue(sample.staticTexts["experiment.score"].label.contains("18 of 18 starlight collected"))
                    XCTAssertFalse(sample.buttons["experiment.next"].exists)
                    XCTAssertTrue(sample.buttons["experiment.replay"].isHittable)
                }
                capture(sample, "kite-tablet-\(view)-scene-\(milestone)-score-\(score)-normal-motion")
            }
        }
    }
}

extension KiteHarborInteractionTests {
    @MainActor private func freshEncounter(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review",
                               "-calmEffects", quiet ? "YES" : "NO"]
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        app.worldVisitControl("kiteHarbor").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("17,000 starlight"))
        XCTAssertFalse(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
        app.revealSkyControls([app.buttons["sky.begin"]])
        capture(app, largest ? "kite-current-entry-largest" : "kite-current-entry-default")
        tap("sky.begin", in: app)
        pauseRunningSky(app)
        assertRestoration(0, score: 0, target: 17_000, in: app)
        return app
    }

    @MainActor private func playEncounter(_ plan: StoryPatternPlan, app: XCUIApplication,
                                         restoreAfterFirstChoice: Bool = false) {
        var exchanges = 0
        app.completeStoryPattern(plan, exchange: { source, destination, _ in
            app.revealSkyControls([source, destination])
            XCTAssertTrue(source.isHittable && destination.isHittable)
            source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
                thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                withVelocity: .fast, thenHoldForDuration: 0.05)
            exchanges += 1
            if exchanges == 1 {
                let firstScore = plan.expectedScore == 17_000 ? 5_000 : 7_000
                let score = "\(firstScore.formatted()) of \(17_000.formatted()) starlight collected"
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", score),
                    object: app.staticTexts["experiment.score"]).wait(timeout: 5))
                capture(app, firstScore == 5_000 ? "kite-current-space-first" : "kite-current-points-first")
                if restoreAfterFirstChoice {
                    let retained = app.otherElements["experiment.board"].value as? String
                    XCTAssertNotNil(retained)
                    XCUIDevice.shared.press(.home); app.activate()
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, retained)
                    app.terminate()
                    app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
                    app.launch()
                    tap("sky.resume", in: app)
                    XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, retained)
                    XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
                    capture(app, "kite-current-restored-points-choice")
                }
            }
        }, shower: {
            tap("experiment.next", in: app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "full"),
                object: app.staticTexts["sky.pressure"]).wait(timeout: 5))
        })
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Kite Harbor restored!")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Seed Moon")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        capture(app, plan.expectedScore == 17_000 ? "kite-current-space-win" : "kite-current-points-win")
    }

    @MainActor func testCurrentKiteChoicesFinishRestoreReplayAndOverflow() {
        executionTimeAllowance = 360
        setSystemMotion(reduced: false)
        for pointsFirst in [false, true] {
            let app = freshEncounter()
            defer { app.terminate() }
            playEncounter(pointsFirst ? .kitePoints : .kiteSpace, app: app,
                          restoreAfterFirstChoice: pointsFirst)
            if pointsFirst {
                app.terminate(); app.launchArguments = ["--sky-flow-review", "--dialogue-review"]; app.launch()
                tap("sky.resume", in: app)
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18,000 of 17,000"))
                tap("experiment.replay", in: app)
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Kite Harbor opening"))
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("17,000 starlight"))
                tap("sky.begin", in: app); pauseRunningSky(app)
                assertRestoration(0, score: 0, target: 17_000, in: app)
                for _ in 0..<12 where !app.staticTexts["experiment.outcome"].exists {
                    let next = app.buttons["experiment.next"]
                    XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                        app.staticTexts["experiment.outcome"].exists || next.isEnabled
                    }, object: nil).wait(timeout: 5))
                    if !app.staticTexts["experiment.outcome"].exists { tap("experiment.next", in: app) }
                }
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "No room to land")
                capture(app, "kite-current-overflow")
            }
        }
    }

    @MainActor func testCurrentKiteLargestQuietHelpAndEarnedOnward() {
        executionTimeAllowance = 360
        setSystemMotion(reduced: false)
        let app = freshEncounter(largest: true, quiet: true)
        defer { app.terminate() }
        tap("experiment.settings", in: app)
        app.skyMenuControl("experiment.help").tap()
        let explanation = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
            "Kite Harbor", "17,000")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        XCTAssertFalse(explanation.label.contains("Ribbon Crossing"))
        XCTAssertFalse(explanation.label.contains("tap groups"))
        let heading = app.staticTexts["Kite Harbor · Raise the sails"]
        for _ in 0..<36 where !heading.isHittable || heading.frame.maxY > app.frame.maxY - 80 {
            app.swipeUp()
        }
        XCTAssertTrue(heading.isHittable)
        capture(app, "kite-current-help-heading-largest")
        for _ in 0..<12 where explanation.frame.maxY > app.frame.maxY - 80 { app.swipeUp() }
        XCTAssertLessThanOrEqual(explanation.frame.maxY, app.frame.maxY - 80)
        XCTAssertGreaterThan(explanation.frame.maxY, app.frame.minY + 80)
        XCTAssertTrue(explanation.isHittable)
        capture(app, "kite-current-help-largest")
        tap("Done", in: app)
        playEncounter(.kitePoints, app: app)
        let onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([onward, app.buttons["experiment.replay"]])
        XCTAssertGreaterThanOrEqual(onward.frame.height, 44)
        XCTAssertTrue(onward.isHittable)
        capture(app, "kite-current-onward-largest")
        tap("sky.worldMap", in: app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Seed Moon")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Seed Moon")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
        capture(app, "kite-current-seed-entry-largest")
    }

    @MainActor func testCurrentKiteAutomaticShowerAllowsPointsFirstRecovery() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--world-map-review", "--world-map-state=twoRepairs",
                               "--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        defer { app.terminate() }
        let seed = app.buttons["world.node.seedMoon"]
        app.revealWorldMapMarker(seed); seed.tap()
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Kite Harbor first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        let kite = app.buttons["world.node.kiteHarbor"]
        app.revealWorldMapMarker(kite); kite.tap()
        tap("world.visit", in: app); tap("sky.begin", in: app); pauseRunningSky(app)
        let first = app.buttons["experiment.cell.0.4"], firstDestination = app.buttons["experiment.cell.1.4"]
        app.revealSkyControls([first, firstDestination])
        first.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: firstDestination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "7,000 of 17,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        if app.buttons["sky.dialogue.close"].exists { tap("sky.dialogue.close", in: app) }
        // Resolve ordinary native coordinates before resuming the actual clock.
        // XCTest lookup overhead is not a player's planning or gesture time.
        let moves = [(15, 14), (36, 29), (29, 22), (4, 3), (3, 2), (2, 1)].map { from, to in
            let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
            let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
            XCTAssertTrue(source.isHittable && destination.isHittable)
            return (source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                    destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)))
        }
        tap("experiment.settings", in: app); tap("experiment.pause", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (app.otherElements["experiment.board"].value as? String)?.hasPrefix("1 showers") == true
        }, object: nil).wait(timeout: 10), "The ordinary automatic shower must arrive without Next")
        for (from, to) in moves {
            from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 0.05)
        }
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Kite Harbor restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18,000 of 17,000"))
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Seed Moon")
        capture(app, "kite-current-automatic-shower-recovery")
        tap("sky.worldMap", in: app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Seed Moon")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Seed Moon")
        capture(app, "kite-current-newly-unlocked-seed")
    }
}
