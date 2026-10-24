import StarfallCore

/// A transient link to one actual displayed forecast entry, never a landing prediction.
struct SkyForecastInspection: Equatable {
    struct Source: Equatable {
        let game: FallingSky
        let generation: UInt64
        let forecast: [IncomingStar]
        let arriving: Bool

        init?(game: FallingSky, generation: UInt64, forecast: [IncomingStar], arriving: Bool) {
            guard !game.isOver, !game.usesFullBoardRefill, game.board.count == 49,
                  (1...49).contains(forecast.count),
                  forecast.allSatisfy({ $0.id >= 0 && (0..<FallingSky.side).contains($0.column) }),
                  Set(forecast.map(\.id)).count == forecast.count else { return nil }
            self.game = game
            self.generation = generation
            self.forecast = forecast
            self.arriving = arriving
        }
    }

    let entryID: Int
    private let source: Source

    init?(entryID: Int, source: Source) {
        guard source.forecast.contains(where: { $0.id == entryID }) else { return nil }
        self.entryID = entryID
        self.source = source
    }

    /// Even an exchange that leaves the forecast unchanged retires the old selection.
    func entry(in source: Source?) -> SkyForecastSnapshot.Entry? {
        guard let source, source == self.source else { return nil }
        return SkyForecastSnapshot(forecast: source.forecast).entries.first { $0.id == entryID }
    }
}
