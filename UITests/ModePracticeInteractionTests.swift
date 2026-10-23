import XCTest
import UIKit

final class ModePracticeInteractionTests: XCTestCase {
    @MainActor private func requireNormalMotion() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        preferences.terminate()
        addTeardownBlock { @MainActor in
            let (settings, toggle) = NativeSystemMotionSettings.open()
            NativeSystemMotionSettings.set(original, on: toggle)
            settings.terminate()
        }
    }

    @MainActor private func launch(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--sky-flow-review", "--starfalls-reset", "-calmEffects", quiet ? "YES" : "NO"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let control = app.buttons[id]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND enabled == true AND hittable == true"),
                                                object: control).wait(timeout: 5), id)
        control.tap()
    }

    @MainActor private func drag(_ from: Int, _ to: Int, _ app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(source.isEnabled && target.isEnabled)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func score(_ value: Int, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "\(value.formatted()) of 150,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 10))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"),
                                                object: app.buttons["experiment.cell.0.0"]).wait(timeout: 10))
    }

    @MainActor private func cells(_ app: XCUIApplication) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button, node.identifier.hasPrefix("experiment.cell.") {
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try app.otherElements["experiment.board"].snapshot())
        XCTAssertEqual(result.count, 49)
        return result.sorted()
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func practice(_ full: Bool, _ app: XCUIApplication, prefix: String, fromEntry: Bool = true) throws {
        tap("sky.practiceMode", app)
        XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["tutorial.title"].label.contains(full ? "Full Board" : "Falling Sky"))
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCTAssertFalse(app.staticTexts["tutorial.coordinates"].exists)
        XCTAssertFalse(app.buttons["sky.begin"].exists && app.buttons["sky.begin"].isHittable)
        if !app.launchArguments.contains("UICTContentSizeCategoryAccessibilityXXXL") {
            let ceiling = app.descendants(matching: .any).matching(identifier: "sky.ceiling").firstMatch
            XCTAssertTrue(app.frame.contains(ceiling.frame))
            XCTAssertGreaterThanOrEqual(ceiling.frame.minY, app.otherElements["sky.header"].frame.maxY)
        }
        let opening = try cells(app)
        tap("tutorial.hint", app)
        XCTAssertTrue(app.staticTexts["tutorial.coordinates"].exists)
        capture(prefix + "-hint", app)
        tap("tutorial.retry", app)
        XCTAssertEqual(try cells(app), opening)
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCUIDevice.shared.press(.home); app.activate()
        if full {
            drag(8, 9, app); score(15_000, app)
            let blocked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in blocked.count == 0 }, object: nil).wait(timeout: 10),
                          "Inspect the refill after every column has finished presenting")
            XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("49"))
            XCTAssertFalse(try cells(app).contains { $0.contains(":Empty,") })
            XCTAssertFalse(app.buttons["experiment.next"].exists)
        } else {
            drag(1, 2, app); score(5_000, app)
            tap("experiment.next", app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "next shower fit"),
                                                    object: app.staticTexts["tutorial.instruction"]).wait(timeout: 10))
        }
        capture(prefix + "-complete", app)
        tap("experiment.settings", app)
        if fromEntry {
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons[full ? "sky.lanternMode.fullBoard" : "sky.lanternMode.fallingSky"].isSelected)
        } else {
            XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.staticTexts["tutorial.title"].exists)
        }
    }

    @MainActor func testBothEntryDiscoveriesPreserveSelectedModeAndRetainedFullBoard() throws {
        executionTimeAllowance = 360
        requireNormalMotion()
        let app = launch()
        defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", app); tap("sky.begin", app)
        score(0, app); drag(8, 9, app); score(15_000, app)
        let saved = try cells(app), summary = app.otherElements["experiment.board"].value as? String
        tap("experiment.settings", app); tap("sky.worldMap", app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", app)
        try practice(true, app, prefix: "mode-practice-full-default")
        tap("sky.lanternMode.fallingSky", app)
        try practice(false, app, prefix: "mode-practice-sky-default")
        tap("sky.home", app); tap("world.done", app)
        score(15_000, app)
        XCTAssertEqual(try cells(app), saved)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, summary)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
    }

    @MainActor func testLargestTextEntryDiscoveriesRetainPausedFallingSky() throws {
        executionTimeAllowance = 360
        let app = launch(largest: true, quiet: true)
        defer { app.terminate() }
        app.worldVisitControl("firstLight").tap(); tap("sky.begin", app)
        tap("experiment.settings", app); tap("experiment.pause", app)
        let saved = try cells(app), summary = app.otherElements["experiment.board"].value as? String
        tap("experiment.settings", app); tap("experiment.help", app)
        try practice(false, app, prefix: "mode-practice-help-largest", fromEntry: false)
        XCTAssertEqual(try cells(app), saved)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, summary)
        XCTAssertTrue(app.buttons["experiment.next"].isEnabled)
        tap("experiment.settings", app); tap("sky.worldMap", app)
        app.worldVisitControl("firstLight").tap()
        try practice(false, app, prefix: "mode-practice-sky-largest")
        tap("sky.lanternMode.fullBoard", app)
        try practice(true, app, prefix: "mode-practice-full-largest")
        tap("sky.home", app); tap("world.done", app)
        XCTAssertEqual(try cells(app), saved)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, summary)
        XCTAssertTrue(app.buttons["experiment.next"].isEnabled)
    }
}
