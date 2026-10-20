import Foundation

/// Immutable points for one clear phase, or the exact sum of a turn's phases.
/// `baseLight` is conserved physical light; bonuses never alter that ledger.
public struct SkyScoreAward: Equatable, Sendable {
    public let baseLight: Int
    public let clearedStarCount: Int
    public let sizeBonus: Int
    public let comboBonus: Int
    public let bonus: Int
    public let displayPoints: Int

    init(baseLight: Int, clearedStarCount: Int, comboDepth: Int = 1) {
        self.baseLight = baseLight
        self.clearedStarCount = clearedStarCount
        sizeBonus = max(0, clearedStarCount - 3) * 1_000
        let normal = baseLight * 1_000 + sizeBonus
        comboBonus = normal * (min(max(1, comboDepth), 5) - 1)
        bonus = sizeBonus + comboBonus
        displayPoints = normal + comboBonus
    }

    init(summing awards: [SkyScoreAward]) {
        baseLight = awards.reduce(0) { $0 + $1.baseLight }
        clearedStarCount = awards.reduce(0) { $0 + $1.clearedStarCount }
        sizeBonus = awards.reduce(0) { $0 + $1.sizeBonus }
        comboBonus = awards.reduce(0) { $0 + $1.comboBonus }
        bonus = sizeBonus + comboBonus
        displayPoints = baseLight * 1_000 + bonus
    }
}

/// Fixed-size receipts validate earned points without a growing action history.
/// Missing tier data is the unchanged revision-one size-only score contract.
struct StoryScoreLedger: Codable, Equatable, Sendable {
    private struct Tier: Codable, Equatable, Sendable {
        var light = 0
        var clearCounts = Array(repeating: 0, count: 50)
        var count: Int { clearCounts.reduce(0, +) }
        var stars: Int { clearCounts.enumerated().reduce(0) { $0 + $1.offset * $1.element } }
        var sizeUnits: Int { clearCounts.enumerated().reduce(0) { $0 + $1.element * max(0, $1.offset - 3) } }
        var hasBoundedValues: Bool {
            (0...1_000).contains(light) && clearCounts.count == 50
                && clearCounts.allSatisfy { (0...1_000).contains($0) }
        }
    }

    private(set) var clearCounts = Array(repeating: 0, count: 50)
    private var cascadeTiers: [Tier]?

    init(automaticRecipes: Bool = false) {
        cascadeTiers = automaticRecipes ? Array(repeating: Tier(), count: 5) : nil
    }

    mutating func record(_ award: SkyScoreAward, depth: Int = 1) {
        precondition((2...49).contains(award.clearedStarCount))
        clearCounts[award.clearedStarCount] += 1
        if cascadeTiers != nil {
            let tier = min(depth, 5) - 1
            cascadeTiers![tier].light += award.baseLight
            cascadeTiers![tier].clearCounts[award.clearedStarCount] += 1
        }
    }

    var bonusUnits: Int {
        guard clearCounts.count == 50, clearCounts.allSatisfy({ (0...1_000).contains($0) }) else { return Int.max }
        let size = clearCounts.enumerated().reduce(0) { $0 + $1.element * max(0, $1.offset - 3) }
        guard let cascadeTiers else { return size }
        guard cascadeTiers.count == 5, cascadeTiers.allSatisfy(\.hasBoundedValues) else { return Int.max }
        return size + cascadeTiers.enumerated().reduce(0) { $0 + $1.offset * ($1.element.light + $1.element.sizeUnits) }
    }

    func isValid(light: Int, target: Int, automaticRecipes: Bool, manualClears: Bool = true) -> Bool {
        guard clearCounts.count == 50, clearCounts[0] == 0, clearCounts[1] == 0,
              (0...(target / 1_000 + 98)).contains(light),
              clearCounts.allSatisfy({ (0...light).contains($0) }) else { return false }
        if !manualClears && (clearCounts[2] != 0 || clearCounts[3] != 0) { return false }
        let stars = clearCounts.enumerated().reduce(0) { $0 + $1.offset * $1.element }
        guard stars <= light, light <= stars * 2 else { return false }
        guard automaticRecipes else {
            return cascadeTiers == nil && light + bonusUnits < target / 1_000 + 144
        }
        guard let tiers = cascadeTiers, tiers.count == 5, tiers.allSatisfy(\.hasBoundedValues),
              tiers.reduce(0, { $0 + $1.light }) == light else { return false }
        for size in 0..<50 {
            guard tiers.reduce(0, { $0 + $1.clearCounts[size] }) == clearCounts[size] else { return false }
        }
        for (index, tier) in tiers.enumerated() {
            guard tier.stars + tier.clearCounts[2] <= tier.light,
                  tier.light <= tier.stars * 2 else { return false }
            if index > 0 {
                // Only automatic recipes continue a transaction: at least four
                // stars. Tiers 2–4 need a preceding phase; tier 5 holds depths 5–12.
                guard tier.clearCounts[2] == 0, tier.clearCounts[3] == 0,
                      tier.count <= tiers[index - 1].count * (index == 4 ? 8 : 1) else { return false }
            }
        }
        // Before the last transaction the objective was unmet. At most 49 grown
        // stars and 46 size units can be spent, each at a multiplier no higher than 5.
        return light + bonusUnits < target / 1_000 + 720
    }
}
