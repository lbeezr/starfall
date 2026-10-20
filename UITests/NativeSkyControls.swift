import XCTest

extension XCUIApplication {
    /// Enter via the shipping world picker, preserving its explicit Begin ceremony.
    @MainActor func worldVisitControl(_ location: String) -> XCUIElement {
        let map = skyMenuControl("sky.worldMap")
        revealSkyControls([map]); map.tap()
        XCTAssertTrue(buttons["world.list"].waitForExistence(timeout: 5))
        if buttons["world.node.firstLight"].exists { buttons["world.list"].tap() }
        let place = buttons["world.place." + location]
        revealSkyMenuElement(place); revealSkyControls([place]); place.tap()
        let visit = buttons["world.visit"]
        revealSkyControls([visit])
        XCTAssertTrue(visit.isEnabled)
        return visit
    }

    /// Sample faster than the quiet forecast's one-second display cadence.
    /// Query membership avoids stale-element retries while the label changes.
    @MainActor func waitForApproachingShower(timeout: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
        waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label == %@",
            "experiment.arrivalCue", "Shower approaching"), timeout: timeout,
            failure: "The approaching forecast did not appear", file: file, line: line)
    }

    @MainActor func waitForSkyGuide(containing text: String, timeout: TimeInterval, file: StaticString = #filePath, line: UInt = #line) {
        waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label CONTAINS %@",
            "experiment.message", text), timeout: timeout,
            failure: "Missing guide: \(text)", file: file, line: line)
    }

    @MainActor private func waitForSkyElement(matching predicate: NSPredicate, timeout: TimeInterval,
                                              failure: String, file: StaticString, line: UInt) {
        let matches = descendants(matching: .any).matching(predicate)
        let deadline = ContinuousClock.now + .seconds(timeout)
        repeat {
            if matches.count == 1 { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while ContinuousClock.now < deadline
        XCTFail("\(failure) within \(timeout) seconds", file: file, line: line)
    }

    /// Physical input needs visible targets. Scroll through the non-playing edge so
    /// revealing a control cannot be interpreted as a swap or held constellation.
    @MainActor func revealSkyControls(_ controls: [XCUIElement], file: StaticString = #filePath, line: UInt = #line) {
        for control in controls {
            guard control.waitForExistence(timeout: 5) else {
                XCTFail("Missing sky control: \(control.identifier)", file: file, line: line); return
            }
        }
        // Fixed footer actions may legitimately reach the bottom of an SE screen;
        // scroll clipping and visible bars, rather than a guessed safe inset, bound input.
        var viewport = frame
        // A form sheet and an inner guide have smaller visible regions than the
        // application window. Use the actual owning scroll view, including on iPad.
        let scroll = controls.first.flatMap { first in
            scrollViews.containing(first.elementType, identifier: first.identifier).allElementsBoundByIndex
                .filter { candidate in controls.allSatisfy { candidate.descendants(matching: $0.elementType)[$0.identifier].exists } }
                .min { $0.frame.width * $0.frame.height < $1.frame.width * $1.frame.height }
        }
        if let scroll { viewport = viewport.intersection(scroll.frame) }
        // A scroll row can report hittable behind a floating navigation bar.
        // Toolbar buttons themselves remain valid in that bar.
        let toolbarTargets = controls.allSatisfy { navigationBars.buttons.matching(identifier: $0.identifier).firstMatch.exists }
        let visibleBar = navigationBars.allElementsBoundByIndex.last {
            $0.buttons.allElementsBoundByIndex.contains(where: \.isHittable)
                || $0.staticTexts.allElementsBoundByIndex.contains(where: \.isHittable)
        }
        if !toolbarTargets, let bar = visibleBar {
            let top = max(viewport.minY, bar.frame.maxY - 1)
            viewport = CGRect(x: viewport.minX, y: top, width: viewport.width, height: max(0, viewport.maxY - top))
        }
        for _ in 0..<8 {
            let bounds = controls.map(\.frame).reduce(CGRect.null) { $0.union($1) }
            if viewport.contains(bounds) {
                XCTAssertTrue(controls.allSatisfy(\.isHittable), "Visible sky controls must accept physical input", file: file, line: line)
                return
            }
            guard bounds.height <= viewport.height else {
                XCTFail("Requested sky targets cannot fit together", file: file, line: line); return
            }
            let up = bounds.maxY > viewport.maxY
            let distance = min(frame.height * 0.45, max(24, up ? bounds.maxY - viewport.maxY + 8 : viewport.minY - bounds.minY + 8))
            let surface = scroll ?? self
            let containsBoard = scroll?.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).firstMatch.exists ?? true
            let scrollX = !containsBoard || visibleBar != nil ? 0.12 : 0.002
            let start = surface.coordinate(withNormalizedOffset: CGVector(dx: scrollX, dy: up ? 0.75 : 0.25))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: up ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTFail("Sky controls did not become fully visible", file: file, line: line)
    }

    /// Read an inner fixed-height guide if present; a flowing guide instead moves
    /// with the page. Both must end above reachable actions without changing play.
    @MainActor func readSkyGuideToEnd(actions: [XCUIElement], file: StaticString = #filePath, line: UInt = #line) {
        revealSkyControls(actions, file: file, line: line)
        let message = staticTexts["experiment.message"]
        let inner = scrollViews.containing(.staticText, identifier: "experiment.message")
            .allElementsBoundByIndex.first { !$0.buttons["experiment.cell.0.0"].exists }
        if let inner {
            for _ in 0..<4 where message.frame.maxY > inner.frame.maxY + 1 { inner.swipeUp() }
            XCTAssertLessThanOrEqual(message.frame.maxY, inner.frame.maxY + 1, file: file, line: line)
        }
        XCTAssertLessThanOrEqual(message.frame.maxY, actions.map(\.frame.minY).min()!, file: file, line: line)
        XCTAssertTrue(actions.allSatisfy(\.isHittable), file: file, line: line)
    }
}
