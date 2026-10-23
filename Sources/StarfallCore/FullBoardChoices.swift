/// An optional arrangement using stars already visible on the full board.
/// Recipes describe the first clear after the final exchange, before any refill.
/// These values are neither committed actions nor part of a saved round.
public struct FullBoardChoice: Equatable, Sendable {
    public let exchanges: [FallingSkyTurn.Exchange]
    public let recipes: [StarRecipe]
    public var cleared: Set<Cell> { Set(recipes.flatMap(\.cells)) }
}

extension FallingSky {
    /// Offers up to two different immediate clears, or one two-exchange setup.
    /// Search order is stable; a different pattern shape is preferred for the
    /// second choice. This examines visible ingredients, never hidden supply,
    /// future awards or the random generator. It does not rank optimal moves.
    ///
    /// At most 84 direct swaps and 84×84 follow-ups are examined. Callers can
    /// cancel detached analysis; a canceled search returns no suggestions.
    public func fullBoardChoices() -> [FullBoardChoice] {
        guard usesFullBoardRefill, canArrangeStars, board.count == Self.side * Self.side,
              board.allSatisfy({ $0 != nil }), !Task.isCancelled else { return [] }
        let lineLength = automaticLineLength
        var direct: [FullBoardChoice] = []
        var clearIdentities: Set<Set<Int>> = []
        var setups: [(FallingSkyTurn.Exchange, [StarfallGem?])] = []

        for exchange in FullBoardChoiceSearch.exchanges {
            guard !Task.isCancelled else { return [] }
            let arranged = FullBoardChoiceSearch.exchanging(board, using: exchange)
            let recipes = StarRecipe.find(in: arranged, lineLength: lineLength)
            if recipes.isEmpty {
                if gem(at: exchange.from)?.kind != gem(at: exchange.to)?.kind {
                    setups.append((exchange, arranged))
                }
            } else if clearIdentities.insert(Set(recipes.flatMap(\.starIDs))).inserted {
                direct.append(FullBoardChoice(exchanges: [exchange], recipes: recipes))
            }
        }

        guard !Task.isCancelled else { return [] }
        if let first = direct.first {
            let shapes = Set(first.recipes.map(\.shape))
            let alternative = direct.dropFirst().first { Set($0.recipes.map(\.shape)) != shapes }
                ?? direct.dropFirst().first
            return [first] + (alternative.map { [$0] } ?? [])
        }

        for (setup, arranged) in setups {
            guard !Task.isCancelled else { return [] }
            for exchange in FullBoardChoiceSearch.exchanges {
                guard !Task.isCancelled else { return [] }
                let next = FullBoardChoiceSearch.exchanging(arranged, using: exchange)
                let recipes = StarRecipe.find(in: next, lineLength: lineLength)
                if !recipes.isEmpty {
                    guard !Task.isCancelled else { return [] }
                    return [FullBoardChoice(exchanges: [setup, exchange], recipes: recipes)]
                }
            }
        }
        return []
    }
}

private enum FullBoardChoiceSearch {
    /// Right and up enumerate every neighboring pair exactly once, bottom first.
    static let exchanges: [FallingSkyTurn.Exchange] = (0..<FallingSky.side).flatMap { row in
        (0..<FallingSky.side).flatMap { column -> [FallingSkyTurn.Exchange] in
            let source = Cell(row, column)
            let neighbors = [Cell(row, column + 1), Cell(row + 1, column)]
            return neighbors.filter { $0.row < FallingSky.side && $0.column < FallingSky.side }
                .map { .init(from: source, to: $0) }
        }
    }

    static func exchanging(_ board: [StarfallGem?], using exchange: FallingSkyTurn.Exchange) -> [StarfallGem?] {
        var arranged = board
        arranged.swapAt(exchange.from.row * FallingSky.side + exchange.from.column,
                        exchange.to.row * FallingSky.side + exchange.to.column)
        return SkyBoardSettling.settle(arranged)
    }
}
