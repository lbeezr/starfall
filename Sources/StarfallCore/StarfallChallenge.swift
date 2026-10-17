/// One authored objective for testing goal-driven play before a campaign exists.
public enum StarfallChallenge: String, Codable, Equatable, Sendable {
    case firstLight

    public var title: String { "First Light" }
    public var target: Int { 18 }
    public var seed: UInt64 { 42 }
    public var balance: StarfallBalance { .init(pace: .steady, darkStars: .none) }

    public func outcome(score: Int, overflowed: Bool) -> Outcome {
        if score >= target { return .won }
        return overflowed ? .lost : .playing
    }
}
