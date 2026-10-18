import XCTest
@testable import StarfallCore

final class SkyGenerationTests: XCTestCase {
    private func clearAvailable(_ game: inout FallingSky) {
        for _ in 0..<49 {
            guard !game.isOver, let first = game.legalGroups.first?.first else { return }
            XCTAssertNotNil(game.clear(first))
        }
        XCTFail("Clear loop exceeded the board's bounded capacity")
    }
    func testCommittedPhaseBoundariesAndLegacyExclusion() {
        let expected: [(Int, SkyShowerPhase)] = [(1,.calm(remaining:9)),(9,.calm(remaining:1)),
            (10,.storm(remaining:3)),(11,.storm(remaining:2)),(12,.storm(remaining:1)),
            (13,.calm(remaining:9)),(21,.calm(remaining:1)),(22,.storm(remaining:3)),
            (24,.storm(remaining:1)),(25,.calm(remaining:9))]
        for (number, phase) in expected {
            XCTAssertEqual(SkyGeneration.current.phase(for:number),phase)
            XCTAssertNil(SkyGeneration.legacy.phase(for:number))
        }
        XCTAssertNil(SkyGeneration.current.phase(for:0))
        XCTAssertNil(SkyGeneration.current.phase(for:-1))
        XCTAssertNotNil(SkyGeneration.current.phase(for:Int.max))
    }

    func testNewGenerationSeededArrivalsReplayAndOpalCadence() throws {
        var seenOpals=0, seenStorms=0, seenClears=0
        for seed in UInt64(0)..<40 {
            var game=FallingSky(seed:seed,generation:.opalStorms)
            var replay=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
            for _ in 0..<48 where !game.isOver {
                let number=game.turns+1, forecast=game.incoming
                XCTAssertTrue(game.isValidSave); XCTAssertEqual(game,replay)
                let opals=forecast.filter(\.isLight)
                XCTAssertLessThanOrEqual(opals.count,1)
                if !number.isMultiple(of:6) { XCTAssertTrue(opals.isEmpty) }
                XCTAssertTrue(opals.allSatisfy { $0.kind == nil && !$0.isDark })
                if game.forecastPhase?.isStorm == true {
                    XCTAssertEqual(forecast.count,5); seenStorms += 1
                }
                seenOpals += opals.count
                game.letStarsFall(); replay.letStarsFall()
                XCTAssertEqual(game,replay); XCTAssertTrue(game.isValidSave)
                XCTAssertTrue(game.board.compactMap{$0}.filter(\.isLight).allSatisfy{!$0.grown && $0.value == 1})
                var count=0
                while !game.isOver, let first=game.legalGroups.first?.first, count < 49 {
                    let incoming=game.incoming, phase=game.forecastPhase, turns=game.turns
                    XCTAssertNotNil(game.clear(first)); XCTAssertNotNil(replay.clear(first))
                    XCTAssertEqual(game.incoming,incoming); XCTAssertEqual(game.forecastPhase,phase); XCTAssertEqual(game.turns,turns)
                    XCTAssertTrue(game.isValidSave); XCTAssertEqual(game,replay)
                    seenClears += 1; count += 1; XCTAssertLessThan(count,50)
                }
                if game.isOver, let first = game.legalGroups.first?.first {
                    let terminal = game
                    XCTAssertNil(game.clear(first)); XCTAssertEqual(game,terminal)
                }
                replay=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(replay))
            }
        }
        XCTAssertGreaterThan(seenOpals,40); XCTAssertGreaterThan(seenStorms,40); XCTAssertGreaterThan(seenClears,40)
    }

    func testOpeningAndFirstLightKeepTheirExistingRoles() throws {
        var legacy=FallingSky(seed:5), modern=FallingSky(seed:5,generation:.opalStorms)
        XCTAssertEqual(legacy.incoming,modern.incoming)
        for _ in 0..<4 { legacy.letStarsFall();modern.letStarsFall();XCTAssertEqual(legacy.board,modern.board) }
        XCTAssertFalse(modern.incoming.contains(where:\.isLight))
        var challenge=FallingSky(challenge:.firstLight)
        XCTAssertEqual(challenge.generation,.legacy)
        for _ in 0..<30 where !challenge.isOver {
            XCTAssertNil(challenge.forecastPhase); XCTAssertFalse(challenge.incoming.contains(where:\.isLight))
            challenge.letStarsFall()
            clearAvailable(&challenge)
            XCTAssertTrue(challenge.isValidSave)
        }
        XCTAssertEqual(challenge.outcome,.won)
    }

    func testUnknownGenerationAndCrossGenerationWhiteStatesReject() throws {
        var game=FallingSky(seed:5,generation:.opalStorms)
        for _ in 0..<6 {
            game.letStarsFall()
            clearAvailable(&game)
        }
        // Keep a committed forecast containing white, rather than editing a board.
        for _ in 0..<24 where !game.isOver {
            if game.incoming.contains(where:\.isLight) { break }
            game.letStarsFall(); clearAvailable(&game)
        }
        XCTAssertTrue(game.incoming.contains(where:\.isLight)); XCTAssertTrue(game.isValidSave)
        var fields=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(game)) as? [String:Any])
        func decoded(_ value:[String:Any]) throws -> FallingSky {
            try JSONDecoder().decode(FallingSky.self,from:JSONSerialization.data(withJSONObject:value))
        }
        fields["savedGeneration"]=99; XCTAssertFalse(try decoded(fields).isValidSave)
        fields["savedGeneration"] = -1; XCTAssertFalse(try decoded(fields).isValidSave)
        fields.removeValue(forKey:"savedGeneration"); XCTAssertFalse(try decoded(fields).isValidSave)
        let legacy=FallingSky(seed:5)
        let data=try JSONEncoder().encode(legacy)
        let oldFields=try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        XCTAssertNil(oldFields["savedGeneration"])
        XCTAssertEqual(try JSONDecoder().decode(FallingSky.self,from:data),legacy)
    }

    func testSharedOpalCreatesVisibleElevenVersusSevenAllocation() {
        var board:[StarfallGem?]=Array(repeating:nil,count:49)
        let placements:[(Cell,Jewel?,Bool)] = [(Cell(0,0),.aqua,false),(Cell(0,1),.mint,false),
            (Cell(1,1),.aqua,false),(Cell(0,2),.aqua,false),(Cell(0,3),.amber,false),(Cell(1,3),.aqua,false),
            (Cell(0,4),nil,false),(Cell(0,5),.rose,true),(Cell(1,5),.rose,false),
            (Cell(0,6),.rose,true),(Cell(1,6),.rose,false)]
        for (id,placement) in placements.enumerated(){let (cell,kind,grown)=placement
            board[cell.row*7+cell.column] = .init(id:id,kind:kind,grown:grown,light:cell == Cell(0,4))}
        let source=FallingSky(board:board,incoming:[.init(id:0,kind:.mint,column:6)],generation:.opalStorms)
        XCTAssertFalse(source.isValidSave,"Layout-only fixture has no invented shower history")
        let aqua=[Cell(0,0),Cell(1,1),Cell(0,2),Cell(1,3),Cell(0,4)]
        let rose=[Cell(0,5),Cell(1,5),Cell(1,6),Cell(0,6),Cell(0,5),Cell(0,4)]
        var small=source, large=source
        XCTAssertEqual(small.clearConstellation(aqua)?.collected,5)
        XCTAssertEqual(small.clear(Cell(0,5))?.collected,6); XCTAssertEqual(small.score,11)
        XCTAssertEqual(large.clearConstellation(rose)?.collected,7);XCTAssertTrue(large.legalGroups.isEmpty)
        XCTAssertTrue(large.constellationGroup(at:Cell(0,0)).isEmpty)
        XCTAssertEqual(source.incoming,small.incoming);XCTAssertEqual(source.incoming,large.incoming)
        var invalid=source;XCTAssertNil(invalid.clearConstellation(Array(aqua.reversed())));XCTAssertEqual(invalid,source)
    }
}

