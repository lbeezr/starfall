import StarfallCore

/// A completed place admitted by the durable journey, independent of whichever
/// round is retained. It contains no game, earned score or action capability.
struct SkyRestoredPlaceSnapshot: Hashable, Identifiable {
    let location: WorldLocation
    var id: WorldLocation { location }
    var challenge: StarfallChallenge { .firstLight }

    /// The normalized pair selects the existing complete painting. It is not a
    /// reconstructed score, target or winning round.
    var presentation: RestorationPresentation {
        RestorationPresentation(challenge: challenge, progress: StarlightRestoration(score: 1, target: 1))
    }

    init?(location: WorldLocation, journey: WorldJourney) {
        guard location == .firstLight, journey.selected == location,
              journey.completed.contains(location) else { return nil }
        self.location = location
    }

    func matches(_ journey: WorldJourney) -> Bool {
        Self(location: location, journey: journey) != nil
    }
}
