import XCTest
import UIKit

final class FullBoardChoiceInteractionTests: XCTestCase {
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
        XCTAssertTrue(source.isEnabled && target.isEnabled)
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

    @MainActor func testOptionalAlternativesPreserveRoundAndReturnToOrdinaryPlay() throws {
        let app = launch()
        drag(8, 9, score: 66_000, app)
        let before = try cells(app)
        tap("experiment.settings", app)
        tap("fullBoard.choices.open", app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.1"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["fullBoard.choices.pattern.0"].label, "Square · 4 stars in the first clear")
        XCTAssertEqual(app.staticTexts["fullBoard.choices.pattern.1"].label, "Line · 4 stars in the first clear")
        XCTAssertFalse(app.staticTexts["fullBoard.choices.step.0.0"].exists)
        capture("depth02-default-phone-visible-options", app)
        tap("sky.menu.back", app)
        tap("fullBoard.choices.open", app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.1"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["fullBoard.choices.step.0.0"].exists)
        tap("fullBoard.choices.reveal.0", app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.0.0"].label, "1. Swipe up from row 7, column 4.")
        tap("fullBoard.choices.reveal.1", app)
        XCTAssertEqual(app.staticTexts["fullBoard.choices.step.1.0"].label, "1. Swipe right from row 5, column 2.")
        capture("depth02-default-phone-revealed-options", app)
        tap("experiment.done", app)
        XCTAssertEqual(try cells(app), before)
        drag(3, 10, score: 81_000, app)
        tap("experiment.settings", app)
        tap("sky.home", app)
        tap("sky.resume", app)
        XCTAssertTrue(app.staticTexts["experiment.score"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "81,000 of 150,000 starlight collected")
        tap("experiment.settings", app)
        tap("sky.home", app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fallingSky", app)
        tap("sky.lanternMode.fullBoard", app)
    }

    @MainActor func testLargestTextSetupAdviceSurvivesBackgroundAndDoesNotPlayForYou() throws {
        let app = launch(largest: true)
        for move in [(8, 9, 66_000), (3, 10, 81_000), (5, 12, 86_000), (33, 40, 91_000), (24, 31, 106_000)] {
            drag(move.0, move.1, score: move.2, app)
        }
        let before = try cells(app)
        tap("experiment.settings", app)
        tap("fullBoard.choices.open", app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.0"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["fullBoard.choices.pattern.1"].exists)
        tap("fullBoard.choices.reveal.0", app)
        let second = app.staticTexts["fullBoard.choices.step.0.1"]
        if !second.isHittable { app.revealSkyMenuElement(second) }
        XCTAssertEqual(second.label, "2. Swipe up from row 6, column 2.")
        XCTAssertTrue(second.isHittable)
        capture("depth02-largest-quiet-setup", app)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 10))
        tap("experiment.done", app)
        XCTAssertEqual(try cells(app), before)
        drag(1, 2, score: 106_000, app)
        drag(8, 15, score: 111_000, app)
        capture("depth02-largest-quiet-after-setup", app)
    }
}
