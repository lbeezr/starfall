import Foundation
import XCTest
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
    if !game.supportsManualClears { return StoryPatternWitness.choice(for: game) }
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


/// Recorded revision-three playthroughs keep lifecycle tests cheap and deterministic.
/// Every snapshot is reconstructed with production swaps/showers, never injected state.
/// A choice is returned only at its exact witnessed prefix; nil requests the next shower.
private enum StoryPatternWitness {
    private struct Step: Sendable {
        let before: FallingSky
        let action: (Cell, Cell)?
    }
    static func choice(for game: FallingSky) -> (Cell, Cell?)? {
        guard game.challengeRevision == 3 else { return nil }
        let waves = game.challenge == .firstLight ? lantern : ribbon
        guard waves.indices.contains(game.turns),
              let step = waves[game.turns].first(where: { $0.before == game }),
              let action = step.action else { return nil }
        return (action.0, action.1)
    }
    private static func record(_ challenge: StarfallChallenge, plan: StoryPatternPlan) -> [[Step]] {
        var game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: 3)!)
        var waves: [[Step]] = []
        var exchangeCount = 0
        XCTAssertEqual(game.displayTarget, plan.target)
        for moves in plan.waves {
            var steps: [Step] = []
            for exchange in moves {
                let source = Cell(exchange.from / 7, exchange.from % 7)
                let destination = Cell(exchange.to / 7, exchange.to % 7)
                steps.append(Step(before: game, action: (source, destination)))
                guard game.nudge(from: source, to: destination) != nil else {
                    XCTFail("Recorded story swap became invalid at shower \(game.turns)")
                    return []
                }
                XCTAssertTrue(game.isValidSave)
                exchangeCount += 1
            }
            if !game.isOver {
                steps.append(Step(before: game, action: nil))
                XCTAssertNotNil(game.letStarsFall())
                XCTAssertTrue(game.isValidSave)
            }
            waves.append(steps)
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, plan.expectedScore)
        XCTAssertEqual(game.turns, plan.expectedShowers)
        XCTAssertEqual(exchangeCount, plan.expectedExchanges)
        return waves
    }
    private static let lantern = record(.firstLight, plan: .lantern)
    private static let ribbon = record(.ribbonCrossing, plan: .ribbon)
}
