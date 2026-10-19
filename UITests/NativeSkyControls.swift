import XCTest

extension XCUIApplication {
    /// Physical input needs visible targets. Scroll through the non-playing edge so
    /// revealing a control cannot be interpreted as a swap or held constellation.
    @MainActor func revealSkyControls(_ controls: [XCUIElement], file: StaticString = #filePath, line: UInt = #line) {
        for control in controls {
            guard control.waitForExistence(timeout: 5) else {
                XCTFail("Missing sky control: \(control.identifier)", file: file, line: line); return
            }
        }
        let viewport = frame.insetBy(dx: 0, dy: 22)
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
            let start = coordinate(withNormalizedOffset: CGVector(dx: 0.002, dy: up ? 0.75 : 0.25))
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
