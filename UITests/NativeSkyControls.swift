import XCTest

extension XCUIApplication {
    /// Play the same production-rule witness validated by the hosted lifecycle tests.
    /// XCTest sends physical swipes; it cannot mutate the game's score or archive.
    @MainActor func completeStoryPattern(_ plan: StoryPatternPlan) {
        completeStoryPattern(plan, exchange: { source, destination, _ in
            // Most exchanges stay inside the already-visible board. Re-running
            // scroll discovery adds two one-second existence waits per move.
            // Keep the same native visibility/hit requirements, and scroll only
            // when either complete target actually needs to be revealed.
            let targets = source.frame.union(destination.frame)
            if !self.frame.contains(targets) || !source.isHittable || !destination.isHittable {
                self.revealSkyControls([source, destination])
            }
            XCTAssertTrue(source.isHittable && destination.isHittable)
            source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05,
                       thenDragTo: destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                       withVelocity: .fast, thenHoldForDuration: 0.05)
        }, shower: {
            let next = self.buttons["experiment.next"]
            self.revealSkyControls([next]); next.tap()
        })
    }

    /// Accessibility callers supply real VoiceOver action selection/activation.
    /// Both input paths retain the exact exchange, shower and terminal assertions.
    @MainActor func completeStoryPattern(_ plan: StoryPatternPlan,
                                         exchange: (XCUIElement, XCUIElement, String) throws -> Void,
                                         shower: () throws -> Void) rethrows {
        let next = buttons["experiment.next"]
        let board = otherElements["experiment.board"]
        let outcome = staticTexts["experiment.outcome"]
        var exchanged = 0, showers = 0
        func settled() {
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || (next.exists && next.isEnabled)
            }, object: nil).wait(timeout: 5),
            "Story did not settle after \(exchanged) exchanges and \(showers) showers; "
                + "board=\(String(describing: board.value)), score=\(self.staticTexts["experiment.score"].label)")
        }
        for (wave, moves) in plan.waves.enumerated() {
            settled()
            XCTAssertFalse(outcome.exists, "The witness must reach its actual final action")
            XCTAssertEqual(Int((board.value as? String ?? "").split(separator: " ").first ?? ""), wave)
            for move in moves {
                settled()
                let source = buttons[move.sourceIdentifier], destination = buttons[move.destinationIdentifier]
                XCTAssertTrue(source.exists && destination.exists && source.isEnabled)
                XCTAssertEqual(source.value as? String, "Automatic pattern play",
                               "A current story witness must not fall back to historical tap matching")
                try exchange(source, destination, move.accessibilityAction)
                exchanged += 1
            }
            settled()
            if outcome.exists { break }
            try shower()
            showers += 1
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                outcome.exists || Int((board.value as? String ?? "").split(separator: " ").first ?? "") == showers
            }, object: nil).wait(timeout: 5), "The explicit shower must commit exactly once")
        }
        XCTAssertTrue(outcome.waitForExistence(timeout: 5))
        XCTAssertEqual(exchanged, plan.expectedExchanges)
        XCTAssertEqual(showers, plan.expectedShowers)
        let score = "\(plan.expectedScore.formatted()) of \(plan.target.formatted()) starlight collected"
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", score),
                                                object: staticTexts["experiment.score"]).wait(timeout: 5),
                      "The terminal score must match the production-rule witness exactly")
    }

    /// Observe the app's initial scroll position without correcting it for the test.
    @MainActor func waitForVisibleWorldMapMarker(_ marker: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let canvas = scrollViews["world.canvas"]
        var lastObservation = "No visibility poll completed."
        let visible = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                let started = ContinuousClock.now
                let canvasExists = canvas.exists, markerExists = marker.exists
                guard canvasExists, markerExists else {
                    lastObservation = "canvasExists=\(canvasExists); markerExists=\(markerExists); "
                        + "pollDuration=\(started.duration(to: ContinuousClock.now))"
                    return false
                }
                // AX reads can be slow. Check one set of measured frames rather
                // than requesting the same target again for each predicate term.
                let viewport = self.frame.intersection(canvas.frame).insetBy(dx: 1, dy: 1)
                let target = marker.frame
                let hittable = marker.isHittable
                lastObservation = "canvasExists=\(canvasExists); markerExists=\(markerExists); "
                    + "target=\(target); viewport=\(viewport); hittable=\(hittable); "
                    + "pollDuration=\(started.duration(to: ContinuousClock.now))"
                return target.width >= 44 && target.height >= 44
                    && viewport.contains(target) && hittable
            }, object: nil).wait(timeout: 5)
        XCTAssertTrue(visible, "The selected destination must be fully visible without test scrolling. "
                      + lastObservation, file: file, line: line)
    }

    /// Scroll only the illustrated world, preserving the pinned destination card.
    @MainActor func revealWorldMapMarker(_ marker: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        let canvas = scrollViews["world.canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5),
                      "The illustrated world owns a dedicated scroll viewport", file: file, line: line)
        XCTAssertTrue(marker.waitForExistence(timeout: 5), file: file, line: line)
        var frames: [String] = []
        func fail(_ message: String) {
            XCTContext.runActivity(named: "Map target reachability frames") { activity in
                let attachment = XCTAttachment(string: frames.joined(separator: "\n"))
                attachment.name = "world-map-reveal-frames"
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            XCTFail(message, file: file, line: line)
        }
        let maximumGestures = 24
        var gestureBudget = maximumGestures
        // A longer world requires more travel. Fix the budget from its initial
        // measured distance, and observe after every gesture including the last.
        for attempt in 0...maximumGestures {
            let viewport = frame.intersection(canvas.frame).insetBy(dx: 1, dy: 1)
            let target = marker.frame
            frames.append("Attempt \(attempt + 1): \(marker.identifier) target=\(target) viewport=\(viewport)")
            guard viewport.width > 0, viewport.height > 0, viewport.height.isFinite,
                  target.minY.isFinite, target.maxY.isFinite,
                  target.width <= viewport.width, target.height <= viewport.height else {
                fail("A complete destination must fit inside the visible map canvas"); return
            }
            if attempt == 0 {
                let initialDistance = max(0, viewport.minY - target.minY, target.maxY - viewport.maxY)
                // Allow for pan recognition within each 55%-viewport gesture,
                // then reserve two gestures for the final edge alignment.
                let effectiveTravel = max(1, viewport.height * 0.55 - 16)
                let predictedGestures = (initialDistance / effectiveTravel).rounded(.up) + 2
                gestureBudget = Int(min(CGFloat(maximumGestures), max(2, predictedGestures)))
                frames.append("Traversal budget: initialDistance=\(initialDistance), viewportHeight=\(viewport.height), "
                              + "effectiveTravel=\(effectiveTravel), predictedGestures=\(predictedGestures), "
                              + "gestureBudget=\(gestureBudget), maximumGestures=\(maximumGestures)")
            }
            if viewport.contains(target) {
                XCTAssertTrue(marker.isHittable, file: file, line: line)
                XCTAssertGreaterThanOrEqual(marker.frame.width, 44, file: file, line: line)
                XCTAssertGreaterThanOrEqual(marker.frame.height, 44, file: file, line: line)
                return
            }
            guard attempt < gestureBudget else { break }
            let upward = target.maxY > viewport.maxY
            let distance = min(viewport.height * 0.55,
                               // Native pan recognition consumes about 10pt
                               // before scrolling starts; leave visible clearance.
                               max(32, upward ? target.maxY - viewport.maxY + 16 : viewport.minY - target.minY + 16))
            // Keep the held drag inside content. The trailing edge can grab
            // iOS's scroll-indicator thumb instead of panning the world.
            let start = coordinate(withNormalizedOffset: .zero).withOffset(CGVector(
                dx: viewport.minX - frame.minX + viewport.width * 0.12,
                dy: viewport.minY - frame.minY + viewport.height * (upward ? 0.75 : 0.25)))
            start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: upward ? -distance : distance)),
                        withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        frames.append("After final drag: target=\(marker.frame) viewport=\(frame.intersection(canvas.frame).insetBy(dx: 1, dy: 1))")
        fail("The destination did not become fully visible after bounded scrolling inside world.canvas")
    }

    /// Enter via the shipping world picker, preserving its explicit Begin ceremony.
    @MainActor func worldVisitControl(_ location: String) -> XCUIElement {
        if !otherElements["world.page"].exists {
            let map = skyMenuControl("sky.worldMap")
            revealSkyControls([map]); map.tap()
        }
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                self.buttons["world.node.firstLight"].exists || self.buttons["world.place.firstLight"].exists
            }, object: nil).wait(timeout: 5), "The world map must expose either native markers or its Places list")
        if buttons["world.node.firstLight"].exists {
            let list = buttons["world.list"]
            XCTAssertTrue(list.waitForExistence(timeout: 5))
            revealSkyControls([list]); list.tap()
        }
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

    @MainActor func waitForSkyElement(matching predicate: NSPredicate, timeout: TimeInterval,
                                     failure: String, file: StaticString = #filePath, line: UInt = #line) {
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
        let message = staticTexts["experiment.message"]
        if !message.exists {
            let reopen = buttons["sky.dialogue.reopen"]
            revealSkyControls([reopen], file: file, line: line)
            XCTAssertTrue(reopen.isEnabled, file: file, line: line)
            reopen.tap()
        }
        guard message.waitForExistence(timeout: 5) else {
            XCTFail("The guide must be open before reading its final line", file: file, line: line)
            return
        }
        revealSkyControls(actions, file: file, line: line)
        XCTAssertTrue(message.exists, "Revealing actions must retain the open guide", file: file, line: line)
        let inner = scrollViews.containing(.staticText, identifier: "experiment.message")
            .allElementsBoundByIndex.first { !$0.buttons["experiment.cell.0.0"].exists }
        if let inner {
            for _ in 0..<4 where message.frame.maxY > inner.frame.maxY + 1 { inner.swipeUp() }
            XCTAssertLessThanOrEqual(message.frame.maxY, inner.frame.maxY + 1, file: file, line: line)
        }
        XCTAssertTrue(message.exists, file: file, line: line)
        XCTAssertFalse(message.frame.isEmpty, file: file, line: line)
        XCTAssertTrue(message.isHittable, "The guide's final line must remain visible", file: file, line: line)
        XCTAssertLessThanOrEqual(message.frame.maxY, actions.map(\.frame.minY).min()!, file: file, line: line)
        XCTAssertTrue(actions.allSatisfy(\.isHittable), file: file, line: line)
    }
}
