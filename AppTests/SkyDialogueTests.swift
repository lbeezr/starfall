import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class SkyDialogueTests: XCTestCase {
    func testHomeAndOpenSkyGuidanceConnectModeActionsToTheReturnedDrawing() {
        XCTAssertEqual(SkyCopy.text(.homeStoryMode), "Story Mode")
        XCTAssertEqual(SkyCopy.text(.homeFreePlay), "Free Play")
        let storyPromise = SkyCopy.text(.homeStoryPromise)
        XCTAssertTrue(storyPromise.contains("automatic patterns"))
        XCTAssertTrue(storyPromise.contains("restore places"))
        XCTAssertFalse(storyPromise.contains("draw"))
        let openPromise = SkyCopy.text(.homeOpenPromise)
        XCTAssertTrue(openPromise.contains("Draw constellations"))
        XCTAssertTrue(openPromise.contains("room for showers"))
        XCTAssertFalse(openPromise.contains("automatic patterns"))

        let entry = SkyEntryRequest.fresh.introduction(challenge: nil)
        XCTAssertEqual(entry.id, "observatory.entry.1")
        XCTAssertTrue(entry.text.contains("Tap a matching group"), "Drawing remains one choice alongside ordinary taps")
        XCTAssertTrue(entry.text.contains("5 or more matching stars"))
        XCTAssertTrue(entry.text.contains("Only the stars you draw clear"))
        XCTAssertTrue(entry.text.contains("room for each shower"))
        let traceHelp = SkyCopy.text(.helpTrace)
        XCTAssertTrue(traceHelp.contains("Only the stars you trace will clear"))
        XCTAssertTrue(traceHelp.contains("When your drawing earns light, its shape returns with it"))

        let replay = SkyEntryRequest.replay.introduction(challenge: nil)
        XCTAssertTrue(replay.text.contains("same starting sky and shower rules"))
        XCTAssertTrue(replay.text.contains("current sky settings"))
        XCTAssertTrue(replay.text.contains("saved round stays until you tap Begin"))
    }

    @MainActor func testSwapAndMultitouchInstructionsFollowTheSavedControlRules() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...4 {
                let game = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision)))
                let swap = SkyCopy.swapInstructions(manualClears: SkyHelpContext(game: game).manualClears)
                let contact = SkyCopy.oneFingerInstructions(drawingEnabled: game.supportsManualClears)
                if revision >= 3 {
                    XCTAssertTrue(swap.contains("matching patterns pop"))
                    XCTAssertFalse(swap.contains("constellation"))
                    XCTAssertEqual(contact, "Use one finger to move a star.")
                } else {
                    XCTAssertEqual(swap, SkyCopy.text(.helpSwap))
                    XCTAssertTrue(swap.contains("draw a constellation"))
                    XCTAssertEqual(contact, "Use one finger to trace or move a star.")
                }
            }
        }
        let openSky = FallingSky(seed: 42)
        XCTAssertEqual(SkyCopy.swapInstructions(manualClears: SkyHelpContext(game: openSky).manualClears),
                       SkyCopy.text(.helpSwap))
        XCTAssertEqual(SkyCopy.oneFingerInstructions(drawingEnabled: openSky.supportsManualClears),
                       SkyCopy.text(.inputOneFinger))
    }

    func testBoardAndMenuSummariesSupplyOnlyTheirModesPlaceholders() {
        XCTAssertEqual(SkyCopy.boardSummary(showers: 2, groups: 4, manualClears: true, automaticLineLength: nil),
                       SkyCopy.text(.a11yBoardSummary, values: ["showers": "2", "groups": "4"]))
        let patterns = SkyCopy.boardSummary(showers: 2, groups: 4, manualClears: false, automaticLineLength: 7)
        XCTAssertEqual(patterns, "2 showers. Arrange matching squares of 4, crosses of 5, or full lines of 7.")
        XCTAssertFalse(patterns.contains("groups"))
        XCTAssertEqual(SkyCopy.boardSummary(showers: 2, groups: 4, manualClears: false, automaticLineLength: 4),
                       "2 showers. Arrange matching squares of 4, crosses of 5, or straight lines of 4 or more.")
    }

    @MainActor func testCascadeEntryReplayAndHelpFollowTheSelectedSavedRevision() throws {
        let practiceHelp = SkyCopy.text(.helpPracticeModes)
        XCTAssertEqual(practiceHelp, "Optional discoveries show how to make room below Falling Sky’s ceiling and follow Full Board’s clear, fall and refill. Tutorial also covers swaps and automatic patterns, Open Sky’s tap and trace controls and the original 18-light restoration exercise. Your saved sky and world stay unchanged.")
        let introduction = SkyCopy.text(.practiceIntro)
        XCTAssertTrue(introduction.hasPrefix("Start with a current Story square."))
        for text in [practiceHelp, introduction] {
            for scope in ["swaps and automatic patterns", "Open Sky’s tap and trace controls",
                          "original 18-light restoration exercise", "Your saved sky and world stay unchanged."] {
                XCTAssertTrue(text.contains(scope), scope)
            }
        }
        let firstChapter = try XCTUnwrap(SkyTutorial.allCases.first)
        XCTAssertEqual(firstChapter, .storySquare)
        var practice = firstChapter.game()
        XCTAssertEqual(practice, FallingSky.freshChallenge(.firstLight))
        XCTAssertFalse(practice.supportsManualClears)
        let firstAction = try XCTUnwrap(firstChapter.actions.first)
        let practiceTurn = try XCTUnwrap(firstAction.perform(in: &practice))
        XCTAssertNotNil(practiceTurn.exchange, "The advertised first lesson uses a swap")
        XCTAssertFalse(practiceTurn.resolutionPhases.isEmpty, "The first swap pops its patterns automatically")
        XCTAssertGreaterThan(practice.displayScore, 0)

        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let old = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: 1)))
            let cascade = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: 2)))
            let seven = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: 3)))
            let fresh = FallingSky.freshChallenge(challenge)
            let entry: SkyEntryRequest = challenge == .firstLight ? .firstLight : .ribbonCrossing
            let freshLine = entry.introduction(challenge: challenge,
                                              replayingRevision: old.challengeRevision,
                                              replayingTarget: old.displayTarget)
            XCTAssertEqual(freshLine.id, challenge.dialoguePrefix + ".patterns.entry.1",
                           "A new visit chooses current rules even while an older round is retained")
            XCTAssertTrue(freshLine.text.contains(SkyCopy.score(try XCTUnwrap(fresh.displayTarget))))
            XCTAssertEqual(SkyHelpContext.selected(game: old, entry: entry), SkyHelpContext(game: fresh))
            XCTAssertTrue(freshLine.text.contains("straight lines of 4 or more"))
            if challenge == .ribbonCrossing {
                XCTAssertTrue(freshLine.text.contains("closer together than at Lantern Landing"))
                XCTAssertTrue(freshLine.text.contains("Plan the falling survivors"))
            }
            for game in [old, cascade, seven, fresh] {
                let replay = SkyEntryRequest.replay.introduction(challenge: challenge,
                    replayingRevision: game.challengeRevision, replayingTarget: game.displayTarget)
                let variant = game.challengeRevision == 1 ? ".story" : game.challengeRevision == 2 ? ".cascade" : ".patterns"
                XCTAssertEqual(replay.id, challenge.dialoguePrefix + variant + ".replay.1")
                XCTAssertEqual(game.challengeGuideLine?.id, "guide." + challenge.dialoguePrefix + variant + ".1")
                XCTAssertTrue(replay.text.contains(SkyCopy.score(try XCTUnwrap(game.displayTarget))))
                XCTAssertEqual(SkyHelpContext.selected(game: game, entry: .replay), SkyHelpContext(game: game))
                XCTAssertEqual(SkyHelpContext(game: game).automaticRecipes, game.challengeRevision >= 2)
                XCTAssertEqual(SkyHelpContext(game: game).manualClears, game.challengeRevision < 3)
                if challenge == .ribbonCrossing {
                    let guide = try XCTUnwrap(game.challengeGuideLine)
                    if game.challengeRevision >= 3 {
                        XCTAssertTrue(replay.text.contains("With closer showers, plan where the survivors fall"))
                        XCTAssertTrue(replay.text.contains("Your saved round stays until you tap Begin"))
                        XCTAssertTrue(guide.text.contains("Showers arrive closer together here"))
                        XCTAssertTrue(guide.text.contains("plan the survivors so one pop sets up the next"))
                        XCTAssertTrue(guide.text.contains(SkyCopy.score(try XCTUnwrap(game.displayTarget))))
                        XCTAssertTrue(guide.text.contains(game.challengeRevision == 3
                            ? "full lines of 7" : "straight lines of 4 or more"))
                        for line in [freshLine, replay, guide] {
                            XCTAssertEqual(line.speaker, .spark)
                            XCTAssertEqual(line.priority, .help)
                            XCTAssertNil(line.seconds)
                        }
                    } else {
                        XCTAssertFalse(replay.text.contains("With closer showers"))
                        XCTAssertFalse(guide.text.contains("Showers arrive closer together here"))
                    }
                }
            }
            XCTAssertTrue(fresh.challengeHelpText?.contains("automatically") == true)
            XCTAssertTrue(fresh.challengeHelpText?.contains("straight lines of 4 or more") == true)
            XCTAssertTrue(fresh.challengeGuideLine?.text.contains("straight lines of 4 or more") == true)
            XCTAssertTrue(SkyHelpContext(game: fresh).recipeInstructions.contains("straight lines of 4 or more"))
            XCTAssertEqual(SkyHelpContext(game: fresh).automaticLineLength, 4)
            XCTAssertTrue(seven.challengeHelpText?.contains("full lines of 7") == true)
            XCTAssertTrue(seven.challengeGuideLine?.text.contains("full lines of 7") == true)
            XCTAssertTrue(SkyHelpContext(game: seven).recipeInstructions.contains("full lines of 7"))
            XCTAssertEqual(SkyHelpContext(game: seven).automaticLineLength, 7)
            XCTAssertTrue(cascade.challengeHelpText?.contains("automatically") == true)
            XCTAssertFalse(old.challengeHelpText?.contains("automatically") == true,
                           "A retained explicit-clear round must not promise automatic recipes")
        }
        let historical = FallingSky(challenge: .firstLight)
        XCTAssertFalse(SkyHelpContext(game: historical).automaticRecipes)
        XCTAssertTrue(historical.challengeHelpText?.contains("18 starlight") == true)
        let historicalRibbon = FallingSky(challenge: .ribbonCrossing)
        let retainedRibbonReplay = SkyEntryRequest.replay.introduction(challenge: .ribbonCrossing,
            replayingRevision: historicalRibbon.challengeRevision, replayingTarget: historicalRibbon.displayTarget)
        XCTAssertEqual(retainedRibbonReplay.id, "ribbon-crossing.replay.1")
        XCTAssertTrue(retainedRibbonReplay.text.contains("18 starlight"))
        XCTAssertFalse(retainedRibbonReplay.text.contains("closer showers"))
        let currentRibbonEntry = SkyEntryRequest.ribbonCrossing.introduction(challenge: .ribbonCrossing,
            replayingRevision: historicalRibbon.challengeRevision, replayingTarget: historicalRibbon.displayTarget)
        XCTAssertTrue(currentRibbonEntry.text.contains("220,000 starlight"),
                      "A new Entry takes its target from the current definition, not the retained 18-light round")
        XCTAssertFalse(currentRibbonEntry.text.contains("18 starlight"))
        XCTAssertTrue(SkyCopy.text(.helpCascadeTrace).contains("first stars to clear"))
        XCTAssertTrue(SkyCopy.text(.helpCascadeTrace).contains("falling stars also pop"))
        XCTAssertTrue(SkyCopy.text(.helpTrace).contains("Only the stars you trace will clear"))
        XCTAssertEqual(SkyCopy.text(.celebrationCascade, values: ["count": "3"]), "3 CHAIN!")
        XCTAssertEqual(SkyCopy.text(.celebrationLine), "Line!")
    }

    @MainActor func testKiteEntryReplayAndHelpUseTheSelectedRules() throws {
        let historical = FallingSky(challenge: .kiteHarbor)
        let fresh = FallingSky.freshChallenge(.kiteHarbor)
        let retainedBytes = try SkySaveArchive.encode(historical)
        XCTAssertEqual(fresh.challengeRevision, 4)
        XCTAssertEqual(fresh.displayTarget, 17_000)
        let entry = SkyEntryRequest.kiteHarbor.introduction(challenge: .kiteHarbor,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        let replay = SkyEntryRequest.replay.introduction(challenge: .kiteHarbor,
            replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
        let guide = try XCTUnwrap(fresh.challengeGuideLine)
        let help = try XCTUnwrap(fresh.challengeHelpText)
        XCTAssertEqual(entry.id, "kite-harbor.patterns.entry.1")
        XCTAssertEqual(replay.id, "kite-harbor.patterns.replay.1")
        XCTAssertEqual(guide.id, "guide.kite-harbor.patterns.1")
        for text in [entry.text, replay.text, guide.text, help] {
            XCTAssertTrue(text.contains("17,000 starlight"))
            XCTAssertTrue(text.contains("crowded column"))
            XCTAssertTrue(text.contains("below"))
            XCTAssertFalse(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("Ribbon Crossing"))
        }
        for text in [entry.text, guide.text, help] {
            XCTAssertTrue(text.contains("straight lines of 4 or more"))
            XCTAssertTrue(text.contains("automatically"))
        }
        XCTAssertTrue(replay.text.contains("Your saved round stays until you tap Begin"))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .kiteHarbor), SkyHelpContext(game: fresh))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .replay), SkyHelpContext(game: historical))
        XCTAssertFalse(SkyHelpContext(game: fresh).manualClears)
        XCTAssertEqual(SkyHelpContext(game: fresh).automaticLineLength, 4)
        let oldReplay = SkyEntryRequest.replay.introduction(challenge: .kiteHarbor,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        XCTAssertEqual(oldReplay.id, "kite-harbor.replay.1")
        XCTAssertEqual(historical.challengeGuideLine?.id, "guide.kite-harbor.1")
        for text in [oldReplay.text, try XCTUnwrap(historical.challengeGuideLine).text,
                     try XCTUnwrap(historical.challengeHelpText)] {
            XCTAssertTrue(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("automatically"))
        }
        XCTAssertTrue(SkyHelpContext(game: historical).manualClears)
        XCTAssertEqual(try SkySaveArchive.encode(historical), retainedBytes)
        XCTAssertFalse(StarfallChallenge.kiteHarbor.menuLabel.contains("18 starlight"))
        XCTAssertFalse(StarfallChallenge.kiteHarbor.menuHint.contains("18 starlight"))
    }

    @MainActor func testSeedEntryReplayAndHelpKeepTheGrownIngredientChoiceDistinct() throws {
        let historical = FallingSky(challenge: .seedMoon)
        let fresh = FallingSky.freshChallenge(.seedMoon)
        let retainedBytes = try SkySaveArchive.encode(historical)
        XCTAssertEqual(fresh.challengeRevision, 4)
        XCTAssertEqual(fresh.displayTarget, 11_000)
        XCTAssertEqual(fresh.displayScore, 0, "An authored grown ingredient is not an earned award")
        let ingredient = try XCTUnwrap(fresh.gem(at: Cell(0, 1)))
        XCTAssertEqual(ingredient.id, 1)
        XCTAssertEqual(ingredient.kind, .aqua)
        XCTAssertTrue(ingredient.grown)
        XCTAssertEqual(ingredient.value, 2)
        let entry = SkyEntryRequest.seedMoon.introduction(challenge: .seedMoon,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        let replay = SkyEntryRequest.replay.introduction(challenge: .seedMoon,
            replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
        let guide = try XCTUnwrap(fresh.challengeGuideLine)
        let help = try XCTUnwrap(fresh.challengeHelpText)
        XCTAssertEqual(entry.id, "seed-moon.patterns.entry.1")
        XCTAssertEqual(replay.id, "seed-moon.patterns.replay.1")
        XCTAssertEqual(guide.id, "guide.seed-moon.patterns.1")
        for text in [entry.text, replay.text, guide.text, help] {
            XCTAssertTrue(text.contains("11,000 starlight"))
            XCTAssertTrue(text.contains("grown aqua star"))
            XCTAssertFalse(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("Kite Harbor"))
            XCTAssertFalse(text.contains("chain"), "Separate Seed clears are not a causal or timed chain")
        }
        for text in [entry.text, guide.text, help] {
            XCTAssertTrue(text.contains("straight lines of 4 or more"))
            XCTAssertTrue(text.contains("automatically"))
        }
        XCTAssertTrue(help.contains("6,000 points"))
        XCTAssertTrue(help.contains("8,000"))
        XCTAssertTrue(help.contains("Waiting does not increase a grown star’s value"))
        XCTAssertTrue(help.contains("Other legal clears can finish the repair too"))
        XCTAssertTrue(replay.text.contains("Your saved round stays until you tap Begin"))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .seedMoon), SkyHelpContext(game: fresh))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .replay), SkyHelpContext(game: historical))
        XCTAssertFalse(SkyHelpContext(game: fresh).manualClears)
        XCTAssertEqual(SkyHelpContext(game: fresh).automaticLineLength, 4)
        let oldReplay = SkyEntryRequest.replay.introduction(challenge: .seedMoon,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        XCTAssertEqual(oldReplay.id, "seed-moon.replay.1")
        XCTAssertEqual(historical.challengeGuideLine?.id, "guide.seed-moon.1")
        for text in [oldReplay.text, try XCTUnwrap(historical.challengeGuideLine).text,
                     try XCTUnwrap(historical.challengeHelpText)] {
            XCTAssertTrue(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("automatically"))
        }
        XCTAssertTrue(SkyHelpContext(game: historical).manualClears)
        XCTAssertEqual(try SkySaveArchive.encode(historical), retainedBytes)
        XCTAssertFalse(StarfallChallenge.seedMoon.menuLabel.contains("18 starlight"))
        XCTAssertFalse(StarfallChallenge.seedMoon.menuHint.contains("18 starlight"))
    }

    @MainActor func testSilverEntryReplayAndHelpDescribeTheCausalFallingSurvivor() throws {
        let historical = FallingSky(challenge: .silverPools)
        let fresh = FallingSky.freshChallenge(.silverPools)
        let retainedBytes = try SkySaveArchive.encode(historical)
        XCTAssertEqual(fresh.challengeRevision, 4)
        XCTAssertEqual(fresh.displayTarget, 12_000)
        XCTAssertEqual(fresh.displayScore, 0)
        XCTAssertEqual(fresh.occupiedCount, 24)
        XCTAssertTrue(fresh.board.compactMap { $0 }.allSatisfy { !$0.grown })
        let entry = SkyEntryRequest.silverPools.introduction(challenge: .silverPools,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        let replay = SkyEntryRequest.replay.introduction(challenge: .silverPools,
            replayingRevision: fresh.challengeRevision, replayingTarget: fresh.displayTarget)
        let guide = try XCTUnwrap(fresh.challengeGuideLine)
        let help = try XCTUnwrap(fresh.challengeHelpText)
        XCTAssertEqual(entry.id, "silver-pools.patterns.entry.1")
        XCTAssertEqual(replay.id, "silver-pools.patterns.replay.1")
        XCTAssertEqual(guide.id, "guide.silver-pools.patterns.1")
        for text in [entry.text, replay.text, guide.text, help] {
            XCTAssertTrue(text.contains("12,000 starlight"))
            XCTAssertTrue(text.contains("support"))
            XCTAssertTrue(text.contains("aqua"))
            XCTAssertTrue(text.contains("chain"))
            XCTAssertFalse(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("Seed Moon"))
        }
        for text in [entry.text, guide.text, help] {
            XCTAssertTrue(text.contains("straight lines of 4 or more"))
            XCTAssertTrue(text.contains("automatically"))
        }
        XCTAssertTrue(help.contains("falls four rows"))
        XCTAssertTrue(help.contains("same action"))
        for award in ["5,000", "7,000", "14,000", "19,000"] { XCTAssertTrue(help.contains(award)) }
        XCTAssertTrue(help.contains("Those separate actions are not a chain"))
        XCTAssertTrue(help.contains("Other legal clears can finish too"))
        XCTAssertTrue(replay.text.contains("Your saved round stays until you tap Begin"))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .silverPools), SkyHelpContext(game: fresh))
        XCTAssertEqual(SkyHelpContext.selected(game: historical, entry: .replay), SkyHelpContext(game: historical))
        XCTAssertFalse(SkyHelpContext(game: fresh).manualClears)
        XCTAssertEqual(SkyHelpContext(game: fresh).automaticLineLength, 4)
        let oldReplay = SkyEntryRequest.replay.introduction(challenge: .silverPools,
            replayingRevision: historical.challengeRevision, replayingTarget: historical.displayTarget)
        XCTAssertEqual(oldReplay.id, "silver-pools.replay.1")
        XCTAssertEqual(historical.challengeGuideLine?.id, "guide.silver-pools.1")
        for text in [oldReplay.text, try XCTUnwrap(historical.challengeGuideLine).text,
                     try XCTUnwrap(historical.challengeHelpText)] {
            XCTAssertTrue(text.contains("18 starlight"))
            XCTAssertFalse(text.contains("automatically"))
        }
        XCTAssertTrue(SkyHelpContext(game: historical).manualClears)
        XCTAssertEqual(try SkySaveArchive.encode(historical), retainedBytes)
        XCTAssertFalse(StarfallChallenge.silverPools.menuLabel.contains("18 starlight"))
        XCTAssertFalse(StarfallChallenge.silverPools.menuHint.contains("18 starlight"))
    }

    @MainActor func testCurrentStoryStartupKeepsItsObjectiveAndAutomaticPatternGuidance() throws {
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools] {
            let suite = "Starfall.StoryStartupGuide.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: clock, feedback: SkyFeedbackRecorder())
            store.startChallenge(challenge)
            let opening = store.game
            let expected = try XCTUnwrap(opening.challengeGuideLine)
            store.setSuspended(false)
            store.togglePause() // The ordinary Begin handoff admits play and starts showers.
            XCTAssertFalse(store.isPaused)
            XCTAssertEqual(store.game, opening, "Admission must not consume an opening shower")
            XCTAssertEqual(store.guideLine, expected)
            XCTAssertEqual(store.dialogue.line, expected)
            XCTAssertTrue(store.guideLine.text.contains(SkyCopy.score(try XCTUnwrap(opening.displayTarget))))
            XCTAssertTrue(store.guideLine.text.contains("Swipe"))
            XCTAssertTrue(store.guideLine.text.contains("pattern pops automatically"))
            if challenge == .ribbonCrossing {
                XCTAssertTrue(store.guideLine.text.contains("Showers arrive closer together here"))
                XCTAssertTrue(store.guideLine.text.contains("plan the survivors so one pop sets up the next"))
                XCTAssertEqual(store.guideLine.speaker, .spark)
                XCTAssertEqual(store.guideLine.priority, .help)
                XCTAssertNil(store.guideLine.seconds)
            }
            XCTAssertEqual(clock.deadline, store.showerInterval)

            store.togglePause()
            XCTAssertTrue(store.isPaused)
            XCTAssertEqual(store.guideLine.id, "guide.paused.1")
            XCTAssertEqual(store.game, opening)
            XCTAssertNil(clock.deadline)
            store.togglePause()
            XCTAssertFalse(store.isPaused)
            XCTAssertEqual(store.guideLine, expected, "Resuming the same pattern round keeps its own instructions")
            XCTAssertEqual(store.game, opening)
            store.setSuspended(true)

            let restoredClock = ManualRainClock()
            let restored = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: restoredClock, feedback: SkyFeedbackRecorder())
            restored.setSuspended(false)
            XCTAssertEqual(restored.game, opening)
            XCTAssertTrue(restored.isPaused)
            XCTAssertEqual(restored.guideLine.id, "guide.restore.1", "Restore retains its intentional paused guidance")
            XCTAssertFalse(restored.openingPending)
            XCTAssertNil(restoredClock.deadline)
            restored.togglePause()
            XCTAssertFalse(restored.isPaused)
            XCTAssertEqual(restored.guideLine, expected, "Continuing a saved pattern round restores its own instructions")
            XCTAssertEqual(restored.game, opening)
            XCTAssertEqual(restoredClock.deadline, restored.showerInterval)
            restored.setSuspended(true)
        }
    }

    @MainActor func testManualSkyStartupAndResumeRetainTheirExistingGuidance() throws {
        var sources = [FallingSky.freshSurvival(seed: 5), FallingSky(challenge: .firstLight)]
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...2 {
                sources.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision))))
            }
        }
        for source in sources {
            let suite = "Starfall.ManualStartupGuide.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(source), forKey: SkySaveArchive.key)
            let store = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: ManualRainClock(), feedback: SkyFeedbackRecorder())
            store.setSuspended(false)
            XCTAssertTrue(store.game.supportsManualClears)
            store.togglePause()
            XCTAssertEqual(store.guideLine, SkyDialogueLibrary.line("guide.started"))
            XCTAssertFalse(store.isPaused)
            XCTAssertEqual(store.game, source)
            store.togglePause()
            XCTAssertEqual(store.guideLine.id, "guide.paused.1")
            store.togglePause()
            XCTAssertEqual(store.guideLine, SkyDialogueLibrary.line("guide.started"))
            XCTAssertEqual(store.game, source)
            store.setSuspended(true)
        }
    }

    @MainActor func testAutomaticSwapChainsPublishAggregateAwardsInsteadOfGenericSwapCopy() throws {
        for (challenge, depth, points) in [
            (StarfallChallenge.firstLight, 2, 15_000),
            (.ribbonCrossing, 3, 30_000)
        ] {
            let suite = "Starfall.CascadeCopy.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(FallingSky.freshChallenge(challenge)), forKey: SkySaveArchive.key)
            let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                clock: ManualRainClock(), feedback: feedback)
            store.setSuspended(false)
            XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 1), Cell(1, 2)),
                snapshot: store.game, generation: store.constellationInputGeneration))
            XCTAssertEqual(store.game.displayScore, points)
            XCTAssertEqual(store.guideLine.id, "guide.cascade.1")
            XCTAssertTrue(store.guideLine.text.contains("\(depth)-clear chain"))
            XCTAssertTrue(store.guideLine.text.contains("+\(points.formatted()) starlight"))
            XCTAssertFalse(store.guideLine.text.contains(SkyCopy.text(.techniqueMoved)))
            XCTAssertEqual(feedback.announcements.last, store.guideLine.spokenText)
            let announcements = feedback.announcements
            presenter.finish()
            XCTAssertEqual(feedback.announcements, announcements,
                           "Settling must not repeat the aggregate spoken result")
            XCTAssertEqual(store.guideLine.id, "guide.cascade.1")
            store.setSuspended(true)
        }
    }

    @MainActor func testPatternGrowthFeedbackFollowsActualCurrentStoryShowers() throws {
        for (challenge, showerCount) in [(StarfallChallenge.firstLight, 1), (.ribbonCrossing, 2)] {
            var game = FallingSky.freshChallenge(challenge)
            for _ in 1..<showerCount { _ = try XCTUnwrap(game.letStarsFall()) }
            let old = game
            let turn = try XCTUnwrap(game.letStarsFall())
            XCTAssertEqual(game.turns, showerCount)
            XCTAssertEqual(turn.arrivals.filter(\.grew).count, 1)
            XCTAssertTrue(turn.resolutionPhases.isEmpty)
            XCTAssertEqual(game.displayScore, 0)
            XCTAssertFalse(game.supportsManualClears)
            let result = SkyDialogueLibrary.result(for: turn, from: old, to: game,
                tracedCount: 0, recipe: nil, relayDepth: 0, techniqueResult: "")
            XCTAssertEqual(result.id, "guide.patterns-growth.1")
            XCTAssertEqual(result.speaker, .spark)
            XCTAssertEqual(result.priority, .routine)
            XCTAssertNil(result.seconds, "Current Story growth guidance remains available for player-paced reading")
            XCTAssertEqual(result.text, "Oh! A star grew. Grown stars carry twice the starlight, but each still counts as one star in a square, cross or straight line.")
            XCTAssertFalse(result.text.contains("tap match"))
            XCTAssertNil(SkyPressureCue(game: game))
            XCTAssertFalse(result.text.contains("room again"), "Growth alone is not a recovery clear")
        }
    }

    @MainActor func testManualGrowthFeedbackPreservesOpenSkyAndRetainedStoryControls() throws {
        var sources = [FallingSky.freshSurvival(seed: 5), FallingSky(challenge: .firstLight)]
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...2 {
                sources.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision))))
            }
        }
        var sawMultipleGrowth = false
        for source in sources {
            var game = source
            var growthResult: SkyDialogueLine?
            for _ in 0..<16 where !game.isOver {
                let old = game
                let turn = try XCTUnwrap(game.letStarsFall())
                let count = turn.arrivals.filter(\.grew).count
                guard count > 0 else { continue }
                XCTAssertTrue(game.supportsManualClears)
                XCTAssertTrue(turn.resolutionPhases.isEmpty)
                XCTAssertFalse(game.isOver)
                sawMultipleGrowth = sawMultipleGrowth || count > 1
                let result = SkyDialogueLibrary.result(for: turn, from: old, to: game,
                    tracedCount: 0, recipe: nil, relayDepth: 0, techniqueResult: "")
                XCTAssertEqual(result, SkyDialogueLibrary.line("guide.growth", values: [
                    "growth": SkyCopy.count(.eventGrowthOne, .eventGrowthMany, count)
                ]))
                XCTAssertTrue(result.text.contains("count as 2 toward a tap match"))
                growthResult = result
                break
            }
            XCTAssertNotNil(growthResult, "The production round must reach growth: revision \(source.challengeRevision), challenge \(String(describing: source.challenge))")
        }
        XCTAssertTrue(sawMultipleGrowth, "Retained production showers also exercise plural growth")
    }

    @MainActor func testPatternGrowthPreservesManualPublicationAndQuietAutomaticShowers() throws {
        for automatic in [false, true] {
            for (challenge, showerCount) in [(StarfallChallenge.firstLight, 1), (.ribbonCrossing, 2)] {
                let suite = "Starfall.PatternGrowth.\(UUID())"
                let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
                defer { defaults.removePersistentDomain(forName: suite) }
                defaults.set(try SkySaveArchive.encode(FallingSky.freshChallenge(challenge)), forKey: SkySaveArchive.key)
                let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder(), clock = ManualRainClock()
                let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                    clock: clock, feedback: feedback)
                store.setSuspended(false)
                if automatic { store.togglePause() }
                feedback.announcements.removeAll()
                for _ in 0..<showerCount {
                    if automatic { clock.advance(store.showerInterval) }
                    else { store.callShower() }
                    presenter.finish()
                }
                XCTAssertEqual(store.game.turns, showerCount)
                XCTAssertEqual(store.game.displayScore, 0)
                XCTAssertEqual(store.guideLine.id, "guide.patterns-growth.1")
                if automatic {
                    XCTAssertTrue(feedback.announcements.isEmpty, "Ordinary automatic growth must not interrupt exploration speech")
                    XCTAssertNotEqual(store.dialogue.line?.id, store.guideLine.id)
                } else {
                    XCTAssertEqual(store.dialogue.line, store.guideLine)
                    XCTAssertEqual(feedback.announcements.last, store.guideLine.spokenText)
                    XCTAssertEqual(feedback.announcements.count, showerCount)
                }
                let announcements = feedback.announcements
                presenter.finish()
                XCTAssertEqual(feedback.announcements, announcements, "Settlement must not repeat the growth result")
                store.setSuspended(true)
            }
        }
    }

    func testTypedInterfaceInventoryAndTemplatesRejectMissingExtraAndInjectedValues() throws {
        let catalog = SkyDialogueLibrary.catalog
        XCTAssertEqual(Set(try XCTUnwrap(catalog.copy).keys), Set(SkyCopy.Key.allCases.map(\.rawValue)))
        for key in SkyCopy.Key.allCases {
            let source = try XCTUnwrap(catalog.copy?[key.rawValue])
            let tokens = try SkyDialogueCatalog.placeholders(in: source)
            let values = Dictionary(uniqueKeysWithValues: tokens.map { ($0, "7") })
            let rendered = try catalog.copyText(key.rawValue, values: values)
            XCTAssertFalse(rendered.contains("{"), key.rawValue)
            XCTAssertFalse(rendered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, key.rawValue)
        }
        XCTAssertThrowsError(try catalog.copyText("missing"))
        XCTAssertThrowsError(try catalog.copyText("result.blocked"))
        XCTAssertThrowsError(try catalog.copyText("result.blocked", values: ["column": "4", "typo": "1"]))
        XCTAssertThrowsError(try catalog.copyText("result.blocked", values: ["column": "{score}"]))
        XCTAssertEqual(SkyCopy.count(.eventEatenOne, .eventEatenMany, 1), "I swallowed 1 star.")
        XCTAssertEqual(SkyCopy.count(.eventEatenOne, .eventEatenMany, 3), "I swallowed 3 stars.")
        let malformed = Data(#"{"schemaVersion":1,"scripts":[{"id":"x","lines":[{"id":"x.1","speaker":"sunny","text":"Hello","priority":"help"}]}],"copy":{"bad":"An unmatched {token"}}"#.utf8)
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(malformed))
    }

    func testContextKeepsTheOriginalSpeakerAndForecastTense() throws {
        let game = ConstellationFixture.stormWarning.game()
        let dusk = SkyDialogueLibrary.line("guide.dusk-collapse", values: ["swallowed": "I swallowed 1 star."])
        let combined = SkyDialogueLibrary.contextual(dusk, game: game, cadence: game.cadenceStep)
        XCTAssertEqual(combined.speaker, .dusk)
        XCTAssertTrue(combined.text.contains("Left those for me?"))
        XCTAssertTrue(combined.text.contains("1 lighter shower before the storm."))
        XCTAssertFalse(combined.text.contains(".."))
        XCTAssertEqual(SkyDialogueLibrary.line("guide.paused").speaker, .twinkle)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.growth", values: ["growth": "A star grew"]).speaker, .spark)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.clear", values: ["score": "3"]).speaker, .pip)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.won", values: ["score": "20"]).speaker, .sunny)
    }

    @MainActor func testDuskTeasesOnlyAfterCommittedConsumptionOrAnActuallyDrainedClear() throws {
        func store(_ fixture: String) -> (FallingSkyStore, FallingSkyRecorder) {
            let suite = "Starfall.CopyDusk.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--dusk-fixture=\(fixture)"],
                presenter: presenter, clock: ManualRainClock())
            store.setSuspended(false)
            return (store, presenter)
        }
        let (eating, presenter) = store("imminent")
        eating.callShower()
        XCTAssertEqual(eating.guideLine.speaker, .dusk)
        XCTAssertTrue(eating.guideLine.text.contains("I swallowed 3 stars."))
        XCTAssertEqual(eating.game.score, 0)
        let committed = eating.game
        eating.setSuspended(true); presenter.finish()
        XCTAssertEqual(eating.game, committed)
        XCTAssertNil(eating.dialogue.line, "A stale callback cannot deliver a taunt")

        let (gray, grayPresenter) = store("zeroClear")
        gray.clear(Cell(0, 1)); grayPresenter.finish()
        XCTAssertEqual(gray.game.score, 0)
        XCTAssertEqual(gray.guideLine.id, "guide.gray-clear.1")
        XCTAssertEqual(gray.guideLine.speaker, .dusk)
        XCTAssertTrue(gray.guideLine.text.contains("No starlight that time"))
        XCTAssertTrue(gray.guideLine.text.contains("You cleared me away"))

        let (invalid, _) = store("unfed")
        let before = invalid.game
        invalid.clear(Cell(6, 6))
        XCTAssertEqual(invalid.game, before)
        XCTAssertEqual(invalid.guideLine.speaker, .sunny, "An invalid tap gets useful help, not a taunt")
        XCTAssertTrue(invalid.guideLine.text.hasPrefix(SkyDialogueLibrary.line("guide.match-help").text))
    }

    @MainActor func testDuskHelpUsesTheRetainedRuleAndTraceCelebrationUsesDistinctStars() throws {
        let suite = "Starfall.CopyRules.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for (rule, count) in [(DuskRule.feeding, "3"), (.patientFeeding, "5")] {
            let text = SkyCopy.text(.helpDusk, values: ["feeds": String(rule.feedingShowers)])
            XCTAssertTrue(text.contains("After \(count) feeding showers"))
            let help = SkyDialogueLibrary.line("guide.dusk-help", values: ["feeds": String(rule.feedingShowers)])
            XCTAssertTrue(help.text.contains("After \(count) feeding showers"))
        }
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults,
            arguments: ["--starfalls-reset", "--constellation-fixture=overlap"],
            presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        let path = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,5), Cell(1,6)]
        let original = store.game
        store.clearTracedConstellation(path, snapshot: original, generation: store.constellationInputGeneration)
        presenter.finish()
        XCTAssertEqual(store.guideLine.id, "guide.constellation.1")
        XCTAssertEqual(store.guideLine.speaker, .spark)
        XCTAssertTrue(store.guideLine.text.contains("You connected 5!"))
        XCTAssertEqual(store.game.occupiedCount, original.occupiedCount - 5)
    }

    private func line(_ id: String, speaker: SkySpeaker = .sunny,
                      priority: SkyDialogueLine.Priority = .routine, seconds: Double? = 5) -> SkyDialogueLine {
        .init(id: id, speaker: speaker, text: "Message \(id)", priority: priority, seconds: seconds)
    }

    func testCatalogRendersEveryBundledScriptAndRejectsAuthoringErrors() throws {
        let catalog = SkyDialogueLibrary.catalog
        for (id, tokens) in [
            ("ribbon-crossing.patterns.entry", Set(["target", "lines"])),
            ("guide.ribbon-crossing.patterns", Set(["target", "lines"])),
            ("ribbon-crossing.patterns.replay", Set(["target"]))
        ] {
            let script = try XCTUnwrap(catalog.scripts.first { $0.id == id })
            XCTAssertEqual(script.lines.count, 1)
            let line = try XCTUnwrap(script.lines.first)
            XCTAssertEqual(line.id, id + ".1")
            XCTAssertEqual(try SkyDialogueCatalog.placeholders(in: line.text), tokens)
            XCTAssertEqual(line.speaker, .spark)
            XCTAssertEqual(line.priority, .help)
            XCTAssertNil(line.seconds, "Ribbon identity remains player-paced copy")
        }
        let samples = ["star": "Aqua swept comet shard, Spark", "size": "Grown", "light": "2 light units", "count": "4", "score": "18", "target": "150,000", "lines": "straight lines of 4 or more", "stars": "5", "dark": "Dark star", "growth": "A star grew", "arrival": "One star arrived", "detail": "A fixture", "release": "The hole releases its stars after 3 more showers.", "feeds": "5", "swallowed": "I swallowed 3 stars.", "shape": "Square", "depth": "2", "phase": "Storm: 3 heavy showers left.", "cadence": "Showers are closer together now.", "summary": "Paused", "reason": "First Light complete!", "context": "A storm is coming", "columns": "2", "recovery": "Column 2 has room again."]
        for source in catalog.scripts {
            let values = samples.filter { key, _ in source.lines.contains { $0.text.contains("{\(key)}") } }
            let rendered = try catalog.script(source.id, values: values)
            XCTAssertFalse(rendered.lines.isEmpty)
            XCTAssertTrue(rendered.lines.allSatisfy { !$0.text.contains("{") })
        }
        XCTAssertThrowsError(try catalog.script("typo"))
        XCTAssertThrowsError(try catalog.script("sky.won"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "A {broken"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "A stray }"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "{nested{token}}"))
        XCTAssertThrowsError(try catalog.script("sky.won", values: ["score": "18", "typo": "unused"]))
        let source = SkyDialogueScript(id: "test", lines: [line("one")])
        func data(version: Int = 1, scripts: [SkyDialogueScript]) throws -> Data {
            let encoded = try JSONEncoder().encode(scripts)
            let array = try JSONSerialization.jsonObject(with: encoded)
            return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "scripts": array])
        }
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(version: 2, scripts: [source])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [source, source])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [.init(id: "empty", lines: [])])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [.init(id: "long", lines: [
            .init(id: "bad", speaker: .sunny, text: String(repeating: "x", count: 401), priority: .help, seconds: nil)
        ])])))
        let bad = "{\"schemaVersion\":1,\"scripts\":[{\"id\":\"x\",\"lines\":[{\"id\":\"x.1\",\"speaker\":\"typo\",\"text\":\"Hello\",\"priority\":\"help\"}]}]}"
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(Data(bad.utf8)))
    }

    @MainActor func testSpeakerSequenceAndPriorityHaveOneCurrentMessageAndNoBacklog() {
        let session = SkyDialogueSession()
        XCTAssertFalse(session.play(.init(id: "empty", lines: [])))
        XCTAssertFalse(session.show(.init(id: "bad", speaker: .sunny, text: "{score}", priority: .help, seconds: nil)))
        let welcome = line("hello", speaker: .spark, priority: .help, seconds: nil)
        let end = line("end", speaker: .nova, priority: .help, seconds: nil)
        XCTAssertTrue(session.play(.init(id: "map.arrival", lines: [welcome, end])))
        XCTAssertEqual(session.line?.spokenText, "Spark. Message hello")
        XCTAssertTrue(session.hasNext)
        XCTAssertFalse(session.show(line("routine")))
        XCTAssertFalse(session.show(welcome), "Repeated events must not rewind a script")
        session.next()
        XCTAssertEqual(session.line?.speaker, .nova); XCTAssertFalse(session.hasNext)
        XCTAssertTrue(session.show(line("storm", speaker: .dusk, priority: .warning)))
        XCTAssertFalse(session.show(line("late-help", priority: .help)))
        XCTAssertTrue(session.show(line("won", speaker: .twinkle, priority: .outcome, seconds: nil)))
        XCTAssertFalse(session.show(line("late-storm", priority: .warning)))
        XCTAssertEqual(session.line?.id, "won")
        session.dismiss(); session.reopen()
        XCTAssertEqual(session.line?.id, "won"); XCTAssertTrue(session.visible)
        XCTAssertFalse(session.hasNext, "Discarded events never become a queued script")
    }

    @MainActor func testExpiryRejectsStaleCallbacksAfterNewMessageReopenAndReset() {
        let session = SkyDialogueSession()
        session.show(line("first")); let old = session.revision
        session.show(line("second", speaker: .pip))
        session.expire(revision: old)
        XCTAssertTrue(session.visible); XCTAssertEqual(session.line?.speaker, .pip)
        let current = session.revision
        session.dismiss(); session.reopen(); session.expire(revision: current)
        XCTAssertTrue(session.visible)
        session.expire(revision: session.revision)
        XCTAssertFalse(session.visible); XCTAssertEqual(session.line?.id, "second")
        XCTAssertTrue(session.show(line("second", speaker: .pip)), "Explicit repeated requests can reopen closed information")
        let stale = session.revision
        session.reset(); session.show(line("new-sky")); session.expire(revision: stale)
        XCTAssertEqual(session.line?.id, "new-sky"); XCTAssertTrue(session.visible)
        session.play(.init(id: "manual", lines: [line("a"), line("b")]))
        session.expire(revision: session.revision)
        XCTAssertTrue(session.visible); XCTAssertTrue(session.hasNext, "Scripts wait for the player")
    }

    @MainActor func testAllSpeakerAssetsArePackagedWithTransparentMarginsAtBoundedSize() throws {
        for speaker in SkySpeaker.allCases {
            let image = try XCTUnwrap(UIImage(named: speaker.portraitAsset), speaker.rawValue)
            let cg = try XCTUnwrap(image.cgImage)
            XCTAssertEqual(cg.width, 256); XCTAssertEqual(cg.height, 256)
            XCTAssertTrue([CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .first, .last].contains(cg.alphaInfo))
            var pixels = [UInt8](repeating: 0, count: 256 * 256 * 4)
            let context = try XCTUnwrap(CGContext(data: &pixels, width: 256, height: 256,
                bitsPerComponent: 8, bytesPerRow: 1024, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: 256, height: 256))
            for edge in 0..<256 {
                for (x, y) in [(edge, 0), (edge, 255), (0, edge), (255, edge)] {
                    XCTAssertLessThan(pixels[(y * 256 + x) * 4 + 3], 16, "Full tips need transparent margins: \(speaker)")
                }
            }
        }
    }

    func testIslandPlacementFallsBackForUnknownSmallAndAccessibleLayouts() {
        XCTAssertTrue(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 440, height: 956), topInset: 62, accessible: false))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "unknown", size: .init(width: 440, height: 956), topInset: 62, accessible: false))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 440, height: 956), topInset: 62, accessible: true))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 956, height: 440), topInset: 0, accessible: false))
    }

    func testEveryForecastStarFinishesOnBothPathsBeforeReset() {
        for count in 1...5 {
            for spacing in [0.105, 16.0/108] {
                for index in 0..<count {
                    // Previous fixed-spacing mapping ends at 1-index*spacing: followers never arrive.
                    let oldEndpoint = 1 - Double(index)*spacing
                    if index > 0 { XCTAssertLessThan(oldEndpoint, 1) }
                    let arrival = 0.96 - Double(count-1-index)*0.045
                    let atEnd = SkyTrailMotion.sample(progress: arrival, index: index, count: count, spacing: spacing)
                    XCTAssertEqual(atEnd.position, 1, accuracy: 0.00001)
                    XCTAssertEqual(atEnd.opacity, 1, accuracy: 0.00001)
                    let reset = SkyTrailMotion.sample(progress: 1, index: index, count: count, spacing: spacing)
                    XCTAssertEqual(reset.position, 1); XCTAssertEqual(reset.opacity, 0)
                    var last = 0.0
                    for frame in 0...300 {
                        let sample = SkyTrailMotion.sample(progress: Double(frame)/300, index: index, count: count, spacing: spacing)
                        XCTAssertGreaterThanOrEqual(sample.position, last)
                        XCTAssertTrue((0...1).contains(sample.position))
                        if sample.opacity < 1 { XCTAssertEqual(sample.position, 1) }
                        last = sample.position
                    }
                }
            }
        }
    }
}

