import XCTest
import UIKit

/// Earns access through current Silver and Frostfruit; no Sunwheel state or
/// score is injected. Every exchange, shower and repair uses production rules.
final class SunwheelEncounterInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .sunwheel }

    @MainActor private func waitScore(_ score: Int, target: Int = 24_000, showers: Int? = nil,
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


    @MainActor private func next(_ count: Int, score: Int, in app: XCUIApplication) {
        tap("experiment.next", in: app)
        waitScore(score, showers: count, in: app)
    }

    @MainActor private func opening(_ app: XCUIApplication, largest: Bool) {
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Sunwheel Mill")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("24,000 starlight"))
        XCTAssertFalse(app.buttons["sky.lanternMode.fullBoard"].exists)
        let begin = app.buttons["sky.begin"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        app.revealSkyControls([begin])
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"),
                                               object: begin).wait(timeout: 5))
        capture(app, largest ? "depth08-largest-sunwheel-entry" : "depth08-normal-sunwheel-entry")
        begin.tap(); pauseRunningSky(app)
        waitScore(0, showers: 0, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 26)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Grown")).count, 1)
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].label.contains("Grown"))
        capture(app, largest ? "depth08-largest-grown-opening" : "depth08-normal-grown-opening")
    }

    @MainActor private func earnSunwheel(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
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
        tap("sky.worldMap", in: app); tap("world.visit", in: app)
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        tap("sky.begin", in: app); pauseRunningSky(app)
        waitScore(0, target: 15_000, showers: 0, in: app)
        exchange(20, 19, in: app); waitScore(5_000, target: 15_000, showers: 0, in: app)
        tap("experiment.next", in: app); waitScore(5_000, target: 15_000, showers: 1, in: app)
        exchange(2, 9, in: app); waitScore(12_000, target: 15_000, showers: 1, in: app)
        exchange(3, 10, in: app); waitScore(17_000, target: 15_000, won: "Frostfruit Orchard restored!", in: app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Sunwheel Mill")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Sunwheel Mill")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        opening(app, largest: largest)
        return app
    }

    @MainActor func testNormalSpacePlanAutomaticShowerExactRestoreEarnedRepairAndReplay() throws {
        executionTimeAllowance = 540
        setSystemMotion(reduced: false)
        let app = earnSunwheel()
        defer { app.terminate() }
        exchange(15, 14, in: app); waitScore(6_000, showers: 0, in: app)
        XCTAssertTrue(app.buttons["experiment.cell.3.0"].label.hasPrefix("Empty,"))
        capture(app, "depth08-normal-space-first-four-spaces")
        tap("experiment.settings", in: app); tap("experiment.pause", in: app)
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (app.otherElements["experiment.board"].value as? String)?.hasPrefix("1 showers") == true
        }, object: nil).wait(timeout: 12))
        tap("experiment.settings", in: app); tap("experiment.pause", in: app)
        waitScore(6_000, showers: 1, in: app)
        let retained = try state(app)
        XCUIDevice.shared.press(.home); app.activate(); app.terminate()
        app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
        app.launch(); tap("sky.resume", in: app)
        waitScore(6_000, showers: 1, in: app)
        XCTAssertEqual(try state(app), retained)
        next(2, score: 6_000, in: app)
        XCTAssertTrue(app.buttons["experiment.cell.5.0"].label.hasPrefix("Empty,"))
        capture(app, "depth08-normal-space-same-second-shower-fits")
        exchange(17, 18, in: app); waitScore(6_000, showers: 2, in: app)
        exchange(9, 10, in: app); waitScore(25_000, won: "Sunwheel Mill restored!", in: app)
        capture(app, "depth08-normal-space-earned-25k")
        tap("experiment.replay", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Sunwheel Mill opening"))
        opening(app, largest: false)
    }

    @MainActor func testLargestQuietSequenceAndPlausibleMistakeRecoveryBothRepair() throws {
        executionTimeAllowance = 540
        let app = earnSunwheel(largest: true, quiet: true)
        defer { app.terminate(); XCUIDevice.shared.orientation = .portrait }
        exchange(9, 10, in: app); waitScore(21_000, showers: 0, in: app)
        XCTAssertFalse(app.buttons["experiment.cell.5.0"].label.hasPrefix("Empty,"))
        XCTAssertTrue(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        capture(app, "depth08-largest-grown-survivor-chain-21k")
        next(1, score: 21_000, in: app)
        XCTAssertFalse(app.buttons["experiment.cell.6.0"].label.hasPrefix("Empty,"))
        capture(app, "depth08-largest-sequence-full-pressure-column")
        exchange(0, 7, in: app); waitScore(26_000, won: "Sunwheel Mill restored!", in: app)
        let replay = app.buttons["experiment.replay"]
        app.revealSkyControls([replay])
        XCTAssertTrue(app.frame.contains(replay.frame)); XCTAssertGreaterThanOrEqual(replay.frame.height, 44)
        capture(app, "depth08-largest-sequence-earned-26k")
        tap("experiment.replay", in: app); opening(app, largest: true)
        exchange(2, 9, in: app); waitScore(8_000, showers: 0, in: app)
        next(1, score: 8_000, in: app)
        exchange(0, 7, in: app); waitScore(13_000, showers: 1, in: app)
        capture(app, "depth08-largest-mistake-recovered-room-13k")
        exchange(3, 10, in: app); waitScore(24_000, won: "Sunwheel Mill restored!", in: app)
        app.revealSkyControls([app.buttons["experiment.replay"]])
        capture(app, "depth08-largest-mistake-earned-exact-24k")
    }
}
