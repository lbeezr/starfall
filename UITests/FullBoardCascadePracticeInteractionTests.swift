import XCTest
import UIKit

final class FullBoardCascadePracticeInteractionTests: XCTestCase {
    @MainActor private func launch(largest: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        if !largest {
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
        let app = XCUIApplication()
        app.launchArguments = ["--sky-flow-review", "--starfalls-reset", "-calmEffects", largest ? "YES" : "NO"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", app)
        tap("sky.begin", app)
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 10))
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

    @MainActor private func drag(_ from: Int, _ to: Int, score: Int, _ app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in source.isEnabled && target.isEnabled }, object: nil).wait(timeout: 10))
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
            "\(score.formatted()) of 150,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 10))
        let blocked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in blocked.count == 0 }, object: nil).wait(timeout: 10))
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

    @MainActor private func compare(largest: Bool) throws {
        let app = launch(largest: largest)
        defer { app.terminate() }
        drag(8, 9, score: 66_000, app)
        let retained = try cells(app)
        tap("experiment.settings", app)
        tap("fullBoard.choices.open", app)
        tap("fullBoard.choices.practice", app)
        let title = app.staticTexts["tutorial.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        XCTAssertEqual(title.label, "Keep a follow-up")
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCTAssertFalse(app.staticTexts["tutorial.coordinates"].exists)
        let opening = try cells(app)
        drag(3, 10, score: 81_000, app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("15,000"))
        capture(largest ? "depth03-largest-survivor-chain" : "depth03-default-survivor-chain", app)
        tap("tutorial.next", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Compare the larger clear"), object: title).wait(timeout: 10))
        XCTAssertEqual(try cells(app), opening, "Both decisions start from the same visible ingredients")
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        tap("tutorial.hint", app)
        XCTAssertTrue(app.staticTexts["tutorial.coordinates"].exists)
        tap("tutorial.retry", app)
        XCTAssertEqual(try cells(app), opening)
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        drag(8, 15, score: 79_000, app)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.contains("13,000"))
        if largest {
            let reading = app.scrollViews.containing(.staticText, identifier: "tutorial.instruction").firstMatch
            if reading.exists { reading.swipeUp() }
        }
        capture(largest ? "depth03-largest-larger-clear" : "depth03-default-larger-clear", app)
        XCTAssertFalse(app.buttons["tutorial.next"].exists)
        tap("tutorial.finish", app)
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        XCTAssertFalse(title.exists)
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "66,000 of 150,000 starlight collected")
        XCTAssertEqual(try cells(app), retained, "Disposable comparisons must not play or archive the retained round")
        if !largest {
            tap("experiment.settings", app)
            tap("sky.learn", app)
            tap("tutorial.chapter.fullBoardImmediate", app)
            XCTAssertTrue(title.waitForExistence(timeout: 10))
            XCTAssertTrue(app.buttons["tutorial.next"].exists, "General Tutorial keeps its complete catalogue sequence")
            tap("tutorial.next", app)
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Match and collect"), object: title).wait(timeout: 10))
        }
    }

    @MainActor func testNormalMotionComparisonShowsSurvivorsAndReturnsTheExactRound() throws {
        try compare(largest: false)
    }

    @MainActor func testLargestQuietComparisonRetainsBothChoicesAndBackgroundReturn() throws {
        try compare(largest: true)
    }
}
