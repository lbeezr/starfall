import Foundation

@main struct ConstellationChecks {
    static func main() throws {
        let pink = Jewel.allCases[0], other = Jewel.allCases[1]
        let cells: Set<Cell> = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,5), Cell(1,6)]
        func fixture(_ positions: Set<Cell>, grown: Bool = false, dark: Set<Cell> = []) -> FallingSky {
            var board: [StarfallGem?] = Array(repeating: nil, count: 49)
            for column in 0..<7 {
                let height = positions.union(dark).filter { $0.column == column }.map(\.row).max() ?? -1
                if height < 0 { continue }
                for row in 0...height {
                    let cell = Cell(row,column)
                    board[row*7+column] = StarfallGem(id: row*7+column, kind: dark.contains(cell) ? nil : positions.contains(cell) ? pink : other, grown: positions.contains(cell) && grown)
                }
            }
            return FallingSky(board: board, incoming: [IncomingStar(id: 100, kind: other, column: 0)])
        }
        let initial = fixture(cells)
        for cell in cells {
            var game = initial
            let before = game
            let turn = game.clear(cell)
            #if CONSTELLATIONS
            precondition(turn?.collected == 5 && turn?.cleared == cells)
            precondition(game.incoming == before.incoming && game.turns == before.turns)
            let beforeJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(before)) as! NSDictionary
            let afterJSON = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game)) as! NSDictionary
            for key in ["random", "remainingColumns", "incoming", "turns"] {
                precondition((beforeJSON[key] as? NSObject)?.isEqual(afterJSON[key]) == true)
            }
            for column in 0..<7 {
                let expected = (0..<7).compactMap { row -> StarfallGem? in
                    cells.contains(Cell(row,column)) ? nil : before.gem(at: Cell(row,column))
                }
                let actual = (0..<7).compactMap { game.gem(at: Cell($0,column)) }
                precondition(expected == actual)
            }
            precondition(game.board.compactMap { $0 }.allSatisfy { !cells.contains(Cell($0.id/7,$0.id%7)) })
            let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            var replay = restored
            var continuation = game
            replay.letStarsFall(); continuation.letStarsFall()
            precondition(replay == continuation)
            #else
            precondition(turn == nil && game == before)
            #endif
        }
        let four: Set<Cell> = [Cell(0,0),Cell(1,1),Cell(2,2),Cell(3,3)]
        var fourGame = fixture(four, grown: true)
        let unchanged = fourGame
        precondition(fourGame.clear(Cell(0,0)) == nil && fourGame == unchanged)
        var ordinary = fixture([Cell(0,0),Cell(0,1)], grown: true)
        precondition(ordinary.clear(Cell(0,0))?.collected == 4)
        var terminal = FallingSky(seed: 17)
        for _ in 0..<100 where !terminal.isOver { terminal.letStarsFall() }
        precondition(terminal.isOver)
        let terminalBefore = terminal
        precondition(terminal.clear(Cell(0,0)) == nil && terminal == terminalBefore)
        #if CONSTELLATIONS
        let dark: Set<Cell> = [Cell(0,3),Cell(0,2)]
        var dusk = fixture(cells, dark: dark)
        let turn = dusk.clear(Cell(1,3))!
        precondition(turn.cleared.contains(Cell(0,3)) && !turn.cleared.contains(Cell(0,2)))
        precondition(dusk.gem(at: Cell(0,2))?.isDark == true)
        var grown = fixture(cells, grown: true)
        precondition(grown.clear(Cell(0,4))?.collected == 10)
        let overlap = cells.union([Cell(0,5),Cell(0,6)])
        let connected = fixture(overlap)
        for cell in overlap { precondition(connected.group(at: cell) == overlap) }
        var edge = fixture([Cell(0,0),Cell(1,0),Cell(0,6),Cell(1,6)])
        precondition(edge.clear(Cell(0,0)) == nil)
        precondition(initial.group(at: Cell(-1,4)).isEmpty)
        // Identical boards: traverse the unmodified ordinary-clear policy.
        var boards = 0, gainedAvailability = 0, gainedChoices = 0, lostChoices = 0
        var addedGroups = 0, mergedOrdinaryStates = 0
        for seed in UInt64(0)..<200 {
            var game = FallingSky(seed: seed)
            for _ in 0..<60 where !game.isOver {
                game.letStarsFall()
                precondition(game.isValidSave)
                guard !game.isOver else { continue }
                let baseline = game.orthogonalLegalGroups, candidate = game.legalGroups
                boards += 1
                if baseline.isEmpty && !candidate.isEmpty { gainedAvailability += 1 }
                if baseline.count < 2 && candidate.count >= 2 { gainedChoices += 1 }
                if baseline.count >= 2 && candidate.count < 2 { lostChoices += 1 }
                addedGroups += candidate.filter { !baseline.contains($0) }.count
                if candidate.contains(where: { c in baseline.filter { Set($0).isSubset(of: Set(c)) }.count > 1 }) { mergedOrdinaryStates += 1 }
                if let group = baseline.first { game.clearOrdinaryForComparison(group[0]); precondition(game.isValidSave)
                    let restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
                    precondition(restored == game && restored.isValidSave) }
            }
        }
        print("{\"fixture\":\"passed\",\"matchedBoards\":\(boards),\"newlyPlayable\":\(gainedAvailability),\"newChoiceStates\":\(gainedChoices),\"lostChoiceStates\":\(lostChoices),\"newOrExpandedGroups\":\(addedGroups),\"mergedOrdinaryStates\":\(mergedOrdinaryStates)}")
        #else
        print("{\"fixture\":\"ordinary rejection reproduced; four-grown rejection and ordinary clear passed\"}")
        #endif
    }
}
