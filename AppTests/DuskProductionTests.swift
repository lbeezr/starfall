import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class DuskProductionTests: XCTestCase {
    @MainActor private func store(_ game: FallingSky) throws -> (FallingSkyStore, UserDefaults, DuskPresenter) {
        let suite = "Dusk.Production.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(game),forKey:SkySaveArchive.key)
        let presenter = DuskPresenter()
        let store = FallingSkyStore(defaults: defaults,arguments:[],presenter:presenter)
        store.setSuspended(false)
        return (store,defaults,presenter)
    }

    @MainActor func testCollapseCommitsBeforeAnimationAndInterruptionsCannotRepeatIt() throws {
        let (store,defaults,presenter) = try store(DuskFixture.imminent.game(rule: .patientFeeding))
        store.callShower()
        XCTAssertEqual(store.game.lostStarlight,4); XCTAssertEqual(store.game.score,0)
        XCTAssertEqual(store.pending?.duskCollapses.count,1)
        XCTAssertEqual(store.changingColumns,Set(0..<7))
        XCTAssertTrue(store.message.contains("swallowed 3 stars"))
        let committed = store.game
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))),committed)
        let stale = try XCTUnwrap(presenter.completions.last)
        store.clear(Cell(0,2)); XCTAssertEqual(store.game,committed)
        store.setSuspended(true); stale()
        XCTAssertEqual(store.game,committed); XCTAssertFalse(store.busy)
        let restored = FallingSkyStore(defaults:defaults,arguments:[],presenter:DuskPresenter())
        XCTAssertEqual(restored.game,committed); XCTAssertTrue(restored.isPaused)
        store.restart(sameSky:true); let restarted=store.game; stale()
        XCTAssertEqual(store.game,restarted); XCTAssertEqual(restarted.duskRule,.patientFeeding)
        XCTAssertEqual(restarted.lostStarlight,0)
    }

    @MainActor func testV6FeedingMigrationRetainsOldBytesAndProgressUntilActivation() throws {
        let old = DuskFixture.imminent.game()
        let suite = "Dusk.V6.\(UUID())", defaults = UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let object = try JSONSerialization.jsonObject(with:JSONEncoder().encode(old))
        let bytes = try JSONSerialization.data(withJSONObject:["schemaVersion":6,"game":object])
        defaults.set(bytes,forKey:SkySaveArchive.feedingKey)
        let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:DuskPresenter())
        XCTAssertEqual(store.game, old.adoptingFeedingDusk())
        XCTAssertEqual(store.game.gem(at:Cell(0,3))?.duskFeeds,2)
        XCTAssertNil(defaults.data(forKey:SkySaveArchive.key))
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.feedingKey),bytes)
        store.setSuspended(false)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))), store.game)
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.feedingKey),bytes)
        defaults.set(Data("broken".utf8),forKey:SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from:defaults))
    }

    @MainActor func testV5MigrationRetainsBoardPreviewRandomnessAndBytesUntilActivation() throws {
        var old = FallingSky(seed:5,generation:.current)
        for _ in 0..<6 { _ = old.letStarsFall() }
        let suite="Dusk.V5.\(UUID())", defaults=UserDefaults(suiteName:suite)!
        defer { defaults.removePersistentDomain(forName:suite) }
        let object=try JSONSerialization.jsonObject(with:JSONEncoder().encode(old))
        let bytes=try JSONSerialization.data(withJSONObject:["schemaVersion":5,"game":object])
        defaults.set(bytes,forKey:SkySaveArchive.gravityKey)
        let store=FallingSkyStore(defaults:defaults,arguments:[],presenter:DuskPresenter())
        XCTAssertEqual(store.game,old.adoptingFeedingDusk())
        XCTAssertTrue(store.game.board.compactMap { $0 }.filter(\.isDark).allSatisfy { $0.duskFeeds == 0 })
        var after=try XCTUnwrap(JSONSerialization.jsonObject(with:JSONEncoder().encode(store.game)) as? [String:Any])
        after.removeValue(forKey:"savedDuskRule");after.removeValue(forKey:"unscoredStarlight")
        XCTAssertEqual(after as NSDictionary,object as! NSDictionary)
        XCTAssertNil(defaults.object(forKey:SkySaveArchive.key)); XCTAssertEqual(defaults.data(forKey:SkySaveArchive.gravityKey),bytes)
        store.setSuspended(false)
        let current=try XCTUnwrap(defaults.data(forKey:SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(current),store.game)
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.gravityKey),bytes)
        let restored=FallingSkyStore(defaults:defaults,arguments:[],presenter:DuskPresenter())
        XCTAssertEqual(restored.game,store.game); XCTAssertEqual(defaults.data(forKey:SkySaveArchive.key),current)
        defaults.set(Data("broken".utf8),forKey:SkySaveArchive.key)
        XCTAssertNil(SkySaveArchive.load(from:defaults),"Invalid current data must not revive v5")
    }

    @MainActor func testZeroRewardClearFeedbackAndInfluenceColumnsRemainAtomic() throws {
        let (store,_,presenter)=try store(DuskFixture.zeroClear.game())
        store.clear(Cell(0,1))
        XCTAssertEqual(store.game.score,0); XCTAssertEqual(store.game.occupiedCount,0)
        XCTAssertTrue(store.message.contains("No starlight that time")); XCTAssertTrue(store.busy)
        XCTAssertFalse(store.canContact(Cell(0,1)))
        presenter.completions.last?(); XCTAssertFalse(store.busy)
    }

    @MainActor func testDuskGuidanceUsesBottomDialogueWithoutChangingSavedGame() throws {
        let (store,_,presenter) = try store(DuskFixture.unfed.game(rule: .patientFeeding))
        let before = store.game
        XCTAssertTrue(store.pausedGuideLine.text.contains("5 more showers with a touching star"))
        XCTAssertEqual(store.game, before)
        store.callShower()
        presenter.completions.last?()
        XCTAssertTrue(store.dialogue.line?.text.contains("4 more showers with a touching star") == true)
        XCTAssertTrue(store.dialogue.visible)
        store.showInputFeedback("Swap ready · lift to move; slide back to cancel")
        XCTAssertEqual(store.pausedGuideLine.speaker, .spark)
        store.showInputFeedback(nil)
        XCTAssertTrue(store.pausedGuideLine.text.contains("4 more showers with a touching star"))
    }

    @MainActor func testStageTargetsDrainMaterialAndWarningSurviveResizeAndQuietRendering() throws {
        let scene=FallingSkyScene(size:.init(width:378,height:690))
        let game=DuskFixture.imminent.game(rule: .patientFeeding)
        for _ in 0..<12 { scene.render(game) }
        XCTAssertTrue(DuskWarning(game:game)!.text.contains("1 more shower with a touching star"))
        XCTAssertTrue(DuskWarning.consequence(game:game,cell:Cell(0,3)).contains("row 6, column 4"))
        XCTAssertNotNil(scene.childNode(withName:"//dusk.progress"))
        XCTAssertNil(scene.childNode(withName:"//sky.growth-lock"))
        let characters=scene.children[1].children.compactMap { $0 as? FallingSkyCharacter }
        XCTAssertEqual(characters.count,game.occupiedCount)
        XCTAssertEqual(characters.filter { $0.character.shader != nil }.count,3)
        scene.reduceMotion=true;scene.size = .init(width:350,height:560);scene.render(game)
        XCTAssertNotNil(scene.childNode(withName:"//dusk.progress"))
        XCTAssertNil(scene.childNode(withName:"//dusk.collapse"))
    }

    @MainActor func testFullMotionCollapseSwallowsAndResetsWithoutStaleCompletion() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else { throw XCTSkip("Requires normal system motion") }
        let view=SKView(frame:.init(x:0,y:0,width:378,height:690))
        let owner=try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior=owner.windows.first(where:\.isKeyWindow), window=UIWindow(windowScene:owner)
        let controller=UIViewController();controller.view=view;window.rootViewController=controller;window.frame=view.frame;window.makeKeyAndVisible()
        let scene=FallingSkyScene(size:view.bounds.size);view.presentScene(scene)
        defer {view.presentScene(nil);window.isHidden=true;prior?.makeKey()}
        let before=DuskFixture.imminent.game(rule: .patientFeeding);var after=before
        let turn=try XCTUnwrap(after.letStarsFall())
        var complete=false,sawHole=false,sawInfall=false,sawArrival=false
        scene.animate(turn,from:before,to:after){complete=true}
        let deadline=ContinuousClock.now + .seconds(5)
        let consumedID=try XCTUnwrap(before.gem(at:Cell(0,2))?.id)
        let origin=ObservatoryGeometry(size:scene.size).scenePoint(Cell(0,2))
        while ContinuousClock.now < deadline && !complete {
            sawHole = sawHole || scene.childNode(withName:"//dusk.collapse") != nil
            if let star=scene.childNode(withName:"//sky.star.\(consumedID)") {
                sawInfall = sawInfall || (star.xScale < 0.9 && hypot(star.position.x-origin.x,star.position.y-origin.y)>1)
            }
            sawArrival = sawArrival || scene.childNode(withName:"//sky.flight.\(turn.arrivals[0].star.id)") != nil
            try await Task.sleep(for:.milliseconds(20))
        }
        XCTAssertTrue(complete);XCTAssertTrue(sawHole);XCTAssertTrue(sawInfall);XCTAssertTrue(sawArrival)
        XCTAssertNil(scene.childNode(withName:"//dusk.collapse"))
        var stale=false;scene.animate(turn,from:before,to:after){stale=true}
        scene.render(after)
        try await Task.sleep(for:.milliseconds(650))
        XCTAssertFalse(stale);XCTAssertNil(scene.childNode(withName:"//dusk.collapse"))
        XCTAssertEqual(scene.children[1].children.count,after.occupiedCount)
    }
}

@MainActor private final class DuskPresenter:FallingSkyPresenting {
    var reduceMotion=false
    var completions:[()->Void]=[]
    func render(_ game:FallingSky) {}
    func animate(_ turn:FallingSkyTurn,from old:FallingSky,to game:FallingSky,completion:@escaping()->Void){completions.append(completion)}
}