extension SkyDialogueTests {
    func testFullColumnCanAcceptGrowthWithoutARecoveryClear() throws {
        var game = FallingSky.freshSurvival(seed: 14)
        for _ in 0..<18 { _ = try XCTUnwrap(game.letStarsFall()) }
        let old = game
        XCTAssertFalse(old.isOver)
        XCTAssertEqual(SkyBoardSettling.height(old.board, column: 0), 7)
        let turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertTrue(turn.arrivals.contains { $0.grew && $0.cell == Cell(6, 0) })
        XCTAssertNil(turn.blockedColumn)
        XCTAssertFalse(game.isOver, "A full column is not a guaranteed loss")
        XCTAssertEqual(game.occupiedCount, old.occupiedCount)
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 0), 7)
        XCTAssertNil(SkyPressureCue(game: game), "Open Sky retains its own feedback")
        let result = SkyDialogueLibrary.result(for: turn, from: old, to: game,
            tracedCount: 0, recipe: nil, relayDepth: 0, techniqueResult: "")
        XCTAssertEqual(result.id, "guide.growth.1")
        XCTAssertFalse(result.text.contains("room again"))
    }

    func testStoryPressureTracksFullColumnsAndACommittedRecovery() throws {
        var game = FallingSky.freshChallenge(.firstLight)
        XCTAssertNil(SkyPressureCue(game: game))
        for _ in 0..<4 { _ = try XCTUnwrap(game.letStarsFall()) }
        XCTAssertEqual((0..<7).map { SkyBoardSettling.height(game.board, column: $0) }, [6, 7, 6, 6, 6, 6, 4])
        XCTAssertEqual(SkyPressureCue(game: game)?.columns, [1])
        XCTAssertEqual(SkyPressureCue(game: game)?.text, "Column 2 is full.")
        XCTAssertEqual(game.displayScore, 0)

        var idle = game
        let blocked = try XCTUnwrap(idle.letStarsFall())
        XCTAssertEqual(blocked.blockedColumn, 1)
        XCTAssertTrue(idle.isOver)
        XCTAssertNil(SkyPressureCue(game: idle), "Terminal copy retains ownership of an actual loss")

        let old = game, forecast = game.incoming
        let turn = try XCTUnwrap(game.nudge(from: Cell(0, 1), to: Cell(0, 2)))
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        XCTAssertEqual(game.displayAward(for: turn), 5_000)
        XCTAssertEqual(game.incoming, forecast)
        XCTAssertEqual(game.turns, 4)
        XCTAssertEqual(SkyBoardSettling.height(game.board, column: 1), 3)
        XCTAssertNil(SkyPressureCue(game: game))
        let result = SkyDialogueLibrary.result(for: turn, from: old, to: game,
            tracedCount: 0, recipe: nil, relayDepth: 0, techniqueResult: "")
        let original = SkyDialogueLibrary.line("guide.automatic-recipe", values: ["score": "5,000"])
        XCTAssertEqual(result.id, original.id)
        XCTAssertEqual(result.speaker, original.speaker)
        XCTAssertEqual(result.priority, original.priority)
        XCTAssertEqual(result.seconds, original.seconds)
        XCTAssertEqual(result.text, original.text + " 4 stars · 4 light. 4,000 base + 1,000 size = 5,000 points. 4 more spaces above the stars in column 2. Column 2 has room again.")
        XCTAssertTrue(result.isValid)

        _ = try XCTUnwrap(game.letStarsFall())
        XCTAssertFalse(game.isOver, "The same fifth shower fits after the committed clear")
        XCTAssertEqual((0..<7).map { SkyBoardSettling.height(game.board, column: $0) }, [7, 4, 6, 7, 6, 7, 5])
        XCTAssertEqual(SkyPressureCue(game: game)?.text, "Columns 1, 4, 6 are full.")
    }

    func testStoryPressureUsesAllFullColumnsAndRetainsManualRuleBoundaries() throws {
        var ribbon = FallingSky.freshChallenge(.ribbonCrossing)
        for _ in 0..<4 { _ = try XCTUnwrap(ribbon.letStarsFall()) }
        XCTAssertEqual(SkyPressureCue(game: ribbon)?.columns, [0, 1, 3])
        XCTAssertEqual(SkyPressureCue(game: ribbon)?.text, "Columns 1, 2, 4 are full.")
        let old = ribbon
        XCTAssertEqual((0..<7).map { SkyBoardSettling.height(old.board, column: $0) }, [7, 7, 6, 7, 5, 6, 5])
        let turn = try XCTUnwrap(ribbon.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertEqual((0..<7).map { SkyBoardSettling.height(ribbon.board, column: $0) }, [5, 2, 1, 4, 4, 6, 5])
        XCTAssertNil(SkyPressureCue(game: ribbon))
        XCTAssertEqual(ribbon.displayAward(for: turn), 50_000)
        let result = SkyDialogueLibrary.result(for: turn, from: old, to: ribbon,
            tracedCount: 0, recipe: nil, relayDepth: 0, techniqueResult: "")
        let original = SkyDialogueLibrary.line(turn.resolutionPhases.count > 1 ? "guide.cascade" : "guide.automatic-recipe",
            values: turn.resolutionPhases.count > 1
                ? ["depth": String(turn.resolutionPhases.count), "score": "50,000"] : ["score": "50,000"])
        XCTAssertEqual(result.text, original.text + " 16 stars · 16 light. 16,000 base + 4,000 size + 30,000 chain = 50,000 points. Diamond marks: 6 survivors fell into later patterns. 16 more spaces above the stars in columns 1, 2, 3, 4, 5. Columns 1, 2, 4 have room again.")
        XCTAssertEqual(result.id, original.id)
        XCTAssertEqual(result.speaker, original.speaker)
        XCTAssertEqual(result.priority, original.priority)
        XCTAssertEqual(result.seconds, original.seconds)

        var retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 3)))
        for _ in 0..<4 { _ = try XCTUnwrap(retained.letStarsFall()) }
        XCTAssertEqual(SkyPressureCue(game: retained)?.text, "Column 2 is full.")

        var manual = [FallingSky.freshSurvival(seed: 5), FallingSky(challenge: .firstLight)]
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            for revision in 1...2 {
                manual.append(FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(challenge, revision: revision))))
            }
        }
        var witnessedFullManualColumn = false
        for var source in manual {
            for _ in 0..<16 where !source.isOver {
                _ = try XCTUnwrap(source.letStarsFall())
                witnessedFullManualColumn = witnessedFullManualColumn || (!source.isOver && (0..<7).contains {
                    SkyBoardSettling.height(source.board, column: $0) == 7
                })
                XCTAssertNil(SkyPressureCue(game: source), "Manual modes keep their existing guidance")
            }
        }
        XCTAssertTrue(witnessedFullManualColumn)
    }

    @MainActor func testStoryPressurePreservesAutomaticGuidanceAndRestoresWithoutRecoverySpeech() throws {
        for quiet in [false, true] {
            let suite = "Starfall.StoryPressure.\(UUID())"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder(), clock = ManualRainClock()
            presenter.reduceMotion = quiet
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                clock: clock, feedback: feedback)
            store.startChallenge(.firstLight)
            store.setSuspended(false)
            store.togglePause()
            let instructions = store.dialogue.line
            feedback.announcements.removeAll()
            for _ in 0..<4 { clock.advance(store.showerInterval); presenter.finish() }
            XCTAssertEqual(store.game.turns, 4)
            XCTAssertEqual(store.pressureCue?.text, "Column 2 is full.")
            XCTAssertEqual(store.dialogue.line, instructions, "Pressure never displaces the player-paced objective and action")
            XCTAssertTrue(feedback.announcements.isEmpty)
            let full = store.game
            store.setSuspended(true)
            clock.advance(30)
            XCTAssertEqual(store.game, full)
            XCTAssertEqual(store.pressureCue?.columns, [1])

            let restoredClock = ManualRainClock()
            let restored = FallingSkyStore(defaults: defaults, arguments: [],
                presenter: FallingSkyRecorder(), clock: restoredClock, feedback: SkyFeedbackRecorder())
            restored.setSuspended(false)
            XCTAssertEqual(restored.game, full)
            XCTAssertEqual(restored.pressureCue?.text, "Column 2 is full.")
            XCTAssertTrue(restored.isPaused)
            XCTAssertNil(restoredClock.deadline)
            XCTAssertEqual(restored.guideLine.id, "guide.restore.1")
            XCTAssertFalse(restored.guideLine.text.contains("room again"))
            restored.setSuspended(true)

            store.setSuspended(false)
            XCTAssertTrue(store.performTechnique(.nudge(Cell(0, 1), Cell(0, 2)),
                snapshot: store.game, generation: store.constellationInputGeneration))
            XCTAssertEqual(store.game.displayScore, 5_000)
            XCTAssertNil(store.pressureCue)
            XCTAssertTrue(store.guideLine.text.hasSuffix("Column 2 has room again."))
            XCTAssertEqual(feedback.announcements.last, store.guideLine.spokenText)
            let saved = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
            XCTAssertEqual(try SkySaveArchive.decode(saved), store.game, "The recovered board commits before presentation finishes")
            let announcements = feedback.announcements, revision = store.dialogue.revision
            presenter.finish(); presenter.finish()
            XCTAssertEqual(store.celebration?.displayAward, 5_000)
            XCTAssertEqual(feedback.announcements, announcements)
            XCTAssertEqual(store.dialogue.revision, revision)
            store.setSuspended(true)
        }
    }
}


