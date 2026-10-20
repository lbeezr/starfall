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
        case .silverPools: .silverPools
        case .frostfruitOrchard: .frostfruitOrchard
        }
    }
    var dialoguePrefix: String {
        switch self {
        case .firstLight: "first-light"
        case .ribbonCrossing: "ribbon-crossing"
        case .kiteHarbor: "kite-harbor"
        case .seedMoon: "seed-moon"
        case .silverPools: "silver-pools"
        case .frostfruitOrchard: "frostfruit-orchard"
        }
    }
    var wonGuideID: String {
        switch self {
        case .firstLight: "guide.won"
        case .ribbonCrossing: "guide.ribbon-won"
        case .kiteHarbor: "guide.kite-won"
        case .seedMoon: "guide.seed-won"
        case .silverPools: "guide.silver-won"
        case .frostfruitOrchard: "guide.frostfruit-won"
        }
    }
    var welcomeIdentifier: String {
        switch self {
        case .firstLight: "sky.firstLight"
        case .ribbonCrossing: "sky.ribbon-crossing"
        case .kiteHarbor: "sky.kite-harbor"
        case .seedMoon: "sky.seed-moon"
        case .silverPools: "sky.silver-pools"
        case .frostfruitOrchard: "sky.frostfruit-orchard"
        }
    }
    var menuIdentifier: String {
        switch self {
        case .firstLight: "experiment.challenge"
        case .ribbonCrossing: "experiment.ribbon-crossing"
        case .kiteHarbor: "experiment.kite-harbor"
        case .seedMoon: "experiment.seed-moon"
        case .silverPools: "experiment.silver-pools"
        case .frostfruitOrchard: "experiment.frostfruit-orchard"
        }
    }
    var restorationIdentifier: String {
        switch self {
        case .firstLight: "lantern.restoration"
        case .ribbonCrossing: "ribbon.restoration"
        case .kiteHarbor: "kite.restoration"
        case .seedMoon: "seed.restoration"
        case .silverPools: "silver.restoration"
        case .frostfruitOrchard: "frostfruit.restoration"
        }
    }
    #if DEBUG
    var restorationReviewArgumentPrefix: String {
        switch self {
        case .firstLight: "--lantern-restoration-review="
        case .ribbonCrossing: "--ribbon-restoration-review="
        case .kiteHarbor: "--kite-restoration-review="
        case .seedMoon: "--seed-restoration-review="
        case .silverPools: "--silver-restoration-review="
        case .frostfruitOrchard: "--frostfruit-restoration-review="
        }
    }
    #endif

    var locationTitle: String { copy(.lanternTitle, .ribbonTitle, .kiteTitle, .seedTitle, .silverTitle, .frostfruitTitle) }
    var welcomeTitle: String { copy(.welcomeChallenge, .ribbonTitle, .kiteTitle, .seedTitle, .silverTitle, .frostfruitTitle) }
    var actionLabel: String { copy(.actionFirstLight, .actionRibbonCrossing, .actionKiteHarbor, .actionSeedMoon, .actionSilverPools, .actionFrostfruitOrchard) }
    var replayLabel: String { copy(.actionReplayFirstLight, .actionReplayRibbonCrossing, .actionReplayKiteHarbor, .actionReplaySeedMoon, .actionReplaySilverPools, .actionReplayFrostfruitOrchard) }
    var menuLabel: String { copy(.menuFirstLight, .menuRibbonCrossing, .menuKiteHarbor, .menuSeedMoon, .menuSilverPools, .menuFrostfruitOrchard) }
    var menuHint: String { copy(.menuFirstLightHint, .menuRibbonCrossingHint, .menuKiteHarborHint, .menuSeedMoonHint, .menuSilverPoolsHint, .menuFrostfruitOrchardHint) }
    var entryKicker: String { copy(.flowFirstLight, .flowRibbonCrossing, .flowKiteHarbor, .flowSeedMoon, .flowSilverPools, .flowFrostfruitOrchard) }
    var completionKicker: String { copy(.flowComplete, .flowRibbonComplete, .flowKiteComplete, .flowSeedComplete, .flowSilverComplete, .flowFrostfruitComplete) }
    var restoredTitle: String { copy(.flowWon, .flowRibbonWon, .flowKiteWon, .flowSeedWon, .flowSilverWon, .flowFrostfruitWon) }
    var resultReason: String { copy(.resultWon, .resultRibbonWon, .resultKiteWon, .resultSeedWon, .resultSilverWon, .resultFrostfruitWon) }
    var helpTitle: String { copy(.helpChallengeTitle, .helpRibbonTitle, .helpKiteTitle, .helpSeedTitle, .helpSilverTitle, .helpFrostfruitTitle) }
    var helpText: String { copy(.helpChallenge, .helpRibbon, .helpKite, .helpSeed, .helpSilver, .helpFrostfruit) }

    func restorationLabel(progress: StarlightRestoration) -> String {
        copy(.lanternRestoration, .ribbonRestoration, .kiteRestoration, .seedRestoration, .silverRestoration, .frostfruitRestoration,
             values: ["percent": String(Int((progress.fraction * 100).rounded()))])
    }

    private func copy(_ firstLight: SkyCopy.Key, _ ribbonCrossing: SkyCopy.Key, _ kiteHarbor: SkyCopy.Key, _ seedMoon: SkyCopy.Key, _ silverPools: SkyCopy.Key, _ frostfruitOrchard: SkyCopy.Key, values: [String: String] = [:]) -> String {
        let key: SkyCopy.Key
        switch self {
        case .firstLight: key = firstLight
        case .ribbonCrossing: key = ribbonCrossing
        case .kiteHarbor: key = kiteHarbor
        case .seedMoon: key = seedMoon
        case .silverPools: key = silverPools
        case .frostfruitOrchard: key = frostfruitOrchard
        }
        return SkyCopy.text(key, values: values)
    }
}
