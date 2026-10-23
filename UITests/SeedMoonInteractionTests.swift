import XCTest

final class SeedMoonInteractionTests: RestorationInteractionScenarios {
    override var location: ReviewLocation { .seed }

    @MainActor func testSeedWinningClearPersistsNamedResultAndReplayStartsAtZero() {
        exerciseWinningClearPersistsNamedResultAndReplayStartsAtZero()
    }

    @MainActor func testSeedDenseOverflowKeepsNamedReplayAndRestartsAtZero() {
        exerciseDenseOverflowKeepsNamedReplayAndRestartsAtZero()
    }

    @MainActor func testSeedLargestTextSystemReduceMotionWinKeepsResultActionsUsable() {
        exerciseLargestTextSystemReduceMotionWinKeepsResultActionsUsable()
    }

    @MainActor func testSeedPreviewCancellationRetainsAllThreeExistingLocationsUntilBegin() {
        exercisePreviewCancellationRetainsLocationsUntilBegin([.lantern, .ribbon, .kite], newVisitTarget: 11_000)
    }

    @MainActor func testTabletRotationKeepsSeedRestorationAndNativeInput() throws {
        try exerciseTabletRotationKeepsRestorationAndNativeInput()
    }
}

extension SeedMoonInteractionTests {
    @MainActor private func freshSeed(largest: Bool = false, quiet: Bool = false) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--sky-flow-review", "--dialogue-review", "--world-legacy-review",
                               "-calmEffects", quiet ? "YES" : "NO"]
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        app.worldVisitControl("seedMoon").tap()
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Seed Moon")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("11,000 starlight"))
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("grown aqua"))
        capture(app, largest ? "seed-current-entry-largest" : "seed-current-entry-default")
        tap("sky.begin", in: app); pauseRunningSky(app)
        seedScore(0, in: app)
        XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.contains("Grown"))
        capture(app, largest ? "seed-current-grown-opening-largest" : "seed-current-grown-opening-default")
        return app
    }

    @MainActor private func seedScore(_ value: Int, in app: XCUIApplication) {
        let score = "\(value.formatted()) of 11,000 starlight collected"
        // The result uses the existing spoken ceremony sentence. Check its
        // delimited numeric slot; the live HUD is the bare exact score label.
        let predicate = app.staticTexts["experiment.outcome"].exists
            ? NSPredicate(format: "identifier == %@ AND label CONTAINS %@", "experiment.score", " \(score).")
            : NSPredicate(format: "identifier == %@ AND label == %@", "experiment.score", score)
        app.waitForSkyElement(matching: predicate, timeout: 5,
            failure: "The Seed ingredient choice must commit its exact score")
    }

    @MainActor private func seedPlan(_ plan: StoryPatternPlan, in app: XCUIApplication, restore: Bool = false) {
        var count = 0
        app.completeStoryPattern(plan, exchange: { from, to, _ in
            app.revealSkyControls([from, to])
            XCTAssertTrue(from.isHittable && to.isHittable)
            from.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
                thenDragTo: to.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                withVelocity: .fast, thenHoldForDuration: 0.05)
            count += 1
            if count == 1 {
                seedScore(plan.expectedScore == 11_000 ? 6_000 : 0, in: app)
                if plan.expectedScore == 13_000 {
                    app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label CONTAINS %@",
                        "experiment.cell.1.1", "Grown"), timeout: 5,
                        failure: "The zero-score setup must preserve the grown ingredient")
                }
                capture(app, plan.expectedScore == 11_000 ? "seed-current-spend-six-thousand" : "seed-current-preserve-zero")
                if restore {
                    let board = app.otherElements["experiment.board"].value as? String
                    let ingredient = app.buttons["experiment.cell.1.1"].label
                    XCTAssertNotNil(board)
                    XCUIDevice.shared.press(.home); app.activate()
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
                    app.terminate()
                    app.launchArguments = ["--sky-flow-review", "--dialogue-review", "-calmEffects", "NO"]
                    app.launch(); tap("sky.resume", in: app)
                    XCTAssertTrue(app.buttons["experiment.next"].waitForExistence(timeout: 5))
                    XCTAssertEqual(app.otherElements["experiment.board"].value as? String, board)
                    XCTAssertEqual(app.buttons["experiment.cell.1.1"].label, ingredient)
                    seedScore(0, in: app)
                    capture(app, "seed-current-grown-choice-restored")
                }
            } else if count == 2 && plan.expectedScore == 13_000 {
                seedScore(8_000, in: app)
                capture(app, "seed-current-preserve-eight-thousand")
            }
        }, shower: { XCTFail("Both Seed opening alternatives must finish without Next") })
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Seed Moon restored!")
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Silver Pools")
        capture(app, plan.expectedScore == 11_000 ? "seed-current-spend-win" : "seed-current-preserve-win")
    }

    @MainActor func testCurrentSeedChoicesRestoreReplayAndOverflow() {
        executionTimeAllowance = 360
        setSystemMotion(reduced: false)
        for preserve in [false, true] {
            let app = freshSeed()
            defer { app.terminate() }
            seedPlan(preserve ? .seedPreserve : .seedSpend, in: app, restore: preserve)
            if preserve {
                app.terminate(); app.launchArguments = ["--sky-flow-review", "--dialogue-review"]; app.launch()
                tap("sky.resume", in: app)
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                seedScore(13_000, in: app)
                tap("experiment.replay", in: app)
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("same Seed Moon opening"))
                XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("11,000 starlight"))
                tap("sky.begin", in: app); pauseRunningSky(app)
                seedScore(0, in: app)
                XCTAssertTrue(app.buttons["experiment.cell.0.1"].label.contains("Grown"))
                for _ in 0..<6 where !app.staticTexts["experiment.outcome"].exists {
                    // A shower can finish the round while its presentation
                    // replaces Next with the ordinary terminal ceremony.
                    app.waitForSkyElement(matching: NSPredicate(format:
                        "(identifier == %@ AND enabled == true) OR identifier == %@",
                        "experiment.next", "experiment.outcome"), timeout: 5,
                        failure: "The paused shower must settle or reach its terminal result")
                    if !app.staticTexts["experiment.outcome"].exists { tap("experiment.next", in: app) }
                }
                XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "No room to land")
                capture(app, "seed-current-ignored-opening-overflow")
            }
        }
    }

    @MainActor func testCurrentSeedAutomaticShowerRecoveryEarnsSilver() {
        executionTimeAllowance = 240
        continueAfterFailure = false
        setSystemMotion(reduced: false)
        let app = XCUIApplication()
        app.launchArguments = ["--starfalls-reset", "--world-map-review", "--world-map-state=twoRepairs",
                               "--dialogue-review", "-calmEffects", "NO"]
        app.launch()
        defer { app.terminate() }
        let silver = app.buttons["world.node.silverPools"]
        app.revealWorldMapMarker(silver); silver.tap()
        XCTAssertEqual(app.staticTexts["world.status"].label, "Restore Seed Moon first")
        XCTAssertFalse(app.buttons["world.visit"].exists)
        let kite = app.buttons["world.node.kiteHarbor"]
        app.revealWorldMapMarker(kite); kite.tap()
        tap("world.visit", in: app); tap("sky.begin", in: app); pauseRunningSky(app)
        app.completeStoryPattern(.kitePoints)
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Kite Harbor restored!")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Seed Moon")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("11,000 starlight"))
        tap("sky.begin", in: app); pauseRunningSky(app)
        let setup = app.buttons["experiment.cell.0.1"], setupTo = app.buttons["experiment.cell.1.1"]
        XCTAssertTrue(setup.label.contains("Grown"))
        app.revealSkyControls([setup, setupTo])
        setup.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).press(forDuration: 0.05,
            thenDragTo: setupTo.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0.05)
        seedScore(0, in: app)
        app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label CONTAINS %@",
            "experiment.cell.1.1", "Grown"), timeout: 5, failure: "Preserve the ingredient before the first shower")
        if app.buttons["sky.dialogue.close"].exists { tap("sky.dialogue.close", in: app) }
        let moves = [(17, 10), (1, 2), (2, 9), (7, 8)].map { from, to in
            let source = app.buttons["experiment.cell.\(from / 7).\(from % 7)"]
            let destination = app.buttons["experiment.cell.\(to / 7).\(to % 7)"]
            XCTAssertTrue(source.isHittable && destination.isHittable)
            return (source.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)),
                    destination.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)))
        }
        tap("experiment.settings", in: app); tap("experiment.pause", in: app)
        app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND value BEGINSWITH %@",
            "experiment.board", "1 showers"), timeout: 10, failure: "One ordinary shower must arrive without Next")
        app.waitForSkyElement(matching: NSPredicate(format: "identifier == %@ AND label == %@",
            "experiment.arrivalCue", "Next shower on its way"), timeout: 5,
            failure: "The shower must finish landing before recovery")
        XCTAssertTrue((app.otherElements["experiment.board"].value as? String)?.hasPrefix("1 showers") == true)
        for (index, move) in moves.enumerated() {
            move.0.press(forDuration: 0.05, thenDragTo: move.1, withVelocity: .fast, thenHoldForDuration: 0.05)
            if index == 0 { seedScore(8_000, in: app) }
        }
        XCTAssertTrue(app.staticTexts["experiment.outcome"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["experiment.outcome"].label, "Seed Moon restored!")
        seedScore(14_000, in: app)
        XCTAssertEqual(app.buttons["sky.worldMap"].label, "Visit Silver Pools")
        capture(app, "seed-current-automatic-shower-earned-win")
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Silver Pools")
        XCTAssertEqual(app.staticTexts["world.status"].label, "Ready to restore")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Silver Pools")
        XCTAssertTrue(app.staticTexts["sky.subtitle"].label.contains("18 starlight"))
        capture(app, "seed-current-earned-silver-entry")
    }

    @MainActor func testCurrentSeedLargestQuietHelpAndOnward() {
        executionTimeAllowance = 300
        setSystemMotion(reduced: false)
        let app = freshSeed(largest: true, quiet: true)
        defer { app.terminate() }
        tap("experiment.settings", in: app)
        app.skyMenuControl("experiment.help").tap()
        let explanation = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@",
            "Seed Moon", "11,000")).firstMatch
        XCTAssertTrue(explanation.waitForExistence(timeout: 5))
        for text in ["6,000", "8,000", "two light units", "Waiting does not increase", "Patterns pop automatically"] {
            XCTAssertTrue(explanation.label.contains(text))
        }
        XCTAssertFalse(explanation.label.contains("tap groups"))
        let heading = app.staticTexts["Seed Moon · Choose your ingredients"]
        for _ in 0..<36 where !heading.isHittable || heading.frame.maxY > app.frame.maxY - 80 { app.swipeUp() }
        XCTAssertTrue(heading.isHittable)
        capture(app, "seed-current-help-heading-largest")
        // Keep an overlapping middle viewport as well as the final line. A
        // hittable long AX paragraph does not prove all of it was visible.
        app.swipeUp()
        capture(app, "seed-current-help-middle-largest")
        for _ in 0..<12 where explanation.frame.maxY > app.frame.maxY - 80 { app.swipeUp() }
        XCTAssertLessThanOrEqual(explanation.frame.maxY, app.frame.maxY - 80)
        XCTAssertGreaterThan(explanation.frame.maxY, app.frame.minY + 80)
        XCTAssertTrue(explanation.isHittable)
        capture(app, "seed-current-help-end-largest")
        tap("Done", in: app)
        seedPlan(.seedPreserve, in: app)
        let onward = app.buttons["sky.worldMap"]
        app.revealSkyControls([onward, app.buttons["experiment.replay"]])
        XCTAssertGreaterThanOrEqual(onward.frame.height, 44)
        tap("sky.worldMap", in: app)
        XCTAssertEqual(app.staticTexts["world.selection"].label, "Silver Pools")
        tap("world.visit", in: app)
        XCTAssertTrue(app.buttons["sky.begin"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["sky.title"].label, "Silver Pools")
        capture(app, "seed-current-silver-entry-largest")
    }
}
