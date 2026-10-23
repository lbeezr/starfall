import XCTest
@testable import StarfallCore

final class StoryMasteryTests: XCTestCase {
    private let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let skyIdentity = StoryMasteryIdentity(challenge: .firstLight, contentRevision: 4, goalSetRevision: 1)
    private let fullIdentity = StoryMasteryIdentity(challenge: .firstLight, contentRevision: 6, goalSetRevision: 1)
    private let skyJoint: [[Int]] = [
        [8,9],[0,1],[5,12],[0,1],[],[],[],[4,11],
        [1,2],[10,9],[11,12],[],[3,10],[3,4],[9,10],[10,11],
        [],[17,18],[3,4],[5,6],[],[12,13],[5,12],[],
        [13,12],[5,12],[0,1],[1,2],[],[4,5],[1,8],[21,22],
        [8,15],[],[3,4],[2,3],[1,2],[20,19],[],[2,3],
        [5,12],[16,17],[],[],[13,20],[1,2],[2,3],[3,4],
        [],[4,5],[0,7],[8,15],[5,6],[],[3,10],[5,6],
        [1,2],[2,3],[],[9,10],[22,23],[7,8],[4,5],[],
        [3,4],[2,3],[10,17],[5,6],[],[4,5],[1,2],[2,3],
        [6,13],[],[28,29],[1,8],[1,2],[7,8],[],[21,22],
        [5,6],[4,5],[3,4],[],[2,3],[1,2],[12,19],[3,4],
        [],[4,5],[7,8],[1,8],[0,1],[],[5,12],[12,13],
        [11,12]
    ]
    private let skyRecovery: [[Int]] = [
        [1,2],[10,17],[16,15],[7,8],[12,19],[1,2],[],[14,15],
        [0,7],[5,6],[],[19,20],[7,8],[8,9],[11,10],[12,11],
        [1,8],[],[26,27],[16,17],[0,1],[7,8],[8,9],[5,6],
        [],[5,12],[6,13],[],[15,16],[2,3],[26,25],[18,17],
        [0,1],[],[9,10],[2,9],[1,8],[14,15],[],[41,40],
        [18,19],[33,32],[25,24],[],[9,16],[18,25],[19,20],[4,5],
        [],[34,41],[18,25],[26,25],[27,26],[4,5],[],[29,28],
        [24,25],[30,31],[31,32],[25,26],[],[18,19],[9,10],[22,23],
        [7,8],[13,12],[0,7],[],[10,11],[10,17],[4,11],[21,22],
        [22,23],[4,5],[],[18,19],[5,6],[9,10],[0,1],[1,2],
        [2,3],[],[1,2],[3,10],[],[20,19],[4,11],[2,9]
    ]
    private let high = [[27,34],[1,2],[31,32],[12,13],[16,17],[8,9],[11,12],[29,30],[29,36],[9,16]]
    private let line = [[1,2],[27,34],[5,12],[0,1],[16,17],[24,31],[25,32],[1,2],[1,8],[7,14],[37,44],
                        [2,3],[2,9],[33,34],[18,19],[16,17],[18,25],[18,19],[1,2],[4,11],[32,33]]
    // This route delays its opener; it does not claim an irreversible missed cascade.
    private let delayed = [[3,10],[27,34],[8,9],[12,13],[11,12],[2,9],[2,3],[3,10],[30,37],[37,44],
                           [3,4],[24,25],[23,24],[38,39],[1,2],[2,3],[3,10],[0,1],[21,28]]

