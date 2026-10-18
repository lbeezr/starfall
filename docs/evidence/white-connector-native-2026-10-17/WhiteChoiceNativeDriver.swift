/// Temporary exported-lab XCTest bridge; no app/core code or target membership change.
final class WhiteChoiceNativeDriver: XCTestCase {
    @MainActor func testPerformChosenActions() {
        continueAfterFailure = false
        let environment = ProcessInfo.processInfo.environment
        let commands = (environment["STARFALL_PLAY_ACTIONS"] ?? environment["TEST_RUNNER_STARFALL_PLAY_ACTIONS"] ?? "").split(separator: ",").map(String.init)
        XCTAssertFalse(commands.isEmpty)
        let app = XCUIApplication(bundleIdentifier: "com.starfall.whiteconnector.lab")
        if commands.first == "reset" {
            app.terminate()
            let fixture = environment["STARFALL_PLAY_FIXTURE"] ?? environment["TEST_RUNNER_STARFALL_PLAY_FIXTURE"] ?? ""
            XCTAssertTrue(["connection", "pressure"].contains(fixture))
            app.launchArguments = ["--starfalls-reset", "--white-fixture=\(fixture)"]
            app.launch()
        } else { app.activate() }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 10))
        for command in commands where command != "reset" && command != "observe" {
            let target = app.buttons[command]
            XCTAssertTrue(target.waitForExistence(timeout: 5))
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: target).wait(timeout: 5))
            let before = app.otherElements["experiment.board"].value as? String ?? ""
            let shower = Int(before.split(separator: " ").first ?? "") ?? -1
            target.tap()
            if command == "experiment.next" {
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    (app.otherElements["experiment.board"].value as? String ?? "").hasPrefix("\(shower+1) showers,")
                }, object: nil).wait(timeout: 5))
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.buttons["experiment.next"].isEnabled || app.staticTexts["experiment.outcome"].exists
                }, object: nil).wait(timeout: 5))
            } else {
                XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                    app.buttons["experiment.next"].isEnabled || app.staticTexts["experiment.outcome"].exists
                }, object: nil).wait(timeout: 5))
            }
        }
        if commands.contains("observe") {
            let diagnostics = XCTAttachment(string: "app.state=\(app.state.rawValue); board=\(app.otherElements["experiment.board"].value as? String ?? "missing"); score=\(app.staticTexts["experiment.score"].label); nextEnabled=\(app.buttons["experiment.next"].isEnabled)")
            diagnostics.name = "Chosen-actions-observation-diagnostics"; diagnostics.lifetime = .keepAlways; add(diagnostics)
        }
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Chosen-actions-result"; image.lifetime = .keepAlways; add(image)
        let snapshot = XCTAttachment(string: app.debugDescription)
        snapshot.name = "Chosen-actions-native-hierarchy"; snapshot.lifetime = .keepAlways; add(snapshot)
    }
}
