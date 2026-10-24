import StarfallCore

/// One committed clear for optional in-session reading. No game, random stream,
/// persistence or action capability crosses this boundary.
struct SkyLastClearSnapshot: Equatable, Identifiable {
    static let maximumPhases = SkyScoreExplanation.maximumPhases

    struct Context: Equatable {
        let challenge: StarfallChallenge?
        let challengeRevision: Int
        let fullBoard: Bool
        let manualClears: Bool
    }

    struct Phase: Equatable {
        let board: [StarfallGem?]
        let drained: Set<Cell>
        let cleared: Set<Cell>
        let paths: [[Cell]]
        let score: SkyScoreExplanation.Phase
        let survivors: SkySurvivorIngredients?
        let refillCount: Int
        let occupiedAfter: Int
    }

    let roundGeneration: UInt64
    let sequence: UInt64
    var id: String { "\(roundGeneration):\(sequence)" }
    let context: Context
    let manualPath: [Cell]
    let phases: [Phase]
    let score: SkyScoreExplanation
    let survivorCount: Int
    let headroom: SkyHeadroomFeedback?
    let resultingOccupiedCount: Int
    let totalRefillCount: Int

    init?(turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
          path: [Cell], recipe: StarRecipe?, roundGeneration: UInt64, sequence: UInt64) {
        guard Self.validBoard(old.board), Self.validBoard(game.board),
              old.isValidSave, game.isValidSave, !old.isOver,
              old.challenge == game.challenge, old.challengeRevision == game.challengeRevision,
              old.usesFullBoardRefill == game.usesFullBoardRefill,
              old.supportsManualClears == game.supportsManualClears,
              let score = SkyScoreExplanation(turn: turn, from: old),
              path.count <= ConstellationReturnLayout.maximumWalkEntries,
              path.allSatisfy(Self.valid) else { return nil }

        if !path.isEmpty {
            guard let selected = old.constellationCells(along: path),
                  selected.isSubset(of: turn.resolutionPhases.first?.cleared ?? turn.cleared),
                  turn.resolutionPhases.first.map({ $0.kind == .manual && $0.before == old.board }) ?? true else { return nil }
        }

        let drainedIDs = Set(old.board.enumerated().compactMap { index, gem -> Int? in
            old.isDrained(at: Cell(index / FallingSky.side, index % FallingSky.side)) ? gem?.id : nil
        })

        var copied: [Phase] = []
        if turn.resolutionPhases.isEmpty {
            guard old.supportsManualClears, score.phases.count == 1, Self.validBoard(turn.settled),
                  turn.settled == game.board,
                  turn.cleared.allSatisfy({ Self.valid($0) && old.gem(at: $0) != nil }),
                  let paths = Self.manualPaths(path, recipe: recipe, board: old.board, cleared: turn.cleared) else { return nil }
            // A legacy turn has no Core resolution phases. Copy its actual
            // clear directly instead of inventing a scored Core transaction.
            copied = [Phase(board: old.board, drained: Self.drained(in: old.board, ids: drainedIDs),
                            cleared: turn.cleared, paths: paths,
                            score: score.phases[0], survivors: nil, refillCount: 0,
                            occupiedAfter: game.occupiedCount)]
        } else {
            let actual = turn.resolutionPhases
            guard (1...Self.maximumPhases).contains(actual.count), score.phases.count == actual.count,
                  actual.last?.refilled == game.board else { return nil }
            for (index, phase) in actual.enumerated() {
                guard phase.comboDepth == index + 1,
                      Self.validBoard(phase.before), Self.validBoard(phase.settled), Self.validBoard(phase.refilled),
                      !phase.cleared.isEmpty,
                      phase.cleared.allSatisfy({ Self.valid($0) && phase.before[$0.row * FallingSky.side + $0.column] != nil }),
                      index == 0 || actual[index - 1].refilled == phase.before,
                      phase.refillArrivals.count <= FallingSky.side * FallingSky.side,
                      phase.refillArrivals.allSatisfy({ arrival in
                          Self.valid(arrival.cell)
                              && phase.refilled[arrival.cell.row * FallingSky.side + arrival.cell.column] == arrival.gem
                      }) else { return nil }
                let paths: [[Cell]]
                let survivors: SkySurvivorIngredients?
                switch phase.kind {
                case .manual:
                    guard old.supportsManualClears, index == 0, phase.recipes.isEmpty,
                          let manual = Self.manualPaths(path, recipe: recipe, board: phase.before, cleared: phase.cleared) else { return nil }
                    paths = manual
                    survivors = nil
                case .recipe:
                    guard !phase.recipes.isEmpty,
                          phase.recipes.count <= PatternReturnLayout.maximumPatterns,
                          phase.recipes.allSatisfy({ Self.validRecipe($0, board: phase.before, cleared: phase.cleared) }),
                          Set(phase.recipes.flatMap(\.cells)) == phase.cleared else { return nil }
                    paths = phase.recipes.map(\.presentationPath)
                    if index > 0 {
                        guard let transition = SkySurvivorIngredients(phases: actual, currentIndex: index) else { return nil }
                        survivors = transition
                    } else { survivors = nil }
                }
                copied.append(Phase(board: phase.before, drained: Self.drained(in: phase.before, ids: drainedIDs),
                                    cleared: phase.cleared, paths: paths,
                                    score: score.phases[index], survivors: survivors,
                                    refillCount: phase.refillArrivals.count,
                                    occupiedAfter: phase.refilled.compactMap { $0 }.count))
            }
        }

        self.roundGeneration = roundGeneration
        self.sequence = sequence
        context = Context(challenge: old.challenge, challengeRevision: old.challengeRevision,
                          fullBoard: old.usesFullBoardRefill, manualClears: old.supportsManualClears)
        manualPath = path
        phases = copied
        self.score = score
        survivorCount = copied.reduce(0) { $0 + ($1.survivors?.movements.count ?? 0) }
        headroom = SkyHeadroomFeedback(turn: turn, from: old, to: game)
        resultingOccupiedCount = game.occupiedCount
        totalRefillCount = copied.reduce(0) { $0 + $1.refillCount }
    }

