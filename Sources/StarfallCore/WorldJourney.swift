import Foundation

/// Stable world identities. Production readiness is separate from player progress.
public enum WorldLocation: String, CaseIterable, Codable, Sendable, Identifiable {
    case firstLight, ribbonCrossing, kiteHarbor, seedMoon, silverPools
    case frostfruitOrchard, sunwheelMill, bellChoir, starferryStation, auroraFalls, petalBeacon, hollowCrown
    public var id: String { rawValue }
    public var number: Int { Self.allCases.firstIndex(of: self)! + 1 }
    public var challenge: StarfallChallenge? { StarfallChallenge(rawValue: rawValue) }
    public var predecessor: Self? { number > 1 ? Self.allCases[number - 2] : nil }
}

/// Local completion is earned only from a committed winning round. Older players
/// keep access to the five locations they could already play, without false wins.
public struct WorldJourney: Codable, Equatable, Sendable {
    public private(set) var completed: Set<WorldLocation> = []
    public private(set) var selected: WorldLocation = .firstLight
    public let legacyAccess: Bool
    // This migration preserves access to content shipped before the journey.
    // New ready locations still require their predecessor’s committed repair.
    private static let legacyLocations: Set<WorldLocation> = [
        .firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools
    ]
    public init(legacyAccess: Bool = false) { self.legacyAccess = legacyAccess }
    public func canEnter(_ location: WorldLocation) -> Bool {
        guard location.challenge != nil else { return false }
        return (legacyAccess && Self.legacyLocations.contains(location)) || completed.contains(location) || location.predecessor == nil
            || location.predecessor.map(completed.contains) == true
    }
    public mutating func select(_ location: WorldLocation) { selected = location }
    public mutating func record(_ game: FallingSky) {
        guard game.isValidSave, game.outcome == .won, let challenge = game.challenge,
              let location = WorldLocation(rawValue: challenge.rawValue) else { return }
        if completed.insert(location).inserted {
            let next = WorldLocation.allCases.dropFirst(location.number).first
            selected = next.flatMap { $0.challenge == nil ? nil : $0 } ?? location
        }
    }
    public var isValid: Bool { completed.allSatisfy { $0.challenge != nil } }
}
