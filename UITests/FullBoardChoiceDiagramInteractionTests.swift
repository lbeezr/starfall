import XCTest

/// Optional diagrams describe copied visible ingredients; only subsequent
/// physical exchanges may change the real Full Board round.
final class FullBoardChoiceDiagramInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
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

    @MainActor private func tap(_ id: String, in app: XCUIApplication) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND enabled == true AND hittable == true"),
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
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND (label BEGINSWITH %@ OR label BEGINSWITH %@)",
            "experiment.cell.", "Empty, ", "Grown ")).count, 0)
        return RoundState(board: board.value as? String,
                          score: app.staticTexts["experiment.score"].label, cells: cells)
    }

    @MainActor private func settled(_ points: Int, target: Int, exchanges: Int, in app: XCUIApplication) {
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return board.hasPrefix("Exchanges: \(exchanges). Full Board.") && !board.contains("Stars settling")
                && app.staticTexts["experiment.score"].label == "\(points.formatted()) of \(target.formatted()) starlight collected"
                && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor private func revealPassive(_ item: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        for attempt in 0...8 {
            let owners = app.scrollViews.containing(item.elementType, identifier: item.identifier).allElementsBoundByIndex
            guard let owner = owners.filter({ $0.frame.width > 0 && $0.frame.height > 0 })
                .min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
                XCTFail("A plan frame must have an actual reading ScrollView"); return
            }
            var visible = app.frame.intersection(owner.frame)
            for ancestor in owners where ancestor.frame != owner.frame {
                if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == owner.frame }) {
                    visible = visible.intersection(ancestor.frame)
                }
            }
            let header = app.descendants(matching: .any).matching(NSPredicate(
                format: "identifier == %@ OR identifier == %@", "sky.menu.title", "sky.menu.back"))
                .allElementsBoundByIndex.filter(\.isHittable)
            let top = max(visible.minY, header.map { $0.frame.maxY }.max() ?? visible.minY)
            let done = app.buttons.matching(identifier: "experiment.done").allElementsBoundByIndex.first(where: \.isHittable)
            let bottom = min(visible.maxY, done?.frame.minY ?? visible.maxY)
            visible = CGRect(x: visible.minX, y: top, width: visible.width, height: max(0, bottom - top))
            let bounds = item.frame
            XCTAssertGreaterThan(bounds.width, 0); XCTAssertGreaterThan(bounds.height, 0)
            guard !visible.isNull, !visible.isEmpty,
                  bounds.width <= visible.width, bounds.height <= visible.height else {
                XCTFail("The complete passive plan frame must fit its actual reading viewport"); return
            }
            if visible.insetBy(dx: -1, dy: -1).contains(bounds) { return }
            guard attempt < 8 else { XCTFail("The complete passive plan frame must be reachable within eight gestures"); return }
            let up = bounds.maxY > visible.maxY
            let distance = min(visible.height * 0.45,
                               max(24, up ? bounds.maxY - visible.maxY + 8 : visible.minY - bounds.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * 0.12,
                dy: visible.minY - app.frame.minY + visible.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
    }

    @MainActor private func frame(_ index: Int, choice: Int, title: String, instruction: String? = nil,
                                 capture name: String, in app: XCUIApplication) {
        let caption = app.staticTexts["fullBoard.choices.frame.\(choice).\(index)"]
        revealPassive(caption, in: app)
        XCTAssertEqual(caption.label, title)
        let board = element("fullBoard.choices.diagram.\(choice).\(index)", in: app)
        revealPassive(board, in: app)
        XCTAssertEqual(board.label, title)
        if let instruction { XCTAssertEqual(board.value as? String, instruction) }
        else {
            let value = board.value as? String ?? ""
            XCTAssertTrue(value.hasPrefix("Outlined stars: row "))
            XCTAssertTrue(value.hasSuffix("."))
        }
        XCTAssertTrue(app.frame.contains(board.frame))
        // The passive figure deliberately ignores touches. Its full viewport,
        // exact native title/value and exported image establish reading instead.
        capture(name, in: app)
    }

    @MainActor private func panThroughFirstDiagram(capture name: String, in app: XCUIApplication) {
        let board = element("fullBoard.choices.diagram.0.0", in: app)
        // Reuse the strict complete-frame admission before placing a real
        // contact inside the passive Canvas instead of the reader's edge.
        revealPassive(board, in: app)
        let before = board.frame
        let owners = app.scrollViews.containing(board.elementType, identifier: board.identifier).allElementsBoundByIndex
        guard let owner = owners.min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
            XCTFail("The passive board must belong to the reading scroll view"); return
        }
        let visible = before.intersection(app.frame.intersection(owner.frame))
        XCTAssertTrue(visible.contains(before), "The whole board must be visible before the pan")
        let startPoint = CGPoint(x: visible.midX, y: visible.midY)
        let endPoint = CGPoint(x: startPoint.x, y: startPoint.y - 72)
        XCTAssertTrue(visible.contains(startPoint) && visible.contains(endPoint),
                      "The entire physical pan must stay inside the visible passive diagram")
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
            dx: startPoint.x - app.frame.minX, dy: startPoint.y - app.frame.minY))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(.init(dx: 0, dy: -72)),
                    withVelocity: .slow, thenHoldForDuration: 0.1)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.frame.minY < before.minY - 1
        }, object: nil).wait(timeout: 5), "Dragging through the passive diagram must move its reading page upward")
        XCTAssertEqual(board.frame.size, before.size)
        capture(name, in: app)
    }

    @MainActor private func openChoices(in app: XCUIApplication) {
        tap("experiment.settings", in: app); tap("fullBoard.choices.open", in: app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.0"].waitForExistence(timeout: 10))
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
        capture("choice-diagram-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor func testNormalLanternDirectDiagramsPreserveRoundAndContinue() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        normalSystemMotion()
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        exchange(8, 9, in: app); settled(15_000, target: 150_000, exchanges: 1, in: app)
        let retained = try round(in: app)
        openChoices(in: app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.pattern.0"].label, "Line · 4 stars in the first clear")
        XCTAssertEqual(app.staticTexts["fullBoard.choices.pattern.1"].label, "Square · 4 stars in the first clear")
        XCTAssertFalse(element("fullBoard.choices.diagram.0.0", in: app).exists)
        tap("fullBoard.choices.reveal.0", in: app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.0.0"].label, "1. Swipe right from row 7, column 1.")
        frame(0, choice: 0, title: "Before swipe 1", instruction: "Swipe right from row 7, column 1.",
              capture: "choice-diagram-phone-line-before", in: app)
        panThroughFirstDiagram(capture: "choice-diagram-phone-pan-through-passive-board", in: app)
        frame(1, choice: 0, title: "First pattern after swipe 1",
              capture: "choice-diagram-phone-line-first-pattern", in: app)
        tap("fullBoard.choices.reveal.0", in: app)
        XCTAssertFalse(element("fullBoard.choices.diagram.0.0", in: app).exists)
        XCTAssertFalse(app.staticTexts["fullBoard.choices.step.0.0"].exists)
        tap("fullBoard.choices.reveal.1", in: app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.1.0"].label, "1. Swipe up from row 7, column 6.")
        frame(0, choice: 1, title: "Before swipe 1", instruction: "Swipe up from row 7, column 6.",
              capture: "choice-diagram-phone-square-before", in: app)
        frame(1, choice: 1, title: "First pattern after swipe 1",
              capture: "choice-diagram-phone-square-first-pattern", in: app)
        tap("sky.menu.back", in: app); tap("fullBoard.choices.open", in: app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.1"].waitForExistence(timeout: 10))
        XCTAssertFalse(element("fullBoard.choices.diagram.0.0", in: app).exists)
        XCTAssertFalse(element("fullBoard.choices.diagram.1.0", in: app).exists)
        tap("experiment.done", in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        XCUIDevice.shared.press(.home); app.activate()
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.home", in: app); tap("sky.resume", in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        try assertWorld(initialWorld, in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        exchange(0, 1, in: app); settled(30_000, target: 150_000, exchanges: 2, in: app)
        XCTAssertNotEqual(try round(in: app), retained)
        capture("choice-diagram-phone-real-selected-clear", in: app)
        try assertWorld(initialWorld, in: app)
    }

    @MainActor func testLargestCalmRibbonSetupDiagramsDoNotPlayForYou() throws {
        continueAfterFailure = false
        executionTimeAllowance = 360
        let app = XCUIApplication()
        // Existing-install access admits Ribbon. Every board/point below still
        // comes from production Begin and real swipes; actual Calm is mutable.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        let visit = app.worldVisitControl("ribbonCrossing")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.ribbonMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 220_000, exchanges: 0, in: app)
        XCTAssertTrue(app.staticTexts["ribbon.mode"].label.contains("Full Board"))
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        // Frozen current Ribbon7 route, already asserted by FullBoardRibbonTests.
        let prefix: [(from: Int, to: Int, score: Int)] = [
            (8, 9, 30_000), (11, 12, 35_000), (31, 38, 40_000), (17, 24, 45_000),
            (9, 16, 50_000), (9, 10, 65_000), (1, 8, 80_000)
        ]
        for (index, move) in prefix.enumerated() {
            exchange(move.from, move.to, in: app)
            settled(move.score, target: 220_000, exchanges: index + 1, in: app)
        }
        let retained = try round(in: app)
        openChoices(in: app)
        XCTAssertFalse(app.staticTexts["fullBoard.choices.pattern.1"].exists)
        let pattern = app.staticTexts["fullBoard.choices.pattern.0"].label
        XCTAssertFalse(pattern.isEmpty)
        XCTAssertTrue(pattern.hasSuffix("stars in the first clear"))
        tap("fullBoard.choices.reveal.0", in: app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.0.0"].label, "1. Swipe right from row 7, column 2.")
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.0.1"].label, "2. Swipe up from row 7, column 2.")
        frame(0, choice: 0, title: "Before swipe 1", instruction: "Swipe right from row 7, column 2.",
              capture: "choice-diagram-tablet-setup-before-first", in: app)
        panThroughFirstDiagram(capture: "choice-diagram-tablet-pan-through-passive-board", in: app)
        frame(1, choice: 0, title: "Before swipe 2", instruction: "Swipe up from row 7, column 2.",
              capture: "choice-diagram-tablet-setup-before-second", in: app)
        frame(2, choice: 0, title: "First pattern after swipe 2",
              capture: "choice-diagram-tablet-setup-first-pattern", in: app)
        tap("fullBoard.choices.reveal.0", in: app)
        XCTAssertFalse(element("fullBoard.choices.diagram.0.0", in: app).exists)
        XCTAssertFalse(app.staticTexts["fullBoard.choices.step.0.1"].exists)
        tap("fullBoard.choices.reveal.0", in: app)
        XCTAssertTrue(element("fullBoard.choices.diagram.0.2", in: app).exists)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(element("fullBoard.choices.diagram.0.2", in: app).waitForExistence(timeout: 5))
        tap("sky.menu.back", in: app); tap("fullBoard.choices.open", in: app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.0"].waitForExistence(timeout: 10))
        XCTAssertFalse(element("fullBoard.choices.diagram.0.0", in: app).exists)
        tap("experiment.done", in: app)
        settled(80_000, target: 220_000, exchanges: 7, in: app)
        XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.home", in: app); tap("sky.resume", in: app)
        settled(80_000, target: 220_000, exchanges: 7, in: app)
        XCTAssertEqual(try round(in: app), retained)
        try assertWorld(initialWorld, in: app)
        settled(80_000, target: 220_000, exchanges: 7, in: app)
        XCTAssertEqual(try round(in: app), retained)
        exchange(1, 2, in: app); settled(80_000, target: 220_000, exchanges: 8, in: app)
        XCTAssertNotEqual((try round(in: app)).cells, retained.cells)
        capture("choice-diagram-tablet-real-setup-no-points", in: app)
        exchange(1, 8, in: app); settled(85_000, target: 220_000, exchanges: 9, in: app)
        capture("choice-diagram-tablet-real-following-clear", in: app)
        try assertWorld(initialWorld, in: app)
        settled(85_000, target: 220_000, exchanges: 9, in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
