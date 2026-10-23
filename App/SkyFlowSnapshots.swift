import StarfallCore

extension SkyEntryRequest {
    /// Explains the pending choice without reading or replacing the retained round.
    func introduction(challenge: StarfallChallenge?, replayingRevision: Int = 0, replayingTarget: Int? = nil) -> SkyDialogueLine {
        if self == .fullBoardLantern || self == .replay && replayingRevision == 5 {
            return SkyDialogueLibrary.line(self == .replay ? "full-board-lantern.replay" : "full-board-lantern.entry",
                values: ["target": SkyCopy.score(self == .replay ? replayingTarget ?? 0 : FallingSky.fullBoardLantern().displayTarget ?? 0)])
        }
        let mode = challenge?.dialoguePrefix ?? "observatory"
        let fresh = challenge.map { FallingSky.freshChallenge($0) }
        let selectedRules = self == .replay
            ? challenge.flatMap { StoryChallengeDefinition($0, revision: replayingRevision) }.map { FallingSky(definition: $0) }
            : fresh
        let story = (selectedRules?.challengeRevision ?? 0) > 0
        let variant = story ? (selectedRules?.supportsManualClears == false ? ".patterns"
            : selectedRules?.supportsAutomaticRecipes == true ? ".cascade" : ".story") : ""
        let id = mode + variant + (self == .replay ? ".replay" : ".entry")
        let target = self == .replay ? replayingTarget : fresh?.displayTarget
        precondition(!story || target != nil, "A story replay needs its retained objective")
        var values = story ? ["target": SkyCopy.score(target ?? 0)] : [:]
        if self != .replay, let fresh { values.merge(fresh.automaticPatternValues) { _, new in new } }
        return SkyDialogueLibrary.line(id, values: values)
    }
}

/// A selected destination's read-only goals. New visits use today's authored
/// definition; only a matching unfinished saved round supplies retained progress.
/// The map receives these values, never the game's mutation or save capabilities.
struct WorldMapGoalSnapshot: Equatable {
    let newVisitTarget: Int
    let retainedProgress: StarlightRestoration?

    init?(journey: WorldJourney, retainedRound: FallingSky?) {
        guard let challenge = journey.selected.challenge, journey.canEnter(journey.selected),
              let target = FallingSky.freshChallenge(challenge).displayTarget else { return nil }
        newVisitTarget = target
        retainedProgress = retainedRound.flatMap {
            $0.challenge == challenge && !$0.isOver ? $0.restoration : nil
        }
    }

    var newVisitLabel: String {
        SkyCopy.text(.worldNewVisitGoal, values: ["target": SkyCopy.score(newVisitTarget)])
    }
    var retainedLabel: String? {
        retainedProgress.map {
            SkyCopy.text(.worldSavedProgress, values: ["score": SkyCopy.score($0.score), "target": SkyCopy.score($0.target)])
        }
    }
}

/// The immediate road onward from an earned repair, independent of map browsing.
struct SkyOnwardSnapshot: Equatable {
    let destination: WorldLocation

    init?(game: FallingSky, journey: WorldJourney) {
        guard game.isValidSave, game.outcome == .won, let challenge = game.challenge,
              let location = WorldLocation(rawValue: challenge.rawValue),
              journey.completed.contains(location),
              let next = WorldLocation.allCases.dropFirst(location.number).first,
              next.challenge != nil, journey.canEnter(next), !journey.completed.contains(next) else { return nil }
        destination = next
    }

    var label: String { SkyCopy.text(.worldVisitNext, values: ["destination": destination.title]) }
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
        let mode = game.usesFullBoardRefill ? SkyCopy.text(.fullBoardWelcome) : game.challenge?.welcomeTitle ?? SkyCopy.text(.welcomeOpen)
        let light = game.displayTarget.map { SkyCopy.text(.welcomeTarget, values: ["score": SkyCopy.score(game.displayScore), "target": SkyCopy.score($0)]) } ?? SkyCopy.text(.welcomeScore, values: ["score": SkyCopy.score(game.displayScore)])
        let state = game.outcome == .won ? SkyCopy.text(.welcomeComplete) : ended ? SkyCopy.text(.welcomeFull)
            : game.usesFullBoardRefill ? SkyCopy.text(.fullBoardPace) : paused ? SkyCopy.text(.welcomePaused) : SkyCopy.text(.welcomeRunning)
        summary = hasSavedSky ? SkyCopy.text(.welcomeSummary, values: ["mode": mode, "score": light, "state": state]) : nil
    }
}
