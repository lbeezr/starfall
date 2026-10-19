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
        case .kiteHarbor: .kiteHarbor
        case .seedMoon: .seedMoon
        }
    }
    var dialoguePrefix: String {
        switch self {
        case .firstLight: "first-light"
        case .ribbonCrossing: "ribbon-crossing"
        case .kiteHarbor: "kite-harbor"
        case .seedMoon: "seed-moon"
        }
    }
    var wonGuideID: String {
        switch self {
        case .firstLight: "guide.won"
        case .ribbonCrossing: "guide.ribbon-won"
        case .kiteHarbor: "guide.kite-won"
        case .seedMoon: "guide.seed-won"
        }
    }
    var welcomeIdentifier: String {
        switch self {
        case .firstLight: "sky.firstLight"
        case .ribbonCrossing: "sky.ribbon-crossing"
        case .kiteHarbor: "sky.kite-harbor"
        case .seedMoon: "sky.seed-moon"
        }
    }
    var menuIdentifier: String {
        switch self {
        case .firstLight: "experiment.challenge"
        case .ribbonCrossing: "experiment.ribbon-crossing"
        case .kiteHarbor: "experiment.kite-harbor"
        case .seedMoon: "experiment.seed-moon"
        }
    }
    var restorationIdentifier: String {
        switch self {
        case .firstLight: "lantern.restoration"
        case .ribbonCrossing: "ribbon.restoration"
        case .kiteHarbor: "kite.restoration"
        case .seedMoon: "seed.restoration"
        }
    }
    #if DEBUG
    var restorationReviewArgumentPrefix: String {
        switch self {
        case .firstLight: "--lantern-restoration-review="
        case .ribbonCrossing: "--ribbon-restoration-review="
        case .kiteHarbor: "--kite-restoration-review="
        case .seedMoon: "--seed-restoration-review="
        }
    }
    #endif

    var locationTitle: String { copy(.lanternTitle, .ribbonTitle, .kiteTitle, .seedTitle) }
    var welcomeTitle: String { copy(.welcomeChallenge, .ribbonTitle, .kiteTitle, .seedTitle) }
    var actionLabel: String { copy(.actionFirstLight, .actionRibbonCrossing, .actionKiteHarbor, .actionSeedMoon) }
    var replayLabel: String { copy(.actionReplayFirstLight, .actionReplayRibbonCrossing, .actionReplayKiteHarbor, .actionReplaySeedMoon) }
    var menuLabel: String { copy(.menuFirstLight, .menuRibbonCrossing, .menuKiteHarbor, .menuSeedMoon) }
    var menuHint: String { copy(.menuFirstLightHint, .menuRibbonCrossingHint, .menuKiteHarborHint, .menuSeedMoonHint) }
    var entryKicker: String { copy(.flowFirstLight, .flowRibbonCrossing, .flowKiteHarbor, .flowSeedMoon) }
    var completionKicker: String { copy(.flowComplete, .flowRibbonComplete, .flowKiteComplete, .flowSeedComplete) }
    var restoredTitle: String { copy(.flowWon, .flowRibbonWon, .flowKiteWon, .flowSeedWon) }
    var resultReason: String { copy(.resultWon, .resultRibbonWon, .resultKiteWon, .resultSeedWon) }
    var helpTitle: String { copy(.helpChallengeTitle, .helpRibbonTitle, .helpKiteTitle, .helpSeedTitle) }
    var helpText: String { copy(.helpChallenge, .helpRibbon, .helpKite, .helpSeed) }

    func restorationLabel(progress: StarlightRestoration) -> String {
        copy(.lanternRestoration, .ribbonRestoration, .kiteRestoration, .seedRestoration,
             values: ["percent": String(Int((progress.fraction * 100).rounded()))])
    }

    private func copy(_ firstLight: SkyCopy.Key, _ ribbonCrossing: SkyCopy.Key, _ kiteHarbor: SkyCopy.Key, _ seedMoon: SkyCopy.Key, values: [String: String] = [:]) -> String {
        let key: SkyCopy.Key
        switch self {
        case .firstLight: key = firstLight
        case .ribbonCrossing: key = ribbonCrossing
        case .kiteHarbor: key = kiteHarbor
        case .seedMoon: key = seedMoon
        }
        return SkyCopy.text(key, values: values)
    }
}
