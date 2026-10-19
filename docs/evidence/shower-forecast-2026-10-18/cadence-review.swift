import Foundation

func sample(seed: UInt64, clearsPerShower: Int) -> [String: Any] {
    var game = FallingSky.freshSurvival(seed: seed)
    var seconds = 0.0, moves = 0
    while !game.isOver && game.turns < 120 {
        seconds += game.automaticShowerDelay
        precondition(game.letStarsFall() != nil)
        for _ in 0..<clearsPerShower where !game.isOver {
            let candidates = game.legalGroups.map { group -> (Int,Cell) in
                // Core orders a colored start before shared Opal connectors.
                let cell = group[0]
                return (game.reward(of:Set(group)),cell)
            }.sorted { a,b in a.0 != b.0 ? a.0 > b.0 : a.1.row*7+a.1.column < b.1.row*7+b.1.column }
            guard let cell = candidates.first?.1 else { break }
            precondition(game.clear(cell) != nil); moves += 1
        }
        precondition(game.isValidSave)
    }
    return ["seed":seed,"showers":game.turns,"scheduledSeconds":seconds,"moves":moves,"score":game.score,"lost":game.isOver,"occupied":game.occupiedCount]
}
@main struct CadenceReview {
    static func main() throws {
        let policies = [("idle",0),("oneGreedyTapPerShower",1),("exhaustGreedyTapGroups",49)]
        let output = policies.map { name,limit in ["policy":name,"runs":(UInt64(0)..<64).map { sample(seed:$0,clearsPerShower:limit) }] as [String:Any] }
        print(String(data:try JSONSerialization.data(withJSONObject:output,options:[.prettyPrinted,.sortedKeys]),encoding:.utf8)!)
    }
}
