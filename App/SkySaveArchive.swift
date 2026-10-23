import Foundation
import StarfallCore

/// One persistence contract for committed skies. Legacy bytes remain untouched;
/// a present but invalid current save never falls back to an older round.
enum SkySaveArchive {
    static let key = "starfall.accumulation.v14"
    static let fourLineKey = "starfall.accumulation.v13"
    static let patternKey = "starfall.accumulation.v12"
    static let cascadeKey = "starfall.accumulation.v11"
    static let storyKey = "starfall.accumulation.v10"
    static let worldKey = "starfall.accumulation.v9"
    static let agingKey = "starfall.accumulation.v8"
    static let patientFeedingKey = "starfall.accumulation.v7"
    static let feedingKey = "starfall.accumulation.v6"
    static let gravityKey = "starfall.accumulation.v5"
    static let previousKey = "starfall.accumulation.v4"
    static let legacyKey = "starfall.accumulation.v3"
    static let schemaVersion = 14
    /// One recovery slot; never used as an automatic fallback.
    static let rejectedKey = "starfall.accumulation.rejected"

    enum LoadResult {
        case missing
        case loaded(FallingSky)
        case rejected(sourceKey: String)
    }

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
        guard game.isValidSave, game.generation == .legacy, game.challengeRevision == 0, game.challengeActionVersion == 0 else { throw Failure.unsupportedOrInvalid }
        return game
    }

    @MainActor static func inspect(from defaults: UserDefaults) -> LoadResult {
        let keys = [key, fourLineKey, patternKey, cascadeKey, storyKey, worldKey, agingKey, patientFeedingKey, feedingKey, gravityKey, previousKey, legacyKey]
        guard let source = keys.first(where: { defaults.object(forKey: $0) != nil }) else { return .missing }
        guard let game = load(from: defaults) else { return .rejected(sourceKey: source) }
        return .loaded(game)
    }

    /// Encode first so a failed validation cannot change the archive or recovery slot.
    /// Preserve rejected property-list values (including wrong types) before replacement.
    @MainActor static func save(_ game: FallingSky, to defaults: UserDefaults) throws {
        let data = try encode(game)
        if case .rejected(let source) = inspect(from: defaults), let value = defaults.object(forKey: source) {
            defaults.set(["sourceKey": source, "value": value], forKey: rejectedKey)
        }
        defaults.set(data, forKey: key)
    }

    @MainActor static func load(from defaults: UserDefaults) -> FallingSky? {
        if defaults.object(forKey: key) != nil {
            guard let data = defaults.data(forKey: key), let game = try? decode(data) else { return nil }
            return game
        }
        if defaults.object(forKey: fourLineKey) != nil {
            guard let data = defaults.data(forKey: fourLineKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 13, envelope.game.isValidSave,
                  (0...4).contains(envelope.game.challengeRevision) else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: patternKey) != nil {
            guard let data = defaults.data(forKey: patternKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 12, envelope.game.isValidSave,
                  (0...3).contains(envelope.game.challengeRevision) else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: cascadeKey) != nil {
            guard let data = defaults.data(forKey: cascadeKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 11, envelope.game.isValidSave,
                  (0...2).contains(envelope.game.challengeRevision) else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: storyKey) != nil {
            guard let data = defaults.data(forKey: storyKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 10, envelope.game.isValidSave,
                  (0...1).contains(envelope.game.challengeRevision) else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: worldKey) != nil {
            guard let data = defaults.data(forKey: worldKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 9, envelope.game.isValidSave,
                  envelope.game.challengeRevision == 0 else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: agingKey) != nil {
            guard let data = defaults.data(forKey: agingKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 8, envelope.game.isValidSave, envelope.game.challengeRevision == 0,
                  envelope.game.challengeActionVersion == 0 else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: patientFeedingKey) != nil {
            guard let data = defaults.data(forKey: patientFeedingKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 7,
                  envelope.game.isValidSave, envelope.game.challengeRevision == 0, envelope.game.challengeActionVersion == 0, !envelope.game.hasPocketedDusk else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: feedingKey) != nil {
            guard let data = defaults.data(forKey: feedingKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 6, envelope.game.isValidSave, envelope.game.challengeRevision == 0, envelope.game.challengeActionVersion == 0, !envelope.game.hasPocketedDusk,
                  envelope.game.duskRule != .patientFeeding else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: gravityKey) != nil {
            guard let data = defaults.data(forKey: gravityKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 5, envelope.game.isValidSave, envelope.game.challengeRevision == 0, envelope.game.challengeActionVersion == 0, !envelope.game.hasPocketedDusk else { return nil }
            return envelope.game
        }
        if defaults.object(forKey: previousKey) != nil {
            guard let data = defaults.data(forKey: previousKey),
                  let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
                  envelope.schemaVersion == 4,
                  [.legacy, .opalStorms].contains(envelope.game.generation),
                  envelope.game.isValidSave, envelope.game.challengeRevision == 0, envelope.game.challengeActionVersion == 0, !envelope.game.hasPocketedDusk else { return nil }
            return envelope.game
        }
        guard let data = defaults.data(forKey: legacyKey), let game = try? decodeLegacy(data) else { return nil }
        return game
    }

}

/// Acknowledgement belongs to this session; neither notice is a restored round.
enum SkyPersistenceNotice: Equatable {
    case rejected, failed
    var title: String { SkyCopy.text(self == .rejected ? .saveRejectedTitle : .saveFailedTitle) }
    var message: String { SkyCopy.text(self == .rejected ? .saveRejectedMessage : .saveFailedMessage) }
}
