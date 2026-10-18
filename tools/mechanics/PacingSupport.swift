// Test-only macOS substitutes. The production Store and trace intent compile unchanged.
import Foundation
import StarfallCore
@MainActor final class GameFeedback: FallingSkyFeedbackProviding {
    func stopSounds() {}
    func announce(_ text: String) {}
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {}
}
@MainActor final class FallingSkyScene: FallingSkyPresenting {
    var reduceMotion = false
    var decorativeMotionActive = false
    var onLayout: (() -> Void)?
    var onReadinessChanged: ((Bool) -> Void)?
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky, completion: @escaping () -> Void) { fatalError("Injected presenter required") }
}
@MainActor final class PacingClock: FallingSkyRainScheduling {
    var now = 0.0
    var deadline: Double?
    var action: (@MainActor () -> Void)?
    func schedule(after delay: Double, action: @escaping @MainActor () -> Void) { deadline = now + delay; self.action = action }
    func cancel() { deadline = nil; action = nil }
    func fire() { let callback = action; cancel(); callback?() }
}
@MainActor final class PacingPresenter: FallingSkyPresenting {
    private struct Presentation {
        let finishAt: Double
        let completion: () -> Void
    }
    var reduceMotion = false
    private var presentations: [Presentation] = []
    var finishAt: Double? { presentations.map(\.finishAt).min() }
    var pendingCount: Int { presentations.count }
    private(set) var maximumPendingCount = 0
    var growthEvents = 0
    var blockedArrivals = 0
    let clock: PacingClock
    init(_ clock: PacingClock, quiet: Bool) { self.clock = clock; reduceMotion = quiet }
    func render(_ game: FallingSky) { presentations.removeAll() }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky, completion: @escaping () -> Void) {
        growthEvents += turn.arrivals.filter(\.grew).count
        if turn.blockedColumn != nil { blockedArrivals += 1 }
        let duration = reduceMotion ? PacingDuration.quiet : turn.arrivals.isEmpty && turn.blockedColumn == nil ? PacingDuration.clearDuration : PacingDuration.flightDuration + PacingDuration.arrivalStagger * Double(max(0, turn.arrivals.count - 1)) + PacingDuration.landingDuration
        presentations.append(.init(finishAt: clock.now + duration, completion: completion))
        maximumPendingCount = max(maximumPendingCount, presentations.count)
    }
    func finish() {
        guard let index = presentations.indices.min(by: { presentations[$0].finishAt < presentations[$1].finishAt }) else { return }
        // Remove before invoking: the store may synchronously present deferred rain.
        let presentation = presentations.remove(at: index)
        presentation.completion()
    }
}
