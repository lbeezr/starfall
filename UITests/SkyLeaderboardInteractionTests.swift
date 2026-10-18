import XCTest

final class SkyLeaderboardInteractionTests: XCTestCase {
    @MainActor private func launch(_ state: String) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--rankings-review=\(state)"]
        app.launch()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        return app
    }
    @MainActor private func open(_ app: XCUIApplication) {
        app.buttons["experiment.settings"].tap()
        let link = app.buttons["rankings.open"]
        XCTAssertTrue(link.waitForExistence(timeout: 5))
        for _ in 0..<4 where !link.isHittable { app.swipeUp() }
        XCTAssertTrue(link.isHittable); link.tap()
        XCTAssertTrue(app.segmentedControls["rankings.scope"].waitForExistence(timeout: 5))
    }
    @MainActor private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testSignedOutRankingsNeverPreventPlayAndDoneRestoresSky() {
        let app = launch("signedout"); defer { app.terminate() }
        open(app)
        XCTAssertTrue(app.staticTexts["rankings.signedOut"].exists)
        XCTAssertTrue(app.buttons["rankings.connect"].exists)
        app.segmentedControls.buttons["Global"].tap()
        XCTAssertTrue(app.staticTexts["rankings.signedOut"].exists)
        capture(app, "rankings-signedout")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        app.buttons["experiment.next"].tap()
        XCTAssertTrue(app.buttons["experiment.cell.0.0"].waitForExistence(timeout: 5))
        let clear = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND value MATCHES %@", "experiment.cell.", "([3-9]|[1-9][0-9]) starlight connected")).firstMatch
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true AND hittable == true"), object: clear).wait(timeout: 5))
        clear.doubleTap()
        XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "3 starlight"), object: app.staticTexts["experiment.score"]).wait(timeout: 5))
    }
    @MainActor func testOfflineCachedFriendsAndGlobalRemainReadable() {
        let app = launch("offline"); defer { app.terminate() }
        open(app)
        XCTAssertTrue(app.descendants(matching: .any)["rankings.offline"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["rankings.updated"].exists)
        XCTAssertTrue(app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS %@", "Iris")).firstMatch.exists)
        capture(app, "rankings-offline-friends")
        app.segmentedControls.buttons["Global"].tap()
        XCTAssertTrue(app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS %@", "Moonbeam")).firstMatch.exists)
        capture(app, "rankings-offline-global")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        app.buttons["experiment.next"].tap()
        app.buttons["experiment.settings"].tap()
        app.buttons["experiment.new"].tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["experiment.cell.0.0"].exists)
    }
    @MainActor func testOfflineWithoutCacheAndWithoutSignIn() {
        let app = launch("signedout-offline"); defer { app.terminate() }
        open(app)
        XCTAssertTrue(app.staticTexts["rankings.signedOut"].exists)
        XCTAssertFalse(app.buttons["rankings.connect"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["rankings.offline"].firstMatch.exists)
        capture(app, "rankings-offline-signedout")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.pause"].waitForExistence(timeout: 5))
    }
    @MainActor func testOfflineUncachedRankingsAndBackgroundResume() {
        let app = launch("uncached"); defer { app.terminate() }
        open(app)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "No saved standings yet")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["rankings.updated"].exists)
        capture(app, "rankings-offline-uncached")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.segmentedControls["rankings.scope"].waitForExistence(timeout: 5))
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
        app.buttons["experiment.next"].tap()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
    }

    @MainActor func testLargestTextRankingsReflowsWithoutHidingDismissal() {
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--rankings-review=offline", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); defer { app.terminate() }
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 10))
        app.buttons["experiment.settings"].tap()
        let link = app.buttons["rankings.open"]
        for _ in 0..<8 where !link.isHittable { app.swipeUp() }
        XCTAssertTrue(link.isHittable); link.tap()
        XCTAssertTrue(app.buttons["experiment.done"].waitForExistence(timeout: 5))
        capture(app, "rankings-largest-text")
        app.buttons["experiment.done"].tap()
        XCTAssertTrue(app.buttons["experiment.settings"].waitForExistence(timeout: 5))
    }

    @MainActor func testSignedInRefreshAndScopeSwitch() {
        let app = launch("online"); defer { app.terminate() }
        open(app)
        XCTAssertTrue(app.buttons["rankings.refresh"].exists)
        app.segmentedControls.buttons["Global"].tap()
        XCTAssertTrue(app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS %@", "Moonbeam")).firstMatch.waitForExistence(timeout: 5))
        app.buttons["rankings.refresh"].tap()
        capture(app, "rankings-online-global")
    }
}
