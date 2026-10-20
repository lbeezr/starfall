import XCTest

/// A bounded visual/state harness through the normal app, map and Entry route.
/// Run this class on the compact phone and iPad; it creates no alternate screen.
final class WorldMapReviewInteractionTests: XCTestCase {
    private struct Review {
        let state: String
        let title: String
        let status: String
        let completedCount: Int
        var visit = true
        var resume = false
        var recovery = false
    }
    private let reviews = [
        Review(state: "fresh", title: "Lantern Landing", status: "Ready to restore", completedCount: 0),
        Review(state: "twoRepairs", title: "Kite Harbor", status: "Ready to restore", completedCount: 2),
        Review(state: "allReady", title: "Frostfruit Orchard", status: "Restored", completedCount: 6),
        Review(state: "locked", title: "Frostfruit Orchard", status: "Restore Silver Pools first", completedCount: 0, visit: false),
        Review(state: "unbuilt", title: "Sunwheel Mill", status: "Not yet available", completedCount: 0, visit: false),
        Review(state: "retained", title: "Kite Harbor", status: "Ready to restore", completedCount: 2, resume: true),
        Review(state: "recovery", title: "Ribbon Crossing", status: "Ready to restore", completedCount: 1, recovery: true)
    ]
    private let destinations = [
        ("firstLight", "Lantern Landing"), ("ribbonCrossing", "Ribbon Crossing"),
        ("kiteHarbor", "Kite Harbor"), ("seedMoon", "Seed Moon"), ("silverPools", "Silver Pools"),
        ("frostfruitOrchard", "Frostfruit Orchard")
    ]

