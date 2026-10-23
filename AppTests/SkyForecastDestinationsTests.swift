import XCTest
import StarfallCore
@testable import Starfall

final class SkyForecastDestinationsTests: XCTestCase {
    @MainActor func testFifthLanternPreviewKeepsItsActualFamiliesAndOneBasedDestinationsInOrder() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        for _ in 0..<4 { _ = try XCTUnwrap(game.letStarsFall()) }
        let snapshot = SkyForecastSnapshot(forecast: game.incoming)
        XCTAssertEqual(snapshot.entries.map(\.id), [20, 21, 22, 23, 24])
        XCTAssertEqual(snapshot.entries.map(\.family), [.colored(.mint), .colored(.rose), .colored(.aqua), .colored(.rose), .colored(.amber)])
        XCTAssertEqual(snapshot.entries.map(\.column), [7, 6, 1, 2, 4])
        XCTAssertEqual(snapshot.accessibilityValue,
            "Mint angular meteor shard, Pip, column 7, then Rose tall glint shard, Twinkle, column 6, then Aqua swept comet shard, Spark, column 1, then Rose tall glint shard, Twinkle, column 2, then Amber irregular sun shard, Sunny, column 4")
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 1), 7)
        XCTAssertEqual(snapshot.entries[3].column, 2, "The arriving Rose now names the same full column as the ceiling")
    }

    @MainActor func testRepeatedColumnsAndUnsortedIdentitiesStayAttachedToTheirOrderedStars() {
        let forecast = [IncomingStar(id: 40, kind: .aqua, column: 6),
                        IncomingStar(id: 12, kind: .rose, column: 0),
                        IncomingStar(id: 99, kind: .amber, column: 6)]
        let snapshot = SkyForecastSnapshot(forecast: forecast)
        XCTAssertEqual(snapshot.entries.map(\.id), [40, 12, 99])
        XCTAssertEqual(snapshot.entries.map(\.column), [7, 1, 7])
        XCTAssertEqual(snapshot.entries.map(\.family), [.colored(.aqua), .colored(.rose), .colored(.amber)])
        XCTAssertEqual(snapshot.accessibilityValue,
            "Aqua swept comet shard, Spark, column 7, then Rose tall glint shard, Twinkle, column 1, then Amber irregular sun shard, Sunny, column 7")
        XCTAssertEqual(forecast.map(\.column), [6, 0, 6], "Presentation cannot rewrite the Core destinations")
    }

    @MainActor func testColoredAndRetainedColorlessRolesUseTheirExistingIdentityDescriptions() {
        let examples: [(IncomingStar, SkyIdentity, String)] = [
            (.init(id: 0, kind: .aqua, column: 0), .colored(.aqua), "Aqua swept comet shard, Spark"),
            (.init(id: 1, kind: .amber, column: 0), .colored(.amber), "Amber irregular sun shard, Sunny"),
            (.init(id: 2, kind: .mint, column: 0), .colored(.mint), "Mint angular meteor shard, Pip"),
            (.init(id: 3, kind: .rose, column: 0), .colored(.rose), "Rose tall glint shard, Twinkle"),
            (.init(id: 4, kind: .violet, column: 0), .colored(.violet), "Violet broad lens shard, Nova"),
            (.init(id: 5, kind: nil, column: 0), .dusk, "Dark notched shard, Dusk"),
            (.init(id: 6, kind: nil, column: 0, light: true), .white, "White Opal Orb"),
            (.init(id: 7, kind: nil, column: 0, gravity: .magnet), .magnet, "Attraction field"),
            (.init(id: 8, kind: nil, column: 0, gravity: .hole), .hole, "Gravity hole")
        ]
        for (star, identity, description) in examples {
            let snapshot = SkyForecastSnapshot(forecast: [star])
            XCTAssertEqual(snapshot.entries.first?.id, star.id)
            XCTAssertEqual(snapshot.entries.first?.family, identity)
            XCTAssertEqual(snapshot.accessibilityValue, description + ", column 1")
        }
    }

    @MainActor func testReadingTheForecastPreservesSavedStateAndTheNextRandomContinuation() throws {
        var source = SkyTutorial.storyRoom.game()
        _ = try XCTUnwrap(source.nudge(from: Cell(0, 1), to: Cell(0, 2)))
        let bytes = try SkySaveArchive.encode(source)
        let snapshot = SkyForecastSnapshot(forecast: source.incoming)
        _ = snapshot.accessibilityValue
        XCTAssertEqual(snapshot, SkyForecastSnapshot(forecast: source.incoming))
        XCTAssertEqual(try SkySaveArchive.encode(source), bytes)

        var queried = source, control = try SkySaveArchive.decode(bytes)
        let actual = try XCTUnwrap(queried.letStarsFall())
        let expected = try XCTUnwrap(control.letStarsFall())
        XCTAssertNil(actual.blockedColumn)
        XCTAssertEqual(actual.forecast, expected.forecast)
        XCTAssertEqual(actual.arrivals, expected.arrivals)
        XCTAssertEqual(queried, control, "The next seeded forecast and all committed state remain identical")
        XCTAssertEqual(try SkySaveArchive.encode(source), bytes)
    }

    @MainActor func testStateLabelsAndColumnHintExplainTheNumbersWithoutPredictingRisk() {
        let forecast = FallingSky.freshChallenge(.firstLight).incoming
        XCTAssertEqual(SkyForecastDestinations(forecast: forecast, arriving: false).stateLabel, "Next columns")
        XCTAssertEqual(SkyForecastDestinations(forecast: forecast, arriving: true).stateLabel, "Arriving columns")
        XCTAssertEqual(SkyCopy.text(.forecastColumnsHint), "Columns count from 1 at the left to 7 at the right.")
        let value = SkyForecastSnapshot(forecast: forecast).accessibilityValue
        XCTAssertFalse(value.contains("full"))
        XCTAssertFalse(value.contains("blocked"))
    }

    @MainActor func testBothFullBoardVersionsHaveNoShowerDestinations() throws {
        let historical = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        for game in [historical, FallingSky.fullBoardLantern()] {
            XCTAssertTrue(game.usesFullBoardRefill)
            let snapshot = SkyForecastSnapshot(forecast: game.incoming)
            XCTAssertTrue(snapshot.entries.isEmpty)
            XCTAssertEqual(snapshot.accessibilityValue, "")
        }
        XCTAssertFalse(SkyForecastSnapshot(forecast: FallingSky.freshSurvival(seed: 5).incoming).entries.isEmpty)
    }
}
