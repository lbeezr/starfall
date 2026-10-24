import XCTest
import UIKit

/// Existing-install access permits Ribbon entry; boards, awards and replay come
/// from current production definitions. Captures/recordings are inspected for
/// the passive seam response, separately from these exact state assertions.
final class RibbonAwardResponseInteractionTests: XCTestCase {
    private struct RoundState {
        let score: String
        let board: String?
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

    private func arguments(largest: Bool, reset: Bool) -> [String] {
        // DialogueReview must remain present on restore: it selects this same
        // isolated defaults suite ahead of SkyFlowReview.
        var result = ["--sky-flow-review", "--dialogue-review"]
        if reset { result += ["--starfalls-reset", "--world-legacy-review"] }
        // A launch override would mask actual @AppStorage preference writes.
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
        return RoundState(score: app.staticTexts["experiment.score"].label,
                          board: board.value as? String, cells: cells)
    }

    @MainActor private func assertRound(_ expected: RoundState, in app: XCUIApplication) throws {
        let actual = try round(in: app)
        XCTAssertEqual(actual.score, expected.score)
        XCTAssertEqual(actual.board, expected.board)
        XCTAssertEqual(actual.cells, expected.cells)
    }

    @MainActor private func settled(_ points: Int, exchanges: Int? = nil, in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let expected = "\(points.formatted()) of 220,000 starlight collected"
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard board.exists, app.staticTexts["experiment.score"].label == expected,
                  let value = board.value as? String, !value.contains("Stars settling"),
                  app.buttons["experiment.cell.0.0"].isEnabled, blocked.count == 0 else { return false }
            return exchanges.map { value.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? value.hasPrefix("0 showers")
        }, object: nil).wait(timeout: 10), "Expected exact settled Ribbon score \(points)")
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        if exchanges != nil {
            XCTAssertEqual(app.buttons.matching(NSPredicate(format:
                "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 49)
        }
    }

    @MainActor private func restoration(_ percent: Int, in app: XCUIApplication) {
        let label = app.descendants(matching: .any).matching(identifier: "ribbon.restoration").firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "Ribbon Crossing, \(percent)% restored"), object: label).wait(timeout: 5))
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                                object: app.buttons["experiment.next"]).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, capture name: String, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        // Record promptly; still capture latency cannot prove the complete
        // short response or the absence of a response before packet arrival.
        capture(name, in: app)
    }

    @MainActor private func assertWorld(_ expected: [String], in app: XCUIApplication) throws {
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.ribbonCrossing"].waitForExistence(timeout: 5))
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
        settled(points, exchanges: exchanges, in: app); try assertRound(expected, in: app)
        app.terminate(); app.launchArguments = arguments(largest: largest, reset: false); app.launch()
        tap("sky.resume", in: app)
        settled(points, exchanges: exchanges, in: app); try assertRound(expected, in: app)
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
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        XCTAssertFalse(app.buttons["sky.ribbonMode.fallingSky"].exists)
        XCTAssertFalse(app.buttons["sky.ribbonMode.fullBoard"].exists)
        if fullBoard { XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board")) }
        tap("sky.begin", in: app)
        if !fullBoard { pauseNewSky(in: app) }
        settled(0, exchanges: fullBoard ? 0 : nil, in: app)
        try assertRound(opening, in: app); restoration(0, in: app)
    }

    @MainActor func testNormalSkyNoAwardAndBelowMilestoneDeliveryKeepExactReplay() throws {
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("ribbonCrossing")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap()
        XCTAssertTrue(app.buttons["sky.ribbonMode.fallingSky"].isSelected)
        tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, in: app); restoration(0, in: app)
        let opening = try round(in: app)
        capture("identity08-phone-damaged-opening", in: app)
        tap("experiment.cell.0.0", in: app)
        settled(0, in: app); try assertRound(opening, in: app)
        capture("identity08-phone-inspection-no-award", in: app)
        // Same-family exchange leaves the recipe-free material arrangement
        // unchanged. Native labels do not expose the exchanged underlying IDs.
        exchange(0, 1, capture: "identity08-phone-setup-no-delivery", in: app)
        settled(0, in: app); restoration(0, in: app)
        exchange(1, 0, capture: "identity08-phone-reversed-setup-no-delivery", in: app)
        settled(0, in: app); try assertRound(opening, in: app)
        exchange(8, 9, capture: "identity08-phone-below-quarter-delivery", in: app)
        settled(30_000, in: app); restoration(14, in: app)
        let retained = try round(in: app)
        capture("identity08-phone-below-quarter-settled", in: app)
        try interruptAndRestore(retained, points: 30_000, in: app)
        try assertWorld(world, in: app)
        settled(30_000, in: app); try assertRound(retained, in: app)
        capture("identity08-phone-delivered-round-restored", in: app)
        try replay(fullBoard: false, opening: opening, in: app)
        capture("identity08-phone-exact-replay-zero", in: app)
    }

    @MainActor func testLargestCalmSameAwardPortraitLandscapeAndExactReplay() throws {
        executionTimeAllowance = 300
        XCUIDevice.shared.orientation = .portrait
        let app = launch(largest: true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        let visit = app.worldVisitControl("ribbonCrossing")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.ribbonMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, exchanges: 0, in: app)
        XCTAssertTrue(app.staticTexts["ribbon.mode"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let opening = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true,
            captureName: "identity08-tablet-actual-calm-off-on", in: app)
        capture("identity08-tablet-portrait-damaged-opening", in: app)
        // The frozen current FullBoard7 line-first route starts with one 5k clear.
        exchange(1, 2, capture: "identity08-tablet-portrait-five-thousand-delivery", in: app)
        settled(5_000, exchanges: 1, in: app); restoration(2, in: app)
        let portraitAward = try round(in: app)
        capture("identity08-tablet-portrait-award-settled", in: app)
        try interruptAndRestore(portraitAward, points: 5_000, exchanges: 1, largest: true, in: app)
        try assertWorld(world, in: app)
        settled(5_000, exchanges: 1, in: app); try assertRound(portraitAward, in: app)
        try replay(fullBoard: true, opening: opening, in: app)

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil).wait(timeout: 8))
        settled(0, exchanges: 0, in: app); try assertRound(opening, in: app)
        capture("identity08-tablet-landscape-damaged-replay", in: app)
        exchange(1, 2, capture: "identity08-tablet-landscape-five-thousand-delivery", in: app)
        settled(5_000, exchanges: 1, in: app); restoration(2, in: app)
        try assertRound(portraitAward, in: app)
        capture("identity08-tablet-landscape-same-award-settled", in: app)
        try interruptAndRestore(portraitAward, points: 5_000, exchanges: 1, largest: true, in: app)
        try assertWorld(world, in: app)
        settled(5_000, exchanges: 1, in: app); try assertRound(portraitAward, in: app)
        try replay(fullBoard: true, opening: opening, in: app)

        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.height > app.frame.width
        }, object: nil).wait(timeout: 8))
        settled(0, exchanges: 0, in: app); try assertRound(opening, in: app)
        capture("identity08-tablet-final-exact-replay-zero", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
