import StarfallCore

extension SkyEntryRequest {
    /// Explains the pending choice without reading or replacing the retained round.
    func introduction(challenge: StarfallChallenge?, replayingRevision: Int = 0, replayingTarget: Int? = nil) -> SkyDialogueLine {
        let mode = challenge?.dialoguePrefix ?? "observatory"
        let fresh = challenge.map { FallingSky.freshChallenge($0) }
        let revision = self == .replay ? replayingRevision : fresh?.challengeRevision ?? 0
        let story = revision > 0 && (challenge == .firstLight || challenge == .ribbonCrossing)
        let variant = story ? (revision >= 3 ? ".patterns" : revision == 2 ? ".cascade" : ".story") : ""
        let id = mode + variant + (self == .replay ? ".replay" : ".entry")
        let target = self == .replay ? replayingTarget : fresh?.displayTarget
        precondition(!story || target != nil, "A story replay needs its retained objective")
        var values = story ? ["target": SkyCopy.score(target ?? 0)] : [:]
        if self != .replay, let fresh { values.merge(fresh.automaticPatternValues) { _, new in new } }
        return SkyDialogueLibrary.line(id, values: values)
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
        score = game.displayScore
        target = game.displayTarget
        blockedColumn = game.blockedColumn
    }

    var scoreLabel: String {
        target.map { SkyCopy.text(.resultChallengeScore, values: ["score": SkyCopy.score(score), "target": SkyCopy.score($0)]) } ?? SkyCopy.text(.resultScore, values: ["score": SkyCopy.score(score)])
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
    let challengeRevision: Int
    let target: Int?
    let summary: String?
    var canContinue: Bool { hasSavedSky && !ended }
    init(game: FallingSky, hasSavedSky: Bool, paused: Bool) {
        self.hasSavedSky = hasSavedSky; ended = game.isOver; score = game.displayScore
        challengeRevision = game.challengeRevision
        target = game.displayTarget
        let mode = game.challenge?.welcomeTitle ?? SkyCopy.text(.welcomeOpen)
        let light = game.displayTarget.map { SkyCopy.text(.welcomeTarget, values: ["score": SkyCopy.score(game.displayScore), "target": SkyCopy.score($0)]) } ?? SkyCopy.text(.welcomeScore, values: ["score": SkyCopy.score(game.displayScore)])
        let state = game.outcome == .won ? SkyCopy.text(.welcomeComplete) : ended ? SkyCopy.text(.welcomeFull) : paused ? SkyCopy.text(.welcomePaused) : SkyCopy.text(.welcomeRunning)
        summary = hasSavedSky ? SkyCopy.text(.welcomeSummary, values: ["mode": mode, "score": light, "state": state]) : nil
    }
}
