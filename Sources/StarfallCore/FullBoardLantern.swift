/// Saved supply accounting for the explicit full-board comparison. Each supplied
/// ordinary star uses one seeded draw and one fresh identity; no growth occurs.
struct FullBoardSupply: Codable, Equatable, Sendable {
    private(set) var suppliedStars = 0
    private(set) var refillingPhases = 0

    mutating func record(_ phases: [SkyResolutionPhase]) {
        suppliedStars += phases.reduce(0) { $0 + $1.refillArrivals.count }
        refillingPhases += phases.filter { !$0.refillArrivals.isEmpty }.count
    }

    func isValid(score: Int, turns: Int, ledger: StoryScoreLedger, random: SeededRandom, seed: UInt64) -> Bool {
        guard suppliedStars == score, suppliedStars >= 0,
              suppliedStars <= 150 + FullBoardLanternResolution.maximumTransactionLight,
              refillingPhases >= 0, refillingPhases <= suppliedStars / 4,
              refillingPhases >= ledger.actionCount, refillingPhases <= ledger.phaseCount,
              ledger.actionCount <= turns else { return false }
        var expected = SeededRandom(seed: seed)
        for _ in 0..<suppliedStars { _ = expected.next() }
        return random == expected
    }
}

/// Full-board transactions preserve every earned clear and survivor. Ordinary
/// refill is bounded to eight phases. If activity continues, resolve surviving
/// patterns without supply (at most twelve more phases), then fill the remaining
/// spaces without creating another pattern. Nothing unresolved is truncated.
enum FullBoardLanternResolution {
    static let maximumRefillingPhases = 8
    static let maximumPhases = maximumRefillingPhases + SkyRecipeResolution.maximumPhases
    static let maximumTransactionLight = 49 * (maximumRefillingPhases + 1)

    static func resolve(_ board: [StarfallGem?], random: inout SeededRandom, nextID: inout Int,
                        maximumOrdinaryRefills: Int = maximumRefillingPhases) -> [SkyResolutionPhase] {
        precondition((0...maximumRefillingPhases).contains(maximumOrdinaryRefills))
        var current = board
        var phases: [SkyResolutionPhase] = []
        while true {
            let recipes = StarRecipe.find(in: current, lineLength: 4)
            guard !recipes.isEmpty else { break }
            let cleared = Set(recipes.flatMap(\.cells))
            let phase = SkyResolutionPhase(kind: .recipe, before: current, cleared: cleared,
                                           recipes: recipes, comboDepth: phases.count + 1)
            let ordinaryRefill = phases.count < maximumOrdinaryRefills
            let settledIsStable = StarRecipe.find(in: phase.settled, lineLength: 4).isEmpty
            if ordinaryRefill || settledIsStable {
                let refill = fill(phase.settled, avoidingPatterns: !ordinaryRefill, random: &random, nextID: &nextID)
                phases.append(SkyResolutionPhase(kind: .recipe, before: current, cleared: cleared,
                                                 recipes: recipes, comboDepth: phases.count + 1,
                                                 refillArrivals: refill.arrivals, refilled: refill.board))
                current = refill.board
            } else {
                phases.append(phase)
                current = phase.settled
            }
        }
        assert(phases.count <= maximumPhases)
        assert(current.allSatisfy { $0 != nil })
        return phases
    }

    private static func fill(_ settled: [StarfallGem?], avoidingPatterns: Bool,
                             random: inout SeededRandom, nextID: inout Int)
        -> (board: [StarfallGem?], arrivals: [FallingSkyTurn.Arrival]) {
        var board = settled
        var arrivals: [FallingSkyTurn.Arrival] = []
        let palette: [Jewel] = [.aqua, .rose, .violet, .mint, .amber]
        for column in 0..<7 {
            for row in SkyBoardSettling.height(board, column: column)..<7 {
                let draw = Int(random.next() % UInt64(palette.count))
                let cell = Cell(row, column), index = row * 7 + column
                var selected: StarfallGem?
                for offset in 0..<palette.count {
                    let candidate = StarfallGem(id: nextID, kind: palette[(draw + offset) % palette.count])
                    board[index] = candidate
                    if !avoidingPatterns || StarRecipe.find(in: board, lineLength: 4).isEmpty {
                        selected = candidate
                        break
                    }
                }
                // Filling from each column's bottom leaves no star above this
                // cell. Any completed recipe must match its left, right or lower
                // neighbor, leaving at least two of the five families available.
                guard let gem = selected else { preconditionFailure("A pattern-free refill family must exist") }
                arrivals.append(.init(star: .init(id: nextID, kind: gem.kind, column: column),
                                      cell: cell, gem: gem, grew: false))
                nextID += 1
            }
        }
        return (board, arrivals)
    }
}
