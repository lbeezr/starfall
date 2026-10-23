import Foundation
import Observation
import StarfallCore

/// Optional whole-run records project independently from a validated round save.
/// The saved winning round remains the recovery receipt until this write succeeds.
@MainActor @Observable final class StoryMasteryStore {
    static let key = "starfall.mastery.v1"
    static let rejectedKey = "starfall.mastery.rejected"

    private struct Envelope: Codable {
        let version: Int
        let records: [StoryMasteryRecord]
    }

    enum Failure: Error { case unsupportedOrInvalid }

    private(set) var records: [StoryMasteryRecord] = []
    private(set) var needsPersistence = false
    private(set) var recovered = false
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let writer: @MainActor (Data, UserDefaults) throws -> Void
    @ObservationIgnored private var rejected: Any?

    /// Read only. A committed winning round can repair a missing best in memory;
    /// activation/commit owns the later durable projection.
    init(defaults: UserDefaults, ignoreSaved: Bool = false,
         writer: @escaping @MainActor (Data, UserDefaults) throws -> Void = StoryMasteryStore.write) {
        self.defaults = defaults
        self.writer = writer
        guard !ignoreSaved else { return }
        if let raw = defaults.object(forKey: Self.key) {
            if let data = raw as? Data,
               let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
               envelope.version == 1, Self.isValid(envelope.records) {
                records = envelope.records
            } else {
                rejected = raw
                recovered = true
            }
        }
        if let saved = SkySaveArchive.load(from: defaults), let record = saved.completedMasteryRun {
            promote(record)
        }
    }

    func best(for identity: StoryMasteryIdentity) -> StoryMasteryRecord? {
        records.first { $0.identity == identity }
    }

    /// Called only after the authoritative round write succeeds. Equal ranks keep
    /// the first whole record; goals from different attempts are never unioned.
    func record(_ game: FallingSky) throws {
        if let record = game.completedMasteryRun { promote(record) }
        guard needsPersistence else { return }
        guard Self.isValid(records) else { throw Failure.unsupportedOrInvalid }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(Envelope(version: 1, records: records))
        // Preserve wrong-type values as well as undecodable bytes. A failed writer
        // leaves the original key and this recovery value available for retry.
        if let rejected { defaults.set(rejected, forKey: Self.rejectedKey) }
        try writer(data, defaults)
        rejected = nil
        needsPersistence = false
    }

    static func write(_ data: Data, to defaults: UserDefaults) throws {
        defaults.set(data, forKey: key)
    }

    private func promote(_ record: StoryMasteryRecord) {
        guard record.isValid else { return }
        if let index = records.firstIndex(where: { $0.identity == record.identity }) {
            guard record.rank > records[index].rank else { return }
            records[index] = record
        } else {
            guard records.count < 2 else { return }
            records.append(record)
        }
        needsPersistence = true
    }

    private static func isValid(_ records: [StoryMasteryRecord]) -> Bool {
        guard records.count <= 2, records.allSatisfy(\.isValid) else { return false }
        for (index, record) in records.enumerated() {
            if records.prefix(index).contains(where: { $0.identity == record.identity }) { return false }
        }
        return true
    }
}
