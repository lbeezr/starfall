import StarfallCore

/// A value snapshot of the nearest feeding event. The store still owns shower timing.
struct DuskWarning: Equatable {
    let text: String

    init?(game: FallingSky) {
        guard game.duskRule != .legacy, !game.isOver else { return nil }
        let cells = (0..<49).map { Cell($0/7,$0%7) }.filter { game.gem(at: $0)?.isDark == true }
        guard let source = cells.sorted(by: {
            let a = game.duskTargets(at: $0).isEmpty ? -1 : (game.gem(at: $0)?.duskFeeds ?? 0)
            let b = game.duskTargets(at: $1).isEmpty ? -1 : (game.gem(at: $1)?.duskFeeds ?? 0)
            return a == b ? ($0.row == $1.row ? $0.column < $1.column : $0.row < $1.row) : a > b
        }).first else { return nil }
        let count = game.duskTargets(at: source).count
        let left = game.duskRule.feedingShowers - (game.gem(at: source)?.duskFeeds ?? 0)
        text = count == 0 ? SkyCopy.text(.duskWaiting)
            : SkyCopy.text(.duskWarning, values: ["stars": SkyCopy.count(.duskStarsOne, .duskStarsMany, count), "showers": SkyCopy.count(.duskShowersOne, .duskShowersMany, left)])
    }

    static func consequence(game: FallingSky, cell: Cell) -> String {
        guard game.gem(at: cell)?.isDark == true, game.duskRule != .legacy else { return "" }
        let targets = game.duskTargets(at: cell).sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        let left = game.duskRule.feedingShowers - (game.gem(at: cell)?.duskFeeds ?? 0)
        if targets.isEmpty { return SkyCopy.text(.duskWaiting) }
        let positions = targets.map { SkyCopy.position(row: 7-$0.row, column: $0.column+1) }.joined(separator: "; ")
        return SkyCopy.text(.duskConsequence, values: ["showers": SkyCopy.count(.duskShowersOne, .duskShowersMany, left), "positions": positions])
    }
}
