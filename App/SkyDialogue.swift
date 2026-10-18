import Foundation
import Observation

/// Stable content IDs. Portraits are presentation assets, independent of board materials.
enum SkySpeaker: String, Codable, CaseIterable, Sendable {
    case sunny, spark, pip, twinkle, nova, dusk
    var name: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }
    var portraitAsset: String { "Dialogue" + name }
}

struct SkyDialogueLine: Codable, Equatable, Identifiable, Sendable {
    enum Priority: String, Codable, Comparable, Sendable {
        case routine, help, warning, outcome
        private var rank: Int {
            switch self { case .routine: 0; case .help: 1; case .warning: 2; case .outcome: 3 }
        }
        static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }
    }
    let id: String
    let speaker: SkySpeaker
    let text: String
    let priority: Priority
    /// Omit for player-paced dialogue. Timed information can always be reopened.
    let seconds: Double?

    var spokenText: String { "\(speaker.name). \(text)" }
    var isValid: Bool {
        !id.isEmpty && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && text.count <= 400 && (seconds.map { $0.isFinite && (4...30).contains($0) } ?? true)
    }
}

struct SkyDialogueScript: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let lines: [SkyDialogueLine]
}

/// Small bundled authoring format. No rule conditions, timers or save state live in content.
struct SkyDialogueCatalog: Decodable, Sendable {
    let schemaVersion: Int
    let scripts: [SkyDialogueScript]
    /// Optional when decoding old authoring fixtures; required by the shipped library.
    let copy: [String: String]?
    enum ContentError: Error, Equatable {
        case invalidCatalog, missingScript(String), missingValue(String), unusedValue(String)
    }

    static func decode(_ data: Data) throws -> Self {
        let catalog = try JSONDecoder().decode(Self.self, from: data)
        guard catalog.schemaVersion == 1, !catalog.scripts.isEmpty, catalog.scripts.count <= 128,
              Set(catalog.scripts.map(\.id)).count == catalog.scripts.count else {
            throw ContentError.invalidCatalog
        }
        var ids = Set<String>()
        for script in catalog.scripts {
            guard !script.id.isEmpty, !script.lines.isEmpty, script.lines.count <= 32 else {
                throw ContentError.invalidCatalog
            }
            for line in script.lines {
                _ = try Self.placeholders(in: line.text)
                guard line.isValid, ids.insert(line.id).inserted else {
                    throw ContentError.invalidCatalog
                }
            }
        }
        if let copy = catalog.copy {
            guard copy.count <= 512 else { throw ContentError.invalidCatalog }
            for (key, text) in copy {
                guard !key.isEmpty, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                      text.count <= 1_600 else { throw ContentError.invalidCatalog }
                _ = try Self.placeholders(in: text)
            }
        }
        return catalog
    }

    static func placeholders(in text: String) throws -> Set<String> {
        var remaining = text[...]
        var keys = Set<String>()
        while let start = remaining.firstIndex(of: "{") {
            guard !remaining[..<start].contains("}"),
                  let end = remaining[start...].firstIndex(of: "}") else { throw ContentError.invalidCatalog }
            let key = String(remaining[remaining.index(after: start)..<end])
            guard !key.isEmpty, key.count <= 40,
                  key.unicodeScalars.allSatisfy({ CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-.")).contains($0) }) else {
                throw ContentError.invalidCatalog
            }
            keys.insert(key)
            remaining = remaining[remaining.index(after: end)...]
        }
        guard !remaining.contains("}") else { throw ContentError.invalidCatalog }
        return keys
    }

    static func render(_ source: String, values: [String: String]) throws -> String {
        let keys = try placeholders(in: source)
        if let unused = Set(values.keys).subtracting(keys).sorted().first { throw ContentError.unusedValue(unused) }
        var text = source
        for key in keys {
            guard let value = values[key], !value.contains("{"), !value.contains("}") else {
                throw ContentError.missingValue(key)
            }
            text = text.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return text
    }

    func copyText(_ key: String, values: [String: String] = [:]) throws -> String {
        guard let source = copy?[key] else { throw ContentError.missingScript(key) }
        let text = try Self.render(source, values: values)
        guard text.count <= 1_600 else { throw ContentError.invalidCatalog }
        return text
    }

    func script(_ id: String, values: [String: String] = [:]) throws -> SkyDialogueScript {
        guard let source = scripts.first(where: { $0.id == id }) else { throw ContentError.missingScript(id) }
        var used = Set<String>()
        let lines = try source.lines.map { line in
            let keys = try Self.placeholders(in: line.text)
            used.formUnion(keys)
            let text = try Self.render(line.text, values: values.filter { keys.contains($0.key) })
            guard text.count <= 400 else { throw ContentError.invalidCatalog }
            return SkyDialogueLine(id: line.id, speaker: line.speaker, text: text,
                                   priority: line.priority, seconds: line.seconds)
        }
        if let unused = Set(values.keys).subtracting(used).sorted().first { throw ContentError.unusedValue(unused) }
        return SkyDialogueScript(id: id, lines: lines)
    }
}

/// One message/short script, no automatic event backlog. All mutations stay on the main actor.
@MainActor @Observable final class SkyDialogueSession {
    private(set) var line: SkyDialogueLine?
    private(set) var visible = false
    private(set) var revision: UInt64 = 0
    private(set) var scriptID: String?
    private var remainder: [SkyDialogueLine] = []
    var hasNext: Bool { !remainder.isEmpty }

    @discardableResult func show(_ incoming: SkyDialogueLine, interrupt: Bool = false) -> Bool {
        guard incoming.isValid, !incoming.text.contains("{"), !incoming.text.contains("}") else { return false }
        if let line, visible, !interrupt, incoming.priority < line.priority { return false }
        // A repeated event does not restart dismissal or interrupt script reading.
        if line == incoming && visible { return false }
        remainder.removeAll(); scriptID = nil
        line = incoming; visible = true; revision &+= 1
        return true
    }

    @discardableResult func play(_ script: SkyDialogueScript) -> Bool {
        guard !script.id.isEmpty, (1...32).contains(script.lines.count),
              script.lines.allSatisfy({ $0.isValid && !$0.text.contains("{") && !$0.text.contains("}") }),
              let first = script.lines.first, show(first) else { return false }
        scriptID = script.id
        remainder = Array(script.lines.dropFirst())
        return true
    }

    func next() {
        guard !remainder.isEmpty else { dismiss(); return }
        line = remainder.removeFirst(); visible = true; revision &+= 1
    }
    func dismiss() { visible = false; revision &+= 1 }
    func reopen() { guard line != nil else { return }; visible = true; revision &+= 1 }
    func expire(revision ticket: UInt64) {
        guard revision == ticket, !hasNext, line?.seconds != nil else { return }
        dismiss()
    }
    /// Restart/screen replacement invalidate any in-flight dismissal and discard old scripts.
    func reset() { scriptID = nil; line = nil; remainder.removeAll(); visible = false; revision &+= 1 }
}
