import XCTest
import StarfallCore
@testable import Starfall

final class ModePracticeTests: XCTestCase {
    func testEntryPracticeUsesSelectedModeAndRejectsStaleSelectionWithoutChangingEntry() throws {
        var flow = SkyFlowState(arguments: [])
        XCTAssertNil(flow.handle(.modePractice, hasSavedSky: true))
        _ = flow.handle(.worldMap, hasSavedSky: true)
        _ = flow.handle(.firstLight, hasSavedSky: true)
        let skyID = try XCTUnwrap(flow.entryID)
        let skyEntry = flow
        XCTAssertNil(flow.handle(.modePractice, hasSavedSky: true))
        XCTAssertEqual(flow.handle(.modePractice, hasSavedSky: true, entryID: skyID), .modePractice(.storyRoom))
        XCTAssertEqual(flow, skyEntry, "Practice does not consume Begin or change its return destination")
        _ = flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: skyID)
        let fullEntry = flow
        XCTAssertNil(flow.handle(.modePractice, hasSavedSky: true, entryID: skyID))
        XCTAssertEqual(flow.handle(.modePractice, hasSavedSky: true, entryID: flow.entryID), .modePractice(.fullBoardRefill))
        XCTAssertEqual(flow, fullEntry)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: flow.entryID), .worldMap)
        XCTAssertNil(flow.handle(.modePractice, hasSavedSky: true, entryID: skyID))
    }

    func testHelpSelectsPracticeFromActualRulesRatherThanRetainedOrHistoricalMode() {
        let full = FallingSky.fullBoardLantern()
        let sky = FallingSky.freshChallenge(.firstLight)
        XCTAssertEqual(SkyHelpContext.selected(game: sky, entry: .fullBoardLantern).practiceChapter, .fullBoardRefill)
        XCTAssertEqual(SkyHelpContext.selected(game: full, entry: .firstLight).practiceChapter, .storyRoom)
        XCTAssertEqual(SkyHelpContext(game: full).practiceChapter, .fullBoardRefill)
        XCTAssertEqual(SkyHelpContext(game: sky).practiceChapter, .storyRoom)
        XCTAssertNil(SkyHelpContext(game: FallingSky(challenge: .firstLight)).practiceChapter)
        XCTAssertNil(SkyHelpContext(game: FallingSky.freshSurvival(seed: 91)).practiceChapter)
        XCTAssertNil(SkyEntryRequest.replay.practiceChapter, "Replay keeps its retained rules without suggesting a fresh mode")
    }

    @MainActor func testBothModeDiscoveriesKeepEitherCommittedRoundAndJourneyByteForByte() throws {
        for retained in [FallingSky.freshChallenge(.firstLight), .fullBoardLantern()] {
            for chapter in [SkyTutorial.storyRoom, .fullBoardRefill] {
                let suite = "Starfall.ModePractice.\(UUID())"
                let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                defer { defaults.removePersistentDomain(forName: suite) }
                var saved = retained
                _ = saved.nudge(from: Cell(1,1), to: Cell(1,2))
                try SkySaveArchive.save(saved, to: defaults)
                try WorldJourneyStore(defaults: defaults).select(.firstLight)
                let round = defaults.data(forKey: SkySaveArchive.key)
                let world = defaults.data(forKey: WorldJourneyStore.key)
                let presenter = FallingSkyRecorder(), clock = ManualRainClock()
                var writes = 0
                let practice = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
                                               tutorial: chapter, archiveWriter: { _, _ in writes += 1 })
                practice.setSuspended(false)
                XCTAssertNil(clock.deadline)
                let opening = practice.game
                XCTAssertFalse(practice.requestTap(Cell(0,0)))
                XCTAssertEqual(practice.game, opening)
                for action in chapter.actions {
                    switch action {
                    case .swap(let from, let to):
                        XCTAssertTrue(practice.requestInput(.swap(from,to), snapshot: practice.game,
                                                            generation: practice.constellationInputGeneration))
                    case .shower: practice.callShower()
                    default: XCTFail("Mode discoveries use ordinary exchanges and the announced shower")
                    }
                    presenter.finish()
                }
                XCTAssertTrue(practice.tutorial?.complete == true)
                let stale = presenter.completions.last
                practice.loadTutorial(chapter)
                stale?(); clock.advance(100)
                XCTAssertEqual(practice.game, opening)
                XCTAssertEqual(practice.tutorial?.step, 0)
                XCTAssertNil(clock.deadline)
                XCTAssertEqual(writes, 0)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), round)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                XCTAssertEqual(SkySaveArchive.load(from: defaults), saved)
                XCTAssertTrue(practice.journey.journey.completed.isEmpty)
                practice.setSuspended(true)
            }
        }
    }
}
