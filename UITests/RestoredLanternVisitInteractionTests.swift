import XCTest

/// A real repair admits the existing complete painting. Viewing never starts
/// a puzzle, replaces a retained round or awards another repair.
final class RestoredLanternVisitInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let winningMoves = [(27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000),
        (12, 13, 63_000), (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
        (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)]
    private let lanternEnding = "Sunny. First Light complete! Lantern Landing is restored. 156,000 of 150,000 starlight collected. Nicely done!"

    @MainActor private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor private func tap(_ id: String, expected: String? = nil, in app: XCUIApplication) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND enabled == true AND hittable == true"),
            object: control).wait(timeout: 5), id)
        XCTAssertTrue(app.frame.contains(control.frame), id)
        if let expected { XCTAssertEqual(control.label, expected) }
        if id == "world.restored.back" {
            let state = XCTAttachment(string: "beforeBack=\(app.state.rawValue); matches=\(app.buttons.matching(identifier: id).count); frame=\(control.frame); enabled=\(control.isEnabled); hittable=\(control.isHittable)")
            state.name = "restored-lantern-back-admission"; state.lifetime = .keepAlways; add(state)
            XCTAssertEqual(app.state, .runningForeground)
        }
        control.tap()
    }

    @MainActor private func capture(_ name: String, in app: XCUIApplication) {
        let image = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func identities(_ root: XCUIElement, prefix: String,
                                      buttonsOnly: Bool = true) throws -> [String] {
        var values: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.identifier.hasPrefix(prefix), !buttonsOnly || node.elementType == .button {
                values.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try root.snapshot())
        return values.sorted()
    }

    @MainActor private func round(in app: XCUIApplication) throws -> RoundState {
        let board = app.otherElements["experiment.board"]
        let cells = try identities(board, prefix: "experiment.cell.")
        XCTAssertEqual(cells.count, 49, "Semantic cells include empty slots")
        return .init(board: board.value as? String,
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

    @MainActor private func settled(_ points: Int, target: Int = 150_000,
                                    exchanges: Int? = nil, in app: XCUIApplication) {
        let expected = "\(points.formatted()) of \(target.formatted()) starlight collected"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let summary = app.otherElements["experiment.board"].value as? String ?? ""
            let cadence = exchanges.map { summary.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? summary.hasPrefix("0 showers")
            return app.staticTexts["experiment.score"].label == expected && cadence
                && !summary.contains("Stars settling") && app.buttons["experiment.cell.0.0"].isEnabled
                && (exchanges != nil || app.buttons["experiment.next"].isEnabled)
        }, object: nil).wait(timeout: 12), expected)
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        if exchanges != nil { XCTAssertFalse(app.buttons["experiment.next"].exists) }
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        // This utility is pinned. Scroll/reveal discovery can spend the first
        // ordinary shower before the menu has suspended the new round.
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND enabled == true AND hittable == true"),
            object: menu).wait(timeout: 5))
        let target = menu.frame
        XCTAssertGreaterThanOrEqual(target.width, 48)
        XCTAssertGreaterThanOrEqual(target.height, 48)
        XCTAssertTrue(app.frame.contains(target))
        menu.tap()
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
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func places(in app: XCUIApplication) {
        XCTAssertTrue(element("world.page", in: app).waitForExistence(timeout: 5))
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" {
            tap("world.list", in: app)
        }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
    }

    @MainActor private func worldState(in app: XCUIApplication) throws -> [String] {
        places(in: app)
        let state = try identities(app, prefix: "world.place.")
        XCTAssertEqual(state.count, 12)
        return state
    }

    @MainActor private func select(_ location: String, in app: XCUIApplication) {
        places(in: app); tap("world.place." + location, in: app)
        XCTAssertTrue(app.buttons["world.place." + location].isSelected)
    }

    @MainActor private func readyAndLockedHaveNoViewer(in app: XCUIApplication) throws -> [String] {
        tap("sky.worldMap", in: app)
        select("firstLight", in: app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        XCTAssertFalse(app.buttons["world.viewRestored"].exists)
        select("ribbonCrossing", in: app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Lantern Landing first")
        XCTAssertFalse(app.buttons["world.viewRestored"].exists)
        XCTAssertFalse(app.buttons["world.visit"].exists)
        select("firstLight", in: app)
        return try worldState(in: app)
    }

    @MainActor private func earnLanternRepair(in app: XCUIApplication) {
        tap("world.visit", in: app)
        tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, exchanges: 0, in: app)
        for (index, move) in winningMoves.enumerated() {
            exchange(move.0, move.1, in: app)
            if move.2 < 150_000 { settled(move.2, exchanges: index + 1, in: app) }
        }
        assertLanternResult(in: app)
    }

    @MainActor private func assertLanternResult(in app: XCUIApplication) {
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Lantern Landing restored!"),
                                                object: outcome).wait(timeout: 12))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, lanternEnding)
        for id in ["sky.worldMap", "experiment.replay"] {
            let control = app.buttons[id]
            app.revealSkyControls([control])
            XCTAssertTrue(control.isEnabled && control.isHittable && app.frame.contains(control.frame))
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Ribbon Crossing")
    }

    /// These short native captions must fit whole in their actual reader.
    /// Fixed headers/Return and nested ancestors remain real clipping bounds.
    @MainActor private func readCaption(_ id: String, expected: String, capture name: String,
                                       in app: XCUIApplication) {
        let item = element(id, in: app)
        XCTAssertTrue(item.waitForExistence(timeout: 5)); XCTAssertEqual(item.label, expected)
        for attempt in 0...8 {
            let owners = app.scrollViews.containing(item.elementType, identifier: id).allElementsBoundByIndex
            let owner = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            var visible = app.frame.intersection(owner?.frame ?? app.frame)
            if let owner {
                for ancestor in owners where ancestor.frame != owner.frame {
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == owner.frame }) {
                        visible = visible.intersection(ancestor.frame)
                    }
                }
            }
            let title = app.staticTexts["sky.menu.title"], done = app.buttons["experiment.done"]
            if title.exists && title.frame.intersects(app.frame) {
                let top = max(visible.minY, title.frame.maxY)
                let bottom = min(visible.maxY, done.exists && done.isHittable ? done.frame.minY : visible.maxY)
                visible = CGRect(x: visible.minX, y: top, width: visible.width, height: max(0, bottom - top))
            }
            guard !visible.isNull, !visible.isEmpty, item.frame.height <= visible.height else {
                XCTFail("A complete caption must fit the actual native reading viewport"); return
            }
            if visible.insetBy(dx: -1, dy: -1).contains(item.frame) {
                capture(name, in: app); return
            }
            guard attempt < 8 else { XCTFail("Caption did not become fully readable within eight pans"); return }
            let up = item.frame.maxY > visible.maxY
            let distance = min(visible.height * 0.8,
                max(24, up ? item.frame.maxY - visible.maxY + 8 : visible.minY - item.frame.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * 0.12,
                dy: visible.minY - app.frame.minY + visible.height * (up ? 0.85 : 0.15)))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
    }

    @MainActor private func recap(mode: String, total: String, fromMenu: Bool,
                                 capture name: String, in app: XCUIApplication) throws -> [String] {
        if fromMenu { tap("experiment.settings", in: app) }
        tap(fromMenu ? "sky.lastClear.menu.open" : "sky.lastClear.result.open", expected: "Review last clear", in: app)
        XCTAssertEqual(app.staticTexts["sky.menu.title"].label, "Last clear")
        readCaption("sky.lastClear.mode", expected: mode, capture: name + "-mode", in: app)
        readCaption("sky.lastClear.total", expected: total, capture: name + "-total", in: app)
        let state = try identities(app, prefix: "sky.lastClear.", buttonsOnly: false)
        XCTAssertGreaterThanOrEqual(state.count, 8)
        tap("experiment.done", in: app)
        return state
    }

    @MainActor private func assertViewer(capture name: String, in app: XCUIApplication) {
        let page = element("world.restored.page", in: app)
        XCTAssertTrue(page.waitForExistence(timeout: 5))
        let title = app.staticTexts["world.restored.title"], status = app.staticTexts["world.restored.status"]
        XCTAssertEqual(title.label, "Lantern Landing"); XCTAssertEqual(status.label, "Restored")
        let art = element("world.restored.art", in: app)
        XCTAssertTrue(art.waitForExistence(timeout: 5))
        XCTAssertEqual(art.label, "Lantern Landing"); XCTAssertEqual(art.value as? String, "Restored")
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !art.frame.isEmpty && !page.frame.isEmpty
        }, object: nil).wait(timeout: 5))
        let viewport = app.frame.intersection(page.frame)
        let bounds = "app=\(app.frame); page=\(page.frame); viewport=\(viewport); art=\(art.frame)"
        let measurement = XCTAttachment(string: bounds)
        measurement.name = name + "-native-bounds"
        measurement.lifetime = .keepAlways
        add(measurement)
        XCTAssertTrue(viewport.contains(art.frame), "The complete semantic art viewport must fit; source paintings keep their accepted bleed. \(bounds)")
        XCTAssertGreaterThan(art.frame.width, 0); XCTAssertGreaterThan(art.frame.height, 0)
        XCTAssertTrue(app.frame.contains(title.frame) && app.frame.contains(status.frame))
        let back = app.buttons["world.restored.back"]
        XCTAssertTrue(back.isEnabled && back.isHittable && app.frame.contains(back.frame))
        XCTAssertEqual(back.label, "Back")
        guard let raster = app.screenshot().image.cgImage else {
            return XCTFail("The actual native raster scale is required for target measurement")
        }
        let scale = CGFloat(max(raster.width, raster.height)) / max(app.frame.width, app.frame.height)
        let target = back.frame
        // Convert global edges before subtraction: fractional-point origins can
        // otherwise report a 44-point target as43.99999999999999. No rounding
        // or epsilon is admitted; the same44-point minimum must still fit.
        let width = (target.maxX * scale - target.minX * scale) / scale
        let height = (target.maxY * scale - target.minY * scale) / scale
        let targetMeasurement = XCTAttachment(string: "back=\(target); nativeScale=\(scale); width=\(width); height=\(height)")
        targetMeasurement.name = name + "-native-target"
        targetMeasurement.lifetime = .keepAlways
        add(targetMeasurement)
        XCTAssertGreaterThanOrEqual(width, 44); XCTAssertGreaterThanOrEqual(height, 44)
        XCTAssertFalse(app.buttons["sky.begin"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 0)
        capture(name, in: app)
    }

    @MainActor private func backgroundAndRestoreViewer(capture name: String, in app: XCUIApplication) {
        let beforeHome = app.state
        XCUIDevice.shared.press(.home)
        let afterHome = app.state
        let backgrounded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.state == .runningBackground || app.state == .runningBackgroundSuspended
        }, object: nil).wait(timeout: 5)
        let beforeActivate = app.state
        let backgroundStates = XCTAttachment(string: "beforeHome=\(beforeHome.rawValue); afterHome=\(afterHome.rawValue); beforeActivate=\(beforeActivate.rawValue); admitted=\(backgrounded)")
        backgroundStates.name = name + "-actual-background"
        backgroundStates.lifetime = .keepAlways; add(backgroundStates)
        XCTAssertTrue(backgrounded, "Home must actually background the app")
        app.activate()
        let afterActivate = app.state
        let foregrounded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let back = app.buttons["world.restored.back"]
            return app.state == .runningForeground && back.isEnabled && back.isHittable
        }, object: nil).wait(timeout: 5)
        let states = XCTAttachment(string: "afterActivate=\(afterActivate.rawValue); admittedState=\(app.state.rawValue); admitted=\(foregrounded)")
        states.name = name + "-actual-lifecycle"
        states.lifetime = .keepAlways
        add(states)
        XCTAssertTrue(foregrounded, "Readmit the foreground viewer and its real Back control")
    }

    @MainActor private func viewRestored(capture name: String, background: Bool = false,
                                       in app: XCUIApplication) {
        tap("world.viewRestored", expected: "View restored place", in: app)
        assertViewer(capture: name, in: app)
        if background {
            backgroundAndRestoreViewer(capture: name, in: app)
            assertViewer(capture: name + "-background", in: app)
        }
        tap("world.restored.back", expected: "Back", in: app)
        XCTAssertTrue(element("world.page", in: app).waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restored")
    }

    @MainActor private func setCalm(_ enabled: Bool, verifyOffToOn: Bool = false,
                                   in app: XCUIApplication) -> Bool {
        tap("experiment.settings", in: app); tap("experiment.preferences", in: app)
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5))
        app.revealSkyMenuElement(calm); app.revealSkyControls([calm])
        let original = calm.value as? String == "1"
        let attachment = XCTAttachment(string: "actual-original-Calm=\(original)")
        attachment.name = "restored-lantern-calm-before-mutation"; attachment.lifetime = .keepAlways; add(attachment)
        func select(_ value: String) {
            if calm.value as? String != value { calm.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value),
                                                    object: calm).wait(timeout: 5))
            XCTAssertEqual(calm.value as? String, value)
        }
        if enabled && verifyOffToOn { select("0") }
        select(enabled ? "1" : "0")
        capture("restored-lantern-actual-calm-" + (enabled ? "on" : "restored-off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor private func assertOnlyLanternRepair(_ initial: [String], repaired: [String]) {
        XCTAssertTrue(repaired.contains("world.place.firstLight:Lantern Landing:Restored"))
        XCTAssertTrue(repaired.contains("world.place.ribbonCrossing:Ribbon Crossing:Ready to restore"))
        func unrelated(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.firstLight:") && !$0.hasPrefix("world.place.ribbonCrossing:") }
        }
        XCTAssertEqual(unrelated(initial), unrelated(repaired))
    }

    @MainActor func testNormalCompletedLanternViewPreservesResultAndOppositeSky() throws {
        continueAfterFailure = false
        executionTimeAllowance = 480
        normalSystemMotion(); XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "-calmEffects", "NO"]
        app.launchArguments = retainedArguments + ["--starfalls-reset"]
        app.launch(); defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        let initialWorld = try readyAndLockedHaveNoViewer(in: app)
        earnLanternRepair(in: app)
        let earnedRecap = try recap(mode: "Lantern Landing · Full Board", total: "58,000 points this clear.",
                                   fromMenu: false, capture: "restored-lantern-phone-earned-recap", in: app)
        assertLanternResult(in: app)
        tap("sky.worldMap", in: app); select("firstLight", in: app)
        let repairedWorld = try worldState(in: app)
        assertOnlyLanternRepair(initialWorld, repaired: repairedWorld)
        XCTAssertEqual(app.buttons["world.visit"].label, "Revisit Lantern Landing")
        // The standard phone proves the actual illustrated Map and Places card.
        tap("world.list", expected: "Map", in: app)
        let marker = app.buttons["world.node.firstLight"]
        app.revealWorldMapMarker(marker)
        XCTAssertTrue(marker.isSelected)
        viewRestored(capture: "restored-lantern-phone-map-complete-painting", background: true, in: app)
        XCTAssertTrue(app.buttons["world.node.firstLight"].exists)
        XCTAssertEqual(app.buttons["world.list"].label, "Places")
        places(in: app)
        viewRestored(capture: "restored-lantern-phone-places-complete-painting", in: app)
        XCTAssertEqual(try worldState(in: app), repairedWorld)
        tap("world.visit", expected: "Revisit Lantern Landing", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.home", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertEqual(try worldState(in: app), repairedWorld)
        tap("world.done", in: app); assertLanternResult(in: app)
        XCTAssertEqual(try recap(mode: "Lantern Landing · Full Board", total: "58,000 points this clear.",
            fromMenu: false, capture: "restored-lantern-phone-result-retained-recap", in: app), earnedRecap)

        tap("sky.worldMap", in: app); select("firstLight", in: app)
        tap("world.visit", expected: "Revisit Lantern Landing", in: app)
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, in: app)
        exchange(8, 9, in: app); settled(15_000, in: app)
        let retained = try round(in: app)
        let skyRecap = try recap(mode: "Lantern Landing · Falling Sky", total: "15,000 points this clear.",
                                fromMenu: true, capture: "restored-lantern-phone-opposite-mode-recap", in: app)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app); select("firstLight", in: app)
        XCTAssertEqual(app.staticTexts["world.savedProgress"].label, "Saved Falling Sky progress: 15,000 of 150,000 starlight.")
        XCTAssertEqual(app.buttons["world.visit"].label, "Start again")
        XCTAssertEqual(app.buttons["world.resume"].label, "Continue")
        let beforeView = try worldState(in: app)
        XCTAssertEqual(beforeView, repairedWorld)
        viewRestored(capture: "restored-lantern-phone-view-preserves-opposite-mode", background: true, in: app)
        XCTAssertEqual(try worldState(in: app), beforeView)
        tap("world.resume", expected: "Continue", in: app)
        settled(15_000, in: app); XCTAssertEqual(try round(in: app), retained)
        XCTAssertEqual(try recap(mode: "Lantern Landing · Falling Sky", total: "15,000 points this clear.",
            fromMenu: true, capture: "restored-lantern-phone-opposite-mode-recap-unchanged", in: app), skyRecap)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        settled(15_000, in: app); XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app); select("firstLight", in: app)
        XCTAssertEqual(try worldState(in: app), repairedWorld)
        viewRestored(capture: "restored-lantern-phone-after-exact-cold-continue", in: app)
        tap("world.resume", in: app); settled(15_000, in: app)
        XCTAssertEqual(try round(in: app), retained)
    }

    @MainActor func testLargestCalmRestoredLanternPortraitLandscapePreservesForeignRound() throws {
        continueAfterFailure = false
        // The observed 494s prefix plus retained-return, recap and preference tails
        // need a whole-journey budget; individual waits and reveal bounds stay fixed.
        executionTimeAllowance = 720
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "-UIPreferredContentSizeCategoryName",
                                 "UICTContentSizeCategoryAccessibilityXXXL"]
        // The actual preference is mutable: no Calm launch argument.
        app.launchArguments = retainedArguments + ["--starfalls-reset"]
        app.launch(); defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        let initialWorld = try readyAndLockedHaveNoViewer(in: app)
        tap("world.visit", in: app); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, exchanges: 0, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        for (index, move) in winningMoves.enumerated() {
            exchange(move.0, move.1, in: app)
            if move.2 < 150_000 { settled(move.2, exchanges: index + 1, in: app) }
        }
        assertLanternResult(in: app)
        tap("sky.worldMap", in: app); select("ribbonCrossing", in: app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        XCTAssertFalse(app.buttons["world.viewRestored"].exists, "Earned access is not a completed repair")
        let repairedWorld = try worldState(in: app)
        assertOnlyLanternRepair(initialWorld, repaired: repairedWorld)
        tap("world.visit", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Ribbon Crossing")
        XCTAssertTrue(app.buttons["sky.ribbonMode.fallingSky"].isSelected)
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, target: 220_000, in: app)
        exchange(8, 9, in: app); settled(30_000, target: 220_000, in: app)
        let retained = try round(in: app)
        let ribbonRecap = try recap(mode: "Ribbon Crossing · Falling Sky", total: "30,000 points this clear.",
                                   fromMenu: true, capture: "restored-lantern-tablet-foreign-ribbon-recap", in: app)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app); select("firstLight", in: app)
        XCTAssertFalse(app.buttons["world.list"].exists, "AX3XL intentionally uses equivalent Places")
        XCTAssertFalse(app.staticTexts["world.savedProgress"].exists, "The retained Ribbon round must not become Lantern progress")
        XCTAssertFalse(app.buttons["world.resume"].exists)
        XCTAssertEqual(app.buttons["world.visit"].label, "Revisit Lantern Landing")
        let beforeView = try worldState(in: app)
        XCTAssertEqual(beforeView, repairedWorld)
        tap("world.viewRestored", expected: "View restored place", in: app)
        assertViewer(capture: "restored-lantern-tablet-portrait-complete-painting", in: app)
        backgroundAndRestoreViewer(capture: "restored-lantern-tablet-portrait", in: app)
        assertViewer(capture: "restored-lantern-tablet-portrait-background", in: app)
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.width > app.frame.height
        }, object: nil).wait(timeout: 8))
        assertViewer(capture: "restored-lantern-tablet-landscape-complete-painting", in: app)
        tap("world.restored.back", expected: "Back", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertFalse(app.buttons["world.list"].exists)
        XCTAssertEqual(try worldState(in: app), beforeView)
        tap("world.done", in: app); settled(30_000, target: 220_000, in: app)
        XCTAssertEqual(try round(in: app), retained)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.frame.height > app.frame.width
        }, object: nil).wait(timeout: 8))
        settled(30_000, target: 220_000, in: app)
        XCTAssertEqual(try round(in: app), retained)
        XCTAssertEqual(try recap(mode: "Ribbon Crossing · Falling Sky", total: "30,000 points this clear.",
            fromMenu: true, capture: "restored-lantern-tablet-foreign-recap-unchanged", in: app), ribbonRecap)
        _ = setCalm(originalCalm, in: app)
        settled(30_000, target: 220_000, in: app); XCTAssertEqual(try round(in: app), retained)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        settled(30_000, target: 220_000, in: app); XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app); select("firstLight", in: app)
        XCTAssertEqual(try worldState(in: app), beforeView)
        viewRestored(capture: "restored-lantern-tablet-cold-continue-restored-view", in: app)
        tap("world.done", in: app); settled(30_000, target: 220_000, in: app)
        XCTAssertEqual(try round(in: app), retained)
    }
}
