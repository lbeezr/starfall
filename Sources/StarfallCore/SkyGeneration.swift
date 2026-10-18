/// Saved rules identity, independent from the app's persistence envelope.
/// Missing historical markers retain legacy generation, including after replay.
public enum SkyGeneration: Int, Codable, Equatable, Sendable {
    case legacy = 0
    case opalStorms = 1

    case gravityOrbits = 2
    case gravityOpportunities = 3
    // Production retirement: Opal/storms remain, historical gravity accounting may survive a migrated save.
    case standardSky = 4

    public var supportsGravity: Bool { self == .gravityOrbits || self == .gravityOpportunities }
    public func offersMagneticPair(at shower: Int) -> Bool {
        guard shower > 0 else { return false }
        return self == .gravityOrbits ? shower % 12 == 8
            : self == .gravityOpportunities && (shower % 12 == 7 || shower % 12 == 8)
    }

    public static let current = SkyGeneration.standardSky

    public func phase(for shower: Int) -> SkyShowerPhase? {
        guard self != .legacy, shower > 0 else { return nil }
        let position = (shower - 1) % 12
        return position < 9 ? .calm(remaining: 9 - position) : .storm(remaining: 12 - position)
    }
}

public enum SkyShowerPhase: Equatable, Sendable {
    case calm(remaining: Int)
    case storm(remaining: Int)

    public var isStorm: Bool {
        if case .storm = self { return true }
        return false
    }
}
