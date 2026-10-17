/// Saved rules identity, independent from the app's persistence envelope.
/// Missing historical markers retain legacy generation, including after replay.
public enum SkyGeneration: Int, Codable, Equatable, Sendable {
    case legacy = 0
    case opalStorms = 1

    public static let current = SkyGeneration.opalStorms

    public func phase(for shower: Int) -> SkyShowerPhase? {
        guard self == .opalStorms, shower > 0 else { return nil }
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
