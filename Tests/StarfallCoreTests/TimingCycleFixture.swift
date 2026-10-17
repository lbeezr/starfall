#if canImport(StarfallCore)
import StarfallCore
#endif

/// Timing-only candidate B v1. Never linked into the app or persisted in normal saves.
/// Its identity and action log are external test-fixture metadata.
enum TimingCycleFixture {
    static let identity = "announcedCycleV1"

    static func step(committedShowers: Int, pace: StarfallBalance.Pace = .brisk) -> SkyCadenceStep {
        let baseline = SkyCadenceID.openingV1.step(committedShowers: committedShowers, pace: pace)
        guard committedShowers >= 4, pace == .brisk else { return baseline }
        let slot = (committedShowers - 4) % 12
        switch slot {
        case 0...5: return .init(delay: 3, phase: .steady, warnsFasterNext: slot == 5)
        case 6...8: return .init(delay: 2.5, phase: .faster)
        default: return .init(delay: 3.5, phase: .breathing)
        }
    }
}

