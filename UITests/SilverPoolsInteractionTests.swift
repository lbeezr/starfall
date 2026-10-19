import XCTest

final class SilverPoolsInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .silver }

    @MainActor func testSilverWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero()
    }

    @MainActor func testSilverDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero()
    }

    @MainActor func testSilverLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable()
    }

    @MainActor func testSilverPreviewCancellationRetainsLanternAndRibbonUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon])
    }

    @MainActor func testSilverPreviewCancellationRetainsKiteAndSeedUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.kite, .seed])
    }

    @MainActor func testSilverPhoneAllFiveStatesKeepNativeBoardFixed() {
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        var baseline: [CGRect] = []
        let ids = ["experiment.cell.0.0", "experiment.cell.0.6", "experiment.cell.6.0", "experiment.cell.6.6"]
        for (score, percent, milestone) in [(0, 0, 0), (5, 28, 25), (9, 50, 50), (14, 78, 75), (18, 100, 100)] {
            let app = launch(score: score)
            defer { app.terminate() }
            if score < 18 {
                assertRestoration(percent, score: score, in: app)
                let frames = ids.map { app.buttons[$0].frame }
                if score == 0 { baseline = frames }
                else { XCTAssertEqual(frames, baseline, "Restoration cannot move native cells") }
                XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "experiment.cell.")).count, 49)
            } else {
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Silver Pools restored!")
            }
            capture(app, "silver-phone-scene-\(milestone)-score-\(score)-normal-motion")
        }
    }

    @MainActor func testSilverDenseRapidClearSurvivesSettingsAndBackground() {
        executionTimeAllowance = 120
        setSystemMotion(reduced: false)
        let app = launch(score: 9, dense: true)
        defer { app.terminate() }
        assertRestoration(50, score: 9, in: app)
        let target = app.buttons["experiment.cell.0.0"]
        XCTAssertTrue((target.value as? String ?? "").contains("4 toward a tap match"))
        capture(app, "silver-dense-before-rapid-clear")
        target.doubleTap()
        assertRestoration(72, score: 13, in: app)
        let board = app.otherElements["experiment.board"]
        let retained = board.value as? String
        XCTAssertNotNil(retained)
        capture(app, "silver-dense-after-rapid-clear")
        tap("experiment.settings", in: app)
        tap("experiment.done", in: app)
        assertRestoration(72, score: 13, in: app)
        XCUIDevice.shared.press(.home)
        app.activate()
        assertRestoration(72, score: 13, in: app)
        XCTAssertEqual(board.value as? String, retained)
        XCTAssertTrue(app.buttons["experiment.next"].exists)
        capture(app, "silver-dense-retained-after-settings-background")
    }

    @MainActor func testTabletRotationKeepsSilverRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }

    @MainActor func testTabletDenseSilverCompletionKeepsNativeInput() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This check targets tablet artwork with a full native board")
        }
        executionTimeAllowance = 180
        setSystemMotion(reduced: false)
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait] {
            XCUIDevice.shared.orientation = orientation
            let app = launch(score: 14, dense: true)
            defer { app.terminate() }
            XCTAssertTrue(XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                (app.frame.width > app.frame.height) == orientation.isLandscape
                    && app.buttons["experiment.cell.0.0"].isHittable
            }, object: nil).wait(timeout: 8))
            assertRestoration(78, score: 14, in: app)
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label BEGINSWITH %@",
                                                           "experiment.cell.", "Empty,")).count, 0)
            let view = orientation.isLandscape ? "landscape" : "portrait"
            capture(app, "silver-tablet-\(view)-dense-075-before-native-win")
            clearTrio(in: app)
            XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
            XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Silver Pools restored!")
            XCTAssertTrue(app.staticTexts["experiment.score"].label.contains("18 of 18 starlight collected"))
            XCTAssertTrue(app.buttons["experiment.replay"].isHittable)
            capture(app, "silver-tablet-\(view)-100-after-native-win")
        }
    }
}
