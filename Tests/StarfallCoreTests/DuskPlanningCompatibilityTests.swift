import XCTest
@testable import StarfallCore

final class DuskPlanningCompatibilityTests: XCTestCase {
    func testPlanningFixturesUnderProductionDusk() {
        for preserve in [true,false] {
            var game=ConstellationFixture.opalPlanning.game().adoptingFeedingDusk()
            let a=Cell(1,1),b=Cell(0,3)
            let one=game.clear(preserve ? a:b)!.collected
            let weight=game.value(of:game.group(at:preserve ? b:a))
            let two=game.clear(preserve ? b:a)!.collected
            XCTAssertEqual([one,weight,two,game.score],preserve ? [2,4,4,33]:[2,3,3,32])
            XCTAssertTrue(game.isValidSave)
            game=ConstellationFixture.opalStormPlanning.game().adoptingFeedingDusk()
            let first=game.clear(preserve ? Cell(0,4):Cell(0,1))!.collected
            let group=game.group(at:Cell(0,4)),stormWeight=game.value(of:group),reward=game.reward(of:group)
            let second=game.clear(Cell(0,4))!.collected
            XCTAssertEqual([first,stormWeight,reward,second,game.score],preserve ? [3,5,2,2,35]:[3,3,3,3,36])
            XCTAssertTrue(game.isValidSave)
            game=GravityFixture.naturalOpportunity.game().adoptingFeedingDusk()
            let firstGravity=game.clear(preserve ? Cell(1,2):Cell(0,1))!.collected
            let secondGravity=game.clear(preserve ? Cell(0,1):Cell(1,2))!.collected
            XCTAssertEqual([firstGravity,secondGravity,game.score],[2,4,30])
            XCTAssertTrue(game.isValidSave)
        }
    }
}
