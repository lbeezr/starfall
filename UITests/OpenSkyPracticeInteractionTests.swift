import XCTest
import UIKit

/// Real optional practice preserves the separately committed current Story round.
final class OpenSkyPracticeInteractionTests: XCTestCase {
    private let prompt = "Open Sky: hold, trace five of six Aqua stars, then lift. Your drawing returns; one stays."
    private let complete = "Five helpers share light as your drawing returns. One Aqua stays. Retry to choose again."
    private let retryMessage = "That changed the setup. Retry to practice this sequence."

    private struct RetainedRound {
        let score: String
        let board: String?
        let cells: [String]
        let world: [String]
    }

    @MainActor private func tap(_ identifier: String, _ app: XCUIApplication) {
        let control = app.buttons[identifier]
        if !control.exists { app.revealSkyMenuElement(control) }
        app.revealSkyControls([control])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: control).wait(timeout: 5), identifier)
        control.tap()
    }

    @MainActor private func identities(_ root: XCUIElement, prefix: String) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button && node.identifier.hasPrefix(prefix) {
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try root.snapshot())
        return result.sorted()
    }

    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func launchPausedRound(largest: Bool = false) throws -> (XCUIApplication, RetainedRound) {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review"]
        if !largest { app.launchArguments += ["-calmEffects", "NO"] }
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        let visit = app.worldVisitControl("firstLight")
        let world = try identities(app, prefix: "world.place.")
        XCTAssertEqual(world.count, 12)
        visit.tap(); tap("sky.begin", app)
        // Enter pause from an admitted playing board, not its first visible header.
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                                object: app.buttons["experiment.cell.1.1"]).wait(timeout: 5))
        tap("experiment.settings", app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Pause sky"),
                                                object: app.buttons["experiment.pause"]).wait(timeout: 5))
        tap("experiment.pause", app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["experiment.next"]).wait(timeout: 5))
        XCTAssertTrue((board.value as? String)?.hasPrefix("0 showers") == true)
        XCTAssertEqual(app.otherElements["sky.header"].value as? String, "Falling Sky")
        let source = app.buttons["experiment.cell.1.1"], target = app.buttons["experiment.cell.1.2"]
        app.revealSkyControls([source, target])
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "15,000 of 150,000 starlight collected"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["experiment.next"]).wait(timeout: 5))
        let cells = try identities(board, prefix: "experiment.cell.")
        XCTAssertEqual(cells.count, 49)
        return (app, RetainedRound(score: app.staticTexts["experiment.score"].label,
                                   board: board.value as? String, cells: cells, world: world))
    }

    @MainActor private func openTrace(_ app: XCUIApplication) {
        tap("experiment.settings", app)
        app.skyMenuControl("sky.learn").tap()
        tap("tutorial.chapter.trace", app)
        XCTAssertTrue(app.staticTexts["tutorial.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tutorial.chapter.match"].exists)
        XCTAssertFalse(app.buttons["tutorial.done"].exists)
        assertOpening(app)
    }

    @MainActor private func expectInstruction(_ value: String, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", value), object: app.staticTexts["tutorial.instruction"]).wait(timeout: 5))
    }

    @MainActor private func practiceScore(_ value: Int, _ app: XCUIApplication) {
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "\(value) starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
    }

    @MainActor private func assertOpening(_ app: XCUIApplication) {
        expectInstruction(prompt, app); practiceScore(0, app)
        XCTAssertEqual(app.buttons["tutorial.hint"].label, "Hint")
        XCTAssertFalse(app.staticTexts["tutorial.detail"].exists)
        XCTAssertFalse(app.staticTexts["tutorial.coordinates"].exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Aqua'")).count, 6)
    }

    @MainActor private func draw(_ from: Int, _ to: Int, _ app: XCUIApplication) {
        let source = app.buttons["experiment.cell.0.\(from)"], target = app.buttons["experiment.cell.0.\(to)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(source.isEnabled && target.isEnabled)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.4, thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .slow, thenHoldForDuration: 0.45)
    }

    @MainActor private func readInstruction(_ app: XCUIApplication, captureName: String, singleViewport: Bool = false) {
        let instruction = app.staticTexts["tutorial.instruction"], hint = app.buttons["tutorial.hint"]
        app.revealSkyControls([hint])
        let inner = app.scrollViews.containing(.staticText, identifier: instruction.identifier)
            .allElementsBoundByIndex.first { !$0.buttons["experiment.cell.0.0"].exists }
        if let inner {
            let viewport = app.frame.intersection(inner.frame)
            if singleViewport {
                XCTAssertGreaterThanOrEqual(instruction.frame.minY, viewport.minY - 1)
                XCTAssertLessThanOrEqual(instruction.frame.maxY, viewport.maxY + 1)
            }
            for _ in 0..<6 where instruction.frame.minY < viewport.minY - 1 { inner.swipeDown() }
            XCTAssertGreaterThanOrEqual(instruction.frame.minY, viewport.minY - 1)
            XCTAssertLessThan(instruction.frame.minY, viewport.maxY)
            capture(captureName + "-start", app)
            for _ in 0..<6 where instruction.frame.maxY > viewport.maxY + 1 { inner.swipeUp() }
            XCTAssertLessThanOrEqual(instruction.frame.maxY, viewport.maxY + 1)
            XCTAssertGreaterThan(instruction.frame.maxY, viewport.minY)
        } else {
            app.revealSkyControls([instruction, hint])
        }
        XCTAssertTrue(instruction.isHittable)
        XCTAssertLessThanOrEqual(instruction.frame.maxY, hint.frame.minY)
        capture(captureName + "-end", app)
    }

    @MainActor private func assertChosenFive(_ app: XCUIApplication, retainedColumn: Int, label: String) {
        practiceScore(5, app); expectInstruction(complete, app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'experiment.cell.' AND label CONTAINS 'Aqua'")).count, 1)
        XCTAssertEqual(app.buttons["experiment.cell.0.\(retainedColumn)"].label, label)
        for column in 0..<6 where column != retainedColumn {
            XCTAssertTrue(app.buttons["experiment.cell.0.\(column)"].label.hasPrefix("Empty"))
        }
        // Completion observes the committed choice, not animation completion.
    }

    @MainActor private func exitAndVerify(_ app: XCUIApplication, retained: RetainedRound, largest: Bool = false) throws {
        tap("experiment.settings", app); tap("tutorial.done", app)
        let board = app.otherElements["experiment.board"]
        func assertRound() throws {
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.staticTexts["experiment.score"].label == retained.score
                    && app.buttons["experiment.next"].isEnabled
            }, object: nil).wait(timeout: 5))
            XCTAssertEqual(app.staticTexts["experiment.score"].label, retained.score)
            XCTAssertEqual(board.value as? String, retained.board)
            XCTAssertEqual(try identities(board, prefix: "experiment.cell."), retained.cells)
            XCTAssertTrue(app.buttons["experiment.next"].isEnabled)
        }
        try assertRound()
        tap("experiment.settings", app); app.skyMenuControl("sky.worldMap").tap()
        if app.buttons["world.list"].exists && app.buttons["world.list"].label == "Places" { tap("world.list", app) }
        XCTAssertTrue(app.buttons["world.place.firstLight"].waitForExistence(timeout: 5))
        XCTAssertEqual(try identities(app, prefix: "world.place."), retained.world)
        tap("world.done", app); try assertRound()
        app.terminate(); app.launchArguments = ["--sky-flow-review"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch(); tap("sky.resume", app); try assertRound()
        capture(largest ? "open-sky-practice-largest-round-restored" : "open-sky-practice-round-restored", app)
    }

    @MainActor func testOpenSkyTraceChoosesEitherEndAndPreservesCurrentRound() throws {
        executionTimeAllowance = 180
        let (app, retained) = try launchPausedRound(); defer { app.terminate() }
        openTrace(app)
        let opening = try identities(app.otherElements["experiment.board"], prefix: "experiment.cell.")
        let left = app.buttons["experiment.cell.0.0"].label, right = app.buttons["experiment.cell.0.5"].label
        capture("open-sky-practice-prompt-hint-closed", app)
        readInstruction(app, captureName: "open-sky-practice-phone-prompt", singleViewport: true)
        tap("tutorial.hint", app)
        XCTAssertTrue(app.staticTexts["tutorial.detail"].exists)
        XCTAssertTrue(app.staticTexts["tutorial.coordinates"].exists)
        tap("tutorial.retry", app); assertOpening(app)
        draw(0, 3, app); practiceScore(0, app); expectInstruction(prompt, app)
        XCTAssertEqual(try identities(app.otherElements["experiment.board"], prefix: "experiment.cell."), opening)
        draw(0, 5, app); practiceScore(6, app); expectInstruction(retryMessage, app)
        tap("tutorial.retry", app); assertOpening(app)
        tap("experiment.cell.0.0", app); practiceScore(6, app); expectInstruction(retryMessage, app)
        tap("tutorial.retry", app); assertOpening(app)
        draw(0, 4, app); assertChosenFive(app, retainedColumn: 5, label: right)
        readInstruction(app, captureName: "open-sky-practice-phone-complete", singleViewport: true)
        capture("open-sky-practice-first-five-complete", app)
        tap("tutorial.retry", app); assertOpening(app)
        XCTAssertEqual(try identities(app.otherElements["experiment.board"], prefix: "experiment.cell."), opening)
        draw(1, 5, app); assertChosenFive(app, retainedColumn: 0, label: left)
        capture("open-sky-practice-rightmost-five-complete", app)
        tap("tutorial.retry", app); assertOpening(app)
        try exitAndVerify(app, retained: retained)
    }

    @MainActor func testTabletLargestTextCalmTraceKeepsHintOptionalAndRoundSafe() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("Tablet AX3XL acceptance") }
        executionTimeAllowance = 180
        let (app, retained) = try launchPausedRound(largest: true); defer { app.terminate() }
        func preferences() {
            tap("experiment.settings", app); app.skyMenuControl("experiment.preferences").tap()
        }
        preferences()
        let calm = app.switches["experiment.calm"]
        XCTAssertTrue(calm.waitForExistence(timeout: 5)); app.revealSkyControls([calm])
        let originalCalm = calm.value as? String == "1"
        // Reuse the toggle helper on the app's Calm switch, not system Reduce Motion.
        NativeSystemMotionSettings.set(true, on: calm); XCTAssertEqual(calm.value as? String, "1")
        tap("experiment.done", app)
        defer {
            preferences(); XCTAssertTrue(calm.waitForExistence(timeout: 5)); app.revealSkyControls([calm])
            NativeSystemMotionSettings.set(originalCalm, on: calm); tap("experiment.done", app)
        }
        openTrace(app)
        readInstruction(app, captureName: "open-sky-practice-largest-calm-prompt")
        tap("tutorial.hint", app)
        XCTAssertTrue(app.staticTexts["tutorial.detail"].exists)
        XCTAssertTrue(app.staticTexts["tutorial.coordinates"].exists)
        XCTAssertTrue(app.staticTexts["tutorial.instruction"].label.hasPrefix("Hold, then draw:"))
        readInstruction(app, captureName: "open-sky-practice-largest-calm-hint")
        tap("tutorial.retry", app); assertOpening(app)
        let right = app.buttons["experiment.cell.0.5"].label
        draw(0, 4, app); assertChosenFive(app, retainedColumn: 5, label: right)
        readInstruction(app, captureName: "open-sky-practice-largest-calm-complete")
        tap("tutorial.retry", app); assertOpening(app)
        try exitAndVerify(app, retained: retained, largest: true)
    }
}
