/// A presentation value derived from committed challenge progress, never saved separately.
public struct StarlightRestoration: Equatable, Sendable {
    public enum Milestone: Int, CaseIterable, Sendable {
        case unrestored = 0
        case quarter = 25
        case half = 50
        case threeQuarters = 75
        case complete = 100
    }

    /// Retain the actual score, including a final clear that exceeds the target.
    public let score: Int
    public let target: Int

    public init(score: Int, target: Int) {
        precondition(target > 0, "A restoration target must be positive")
        self.score = score
        self.target = target
    }

    public var fraction: Double {
        Double(min(target, max(0, score))) / Double(target)
    }

    public var milestone: Milestone {
        if score >= target { return .complete }
        // Ceiling thresholds keep a milestone from appearing before it is earned.
        // Divide before adding so a large valid target cannot overflow.
        if score >= target - target / 4 { return .threeQuarters }
        if score >= target / 2 + target % 2 { return .half }
        if score >= target / 4 + (target % 4 == 0 ? 0 : 1) { return .quarter }
        return .unrestored
    }
}

extension FallingSky {
    public var restoration: StarlightRestoration? {
        challenge.map { StarlightRestoration(score: score, target: $0.target) }
    }
}
