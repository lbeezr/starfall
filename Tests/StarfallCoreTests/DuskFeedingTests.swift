import XCTest
@testable import StarfallCore

final class DuskFeedingTests: XCTestCase {
    private func position(_ entries: [(Cell, SkyIdentity, Bool)], feeds: [Cell: Int] = [:],
                          incoming: [IncomingStar] = [.init(id: 50, kind: .rose, column: 6)]) throws -> FallingSky {
        var board = [StarfallGem?](repeating: nil, count: 49), id = 0
        for (cell, identity, grown) in entries {
            let kind: Jewel? = { if case .colored(let value) = identity { return value }; return nil }()
            let gravity: GravityKind? = identity == .magnet ? .magnet : identity == .hole ? .hole : nil
            board[cell.row*7+cell.column] = .init(id: id, kind: kind, grown: grown, light: identity == .white, gravity: gravity)
            id += gravity == .hole ? 2 : gravity == .magnet || identity == .dusk ? 1 : grown ? 2 : 1
        }
        let original = FallingSky(board: board, incoming: incoming, generation: .gravityOpportunities)
        var data = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        data["savedDuskRule"] = 1; data["unscoredStarlight"] = 0
        data["starsLanded"] = id; data["turns"] = max(1,(id+4)/5)
        var encoded = try XCTUnwrap(data["board"] as? [Any])
        for (cell, stage) in feeds {
            var gem = try XCTUnwrap(encoded[cell.row*7+cell.column] as? [String: Any])
            gem["savedDuskFeeds"] = stage; encoded[cell.row*7+cell.column] = gem
        }
        data["board"] = encoded
        let game = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: data))
        XCTAssertTrue(game.isValidSave)
        return game
    }

    func testBirthDoesNotFeedAndThreeSubsequentFeedingShowersCollapseBeforeArrival() throws {
        var game = DuskFixture.unfed.game()
        let dusk = Cell(0,3)
        XCTAssertEqual(game.gem(at: dusk)?.duskFeeds, 0)
        XCTAssertEqual(game.reward(of: game.group(at: Cell(0,2))), 1)
        XCTAssertEqual(game.value(of: game.group(at: Cell(0,2))), 3)
        XCTAssertTrue(game.letStarsFall()!.duskCollapses.isEmpty)
        XCTAssertEqual(game.gem(at: dusk)?.duskFeeds, 1)
        // Use the exact imminent fixture to keep the same committed preview for both branches.
        game = DuskFixture.imminent.game()
        let forecast = game.incoming
        let before = game
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertEqual(turn.forecast, forecast)
        XCTAssertEqual(turn.duskCollapses.count, 1)
        XCTAssertEqual(turn.duskCollapses[0].consumed, [Cell(0,2),Cell(1,3),Cell(0,4)])
        XCTAssertEqual(game.lostStarlight, 4); XCTAssertEqual(game.score, 0)
        XCTAssertEqual(game.darkStarsCleared, before.darkStarsCleared+1)
        XCTAssertEqual(turn.settled[2]?.kind, .amber, "Surviving small amber settles before the arrival")
        XCTAssertEqual(turn.arrivals.first?.cell, Cell(1,2))
        XCTAssertEqual(game.gem(at: Cell(0,3)), nil)
        XCTAssertTrue(game.isValidSave)
    }

    func testClearEarlyOrWaitHaveDifferentUsefulOutcomesAndTraceUsesSameReward() throws {
        let start = DuskFixture.imminent.game()
        var saveLight = start, makeSpace = start
        XCTAssertEqual(saveLight.clear(Cell(0,2))?.collected, 1)
        XCTAssertEqual(saveLight.reward(of: [Cell(0,4)]), 1)
        XCTAssertFalse(saveLight.isDrained(at: Cell(0,4)))
        let turn = try XCTUnwrap(makeSpace.letStarsFall())
        XCTAssertEqual(turn.collected, 0)
        XCTAssertGreaterThan(turn.duskCollapses.first!.consumed.count, 0)
        XCTAssertNotEqual(saveLight.board, makeSpace.board)
        XCTAssertTrue(saveLight.isValidSave && makeSpace.isValidSave)
        let cells = [Cell(0,0),Cell(1,0),Cell(2,1),Cell(1,1),Cell(0,1)]
        var trace = try position(cells.map { ($0,.colored(.aqua),false) } + [(Cell(0,2),.dusk,false)])
        let expected = trace.reward(of: Set(cells))
        XCTAssertLessThan(expected, 5)
        XCTAssertEqual(trace.clearConstellation(cells)?.collected, expected)
        XCTAssertTrue(trace.isValidSave)
    }

    func testStarvationPausesProgressWithoutResetAndGrowthIsAllowedWhileDrained() throws {
        var empty = DuskFixture.starved.game()
        XCTAssertEqual(empty.gem(at: Cell(0,3))?.duskFeeds, 0)
        _ = empty.letStarsFall()
        XCTAssertEqual(empty.gem(at: Cell(0,3))?.duskFeeds, 0, "The first neighbor arrives after feeding")
        _ = empty.letStarsFall()
        XCTAssertEqual(empty.gem(at: Cell(0,3))?.duskFeeds, 1)
        var grown = try position([(Cell(0,0),.dusk,false),(Cell(0,1),.colored(.mint),false)],
                                 incoming: [.init(id: 20, kind: .mint, column: 1)])
        XCTAssertFalse(grown.isGrowthBlocked(at: Cell(0,1)))
        XCTAssertTrue(grown.letStarsFall()!.arrivals[0].grew)
        XCTAssertEqual(grown.gem(at: Cell(0,1))?.value, 2)
        XCTAssertEqual(grown.reward(of: [Cell(0,1)]), 0)
        XCTAssertTrue(grown.isValidSave)
        var paused = try position([(Cell(0,0),.dusk,false)], feeds: [Cell(0,0): 2])
        _ = paused.letStarsFall()
        XCTAssertEqual(paused.gem(at: Cell(0,0))?.duskFeeds, 2)
    }

    func testZeroRewardIsLegalAndSimultaneousCollapseCountsSharedNeighborsOnlyOnce() throws {
        var zero = DuskFixture.zeroClear.game()
        XCTAssertEqual(zero.clear(Cell(0,1))?.collected, 0)
        XCTAssertEqual(zero.occupiedCount, 0); XCTAssertEqual(zero.lostStarlight, 3)
        XCTAssertTrue(zero.isValidSave)
        var shared = try position([(Cell(0,0),.dusk,false),(Cell(0,1),.white,false),(Cell(0,2),.dusk,false)],
                                  feeds: [Cell(0,0): 2,Cell(0,2): 2])
        let turn = try XCTUnwrap(shared.letStarsFall())
        XCTAssertEqual(turn.duskCollapses.count, 2)
        XCTAssertEqual(shared.lostStarlight, 1)
        XCTAssertEqual(shared.darkStarsCleared, 2); XCTAssertEqual(shared.score, 0)
        XCTAssertTrue(shared.isValidSave)
    }

    func testRemovingOneDuskKeepsSharedSurvivorDrainedUntilLastSourceLeaves() throws {
        var game = try position([(Cell(0,0),.colored(.aqua),false),(Cell(0,1),.colored(.aqua),false),
            (Cell(0,2),.colored(.aqua),false),(Cell(0,3),.dusk,false),
            (Cell(0,4),.colored(.mint),false),(Cell(1,4),.dusk,false),
            (Cell(0,5),.colored(.rose),true),(Cell(1,5),.colored(.rose),false)])
        XCTAssertTrue(game.isDrained(at:Cell(0,4)))
        XCTAssertEqual(game.clear(Cell(0,2))?.collected,2)
        XCTAssertTrue(game.isDrained(at:Cell(0,4)),"The second source still drains the survivor")
        XCTAssertEqual(game.reward(of:[Cell(0,4)]),0)
        XCTAssertNotNil(game.clear(Cell(0,5)))
        XCTAssertFalse(game.isDrained(at:Cell(0,4)))
        XCTAssertEqual(game.reward(of:[Cell(0,4)]),1)
        XCTAssertTrue(game.isValidSave)
    }

    func testCollapseCanRescueFullColumnButDoesNotConsumeSpecialStarsOrChain() throws {
        var entries: [(Cell,SkyIdentity,Bool)] = [(Cell(0,0),.dusk,false),(Cell(0,2),.dusk,false),(Cell(1,0),.magnet,false)]
        for row in 0..<7 { entries.append((Cell(row,1),.colored(row.isMultiple(of: 2) ? .aqua : .mint),false)) }
        var game = try position(entries, feeds: [Cell(0,0):2], incoming:[.init(id: 50,kind:.rose,column:1)])
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertNil(turn.blockedColumn); XCTAssertFalse(game.isOver)
        XCTAssertEqual(game.gem(at: Cell(0,0))?.gravityKind, .magnet)
        XCTAssertEqual(game.gem(at: Cell(0,2))?.isDark, true)
        XCTAssertEqual(game.gem(at: Cell(0,2))?.duskFeeds, 1)
        XCTAssertTrue(game.isValidSave)
    }

    func testSaveValidationReplayAndLegacyAdoptionPreserveCommittedState() throws {
        var game = DuskFixture.imminent.game()
        let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
        XCTAssertEqual(game, restored)
        var continued = restored
        _ = game.letStarsFall(); _ = continued.letStarsFall()
        XCTAssertEqual(game, continued); XCTAssertTrue(game.isValidSave)
        let replay = game.replay()
        XCTAssertEqual(replay.duskRule,.feeding); XCTAssertEqual(replay.lostStarlight,0)
        XCTAssertEqual(replay.occupiedCount,0); XCTAssertTrue(replay.isValidSave)
        let old = FallingSky(seed:17, generation:.current)
        let adopted = old.adoptingFeedingDusk()
        XCTAssertEqual(adopted.board,old.board); XCTAssertEqual(adopted.incoming,old.incoming)
        XCTAssertEqual(adopted.score,old.score); XCTAssertEqual(adopted.cadenceID,old.cadenceID)
        XCTAssertEqual(adopted.generation,old.generation); XCTAssertTrue(adopted.isValidSave)
        XCTAssertEqual(adopted.adoptingFeedingDusk(),adopted)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(restored)) as? [String:Any])
        for (key,value) in [("savedDuskRule",99),("unscoredStarlight",-1)] {
            var invalid=json; invalid[key]=value
            XCTAssertFalse(try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:invalid)).isValidSave)
        }
        var extreme = json
        let huge = (Int.max / 4) * 3
        extreme["starsLanded"] = huge; extreme["turns"] = Int.max / 6 - 1
        extreme["darkStarsCleared"] = huge; extreme["retiredMagnetic"] = huge
        extreme["unscoredStarlight"] = huge
        XCTAssertFalse(try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:extreme)).isValidSave,
                       "Overlapping counters must reject before arithmetic can overflow")
        extreme = json; extreme["retiredMagnetic"] = Int.min
        XCTAssertFalse(try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:extreme)).isValidSave)
        var board = try XCTUnwrap(json["board"] as? [Any])
        var dusk = try XCTUnwrap(board[3] as? [String:Any]); dusk["savedDuskFeeds"]=3;board[3]=dusk;json["board"]=board
        XCTAssertFalse(try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:json)).isValidSave)
    }

    func testConsumingACaptiveClosesOrbitAndReleasesRemainingStars() throws {
        var base = GravityFixture.opportunity.game().adoptingFeedingDusk()
        _ = base.clear(Cell(0,3))
        let field = try XCTUnwrap(base.orbit)
        XCTAssertTrue(field.slots.contains(Cell(0,2)))
        let replaced = try XCTUnwrap(base.gem(at: Cell(0,1)))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(base)) as? [String:Any])
        var board = try XCTUnwrap(json["board"] as? [Any])
        board[1] = ["id":replaced.id,"grown":false,"savedDuskFeeds":2]
        json["board"] = board
        json["starsLanded"] = base.starsLanded - replaced.value + 1
        var game = try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:json))
        XCTAssertTrue(game.isValidSave)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertTrue(turn.duskCollapses.first?.consumed.contains(Cell(0,2)) == true)
        XCTAssertNil(game.orbit)
        XCTAssertTrue(turn.gravityPhases.contains { $0.event == .release })
        XCTAssertFalse(game.board.contains { $0?.gravityKind == .hole })
        XCTAssertTrue(game.isValidSave)
    }

    func testSeededMixedSpecialReplayConservesEveryPointAcrossClearsAndFeeding() throws {
        for sample in 0..<160 {
            let seed = sample % 80
            let generation: SkyGeneration = sample < 80 ? .current : .gravityOpportunities
            var game = FallingSky(seed:UInt64(seed),generation:generation,duskRule:.feeding)
            for _ in 0..<40 where !game.isOver {
                _ = game.letStarsFall()
                if !game.isOver, let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
                XCTAssertTrue(game.isValidSave,"Seed \(seed), shower \(game.turns)")
                var restored = try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
                var reference = game
                _ = restored.letStarsFall(); _ = reference.letStarsFall()
                XCTAssertEqual(restored,reference)
            }
        }
    }
}
