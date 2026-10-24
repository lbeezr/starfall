import Foundation
import Observation
import StarfallCore

/// One in-session drawing or automatic phase. It contains no award, packet,
/// clock or persistence capability; separate recipe paths never become a union walk.
struct SkyFinalLightReceipt: Equatable, Identifiable {
    let roundGeneration: UInt64
    let sequence: UInt64
    let paths: [[Cell]]
    let cells: [Cell]
    let identity: SkyIdentity
    var id: String { "\(roundGeneration):\(sequence)" }
}

/// Live celebration lifetime and one last-earned figure share the round boundary.
/// Interruptions retire live art; only a real replacement retires the earned record.
@MainActor @Observable final class SkyLightReceiptSession {
    private(set) var current: StarlightCelebration?
    private(set) var lastSurvivorCount: Int?
    private(set) var lastScore: SkyScoreExplanation?
    private(set) var lastEarned: SkyFinalLightReceipt?
    private(set) var roundGeneration: UInt64 = 0
    @ObservationIgnored private var sequence: UInt64 = 0
    @ObservationIgnored private var earnedSequence: UInt64 = 0
    @ObservationIgnored private var expiry: Task<Void, Never>?

    func nextSequence() -> UInt64 {
        sequence &+= 1
        return sequence
    }

    func publish(_ receipt: StarlightCelebration) {
        cancel()
        current = receipt
        let generation = roundGeneration
        expiry = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(StarlightCelebration.duration)) }
            catch { return }
            guard let self, self.roundGeneration == generation, self.current?.id == receipt.id else { return }
            self.current = nil
            self.expiry = nil
        }
    }

    func cancel() {
        expiry?.cancel()
        expiry = nil
        current = nil
    }

    func beginRound() {
        cancel()
        roundGeneration &+= 1
        lastEarned = nil
        lastScore = nil
        lastSurvivorCount = nil
    }

    /// Capture from the already committed transaction, before a presenter can
    /// skip callbacks or a terminal handoff can discard its board anchors.
    func capture(_ turn: FallingSkyTurn, from old: FallingSky, path: [Cell], recipe: StarRecipe?) {
        if let explanation = SkyScoreExplanation(turn: turn, from: old) {
            lastScore = explanation
            lastSurvivorCount = SkySurvivorCopy.count(in: turn.resolutionPhases)
        }
        guard turn.collected > 0 else { return }
        earnedSequence &+= 1
        // An earned ordinary tap has no shape; do not mislabel an older drawing
        // as that latest award. A no-award move or losing shower keeps the record.
        lastEarned = nil
        if let phase = turn.resolutionPhases.last {
            guard phase.award.baseLight > 0 else { return }
            if phase.kind == .recipe {
                captureRecipes(phase.recipes, cleared: phase.cleared, board: phase.before)
            } else if !path.isEmpty {
                captureWalk(path, cleared: phase.cleared, from: old)
            }
        } else if !path.isEmpty {
            captureWalk(path, cleared: turn.cleared, from: old)
        } else if let recipe {
            captureRecipes([recipe], cleared: turn.cleared, board: old.board)
        }
    }

    private func captureWalk(_ path: [Cell], cleared: Set<Cell>, from old: FallingSky) {
        guard let selected = old.constellationCells(along: path), selected.isSubset(of: cleared) else { return }
        lastEarned = makeReceipt(paths: [path], board: old.board,
            maximumPaths: 1, maximumEntries: ConstellationReturnLayout.maximumWalkEntries,
            reward: { old.reward(of: [$0]) })
    }

    private func captureRecipes(_ recipes: [StarRecipe], cleared: Set<Cell>, board: [StarfallGem?]) {
        guard board.count == FallingSky.side * FallingSky.side,
              !recipes.isEmpty, recipes.count <= PatternReturnLayout.maximumPatterns,
              recipes.allSatisfy({ recipe in
                  validIngredientCount(recipe)
                      && recipe.cells.allSatisfy(Self.valid)
                      && Set(recipe.cells).count == recipe.cells.count
                      && Set(recipe.cells).isSubset(of: cleared)
                      && recipe.starIDs == Set(recipe.cells.compactMap { board[$0.row * FallingSky.side + $0.column]?.id })
              }) else { return }
        lastEarned = makeReceipt(paths: recipes.map(\.presentationPath), board: board,
            maximumPaths: PatternReturnLayout.maximumPatterns,
            maximumEntries: PatternReturnLayout.maximumPathEntries,
            reward: { board[$0.row * FallingSky.side + $0.column]?.value ?? 0 })
    }

    private func validIngredientCount(_ recipe: StarRecipe) -> Bool {
        switch recipe.shape {
        case .square: recipe.cells.count == 4
        case .cross: recipe.cells.count == 5
        case .line: (4...FallingSky.side).contains(recipe.cells.count)
        }
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<FallingSky.side).contains(cell.row) && (0..<FallingSky.side).contains(cell.column)
    }

    private func makeReceipt(paths: [[Cell]], board: [StarfallGem?], maximumPaths: Int,
                             maximumEntries: Int, reward: (Cell) -> Int) -> SkyFinalLightReceipt? {
        guard !paths.isEmpty, paths.count <= maximumPaths,
              paths.allSatisfy({ (2...maximumEntries).contains($0.count) && $0.allSatisfy(Self.valid) }),
              board.count == FallingSky.side * FallingSky.side else { return nil }
        let cells = Set(paths.flatMap { $0 }).sorted {
            $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row
        }
        guard cells.count <= ConstellationReturnLayout.maximumStars,
              cells.allSatisfy({ board[$0.row * FallingSky.side + $0.column] != nil }),
              let brightest = cells.max(by: { reward($0) < reward($1) }), reward(brightest) > 0,
              let identity = board[brightest.row * FallingSky.side + brightest.column]?.identity else { return nil }
        return SkyFinalLightReceipt(roundGeneration: roundGeneration, sequence: earnedSequence,
                                    paths: paths, cells: cells, identity: identity)
    }

    deinit { expiry?.cancel() }
}
