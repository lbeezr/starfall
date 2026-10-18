import Foundation
#if canImport(StarfallCore)
import StarfallCore
#endif

/// Bounded offline policy walk. Core owns geometry and anchored family legality.
/// The selected set is explicit; an unreachable member must never be silently omitted.
func calibrationTrace(_ selected: Set<Cell>, in game: FallingSky) -> [Cell]? {
    let ordered = selected.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
    guard let first = ordered.first(where: { game.gem(at: $0)?.kind != nil }) else { return nil }
    var seen: Set<Cell> = [first], path = [first]
    func visit(_ cell: Cell) {
        for next in ordered where !seen.contains(next) && game.canLinkConstellation(cell, to: next) {
            seen.insert(next); path.append(next); visit(next); path.append(cell)
        }
    }
    visit(first)
    guard seen == selected, game.isValidConstellationPrefix(path) else { return nil }
    precondition(path.count <= 97)
    return path
}

func checkCalibrationTraces() {
    for fixture: ConstellationFixture in [.singleGap, .diagonalSix, .opalTrace] {
        let game = fixture.game()
        for row in 0..<7 { for column in 0..<7 {
            let selected = game.constellationGroup(at: Cell(row, column))
            guard !selected.isEmpty else { continue }
            let path = calibrationTrace(selected, in: game)!
            precondition(Set(path) == selected && game.constellationCells(along: path) == selected)
            var copy = game
            precondition(copy.clearConstellation(path)?.collected == game.reward(of: selected))
        } }
    }
    let original = ConstellationFixture.singleGap.game()
    let selected = original.constellationGroup(at: Cell(0, 0))
    precondition(selected == Set([0,1,2,3,5].map { Cell(0, $0) }))
    // Any occupied midpoint blocks this selected set, including same-family and Opal.
    let blockers = [StarfallGem(id: 99, kind: .rose), StarfallGem(id: 99, kind: .aqua),
                    StarfallGem(id: 99, kind: nil), StarfallGem(id: 99, kind: nil, light: true)]
    for blocker in blockers {
        // Geometry-only variant; no state is admitted to app saves or a policy run.
        var object = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as! [String: Any]
        var board = object["board"] as! [Any]
        board[4] = try! JSONSerialization.jsonObject(with: JSONEncoder().encode(blocker))
        object["board"] = board
        let blocked = try! JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        precondition(calibrationTrace(selected, in: blocked) == nil)
    }
}
