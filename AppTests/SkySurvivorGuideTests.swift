import XCTest
@testable import StarfallCore
@testable import Starfall

final class SkySurvivorGuideTests: XCTestCase {
    private func exchange(_ from:Int,_ to:Int,in game:inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from:Cell(from/7,from%7),to:Cell(to/7,to%7)))
    }

    func testWholeCommittedChainKeepsOneLiveReactionAndExactOptionalSurvivors() throws {
        let old = FallingSky.fullBoardRibbon()
        var game = old
        let turn = try exchange(8,9,in:&game)
        XCTAssertEqual(turn.resolutionPhases.count,3)
        XCTAssertEqual(SkySurvivorCopy.count(in:turn.resolutionPhases),4)
        let result = SkyDialogueLibrary.result(for:turn,from:old,to:game,tracedCount:0,recipe:nil,
                                               relayDepth:0,techniqueResult:"")
        let original = SkyDialogueLibrary.line("guide.live-cascade",values:["depth":"3","score":"30,000"])
        XCTAssertEqual(result.text,"3-clear chain · +30,000 points")
        let recap = try XCTUnwrap(SkyLastClearSnapshot(turn:turn,from:old,to:game,path:[],recipe:nil,
                                                     roundGeneration:0,sequence:1))
        XCTAssertEqual(recap.score.guideText,"12 stars · 12 light. 12,000 base + 3,000 size + 15,000 chain = 30,000 points.")
        XCTAssertEqual(recap.survivorCount,4)
        XCTAssertEqual(SkySurvivorCopy.fact(recap.survivorCount),"4 survivors fell into later patterns.")
        XCTAssertEqual(SkyLastClearCopy.room(recap),"Refill added 12 stars. 49 stars on the board after this clear.")
        XCTAssertEqual(result.id,original.id);XCTAssertEqual(result.speaker,original.speaker)
        XCTAssertEqual(result.priority,original.priority);XCTAssertEqual(result.seconds,original.seconds)
        XCTAssertTrue(result.isValid)
    }

    func testSeparateActionHasNoStaleCausalGuideOrSpeculativeFutureClaim() throws {
        var game = FallingSky.fullBoardRibbon()
        _ = try exchange(8,9,in:&game)
        let encoder = JSONEncoder();encoder.outputFormatting = .sortedKeys
        let old = game, encoded = try encoder.encode(game)
        let turn = try exchange(11,12,in:&game)
        XCTAssertEqual(turn.displayAward,5_000)
        XCTAssertEqual(turn.resolutionPhases.count,1)
        XCTAssertEqual(SkySurvivorCopy.count(in:turn.resolutionPhases),0)
        let result = SkyDialogueLibrary.result(for:turn,from:old,to:game,tracedCount:0,recipe:nil,
                                               relayDepth:0,techniqueResult:"")
        XCTAssertFalse(result.text.contains("Diamond"));XCTAssertFalse(result.text.contains("survivor"))
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(try encoder.encode(old),encoded)
        XCTAssertNil(SkySurvivorCopy.fact(0));XCTAssertNil(SkySurvivorCopy.fact(-1))
    }

    @MainActor func testLastClearCapturesTerminalSurvivorCountSynchronouslyAndNewClearReplacesIt() throws {
        let old = FallingSky.freshChallenge(.silverPools)
        var game = old
        let turn = try exchange(9,10,in:&game)
        let session = SkyLightReceiptSession()
        session.capture(turn,from:old,to:game,path:[],recipe:nil)
        XCTAssertEqual(game.outcome,.won)
        XCTAssertEqual(session.lastSurvivorCount,1)
        XCTAssertEqual(SkySurvivorCopy.fact(1),"1 survivor fell into a later pattern.")
        session.cancel();XCTAssertEqual(session.lastSurvivorCount,1)
        XCTAssertNil(SkyLightReceiptSession().lastSurvivorCount,"Cold restore has no reconstructed provenance")
        var alternate = old
        let single = try exchange(2,9,in:&alternate)
        session.capture(single,from:old,to:alternate,path:[],recipe:nil)
        XCTAssertEqual(session.lastSurvivorCount,0)
        session.beginRound();XCTAssertNil(session.lastSurvivorCount)
    }

    func testImmediateSimultaneousRecipesAndNoClearHaveNoCausalFact() throws {
        var immediate = SkyTutorial.fullBoardImmediate.game()
        let turn = try XCTUnwrap(SkyTutorial.fullBoardImmediate.actions.first?.perform(in:&immediate))
        XCTAssertEqual(turn.resolutionPhases.count,1)
        XCTAssertEqual(turn.resolutionPhases[0].recipes.count,2)
        XCTAssertEqual(SkySurvivorCopy.count(in:turn.resolutionPhases),0)
        XCTAssertEqual(SkySurvivorCopy.count(in:[]),0)
    }
}
