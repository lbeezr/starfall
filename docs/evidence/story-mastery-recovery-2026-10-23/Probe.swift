import Foundation
import CryptoKit

// Disposable fixture-specific authoring probe. No Core, save or supply mutation.
@main struct Probe {
    static let directory = URL(fileURLWithPath: "/private/tmp/starfall-mastery-recovery-20261023")
    static let width = 8, maximumShowers = 40, maximumSwaps = 6, maximumSuccessors = 100_000
    static let maximumSeconds = 180.0, fallCode = 2_401
    static let encoder: JSONEncoder = { let value = JSONEncoder(); value.outputFormatting = [.sortedKeys]; return value }()
    struct Node { var game: FallingSky; var a: Bool; var b: Bool; var swaps: Int; var path: [Int]; var rank: Int }
    struct Counts: Codable {
        var raw = 0, swaps = 0, showers = 0, rejected = 0, duplicates = 0, accepted = 0
        var rawWon = 0, rawLost = 0, rawPlaying = 0, uniqueWon = 0, uniqueLost = 0, uniquePlaying = 0
        var nonScoringSwaps = 0, scoredSwaps = 0
    }
    static func cell(_ index: Int) -> Cell { Cell(index / 7,index % 7) }
    static func grownIDs(_ phase: SkyResolutionPhase) -> [Int] {
        phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column] }
            .filter { $0.kind != nil && $0.grown && !$0.isLight && $0.gravityKind == nil }.map(\.id).sorted()
    }
    static func chain(_ phases: [SkyResolutionPhase]) -> Bool {
        for (earlier,later) in zip(phases, phases.dropFirst()) {
            guard earlier.kind == .recipe, later.kind == .recipe, !earlier.cleared.isEmpty,
                  !later.cleared.isEmpty, later.comboDepth == earlier.comboDepth + 1,
                  later.before == earlier.settled else { continue }
            let spent = Set(earlier.cleared.compactMap { earlier.before[$0.row * 7 + $0.column]?.id })
            let ids = Set(later.cleared.compactMap { later.before[$0.row * 7 + $0.column]?.id })
            let survivors = Set(earlier.settled.compactMap { $0?.id })
            guard spent.isDisjoint(with: ids), ids.isSubset(of: survivors),
                  ids.contains(where: { id in earlier.before.firstIndex(where: {$0?.id == id}) != later.before.firstIndex(where: {$0?.id == id}) }),
                  later.recipes.allSatisfy({ recipe in !earlier.recipes.contains(where: {$0.starIDs == recipe.starIDs}) }) else { continue }
            return true
        }
        return false
    }
    static func rank(_ game: FallingSky, a: Bool, b: Bool) -> Int {
        let heights = (0..<7).map { SkyBoardSettling.height(game.board,column: $0) }
        let occupied = game.board.compactMap {$0}.count
        var potential = 0
        func add(_ cells: [Int]) {
            var counts = Array(repeating: 0,count: 5)
            for index in cells { if let kind = game.board[index]?.kind, let family = Jewel.allCases.firstIndex(of: kind) { counts[family] += 1 } }
            for count in counts { if count == 3 { potential += 10 } else if count == 2 { potential += 2 } }
        }
        for row in 0..<6 { for col in 0..<6 { let i = row * 7 + col; add([i,i+1,i+7,i+8]) } }
        for row in 0..<7 { for col in 0..<4 { let i = row * 7 + col; add([i,i+1,i+2,i+3]) } }
        for col in 0..<7 { for row in 0..<4 { let i = row * 7 + col; add([i,i+7,i+14,i+21]) } }
        let danger = heights.reduce(0) { let excess = max(0,$1-4); return $0 + excess * excess }
        return game.displayScore + (a ? 2_000 : 0) + (b ? 8_000 : 0) - 300 * occupied - 1_200 * danger + 180 * potential
    }
    static func ordered(_ lhs: Node,_ rhs: Node) -> Bool {
        if lhs.rank != rhs.rank { return lhs.rank > rhs.rank }
        if lhs.game.displayScore != rhs.game.displayScore { return lhs.game.displayScore > rhs.game.displayScore }
        if lhs.path.count != rhs.path.count { return lhs.path.count < rhs.path.count }
        return lhs.path.lexicographicallyPrecedes(rhs.path)
    }
    static func key(_ node: Node) throws -> Data {
        var hasher = SHA256(); hasher.update(data: try encoder.encode(node.game))
        hasher.update(data: Data([node.a ? 1 : 0,node.b ? 1 : 0,UInt8(node.swaps)]))
        return Data(hasher.finalize())
    }
    static func write(_ object: Any,_ name: String) throws {
        try JSONSerialization.data(withJSONObject: object,options: [.sortedKeys]).write(to: directory.appendingPathComponent(name))
    }
    static func actions(_ path: [Int]) -> [[Int]] { path.map { $0 == fallCode ? [] : [$0 / 49,$0 % 49] } }
    static func summary(_ node: Node) -> [String: Any] {
        ["score":node.game.displayScore,"showers":node.game.turns,"outcome":String(describing:node.game.outcome),"A":node.a,"laterB":node.b,
         "swapsSinceShower":node.swaps,"rank":node.rank,"actions":actions(node.path),"encodedGame":String(data:try! encoder.encode(node.game),encoding:.utf8)!]
    }
    static func board(_ values: [StarfallGem?]) -> [Any] {
        values.map { value -> Any in guard let value else { return NSNull() }; return ["id":value.id,"kind":String(describing:value.kind!),"grown":value.grown] as [String:Any] }
    }
    static func trace(_ node: Node,_ name: String) throws {
        var game = FallingSky.freshChallenge(.firstLight), a = false, b = false
        var records: [[String:Any]] = []
        for (index,code) in node.path.enumerated() {
            precondition(!game.isOver)
            let before = game
            let turn = code == fallCode ? game.letStarsFall()! : game.nudge(from:cell(code / 49),to:cell(code % 49))!
            let copy = try JSONDecoder().decode(FallingSky.self,from:encoder.encode(game))
            precondition(game.isValidSave && copy == game && copy.isValidSave)
            let newA = turn.resolutionPhases.contains { !grownIDs($0).isEmpty }
            let newB = before.turns >= 1 && chain(turn.resolutionPhases)
            a = a || newA; b = b || newB
            let phases: [[String:Any]] = turn.resolutionPhases.map { phase in
                ["depth":phase.comboDepth,"kind":phase.kind.rawValue,"before":board(phase.before),"settled":board(phase.settled),
                 "clearedIDs":phase.cleared.compactMap {phase.before[$0.row * 7 + $0.column]?.id}.sorted(),"grownClearedIDs":grownIDs(phase),
                 "points":phase.award.displayPoints,"clearedCells":phase.cleared.map {$0.row * 7 + $0.column}.sorted(),
                 "recipes":phase.recipes.map { ["shape":$0.shape.rawValue,"ids":$0.starIDs.sorted()] }]
            }
            records.append(["actionIndex":index,"action":actions([code])[0],"showersBefore":before.turns,"showersAfter":game.turns,
                "scoreBefore":before.displayScore,"scoreAfter":game.displayScore,"outcome":String(describing:game.outcome),"newA":newA,"newLaterB":newB,
                "validSave":game.isValidSave,"roundTripEqual":copy == game,"phases":phases])
        }
        precondition(game == node.game && a == node.a && b == node.b)
        try write(["source":"8298d6cd","summary":summary(node),"records":records],name)
    }
    static func main() throws {
        let initial = FallingSky.freshChallenge(.firstLight)
        var startGame = initial
        let prefix = startGame.nudge(from:cell(1),to:cell(2))!
        precondition(prefix.resolutionPhases.count == 1 && prefix.displayAward == 5_000)
        precondition(Set(prefix.resolutionPhases[0].cleared.compactMap {prefix.resolutionPhases[0].before[$0.row * 7 + $0.column]?.id}) == Set([2,8,15,22]))
        let start = Node(game:startGame,a:false,b:false,swaps:1,path:[51],rank:rank(startGame,a:false,b:false))
        var counts = Counts(), visited = Set<Data>(), beam = [start], bestRank = start, bestScore = start
        var bestBoth: Node?, winner: Node?, layers: [[String:Any]] = []
        visited.insert(try key(start))
        let began = ProcessInfo.processInfo.systemUptime
        func exhausted() -> Bool { counts.raw >= maximumSuccessors || ProcessInfo.processInfo.systemUptime - began >= maximumSeconds }
        func evaluate(_ parent: Node,_ code: Int) throws -> Node? {
            guard !exhausted() else { return nil }
            counts.raw += 1
            if code == fallCode { counts.showers += 1 } else { counts.swaps += 1 }
            var game = parent.game
            let turn = code == fallCode ? game.letStarsFall() : game.nudge(from:cell(code / 49),to:cell(code % 49))
            guard let turn else { counts.rejected += 1; return nil }
            if code != fallCode { if turn.displayAward == 0 { counts.nonScoringSwaps += 1 } else { counts.scoredSwaps += 1 } }
            switch game.outcome { case .won:counts.rawWon += 1;case .lost:counts.rawLost += 1;case .playing:counts.rawPlaying += 1 }
            let a = parent.a || turn.resolutionPhases.contains {!grownIDs($0).isEmpty}
            let b = parent.b || (parent.game.turns >= 1 && chain(turn.resolutionPhases))
            let node = Node(game:game,a:a,b:b,swaps:code == fallCode ? 0 : parent.swaps+1,path:parent.path+[code],rank:rank(game,a:a,b:b))
            guard visited.insert(try key(node)).inserted else { counts.duplicates += 1;return nil }
            counts.accepted += 1
            switch game.outcome { case .won:counts.uniqueWon += 1;case .lost:counts.uniqueLost += 1;case .playing:counts.uniquePlaying += 1 }
            if ordered(node,bestRank) { bestRank = node }
            if node.game.displayScore > bestScore.game.displayScore || (node.game.displayScore == bestScore.game.displayScore && ordered(node,bestScore)) { bestScore = node }
            if a && b && (bestBoth == nil || node.game.displayScore > bestBoth!.game.displayScore) { bestBoth = node }
            if game.outcome == .won && a && b { winner = node }
            return node
        }
        var frontier: [Node] = beam, lastSwapInput: [Node] = beam, lastSwapOutput: [Node] = []
        var haltLayer = 0, haltDepth = 0
        for shower in 0..<maximumShowers {
            if exhausted() || beam.isEmpty || winner != nil { break }
            var active = beam, next: [Node] = []
            for depth in 0...maximumSwaps {
                if exhausted() || active.isEmpty || winner != nil { break }
                haltLayer = shower; haltDepth = depth; lastSwapInput = active
                var children: [Node] = []
                for node in active {
                    if exhausted() || winner != nil { break }
                    if let advanced = try evaluate(node,fallCode), !advanced.game.isOver { next.append(advanced) }
                    if winner != nil || exhausted() { break }
                    if node.swaps >= maximumSwaps { continue }
                    for from in 0..<49 {
                        if exhausted() || winner != nil { break }
                        guard node.game.board[from] != nil else { continue }
                        let destinations = [from-7,from-1,from+1,from+7].filter {(0..<49).contains($0) && abs(from/7-$0/7)+abs(from%7-$0%7)==1}.sorted()
                        for to in destinations {
                            if exhausted() || winner != nil { break }
                            if let child = try evaluate(node,from * 49 + to), !child.game.isOver { children.append(child) }
                        }
                    }
                }
                active = Array(children.sorted(by:ordered).prefix(width))
                lastSwapOutput = active
                frontier = active.isEmpty ? Array(next.sorted(by:ordered).prefix(width)) : active
                if depth == maximumSwaps { break }
            }
            beam = Array(next.sorted(by:ordered).prefix(width)); if !beam.isEmpty { frontier = beam }
            layers.append(["showersCompleted":shower+1,"raw":counts.raw,"unique":counts.accepted,"beam":beam.map(summary)])
            print("LAYER \(shower+1) raw=\(counts.raw) unique=\(counts.accepted) beam=\(beam.count) best=\(bestScore.game.displayScore) both=\(bestBoth?.game.displayScore ?? -1)")
        }
        let elapsed = ProcessInfo.processInfo.systemUptime - began
        let countsObject = try JSONSerialization.jsonObject(with:encoder.encode(counts))
        try write(["source":"8298d6cd","width":width,"maximumShowers":maximumShowers,"maximumSwapsBetweenShowers":maximumSwaps,
            "maximumSuccessors":maximumSuccessors,"maximumSeconds":maximumSeconds,"elapsedSeconds":elapsed,"forcedPrefixCommits":1,
            "stopReason":winner != nil ? "qualified-win" : counts.raw >= maximumSuccessors ? "successor-cap" : elapsed >= maximumSeconds ? "time-cap" : "horizon-or-empty-frontier",
            "counts":countsObject,"visitedIncludingStart":visited.count,"winner":winner.map {summary($0) as Any} ?? NSNull(),"bestScore":summary(bestScore),
            "bestRank":summary(bestRank),"bestBothGoals":bestBoth.map {summary($0) as Any} ?? NSNull(),"frontier":frontier.map(summary),
            "haltLayer":haltLayer,"haltSwapDepth":haltDepth,"lastSwapDepthInputFrontier":lastSwapInput.map(summary),
            "lastSwapDepthOutputFrontier":lastSwapOutput.map(summary),"nextShowerFrontier":beam.map(summary),"layers":layers],"search-result.json")
        try write(actions(bestRank.path),"best-rank-actions.json");try write(actions(bestScore.path),"best-score-actions.json")
        for (index,node) in frontier.enumerated() { try write(actions(node.path),"frontier-\(index)-actions.json") }
        try trace(bestRank,"best-rank-trace.json");try trace(bestScore,"best-score-trace.json")
        if let bestBoth { try trace(bestBoth,"best-both-trace.json");try write(actions(bestBoth.path),"best-both-actions.json") }
        if let winner { try trace(winner,"winning-trace.json");try write(actions(winner.path),"winning-actions.json") }
        print("FROZEN raw=\(counts.raw) unique=\(counts.accepted) duplicate=\(counts.duplicates) win=\(winner != nil) elapsed=\(elapsed)")
    }
}
