import XCTest
import UIKit

/// Debug review setup grants retained local access only; all Ribbon boards,
/// scores and wins come from production Begin and physical exchanges.
final class FullBoardRibbonInteractionTests: XCTestCase {
    @MainActor private func requireNormalMotion() {
        let (preferences, reduce) = NativeSystemMotionSettings.open()
        let original = reduce.value as? String == "1"
        NativeSystemMotionSettings.set(false, on: reduce)
        preferences.terminate()
        if original {
            addTeardownBlock { @MainActor in
                let (settings, toggle) = NativeSystemMotionSettings.open()
                NativeSystemMotionSettings.set(original, on: toggle)
                settings.terminate()
            }
        }
    }

    private func arguments(largest: Bool, quiet: Bool, reset: Bool) -> [String] {
        var result = ["--sky-flow-review", "--dialogue-review", "-calmEffects", quiet ? "YES" : "NO"]
        if reset { result += ["--starfalls-reset", "--world-legacy-review"] }
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
        app.worldVisitControl("ribbonCrossing").tap()
        let falling = app.buttons["sky.ribbonMode.fallingSky"]
        let full = app.buttons["sky.ribbonMode.fullBoard"]
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
        XCTAssertTrue(app.staticTexts["ribbon.mode"].label.contains("Full Board"))
        XCTAssertEqual(ceiling(app).label, "Board top edge")
        XCTAssertEqual(ceiling(app).value as? String ?? "", "")
        XCTAssertFalse(app.staticTexts["sky.pressure"].exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sky.forecast.destinations").firstMatch.exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "experiment.arrivalCue").firstMatch.exists)
        XCTAssertFalse(app.buttons["experiment.pause"].exists)
        XCTAssertFalse(app.buttons["experiment.next"].exists)
    }

    @MainActor private func waitForRound(_ app: XCUIApplication, exchanges: Int, score: Int) {
        let expected = "\(score.formatted()) of \(220_000.formatted()) starlight collected"
        let board = app.otherElements["experiment.board"]
        let blocked = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND enabled == false", "experiment.cell."))
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.exists && (board.value as? String)?.hasPrefix("Exchanges: \(exchanges). Full Board.") == true
                && (board.value as? String)?.contains("Stars settling") == false
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
        if score < 220_000 { waitForRound(app, exchanges: count, score: score) }
    }

    @MainActor private func restore(_ app: XCUIApplication, largest: Bool = false, quiet: Bool = false) {
        app.terminate()
        app.launchArguments = arguments(largest: largest, quiet: quiet, reset: false)
        app.launch()
        XCTAssertTrue(app.buttons["sky.resume"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        tap("sky.resume", app)
    }

    private let survivorMoves = [(8,9),(11,12),(31,38),(17,24),(9,16),(9,10),(1,8),(1,2),(1,8),(9,10),(10,11),(22,29),(2,3),(2,9),(1,8),(37,38),(2,3),(16,17)]
    private let survivorScores = [30,35,40,45,50,65,80,80,85,85,90,179,179,184,199,214,214,229]

    @MainActor func testThreeRapidPlansSurviveFivePhaseCascadeWithoutSettlingWaits() throws {
        executionTimeAllowance = 240
        requireNormalMotion()
        let app = launch()
        defer { app.terminate() }
        chooseFullBoard(app, captureName: "momentum-ribbon-mode")
        for index in 0..<11 {
            let move = survivorMoves[index]
            exchange(move.0, move.1, score: survivorScores[index] * 1_000, count: index + 1, in: app)
        }
        // Cache real cell coordinates before motion. The following distinct
        // contacts deliberately contain no settling/readiness wait between them.
        func coordinate(_ index: Int) -> XCUICoordinate {
            app.buttons["experiment.cell.\(index / 7).\(index % 7)"].coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        }
        let trigger = (coordinate(22), coordinate(29))
        let plans = [(coordinate(0), coordinate(1)), (coordinate(2), coordinate(3)), (coordinate(4), coordinate(5))]
        trigger.0.press(forDuration: 0.05, thenDragTo: trigger.1, withVelocity: .fast, thenHoldForDuration: 0)
        plans[0].0.press(forDuration: 0.05, thenDragTo: plans[0].1, withVelocity: .fast, thenHoldForDuration: 0)
        let queued = app.staticTexts["sky.inputQueue"]
        XCTAssertTrue(queued.waitForExistence(timeout: 2), "A next move must be accepted during the five-phase presentation")
        capture(app, "momentum-ribbon-plan-during-five-phases")
        for plan in plans.dropFirst() {
            plan.0.press(forDuration: 0.05, thenDragTo: plan.1, withVelocity: .fast, thenHoldForDuration: 0)
        }
        waitForRound(app, exchanges: 15, score: 179_000)
        XCTAssertFalse(queued.exists)
        XCTAssertEqual(try cells(app).count, 49)
        capture(app, "momentum-ribbon-three-plans-committed")
    }
    private let lineMoves = [(1,2),(7,8),(11,12),(30,37),(8,9),(36,37),(39,40),(32,33),(0,1),(1,8),(43,44),(36,37),(4,5),(3,4),(19,20),(2,9),(2,3),(17,24),(1,8),(8,9),(8,15),(38,45),(2,9),(9,16),(3,10),(9,10),(14,15),(26,33),(31,32),(12,19),(18,25),(14,21),(32,33),(16,23)]
    private let lineScores = [5,28,33,71,76,83,88,93,93,98,103,110,110,115,120,120,125,130,130,135,140,145,145,150,155,160,165,170,175,175,180,195,218,223]

    @MainActor func testNormalMotionSurvivorRoundCancellationRestoreWinAndReplay() throws {
        executionTimeAllowance = 480
        requireNormalMotion()
        let app = launch()
        defer { app.terminate() }
        chooseFullBoard(app, captureName: "depth06-ribbon-default-mode-choice")
        let opening = try cells(app)
        capture(app, "depth06-ribbon-default-opening")
        exchange(8,9,score:30_000,count:1,in:app)
        let retained = try cells(app)
        capture(app, "depth06-ribbon-visible-survivors-after-three-phases")
        tap("experiment.settings", app)
        app.worldVisitControl("ribbonCrossing").tap()
        XCTAssertTrue(app.buttons["sky.ribbonMode.fallingSky"].isSelected)
        tap("sky.ribbonMode.fullBoard", app)
        tap("sky.ribbonMode.fallingSky", app)
        tap("sky.home", app)
        tap("world.resume", app)
        waitForRound(app, exchanges:1,score:30_000)
        XCTAssertEqual(try cells(app),retained)
        XCUIDevice.shared.press(.home); app.activate()
        waitForRound(app, exchanges:1,score:30_000)
        restore(app)
        waitForRound(app, exchanges:1,score:30_000)
        XCTAssertEqual(try cells(app),retained)
        for index in 1..<survivorMoves.count {
            let move=survivorMoves[index]
            exchange(move.0,move.1,score:survivorScores[index]*1_000,count:index+1,in:app)
            if index == 7 { capture(app,"depth06-ribbon-middle-setup-80k") }
            if index == 11 { capture(app,"depth06-ribbon-five-phase-middle-179k") }
        }
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout:12))
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label,"Ribbon Crossing restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"Sunny. Ribbon Crossing complete! The cloud banks are connected again. 229,000 of 220,000 starlight collected. Nicely done!")
        capture(app,"depth06-ribbon-survivor-earned-win")
        tap("experiment.replay", app)
        XCTAssertEqual(app.staticTexts["sky.title"].label,"Ribbon Crossing")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("Full Board"))
        XCTAssertFalse(app.buttons["sky.ribbonMode.fallingSky"].exists)
        tap("sky.begin",app)
        waitForRound(app,exchanges:0,score:0)
        XCTAssertEqual(try cells(app),opening)
        exchange(8,9,score:30_000,count:1,in:app)
        XCTAssertEqual(try cells(app),retained)
        capture(app,"depth06-ribbon-replayed-same-survivors")
        tap("experiment.settings",app)
        app.worldVisitControl("ribbonCrossing").tap()
        XCTAssertTrue(app.buttons["sky.ribbonMode.fallingSky"].isSelected)
        tap("sky.begin",app)
        tap("experiment.settings",app)
        tap("experiment.pause",app)
        XCTAssertEqual(app.staticTexts["ribbon.mode"].label,"Falling Sky")
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        XCTAssertEqual(ceiling(app).label,"Sky ceiling")
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"0 of 220,000 starlight collected")
        capture(app,"depth06-ribbon-new-falling-sky-remains-available")
    }

    @MainActor func testIntegratedRibbonAdvicePreservesItsSettledRound() throws {
        executionTimeAllowance = 180
        let app = launch(quiet: true)
        defer { app.terminate() }
        chooseFullBoard(app, captureName: "depth06-integrated-ribbon-mode-choice")
        exchange(8,9,score:30_000,count:1,in:app)
        let retained = try cells(app)
        capture(app,"depth06-integrated-ribbon-settled-survivors")
        tap("experiment.settings",app)
        tap("fullBoard.choices.open",app)
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.0"].waitForExistence(timeout:10))
        XCTAssertTrue(app.staticTexts["fullBoard.choices.pattern.1"].exists)
        XCTAssertFalse(app.buttons["fullBoard.choices.practice"].exists)
        capture(app,"depth06-integrated-ribbon-own-visible-choices")
        tap("experiment.done",app)
        waitForRound(app,exchanges:1,score:30_000)
        XCTAssertEqual(try cells(app),retained)
    }

    @MainActor func testLargestQuietLineFirstRoundRotationAndWin() throws {
        executionTimeAllowance = 540
        XCUIDevice.shared.orientation = .portrait
        let app=launch(largest:true,quiet:true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        chooseFullBoard(app,captureName:"depth06-ribbon-largest-mode-choice")
        capture(app,"depth06-ribbon-largest-opening")
        for index in lineMoves.indices {
            if index == 2 && UIDevice.current.userInterfaceIdiom == .pad {
                XCUIDevice.shared.orientation = .landscapeLeft
                XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in app.frame.width > app.frame.height }, object:nil).wait(timeout:8))
                waitForRound(app,exchanges:index,score:lineScores[index-1]*1_000)
                _ = try cells(app)
                capture(app,"depth06-ribbon-largest-landscape-line-first")
            }
            let move=lineMoves[index]
            exchange(move.0,move.1,score:lineScores[index]*1_000,count:index+1,in:app)
            if index == 15 { capture(app,"depth06-ribbon-largest-middle-setup-120k") }
        }
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout:12))
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label,"Ribbon Crossing restored!")
        XCTAssertEqual(app.staticTexts["experiment.score"].label,"Sunny. Ribbon Crossing complete! The cloud banks are connected again. 223,000 of 220,000 starlight collected. Nicely done!")
        let replay=app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertTrue(app.frame.contains(replay.frame))
        XCTAssertGreaterThanOrEqual(replay.frame.height,44)
        capture(app,"depth06-ribbon-largest-line-first-earned-win")
        tap("experiment.replay",app)
        XCTAssertEqual(app.staticTexts["sky.title"].label,"Ribbon Crossing")
        XCTAssertFalse(app.buttons["sky.ribbonMode.fullBoard"].exists)
        tap("sky.begin",app)
        waitForRound(app,exchanges:0,score:0)
        exchange(1,2,score:5_000,count:1,in:app)
        capture(app,"depth06-ribbon-largest-exact-replay-line")
    }
}
