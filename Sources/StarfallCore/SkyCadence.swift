/// Persisted production timing versions; existing rounds retain their saved contract.
public enum SkyCadenceID: String, Codable, Equatable, Sendable {
    case originalV1
    case openingV1
    case announcedCycleV1
    case announcedCycleV2

    public var isAnnouncedCycle: Bool { self == .announcedCycleV1 || self == .announcedCycleV2 }

    /// The interval after `committedShowers`, leading to shower `committedShowers + 1`.
    /// Manual showers count; clears, elapsed time and presentation do not.
    public func step(committedShowers: Int, pace: StarfallBalance.Pace) -> SkyCadenceStep {
        precondition(committedShowers >= 0)
        if self != .originalV1 && committedShowers < 4 {
            return SkyCadenceStep(delay: committedShowers == 0 ? 0.25 : 1.8, phase: .opening)
        }
        // Gentle and steady remain explicit fixed-pace choices.
        guard isAnnouncedCycle, pace == .brisk else {
            return SkyCadenceStep(delay: Double(pace.rawValue), phase: .steady)
        }
        let slot = (committedShowers - 4) % 12
        if self == .announcedCycleV2 {
            switch slot {
            case 0...5: return .init(delay: 2, phase: .steady, warnsFasterNext: slot == 5)
            case 6...8: return .init(delay: 1.7, phase: .faster)
            default: return .init(delay: 2.5, phase: .breathing)
            }
        }
        switch slot {
        case 0...5: return .init(delay: 3, phase: .steady, warnsFasterNext: slot == 5)
        case 6...8: return .init(delay: 2.5, phase: .faster)
        default: return .init(delay: 3.5, phase: .breathing)
        }
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
