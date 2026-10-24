import XCTest
import UIKit

/// Native components explain earned points without replaying an award. The
/// isolated historical manual fixture below proves unscaled input, not modern
/// random supply or a newly earned campaign entry.
final class ScoreExplanationInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let fourSmall = "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points."
    private let fiveSmallChain = "5 stars · 5 light. 5,000 base + 2,000 size + 7,000 chain = 14,000 points."
    private let fiveSmall = "5 stars · 5 light. 5,000 base + 2,000 size = 7,000 points."
    private let fourWithGrown = "4 stars · 5 light. 5,000 base + 1,000 size = 6,000 points."
    private let manualFive = "5 stars · 5 light = 5 points."

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

    @MainActor private func settled(_ points: Int, target: Int? = nil, showers: Int? = 0,
                                    in app: XCUIApplication) {
        let expected = target.map { "\(points.formatted()) of \($0.formatted()) starlight collected" }
            ?? "\(points.formatted()) starlight"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            return app.staticTexts["experiment.score"].label == expected
                && (showers == nil || board.hasPrefix("\(showers!) showers")) && !board.contains("Stars settling")
                && app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled
        }, object: nil).wait(timeout: 12))
        XCTAssertFalse(app.staticTexts["experiment.outcome"].exists)
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
        // The shipping pause action dismisses its menu. Reopen it to inspect
        // the retained choice, then return to the paused board for play.
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

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
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
        capture("score-explanation-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    /// Terminal prose has no hit action. Its actual smallest owner is clipped
    /// by every enclosing reader; reveal a nested ancestor before its child.
    @MainActor private func readPassive(_ id: String, expected: String, capture name: String,
                                       in app: XCUIApplication) {
        let text = app.staticTexts[id]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertEqual(text.label, expected)
        func viewport(of scroll: XCUIElement?, among owners: [XCUIElement]) -> CGRect {
            var visible = app.frame.intersection(scroll?.frame ?? app.frame)
            if let scroll {
                for ancestor in owners where ancestor.frame != scroll.frame {
                    if ancestor.scrollViews.allElementsBoundByIndex.contains(where: { $0.frame == scroll.frame }) {
                        visible = visible.intersection(ancestor.frame)
                    }
                }
            }
            return visible
        }
        func move(_ target: CGRect, inside visible: CGRect, owner: XCUIElement?) {
            let up = target.maxY > visible.maxY
            let distance = min(visible.height * 0.45,
                               max(24, up ? target.maxY - visible.maxY + 8 : visible.minY - target.minY + 8))
            let containsBoard = owner?.buttons.matching(NSPredicate(
                format: "identifier BEGINSWITH %@", "experiment.cell.")).firstMatch.exists ?? false
            let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                dx: visible.minX - app.frame.minX + visible.width * (containsBoard ? 0.002 : 0.12),
                dy: visible.minY - app.frame.minY + visible.height * (up ? 0.75 : 0.25)))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(.init(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        for attempt in 0...8 {
            let owners = app.scrollViews.containing(.staticText, identifier: id).allElementsBoundByIndex
            let owner = owners.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
            let visible = viewport(of: owner, among: owners)
            if let owner, owners.count > 1,
               visible.isNull || visible.isEmpty || visible.height < min(text.frame.height, owner.frame.height) {
                let ancestor = owners.filter {
                    $0.frame != owner.frame && !viewport(of: $0, among: owners).isEmpty
                        && !viewport(of: $0, among: owners).isNull
                }.min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
                guard attempt < 8, let ancestor else { XCTFail("The result reader must become visible"); return }
                move(owner.frame, inside: viewport(of: ancestor, among: owners), owner: ancestor)
                continue
            }
            XCTAssertFalse(visible.isEmpty || visible.isNull)
            XCTAssertGreaterThan(text.frame.height, 0)
            XCTAssertLessThanOrEqual(text.frame.height, visible.height)
            if visible.insetBy(dx: -1, dy: -1).contains(text.frame) {
                XCTAssertEqual(text.label, expected)
                capture(name, in: app)
                return
            }
            guard attempt < 8 else { XCTFail("A whole score paragraph must fit its actual reader within eight pans"); return }
            move(text.frame, inside: visible, owner: owner)
        }
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
        // Close may be beside the paragraph: only its own viewport and native
        // action readiness matter, not its y position relative to body text.
        XCTAssertTrue(message.isHittable)
        XCTAssertEqual(message.label, expected)
        XCTAssertTrue(app.frame.contains(close.frame) && close.isEnabled && close.isHittable)
        capture(name + "-end", in: app)
        XCTAssertEqual(try round(in: app), retained)
        close.tap(); XCTAssertEqual(try round(in: app), retained)
    }

    @MainActor private func reviewLastScore(_ expected: String, room: String, capture name: String,
                                           in app: XCUIApplication) throws {
        let retained = try round(in: app)
        tap("experiment.settings", in: app); tap("sky.lastClear.menu.open", in: app)
        let title = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "sky.menu.title", "Last clear")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND hittable == true"), object: title).wait(timeout: 5))
        readPassive("sky.lastClear.score.1", expected: expected, capture: name + "-equation", in: app)
        XCTAssertFalse(app.staticTexts["sky.lastClear.phase.2"].exists)
        readPassive("sky.lastClear.room", expected: room, capture: name + "-room", in: app)
        tap("experiment.done", in: app)
        XCTAssertEqual(try round(in: app), retained, "Optional accounting cannot replay or alter the clear")
    }

    @MainActor private func assertResult(score: Int, in app: XCUIApplication) {
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Silver Pools restored!"),
                                                object: outcome).wait(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
            "Sunny. Silver Pools complete! One silver cascade now flows through every pool. \(score.formatted()) of 12,000 starlight collected. Nicely done!")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let replay = app.buttons["experiment.replay"], onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([replay, onward])
        XCTAssertTrue(app.frame.contains(replay.frame) && app.frame.contains(onward.frame))
        XCTAssertTrue(replay.isEnabled && replay.isHittable && onward.isEnabled && onward.isHittable)
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        XCTAssertGreaterThanOrEqual(onward.frame.height, 44)
        XCTAssertEqual(onward.label, "Visit Frostfruit Orchard")
    }

    @MainActor private func replaySilver(opening: RoundState, in app: XCUIApplication) throws {
        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Silver Pools")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Silver Pools opening"))
        XCTAssertFalse(element("score.explanation", in: app).exists)
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, target: 12_000, in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertFalse(element("score.explanation", in: app).exists)
    }

    @MainActor func testNormalSilverPhaseScoresSeparateActionsAndExactReplay() throws {
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
        let visit = app.worldVisitControl("silverPools")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        XCTAssertTrue(initialWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Restore Silver Pools first"))
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 12_000, in: app)
        let opening = try round(in: app)
        XCTAssertFalse(element("score.explanation", in: app).exists)
        exchange(9, 10, in: app)
        capture("score-phone-silver-committed-chain", in: app)
        assertResult(score: 19_000, in: app)
        XCTAssertTrue(element("score.explanation", in: app).exists)
        readPassive("score.phase.1", expected: fourSmall, capture: "score-phone-chain-phase-one-five-thousand", in: app)
        readPassive("score.phase.2", expected: fiveSmallChain, capture: "score-phone-chain-phase-two-fourteen-thousand", in: app)
        readPassive("score.total", expected: "19,000 points this clear.", capture: "score-phone-chain-whole-clear-total", in: app)
        assertResult(score: 19_000, in: app)
        XCUIDevice.shared.press(.home); app.activate()
        assertResult(score: 19_000, in: app)
        XCTAssertEqual(app.staticTexts["score.phase.1"].label, fourSmall)
        XCTAssertEqual(app.staticTexts["score.phase.2"].label, fiveSmallChain)
        let repairedWorld = try world(fromMenu: false, in: app)
        XCTAssertTrue(repairedWorld.contains("world.place.silverPools:Silver Pools:Restored"))
        XCTAssertTrue(repairedWorld.contains("world.place.frostfruitOrchard:Frostfruit Orchard:Ready to restore"))
        func unrelated(_ state: [String]) -> [String] {
            state.filter { !$0.hasPrefix("world.place.silverPools:") && !$0.hasPrefix("world.place.frostfruitOrchard:") }
        }
        XCTAssertEqual(unrelated(repairedWorld), unrelated(initialWorld))
        try replaySilver(opening: opening, in: app)
        exchange(2, 9, in: app); settled(7_000, target: 12_000, in: app)
        let separateGuide = "Pip. Pattern clear · +7,000 points"
        try guide(separateGuide, capture: "score-phone-independent-seven-thousand", in: app)
        try reviewLastScore(fiveSmall,
            room: "5 more spaces above the stars in columns 1, 2, 3, 4, 5. 19 stars on the board after this clear.",
            capture: "score-phone-optional-independent-accounting", in: app)
        exchange(23, 22, in: app)
        capture("score-phone-independent-final-five-thousand", in: app)
        assertResult(score: 12_000, in: app)
        readPassive("score.phase.1", expected: fourSmall, capture: "score-phone-latest-independent-clear", in: app)
        XCTAssertFalse(app.staticTexts["score.phase.2"].exists)
        XCTAssertFalse(app.staticTexts["score.total"].exists, "One phase already contains this clear's exact 5,000-point total")
        assertResult(score: 12_000, in: app)
        XCTAssertEqual(try world(fromMenu: false, in: app), repairedWorld)
        app.terminate(); app.launchArguments = retainedArguments; app.launch(); tap("sky.resume", in: app)
        assertResult(score: 12_000, in: app)
        XCTAssertFalse(element("score.explanation", in: app).exists,
                       "A cold restore cannot reconstruct the previous action's components from aggregate saved score")
        XCTAssertEqual(try world(fromMenu: false, in: app), repairedWorld)
        try replaySilver(opening: opening, in: app)
    }

    @MainActor func testLargestCalmGrownScoreAndUnscaledOpenSkyReadCompletely() throws {
        continueAfterFailure = false
        executionTimeAllowance = 300
        let app = XCUIApplication(); defer { app.terminate() }
        let largest = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review"] + largest
        app.launch()
        let visit = app.worldVisitControl("seedMoon")
        let seedWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(seedWorld.count, 12)
        visit.tap(); tap("sky.begin", in: app); pauseNewSky(in: app)
        settled(0, target: 11_000, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.hasPrefix("Grown Aqua"))
        exchange(4, 3, in: app); settled(6_000, target: 11_000, in: app)
        let grownGuide = "Pip. Pattern clear · +6,000 points"
        try guide(grownGuide, capture: "score-tablet-four-stars-five-light-grown-award", in: app)
        try reviewLastScore(fourWithGrown,
            room: "4 more spaces above the stars in columns 1, 2, 3, 4. 19 stars on the board after this clear.",
            capture: "score-tablet-optional-grown-accounting", in: app)
        let spent = try round(in: app)
        XCTAssertEqual(try world(in: app), seedWorld)
        settled(6_000, target: 11_000, in: app); XCTAssertEqual(try round(in: app), spent)
        exchange(0, 1, in: app); settled(6_000, target: 11_000, in: app)
        XCTAssertNotEqual((try round(in: app)).cells, spent.cells)
        let message = app.staticTexts["experiment.message"]
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        XCTAssertFalse(message.label.contains(fourWithGrown), "A no-award setup replaces the guide, without inventing a new award")
        XCTAssertFalse(element("score.explanation", in: app).exists, "Lasting score components are shown only at an actual ending")
        let prepared = try round(in: app)
        XCUIDevice.shared.press(.home); app.activate()
        settled(6_000, target: 11_000, in: app); XCTAssertEqual(try round(in: app), prepared)
        XCTAssertEqual(try world(in: app), seedWorld)
        // A separate existing reset-only historical fixture supplies the manual
        // contrast. Do not claim continuity of Seed's round or modern supply.
        app.terminate()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--constellation-fixture=horizontalFive"] + largest
        app.launch(); settled(0, showers: nil, in: app)
        _ = setCalm(true, verifyOffToOn: true, in: app)
        let manualWorld = try world(in: app)
        settled(0, showers: nil, in: app)
        let counter = (app.otherElements["experiment.board"].value as? String)?.split(separator: " ").first
        let source = app.buttons["experiment.cell.0.0"], destination = app.buttons["experiment.cell.0.4"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isEnabled && source.isHittable && destination.isEnabled && destination.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.4,
            thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .slow, thenHoldForDuration: 0.45)
        capture("score-tablet-open-sky-real-five-star-trace", in: app)
        settled(5, showers: nil, in: app)
        XCTAssertEqual((app.otherElements["experiment.board"].value as? String)?.split(separator: " ").first, counter)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Twinkle")).count, 0)
        let manualGuide = "Spark. You connected 5! +5 starlight. Only your traced stars cleared. " + manualFive
            + " 5 more spaces above the stars in columns 1, 2, 3, 4, 5."
        try guide(manualGuide, capture: "score-tablet-open-sky-unscaled-five-points", in: app)
        XCTAssertFalse(app.staticTexts["experiment.score"].label.contains("5,000"))
        XCTAssertEqual(try world(in: app), manualWorld, "A manual Open Sky award does not earn a Story repair")
        settled(5, showers: nil, in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
