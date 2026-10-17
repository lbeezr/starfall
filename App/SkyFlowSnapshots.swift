import StarfallCore

/// Committed values only: results remain explainable after process restoration.
struct SkyResultSnapshot: Equatable {
    let won: Bool
    let score: Int
    let target: Int?
    let blockedColumn: Int?

    init?(game: FallingSky) {
        guard game.isOver else { return nil }
        won = game.outcome == .won
        score = game.score
        target = game.challenge?.target
        blockedColumn = game.blockedColumn
    }

    var scoreLabel: String {
        target.map { "\(score) of \($0) starlight collected" } ?? "\(score) starlight"
    }
    var reason: String {
        if won { return "First Light complete." }
        return blockedColumn.map { "Column \($0 + 1) had no room for the next star." }
            ?? "There was no room for the next star."
    }
    var announcement: String { "\(reason) \(scoreLabel)." }
}


/// Welcome describes the retained round without changing it.
struct SkyWelcomeSnapshot: Equatable {
    let hasSavedSky: Bool
    let ended: Bool
    let score: Int
    let summary: String?
    var canContinue: Bool { hasSavedSky && !ended }
    init(game: FallingSky, hasSavedSky: Bool, paused: Bool) {
        self.hasSavedSky = hasSavedSky; ended = game.isOver; score = game.score
        let mode = game.challenge != nil ? "First Light" : "Open sky"
        let light = game.challenge.map { "\(game.score) of \($0.target) starlight" } ?? "\(game.score) starlight"
        let state = game.outcome == .won ? "Complete" : ended ? "Sky full" : paused ? "Paused" : "Automatic showers"
        summary = hasSavedSky ? "\(mode) · \(light) · \(state)" : nil
    }
}
