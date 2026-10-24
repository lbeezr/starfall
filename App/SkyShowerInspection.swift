import Foundation
import StarfallCore

/// One disposable evaluation of the announced shower, never its following supply.
struct SkyShowerInspection: Identifiable {
    enum Effect: Equatable {
        case grew(Cell, StarfallGem)
        case landed(Cell, StarfallGem)
        case blocked
        case notReached
    }

    struct Step: Identifiable {
        let id: Int
        let star: IncomingStar
        let effect: Effect
    }

    let id: UUID
    let steps: [Step]
    let phases: [SkyResolutionPhase]
    let prearrivalChanges: Bool
    let blockedColumn: Int?
    private let source: SkyForecastInspection.Source

    init?(source: SkyForecastInspection.Source) {
        guard !source.arriving, source.forecast == source.game.incoming,
              source.game.isValidSave, !source.game.isOver,
              !source.game.usesFullBoardRefill else { return nil }
        var copy = source.game
        guard let turn = copy.letStarsFall(), turn.forecast == source.forecast,
              turn.arrivals.count <= source.forecast.count,
              zip(turn.arrivals, source.forecast).allSatisfy({ $0.0.star == $0.1 }) else { return nil }
        if let column = turn.blockedColumn {
            guard turn.arrivals.count < source.forecast.count,
                  source.forecast[turn.arrivals.count].column == column else { return nil }
        } else {
            guard turn.arrivals.count == source.forecast.count else { return nil }
        }
        self.source = source
        id = UUID()
        steps = source.forecast.enumerated().map { index, star in
            let effect: Effect
            if index < turn.arrivals.count {
                let arrival = turn.arrivals[index]
                effect = arrival.grew ? .grew(arrival.cell, arrival.gem) : .landed(arrival.cell, arrival.gem)
            } else {
                effect = index == turn.arrivals.count ? .blocked : .notReached
            }
            return Step(id: star.id, star: star, effect: effect)
        }
        phases = turn.resolutionPhases
        prearrivalChanges = turn.settled != source.game.board || !turn.presentationPhases.isEmpty
            || !turn.stellarCollapses.isEmpty || !turn.duskCollapses.isEmpty
        blockedColumn = turn.blockedColumn
    }

    func matches(_ source: SkyForecastInspection.Source?) -> Bool {
        source == self.source
    }
}
