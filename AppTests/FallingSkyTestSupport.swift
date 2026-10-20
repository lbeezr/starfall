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
    var bufferedCue: SkyPlayerInput?
    func showBufferedInput(_ action: SkyPlayerInput?) { bufferedCue = action }
    func render(_ game: FallingSky) { lastRendered = game }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky,
                 to game: FallingSky, completion: @escaping () -> Void) {
        completions.append(completion)
    }
    func finish() { completions.last?() }
}


@MainActor final class SkyFeedbackRecorder: FallingSkyFeedbackProviding {
    var armedPreferences: [Bool] = []
    func traceArmed(enabled: Bool) { armedPreferences.append(enabled) }
    var clears = 0, stops = 0
    var announcements: [String] = []
    var sound = false, haptics = false
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        clears += 1; sound = soundEnabled; haptics = hapticsEnabled
    }
    func announce(_ message: String) { announcements.append(message) }
    func stopSounds() { stops += 1 }
}


/// Deterministic player for lifecycle/snapshot wins; production rules choose each result.
func storyScoringChoice(_ game: FallingSky) -> (Cell, Cell?)? {
    var best: (Cell, Cell?, Int, Int)?
    func consider(_ from: Cell, _ to: Cell?, _ points: Int, _ count: Int) {
        if best == nil || points > best!.2 || (points == best!.2 && count > best!.3) {
            best = (from, to, points, count)
        }
    }
    for group in game.legalGroups {
        var next = game
        let turn = next.clear(group[0])!
        consider(group[0], nil, turn.displayAward, group.count)
    }
    for setup in [false, true] {
        if setup && best != nil { break }
        for row in 0..<7 { for column in 0..<7 {
            let from = Cell(row, column)
            guard let gem = game.gem(at: from) else { continue }
            for to in [Cell(row, column + 1), Cell(row + 1, column)] {
                guard let other = game.gem(at: to), gem.kind != other.kind || gem.grown != other.grown else { continue }
                var next = game
                guard let turn = next.nudge(from: from, to: to) else { continue }
                if !setup, turn.displayAward > 0 {
                    consider(from, to, turn.displayAward, turn.award!.clearedStarCount)
                } else if setup {
                    for group in next.legalGroups {
                        var future = next
                        consider(from, to, future.clear(group[0])!.displayAward, group.count)
                    }
                }
            }
        } }
    }
    return best.map { ($0.0, $0.1) }
}
