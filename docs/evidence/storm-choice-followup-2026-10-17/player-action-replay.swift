import Foundation
@main enum ActionReplay {
    static func main() throws {
        let commands = try JSONDecoder().decode([String].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        var game = FallingSky(seed: 17)
        var trace: [[String: Any]] = []
        var beforeEight: Any = NSNull()
        for (index, command) in commands.enumerated() {
            let previous = game.score
            var value = 0
            if command == "reset" { precondition(index == 0); game = FallingSky(seed: 17) }
            else if command == "experiment.next" {
                precondition(!game.isOver)
                _ = game.letStarsFall()
                if game.turns == 8 {
                    beforeEight = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
                }
            } else {
                let parts = command.split(separator: ".")
                precondition(parts.count == 4 && parts[0] == "experiment" && parts[1] == "cell")
                let cell = Cell(Int(parts[2])!, Int(parts[3])!)
                value = game.value(of: game.group(at: cell))
                _ = game.clear(cell)
            }
            precondition(game.isValidSave)
            trace.append(["command": command, "shower": game.turns, "score": game.score,
                          "delta": game.score-previous, "connectedValue": value,
                          "occupied": game.occupiedCount, "darkRemoved": game.darkStarsCleared])
        }
        let result: [String: Any] = ["seed": 17, "turns": game.turns, "score": game.score,
                                    "over": game.isOver, "beforeDecisionAtEight": beforeEight, "trace": trace]
        print(String(data: try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]), encoding: .utf8)!)
    }
}
