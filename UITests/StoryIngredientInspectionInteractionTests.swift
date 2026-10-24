import XCTest

/// Native taps inspect committed ingredients without consuming them. Production
/// exchanges remain the only source of clears, points and restoration progress.
final class StoryIngredientInspectionInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let smallAqua = "Spark. Aqua swept comet shard, Spark. Small: 1 light unit. Swipe neighbors into squares of 4, crosses of 5, or straight lines of 4 or more. Patterns pop automatically."
    private let grownAqua = "Spark. Aqua swept comet shard, Spark. Grown: 2 light units. Swipe neighbors into squares of 4, crosses of 5, or straight lines of 4 or more. Patterns pop automatically."

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

    @MainActor private func tap(_ id: String, in app: XCUIApplication) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND enabled == true AND hittable == true"),
            object: control).wait(timeout: 5), id)
        XCTAssertTrue(app.frame.contains(control.frame))
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

    @MainActor private func seedScore(_ points: Int, in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of 11,000 starlight collected"
                && board.hasPrefix("0 showers") && !board.contains("Stars settling")
                && app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled
        }, object: nil).wait(timeout: 10))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor private func fullBoard(_ points: Int, exchanges: Int, in app: XCUIApplication) {
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of 150,000 starlight collected"
                && board.hasPrefix("Exchanges: \(exchanges). Full Board.") && !board.contains("Stars settling")
                && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        // Require actual modal admission, rather than the first rendered cell.
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        app.revealSkyControls([pause])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Start sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5))
        let next = app.buttons["experiment.next"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func inspect(_ cell: String, expected: String, capture name: String,
                                   in app: XCUIApplication) throws {
        let retained = try round(in: app)
        let star = app.buttons[cell]
        app.revealSkyControls([star])
        XCTAssertTrue(star.isEnabled && star.isHittable)
        XCTAssertEqual(star.value as? String, "Automatic pattern play")
        star.tap()
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected),
                                                object: message).wait(timeout: 5))
        let close = app.buttons["sky.dialogue.close"]
        app.revealSkyControls([close])
        let reader = app.scrollViews["sky.dialogue.reading"]
        if reader.exists {
            let visible = app.frame.intersection(reader.frame)
            XCTAssertFalse(visible.isEmpty)
            // A previously read message can leave the same native reader
            // scrolled. Reveal the new ingredient's actual first line first.
            for _ in 0..<4 where message.frame.minY < visible.minY - 1 { reader.swipeDown() }
            XCTAssertGreaterThanOrEqual(message.frame.minY, visible.minY - 1)
            XCTAssertLessThan(message.frame.minY, visible.maxY)
        } else {
            app.revealSkyControls([message])
            XCTAssertTrue(app.frame.contains(message.frame))
        }
        capture(name + "-start", in: app)
        // Ordinary constrained dialogue places Close beside the paragraph;
        // accessibility layouts put it below. The reader, rather than Close's
        // vertical position, bounds the text in both production layouts.
        if reader.exists {
            for _ in 0..<4 where message.frame.maxY > app.frame.intersection(reader.frame).maxY + 1 {
                reader.swipeUp()
            }
        }
        XCTAssertTrue(message.exists)
        XCTAssertFalse(message.frame.isEmpty)
        XCTAssertTrue(message.isHittable, "The ingredient guide's final line must remain visible")
        XCTAssertEqual(message.label, expected)
        if reader.exists {
            let visible = app.frame.intersection(reader.frame)
            XCTAssertLessThanOrEqual(message.frame.maxY, visible.maxY + 1)
            XCTAssertGreaterThan(message.frame.maxY, visible.minY)
            if message.frame.height <= visible.height {
                XCTAssertTrue(visible.insetBy(dx: -1, dy: -1).contains(message.frame))
            }
        } else {
            XCTAssertTrue(app.frame.contains(message.frame))
        }
        XCTAssertTrue(app.frame.contains(close.frame))
        XCTAssertTrue(close.isEnabled && close.isHittable)
        capture(name + "-end", in: app)
        XCTAssertEqual(try round(in: app), retained, "Ingredient inspection must not commit, clear or change a forecast")
        close.tap()
        XCTAssertEqual(try round(in: app), retained)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func assertWorld(_ expected: [String], in app: XCUIApplication) throws {
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        XCTAssertEqual(try identities(app, prefix: "world.place."), expected)
        tap("world.done", in: app)
    }

    @MainActor private func setCalm(_ enabled: Bool, verifyOffToOn: Bool = false,
                                   in app: XCUIApplication) -> Bool {
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
        capture("ingredient-inspection-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor func testNormalSeedIngredientsInspectWithoutCommitAndRestore() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        // Existing-install access admits Seed. This does not claim that earlier
        // repairs were earned during this isolated native inspection journey.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("seedMoon")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Seed Moon")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("11,000"))
        tap("sky.begin", in: app); pauseNewSky(in: app)
        seedScore(0, in: app)
        let opening = try round(in: app)
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.contains("Grown"))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].label.contains("Grown"))
        try inspect("experiment.cell.0.1", expected: grownAqua, capture: "ingredient-inspection-phone-grown-aqua", in: app)
        try inspect("experiment.cell.0.0", expected: smallAqua, capture: "ingredient-inspection-phone-small-aqua", in: app)
        XCTAssertEqual(try round(in: app), opening)
        try assertWorld(initialWorld, in: app); seedScore(0, in: app)

        // Existing Seed4 preserve route: ID1 moves from0.1 to1.1 without a clear.
        exchange(1, 8, in: app); seedScore(0, in: app)
        let moved = try round(in: app)
        XCTAssertNotEqual(moved.cells, opening.cells)
        XCTAssertTrue(app.buttons["experiment.cell.1.1"].label.contains("Grown"))
        try inspect("experiment.cell.1.1", expected: grownAqua,
                    capture: "ingredient-inspection-phone-current-grown-after-setup", in: app)
        XCTAssertEqual(try round(in: app), moved)
        XCUIDevice.shared.press(.home); app.activate()
        seedScore(0, in: app); XCTAssertEqual(try round(in: app), moved)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        seedScore(0, in: app); XCTAssertEqual(try round(in: app), moved)
        try inspect("experiment.cell.1.1", expected: grownAqua,
                    capture: "ingredient-inspection-phone-restored-current-grown", in: app)
        try assertWorld(initialWorld, in: app)
        seedScore(0, in: app); XCTAssertEqual(try round(in: app), moved)
    }

    @MainActor func testLargestCalmFullBoardIngredientsInspectThenClear() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        let app = XCUIApplication()
        // Actual Settings must remain writable; no Calm argument-domain override.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        fullBoard(0, exchanges: 0, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        let opening = try round(in: app)
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].label.contains("Grown"))
        try inspect("experiment.cell.0.0", expected: smallAqua,
                    capture: "ingredient-inspection-tablet-full-board-small-aqua", in: app)
        fullBoard(0, exchanges: 0, in: app)
        XCTAssertEqual(try round(in: app), opening)
        try assertWorld(initialWorld, in: app)
        fullBoard(0, exchanges: 0, in: app); XCTAssertEqual(try round(in: app), opening)
        exchange(27, 34, in: app)
        capture("ingredient-inspection-tablet-following-real-clear", in: app)
        fullBoard(42_000, exchanges: 1, in: app)
        let cleared = try round(in: app)
        XCTAssertNotEqual(cleared.cells, opening.cells)
        try assertWorld(initialWorld, in: app)
        fullBoard(42_000, exchanges: 1, in: app); XCTAssertEqual(try round(in: app), cleared)
        _ = setCalm(originalCalm, in: app)
    }
}