extension SkyDialogueTests {
    @MainActor func testNewerHelpSurvivesPlayerAndShowerCompletionWithoutDuplicateSpeech() throws {
        for action in ["clear", "swap", "manualShower", "automaticShower"] {
            let suite = "Starfall.FeedbackOwnership.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(ObservatoryReviewFixture.game(dense: false)), forKey: SkySaveArchive.key)
            let presenter = FallingSkyRecorder(), feedback = SkyFeedbackRecorder(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults,
                arguments: [], presenter: presenter, clock: clock, feedback: feedback)
            store.setSuspended(false)
            switch action {
            case "clear": store.clear(Cell(0, 0))
            case "swap": XCTAssertTrue(store.requestInput(.swap(Cell(0, 2), Cell(0, 3)), snapshot: store.game,
                                                          generation: store.constellationInputGeneration))
            case "automaticShower": store.togglePause(); clock.advance(store.showerInterval)
            default: store.callShower()
            }
            XCTAssertEqual(presenter.completions.count, 1)
            if action == "clear" || action == "swap" {
                XCTAssertEqual(store.dialogue.line, store.pausedGuideLine)
                XCTAssertEqual(feedback.announcements.last, store.pausedGuideLine.spokenText,
                               "Committed result is immediate")
            }
            let empty = try XCTUnwrap((0..<7).map { Cell(6, $0) }.first {
                store.canClear($0) && store.game.gem(at: $0) == nil
            })
            store.clear(empty) // A newer invalid tap asks for help on an independent column.
            XCTAssertTrue(store.pausedGuideLine.text.contains("matching"))
            XCTAssertNil(store.inputMessage, "Ordinary help must not rely on the trace-error guard")
            let line = store.dialogue.line, revision = store.dialogue.revision
            let announcements = feedback.announcements
            presenter.finish(); presenter.finish()
            XCTAssertEqual(store.dialogue.line, line)
            XCTAssertEqual(store.dialogue.revision, revision)
            XCTAssertEqual(feedback.announcements, announcements)
            store.setSuspended(true)
        }
    }

