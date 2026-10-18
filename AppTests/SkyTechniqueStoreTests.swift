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
    @MainActor func testExpiredSelectionAndSwapTargetsCannotSurviveCancel() throws {
        let game=SkyTechniqueExample.fork.game(),intent=SkyTechniqueIntent()
        intent.setArranging(true);intent.select(Cell(2,1),game:game,generation:4)
        let old=intent.selectionID
        intent.cancel();intent.select(Cell(2,1),game:game,generation:4)
        let recipe=intent.recipe
        intent.chooseRecipe("missing",selectionID:old)
        XCTAssertEqual(intent.recipe,recipe);XCTAssertNil(intent.consumeSelection(old))
        intent.setArranging(false)
        intent.armSwap(Cell(1,2),to:Cell(1,1),game:SkyTechniqueExample.nudge.game(),generation:5)
        XCTAssertTrue(intent.swapping);XCTAssertFalse(intent.arranging)
        XCTAssertEqual(intent.swapDestination,Cell(1,1));intent.cancel()
        XCTAssertFalse(intent.swapping);XCTAssertNil(intent.swapDestination)
    }
    @MainActor func testUnchangedRecipeSurvivesShowerWithFreshSnapshotAndStableChoiceIdentity() throws {
        let source = SkyTechniqueExample.relay.game(), intent = SkyTechniqueIntent()
        intent.setArranging(true); intent.select(Cell(0,0), game:source, generation:4)
        let previousID = intent.selectionID, recipe = try XCTUnwrap(intent.recipe)
        var shower = source; XCTAssertNotNil(shower.letStarsFall())
        intent.reconcile(with:shower, preservingRecipeAt:5)
        XCTAssertEqual(intent.recipe,recipe); XCTAssertEqual(intent.snapshot,shower)
        XCTAssertEqual(intent.generation,5); XCTAssertEqual(intent.selectionID,previousID)
        let renewedID = intent.selectionID
        intent.reconcile(with:shower, preservingRecipeAt:5)
        XCTAssertEqual(intent.selectionID,renewedID, "Both observed committed properties may reconcile the same event")
        XCTAssertTrue(intent.commitSelection(previousID) { snapshot,ticket in
            XCTAssertEqual(snapshot,shower); XCTAssertEqual(ticket,5)
            return true
        }, "A button for the unchanged choice spends its renewed snapshot, never the old committed state")
        XCTAssertNil(intent.snapshot)
    }
    @MainActor func testAutomaticRecipeRevalidationAndAvailabilityRespectLandingAndInterruption() throws {
        let suite = "Starfall.RecipeRain.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        var source = FallingSky(seed:0,generation:.current,duskRule:.patientFeeding)
        for _ in 0..<6 { XCTAssertNotNil(source.letStarsFall()) }
        XCTAssertNotNil(source.nudge(from:Cell(4,0),to:Cell(4,1)))
        defaults.set(try SkySaveArchive.encode(source),forKey:SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock)
        store.setSuspended(false); store.togglePause()
        let intent = SkyTechniqueIntent()
        intent.setArranging(true); intent.select(Cell(1,0),game:store.game,generation:store.constellationInputGeneration)
        let recipe = try XCTUnwrap(intent.recipe), action = SkyBoardAction.recipe(recipe)
        XCTAssertTrue(store.canPerformTechnique(action))
        clock.advance(store.showerInterval)
        XCTAssertEqual(store.recipeRevalidationGeneration,store.constellationInputGeneration)
        intent.reconcile(with:store.game,preservingRecipeAt:store.recipeRevalidationGeneration)
        XCTAssertEqual(intent.recipe,recipe)
        XCTAssertFalse(store.canPerformTechnique(action), "Recipe columns are reserved until the shower lands")
        XCTAssertFalse(store.performTechnique(action,snapshot:store.game,generation:store.constellationInputGeneration))
        XCTAssertNotNil(intent.snapshot, "Unavailable actions have not consumed the UI selection")
        presenter.finish()
        XCTAssertTrue(store.canPerformTechnique(action))
        let selected = try XCTUnwrap(intent.consumeSelection(intent.selectionID))
        XCTAssertTrue(store.performTechnique(action,snapshot:selected.0,generation:selected.1))
        XCTAssertEqual(store.game.score,4); XCTAssertNil(store.recipeRevalidationGeneration)
        store.setSuspended(true)
        XCTAssertNil(store.recipeRevalidationGeneration); XCTAssertFalse(store.canPerformTechnique(action))
        presenter.finish()
    }
    @MainActor func testRecipeRevalidationRejectsChangedIngredientsAndNonRecipeSelections() throws {
        let source = SkyTechniqueExample.relay.game(), intent = SkyTechniqueIntent()
        intent.setArranging(true); intent.select(Cell(0,0),game:source,generation:4)
        var changed = source
        XCTAssertNotNil(changed.nudge(from:Cell(0,1),to:Cell(0,2)))
        intent.reconcile(with:changed,preservingRecipeAt:5)
        XCTAssertNil(intent.snapshot); XCTAssertNil(intent.recipe)
        intent.select(Cell(0,2),game:source,generation:4)
        XCTAssertNil(intent.recipe)
        var shower = source; shower.letStarsFall()
        intent.reconcile(with:shower,preservingRecipeAt:5)
        XCTAssertNil(intent.anchor, "A bare move anchor is not a revalidated recipe")
        intent.armSwap(Cell(0,1),to:Cell(0,2),game:source,generation:4)
        intent.reconcile(with:shower,preservingRecipeAt:5)
        XCTAssertFalse(intent.swapping); XCTAssertNil(intent.anchor)
    }
    @MainActor func testRejectedSelectionCommitRetainsChoiceAndStaleCallbackCannotPerform() throws {
        let game = SkyTechniqueExample.relay.game(), intent = SkyTechniqueIntent()
        intent.setArranging(true); intent.select(Cell(0,0),game:game,generation:4)
        let id = intent.selectionID, recipe = intent.recipe
        XCTAssertFalse(intent.commitSelection(id) { snapshot,ticket in
            XCTAssertEqual(snapshot,game); XCTAssertEqual(ticket,4); return false
        })
        XCTAssertEqual(intent.selectionID,id); XCTAssertEqual(intent.recipe,recipe)
        XCTAssertTrue(intent.commitSelection(id) { _,_ in true })
        XCTAssertNil(intent.snapshot)
        intent.select(Cell(0,0),game:game,generation:5)
        XCTAssertFalse(intent.commitSelection(id) { _,_ in XCTFail("Stale callback must not execute"); return true })
        XCTAssertNotNil(intent.snapshot)
    }
    @MainActor func testArrangeReconciliationKeepsUsefulModeAndExitsEmptyOrUnsupportedSkies() throws {
        let source = SkyTechniqueExample.relay.game(), intent = SkyTechniqueIntent()
        intent.setArranging(true); intent.select(Cell(0,0),game:source,generation:4)
        let selectionID = intent.selectionID
        intent.reconcile(with:source)
        XCTAssertTrue(intent.arranging)
        XCTAssertNil(intent.anchor); XCTAssertNil(intent.snapshot)
        XCTAssertNil(intent.consumeSelection(selectionID))

        var cleared = source
        XCTAssertNotNil(cleared.activate(try XCTUnwrap(cleared.recipes.first)))
        XCTAssertNotNil(cleared.activate(try XCTUnwrap(cleared.recipes.first)))
        XCTAssertEqual(cleared.occupiedCount,0)
        intent.reconcile(with:cleared)
        XCTAssertFalse(intent.arranging)
        XCTAssertFalse(SkyTechniqueIntent.canArrange(in:cleared))
        XCTAssertTrue(SkyTechniqueIntent.canArrange(in:source))

        var challenge = FallingSky(challenge:.firstLight)
        challenge.letStarsFall()
        XCTAssertGreaterThan(challenge.occupiedCount,0)
        intent.setArranging(true);intent.reconcile(with:challenge)
        XCTAssertFalse(intent.arranging)
        XCTAssertFalse(SkyTechniqueIntent.canArrange(in:challenge))
    }
}
