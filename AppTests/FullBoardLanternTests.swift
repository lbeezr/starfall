import XCTest
import SpriteKit
import UIKit
import StarfallCore
@testable import Starfall

@MainActor private final class FullBoardPresenter: FallingSkyPresenting {
    var reduceMotion = false
    var rendered: FallingSky?
    var prepared: FallingSky?
    var openings: [() -> Void] = []
    var phases: [(Int) -> Void] = []
    var completions: [() -> Void] = []
    func render(_ game: FallingSky) { rendered = game }
    func prepareOpening(_ game: FallingSky) { prepared = game }
    func presentOpening(_ game: FallingSky, completion: @escaping () -> Void) { openings.append(completion) }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) { completions.append(completion) }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        phases.append(phaseBegan); completions.append(completion)
    }
}

final class FullBoardLanternTests: XCTestCase {
    @MainActor private func defaults() -> UserDefaults {
        let suite = "Starfall.FullBoard.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        return defaults
    }

    @MainActor func testLanternSelectionOnlyStagesAndCancelPreservesRetainedSkyAndMapOrigin() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.startFirstLight(); store.setSuspended(false); store.callShower(); presenter.finish()
        store.setSuspended(true)
        let retained = store.game, archive = defaults.data(forKey: SkySaveArchive.key)
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.worldMap, hasSavedSky: true), .worldMap)
        XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true), .staged)
        let skyID = try XCTUnwrap(flow.entryID)
        XCTAssertNil(flow.handle(.fullBoardLantern, hasSavedSky: true), "Unidentified Entry callbacks cannot change selection")
        XCTAssertEqual(flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: skyID), .staged)
        let fullID = try XCTUnwrap(flow.entryID)
        XCTAssertNotEqual(fullID, skyID)
        XCTAssertEqual(flow.entry, .fullBoardLantern)
        XCTAssertNil(flow.handle(.begin, hasSavedSky: true, entryID: skyID))
        XCTAssertNil(flow.handle(.firstLight, hasSavedSky: true, entryID: skyID))
        XCTAssertEqual(SkyHelpContext.selected(game: retained, entry: flow.entry).fullBoard, true)
        XCTAssertEqual(RestorationPresentation.selected(game: retained, entry: flow.entry)?.progress.score, 0)
        clock.advance(100)
        XCTAssertEqual(store.game, retained); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), archive)
        XCTAssertEqual(flow.handle(.entryBack, hasSavedSky: true, entryID: fullID), .worldMap)
        XCTAssertEqual(flow.handle(.worldBack, hasSavedSky: true), .home)
        XCTAssertEqual(store.game, retained); XCTAssertNil(clock.deadline)

        _ = flow.handle(.firstLight, hasSavedSky: true)
        _ = flow.handle(.fullBoardLantern, hasSavedSky: true, entryID: flow.entryID)
        XCTAssertEqual(flow.handle(.firstLight, hasSavedSky: true, entryID: flow.entryID), .staged)
        XCTAssertEqual(flow.entry, .firstLight)
        XCTAssertFalse(SkyHelpContext.selected(game: retained, entry: flow.entry).fullBoard)
    }

    @MainActor func testBeginCommitsOpeningAndNeverStartsAutomaticOrManualRain() throws {
        let defaults = defaults(), presenter = FullBoardPresenter(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        var flow = SkyFlowState(arguments: [])
        _ = flow.handle(.firstLight, hasSavedSky: false)
        _ = flow.handle(.fullBoardLantern, hasSavedSky: false, entryID: flow.entryID)
        let id = try XCTUnwrap(flow.entryID)
        guard case .began(let choice) = flow.handle(.begin, hasSavedSky: false, entryID: id) else {
            return XCTFail("Begin must commit the selected full board")
        }
        store.beginEntry(choice)
        let opening = FallingSky.fullBoardLantern()
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(store.dialogue.line, opening.challengeGuideLine)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), opening)
        XCTAssertEqual(presenter.prepared, opening)
        XCTAssertTrue(store.openingPending); XCTAssertNil(clock.deadline)
        store.setSuspended(false)
        XCTAssertEqual(presenter.openings.count, 1)
        XCTAssertFalse(store.canReceiveInput)
        store.togglePause(); store.callShower(); clock.advance(100)
        XCTAssertEqual(store.game, opening); XCTAssertNil(clock.deadline)
        presenter.openings[0]()
        XCTAssertTrue(store.canReceiveInput)
        XCTAssertNil(clock.deadline)
        XCTAssertTrue(store.forecast.isEmpty); XCTAssertNil(store.pressureCue)
        store.togglePause(); store.callShower(); clock.advance(100)
        XCTAssertEqual(store.game, opening); XCTAssertNil(clock.deadline)
        store.setSuspended(true); store.setSuspended(false)
        XCTAssertEqual(presenter.openings.count, 1)
        XCTAssertNil(clock.deadline)
        store.setSuspended(true)
    }

    @MainActor func testRefillOutcomeSavesBeforePresentationAndRestoresReplayWithSameRules() throws {
        let defaults = defaults(), presenter = FullBoardPresenter(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.beginEntry(.fullBoardLantern); store.setSuspended(false); presenter.openings[0]()
        let before = store.game
        var expected = before
        let turn = try XCTUnwrap(expected.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertGreaterThan(turn.displayAward, 0)
        XCTAssertFalse(turn.resolutionPhases.flatMap(\.refillArrivals).isEmpty)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 1), Cell(1, 2)),
            snapshot: before, generation: store.constellationInputGeneration))
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), expected)
        XCTAssertEqual(expected.occupiedCount, 49)
        XCTAssertEqual(expected.turns, 1)
        XCTAssertNil(clock.deadline)
        let saved = defaults.data(forKey: SkySaveArchive.key)
        let restoredPresenter = FullBoardPresenter(), restoredClock = ManualRainClock()
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: restoredPresenter, clock: restoredClock)
        XCTAssertEqual(restored.game, expected)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
        XCTAssertFalse(restored.openingPending)
        XCTAssertTrue(restored.message.contains("Full Board"))
        XCTAssertEqual(restored.dialogue.line?.id, "guide.full-board-restore.1")
        restored.setSuspended(false)
        XCTAssertTrue(restoredPresenter.openings.isEmpty)
        XCTAssertNil(restoredClock.deadline)
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, before)
        XCTAssertTrue(restored.game.usesFullBoardRefill)
        restored.beginEntry(.firstLight)
        XCTAssertEqual(restored.game, FallingSky.freshChallenge(.firstLight))
        XCTAssertFalse(restored.game.usesFullBoardRefill)
        restored.setSuspended(true)
        store.setSuspended(true)
    }

    @MainActor func testRestartRejectsStaleFullBoardReceiptsAndKeepsFallingSkyClock() throws {
        let presenter = FullBoardPresenter(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults(), arguments: [], presenter: presenter, clock: clock, feedback: feedback)
        store.startFullBoardLantern(); store.setSuspended(false); presenter.openings[0]()
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1, 1), Cell(1, 2)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        let stalePhase = try XCTUnwrap(presenter.phases.first)
        let staleCompletion = try XCTUnwrap(presenter.completions.first)
        store.startFirstLight()
        let sky = store.game
        XCTAssertEqual(sky.challengeRevision, 4)
        stalePhase(0); staleCompletion(); presenter.openings[0]()
        XCTAssertEqual(store.game, sky)
        XCTAssertNil(store.celebration)
        XCTAssertEqual(feedback.clears, 0)
        store.togglePause()
        presenter.openings[1]()
        XCTAssertNotNil(clock.deadline, "The comparison must preserve normal Falling Sky scheduling")
        store.callShower()
        XCTAssertEqual(store.game.turns, 1)
        XCTAssertFalse(store.game.usesFullBoardRefill)
        store.setSuspended(true)
    }

    @MainActor func testSetupExchangeCountsAMoveWithoutPointsOrRain() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.startFullBoardLantern(); store.setSuspended(false)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0, 0), Cell(0, 1)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game.turns, 1)
        XCTAssertEqual(store.game.displayScore, 0)
        XCTAssertEqual(store.game.occupiedCount, 49)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
        XCTAssertNil(store.celebration)
        presenter.finish(); clock.advance(100)
        XCTAssertTrue(store.canReceiveInput)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(store.game.turns, 1)
        store.setSuspended(true)
    }

    @MainActor func testProductionFullBoardWinEarnsLanternRepairAndRestoreKeepsTheMode() throws {
        let defaults = defaults(), presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.startFullBoardLantern(); store.setSuspended(false)
        XCTAssertFalse(store.journey.journey.completed.contains(.firstLight))
        let witness = [(8, 9), (3, 10), (5, 12), (33, 40), (24, 31),
                       (22, 23), (23, 24), (28, 29), (36, 37), (32, 39)]
        for (from, to) in witness {
            XCTAssertTrue(store.performTechnique(.nudge(Cell(from / 7, from % 7), Cell(to / 7, to % 7)),
                snapshot: store.game, generation: store.constellationInputGeneration))
            XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
            XCTAssertEqual(store.game.occupiedCount, 49)
            presenter.finish()
        }
        XCTAssertEqual(store.game.displayScore, 150_000)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertTrue(store.journey.journey.completed.contains(.firstLight))
        XCTAssertTrue(store.journey.journey.canEnter(.ribbonCrossing))
        XCTAssertNil(clock.deadline)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(restored.game, store.game)
        XCTAssertTrue(restored.game.usesFullBoardRefill)
        XCTAssertTrue(restored.journey.journey.completed.contains(.firstLight))
        restored.beginEntry(.replay)
        XCTAssertEqual(restored.game, FallingSky.fullBoardLantern())
        XCTAssertTrue(restored.journey.journey.completed.contains(.firstLight))
        restored.beginEntry(.firstLight)
        XCTAssertEqual(restored.game, FallingSky.freshChallenge(.firstLight))
        store.setSuspended(true)
    }

    @MainActor func testV13RestorePreservesOriginalBytesAndDoesNotGrantLegacyWorldAccess() throws {
        let defaults = defaults()
        var retained = FallingSky.freshChallenge(.firstLight)
        XCTAssertNotNil(retained.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        let core = try JSONSerialization.jsonObject(with: JSONEncoder().encode(retained))
        let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 13, "game": core])
        defaults.set(bytes, forKey: SkySaveArchive.fourLineKey)
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
        XCTAssertEqual(store.game, retained)
        XCTAssertNil(defaults.object(forKey: SkySaveArchive.key))
        XCTAssertFalse(store.journey.journey.canEnter(.ribbonCrossing))
        store.setSuspended(false)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), retained)
        XCTAssertNotNil(defaults.object(forKey: SkySaveArchive.key))
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fourLineKey), bytes)
        store.beginEntry(.replay)
        XCTAssertEqual(store.game, FallingSky.freshChallenge(.firstLight))
        store.setSuspended(true)
    }

    @MainActor func testFullBoardRevisionCannotEnterHistoricalEnvelopesAndInvalidCurrentBlocksV13() throws {
        let game = FallingSky.fullBoardLantern()
        let core = try JSONSerialization.jsonObject(with: JSONEncoder().encode(game))
        for (key, version) in [(SkySaveArchive.fourLineKey, 13), (SkySaveArchive.patternKey, 12),
                               (SkySaveArchive.cascadeKey, 11), (SkySaveArchive.storyKey, 10),
                               (SkySaveArchive.worldKey, 9), (SkySaveArchive.agingKey, 8)] {
            let defaults = defaults()
            let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "game": core])
            defaults.set(bytes, forKey: key)
            XCTAssertNil(SkySaveArchive.load(from: defaults), key)
            guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail(key) }
            XCTAssertEqual(source, key)
            XCTAssertEqual(defaults.data(forKey: key), bytes)
        }
        let defaults = defaults()
        let old = try JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky.freshChallenge(.firstLight)))
        let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 13, "game": old])
        defaults.set(bytes, forKey: SkySaveArchive.fourLineKey)
        defaults.set(Data("invalid current".utf8), forKey: SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from: defaults))
        guard case .rejected(let source) = SkySaveArchive.inspect(from: defaults) else { return XCTFail("Current presence must block v13") }
        XCTAssertEqual(source, SkySaveArchive.key)
        try SkySaveArchive.save(game, to: defaults)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), game)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.fourLineKey), bytes)
        XCTAssertEqual(defaults.dictionary(forKey: SkySaveArchive.rejectedKey)?["sourceKey"] as? String, SkySaveArchive.key)
    }

    @MainActor func testHelpEntryReplayAndWelcomeDescribeFullBoardWithoutChangingSkyCopy() {
        let full = FallingSky.fullBoardLantern(), sky = FallingSky.freshChallenge(.firstLight)
        let context = SkyHelpContext(game: full)
        XCTAssertTrue(context.fullBoard)
        XCTAssertFalse(context.opalStorms)
        XCTAssertTrue(context.restorationHelp?.contains("no move limit") == true)
        XCTAssertFalse(context.recipeInstructions.contains("shower"))
        XCTAssertTrue(context.recipeInstructions.contains("refill"))
        let entry = SkyEntryRequest.fullBoardLantern.introduction(challenge: .firstLight)
        XCTAssertTrue(entry.text.contains("No timed showers or ceiling loss"))
        XCTAssertTrue(entry.text.contains("150,000"))
        let replay = SkyEntryRequest.replay.introduction(challenge: .firstLight, replayingRevision: 5, replayingTarget: 150_000)
        XCTAssertTrue(replay.text.contains("Full Board"))
        XCTAssertTrue(replay.text.contains("saved round stays"))
        let summary = SkyWelcomeSnapshot(game: full, hasSavedSky: true, paused: true).summary
        XCTAssertTrue(summary?.contains("Full Board") == true)
        XCTAssertTrue(summary?.contains("no timed showers") == true)
        XCTAssertFalse(summary?.contains("Paused") == true)
        XCTAssertEqual(SkyCopy.boardSummary(showers: 1, groups: 0, manualClears: false, automaticLineLength: 4, fullBoard: true).prefix(13), "Exchanges: 1.")
        XCTAssertFalse(SkyHelpContext(game: sky).fullBoard)
        XCTAssertTrue(sky.challengeHelpText?.contains("arriving star has nowhere to land") == true)
    }

    @MainActor func testRealScenePresentsRefillFlightsThenFinalBoardAndQuietModeHasSameResult() async throws {
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning,
                       "Normal-motion evidence requires system quiet modes off")
        let before = FallingSky.fullBoardLantern()
        var after = before
        let turn = try XCTUnwrap(after.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        let arrivals = turn.resolutionPhases.flatMap(\.refillArrivals)
        XCTAssertFalse(arrivals.isEmpty)
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try FullBoardSceneHost(scene: scene)
        defer { host.close() }
        var ready = false
        scene.run(.run { ready = true }, withKey: "test.full-board-ready")
        let readyLimit = ContinuousClock.now + .seconds(2)
        while !ready && ContinuousClock.now < readyLimit { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(ready)
        var complete = false, phases: [Int] = [], sawFlight = false
        scene.animate(turn, from: before, to: after, phaseBegan: { phases.append($0) }, completion: { complete = true })
        let limit = ContinuousClock.now + .seconds(15)
        while !complete && ContinuousClock.now < limit {
            sawFlight = sawFlight || arrivals.contains { scene.childNode(withName: "//sky.flight.\($0.star.id)") != nil }
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertTrue(complete)
        XCTAssertTrue(sawFlight, "Core refill arrivals must visibly fall between committed pop phases")
        XCTAssertEqual(phases, Array(turn.resolutionPhases.indices))
        assertBoard(after, in: scene)
        XCTAssertTrue(arrivals.allSatisfy { scene.childNode(withName: "//sky.flight.\($0.star.id)") == nil })
        scene.reduceMotion = true
        var quietCompletion = 0, quietPhases: [Int] = []
        scene.animate(turn, from: before, to: after, phaseBegan: { quietPhases.append($0) }, completion: { quietCompletion += 1 })
        XCTAssertEqual(quietCompletion, 1); XCTAssertTrue(quietPhases.isEmpty)
        assertBoard(after, in: scene)
        XCTAssertFalse(scene.hasActions())
    }

    @MainActor private func assertBoard(_ game: FallingSky, in scene: FallingSkyScene,
                                        file: StaticString = #filePath, line: UInt = #line) {
        let visible = scene.children[1].children.compactMap { $0 as? FallingSkyCharacter }
        XCTAssertEqual(visible.map(\.gem).sorted { $0.id < $1.id },
                       game.board.compactMap { $0 }.sorted { $0.id < $1.id }, file: file, line: line)
        for (index, gem) in game.board.enumerated() {
            guard let gem, let node = visible.first(where: { $0.gem.id == gem.id }) else { continue }
            let point = LandingGeometry(size: scene.size).scenePoint(Cell(index / 7, index % 7))
            XCTAssertEqual(node.position.x, point.x, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(node.position.y, point.y, accuracy: 0.01, file: file, line: line)
        }
    }
}

@MainActor private final class FullBoardSceneHost {
    private let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    private let window: UIWindow
    private let previous: UIWindow?
    init(scene: FallingSkyScene) throws {
        let session = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        previous = session.windows.first(where: \.isKeyWindow)
        window = UIWindow(windowScene: session); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        view.presentScene(scene)
    }
    func close() { view.presentScene(nil); window.isHidden = true; previous?.makeKey() }
}
