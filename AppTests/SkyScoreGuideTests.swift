import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkyScoreGuideTests: XCTestCase {
    private func result(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky) -> SkyDialogueLine {
        SkyDialogueLibrary.result(for: turn, from: old, to: game, tracedCount: 0,
                                 recipe: nil, relayDepth: 0, techniqueResult: SkyCopy.text(.techniqueMoved))
    }

    private func exchange(_ from: Int, _ to: Int, in game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(from / 7, from % 7), to: Cell(to / 7, to % 7)))
    }

    func testScaledClearCopySeparatesActualStarAndLightCountsFromCommittedPointComponents() throws {
        let examples: [(StarfallChallenge, Int, Int, String, String, String)] = [
            (.kiteHarbor, 15, 14, "5,000",
             "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points.",
             "4 more spaces above the stars in column 1."),
            (.kiteHarbor, 4, 11, "7,000",
             "5 stars · 5 light. 5,000 base + 2,000 size = 7,000 points.",
             "5 more spaces above the stars in columns 3, 4, 5, 6, 7."),
            (.seedMoon, 4, 3, "6,000",
             "4 stars · 5 light. 5,000 base + 1,000 size = 6,000 points.",
             "4 more spaces above the stars in columns 1, 2, 3, 4."),
            (.silverPools, 2, 9, "7,000",
             "5 stars · 5 light. 5,000 base + 2,000 size = 7,000 points.",
             "5 more spaces above the stars in columns 1, 2, 3, 4, 5.")
        ]
        for (challenge, from, to, points, equation, room) in examples {
            let opening = FallingSky.freshChallenge(challenge)
            var game = opening
            let turn = try exchange(from, to, in: &game)
            XCTAssertFalse(game.isOver)
            let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
            XCTAssertEqual(explanation.phases.count, 1)
            XCTAssertEqual(explanation.phases[0].explanationText, equation)
            XCTAssertEqual(explanation.guideText, equation)
            let original = SkyDialogueLibrary.line("guide.automatic-recipe", values: ["score": points])
            let line = result(turn, from: opening, to: game)
            XCTAssertEqual(line.text, original.text + " " + equation + " " + room)
            XCTAssertEqual(line.id, original.id)
            XCTAssertEqual(line.speaker, original.speaker)
            XCTAssertEqual(line.priority, original.priority)
            XCTAssertEqual(line.seconds, original.seconds)
            XCTAssertTrue(line.isValid)
        }
    }

    func testSilverChainKeepsEachActualPhaseAndOneWholeActionTotalWithoutReplacingTheTerminalGuide() throws {
        let opening = FallingSky.freshChallenge(.silverPools)
        var game = opening
        let turn = try exchange(9, 10, in: &game)
        XCTAssertEqual(turn.resolutionPhases.map(\.award.clearedStarCount), [4, 5])
        XCTAssertEqual(turn.resolutionPhases.map(\.award.displayPoints), [5_000, 14_000])
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
        XCTAssertEqual(explanation.phases.map(\.physicalText), ["4 stars · 4 light.", "5 stars · 5 light."])
        XCTAssertEqual(explanation.phases.map(\.equationText), [
            "4,000 base + 1,000 size = 5,000 points.",
            "5,000 base + 2,000 size + 7,000 chain = 14,000 points."
        ])
        XCTAssertEqual(explanation.guideText,
                       "9 stars · 9 light. 9,000 base + 3,000 size + 7,000 chain = 19,000 points.")
        XCTAssertEqual(explanation.compactText, "9,000 base + 3,000 size + 7,000 chain")
        XCTAssertEqual(explanation.totalText, "19,000 points this clear.")
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(result(turn, from: opening, to: game),
                       SkyDialogueLibrary.line("guide.silver-won", values: ["score": "19,000"]))
    }

    func testManualOpenSkyAndDrainedHistoryUseTheirUnscaledActualLightWithoutStoryBonuses() throws {
        let opening = ConstellationFixture.horizontalFive.game()
        var game = opening
        let path = (0..<5).map { Cell(0, $0) }
        let turn = try XCTUnwrap(game.clearConstellation(path))
        XCTAssertNil(turn.award)
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
        XCTAssertEqual(explanation.phases[0].physicalText, "5 stars · 5 light.")
        XCTAssertEqual(explanation.phases[0].equationText, "5 light = 5 points.")
        XCTAssertEqual(explanation.guideText, "5 stars · 5 light = 5 points.")
        XCTAssertEqual(explanation.totalText, "5 points this clear.")
        XCTAssertFalse(explanation.guideText.contains("1,000"))
        XCTAssertFalse(explanation.guideText.contains("size"))
        XCTAssertFalse(explanation.guideText.contains("chain"))

        let drained = DuskFixture.zeroClear.game(rule: .patientFeeding)
        var after = drained
        let gray = try XCTUnwrap(after.clear(Cell(0, 1)))
        let empty = try XCTUnwrap(SkyScoreExplanation(turn: gray, from: drained))
        XCTAssertEqual(empty.guideText, "4 stars · 0 light = 0 points.")
        let line = result(gray, from: drained, to: after)
        let original = SkyDialogueLibrary.line("guide.gray-clear")
        XCTAssertEqual(line.text, original.text + " 4 stars · 0 light = 0 points. 4 more spaces above the stars in columns 1, 2, 3.")
        XCTAssertEqual(line.id, original.id)
        XCTAssertEqual(line.speaker, original.speaker)
        XCTAssertEqual(line.priority, original.priority)
        XCTAssertEqual(line.seconds, original.seconds)
        XCTAssertTrue(line.isValid)
    }

    func testFullBoardAggregateCountsEachRealClearOnceAndPreservesTheExactCumulativePrefix() throws {
        let opening = FallingSky.fullBoardLantern()
        var game = opening
        let turn = try exchange(8, 9, in: &game)
        let first = try XCTUnwrap(SkyScoreExplanation(phases: Array(turn.resolutionPhases.prefix(1)), expectedTotal: 5_000))
        let whole = try XCTUnwrap(SkyScoreExplanation(turn: turn, from: opening))
        XCTAssertEqual(first.guideText, "4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points.")
        XCTAssertEqual(first.compactText, "4,000 base + 1,000 size")
        XCTAssertEqual(whole.guideText, "8 stars · 8 light. 8,000 base + 2,000 size + 5,000 chain = 15,000 points.")
        XCTAssertEqual(whole.totalText, "15,000 points this clear.")
        let original = SkyDialogueLibrary.line("guide.cascade", values: ["depth": "2", "score": "15,000"])
        XCTAssertEqual(result(turn, from: opening, to: game).text,
                       original.text + " " + whole.guideText + " Refill added 8 stars; the board is full.")

        var setup = opening
        let move = try exchange(0, 1, in: &setup)
        XCTAssertNil(SkyScoreExplanation(turn: move, from: opening))
        XCTAssertEqual(result(move, from: opening, to: setup).text, "Star moved. What can you line up?")

        // Resolver geometry fixture, not an authored-route or difficulty claim.
        var overlap = Array<StarfallGem?>(repeating: nil, count: 49)
        for (id, index) in [0, 1, 2, 7, 8, 9].enumerated() { overlap[index] = .init(id: id, kind: .aqua) }
        let phases = SkyRecipeResolution.resolve(overlap, lineLength: 4)
        XCTAssertEqual(phases[0].recipes.count, 2)
        XCTAssertEqual(phases[0].recipes.flatMap(\.cells).count, 8)
        let union = try XCTUnwrap(SkyScoreExplanation(phases: phases, expectedTotal: 9_000))
        XCTAssertEqual(union.guideText, "6 stars · 6 light. 6,000 base + 3,000 size = 9,000 points.")
    }

    func testCompleteKnownCurrentRoutesAndRetainedFullBoardFitTheExistingGuideAndContextLimit() throws {
        func check(_ opening: FallingSky, actions: [[Int]], expectedScore: Int? = nil) throws {
            var game = opening
            for action in actions {
                if game.isOver { break }
                let old = game
                let turn = try XCTUnwrap(action.isEmpty ? game.letStarsFall()
                    : game.nudge(from: Cell(action[0] / 7, action[0] % 7), to: Cell(action[1] / 7, action[1] % 7)))
                let line = result(turn, from: old, to: game)
                let context = SkyDialogueLibrary.contextual(line, game: game,
                    cadence: .init(delay: 4, phase: .steady))
                XCTAssertTrue(line.isValid, "\(opening.challengeRevision): \(line.text)")
                XCTAssertTrue(context.isValid, context.text)
                if !game.isOver, let explanation = SkyScoreExplanation(turn: turn, from: old) {
                    XCTAssertTrue(line.text.contains(explanation.guideText))
                }
            }
            XCTAssertEqual(game.outcome, .won)
            if let expectedScore { XCTAssertEqual(game.displayScore, expectedScore) }
        }

        for (challenge, plan) in [(StarfallChallenge.firstLight, StoryPatternPlan.lantern), (.ribbonCrossing, .ribbon)] {
            let actions = plan.waves.flatMap { wave in wave.map { [$0.from, $0.to] } + [[]] }
            try check(.freshChallenge(challenge), actions: actions, expectedScore: plan.expectedScore)
        }
        try check(.freshChallenge(.kiteHarbor),
                  actions: [[4,11], [], [15,14], [36,29], [29,22], [4,3], [3,2], [2,1]], expectedScore: 18_000)
        try check(.freshChallenge(.seedMoon), actions: [[4,3], [0,1], [1,8], [2,9]], expectedScore: 11_000)
        try check(.freshChallenge(.silverPools), actions: [[2,9], [23,22]], expectedScore: 12_000)
        try check(.freshChallenge(.frostfruitOrchard), actions: [[35,36], [], [], [20,19], [2,9], [3,10]])
        try check(.freshChallenge(.sunwheelMill), actions: [[15,14], [], [], [17,18], [9,10]])
        try check(.fullBoardLantern(), actions: [[27,34], [1,2], [31,32], [12,13], [16,17],
                  [8,9], [11,12], [29,30], [29,36], [9,16]], expectedScore: 156_000)
        try check(.fullBoardRibbon(), actions: [[8,9], [11,12], [31,38], [17,24], [9,16], [9,10], [1,8],
                  [1,2], [1,8], [9,10], [10,11], [22,29], [2,3], [2,9], [1,8], [37,38], [2,3], [16,17]],
                  expectedScore: 229_000)

        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        var next = retained
        let large = try exchange(8, 9, in: &next)
        XCTAssertEqual(large.displayAward, 66_000)
        XCTAssertGreaterThan(large.resolutionPhases.count, 2)
        XCTAssertTrue(result(large, from: retained, to: next).isValid)

        var dusk = FallingSky(seed: 5, generation: .current, duskRule: .patientFeeding)
        for _ in 0..<6 { XCTAssertNotNil(dusk.letStarsFall()) }
        let before = dusk
        let clear = try XCTUnwrap(dusk.clear(Cell(0, 0)))
        let contextual = SkyDialogueLibrary.contextual(result(clear, from: before, to: dusk), game: dusk,
                                                       cadence: .init(delay: 4, phase: .steady))
        XCTAssertTrue(contextual.text.contains("3 stars · 3 light = 3 points."))
        XCTAssertTrue(contextual.text.contains("Dusk will eat"))
        XCTAssertTrue(contextual.isValid, contextual.text)
    }

    func testDefensiveTwentyPhaseReceiptKeepsItsAggregateGuideWithinTheExistingLineBound() throws {
        // Deliberately repeated mechanical phases exercise the presentation cap;
        // they are not a claimed reachable turn or a save/progression witness.
        var board = Array<StarfallGem?>(repeating: nil, count: 49)
        for column in 0..<4 { board[column] = .init(id: column, kind: .aqua) }
        let cleared = Set((0..<4).map { Cell(0, $0) })
        let phases = (1...20).map { depth in
            SkyResolutionPhase(kind: .recipe, before: board, cleared: cleared, comboDepth: depth)
        }
        let explanation = try XCTUnwrap(SkyScoreExplanation(phases: phases, expectedTotal: 450_000))
        XCTAssertEqual(explanation.phases.count, 20)
        XCTAssertEqual(explanation.guideText,
                       "80 stars · 80 light. 80,000 base + 20,000 size + 350,000 chain = 450,000 points.")
        XCTAssertEqual(explanation.totalText, "450,000 points this clear.")
        let original = SkyDialogueLibrary.line("guide.cascade", values: ["depth": "20", "score": "450,000"])
        let full = SkyDialogueLine(id: original.id, speaker: original.speaker,
            text: original.text + " " + explanation.guideText + " Refill added 80 stars; the board is full.",
            priority: original.priority, seconds: original.seconds)
        XCTAssertTrue(full.isValid, full.text)
        XCTAssertEqual(SkyCopy.text(.scoreExplanationTitle), "Last clear")
    }
}
