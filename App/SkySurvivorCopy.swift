import StarfallCore

/// Read-only wording for committed movements; no prediction or scoring capability.
enum SkySurvivorCopy {
    static func count(in phases: [SkyResolutionPhase]) -> Int {
        guard (2...SkySurvivorIngredients.maximumPhases).contains(phases.count) else { return 0 }
        var count = 0
        for index in 1..<phases.count {
            guard let transition = SkySurvivorIngredients(phases: phases, currentIndex: index) else { return 0 }
            count += transition.movements.count
        }
        return count
    }

    static func fact(_ count: Int) -> String? {
        guard count > 0, count <= SkySurvivorIngredients.maximumPhases * 49 else { return nil }
        return SkyCopy.text(count == 1 ? .survivorOne : .survivorMany,
                            values: count == 1 ? [:] : ["count": String(count)])
    }

    static func guide(_ count: Int) -> String? {
        fact(count).map { SkyCopy.text(.survivorLegend, values: ["detail": $0]) }
    }
}
