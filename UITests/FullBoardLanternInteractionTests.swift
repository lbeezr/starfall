import XCTest
import UIKit

/// Physical inputs for the ten-exchange witness independently replayed by Core.
/// No app state, archive bytes, scores or board contents are injected by this suite.
final class FullBoardLanternInteractionTests: XCTestCase {
    private let winningMoves: [(from: Int, to: Int, score: Int)] = [
        (27, 34, 42_000), (1, 2, 47_000), (31, 32, 54_000), (12, 13, 63_000),
        (16, 17, 78_000), (8, 9, 83_000), (11, 12, 88_000),
        (29, 30, 93_000), (29, 36, 98_000), (9, 16, 156_000)
    ]

    @MainActor private func requireNormalMotion() {
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

    private func arguments(largest: Bool, quiet: Bool, reset: Bool) -> [String] {
        var result = ["--sky-flow-review", "-calmEffects", quiet ? "YES" : "NO"]
        if reset { result.append("--starfalls-reset") }
        if largest { result += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        return result
    }

    @MainActor private func launch(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = arguments(largest: largest, quiet: quiet, reset: true)
        app.launch()
        XCTAssertTrue(app.buttons["sky.worldMap"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = app.buttons[id]
        if button.exists {
            XCTAssertTrue(XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: button).wait(timeout: 5), id)
        } else {
            app.revealSkyMenuElement(button)
        }
        XCTAssertTrue(button.waitForExistence(timeout: 5), id)
        app.revealSkyControls([button])
        XCTAssertTrue(XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: button).wait(timeout: 5), id)
        button.tap()
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let image = app.frame.width > app.frame.height ? XCUIScreen.main.screenshot() : app.screenshot()
        let attachment = XCTAttachment(screenshot: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func ceiling(_ app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: "sky.ceiling").firstMatch
    }

    @MainActor private func chooseFullBoard(_ app: XCUIApplication, captureName: String) {
        app.worldVisitControl("firstLight").tap()
        let falling = app.buttons["sky.lanternMode.fallingSky"]
        let full = app.buttons["sky.lanternMode.fullBoard"]
        app.revealSkyControls([falling, full])
        XCTAssertTrue(falling.isSelected, "An explicit new visit keeps Falling Sky as the default")
        XCTAssertGreaterThanOrEqual(falling.frame.height, 44)
        XCTAssertGreaterThanOrEqual(full.frame.height, 44)
        XCTAssertFalse(falling.frame.intersects(full.frame))
        full.tap()
        XCTAssertTrue(full.isSelected)
        XCTAssertFalse(falling.isSelected)
        let begin = app.buttons["sky.begin"]
        app.revealSkyControls([full, begin])
        XCTAssertTrue(app.frame.contains(full.frame) && app.frame.contains(begin.frame),
                      "The selected mode and Begin must be completely visible in the entry capture")
        capture(app, captureName)
        tap("sky.begin", app)
        waitForRound(app, exchanges: 0, score: 0)
        XCTAssertTrue(app.staticTexts["lantern.mode"].label.contains("Full Board"))
        XCTAssertEqual(ceiling(app).label, "Board top edge")
        XCTAssertEqual(ceiling(app).value as? String ?? "", "")
        XCTAssertFalse(app.staticTexts["sky.pressure"].exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sky.forecast.destinations").firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "experiment.arrivalCue").firstMatch.exists)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
    }

    @MainActor private func waitForRound(_ app: XCUIApplication, exchanges: Int, score: Int) {
        let expected = "\(score.formatted()) of \(150_000.formatted()) starlight collected"
        let board = app.otherElements["experiment.board"]
        let blocked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.exists && (board.value as? String)?.hasPrefix("Exchanges: \(exchanges). Full Board.") == true
                && app.staticTexts["experiment.score"].label == expected
                && app.buttons["experiment.cell.0.0"].isEnabled && blocked.count == 0
        }, object: nil).wait(timeout: 10),
        "Expected exchange \(exchanges), score \(score); observed \(String(describing: board.value))")
    }

    @MainActor private func cells(_ app: XCUIApplication) throws -> [String] {
        var result: [String] = []
        func visit(_ node: any XCUIElementSnapshot) {
            if node.elementType == .button, node.identifier.hasPrefix("experiment.cell.") {
                XCTAssertFalse(node.label.hasPrefix("Empty, "), "A settled refill board must have 49 occupied cells")
                XCTAssertFalse(node.label.hasPrefix("Grown "), "Full Board uses ordinary one-light stars")
                result.append("\(node.identifier):\(node.label):\(node.value as? String ?? "")")
            }
            node.children.forEach(visit)
        }
        visit(try app.otherElements["experiment.board"].snapshot())
        XCTAssertEqual(result.count, 49)
        return result.sorted()
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, score: Int, count: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in source.isEnabled && target.isEnabled }, object: nil).wait(timeout: 10))
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05,
                   thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
        if score < 150_000 { waitForRound(app, exchanges: count, score: score) }
    }

    @MainActor private func restore(_ app: XCUIApplication, largest: Bool = false, quiet: Bool = false) {
        app.terminate()
        app.launchArguments = arguments(largest: largest, quiet: quiet, reset: false)
        app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.resume", app)
    }

    @MainActor func testNormalMotionFullBoardRefillRestoreWinAndReplay() throws {
        executionTimeAllowance = 300
        requireNormalMotion()
        let app = launch()
        defer { app.terminate() }
        chooseFullBoard(app, captureName: "full-board-default-choice")
        let opening = try cells(app)
        capture(app, "full-board-default-opening")
        exchange(27, 34, score: 42_000, count: 1, in: app)
        let retained = try cells(app)
        XCTAssertNotEqual(retained, opening, "The real opening square clears and refills")
        capture(app, "full-board-default-refill")

        tap("experiment.settings", app)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        tap("experiment.done", app)
        XCUIDevice.shared.press(.home); app.activate()
        waitForRound(app, exchanges: 1, score: 42_000)
        XCTAssertEqual(try cells(app), retained)
        restore(app)
        waitForRound(app, exchanges: 1, score: 42_000)
        XCTAssertEqual(try cells(app), retained)
        capture(app, "full-board-default-restored")

        for (index, move) in winningMoves.dropFirst().enumerated() {
            exchange(move.from, move.to, score: move.score, count: index + 2, in: app)
            if move.score < 150_000 { _ = try cells(app) }
        }
        let outcome = app.staticTexts["experiment.outcome"]
        XCTAssertTrue(outcome.waitForExistence(timeout: 12))
        XCTAssertEqual(outcome.label, "Lantern Landing restored!")
        XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("156,000 of 150,000 starlight collected"))
        capture(app, "full-board-default-won")
        tap("experiment.replay", app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fallingSky"].exists, "Replay retains the completed round's mode")
        tap("sky.begin", app)
        waitForRound(app, exchanges: 0, score: 0)
        XCTAssertEqual(try cells(app), opening)
        exchange(27, 34, score: 42_000, count: 1, in: app)
        XCTAssertEqual(try cells(app), retained)
        capture(app, "full-board-default-replayed-refill")
    }

    @MainActor func testLanternModeCancellationPreservesFullBoardUntilFallingSkyBegins() throws {
        let app = launch(quiet: true)
        defer { app.terminate() }
        chooseFullBoard(app, captureName: "full-board-switch-choice")
        exchange(8, 9, score: 15_000, count: 1, in: app)
        let retained = try cells(app)
        tap("experiment.settings", app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", app)
        tap("sky.lanternMode.fallingSky", app)
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.home", app)
        tap("world.resume", app)
        waitForRound(app, exchanges: 1, score: 15_000)
        XCTAssertEqual(try cells(app), retained)
        XCTAssertTrue(app.staticTexts["lantern.mode"].label.contains("Full Board"))

        tap("experiment.settings", app)
        app.worldVisitControl("firstLight").tap()
        XCTAssertTrue(app.buttons["sky.lanternMode.fallingSky"].isSelected)
        tap("sky.begin", app)
        tap("experiment.settings", app)
        tap("experiment.pause", app)
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue((board.value as? String)?.hasPrefix("0 showers") == true)
        XCTAssertEqual(app.staticTexts["lantern.mode"].label, "Falling Sky")
        XCTAssertEqual(app.staticTexts["experiment.score"].label, "0 of 150,000 starlight collected")
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        XCTAssertEqual(ceiling(app).label, "Sky ceiling")
        XCTAssertTrue((ceiling(app).value as? String)?.contains("spaces left") == true)
        capture(app, "full-board-switched-to-falling-sky")
    }

    @MainActor func testLargestQuietFullBoardChoiceSwapRotationAndRestore() throws {
        executionTimeAllowance = 240
        XCUIDevice.shared.orientation = .portrait
        let app = launch(largest: true, quiet: true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        chooseFullBoard(app, captureName: "full-board-largest-choice")
        exchange(8, 9, score: 15_000, count: 1, in: app)
        var count = 1, score = 15_000
        capture(app, "full-board-largest-portrait-refill")
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.frame.width > app.frame.height
            }, object: nil).wait(timeout: 8))
            waitForRound(app, exchanges: count, score: score)
            exchange(27, 34, score: 34_000, count: 2, in: app)
            count = 2; score = 34_000
            capture(app, "full-board-largest-tablet-landscape-refill")
            XCUIDevice.shared.orientation = .portrait
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                app.frame.height > app.frame.width
            }, object: nil).wait(timeout: 8))
        }
        let retained = try cells(app)
        tap("experiment.settings", app)
        tap("experiment.preferences", app)
        capture(app, "full-board-largest-settings")
        tap("experiment.done", app)
        XCUIDevice.shared.press(.home); app.activate()
        waitForRound(app, exchanges: count, score: score)
        XCTAssertEqual(try cells(app), retained)
        restore(app, largest: true, quiet: true)
        waitForRound(app, exchanges: count, score: score)
        XCTAssertEqual(try cells(app), retained)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertEqual(ceiling(app).label, "Board top edge")
        capture(app, "full-board-largest-restored")
    }

    @MainActor func testRetainedV5ContinueReplayAndExplicitNewVisitKeepTheirOwnDefinitions() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--dialogue-review", "--full-board-v5-review", "-calmEffects", "YES"]
        app.launch()
        defer { app.terminate() }
        waitForRound(app, exchanges: 0, score: 0)
        let opening = try cells(app)
        exchange(8, 9, score: 66_000, count: 1, in: app)
        let retained = try cells(app)
        app.terminate()
        app.launchArguments = ["--dialogue-review", "-calmEffects", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.resume", app)
        waitForRound(app, exchanges: 1, score: 66_000)
        XCTAssertEqual(try cells(app), retained)
        tap("experiment.settings", app)
        tap("experiment.replay", app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fallingSky"].exists)
        tap("sky.begin", app)
        waitForRound(app, exchanges: 0, score: 0)
        XCTAssertEqual(try cells(app), opening)
        exchange(8, 9, score: 66_000, count: 1, in: app)
        XCTAssertEqual(try cells(app), retained)
        capture(app, "depth04-retained-v5-replay")
        tap("experiment.settings", app)
        app.worldVisitControl("firstLight").tap()
        tap("sky.lanternMode.fullBoard", app)
        tap("sky.begin", app)
        waitForRound(app, exchanges: 0, score: 0)
        XCTAssertNotEqual(try cells(app), opening, "Explicit new visits select the new authored opening")
        exchange(8, 9, score: 15_000, count: 1, in: app)
        capture(app, "depth04-explicit-new-v6-after-retained-v5")
    }

}