    private static func manualPaths(_ path: [Cell], recipe: StarRecipe?, board: [StarfallGem?],
                                    cleared: Set<Cell>) -> [[Cell]]? {
        if !path.isEmpty { return [path] }
        guard let recipe else { return [] }
        guard validRecipe(recipe, board: board, cleared: cleared) else { return nil }
        return [recipe.presentationPath]
    }

    private static func validRecipe(_ recipe: StarRecipe, board: [StarfallGem?], cleared: Set<Cell>) -> Bool {
        let count = recipe.cells.count
        let validCount: Bool
        switch recipe.shape {
        case .square: validCount = count == 4
        case .cross: validCount = count == 5
        case .line: validCount = (4...FallingSky.side).contains(count)
        }
        guard validCount, Set(recipe.cells).count == count, recipe.starIDs.count == count,
              recipe.cells.allSatisfy(valid), Set(recipe.cells).isSubset(of: cleared),
              recipe.starIDs == Set(recipe.cells.compactMap { board[$0.row * FallingSky.side + $0.column]?.id }),
              recipe.presentationPath.count <= PatternReturnLayout.maximumPathEntries else { return false }
        return true
    }

    private static func validBoard(_ board: [StarfallGem?]) -> Bool {
        guard board.count == FallingSky.side * FallingSky.side else { return false }
        let ids = board.compactMap { $0?.id }
        return ids.allSatisfy { $0 >= 0 } && Set(ids).count == ids.count
    }

    private static func drained(in board: [StarfallGem?], ids: Set<Int>) -> Set<Cell> {
        Set(board.enumerated().compactMap { index, gem in
            guard let gem, ids.contains(gem.id) else { return nil }
            return Cell(index / FallingSky.side, index % FallingSky.side)
        })
    }

    private static func valid(_ cell: Cell) -> Bool {
        (0..<FallingSky.side).contains(cell.row) && (0..<FallingSky.side).contains(cell.column)
    }
}
