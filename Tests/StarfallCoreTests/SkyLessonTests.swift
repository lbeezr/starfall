import XCTest
@testable import StarfallCore

final class SkyLessonTests: XCTestCase {
    func testEveryAuthoredMoveUsesRealRulesAndKeepsOtherStars() throws {
        for lesson in SkyLesson.allCases {
            var game = lesson.game()
            let original = game
            var gains: [Int] = []
            for move in lesson.moves {
                let before = game
                let turn = try XCTUnwrap(move.perform(in: &game), lesson.rawValue)
                gains.append(turn.collected)
                XCTAssertEqual(game.incoming, original.incoming)
                XCTAssertEqual(game.turns, 0)
                let removed = Set(turn.cleared.compactMap { before.gem(at: $0)?.id })
                XCTAssertEqual(Set(before.board.compactMap { $0?.id }).subtracting(removed), Set(game.board.compactMap { $0?.id }))
            }
            XCTAssertEqual(gains, lesson == .square ? [0,4] : lesson == .cross ? [5] : lesson == .opal ? [3] : [4,4])
            XCTAssertEqual(lesson.game(), original, "Reopening starts a new local example")
        }
    }
    func testSquareAndRelayDemonstrateCreatedRecipes() throws {
        for lesson in [SkyLesson.square, .relay] {
            var game = lesson.game()
            let originalRecipes = Set(game.recipes.map(\.id))
            try XCTUnwrap(lesson.moves[0].perform(in: &game))
            let created = try XCTUnwrap(game.recipes.first { !originalRecipes.contains($0.id) })
            let before = game
            let turn = try XCTUnwrap(lesson.moves[1].perform(in: &game))
            XCTAssertEqual(Set(turn.cleared.compactMap { before.gem(at:$0)?.id }), created.starIDs)
            XCTAssertEqual(created.shape, .square)
        }
    }
    func testOpalJoinsOnlyTheStartedFamily() throws {
        var game = SkyLesson.opal.game()
        let before = game
        XCTAssertNil(game.clear(Cell(0,1)), "Starting on Opal does not choose a color")
        XCTAssertEqual(game,before)
        let turn = try XCTUnwrap(SkyLesson.opal.moves[0].perform(in:&game))
        XCTAssertTrue(turn.cleared.contains(Cell(0,1)))
        XCTAssertEqual(game.gem(at:Cell(0,3))?.kind,.mint)
    }
}
