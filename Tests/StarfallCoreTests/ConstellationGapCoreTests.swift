import XCTest
@testable import StarfallCore

final class ConstellationGapCoreTests: XCTestCase {
    func testGapClearPreservesCommittedStateAndReplay() throws {
        var game = ConstellationFixture.singleGap.game()
        let before = game, walk = [0,1,2,3,5].map { Cell(0,$0) }
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.constellationGroup(at:walk[0]),Set(walk))
        XCTAssertEqual(game.constellationCells(along:walk),Set(walk))
        XCTAssertEqual(game.clearConstellation(walk)?.collected,5)
        XCTAssertEqual(game.incoming,before.incoming); XCTAssertEqual(game.turns,before.turns)
        XCTAssertTrue(game.isValidSave)
        var restored = try JSONDecoder().decode(FallingSky.self,from:JSONEncoder().encode(game))
        game.letStarsFall(); restored.letStarsFall(); XCTAssertEqual(game,restored)
        var ordinary = before
        XCTAssertEqual(ordinary.clear(Cell(0,0))?.collected,4)
    }

    func testConnectionBoundariesInEveryDirection() {
        // Sparse boards deliberately exercise geometric validation independently
        // of the gravity invariant; valid saved-state coverage is above.
        let center = Cell(3,3)
        for dr in -1...1 { for dc in -1...1 where dr != 0 || dc != 0 {
            let end = Cell(3+dr*2,3+dc*2), middle = Cell(3+dr,3+dc)
            func board(_ blocker: StarfallGem? = nil) -> FallingSky {
                var cells: [StarfallGem?] = Array(repeating:nil,count:49)
                cells[center.row*7+center.column] = StarfallGem(id:1,kind:.rose)
                cells[end.row*7+end.column] = StarfallGem(id:2,kind:.rose)
                cells[middle.row*7+middle.column] = blocker
                return FallingSky(board:cells,incoming:(0..<3).map { IncomingStar(id:100+$0,kind:.aqua,column:$0) })
            }
            XCTAssertTrue(board().canLinkConstellation(center,to:end))
            XCTAssertTrue(board().canLinkConstellation(end,to:center))
            for kind: Jewel? in [.aqua,.rose,nil] {
                XCTAssertFalse(board(StarfallGem(id:3,kind:kind)).canLinkConstellation(center,to:end))
            }
        } }
        var cells: [StarfallGem?] = Array(repeating:nil,count:49)
        for (id,cell) in [center,Cell(3,6),Cell(5,4)].enumerated() { cells[cell.row*7+cell.column] = StarfallGem(id:id,kind:.rose) }
        let game = FallingSky(board:cells,incoming:(0..<3).map { IncomingStar(id:100+$0,kind:.aqua,column:$0) })
        XCTAssertFalse(game.canLinkConstellation(center,to:Cell(3,6)))
        XCTAssertFalse(game.canLinkConstellation(center,to:Cell(5,4)))
        XCTAssertFalse(game.canLinkConstellation(center,to:Cell(-1,3)))
    }
    func testRepeatedGapLinksKeepOpalFamilyAnchored() {
        var cells: [StarfallGem?] = Array(repeating:nil,count:49)
        let walk = [Cell(0,0),Cell(0,2),Cell(0,4),Cell(2,4),Cell(2,6)]
        for (id,cell) in walk.enumerated() { cells[cell.row*7+cell.column] = StarfallGem(id:id,kind:.rose) }
        cells[4] = StarfallGem(id:2,kind:nil,light:true)
        let incoming = [IncomingStar(id:100,kind:.aqua,column:0)]
        var game = FallingSky(board:cells,incoming:incoming)
        XCTAssertEqual(game.constellationCells(along:walk),Set(walk))
        cells[2*7+6] = StarfallGem(id:4,kind:.aqua)
        game = FallingSky(board:cells,incoming:incoming)
        XCTAssertFalse(game.isValidConstellationPrefix(walk), "Opal cannot change the selected family")
        cells[2*7+6] = StarfallGem(id:4,kind:.rose)
        cells[3] = StarfallGem(id:5,kind:nil,light:true)
        game = FallingSky(board:cells,incoming:incoming)
        XCTAssertFalse(game.isValidConstellationPrefix(walk), "An unselected Opal still blocks an empty-gap jump")
    }

}
