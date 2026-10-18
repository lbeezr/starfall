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
        return recipe.presentationPath
    }

    func setArranging(_ value: Bool) { cancel(); arranging = value }
    /// Arrange mode needs an actual piece. A committed empty sky must return
    /// to the ordinary controls instead of asking for an impossible selection.
    static func canArrange(in game: FallingSky) -> Bool {
        game.canArrangeStars && game.occupiedCount > 0
    }
    func reconcile(with game: FallingSky, preservingRecipeAt generation: UInt64? = nil) {
        // A shower may add unrelated stars without changing the chosen ingredients.
        // Keep the same explicit choice, but spend only the current committed snapshot.
        if let generation, arranging, !swapping, let anchor, let snapshot, let recipe,
           Self.canArrange(in: game), game.recipes.contains(recipe),
           game.gem(at: anchor) == snapshot.gem(at: anchor),
           recipe.cells.allSatisfy({ game.gem(at: $0) == snapshot.gem(at: $0) }) {
            self.snapshot = game; self.generation = generation
            return
        }
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
    private func selection(_ selectionID: UInt64) -> (FallingSky,UInt64)? {
        guard arranging, self.selectionID == selectionID, let snapshot, anchor != nil else { return nil }
        return (snapshot,generation)
    }
    func consumeSelection(_ selectionID: UInt64) -> (FallingSky,UInt64)? {
        guard let selected = selection(selectionID) else { return nil }
        cancel()
        return selected
    }
    @discardableResult func commitSelection(_ selectionID: UInt64, perform: (FallingSky,UInt64) -> Bool) -> Bool {
        guard let (snapshot,ticket) = selection(selectionID), perform(snapshot,ticket) else { return false }
        if self.selectionID == selectionID { cancel() }
        return true
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

/// Shared drawing order for an already validated recipe; it never resolves a recipe.
extension StarRecipe {
    var presentationPath: [Cell] {
        let cells = cells
        switch shape {
        case .square: return [cells[0], cells[1], cells[3], cells[2], cells[0]]
        case .cross: return [cells[2], cells[0], cells[2], cells[1], cells[2], cells[3], cells[2], cells[4]]
        }
    }
}

/// Logical contact ownership, separate from UIKit's physical recognizer and Core rules.
/// A trace may become a swap without releasing its shower hold. Every terminal path
/// clears local selection before releasing the ticket, so reentrant updates see idle state.
@MainActor @Observable final class SkyInteractionSession {
    let trace = ConstellationTraceIntent()
    let technique = SkyTechniqueIntent()
    private(set) var holdTicket: UInt64?

    @discardableResult func acquireHold(at cell: Cell?, using acquire: (Cell?) -> UInt64?) -> Bool {
        if holdTicket != nil { return true }
        holdTicket = acquire(cell)
        if holdTicket == nil { trace.cancel() }
        return holdTicket != nil
    }

    func armSwap(from: Cell, to: Cell, game: FallingSky, generation: UInt64) {
        trace.cancel()
        technique.armSwap(from, to: to, game: game, generation: generation)
    }

    func endContact(ticket: UInt64?, release: (UInt64?) -> Void) {
        guard ticket == holdTicket else { return }
        let owned = holdTicket
        holdTicket = nil
        trace.cancel()
        if technique.swapping { technique.cancel() }
        if let owned { release(owned) }
    }

    func cancelContact(release: (UInt64?) -> Void) {
        endContact(ticket: holdTicket, release: release)
    }

    func reconcile(with game: FallingSky, preservingRecipeAt generation: UInt64? = nil, release: (UInt64?) -> Void) {
        cancelContact(release: release)
        technique.reconcile(with: game, preservingRecipeAt: generation)
    }

    func invalidate(release: (UInt64?) -> Void) {
        cancelContact(release: release)
        technique.cancel()
    }
}


/// Transient input ticket. Core remains the authority for whether a walk can clear.
@MainActor final class ConstellationTraceIntent {
    var lastFinger: CGPoint?
    private(set) var path: [Cell] = []
    private(set) var snapshot: FallingSky?
    private(set) var generation: UInt64 = 0
    private(set) var sequence: UInt64 = 0
    var count: Int { Set(path).count }
    var value: Int { snapshot?.reward(of: Set(path)) ?? 0 }

    @discardableResult func begin(_ cell: Cell, game: FallingSky, generation: UInt64, enabled: Bool) -> UInt64? {
        cancel()
        guard enabled, game.canStartConstellation(at: cell) else { return nil }
        sequence &+= 1
        snapshot = game; self.generation = generation; path = [cell]
        return sequence
    }
    @discardableResult func visit(_ cell: Cell, ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> Bool {
        guard ticket == sequence, snapshot != nil else { return false }
        guard snapshot == game, self.generation == generation,
              let last = path.last, path.count < 196 else {
            cancel(); return false
        }
        guard enabled, cell != last, game.isValidConstellationPrefix(path + [cell]) else { return false }
        path.append(cell)
        return true
    }
    func finish(ticket: UInt64?, game: FallingSky, generation: UInt64, enabled: Bool) -> (path: [Cell], snapshot: FallingSky, generation: UInt64)? {
        defer { cancel() }
        guard ticket == sequence, let snapshot, snapshot == game, self.generation == generation,
              enabled, game.constellationCells(along: path) != nil else { return nil }
        return (path, snapshot, generation)
    }
    func cancel() { lastFinger = nil; path = []; snapshot = nil; sequence &+= 1 }
}
