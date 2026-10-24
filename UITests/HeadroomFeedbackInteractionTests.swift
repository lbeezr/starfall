import XCTest
import UIKit

/// Concise live reactions retain exact room/refill facts in Last clear. All boards, showers
/// and rewards below come from ordinary current-definition native input.
final class HeadroomFeedbackInteractionTests: XCTestCase {
    private struct RoundState: Equatable {
        let board: String?
        let score: String
        let cells: [String]
    }

    private let highGuide = "Pip. Pattern clear · +5,000 points"
    private let lowGuide = "Pip. Pattern clear · +7,000 points"
    private let recoveryGuide = "Pip. Pattern clear · +5,000 points"
    private let refillGuide = "Spark. 2-clear chain · +15,000 points"

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

    @MainActor private func settled(_ points: Int, target: Int = 17_000, showers: Int = 0,
                                    exchanges: Int? = nil, in app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let board = app.otherElements["experiment.board"].value as? String ?? ""
            let correctCount = exchanges.map { board.hasPrefix("Exchanges: \($0). Full Board.") }
                ?? board.hasPrefix("\(showers) showers")
            return app.staticTexts["experiment.score"].label == "\(points.formatted()) of \(target.formatted()) starlight collected"
                && correctCount && !board.contains("Stars settling")
                && app.buttons["experiment.cell.0.0"].isEnabled
                && (exchanges != nil || (app.buttons["experiment.next"].exists && app.buttons["experiment.next"].isEnabled))
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

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(source.isEnabled && source.isHittable && target.isEnabled && target.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func forecast(in app: XCUIApplication) -> String {
        let row = app.descendants(matching: .any).matching(identifier: "sky.forecast.destinations").firstMatch
        XCTAssertTrue(row.exists)
        XCTAssertEqual(row.label, "Next columns")
        let value = row.value as? String ?? ""
        XCTAssertEqual(value.components(separatedBy: ", then ").count, 5)
        return value
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
            for _ in 0..<4 where message.frame.minY < app.frame.intersection(reader.frame).minY - 1 {
                reader.swipeDown()
            }
            let visible = app.frame.intersection(reader.frame)
            XCTAssertFalse(visible.isEmpty)
            XCTAssertGreaterThanOrEqual(message.frame.minY, visible.minY - 1)
            XCTAssertLessThan(message.frame.minY, visible.maxY)
        } else {
            app.revealSkyControls([message])
            XCTAssertTrue(app.frame.contains(message.frame))
        }
        capture(name + "-start", in: app)
        // Close sits beside the ordinary reader and below the AX3XL reader.
        // Its vertical position must not stand in for the actual text viewport.
        if reader.exists {
            var readThrough = min(message.frame.height,
                                  app.frame.intersection(reader.frame).maxY - message.frame.minY)
            for attempt in 0..<4 {
                let visible = app.frame.intersection(reader.frame)
                if message.frame.maxY <= visible.maxY + 1 { break }
                let distance = visible.height * 0.45
                let start = app.coordinate(withNormalizedOffset: .zero).withOffset(.init(
                    dx: visible.minX - app.frame.minX + visible.width * 0.15,
                    dy: visible.minY - app.frame.minY + visible.height * 0.75))
                start.press(forDuration: 0.05,
                            thenDragTo: start.withOffset(.init(dx: 0, dy: -distance)),
                            withVelocity: .slow, thenHoldForDuration: 0.1)
                let nextVisible = app.frame.intersection(reader.frame)
                XCTAssertLessThanOrEqual(max(0, nextVisible.minY - message.frame.minY), readThrough + 1,
                                         "Reading pans must overlap without skipping body text")
                readThrough = max(readThrough, min(message.frame.height, nextVisible.maxY - message.frame.minY))
                capture(name + "-reading-\(attempt + 1)", in: app)
            }
            let visible = app.frame.intersection(reader.frame)
            XCTAssertLessThanOrEqual(message.frame.maxY, visible.maxY + 1)
            XCTAssertGreaterThan(message.frame.maxY, visible.minY)
            XCTAssertGreaterThanOrEqual(readThrough, message.frame.height - 1)
            if message.frame.height <= visible.height {
                XCTAssertTrue(visible.insetBy(dx: -1, dy: -1).contains(message.frame))
            }
        } else { XCTAssertTrue(app.frame.contains(message.frame)) }
        XCTAssertTrue(message.isHittable)
        XCTAssertEqual(message.label, expected)
        XCTAssertTrue(app.frame.contains(close.frame))
        XCTAssertTrue(close.isEnabled && close.isHittable)
        capture(name + "-end", in: app)
        XCTAssertEqual(try round(in: app), retained)
        close.tap()
        XCTAssertEqual(try round(in: app), retained)
    }

    @MainActor private func noStaleRoomClaim(requireMessage: Bool = false, in app: XCUIApplication) {
        let message = app.staticTexts["experiment.message"]
        if requireMessage { XCTAssertTrue(message.waitForExistence(timeout: 5)) }
        if message.exists {
            XCTAssertFalse(message.label.contains("more spaces above the stars"))
            XCTAssertFalse(message.label.contains("has room again"))
            XCTAssertFalse(message.label.contains("Refill added"))
        }
    }

    @MainActor private func world(in app: XCUIApplication) throws -> [String] {
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" { tap("world.list", in: app) }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        let result = try identities(app, prefix: "world.place.")
        XCTAssertEqual(result.count, 12)
        tap("world.done", in: app)
        return result
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
        capture("headroom-tablet-actual-calm-" + (enabled ? "on" : "off"), in: app)
        tap("experiment.done", in: app)
        return original
    }

    @MainActor private func launchKite(largest: Bool, in app: XCUIApplication) throws -> [String] {
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review"]
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        } else { app.launchArguments += ["-calmEffects", "NO"] }
        app.launch()
        // Legacy access supplies entry, not a claimed earlier campaign win.
        let visit = app.worldVisitControl("kiteHarbor")
        let initialWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(initialWorld.count, 12)
        visit.tap(); XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("17,000 starlight"))
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, in: app)
        return initialWorld
    }

    @MainActor private func reviewRoom(_ expected: String, capture name: String,
                                      in app: XCUIApplication) throws {
        let retained = try round(in: app)
        tap("experiment.settings", in: app); tap("sky.lastClear.menu.open", in: app)
        let title = app.staticTexts.matching(NSPredicate(
            format: "identifier == %@ AND label == %@", "sky.menu.title", "Last clear")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(
            format: "exists == true AND hittable == true"), object: title).wait(timeout: 5))
        let room = app.staticTexts["sky.lastClear.room"]
        app.revealSkyMenuElement(room); app.revealSkyControls([room])
        XCTAssertEqual(room.label, expected)
        XCTAssertTrue(app.frame.contains(room.frame) && room.isHittable)
        capture(name, in: app)
        tap("experiment.done", in: app)
        XCTAssertEqual(try round(in: app), retained, "Reading room/refills cannot change the committed round")
    }

    @MainActor private func replayKite(in app: XCUIApplication, fromEnding: Bool = false) {
        if !fromEnding { tap("experiment.settings", in: app) }
        tap("experiment.replay", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Kite Harbor")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Kite Harbor opening"))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("17,000 starlight"))
        tap("sky.begin", in: app); pauseNewSky(in: app); settled(0, in: app)
    }

    @MainActor func testNormalKiteHeadroomChoicesRecoverAndFinishWithExactReplay() throws {
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
        let initialWorld = try launchKite(largest: false, in: app)
        let opening = try round(in: app), announced = forecast(in: app)
        exchange(15, 14, in: app); settled(5_000, in: app)
        XCTAssertEqual(forecast(in: app), announced)
        try guide(highGuide, capture: "headroom-phone-high-column-four-spaces", in: app)
        try reviewRoom("4 more spaces above the stars in column 1. 20 stars on the board after this clear.",
            capture: "headroom-phone-optional-high-column", in: app)
        let high = try round(in: app)
        XCTAssertEqual(try world(in: app), initialWorld)
        settled(5_000, in: app); XCTAssertEqual(try round(in: app), high)
        XCUIDevice.shared.press(.home); app.activate()
        settled(5_000, in: app); XCTAssertEqual(try round(in: app), high)
        app.terminate(); app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        app.launch(); tap("sky.resume", in: app)
        settled(5_000, in: app); XCTAssertEqual(try round(in: app), high)
        noStaleRoomClaim(in: app)
        replayKite(in: app)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertEqual(forecast(in: app), announced)
        exchange(4, 11, in: app); settled(7_000, in: app)
        XCTAssertEqual(forecast(in: app), announced)
        try guide(lowGuide, capture: "headroom-phone-low-five-spaces", in: app)
        try reviewRoom("5 more spaces above the stars in columns 3, 4, 5, 6, 7. 19 stars on the board after this clear.",
            capture: "headroom-phone-optional-low-columns", in: app)
        tap("experiment.next", in: app); settled(7_000, showers: 1, in: app)
        noStaleRoomClaim(in: app)
        let pressure = app.staticTexts["sky.pressure"]
        XCTAssertEqual(pressure.label, "Columns 1, 2 are full.")
        let nextAnnounced = forecast(in: app)
        exchange(15, 14, in: app); settled(12_000, showers: 1, in: app)
        XCTAssertEqual(forecast(in: app), nextAnnounced)
        try guide(recoveryGuide, capture: "headroom-phone-real-full-column-recovery", in: app)
        XCTAssertEqual(pressure.label, "Column 2 is full.")
        try reviewRoom("4 more spaces above the stars in column 1. 19 stars on the board after this clear.",
            capture: "headroom-phone-optional-recovered-column", in: app)
        // The existing points-first route has four non-clearing setup moves;
        // none may retain the previous clear's room claim.
        for (from, to) in [(36, 29), (29, 22), (4, 3), (3, 2)] {
            let before = try round(in: app)
            exchange(from, to, in: app); settled(12_000, showers: 1, in: app)
            XCTAssertNotEqual((try round(in: app)).cells, before.cells)
            XCTAssertEqual(forecast(in: app), nextAnnounced)
            noStaleRoomClaim(requireMessage: true, in: app)
        }
        capture("headroom-phone-following-setup-without-stale-claim", in: app)
        exchange(2, 1, in: app)
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Kite Harbor restored!"),
                                                object: outcome).wait(timeout: 10))
        // The result combines its earned score with the existing ceremony text;
        // its native label differs from the in-play score instrument.
        XCTAssertEqual(app.staticTexts["experiment.score"].label,
                       "Sunny. Kite Harbor complete! The fleet is aloft and ready to depart. 18,000 of 17,000 starlight collected. Nicely done!")
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        let replay = app.buttons["experiment.replay"], onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([replay, onward])
        XCTAssertTrue(app.frame.contains(replay.frame) && app.frame.contains(onward.frame))
        XCTAssertTrue(replay.isEnabled && replay.isHittable && onward.isEnabled && onward.isHittable)
        XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        XCTAssertEqual(onward.label, "Visit Seed Moon")
        capture("headroom-phone-immediate-earned-result", in: app)
        tap("sky.worldMap", in: app)
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" { tap("world.list", in: app) }
        XCTAssertTrue(app.buttons["world.place.kiteHarbor"].waitForExistence(timeout: 5))
        let completedWorld = try identities(app, prefix: "world.place.")
        XCTAssertEqual(completedWorld.count, 12)
        XCTAssertEqual(app.buttons["world.place.kiteHarbor"].value as? String, "Restored")
        XCTAssertEqual(completedWorld.filter { !$0.hasPrefix("world.place.kiteHarbor:") },
                       initialWorld.filter { !$0.hasPrefix("world.place.kiteHarbor:") })
        tap("world.done", in: app)
        replayKite(in: app, fromEnding: true)
        XCTAssertEqual(try round(in: app), opening)
        XCTAssertEqual(forecast(in: app), announced)
        noStaleRoomClaim(in: app)
    }

    @MainActor func testLargestCalmHeadroomAndFullBoardRefillReadCompletely() throws {
        continueAfterFailure = false
        executionTimeAllowance = 240
        let app = XCUIApplication(); defer { app.terminate() }
        let initialWorld = try launchKite(largest: true, in: app)
        let originalCalm = setCalm(true, verifyOffToOn: true, in: app)
        let announced = forecast(in: app)
        exchange(4, 11, in: app); settled(7_000, in: app)
        XCTAssertEqual(forecast(in: app), announced)
        try guide(lowGuide, capture: "headroom-tablet-low-clear-full-guide", in: app)
        try reviewRoom("5 more spaces above the stars in columns 3, 4, 5, 6, 7. 19 stars on the board after this clear.",
            capture: "headroom-tablet-optional-low-columns", in: app)
        let retained = try round(in: app)
        XCTAssertEqual(try world(in: app), initialWorld)
        settled(7_000, in: app); XCTAssertEqual(try round(in: app), retained)
        tap("experiment.settings", in: app); tap("sky.worldMap", in: app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", in: app); tap("sky.begin", in: app)
        settled(0, target: 150_000, exchanges: 0, in: app)
        XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Full Board · clears refill and cascade")
        exchange(8, 9, in: app); settled(15_000, target: 150_000, exchanges: 1, in: app)
        try guide(refillGuide, capture: "headroom-tablet-full-board-refilled-eight-stars", in: app)
        try reviewRoom("Refill added 8 stars. 49 stars on the board after this clear.",
            capture: "headroom-tablet-optional-full-board-refills", in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 49)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sky.pressure").firstMatch.exists)
        let refilled = try round(in: app)
        XCUIDevice.shared.press(.home); app.activate()
        settled(15_000, target: 150_000, exchanges: 1, in: app)
        XCTAssertEqual(try round(in: app), refilled)
        exchange(0, 1, in: app); settled(30_000, target: 150_000, exchanges: 2, in: app)
        capture("headroom-tablet-following-real-full-board-clear", in: app)
        XCTAssertEqual(try world(in: app), initialWorld)
        settled(30_000, target: 150_000, exchanges: 2, in: app)
        _ = setCalm(originalCalm, in: app)
    }
}
