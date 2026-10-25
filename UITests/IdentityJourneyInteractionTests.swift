import XCTest

/// Whole native journeys use the existing authored input fixture or real
/// production encounters. Captures establish reading separately from motion.
final class IdentityJourneyInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let openEntry = "Tap a matching group, or hold and draw through 5 or more matching stars. Only the stars you draw clear. Make room for each shower."
    private let openReplay = "Replay the same starting sky and shower rules with your current sky settings. Your saved round stays until you tap Begin."
    private let openTraceHelp = "Hold a star until it glows, then draw through 5 or more matching stars and lift your finger. Only the stars you trace will clear. Each star can touch the previous star or cross one empty space in a straight line, including diagonally. Another star blocks the gap. When your drawing earns light, its shape returns with it."
    private let silverHelp = "Restore Silver Pools with 12,000 starlight. In this opening, clearing the vertical rose support line earns 5,000 points. An aqua survivor falls four rows and completes a five-star line in the same action; that second phase earns 14,000 with the chain bonus, for 19,000 total. Taking the low aqua line first earns 7,000 and spends those follow-up ingredients; a later separate rose clear earns 5,000 and can finish the repair. Those separate actions are not a chain. Arrange squares of 4, crosses of 5, or straight lines of 4 or more. Patterns pop automatically after swaps and showers. Other legal clears can finish too."
    private let fullBoardHelp = "Restore Lantern Landing with 150,000 starlight in Full Board. Build patterns with swaps, then watch the empty spaces refill and the next patterns pop. Chains earn the same increasing bonus as Falling Sky. Take as many setup moves as you need; there is no move limit. Both Lantern boards can earn the repair."
    private let fullBoardRefill = "Full Board starts with 49 stars. Swipe neighboring stars in any direction to arrange matching squares of 4, crosses of 5, or straight lines of 4 or more. Setup swaps are allowed. After each pop, survivors fall and new stars fill the spaces; a new pattern continues the chain. Every star counts once. There is no star growth, timed shower, or ceiling loss."

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

    @MainActor private func home(capture name: String, in app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["sky.title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Welcome to the Observatory")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Story Mode")
        XCTAssertEqual(app.buttons["sky.start"].label, "Free Play")
        XCTAssertEqual(app.buttons["sky.learn"].label, "Tutorial")
        // The visual promise is the named button's accessibility hint, rather
        // than a separately selectable static text. Inspect its actual capture.
        app.revealSkyControls([app.buttons["sky.worldMap"], app.buttons["sky.start"]])
        capture(name, in: app)
    }

    @MainActor private func paused(_ points: Int, target: Int? = nil, showers: Int,
                                   in app: XCUIApplication) {
        let expected = target.map { "\(points.formatted()) of \($0.formatted()) starlight collected" }
            ?? "\(points.formatted()) starlight"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == expected
                && board.hasPrefix("\(showers) showers") && !board.contains("Stars settling")
                && app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled
        }, object: nil).wait(timeout: 10))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor @discardableResult private func pauseRunningSky(showers: Int?, in app: XCUIApplication) -> Int {
        // This is ordinary admitted control use, not a rapid Begin timing probe.
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        app.revealSkyControls([pause])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        let board = app.otherElements["experiment.board"].value as? String ?? ""
        guard let actual = Int(board.components(separatedBy: " showers").first ?? "") else {
            XCTFail("A paused Falling Sky must expose its actual shower count: \(board)"); return -1
        }
        if let showers { XCTAssertEqual(actual, showers, board) }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@", actual == 0 ? "Start sky" : "Resume sky"),
            object: app.buttons["experiment.pause"]).wait(timeout: 5))
        let next = app.buttons["experiment.next"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("\(actual) showers") == true)
        return actual
    }

    @MainActor private func fullBoard(_ points: Int, exchanges: Int, in app: XCUIApplication) {
        let blocked = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return board.hasPrefix("Exchanges: \(exchanges). Full Board.") && !board.contains("Stars settling")
                && app.staticTexts["experiment.score"].label == "\(points.formatted()) of 150,000 starlight collected"
                && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, capture name: String,
                                     in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
        capture(name, in: app)
    }

    @MainActor private func world(in app: XCUIApplication, fromMenu: Bool) throws -> [String] {
        if fromMenu { tap("experiment.settings", in: app) }
        tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        let state = try identities(app, prefix: "world.place.")
        XCTAssertEqual(state.count, 12)
        tap("world.done", in: app)
        return state
    }

    @MainActor private func readHelp(_ text: String, capture name: String, menu: Bool = true,
                                    in app: XCUIApplication) {
        let match = NSPredicate(format: "label == %@", text)
        let paragraph = app.staticTexts.matching(match).firstMatch
        XCTAssertTrue(paragraph.waitForExistence(timeout: 5))
        XCTAssertEqual(paragraph.label, text)
        func readingArea() -> (scroll: XCUIElement, viewport: CGRect)? {
            let owners = app.scrollViews.containing(match).allElementsBoundByIndex
            guard let scroll = owners.filter({ $0.frame.width > 0 && $0.frame.height > 0 })
                .min(by: { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }) else {
                XCTFail("The exact paragraph must have a rendered reading ScrollView"); return nil
            }
            var viewport = app.frame.intersection(scroll.frame)
            for ancestor in owners where ancestor.frame != scroll.frame {
                if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == scroll.frame }) {
                    viewport = viewport.intersection(ancestor.frame)
                }
            }
            if menu {
                let header = app.descendants(matching: .any).matching(NSPredicate(
                    format: "identifier == %@ OR identifier == %@", "sky.menu.title", "sky.menu.back"))
                    .allElementsBoundByIndex.filter(\.isHittable)
                let top = max(viewport.minY, header.map { $0.frame.maxY }.max() ?? viewport.minY)
                let done = app.buttons.matching(identifier: "experiment.done").allElementsBoundByIndex.first(where: \.isHittable)
                let bottom = min(viewport.maxY, done?.frame.minY ?? viewport.maxY)
                viewport = CGRect(x: viewport.minX, y: top, width: viewport.width, height: max(0, bottom - top))
            }
            guard !viewport.isNull, !viewport.isEmpty else {
                XCTFail("The reading viewport must exclude the fixed header and Done action"); return nil
            }
            return (scroll, viewport)
        }
        func move(_ target: CGRect, through area: (scroll: XCUIElement, viewport: CGRect), fraction: CGFloat = 0.45) {
            let visible = area.viewport
            let up = target.maxY > visible.maxY
            let distance = min(visible.height * fraction,
                               max(24, up ? target.maxY - visible.maxY + 8 : visible.minY - target.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * 0.12,
                dy: visible.minY - app.frame.minY + visible.height * (up ? max(0.75, fraction + 0.05) : min(0.25, 0.95 - fraction))))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        // A short paragraph must fit completely. A long paragraph starts with
        // its true first line and at least half a reading viewport of body text.
        for attempt in 0...8 {
            guard let area = readingArea() else { return }
            let bounds = paragraph.frame
            let firstPart = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width,
                                   height: bounds.height <= area.viewport.height ? bounds.height : area.viewport.height * 0.5)
            if area.viewport.insetBy(dx: -1, dy: -1).contains(firstPart) { break }
            guard attempt < 8 else { XCTFail("The paragraph's actual beginning must become readable within eight gestures"); return }
            // Navigate through unrelated sections before reading this one.
            // Reading below still uses overlapping 45% advances.
            move(firstPart, through: area, fraction: 0.8)
        }
        guard let firstArea = readingArea() else { return }
        XCTAssertGreaterThan(paragraph.frame.width, 0); XCTAssertGreaterThan(paragraph.frame.height, 0)
        XCTAssertGreaterThanOrEqual(paragraph.frame.minY, firstArea.viewport.minY - 1)
        var readThrough = min(paragraph.frame.height, firstArea.viewport.maxY - paragraph.frame.minY)
        capture(name + "-start", in: app)
        // Each following captured position overlaps the preceding visible
        // content range. A clipped first line at the final position is not a
        // claim that the whole long paragraph fits in one screenshot.
        for attempt in 0...8 {
            guard let area = readingArea() else { return }
            if paragraph.frame.maxY <= area.viewport.maxY + 1 { break }
            guard attempt < 8 else { XCTFail("The paragraph's actual end must become readable within eight gestures"); return }
            move(paragraph.frame, through: area)
            guard let nextArea = readingArea() else { return }
            let contentStart = max(0, nextArea.viewport.minY - paragraph.frame.minY)
            XCTAssertLessThanOrEqual(contentStart, readThrough + 1, "Consecutive reading captures must not skip body text")
            readThrough = max(readThrough, min(paragraph.frame.height, nextArea.viewport.maxY - paragraph.frame.minY))
            capture(name + "-reading-\(attempt + 1)", in: app)
        }
        guard let lastArea = readingArea() else { return }
        XCTAssertLessThanOrEqual(paragraph.frame.maxY, lastArea.viewport.maxY + 1)
        XCTAssertGreaterThan(paragraph.frame.maxY, lastArea.viewport.minY)
        XCTAssertGreaterThanOrEqual(readThrough, paragraph.frame.height - 1)
        XCTAssertEqual(paragraph.label, text)
        capture(name + "-end", in: app)
    }

    @MainActor private func entryHelp(_ text: String, capture name: String,
                                    openSky: Bool = false, additional: [(text: String, name: String)] = [],
                                    in app: XCUIApplication) {
        tap("sky.preferences", in: app); tap("experiment.help", in: app)
        if openSky {
            XCTAssertFalse(app.staticTexts["First Light · Lantern Landing"].exists)
            XCTAssertEqual(app.staticTexts.matching(NSPredicate(format:
                "label CONTAINS %@ OR label CONTAINS %@", "Restore Lantern Landing", "150,000")).count, 0)
        }
        readHelp(text, capture: name, in: app)
        for paragraph in additional { readHelp(paragraph.text, capture: paragraph.name, in: app) }
        if openSky {
            XCTAssertFalse(app.staticTexts["First Light · Lantern Landing"].exists)
            XCTAssertEqual(app.staticTexts.matching(NSPredicate(format:
                "label CONTAINS %@ OR label CONTAINS %@", "Restore Lantern Landing", "150,000")).count, 0)
        }
        tap("experiment.done", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        let subtitle = app.staticTexts["sky.subtitle"]
        readHelp(subtitle.label, capture: name + "-entry", menu: false, in: app)
        app.revealSkyControls([app.buttons["sky.begin"]])
        XCTAssertTrue(app.buttons["sky.begin"].isEnabled && app.buttons["sky.begin"].isHittable)
    }

    @MainActor private func setCalm(_ enabled: Bool, fromHome: Bool = false,
                                   verifyOffToOn: Bool = false, in app: XCUIApplication) -> Bool {
        if fromHome { tap("sky.preferences", in: app) }
        else { tap("experiment.settings", in: app); tap("experiment.preferences", in: app) }
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
        capture("identity10-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor private func assertFinalLight(capture name: String, in app: XCUIApplication) {
        let figure = app.descendants(matching: .any).matching(identifier: "sky.finalLight").firstMatch
        XCTAssertTrue(figure.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !figure.frame.isEmpty
        }, object: nil).wait(timeout: 5))
        // Preserve goal9's exact passive/nested-viewport contract. Unlike an
        // action, this decoration intentionally never accepts physical input.
        func viewport(of scroll: XCUIElement?, among owners: [XCUIElement]) -> CGRect {
            var visible = app.frame.intersection(scroll?.frame ?? app.frame)
            if let scroll {
                for ancestor in owners where ancestor.frame != scroll.frame {
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == scroll.frame }) {
                        visible = visible.intersection(ancestor.frame)
                    }
                }
            }
            guard !visible.isNull, !visible.isEmpty else { return visible }
            if let bar = app.navigationBars.allElementsBoundByIndex.last(where: {
                $0.buttons.allElementsBoundByIndex.contains(where: \.isHittable)
                    || $0.staticTexts.allElementsBoundByIndex.contains(where: \.isHittable)
            }) {
                let top = max(visible.minY, bar.frame.maxY - 1)
                visible = CGRect(x: visible.minX, y: top, width: visible.width, height: max(0, visible.maxY - top))
            }
            return visible
        }
        func move(_ bounds: CGRect, through visible: CGRect, owner: XCUIElement?) {
            let up = bounds.maxY > visible.maxY
            let distance = min(visible.height * 0.45,
                               max(24, up ? bounds.maxY - visible.maxY + 8 : visible.minY - bounds.minY + 8))
            let containsBoard = owner?.buttons.matching(NSPredicate(
                format: "identifier BEGINSWITH %@", "experiment.cell.")).firstMatch.exists ?? true
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * (containsBoard ? 0.002 : 0.12),
                dy: visible.minY - app.frame.minY + visible.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        for attempt in 0...8 {
            let owners = app.scrollViews.containing(figure.elementType, identifier: figure.identifier).allElementsBoundByIndex
            let scroll = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            let visible = viewport(of: scroll, among: owners)
            let bounds = figure.frame
            if owners.count > 1, let scroll,
               visible.isNull || visible.isEmpty || visible.height < min(bounds.height, scroll.frame.height) {
                let ancestor = owners.filter {
                    let clipped = viewport(of: $0, among: owners)
                    return $0.frame != scroll.frame && !clipped.isNull && !clipped.isEmpty
                }.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                guard attempt < 8, let ancestor else {
                    XCTFail("The passive signature's ancestor must become visible within eight gestures"); return
                }
                move(scroll.frame, through: viewport(of: ancestor, among: owners), owner: ancestor)
                continue
            }
            if visible.insetBy(dx: -1, dy: -1).contains(bounds) {
                XCTAssertEqual(figure.label, "Last earned light")
                XCTAssertGreaterThan(bounds.width, 0); XCTAssertGreaterThan(bounds.height, 0)
                XCTAssertTrue(app.frame.insetBy(dx: -1, dy: -1).contains(bounds))
                capture(name, in: app)
                return
            }
            guard attempt < 8, bounds.height <= visible.height else {
                XCTFail("The complete passive signature must fit its actual scroll viewport"); return
            }
            move(bounds, through: visible, owner: scroll)
        }
    }

    @MainActor func testNormalHomeOpenSkyTraceEndingAndReplay() throws {
        continueAfterFailure = false
        executionTimeAllowance = 420
        normalSystemMotion()
        let app = XCUIApplication()
        // Existing authored historical-Dusk input, displayed through real Home.
        // This is not a witness for modern random shower generation.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review",
                               "--constellation-fixture=horizontalFive", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        home(capture: "identity10-phone-home-open-sky-promise", in: app)
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        let initialWorld = try world(in: app, fromMenu: false)
        tap("sky.start", in: app)
        XCTAssertEqual(app.staticTexts["sky.subtitle"].label, "Sunny. " + openEntry)
        entryHelp(openTraceHelp, capture: "identity10-phone-open-sky-help", openSky: true, in: app)
        XCTAssertEqual(app.staticTexts["sky.subtitle"].label, "Sunny. " + openEntry)
        tap("sky.begin", in: app)
        // This historical fixture encodes one prior shower. Ordinary Begin
        // starts its clock, so record any real arrival before admitted Pause.
        let firstPausedShowers = pauseRunningSky(showers: nil, in: app)
        XCTAssertGreaterThanOrEqual(firstPausedShowers, 1)
        paused(0, showers: firstPausedShowers, in: app)
        let source = app.buttons["experiment.cell.0.0"], destination = app.buttons["experiment.cell.0.4"]
        app.revealSkyControls([source, destination])
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.4,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .slow, thenHoldForDuration: 0.45)
        capture("identity10-phone-open-sky-exact-trace-return", in: app)
        paused(5, showers: firstPausedShowers, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Twinkle")).count, 0)
        let outcome = app.staticTexts["experiment.outcome"]
        var showers = firstPausedShowers
        for _ in 0..<40 {
            if outcome.exists { break }
            paused(5, showers: showers, in: app)
            tap("experiment.next", in: app); showers += 1
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || app.buttons["experiment.next"].isEnabled
            }, object: nil).wait(timeout: 8))
        }
        XCTAssertGreaterThan(showers, firstPausedShowers)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains(" 5 starlight collected."))
        let ending = app.staticTexts["experiment.score"].label
        assertFinalLight(capture: "identity10-phone-open-sky-earned-ending", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: false), initialWorld)
        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.subtitle"].label, "Sunny. " + openReplay)
        readHelp("Sunny. " + openReplay, capture: "identity10-phone-open-sky-replay-entry", menu: false, in: app)
        tap("sky.home", in: app)
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, ending)
        assertFinalLight(capture: "identity10-phone-open-sky-replay-back", in: app)
        tap("experiment.replay", in: app); tap("sky.begin", in: app)
        let replayPausedShowers = pauseRunningSky(showers: nil, in: app)
        XCTAssertGreaterThanOrEqual(replayPausedShowers, 0)
        paused(0, showers: replayPausedShowers, in: app)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sky.finalLight").firstMatch.exists)
        // Core Replay reconstructs the saved seed/rules, not an injected fixture
        // row. Do not assert equality with horizontalFive's authored input.
        XCTAssertEqual(try world(in: app, fromMenu: true), initialWorld)
        capture("identity10-phone-open-sky-replay-zero", in: app)
    }

    @MainActor func testNormalStoryRepairHomeAndRetainedEnding() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        // Existing-install access admits Silver; the test does not claim that
        // the preceding campaign was earned in this isolated journey.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch(); defer { app.terminate() }
        home(capture: "identity10-phone-home-story-promise", in: app)
        let visit = app.worldVisitControl("silverPools")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertTrue(initialWorld.contains("world.place.silverPools:Silver Pools:Ready to restore"))
        XCTAssertTrue(initialWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Restore Silver Pools first"))
        visit.tap()
        entryHelp(silverHelp, capture: "identity10-phone-current-silver-help", in: app)
        tap("sky.begin", in: app); pauseRunningSky(showers: 0, in: app)
        paused(0, target: 12_000, showers: 0, in: app)
        exchange(9, 10, capture: "identity10-phone-story-automatic-pattern-return", in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        let ending = app.staticTexts["experiment.score"].label
        XCTAssertTrue(ending.contains("19,000 of 12,000 starlight collected"))
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        assertFinalLight(capture: "identity10-phone-story-earned-final-light", in: app)
        let repairedWorld = try world(in: app, fromMenu: false)
        XCTAssertTrue(repairedWorld.contains("world.place.silverPools:Silver Pools:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Ready to restore"))
        func unrelated(_ state: [String]) -> [String] {
            state.filter { !$0.hasPrefix("world.place.silverPools:") && !$0.hasPrefix("world.place.frostfruitOrchard:") }
        }
        XCTAssertEqual(unrelated(initialWorld), unrelated(repairedWorld))
        tap("sky.home", in: app)
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["sky.resume"].label, "View last sky")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Silver Pools"))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("19,000"))
        app.revealSkyControls([app.staticTexts["sky.subtitle"]])
        XCTAssertTrue(app.frame.contains(app.staticTexts["sky.subtitle"].frame))
        capture("identity10-phone-home-retained-silver-ending", in: app)
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, ending)
        assertFinalLight(capture: "identity10-phone-story-return-same-earned-light", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: false), repairedWorld)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, ending)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sky.finalLight").firstMatch.exists)
        XCTAssertEqual(try world(in: app, fromMenu: false), repairedWorld)
        capture("identity10-phone-story-cold-retained-ending", in: app)
    }

    @MainActor func testLargestCalmModeGuidanceCancellationAndExactContinue() throws {
        continueAfterFailure = false
        executionTimeAllowance = 360
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "-UIPreferredContentSizeCategoryName",
                                 "UICTContentSizeCategoryAccessibilityXXXL"]
        // No Calm argument-domain override: actual Settings must remain mutable.
        app.launchArguments = retainedArguments + ["--starfalls-reset"]
        app.launch(); defer { app.terminate() }
        home(capture: "identity10-tablet-largest-home-promises", in: app)
        let originalCalm = setCalm(true, fromHome: true, verifyOffToOn: true, in: app)
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app)
        entryHelp(fullBoardRefill, capture: "identity10-tablet-full-board-refill-help",
                  additional: [(fullBoardHelp, "identity10-tablet-full-board-exact-objective")], in: app)
        tap("sky.begin", in: app); fullBoard(0, exchanges: 0, in: app)
        exchange(27, 34, capture: "identity10-tablet-full-board-cascade-return", in: app)
        fullBoard(42_000, exchanges: 1, in: app)
        let retained = try round(in: app)
        for action in ["experiment.replay", "experiment.new"] {
            tap("experiment.settings", in: app); tap(action, in: app)
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            if action == "experiment.replay" { XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board")) }
            else { XCTAssertEqual(app.staticTexts["sky.subtitle"].label, "Sunny. " + openEntry) }
            capture("identity10-tablet-" + action + "-preview", in: app)
            tap("sky.home", in: app)
            fullBoard(42_000, exchanges: 1, in: app)
            XCTAssertEqual(try round(in: app), retained)
            XCTAssertFalse(app.buttons["sky.resume"].exists)
        }
        tap("experiment.settings", in: app)
        let revisit = app.worldVisitControl("firstLight")
        let saved = "Saved Full Board progress: 42,000 of 150,000 starlight."
        XCTAssertEqual(app.staticTexts["world.savedProgress"].label, saved)
        XCTAssertEqual(try identities(app, prefix: "world.place."), initialWorld)
        revisit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.lanternMode.fallingSky", in: app)
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.home", in: app)
        XCTAssertTrue(app.otherElements["world.page"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertEqual(app.staticTexts["world.savedProgress"].label, saved)
        XCTAssertEqual(try identities(app, prefix: "world.place."), initialWorld)
        app.revealSkyControls([app.staticTexts["world.savedProgress"]])
        capture("identity10-tablet-map-back-retains-full-board-mode", in: app)
        tap("world.resume", in: app)
        fullBoard(42_000, exchanges: 1, in: app); XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.home", in: app)
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["sky.resume"].label, "Continue sky")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("42,000"))
        app.revealSkyControls([app.staticTexts["sky.subtitle"]])
        capture("identity10-tablet-home-exact-saved-mode", in: app)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        fullBoard(42_000, exchanges: 1, in: app); XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", in: app); tap("sky.lanternMode.fallingSky", in: app)
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.begin", in: app); pauseRunningSky(showers: 0, in: app)
        paused(0, target: 150_000, showers: 0, in: app)
        XCTAssertNotEqual(try round(in: app), retained, "Only Begin commits the chosen replacement")
        XCTAssertEqual(app.otherElements["sky.header"].value as? String, "Falling Sky")
        exchange(8, 9, capture: "identity10-tablet-explicit-sky-pattern-return", in: app)
        paused(15_000, target: 150_000, showers: 0, in: app)
        let switched = try round(in: app)
        XCTAssertEqual(try world(in: app, fromMenu: true), initialWorld)
        paused(15_000, target: 150_000, showers: 0, in: app)
        XCTAssertEqual(try round(in: app), switched)
        _ = setCalm(originalCalm, in: app)
    }
}
