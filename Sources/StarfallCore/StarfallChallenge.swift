/// Directly selectable authored rounds, without campaign or unlock state.
public enum StarfallChallenge: String, Codable, CaseIterable, Equatable, Sendable {
    case firstLight, ribbonCrossing

    public var title: String {
        switch self {
        case .firstLight: "First Light"
        case .ribbonCrossing: "Ribbon Crossing"
        }
    }
    public var target: Int { 18 }
    public var seed: UInt64 { 42 }
    public var balance: StarfallBalance { .init(pace: .steady, darkStars: .none) }

    public func outcome(score: Int, overflowed: Bool) -> Outcome {
        if score >= target { return .won }
        return overflowed ? .lost : .playing
    }
}
