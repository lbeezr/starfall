import StarfallCore

/// Actual moved ingredients of one later recipe, from the same committed action.
/// Refill births never become original-action survivors, even in a later phase.
struct SkySurvivorIngredients: Equatable {
    static let maximumPhases = 20
    static let maximumMovements = FallingSky.side * FallingSky.side

    struct Movement: Equatable, Identifiable {
        let id: Int
        let gem: StarfallGem
        let from: Cell
        let to: Cell
        let recipeIndices: [Int]
    }

    let movements: [Movement]
    let patterns: [StarRecipe]

    init?(phases: [SkyResolutionPhase], currentIndex: Int) {
        guard (1...Self.maximumPhases).contains(phases.count),
              phases.indices.contains(currentIndex), currentIndex > 0 else { return nil }
        var snapshots: [Snapshot] = []
        for (index, phase) in phases.prefix(currentIndex + 1).enumerated() {
            guard phase.comboDepth == index + 1, !phase.cleared.isEmpty,
                  phase.cleared.count <= Self.maximumMovements,
                  let before = Self.positions(phase.before),
                  let settled = Self.positions(phase.settled),
                  let refilled = Self.positions(phase.refilled),
                  phase.cleared.allSatisfy({ Self.valid($0) && phase.before[$0.row * FallingSky.side + $0.column] != nil }),
                  snapshots.last.map({ $0.phase.refilled == phase.before }) ?? true else { return nil }
            snapshots.append(Snapshot(phase: phase, before: before, settled: settled, refilled: refilled))
        }
        let current = snapshots[currentIndex], previous = snapshots[currentIndex - 1]
        let recipes = current.phase.recipes
        guard current.phase.kind == .recipe, !recipes.isEmpty,
              recipes.count <= PatternReturnLayout.maximumPatterns,
              recipes.allSatisfy({ recipe in
                  (4...FallingSky.side).contains(recipe.cells.count)
                      && Set(recipe.cells).count == recipe.cells.count
                      && recipe.starIDs.count == recipe.cells.count
                      && recipe.cells.allSatisfy(Self.valid)
                      && Set(recipe.cells.compactMap { current.phase.before[$0.row * FallingSky.side + $0.column]?.id }) == recipe.starIDs
              }), Set(recipes.flatMap(\.cells)) == current.phase.cleared else { return nil }
        let originals = snapshots[0].before
        var moved: [Movement] = []
        for id in Set(recipes.flatMap(\.starIDs)).sorted() {
            guard let original = originals[id], let from = previous.before[id], let to = current.before[id],
                  from.cell != to.cell, from.gem == original.gem, to.gem == original.gem,
                  previous.settled[id]?.cell == to.cell,
                  previous.settled[id]?.gem == original.gem else { continue }
            // Check continuity through every earlier clear/refill, rather than
            // mistaking a newly supplied star for an original survivor later.
            guard snapshots.dropLast().allSatisfy({ snapshot in
                guard let location = snapshot.before[id] else { return false }
                return location.gem == original.gem && !snapshot.phase.cleared.contains(location.cell)
                    && snapshot.settled[id]?.gem == original.gem
                    && snapshot.refilled[id]?.gem == original.gem
                    && !snapshot.phase.refillArrivals.contains(where: { $0.gem.id == id })
            }) else { continue }
            let memberships = recipes.indices.filter { recipes[$0].starIDs.contains(id) }
            moved.append(Movement(id: id, gem: to.gem, from: from.cell, to: to.cell, recipeIndices: memberships))
        }
        guard moved.count <= Self.maximumMovements else { return nil }
        movements = moved
        patterns = recipes
    }

    private struct Location {
        let cell: Cell
        let gem: StarfallGem
    }

    private struct Snapshot {
        let phase: SkyResolutionPhase
        let before: [Int: Location]
        let settled: [Int: Location]
        let refilled: [Int: Location]
    }

    private static func positions(_ board: [StarfallGem?]) -> [Int: Location]? {
        guard board.count == maximumMovements else { return nil }
        var result: [Int: Location] = [:]
        for (index, value) in board.enumerated() {
            guard let gem = value else { continue }
            guard gem.id >= 0, result[gem.id] == nil else { return nil }
            result[gem.id] = Location(cell: Cell(index / FallingSky.side, index % FallingSky.side), gem: gem)
        }
        return result
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<FallingSky.side).contains(cell.row) && (0..<FallingSky.side).contains(cell.column)
    }
}
