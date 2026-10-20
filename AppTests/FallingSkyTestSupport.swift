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
    private static func record(_ challenge: StarfallChallenge, moves: [[(Int, Int)]],
                               expectedScore: Int, expectedShowers: Int) -> [[Step]] {
        var game = FallingSky(definition: StoryChallengeDefinition(challenge, revision: 3)!)
        var waves: [[Step]] = []
        for moves in moves {
            var steps: [Step] = []
            for (from, to) in moves {
                let source = Cell(from / 7, from % 7), destination = Cell(to / 7, to % 7)
                steps.append(Step(before: game, action: (source, destination)))
                guard game.nudge(from: source, to: destination) != nil else {
                    XCTFail("Recorded story swap became invalid at shower \(game.turns)")
                    return []
                }
                XCTAssertTrue(game.isValidSave)
            }
            if !game.isOver {
                steps.append(Step(before: game, action: nil))
                XCTAssertNotNil(game.letStarsFall())
                XCTAssertTrue(game.isValidSave)
            }
            waves.append(steps)
        }
        XCTAssertEqual(game.outcome, .won)
        XCTAssertEqual(game.displayScore, expectedScore)
        XCTAssertEqual(game.turns, expectedShowers)
        return waves
    }
    private static let lantern = record(.firstLight, moves: [
        [(8, 9), (5, 12), (17, 18), (7, 8)],
        [(1, 2), (7, 8), (17, 16), (0, 7)],
        [(18, 19), (18, 17), (10, 17), (12, 13)],
        [(11, 12), (9, 10), (4, 11), (11, 12)],
        [(16, 17), (3, 4), (10, 11), (0, 1)],
        [(15, 16), (28, 29), (1, 8), (15, 22)],
        [(8, 9), (2, 3), (1, 2), (12, 11)],
        [(5, 6), (4, 5), (16, 17), (19, 18)],
        [(2, 3), (34, 33), (12, 19), (3, 4)],
        [(0, 1), (4, 5), (7, 8), (1, 2)],
        [(10, 11), (7, 8), (8, 9)],
        [(18, 17), (15, 16), (1, 2), (3, 4)],
        [(3, 2), (18, 17), (11, 10), (10, 9)],
        [(33, 32), (12, 13), (34, 33), (26, 33)],
        [(19, 26), (12, 19), (27, 34), (10, 11)],
        [(4, 5), (34, 33)],
        [(20, 19), (3, 10), (11, 12), (15, 16)],
        [(2, 9), (7, 14), (7, 8), (35, 36)],
        [(10, 11), (7, 8), (8, 9), (28, 29)],
        [(28, 29)],
        [(12, 19), (4, 5), (4, 11), (11, 18)],
        [(5, 6), (6, 13), (10, 11), (12, 13)],
        [(0, 1), (1, 8), (17, 16), (15, 16)]
    ], expectedScore: 154_000, expectedShowers: 22)
    private static let ribbon = record(.ribbonCrossing, moves: [
        [(8, 9), (11, 12), (18, 19), (5, 6)],
        [(3, 10), (10, 11)],
        [],
        [(7, 8), (10, 11), (9, 10)],
        [(21, 22), (14, 15), (17, 16), (10, 9)],
        [(8, 9), (9, 10), (12, 19), (11, 12)],
        [(26, 27), (26, 25), (19, 20), (34, 33)],
        [(19, 20), (20, 27), (3, 4), (4, 5)],
        [(5, 12), (4, 5), (1, 8), (1, 2)],
        [(2, 3), (14, 15), (8, 15), (15, 22)],
        [(3, 10), (3, 4), (7, 14), (1, 8)],
        [(4, 3), (2, 3), (1, 2), (3, 4)],
        [(2, 9), (7, 8), (8, 9), (26, 25)],
        [(2, 3), (5, 6), (4, 5), (19, 26)],
        [(13, 20), (20, 27), (23, 24), (3, 4)],
        [(10, 11), (23, 22), (1, 2), (3, 4)],
        [(2, 3), (24, 25), (13, 20), (20, 19)],
        [(4, 11), (27, 26), (3, 10), (19, 18)],
        [(5, 12), (9, 10), (13, 12), (12, 11)],
        [(16, 17), (10, 11), (11, 12), (9, 10)],
        [(0, 7), (7, 8)],
        [(14, 15), (8, 15), (12, 11), (10, 11)],
        [(9, 10), (8, 9), (9, 16), (8, 9)],
        [(9, 10), (27, 26), (4, 11), (18, 19)],
        [(27, 26), (26, 25), (9, 10), (11, 18)],
        [(19, 18), (11, 10), (4, 5), (3, 4)],
        [(15, 16), (9, 10), (3, 4)],
        [(0, 1), (2, 3), (4, 5), (5, 6)],
        [(4, 11), (4, 5)],
        [(21, 22), (0, 1), (3, 4), (3, 10)],
        [(10, 9), (11, 12), (6, 13), (20, 27)],
        [(13, 20), (1, 2), (2, 3), (14, 15)],
        [(0, 7), (7, 14)]
    ], expectedScore: 220_000, expectedShowers: 32)
}
