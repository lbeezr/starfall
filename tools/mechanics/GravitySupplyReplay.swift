import Foundation
@main enum GravitySupplyReplay {
    static func main() throws {
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
        func emit(_ game:FallingSky) throws {
            precondition(game.isValidSave)
            FileHandle.standardOutput.write(try encoder.encode(game));FileHandle.standardOutput.write(Data([10]))
        }
        for raw in 0...2 {for seed in UInt64(0)..<40 {for largest in [false,true] {
            var game=FallingSky(seed:seed,generation:SkyGeneration(rawValue:raw)!)
            try emit(game)
            while !game.isOver && game.turns<36 {
                game.letStarsFall();try emit(game)
                for _ in 0..<49 where !game.isOver {
                    guard let first=game.legalGroups.first else {break}
                    let selected=largest ? game.legalGroups.max{game.value(of:Set($0))<game.value(of:Set($1))}! : first
                    precondition(game.clear(selected[0]) != nil);try emit(game)
                }
            }
        }}}
    }
}
