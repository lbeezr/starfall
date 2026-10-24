import XCTest

/// Forecast contact locates the announced column; it never plays a move or
/// predicts growth, clears or available headroom.
final class ForecastColumnInspectionInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    @MainActor private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
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
        let attachment = XCTAttachment(screenshot: app.screenshot())
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

    @MainActor private func settled(_ points: Int, target: Int, showers: Int,
                                    in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of \(target.formatted()) starlight collected"
                && board.hasPrefix("\(showers) showers") && !board.contains("Stars settling")
                && app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor private func fullBoard(_ points: Int, exchanges: Int, in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of 150,000 starlight collected"
                && board.hasPrefix("Exchanges: \(exchanges). Full Board.") && !board.contains("Stars settling")
                && app.buttons["experiment.cell.0.0"].isEnabled
        }, object: nil).wait(timeout: 12))
        XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        XCTAssertFalse(element("sky.forecast.destinations", in: app).exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sky.forecast.star.")).count, 0)
        XCTAssertFalse(element("sky.forecast.column", in: app).exists)
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
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

    @MainActor private func assertForecast(ids: [Int], columns: [Int]? = nil,
                                          in app: XCUIApplication) -> String {
        let forecast = element("sky.forecast.destinations", in: app)
        XCTAssertTrue(forecast.waitForExistence(timeout: 5))
        XCTAssertEqual(forecast.label, "Next columns")
        XCTAssertGreaterThanOrEqual(forecast.frame.height, 44)
        XCTAssertLessThan(forecast.frame.height, 400, "Forecast targets reflow within a bounded header")
        let value = forecast.value as? String ?? ""
        let descriptions = value.components(separatedBy: ", then ")
        XCTAssertEqual(descriptions.count, ids.count)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sky.forecast.star.")).count, ids.count)
        for (index, id) in ids.enumerated() {
            let chip = app.buttons["sky.forecast.star.\(id)"]
            XCTAssertTrue(chip.exists && chip.isEnabled)
            XCTAssertGreaterThanOrEqual(chip.frame.width, 44)
            XCTAssertGreaterThanOrEqual(chip.frame.height, 44)
            XCTAssertTrue(app.frame.contains(chip.frame), "Every complete target must fit the screen")
            XCTAssertTrue(forecast.frame.contains(chip.frame), "Every complete target must fit its actual reading surface")
            if index < descriptions.count { XCTAssertEqual(chip.label, descriptions[index]) }
            if let columns, index < columns.count, index < descriptions.count {
                XCTAssertTrue(descriptions[index].hasSuffix("column \(columns[index])"), descriptions[index])
            }
        }
        return value
    }

    @MainActor private func assertNoFocus(in app: XCUIApplication) {
        let cue = element("sky.forecast.column", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                object: cue).wait(timeout: 5))
        for chip in app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "sky.forecast.star.")).allElementsBoundByIndex {
            XCTAssertFalse(chip.isSelected)
        }
    }

    @MainActor private func focus(_ id: Int, column: Int, capture name: String,
                                 in app: XCUIApplication) {
        let chip = app.buttons["sky.forecast.star.\(id)"]
        tap(chip.identifier, in: app)
        let cue = element("sky.forecast.column", in: app)
        XCTAssertTrue(cue.waitForExistence(timeout: 5))
        XCTAssertEqual(cue.label, "Column \(column)")
        XCTAssertEqual(cue.value as? String, String(column))
        XCTAssertTrue(chip.isSelected)
        let topCell = app.buttons["experiment.cell.6.\(column - 1)"]
        let scroll = app.scrollViews.containing(.button, identifier: topCell.identifier).allElementsBoundByIndex
            .min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
        let header = element("sky.header", in: app)
        func viewport() -> CGRect {
            let bounds = app.frame.intersection(scroll?.frame ?? app.frame)
            let top = max(bounds.minY, header.exists ? header.frame.maxY + 4 : bounds.minY)
            return CGRect(x: bounds.minX, y: top, width: bounds.width, height: max(0, bounds.maxY - top))
        }
        // Pan only the non-playing edge. A passive cue has no hittability
        // contract, and the pinned header must not mask its top-row boundary.
        for _ in 0..<8 {
            let visible = viewport(), target = cue.frame
            XCTAssertGreaterThan(visible.height, 0)
            XCTAssertLessThanOrEqual(target.height, visible.height)
            if visible.contains(target) { break }
            let up = target.maxY > visible.maxY
            let distance = min(visible.height * 0.45,
                               max(24, up ? target.maxY - visible.maxY + 8 : visible.minY - target.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(
                .init(dx: visible.minX + 1, dy: visible.minY + visible.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTAssertTrue(viewport().contains(cue.frame), "The entire receiving column must be visible below the pinned header")
        XCTAssertTrue(app.frame.contains(chip.frame) && chip.isHittable)
        var expected = CGRect.null
        for row in 0..<7 {
            expected = expected.union(app.buttons["experiment.cell.\(row).\(column - 1)"].frame)
        }
        // AX reports the full painted outline: its five-point centered outer
        // stroke extends 2.5 points beyond the registered column centerline.
        // Compare that centerline to the actual seven native cell frames.
        let centerline = cue.frame.insetBy(dx: 2.5, dy: 2.5)
        XCTAssertEqual(centerline.minX, expected.minX, accuracy: 1)
        XCTAssertEqual(centerline.minY, expected.minY, accuracy: 1)
        XCTAssertEqual(centerline.width, expected.width, accuracy: 1)
        XCTAssertEqual(centerline.height, expected.height, accuracy: 1)
        capture(name, in: app)
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
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" { tap("world.list", in: app) }
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
        capture("forecast-inspection-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor func testNormalSeedForecastFocusDoesNotCommitAndRetiresOnReplacement() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let (settings, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce); settings.terminate()
        addTeardownBlock { @MainActor in
            let (settings, reduce) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: reduce); settings.terminate()
        }
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        // Legacy access models an existing install; this case earns no repair.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("seedMoon")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("11,000"))
        tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 11_000, showers: 0, in: app)
        let opening = try round(in: app)
        let preview = assertForecast(ids: Array(0..<5), columns: [6, 1, 2, 4, 5], in: app)
        focus(0, column: 6, capture: "forecast-inspection-phone-column-six", in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertEqual(element("sky.forecast.destinations", in: app).value as? String, preview)
        tap("sky.forecast.star.0", in: app); assertNoFocus(in: app)
        focus(1, column: 1, capture: "forecast-inspection-phone-column-one", in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCUIDevice.shared.press(.home); app.activate()
        settled(0, target: 11_000, showers: 0, in: app); assertNoFocus(in: app)
        XCTAssertEqual(try round(in: app), opening)
        tap("experiment.settings", in: app); tap("sky.home", in: app); tap("sky.resume", in: app)
        settled(0, target: 11_000, showers: 0, in: app); assertNoFocus(in: app)
        XCTAssertEqual(try round(in: app), opening)
        focus(2, column: 2, capture: "forecast-inspection-phone-before-real-setup", in: app)
        // Seed4's frozen preserve opening moves grown ID1 without any clear.
        exchange(1, 8, in: app)
        settled(0, target: 11_000, showers: 0, in: app); assertNoFocus(in: app)
        let moved = try round(in: app)
        XCTAssertNotEqual(moved.cells, opening.cells)
        XCTAssertTrue(app.buttons["experiment.cell.1.1"].label.contains("Grown"))
        XCTAssertEqual(assertForecast(ids: Array(0..<5), in: app), preview)
        focus(1, column: 1, capture: "forecast-inspection-phone-before-next-shower", in: app)
        tap("experiment.next", in: app)
        settled(0, target: 11_000, showers: 1, in: app); assertNoFocus(in: app)
        let showered = try round(in: app)
        XCTAssertNotEqual(showered.cells, moved.cells)
        _ = assertForecast(ids: Array(5..<10), in: app)
        for id in 0..<5 { XCTAssertFalse(app.buttons["sky.forecast.star.\(id)"].exists) }
        capture("forecast-inspection-phone-replaced-arrivals", in: app)
        try assertWorld(initialWorld, in: app)
        settled(0, target: 11_000, showers: 1, in: app)
        XCTAssertEqual(try round(in: app), showered)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        settled(0, target: 11_000, showers: 1, in: app); assertNoFocus(in: app)
        XCTAssertEqual(try round(in: app), showered)
        _ = assertForecast(ids: Array(5..<10), in: app)
    }

    @MainActor func testLargestCalmLanternForecastFocusRetiresBeforeFullBoard() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication()
        // No Calm argument override: this journey mutates actual Settings.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 150_000, showers: 0, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        let opening = try round(in: app)
        let preview = assertForecast(ids: Array(0..<5), columns: [6, 1, 2, 4, 5], in: app)
        focus(0, column: 6, capture: "forecast-inspection-tablet-column-six", in: app)
        XCTAssertEqual(try round(in: app), opening)
        focus(1, column: 1, capture: "forecast-inspection-tablet-column-one", in: app)
        XCTAssertFalse(app.buttons["sky.forecast.star.0"].isSelected)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertEqual(element("sky.forecast.destinations", in: app).value as? String, preview)
        // The actual exchange begins inside the highlighted passive column.
        focus(2, column: 2, capture: "forecast-inspection-tablet-before-real-chain", in: app)
        exchange(8, 9, in: app)
        settled(15_000, target: 150_000, showers: 0, in: app); assertNoFocus(in: app)
        let cleared = try round(in: app)
        XCTAssertNotEqual(cleared.cells, opening.cells)
        capture("forecast-inspection-tablet-real-automatic-chain", in: app)
        try assertWorld(initialWorld, in: app)
        settled(15_000, target: 150_000, showers: 0, in: app)
        XCTAssertEqual(try round(in: app), cleared)
        // worldVisitControl consumes an admitted picker/menu, not the playfield.
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        let newVisit = app.worldVisitControl("firstLight")
        newVisit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        fullBoard(0, exchanges: 0, in: app)
        capture("forecast-inspection-tablet-full-board-has-no-shower-focus", in: app)
        exchange(27, 34, in: app); fullBoard(42_000, exchanges: 1, in: app)
        try assertWorld(initialWorld, in: app)
        fullBoard(42_000, exchanges: 1, in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
