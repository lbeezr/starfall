import StarfallCore

/// Room left by one committed clear, distinct from temporary refill vacancies.
struct SkyHeadroomFeedback: Equatable {
    struct Column: Equatable {
        let index: Int
        let beforeSpaces: Int
        let afterSpaces: Int
    }

    enum Kind: Equatable {
        case opened(columns: [Int], spaces: Int)
        case refilled(stars: Int)
    }

    let columns: [Column]
    let kind: Kind

    init?(turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky) {
        guard old.isValidSave, game.isValidSave, !old.isOver, !game.isOver,
              old.challenge == game.challenge, old.challengeRevision == game.challengeRevision,
              old.usesFullBoardRefill == game.usesFullBoardRefill,
              !turn.cleared.isEmpty || turn.resolutionPhases.contains(where: { !$0.cleared.isEmpty }) else { return nil }
        let columns = (0..<FallingSky.side).map { index in
            Column(index: index,
                   beforeSpaces: FallingSky.side - SkyBoardSettling.height(old.board, column: index),
                   afterSpaces: FallingSky.side - SkyBoardSettling.height(game.board, column: index))
        }
        if game.usesFullBoardRefill {
            let arrivals = turn.resolutionPhases.reduce(0) { $0 + $1.refillArrivals.count }
            guard game.occupiedCount == FallingSky.side * FallingSky.side, arrivals > 0 else { return nil }
            kind = .refilled(stars: arrivals)
        } else {
            let opened = columns.filter { $0.afterSpaces > $0.beforeSpaces }
            guard !opened.isEmpty else { return nil }
            kind = .opened(columns: opened.map(\.index),
                           spaces: opened.reduce(0) { $0 + $1.afterSpaces - $1.beforeSpaces })
        }
        self.columns = columns
    }
}
