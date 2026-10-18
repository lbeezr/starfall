import Foundation
import StarfallCore

/// One persistence contract for committed skies. Legacy bytes remain untouched;
/// a present but invalid current save never falls back to an older round.
enum SkySaveArchive {
    static let key = "starfall.accumulation.v5"
    static let previousKey = "starfall.accumulation.v4"
    static let legacyKey = "starfall.accumulation.v3"
    static let schemaVersion = 5

    private struct Envelope: Codable {
        let schemaVersion: Int
        let game: FallingSky
    }

    enum Failure: Error { case unsupportedOrInvalid }

    static func encode(_ game: FallingSky) throws -> Data {
        guard game.isValidSave else { throw Failure.unsupportedOrInvalid }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(Envelope(schemaVersion: schemaVersion, game: game))
    }

    static func decode(_ data: Data) throws -> FallingSky {
        let envelope = try JSONDecoder().decode(Envelope.self, from: data)
        guard envelope.schemaVersion == schemaVersion, envelope.game.isValidSave else {
            throw Failure.unsupportedOrInvalid
        }
        return envelope.game
    }

    private static func decodeLegacy(_ data: Data) throws -> FallingSky {
        let game = try JSONDecoder().decode(FallingSky.self, from: data)
        guard game.isValidSave, game.generation == .legacy else { throw Failure.unsupportedOrInvalid }
        return game
    }

    @MainActor static func load(from defaults: UserDefaults) -> FallingSky? {
        if defaults.object(forKey: key) != nil {
            guard let data = defaults.data(forKey: key), let game = try? decode(data) else { return nil }
            return game
        }
        if defaults.object(forKey: previousKey) != nil {
            guard let data = defaults.data(forKey: previousKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 4,
                  [.legacy, .opalStorms].contains(envelope.game.generation),
                  envelope.game.isValidSave else { return nil }
            return envelope.game
        }
        guard let data = defaults.data(forKey: legacyKey), let game = try? decodeLegacy(data) else { return nil }
        return game
    }

}
