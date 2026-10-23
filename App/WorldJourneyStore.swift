import Foundation
import Observation
import StarfallCore

@MainActor @Observable final class WorldJourneyStore {
    static let key = "starfall.world.v1"
    static let rejectedKey = "starfall.world.rejected"
    private struct Envelope: Codable { let version: Int; let journey: WorldJourney }
    private(set) var journey: WorldJourney
    private(set) var recovered = false
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var rejected: Any?

    /// Read only. A committed round repairs an interrupted completion write.
    init(defaults: UserDefaults, ignoreSaved: Bool = false) {
        self.defaults = defaults
        let saved = ignoreSaved ? nil : SkySaveArchive.load(from: defaults)
        let priorInstall = !ignoreSaved && defaults.object(forKey: SkySaveArchive.key) == nil
            && defaults.object(forKey: SkySaveArchive.preMasteryKey) == nil
            && defaults.object(forKey: SkySaveArchive.frostfruitEncounterKey) == nil
            && defaults.object(forKey: SkySaveArchive.ribbonFullBoardKey) == nil
            && defaults.object(forKey: SkySaveArchive.revisedFullBoardKey) == nil
            && defaults.object(forKey: SkySaveArchive.fullBoardKey) == nil
            && defaults.object(forKey: SkySaveArchive.fourLineKey) == nil
            && defaults.object(forKey: SkySaveArchive.patternKey) == nil
            && defaults.object(forKey: SkySaveArchive.cascadeKey) == nil
            && defaults.object(forKey: SkySaveArchive.storyKey) == nil
            && defaults.object(forKey: SkySaveArchive.worldKey) == nil && saved != nil
        if !ignoreSaved, let raw = defaults.object(forKey: Self.key) {
            if let data = raw as? Data,
               let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
               envelope.version == 1, envelope.journey.isValid {
                journey = envelope.journey
            } else {
                rejected = raw; recovered = true
                journey = WorldJourney(legacyAccess: priorInstall)
            }
        } else {
            // A current-format round alone is not evidence of pre-world access.
            journey = WorldJourney(legacyAccess: priorInstall)
        }
        if let saved { journey.record(saved) }
    }

    func select(_ location: WorldLocation) throws {
        var next = journey; next.select(location)
        try persist(next)
    }

    #if DEBUG
    /// Reset-only native tests model an existing installation's access.
    func useLegacyReviewAccess() { journey = WorldJourney(legacyAccess: true) }

    /// A validated completed review round earns access through the production rule.
    /// Construction remains read-only; the isolated review save commits on activation.
    func useReviewCompletion(_ game: FallingSky) { journey.record(game) }
    #endif

    /// Called after the round archive succeeds, before any result/travel animation.
    func record(_ game: FallingSky) throws {
        var next = journey; next.record(game)
        try persist(next)
    }

    private func persist(_ next: WorldJourney) throws {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(Envelope(version: 1, journey: next))
        if let rejected { defaults.set(rejected, forKey: Self.rejectedKey); self.rejected = nil }
        defaults.set(data, forKey: Self.key)
        journey = next
    }
}
