import XCTest

/// Optional recaps read committed transactions without replaying their rewards.
/// Historical manual input below is an isolated fixture, not campaign delivery.
final class LastClearRecapInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let fourSmall = "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points."
    private let fiveSmall = "5 stars · 5 light. 5,000 base + 2,000 size = 7,000 points."
    private let fiveChain = "5 stars · 5 light. 5,000 base + 2,000 size + 7,000 chain = 14,000 points."

    @MainActor private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor private func tap(_ id: String, in app: XCUIApplication, expectedLabel: String? = nil) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND enabled == true AND hittable == true"),
            object: control).wait(timeout: 5), id)
        XCTAssertTrue(app.frame.contains(control.frame), id)
        if let expectedLabel { XCTAssertEqual(control.label, expectedLabel) }
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
        // These are semantic cells, including empty slots, not occupied stars.
        XCTAssertEqual(cells.count, 49)
        return RoundState(board: board.value as? String,
                          score: app.staticTexts["experiment.score"].label, cells: cells)
    }

    @MainActor private func normalSystemMotion() {
        let (settings, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce); settings.terminate()
        addTeardownBlock { @MainActor in
            let (settings, reduce) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: reduce); settings.terminate()
        }
    }

    @MainActor private func settled(_ points: Int, target: Int? = nil, exchanges: Int? = nil,
                                    showers: Int? = 0, in app: XCUIApplication) {
        let expected = target.map { "\(points.formatted()) of \($0.formatted()) starlight collected" }
            ?? "\(points.formatted()) starlight"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            let cadence = exchanges.map { board.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? showers.map { board.hasPrefix("\($0) showers") } ?? true
            return app.staticTexts["experiment.score"].label == expected && cadence
                && !board.contains("Stars settling") && app.buttons["experiment.cell.0.0"].isEnabled
                && (exchanges != nil || app.buttons["experiment.next"].isEnabled)
        }, object: nil).wait(timeout: 12), expected)
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        if exchanges != nil { XCTAssertFalse(app.buttons["experiment.next"].exists) }
    }

    @MainActor @discardableResult private func pauseNewSky(expectedShowers: Int? = 0,
                                                         in app: XCUIApplication) -> Int {
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        app.revealSkyControls([pause])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        let board = app.otherElements["experiment.board"].value as? String ?? ""
        guard let actual = Int(board.components(separatedBy: " showers").first ?? "") else {
            XCTFail("Paused Falling Sky must expose its actual shower count: \(board)"); return -1
        }
        if let expectedShowers { XCTAssertEqual(actual, expectedShowers, board) }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@", actual == 0 ? "Start sky" : "Resume sky"), object: pause).wait(timeout: 5))
        let next = app.buttons["experiment.next"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("\(actual) showers") == true)
        return actual
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

    @MainActor private func world(fromMenu: Bool, in app: XCUIApplication) throws -> [String] {
        if fromMenu { tap("experiment.settings", in: app) }
        tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" { tap("world.list", in: app) }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        let state = try identities(app, prefix: "world.place.")
        XCTAssertEqual(state.count, 12)
        tap("world.done", in: app)
        return state
    }

    @MainActor private func setCalm(_ enabled: Bool, verifyOffToOn: Bool = false,
                                   in app: XCUIApplication) -> Bool {
        tap("experiment.settings", in: app); tap("experiment.preferences", in: app)
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        app.revealSkyMenuElement(calm); app.revealSkyControls([calm])
        let original = calm.value as? String == "1"
        let preference = XCTAttachment(string: "actual-original-Calm=\(original)")
        preference.name = "last-clear-calm-before-mutation"; preference.lifetime = .keepAlways; add(preference)
        func select(_ value: String) {
            if calm.value as? String != value { calm.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value),
                                                    object: calm).wait(timeout: 5))
            XCTAssertEqual(calm.value as? String, value)
        }
        if enabled && verifyOffToOn { select("0") }
        select(enabled ? "1" : "0")
        capture("last-clear-tablet-actual-calm-" + (enabled ? "on" : "restored-off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    /// Use the smallest actual reader, its ancestor clips and the pinned menu
    /// title/Return bounds. Passive art needs complete geometry, not hit testing.
    @MainActor private func read(_ item: XCUIElement, expected: String? = nil,
                                capture name: String, in app: XCUIApplication) {
        XCTAssertTrue(item.waitForExistence(timeout: 5), item.identifier)
        if let expected { XCTAssertEqual(item.label, expected) }
        func viewport(of scroll: XCUIElement?, among owners: [XCUIElement]) -> CGRect {
            var viewport = app.frame.intersection(scroll?.frame ?? app.frame)
            if let scroll {
                for ancestor in owners where ancestor.frame != scroll.frame {
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == scroll.frame }) {
                        viewport = viewport.intersection(ancestor.frame)
                    }
                }
            }
            let title = app.staticTexts["sky.menu.title"]
            if title.exists, !title.frame.isEmpty, title.frame.intersects(app.frame) {
                let top = max(viewport.minY, title.frame.maxY)
                let done = app.buttons["experiment.done"]
                let bottom = min(viewport.maxY, done.exists && done.isHittable ? done.frame.minY : viewport.maxY)
                viewport = CGRect(x: viewport.minX, y: top, width: viewport.width, height: max(0, bottom - top))
            }
            return viewport
        }
        func area() -> (owner: XCUIElement?, viewport: CGRect, owners: [XCUIElement]) {
            let owners = app.scrollViews.containing(item.elementType, identifier: item.identifier).allElementsBoundByIndex
            let owner = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            return (owner, viewport(of: owner, among: owners), owners)
        }
        func move(_ bounds: CGRect, through viewport: CGRect, fraction: CGFloat) {
            let up = bounds.maxY > viewport.maxY
            let distance = min(viewport.height * fraction,
                max(24, up ? bounds.maxY - viewport.maxY + 8 : viewport.minY - bounds.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: viewport.minX - app.frame.minX + viewport.width * 0.12,
                dy: viewport.minY - app.frame.minY + viewport.height * (up ? max(0.75, fraction + 0.05) : 0.2)))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        for attempt in 0...8 {
            let current = area(), visible = current.viewport
            if let owner = current.owner, current.owners.count > 1,
               visible.isNull || visible.isEmpty || visible.height < min(item.frame.height, owner.frame.height) {
                let ancestor = current.owners.filter {
                    let clipped = viewport(of: $0, among: current.owners)
                    return $0.frame != owner.frame && !clipped.isNull && !clipped.isEmpty
                }.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                guard attempt < 8, let ancestor else {
                    XCTFail("An offscreen nested reader must become visible within eight pans"); return
                }
                move(owner.frame, through: viewport(of: ancestor, among: current.owners), fraction: 0.8)
                continue
            }
            guard !visible.isEmpty, !visible.isNull else { XCTFail("The actual reading viewport must be visible"); return }
            let bounds = item.frame
            // An element that fits must be aligned as a whole. Treating a
            //300pt figure as a half-page paragraph can overscroll its top.
            let first = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width,
                height: bounds.height <= visible.height ? bounds.height : visible.height * 0.5)
            if visible.insetBy(dx: -1, dy: -1).contains(first) { break }
            guard attempt < 8 else { XCTFail("The first complete reading line must be reachable within eight pans"); return }
            move(first, through: visible, fraction: 0.8)
        }
        let initial = area().viewport
        XCTAssertGreaterThan(item.frame.width, 0); XCTAssertGreaterThan(item.frame.height, 0)
        XCTAssertGreaterThanOrEqual(item.frame.minY, initial.minY - 1)
        if initial.insetBy(dx: -1, dy: -1).contains(item.frame) {
            capture(name + "-end", in: app)
            return
        }
        var readThrough = min(item.frame.height, initial.maxY - item.frame.minY)
        capture(name + "-start", in: app)
        for attempt in 0...8 {
            let visible = area().viewport
            if item.frame.maxY <= visible.maxY + 1 { break }
            guard attempt < 8 else { XCTFail("The complete reading must be reachable within eight overlapping pans"); return }
            move(item.frame, through: visible, fraction: 0.45)
            let next = area().viewport
            XCTAssertLessThanOrEqual(max(0, next.minY - item.frame.minY), readThrough + 1)
            readThrough = max(readThrough, min(item.frame.height, next.maxY - item.frame.minY))
            capture(name + "-reading-\(attempt + 1)", in: app)
        }
        let final = area().viewport
        XCTAssertLessThanOrEqual(item.frame.maxY, final.maxY + 1)
        XCTAssertGreaterThan(item.frame.maxY, final.minY)
        XCTAssertGreaterThanOrEqual(readThrough, item.frame.height - 1)
        if item.frame.height <= final.height { XCTAssertTrue(final.insetBy(dx: -1, dy: -1).contains(item.frame)) }
        if let expected { XCTAssertEqual(item.label, expected) }
        capture(name + "-end", in: app)
    }

    @MainActor private func panThroughDiagram(_ figure: XCUIElement, in app: XCUIApplication) {
        let before = figure.frame
        XCTAssertTrue(app.frame.contains(before))
        XCTAssertGreaterThanOrEqual(before.height, 112)
        let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
            dx: before.midX - app.frame.minX,
            dy: before.minY - app.frame.minY + before.height * 0.75))
        let end = start.withOffset(.init(dx: 0, dy: -64))
        // Both contacts begin inside the already fully visible passive board.
        // It has no hit action; the one physical pan belongs to its reader.
        start.press(forDuration: 0.05, thenDragTo: end,
                    withVelocity: .slow, thenHoldForDuration: 0.1)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            figure.frame.minY < before.minY - 1
        }, object: nil).wait(timeout: 5), "A pan through passive art must move the actual reading content")
        capture("last-clear-tablet-passive-board-pan", in: app)
    }

    @MainActor private func openRecap(fromMenu: Bool, in app: XCUIApplication) {
        if fromMenu { tap("experiment.settings", in: app) }
        // A menu NavigationLink and a terminal Button have distinct native
        // identities. Use the exact current route and the same strict control
        // admission as every sibling action, including bounded viewport reveal.
        let id = fromMenu ? "sky.lastClear.menu.open" : "sky.lastClear.result.open"
        let other = fromMenu ? "sky.lastClear.result.open" : "sky.lastClear.menu.open"
        XCTAssertFalse(app.buttons[other].exists)
        tap(id, in: app, expectedLabel: "Review last clear")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Last clear"),
                                                object: app.staticTexts["sky.menu.title"]).wait(timeout: 5))
    }

    @MainActor private func assertNoRecap(fromMenu: Bool, in app: XCUIApplication) {
        if fromMenu { tap("experiment.settings", in: app) }
        XCTAssertFalse(app.buttons["sky.lastClear.menu.open"].exists)
        XCTAssertFalse(app.buttons["sky.lastClear.result.open"].exists)
        if fromMenu { tap("experiment.done", in: app) }
    }

    @MainActor private func readRecap(mode: String, scores: [String], total: String,
                                     room: String? = nil,
                                     survivors: String? = nil, capture name: String,
                                     in app: XCUIApplication) -> [String] {
        var snapshot: [String] = []
        func record(_ id: String, expected: String? = nil) {
            let item = element(id, in: app)
            read(item, expected: expected, capture: name + "-" + id, in: app)
            XCTAssertFalse(item.label.isEmpty, id)
            snapshot.append("\(id):\(item.label):\(item.value as? String ?? "")")
        }
        record("sky.lastClear.mode", expected: mode)
        for (offset, text) in scores.enumerated() {
            let number = offset + 1
            record("sky.lastClear.phase.\(number)", expected: "Clear \(number)")
            record("sky.lastClear.diagram.\(number)", expected: "Clear \(number)")
            record("sky.lastClear.ingredients.\(number)")
            XCTAssertEqual(element("sky.lastClear.diagram.\(number)", in: app).value as? String,
                           element("sky.lastClear.ingredients.\(number)", in: app).label)
            record("sky.lastClear.score.\(number)", expected: text)
        }
        XCTAssertFalse(element("sky.lastClear.phase.\(scores.count + 1)", in: app).exists)
        record("sky.lastClear.total", expected: total)
        if let survivors { record("sky.lastClear.survivors", expected: survivors) }
        else { XCTAssertFalse(element("sky.lastClear.survivors", in: app).exists) }
        record("sky.lastClear.room", expected: room)
        return snapshot
    }

    @MainActor private func silverResult(_ points: Int, in app: XCUIApplication) {
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Silver Pools restored!"),
                                                object: outcome).wait(timeout: 12))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
            "Sunny. Silver Pools complete! One silver cascade now flows through every pool. \(points.formatted()) of 12,000 starlight collected. Nicely done!")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        for id in ["experiment.replay", "experiment.new", "sky.worldMap"] {
            let action = app.buttons[id]
            app.revealSkyControls([action])
            XCTAssertTrue(action.isEnabled && action.isHittable && app.frame.contains(action.frame))
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        }
    }

    @MainActor private func replaySilver(_ opening: RoundState, in app: XCUIApplication) throws {
        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Silver Pools")
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, target: 12_000, in: app)
        XCTAssertEqual(try round(in: app), opening)
        assertNoRecap(fromMenu: true, in: app)
    }

    @MainActor func testNormalSilverMenuThenResultRecapUsesPhysicalButton() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO",
                               "--starfalls-reset", "--world-legacy-review"]
        app.launch()
        app.worldVisitControl("silverPools").tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 12_000, in: app)
        exchange(2, 9, in: app); settled(7_000, target: 12_000, in: app)
        let before = try round(in: app)
        openRecap(fromMenu: true, in: app)
        XCTAssertEqual(element("sky.lastClear.total", in: app).label, "7,000 points this clear.")
        tap("sky.menu.back", in: app); tap("sky.lastClear.menu.open", in: app); tap("experiment.done", in: app)
        settled(7_000, target: 12_000, in: app); XCTAssertEqual(try round(in: app), before)
        exchange(23, 22, in: app); silverResult(12_000, in: app)
        openRecap(fromMenu: false, in: app)
        XCTAssertEqual(element("sky.lastClear.total", in: app).label, "5,000 points this clear.")
        read(element("sky.lastClear.diagram.1", in: app), capture: "last-clear-menu-result-physical-opener", in: app)
        tap("experiment.done", in: app); silverResult(12_000, in: app)
    }

    @MainActor func testNormalSilverLastClearChainSeparateActionsAndColdRestore() throws {
        continueAfterFailure = false
        // The first measured complete-flow attempt reached its fourth recap at
        //328s. Preserve every physical/viewport/state assertion with a bounded
        //whole-journey budget; individual waits and gesture limits stay fixed.
        executionTimeAllowance = 540
        normalSystemMotion()
        let app = XCUIApplication(); defer { app.terminate() }
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        // Existing-install admission is not a claim that earlier repairs were earned.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch()
        let visit = app.worldVisitControl("silverPools")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertTrue(initialWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Restore Silver Pools first"))
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 12_000, in: app)
        let opening = try round(in: app)
        assertNoRecap(fromMenu: true, in: app)
        exchange(9, 10, in: app); silverResult(19_000, in: app)
        read(app.staticTexts["experiment.score"],
             expected: "Sunny. Silver Pools complete! One silver cascade now flows through every pool. 19,000 of 12,000 starlight collected. Nicely done!",
             capture: "last-clear-phone-silver-whole-result", in: app)
        openRecap(fromMenu: false, in: app)
        let chain = readRecap(mode: "Silver Pools · Falling Sky", scores: [fourSmall, fiveChain],
            total: "19,000 points this clear.", room: "15 stars on the board after this clear.",
            survivors: "1 survivor fell into a later pattern.",
            capture: "last-clear-phone-silver-chain", in: app)
        tap("experiment.done", in: app); silverResult(19_000, in: app)
        XCUIDevice.shared.press(.home); app.activate(); silverResult(19_000, in: app)
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        tap("sky.home", in: app); silverResult(19_000, in: app)
        openRecap(fromMenu: false, in: app)
        XCTAssertEqual(readRecap(mode: "Silver Pools · Falling Sky", scores: [fourSmall, fiveChain],
            total: "19,000 points this clear.", room: "15 stars on the board after this clear.",
            survivors: "1 survivor fell into a later pattern.",
            capture: "last-clear-phone-entry-back-retains-chain", in: app), chain)
        tap("experiment.done", in: app)
        let repairedWorld = try world(fromMenu: false, in: app)
        XCTAssertTrue(repairedWorld.contains("world.place.silverPools:Silver Pools:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Ready to restore"))
        func unrelated(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.silverPools:") && !$0.hasPrefix("world.place.frostfruitOrchard:") }
        }
        XCTAssertEqual(unrelated(initialWorld), unrelated(repairedWorld))
        try replaySilver(opening, in: app)
        exchange(2, 9, in: app); settled(7_000, target: 12_000, in: app)
        let separate = try round(in: app)
        openRecap(fromMenu: true, in: app)
        _ = readRecap(mode: "Silver Pools · Falling Sky", scores: [fiveSmall], total: "7,000 points this clear.",
                      room: "5 more spaces above the stars in columns 1, 2, 3, 4, 5. 19 stars on the board after this clear.",
                      capture: "last-clear-phone-independent-seven", in: app)
        tap("sky.menu.back", in: app)
        XCTAssertEqual(app.staticTexts["sky.menu.title"].label, "Sky menu")
        tap("sky.lastClear.menu.open", in: app); tap("experiment.done", in: app)
        settled(7_000, target: 12_000, in: app); XCTAssertEqual(try round(in: app), separate)
        XCTAssertEqual(try world(fromMenu: true, in: app), repairedWorld)
        exchange(23, 22, in: app); silverResult(12_000, in: app)
        openRecap(fromMenu: false, in: app)
        _ = readRecap(mode: "Silver Pools · Falling Sky", scores: [fourSmall], total: "5,000 points this clear.",
                      room: "15 stars on the board after this clear.",
                      capture: "last-clear-phone-only-latest-independent-five", in: app)
        tap("experiment.done", in: app); silverResult(12_000, in: app)
        read(app.staticTexts["experiment.score"],
             expected: "Sunny. Silver Pools complete! One silver cascade now flows through every pool. 12,000 of 12,000 starlight collected. Nicely done!",
             capture: "last-clear-phone-independent-whole-result", in: app)
        XCTAssertEqual(try world(fromMenu: false, in: app), repairedWorld)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        silverResult(12_000, in: app); assertNoRecap(fromMenu: false, in: app)
        XCTAssertEqual(try world(fromMenu: false, in: app), repairedWorld)
        capture("last-clear-phone-cold-ending-omits-session-recap", in: app)
        try replaySilver(opening, in: app)
    }

    @MainActor func testLargestCalmFullBoardLastClearSimultaneousPatternsAndExactReplay() throws {
        continueAfterFailure = false
        // The original285s run had only reached final recap admission at263s.
        // Allow the whole three-phase reading, result/mastery controls and
        // exact Replay to finish; individual waits/eight-pan bounds are intact.
        executionTimeAllowance = 600
        let app = XCUIApplication(); defer { app.terminate() }
        // Omit Calm arguments so real Settings can write the preference.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertTrue(initialWorld.contains("world.place.ribbonCrossing:Ribbon Crossing:Restore Lantern Landing first"))
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        let opening = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        assertNoRecap(fromMenu: true, in: app)
        let moves = [(27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000), (12, 13, 63_000),
                     (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
                     (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)]
        for (index, move) in moves.enumerated() {
            exchange(move.0, move.1, in: app)
            if move.2 < 150_000 { settled(move.2, target: 150_000, exchanges: index + 1, in: app) }
            if index == 0 {
                let retained = try round(in: app)
                openRecap(fromMenu: true, in: app)
                read(element("sky.lastClear.mode", in: app), expected: "Lantern Landing · Full Board",
                     capture: "last-clear-tablet-live-mode", in: app)
                let diagram = element("sky.lastClear.diagram.1", in: app)
                read(diagram, expected: "Clear 1", capture: "last-clear-tablet-live-first-diagram", in: app)
                panThroughDiagram(diagram, in: app)
                read(element("sky.lastClear.total", in: app), expected: "42,000 points this clear.",
                     capture: "last-clear-tablet-live-whole-action", in: app)
                tap("sky.menu.back", in: app)
                XCTAssertEqual(app.staticTexts["sky.menu.title"].label, "Sky menu")
                tap("experiment.replay", in: app)
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
                tap("sky.home", in: app)
                settled(42_000, target: 150_000, exchanges: 1, in: app)
                XCTAssertEqual(try round(in: app), retained)
                XCUIDevice.shared.press(.home); app.activate()
                settled(42_000, target: 150_000, exchanges: 1, in: app)
                XCTAssertEqual(try round(in: app), retained)
                openRecap(fromMenu: true, in: app)
                read(element("sky.lastClear.total", in: app), expected: "42,000 points this clear.",
                     capture: "last-clear-tablet-entry-back-retains-recap", in: app)
                tap("experiment.done", in: app)
                XCTAssertEqual(try round(in: app), retained)
                XCTAssertEqual(try world(fromMenu: true, in: app), initialWorld)
            }
        }
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Lantern Landing restored!"),
                                                object: outcome).wait(timeout: 12))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
            "Sunny. First Light complete! Lantern Landing is restored. 156,000 of 150,000 starlight collected. Nicely done!")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Ribbon Crossing")
        openRecap(fromMenu: false, in: app)
        _ = readRecap(mode: "Lantern Landing · Full Board", scores: [
            "10 stars · 10 light. 10,000 base + 7,000 size = 17,000 points.",
            "8 stars · 8 light. 8,000 base + 5,000 size + 13,000 chain = 26,000 points.",
            "4 stars · 4 light. 4,000 base + 1,000 size + 10,000 chain = 15,000 points."
        ], total: "58,000 points this clear.",
            room: "Refill added 22 stars. 49 stars on the board after this clear.",
            survivors: "6 survivors fell into later patterns.",
            capture: "last-clear-tablet-simultaneous-three-phase-finish", in: app)
        tap("experiment.done", in: app)
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        read(outcome, expected: "Lantern Landing restored!", capture: "last-clear-tablet-result-heading", in: app)
        read(app.staticTexts["experiment.score"],
             expected: "Sunny. First Light complete! Lantern Landing is restored. 156,000 of 150,000 starlight collected. Nicely done!",
             capture: "last-clear-tablet-result-whole-score", in: app)
        for id in ["sky.mastery.result.rating", "sky.mastery.result.goal.cascade", "sky.mastery.result.goal.largeClear"] {
            read(element(id, in: app), capture: "last-clear-tablet-result-" + id, in: app)
        }
        XCTAssertEqual(element("sky.mastery.result.rating", in: app).label, "3 of 3 stars earned")
        for name in ["cascade", "largeClear"] {
            XCTAssertEqual(element("sky.mastery.result.goal.\(name)", in: app).value as? String, "Earned this run")
        }
        let best = app.staticTexts["sky.mastery.result.best"]
        read(best, capture: "last-clear-tablet-result-best", in: app)
        XCTAssertTrue(best.label.contains("3 of 3 stars from one completed run"))
        for id in ["sky.worldMap", "experiment.replay", "experiment.new", "sky.home"] {
            let action = app.buttons[id]
            app.revealSkyControls([action])
            XCTAssertTrue(action.isEnabled && action.isHittable && app.frame.contains(action.frame))
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        }
        let repairedWorld = try world(fromMenu: false, in: app)
        XCTAssertTrue(repairedWorld.contains("world.place.firstLight:Lantern Landing:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.ribbonCrossing:Ribbon Crossing:Ready to restore"))
        func unrelated(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.firstLight:") && !$0.hasPrefix("world.place.ribbonCrossing:") }
        }
        XCTAssertEqual(unrelated(initialWorld), unrelated(repairedWorld))
        tap("experiment.replay", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        XCTAssertEqual(try round(in: app), opening)
        assertNoRecap(fromMenu: true, in: app)
        _ = setCalm(originalCalm, in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertEqual(try world(fromMenu: true, in: app), repairedWorld)
        capture("last-clear-tablet-exact-replay-no-recap", in: app)
    }

    @MainActor func testNormalOpenSkyLastClearTracePersistsThroughNoAwardLoss() throws {
        continueAfterFailure = false
        executionTimeAllowance = 420
        normalSystemMotion()
        let app = XCUIApplication(); defer { app.terminate() }
        let retainedArguments = ["--dialogue-review", "-calmEffects", "NO"]
        // Authored horizontalFive starts paused and tests real production input;
        // it does not certify modern random showers or an earned Story entry.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--constellation-fixture=horizontalFive"]
        app.launch(); settled(0, showers: nil, in: app)
        let initialWorld = try world(fromMenu: true, in: app)
        assertNoRecap(fromMenu: true, in: app)
        let source = app.buttons["experiment.cell.0.0"], end = app.buttons["experiment.cell.0.4"]
        app.revealSkyControls([source, end])
        XCTAssertTrue(source.isEnabled && source.isHittable && end.isEnabled && end.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.4,
            thenDragTo: end.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .slow, thenHoldForDuration: 0.45)
        settled(5, showers: nil, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Twinkle")).count, 0)
        let afterTrace = try round(in: app)
        openRecap(fromMenu: true, in: app)
        let traceRoom = "5 more spaces above the stars in columns 1, 2, 3, 4, 5. 0 stars on the board after this clear."
        let trace = readRecap(mode: "OPEN SKY", scores: ["5 stars · 5 light = 5 points."],
            total: "5 points this clear.", room: traceRoom, capture: "last-clear-phone-manual-exact-five", in: app)
        tap("experiment.done", in: app); settled(5, showers: nil, in: app)
        XCTAssertEqual(try round(in: app), afterTrace)
        XCUIDevice.shared.press(.home); app.activate(); settled(5, showers: nil, in: app)
        XCTAssertEqual(try round(in: app), afterTrace)
        tap("experiment.next", in: app); settled(5, showers: nil, in: app)
        let afterShower = try round(in: app)
        openRecap(fromMenu: true, in: app)
        XCTAssertEqual(readRecap(mode: "OPEN SKY", scores: ["5 stars · 5 light = 5 points."],
            total: "5 points this clear.", room: traceRoom,
            capture: "last-clear-phone-no-award-shower-retains-trace", in: app), trace)
        tap("experiment.done", in: app); XCTAssertEqual(try round(in: app), afterShower)
        let outcome = app.staticTexts["experiment.outcome"]
        var showers = 1
        for _ in 0..<39 {
            if outcome.exists { break }
            settled(5, showers: nil, in: app); tap("experiment.next", in: app); showers += 1
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || app.buttons["experiment.next"].isEnabled
            }, object: nil).wait(timeout: 8))
        }
        XCTAssertGreaterThan(showers, 1)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "No room to land")
        let ending = app.staticTexts["experiment.score"].label
        XCTAssertTrue((1...7).contains { column in
            ending == "Twinkle. Column \(column) had no room for the next star. 5 starlight collected. Ready for another sky?"
        }, "The complete Twinkle loss paragraph must identify one actual board column and the exact raw score")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        openRecap(fromMenu: false, in: app)
        XCTAssertEqual(readRecap(mode: "OPEN SKY", scores: ["5 stars · 5 light = 5 points."],
            total: "5 points this clear.", room: traceRoom,
            capture: "last-clear-phone-loss-keeps-prior-trace", in: app), trace)
        tap("experiment.done", in: app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, ending)
        XCTAssertEqual(try world(fromMenu: false, in: app), initialWorld, "Open Sky never earns a restoration repair")
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, ending)
        assertNoRecap(fromMenu: false, in: app)
        XCTAssertEqual(try world(fromMenu: false, in: app), initialWorld)
        capture("last-clear-phone-cold-loss-no-reconstructed-clear", in: app)
        tap("experiment.replay", in: app); tap("sky.begin", in: app)
        // Replay reconstructs this historical seed/rules, not the injected row.
        let replayShowers = pauseNewSky(expectedShowers: nil, in: app)
        settled(0, showers: replayShowers, in: app); assertNoRecap(fromMenu: true, in: app)
        XCTAssertEqual(try world(fromMenu: true, in: app), initialWorld)
    }
}
