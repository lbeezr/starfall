import Foundation
import CryptoKit

/// Offline observation only. No fields are added to the game or its save.
enum BurstExposureRecorder {
    struct Event: Codable {
        let seed: UInt64
        let shower: Int
        let changed: Bool
        let groups: Int
        let pressureColumns: [Int]
        let preparationColumns: [Int]
    }
    static var events: [Event] = []
    static func record(_ before: StarfallExperiment, pressure: [IncomingStar], preparation: [IncomingStar]) {
        events.append(.init(seed: before.seed, shower: before.turns + 1,
            changed: pressure != preparation, groups: before.legalGroups.count,
            pressureColumns: pressure.map(\.column), preparationColumns: preparation.map(\.column)))
    }
}

@main struct ShowerBurstExposure {
    struct Round: Codable {
        let seed: UInt64
        let delivered: Int
        let ended: Bool
        let score: Int
        let trajectorySHA256: String
    }
    struct Report: Codable {
        let rounds: [Round]
        let events: [BurstExposureRecorder.Event]
    }
    static func main() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        var rounds: [Round] = []
        for seed in UInt64(0)..<200 {
            var game = StarfallExperiment(seed: seed)
            var digest = SHA256()
            digest.update(data: try encoder.encode(game))
            for _ in 0..<60 where !game.isOver {
                game.letStarsFall()
                digest.update(data: try encoder.encode(game))
                if let cell = game.legalGroups.first?.first { game.clear(cell) }
                precondition(game.isValidSave)
                digest.update(data: try encoder.encode(game))
            }
            rounds.append(.init(seed: seed, delivered: game.turns, ended: game.isOver,
                score: game.score, trajectorySHA256: digest.finalize().map { String(format: "%02x", $0) }.joined()))
        }
        print(String(decoding: try encoder.encode(Report(rounds: rounds, events: BurstExposureRecorder.events)), as: UTF8.self))
    }
}
