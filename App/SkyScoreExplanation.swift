import StarfallCore

/// Copied components of a committed award; never a scoring or save capability.
struct SkyScoreExplanation: Equatable {
    // Current Core permits eight ordinary refills plus twelve survivor phases.
    // A hosted boundary assertion keeps this defensive presentation cap aligned.
    static let maximumPhases = 20

    struct Phase: Equatable {
        let clearedStarCount: Int
        let baseLight: Int
        let basePoints: Int
        let sizeBonus: Int
        let comboBonus: Int
        let points: Int
        let depth: Int
        let usesStoryPoints: Bool
    }

    let phases: [Phase]
    let total: Int

    init?(turn: FallingSkyTurn, from old: FallingSky) {
        guard !turn.cleared.isEmpty || turn.resolutionPhases.contains(where: { !$0.cleared.isEmpty }),
              turn.collected >= 0 else { return nil }
        if !turn.resolutionPhases.isEmpty {
            guard let award = turn.award,
                  let explanation = Self(phases: turn.resolutionPhases, expectedTotal: turn.displayAward),
                  Self.sum(explanation.phases.map(\.baseLight)) == turn.collected,
                  Self.sum(explanation.phases.map(\.clearedStarCount)) == award.clearedStarCount,
                  Self.sum(explanation.phases.map(\.baseLight)) == award.baseLight,
                  Self.sum(explanation.phases.map(\.sizeBonus)) == award.sizeBonus,
                  Self.sum(explanation.phases.map(\.comboBonus)) == award.comboBonus else { return nil }
            self = explanation
        } else if let award = turn.award {
            guard award.baseLight == turn.collected, let phase = Self.phase(award, depth: 1) else { return nil }
            phases = [phase]
            total = phase.points
        } else {
            guard old.board.count == FallingSky.side * FallingSky.side,
                  turn.cleared.count <= FallingSky.side * FallingSky.side,
                  turn.cleared.allSatisfy({ old.gem(at: $0) != nil }) else { return nil }
            phases = [Phase(clearedStarCount: turn.cleared.count, baseLight: turn.collected,
                            basePoints: turn.collected, sizeBonus: 0, comboBonus: 0,
                            points: turn.collected, depth: 1, usesStoryPoints: false)]
            total = turn.collected
        }
    }

    /// An actual contiguous prefix, including the active phase, matches the
    /// rising celebration total. Separate actions never share this prefix.
    init?(phases: [SkyResolutionPhase], expectedTotal: Int) {
        guard (1...Self.maximumPhases).contains(phases.count), expectedTotal >= 0 else { return nil }
        var copied: [Phase] = []
        for (index, phase) in phases.enumerated() {
            guard phase.comboDepth == index + 1, !phase.cleared.isEmpty,
                  phase.before.count == FallingSky.side * FallingSky.side,
                  phase.cleared.count <= FallingSky.side * FallingSky.side,
                  phase.cleared.allSatisfy({ cell in
                      (0..<FallingSky.side).contains(cell.row) && (0..<FallingSky.side).contains(cell.column)
                          && phase.before[cell.row * FallingSky.side + cell.column] != nil
                  }), phase.award.clearedStarCount == phase.cleared.count,
                  let value = Self.phase(phase.award, depth: phase.comboDepth) else { return nil }
            copied.append(value)
        }
        guard Self.sum(copied.map(\.points)) == expectedTotal else { return nil }
        self.phases = copied
        total = expectedTotal
    }

    private static func phase(_ award: SkyScoreAward, depth: Int) -> Phase? {
        guard (0...(FallingSky.side * FallingSky.side)).contains(award.clearedStarCount),
              award.baseLight >= 0, award.sizeBonus >= 0, award.comboBonus >= 0,
              award.displayPoints >= 0,
              sum([award.sizeBonus, award.comboBonus]) == award.bonus else { return nil }
        let (basePoints, overflow) = award.displayPoints.subtractingReportingOverflow(award.bonus)
        guard !overflow, basePoints >= 0 else { return nil }
        return Phase(clearedStarCount: award.clearedStarCount, baseLight: award.baseLight,
                     basePoints: basePoints, sizeBonus: award.sizeBonus, comboBonus: award.comboBonus,
                     points: award.displayPoints, depth: depth, usesStoryPoints: true)
    }

    private static func sum(_ values: [Int]) -> Int? {
        var total = 0
        for value in values {
            let (next, overflow) = total.addingReportingOverflow(value)
            guard !overflow else { return nil }
            total = next
        }
        return total
    }
}
