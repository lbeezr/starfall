import Foundation
import StarfallCore
@testable import Starfall

@MainActor final class ManualRainClock: FallingSkyRainScheduling {
    var now: TimeInterval = 0
    var deadline: TimeInterval?
    var action: (@MainActor () -> Void)?
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {
        deadline = now + delay; self.action = action
    }
    func cancel() { deadline = nil; action = nil }
    func advance(_ duration: TimeInterval) {
        now += duration
        if let deadline, deadline <= now + 0.00001 {
            let callback = action
            cancel(); callback?()
        }
    }
}

@MainActor final class FallingSkyRecorder: FallingSkyPresenting {
    var reduceMotion = false
    var lastRendered: FallingSky?
    var completions: [() -> Void] = []
    func render(_ game: FallingSky) { lastRendered = game }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        completions.append(completion)
    }
    func finish() { completions.last?() }
}

