import XCTest
import SpriteKit
import StarfallCore
@testable import Starfall

/// Exercises the real SpriteKit presenter and cached assets, not GPU frame pacing.
final class CrystalPilotTests: XCTestCase {
    @MainActor func testAtlasHasNineFramesAndFourFragments() throws {
        XCTAssertEqual(CrystalPilot.frames.count, 9)
        XCTAssertEqual(CrystalPilot.shards.count, 4)
        XCTAssertEqual(try XCTUnwrap(CrystalPilot.frames.first).size(), CGSize(width: 256, height: 256))
        XCTAssertEqual(try XCTUnwrap(CrystalPilot.shards.first).size(), CGSize(width: 128, height: 128))
        XCTAssertEqual(CrystalPilot.canvasSide(radius: 94), 256, accuracy: 0.001)
        XCTAssertFalse(CrystalPilot.isEnabled(arguments: []))
        #if DEBUG
        XCTAssertTrue(CrystalPilot.isEnabled(arguments: ["--crystal-pilot"]))
        #endif
    }

    @MainActor func testActualRendererCancellationRemovesFragmentsAndActions() throws {
        let (scene, view, old, new, turn) = try fixture()
        var completions = 0
        scene.animate(turn: turn, old: old, new: new) { completions += 1 }
        XCTAssertGreaterThan(scene.transientNodeCount, 0)
        XCTAssertLessThanOrEqual(scene.transientNodeCount, CrystalPilot.maximumShards)
        XCTAssertTrue(scene.hasActions())
        scene.cancelAnimations()
        XCTAssertEqual(scene.transientNodeCount, 0)
        XCTAssertFalse(scene.hasActions())
        scene.render(new)
        XCTAssertEqual(scene.renderedJewelCount, 49)
        XCTAssertEqual(completions, 0)
        scene.enumerateChildNodes(withName: "//*") { node, _ in
            XCTAssertFalse(node.hasActions())
        }
        withExtendedLifetime(view) {}
    }

    @MainActor func testLargeAquaClearCapsFragmentsAt48() throws {
        let data = try JSONEncoder().encode(Game(seed: 42))
        var fixture = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        fixture["board"] = Array(repeating: Jewel.aqua.rawValue, count: 49)
        let old = try JSONDecoder().decode(Game.self, from: JSONSerialization.data(withJSONObject: fixture))
        var new = old
        let turn = try XCTUnwrap(new.tap(Cell(0, 0)))
        XCTAssertEqual(turn.cleared.count, 49)
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        scene.crystalPilotEnabled = true
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene)
        scene.isPaused = true
        scene.render(old)
        scene.animate(turn: turn, old: old, new: new) {}
        XCTAssertEqual(scene.transientNodeCount, 48)
        scene.cancelAnimations()
        XCTAssertEqual(scene.transientNodeCount, 0)
        withExtendedLifetime(view) {}
    }

    @MainActor func testReducedMotionImmediatelySettlesWithoutFragments() throws {
        let (scene, view, old, new, turn) = try fixture()
        scene.reduceMotion = true
        var completions = 0
        scene.animate(turn: turn, old: old, new: new) { completions += 1 }
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(scene.renderedJewelCount, 49)
        XCTAssertEqual(scene.transientNodeCount, 0)
        XCTAssertFalse(scene.hasActions())
        withExtendedLifetime(view) {}
    }

    @MainActor func testUnattachedRendererImmediatelySettlesWithoutFragments() throws {
        let (_, _, old, new, turn) = try fixture()
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        scene.crystalPilotEnabled = true
        scene.render(old)
        var completions = 0
        scene.animate(turn: turn, old: old, new: new) { completions += 1 }
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(scene.renderedJewelCount, 49)
        XCTAssertEqual(scene.transientNodeCount, 0)
    }

    @MainActor private func fixture() throws -> (JewelScene, SKView, Game, Game, Turn) {
        for seed in UInt64(0)..<1000 {
            let old = Game(seed: seed)
            for row in 0..<Game.side { for column in 0..<Game.side {
                let cell = Cell(row, column)
                guard old.jewel(at: cell) == .aqua, old.group(at: cell).count >= 3 else { continue }
                var new = old
                let turn = try XCTUnwrap(new.tap(cell))
                let scene = JewelScene(size: CGSize(width: 350, height: 350))
                scene.crystalPilotEnabled = true
                let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
                view.presentScene(scene)
                scene.isPaused = true
                scene.render(old)
                XCTAssertNotNil(scene.view)
                return (scene, view, old, new, turn)
            } }
        }
        throw NSError(domain: "CrystalPilotTests.NoAquaFixture", code: 1)
    }
}
