import StarfallCore

extension SkyEntryRequest {
    /// Explains the pending choice without reading or replacing the retained round.
    func introduction(challenge: StarfallChallenge?) -> SkyDialogueLine {
        let mode = challenge?.dialoguePrefix ?? "observatory"
        return SkyDialogueLibrary.line(mode + (self == .replay ? ".replay" : ".entry"))
    }
}

/// Committed values only: results remain explainable after process restoration.
struct SkyResultSnapshot: Equatable {
    let won: Bool
    let challenge: StarfallChallenge?
    let score: Int
    let target: Int?
    let blockedColumn: Int?

    init?(game: FallingSky) {
        guard game.isOver else { return nil }
        won = game.outcome == .won
        challenge = game.challenge
        score = game.score
        target = game.challenge?.target
        blockedColumn = game.blockedColumn
    }

    var scoreLabel: String {
        target.map { SkyCopy.text(.resultChallengeScore, values: ["score": String(score), "target": String($0)]) } ?? SkyCopy.text(.resultScore, values: ["score": String(score)])
    }
    var reason: String {
        if won, let challenge { return challenge.resultReason }
        return blockedColumn.map { SkyCopy.text(.resultBlocked, values: ["column": String($0 + 1)]) }
            ?? SkyCopy.text(.resultFull)
    }
    var announcement: String { SkyCopy.text(.resultAnnouncement, values: ["reason": reason, "score": scoreLabel]) }
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
        let mode = game.challenge?.welcomeTitle ?? SkyCopy.text(.welcomeOpen)
        let light = game.challenge.map { SkyCopy.text(.welcomeTarget, values: ["score": String(game.score), "target": String($0.target)]) } ?? SkyCopy.text(.welcomeScore, values: ["score": String(game.score)])
        let state = game.outcome == .won ? SkyCopy.text(.welcomeComplete) : ended ? SkyCopy.text(.welcomeFull) : paused ? SkyCopy.text(.welcomePaused) : SkyCopy.text(.welcomeRunning)
        summary = hasSavedSky ? SkyCopy.text(.welcomeSummary, values: ["mode": mode, "score": light, "state": state]) : nil
    }
}
