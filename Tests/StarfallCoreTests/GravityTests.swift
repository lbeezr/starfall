import XCTest
@testable import StarfallCore

final class GravityTests: XCTestCase {
    private func restore(_ data: Data) -> FallingSky? {
        guard let game = try? JSONDecoder().decode(FallingSky.self, from:data), game.isValidSave else { return nil }
        return game
    }
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
            let data = try JSONEncoder().encode(game)
            var restored = try XCTUnwrap(restore(data))
            XCTAssertEqual(restored,game)
            restored.letStarsFall(); game.letStarsFall(); XCTAssertEqual(restored,game)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
            json["savedGeneration"] = 999
            XCTAssertNil(restore(try JSONSerialization.data(withJSONObject:json)))
        }
    }
    func testMalformedTopologyAndAccountingRejected() throws {
        var game = GravityFixture.opportunity.game(); game.clear(Cell(0,3))
        let data = try JSONEncoder().encode(game)
        for key in ["holeID","windowsRemaining"] {
            var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
            var payload = envelope
            var field = try XCTUnwrap(payload["orbit"] as? [String:Any]); field[key] = 999
            payload["orbit"] = field; envelope = payload
            XCTAssertNil(restore(try JSONSerialization.data(withJSONObject:envelope)))
        }
        var envelope = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        var payload = envelope; payload["retiredMagnetic"] = 1
        envelope = payload
        XCTAssertNil(restore(try JSONSerialization.data(withJSONObject:envelope)))
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
        let restored=try XCTUnwrap(restore(JSONEncoder().encode(game)))
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

extension GravityTests {
    func testNaturalPairsAreBoundedForecastedAndDeterministic() throws {
        var pairs = 0, collisions = 0, rounds = 0
        for seed in UInt64(0)..<80 {
            var game = FallingSky(seed:seed, generation:.current)
            var replay = game
            for _ in 0..<36 where !game.isOver {
                XCTAssertEqual(game,replay)
                let magnets = game.incoming.filter { $0.gravityKind == .magnet }
                if !magnets.isEmpty {
                    pairs += 1
                    XCTAssertEqual(magnets.count,2)
                    XCTAssertEqual((game.turns+1)%12,8)
                    XCTAssertEqual(abs(magnets[0].column-magnets[1].column),2)
                    XCTAssertNil(game.orbit)
                    XCTAssertFalse(game.board.contains { $0?.gravityKind != nil })
                }
                game.letStarsFall(); replay.letStarsFall(); rounds += 1
                XCTAssertTrue(game.isValidSave, "seed \(seed) wave \(game.turns)")
                for _ in 0..<49 where !game.isOver {
                    // Prefer a legal collision when available, then ordinary clears.
                    guard let cell = game.legalGroups.compactMap(\.first).max(by: {
                        (game.gravityPreview(at:$0)?.orbit == nil ? 0 : 1) < (game.gravityPreview(at:$1)?.orbit == nil ? 0 : 1)
                    }) else { break }
                    let forecast = game.incoming
                    game.clear(cell); replay.clear(cell)
                    if game.orbit != nil { collisions += 1 }
                    XCTAssertEqual(game.incoming,forecast)
                    XCTAssertEqual(game,replay); XCTAssertTrue(game.isValidSave)
                }
                replay = try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(replay))
            }
        }
        print("Gravity supply sample: \(pairs) pairs; \(collisions) clears ending with a field; \(rounds) showers across 80 seeds")
        XCTAssertGreaterThan(pairs,0); XCTAssertGreaterThan(collisions,0)
    }
    func testOldGenerationRejectsGravityAndFirstLightNeverSuppliesIt() throws {
        let game = GravityFixture.opportunity.game()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(game)) as? [String:Any])
        for generation in [0,1,99] {
            json["savedGeneration"] = generation
            let decoded = try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:json))
            XCTAssertFalse(decoded.isValidSave)
        }
        var challenge = FallingSky(challenge:.firstLight)
        for _ in 0..<30 where !challenge.isOver {
            XCTAssertFalse(challenge.incoming.contains { $0.gravityKind != nil })
            challenge.letStarsFall()
            for group in challenge.legalGroups { if let first = group.first { challenge.clear(first) } }
        }
        XCTAssertEqual(challenge.outcome,.won)
    }
}


extension GravityTests {
    func testOpalStaysUncapturedAndRemainsAMatchingConnector() throws {
        var game = GravityFixture.opalBoundaryGame()
        let opal = try XCTUnwrap(game.gem(at:Cell(1,2)))
        XCTAssertTrue(opal.isLight)
        XCTAssertEqual(game.clearConstellation((0..<5).map { Cell($0,3) })?.collected,10)
        let field = try XCTUnwrap(game.orbit)
        XCTAssertEqual(field.slots,[Cell(1,3),Cell(0,4)])
        XCTAssertFalse(field.slots.contains(Cell(0,2)))
        XCTAssertEqual(game.gem(at:Cell(0,2))?.id,opal.id)
        XCTAssertTrue(game.isValidConstellationPrefix([Cell(1,3),Cell(0,2)]))
        XCTAssertTrue(game.isValidSave)
        for _ in 0..<3 { game.letStarsFall(); XCTAssertTrue(game.isValidSave) }
        XCTAssertNil(game.orbit)
        XCTAssertTrue(game.board.contains { $0?.id == opal.id })
    }
}
