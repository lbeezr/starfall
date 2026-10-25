import Foundation

/// Island followers and retained historical straight sampling finish, then fade at the endpoint.
/// Presentation only: never schedules, advances or holds a core shower.
enum SkyTrailMotion {
    struct Sample: Equatable {
        let position: Double
        let opacity: Double
    }
    static func sample(progress: Double, index: Int, count: Int, spacing: Double) -> Sample {
        guard (1...5).contains(count), (0..<count).contains(index), progress.isFinite,
              spacing.isFinite, spacing >= 0 else { return Sample(position: 0, opacity: 0) }
        let p = min(1, max(0, progress))
        let start = min(0.75, Double(count - 1 - index) * spacing)
        // A short endpoint dwell/fade precedes the deadline; no star disappears en route.
        let finish = 0.96 - Double(count - 1 - index) * 0.045
        return Sample(position: start + (1 - start) * min(1, p / finish),
                      opacity: max(0, 1 - max(0, p - finish) / 0.035))
    }
}
