import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class SkyTechniqueStoreTests: XCTestCase {
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
        presenter.finish()
        let second=try XCTUnwrap(store.game.recipes.first)
        XCTAssertTrue(store.performTechnique(.recipe(second),snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertEqual(store.game.score,8);XCTAssertEqual(store.techniqueResult,"2-clear relay")
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
    func testSwapDwellCannotRearmAfterLeavingRowOrCrossingTwoColumns() {
        let mapping=ObservatoryGeometry(size:.init(width:390,height:844)),origin=mapping.viewPoint(Cell(1,2))
        var dwell=SkySwapDwell()
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,1)),mapping:mapping)
        XCTAssertEqual(dwell.target,Cell(1,1))
        dwell.visit(origin:origin,point:origin,mapping:mapping);XCTAssertNil(dwell.target)
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,1)),mapping:mapping)
        XCTAssertEqual(dwell.target,Cell(1,1))
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(2,1)),mapping:mapping)
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,1)),mapping:mapping)
        XCTAssertFalse(dwell.eligible);XCTAssertNil(dwell.target)
        dwell=SkySwapDwell()
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,4)),mapping:mapping)
        dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,3)),mapping:mapping)
        XCTAssertFalse(dwell.eligible);XCTAssertNil(dwell.target)
        for departure in [origin,mapping.viewPoint(Cell(2,3)),mapping.viewPoint(Cell(1,4))] {
            dwell=SkySwapDwell()
            dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,3)),mapping:mapping)
            dwell.arm();dwell.visit(origin:origin,point:departure,mapping:mapping)
            dwell.visit(origin:origin,point:mapping.viewPoint(Cell(1,3)),mapping:mapping)
            XCTAssertFalse(dwell.eligible,"Leaving an armed target cannot rearm on return")
            XCTAssertNil(dwell.target)
        }
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

    @MainActor func testDirectSwapTargetsCannotSurviveCancelOrReconciliation() {
        let game = SkyTechniqueExample.nudge.game(), intent = SkyTechniqueIntent()
        intent.armSwap(Cell(1,2),to:Cell(1,1),game:game,generation:5)
        XCTAssertTrue(intent.swapping)
        XCTAssertEqual(intent.preview, [Cell(1,2), Cell(1,1)])
        intent.cancel()
        XCTAssertFalse(intent.swapping); XCTAssertNil(intent.snapshot)
        XCTAssertNil(intent.anchor); XCTAssertNil(intent.swapDestination)
        intent.armSwap(Cell(1,2),to:Cell(1,1),game:game,generation:6)
        intent.reconcile(with:game)
        XCTAssertFalse(intent.swapping); XCTAssertTrue(intent.preview.isEmpty)
        intent.armSwap(Cell(1,2),to:Cell(3,1),game:game,generation:7)
        XCTAssertNil(intent.snapshot, "An invalid destination cannot leave an armed swap")
    }
}
