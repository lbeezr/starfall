import XCTest

/// Committed production chains, separate actions and simultaneous recipes have
/// distinct inputs. Passive return art is reviewed from the attached captures
/// and external recording; these assertions own the exact playable outcomes.
final class CascadeReturnInteractionTests: XCTestCase {
    private struct RoundState {
        let board: String?
        let score: String
        let cells: [String]
    }

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

    private func arguments(largest: Bool, reset: Bool, legacyAccess: Bool = false) -> [String] {
        var result = ["--sky-flow-review"]
        if reset { result.append("--starfalls-reset") }
        // Actual Settings writes must not be masked by NSArgumentDomain.
        if !largest { result += ["-calmEffects", "NO"] }
        if legacyAccess { result += ["--dialogue-review", "--world-legacy-review"] }
        if largest { result += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        return result
    }

    @MainActor private func launch(largest: Bool = false, legacyAccess: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = arguments(largest: largest, reset: true, legacyAccess: legacyAccess)
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
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func identities(_ element: XCUIElement, prefix: String) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button, node.identifier.hasPrefix(prefix) {
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try element.snapshot())
        return result.sorted()
    }

    @MainActor private func round(in app: XCUIApplication) throws -> RoundState {
        let board = app.otherElements["experiment.board"]
        let cells = try identities(board, prefix: "experiment.cell.")
        XCTAssertEqual(cells.count, 49)
        return RoundState(board: board.value as? String,
                          score: app.staticTexts["experiment.score"].label, cells: cells)
    }

    @MainActor private func assertRound(_ expected: RoundState, in app: XCUIApplication) throws {
        let actual = try round(in: app)
        XCTAssertEqual(actual.board, expected.board)
        XCTAssertEqual(actual.score, expected.score)
        XCTAssertEqual(actual.cells, expected.cells)
    }

    @MainActor private func settled(score: Int, target: Int, in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let points = app.staticTexts["experiment.score"]
        let expected = "\(score.formatted()) of \(target.formatted()) starlight collected"
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.exists && points.label == expected
                && (board.value as? String)?.contains("Stars settling") == false
                && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
        }, object: nil).wait(timeout: 10), "Expected settled score \(score) of \(target)")
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor private func pauseNewStory(in app: XCUIApplication) {
        // Wait for modal admission, not just the first registered cell.
        tap("experiment.settings", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Pause sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5))
        tap("experiment.pause", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                                object: app.buttons["experiment.next"]).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, capture name: String, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        capture("\(name)-before-input", in: app)
        let gestureStart = Date()
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        // Capture before settlement queries consume the bounded return interval.
        capture(name, in: app)
        let timing = XCTAttachment(string: "gestureStartEpoch=\(gestureStart.timeIntervalSince1970); captureEndEpoch=\(Date.now.timeIntervalSince1970). Passive timestamps bind the separately recorded normal motion; no latency threshold is inferred.")
        timing.name = "\(name)-motion-timing"; timing.lifetime = .keepAlways; add(timing)
    }

    @MainActor private func separateClearsWithoutInterveningQueries(in app: XCUIApplication) {
        let ids = ["experiment.cell.0.0", "experiment.cell.0.1", "experiment.cell.0.5", "experiment.cell.1.5"]
        let controls = ids.map { app.buttons[$0] }
        app.revealSkyControls(controls)
        for control in controls {
            XCTAssertTrue(control.isEnabled && control.isHittable)
            XCTAssertEqual(control.value as? String, "Automatic pattern play")
        }
        let window = app.frame
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let points = controls.map { control in
            let frame = control.frame
            return origin.withOffset(.init(dx: frame.midX - window.minX, dy: frame.midY - window.minY))
        }
        let wallStart = Date()
        let start = ContinuousClock.now
        points[0].press(forDuration: 0.05, thenDragTo: points[1], withVelocity: .fast, thenHoldForDuration: 0.05)
        let firstEnd = ContinuousClock.now
        // No screenshot, accessibility query, score wait or settle wait occurs
        // between these independent line and square inputs.
        points[2].press(forDuration: 0.05, thenDragTo: points[3], withVelocity: .fast, thenHoldForDuration: 0.05)
        let end = ContinuousClock.now
        capture("identity06-phone-two-separate-returns", in: app)
        let timing = XCTAttachment(string: "wallStart=\(wallStart.ISO8601Format()); "
            + "firstGesture=\(start.duration(to: firstEnd)); secondGesture=\(firstEnd.duration(to: end)); "
            + "total=\(start.duration(to: end)). No sub-receipt latency threshold is inferred.")
        timing.name = "identity06-separate-input-actual-timing"
        timing.lifetime = .keepAlways; add(timing)
    }

    @MainActor private func assertWorld(_ expected: [String], in app: XCUIApplication) throws {
        tap("experiment.settings", in: app)
        tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        let actual = try identities(app, prefix: "world.place.")
        XCTAssertEqual(actual.count, 12)
        XCTAssertEqual(actual, expected, "Return presentation cannot earn a repair or alter local world status")
        tap("world.done", in: app)
    }

    @MainActor private func settingsBackgroundAndRestore(_ expected: RoundState, score: Int, target: Int,
                                                        largest: Bool = false, legacyAccess: Bool = false,
                                                        in app: XCUIApplication) throws {
        tap("experiment.settings", in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        tap("experiment.done", in: app)
        settled(score: score, target: target, in: app)
        try assertRound(expected, in: app)
        app.terminate()
        // Keep the same isolated defaults suite selected by the initial launch.
        // The legacy marker cannot grant access again without an explicit reset.
        app.launchArguments = arguments(largest: largest, reset: false, legacyAccess: legacyAccess)
        app.launch()
        tap("sky.resume", in: app)
        settled(score: score, target: target, in: app)
        try assertRound(expected, in: app)
    }

    @MainActor private func setCalm(_ enabled: Bool, verifyOffToOn: Bool = false,
                                   captureName: String? = nil, in app: XCUIApplication) -> Bool {
        tap("experiment.settings", in: app)
        tap("experiment.preferences", in: app)
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        app.revealSkyMenuElement(calm); app.revealSkyControls([calm])
        let original = calm.value as? String == "1"
        func select(_ value: String) {
            if calm.value as? String != value { calm.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value),
                                                    object: calm).wait(timeout: 5))
            XCTAssertEqual(calm.value as? String, value)
        }
        if enabled && verifyOffToOn { select("0") }
        select(enabled ? "1" : "0")
        if let captureName { capture(captureName, in: app) }
        tap("experiment.done", in: app)
        return original
    }

    @MainActor func testNormalTwoPhaseChainSeparateActionsAndReplay() throws {
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.begin", in: app); pauseNewStory(in: app)
        settled(score: 0, target: 150_000, in: app)
        let opening = try round(in: app)
        exchange(8, 9, capture: "identity06-phone-two-phase-square-chain", in: app)
        settled(score: 15_000, target: 150_000, in: app)
        separateClearsWithoutInterveningQueries(in: app)
        settled(score: 25_000, target: 150_000, in: app)
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 8)
        let retained = try round(in: app)
        try settingsBackgroundAndRestore(retained, score: 25_000, target: 150_000, in: app)
        try assertWorld(world, in: app)
        settled(score: 25_000, target: 150_000, in: app)
        try assertRound(retained, in: app)
        capture("identity06-phone-separate-actions-retained", in: app)
        tap("experiment.settings", in: app); tap("experiment.replay", in: app)
        tap("sky.begin", in: app); pauseNewStory(in: app)
        settled(score: 0, target: 150_000, in: app)
        try assertRound(opening, in: app)
        capture("identity06-phone-two-phase-exact-replay", in: app)
    }

    @MainActor func testNormalDenseThreePhaseRibbonReturnInterruptionAndReplay() throws {
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = launch(legacyAccess: true)
        defer { app.terminate() }
        let visit = app.worldVisitControl("ribbonCrossing")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.ribbonMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(score: 0, target: 220_000, in: app)
        XCTAssertTrue(app.staticTexts["ribbon.mode"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let opening = try round(in: app)
        exchange(8, 9, capture: "identity06-phone-ribbon-three-phase-returns", in: app)
        settled(score: 30_000, target: 220_000, in: app)
        let afterChain = try round(in: app)
        XCTAssertTrue(afterChain.board?.hasPrefix("Exchanges: 1. Full Board.") == true)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 49)
        exchange(11, 12, capture: "identity06-phone-ribbon-separate-following-clear", in: app)
        settled(score: 35_000, target: 220_000, in: app)
        let retained = try round(in: app)
        XCTAssertTrue(retained.board?.hasPrefix("Exchanges: 2. Full Board.") == true)
        try settingsBackgroundAndRestore(retained, score: 35_000, target: 220_000, legacyAccess: true, in: app)
        try assertWorld(world, in: app)
        settled(score: 35_000, target: 220_000, in: app)
        try assertRound(retained, in: app)
        tap("experiment.settings", in: app); tap("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.begin", in: app)
        settled(score: 0, target: 220_000, in: app)
        try assertRound(opening, in: app)
        exchange(8, 9, capture: "identity06-phone-ribbon-replayed-three-phase-returns", in: app)
        settled(score: 30_000, target: 220_000, in: app)
        try assertRound(afterChain, in: app)
    }

    @MainActor func testLargestCalmDenseChainAndSimultaneousPatternsKeepRetainedRound() throws {
        executionTimeAllowance = 300
        let app = launch(largest: true)
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(score: 0, target: 150_000, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true,
            captureName: "identity06-tablet-actual-calm-off-on", in: app)
        exchange(8, 9, capture: "identity06-tablet-full-board-two-phase-returns", in: app)
        settled(score: 15_000, target: 150_000, in: app)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let retained = try round(in: app)
        tap("experiment.settings", in: app)
        tap("fullBoard.choices.open", in: app); tap("fullBoard.choices.practice", in: app)
        let title = app.staticTexts["tutorial.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Keep a follow-up")
        let comparisonOpening = try round(in: app)
        exchange(3, 10, capture: "identity06-tablet-square-then-survivor-line", in: app)
        settled(score: 81_000, target: 150_000, in: app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("15,000"))
        tap("tutorial.next", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Compare the larger clear"),
                                                object: title).wait(timeout: 10))
        try assertRound(comparisonOpening, in: app)
        exchange(8, 15, capture: "identity06-tablet-one-phase-two-simultaneous-squares", in: app)
        settled(score: 79_000, target: 150_000, in: app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("13,000"))
        app.revealSkyControls([app.staticTexts["tutorial.instruction"], app.buttons["tutorial.finish"]])
        XCTAssertTrue(app.frame.contains(app.staticTexts["tutorial.instruction"].frame))
        capture("identity06-tablet-simultaneous-pattern-reading", in: app)
        tap("tutorial.finish", in: app)
        XCTAssertFalse(title.exists)
        settled(score: 15_000, target: 150_000, in: app)
        try assertRound(retained, in: app)
        try settingsBackgroundAndRestore(retained, score: 15_000, target: 150_000, largest: true, in: app)
        try assertWorld(world, in: app)
        settled(score: 15_000, target: 150_000, in: app)
        try assertRound(retained, in: app)
        capture("identity06-tablet-exact-retained-round-after-returns", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
