import XCTest

final class WorldJourneyInteractionTests: XCTestCase {
    @MainActor private func launch(large: Bool = false, calm: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "-calmEffects", calm ? "YES" : "NO"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = app.buttons[id]
        if id == "sky.learn" || id == "sky.worldMap" || id.hasPrefix("tutorial.chapter.") { app.revealSkyMenuElement(button) }
        XCTAssertTrue(button.waitForExistence(timeout: 5), id)
        app.revealSkyControls([button])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), id)
        button.tap()
    }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testMapSeparatesLockedAndUnavailableAndEntryCanCancel() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch(); defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        XCTAssertFalse(app.buttons["sky.firstLight"].exists)
        tap("sky.worldMap", app)
        XCTAssertTrue(app.buttons["world.node.firstLight"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.sheets.count, 0, "The world map is a page, not a modal")
        XCTAssertFalse(app.staticTexts["sky.title"].exists, "Welcome does not sit beneath the map")
        // AX containers union child hit regions, which can extend past the canvas.
        XCTAssertEqual(app.otherElements["world.page"].frame.intersection(app.frame).width, app.frame.width, accuracy: 1)
        capture("official-world-map-phone", app)
        if app.frame.width > 700 {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: nil).wait(timeout: 5))
            for node in app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.node.")).allElementsBoundByIndex {
                XCTAssertTrue(node.isHittable)
                XCTAssertGreaterThanOrEqual(node.frame.width, 44)
                XCTAssertGreaterThanOrEqual(node.frame.height, 44)
            }
            capture("world-map-landscape", app)
            XCUIDevice.shared.orientation = .portrait
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.frame.height > app.frame.width }, object: nil).wait(timeout: 5))
        }
        tap("world.done", app)
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        tap("sky.worldMap", app)
        tap("world.node.ribbonCrossing", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Lantern Landing first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.list", app)
        tap("world.place.frostfruitOrchard", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Silver Pools first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.place.sunwheelMill", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Not yet available")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.place.firstLight", app); tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        tap("sky.home", app)
        XCTAssertFalse(app.buttons["sky.resume"].exists, "Browsing does not save a round")
        tap("sky.worldMap", app); tap("world.visit", app); tap("sky.begin", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("of 18"))
        capture("official-lantern-after-map-entry", app)
        let score = app.staticTexts["experiment.score"].label
        let board = app.otherElements["experiment.board"].value as? String
        tap("experiment.settings", app); tap("sky.worldMap", app); tap("world.resume", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
    }
    @MainActor func testTutorialRealTapSwapTraceRetryAndExitPreserveRound() {
        let app = launch(); defer { app.terminate() }
        tap("sky.start", app); tap("sky.begin", app)
        tap("experiment.settings", app); tap("experiment.pause", app)
        let score = app.staticTexts["experiment.score"].label
        let board = app.otherElements["experiment.board"].value as? String
        tap("experiment.settings", app); tap("sky.learn", app)
        for chapter in ["match", "exchange", "trace"] {
            tap("tutorial.chapter." + chapter, app)
            XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
            if chapter == "match" {
                tap("experiment.cell.0.0", app)
            } else if chapter == "exchange" {
                for (from, to) in [((1,1),(1,2)), ((1,2),(1,1)), ((1,1),(2,1)), ((2,1),(1,1))] {
                    drag(app, from: from, to: to, drawing: false)
                }
            } else {
                drag(app, from: (0,0), to: (0,4), drawing: true)
                XCTAssertTrue(app.buttons["experiment.cell.0.5"].label.contains("Aqua"))
            }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Chapter complete"), object: app.staticTexts["tutorial.instruction"]).wait(timeout: 5))
            capture("tutorial-\(chapter)-native-complete", app)
            tap("tutorial.retry", app)
            XCTAssertNotEqual(app.staticTexts["tutorial.instruction"].label, "Chapter complete")
            tap("experiment.settings", app)
            XCTAssertTrue(app.buttons["tutorial.chapter.match"].waitForExistence(timeout: 5))
        }
        tap("tutorial.done", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
    }
    @MainActor private func drag(_ app: XCUIApplication, from: (Int, Int), to: (Int, Int), drawing: Bool) {
        let start = app.buttons["experiment.cell.\(from.0).\(from.1)"], end = app.buttons["experiment.cell.\(to.0).\(to.1)"]
        app.revealSkyControls([start,end])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: start).wait(timeout: 5))
        start.coordinate(withNormalizedOffset: .init(dx: 0.5,dy: 0.5))
            .press(forDuration: drawing ? 0.4 : 0.05, thenDragTo: end.coordinate(withNormalizedOffset: .init(dx: 0.5,dy: 0.5)), withVelocity: .slow, thenHoldForDuration: 0.15)
    }
    @MainActor func testLargestTextMapAndPracticeSurviveBackground() {
        let app = launch(large: true, calm: true); defer { app.terminate() }
        tap("sky.worldMap", app)
        tap("world.place.firstLight", app)
        XCTAssertTrue(app.buttons["world.visit"].exists)
        capture("world-largest-text-list", app)
        tap("world.learn", app); tap("tutorial.chapter.match", app)
        XCUIDevice.shared.press(.home); app.activate()
        tap("experiment.cell.0.0", app)
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Chapter complete")
        tap("tutorial.retry", app); capture("tutorial-largest-text-retry", app)
        tap("experiment.settings", app); tap("tutorial.done", app)
    }
    @MainActor func testAllReadyLocationsAcceptFourDirectionSwapsAndClears() {
        executionTimeAllowance = 300
        for location in ["lantern", "ribbon", "kite", "seed", "silver", "frostfruit"] {
            let app = XCUIApplication()
            app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--\(location)-restoration-review=0", "-calmEffects", "NO"]
            app.launch()
            XCTAssertTrue(app.buttons["experiment.cell.1.1"].waitForExistence(timeout: 10))
            for (from,to) in [((1,1),(1,2)), ((1,2),(1,1)), ((1,1),(2,1)), ((2,1),(1,1))] {
                drag(app, from: from, to: to, drawing: false)
                let destination = app.buttons["experiment.cell.\(to.0).\(to.1)"]
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@ AND enabled == true", "Mint"), object: destination).wait(timeout: 5), location)
                XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
            }
            tap("experiment.cell.0.0", app)
            XCTAssertEqual(app.staticTexts["experiment.score"].label, "4 of 18 starlight collected")
            capture("\(location)-official-native-swap-and-clear", app)
            app.terminate()
        }
    }
    @MainActor func testRepairLightsMapAndPersistsWithoutUnlockingUnbuiltPlaces() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--lantern-restoration-review=14", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
        tap("experiment.cell.0.0", app)
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        tap("sky.worldMap", app)
        XCTAssertEqual(app.buttons["world.node.firstLight"].value as? String, "Restored")
        XCTAssertEqual(app.buttons["world.node.ribbonCrossing"].value as? String, "Ready to restore")
        XCTAssertEqual(app.buttons["world.node.frostfruitOrchard"].value as? String, "Restore Silver Pools first")
        XCTAssertEqual(app.buttons["world.node.sunwheelMill"].value as? String, "Not yet available")
        capture("world-lantern-repaired-path-revealed", app)
        app.terminate(); app.launchArguments = ["--dialogue-review"]; app.launch()
        tap("sky.worldMap", app)
        XCTAssertEqual(app.buttons["world.node.firstLight"].value as? String, "Restored")
        XCTAssertEqual(app.buttons["world.node.ribbonCrossing"].value as? String, "Ready to restore")
        capture("world-repair-after-relaunch", app)
    }

    @MainActor func testSilverWinningClearUnlocksFrostfruitAndPersistsItsMapEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--silver-restoration-review=14", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
        tap("experiment.settings", app); tap("sky.worldMap", app)
        tap("world.node.frostfruitOrchard", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Silver Pools first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.done", app)
        tap("experiment.cell.0.0", app)
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        tap("sky.worldMap", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Frostfruit Orchard")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        XCTAssertEqual(app.buttons["world.node.silverPools"].value as? String, "Restored")
        XCTAssertEqual(app.buttons["world.node.sunwheelMill"].value as? String, "Not yet available")
        capture("frostfruit-ready-after-silver-repair", app)
        app.terminate(); app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]; app.launch()
        tap("sky.worldMap", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Frostfruit Orchard")
        tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        tap("sky.begin", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertTrue(app.descendants(matching: .any)["frostfruit.restoration"].firstMatch.exists)
        capture("frostfruit-entered-from-earned-map-unlock", app)
    }

}
