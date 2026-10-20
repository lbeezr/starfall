import Foundation
import StarfallCore

/// Bundled local content, decoded once. A missing/invalid shipped catalog is a packaging defect.
enum SkyDialogueLibrary {
    static let catalog: SkyDialogueCatalog = {
        guard let url = Bundle.main.url(forResource: "observatory-dialogue", withExtension: "json"),
              let data = try? Data(contentsOf: url), let catalog = try? SkyDialogueCatalog.decode(data) else {
            preconditionFailure("Missing or invalid observatory-dialogue.json")
        }
        precondition(Set(catalog.copy?.keys.map { $0 } ?? []) == Set(SkyCopy.Key.allCases.map(\.rawValue)),
                     "Interface copy must match the typed key inventory")
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
        let context = [includeTiming ? timing(game: game, cadence: cadence)?.text : nil, DuskWarning(game: game)?.text, CriticalMassPresentation.warning(game: game)]
            .compactMap { $0 }.joined(separator: " ")
        guard !context.isEmpty else { return result }
        let combined = line("guide.context", values: ["detail": result.text, "context": context])
        return SkyDialogueLine(id: combined.id, speaker: result.speaker, text: combined.text,
                               priority: combined.priority, seconds: combined.seconds)
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


extension SkyDialogueLibrary {
    /// Pure selection from committed values. No clock, persistence or session mutation.
    static func result(for turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                       tracedCount: Int, recipe: StarRecipe?, relayDepth: Int,
                       techniqueResult: String) -> SkyDialogueLine {
        var result: SkyDialogueLine
        let growth = turn.arrivals.filter(\.grew).count
        let dissolved = turn.cleared.filter { old.gem(at: $0)?.isDark == true }.count
        if game.outcome == .won {
            result = line(game.challenge?.wonGuideID ?? "guide.won", values: ["score": game.displayScore.formatted()])
        } else if turn.blockedColumn != nil {
            result = line("guide.full", values: ["score": game.displayScore.formatted()])
        } else if !turn.stellarCollapses.isEmpty {
            let count = Set(turn.stellarCollapses.flatMap { $0.consumed.union([$0.center]) }).count
            result = line("guide.stellar-collapse", values: ["count": String(count)])
        } else if !turn.duskCollapses.isEmpty {
            let count = Set(turn.duskCollapses.flatMap(\.consumed)).count
            result = line("guide.dusk-collapse", values: ["swallowed": SkyCopy.count(.eventEatenOne, .eventEatenMany, count)])
        } else if !turn.cleared.isEmpty {
            if turn.collected == 0 && turn.cleared.contains(where: { old.isDrained(at: $0) }) {
                result = line("guide.gray-clear")
            } else if dissolved > 0 {
                result = line("guide.dissolved", values: ["score": game.displayAward(for: turn).formatted(), "dark": game.duskRule != .legacy ? SkyCopy.count(.eventDusk, .eventDusks, dissolved) : SkyCopy.text(dissolved == 1 ? .eventDark : .eventDarks)])
            } else if let recipe {
                result = line("guide.recipe", values: ["shape": SkyCopy.text(recipe.shape == .square ? .techniqueSquare : .techniqueCross), "score": game.displayAward(for: turn).formatted()])
            } else if tracedCount > 0 {
                result = line("guide.constellation", values: ["stars": String(tracedCount), "score": game.displayAward(for: turn).formatted()])
            } else { result = line("guide.clear", values: ["score": game.displayAward(for: turn).formatted()]) }
        } else if turn.arrivals.contains(where: { $0.gem.isDark }) {
            result = line(game.duskRule != .legacy ? "guide.dusk-arrival" : "guide.dark-arrival")
        } else if turn.arrivals.contains(where: { $0.gem.isLight }) {
            result = line("guide.opal-arrival")
        } else if turn.arrivals.contains(where: { $0.gem.gravityKind == .magnet }) {
            result = line("guide.magnet-arrival")
        } else if growth > 0 {
            result = line(game.duskRule != .legacy && game.board.enumerated().contains(where: { game.isDrained(at: Cell($0.offset/7,$0.offset%7)) }) ? "guide.dusk-growth" : "guide.growth", values: ["growth": SkyCopy.count(.eventGrowthOne, .eventGrowthMany, growth)])
        } else {
            result = line("guide.arrival", values: ["arrival": SkyCopy.count(.eventArrivalOne, .eventArrivalMany, turn.arrivals.count)])
        }
        if !game.isOver {
            if turn.exchange != nil { result = line("guide.technique",values:["detail":techniqueResult]) }
            else if relayDepth > 1 && turn.collected > 0 { result = line("guide.relay", values: ["score": game.displayAward(for: turn).formatted(), "depth": String(relayDepth)]) }
        }
        if !game.isOver, let field = game.orbit {
            result = line("guide.orbit", values: ["release": SkyCopy.count(.orbitReleaseOne, .orbitReleaseMany, field.windowsRemaining)])
        } else if !game.isOver, turn.presentationPhases.contains(where: { $0.event == .release }) {
            result = line("guide.release")
        }
        return result
    }
}
