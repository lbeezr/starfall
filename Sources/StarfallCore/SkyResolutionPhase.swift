/// One committed clear and its falling survivors. Coordinates belong to `before`,
/// so a later phase can safely reuse a cell without reusing the same star.
public struct SkyResolutionPhase: Equatable, Sendable {
    public enum Kind: String, Sendable { case manual, recipe }
    public let kind: Kind
    public let before: [StarfallGem?]
    public let cleared: Set<Cell>
    public let recipes: [StarRecipe]
    public let settled: [StarfallGem?]
    /// New supply after surviving stars settle. Historical phases have no arrivals.
    public let refillArrivals: [FallingSkyTurn.Arrival]
    /// Full refill snapshot before the next causal clear; historical phases equal `settled`.
    public let refilled: [StarfallGem?]
    public let award: SkyScoreAward
    /// Causal clear number within this action, starting at one; never a timed streak.
    public let comboDepth: Int

    init(kind: Kind, before: [StarfallGem?], cleared: Set<Cell>,
         recipes: [StarRecipe] = [], comboDepth: Int,
         refillArrivals: [FallingSkyTurn.Arrival] = [], refilled: [StarfallGem?]? = nil) {
        self.kind = kind
        self.before = before
        self.cleared = cleared
        self.recipes = recipes
        self.comboDepth = comboDepth
        let ingredients = cleared.compactMap { before[$0.row * FallingSky.side + $0.column] }
        award = SkyScoreAward(baseLight: ingredients.reduce(0) { $0 + $1.value },
                              clearedStarCount: ingredients.count, comboDepth: comboDepth)
        var remaining = before
        for cell in cleared { remaining[cell.row * FallingSky.side + cell.column] = nil }
        settled = SkyBoardSettling.settle(remaining)
        self.refillArrivals = refillArrivals
        self.refilled = refilled ?? settled
    }
}

/// Automatic recipe resolution never introduces new stars or draws random values.
/// Every automatic phase spends at least four distinct stars, bounding an action
/// (including a possible two-star grown manual clear) to twelve phases on 49 cells.
enum SkyRecipeResolution {
    static let maximumPhases = 12

    static func resolve(_ board: [StarfallGem?], manualClear: Set<Cell>? = nil,
                        lineLength: Int? = nil) -> [SkyResolutionPhase] {
        var phases: [SkyResolutionPhase] = []
        var current = board
        if let manualClear {
            let phase = SkyResolutionPhase(kind: .manual, before: current, cleared: manualClear, comboDepth: 1)
            phases.append(phase)
            current = phase.settled
        }
        while phases.count < maximumPhases {
            let recipes = StarRecipe.find(in: current, lineLength: lineLength)
            guard !recipes.isEmpty else { break }
            // Simultaneous overlapping recipes spend the union once. Unrelated
            // matching neighbors remain available for ordinary taps and traces.
            let cells = Set(recipes.flatMap(\.cells))
            let phase = SkyResolutionPhase(kind: .recipe, before: current, cleared: cells,
                                           recipes: recipes, comboDepth: phases.count + 1)
            phases.append(phase)
            current = phase.settled
        }
        assert(StarRecipe.find(in: current, lineLength: lineLength).isEmpty)
        return phases
    }
}
