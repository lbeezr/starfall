import XCTest
@testable import StarfallCore

final class GravityTests: XCTestCase {
    func testFloorCollisionCapturesSurvivorsAndRotationCreatesConnections() throws {
        var game = GravityFixture.opportunity.game()
        let before = game
        let turn = try XCTUnwrap(game.clear(Cell(0,3)))
        XCTAssertEqual(game.score, 3)
        XCTAssertEqual(game.occupiedCount, before.occupiedCount-3) // two rose cells plus net one magnetic cell
        let field = try XCTUnwrap(game.orbit)
        XCTAssertEqual(field.center, Cell(0,3))
        XCTAssertEqual(field.slots, [Cell(0,4),Cell(0,2)])
        XCTAssertEqual(field.windowsRemaining, 3)
        XCTAssertEqual(game.group(at: Cell(0,2)).count, 1)
        XCTAssertEqual(turn.gravityPhases.map(\.event), [.removal,.collision,.settling,.capture])
        let ids = Set(field.slots.compactMap { game.gem(at: $0)?.id })
        game.letStarsFall()
        XCTAssertEqual(game.orbit?.windowsRemaining, 2)
        XCTAssertEqual(Set(field.slots.compactMap { game.gem(at: $0)?.id }),ids)
        XCTAssertEqual(game.value(of: game.group(at: Cell(0,2))),3)
        XCTAssertEqual(game.value(of: game.group(at: Cell(0,4))),3)
        XCTAssertTrue(game.isValidSave)
    }
    func testWaitingCanDestroyExistingOpportunity() throws {
        var game = GravityFixture.takeNow.game()
        game.clear(Cell(0,3))
        XCTAssertEqual(game.value(of: game.group(at: Cell(0,2))),3)
        var spend = game
        spend.clear(Cell(0,2))
        XCTAssertNil(spend.orbit)
        XCTAssertEqual(spend.score,6)
        game.letStarsFall()
        XCTAssertEqual(game.group(at: Cell(0,2)).count,1)
        XCTAssertEqual(game.group(at: Cell(0,4)).count,1)
        XCTAssertTrue(game.isValidSave)
    }
    func testCaptiveClearClosesOnceReleasesOtherIDsAndPreservesForecast() throws {
        var game = GravityFixture.takeNow.game(); game.clear(Cell(0,3))
        let survivor = try XCTUnwrap(game.gem(at: Cell(0,4)))
        let incoming = game.incoming
        let turn = try XCTUnwrap(game.clear(Cell(0,2)))
        XCTAssertNil(game.orbit)
        XCTAssertEqual(game.gem(at: Cell(0,4)), survivor)
        XCTAssertEqual(game.incoming,incoming)
        XCTAssertEqual(turn.gravityPhases.filter { $0.event == .release }.count,1)
        XCTAssertTrue(game.isValidSave)
    }
    func testThreeWindowsEndWithoutInvisibleLastRotation() throws {
        var game = GravityFixture.opportunity.game(); game.clear(Cell(0,3))
        game.letStarsFall(); game.letStarsFall()
        XCTAssertEqual(game.orbit?.windowsRemaining,1)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertNil(game.orbit)
        XCTAssertFalse(turn.gravityPhases.contains { $0.event == .rotation })
        XCTAssertEqual(turn.gravityPhases.first?.event,.release)
        XCTAssertTrue(game.isValidSave)
    }
    func testPreviewIsPureAndInvalidInputsDoNotChangeState() throws {
        var game = GravityFixture.opportunity.game(); let before = game
        let preview = try XCTUnwrap(game.gravityPreview(at: Cell(0,3)))
        XCTAssertNotNil(preview.orbit); XCTAssertEqual(game,before)
        XCTAssertNil(game.clear(Cell(0,2))); XCTAssertEqual(game,before)
        game.clear(Cell(0,3)); let formed = game
        XCTAssertNil(game.clear(Cell(0,3))); XCTAssertEqual(game,formed)
    }
    func testSaveEnvelopeRoundTripsEveryWindowAndRejectsUnknownVersions() throws {
        var game = GravityFixture.opportunity.game()
        game.clear(Cell(0,3))
        for _ in 0..<4 {
            let data = try JSONEncoder().encode(GravitySave(game))
            var restored = try XCTUnwrap(GravitySave.restore(data))
            XCTAssertEqual(restored,game)
            restored.letStarsFall(); game.letStarsFall(); XCTAssertEqual(restored,game)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
            json["version"] = 999
            XCTAssertNil(GravitySave.restore(try JSONSerialization.data(withJSONObject:json)))
        }
    }
    func testMalformedTopologyAndAccountingRejected() throws {
        var game = GravityFixture.opportunity.game(); game.clear(Cell(0,3))
        let data = try JSONEncoder().encode(GravitySave(game))
        for key in ["holeID","windowsRemaining"] {
            var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
            var payload = try XCTUnwrap(envelope["game"] as? [String:Any])
            var field = try XCTUnwrap(payload["orbit"] as? [String:Any]); field[key] = 999
            payload["orbit"] = field; envelope["game"] = payload
            XCTAssertNil(GravitySave.restore(try JSONSerialization.data(withJSONObject:envelope)))
        }
        var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        var payload = try XCTUnwrap(envelope["game"] as? [String:Any]); payload["retiredMagnetic"] = 1
        envelope["game"] = payload
        XCTAssertNil(GravitySave.restore(try JSONSerialization.data(withJSONObject:envelope)))
    }
    func testSupportSegmentsHoldGapsUntilReleaseAndPreserveOrder() {
        var board = Array<StarfallGem?>(repeating:nil,count:49)
        let center = Cell(2,3), slots = [Cell(2,4),Cell(2,2)]
        board[17] = StarfallGem(id:42,kind:nil,gravity:.hole)
        for (i,cell) in slots.enumerated() { board[cell.row*7+cell.column] = StarfallGem(id:i,kind:.aqua) }
        board[5*7+2] = StarfallGem(id:10,kind:.rose)
        board[6*7+2] = StarfallGem(id:11,kind:.amber)
        let field = OrbitField(holeID:42,center:center,slots:slots,windowsRemaining:3)
        let held = GravityFieldRules.settle(board,field:field)
        XCTAssertNil(held[2]); XCTAssertEqual(held[2*7+2]?.id,1)
        XCTAssertEqual(held[3*7+2]?.id,10); XCTAssertEqual(held[4*7+2]?.id,11)
        var released = held; released[17] = nil
        released = GravityFieldRules.settle(released,field:nil)
        XCTAssertEqual(released[2]?.id,1); XCTAssertEqual(released[7+2]?.id,10)
    }
    func testCornerAndFloorTopologyNeverWraps() {
        XCTAssertEqual(GravityFieldRules.neighbors(Cell(0,0)),[Cell(1,0),Cell(0,1)])
        XCTAssertEqual(GravityFieldRules.neighbors(Cell(0,3)).count,3)
        XCTAssertEqual(GravityFieldRules.neighbors(Cell(3,3)).count,4)
    }
    func testElevatedFourCaptivesSupportGapAndArrivalLandsAboveAnchor() throws {
        var game=GravityFixture.supports.game()
        game.clear(Cell(1,3))
        XCTAssertEqual(game.orbit?.slots.count,4)
        XCTAssertEqual(game.orbit?.center,Cell(1,3))
        let anchorID=game.gem(at:Cell(1,2))?.id
        game.clear(Cell(0,1))
        XCTAssertNotNil(game.orbit)
        XCTAssertNil(game.gem(at:Cell(0,2)))
        XCTAssertEqual(game.gem(at:Cell(1,2))?.id,anchorID)
        XCTAssertTrue(game.isValidSave)
        let restored=try XCTUnwrap(GravitySave.restore(JSONEncoder().encode(GravitySave(game))))
        XCTAssertEqual(restored,game)
        let turn=try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.arrivals.first?.cell,Cell(2,2))
        XCTAssertNil(game.gem(at:Cell(0,2)))
        XCTAssertTrue(game.isValidSave)
        game.letStarsFall(); game.letStarsFall()
        XCTAssertNil(game.orbit); XCTAssertTrue(game.isValidSave)
    }
    func testSparseZeroAndOneCaptiveCloseImmediatelyAndThreeCycleInOrder() throws {
        for count in 0...1 {
            var game=GravityFixture.sparse(captives:count)
            let turn=try XCTUnwrap(game.clear(Cell(0,3)))
            XCTAssertNil(game.orbit)
            XCTAssertEqual(turn.gravityPhases.filter { $0.event == .release }.count,1)
            XCTAssertEqual(game.occupiedCount,count)
            XCTAssertTrue(game.isValidSave)
        }
        var game=GravityFixture.sparse(captives:3)
        game.clear(Cell(0,3))
        let field=try XCTUnwrap(game.orbit)
        XCTAssertEqual(field.slots.count,3)
        let ids=field.slots.map { game.gem(at:$0)?.id }
        game.letStarsFall()
        for index in field.slots.indices {
            XCTAssertEqual(game.gem(at:field.slots[(index+1)%3])?.id,ids[index])
        }
        XCTAssertTrue(game.isValidSave)
    }
    func testReplayClearsEveryGravityCounterAndField() throws {
        var game=GravityFixture.opportunity.game(); game.clear(Cell(0,3))
        let replay=game.replay()
        XCTAssertNil(replay.orbit); XCTAssertTrue(replay.isValidSave)
        XCTAssertEqual(replay.occupiedCount,0); XCTAssertEqual(replay.score,0)
    }
    func testDuskRemovalDoesNotChainIntoAnUntouchedMagnet() {
        var game=GravityFixture.duskBoundaryGame()
        XCTAssertNotNil(game.clear(Cell(0,1)))
        XCTAssertEqual(game.darkStarsCleared,1)
        XCTAssertEqual(game.gem(at:Cell(0,3))?.gravityKind,.magnet)
        XCTAssertTrue(game.isValidSave)
    }
    func testSpecialIdentityIsNeverDarkOrMatching() {
        for role in [GravityKind.magnet,.hole] {
            let special=StarfallGem(id:0,kind:nil,gravity:role)
            XCTAssertFalse(special.isDark); XCTAssertEqual(special.value,0)
        }
    }
    func testStrandedMagnetDissolvesWithoutCollision() {
        var game=GravityFixture.stranded.game()
        // A committed grown aqua and its small neighbor touch the lone magnet.
        XCTAssertNotNil(game.clear(Cell(0,1)))
        XCTAssertNil(game.orbit)
        XCTAssertNil(game.gem(at:Cell(0,3)))
        XCTAssertTrue(game.isValidSave)
    }
}
