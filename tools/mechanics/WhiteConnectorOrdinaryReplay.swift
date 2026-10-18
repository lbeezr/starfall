import Foundation
@main enum OrdinaryReplay {
    static func main() throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        func emit(_ game: FallingSky) throws {
            precondition(game.isValidSave)
            FileHandle.standardOutput.write(try encoder.encode(game))
            FileHandle.standardOutput.write(Data([10]))
        }
        for seed in 0..<40 { for policy in 0..<2 {
            var game = FallingSky(seed: UInt64(seed))
            try emit(game)
            while !game.isOver && game.turns < 24 {
                game.letStarsFall(); try emit(game)
                var count = 0
                while !game.isOver, let first = game.legalGroups.first {
                    precondition(count < 50); count += 1
                    var chosen = first
                    if policy == 1 {
                        for group in game.legalGroups where game.value(of: Set(group)) > game.value(of: Set(chosen)) { chosen = group }
                    }
                    game.clear(chosen[0]); try emit(game)
                }
            }
        } }
    }
}
