import SwiftUI
import StarfallCore

enum SkyBoardAction {
    case recipe(StarRecipe)
    case nudge(Cell, Cell)
}

/// A direct swipe owns one transient snapshot and generation; it is never saved.
@MainActor @Observable final class SkyTechniqueIntent {
    private(set) var swapping = false
    private(set) var swapDestination: Cell?
    private(set) var anchor: Cell?
    private(set) var snapshot: FallingSky?
    private(set) var generation: UInt64 = 0
    var preview: [Cell] {
        guard swapping, let anchor, let swapDestination else { return [] }
        return [anchor, swapDestination]
    }

    func reconcile(with game: FallingSky) { cancel() }
    func cancel() { anchor = nil; snapshot = nil; swapping = false; swapDestination = nil }
    func armSwap(_ cell: Cell, to destination: Cell, game: FallingSky, generation: UInt64) {
        cancel()
        guard game.canNudge(from: cell, to: destination) else { return }
        anchor = cell; swapDestination = destination; snapshot = game
        self.generation = generation; swapping = true
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

    func reconcile(with game: FallingSky, release: (UInt64?) -> Void) {
        cancelContact(release: release)
        technique.reconcile(with: game)
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
