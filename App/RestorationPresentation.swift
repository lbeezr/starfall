import StarfallCore

/// Selects the location's presentation without committing or saving a replacement sky.
/// Pending entry previews start unrestored; canceling reveals the committed round again.
struct RestorationPresentation: Equatable {
    let challenge: StarfallChallenge
    let progress: StarlightRestoration

    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> Self? {
        if let entry {
            let preview = entry.previewGame(retaining: game)
            guard let challenge = preview.challenge, let progress = preview.restoration else { return nil }
            return Self(challenge: challenge, progress: progress)
        }
        guard let challenge = game.challenge, let progress = game.restoration else { return nil }
        return Self(challenge: challenge, progress: progress)
    }
}

extension SkyEntryRequest {
    /// One read-only rules preview for artwork, entry and help.
    func previewGame(retaining game: FallingSky) -> FallingSky {
        switch self {
        case .initial: game
        case .fresh: .freshSurvival(seed: game.seed, balance: game.balance)
        case .replay: game.replay()
        case .fullBoardLantern: .fullBoardLantern()
        case .fullBoardRibbon: .fullBoardRibbon()
        case .firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools, .frostfruitOrchard, .sunwheelMill:
            .freshChallenge(selectedChallenge(replaying: nil)!)
        }
    }
}

extension FallingSky {
    var fullBoardDialoguePrefix: String? {
        guard usesFullBoardRefill else { return nil }
        return challenge == .ribbonCrossing ? "full-board-ribbon" : "full-board-lantern"
    }

    var fullBoardRestoreGuideID: String? {
        guard usesFullBoardRefill else { return nil }
        return challenge == .ribbonCrossing ? "guide.full-board-ribbon-restore" : "guide.full-board-restore"
    }

    var fullBoardWelcomeTitle: String? {
        guard usesFullBoardRefill else { return nil }
        return SkyCopy.text(challenge == .ribbonCrossing ? .ribbonFullBoardWelcome : .fullBoardWelcome)
    }

    var automaticPatternValues: [String: String] {
        guard let automaticLineLength else { return [:] }
        return ["lines": SkyCopy.patternLines(automaticLineLength)]
    }

    var challengeGuideLine: SkyDialogueLine? {
        guard let challenge else { return nil }
        if let prefix = fullBoardDialoguePrefix {
            return SkyDialogueLibrary.line("guide." + prefix, values: ["target": SkyCopy.score(displayTarget ?? 0)])
        }
        let story = StoryChallengeDefinition(challenge, revision: challengeRevision) != nil
        let variant = !supportsManualClears ? ".patterns" : supportsAutomaticRecipes ? ".cascade" : story ? ".story" : ""
        var values = story ? ["target": SkyCopy.score(displayTarget ?? 0)] : [:]
        values.merge(automaticPatternValues) { _, new in new }
        return SkyDialogueLibrary.line("guide." + challenge.dialoguePrefix + variant, values: values)
    }

