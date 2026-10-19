import StarfallCore

/// Selects the location's presentation without constructing or saving a replacement sky.
/// Pending entry previews start unrestored; canceling reveals the committed round again.
enum LanternLandingPresentation {
    static func selected(game: FallingSky, entry: SkyEntryRequest?) -> StarlightRestoration? {
        guard let entry else { return game.restoration }
        guard entry.isChallenge(replayingChallenge: game.challenge == .firstLight) else { return nil }
        return StarlightRestoration(score: 0, target: StarfallChallenge.firstLight.target)
    }
}
