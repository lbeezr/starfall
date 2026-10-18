// Test-only macOS substitutes. The production Store and trace intent compile unchanged.
import Foundation
import StarfallCore
@MainActor protocol FallingSkyFeedbackProviding: AnyObject {
    func stopSounds()
    func announce(_ text: String)
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool)
}
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
    var reduceMotion = false
    var finishAt: Double?
    var completion: (() -> Void)?
    var growthEvents = 0
    var blockedArrivals = 0
    let clock: PacingClock
    init(_ clock: PacingClock, quiet: Bool) { self.clock = clock; reduceMotion = quiet }
    func render(_ game: FallingSky) { finishAt = nil; completion = nil }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky, completion: @escaping () -> Void) {
        growthEvents += turn.arrivals.filter(\.grew).count
        if turn.blockedColumn != nil { blockedArrivals += 1 }
        let duration = reduceMotion ? PacingDuration.quiet : turn.arrivals.isEmpty && turn.blockedColumn == nil ? PacingDuration.clearDuration : PacingDuration.flightDuration + PacingDuration.arrivalStagger * Double(max(0, turn.arrivals.count - 1)) + PacingDuration.landingDuration
        finishAt = clock.now + duration; self.completion = completion
    }
    func finish() { let callback = completion; finishAt = nil; completion = nil; callback?() }
}
