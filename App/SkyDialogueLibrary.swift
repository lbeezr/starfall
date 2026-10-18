import Foundation
import StarfallCore

/// Bundled local content, decoded once. A missing/invalid shipped catalog is a packaging defect.
enum SkyDialogueLibrary {
    static let catalog: SkyDialogueCatalog = {
        guard let url = Bundle.main.url(forResource: "observatory-dialogue", withExtension: "json"),
              let data = try? Data(contentsOf: url), let catalog = try? SkyDialogueCatalog.decode(data) else {
            preconditionFailure("Missing or invalid observatory-dialogue.json")
        }
        return catalog
    }()

    static func script(_ id: String, values: [String: String] = [:]) -> SkyDialogueScript {
        do { return try catalog.script(id, values: values) }
        catch { preconditionFailure("Invalid dialogue \(id): \(error)") }
    }
    static func line(_ id: String, values: [String: String] = [:]) -> SkyDialogueLine {
        script(id, values: values).lines[0]
    }
}


extension SkyDialogueLibrary {
    static func contextual(_ result: SkyDialogueLine, game: FallingSky, cadence: SkyCadenceStep, includeTiming: Bool = true) -> SkyDialogueLine {
        let context = [includeTiming ? timing(game: game, cadence: cadence)?.text : nil, DuskWarning(game: game)?.text]
            .compactMap { $0 }.joined(separator: ". ")
        guard !context.isEmpty else { return result }
        return line("guide.context", values: ["detail": result.text, "context": context])
    }

    /// Read committed next-shower snapshots; content cannot schedule a storm or change its rules.
    static func timing(game: FallingSky, cadence: SkyCadenceStep) -> SkyDialogueLine? {
        guard !game.isOver, game.challenge == nil else { return nil }
        let phase = SkyPhaseCue(game: game)?.text
        let pace = SkyCadenceCueCopy(step: cadence)?.label
        if let phase, let pace { return line("timing.combined", values: ["phase": phase, "cadence": pace]) }
        if let pace { return line("timing.cadence", values: ["cadence": pace]) }
        // Calm counts stay quiet until the storm warning or recovery.
        if let cue = SkyPhaseCue(game: game), cue.phase.isStorm || cue.announcesTransition {
            return line("timing.phase", values: ["phase": cue.text])
        }
        return nil
    }
    static func transition(from old: FallingSky, to game: FallingSky,
                           previousCadence: SkyCadenceStep?, cadence: SkyCadenceStep) -> SkyDialogueLine? {
        guard game.turns != old.turns, previousCadence != nil else { return nil }
        return timing(game: game, cadence: cadence)
    }
    static func announcesTransition(from old: FallingSky, to game: FallingSky,
                                    previousCadence: SkyCadenceStep?, cadence: SkyCadenceStep) -> Bool {
        guard !game.isOver, game.challenge == nil, let previousCadence else { return false }
        if let cue = SkyPhaseCue(game: game), cue.announcesTransition, cue != SkyPhaseCue(game: old) { return true }
        return (cadence.warnsFasterNext && !previousCadence.warnsFasterNext)
            || (cadence.phase == .breathing && previousCadence.phase != .breathing)
    }
}
