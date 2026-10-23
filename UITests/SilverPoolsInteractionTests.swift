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
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon], newVisitTarget: 12_000)
    }

    @MainActor func testSilverPreviewCancellationRetainsKiteAndSeedUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.kite, .seed], newVisitTarget: 12_000)
    }

    @MainActor func testSilverPhoneAllFiveStatesKeepNativeBoardFixed() {
        exercisePhoneAllFiveStatesKeepNativeBoardFixed()
    }

    @MainActor func testSilverDenseRapidClearSurvivesSettingsAndBackground() {
        exerciseDenseRapidClearSurvivesSettingsAndBackground()
    }

    @MainActor func testTabletRotationKeepsSilverRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }

    @MainActor func testTabletDenseSilverCompletionKeepsNativeInput() throws {
        try exerciseTabletDenseCompletionKeepsNativeInput()
    }
}

extension SilverPoolsInteractionTests {
    @MainActor private func freshSilver(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review",
                               "-calmEffects", quiet ? "YES" : "NO"]
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        app.worldVisitControl("silverPools").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Silver Pools")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("12,000 starlight"))
        capture(app, largest ? "silver-current-entry-largest" : "silver-current-entry-default")
        tap("sky.begin", in: app); pauseRunningSky(app)
        silverScore(0, in: app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND NOT label BEGINSWITH %@", "experiment.cell.", "Empty,")).count, 24)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:
            "identifier BEGINSWITH %@ AND label CONTAINS %@", "experiment.cell.", "Grown")).count, 0)
        capture(app, largest ? "silver-current-opening-largest" : "silver-current-opening-default")
        return app
    }

    @MainActor private func silverScore(_ value: Int, in app: XCUIApplication) {
        let score = "\(value.formatted()) of 12,000 starlight collected"
        let predicate = app.staticTexts["experiment.outcome"].exists
            ? NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "experiment.score", " \(score).")
            : NSPredicate(format: "identifier == %@ AND label == %@", "experiment.score", score)
        app.waitForSkyElement(matching: predicate, timeout: 5,
            failure: "The Silver sequence must commit its exact score")
    }

    @MainActor private func silverPlan(_ plan: StoryPatternPlan, in app: XCUIApplication, restore: Bool = false) {
        var count = 0
        app.completeStoryPattern(plan, exchange: { from, to, _ in
            app.revealSkyControls([from, to])
            XCTAssertTrue(from.isHittable && to.isHittable)
            from.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
                thenDragTo: to.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                withVelocity: .fast, thenHoldForDuration: 0.05)
            count += 1
            if count == 1 && plan.expectedExchanges == 2 {
                silverScore(7_000, in: app)
                capture(app, "silver-current-immediate-seven-thousand")
                if restore {
                    let board = app.otherElements["experiment.board"].value as? String
                    let survivor = app.buttons["experiment.cell.3.2"].label
                    XCTAssertNotNil(board)
                    XCUIDevice.shared.press(.home); app.activate()
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
                    app.terminate()
                    app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
                    app.launch(); tap("sky.resume", in: app)
                    XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
                    XCTAssertEqual(app.buttons["experiment.cell.3.2"].label, survivor)
                    silverScore(7_000, in: app)
                    capture(app, "silver-current-separate-choice-restored")
                }
            }
        }, shower: { XCTFail("Both Silver opening alternatives must finish without Next") })
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Silver Pools restored!")
        silverScore(plan.expectedScore, in: app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        capture(app, plan.expectedExchanges == 1 ? "silver-current-survivor-chain-win" : "silver-current-separate-clears-win")
    }

    @MainActor func testCurrentSilverCausalChoicesRestoreReplayAndOverflow() {
        executionTimeAllowance = 360
        setSystemMotion(reduced: false)
        for separate in [false, true] {
            let app = freshSilver()
            defer { app.terminate() }
            silverPlan(separate ? .silverImmediate : .silverChain, in: app, restore: separate)
            if separate {
                app.terminate(); app.launchArguments = ["--sky-flow-review", "--dialogue-review"]; app.launch()
                tap("sky.resume", in: app)
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                silverScore(12_000, in: app)
                tap("experiment.replay", in: app)
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Silver Pools opening"))
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("12,000 starlight"))
                tap("sky.begin", in: app); pauseRunningSky(app)
                silverScore(0, in: app)
                for _ in 0..<4 where !app.staticTexts["experiment.outcome"].exists {
                    app.waitForSkyElement(matching: NSPredicate(format:
                        "(identifier == %@ AND enabled == true) OR identifier == %@",
                        "experiment.next", "experiment.outcome"), timeout: 5,
                        failure: "The paused shower must settle or reach overflow")
                    if !app.staticTexts["experiment.outcome"].exists { tap("experiment.next", in: app) }
                }
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "No room to land")
                silverScore(0, in: app)
                capture(app, "silver-current-ignored-opening-overflow")
            }
        }
    }

    @MainActor func testCurrentSilverAutomaticShowerChainEarnsFrostfruit() {
        executionTimeAllowance = 300
        continueAfterFailure = false
        setSystemMotion(reduced: false)
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--world-map-review", "--world-map-state=twoRepairs",
                               "--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        defer { app.terminate() }
        let frostfruit = app.buttons["world.node.frostfruitOrchard"]
        app.revealWorldMapMarker(frostfruit); frostfruit.tap()
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Silver Pools first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        let kite = app.buttons["world.node.kiteHarbor"]
        app.revealWorldMapMarker(kite); kite.tap()
        tap("world.visit", in: app); tap("sky.begin", in: app); pauseRunningSky(app)
        app.completeStoryPattern(.kitePoints)
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Kite Harbor restored!")
        tap("sky.worldMap", in: app); tap("world.visit", in: app)
        tap("sky.begin", in: app); pauseRunningSky(app)
        app.completeStoryPattern(.seedSpend)
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Seed Moon restored!")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Silver Pools")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("12,000 starlight"))
        tap("sky.begin", in: app); pauseRunningSky(app)
        if app.buttons["sky.dialogue.close"].exists { tap("sky.dialogue.close", in: app) }
        let source = app.buttons["experiment.cell.1.2"], destination = app.buttons["experiment.cell.1.3"]
        app.revealSkyControls([source, destination])
        XCTAssertTrue(source.isHittable && destination.isHittable)
        let from = source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        let to = destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        tap("experiment.settings", in: app); tap("experiment.pause", in: app)
        app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND value BEGINSWITH %@",
            "experiment.board", "1 showers"), timeout: 10, failure: "One ordinary Silver shower must arrive without Next")
        app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label == %@",
            "experiment.arrivalCue", "Next shower on its way"), timeout: 5,
            failure: "The Silver shower must finish landing before the support exchange")
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("1 showers") == true)
        from.press(forDuration: 0.05, thenDragTo: to, withVelocity: .fast, thenHoldForDuration: 0.05)
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Silver Pools restored!")
        silverScore(19_000, in: app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Frostfruit Orchard")
        capture(app, "silver-current-automatic-shower-earned-chain-win")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Frostfruit Orchard")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
        capture(app, "silver-current-earned-frostfruit-entry")
    }

    @MainActor func testCurrentSilverLargestQuietHelpAndOnward() {
        executionTimeAllowance = 300
        setSystemMotion(reduced: false)
        let app = freshSilver(largest: true, quiet: true)
        defer { app.terminate() }
        tap("experiment.settings", in: app)
        app.skyMenuControl("experiment.help").tap()
        let explanation = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
            "Silver Pools", "12,000")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        for text in ["5,000", "four rows", "14,000", "19,000", "7,000", "separate actions are not a chain", "Patterns pop automatically"] {
            XCTAssertTrue(explanation.label.contains(text))
        }
        XCTAssertFalse(explanation.label.contains("tap groups"))
        let heading = app.staticTexts["Silver Pools · Plan the falling stars"]
        for _ in 0..<40 where !heading.isHittable || heading.frame.maxY > app.frame.maxY - 80 { app.swipeUp() }
        XCTAssertTrue(heading.isHittable)
        capture(app, "silver-current-help-heading-largest")
        app.swipeUp(); capture(app, "silver-current-help-middle-largest")
        for _ in 0..<12 where explanation.frame.maxY > app.frame.maxY - 80 { app.swipeUp() }
        XCTAssertLessThanOrEqual(explanation.frame.maxY, app.frame.maxY - 80)
        XCTAssertGreaterThan(explanation.frame.maxY, app.frame.minY + 80)
        XCTAssertTrue(explanation.isHittable)
        capture(app, "silver-current-help-end-largest")
        tap("Done", in: app)
        silverPlan(.silverImmediate, in: app)
        let onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([onward, app.buttons["experiment.replay"]])
        XCTAssertGreaterThanOrEqual(onward.frame.height, 44)
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Frostfruit Orchard")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Frostfruit Orchard")
        capture(app, "silver-current-frostfruit-entry-largest")
    }
}
