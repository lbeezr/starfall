import XCTest
import UIKit

/// Actual committed chains supply the survivor facts. Native captures and the
/// coordinator's continuous recording inspect the passive diamonds separately
/// from these outcome, reading, cancellation and persistence assertions.
final class SurvivorIngredientsInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let ribbonGuide = "Spark. 3-clear chain · +30,000 points"
    private let independentGuide = "Pip. Pattern clear · +5,000 points"
    private let lanternGuide = "Spark. 2-clear chain · +15,000 points"
    private let silverFact = "1 survivor fell into a later pattern."

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

    @MainActor private func settled(_ points: Int, target: Int, exchanges: Int? = nil,
                                    in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            let correctCount = exchanges.map { board.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? board.hasPrefix("0 showers")
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of \(target.formatted()) starlight collected"
                && correctCount && !board.contains("Stars settling")
                && app.buttons["experiment.cell.0.0"].isEnabled
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
        if exchanges != nil { XCTAssertFalse(app.buttons["experiment.next"].exists) }
    }

    @MainActor private func pauseNewSky(in app: XCUIApplication) {
        // Freeze the live clock as soon as the fixed HUD menu is admitted.
        // Generic scroll discovery can consume this opening's six-second sky.
        let menu = app.buttons["experiment.settings"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true AND hittable == true"), object: menu).wait(timeout: 5))
        XCTAssertTrue(app.frame.contains(menu.frame))
        menu.tap()
        let pause = app.buttons["experiment.pause"]
        app.revealSkyControls([pause])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "label == %@ AND enabled == true AND hittable == true", "Pause sky"),
            object: pause).wait(timeout: 5))
        pause.tap()
        // Pause dismisses the production menu; inspect its retained choice
        // through a new menu visit before returning to the paused board.
        tap("experiment.settings", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Start sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5),
            "Expected untouched opening: board=\(app.otherElements["experiment.board"].value as? String ?? "unavailable"), pause=\(app.buttons["experiment.pause"].label)")
        tap("experiment.done", in: app)
        let next = app.buttons["experiment.next"]
        app.revealSkyControls([next])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "enabled == true AND hittable == true"), object: next).wait(timeout: 5))
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("0 showers") == true)
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
        // Capture before accessibility/settlement reads consume the live return.
        // No duration threshold is inferred from this screenshot's timing.
        capture(name, in: app)
    }

    @MainActor private func world(fromMenu: Bool = true, in app: XCUIApplication) throws -> [String] {
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
        func select(_ value: String) {
            if calm.value as? String != value { calm.tap() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value),
                                                    object: calm).wait(timeout: 5))
            XCTAssertEqual(calm.value as? String, value)
        }
        if enabled && verifyOffToOn { select("0") }
        select(enabled ? "1" : "0")
        capture("survivor-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor private func guide(_ expected: String, capture name: String,
                                 in app: XCUIApplication) throws {
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected),
                                                object: message).wait(timeout: 5))
        let retained = try round(in: app)
        let close = app.buttons["sky.dialogue.close"]
        app.revealSkyControls([close])
        let reader = app.scrollViews["sky.dialogue.reading"]
        if reader.exists {
            for _ in 0..<8 where message.frame.minY < app.frame.intersection(reader.frame).minY - 1 { reader.swipeDown() }
            let visible = app.frame.intersection(reader.frame)
            XCTAssertFalse(visible.isEmpty)
            XCTAssertGreaterThanOrEqual(message.frame.minY, visible.minY - 1)
            XCTAssertLessThan(message.frame.minY, visible.maxY)
        } else { app.revealSkyControls([message]); XCTAssertTrue(app.frame.contains(message.frame)) }
        capture(name + "-start", in: app)
        if reader.exists {
            var readThrough = min(message.frame.height, app.frame.intersection(reader.frame).maxY - message.frame.minY)
            for attempt in 0..<8 {
                let visible = app.frame.intersection(reader.frame)
                if message.frame.maxY <= visible.maxY + 1 { break }
                let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                    dx: visible.minX - app.frame.minX + visible.width * 0.15,
                    dy: visible.minY - app.frame.minY + visible.height * 0.75))
                start.press(forDuration: 0.05,
                            thenDragTo: start.withOffset(.init(dx: 0, dy: -visible.height * 0.45)),
                            withVelocity: .slow, thenHoldForDuration: 0.1)
                let next = app.frame.intersection(reader.frame)
                XCTAssertLessThanOrEqual(max(0, next.minY - message.frame.minY), readThrough + 1)
                readThrough = max(readThrough, min(message.frame.height, next.maxY - message.frame.minY))
                capture(name + "-reading-\(attempt + 1)", in: app)
            }
            let visible = app.frame.intersection(reader.frame)
            XCTAssertLessThanOrEqual(message.frame.maxY, visible.maxY + 1)
            XCTAssertGreaterThan(message.frame.maxY, visible.minY)
            XCTAssertGreaterThanOrEqual(readThrough, message.frame.height - 1)
            if message.frame.height <= visible.height { XCTAssertTrue(visible.insetBy(dx: -1, dy: -1).contains(message.frame)) }
        } else { XCTAssertTrue(app.frame.contains(message.frame)) }
        XCTAssertTrue(message.isHittable)
        XCTAssertEqual(message.label, expected)
        XCTAssertTrue(app.frame.contains(close.frame) && close.isEnabled && close.isHittable)
        capture(name + "-end", in: app)
        XCTAssertEqual(try round(in: app), retained)
        close.tap(); XCTAssertEqual(try round(in: app), retained)
    }

    @MainActor private func reviewLastClear(scores: [String], total: String, survivors: String?,
                                          refills: Int, capture name: String,
                                          in app: XCUIApplication) throws {
        let retained = try round(in: app)
        tap("experiment.settings", in: app); tap("sky.lastClear.menu.open", in: app)
        let title = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "sky.menu.title", "Last clear")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND hittable == true"), object: title).wait(timeout: 5))
        var facts = scores.enumerated().map { ("sky.lastClear.score.\($0.offset + 1)", $0.element) }
        facts.append(("sky.lastClear.total", total))
        if let survivors { facts.append(("sky.lastClear.survivors", survivors)) }
        else { XCTAssertFalse(app.staticTexts["sky.lastClear.survivors"].exists) }
        facts.append(("sky.lastClear.room", "Refill added \(refills) stars. 49 stars on the board after this clear."))
        for (id, expected) in facts {
            let fact = app.staticTexts[id]
            app.revealSkyMenuElement(fact); app.revealSkyControls([fact])
            XCTAssertEqual(fact.label, expected)
            XCTAssertTrue(app.frame.contains(fact.frame) && fact.isHittable)
            capture(name + "-" + id, in: app)
        }
        XCTAssertFalse(app.staticTexts["sky.lastClear.phase.\(scores.count + 1)"].exists)
        tap("experiment.done", in: app)
        XCTAssertEqual(try round(in: app), retained, "Reading exact survivors and accounting cannot replay the chain")
    }

    @MainActor private func readTerminalFact(in app: XCUIApplication) {
        let fact = app.staticTexts["score.survivors"]
        XCTAssertTrue(fact.waitForExistence(timeout: 5))
        XCTAssertEqual(fact.label, silverFact)
        for attempt in 0...8 {
            let owners = app.scrollViews.containing(.staticText, identifier: fact.identifier).allElementsBoundByIndex
            let owner = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            var visible = app.frame.intersection(owner?.frame ?? app.frame)
            if let owner {
                for ancestor in owners where ancestor.frame != owner.frame {
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == owner.frame }) {
                        visible = visible.intersection(ancestor.frame)
                    }
                }
            }
            XCTAssertFalse(visible.isNull || visible.isEmpty)
            XCTAssertGreaterThan(fact.frame.height, 0)
            XCTAssertLessThanOrEqual(fact.frame.height, visible.height)
            if visible.insetBy(dx: -1, dy: -1).contains(fact.frame) {
                capture("survivor-phone-silver-terminal-fact-only", in: app)
                XCTAssertFalse(fact.label.contains("Diamond marks"))
                return
            }
            guard attempt < 8 else { XCTFail("The complete terminal survivor fact must be readable"); return }
            let up = fact.frame.maxY > visible.maxY
            let distance = min(visible.height * 0.45,
                               max(24, up ? fact.frame.maxY - visible.maxY + 8 : visible.minY - fact.frame.minY + 8))
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * 0.12,
                dy: visible.minY - app.frame.minY + visible.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
    }

    @MainActor private func assertSilverResult(in app: XCUIApplication) {
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Silver Pools restored!"),
                                                object: outcome).wait(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
            "Sunny. Silver Pools complete! One silver cascade now flows through every pool. 19,000 of 12,000 starlight collected. Nicely done!")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let replay = app.buttons["experiment.replay"], onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([replay, onward])
        XCTAssertTrue(app.frame.contains(replay.frame) && app.frame.contains(onward.frame))
        XCTAssertTrue(replay.isEnabled && replay.isHittable && onward.isEnabled && onward.isHittable)
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        XCTAssertGreaterThanOrEqual(onward.frame.height, 44)
        XCTAssertEqual(onward.label, "Visit Frostfruit Orchard")
    }

    @MainActor func testNormalRibbonSurvivorsSeparateActionAndSilverTerminalCancellation() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        if UIAccessibility.isReduceMotionEnabled {
            let (settings, reduce) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(false, on: reduce); settings.terminate()
            addTeardownBlock { @MainActor in
                let (settings, reduce) = NativeSystemMotionSettings.open()
                NativeSystemMotionSettings.set(true, on: reduce); settings.terminate()
            }
        }
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled, "This journey requires actual normal system motion")
        let app = XCUIApplication(); defer { app.terminate() }
        let retainedArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        app.launchArguments = retainedArguments + ["--starfalls-reset", "--world-legacy-review"]
        app.launch()
        // Existing-install access admits Ribbon/Silver; it does not invent an
        // earned preceding campaign in this isolated presentation journey.
        let visit = app.worldVisitControl("ribbonCrossing")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.ribbonMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 220_000, exchanges: 0, in: app)
        let opening = try round(in: app)
        exchange(8, 9, capture: "survivor-phone-ribbon-three-actual-phases", in: app)
        settled(30_000, target: 220_000, exchanges: 1, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 49)
        try guide(ribbonGuide, capture: "survivor-phone-ribbon-four-causal-movers", in: app)
        try reviewLastClear(scores: ["4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points.",
            "4 stars · 4 light. 4,000 base + 1,000 size + 5,000 chain = 10,000 points.",
            "4 stars · 4 light. 4,000 base + 1,000 size + 10,000 chain = 15,000 points."],
            total: "30,000 points this clear.", survivors: "4 survivors fell into later patterns.",
            refills: 12, capture: "survivor-phone-optional-ribbon-exact", in: app)
        exchange(11, 12, capture: "survivor-phone-independent-following-clear", in: app)
        settled(35_000, target: 220_000, exchanges: 2, in: app)
        try guide(independentGuide, capture: "survivor-phone-independent-action-no-old-causal-claim", in: app)
        try reviewLastClear(scores: ["4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points."],
            total: "5,000 points this clear.", survivors: nil, refills: 4,
            capture: "survivor-phone-optional-independent-exact", in: app)
        let retained = try round(in: app)
        tap("experiment.settings", in: app); XCUIDevice.shared.press(.home); app.activate(); tap("experiment.done", in: app)
        settled(35_000, target: 220_000, exchanges: 2, in: app)
        XCTAssertEqual(try round(in: app), retained)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        settled(35_000, target: 220_000, exchanges: 2, in: app)
        XCTAssertEqual(try round(in: app), retained)
        XCTAssertEqual(try world(in: app), initialWorld)
        tap("experiment.settings", in: app); tap("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.begin", in: app); settled(0, target: 220_000, exchanges: 0, in: app)
        XCTAssertEqual(try round(in: app), opening)
        capture("survivor-phone-ribbon-exact-replay", in: app)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        app.worldVisitControl("silverPools").tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 12_000, in: app)
        let silverOpening = try round(in: app)
        exchange(9, 10, capture: "survivor-phone-silver-two-phase-terminal-handoff", in: app)
        assertSilverResult(in: app)
        readTerminalFact(in: app)
        assertSilverResult(in: app)
        XCUIDevice.shared.press(.home); app.activate()
        assertSilverResult(in: app)
        XCTAssertEqual(app.staticTexts["score.survivors"].label, silverFact)
        let repairedWorld = try world(fromMenu: false, in: app)
        XCTAssertTrue(repairedWorld.contains("world.place.silverPools:Silver Pools:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Ready to restore"))
        func unrelated(_ states: [String]) -> [String] {
            states.filter { !$0.hasPrefix("world.place.silverPools:") && !$0.hasPrefix("world.place.frostfruitOrchard:") }
        }
        XCTAssertEqual(unrelated(repairedWorld), unrelated(initialWorld))
        XCTAssertEqual(app.staticTexts["score.survivors"].label, silverFact)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        assertSilverResult(in: app)
        XCTAssertFalse(element("score.explanation", in: app).exists)
        XCTAssertFalse(app.staticTexts["score.survivors"].exists)
        capture("survivor-phone-cold-ending-no-invented-receipt", in: app)
        XCTAssertEqual(try world(fromMenu: false, in: app), repairedWorld)
        tap("experiment.replay", in: app); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 12_000, in: app)
        XCTAssertEqual(try round(in: app), silverOpening)
        XCTAssertFalse(element("score.explanation", in: app).exists)
        XCTAssertFalse(app.staticTexts["score.survivors"].exists)
        capture("survivor-phone-silver-exact-replay-clears-receipt", in: app)
    }

    @MainActor func testLargestCalmSurvivorsAndSimultaneousPatternsPreserveRound() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication(); defer { app.terminate() }
        let retainedArguments = ["--sky-flow-review", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        // No Calm argument-domain override: the actual preference is mutable.
        app.launchArguments = retainedArguments + ["--starfalls-reset"]
        app.launch()
        let visit = app.worldVisitControl("firstLight")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        let opening = try round(in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        exchange(8, 9, capture: "survivor-tablet-two-phase-current-lantern-diamonds", in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        try guide(lanternGuide, capture: "survivor-tablet-two-causal-movers-full-guide", in: app)
        try reviewLastClear(scores: ["4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points.",
            "4 stars · 4 light. 4,000 base + 1,000 size + 5,000 chain = 10,000 points."],
            total: "15,000 points this clear.", survivors: "2 survivors fell into later patterns.",
            refills: 8, capture: "survivor-tablet-optional-lantern-exact", in: app)
        let retained = try round(in: app)
        tap("experiment.settings", in: app); tap("fullBoard.choices.open", in: app); tap("fullBoard.choices.practice", in: app)
        let title = app.staticTexts["tutorial.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Keep a follow-up")
        let comparisonOpening = try round(in: app)
        // The shipping comparison retains revision5. It uses production receipt
        // geometry, while its own chapter instruction replaces the Story guide.
        exchange(3, 10, capture: "survivor-tablet-historical-square-then-survivor-line", in: app)
        settled(81_000, target: 150_000, exchanges: 3, in: app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("15,000"))
        tap("tutorial.next", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Compare the larger clear"),
                                                object: title).wait(timeout: 10))
        XCTAssertEqual(try round(in: app), comparisonOpening)
        exchange(8, 15, capture: "survivor-tablet-one-phase-two-disjoint-squares", in: app)
        settled(79_000, target: 150_000, exchanges: 3, in: app)
        let instruction = app.staticTexts["tutorial.instruction"], finish = app.buttons["tutorial.finish"]
        XCTAssertTrue(instruction.label.contains("13,000"))
        app.revealSkyControls([instruction, finish])
        XCTAssertTrue(app.frame.contains(instruction.frame))
        XCTAssertTrue(app.frame.contains(finish.frame) && finish.isEnabled && finish.isHittable)
        capture("survivor-tablet-simultaneous-choice-reading", in: app)
        finish.tap()
        XCTAssertFalse(title.exists)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); XCUIDevice.shared.press(.home); app.activate(); tap("experiment.done", in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), retained)
        XCTAssertEqual(try world(in: app), initialWorld)
        tap("experiment.settings", in: app); tap("experiment.replay", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertFalse(element("score.explanation", in: app).exists)
        XCTAssertFalse(app.staticTexts["score.survivors"].exists)
        capture("survivor-tablet-current-full-board-exact-replay", in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
