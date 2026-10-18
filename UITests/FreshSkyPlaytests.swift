import XCTest

/// Visible-surface calibration samples; no Core state or forecast oracle.
final class FreshSkyPlaytests: XCTestCase {
    /// Fresh automatic rounds, using only the visible accessibility surface.
    /// XCTest query/gesture latency is recorded, not treated as human reaction time.
    @MainActor private func playVisibleMatches(seed: Int) {
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
        var skipped = 0
        let legalValuePattern = "^([3-9]|[1-9][0-9]+) toward a tap match(; [0-9]+ starlight if cleared)?$"
        func exposedReward(_ value: String) -> Int? {
            guard value.range(of: legalValuePattern, options: .regularExpression) != nil else { return nil }
            return value.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }.last
        }
        while Date().timeIntervalSince(started) < 45 && !app.staticTexts["experiment.outcome"].exists {
            let matches = app.buttons.matching(NSPredicate(format:
                "identifier BEGINSWITH %@ AND enabled == true AND value MATCHES %@",
                "experiment.cell.", legalValuePattern))
            // SwiftUI can replace AX identities during arrivals. Resolve known
            // native identifiers afresh; retain neither a result index nor AX binding.
            let candidates = (0..<49).compactMap { index -> (String, Int, String)? in
                let id = "experiment.cell.\(index / 7).\(index % 7)"
                let element = app.buttons[id]
                let value = element.value as? String ?? ""
                guard let reward = exposedReward(value), element.isEnabled else { return nil }
                return (id, reward, value)
            }
            if let choice = candidates.max(by: { $0.1 < $1.1 }) {
                observations.append(String(format: "t=%.2f %@ %@; %@; %@", Date().timeIntervalSince(started),
                    choice.0, choice.2, app.staticTexts["experiment.score"].label,
                    app.otherElements["experiment.board"].value as? String ?? "unavailable"))
                let target = app.buttons[choice.0]
                let before = app.staticTexts["experiment.score"].label
                let immediateValue = target.value as? String ?? "unavailable"
                let frame = target.frame
                let ready = target.isEnabled
                guard ready, let expectedReward = exposedReward(immediateValue) else {
                    skipped += 1
                    observations.append("selectionSkipped=\(choice.0); ready=\(ready); immediate=\(immediateValue)")
                    continue
                }
                target.tap(); attempts += 1
                let after = app.staticTexts["experiment.score"].label
                observations.append("attempt=\(attempts); targetReady=\(ready); immediate=\(immediateValue); frame=\(frame); score=\(before) -> \(after)")
                if before == after {
                    misses += 1
                    if expectedReward > 0 && misses <= 4 {
                        let snapshot = XCTAttachment(string: app.debugDescription)
                        snapshot.name = "fresh-\(seed)-miss-\(misses)-hierarchy"
                        snapshot.lifetime = .keepAlways; add(snapshot)
                        if misses <= 2 { capture(app, "fresh-\(seed)-miss-\(misses)") }
                    }
                }
                if attempts == 1 { capture(app, "fresh-\(seed)-first-clear") }
            } else {
                // Wait for a visible opportunity or the terminal ceremony, bounded by the round sample.
                _ = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    matches.count > 0 || app.staticTexts["experiment.outcome"].exists
                }, object: nil).wait(timeout: min(3, max(0.1, 45 - Date().timeIntervalSince(started))))
            }
        }
        let finalScore = app.staticTexts["experiment.score"].label
        let board = app.otherElements["experiment.board"].value as? String ?? "unavailable"
        let outcome = app.staticTexts["experiment.outcome"]
        observations.append("attempts=\(attempts); nonScoring=\(misses); staleSelectionsSkipped=\(skipped); final=\(finalScore); board=\(board); terminal=\(outcome.exists)")
        let report = XCTAttachment(string: observations.joined(separator: "\n"))
        report.name = "fresh-\(seed)-visible-match-observations"; report.lifetime = .keepAlways; add(report)
        capture(app, "fresh-\(seed)-sample-end")
        XCTAssertGreaterThan(attempts, 0, "The ordinary opening offers a native clear")
        XCTAssertNotEqual(finalScore, "0 starlight", "Automatic arrivals and ordinary native taps produce light")
    }
    @MainActor func testFreshAutomaticVisibleMatchesSeed5() { playVisibleMatches(seed: 5) }
    @MainActor func testFreshAutomaticVisibleMatchesSeed180() { playVisibleMatches(seed: 180) }

    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
