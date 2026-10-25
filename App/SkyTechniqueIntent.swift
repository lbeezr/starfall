import SwiftUI
import StarfallCore

enum SkyGestureTiming {
    static let drawingHoldMilliseconds = 300
    static var drawingHoldDuration: TimeInterval { Double(drawingHoldMilliseconds) / 1_000 }
}

enum SkyBoardAction {
    case recipe(StarRecipe)
    case nudge(Cell, Cell)
}

/// A request names the committed stars, never an animation's node coordinates.
enum SkyPlayerInput: Equatable {
    case tap(Cell)
    case swap(Cell, Cell)

    var source: Cell {
        switch self { case .tap(let cell), .swap(let cell, _): cell }
    }
    var destination: Cell? {
        if case .swap(_, let cell) = self { return cell }
        return nil
    }
    func preview(in game: FallingSky) -> FallingSkyTurn? {
        var next = game
        switch self {
        case .tap(let cell): return next.clear(cell)
        case .swap(let from, let to): return next.nudge(from: from, to: to)
        }
    }
}

struct SkyBufferedInput: Equatable {
    /// A bounded plan, never a timer or a saved action. Every entry names the
    /// exact projected prestate and endpoints; later contacts cannot retarget it.
    static let capacity = 4
    let ticket: UInt64
    let action: SkyPlayerInput
    let snapshot: FallingSky
    let sourceID: Int
    let destinationID: Int?
    let projectedGame: FallingSky

    init?(ticket: UInt64, action: SkyPlayerInput, game: FallingSky) {
        guard let sourceID = game.gem(at: action.source)?.id else { return nil }
        var projected = game
        let turn: FallingSkyTurn?
        switch action {
        case .tap(let cell): turn = projected.clear(cell)
        case .swap(let from, let to): turn = projected.nudge(from: from, to: to)
        }
        guard turn != nil else { return nil }
        self.ticket = ticket; self.action = action; snapshot = game
        self.sourceID = sourceID
        destinationID = action.destination.flatMap { game.gem(at: $0)?.id }
        projectedGame = projected
    }
    func matches(_ game: FallingSky) -> Bool {
        snapshot == game && game.gem(at: action.source)?.id == sourceID
            && action.destination.flatMap { game.gem(at: $0)?.id } == destinationID
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
    var title: String {
        SkyCopy.text(shape == .square ? .techniqueSquare : shape == .cross ? .techniqueCross : .techniqueLine)
    }
    var presentationPath: [Cell] {
        let cells = cells
        switch shape {
        case .square: return [cells[0], cells[1], cells[3], cells[2], cells[0]]
        case .cross: return [cells[2], cells[0], cells[2], cells[1], cells[2], cells[3], cells[2], cells[4]]
        case .line: return cells
        }
    }
}

/// Logical contact ownership, separate from UIKit's physical recognizer and Core rules.
/// Every terminal path clears local selection before releasing the ticket, so reentrant updates see idle state.
@MainActor @Observable final class SkyInteractionSession {
    let trace = ConstellationTraceIntent()
    private(set) var holdTicket: UInt64?
    // Contact callbacks consume this source; it never drives rendering.
    @ObservationIgnored private(set) var inputSnapshot: FallingSky?

    @discardableResult func acquireHold(at cell: Cell?, snapshot: FallingSky? = nil,
                                       using acquire: (Cell?) -> UInt64?) -> Bool {
        if holdTicket != nil { return true }
        guard let ticket = acquire(cell) else {
            inputSnapshot = nil
            trace.cancel()
            return false
        }
        holdTicket = ticket
        inputSnapshot = snapshot
        return true
    }

    func endContact(ticket: UInt64?, release: (UInt64?) -> Void) {
        guard ticket == holdTicket else { return }
        let owned = holdTicket
        holdTicket = nil
        inputSnapshot = nil
        trace.cancel()
        if let owned { release(owned) }
    }

    func cancelContact(release: (UInt64?) -> Void) {
        endContact(ticket: holdTicket, release: release)
    }

    func reconcile(with game: FallingSky, release: (UInt64?) -> Void) {
        cancelContact(release: release)
    }

    func invalidate(release: (UInt64?) -> Void) {
        cancelContact(release: release)
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
    var value: Int { snapshot?.displayReward(of: Set(path)) ?? 0 }

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
