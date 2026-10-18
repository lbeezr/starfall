import SwiftUI
import StarfallCore

enum SkyBoardAction {
    case recipe(StarRecipe)
    case nudge(Cell, Cell)
}

/// One transient selection owns its snapshot and generation; it is never saved.
@MainActor @Observable final class SkyTechniqueIntent {
    private(set) var arranging = false
    private(set) var swapping = false
    private(set) var swapDestination: Cell?
    private(set) var anchor: Cell?
    private(set) var snapshot: FallingSky?
    private(set) var generation: UInt64 = 0
    private(set) var selectionID: UInt64 = 0
    private(set) var recipe: StarRecipe?
    var preview: [Cell] {
        if swapping, let anchor, let swapDestination { return [anchor,swapDestination] }
        guard arranging || swapping else { return [] }
        guard let recipe else { return anchor.map { [$0] } ?? [] }
        let cells = recipe.cells
        switch recipe.shape {
        case .square: return [cells[0],cells[1],cells[3],cells[2],cells[0]]
        case .cross: return [cells[2],cells[0],cells[2],cells[1],cells[2],cells[3],cells[2],cells[4]]
        }
    }

    func setArranging(_ value: Bool) { cancel(); arranging = value }
    /// Arrange mode needs an actual piece. A committed empty sky must return
    /// to the ordinary controls instead of asking for an impossible selection.
    static func canArrange(in game: FallingSky) -> Bool {
        game.canArrangeStars && game.occupiedCount > 0
    }
    func reconcile(with game: FallingSky) {
        cancel()
        if !Self.canArrange(in: game) { arranging = false }
    }
    func cancel() { selectionID &+= 1; anchor = nil; recipe = nil; snapshot = nil; swapping = false; swapDestination = nil }
    func armSwap(_ cell: Cell, to destination: Cell, game: FallingSky, generation: UInt64) {
        guard game.canNudge(from:cell,to:destination) else { cancel(); return }
        select(cell, game: game, generation: generation)
        swapping = snapshot != nil
        swapDestination = destination
        recipe = nil
    }
    /// Menu/toolbar callbacks may outlive cancellation without a core generation change.
    func chooseRecipe(_ recipeID: String, selectionID: UInt64) {
        guard arranging, self.selectionID == selectionID, let anchor, let snapshot,
              let next = snapshot.recipes(containing:anchor).first(where: { $0.id == recipeID }),
              next != recipe else { return }
        recipe = next; self.selectionID &+= 1
    }
    func consumeSelection(_ selectionID: UInt64) -> (FallingSky,UInt64)? {
        guard arranging, self.selectionID == selectionID, let snapshot, anchor != nil else { return nil }
        let ticket = generation
        cancel()
        return (snapshot,ticket)
    }
    func select(_ cell: Cell, game: FallingSky, generation: UInt64) {
        cancel()
        guard game.canArrangeStars, game.gem(at: cell) != nil else { return }
        anchor = cell; snapshot = game; self.generation = generation
        recipe = game.recipes(containing: cell).first
    }
}

/// Descriptive only: every continuation must spend a recipe created by the preceding clear.
struct SkyTechniqueRelay {
    private var followups: [StarRecipe] = []
    private(set) var depth = 0
    mutating func reset() { followups = []; depth = 0 }
    mutating func record(before: FallingSky, after: FallingSky, cleared: Set<Cell>) {
        let spent = Set(cleared.compactMap { before.gem(at:$0)?.id })
        depth = followups.contains { $0.starIDs.isSubset(of:spent) } ? depth + 1 : 1
        let previous = Set(before.recipes.map(\.id))
        followups = after.recipes.filter { !previous.contains($0.id) }
    }
}