    @MainActor private func launch(_ state: String, textSize: String? = nil) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--world-map-review", "--world-map-state=" + state,
                               "-calmEffects", "NO"]
        if let textSize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", textSize] }
        app.launch()
        XCTAssertTrue(app.otherElements["world.page"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["sky.worldMap"].exists, "The harness displays the normal map directly")
        return app
    }

    @MainActor private func tap(_ identifier: String, _ app: XCUIApplication) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 5), identifier)
        app.revealSkyControls([button])
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), identifier)
        button.tap()
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func assertSelection(_ review: Review, _ app: XCUIApplication) {
        XCTAssertTrue(app.staticTexts["world.selection"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["world.selection"].label, review.title)
        XCTAssertEqual(app.staticTexts["world.status"].label, review.status)
        XCTAssertEqual(app.buttons["world.visit"].exists, review.visit)
        XCTAssertEqual(app.buttons["world.resume"].exists, review.resume)
        let recovery = app.staticTexts["world.recovery"]
        XCTAssertEqual(recovery.exists, review.recovery)
    }

    @MainActor func testSevenReviewStatesUseNormalMapAndExplicitEntryBoundary() {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        for review in reviews {
            let app = launch(review.state)
            defer { app.terminate() }
            assertSelection(review, app)
            let markers = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.node."))
            XCTAssertEqual(markers.count, destinations.count)
            for (index, destination) in destinations.enumerated() {
                let marker = app.buttons["world.node." + destination.0]
                let status = index < review.completedCount ? "Restored"
                    : index == review.completedCount ? "Ready to restore"
                    : "Restore " + destinations[index - 1].1 + " first"
                XCTAssertEqual(marker.label, destination.1)
                XCTAssertEqual(marker.value as? String, status)
            }
            XCTAssertEqual(markers.allElementsBoundByIndex.filter(\.isSelected).count, review.state == "unbuilt" ? 0 : 1)
            if let selected = destinations.first(where: { $0.1 == review.title }) {
                app.waitForVisibleWorldMapMarker(app.buttons["world.node." + selected.0])
            }
            capture("map-harness-" + review.state + "-portrait", app)
            if review.state == "twoRepairs", app.frame.width > 700 {
                XCUIDevice.shared.orientation = .landscapeLeft
                XCTAssertTrue(XCTNSPredicateExpectation(
                    predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: nil).wait(timeout: 5))
                assertSelection(review, app)
                app.waitForVisibleWorldMapMarker(app.buttons["world.node.kiteHarbor"])
                capture("map-harness-two-repairs-landscape", app)
                XCUIDevice.shared.orientation = .portrait
                XCTAssertTrue(XCTNSPredicateExpectation(
                    predicate: NSPredicate { _, _ in app.frame.height > app.frame.width }, object: nil).wait(timeout: 5))
            }
            if review.visit {
                tap("world.visit", app)
                XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["sky.title"].label, review.title)
                XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
                tap("sky.home", app)
                assertSelection(review, app)
            } else {
                tap("world.list", app)
                let selectedID = review.state == "unbuilt" ? "sunwheelMill" : "frostfruitOrchard"
                XCTAssertTrue(app.buttons["world.place." + selectedID].isSelected)
                XCTAssertFalse(app.buttons["world.visit"].exists)
            }
            tap("world.done", app)
            XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["sky.resume"].exists, review.completedCount > 0,
                           "Inspecting or canceling never creates or discards a committed round")
        }
    }

    @MainActor func testLanternLayerKeepsNativeTargetAcrossRepairStates() {
        executionTimeAllowance = 120
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        for (state, status, visit) in [
            ("fresh", "Ready to restore", "Visit Lantern Landing"),
            ("twoRepairs", "Restored", "Revisit Lantern Landing")
        ] {
            let app = launch(state)
            defer { app.terminate() }
            let lantern = app.buttons["world.node.firstLight"]
            app.revealWorldMapMarker(lantern)
            lantern.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", "Lantern Landing"),
                object: app.staticTexts["world.selection"]).wait(timeout: 5))
            XCTAssertTrue(lantern.isSelected)
            XCTAssertEqual(lantern.value as? String, status)
            XCTAssertEqual(app.staticTexts["world.status"].label, status)
            XCTAssertEqual(app.buttons["world.visit"].label, visit)
            app.waitForVisibleWorldMapMarker(lantern)
            // The native target is asserted here; inspect the whole island's
            // visible composition in these captures against hosted geometry.
            capture("map-lantern-layer-" + state, app)
            tap("world.visit", app)
            XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
            XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
            tap("sky.home", app)
            XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
            XCTAssertEqual(app.staticTexts["world.status"].label, status)
            XCTAssertEqual(lantern.value as? String, status)
            XCTAssertTrue(lantern.isSelected)
            app.waitForVisibleWorldMapMarker(lantern)
        }
    }

    @MainActor func testTutorialHidesCoveredMapAndPreservesSelectionAndRetainedRound() throws {
        executionTimeAllowance = 180
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = launch("retained")
        defer { app.terminate() }
        tap("world.resume", app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "9 of 18 starlight collected")
        XCTAssertTrue(app.buttons["experiment.next"].exists, "The retained round stays paused")
        let committed = board.value as? String
        XCTAssertNotNil(committed)
        func cellLabels() throws -> [String] {
            var labels: [String] = []
            func visit(_ element: any XCUIElementSnapshot) {
                if element.elementType == .button && element.identifier.hasPrefix("experiment.cell.") {
                    labels.append("\(element.identifier):\(element.label)")
                }
                element.children.forEach(visit)
            }
            visit(try board.snapshot())
            return labels.sorted()
        }
        let committedCells = try cellLabels()
        XCTAssertEqual(committedCells.count, 49)

        tap("experiment.settings", app)
        app.skyMenuControl("sky.worldMap").tap()
        let selectedMarker = app.buttons["world.node.silverPools"]
        app.revealWorldMapMarker(selectedMarker)
        selectedMarker.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Silver Pools"),
            object: app.staticTexts["world.selection"]).wait(timeout: 5))

        for showingPlaces in [false, true] {
            if showingPlaces { tap("world.list", app) }
            let selected = app.buttons[showingPlaces ? "world.place.silverPools" : "world.node.silverPools"]
            XCTAssertTrue(selected.isSelected)
            tap("world.learn", app)
            XCTAssertTrue(app.buttons["tutorial.chapter.match"].waitForExistence(timeout: 5))
            let coveredMap = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH %@", "world."))
            let withdrawn = XCTNSPredicateExpectation(
                predicate: NSPredicate { _, _ in coveredMap.count == 0 }, object: nil).wait(timeout: 5)
            if !withdrawn {
                let exposed = coveredMap.allElementsBoundByIndex.map {
                    "\($0.elementType) \($0.identifier) frame=\($0.frame)"
                }
                let attachment = XCTAttachment(string: exposed.joined(separator: "\n"))
                attachment.name = "covered-map-accessibility-leaks"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            XCTAssertTrue(withdrawn, "A covered map must expose neither its page nor its native controls")
            XCTAssertFalse(app.otherElements["world.page"].exists)
            capture(showingPlaces ? "map-places-covered-by-tutorial" : "map-covered-by-tutorial", app)

            if !showingPlaces {
                tap("tutorial.chapter.match", app)
                XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
                XCTAssertEqual(coveredMap.count, 0)
                tap("experiment.cell.0.0", app)
                XCTAssertTrue(XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "label == %@", "Chapter complete"),
                    object: app.staticTexts["tutorial.instruction"]).wait(timeout: 5))
                tap("experiment.settings", app)
                XCTAssertTrue(app.buttons["tutorial.chapter.match"].waitForExistence(timeout: 5))
                XCTAssertEqual(coveredMap.count, 0)
            }
            tap("tutorial.done", app)
            XCTAssertTrue(app.otherElements["world.page"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["world.selection"].label, "Silver Pools")
            XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Seed Moon first")
            XCTAssertTrue(selected.isSelected, "Closing Tutorial preserves the selection and Map/Places mode")
            XCTAssertFalse(app.buttons["world.visit"].exists)
            XCTAssertFalse(app.buttons["world.resume"].exists)
        }

        tap("world.done", app)
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(board.value as? String, committed)
        XCTAssertEqual(try cellLabels(), committedCells)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "9 of 18 starlight collected")
        XCTAssertTrue(app.buttons["experiment.next"].exists, "Tutorial never resumes the retained round")
    }

    @MainActor func testRetainedAndRecoveryReviewsReflowWithoutChangingTheRound() {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let retained = launch("retained", textSize: "UICTContentSizeCategoryXL")
        defer { retained.terminate() }
        retained.waitForVisibleWorldMapMarker(retained.buttons["world.node.kiteHarbor"])
        let continueButton = retained.buttons["world.resume"], restart = retained.buttons["world.visit"]
        retained.revealSkyControls([continueButton, restart])
        XCTAssertFalse(continueButton.frame.intersects(restart.frame))
        XCTAssertGreaterThanOrEqual(continueButton.frame.height, 44)
        XCTAssertGreaterThanOrEqual(restart.frame.height, 44)
        capture("map-harness-retained-extra-large", retained)
        tap("world.visit", retained); tap("sky.home", retained); tap("world.resume", retained)
        let board = retained.otherElements["experiment.board"]
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(retained.staticTexts["experiment.score"].label, "9 of 18 starlight collected")
        XCTAssertTrue(retained.buttons["experiment.next"].exists)
        let committed = board.value as? String
        XCTAssertNotNil(committed)
        XCUIDevice.shared.press(.home); retained.activate()
        XCTAssertEqual(board.value as? String, committed)
        XCTAssertEqual(retained.staticTexts["experiment.score"].label, "9 of 18 starlight collected")
        tap("experiment.settings", retained)
        retained.skyMenuControl("sky.worldMap").tap()
        XCTAssertTrue(retained.buttons["world.resume"].waitForExistence(timeout: 5))
        XCTAssertEqual(retained.staticTexts["world.selection"].label, "Kite Harbor")
        retained.terminate()

        let recoveryMap = launch("recovery", textSize: "UICTContentSizeCategoryXL")
        defer { recoveryMap.terminate() }
        let canvas = recoveryMap.scrollViews["world.canvas"]
        if canvas.exists {
            XCTAssertTrue(recoveryMap.buttons["world.list"].exists)
            recoveryMap.waitForVisibleWorldMapMarker(recoveryMap.buttons["world.node.ribbonCrossing"])
            for control in [recoveryMap.staticTexts["world.recovery"], recoveryMap.staticTexts["world.selection"],
                            recoveryMap.staticTexts["world.status"], recoveryMap.buttons["world.visit"]] {
                XCTAssertTrue(control.exists)
                XCTAssertTrue(recoveryMap.frame.contains(control.frame), "The complete recovery card must remain visible")
                XCTAssertFalse(canvas.frame.intersects(control.frame), "The pinned card must not cover map input")
            }
            XCTAssertGreaterThanOrEqual(recoveryMap.buttons["world.visit"].frame.height, 44)
            XCTAssertTrue(recoveryMap.buttons["world.visit"].isHittable)
            capture("map-harness-recovery-extra-large-map", recoveryMap)
            for (id, name, status) in [
                ("silverPools", "Silver Pools", "Restore Seed Moon first"),
                ("firstLight", "Lantern Landing", "Restored"),
                ("ribbonCrossing", "Ribbon Crossing", "Ready to restore")
            ] {
                let marker = recoveryMap.buttons["world.node." + id]
                recoveryMap.revealWorldMapMarker(marker)
                marker.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
                XCTAssertTrue(XCTNSPredicateExpectation(
                    predicate: NSPredicate(format: "label == %@", name),
                    object: recoveryMap.staticTexts["world.selection"]).wait(timeout: 5))
                XCTAssertTrue(marker.isSelected)
                XCTAssertEqual(recoveryMap.staticTexts["world.status"].label, status)
                XCTAssertTrue(recoveryMap.staticTexts["world.recovery"].exists)
            }
        } else {
            XCTAssertFalse(recoveryMap.buttons["world.list"].exists,
                           "A measured Places fallback must not offer an ineffective map toggle")
            XCTAssertFalse(recoveryMap.buttons["world.node.firstLight"].exists)
            let places = recoveryMap.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "world.place."))
            XCTAssertEqual(places.count, 12, "Every destination remains available to inspect")
            for (index, destination) in destinations.enumerated() {
                let place = recoveryMap.buttons["world.place." + destination.0]
                XCTAssertEqual(place.label, destination.1)
                let status = index == 0 ? "Restored" : index == 1 ? "Ready to restore"
                    : "Restore " + destinations[index - 1].1 + " first"
                XCTAssertEqual(place.value as? String, status)
            }
            for (id, title) in [
                ("sunwheelMill", "Sunwheel Mill"),
                ("bellChoir", "Bell Choir"), ("starferryStation", "Starferry Station"),
                ("auroraFalls", "Aurora Falls"), ("petalBeacon", "Petal Beacon"), ("hollowCrown", "Hollow Crown")
            ] {
                let place = recoveryMap.buttons["world.place." + id]
                XCTAssertEqual(place.label, title)
                XCTAssertEqual(place.value as? String, "Not yet available")
            }
            let controls = [recoveryMap.staticTexts["world.recovery"], recoveryMap.staticTexts["world.selection"],
                            recoveryMap.staticTexts["world.status"], recoveryMap.buttons["world.visit"]]
            recoveryMap.revealSkyControls(controls)
            XCTAssertTrue(controls.allSatisfy { recoveryMap.frame.contains($0.frame) })
            capture("map-harness-recovery-extra-large-places", recoveryMap)
            let ribbon = recoveryMap.buttons["world.place.ribbonCrossing"]
            recoveryMap.revealSkyControls([ribbon])
            XCTAssertGreaterThanOrEqual(ribbon.frame.height, 44)
            ribbon.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", "Ribbon Crossing"),
                object: recoveryMap.staticTexts["world.selection"]).wait(timeout: 5))
            XCTAssertTrue(ribbon.isSelected)
        }
        tap("world.visit", recoveryMap); tap("sky.home", recoveryMap)
        XCTAssertEqual(recoveryMap.staticTexts["world.selection"].label, "Ribbon Crossing")
        XCTAssertEqual(recoveryMap.staticTexts["world.status"].label, "Ready to restore")
        if canvas.exists {
            recoveryMap.waitForVisibleWorldMapMarker(recoveryMap.buttons["world.node.ribbonCrossing"])
        } else {
            XCTAssertFalse(recoveryMap.buttons["world.list"].exists)
            XCTAssertTrue(recoveryMap.buttons["world.place.ribbonCrossing"].isSelected)
        }
        recoveryMap.terminate()

        let recovery = launch("recovery", textSize: "UICTContentSizeCategoryAccessibilityXXXL")
        defer { recovery.terminate() }
        XCTAssertFalse(recovery.buttons["world.list"].exists)
        XCTAssertFalse(recovery.buttons["world.node.firstLight"].exists)
        let message = recovery.staticTexts["world.recovery"]
        XCTAssertTrue(message.exists)
        XCTAssertTrue(message.label.hasPrefix("Some world progress could not be read."))
        XCTAssertTrue(message.label.hasSuffix("Your current sky is unchanged."))
        let readingScroll = recovery.scrollViews.containing(.staticText, identifier: "world.recovery").firstMatch
        XCTAssertTrue(readingScroll.waitForExistence(timeout: 5))
        let viewport = recovery.frame.intersection(readingScroll.frame).insetBy(dx: 1, dy: 1)
        let paragraphSize = message.frame.size
        XCTAssertGreaterThan(viewport.height, 80)
        XCTAssertGreaterThanOrEqual(message.frame.minY, viewport.minY, "The paragraph's beginning is initially visible")
        XCTAssertLessThanOrEqual(message.frame.minY + min(80, paragraphSize.height), viewport.maxY)
        var previousVisibleEnd: CGFloat?
        var reachedEnd = false
        // Prose may exceed one viewport. Read it with overlapping physical pans;
        // each retained capture supplies visible-line evidence beyond the AX label.
        for step in 0...8 {
            let frame = message.frame
            XCTAssertGreaterThanOrEqual(frame.minX, viewport.minX)
            XCTAssertLessThanOrEqual(frame.maxX, viewport.maxX, "Recovery prose fits without horizontal scrolling")
            XCTAssertEqual(frame.width, paragraphSize.width, accuracy: 1)
            XCTAssertEqual(frame.height, paragraphSize.height, accuracy: 1, "Reading must not shrink or truncate prose")
            let visibleStart = max(0, viewport.minY - frame.minY)
            let visibleEnd = min(frame.height, viewport.maxY - frame.minY)
            if let previousVisibleEnd {
                XCTAssertLessThanOrEqual(visibleStart, previousVisibleEnd - 44, "Reading steps retain visible overlap")
            }
            capture("map-harness-recovery-largest-text-reading-\(step)", recovery)
            if frame.maxY <= viewport.maxY {
                XCTAssertGreaterThanOrEqual(frame.maxY, viewport.minY + min(80, frame.height),
                                           "The final lines remain inside the viewport")
                reachedEnd = true
                break
            }
            guard step < 8 else { break }
            previousVisibleEnd = visibleEnd
            let start = recovery.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: frame.midX - recovery.frame.minX,
                dy: viewport.minY - recovery.frame.minY + viewport.height * 0.75))
            start.press(forDuration: 0.05,
                        thenDragTo: start.withOffset(CGVector(dx: 0, dy: -viewport.height * 0.45)),
                        withVelocity: .slow, thenHoldForDuration: 0.2)
            let movement = frame.minY - message.frame.minY
            XCTAssertGreaterThan(movement, 1, "A reading pan must advance through the paragraph")
            XCTAssertLessThanOrEqual(movement, viewport.height * 0.5,
                                    "A pan must not skip unread lines")
        }
        XCTAssertTrue(reachedEnd, "Reach the recovery paragraph's final line within eight overlapping pans")
        capture("map-harness-recovery-largest-text", recovery)
        tap("world.visit", recovery); tap("sky.home", recovery)
        XCTAssertEqual(recovery.staticTexts["world.selection"].label, "Ribbon Crossing")
        XCTAssertEqual(recovery.staticTexts["world.status"].label, "Ready to restore")
        tap("world.done", recovery)
        XCTAssertTrue(recovery.buttons["sky.resume"].waitForExistence(timeout: 5))
    }
}
