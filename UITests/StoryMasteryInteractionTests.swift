import XCTest
import UIKit

/// Both wins use complete production-action witnesses. Review arguments isolate
/// persistence; no board, score, mastery flags or repair records are injected.
final class StoryMasteryInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .lantern }

    private let fullBoardMoves: [(from: Int, to: Int, score: Int)] = [
        (27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000), (12, 13, 63_000),
        (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
        (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)
    ]

    private func arguments(largest: Bool, quiet: Bool, reset: Bool) -> [String] {
        var result = ["--sky-flow-review", "-calmEffects", quiet ? "YES" : "NO"]
        if reset { result.append("--starfalls-reset") }
        if largest {
            result += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        return result
    }

    @MainActor private func fresh(largest: Bool, quiet: Bool) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = arguments(largest: largest, quiet: quiet, reset: true)
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        app.worldVisitControl("firstLight").tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Lantern Landing")
        return app
    }

    @MainActor private func tapControl(_ identifier: String, in app: XCUIApplication) {
        let button = app.buttons[identifier]
        if !button.exists { app.revealSkyMenuElement(button) }
        XCTAssertTrue(button.waitForExistence(timeout: 5), identifier)
        app.revealSkyControls([button])
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), identifier)
        button.tap()
    }

    @MainActor private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @MainActor private func goal(_ name: String, context: String, in app: XCUIApplication) -> XCUIElement {
        element("sky.mastery.\(context).goal.\(name)", in: app)
    }

    @MainActor private func assertGoals(_ context: String, fullBoard: Bool, earned: Set<String>, in app: XCUIApplication) {
        let names = fullBoard ? ["cascade", "largeClear"] : ["grownCollection", "cascade"]
        for name in names {
            let row = goal(name, context: context, in: app)
            XCTAssertTrue(row.waitForExistence(timeout: 5), name)
            let state = earned.contains(name) ? "Earned this run"
                : context == "result" ? "Not earned this run" : "Not yet this run"
            XCTAssertEqual(row.value as? String, state)
        }
        XCTAssertFalse(goal(fullBoard ? "grownCollection" : "largeClear", context: context, in: app).exists)
        app.revealSkyControls(names.map { goal($0, context: context, in: app) })
        if fullBoard {
            XCTAssertTrue(goal("largeClear", context: context, in: app).label.contains("Clear 8 stars at once"))
            XCTAssertTrue(goal("cascade", context: context, in: app).label.contains("gaps refill"))
        } else {
            XCTAssertTrue(goal("grownCollection", context: context, in: app).label.contains("grown colored star"))
        }
    }

    @MainActor private func assertBest(_ context: String, in app: XCUIApplication) {
        let best = app.staticTexts["sky.mastery.\(context).best"]
        XCTAssertTrue(best.waitForExistence(timeout: 5))
        XCTAssertTrue(best.label.contains("3 of 3 stars from one completed run"))
    }

    @MainActor private func begin(_ app: XCUIApplication) {
        let begin = app.buttons["sky.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        app.revealSkyControls([begin])
        XCTAssertGreaterThanOrEqual(begin.frame.height, 44)
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: begin).wait(timeout: 5))
        begin.tap()
    }

    @MainActor private func waitFullBoard(exchanges: Int, score: Int, in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let text = "\(score.formatted()) of 150,000 starlight collected"
        let disabled = app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = board.value as? String ?? ""
            return board.exists && value.hasPrefix("Exchanges: \(exchanges). Full Board.")
                && !value.contains("Stars settling") && app.staticTexts["experiment.score"].label == text
                && app.buttons["experiment.cell.0.0"].isEnabled && disabled.count == 0
        }, object: nil).wait(timeout: 12), "Full Board must settle exchange \(exchanges) at \(score)")
    }

    @MainActor private func waitSky(score: Int, showers: Int, in app: XCUIApplication) {
        let board = app.otherElements["experiment.board"]
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let value = board.value as? String ?? ""
            return board.exists && value.hasPrefix("\(showers) showers") && !value.contains("Stars settling")
                && next.exists && next.isEnabled
                && app.staticTexts["experiment.score"].label == "\(score.formatted()) of 150,000 starlight collected"
        }, object: nil).wait(timeout: 12))
    }

    @MainActor private func exchange(_ source: XCUIElement, _ target: XCUIElement, in app: XCUIApplication) {
        if !app.frame.contains(source.frame.union(target.frame)) || !source.isHittable || !target.isHittable {
            app.revealSkyControls([source, target])
        }
        XCTAssertTrue(source.isHittable && target.isHittable && source.isEnabled && target.isEnabled)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func state(_ app: XCUIApplication) throws -> [String] {
        var cells: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button && node.identifier.hasPrefix("experiment.cell.") {
                cells.append(node.identifier + ":" + node.label)
            }
            node.children.forEach(visit)
        }
        visit(try app.otherElements["experiment.board"].snapshot())
        XCTAssertEqual(cells.count, 49)
        return cells.sorted()
    }

    @MainActor private func assertWin(score: Int, fullBoard: Bool, in app: XCUIApplication) {
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("\(score.formatted()) of 150,000 starlight collected"))
        let rating = element("sky.mastery.result.rating", in: app)
        XCTAssertTrue(rating.waitForExistence(timeout: 5))
        XCTAssertEqual(rating.label, "3 of 3 stars earned")
        assertGoals("result", fullBoard: fullBoard,
                    earned: fullBoard ? ["cascade", "largeClear"] : ["grownCollection", "cascade"], in: app)
        app.revealSkyControls([rating])
        XCTAssertFalse(app.buttons["experiment.next"].exists)
    }

    @MainActor private func inspectModeBests(fullBoard: Bool, in app: XCUIApplication) {
        tapControl("sky.worldMap", in: app)
        _ = app.worldVisitControl("firstLight")
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Lantern Landing")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restored")
        let sky = app.staticTexts["world.mastery.fallingSky"]
        let full = app.staticTexts["world.mastery.fullBoard"]
        XCTAssertTrue(sky.waitForExistence(timeout: 5) && full.waitForExistence(timeout: 5))
        XCTAssertEqual(sky.label, fullBoard ? "Falling Sky: no result for these optional goals yet" : "Falling Sky best: 3 of 3 stars")
        XCTAssertEqual(full.label, fullBoard ? "Full Board best: 3 of 3 stars" : "Full Board: no result for these optional goals yet")
        app.revealSkyControls([sky, full])
        capture(app, fullBoard ? "mastery-normal-full-board-map-best" : "mastery-largest-sky-map-best")
        tapControl("world.done", in: app)
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
    }

    @MainActor private func relaunch(_ app: XCUIApplication, largest: Bool, quiet: Bool, fullBoard: Bool) {
        app.terminate()
        app.launchArguments = arguments(largest: largest, quiet: quiet, reset: false)
        app.launch()
        let resume = app.buttons["sky.resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        let summary = app.staticTexts["sky.subtitle"].label
        XCTAssertTrue(summary.contains(fullBoard ? "Lantern Landing · Full Board" : "First Light"))
        XCTAssertEqual(summary.contains("Full Board"), fullBoard)
        tapControl("sky.resume", in: app)
    }

    @MainActor func testNormalFullBoardGoalsWinRestoreAndReplay() throws {
        executionTimeAllowance = 600
        setSystemMotion(reduced: false)
        let app = fresh(largest: false, quiet: false)
        defer { app.terminate() }
        tapControl("sky.lanternMode.fullBoard", in: app)
        XCTAssertTrue(app.buttons["sky.lanternMode.fullBoard"].isSelected)
        assertGoals("entry", fullBoard: true, earned: [], in: app)
        XCTAssertFalse(app.staticTexts["sky.mastery.entry.best"].exists)
        capture(app, "mastery-normal-full-board-entry-goals")
        begin(app)
        waitFullBoard(exchanges: 0, score: 0, in: app)
        let opening = try state(app)
        XCTAssertFalse(element("sky.forecast.destinations", in: app).exists)

        for (index, move) in fullBoardMoves.enumerated() {
            exchange(app.buttons["experiment.cell.\(move.from / 7).\(move.from % 7)"],
                     app.buttons["experiment.cell.\(move.to / 7).\(move.to % 7)"], in: app)
            if move.score < 150_000 { waitFullBoard(exchanges: index + 1, score: move.score, in: app) }
            if index == 0 {
                tapControl("experiment.settings", in: app)
                assertGoals("progress", fullBoard: true, earned: ["cascade"], in: app)
                XCTAssertFalse(app.staticTexts["sky.mastery.progress.rating"].exists)
                capture(app, "mastery-normal-full-board-chain-progress")
                tapControl("experiment.done", in: app)
                waitFullBoard(exchanges: 1, score: 42_000, in: app)
            }
        }
        assertWin(score: 156_000, fullBoard: true, in: app)
        capture(app, "mastery-normal-full-board-earned-three-stars")
        inspectModeBests(fullBoard: true, in: app)
        relaunch(app, largest: false, quiet: false, fullBoard: true)
        assertWin(score: 156_000, fullBoard: true, in: app)
        capture(app, "mastery-normal-full-board-restored-winner")

        tapControl("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fallingSky"].exists)
        assertGoals("entry", fullBoard: true, earned: [], in: app)
        assertBest("entry", in: app)
        capture(app, "mastery-normal-full-board-replay-goals-best")
        begin(app)
        waitFullBoard(exchanges: 0, score: 0, in: app)
        XCTAssertEqual(try state(app), opening)
        relaunch(app, largest: false, quiet: false, fullBoard: true)
        waitFullBoard(exchanges: 0, score: 0, in: app)
        XCTAssertEqual(try state(app), opening)
        tapControl("experiment.settings", in: app)
        assertGoals("progress", fullBoard: true, earned: [], in: app)
        assertBest("progress", in: app)
        capture(app, "mastery-normal-full-board-restored-replay-progress")
    }

    @MainActor func testLargestCalmFallingSkyGoalsWinRestoreAndReplay() throws {
        executionTimeAllowance = 900
        setSystemMotion(reduced: false)
        let app = fresh(largest: true, quiet: true)
        defer { app.terminate() }
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        assertGoals("entry", fullBoard: false, earned: [], in: app)
        XCTAssertFalse(app.staticTexts["sky.mastery.entry.best"].exists)
        capture(app, "mastery-largest-sky-entry-goals")
        begin(app)
        pauseRunningSky(app)
        waitSky(score: 0, showers: 0, in: app)
        let opening = try state(app)
        var exchanges = 0
        app.completeStoryPattern(.lantern, exchange: { source, target, _ in
            self.exchange(source, target, in: app)
            exchanges += 1
            if exchanges == 1 {
                self.waitSky(score: 15_000, showers: 0, in: app)
                self.tapControl("experiment.settings", in: app)
                self.assertGoals("progress", fullBoard: false, earned: ["cascade"], in: app)
                XCTAssertFalse(app.staticTexts["sky.mastery.progress.rating"].exists)
                self.capture(app, "mastery-largest-sky-chain-progress")
                self.tapControl("experiment.done", in: app)
            }
        }, shower: { self.tapControl("experiment.next", in: app) })
        XCTAssertEqual(exchanges, 75)
        assertWin(score: 151_000, fullBoard: false, in: app)
        capture(app, "mastery-largest-sky-earned-three-stars")
        inspectModeBests(fullBoard: false, in: app)
        relaunch(app, largest: true, quiet: true, fullBoard: false)
        assertWin(score: 151_000, fullBoard: false, in: app)
        capture(app, "mastery-largest-sky-restored-winner")

        tapControl("experiment.replay", in: app)
        XCTAssertFalse(app.buttons["sky.lanternMode.fullBoard"].exists)
        assertGoals("entry", fullBoard: false, earned: [], in: app)
        assertBest("entry", in: app)
        capture(app, "mastery-largest-sky-replay-goals-best")
        begin(app)
        pauseRunningSky(app)
        waitSky(score: 0, showers: 0, in: app)
        XCTAssertEqual(try state(app), opening)
        tapControl("experiment.settings", in: app)
        assertGoals("progress", fullBoard: false, earned: [], in: app)
        assertBest("progress", in: app)
        capture(app, "mastery-largest-sky-replay-cleared-goals")
    }
}
