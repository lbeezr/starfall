import XCTest

/// Native outcomes and captures for actual delivered Lantern awards. The
/// passive receiver response is inspected separately from state assertions;
/// screenshots do not establish its complete short animation or cancellation.
final class LanternAwardResponseInteractionTests: XCTestCase {
    private struct RoundState {
        let board: String?
        let score: String
        let cells: [String]
    }

    // Existing production FullBoard6 witness; no board, score or supply injection.
    private let winningMoves: [(from: Int, to: Int, score: Int)] = [
        (27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000), (12, 13, 63_000),
        (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
        (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)
    ]

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

    private func arguments(largest: Bool, reset: Bool) -> [String] {
        var result = ["--sky-flow-review"]
        if reset { result.append("--starfalls-reset") }
        // Do not mask the actual preference changed in the tablet journey.
        if !largest { result += ["-calmEffects", "NO"] }
        if largest { result += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        return result
    }

    @MainActor private func launch(largest: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = arguments(largest: largest, reset: true)
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

    @MainActor private func identities(_ root: XCUIElement, prefix: String) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button, node.identifier.hasPrefix(prefix) {
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try root.snapshot())
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

    @MainActor private func settled(_ points: Int, exchanges: Int? = nil, in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let expected = "\(points.formatted()) of 150,000 starlight collected"
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard board.exists, app.staticTexts["experiment.score"].label == expected,
                  let value = board.value as? String, !value.contains("Stars settling"),
                  app.buttons["experiment.cell.0.0"].isEnabled, blocked.count == 0 else { return false }
            return exchanges.map { value.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? value.hasPrefix("0 showers")
        }, object: nil).wait(timeout: 10), "Expected the exact settled Lantern award \(points)")
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor private func restoration(_ percent: Int, in app: XCUIApplication) {
        let label = app.descendants(matching: .any).matching(identifier: "lantern.restoration").firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "Lantern Landing, \(percent)% restored"), object: label).wait(timeout: 5))
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        tap("experiment.settings", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Pause sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5))
        tap("experiment.pause", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                                object: app.buttons["experiment.next"]).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, capture name: String? = nil,
                                     in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        // External recording owns continuous arrival/response evidence. Capture
        // promptly, before score and settlement queries consume that interval.
        if let name { capture(name, in: app) }
    }

    @MainActor private func assertWorld(_ expected: [String], in app: XCUIApplication) throws {
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        let actual = try identities(app, prefix: "world.place.")
        XCTAssertEqual(actual.count, 12); XCTAssertEqual(actual, expected)
        tap("world.done", in: app)
    }

    @MainActor private func interruptAndRestore(_ expected: RoundState, points: Int,
                                              exchanges: Int? = nil, largest: Bool = false,
                                              in app: XCUIApplication) throws {
        tap("experiment.settings", in: app)
        XCUIDevice.shared.press(.home); app.activate()
        tap("experiment.done", in: app)
        settled(points, exchanges: exchanges, in: app)
        try assertRound(expected, in: app)
        app.terminate(); app.launchArguments = arguments(largest: largest, reset: false); app.launch()
        tap("sky.resume", in: app)
        settled(points, exchanges: exchanges, in: app)
        try assertRound(expected, in: app)
    }

    @MainActor private func setCalm(_ enabled: Bool, verifyOffToOn: Bool = false,
                                   captureName: String? = nil, in app: XCUIApplication) -> Bool {
        tap("experiment.settings", in: app); tap("experiment.preferences", in: app)
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

    @MainActor private func replay(fullBoard: Bool, opening: RoundState, in app: XCUIApplication) throws {
        tap("experiment.settings", in: app); tap("experiment.replay", in: app)
        if fullBoard { XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board")) }
        tap("sky.begin", in: app)
        if !fullBoard { pauseNewSky(in: app) }
        settled(0, exchanges: fullBoard ? 0 : nil, in: app)
        try assertRound(opening, in: app)
    }

    @MainActor func testNormalBelowMilestoneAwardNoAwardContrastAndExactReplay() throws {
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, in: app); restoration(0, in: app)
        let opening = try round(in: app)
        tap("experiment.cell.0.0", in: app)
        settled(0, in: app); try assertRound(opening, in: app)
        capture("identity07-phone-inspection-no-award", in: app)
        exchange(5, 6, capture: "identity07-phone-setup-no-delivery", in: app)
        settled(0, in: app); restoration(0, in: app)
        XCTAssertNotEqual(try round(in: app).cells, opening.cells)
        exchange(6, 5, capture: "identity07-phone-reversed-setup-no-delivery", in: app)
        settled(0, in: app); try assertRound(opening, in: app)
        exchange(8, 9, capture: "identity07-phone-below-quarter-delivered-award", in: app)
        settled(15_000, in: app); restoration(10, in: app)
        let retained = try round(in: app)
        try interruptAndRestore(retained, points: 15_000, in: app)
        try assertWorld(world, in: app)
        settled(15_000, in: app); try assertRound(retained, in: app)
        capture("identity07-phone-below-quarter-exact-restore", in: app)
        try replay(fullBoard: false, opening: opening, in: app)
        restoration(0, in: app)
        capture("identity07-phone-replay-zero-no-stale-response", in: app)
    }

    @MainActor func testLargestCalmBelowMilestoneMilestoneAndFinalRepairKeepExactReplay() throws {
        executionTimeAllowance = 480
        let app = launch(largest: true)
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        XCTAssertEqual(app.buttons["world.place.ribbonCrossing"].value as? String, "Restore Lantern Landing first")
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, exchanges: 0, in: app)
        let opening = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true,
            captureName: "identity07-tablet-actual-calm-off-on", in: app)
        exchange(8, 9, capture: "identity07-tablet-below-quarter-delivered-award", in: app)
        settled(15_000, exchanges: 1, in: app); restoration(10, in: app)
        let belowQuarter = try round(in: app)
        try interruptAndRestore(belowQuarter, points: 15_000, exchanges: 1, largest: true, in: app)
        try assertWorld(world, in: app)
        settled(15_000, exchanges: 1, in: app); try assertRound(belowQuarter, in: app)
        try replay(fullBoard: true, opening: opening, in: app)
        restoration(0, in: app)

        for (index, move) in winningMoves.enumerated() {
            let name: String? = index == 0 ? "identity07-tablet-quarter-milestone-delivery"
                : move.score >= 150_000 ? "identity07-tablet-final-repair-delivery" : nil
            exchange(move.from, move.to, capture: name, in: app)
            if move.score < 150_000 {
                settled(move.score, exchanges: index + 1, in: app)
                XCTAssertEqual(app.buttons.matching(NSPredicate(format:
                    "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 49)
            }
            if index == 0 { restoration(28, in: app) }
        }
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("156,000 of 150,000 starlight collected"))
        let onward = app.buttons["sky.worldMap"], replay = app.buttons["experiment.replay"]
        XCTAssertEqual(onward.label, "Visit Ribbon Crossing")
        app.revealSkyControls([onward, replay])
        XCTAssertTrue(onward.isEnabled && onward.isHittable && replay.isEnabled && replay.isHittable)
        capture("identity07-tablet-earned-result-usable-controls", in: app)
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Ribbon Crossing")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        _ = app.worldVisitControl("ribbonCrossing")
        XCTAssertEqual(app.buttons["world.place.firstLight"].value as? String, "Restored")
        XCTAssertEqual(app.buttons["world.place.ribbonCrossing"].value as? String, "Ready to restore")
        let afterRepair = try identities(app, prefix: "world.place.")
        XCTAssertEqual(afterRepair.count, 12)
        func otherPlaces(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.firstLight:") && !$0.hasPrefix("world.place.ribbonCrossing:") }
        }
        XCTAssertEqual(otherPlaces(afterRepair), otherPlaces(world), "Only the genuinely earned repair and immediate access change")
        XCTAssertTrue(app.buttons["world.visit"].isEnabled)
        capture("identity07-tablet-earned-ribbon-access", in: app)
        tap("world.done", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.begin", in: app)
        settled(0, exchanges: 0, in: app)
        try assertRound(opening, in: app); restoration(0, in: app)
        capture("identity07-tablet-final-exact-replay-zero", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