    private func changed(_ game: FallingSky, _ edit: (inout [String: Any]) throws -> Void) throws -> FallingSky {
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as? [String: Any])
        try edit(&fields)
        return try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: fields))
    }

    private func withoutEnrollment(_ game: FallingSky) throws -> FallingSky {
        try changed(game) { $0.removeValue(forKey: "masteryEnrollment") }
    }

    private func restored(_ game: FallingSky) throws -> FallingSky {
        let copy = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(copy, game)
        XCTAssertTrue(copy.isValidSave)
        return copy
    }

    private func apply(_ action: [Int], to game: inout FallingSky) throws -> FallingSkyTurn {
        if action.isEmpty { return try XCTUnwrap(game.letStarsFall()) }
        return try XCTUnwrap(game.nudge(from: Cell(action[0]/7,action[0]%7), to: Cell(action[1]/7,action[1]%7)))
    }

    @discardableResult private func actual(_ initial: FallingSky, path: [[Int]], final: Int,
                                           expected: Set<StoryMasteryGoal>) throws -> FallingSky {
        var game = initial, plain = initial
        XCTAssertTrue(game.enrollMastery(runID: firstID))
        let identity = try XCTUnwrap(game.masteryEnrollment).identity
        var earned: Set<StoryMasteryGoal> = []
        for (index, action) in path.enumerated() {
            var copy = try restored(game)
            let turn = try apply(action, to: &game)
            let repeated = try apply(action, to: &copy)
            let original = try apply(action, to: &plain)
            XCTAssertEqual(turn.resolutionPhases, repeated.resolutionPhases)
            XCTAssertEqual(turn.resolutionPhases, original.resolutionPhases)
            XCTAssertEqual(turn.arrivals.map(\.gem), repeated.arrivals.map(\.gem))
            XCTAssertEqual(turn.arrivals.map(\.cell), repeated.arrivals.map(\.cell))
            XCTAssertEqual(turn.arrivals.map(\.star), repeated.arrivals.map(\.star))
            XCTAssertEqual(game, copy)
            XCTAssertEqual(try withoutEnrollment(game), plain, "Enrollment never changes rules, supply or RNG")
            if identity.contentRevision == 4,
               turn.resolutionPhases.contains(where: { phase in
                   phase.cleared.contains { phase.before[$0.row*7+$0.column]?.grown == true }
               }) { earned.insert(.grownCollection) }
            if turn.resolutionPhases.count >= 2 { earned.insert(.cascade) }
            if identity.contentRevision == 6,
               turn.resolutionPhases.contains(where: { $0.cleared.count >= 8 }) { earned.insert(.largeClear) }
            XCTAssertEqual(game.masteryProgress?.earned, earned, "Committed action \(index)")
            XCTAssertEqual(game.masteryProgress?.goals, identity.goals)
            XCTAssertTrue(game.isValidSave)
            XCTAssertTrue(try XCTUnwrap(game.replay().masteryProgress).earned.isEmpty)
            if game.outcome != .won { XCTAssertNil(game.completedMasteryRun) }
        }
        XCTAssertEqual(game.displayScore, final)
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.masteryProgress?.earned, expected)
        let record = try XCTUnwrap(game.completedMasteryRun)
        XCTAssertTrue(record.isValid)
        XCTAssertEqual(record.earned, expected)
        XCTAssertEqual(record.rank, 1+expected.count)
        XCTAssertEqual(record.runID, firstID)
        XCTAssertEqual(try JSONDecoder().decode(StoryMasteryRecord.self, from: JSONEncoder().encode(record)), record)
        return game
    }

    /// Invariant-valid aggregate accounting fixtures exercise ranks and record
    /// validation. They are not claims about reachable authored action histories.
    private func aggregateWin(grown: Bool, cascade: Bool, runID: UUID) throws -> FallingSky {
        var opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(opening.enrollMastery(runID: runID))
        let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 4))
        var ledger = StoryScoreLedger(automaticRecipes: true)
        let phases = cascade ? 29 : 30
        var light = 0
        for index in 0..<phases {
            let base = 4 + (grown && index == 0 ? 1 : 0)
            light += base
            ledger.record(SkyScoreAward(baseLight: base, clearedStarCount: 4), depth: cascade && index == phases-1 ? 2 : 1)
        }
        let landed = definition.initialLight + definition.suppliedLight(after: 20)
        var board: [StarfallGem?] = Array(repeating: nil, count: 49)
        for index in 0..<(landed-light) {
            board[index] = StarfallGem(id: light+index, kind: Jewel.allCases[index % Jewel.allCases.count])
        }
        let game = try changed(opening) {
            $0["score"] = light
            $0["storyScoreLedger"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ledger))
            $0["board"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(board))
            $0["turns"] = 20
            $0["starsLanded"] = landed
            $0["incoming"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(definition.shower(number: 21)))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        return game
    }

    /// Full Board accounting variants likewise prove validation and rank rules,
    /// not four independently discovered production routes.
    private func fullAggregateWin(cascade: Bool, large: Bool) throws -> FallingSky {
        var opening = FallingSky.fullBoardLantern()
        XCTAssertTrue(opening.enrollMastery(runID: firstID))
        var ledger = StoryScoreLedger(automaticRecipes: true)
        var light = 0
        if large {
            ledger.record(SkyScoreAward(baseLight: 8, clearedStarCount: 8))
            light += 8
        }
        let fours = large ? 28 : cascade ? 29 : 30
        for index in 0..<fours {
            ledger.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4), depth: cascade && index == fours-1 ? 2 : 1)
            light += 4
        }
        var random = SeededRandom(seed: 42)
        for _ in 0..<light { _ = random.next() }
        let game = try changed(opening) {
            $0["score"] = light
            $0["starsLanded"] = 49+light
            $0["turns"] = ledger.actionCount
            $0["storyScoreLedger"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(ledger))
            $0["fullBoardSupply"] = ["suppliedStars":light,"refillingPhases":ledger.phaseCount]
            $0["random"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(random))
        }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        return game
    }

    func testOnlyTheTwoExactLanternContractsAreAvailableWithoutAutomaticEnrollment() throws {
        for challenge in StarfallChallenge.allCases {
            let game = FallingSky.freshChallenge(challenge)
            XCTAssertEqual(StoryMasteryIdentity.available(for: game), challenge == .firstLight ? skyIdentity : nil)
            XCTAssertNil(game.masteryEnrollment)
            XCTAssertNil(game.masteryProgress)
            XCTAssertNil(game.completedMasteryRun)
        }
        XCTAssertEqual(StoryMasteryIdentity.available(for: .fullBoardLantern()), fullIdentity)
        XCTAssertNil(StoryMasteryIdentity.available(for: .fullBoardRibbon()))
        for revision in [1,2,3,5] {
            let game = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: revision)))
            XCTAssertNil(StoryMasteryIdentity.available(for: game))
        }
        XCTAssertEqual(skyIdentity.goals, [.grownCollection,.cascade])
        XCTAssertEqual(fullIdentity.goals, [.cascade,.largeClear])
        for identity in [StoryMasteryIdentity(challenge: .ribbonCrossing, contentRevision: 4, goalSetRevision: 1),
                         StoryMasteryIdentity(challenge: .firstLight, contentRevision: 5, goalSetRevision: 1),
                         StoryMasteryIdentity(challenge: .firstLight, contentRevision: 4, goalSetRevision: 2)] {
            XCTAssertFalse(identity.isValid)
            XCTAssertTrue(identity.goals.isEmpty)
        }
    }

    func testEnrollmentRequiresAValidPristineOpeningAndCannotReplaceAnAttempt() throws {
        for initial in [FallingSky.freshChallenge(.firstLight), .fullBoardLantern()] {
            var game = initial
            XCTAssertTrue(game.enrollMastery(runID: firstID))
            XCTAssertTrue(game.isValidSave)
            XCTAssertFalse(game.enrollMastery(runID: secondID))
            XCTAssertEqual(game.masteryEnrollment?.runID, firstID)
            XCTAssertEqual(try withoutEnrollment(game), initial)
            XCTAssertEqual(try restored(game), game)
            XCTAssertTrue(try XCTUnwrap(game.masteryProgress).earned.isEmpty)
        }
        var arranged = FallingSky.freshChallenge(.firstLight)
        _ = try apply([3,10], to: &arranged)
        XCTAssertEqual(arranged.score, 0)
        XCTAssertEqual(arranged.turns, 0)
        XCTAssertFalse(arranged.enrollMastery(runID: firstID))
        var played = FallingSky.fullBoardLantern()
        _ = try apply([8,9], to: &played)
        XCTAssertFalse(played.enrollMastery(runID: firstID))
        var invalid = try changed(FallingSky.freshChallenge(.firstLight)) { $0["seed"] = 43 }
        XCTAssertFalse(invalid.enrollMastery(runID: firstID))
        for initial in [FallingSky(challenge: .firstLight), .freshChallenge(.ribbonCrossing), .fullBoardRibbon(), .freshSurvival(seed: 42)] {
            var game = initial
            XCTAssertFalse(game.enrollMastery(runID: firstID))
            XCTAssertEqual(game, initial)
        }
    }

    func testMissingEnrollmentStaysAbsentThroughRestoreAndBothReplayEntryPoints() throws {
        let completed = try withoutEnrollment(aggregateWin(grown: true, cascade: true, runID: firstID))
        XCTAssertTrue(completed.isValidSave)
        XCTAssertEqual(completed.outcome, .won)
        XCTAssertNil(completed.masteryEnrollment)
        XCTAssertNil(completed.masteryProgress)
        XCTAssertNil(completed.completedMasteryRun)
        XCTAssertNil(try restored(completed).replay().masteryEnrollment)
        XCTAssertNil(completed.replay(masteryRunID: secondID).masteryEnrollment)
        var journey = WorldJourney()
        journey.record(completed)
        XCTAssertTrue(journey.completed.contains(.firstLight))
    }

    func testReplayPreservesTheContractResetsGoalsAndUsesOnlyTheExplicitNewAttemptID() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(game.enrollMastery(runID: firstID))
        _ = try apply([8,9], to: &game)
        XCTAssertEqual(game.masteryProgress?.earned, [.cascade])
        let preview = game.replay()
        XCTAssertEqual(preview.masteryEnrollment, game.masteryEnrollment)
        XCTAssertTrue(try XCTUnwrap(preview.masteryProgress).earned.isEmpty)
        let replay = game.replay(masteryRunID: secondID)
        XCTAssertEqual(replay.masteryEnrollment?.identity, skyIdentity)
        XCTAssertEqual(replay.masteryEnrollment?.runID, secondID)
        XCTAssertTrue(try XCTUnwrap(replay.masteryProgress).earned.isEmpty)
        XCTAssertEqual(try withoutEnrollment(replay), FallingSky.freshChallenge(.firstLight))
        XCTAssertEqual(game.masteryProgress?.earned, [.cascade])
    }

    func testActualFixedRoutesMatchCommittedPhasePredicatesAtAll235Actions() throws {
        XCTAssertEqual(skyJoint.count+skyRecovery.count+high.count+line.count+delayed.count, 235)
        try actual(.freshChallenge(.firstLight), path: skyJoint, final: 151_000, expected: [.grownCollection,.cascade])
        try actual(.freshChallenge(.firstLight), path: skyRecovery, final: 150_000, expected: [.grownCollection,.cascade])
        try actual(.fullBoardLantern(), path: high, final: 156_000, expected: [.cascade,.largeClear])
        try actual(.fullBoardLantern(), path: line, final: 150_000, expected: [.cascade])
        try actual(.fullBoardLantern(), path: delayed, final: 151_000, expected: [.cascade])
    }

    func testFullBoardLargeClearFirstQualifiesInTheEntireWinningTransaction() throws {
        var game = FallingSky.fullBoardLantern()
        XCTAssertTrue(game.enrollMastery(runID: firstID))
        for action in high.dropLast() { _ = try apply(action, to: &game) }
        XCTAssertEqual(game.displayScore, 98_000)
        XCTAssertEqual(game.masteryProgress?.earned, [.cascade])
        let finish = try apply(high.last!, to: &game)
        XCTAssertEqual(finish.resolutionPhases.map { $0.cleared.count }, [10,8,4])
        XCTAssertEqual(game.completedMasteryRun?.earned, [.cascade,.largeClear])
        XCTAssertEqual(game.completedMasteryRun?.rank, 3)
        XCTAssertEqual(game.displayScore, 156_000)
        XCTAssertNil(game.nudge(from: Cell(0,0), to: Cell(0,1)))
    }

    func testGrowthSizeAndSimultaneousPatternsAreNotInterchangeableWithTheGoals() throws {
        var empty = StoryScoreLedger(automaticRecipes: true)
        XCTAssertEqual(empty.masteryGoals(for: skyIdentity, light: 0), [])
        empty.record(SkyScoreAward(baseLight: 8, clearedStarCount: 8))
        XCTAssertEqual(empty.masteryGoals(for: skyIdentity, light: 8), [], "A large small-star clear is not grown collection or a chain")
        XCTAssertEqual(empty.masteryGoals(for: fullIdentity, light: 8), [.largeClear], "Two simultaneous patterns are one phase")
        var six = StoryScoreLedger(automaticRecipes: true)
        six.record(SkyScoreAward(baseLight: 6, clearedStarCount: 6))
        XCTAssertEqual(six.masteryGoals(for: fullIdentity, light: 6), [])
        var grown = StoryScoreLedger(automaticRecipes: true)
        grown.record(SkyScoreAward(baseLight: 5, clearedStarCount: 4))
        XCTAssertEqual(grown.masteryGoals(for: skyIdentity, light: 5), [.grownCollection])
        XCTAssertNil(grown.masteryGoals(for: fullIdentity, light: 5), "Full Board cannot contain grown light")
        var separate = StoryScoreLedger(automaticRecipes: true)
        separate.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4))
        separate.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4))
        XCTAssertEqual(separate.masteryGoals(for: skyIdentity, light: 8), [])
        var chain = StoryScoreLedger(automaticRecipes: true)
        chain.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4))
        chain.record(SkyScoreAward(baseLight: 4, clearedStarCount: 4), depth: 2)
        XCTAssertEqual(chain.masteryGoals(for: skyIdentity, light: 8), [.cascade])
    }

    func testEachAggregateWinningRankIsOneWholeRecordWithoutCrossAttemptUnion() throws {
        let none = try XCTUnwrap(aggregateWin(grown: false, cascade: false, runID: firstID).completedMasteryRun)
        let onlyA = try XCTUnwrap(aggregateWin(grown: true, cascade: false, runID: firstID).completedMasteryRun)
        let onlyB = try XCTUnwrap(aggregateWin(grown: false, cascade: true, runID: secondID).completedMasteryRun)
        let both = try XCTUnwrap(aggregateWin(grown: true, cascade: true, runID: secondID).completedMasteryRun)
        XCTAssertEqual([none.rank,onlyA.rank,onlyB.rank,both.rank], [1,2,2,3])
        XCTAssertEqual(none.earned, [])
        XCTAssertEqual(onlyA.earned, [.grownCollection])
        XCTAssertEqual(onlyB.earned, [.cascade])
        XCTAssertEqual(both.earned, [.grownCollection,.cascade])
        XCTAssertNotEqual(onlyA.runID, onlyB.runID)
        XCTAssertEqual(onlyA.rank, onlyB.rank)
        XCTAssertEqual(onlyA.earned, [.grownCollection], "A different attempt cannot mutate this whole result")
        XCTAssertEqual(onlyB.earned, [.cascade])
        for record in [none,onlyA,onlyB,both] {
            XCTAssertTrue(record.isValid)
            XCTAssertEqual(try JSONDecoder().decode(StoryMasteryRecord.self, from: JSONEncoder().encode(record)), record)
        }
    }

    func testFullBoardAggregateProofsKeepCascadeAndEightStarClearIndependent() throws {
        for (cascade, large, rank, score) in [(false,false,1,150_000), (false,true,2,153_000),
                                             (true,false,2,150_000), (true,true,3,158_000)] {
            let game = try fullAggregateWin(cascade: cascade, large: large)
            let record = try XCTUnwrap(game.completedMasteryRun)
            XCTAssertEqual(record.identity, fullIdentity)
            XCTAssertEqual(record.earned.contains(.cascade), cascade)
            XCTAssertEqual(record.earned.contains(.largeClear), large)
            XCTAssertFalse(record.earned.contains(.grownCollection))
            XCTAssertEqual(record.rank, rank)
            XCTAssertEqual(game.displayScore, score)
            XCTAssertTrue(record.isValid)
            XCTAssertEqual(try JSONDecoder().decode(StoryMasteryRecord.self, from: JSONEncoder().encode(record)), record)
        }
    }

    func testRecordDecodingRejectsNonwinsAndForgedContractsAndIgnoresUntrustedRankFlags() throws {
        let game = try aggregateWin(grown: false, cascade: false, runID: firstID)
        let record = try XCTUnwrap(game.completedMasteryRun)
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(record)) as? [String: Any])
        fields["rank"] = 3
        fields["earned"] = ["grownCollection","cascade"]
        let decoded = try JSONDecoder().decode(StoryMasteryRecord.self, from: JSONSerialization.data(withJSONObject: fields))
        XCTAssertEqual(decoded.rank, 1)
        XCTAssertTrue(decoded.earned.isEmpty)
        for invalidGame in [game.replay(), try withoutEnrollment(game),
                            try changed(game, { $0["score"] = Int.max })] {
            XCTAssertNil(StoryMasteryRecord(game: invalidGame))
            let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(invalidGame))
            XCTAssertThrowsError(try JSONDecoder().decode(StoryMasteryRecord.self,
                from: JSONSerialization.data(withJSONObject: ["game":encoded])))
        }
    }

    func testEnrollmentCorruptionCannotReinterpretAnotherContentOrGoalRevision() throws {
        var opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(opening.enrollMastery(runID: firstID))
        for identity in [StoryMasteryIdentity(challenge: .firstLight, contentRevision: 6, goalSetRevision: 1),
                         StoryMasteryIdentity(challenge: .firstLight, contentRevision: 4, goalSetRevision: 2),
                         StoryMasteryIdentity(challenge: .ribbonCrossing, contentRevision: 4, goalSetRevision: 1)] {
            let invalid = try changed(opening) {
                $0["masteryEnrollment"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(
                    StoryMasteryEnrollment(identity: identity, runID: firstID)))
            }
            XCTAssertFalse(invalid.isValidSave)
            XCTAssertNil(invalid.masteryProgress)
            XCTAssertNil(invalid.completedMasteryRun)
        }
        XCTAssertThrowsError(try changed(opening) { $0["masteryEnrollment"] = ["runID":"not-a-uuid"] })
        let foreign = try changed(FallingSky.freshChallenge(.ribbonCrossing)) {
            $0["masteryEnrollment"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(
                StoryMasteryEnrollment(identity: skyIdentity, runID: firstID)))
        }
        XCTAssertFalse(foreign.isValidSave)
    }

    func testPlayingLostAndDisposablePracticeDoNotProduceCompletedRecords() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        XCTAssertTrue(game.enrollMastery(runID: firstID))
        _ = try apply([8,9], to: &game)
        XCTAssertNil(game.completedMasteryRun)
        for _ in 0..<30 where !game.isOver { _ = try apply([], to: &game) }
        XCTAssertEqual(game.outcome, .lost)
        XCTAssertNil(game.completedMasteryRun)
        XCTAssertEqual(game.replay(masteryRunID: secondID).masteryProgress?.earned, [])
        for chapter in SkyTutorial.allCases {
            let practice = chapter.game()
            XCTAssertNil(practice.masteryEnrollment)
            XCTAssertNil(practice.masteryProgress)
            XCTAssertNil(practice.completedMasteryRun)
        }
    }
}
