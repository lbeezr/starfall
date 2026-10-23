import XCTest
import UIKit

/// Starts with production Silver4 and earns access; only review access to the
/// original five places is granted. Every board, shower and repair is ordinary.
final class FrostfruitEncounterInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .frostfruit }

    @MainActor private func waitScore(_ score: Int, target: Int = 15_000, showers: Int? = nil,
                                      won: String? = nil, in app: XCUIApplication) {
        let text = "\(score.formatted()) of \(target.formatted()) starlight collected"
        let board = app.otherElements["experiment.board"]
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            if let won {
                let outcome = app.staticTexts["experiment.outcome"]
                return outcome.exists && outcome.label == won
                    && (outcome.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) == text + "."
            }
            let next = app.buttons["experiment.next"]
            let value = board.value as? String ?? ""
            return board.exists && app.staticTexts["experiment.score"].label == text
                && next.exists && next.isEnabled && !value.contains("Stars settling")
                && (showers == nil || value.hasPrefix("\(showers!) showers"))
        }, object: nil).wait(timeout: 12), "Expected committed, settled score \(text)")
    }

    @MainActor private func exchange(_ from: Int, _ to: Int, in app: XCUIApplication) {
        let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
        let target = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
        app.revealSkyControls([source, target])
        XCTAssertTrue(source.isHittable && target.isHittable)
        source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.05, thenDragTo: target.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                   withVelocity: .fast, thenHoldForDuration: 0.05)
    }

    @MainActor private func opening(_ app: XCUIApplication, largest: Bool) {
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("15,000 starlight"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fullBoard"].exists)
        tap("sky.begin", in: app); pauseRunningSky(app)
        waitScore(0, showers: 0, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 30)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Grown")).count, 0)
        capture(app, largest ? "depth07-frost-largest-opening" : "depth07-frost-normal-opening")
    }

    @MainActor private func earnFrostfruit(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review",
                               "-calmEffects", quiet ? "YES" : "NO"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        app.worldVisitControl("silverPools").tap()
        tap("sky.begin", in: app); pauseRunningSky(app)
        waitScore(0, target: 12_000, showers: 0, in: app)
        exchange(9, 10, in: app)
        waitScore(19_000, target: 12_000, won: "Silver Pools restored!", in: app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Frostfruit Orchard")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        opening(app, largest: largest)
        return app
    }

    @MainActor private func next(_ count: Int, score: Int, in app: XCUIApplication) {
        tap("experiment.next", in: app)
        waitScore(score, showers: count, in: app)
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
        XCTAssertEqual(cells.count,49)
        return cells.sorted()
    }

    @MainActor func testNormalGrowthRoomAutomaticShowerRestoreRepairReplayAndSunwheelAccess() throws {
        executionTimeAllowance = 360
        setSystemMotion(reduced: false)
        let app = earnFrostfruit()
        defer { app.terminate() }
        exchange(35,36,in:app); waitScore(0,showers:0,in:app)
        // Resume the actual clock; no Next action produces this first shower.
        tap("experiment.settings",in:app); tap("experiment.pause",in:app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in
            (app.otherElements["experiment.board"].value as? String)?.hasPrefix("1 showers") == true
        },object:nil).wait(timeout:12))
        tap("experiment.settings",in:app); tap("experiment.pause",in:app)
        waitScore(0,showers:1,in:app)
        XCTAssertTrue(app.buttons["experiment.cell.5.0"].label.contains("Grown"))
        XCTAssertTrue(app.buttons["experiment.cell.5.1"].label.contains("Grown"))
        XCTAssertTrue(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        XCTAssertTrue(app.buttons["experiment.cell.6.1"].label.hasPrefix("Empty,"))
        let retained = try state(app)
        capture(app,"depth07-normal-two-grown-caps-kept-room")
        XCUIDevice.shared.press(.home); app.activate()
        app.terminate(); app.launchArguments = ["--sky-flow-review","--dialogue-review","-calmEffects","NO"]
        app.launch(); tap("sky.resume",in:app)
        waitScore(0,showers:1,in:app)
        XCTAssertEqual(try state(app),retained)
        next(2,score:0,in:app)
        capture(app,"depth07-normal-same-second-forecast-fits")
        exchange(20,19,in:app); waitScore(6_000,showers:2,in:app)
        exchange(2,9,in:app); waitScore(13_000,showers:2,in:app)
        exchange(3,10,in:app); waitScore(18_000,won:"Frostfruit Orchard restored!",in:app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label,"Visit Sunwheel Mill")
        capture(app,"depth07-normal-earned-frostfruit-repair-18k")
        tap("experiment.replay",in:app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Frostfruit Orchard opening"))
        opening(app,largest:false)
        tap("experiment.settings",in:app)
        app.worldVisitControl("sunwheelMill").tap()
        XCTAssertEqual(app.staticTexts["sky.title"].label,"Sunwheel Mill")
        let begin = app.buttons["sky.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        app.revealSkyControls([begin])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: begin).wait(timeout: 5))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("24,000 starlight"))
        capture(app,"depth07-normal-earned-sunwheel-entry")
        begin.tap(); pauseRunningSky(app)
        waitScore(0,target:24_000,in:app)
    }

    @MainActor func testLargestQuietImmediateRecoveryAndIgnoredOpeningBothRepair() throws {
        executionTimeAllowance = 360
        let app = earnFrostfruit(largest:true,quiet:true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        exchange(20,19,in:app); waitScore(5_000,showers:0,in:app)
        next(1,score:5_000,in:app)
        XCTAssertFalse(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        XCTAssertFalse(app.buttons["experiment.cell.6.1"].label.hasPrefix("Empty,"))
        capture(app,"depth07-largest-reward-fills-pressure-columns")
        exchange(2,9,in:app); waitScore(12_000,showers:1,in:app)
        XCTAssertTrue(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        XCTAssertTrue(app.buttons["experiment.cell.6.1"].label.hasPrefix("Empty,"))
        next(2,score:12_000,in:app)
        capture(app,"depth07-largest-recovery-before-same-second-shower")
        exchange(3,10,in:app); waitScore(17_000,won:"Frostfruit Orchard restored!",in:app)
        let replay=app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertTrue(app.frame.contains(replay.frame)); XCTAssertGreaterThanOrEqual(replay.frame.height,44)
        capture(app,"depth07-largest-immediate-recovery-earned-17k")
        tap("experiment.replay",in:app); opening(app,largest:true)
        next(1,score:0,in:app)
        exchange(20,19,in:app); waitScore(5_000,showers:1,in:app)
        exchange(2,9,in:app); waitScore(12_000,showers:1,in:app)
        exchange(3,10,in:app); waitScore(17_000,won:"Frostfruit Orchard restored!",in:app)
        capture(app,"depth07-largest-ignored-opening-earned-17k")
    }
}