    @MainActor func testCommittedClearPublishesFeedbackImmediatelyAndRestoresWithoutTransientCopy() throws {
        let suite = "Starfall.DialogueCompletion.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(FallingSky(seed: 5, generation: .current, duskRule: .patientFeeding)), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults,
            arguments: [],
            presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        for _ in 0..<6 { store.callShower(); presenter.finish() }
        let darkIndex = try XCTUnwrap(store.game.board.firstIndex { $0?.isDark == true })
        store.clear(Cell(darkIndex / 7, darkIndex % 7))
        let help = store.pausedGuideLine
        XCTAssertEqual(help.speaker, .dusk)
        XCTAssertTrue(help.text.contains("beside me to send me off"))
        let source = store.game, cell = Cell(0,0)
        let value = source.reward(of: source.group(at: cell))
        XCTAssertGreaterThanOrEqual(value, 3)
        store.clear(cell)
        XCTAssertEqual(store.game.score, value, "Core reward commits before the result animation")
        let clear = SkyDialogueLibrary.line("guide.clear", values: ["score": String(value)])
        XCTAssertEqual(value, 3, "This retained manual fixture removes three actual bodies")
        let clearWithRoom = SkyDialogueLine(id: clear.id, speaker: clear.speaker,
            text: clear.text + " 3 stars · 3 light = 3 points. 3 more spaces above the stars in columns 1, 2, 3.",
            priority: clear.priority, seconds: clear.seconds)
        XCTAssertEqual(store.pausedGuideLine, SkyDialogueLibrary.contextual(clearWithRoom, game: store.game, cadence: store.nextShowerCadence))
        let revision = store.dialogue.revision
        presenter.finish()
        XCTAssertEqual(store.dialogue.revision, revision, "Presentation completion must not repeat committed feedback")
        let committed = store.game
        let restored = FallingSkyStore(defaults: defaults, arguments: [],
            presenter: FallingSkyRecorder(), clock: ManualRainClock())
        restored.setSuspended(false)
        XCTAssertEqual(restored.game, committed)
        XCTAssertTrue(restored.isPaused)
        XCTAssertEqual(restored.pausedGuideLine, SkyDialogueLibrary.contextual(SkyDialogueLibrary.line("guide.restore"), game: restored.game, cadence: restored.nextShowerCadence))
        XCTAssertFalse(restored.pausedGuideLine.text.contains("+"))
    }
}
