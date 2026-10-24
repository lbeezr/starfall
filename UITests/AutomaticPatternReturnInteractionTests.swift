import XCTest

/// Real Story exchanges exercise committed automatic returns. The passive art
/// stays outside accessibility; screenshots/video are inspected separately from
/// these exact score, input, save and result assertions.
final class AutomaticPatternReturnInteractionTests: XCTestCase {
    @MainActor private func normalSystemMotion() {
        let (settings, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        settings.terminate()
        addTeardownBlock { @MainActor in
            let (settings, reduce) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: reduce)
            settings.terminate()
        }
    }

    @MainActor private func launch(largest: Bool = false, legacyAccess: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review"]
        // Argument-domain overrides would mask the actual preference writes
        // exercised by the largest-text Settings journey below.
        if !largest { app.launchArguments += ["-calmEffects", "NO"] }
        if legacyAccess { app.launchArguments += ["--dialogue-review", "--world-legacy-review"] }
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func tap(_ id: String, in app: XCUIApplication) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true AND hittable == true"),
            object: control).wait(timeout: 5), id)
        control.tap()
    }

    @MainActor private func capture(_ name: String, in app: XCUIApplication) {
        let image = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor private func pauseNewStory(in app: XCUIApplication) {
        // A registered cell alone does not establish handoff/menu admission.
        tap("experiment.settings", in: app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Pause sky")
        tap("experiment.pause", in: app)
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func score(_ value: Int, target: Int, in app: XCUIApplication) {
        let expected = "\(value.formatted()) of \(target.formatted()) starlight collected"
        let predicate = app.staticTexts["experiment.outcome"].exists
            ? NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "experiment.score", " \(expected).")
            : NSPredicate(format: "identifier == %@ AND label == %@", "experiment.score", expected)
        app.waitForSkyElement(matching: predicate, timeout: 8,
                             failure: "The native automatic exchange must retain its exact committed score")
    }

    @MainActor private func settled(in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["experiment.outcome"].exists
                || (board.exists && (board.value as? String)?.contains("Stars settling") == false
                    && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0)
        }, object: nil).wait(timeout: 10), "Committed Story presentation must release its real input reservations")
    }

    @MainActor private func cells(in app: XCUIApplication) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button, node.identifier.hasPrefix("experiment.cell.") {
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try app.otherElements["experiment.board"].snapshot())
        XCTAssertEqual(result.count, 49)
        return result.sorted()
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, score value: Int, target: Int,
                                     capture name: String, in app: XCUIApplication) {
        settled(in: app)
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play",
                       "Story exchanges must not fall back to Open Sky manual clearing")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        // Capture before score/settlement queries consume the bounded receipt.
        // Capture IO is not proof that every 0.18-second body frame was sampled.
        capture(name, in: app)
        score(value, target: target, in: app)
        settled(in: app)
    }

    @MainActor private func setCalm(_ enabled: Bool, in app: XCUIApplication, captureName: String? = nil,
                                   verifyOffToOn: Bool = false) -> Bool {
        tap("experiment.settings", in: app)
        tap("experiment.preferences", in: app)
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        app.revealSkyMenuElement(calm)
        app.revealSkyControls([calm])
        let original = calm.value as? String == "1"
        let expectedValue = enabled ? "1" : "0"
        // Use the app switch's native action for its adaptive row layout.
        // Earlier failures also retained an argument-domain NO override, so
        // those failures do not establish a coordinate/hit-mapping cause.
        if enabled && verifyOffToOn {
            if calm.value as? String != "0" { calm.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0"),
                                                    object: calm).wait(timeout: 5))
            XCTAssertEqual(calm.value as? String, "0")
        }
        if calm.value as? String != expectedValue { calm.tap() }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expectedValue),
                                                object: calm).wait(timeout: 5))
        XCTAssertEqual(calm.value as? String, expectedValue)
        if let captureName { capture(captureName, in: app) }
        tap("experiment.done", in: app)
        return original
    }

    @MainActor func testNormalStoryInspectionSetupSquaresAndFourStarLine() throws {
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = launch()
        defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.begin", in: app)
        pauseNewStory(in: app)
        score(0, target: 150_000, in: app)
        settled(in: app)
        let opening = try cells(in: app)

        tap("experiment.cell.0.0", in: app)
        score(0, target: 150_000, in: app)
        XCTAssertEqual(try cells(in: app), opening, "Inspection neither clears nor fabricates a drawn pattern")
        capture("identity05-story-inspection-no-return", in: app)
        // This ordinary adjacent setup makes no current square/cross/4+ line.
        exchange(5, 6, score: 0, target: 150_000,
                 capture: "identity05-story-nonclearing-setup", in: app)
        XCTAssertNotEqual(try cells(in: app), opening)
        exchange(6, 5, score: 0, target: 150_000,
                 capture: "identity05-story-setup-restored", in: app)
        XCTAssertEqual(try cells(in: app), opening)

        exchange(8, 9, score: 15_000, target: 150_000,
                 capture: "identity05-story-square-cascade-return", in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 16)
        let beforeLine = try cells(in: app)
        tap("experiment.cell.0.0", in: app)
        score(15_000, target: 150_000, in: app)
        XCTAssertEqual(try cells(in: app), beforeLine)
        exchange(0, 1, score: 20_000, target: 150_000,
                 capture: "identity05-story-four-star-line-return", in: app)
        exchange(5, 12, score: 25_000, target: 150_000,
                 capture: "identity05-story-next-square-return", in: app)
        let retained = try cells(in: app)
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
        tap("experiment.settings", in: app)
        tap("experiment.done", in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertEqual(try cells(in: app), retained)
        app.terminate()
        app.launchArguments = ["--sky-flow-review", "-calmEffects", "NO"]
        app.launch()
        tap("sky.resume", in: app)
        score(25_000, target: 150_000, in: app)
        settled(in: app)
        XCTAssertEqual(try cells(in: app), retained)
        capture("identity05-story-return-retained-relaunch", in: app)
    }

    @MainActor func testNormalSilverFinalActionRepairsAndReplayKeepsExactOpening() throws {
        executionTimeAllowance = 180
        normalSystemMotion()
        let app = launch(legacyAccess: true)
        defer { app.terminate() }
        // Existing-install access permits entry; this is a real current repair,
        // not a claim that this fixture first unlocks a previously locked place.
        app.worldVisitControl("silverPools").tap()
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("12,000 starlight"))
        tap("sky.begin", in: app)
        pauseNewStory(in: app)
        score(0, target: 12_000, in: app)
        settled(in: app)
        let opening = try cells(in: app)
        exchange(9, 10, score: 19_000, target: 12_000,
                 capture: "identity05-silver-final-action-pattern-return", in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 8))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        app.revealSkyControls([app.buttons["experiment.replay"]])
        XCTAssertTrue(app.buttons["experiment.replay"].isEnabled && app.buttons["experiment.replay"].isHittable)
        capture("identity05-silver-earned-result-controls", in: app)
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Silver Pools opening"))
        tap("sky.begin", in: app)
        pauseNewStory(in: app)
        score(0, target: 12_000, in: app)
        settled(in: app)
        XCTAssertEqual(try cells(in: app), opening)
        capture("identity05-silver-exact-replay-opening", in: app)
    }

    @MainActor func testLargestCalmFullBoardAndPairedPatternPracticeKeepRetainedRound() throws {
        executionTimeAllowance = 300
        let app = launch(largest: true)
        defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", in: app)
        tap("sky.begin", in: app)
        score(0, target: 150_000, in: app)
        settled(in: app)
        let originalCalm = setCalm(true, in: app, captureName: "identity05-tablet-actual-calm-setting", verifyOffToOn: true)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        exchange(27, 34, score: 42_000, target: 150_000,
                 capture: "identity05-tablet-full-board-pattern-return", in: app)
        let retained = try cells(in: app)
        tap("experiment.settings", in: app)
        tap("fullBoard.choices.open", in: app)
        tap("fullBoard.choices.practice", in: app)
        let title = app.staticTexts["tutorial.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Keep a follow-up")
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        let practiceOpening = try cells(in: app)
        exchange(3, 10, score: 81_000, target: 150_000,
                 capture: "identity05-tablet-comparison-survivor-pattern-return", in: app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("15,000"))
        app.revealSkyControls([app.staticTexts["tutorial.instruction"], app.buttons["tutorial.next"]])
        XCTAssertTrue(app.frame.contains(app.staticTexts["tutorial.instruction"].frame))
        capture("identity05-tablet-follow-up-reading", in: app)
        tap("tutorial.next", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Compare the larger clear"),
                                                object: title).wait(timeout: 10))
        XCTAssertEqual(try cells(in: app), practiceOpening)
        exchange(8, 15, score: 79_000, target: 150_000,
                 capture: "identity05-tablet-comparison-larger-pattern-return", in: app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("13,000"))
        app.revealSkyControls([app.staticTexts["tutorial.instruction"], app.buttons["tutorial.finish"]])
        XCTAssertTrue(app.frame.contains(app.staticTexts["tutorial.instruction"].frame))
        capture("identity05-tablet-larger-clear-reading", in: app)
        tap("tutorial.finish", in: app)
        XCTAssertFalse(title.exists)
        score(42_000, target: 150_000, in: app)
        settled(in: app)
        XCTAssertEqual(try cells(in: app), retained, "Paired automatic-pattern practice must not write the retained round")
        capture("identity05-tablet-unchanged-full-board-return", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
