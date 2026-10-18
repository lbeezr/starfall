import XCTest
@testable import StarfallCore

final class GravityOpportunityTests: XCTestCase {
    func testSupplyWindowsAreVersionedAndRemainCalm() {
        for shower in -1...48 {
            XCTAssertEqual(SkyGeneration.gravityOrbits.offersMagneticPair(at:shower),shower>0 && shower%12==8)
            XCTAssertEqual(SkyGeneration.gravityOpportunities.offersMagneticPair(at:shower),shower>0 && [7,8].contains(shower%12))
            for generation in [SkyGeneration.legacy,.opalStorms] {XCTAssertFalse(generation.offersMagneticPair(at:shower))}
            if SkyGeneration.gravityOpportunities.offersMagneticPair(at:shower) {
                XCTAssertFalse(SkyGeneration.gravityOpportunities.phase(for:shower)!.isStorm)
            }
        }
    }

    func testOpeningAndFirstSixPreviewsAreUnchanged() {
        for seed in UInt64(0)..<40 {
            var old=FallingSky(seed:seed,generation:.gravityOrbits)
            var candidate=FallingSky(seed:seed,generation:.gravityOpportunities)
            for _ in 0..<6 {
                XCTAssertEqual(candidate.incoming,old.incoming)
                old.letStarsFall();candidate.letStarsFall()
                XCTAssertEqual(candidate.board,old.board)
                XCTAssertEqual(candidate.automaticShowerDelay,old.automaticShowerDelay)
            }
        }
        var challenge=FallingSky(challenge:.firstLight)
        for _ in 0..<30 where !challenge.isOver {
            XCTAssertEqual(challenge.generation,.legacy)
            XCTAssertFalse(challenge.incoming.contains{$0.gravityKind != nil})
            challenge.letStarsFall()
            while !challenge.isOver,let first=challenge.legalGroups.first?.first {challenge.clear(first)}
        }
        XCTAssertEqual(challenge.outcome,.won)
    }

    func testNaturalSupplyRemainsOneCommittedOfferPerCycleAndRestorable() throws {
        var pairOffers=0, fields=0
        for seed in UInt64(0)..<80 {
            var game=FallingSky(seed:seed,generation:.gravityOpportunities)
            var offeredCycles:Set<Int>=[]
            while !game.isOver && game.turns<36 {
                let magnets=game.incoming.filter{$0.gravityKind == .magnet}
                if !magnets.isEmpty {
                    XCTAssertEqual(magnets.count,2);pairOffers += 1
                    XCTAssertTrue([7,8].contains((game.turns+1)%12))
                    XCTAssertTrue(offeredCycles.insert(game.turns/12).inserted)
                    XCTAssertNil(game.orbit)
                    XCTAssertFalse(game.board.contains{$0?.gravityKind != nil})
                    XCTAssertFalse(game.incoming.contains{$0.isDark || $0.isLight})
                }
                var restored=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
                game.letStarsFall();restored.letStarsFall()
                XCTAssertEqual(game,restored);XCTAssertTrue(game.isValidSave)
                for _ in 0..<49 where !game.isOver {
                    guard let cell=game.legalGroups.compactMap(\.first).max(by:{
                        (game.gravityPreview(at:$0)?.orbit == nil ? 0 : 1)<(game.gravityPreview(at:$1)?.orbit == nil ? 0 : 1)
                    }) else {break}
                    let incoming=game.incoming, turns=game.turns
                    let wasField=game.orbit != nil
                    XCTAssertNotNil(game.clear(cell));XCTAssertNotNil(restored.clear(cell))
                    XCTAssertEqual(game,restored);XCTAssertTrue(game.isValidSave)
                    XCTAssertEqual(game.incoming,incoming);XCTAssertEqual(game.turns,turns)
                    if !wasField && game.orbit != nil {fields += 1}
                }
            }
        }
        XCTAssertGreaterThan(pairOffers,0);XCTAssertGreaterThan(fields,0)
    }

    func testSameSkyReplayPreservesEverySupportedGeneration() throws {
        for generation in [SkyGeneration.legacy,.opalStorms,.gravityOrbits,.gravityOpportunities] {
            var game=FallingSky(seed:349,generation:generation)
            for _ in 0..<5 {game.letStarsFall()}
            let restored=try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
            XCTAssertEqual(restored.replay(),FallingSky(seed:349,generation:generation))
        }
    }
}

extension GravityOpportunityTests {
    func testReachableExtraWindowChoiceHasDifferentImmediateConsequences() throws {
        let original=GravityOpportunityFixture.game()
        XCTAssertEqual(original.turns,10);XCTAssertEqual(original.score,24)
        XCTAssertEqual(original.generation,.gravityOpportunities)
        var higher=original,lower=original
        XCTAssertEqual(higher.clear(Cell(1,2))?.collected,4)
        XCTAssertEqual(lower.clear(Cell(0,1))?.collected,3)
        let highSecond=higher.legalGroups.map{higher.value(of:Set($0))}.max() ?? 0
        let lowSecond=lower.legalGroups.map{lower.value(of:Set($0))}.max() ?? 0
        XCTAssertEqual(highSecond,4);XCTAssertEqual(lowSecond,4)
        for game in [higher,lower] {
            XCTAssertEqual(game.incoming,original.incoming)
            XCTAssertEqual(game.turns,original.turns);XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game)),game)
        }
    }
}
