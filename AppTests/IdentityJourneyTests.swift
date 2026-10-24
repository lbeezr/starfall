import XCTest
import StarfallCore
@testable import Starfall

final class IdentityJourneyTests: XCTestCase {
    func testOpenSkyAndManualPracticeNeverBorrowAStoryRestorationSection() {
        let skies = [FallingSky.freshSurvival(seed: 42), FallingSky(seed: 42),
                     FallingSky(seed: 42).adoptingFeedingDusk(),
                     SkyTutorial.trace.game(), SkyTutorial.gap.game(), SkyTutorial.branch.game()]
        for game in skies {
            let help = SkyHelpContext(game: game)
            XCTAssertTrue(help.manualClears)
            XCTAssertFalse(help.challenge)
            XCTAssertNil(help.restorationSection,
                         "An Open Sky or manual practice sky must not acquire Lantern Landing’s automatic-pattern objective")
        }
        let restorationPractice = SkyHelpContext(game: SkyTutorial.restoration.game())
        XCTAssertEqual(restorationPractice.restorationSection?.body, SkyCopy.text(.helpChallenge))
        XCTAssertTrue(restorationPractice.restorationSection?.body.contains("18 starlight") == true)
    }

    func testSelectedRestorationHelpKeepsCurrentHistoricalAndFullBoardRules() throws {
        let currentTargets: [(StarfallChallenge, Int)] = [
            (.firstLight, 150_000), (.ribbonCrossing, 220_000), (.kiteHarbor, 17_000),
            (.seedMoon, 11_000), (.silverPools, 12_000), (.frostfruitOrchard, 15_000), (.sunwheelMill, 24_000)
        ]
        for (challenge, target) in currentTargets {
            let historical = FallingSky(challenge: challenge)
            let oldHelp = SkyHelpContext(game: historical)
            let oldSection = try XCTUnwrap(oldHelp.restorationSection)
            XCTAssertEqual(oldSection.title, challenge.helpTitle)
            XCTAssertEqual(oldSection.body, historical.challengeHelpText)
            XCTAssertTrue(oldSection.body.contains("18 starlight"))
            XCTAssertTrue(oldHelp.manualClears)
            XCTAssertFalse(oldHelp.automaticRecipes)

            let current = FallingSky.freshChallenge(challenge)
            let currentHelp = SkyHelpContext(game: current)
            let currentSection = try XCTUnwrap(currentHelp.restorationSection)
            XCTAssertEqual(currentSection.title, challenge.helpTitle)
            XCTAssertEqual(currentSection.body, current.challengeHelpText)
            XCTAssertTrue(currentSection.body.contains(SkyCopy.score(target)))
            XCTAssertFalse(currentSection.body.contains("18 starlight"))
            XCTAssertFalse(currentHelp.manualClears)
            XCTAssertEqual(currentHelp.automaticLineLength, 4)
        }
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...3 {
                let game = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision)))
                let help = SkyHelpContext(game: game)
                let section = try XCTUnwrap(help.restorationSection)
                XCTAssertEqual(section.title, challenge.helpTitle)
                XCTAssertEqual(section.body, game.challengeHelpText)
                XCTAssertEqual(help.manualClears, revision < 3)
                XCTAssertEqual(help.automaticRecipes, revision >= 2)
                if revision == 3 {
                    XCTAssertTrue(section.body.contains("full lines of 7"))
                    XCTAssertFalse(section.body.contains("straight lines of 4"))
                }
            }
        }
        let retainedFullBoard = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))
        for game in [retainedFullBoard, .fullBoardLantern(), .fullBoardRibbon()] {
            let help = SkyHelpContext(game: game)
            let section = try XCTUnwrap(help.restorationSection)
            XCTAssertEqual(section.title, try XCTUnwrap(game.challenge).helpTitle)
            XCTAssertEqual(section.body, game.challengeHelpText)
            XCTAssertTrue(help.fullBoard)
            XCTAssertFalse(help.manualClears)
            XCTAssertTrue(section.body.contains(SkyCopy.score(game.challenge == .ribbonCrossing ? 220_000 : 150_000)))
            XCTAssertFalse(section.body.contains("before an arriving star has nowhere to land"))
        }
    }

    func testPendingHelpUsesPreviewCapabilitiesWhileReplayUsesTheRetainedRound() throws {
        let retained = FallingSky(challenge: .firstLight)
        let retainedHelp = SkyHelpContext(game: retained)
        for entry in [SkyEntryRequest?.none, .initial, .replay] {
            XCTAssertEqual(SkyHelpContext.selected(game: retained, entry: entry).restorationSection,
                           retainedHelp.restorationSection)
        }
        let openSkyPreview = SkyHelpContext.selected(game: retained, entry: .fresh)
        XCTAssertNil(openSkyPreview.restorationSection)
        XCTAssertTrue(openSkyPreview.manualClears)
        XCTAssertFalse(openSkyPreview.automaticRecipes)

        let storyPreview = SkyHelpContext.selected(game: retained, entry: .firstLight)
        let storySection = try XCTUnwrap(storyPreview.restorationSection)
        XCTAssertEqual(storySection.body, FallingSky.freshChallenge(.firstLight).challengeHelpText)
        XCTAssertTrue(storySection.body.contains("150,000"))
        XCTAssertFalse(storySection.body.contains("18 starlight"))
        XCTAssertFalse(storyPreview.manualClears)

        let openSky = FallingSky.freshSurvival(seed: 42)
        for (entry, challenge, target) in [
            (SkyEntryRequest.fullBoardLantern, StarfallChallenge.firstLight, 150_000),
            (.fullBoardRibbon, .ribbonCrossing, 220_000)
        ] {
            let preview = SkyHelpContext.selected(game: openSky, entry: entry)
            let section = try XCTUnwrap(preview.restorationSection)
            XCTAssertEqual(section.title, challenge.helpTitle)
            XCTAssertTrue(section.body.contains(SkyCopy.score(target)))
            XCTAssertTrue(preview.fullBoard)
            XCTAssertFalse(preview.manualClears)
        }
        XCTAssertNil(SkyHelpContext.selected(game: openSky, entry: .replay).restorationSection)
        XCTAssertEqual(SkyHelpContext.selected(game: retained, entry: nil), retainedHelp,
                       "Returning from an uncommitted preview selects the retained 18-light instructions")
    }
}
