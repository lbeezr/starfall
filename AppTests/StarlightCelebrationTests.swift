import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class StarlightCelebrationTests: XCTestCase {
    @MainActor func testHeaderRegistrationPreservesNestedScoreAndSiblingBoard() async throws {
        let registered = expectation(description: "All celebration anchors reach the overlay")
        var didRegister = false
        var observed: Set<StarlightAnchor> = []
        let probe = VStack {
            Text("12").starlightAnchor(.score)
        }
        .starlightAnchor(.header)
        .background { Color.clear.starlightAnchor(.board) }
        .overlayPreferenceValue(StarlightAnchors.self) { anchors in
            Color.clear
                .onAppear { inspect(Set(anchors.keys)) }
                .onChange(of: Set(anchors.keys)) { _, roles in inspect(roles) }
        }
        func inspect(_ roles: Set<StarlightAnchor>) {
            observed = roles
            if roles == [.score, .header, .board], !didRegister {
                didRegister = true; registered.fulfill()
            }
        }
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: probe)
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        await fulfillment(of: [registered], timeout: 3)
        XCTAssertEqual(observed, [.score, .header, .board])
    }

    @MainActor private func makeStore(_ game: FallingSky) throws -> (FallingSkyStore, FallingSkyRecorder, ManualRainClock, UserDefaults) {
        let suite = "Starfall.Celebrations.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
    }

    @MainActor func testConcurrentAwardsReplaceOnceWithoutOwningInputOrSave() throws {
        for reversed in [false, true] {
            let (store, presenter, _, defaults) = try makeStore(ObservatoryReviewFixture.game(dense: false))
            store.clear(Cell(0, 0))
            let first = try XCTUnwrap(store.celebration), firstGame = store.game
            store.clear(Cell(0, 0))
            XCTAssertEqual(store.celebration, first); XCTAssertEqual(store.game, firstGame)
            XCTAssertTrue(store.canClear(Cell(2, 6)), "An award must not reserve unrelated columns")
            store.clear(Cell(2, 6))
            let second = try XCTUnwrap(store.celebration), committed = store.game
            XCTAssertNotEqual(first.id, second.id)
            XCTAssertEqual(second.total, committed.score)
            XCTAssertEqual(second.collected, committed.score - firstGame.score)
            let callbacks = reversed ? Array(presenter.completions.reversed()) : presenter.completions
            callbacks.forEach { $0() }
            XCTAssertEqual(store.celebration, second); XCTAssertFalse(store.busy)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), committed)
            let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(), clock: ManualRainClock())
            XCTAssertEqual(restored.game, committed); XCTAssertNil(restored.celebration)
        }
    }

    @MainActor func testTraceReceiptIncludesRewardingOpalAndExactValidatedPath() throws {
        let original = ConstellationFixture.opalTrace.game(), path = (0..<5).map { Cell($0, 2) }
        let (store, _, _, _) = try makeStore(original)
        let before = store.game
        store.clearTracedConstellation(path, snapshot: before, generation: store.constellationInputGeneration)
        let receipt = try XCTUnwrap(store.celebration)
        XCTAssertEqual(receipt.level, .constellation); XCTAssertEqual(receipt.path, path)
        XCTAssertEqual(before.value(of: Set(path)), 8)
        XCTAssertTrue(before.isDrained(at: Cell(3, 2)))
        XCTAssertEqual(receipt.collected, 7); XCTAssertEqual(receipt.total, store.game.score)
        XCTAssertEqual(Set(receipt.cells), Set(path).subtracting([Cell(3, 2)]))
        XCTAssertTrue(receipt.cells.contains { before.gem(at: $0)?.isLight == true })
        XCTAssertEqual(store.game.incoming, before.incoming)
    }

    @MainActor func testZeroRewardDuskClearHasNoCollectionOrFakeCelebration() throws {
        let game = DuskFixture.zeroClear.game(rule: .patientFeeding)
        let (store, _, _, _) = try makeStore(game)
        store.clear(Cell(0, 1))
        XCTAssertEqual(store.game.score, 0); XCTAssertEqual(store.game.occupiedCount, 0)
        XCTAssertNil(store.celebration)
    }

    @MainActor func testRecipeAndCausalRelayUseCommittedCategoriesWithoutBonusPoints() throws {
        let suite = "Starfall.CelebrationRecipe.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults,
            arguments: ["--starfalls-reset", "--technique-review", "--technique-example=relay"],
            presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        let first = try XCTUnwrap(store.game.recipes.first { $0.cells.contains(Cell(0, 0)) })
        XCTAssertTrue(store.performTechnique(.recipe(first), snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.celebration?.level, .recipe(.square))
        XCTAssertEqual(store.celebration?.path, first.presentationPath)
        XCTAssertEqual(store.game.score, 4)
        presenter.finish()
        let second = try XCTUnwrap(store.game.recipes.first)
        XCTAssertTrue(store.performTechnique(.recipe(second), snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.celebration?.level, .relay(2)); XCTAssertEqual(store.game.score, 8)
        XCTAssertEqual(store.celebration?.collected, 4)
        XCTAssertNil(defaults.data(forKey: SkySaveArchive.key))
    }

    @MainActor func testInterruptionsCancelReceiptAndRejectStaleCompletion() throws {
        for boundary in ["settings", "motion", "restart", "challenge", "shower", "geometry"] {
            let (store, presenter, _, _) = try makeStore(ObservatoryReviewFixture.game(dense: false))
            store.clear(Cell(0, 0)); XCTAssertNotNil(store.celebration)
            switch boundary {
            case "settings": store.setSuspended(true)
            case "motion": store.setReducedMotion(true)
            case "restart": store.restart(sameSky: true)
            case "challenge": store.startFirstLight()
            case "shower": presenter.finish(); store.callShower()
            default: store.scene.onLayout?()
            }
            let committed = store.game
            XCTAssertNil(store.celebration, boundary)
            presenter.finish()
            XCTAssertNil(store.celebration, boundary); XCTAssertEqual(store.game, committed, boundary)
        }
    }

    @MainActor func testExpiryCannotFinishGameplayPresentation() async throws {
        let (store, presenter, _, _) = try makeStore(ObservatoryReviewFixture.game(dense: false))
        store.clear(Cell(0, 0)); XCTAssertNotNil(store.celebration)
        let expired = expectation(description: "Receipt expires independently")
        let observer = Task { @MainActor in
            while store.celebration != nil && !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(20)) } catch { return }
            }
            expired.fulfill()
        }
        await fulfillment(of: [expired], timeout: 3); observer.cancel()
        XCTAssertTrue(store.busy)
        presenter.finish(); XCTAssertFalse(store.busy)
    }
}
