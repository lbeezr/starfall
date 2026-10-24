import XCTest

/// Read one actual announced shower without committing its copied outcome.
/// The prior Silver repair is an existing isolated review fixture, not an
/// earned-campaign claim; explicit Visit/Begin selects production Frostfruit8.
final class ShowerInspectionInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let descriptions = ["Aqua swept comet shard, Spark", "Amber irregular sun shard, Sunny",
                                "Aqua swept comet shard, Spark", "Mint angular meteor shard, Pip",
                                "Rose tall glint shard, Twinkle"]
    private let columns = [6, 1, 2, 4, 5]

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

    @MainActor private func settled(_ points: Int, showers: Int, in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of 15,000 starlight collected"
                && board.hasPrefix("\(showers) showers") && !board.contains("Stars settling")
                && app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
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

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(source.isEnabled && source.isHittable && target.isEnabled && target.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    /// Read each complete row within the actual sheet reader, excluding the
    /// fixed title and Done. A passive row need not accept a tap.
    @MainActor private func read(_ id: String, expected: String, capture name: String,
                                in app: XCUIApplication) {
        let target = element(id, in: app)
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertEqual(target.label, expected)
        func readingArea() -> (scroll: XCUIElement, viewport: CGRect)? {
            let owners = app.scrollViews.containing(NSPredicate(format: "identifier == %@", id)).allElementsBoundByIndex
            guard let scroll = owners.filter({ !$0.frame.isEmpty }).min(by: {
                $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height
            }) else { XCTFail("The inspection must have a real reading viewport"); return nil }
            var visible = app.frame.intersection(scroll.frame)
            for ancestor in owners where ancestor.frame != scroll.frame {
                if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == scroll.frame }) {
                    visible = visible.intersection(ancestor.frame)
                }
            }
            let title = element("sky.menu.title", in: app), done = app.buttons["experiment.done"]
            let top = max(visible.minY, title.frame.maxY)
            let bottom = min(visible.maxY, done.frame.minY)
            visible = CGRect(x: visible.minX, y: top, width: visible.width, height: max(0, bottom - top))
            guard !visible.isEmpty, !visible.isNull else {
                XCTFail("The reader must exclude the fixed title and Done"); return nil
            }
            return (scroll, visible)
        }
        for attempt in 0...8 {
            guard let area = readingArea() else { return }
            let bounds = target.frame
            XCTAssertGreaterThan(bounds.width, 0); XCTAssertGreaterThan(bounds.height, 0)
            XCTAssertLessThanOrEqual(bounds.height, area.viewport.height,
                                     "A whole inspection row must fit at the actual text size")
            if area.viewport.insetBy(dx: -1, dy: -1).contains(bounds) { break }
            guard attempt < 8 else { XCTFail("A complete inspection row must be readable within eight pans"); return }
            let up = bounds.maxY > area.viewport.maxY
            let distance = min(area.viewport.height * 0.45,
                               max(24, up ? bounds.maxY - area.viewport.maxY + 8 : area.viewport.minY - bounds.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: area.viewport.minX - app.frame.minX + area.viewport.width * 0.12,
                dy: area.viewport.minY - app.frame.minY + area.viewport.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        guard let area = readingArea() else { return }
        XCTAssertTrue(area.viewport.insetBy(dx: -1, dy: -1).contains(target.frame))
        XCTAssertEqual(target.label, expected)
        XCTAssertTrue(app.frame.contains(app.buttons["experiment.done"].frame))
        XCTAssertTrue(app.buttons["experiment.done"].isEnabled && app.buttons["experiment.done"].isHittable)
        capture(name, in: app)
    }

    @MainActor private func inspect(prepared: Bool, capture name: String, in app: XCUIApplication) {
        tap("sky.showerInspection.open", in: app)
        let title = element("sky.menu.title", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "This announced shower"),
                                                object: title).wait(timeout: 5))
        XCTAssertTrue(app.frame.contains(title.frame))
        read("sky.showerInspection.warning", expected: "For this sky now. A move or shower closes this view.",
             capture: name + "-warning", in: app)
        read("sky.showerInspection.status", expected: "Your sky is already paused.",
             capture: name + "-paused", in: app)
        for id in 0..<5 {
            let row = [3, prepared ? 2 : 1, prepared ? 2 : 1, 4, 3][id]
            let effect = prepared && (id == 1 || id == 2)
                ? "Would grow the top star at row \(row), column \(columns[id]) to 2 light."
                : "Would add a star at row \(row), column \(columns[id])."
            read("sky.showerInspection.step.\(id)",
                 expected: "\(id + 1). \(descriptions[id]) → column \(columns[id]) \(effect)",
                 capture: name + "-arrival-\(id)", in: app)
        }
        read("sky.showerInspection.patterns", expected: "No automatic pattern clear in this snapshot.",
             capture: name + "-patterns", in: app)
        tap("experiment.done", in: app)
        XCTAssertFalse(element("sky.showerInspection.warning", in: app).exists)
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
        capture("shower-inspection-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor private func beginFrostfruit(largest: Bool, in app: XCUIApplication) throws -> [String] {
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review",
                               "--world-legacy-review", "--world-silver-complete-review", "--frostfruit-restoration-review=0"]
        if largest {
            // No argument-domain Calm override: actual Settings remains writable.
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        } else { app.launchArguments += ["-calmEffects", "NO"] }
        app.launch()
        let visit = app.worldVisitControl("frostfruitOrchard")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("15,000 starlight"))
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, showers: 0, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 30)
        return world
    }

    @MainActor func testNormalFrostfruitShowerInspectionMatchesGrowthAndKeepsClockRunning() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let (settings, reduce) = NativeSystemMotionSettings.open()
        let originalMotion = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce); settings.terminate()
        addTeardownBlock { @MainActor in
            let (settings, reduce) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(originalMotion, on: reduce); settings.terminate()
        }
        let app = XCUIApplication(); defer { app.terminate() }
        let world = try beginFrostfruit(largest: false, in: app)
        let opening = try round(in: app)
        inspect(prepared: false, capture: "shower-inspection-phone-opening", in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), opening)
        exchange(35, 36, in: app); settled(0, showers: 0, in: app)
        let prepared = try round(in: app)
        XCTAssertNotEqual(prepared.cells, opening.cells)
        inspect(prepared: true, capture: "shower-inspection-phone-prepared", in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), prepared)
        try assertWorld(world, in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), prepared)
        tap("experiment.next", in: app); settled(0, showers: 1, in: app)
        // Core maps the two predicted grown caps to IDs29/28; native semantics
        // expose their actual family, grown state and position, not hidden IDs.
        XCTAssertTrue(app.buttons["experiment.cell.5.0"].label.hasPrefix("Grown Amber irregular sun shard, Sunny"))
        XCTAssertTrue(app.buttons["experiment.cell.5.1"].label.hasPrefix("Grown Aqua swept comet shard, Spark"))
        XCTAssertTrue(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        XCTAssertTrue(app.buttons["experiment.cell.6.1"].label.hasPrefix("Empty,"))
        XCTAssertTrue(app.buttons["experiment.cell.4.5"].label.hasPrefix("Aqua swept comet shard, Spark"))
        XCTAssertTrue(app.buttons["experiment.cell.3.3"].label.hasPrefix("Mint angular meteor shard, Pip"))
        XCTAssertTrue(app.buttons["experiment.cell.4.4"].label.hasPrefix("Rose tall glint shard, Twinkle"))
        capture("shower-inspection-phone-real-grown-caps", in: app)
        let firstShower = try round(in: app)
        // Readiness is checked while paused. One subsequent opening attempt
        // must be admitted during real running play; no retry or Next follows.
        let open = app.buttons["sky.showerInspection.open"]
        app.revealSkyControls([open]); XCTAssertTrue(open.isEnabled && open.isHittable)
        tap("experiment.settings", in: app)
        let resume = app.buttons["experiment.pause"]
        app.revealSkyControls([resume])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Resume sky"),
            object: resume).wait(timeout: 5))
        resume.tap()
        tap("sky.showerInspection.open", in: app)
        let status = element("sky.showerInspection.status", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@", "The sky keeps running unless you pause it first."),
            object: status).wait(timeout: 3))
        capture("shower-inspection-phone-running-before-automatic-arrival", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !self.element("sky.showerInspection.warning", in: app).exists
                && (app.otherElements["experiment.board"].value as? String)?.hasPrefix("2 showers") == true
        }, object: nil).wait(timeout: 12), "The ordinary second shower must dismiss the stale inspection without Next")
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        app.revealSkyControls([pause])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap(); settled(0, showers: 2, in: app)
        XCTAssertNotEqual((try round(in: app)).cells, firstShower.cells)
        XCTAssertFalse(element("sky.showerInspection.warning", in: app).exists)
        capture("shower-inspection-phone-automatic-arrival-retired-copy", in: app)
        try assertWorld(world, in: app); settled(0, showers: 2, in: app)
    }

    @MainActor func testLargestCalmShowerInspectionReadsWithoutCommitAndFullBoardHasNone() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication(); defer { app.terminate() }
        let world = try beginFrostfruit(largest: true, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        let opening = try round(in: app)
        inspect(prepared: false, capture: "shower-inspection-tablet-opening", in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), opening)
        exchange(35, 36, in: app); settled(0, showers: 0, in: app)
        let prepared = try round(in: app)
        inspect(prepared: true, capture: "shower-inspection-tablet-prepared", in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), prepared)
        XCUIDevice.shared.press(.home); app.activate()
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), prepared)
        XCTAssertFalse(element("sky.showerInspection.warning", in: app).exists)
        try assertWorld(world, in: app)
        settled(0, showers: 0, in: app); XCTAssertEqual(try round(in: app), prepared)
        // Explicit menu admission is needed after the inspector's Done. The
        // picker helper must not be asked to tap a hidden background Map row.
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        func fullBoard(_ score: Int, exchanges: Int) {
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                let board = app.otherElements["experiment.board"].value as? String ?? ""
                return app.staticTexts["experiment.score"].label == "\(score.formatted()) of 150,000 starlight collected"
                    && board.hasPrefix("Exchanges: \(exchanges). Full Board.") && !board.contains("Stars settling")
                    && app.buttons["experiment.cell.0.0"].isEnabled
            }, object: nil).wait(timeout: 12))
            XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
            XCTAssertFalse(app.buttons["sky.showerInspection.open"].exists)
            XCTAssertFalse(app.buttons["experiment.next"].exists)
            XCTAssertFalse(element("sky.showerInspection.warning", in: app).exists)
        }
        fullBoard(0, exchanges: 0)
        capture("shower-inspection-tablet-full-board-absence", in: app)
        exchange(27, 34, in: app); fullBoard(42_000, exchanges: 1)
        capture("shower-inspection-tablet-following-real-full-board-clear", in: app)
        try assertWorld(world, in: app); fullBoard(42_000, exchanges: 1)
        _ = setCalm(originalCalm, in: app)
    }
}
