import Foundation
import StarfallCore

#if DEBUG
/// Reset-only data for the normal map, store and restoration readers. This owns
/// no alternate view, access rule, asset selection or ordinary player defaults.
enum WorldMapReviewFixture: String, CaseIterable {
    case fresh, twoRepairs, allReady, locked, unbuilt, retained, recovery

    static let suiteName = "Starfall.WorldMapReview"
    static let marker = "--world-map-review"
    static let statePrefix = "--world-map-state="
    static let rejectedWorldBytes = Data("unreadable world review save".utf8)

    static func requested(arguments: [String]) -> Self? {
        guard arguments.contains("--starfalls-reset"), arguments.contains(marker) else { return nil }
        let states = arguments.filter { $0.hasPrefix(statePrefix) }
        guard states.count == 1 else { return nil }
        return Self(rawValue: String(states[0].dropFirst(statePrefix.count)))
    }

    /// Only the factory calls this after admission. The destination is fixed so
    /// a fixture can never be prepared in standard or caller-supplied defaults.
    @MainActor func prepareIsolatedDefaults() throws -> UserDefaults {
        let defaults = UserDefaults(suiteName: Self.suiteName)!
        defaults.removePersistentDomain(forName: Self.suiteName)
        let world = WorldJourneyStore(defaults: defaults)
        let repairs: [StarfallChallenge]
        switch self {
        case .twoRepairs, .retained: repairs = [.firstLight, .ribbonCrossing]
        case .allReady: repairs = StarfallChallenge.allCases
        case .recovery: repairs = [.firstLight]
        case .fresh, .locked, .unbuilt: repairs = []
        }
        for challenge in repairs {
            // These bounded repair histories deliberately retain revision 0's
            // 18-light rules. New visits still select the current definition at
            // Begin; a fixture earns each repair through an actual winning clear.
            var round = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: challenge)
            precondition(round.challengeRevision == 0 && round.displayTarget == 18 && round.outcome == .playing)
            let turn = round.clear(Cell(0, 0))
            precondition(turn != nil && round.isValidSave && round.outcome == .won)
            // Use the same round-before-world ordering as committed gameplay.
            try SkySaveArchive.save(round, to: defaults)
            try world.record(round)
        }
        switch self {
        case .fresh: try world.select(.firstLight)
        case .twoRepairs: try world.select(.kiteHarbor)
        case .allReady: break // Recording every repair selects the last ready location.
        case .locked: try world.select(.frostfruitOrchard)
        case .unbuilt: try world.select(.sunwheelMill)
        case .retained:
            let round = ObservatoryReviewFixture.game(dense: false, score: 9, challenge: .kiteHarbor)
            try SkySaveArchive.save(round, to: defaults)
            try world.select(.kiteHarbor)
        case .recovery:
            // The ordinary reader must recover the valid committed repair and
            // preserve these rejected bytes when the next selection is saved.
            defaults.set(Self.rejectedWorldBytes, forKey: WorldJourneyStore.key)
        }
        return defaults
    }
}
#endif
