import Foundation
@main enum GreedyReference {
    static func main() throws {
        let threshold = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1])! : 3
        precondition([3, 5].contains(threshold))
        var game = FallingSky(seed: 17)
        var rows: [[String: Any]] = []
        while !game.isOver && game.turns < 24 {
            _ = game.letStarsFall()
            let available = game.legalGroups.count
            var clears: [[String: Int]] = []
            while !game.isOver, let first = game.legalGroups.first {
                precondition(clears.count < 50)
                var chosen = first
                for group in game.legalGroups where game.value(of: Set(group)) > game.value(of: Set(chosen)) { chosen = group }
                if game.value(of: Set(chosen)) < threshold { break }
                let cell = chosen.first!
                let value = game.value(of: Set(chosen))
                _ = game.clear(cell)
                precondition(game.isValidSave)
                clears.append(["row": cell.row, "column": cell.column, "value": value])
            }
            precondition(game.isValidSave)
            rows.append(["shower": game.turns, "legalBeforeClearing": available, "score": game.score,
                         "occupied": game.occupiedCount, "over": game.isOver, "clears": clears])
        }
        let output: [String: Any] = ["seed": 17, "cap": 24, "threshold": threshold, "policy": "largest-ready-until-below-threshold; first canonical group wins ties",
                                     "turns": game.turns, "score": game.score, "over": game.isOver, "trace": rows]
        print(String(data: try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
    }
}
