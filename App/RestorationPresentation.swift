import StarfallCore

/// Selects the location's presentation without constructing or saving a replacement sky.
/// Pending entry previews start unrestored; canceling reveals the committed round again.
struct RestorationPresentation: Equatable {
    let challenge: StarfallChallenge
    let progress: StarlightRestoration

    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> Self? {
        if let entry {
            guard let challenge = entry.selectedChallenge(replaying: game.challenge) else { return nil }
            return Self(challenge: challenge, progress: StarlightRestoration(score: 0, target: challenge.target))
        }
        guard let challenge = game.challenge, let progress = game.restoration else { return nil }
        return Self(challenge: challenge, progress: progress)
    }
}

/// App-only names and content routes. Core retains the saved challenge identity;
/// the local catalogue remains the single owner of player-facing wording.
extension StarfallChallenge {
    var flowAction: SkyFlowAction {
        switch self {
        case .firstLight: .firstLight
        case .ribbonCrossing: .ribbonCrossing
        }
    }
    var dialoguePrefix: String {
        switch self {
        case .firstLight: "first-light"
        case .ribbonCrossing: "ribbon-crossing"
        }
    }
    var wonGuideID: String {
        switch self {
        case .firstLight: "guide.won"
        case .ribbonCrossing: "guide.ribbon-won"
        }
    }
    var welcomeIdentifier: String {
        switch self {
        case .firstLight: "sky.firstLight"
        case .ribbonCrossing: "sky.ribbon-crossing"
        }
    }
    var menuIdentifier: String {
        switch self {
        case .firstLight: "experiment.challenge"
        case .ribbonCrossing: "experiment.ribbon-crossing"
        }
    }
    var restorationIdentifier: String {
        switch self {
        case .firstLight: "lantern.restoration"
        case .ribbonCrossing: "ribbon.restoration"
        }
    }
    var locationTitle: String { copy(.lanternTitle, .ribbonTitle) }
    var welcomeTitle: String { copy(.welcomeChallenge, .ribbonTitle) }
    var actionLabel: String { copy(.actionFirstLight, .actionRibbonCrossing) }
    var replayLabel: String { copy(.actionReplayFirstLight, .actionReplayRibbonCrossing) }
    var menuLabel: String { copy(.menuFirstLight, .menuRibbonCrossing) }
    var menuHint: String { copy(.menuFirstLightHint, .menuRibbonCrossingHint) }
    var entryKicker: String { copy(.flowFirstLight, .flowRibbonCrossing) }
    var completionKicker: String { copy(.flowComplete, .flowRibbonComplete) }
    var restoredTitle: String { copy(.flowWon, .flowRibbonWon) }
    var resultReason: String { copy(.resultWon, .resultRibbonWon) }
    var helpTitle: String { copy(.helpChallengeTitle, .helpRibbonTitle) }
    var helpText: String { copy(.helpChallenge, .helpRibbon) }

    func restorationLabel(progress: StarlightRestoration) -> String {
        copy(.lanternRestoration, .ribbonRestoration,
             values: ["percent": String(Int((progress.fraction * 100).rounded()))])
    }

    private func copy(_ firstLight: SkyCopy.Key, _ ribbonCrossing: SkyCopy.Key, values: [String: String] = [:]) -> String {
        let key: SkyCopy.Key
        switch self {
        case .firstLight: key = firstLight
        case .ribbonCrossing: key = ribbonCrossing
        }
        return SkyCopy.text(key, values: values)
    }
}
