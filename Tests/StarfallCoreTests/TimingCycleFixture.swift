#if canImport(StarfallCore)
import StarfallCore
#endif

/// Historical tool/test name retained as a thin adapter to the adopted Core rule.
/// No independent candidate algorithm or production selection route remains.
enum TimingCycleFixture {
    static let identity = SkyCadenceID.announcedCycleV1.rawValue

    static func step(committedShowers: Int, pace: StarfallBalance.Pace = .brisk) -> SkyCadenceStep {
        SkyCadenceID.announcedCycleV1.step(committedShowers: committedShowers, pace: pace)
    }
}
