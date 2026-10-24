import StarfallCore

extension SkyScoreExplanation.Phase {
    var physicalText: String {
        SkyCopy.text(.scoreExplanationPhysical, values: [
            "stars": String(clearedStarCount), "light": String(baseLight)
        ])
    }

    var equationText: String {
        if !usesStoryPoints {
            return SkyCopy.text(.scoreExplanationManualEquation, values: [
                "light": String(baseLight), "points": SkyCopy.score(points)
            ])
        }
        return SkyCopy.text(.scoreExplanationEquation, values: [
            "components": SkyScoreExplanation.components(base: basePoints, size: sizeBonus, chain: comboBonus),
            "points": SkyCopy.score(points)
        ])
    }

    var explanationText: String {
        if !usesStoryPoints {
            return SkyCopy.text(.scoreExplanationManual, values: [
                "stars": String(clearedStarCount), "light": String(baseLight), "points": SkyCopy.score(points)
            ])
        }
        return physicalText + " " + equationText
    }
}

extension SkyScoreExplanation {
    /// One action-level equation fits the existing result guide's bounded text.
    /// Detailed native reading still retains every chronological phase separately.
    var guideText: String {
        let stars = phases.reduce(0) { $0 + $1.clearedStarCount }
        let light = phases.reduce(0) { $0 + $1.baseLight }
        if phases.first?.usesStoryPoints != true {
            return SkyCopy.text(.scoreExplanationManual, values: [
                "stars": String(stars), "light": String(light), "points": SkyCopy.score(total)
            ])
        }
        let physical = SkyCopy.text(.scoreExplanationPhysical, values: [
            "stars": String(stars), "light": String(light)
        ])
        let equation = SkyCopy.text(.scoreExplanationEquation, values: [
            "components": compactText, "points": SkyCopy.score(total)
        ])
        return physical + " " + equation
    }

    /// This caption names point contributions; physical light has its own units.
    var compactText: String {
        if phases.first?.usesStoryPoints != true {
            return SkyCopy.text(.scoreExplanationManualEquation, values: [
                "light": String(phases.reduce(0) { $0 + $1.baseLight }), "points": SkyCopy.score(total)
            ])
        }
        return Self.components(base: phases.reduce(0) { $0 + $1.basePoints },
                               size: phases.reduce(0) { $0 + $1.sizeBonus },
                               chain: phases.reduce(0) { $0 + $1.comboBonus })
    }

    var totalText: String {
        SkyCopy.text(.scoreExplanationTotal, values: ["points": SkyCopy.score(total)])
    }

    fileprivate static func components(base: Int, size: Int, chain: Int) -> String {
        var parts = [SkyCopy.text(.scoreExplanationBase, values: ["points": SkyCopy.score(base)])]
        if size > 0 { parts.append(SkyCopy.text(.scoreExplanationSize, values: ["points": SkyCopy.score(size)])) }
        if chain > 0 { parts.append(SkyCopy.text(.scoreExplanationChain, values: ["points": SkyCopy.score(chain)])) }
        return parts.joined(separator: " + ")
    }
}
