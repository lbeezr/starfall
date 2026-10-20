/// Authored round identities and rules. WorldJourney owns access separately.
public enum StarfallChallenge: String, Codable, CaseIterable, Equatable, Sendable {
    case firstLight, ribbonCrossing, kiteHarbor, seedMoon, silverPools, frostfruitOrchard

    public var title: String {
        switch self {
        case .firstLight: "First Light"
        case .ribbonCrossing: "Ribbon Crossing"
        case .kiteHarbor: "Kite Harbor"
        case .seedMoon: "Seed Moon"
        case .silverPools: "Silver Pools"
        case .frostfruitOrchard: "Frostfruit Orchard"
        }
    }
    /// Historical unversioned contract. Revised rounds expose their saved displayTarget.
    public var target: Int { 18 }
    public var seed: UInt64 { 42 }
    public var balance: StarfallBalance { .init(pace: .steady, darkStars: .none) }

    public func outcome(score: Int, overflowed: Bool) -> Outcome {
        if score >= target { return .won }
        return overflowed ? .lost : .playing
    }
}
