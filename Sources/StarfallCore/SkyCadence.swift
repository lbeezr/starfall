/// Persisted production timing versions. Experimental policies belong in test support.
public enum SkyCadenceID: String, Codable, Equatable, Sendable {
    case originalV1
    case openingV1

    /// The interval after `committedShowers`, leading to shower `committedShowers + 1`.
    /// Manual showers count; clears, elapsed time and presentation do not.
    public func step(committedShowers: Int, pace: StarfallBalance.Pace) -> SkyCadenceStep {
        precondition(committedShowers >= 0)
        if self == .openingV1 && committedShowers < 4 {
            return SkyCadenceStep(delay: committedShowers == 0 ? 0.25 : 1.8, phase: .opening)
        }
        return SkyCadenceStep(delay: Double(pace.rawValue), phase: .steady)
    }
}

/// A timing snapshot, never a new source of mutable phase state.
public struct SkyCadenceStep: Equatable, Sendable {
    public enum Phase: Equatable, Sendable { case opening, steady, faster, breathing }
    public let delay: Double
    public let phase: Phase
    public let warnsFasterNext: Bool

    public init(delay: Double, phase: Phase, warnsFasterNext: Bool = false) {
        self.delay = delay
        self.phase = phase
        self.warnsFasterNext = warnsFasterNext
    }
}
