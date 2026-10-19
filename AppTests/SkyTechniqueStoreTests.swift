import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class SkyTechniqueStoreTests: XCTestCase {
    @MainActor func testDrawingArmingFeedbackRequiresContactAndRespectsPreferences() throws {
        let suite = "Starfall.HoldFeedback.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset","--technique-review","--technique-example=trace"],
                                    presenter:FallingSkyRecorder(),clock:ManualRainClock(),feedback:feedback)
        store.setSuspended(false)
        store.traceArmed(); XCTAssertTrue(feedback.armedPreferences.isEmpty)
        let hold = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        store.traceArmed()
        store.hapticsEnabled = false; store.traceArmed()
        store.endConstellationHold(hold); store.traceArmed()
        XCTAssertEqual(feedback.armedPreferences,[true,false])
        store.hapticsEnabled = true; store.setReducedMotion(true)
        let quietHold = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        store.traceArmed(); store.endConstellationHold(quietHold)
        XCTAssertEqual(feedback.armedPreferences,[true,false,false])
        store.setSuspended(true); store.traceArmed()
        XCTAssertEqual(feedback.armedPreferences.count,3)
    }

    @MainActor func testNativeHoldProgressArmsOnceAndQuietCueStaysStatic() async throws {
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled)
        let owner = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior = owner.windows.first(where:\.isKeyWindow), window = UIWindow(windowScene:owner)
        let view = SKView(frame:.init(x:0,y:0,width:390,height:844)), controller = UIViewController()
        controller.view = view; window.rootViewController = controller; window.frame = view.frame; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; prior?.makeKey() }
        let scene = FallingSkyScene(size:view.bounds.size)
        let game = SkyTechniqueExample.trace.game(), cell = Cell(0,2)
        scene.render(game); view.presentScene(scene)
        var ready = false; scene.run(.run { ready = true },withKey:"test.hold-ready")
        let readyDeadline = ContinuousClock.now + .seconds(2)
        while !ready && ContinuousClock.now < readyDeadline { try await Task.sleep(for:.milliseconds(5)) }
        XCTAssertTrue(ready)
        for quiet in [false,true] {
            scene.reduceMotion = quiet
            let surface = ConstellationTraceSurface.Surface(), mapping = ObservatoryGeometry(size:scene.size)
            var armed = 0
            surface.updateInput(.init(size:scene.size,enabled:true,generation:1,traceStart:{ _ in cell },tap:{ _ in },
                begin:{ _ in armed += 1; scene.showConstellationTrace([cell],ready:false) },move:{ _ in },end:{},
                cancel:{ scene.clearConstellationTrace() },contact:{ _ in scene.showContact(cell,drawingEligible:true); return true },swapStart:{ _ in true }))
            surface.beginInput(at:mapping.viewPoint(cell))
            let progress = scene.childNode(withName:"//sky.input.hold.progress")
            if quiet { XCTAssertNil(progress) }
            else {
                XCTAssertEqual(progress?.children.count,12)
                for mark in try XCTUnwrap(progress).children { XCTAssertEqual(mark.alpha,0.15,accuracy:0.001) }
                let progressDeadline = ContinuousClock.now + .seconds(1)
                while progress?.children.first?.alpha ?? 0 < 0.9 && ContinuousClock.now < progressDeadline {
                    try await Task.sleep(for:.milliseconds(5))
                }
                XCTAssertLessThan(progress?.children.last?.alpha ?? 1,0.9,"The cue progresses rather than appearing complete immediately")
                let pending = XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)?.cgImage())))
                pending.name = "hold-progress-native-scene"; pending.lifetime = .keepAlways; add(pending)
            }
            let armedDeadline = ContinuousClock.now + .seconds(2)
            while armed == 0 && ContinuousClock.now < armedDeadline { try await Task.sleep(for:.milliseconds(5)) }
            XCTAssertEqual(armed,1)
            XCTAssertNil(scene.childNode(withName:"//sky.input.hold.progress"))
            XCTAssertNotNil(scene.childNode(withName:"//sky.input.drawing.armed"))
            let image = XCTAttachment(image:UIImage(cgImage:try XCTUnwrap(view.texture(from:scene)?.cgImage())))
            image.name = "hold-armed-\(quiet ? "quiet" : "full")-native-scene"; image.lifetime = .keepAlways; add(image)
            let stale = surface.session.sequence
            surface.cancelInput(); surface.armDrawing(ticket:stale,generation:1)
            XCTAssertEqual(armed,1)
            XCTAssertNil(scene.childNode(withName:"//sky.input.drawing.armed"))
            scene.showContact(cell,drawingEligible:false)
            XCTAssertNil(scene.childNode(withName:"//sky.input.hold.progress"))
            scene.clearConstellationTrace()
        }
    }

    @MainActor private func request(_ action: SkyPlayerInput, in store: FallingSkyStore) -> Bool {
        store.requestInput(action, snapshot: store.game, generation: store.constellationInputGeneration)
    }

    @MainActor func testProductionSurfaceBuffersDuringMotionAndImmediatelyRetouchesQuietBoard() async throws {
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled)
        let owner = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior = owner.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: owner), view = SKView(frame: .init(x:0,y:0,width:390,height:844))
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.frame = view.frame; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; prior?.makeKey() }
        for quiet in [false, true] {
            let suite = "Starfall.BufferedNative.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = FallingSkyStore(defaults: defaults, arguments: ["--starfalls-reset", "--technique-review", "--technique-example=nudge"])
            let scene = store.scene
            scene.size = view.bounds.size; view.presentScene(scene)
            store.setSuspended(false); store.setReducedMotion(quiet)
            var ready = false
            scene.run(.run { ready = true }, withKey: "test.buffer-ready")
            let readyDeadline = ContinuousClock.now + .seconds(2)
            while !ready && ContinuousClock.now < readyDeadline { try await Task.sleep(for: .milliseconds(5)) }
            XCTAssertTrue(ready)
            let mapping = ObservatoryGeometry(size: scene.size)
            let session = SkyInteractionSession(), surface = ConstellationTraceSurface.Surface()
            func refreshSurface() {
                surface.updateInput(.init(size: scene.size, enabled: store.canReceiveInput, generation: store.constellationInputGeneration,
                    traceStart: { mapping.cell(at: $0) }, tap: { store.requestTap($0) }, begin: { _ in XCTFail("A swipe cannot arm drawing") },
                    move: { _ in }, end: {}, cancel: { session.cancelContact(release: store.endConstellationHold) },
                    contact: { session.acquireHold(at: mapping.cell(at: $0), using: store.beginResponsiveContact) },
                    swapStart: { mapping.cell(at: $0).map { store.game.gem(at: $0) != nil } ?? false },
                    swap: { from, to, generation in
                        XCTAssertTrue(store.requestInput(.swap(from, to), snapshot: store.game, generation: generation))
                    }))
            }
            let initial = store.game, id = try XCTUnwrap(initial.gem(at: Cell(1,2))?.id)
            refreshSurface()
            surface.beginInput(at: mapping.viewPoint(Cell(1,2)))
            let started = ProcessInfo.processInfo.systemUptime
            surface.moveInput(to: mapping.viewPoint(Cell(1,3)))
            surface.endInput(at: mapping.viewPoint(Cell(1,3)))
            XCTAssertEqual(store.busy,!quiet,"Quiet presentation has no remaining motion to own input")
            let first = store.game
            XCTAssertEqual(first.gem(at: Cell(0,3))?.id, id)
            refreshSurface()
            surface.beginInput(at: mapping.viewPoint(Cell(0,3)))
            surface.moveInput(to: mapping.viewPoint(Cell(0,4)))
            surface.endInput(at: mapping.viewPoint(Cell(0,4)))
            var expected = first
            XCTAssertNotNil(expected.nudge(from: Cell(0,3), to: Cell(0,4)))
            if quiet {
                XCTAssertNil(store.bufferedInput)
                XCTAssertNil(scene.childNode(withName: "//sky.input.buffered.direction"))
                XCTAssertFalse(store.busy)
                XCTAssertEqual(store.game,expected,"The second quiet swipe commits during input delivery")
            } else {
                XCTAssertNotNil(store.bufferedInput)
                XCTAssertNotNil(scene.childNode(withName: "//sky.input.buffered.direction"))
                XCTAssertEqual(store.game,first)
            }
            var firstMotion: TimeInterval? = quiet ? ProcessInfo.processInfo.systemUptime - started : nil
            let initialPosition = mapping.scenePoint(Cell(1,2))
            let deadline = ContinuousClock.now + .seconds(3)
            while store.busy && ContinuousClock.now < deadline {
                if firstMotion == nil, let node = scene.childNode(withName: "//sky.star.\(id)"),
                   hypot(node.position.x-initialPosition.x, node.position.y-initialPosition.y) > 1 {
                    firstMotion = ProcessInfo.processInfo.systemUptime - started
                }
                try await Task.sleep(for: .milliseconds(5))
            }
            XCTAssertFalse(store.busy); XCTAssertEqual(store.game, expected)
            XCTAssertNil(store.bufferedInput); XCTAssertNil(scene.childNode(withName: "//sky.input.buffered.direction"))
            let finalPosition = try XCTUnwrap(scene.childNode(withName: "//sky.star.\(id)")).position
            XCTAssertEqual(finalPosition.x, mapping.scenePoint(Cell(0,4)).x, accuracy: 0.01)
            XCTAssertEqual(finalPosition.y, mapping.scenePoint(Cell(0,4)).y, accuracy: 0.01)
            XCTAssertNotNil(firstMotion)
            let measurement = XCTAttachment(string: "quiet=\(quiet); first observed displacement seconds=\(firstMotion ?? -1); sequence seconds=\(ProcessInfo.processInfo.systemUptime-started)")
            measurement.name = "Native buffered sequence timing"; measurement.lifetime = .keepAlways; add(measurement)
            // Capture the bounded cue separately, after timing. UIKit hierarchy
            // snapshots may retain the previous SpriteKit frame during motion.
            scene.showBufferedInput(.swap(Cell(0,4), Cell(0,5)))
            let pixels = try XCTUnwrap(view.texture(from: scene)?.cgImage())
            let cueCapture = XCTAttachment(image: UIImage(cgImage: pixels))
            cueCapture.name = "buffered-input-\(quiet ? "quiet" : "full")"
            cueCapture.lifetime = .keepAlways; add(cueCapture)
            scene.showBufferedInput(nil)
            store.setSuspended(true)
        }
    }

    @MainActor func testBufferedSwapAcknowledgesThenCommitsExactlyOnceAfterContactRelease() throws {
        let (store, presenter, _, _) = fixture("nudge")
        let original = store.game
        XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
        let first = store.game
        let hold = try XCTUnwrap(store.beginResponsiveContact(at: Cell(1,2)))
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
        XCTAssertEqual(store.game, first)
        XCTAssertEqual(presenter.bufferedCue, .swap(Cell(1,2), Cell(0,2)))
        XCTAssertEqual(store.inputMessage, SkyCopy.text(.inputBuffered))
        presenter.completions[0]()
        XCTAssertEqual(store.game, first, "A live finger retains contact ownership")
        store.endConstellationHold(hold)
        XCTAssertEqual(store.game, original)
        XCTAssertEqual(presenter.completions.count, 2)
        XCTAssertNil(store.bufferedInput); XCTAssertNil(presenter.bufferedCue)
        presenter.completions[0](); store.endConstellationHold(hold)
        XCTAssertEqual(presenter.completions.count, 2)
        presenter.finish(); XCTAssertFalse(store.busy)
    }

    @MainActor func testLatestBufferedIntentReplacesPreviousAndNewContactCancelsIt() throws {
        let (store, presenter, _, _) = fixture("nudge")
        XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
        let first = store.game
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
        let retired = try XCTUnwrap(store.bufferedInput?.ticket)
        let latest = SkyPlayerInput.swap(Cell(1,2), Cell(1,1))
        XCTAssertTrue(request(latest, in: store))
        store.expireBufferedInput(ticket: retired)
        XCTAssertEqual(store.bufferedInput?.action, latest)
        let hold = try XCTUnwrap(store.beginResponsiveContact(at: Cell(1,2)))
        XCTAssertNil(store.bufferedInput); XCTAssertNil(presenter.bufferedCue)
        presenter.finish(); store.endConstellationHold(hold)
        XCTAssertEqual(store.game, first)
        XCTAssertEqual(presenter.completions.count, 1)
    }

    @MainActor func testExpiredBufferedInputNeverReplaysOnLateCompletion() throws {
        let (store, presenter, clock, _) = fixture("nudge")
        XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
        let first = store.game
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
        clock.advance(SkyBufferedInput.lifetime + 0.001)
        presenter.finish()
        XCTAssertNil(store.bufferedInput); XCTAssertNil(presenter.bufferedCue)
        XCTAssertEqual(store.game, first); XCTAssertEqual(presenter.completions.count, 1)
        XCTAssertEqual(store.inputMessage, SkyCopy.text(.inputBufferExpired))
        XCTAssertTrue(store.dialogue.line?.text.contains(SkyCopy.text(.inputBufferExpired)) == true,
                      "The older animation cannot overwrite newer cancellation feedback")
    }

    @MainActor func testPendingDeadlineExpiresWithoutAnyPresenterCompletion() async throws {
        let (store, presenter, _, _) = fixture("nudge")
        XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
        let first = store.game
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
        let deadline = ContinuousClock.now + .seconds(2)
        while store.bufferedInput != nil && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertNil(store.bufferedInput); XCTAssertNil(presenter.bufferedCue)
        XCTAssertEqual(store.inputMessage, SkyCopy.text(.inputBufferExpired))
        presenter.finish(); XCTAssertEqual(store.game, first)
    }

    @MainActor func testBufferedIdentityCannotFollowAReplacementOrIndependentCommit() throws {
        let (store, presenter, _, _) = fixture("nudge")
        XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
        let pending = try XCTUnwrap(store.bufferedInput)
        XCTAssertTrue(pending.matches(store.game))
        XCTAssertTrue(request(.swap(Cell(1,0), Cell(1,1)), in: store))
        XCTAssertFalse(pending.matches(store.game))
        XCTAssertNil(store.bufferedInput)
        let committed = store.game
        presenter.completions[0](); presenter.completions[1]()
        XCTAssertEqual(store.game, committed)
    }

    @MainActor func testLifecycleRetiresPendingIntentBeforeAnyStaleCallbacks() throws {
        for interruption in 0..<6 {
            let (store, presenter, _, _) = fixture("nudge")
            XCTAssertTrue(request(.swap(Cell(0,2), Cell(1,2)), in: store))
            XCTAssertTrue(request(.swap(Cell(1,2), Cell(0,2)), in: store))
            let pending = try XCTUnwrap(store.bufferedInput)
            switch interruption {
            case 0: store.setSuspended(true) // Settings and background share this boundary.
            case 1: store.restart(sameSky: true)
            case 2: store.setReducedMotion(true)
            case 3: store.scene.onLayout?()
            case 4: store.startFirstLight()
            default: store.settlePresentation(reason: "detachment")
            }
            let after = store.game
            XCTAssertNil(store.bufferedInput); XCTAssertNil(presenter.bufferedCue)
            presenter.completions[0](); store.expireBufferedInput(ticket: pending.ticket)
            XCTAssertEqual(store.game, after)
            XCTAssertNotEqual(store.inputMessage, SkyCopy.text(.inputBufferExpired))
        }
    }

    @MainActor func testQueuedTapCommitsOnlyAfterItsClearColumnsAreAvailable() throws {
        let (store, presenter, _, _) = fixture("nudge")
        XCTAssertTrue(request(.swap(Cell(1,2), Cell(1,1)), in: store))
        let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
        XCTAssertFalse(store.canClear(cell))
        let first = store.game
        var expected = first
        XCTAssertNotNil(expected.clear(cell))
        XCTAssertTrue(store.requestTap(cell))
        XCTAssertEqual(store.game, first)
        XCTAssertEqual(presenter.bufferedCue, .tap(cell))
        presenter.completions[0]()
        XCTAssertEqual(store.game, expected)
        XCTAssertNil(store.bufferedInput)
        presenter.completions[0](); XCTAssertEqual(presenter.completions.count, 2)
        presenter.finish()
    }

    @MainActor func testPendingInputPreservesCommittedSaveAndExactShowerRemainder() throws {
        let suite = "Starfall.BufferedSave.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var game = FallingSky(seed: 5, generation: .current); game.letStarsFall()
        defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false); store.togglePause()
        let deadline = try XCTUnwrap(clock.deadline)
        clock.advance(deadline - 0.04)
        let pairs = (0..<7).flatMap { column in [-1,1].map { (Cell(0,column), Cell(0,column+$0)) } }
        let (from, to) = try XCTUnwrap(pairs.first { from, to in
            var preview = store.game
            return preview.nudge(from: from, to: to) != nil && preview.canNudge(from: to, to: from)
        })
        XCTAssertTrue(request(.swap(from, to), in: store))
        let first = store.game
        XCTAssertTrue(request(.swap(to, from), in: store))
        let pending = try XCTUnwrap(store.bufferedInput)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), first)
        clock.advance(0.1)
        store.expireBufferedInput(ticket: pending.ticket)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, 0.04, accuracy: 0.0001)
        clock.advance(0.04)
        XCTAssertFalse(store.canReceiveInput)
        XCTAssertFalse(request(.swap(to, from), in: store), "Already-due rain retains priority")
        presenter.completions[0]()
        XCTAssertEqual(store.game.turns, first.turns + 1)
        XCTAssertNil(store.bufferedInput)
        store.setSuspended(true)
    }

    @MainActor private func fixture(_ name:String) -> (FallingSkyStore,FallingSkyRecorder,ManualRainClock,UserDefaults) {
        let suite="Starfall.TechniqueTests.\(UUID())", defaults=UserDefaults(suiteName:suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName:suite) }
        let presenter=FallingSkyRecorder(),clock=ManualRainClock()
        let store=FallingSkyStore(defaults:defaults,arguments:["--starfalls-reset","--technique-review","--technique-example=\(name)"],presenter:presenter,clock:clock)
        store.setSuspended(false)
        return (store,presenter,clock,defaults)
    }
    @MainActor func testRecipesCommitThroughCurrentPresenterAndReportOnlyCausalRelay() throws {
        let (store,presenter,_,defaults)=fixture("relay")
        let first=try XCTUnwrap(store.game.recipes.first { $0.cells.contains(Cell(0,0)) })
        XCTAssertTrue(store.performTechnique(.recipe(first),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game.score,4);XCTAssertEqual(store.changingColumns,[0,1])
        XCTAssertEqual(store.guideLine.id,"guide.recipe.1");XCTAssertEqual(store.guideLine.speaker,.pip)
        presenter.finish()
        let second=try XCTUnwrap(store.game.recipes.first)
        XCTAssertTrue(store.performTechnique(.recipe(second),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game.score,8);XCTAssertEqual(store.techniqueResult,"2-clear relay")
        XCTAssertEqual(store.guideLine.id,"guide.relay.1");XCTAssertEqual(store.guideLine.speaker,.pip)
        XCTAssertTrue(store.guideLine.text.contains("+4 starlight. 2-clear relay."))
        XCTAssertNil(defaults.data(forKey:SkySaveArchive.key),"Authored examples never replace a saved sky")
        presenter.finish();store.setSuspended(true)
        XCTAssertEqual(store.techniqueResult,"")
    }
    @MainActor func testNewActionsRejectStaleInputBusyColumnsAndFirstLight() throws {
        let (store,presenter,_,_)=fixture("nudge")
        let old=store.game,ticket=store.constellationInputGeneration
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,2),Cell(1,1)),snapshot:old,generation:ticket))
        let committed=store.game
        XCTAssertFalse(store.performTechnique(.nudge(Cell(1,1),Cell(1,2)),snapshot:committed,generation:store.constellationInputGeneration))
        XCTAssertFalse(store.performTechnique(.nudge(Cell(1,2),Cell(1,1)),snapshot:old,generation:ticket))
        XCTAssertEqual(store.game,committed)
        presenter.finish();store.startFirstLight()
        XCTAssertFalse(store.performTechnique(.nudge(Cell(0,0),Cell(0,1)),snapshot:store.game,generation:store.constellationInputGeneration))
    }
    @MainActor func testCurrentSaveNudgeKeepsDeadlineAndCommitsBeforeAnimation() throws {
        let suite="Starfall.TechniqueSave.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        var game=FallingSky(seed:5,generation:.current);game.letStarsFall()
        defaults.set(try SkySaveArchive.encode(game),forKey:SkySaveArchive.key)
        let presenter=FallingSkyRecorder(),clock=ManualRainClock()
        let store=FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock)
        store.setSuspended(false);store.togglePause()
        let deadline=clock.deadline
        let pairs=(0..<7).flatMap { col in [-1,1].map { (Cell(0,col),Cell(0,col+$0)) } }
        let pair=try XCTUnwrap(pairs.first { game.canNudge(from:$0.0,to:$0.1) })
        XCTAssertTrue(store.performTechnique(.nudge(pair.0,pair.1),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(clock.deadline,deadline)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))),store.game)
        XCTAssertTrue(store.game.isValidSave);XCTAssertEqual(store.game.incoming,game.incoming)
        let stale=presenter.completions.last
        store.setSuspended(true);stale?()
        let restored=FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(restored.game,store.game);XCTAssertTrue(restored.isPaused)
    }
    @MainActor func testAuthoredReviewHasNoClockOrSaveAndRestartExitsToCurrentGeneration() {
        let (store,_,clock,defaults)=fixture("fork")
        let old=store.game
        store.togglePause();store.callShower();clock.advance(100)
        XCTAssertEqual(store.game,old);XCTAssertNil(clock.deadline)
        XCTAssertNil(defaults.data(forKey:SkySaveArchive.key))
        store.restart(sameSky:true)
        XCTAssertFalse(store.isTechniqueFixture);XCTAssertEqual(store.game.generation,.current)
        XCTAssertTrue(store.game.isValidSave);XCTAssertNotNil(defaults.data(forKey:SkySaveArchive.key))
    }
    @MainActor func testVerticalExchangeOwnsOneColumnAndRejectsAnotherBeforeCompletion() throws {
        let (store,presenter,_,_) = fixture("nudge")
        let before = store.game, first = try XCTUnwrap(before.gem(at:Cell(0,2)))
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0,2),Cell(1,2)),snapshot:before,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game.gem(at:Cell(1,2))?.id,first.id)
        XCTAssertEqual(store.changingColumns,[2])
        XCTAssertFalse(store.performTechnique(.nudge(Cell(1,2),Cell(0,2)),snapshot:store.game,generation:store.constellationInputGeneration))
        presenter.finish()
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,2),Cell(0,2)),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game,before)
    }
    @MainActor func testIndependentExchangesKeepCurrentColumnOwnershipAndCompletionOrder() {
        let (store,presenter,_,_)=fixture("nudge")
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,2),Cell(1,3)),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.changingColumns,[2,3])
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,0),Cell(1,1)),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.changingColumns,[0,1,2,3])
        let committed=store.game
        presenter.completions[1]();XCTAssertTrue(store.busy)
        presenter.completions[0]();XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game,committed)
    }
    @MainActor func testMovingDuskOwnsChangedNeighborRewardColumns() throws {
        let suite="Starfall.TechniqueDusk.\(UUID())",defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        defaults.set(try SkySaveArchive.encode(DuskFixture.unfed.game()),forKey:SkySaveArchive.key)
        let store=FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        store.setSuspended(false)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0,3),Cell(0,4)),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertTrue(store.changingColumns.contains(2));XCTAssertFalse(store.canContact(Cell(0,2)))
        XCTAssertTrue(store.canContact(Cell(0,6)))
        XCTAssertTrue(store.game.isValidSave)
    }
    @MainActor func testFullMotionExchangeSlidesBeforeFallingAndQuietModeKeepsOutcome() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else { throw XCTSkip("Requires normal system motion") }
        let view=SKView(frame:.init(x:0,y:0,width:390,height:844))
        let owner=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior=owner.windows.first(where:\.isKeyWindow),window=UIWindow(windowScene:owner)
        let controller=UIViewController();controller.view=view;window.rootViewController=controller;window.frame=view.frame;window.makeKeyAndVisible()
        let scene=FallingSkyScene(size:view.bounds.size);view.presentScene(scene)
        defer { view.presentScene(nil);window.isHidden=true;prior?.makeKey() }
        let before=SkyTechniqueExample.nudge.game();var after=before
        let turn=try XCTUnwrap(after.nudge(from:Cell(1,2),to:Cell(1,3)))
        let id=try XCTUnwrap(before.gem(at:Cell(1,2))?.id)
        let origin=ObservatoryGeometry(size:scene.size).scenePoint(Cell(1,2))
        var complete=false,sideways=false,fall=false
        scene.render(before)
        // The host must deliver an update before a timed exchange starts. Otherwise
        // its first frame can consume the entire action while setup is still pending.
        var frameReady = false
        scene.run(.run { frameReady = true }, withKey: "test.host-ready")
        let frameDeadline = ContinuousClock.now + .seconds(2)
        while !frameReady && ContinuousClock.now < frameDeadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(frameReady, "The native SpriteKit host must produce an update")
        scene.animate(turn,from:before,to:after) { complete=true }
        let deadline=ContinuousClock.now + .seconds(5)
        while ContinuousClock.now < deadline && !complete {
            if let node=scene.childNode(withName:"//sky.star.\(id)") {
                sideways = sideways || (abs(node.position.x-origin.x)>1 && abs(node.position.y-origin.y)<2)
                fall = fall || abs(node.position.y-origin.y)>4
            }
            try await Task.sleep(for:.milliseconds(20))
        }
        XCTAssertTrue(complete);XCTAssertTrue(sideways);XCTAssertTrue(fall)
        let final=try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)"))
        let destination=ObservatoryGeometry(size:scene.size).scenePoint(Cell(0,3))
        // SpriteKit action coordinates round through Float; compare below a thousandth of a point.
        XCTAssertEqual(final.position.x,destination.x,accuracy:0.001)
        XCTAssertEqual(final.position.y,destination.y,accuracy:0.001)
        scene.reduceMotion=true;scene.render(before);complete=false
        scene.animate(turn,from:before,to:after) { complete=true }
        let quietDeadline=ContinuousClock.now + .seconds(2)
        while !complete && ContinuousClock.now < quietDeadline { try await Task.sleep(for:.milliseconds(20)) }
        XCTAssertTrue(complete)
        let quiet=try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)"))
        XCTAssertEqual(quiet.position.x,destination.x,accuracy:0.001)
        XCTAssertEqual(quiet.position.y,destination.y,accuracy:0.001)

        // A second, disjoint turn must not reschedule the first column's falling star or shadow.
        scene.reduceMotion=false;scene.render(before)
        var firstComplete=false,secondComplete=false
        scene.animate(turn,from:before,to:after) { firstComplete=true }
        let moving=try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)"))
        let shadow=try XCTUnwrap(scene.childNode(withName:"//sky.ground.\(id)"))
        let movement=try XCTUnwrap(moving.action(forKey:"sky.settle"))
        let shadowMovement=try XCTUnwrap(shadow.action(forKey:"sky.settle"))
        var second=after
        let secondTurn=try XCTUnwrap(second.nudge(from:Cell(1,0),to:Cell(1,1)))
        scene.animate(secondTurn,from:after,to:second) { secondComplete=true }
        XCTAssertTrue(moving.action(forKey:"sky.settle") === movement)
        XCTAssertTrue(shadow.action(forKey:"sky.settle") === shadowMovement)
        let overlapDeadline=ContinuousClock.now + .seconds(5)
        while (!firstComplete || !secondComplete) && ContinuousClock.now < overlapDeadline {
            try await Task.sleep(for:.milliseconds(20))
        }
        XCTAssertTrue(firstComplete);XCTAssertTrue(secondComplete)
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)")).position.x,destination.x,accuracy:0.001)
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)")).position.y,destination.y,accuracy:0.001)
    }
    @MainActor func testExactRecipeTracesNeedNoArrangeModeAndPreserveUntracedStars() throws {
        for example in [SkyTechniqueExample.relay, .fork] {
            let source = example.game()
            for recipe in source.recipes {
                let intent = ConstellationTraceIntent()
                let path = recipe.presentationPath
                let ticket = intent.begin(path[0], game:source, generation:1, enabled:true)
                for cell in path.dropFirst() {
                    XCTAssertTrue(intent.visit(cell,ticket:ticket,game:source,generation:1,enabled:true))
                }
                let result = try XCTUnwrap(intent.finish(ticket:ticket,game:source,generation:1,enabled:true))
                var after = source
                let turn = try XCTUnwrap(after.clearConstellation(result.path))
                XCTAssertEqual(turn.cleared,Set(recipe.cells))
                let untouched = Set(source.board.compactMap { $0?.id }).subtracting(recipe.starIDs)
                XCTAssertEqual(Set(after.board.compactMap { $0?.id }),untouched)
            }
        }
    }

    @MainActor func testHeldSwapCommitsAndRetiresTheContactBeforeRelease() throws {
        let (store,presenter,_,_) = fixture("trace")
        let before = store.game
        let hold = try XCTUnwrap(store.beginConstellationHold(at:Cell(0,0)))
        XCTAssertTrue(store.performTechnique(.nudge(Cell(0,0),Cell(0,1)),snapshot:before,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game.gem(at:Cell(0,1))?.id,before.gem(at:Cell(0,0))?.id)
        XCTAssertFalse(store.constellationTracing, "Committed presentation invalidates the held input ticket")
        let committed = store.game
        store.endConstellationHold(hold)
        presenter.finish()
        XCTAssertEqual(store.game,committed)
    }
}