#if DEBUG
extension SkyGenerationTests {
    func testNativeOpalChoiceComesFromValidHistoryAndSupportsBothInputs() throws {
        let game = ConstellationFixture.opalChoice.game()
        XCTAssertTrue(game.isValidSave); XCTAssertEqual(game.turns, 18)
        let whites = Set(game.board.enumerated().compactMap { index, gem in gem?.isLight == true ? Cell(index / 7, index % 7) : nil })
        XCTAssertEqual(whites.count, 2)
        let shared = game.legalGroups.filter { !whites.isDisjoint(with: $0) }
        XCTAssertEqual(shared.map { game.value(of: Set($0)) }.sorted(), [3, 4, 5])
        var tapped = game
        XCTAssertEqual(tapped.clear(Cell(0, 6))?.collected, 5)
        XCTAssertFalse(tapped.board.contains { $0?.isLight == true }); XCTAssertTrue(tapped.isValidSave)
        let path = [Cell(3, 1), Cell(3, 2), Cell(2, 3), Cell(2, 4), Cell(2, 5)]
        var traced = game
        XCTAssertEqual(traced.clearConstellation(path)?.collected, 5)
        XCTAssertEqual(traced.board.compactMap { $0 }.filter(\.isLight).count, 1)
        XCTAssertTrue(traced.isValidSave)
        XCTAssertEqual(try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(traced)), traced)
        var straight = ConstellationFixture.opalTrace.game()
        XCTAssertEqual(straight.score, 12)
        XCTAssertEqual(straight.clearConstellation((0..<5).map { Cell($0, 2) })?.collected, 8)
        XCTAssertEqual(straight.score, 20); XCTAssertTrue(straight.isValidSave)
        XCTAssertEqual(straight.board.compactMap { $0 }.filter(\.isLight).count, 1)
    }
}
#endif
