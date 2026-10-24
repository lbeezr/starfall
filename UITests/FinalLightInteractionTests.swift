import XCTest

/// Final signatures belong to actual in-session earned light. Native input
/// establishes the outcome; captures are reviewed separately for exact art.
final class FinalLightInteractionTests: XCTestCase {
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
        return RoundState(board: board.value as? String,
                          score: app.staticTexts["experiment.score"].label, cells: cells)
    }

    @MainActor private func assertRound(_ expected: RoundState, in app: XCUIApplication) throws {
        let actual = try round(in: app)
        XCTAssertEqual(actual.board, expected.board)
        XCTAssertEqual(actual.score, expected.score)
        XCTAssertEqual(actual.cells, expected.cells)
    }

    @MainActor private func playingScore(_ points: Int, target: Int? = nil, in app: XCUIApplication) {
        let expected = target.map { "\(points.formatted()) of \($0.formatted()) starlight collected" }
            ?? "\(points.formatted()) starlight"
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["experiment.score"].label == expected
                && next.exists && next.isEnabled
                && (app.otherElements["experiment.board"].value as? String)?.contains("Stars settling") == false
        }, object: nil).wait(timeout: 10), "Expected paused score \(expected)")
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        tap("experiment.settings", in: app)
        let pause = app.buttons["experiment.pause"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Start sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5))
        let next = app.buttons["experiment.next"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                                object: next).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
    }

    @MainActor private func signature(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor private func revealPassiveSignature(_ figure: XCUIElement, in app: XCUIApplication) {
        // The shared control helper intentionally requires hittability. This
        // passive figure instead needs complete readable viewport coverage.
        func visibleViewport(of scroll: XCUIElement?, among owners: [XCUIElement]) -> CGRect {
            var viewport = app.frame.intersection(scroll?.frame ?? app.frame)
            if let scroll {
                let selectedFrame = scroll.frame
                for ancestor in owners where ancestor.frame != selectedFrame {
                    // Only an actual enclosing ScrollView clips this owner;
                    // its offscreen child must not clip an outer gesture.
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: {
                        $0.frame == selectedFrame
                    }) {
                        viewport = viewport.intersection(ancestor.frame)
                    }
                }
            }
            guard !viewport.isNull, !viewport.isEmpty else { return viewport }
            if let bar = app.navigationBars.allElementsBoundByIndex.last(where: {
                $0.buttons.allElementsBoundByIndex.contains(where: \.isHittable)
                    || $0.staticTexts.allElementsBoundByIndex.contains(where: \.isHittable)
            }) {
                let top = max(viewport.minY, bar.frame.maxY - 1)
                viewport = CGRect(x: viewport.minX, y: top, width: viewport.width,
                                  height: max(0, viewport.maxY - top))
            }
            return viewport
        }
        func move(_ bounds: CGRect, through viewport: CGRect, owner: XCUIElement?) {
            let up = bounds.maxY > viewport.maxY
            let distance = min(viewport.height * 0.45,
                               max(24, up ? bounds.maxY - viewport.maxY + 8 : viewport.minY - bounds.minY + 8))
            let containsBoard = owner?.buttons.matching(NSPredicate(
                format: "identifier BEGINSWITH %@", "experiment.cell.")).firstMatch.exists ?? true
            // Coordinates come from the visible intersection, never an offscreen
            // portion of a nested ScrollView's full accessibility frame.
            let window = app.frame
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: viewport.minX - window.minX + viewport.width * (containsBoard ? 0.002 : 0.12),
                dy: viewport.minY - window.minY + viewport.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        for attempt in 0...8 {
            // Recompute after every outer or inner gesture: moving an ancestor
            // changes both the nested viewport and the figure's screen frame.
            let owners = app.scrollViews.containing(figure.elementType, identifier: figure.identifier)
                .allElementsBoundByIndex
            let scroll = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            let viewport = visibleViewport(of: scroll, among: owners)
            let bounds = figure.frame
            if owners.count > 1, let scroll,
               viewport.isNull || viewport.isEmpty || viewport.height < min(bounds.height, scroll.frame.height) {
                let nestedFrame = scroll.frame
                let visibleAncestor = owners.filter {
                    let visible = visibleViewport(of: $0, among: owners)
                    return $0.frame != nestedFrame && !visible.isNull && !visible.isEmpty
                }.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                guard attempt < 8, let visibleAncestor else {
                    XCTFail("The passive signature's nested scroll ancestor must become visible within eight gestures")
                    return
                }
                move(nestedFrame, through: visibleViewport(of: visibleAncestor, among: owners), owner: visibleAncestor)
                continue
            }
            if viewport.insetBy(dx: -1, dy: -1).contains(bounds) { return }
            guard attempt < 8, bounds.height <= viewport.height else {
                XCTFail("The complete passive final signature must fit in its actual scroll viewport")
                return
            }
            move(bounds, through: viewport, owner: scroll)
        }
    }

    @MainActor private func assertSignature(_ id: String, capture name: String,
                                          in app: XCUIApplication) -> String {
        let figure = signature(id, in: app)
        XCTAssertTrue(figure.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !figure.frame.isEmpty
        }, object: nil).wait(timeout: 5), "The final signature needs rendered native geometry")
        revealPassiveSignature(figure, in: app)
        XCTAssertEqual(figure.label, "Last earned light")
        XCTAssertGreaterThan(figure.frame.width, 0)
        XCTAssertGreaterThan(figure.frame.height, 0)
        XCTAssertTrue(app.frame.insetBy(dx: -1, dy: -1).contains(figure.frame),
                      "The complete passive final signature must fit in the current viewport")
        // This element deliberately accepts no touch. Do not require hittability.
        capture(name, in: app)
        return figure.label
    }

    @MainActor private func assertNoSignature(_ id: String, in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"),
                                                object: signature(id, in: app)).wait(timeout: 5))
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

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        XCTAssertEqual(source.value as? String, "Automatic pattern play")
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func drawFive(in app: XCUIApplication, lastColumn: Int = 4) {
        let source = app.buttons["experiment.cell.0.0"]
        let destination = app.buttons["experiment.cell.0.\(lastColumn)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.4,
                   thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.45)
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

    @MainActor func testNormalSilverWinSignatureReplayAndColdEndingRestore() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        normalSystemMotion()
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("silverPools")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertTrue(initialWorld.contains("world.place.silverPools:Silver Pools:Ready to restore"))
        XCTAssertTrue(initialWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Restore Silver Pools first"))
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        playingScore(0, target: 12_000, in: app)
        let opening = try round(in: app)
        assertNoSignature("sky.finalLight", in: app)
        exchange(9, 10, in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("19,000 of 12,000 starlight collected"))
        let wonScore = app.staticTexts["experiment.score"].label
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        app.revealSkyControls([app.buttons["experiment.replay"]])
        XCTAssertTrue(app.buttons["experiment.replay"].isEnabled && app.buttons["experiment.replay"].isHittable)
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-silver-earned-final-light", in: app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-silver-background-retained-light", in: app)
        let repairedWorld = try world(in: app, fromMenu: false)
        XCTAssertTrue(repairedWorld.contains("world.place.silverPools:Silver Pools:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Ready to restore"))
        func unrelatedPlaces(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.silverPools:") && !$0.hasPrefix("world.place.frostfruitOrchard:") }
        }
        XCTAssertEqual(unrelatedPlaces(repairedWorld), unrelatedPlaces(initialWorld),
                       "Only the actual Silver repair and its immediate Frostfruit access change")
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-silver-world-return-light", in: app)

        tap("experiment.replay", in: app)
        assertNoSignature("sky.finalLight", in: app)
        tap("sky.begin", in: app); pauseNewSky(in: app)
        playingScore(0, target: 12_000, in: app); try assertRound(opening, in: app)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-phone-silver-exact-replay-no-light", in: app)
        exchange(9, 10, in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, wonScore)
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-silver-second-earned-light", in: app)

        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "Silver Pools restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, wonScore)
        assertNoSignature("sky.finalLight", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: false), repairedWorld)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-phone-silver-cold-ending-no-session-light", in: app)
    }

    @MainActor func testNormalOpenSkyTraceOverflowKeepsLastLightWithoutRepair() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        normalSystemMotion()
        let app = XCUIApplication()
        let retainedArguments = ["--dialogue-review", "-calmEffects", "NO"]
        // The existing reset-only trace fixture starts directly in paused play;
        // DialogueReview isolates its real commits from normal player defaults.
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--constellation-fixture=horizontalFive"]
        app.launch()
        defer { app.terminate() }
        playingScore(0, in: app)
        let initialWorld = try world(in: app, fromMenu: true)
        playingScore(0, in: app)
        drawFive(in: app); playingScore(5, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Twinkle")).count, 0)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-phone-open-sky-real-five-star-clear", in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        var showers = 0
        for _ in 0..<40 {
            if outcome.exists { break }
            playingScore(5, in: app)
            tap("experiment.next", in: app)
            showers += 1
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || app.buttons["experiment.next"].isEnabled
            }, object: nil).wait(timeout: 8))
        }
        XCTAssertGreaterThan(showers, 0)
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(outcome.label, "No room to land")
        let lostScore = app.staticTexts["experiment.score"].label
        XCTAssertTrue(lostScore.contains(" 5 starlight collected."))
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-open-sky-loss-last-earned-light", in: app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-open-sky-loss-background-light", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: false), initialWorld, "An Open Sky loss earns no restoration repair")
        _ = assertSignature("sky.finalLight", capture: "identity09-phone-open-sky-loss-map-return-light", in: app)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        XCTAssertTrue(outcome.waitForExistence(timeout: 10))
        XCTAssertEqual(outcome.label, "No room to land")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, lostScore)
        assertNoSignature("sky.finalLight", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: false), initialWorld)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-phone-open-sky-cold-loss-no-session-light", in: app)
    }

    @MainActor func testLargestCalmPracticeFinalLightRetryAndRetainedRound() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication()
        let retainedArguments = ["--sky-flow-review", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        // No Calm launch argument: this test changes and restores actual Settings.
        app.launchArguments = retainedArguments + ["--starfalls-reset"]
        app.launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        playingScore(0, target: 150_000, in: app)
        exchange(8, 9, in: app); playingScore(15_000, target: 150_000, in: app)
        let retained = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true,
            captureName: "identity09-tablet-actual-calm-off-on", in: app)
        tap("experiment.settings", in: app); tap("sky.learn", in: app)
        tap("tutorial.chapter.trace", in: app)
        XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
        let practiceOpening = try round(in: app)
        XCTAssertEqual(practiceOpening.score, "0 starlight")
        assertNoSignature("tutorial.finalLight", in: app)
        drawFive(in: app)
        let instruction = app.staticTexts["tutorial.instruction"]
        let complete = "Five helpers share light as your drawing returns. One Aqua stays. Retry to choose again."
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", complete),
                                                object: instruction).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "5 starlight")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Aqua")).count, 1)
        _ = assertSignature("tutorial.finalLight", capture: "identity09-tablet-completed-practice-final-light", in: app)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", complete),
                                                object: instruction).wait(timeout: 5))
        _ = assertSignature("tutorial.finalLight", capture: "identity09-tablet-practice-background-final-light", in: app)
        tap("tutorial.retry", in: app)
        assertNoSignature("tutorial.finalLight", in: app)
        try assertRound(practiceOpening, in: app)
        capture("identity09-tablet-practice-retry-no-final-light", in: app)
        drawFive(in: app, lastColumn: 3)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 starlight")
        assertNoSignature("tutorial.finalLight", in: app)
        try assertRound(practiceOpening, in: app)
        tap("experiment.settings", in: app); tap("tutorial.done", in: app)
        playingScore(15_000, target: 150_000, in: app); try assertRound(retained, in: app)
        assertNoSignature("sky.finalLight", in: app)
        XCTAssertEqual(try world(in: app, fromMenu: true), initialWorld)
        playingScore(15_000, target: 150_000, in: app); try assertRound(retained, in: app)
        app.terminate(); app.launchArguments = retainedArguments; app.launch()
        tap("sky.resume", in: app)
        playingScore(15_000, target: 150_000, in: app); try assertRound(retained, in: app)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-tablet-exact-retained-round-after-practice", in: app)
        _ = setCalm(originalCalm, in: app)
    }

    @MainActor func testLargestCalmFullBoardWinFinalLightAndExactReplay() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication()
        // Actual Settings remains writable: no Calm argument-domain override.
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        defer { app.terminate() }
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertEqual(app.buttons["world.place.ribbonCrossing"].value as? String, "Restore Lantern Landing first")
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)

        func waitFullBoard(_ points: Int, exchanges: Int) {
            let board = app.otherElements["experiment.board"]
            let blocked = app.buttons.matching(NSPredicate(
                format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                guard board.exists, let value = board.value as? String else { return false }
                return value.hasPrefix("Exchanges: \(exchanges). Full Board.") && !value.contains("Stars settling")
                    && app.staticTexts["experiment.score"].label == "\(points.formatted()) of 150,000 starlight collected"
                    && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
            }, object: nil).wait(timeout: 12))
            XCTAssertFalse(app.buttons["experiment.next"].exists)
            XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        }
        func readResult(_ element: XCUIElement, captureName: String) {
            XCTAssertTrue(element.waitForExistence(timeout: 5))
            app.revealSkyControls([element])
            XCTAssertFalse(element.frame.isEmpty)
            XCTAssertTrue(app.frame.contains(element.frame), "Each complete result reading block must be reachable")
            capture(captureName, in: app)
        }

        waitFullBoard(0, exchanges: 0)
        let opening = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true,
            captureName: "identity09-tablet-full-board-actual-calm-off-on", in: app)
        // The same complete ten-exchange production witness is independently
        // checked by FullBoardLanternInteractionTests and the Core tests.
        let moves: [(from: Int, to: Int, score: Int)] = [
            (27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000), (12, 13, 63_000),
            (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
            (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)
        ]
        for (index, move) in moves.enumerated() {
            exchange(move.from, move.to, in: app)
            if move.score < 150_000 { waitFullBoard(move.score, exchanges: index + 1) }
        }
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        let score = app.staticTexts["experiment.score"]
        XCTAssertTrue(score.label.contains("156,000 of 150,000 starlight collected"))
        readResult(outcome, captureName: "identity09-tablet-full-board-result-heading")
        readResult(score, captureName: "identity09-tablet-full-board-result-score")

        let rating = app.descendants(matching: .any).matching(identifier: "sky.mastery.result.rating").firstMatch
        XCTAssertTrue(rating.waitForExistence(timeout: 5))
        XCTAssertEqual(rating.label, "3 of 3 stars earned")
        readResult(rating, captureName: "identity09-tablet-full-board-result-rating")
        for name in ["cascade", "largeClear"] {
            let row = app.descendants(matching: .any).matching(identifier: "sky.mastery.result.goal.\(name)").firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            XCTAssertEqual(row.value as? String, "Earned this run")
            XCTAssertTrue(row.label.contains(name == "cascade" ? "gaps refill" : "Clear 8 stars at once"))
            readResult(row, captureName: "identity09-tablet-full-board-result-\(name)")
        }
        let best = app.staticTexts["sky.mastery.result.best"]
        XCTAssertTrue(best.waitForExistence(timeout: 5))
        XCTAssertTrue(best.label.contains("3 of 3 stars from one completed run"))
        readResult(best, captureName: "identity09-tablet-full-board-result-best")
        _ = assertSignature("sky.finalLight", capture: "identity09-tablet-full-board-result-final-light", in: app)

        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Ribbon Crossing")
        for id in ["sky.worldMap", "experiment.new", "experiment.replay", "sky.home"] {
            let control = app.buttons[id]
            app.revealSkyControls([control])
            XCTAssertTrue(control.isEnabled && control.isHittable)
            XCTAssertGreaterThanOrEqual(control.frame.width, 44)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
            XCTAssertTrue(app.frame.contains(control.frame), "Result action \(id) must fit in the actual AX3XL viewport")
            capture("identity09-tablet-full-board-action-" + id, in: app)
        }
        let repairedWorld = try world(in: app, fromMenu: false)
        XCTAssertTrue(repairedWorld.contains("world.place.firstLight:Lantern Landing:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.ribbonCrossing:Ribbon Crossing:Ready to restore"))
        func otherPlaces(_ entries: [String]) -> [String] {
            entries.filter { !$0.hasPrefix("world.place.firstLight:") && !$0.hasPrefix("world.place.ribbonCrossing:") }
        }
        XCTAssertEqual(otherPlaces(repairedWorld), otherPlaces(initialWorld))
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        _ = assertSignature("sky.finalLight", capture: "identity09-tablet-full-board-earned-map-return-light", in: app)
        tap("experiment.replay", in: app)
        assertNoSignature("sky.finalLight", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fallingSky"].exists)
        tap("sky.begin", in: app)
        waitFullBoard(0, exchanges: 0)
        try assertRound(opening, in: app)
        assertNoSignature("sky.finalLight", in: app)
        capture("identity09-tablet-full-board-exact-replay-no-final-light", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