extension SkyTechniqueStoreTests {
    @MainActor func testUpwardEmptyExchangeAnimatesEvenWhenGravityReturnsToOrigin() async throws {
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled)
        let view = SKView(frame:.init(x:0,y:0,width:390,height:844))
        let owner = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior = owner.windows.first(where: \.isKeyWindow), window = UIWindow(windowScene:owner)
        let controller = UIViewController(); controller.view = view; window.rootViewController = controller
        window.frame = view.frame; window.makeKeyAndVisible()
        let scene = FallingSkyScene(size:view.bounds.size); view.presentScene(scene)
        defer { view.presentScene(nil); window.isHidden = true; prior?.makeKey() }
        let before = SkyTechniqueExample.trace.game(); var after = before
        let turn = try XCTUnwrap(after.nudge(from:Cell(0,0),to:Cell(1,0)))
        XCTAssertEqual(before,after)
        let id = try XCTUnwrap(before.gem(at:Cell(0,0))?.id)
        let origin = ObservatoryGeometry(size:scene.size).scenePoint(Cell(0,0))
        scene.render(before)
        var ready = false
        scene.run(.run { ready = true }, withKey:"test.host-ready")
        let firstFrame = ContinuousClock.now + .seconds(2)
        while !ready && ContinuousClock.now < firstFrame { try await Task.sleep(for:.milliseconds(10)) }
        XCTAssertTrue(ready)
        var completed = false, rose = false
        scene.animate(turn,from:before,to:after) { completed = true }
        let deadline = ContinuousClock.now + .seconds(3)
        while !completed && ContinuousClock.now < deadline {
            if let node = scene.childNode(withName:"//sky.star.\(id)") { rose = rose || node.position.y > origin.y + 4 }
            try await Task.sleep(for:.milliseconds(10))
        }
        XCTAssertTrue(completed); XCTAssertTrue(rose,"A real upward motion must be visible before falling back")
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)")).position.y,origin.y,accuracy:0.001)
        scene.reduceMotion = true; scene.render(before); completed = false
        scene.animate(turn,from:before,to:after) { completed = true }
        XCTAssertEqual(try XCTUnwrap(scene.childNode(withName:"//sky.star.\(id)")).position.y,origin.y,accuracy:0.001)
        let quietDeadline = ContinuousClock.now + .seconds(2)
        while !completed && ContinuousClock.now < quietDeadline { try await Task.sleep(for:.milliseconds(10)) }
        XCTAssertTrue(completed)
    }
}
