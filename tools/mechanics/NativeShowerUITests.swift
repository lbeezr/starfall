final class PairedShowerLabInteractionTests: XCTestCase {
    @MainActor func testOpeningAndMultipleChoicesWithNativeManualPlay() {
        continueAfterFailure = false
        let app = XCUIApplication(bundleIdentifier: "com.starfall.pairedshowerslab")
        app.launchArguments = ["--starfalls-reset", "--starfalls-seed=5"]
        app.launch(); defer { app.terminate() }
        let next = app.buttons["experiment.next"]
        XCTAssertTrue(next.waitForExistence(timeout: 10))
        var sawChoice = false
        for shower in 1...20 {
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            next.tap()
            XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "enabled == true"), object: next)], timeout: 5), .completed)
            let summary = app.staticTexts["experiment.matches"].label
            let count = Int(summary.split(separator: " ").first ?? "0") ?? 0
            if shower == 1 { XCTAssertEqual(count, 1, "First shower still teaches an immediate clear") }
            if count > 1 { sawChoice = true }
            if sawChoice {
                let capture = XCTAttachment(screenshot: app.screenshot())
                capture.name = "paired-shower-native-choice"; capture.lifetime = .keepAlways; add(capture)
            }
            let clear = app.buttons.matching(NSPredicate(format: "value MATCHES %@", "([3-9]|[1-9][0-9]+) starlight connected")).firstMatch
            if clear.exists { clear.tap() }
            if sawChoice { break }
        }
        XCTAssertTrue(sawChoice, "The fixed native sample reaches simultaneous groups")
    }
}
