extension WhiteConnectorTests {
    func testScriptedNativeExamplesAreValidRestorableAndHaveCompetingBranches() throws {
        for fixture in WhiteConnectorFixture.allCases {
            let game = fixture.game()
            XCTAssertTrue(game.isValidSave)
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            XCTAssertEqual(game, restored)
            XCTAssertEqual(game.legalGroups.count, 2)
        }
        var spend = WhiteConnectorFixture.connection.game(), hold = spend
        XCTAssertEqual(spend.clear(Cell(0,1))?.collected, 3)
        spend.letStarsFall(); hold.letStarsFall()
        XCTAssertEqual(hold.clear(Cell(1,0))?.collected, 4)
        XCTAssertTrue(spend.isValidSave && hold.isValidSave)
        var small = WhiteConnectorFixture.pressure.game(), large = small
        XCTAssertEqual(small.clear(Cell(0,0))?.collected, 3)
        XCTAssertEqual(large.clear(Cell(0,2))?.collected, 4)
        small.letStarsFall(); large.letStarsFall()
        XCTAssertFalse(small.isOver); XCTAssertTrue(large.isOver)
        XCTAssertTrue(small.isValidSave && large.isValidSave)
        // Smaller-first preserves the independently legal rose pair as well.
        var ordered = WhiteConnectorFixture.pressure.game()
        XCTAssertEqual(ordered.clear(Cell(0,0))?.collected, 3)
        XCTAssertEqual(ordered.clear(Cell(0,2))?.collected, 3)
        XCTAssertEqual(ordered.score, 6)
        ordered.letStarsFall()
        XCTAssertFalse(ordered.isOver); XCTAssertTrue(ordered.isValidSave)
    }
}
