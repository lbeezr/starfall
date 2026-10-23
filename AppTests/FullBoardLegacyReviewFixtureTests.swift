import XCTest
import StarfallCore
@testable import Starfall

#if DEBUG
final class FullBoardLegacyReviewFixtureTests: XCTestCase {
    private let arguments = ["--starfalls-reset", "--dialogue-review", "--full-board-v5-review"]

    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FullBoardLegacyReview.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor func testFixtureIsTheUnplayedProductionVersionFiveOpening() throws {
        let game = try XCTUnwrap(ObservatoryReviewFixture.fullBoardV5(arguments: arguments))
        let definition = try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5))
        XCTAssertEqual(game, FallingSky(definition: definition))
        XCTAssertEqual(game.challengeRevision, 5)
        XCTAssertTrue(game.usesFullBoardRefill)
        XCTAssertEqual(game.displayTarget, 150_000)
        XCTAssertEqual(game.displayScore, 0)
        XCTAssertEqual(game.turns, 0)
        XCTAssertEqual(game.occupiedCount, 49)
        XCTAssertEqual(Set(game.board.compactMap { $0?.id }), Set(0..<49))
        XCTAssertTrue(game.board.allSatisfy { $0?.grown == false })
        XCTAssertTrue(game.recipes.isEmpty)
        XCTAssertTrue(game.incoming.isEmpty)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(SkyFlowScreen.initial(arguments: arguments), .playing)
    }

    @MainActor func testMissingRequiredFlagCannotSelectOrReplaceTheRetainedRound() throws {
        let rejected = [[], [arguments[2]], Array(arguments.dropFirst()),
                        [arguments[0], arguments[2]], Array(arguments.dropLast()),
                        arguments + [arguments[2]],
                        [arguments[0], arguments[1], "--full-board-v5-review=5"]]
        for request in rejected {
            XCTAssertNil(ObservatoryReviewFixture.fullBoardV5(arguments: request), "\(request)")
            let defaults = defaults(), saved = FallingSky.freshChallenge(.firstLight)
            try SkySaveArchive.save(saved, to: defaults)
            try WorldJourneyStore(defaults: defaults).select(.firstLight)
            let round = defaults.data(forKey: SkySaveArchive.key)
            let world = defaults.data(forKey: WorldJourneyStore.key)
            let store = FallingSkyStore(defaults: defaults, arguments: request,
                                       presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(store.game, request.contains("--starfalls-reset") ? FallingSky.freshSurvival(seed: 5) : saved)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
        }
    }

    @MainActor func testConflictingReviewsKeepTheirExistingSelectionSemantics() {
        let conflicts = [["--observatory-review"], ["--lantern-restoration-review=9"],
                         ["--lantern-restoration-review=bad"], ["--technique-review", "--technique-example=square"],
                         ["--sky-flow-review"], [WorldMapReviewFixture.marker], ["--world-legacy-review"],
                         ["--world-silver-complete-review"], ["--world-frostfruit-complete-review"],
                         ["--constellation-fixture=gap"], ["--gravity-fixture=trace"],
                         ["--dusk-fixture=warning"], ["--critical-mass-review"]]
        for conflict in conflicts {
            let request = arguments + conflict
            XCTAssertNil(ObservatoryReviewFixture.fullBoardV5(arguments: request), "\(conflict)")
            let baseline = FallingSkyStore(defaults: defaults(), arguments: Array(arguments.dropLast()) + conflict,
                                           presenter: FallingSkyRecorder(), clock: ManualRainClock())
            let actual = FallingSkyStore(defaults: defaults(), arguments: request,
                                         presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(actual.game, baseline.game, "\(conflict)")
            XCTAssertEqual(actual.journey.journey, baseline.journey.journey, "\(conflict)")
        }
    }

    @MainActor func testActivationAndActualExchangeSaveVersionFiveAndReplayKeepsIt() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: arguments, presenter: presenter, clock: clock)
        let opening = store.game
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key), "Fixture construction stays read-only")
        XCTAssertNil(defaults.object(forKey: WorldJourneyStore.key))
        XCTAssertFalse(store.hasSavedSky)
        XCTAssertTrue(store.journey.journey.completed.isEmpty)
        store.setSuspended(false)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 1), Cell(1, 2)), snapshot: opening,
                                            generation: store.constellationInputGeneration))
        let played = store.game
        XCTAssertEqual(played.challengeRevision, 5)
        XCTAssertEqual(played.displayScore, 66_000)
        XCTAssertEqual(played.turns, 1)
        XCTAssertEqual(played.occupiedCount, 49)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), played, "Ordinary actions save before presentation")
        XCTAssertTrue(store.journey.journey.completed.isEmpty)
        XCTAssertNil(clock.deadline)
        presenter.finish()
        store.setSuspended(true)

        let bytes = defaults.data(forKey: SkySaveArchive.key)
        let restored = FallingSkyStore(defaults: defaults, arguments: ["--dialogue-review"],
                                       presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(SkyFlowScreen.initial(arguments: ["--dialogue-review"]), .welcome)
        XCTAssertTrue(restored.hasSavedSky)
        XCTAssertEqual(restored.game, played)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, opening)
        XCTAssertEqual(restored.game.challengeRevision, 5)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertTrue(restored.journey.journey.completed.isEmpty)
    }

    @MainActor func testResetReviewUsesOnlyTheExistingDialogueDomain() throws {
        let suite = "Starfall.DialogueReview", review = UserDefaults(suiteName: suite)!
        let previous = review.persistentDomain(forName: suite)
        addTeardownBlock {
            review.removePersistentDomain(forName: suite)
            if let previous { review.setPersistentDomain(previous, forName: suite) }
        }
        let ordinary = UserDefaults.standard
        let keys = [SkySaveArchive.key, SkySaveArchive.fourLineKey, WorldJourneyStore.key,
                    SkySaveArchive.rejectedKey, WorldJourneyStore.rejectedKey, "soundEnabled", "starfall.haptics", "calmEffects"]
        let ordinaryValues = keys.map { ordinary.object(forKey: $0) as? NSObject }
        try SkySaveArchive.save(FallingSky.freshSurvival(seed: 91), to: review)
        let retained = review.data(forKey: SkySaveArchive.key)
        let store = FallingSkyStore.forSkyFlowApp(arguments: arguments)
        XCTAssertEqual(store.game.challengeRevision, 5)
        XCTAssertEqual(review.data(forKey: SkySaveArchive.key), retained, "Reset chooses a fixture without deleting saved bytes")
        store.setSuspended(false)
        XCTAssertEqual(SkySaveArchive.load(from: review), store.game)
        XCTAssertEqual(store.game.turns, 0)
        XCTAssertTrue(store.journey.journey.completed.isEmpty)
        store.setSuspended(true)
        for (index, key) in keys.enumerated() {
            XCTAssertEqual(ordinary.object(forKey: key) as? NSObject, ordinaryValues[index], key)
        }
        XCTAssertTrue(SkyDefaults.forApp(arguments: [arguments[2]]) === UserDefaults.standard)
    }
}
#endif
