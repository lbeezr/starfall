import XCTest

/// Visible-surface calibration samples; no Core state or forecast oracle.
final class FreshSkyPlaytests: XCTestCase {
    private static let legalValuePattern = "^([3-9]|[1-9][0-9]+) toward a tap match(; [0-9]+ starlight if cleared)?$"

    private struct VisibleCell {
        let identifier: String
        let value: String
        let frame: CGRect
        let enabled: Bool
        var reward: Int? {
            guard value.range(of: FreshSkyPlaytests.legalValuePattern, options: .regularExpression) != nil else { return nil }
            return value.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.last
        }
    }

    private struct VisibleSky {
        let frame: CGRect
        var cells: [VisibleCell] = []
        var score: String?
        var board: String?
        var outcome: String?
    }

    /// Read one immutable AX tree. A round may finish while XCTest is observing it;
    /// individual live cell/property queries can then retry elements already removed.
    @MainActor private func observe(_ app: XCUIApplication) throws -> VisibleSky {
        let snapshot = try app.snapshot()
        var sky = VisibleSky(frame: snapshot.frame)
        func visit(_ element: any XCUIElementSnapshot) {
            switch element.identifier {
            case "experiment.score": sky.score = element.label
            case "experiment.board": sky.board = element.value as? String
            case "experiment.outcome": sky.outcome = element.label
            default:
                if element.elementType == .button && element.identifier.hasPrefix("experiment.cell.") {
                    sky.cells.append(VisibleCell(identifier: element.identifier, value: element.value as? String ?? "",
                                                 frame: element.frame, enabled: element.isEnabled))
                }
            }
            element.children.forEach(visit)
        }
        visit(snapshot)
        return sky
    }

    /// Fresh automatic rounds, using only the visible accessibility surface.
    /// XCTest query/gesture latency is recorded, not treated as human reaction time.
    @MainActor private func playVisibleMatches(seed: Int, duration: TimeInterval = 45) throws {
        executionTimeAllowance = 180
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=\(seed)", "-calmEffects", "NO"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
        let started = Date()
        var observations = ["seed=\(seed); full effects requested; automatic clock; visible largest reward; no setup/search forecast"]
        var attempts = 0
        var misses = 0
        while Date().timeIntervalSince(started) < duration {
            let sky = try observe(app)
            if sky.outcome != nil { break }
            let candidates = sky.cells.filter {
                $0.enabled && $0.reward != nil && !$0.frame.isEmpty && sky.frame.contains($0.frame)
            }
            if let choice = candidates.max(by: { ($0.reward ?? 0) < ($1.reward ?? 0) }) {
                observations.append(String(format: "t=%.2f %@ %@; %@; %@", Date().timeIntervalSince(started),
                    choice.identifier, choice.value, sky.score ?? "unavailable", sky.board ?? "unavailable"))
                // The native contact uses the last visible cell position, like a player.
                // Do not resolve a live cell again after a terminal screen can replace it.
                let point = CGVector(dx: choice.frame.midX - sky.frame.minX, dy: choice.frame.midY - sky.frame.minY)
                app.coordinate(withNormalizedOffset: .zero).withOffset(point).tap()
                attempts += 1
                let after = try observe(app)
                observations.append("attempt=\(attempts); sampledValue=\(choice.value); frame=\(choice.frame); score=\(sky.score ?? "unavailable") -> \(after.score ?? "unavailable"); terminal=\(after.outcome != nil)")
                if let before = sky.score, before == after.score {
                    misses += 1
                    if (choice.reward ?? 0) > 0 && misses <= 4 {
                        let snapshot = XCTAttachment(string: app.debugDescription)
                        snapshot.name = "fresh-\(seed)-miss-\(misses)-hierarchy"
                        snapshot.lifetime = .keepAlways; add(snapshot)
                        if misses <= 2 { capture(app, "fresh-\(seed)-miss-\(misses)") }
                    }
                }
                if attempts == 1 { capture(app, "fresh-\(seed)-first-clear") }
            } else {
                let matches = app.buttons.matching(NSPredicate(format:
                    "identifier BEGINSWITH %@ AND enabled == true AND value MATCHES %@",
                    "experiment.cell.", Self.legalValuePattern))
                // Wait for an opportunity or ending, then take a new coherent observation.
                _ = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    matches.count > 0 || app.staticTexts["experiment.outcome"].exists
                }, object: nil).wait(timeout: min(3, max(0.1, duration - Date().timeIntervalSince(started))))
            }
        }
        XCTAssertTrue(app.staticTexts["experiment.score"].waitForExistence(timeout: 5))
        let final = try observe(app)
        let finalScore = try XCTUnwrap(final.score, "The visible playing or terminal screen must expose its score")
        observations.append("attempts=\(attempts); nonScoring=\(misses); final=\(finalScore); board=\(final.board ?? "unavailable"); terminal=\(final.outcome != nil)")
        let report = XCTAttachment(string: observations.joined(separator: "\n"))
        report.name = "fresh-\(seed)-visible-match-observations"; report.lifetime = .keepAlways; add(report)
        capture(app, "fresh-\(seed)-sample-end")
        XCTAssertGreaterThan(attempts, 0, "The ordinary opening offers a native clear")
        XCTAssertNotEqual(finalScore, "0 starlight", "Automatic arrivals and ordinary native taps produce light")
    }

    @MainActor func testFreshAutomaticVisibleMatchesSeed5() throws { try playVisibleMatches(seed: 5) }
    @MainActor func testFreshAutomaticVisibleMatchesSeed180() throws { try playVisibleMatches(seed: 180) }
    @MainActor func testRepeatedAutomaticVisibleMatchesSeed28() throws { try playVisibleMatches(seed: 28, duration: 90) }

    @MainActor func testVisibleObservationSurvivesAutomaticOverflow() throws {
        continueAfterFailure = false
        let app = XCUIApplication(); defer { app.terminate() }
        app.launchArguments = ["--starfalls-reset", "--observatory-review", "--observatory-dense", "-calmEffects", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 10))
        let active = try observe(app)
        XCTAssertEqual(active.cells.count, 49)
        XCTAssertNil(active.outcome)
        app.buttons["experiment.pause"].tap()
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["experiment.score"].waitForExistence(timeout: 5))
        let ended = try observe(app)
        XCTAssertEqual(ended.outcome, "No room to land")
        XCTAssertTrue(ended.cells.isEmpty, "The terminal ceremony removes interactive native cells")
        XCTAssertNotNil(ended.score)
        XCTAssertTrue(active.cells.contains { $0.reward != nil && !$0.frame.isEmpty },
                      "An earlier observation remains readable after its native controls are removed")
        capture(app, "fresh-observation-after-overflow")
    }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
