/// Shared deterministic revision-three player inputs for hosted and native tests.
/// These are ordinary adjacent exchanges and showers, never injected board/score state.
/// Hosted reconstruction verifies every step against production Core before use.
struct StoryPatternPlan: Sendable {
    struct Exchange: Sendable {
        let from: Int
        let to: Int

        var sourceIdentifier: String { "experiment.cell.\(from / 7).\(from % 7)" }
        var destinationIdentifier: String { "experiment.cell.\(to / 7).\(to % 7)" }
        var accessibilityAction: String {
            switch to - from {
            case -1: "Move star left"
            case 1: "Move star right"
            case 7: "Move star up"
            case -7: "Move star down"
            default: preconditionFailure("A story witness must use adjacent exchanges")
            }
        }
    }

    let target: Int
    let waves: [[Exchange]]
    let expectedScore: Int
    let expectedShowers: Int
    let expectedExchanges: Int

    private init(target: Int, moves: [[(Int, Int)]], expectedScore: Int,
                 expectedShowers: Int, expectedExchanges: Int) {
        self.target = target
        waves = moves.map { $0.map { Exchange(from: $0.0, to: $0.1) } }
        self.expectedScore = expectedScore
        self.expectedShowers = expectedShowers
        self.expectedExchanges = expectedExchanges
    }

    static let lantern = StoryPatternPlan(target: 150_000, moves: [
        [(8, 9), (5, 12), (17, 18), (7, 8)],
        [(1, 2), (7, 8), (17, 16), (0, 7)],
        [(18, 19), (18, 17), (10, 17), (12, 13)],
        [(11, 12), (9, 10), (4, 11), (11, 12)],
        [(16, 17), (3, 4), (10, 11), (0, 1)],
        [(15, 16), (28, 29), (1, 8), (15, 22)],
        [(8, 9), (2, 3), (1, 2), (12, 11)],
        [(5, 6), (4, 5), (16, 17), (19, 18)],
        [(2, 3), (34, 33), (12, 19), (3, 4)],
        [(0, 1), (4, 5), (7, 8), (1, 2)],
        [(10, 11), (7, 8), (8, 9)],
        [(18, 17), (15, 16), (1, 2), (3, 4)],
        [(3, 2), (18, 17), (11, 10), (10, 9)],
        [(33, 32), (12, 13), (34, 33), (26, 33)],
        [(19, 26), (12, 19), (27, 34), (10, 11)],
        [(4, 5), (34, 33)],
        [(20, 19), (3, 10), (11, 12), (15, 16)],
        [(2, 9), (7, 14), (7, 8), (35, 36)],
        [(10, 11), (7, 8), (8, 9), (28, 29)],
        [(28, 29)],
        [(12, 19), (4, 5), (4, 11), (11, 18)],
        [(5, 6), (6, 13), (10, 11), (12, 13)],
        [(0, 1), (1, 8), (17, 16), (15, 16)]
    ], expectedScore: 154_000, expectedShowers: 22, expectedExchanges: 86)
    static let ribbon = StoryPatternPlan(target: 220_000, moves: [
        [(8, 9), (11, 12), (18, 19), (5, 6)],
        [(3, 10), (10, 11)],
        [],
        [(7, 8), (10, 11), (9, 10)],
        [(21, 22), (14, 15), (17, 16), (10, 9)],
        [(8, 9), (9, 10), (12, 19), (11, 12)],
        [(26, 27), (26, 25), (19, 20), (34, 33)],
        [(19, 20), (20, 27), (3, 4), (4, 5)],
        [(5, 12), (4, 5), (1, 8), (1, 2)],
        [(2, 3), (14, 15), (8, 15), (15, 22)],
        [(3, 10), (3, 4), (7, 14), (1, 8)],
        [(4, 3), (2, 3), (1, 2), (3, 4)],
        [(2, 9), (7, 8), (8, 9), (26, 25)],
        [(2, 3), (5, 6), (4, 5), (19, 26)],
        [(13, 20), (20, 27), (23, 24), (3, 4)],
        [(10, 11), (23, 22), (1, 2), (3, 4)],
        [(2, 3), (24, 25), (13, 20), (20, 19)],
        [(4, 11), (27, 26), (3, 10), (19, 18)],
        [(5, 12), (9, 10), (13, 12), (12, 11)],
        [(16, 17), (10, 11), (11, 12), (9, 10)],
        [(0, 7), (7, 8)],
        [(14, 15), (8, 15), (12, 11), (10, 11)],
        [(9, 10), (8, 9), (9, 16), (8, 9)],
        [(9, 10), (27, 26), (4, 11), (18, 19)],
        [(27, 26), (26, 25), (9, 10), (11, 18)],
        [(19, 18), (11, 10), (4, 5), (3, 4)],
        [(15, 16), (9, 10), (3, 4)],
        [(0, 1), (2, 3), (4, 5), (5, 6)],
        [(4, 11), (4, 5)],
        [(21, 22), (0, 1), (3, 4), (3, 10)],
        [(10, 9), (11, 12), (6, 13), (20, 27)],
        [(13, 20), (1, 2), (2, 3), (14, 15)],
        [(0, 7), (7, 14)]
    ], expectedScore: 220_000, expectedShowers: 32, expectedExchanges: 118)
}
