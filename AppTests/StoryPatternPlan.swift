/// Shared deterministic revision-four player inputs for hosted and native tests.
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

    static let kiteSpace = StoryPatternPlan(target: 17_000, moves: [
        [(15, 14)],
        [(4, 11), (36, 29), (29, 22), (4, 3), (3, 2), (2, 1)]
    ], expectedScore: 17_000, expectedShowers: 1, expectedExchanges: 7)

    static let kitePoints = StoryPatternPlan(target: 17_000, moves: [
        [(4, 11)],
        [(15, 14), (36, 29), (29, 22), (4, 3), (3, 2), (2, 1)]
    ], expectedScore: 18_000, expectedShowers: 1, expectedExchanges: 7)

    static let seedSpend = StoryPatternPlan(target: 11_000, moves: [
        [(4, 3), (0, 1), (1, 8), (2, 9)]
    ], expectedScore: 11_000, expectedShowers: 0, expectedExchanges: 4)

    static let seedPreserve = StoryPatternPlan(target: 11_000, moves: [
        [(1, 8), (17, 10), (1, 2), (2, 9), (7, 8)]
    ], expectedScore: 13_000, expectedShowers: 0, expectedExchanges: 5)

    static let silverChain = StoryPatternPlan(target: 12_000, moves: [
        [(9, 10)]
    ], expectedScore: 19_000, expectedShowers: 0, expectedExchanges: 1)

    static let silverImmediate = StoryPatternPlan(target: 12_000, moves: [
        [(2, 9), (23, 22)]
    ], expectedScore: 12_000, expectedShowers: 0, expectedExchanges: 2)

    static let lantern = StoryPatternPlan(target: 150_000, moves: [
        [(8, 9), (0, 1), (5, 12), (0, 1)],
        [],
        [],
        [(4, 11), (1, 2), (10, 9), (11, 12)],
        [(3, 10), (3, 4), (9, 10), (10, 11)],
        [(17, 18), (3, 4), (5, 6)],
        [(12, 13), (5, 12)],
        [(13, 12), (5, 12), (0, 1), (1, 2)],
        [(4, 5), (1, 8), (21, 22), (8, 15)],
        [(3, 4), (2, 3), (1, 2), (20, 19)],
        [(2, 3), (5, 12), (16, 17)],
        [],
        [(13, 20), (1, 2), (2, 3), (3, 4)],
        [(4, 5), (0, 7), (8, 15), (5, 6)],
        [(3, 10), (5, 6), (1, 2), (2, 3)],
        [(9, 10), (22, 23), (7, 8), (4, 5)],
        [(3, 4), (2, 3), (10, 17), (5, 6)],
        [(4, 5), (1, 2), (2, 3), (6, 13)],
        [(28, 29), (1, 8), (1, 2), (7, 8)],
        [(21, 22), (5, 6), (4, 5), (3, 4)],
        [(2, 3), (1, 2), (12, 19), (3, 4)],
        [(4, 5), (7, 8), (1, 8), (0, 1)],
        [(5, 12), (12, 13), (11, 12)]
    ], expectedScore: 151_000, expectedShowers: 22, expectedExchanges: 75)
    static let ribbon = StoryPatternPlan(target: 220_000, moves: [
        [(8, 9), (11, 12), (18, 19), (5, 12)],
        [],
        [],
        [(7, 8), (10, 17), (9, 10), (7, 8)],
        [(10, 9), (21, 22), (15, 16), (7, 8)],
        [(4, 5), (6, 13), (13, 20), (19, 20)],
        [(10, 11), (11, 12), (14, 15), (8, 9)],
        [(2, 9)],
        [(12, 13), (11, 12), (11, 10), (7, 14)],
        [(2, 3), (1, 2), (1, 2), (7, 8)],
        [(3, 4), (1, 8), (11, 12), (13, 20)],
        [(25, 24), (3, 4), (4, 5), (18, 17)],
        [(3, 10)],
        [(8, 9), (10, 11), (6, 13), (0, 1)],
        [(2, 3), (1, 2), (0, 1), (0, 7)],
        [(5, 12), (3, 10), (3, 4), (12, 13)],
        [],
        [(27, 26), (5, 12)],
        [(8, 15), (7, 8), (9, 10), (8, 9)],
        [(7, 8), (3, 4), (2, 3), (27, 26)],
        [(19, 18), (4, 11)],
        [(19, 18), (11, 10), (14, 15), (8, 9)],
        [(8, 9), (0, 1), (4, 5), (2, 3)],
        [(27, 26), (26, 25), (4, 11), (13, 20)],
        [(4, 11), (11, 12)],
        [],
        [(5, 6), (0, 1), (2, 3), (1, 2)],
        [(3, 4), (3, 10), (15, 16), (9, 10)],
        [(11, 12), (20, 19), (19, 18), (9, 10)],
        [(9, 10), (11, 18), (6, 13)],
        [(18, 19), (4, 5)],
        [(8, 9), (21, 22), (1, 2), (3, 4)],
        [(2, 3)]
    ], expectedScore: 220_000, expectedShowers: 32, expectedExchanges: 98)

}
