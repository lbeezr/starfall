
private extension FallingSkyView {
    func cancelConstellation() {
        trace.cancel(); store.constellationTracing = false; store.scene.clearConstellationTrace()
    }
    func beginConstellation(_ point: CGPoint, size: CGSize) {
        cancelConstellation()
        store.constellationTracing = true
        guard let cell = ObservatoryGeometry(size: size).cell(at: point) else { return }
        _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        trace.lastFinger = point
        refreshConstellation()
    }
    func moveConstellation(_ point: CGPoint, size: CGSize) {
        guard trace.snapshot != nil else { return }
        let mapping = ObservatoryGeometry(size: size)
        guard mapping.cell(at: point) != nil else { cancelConstellation(); return }
        let previous = trace.lastFinger ?? point
        let distance = hypot(point.x-previous.x, point.y-previous.y)
        let steps = min(96, max(1, Int(ceil(distance/6))))
        for index in 1...steps {
            let fraction = CGFloat(index)/CGFloat(steps)
            let sample = CGPoint(x: previous.x+(point.x-previous.x)*fraction, y: previous.y+(point.y-previous.y)*fraction)
            guard let cell = mapping.cell(at: sample) else { cancelConstellation(); return }
            let center = mapping.viewPoint(cell), frame = mapping.frame(cell)
            // Enter a star's central region; diagonal corner crossings do not select unrelated supports.
            guard hypot(sample.x-center.x, sample.y-center.y) < min(frame.width,frame.height)*0.38 else { continue }
            let count = trace.count
            if trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear) {
                refreshConstellation()
                if trace.count > count { traceFeedback.step(count: trace.count, enabled: store.hapticsEnabled && !reduceMotion && !calmEffects && !voiceOver) }
            }
            if trace.snapshot == nil { cancelConstellation(); return }
        }
        trace.lastFinger = point
        store.scene.moveConstellationTip(point)
    }
    func refreshConstellation() { store.scene.showConstellationTrace(trace.path, ready: trace.count >= 5) }
    func releaseConstellation() {
        let outcome = trace.finish(ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        store.constellationTracing = false
        store.scene.clearConstellationTrace()
        guard let outcome else { return }
        store.clearTracedConstellation(outcome.path, snapshot: outcome.snapshot, generation: outcome.generation)
        // Commit synchronously first; effects never choose or delay the cleared set.
        if store.game != outcome.snapshot { store.scene.constellationBurst(outcome.path) }
    }
    func accessibleTrace(_ cell: Cell) {
        if trace.snapshot == nil {
            _ = trace.begin(cell, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        } else {
            _ = trace.visit(cell, ticket: trace.sequence, game: store.game, generation: store.constellationInputGeneration, enabled: store.canClear)
        }
        refreshConstellation()
        UIAccessibility.post(notification: .announcement, argument: trace.count > 0
            ? "\(trace.count) stars worth \(trace.value) starlight. \(trace.count >= 5 ? "Ready to release." : "Five stars needed.")"
            : "Choose a neighboring matching star. Trace canceled.")
    }
}

@MainActor private final class ConstellationTraceFeedback {
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let ready = UIImpactFeedbackGenerator(style: .rigid)
    func step(count: Int, enabled: Bool) {
        guard enabled else { return }
        if count == 5 { ready.impactOccurred(intensity: 0.8) }
        else { impact.impactOccurred(intensity: min(0.85, 0.2+Double(count)*0.1)) }
        impact.prepare(); ready.prepare()
    }
}
