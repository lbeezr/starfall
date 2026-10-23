import XCTest

final class SkyFlowInteractionTests: XCTestCase {
    @MainActor private func requireNormalMotion() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let originalMotion = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(originalMotion, on: toggle); settings.terminate()
        }
    }

    @MainActor private func launch(largest: Bool = false, review: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--starfalls-seed=5", "-calmEffects", "NO"]
        app.launchArguments += review
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        if !review.contains("--save-rejection-review") {
            XCTAssertTrue(app.staticTexts["sky.title"].waitForExistence(timeout: 10))
        }
        return app
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        for _ in 0..<8 where !button.isHittable {
            if button.frame.maxY > app.frame.maxY - 44 { app.swipeUp() }
            else if button.frame.minY < app.frame.minY + 80 { app.swipeDown() }
            else { break }
        }
        XCTAssertTrue(button.isHittable); button.tap()
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        // Avoid this runtime's rotated element-crop transform on landscape iPad.
        let screenshot = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let image = XCTAttachment(screenshot: screenshot); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    @MainActor private func captureEntry(_ app: XCUIApplication, _ name: String) {
        // The heading precedes the animated action panel. A title alone does not
        // establish a usable entry screen, especially in a compact viewport.
        app.revealSkyControls([app.buttons["sky.begin"]])
        capture(app, name)
    }
    @MainActor private func pause(_ app: XCUIApplication) {
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor private func assertStoryStartupGuidance(largest: Bool) {
        let app = launch(largest: largest)
        defer { app.terminate() }
        tap("sky.worldMap", app); tap("world.visit", app); tap("sky.begin", app)
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: menu).wait(timeout: 10))
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        capture(app, largest ? "story-start-largest" : "story-start-default")
        XCTAssertTrue(message.label.contains("150,000 starlight"))
        XCTAssertTrue(message.label.contains("Swipe to arrange"))
        XCTAssertTrue(message.label.contains("pattern pops automatically"))
        if largest {
            app.readSkyGuideToEnd(actions: [app.buttons["sky.dialogue.close"]])
            capture(app, "story-start-largest-read-through")
        }
        tap("sky.dialogue.close", app)
        pause(app)
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        let score = app.staticTexts["experiment.score"].label
        let star = app.buttons["experiment.cell.0.0"]
        app.revealSkyControls([star]); star.tap()
        XCTAssertEqual(board.value as? String, retained, "Inspection cannot activate an automatic pattern")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
    }

    @MainActor func testStoryStartupExplainsTheActualPatternAction() {
        assertStoryStartupGuidance(largest: false)
    }

    @MainActor func testLargestTextStoryStartupRemainsReadableUntilDismissed() {
        assertStoryStartupGuidance(largest: true)
    }

    @MainActor private func assertCurrentStoryGrowthGuidance(largest: Bool) {
        let app = launch(largest: largest)
        defer { app.terminate() }
        tap("sky.worldMap", app)
        tap("world.visit", app)
        tap("sky.begin", app)
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: menu).wait(timeout: 10))
        pause(app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue((board.value as? String)?.hasPrefix("0 showers") == true,
                      "Pause the ordinary new visit before its first scheduled shower")
        tap("experiment.next", app)
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "A star grew"),
                                               object: message).wait(timeout: 10))
        capture(app, largest ? "story-growth-largest" : "story-growth-default")
        if largest {
            app.readSkyGuideToEnd(actions: [app.buttons["experiment.pause"], app.buttons["experiment.next"]])
            capture(app, "story-growth-largest-read-through")
        }
        XCTAssertTrue(message.label.contains("twice the starlight"))
        XCTAssertTrue(message.label.contains("counts as one star"))
        XCTAssertFalse(message.label.contains("tap match"))
        XCTAssertTrue(app.buttons["experiment.cell.3.0"].label.hasPrefix("Grown "))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
                       "0 of \(150_000.formatted()) starlight collected")
        let retained = board.value as? String
        tap("experiment.cell.3.0", app)
        XCTAssertEqual(board.value as? String, retained, "Inspecting a grown star cannot clear it in current Story")
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
                       "0 of \(150_000.formatted()) starlight collected")
        app.revealSkyControls([app.buttons["experiment.pause"], app.buttons["experiment.next"]])
        XCTAssertTrue(app.buttons["experiment.pause"].isHittable)
        XCTAssertTrue(app.buttons["experiment.next"].isHittable)
        capture(app, largest ? "story-inspect-largest-controls" : "story-inspect-default-controls")
    }

    @MainActor func testCurrentStoryGrowthGuidanceMatchesAutomaticPatterns() {
        assertCurrentStoryGrowthGuidance(largest: false)
    }

    @MainActor func testLargestTextCurrentStoryGrowthGuidanceKeepsControlsUsable() {
        assertCurrentStoryGrowthGuidance(largest: true)
    }

    @MainActor func testWelcomeEntryBackgroundAndAnotherSky() {
        requireNormalMotion()
        let app = launch(); defer { app.terminate() }
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Story Mode")
        XCTAssertEqual(app.buttons["sky.start"].label, "Free Play")
        XCTAssertEqual(app.buttons["sky.learn"].label, "Tutorial")
        capture(app, "flow-welcome")
        tap("sky.start", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Make room for the stars")
        XCTAssertFalse(app.buttons["experiment.settings"].exists)
        captureEntry(app, "flow-entry")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.begin", app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        pause(app)
        if (board.value as? String)?.hasPrefix("0 showers") == true {
            tap("experiment.next", app)
        }
        let legal = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@ AND enabled == true", "experiment.cell.", "([3-9]|[1-9][0-9]) toward a tap match")).firstMatch
        XCTAssertTrue(legal.waitForExistence(timeout: 5)); legal.doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "0 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        let retained = board.value as? String
        tap("experiment.settings", app); tap("sky.home", app)
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 5))
        capture(app, "flow-resume-welcome")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        tap("sky.resume", app)
        XCTAssertEqual(board.value as? String, retained)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        tap("experiment.settings", app); tap("experiment.new", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        captureEntry(app, "flow-another-entry")
    }
    @MainActor func testCurrentRibbonWinReplayAndFullSky() {
        // The current four-star-line witness uses 98 exchanges and 32 showers to win.
        // Replay the same revision without arranging to retain the overflow boundary.
        executionTimeAllowance = 600
        requireNormalMotion()
        let app = launch(review: ["--dialogue-review", "--world-legacy-review"]); defer { app.terminate() }
        app.worldVisitControl("ribbonCrossing").tap(); tap("sky.begin", app); pause(app)
        let next = app.buttons["experiment.next"], outcome = app.staticTexts["experiment.outcome"]
        app.completeStoryPattern(.ribbon)
        XCTAssertEqual(outcome.label, "Ribbon Crossing restored!")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable, "Result actions remain usable during the celebration")
        capture(app, "flow-win")
        tap("experiment.replay", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Ribbon Crossing opening"))
        captureEntry(app, "flow-ribbon-replay-explanation")
        tap("sky.begin", app); pause(app)
        for _ in 0..<40 {
            if outcome.exists { break }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in outcome.exists || next.isEnabled }, object: nil).wait(timeout: 5),
                          "Paused round did not settle: state=\(app.state.rawValue), board=\(String(describing: app.otherElements["experiment.board"].value)), score=\(app.staticTexts["experiment.score"].label), outcome=\(outcome.exists), nextExists=\(next.exists), nextEnabled=\(next.isEnabled)")
            if !outcome.exists { tap("experiment.next", app) }
        }
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("had no room for the next star"))
        XCTAssertEqual(app.buttons["experiment.replay"].label, "Replay Ribbon Crossing")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("of \(220_000.formatted(.number.grouping(.automatic)))"))
        capture(app, "flow-full")
        app.terminate(); app.launchArguments = ["--sky-flow-review", "--dialogue-review"]; app.launch()
        tap("sky.resume", app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "No room to land")
        tap("experiment.new", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Make room for the stars")
        captureEntry(app, "flow-fresh-after-full")
    }

    @MainActor func testResultActionsRemainHittableAboveTheVisibleFinalBoard() {
        continueAfterFailure = false
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--observatory-review", "--observatory-dense"]
        app.launch()
        tap("sky.start", app); tap("sky.begin", app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "No room to land")
        capture(app, "result-input-over-visible-board")
        XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
        tap("experiment.replay", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("current sky settings"))
        captureEntry(app, "flow-replay-explanation")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
    }

    @MainActor func testLargestEndingReplayRetainsResultAcrossBackgroundAndCancel() {
        let app = launch(largest: true, review: ["--observatory-review", "--observatory-dense"])
        defer { app.terminate() }
        tap("sky.start", app); tap("sky.begin", app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "No room to land")
        let score = app.staticTexts["experiment.score"].label
        XCTAssertTrue(score.contains("had no room for the next star"))
        capture(app, "flow-ending-largest")
        tap("experiment.replay", app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Your saved round stays until you tap Begin."))
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        capture(app, "flow-replay-largest-background")
        tap("sky.home", app); tap("sky.resume", app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        tap("experiment.new", app)
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("each shower"))
    }

    @MainActor func testEntryCancellationAndTerminationRetainThePlayedSky() {
        let app = launch(); defer { app.terminate() }
        tap("sky.start", app); tap("sky.begin", app); pause(app)
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        tap("experiment.next", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: next).wait(timeout: 5))
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        let score = app.staticTexts["experiment.score"].label
        func assertRetained() {
            XCTAssertEqual(board.value as? String, retained)
            XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
            XCTAssertTrue(next.exists, "Continue preserves the intentional pause")
        }
        for choice in ["experiment.new", "experiment.replay", "sky.worldMap"] {
            tap("experiment.settings", app)
            // Form may not materialize an offscreen Explore row until scrolled.
            if choice == "sky.worldMap" { app.worldVisitControl("firstLight").tap() }
            else { tap(choice, app) }
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
            tap("sky.home", app)
            if choice == "sky.worldMap" {
                XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
                tap("world.done", app)
            } else {
                tap("sky.resume", app)
            }
            assertRetained()
        }
        tap("experiment.settings", app); tap("sky.home", app)
        app.worldVisitControl("firstLight").tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        captureEntry(app, "entry-staged-over-retained-sky")
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        tap("sky.resume", app)
        assertRetained()
        capture(app, "entry-cancel-retained-sky")
    }

    @MainActor func testReducedMotionEntryAndReplayKeepExplicitBegin() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(true, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: toggle); settings.terminate()
        }
        let app = launch(); defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        let begin = app.buttons["sky.begin"]
        XCTAssertGreaterThanOrEqual(begin.frame.height, 44)
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        captureEntry(app, "flow-reduced-entry")
        tap("sky.begin", app); pause(app)
        tap("experiment.next", app)
        tap("experiment.settings", app); tap("experiment.replay", app)
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
        captureEntry(app, "flow-reduced-replay")
    }
    @MainActor func testRejectedSaveNoticeSurvivesBackgroundAndReplacementRestoresNormally() {
        let app = launch(largest: true, review: ["--save-rejection-review"]); defer { app.terminate() }
        let alert = app.alerts["Saved sky unavailable"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "No older round has been loaded")).firstMatch.exists)
        capture(app, "rejected-save-notice-largest")
        // Read the native alert's scrollable message without dragging its fixed action.
        for _ in 0..<3 {
            alert.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.6))
                .press(forDuration: 0.05, thenDragTo: alert.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        }
        XCTAssertTrue(alert.buttons["Done"].isHittable)
        capture(app, "rejected-save-notice-largest-end")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Done"].tap()
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        tap("sky.start", app); tap("sky.begin", app); pause(app)
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        XCTAssertFalse(app.alerts["Saved sky unavailable"].exists)
        tap("sky.resume", app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor func testSaveFailureNoticeAcknowledgementResumesHandoffAndDoesNotRepeat() {
        let app = launch(review: ["--save-failure-review"]); defer { app.terminate() }
        tap("sky.start", app); tap("sky.begin", app)
        let alert = app.alerts["Sky could not be saved"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Your previous save is unchanged")).firstMatch.exists)
        capture(app, "save-failure-notice")
        alert.buttons["Done"].tap()
        pause(app)
        XCTAssertFalse(alert.exists)
        tap("experiment.next", app)
        tap("experiment.settings", app); tap("experiment.done", app)
        XCTAssertFalse(alert.exists)
        app.terminate(); app.launchArguments = ["--sky-flow-review"]; app.launch()
        tap("sky.resume", app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
    }

    @MainActor func testPendingFirstLightHelpUsesChallengeRulesAndPreservesEntry() {
        let app = launch(); defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        tap("sky.preferences", app); tap("experiment.help", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "How to play"),
            object: app.staticTexts["sky.menu.title"]).wait(timeout: 5))
        let objective = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Restore Lantern Landing with \(150_000.formatted(.number.grouping(.automatic))) starlight.")).firstMatch
        for _ in 0..<10 where !objective.exists || !objective.isHittable { app.swipeUp() }
        XCTAssertTrue(objective.exists); XCTAssertTrue(objective.isHittable)
        capture(app, "first-light-entry-help")
        tap("experiment.done", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        captureEntry(app, "first-light-entry-after-help")
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertFalse(app.buttons["sky.resume"].exists, "Reading pending Help does not save or begin a round")
    }

    @MainActor func testWelcomePreferencesShareValuesWithPlayAndDoNotCreateASave() {
        let app = launch(); defer { app.terminate() }
        tap("sky.preferences", app)
        XCTAssertFalse(app.buttons["sky.start"].exists)
        let sound = app.switches["experiment.sound"]
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        let original = sound.value as? String
        // The authored Toggle exposes its full row as the native switch target.
        XCTAssertTrue(sound.isEnabled)
        XCTAssertTrue(sound.isHittable)
        XCTAssertGreaterThanOrEqual(sound.frame.width, 44)
        XCTAssertGreaterThanOrEqual(sound.frame.height, 44)
        sound.tap()
        capture(app, "welcome-preferences")
        let selected = original == "1" ? "0" : "1"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", selected), object: sound).wait(timeout: 3))
        tap("experiment.help", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "How to play"),
            object: app.staticTexts["sky.menu.title"]).wait(timeout: 5))
        capture(app, "welcome-help-before-begin")
        tap("experiment.done", app)
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        app.worldVisitControl("firstLight").tap(); tap("sky.begin", app); pause(app)
        tap("experiment.settings", app)
        tap("experiment.preferences", app)
        XCTAssertTrue(sound.waitForExistence(timeout: 5))
        XCTAssertEqual(sound.value as? String, selected)
        app.revealSkyControls([sound])
        XCTAssertTrue(sound.isEnabled)
        XCTAssertTrue(sound.isHittable)
        XCTAssertGreaterThanOrEqual(sound.frame.width, 44)
        XCTAssertGreaterThanOrEqual(sound.frame.height, 44)
        capture(app, "game-preferences-shared-values")
        sound.tap() // Restore the review preference; normal defaults were never used.
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", original ?? ""), object: sound).wait(timeout: 3))
        tap("sky.menu.back", app)
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("First Light"))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Automatic showers paused"))
        capture(app, "welcome-retained-challenge-summary")
    }

    @MainActor func testLandscapeWelcomeEntryAndPreferences() throws {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        @MainActor func revealFully(_ id: String, in app: XCUIApplication) -> XCUIElement {
            let control = app.buttons[id]
            XCTAssertTrue(control.waitForExistence(timeout: 5))
            // A hittable center can hide the bottom of a control under Home.
            // Full-window iPad reserves 21 points for that system gesture region.
            for _ in 0..<8 {
                if control.frame.maxY > app.frame.maxY - 21 { app.swipeUp() }
                else if control.frame.minY < app.frame.minY { app.swipeDown() }
                else { break }
            }
            XCTAssertGreaterThanOrEqual(control.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(control.frame.maxY, app.frame.maxY - 21)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
            XCTAssertTrue(control.isHittable)
            return control
        }
        for largest in [false, true] {
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                XCUIDevice.shared.orientation = .portrait
                let app = launch(largest: largest)
                defer { app.terminate() }
                guard app.frame.width >= 700 else { throw XCTSkip("Tablet coverage; iPhone supports portrait only") }
                XCUIDevice.shared.orientation = orientation
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    (app.frame.width > app.frame.height) == (orientation == .landscapeLeft)
                }, object: nil).wait(timeout: 5))
                let variant = "\(orientation.rawValue)-\(largest ? "largest" : "default")"
                for id in ["sky.start", "sky.worldMap"] { _ = revealFully(id, in: app) }
                let preferences = revealFully("sky.preferences", in: app)
                capture(app, "tablet-welcome-safe-" + variant)
                preferences.tap()
                XCTAssertTrue(app.switches["experiment.sound"].waitForExistence(timeout: 5))
                app.buttons["experiment.done"].tap()
                app.worldVisitControl("firstLight").tap()
                _ = revealFully("sky.begin", in: app)
                _ = revealFully("sky.home", in: app)
                revealFully("sky.preferences", in: app).tap()
                XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
                app.buttons["experiment.done"].tap()
                let begin = revealFully("sky.begin", in: app)
                capture(app, "tablet-entry-safe-" + variant)
                begin.tap()
                XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
            }
        }
    }

    @MainActor func testLargestTextWelcomeEntryAndBackRemainReachable() {
        let app = launch(largest: true); defer { app.terminate() }
        capture(app, "flow-largest-welcome-actions-first")
        tap("sky.preferences", app)
        XCTAssertTrue(app.switches["experiment.sound"].waitForExistence(timeout: 5))
        capture(app, "flow-largest-welcome-preferences")
        tap("experiment.done", app)
        app.worldVisitControl("firstLight").tap()
        captureEntry(app, "flow-largest-entry")
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertFalse(app.buttons["world.list"].exists)
        XCTAssertFalse(app.buttons["sky.resume"].exists, "Canceling an unbegun round must not create a save")
        app.worldVisitControl("firstLight").tap()
        tap("sky.begin", app)
        pause(app)
        tap("experiment.settings", app)
        tap("experiment.done", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
    }

}

/// Production forecast layouts: verifies lifecycle and fallback, not physical camera fit.