    var challengeHelpText: String? {
        guard let challenge else { return nil }
        if usesFullBoardRefill {
            return SkyCopy.text(challenge == .ribbonCrossing ? .helpFullBoardRibbonChallenge : .helpFullBoardChallenge,
                                values: ["target": SkyCopy.score(displayTarget ?? 0)])
        }
        if !supportsManualClears {
            let key: SkyCopy.Key
            switch challenge {
            case .firstLight: key = .helpPatternsChallenge
            case .ribbonCrossing: key = .helpPatternsRibbon
            case .kiteHarbor: key = .helpPatternsKite
            case .seedMoon: key = .helpPatternsSeed
            case .silverPools: key = .helpPatternsSilver
            case .frostfruitOrchard: key = .helpPatternsFrostfruit
            case .sunwheelMill:
                preconditionFailure("Missing automatic-pattern help for this challenge")
            }
            return SkyCopy.text(key,
                                values: automaticPatternValues.merging(["target": SkyCopy.score(displayTarget ?? 0)]) { _, new in new })
        }
        if supportsAutomaticRecipes {
            return SkyCopy.text(challenge == .firstLight ? .helpCascadeChallenge : .helpCascadeRibbon,
                                values: ["target": SkyCopy.score(displayTarget ?? 0)])
        }
        if StoryChallengeDefinition(challenge, revision: challengeRevision) != nil {
            return SkyCopy.text(challenge == .firstLight ? .helpStoryChallenge : .helpStoryRibbon,
                                values: ["target": SkyCopy.score(displayTarget ?? 0)])
        }
        return challenge.helpText
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
        case .sunwheelMill: .sunwheelMill
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
        case .sunwheelMill: "sunwheel-mill"
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
        case .sunwheelMill: "guide.sunwheel-won"
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
        case .sunwheelMill: "sky.sunwheel-mill"
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
        case .sunwheelMill: "experiment.sunwheel-mill"
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
        case .sunwheelMill: "sunwheel.restoration"
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
        case .sunwheelMill: "--sunwheel-restoration-review="
        }
    }
    #endif

    var locationTitle: String { copy(.lanternTitle, .ribbonTitle, .kiteTitle, .seedTitle, .silverTitle, .frostfruitTitle, .sunwheelTitle) }
    var welcomeTitle: String { copy(.welcomeChallenge, .ribbonTitle, .kiteTitle, .seedTitle, .silverTitle, .frostfruitTitle, .sunwheelTitle) }
    var actionLabel: String { copy(.actionFirstLight, .actionRibbonCrossing, .actionKiteHarbor, .actionSeedMoon, .actionSilverPools, .actionFrostfruitOrchard, .actionSunwheelMill) }
    var replayLabel: String { copy(.actionReplayFirstLight, .actionReplayRibbonCrossing, .actionReplayKiteHarbor, .actionReplaySeedMoon, .actionReplaySilverPools, .actionReplayFrostfruitOrchard, .actionReplaySunwheelMill) }
    var menuLabel: String { copy(.menuFirstLight, .menuRibbonCrossing, .menuKiteHarbor, .menuSeedMoon, .menuSilverPools, .menuFrostfruitOrchard, .menuSunwheelMill) }
    var menuHint: String { copy(.menuFirstLightHint, .menuRibbonCrossingHint, .menuKiteHarborHint, .menuSeedMoonHint, .menuSilverPoolsHint, .menuFrostfruitOrchardHint, .menuSunwheelMillHint) }
    var entryKicker: String { copy(.flowFirstLight, .flowRibbonCrossing, .flowKiteHarbor, .flowSeedMoon, .flowSilverPools, .flowFrostfruitOrchard, .flowSunwheelMill) }
    var completionKicker: String { copy(.flowComplete, .flowRibbonComplete, .flowKiteComplete, .flowSeedComplete, .flowSilverComplete, .flowFrostfruitComplete, .flowSunwheelComplete) }
    var restoredTitle: String { copy(.flowWon, .flowRibbonWon, .flowKiteWon, .flowSeedWon, .flowSilverWon, .flowFrostfruitWon, .flowSunwheelWon) }
    var resultReason: String { copy(.resultWon, .resultRibbonWon, .resultKiteWon, .resultSeedWon, .resultSilverWon, .resultFrostfruitWon, .resultSunwheelWon) }
    var helpTitle: String { copy(.helpChallengeTitle, .helpRibbonTitle, .helpKiteTitle, .helpSeedTitle, .helpSilverTitle, .helpFrostfruitTitle, .helpSunwheelTitle) }
    var helpText: String { copy(.helpChallenge, .helpRibbon, .helpKite, .helpSeed, .helpSilver, .helpFrostfruit, .helpSunwheel) }

    func restorationLabel(progress: StarlightRestoration) -> String {
        copy(.lanternRestoration, .ribbonRestoration, .kiteRestoration, .seedRestoration, .silverRestoration, .frostfruitRestoration, .sunwheelRestoration,
             values: ["percent": String(Int((progress.fraction * 100).rounded()))])
    }

    private func copy(_ firstLight: SkyCopy.Key, _ ribbonCrossing: SkyCopy.Key, _ kiteHarbor: SkyCopy.Key, _ seedMoon: SkyCopy.Key, _ silverPools: SkyCopy.Key, _ frostfruitOrchard: SkyCopy.Key, _ sunwheelMill: SkyCopy.Key, values: [String: String] = [:]) -> String {
        let key: SkyCopy.Key
        switch self {
        case .firstLight: key = firstLight
        case .ribbonCrossing: key = ribbonCrossing
        case .kiteHarbor: key = kiteHarbor
        case .seedMoon: key = seedMoon
        case .silverPools: key = silverPools
        case .frostfruitOrchard: key = frostfruitOrchard
        case .sunwheelMill: key = sunwheelMill
        }
        return SkyCopy.text(key, values: values)
    }
}
