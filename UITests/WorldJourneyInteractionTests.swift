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
        if id.hasPrefix("world.node.") { revealMapMarker(button, app) }
        else { app.revealSkyControls([button]) }
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), id)
        button.tap()
    }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func assertTutorialIndexCovered(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let coveredControls = app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@ OR identifier == %@", "tutorial.chapter.", "tutorial.done"))
        XCTAssertEqual(coveredControls.count, 0,
                       "Practice must expose neither the covered chapter choices nor the index Done action",
                       file: file, line: line)
    }
    @MainActor private func assertReturnedChapterVisible(_ id: String, _ app: XCUIApplication,
                                                         file: StaticString = #filePath, line: UInt = #line) {
        let chapter = app.buttons["tutorial.chapter." + id]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5), file: file, line: line)
        let owners = app.scrollViews.containing(.button, identifier: chapter.identifier)
        XCTAssertEqual(owners.count, 1, file: file, line: line)
        let scroll = owners.element(boundBy: 0)
        var observation = "No chapter geometry observed"
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard chapter.exists, scroll.exists else { return false }
            let viewport = app.frame.intersection(scroll.frame)
            let target = chapter.frame
            let hittable = chapter.isHittable
            observation = "target=\(target), viewport=\(viewport), hittable=\(hittable)"
            return target.width >= 44 && target.height >= 44 && viewport.contains(target) && hittable
        }, object: nil).wait(timeout: 5)
        XCTAssertTrue(visible, "Exit must restore \(id) fully visible without test scrolling: \(observation)",
                      file: file, line: line)
    }
    @MainActor private func revealMapMarker(_ marker: XCUIElement, _ app: XCUIApplication) {
        app.revealWorldMapMarker(marker)
        assertSeparateMapTargets(app)
    }

    @MainActor private func assertSeparateMapTargets(_ app: XCUIApplication) {
        // Compare visible pairs at one current window/scroll offset. Checking
        // each revealed destination covers every target without treating clipped
        // offscreen accessibility frames as complete controls.
        let viewport = app.frame.intersection(app.scrollViews["world.canvas"].frame)
        let frames = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.node."))
            .allElementsBoundByIndex.map { ($0.identifier, $0.frame) }
        XCTAssertEqual(frames.count, 7)
        let visible = frames.filter { !$0.1.isEmpty && viewport.intersects($0.1) }
        for (index, marker) in visible.enumerated() {
            for sibling in visible.dropFirst(index + 1) {
                XCTAssertFalse(marker.1.intersects(sibling.1), "\(marker.0) overlaps \(sibling.0)")
            }
        }
    }

    @MainActor private func checkPhysicalMapSelections(_ app: XCUIApplication) {
        let places = [
            ("firstLight", "Lantern Landing", "Ready to restore"),
            ("ribbonCrossing", "Ribbon Crossing", "Restore Lantern Landing first"),
            ("kiteHarbor", "Kite Harbor", "Restore Ribbon Crossing first"),
            ("seedMoon", "Seed Moon", "Restore Kite Harbor first"),
            ("silverPools", "Silver Pools", "Restore Seed Moon first"),
            ("frostfruitOrchard", "Frostfruit Orchard", "Restore Silver Pools first"),
            ("sunwheelMill", "Sunwheel Mill", "Restore Frostfruit Orchard first")
        ]
        let markers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.node."))
        XCTAssertEqual(markers.count, places.count, "Every built destination has one foreground map marker")
        for (id, name, status) in places {
            let marker = app.buttons["world.node." + id]
            revealMapMarker(marker, app)
            XCTAssertTrue(marker.isHittable, name)
            XCTAssertGreaterThanOrEqual(marker.frame.width, 44, name)
            XCTAssertGreaterThanOrEqual(marker.frame.height, 44, name)
            XCTAssertTrue(app.frame.insetBy(dx: -1, dy: -1).contains(marker.frame), "\(name) is fully inside the page")
            XCTAssertTrue(marker.label.contains(name), name)
            XCTAssertEqual(marker.value as? String, status, name)
            // Use an actual screen coordinate, so an obscuring card or overlapping
            // marker cannot pass through accessibility activation alone.
            marker.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", name),
                object: app.staticTexts["world.selection"]).wait(timeout: 5), name)
            XCTAssertEqual(app.staticTexts["world.status"].label, status)
            XCTAssertTrue(marker.isSelected, "Locked places also expose an immediate selected state")
            XCTAssertEqual(markers.allElementsBoundByIndex.filter(\.isSelected).count, 1)
            XCTAssertEqual(app.buttons["world.visit"].exists, id == "firstLight")
        }
        assertSeparateMapTargets(app)
    }
    @MainActor func testMapMarkersUsePhysicalTargetsAndSelectLockedDestinations() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch(); defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        tap("sky.worldMap", app)
        XCTAssertTrue(app.buttons["world.node.firstLight"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["world.list"].label, "Places")
        checkPhysicalMapSelections(app)
        capture("world-map-selected-locked-phone", app)
        if app.frame.width > 700 {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in app.frame.width > app.frame.height },
                object: nil).wait(timeout: 5))
            checkPhysicalMapSelections(app)
            capture("world-map-selected-locked-landscape", app)
        }
        tap("world.list", app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.place.")).count, 12)
        XCTAssertFalse(app.buttons["world.node.firstLight"].exists)
        tap("world.place.bellChoir", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Bell Choir")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Not yet available")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        XCTAssertTrue(app.buttons["world.place.bellChoir"].isSelected)
        tap("world.list", app)
        XCTAssertTrue(app.buttons["world.node.firstLight"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Bell Choir")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.node."))
            .allElementsBoundByIndex.filter(\.isSelected).count, 0,
                       "An unbuilt selection must not falsely select a built destination")
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
                revealMapMarker(node, app)
                XCTAssertTrue(node.isHittable)
                XCTAssertGreaterThanOrEqual(node.frame.width, 44)
                XCTAssertGreaterThanOrEqual(node.frame.height, 44)
            }
            assertSeparateMapTargets(app)
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
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Frostfruit Orchard first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.place.bellChoir", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Not yet available")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.place.firstLight", app); tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        XCTAssertFalse(app.buttons["sky.resume"].exists, "Browsing does not save a round")
        tap("world.done", app)
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["sky.resume"].exists)
        tap("sky.worldMap", app); tap("world.visit", app); tap("sky.begin", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("of 150,000"))
        capture("official-lantern-after-map-entry", app)
        let score = app.staticTexts["experiment.score"].label
        let board = app.otherElements["experiment.board"].value as? String
        XCTAssertNotNil(board)
        tap("experiment.settings", app); tap("sky.worldMap", app)
        tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        tap("sky.home", app)
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertTrue(app.buttons["world.resume"].exists, "Canceling a restart keeps the retained round available")
        tap("world.done", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
        tap("experiment.settings", app)
        XCTAssertEqual(app.buttons["experiment.pause"].label, "Resume sky", "Map Back preserves the paused round")
        tap("sky.worldMap", app); tap("world.resume", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
    }

    @MainActor func testExtraLargeTextRetainedMapKeepsMarkersAndActionsReachable() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "-calmEffects", "NO",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXL"]
        app.launch()
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        tap("sky.worldMap", app); tap("world.visit", app); tap("sky.begin", app)
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true"), object: app.buttons["experiment.next"]).wait(timeout: 5))
        let board = app.otherElements["experiment.board"].value as? String
        let score = app.staticTexts["experiment.score"].label
        XCTAssertNotNil(board)
        tap("experiment.settings", app); tap("sky.worldMap", app)
        XCTAssertTrue(app.buttons["world.list"].exists, "Extra Large text retains a usable illustrated map")
        let resume = app.buttons["world.resume"], restart = app.buttons["world.visit"]
        app.revealSkyControls([resume, restart])
        XCTAssertEqual(resume.label, "Continue")
        XCTAssertEqual(restart.label, "Start again")
        for control in [resume, restart] {
            XCTAssertTrue(app.frame.contains(control.frame), "The complete retained-round action must be visible")
            XCTAssertGreaterThanOrEqual(control.frame.width, 44)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
        XCTAssertFalse(resume.frame.intersects(restart.frame))
        capture("world-extra-large-retained-card", app)
        // Growing card copy must not squeeze markers into one another or leave
        // them unreachable. Scroll through the real page when it needs room.
        for location in ["sunwheelMill", "frostfruitOrchard", "silverPools", "seedMoon", "kiteHarbor", "ribbonCrossing", "firstLight"] {
            let marker = app.buttons["world.node." + location]
            revealMapMarker(marker, app)
            let title = marker.label
            marker.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", title),
                object: app.staticTexts["world.selection"]).wait(timeout: 5))
            XCTAssertTrue(marker.isSelected)
        }
        assertSeparateMapTargets(app)
        tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        tap("sky.home", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        tap("world.resume", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertTrue(app.buttons["experiment.next"].exists, "The map keeps the retained round paused")
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
            assertTutorialIndexCovered(app)
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
            assertTutorialIndexCovered(app)
            capture("tutorial-\(chapter)-native-complete", app)
            tap("tutorial.retry", app)
            XCTAssertNotEqual(app.staticTexts["tutorial.instruction"].label, "Chapter complete")
            tap("experiment.settings", app)
            XCTAssertTrue(app.buttons["tutorial.chapter.match"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["tutorial.done"].exists)
            assertReturnedChapterVisible(chapter, app)
            if chapter == "trace" { capture("tutorial-returned-trace-index", app) }
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
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["world.list"].exists, "The mandatory accessibility list must not offer an ineffective map toggle")
        XCTAssertFalse(app.buttons["world.node.firstLight"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.place.")).count, 12)
        tap("world.place.ribbonCrossing", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Lantern Landing first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        XCTAssertTrue(app.buttons["world.place.ribbonCrossing"].isSelected)
        tap("world.place.firstLight", app)
        XCTAssertTrue(app.buttons["world.place.firstLight"].isSelected)
        XCTAssertFalse(app.buttons["world.place.ribbonCrossing"].isSelected)
        XCTAssertTrue(app.buttons["world.visit"].exists)
        capture("world-largest-text-list", app)
        tap("world.learn", app); tap("tutorial.chapter.match", app)
        XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
        assertTutorialIndexCovered(app)
        XCUIDevice.shared.press(.home); app.activate()
        assertTutorialIndexCovered(app)
        tap("experiment.cell.0.0", app)
        XCTAssertEqual(app.staticTexts["tutorial.instruction"].label, "Chapter complete")
        tap("tutorial.retry", app); capture("tutorial-largest-text-retry", app)
        assertTutorialIndexCovered(app)
        tap("experiment.settings", app)
        XCTAssertTrue(app.buttons["tutorial.chapter.match"].waitForExistence(timeout: 5))
        assertReturnedChapterVisible("match", app)
        tap("tutorial.done", app)
    }

    @MainActor func testLargestTextTutorialIndexScrollsAcrossPaintedPadding() {
        XCUIDevice.shared.orientation = .portrait
        let app = launch(large: true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        tap("sky.worldMap", app); tap("world.learn", app)
        let chapter = app.buttons["tutorial.chapter.match"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 5))
        let owners = app.scrollViews.containing(.button, identifier: chapter.identifier)
        XCTAssertEqual(owners.count, 1, "The visible tutorial index owns its chapter scroll view")
        let scroll = owners.element(boundBy: 0)
        capture("tutorial-largest-index-header", app)

        var trace: [String] = []
        var results: [(lane: String, moved: Bool)] = []
        // Match the original failing path: its center swipe exposes or overshoots
        // Match, then the helper tries a downward correction along the left edge.
        let initial = chapter.frame
        app.swipeUp()
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in chapter.exists && initial.minY - chapter.frame.minY > 40 },
            object: nil).wait(timeout: 3), "The initial center swipe must establish a scrolled index")
        trace.append("Initial center swipe: before=\(initial), after=\(chapter.frame)")
        // Inspect every lane before asserting, so later diagnostic movement
        // cannot replace a failed first pan with a passing outcome.
        let lanes: [(name: String, fraction: CGFloat, upward: Bool)] = [
            ("left painted padding downward", 0.12, false),
            ("center downward", 0.5, false),
            ("right painted padding upward", 0.88, true),
            ("left painted padding upward", 0.12, true)
        ]
        for (lane, fraction, upward) in lanes {
            let viewport = app.frame.intersection(scroll.frame).insetBy(dx: 1, dy: 1)
            let distance = min(180, viewport.height * 0.5)
            XCTAssertGreaterThanOrEqual(distance, 160, "The diagnostic pan stays inside the visible tutorial viewport")
            let before = chapter.frame
            let startPoint = CGPoint(x: viewport.minX + viewport.width * fraction,
                                     y: viewport.minY + viewport.height * (upward ? 0.75 : 0.25))
            let start = app.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: startPoint.x - app.frame.minX, dy: startPoint.y - app.frame.minY))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(CGVector(dx: 0, dy: upward ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
            let moved = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in
                    guard chapter.exists else { return false }
                    return (chapter.frame.minY - before.minY) * (upward ? -1 : 1) > 40
                }, object: nil).wait(timeout: 3)
            trace.append("\(lane): viewport=\(viewport), start=\(startPoint), distance=\(distance), "
                         + "before=\(before), after=\(chapter.frame), moved=\(moved)")
            results.append((lane, moved))
        }
        XCTContext.runActivity(named: "Tutorial painted-area pan measurements") { activity in
            let attachment = XCTAttachment(string: trace.joined(separator: "\n"))
            attachment.name = "tutorial-index-pan-frames"
            attachment.lifetime = .keepAlways
            activity.add(attachment)
        }
        capture("tutorial-largest-index-after-painted-pans", app)
        // Center/right measurements diagnose admission; successive downward
        // pans may reach the top, so only the two left-edge probes are gates.
        for result in results where result.lane.hasPrefix("left ") {
            XCTAssertTrue(result.moved, "The tutorial index must scroll from its \(result.lane)")
        }
    }

    @MainActor func testAllReadyLocationsAcceptFourDirectionSwapsAndClears() {
        executionTimeAllowance = 300
        for location in ["lantern", "ribbon", "kite", "seed", "silver", "frostfruit", "sunwheel"] {
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
        XCTAssertEqual(app.buttons["world.node.sunwheelMill"].value as? String, "Restore Frostfruit Orchard first")
        XCTAssertFalse(app.buttons["world.node.bellChoir"].exists)
        capture("world-lantern-repaired-path-revealed", app)
        tap("world.list", app); tap("world.place.bellChoir", app)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Not yet available")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        app.terminate(); app.launchArguments = ["--dialogue-review"]; app.launch()
        tap("sky.worldMap", app)
        XCTAssertEqual(app.buttons["world.node.firstLight"].value as? String, "Restored")
        XCTAssertEqual(app.buttons["world.node.ribbonCrossing"].value as? String, "Ready to restore")
        capture("world-repair-after-relaunch", app)
    }

    @MainActor func testRevisedLanternEarnsThousandsAndRetainsScoreAcrossRelaunch() {
        let app = launch(); defer { app.terminate() }
        app.worldVisitControl("firstLight").tap()
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("150,000"))
        capture("story-lantern-entry-150000", app)
        tap("sky.begin", app)
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("of 150,000"))
        tap("experiment.cell.0.4", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3,000 of 150,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        capture("story-lantern-three-thousand-native-clear", app)
        let score = app.staticTexts["experiment.score"].label
        let board = app.otherElements["experiment.board"].value as? String
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        app.terminate(); app.launchArguments = ["--sky-flow-review", "-calmEffects", "NO"]; app.launch()
        tap("sky.resume", app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, score)
        XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
        XCTAssertTrue(app.buttons["experiment.next"].exists)
    }

    @MainActor func testRevisedRibbonSwapCreatesLargerClearWithLargestText() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--world-legacy-review", "--sky-flow-review",
                               "-calmEffects", "YES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        app.worldVisitControl("ribbonCrossing").tap()
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("220,000"))
        capture("story-ribbon-entry-largest-text", app)
        app.revealSkyControls([app.buttons["sky.begin"]])
        capture("story-ribbon-entry-actions-largest-text", app)
        tap("sky.begin", app)
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertTrue(app.buttons["experiment.cell.0.2"].value.debugDescription.contains("3 toward a tap match"))
        drag(app, from: (1,1), to: (0,1), drawing: false)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "value CONTAINS %@ AND enabled == true", "5 toward a tap match"), object: app.buttons["experiment.cell.0.2"]).wait(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 220,000 starlight collected")
        tap("experiment.cell.0.2", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "7,000 of 220,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        capture("story-ribbon-seven-thousand-largest-text", app)
        tap("experiment.settings", app); tap("experiment.done", app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "7,000 of 220,000 starlight collected")

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
        XCTAssertEqual(app.buttons["world.node.sunwheelMill"].value as? String, "Restore Frostfruit Orchard first")
        XCTAssertFalse(app.buttons["world.node.bellChoir"].exists)
        tap("world.list", app)
        XCTAssertEqual(app.buttons["world.place.sunwheelMill"].value as? String, "Restore Frostfruit Orchard first")
        XCTAssertEqual(app.buttons["world.place.bellChoir"].value as? String, "Not yet available")
        XCTAssertTrue(app.buttons["world.place.frostfruitOrchard"].isSelected)
        tap("world.list", app)
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

    @MainActor func testFrostfruitWinningClearUnlocksSunwheelAndPersistsItsMapEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--frostfruit-restoration-review=14", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
        tap("experiment.settings", app); tap("sky.worldMap", app)
        let sunwheel = app.buttons["world.node.sunwheelMill"]
        revealMapMarker(sunwheel, app)
        sunwheel.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Sunwheel Mill"),
            object: app.staticTexts["world.selection"]).wait(timeout: 5))
        XCTAssertTrue(sunwheel.isSelected)
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Frostfruit Orchard first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        tap("world.done", app)
        tap("experiment.cell.0.0", app)
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        tap("sky.worldMap", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Sunwheel Mill")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        XCTAssertEqual(app.buttons["world.node.frostfruitOrchard"].value as? String, "Restored")
        XCTAssertFalse(app.buttons["world.node.bellChoir"].exists)
        tap("world.list", app)
        XCTAssertEqual(app.buttons["world.place.bellChoir"].value as? String, "Not yet available")
        XCTAssertTrue(app.buttons["world.place.sunwheelMill"].isSelected)
        tap("world.list", app)
        app.waitForVisibleWorldMapMarker(sunwheel)
        capture("sunwheel-ready-after-frostfruit-repair", app)
        app.terminate(); app.launchArguments = ["--dialogue-review", "-calmEffects", "NO"]; app.launch()
        tap("sky.worldMap", app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Sunwheel Mill")
        app.waitForVisibleWorldMapMarker(sunwheel)
        tap("world.visit", app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Sunwheel Mill")
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists, "Entry must not replace the repaired Frostfruit round before Begin")
        tap("sky.begin", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        tap("experiment.settings", app); tap("experiment.pause", app)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 18 starlight collected")
        XCTAssertTrue(app.descendants(matching: .any)["sunwheel.restoration"].firstMatch.exists)
        capture("sunwheel-entered-from-earned-map-unlock", app)
    }

}
