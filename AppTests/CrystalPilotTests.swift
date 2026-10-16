import XCTest
import SpriteKit
import UIKit
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

    @MainActor func testExplicitLegacyComparisonRemainsSeparateFromDefaultFamily() throws {
        let game = Game(seed: 42)
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        var requests = 0
        scene.artwork = StarshardArtwork { name in
            requests += 1
            return UIImage(named: name)?.cgImage
        }
        scene.crystalPilotEnabled = true
        scene.render(game)
        #if DEBUG
        XCTAssertFalse(scene.starshardArtworkIsActive)
        XCTAssertEqual(requests, 0, "Legacy comparison must not load the current family")
        let fallback = JewelScene(size: scene.size)
        fallback.crystalPilotEnabled = false
        fallback.artwork = StarshardArtwork { _ in nil }
        fallback.render(game)
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let expected: SKTexture
            if game.jewel(at: cell) == .aqua {
                expected = CrystalPilot.frames[CrystalPilot.neutralIndex]
            } else {
                expected = try XCTUnwrap(fallback.renderedTexture(at: cell))
            }
            XCTAssertTrue(scene.renderedTexture(at: cell) === expected)
        } }
        #else
        XCTAssertTrue(scene.starshardArtworkIsActive)
        XCTAssertEqual(requests, 5, "Release always uses the complete current family")
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let kind = try XCTUnwrap(game.jewel(at: cell))
            let expected = try XCTUnwrap(scene.artwork.frames(for: kind))
            XCTAssertTrue(scene.renderedTexture(at: cell) === expected.neutralFrame)
        } }
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
        try requireLegacyPilot()
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
        try requireLegacyPilot()
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

    private func requireLegacyPilot() throws {
        #if !DEBUG
        throw XCTSkip("The original aqua comparison route is Debug-only; Release uses the current family")
        #endif
    }
}
