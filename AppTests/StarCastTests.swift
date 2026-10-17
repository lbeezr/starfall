import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class StarCastTests: XCTestCase {
    @MainActor func testSkyReactionWeightsAndBounds() {
        XCTAssertLessThan(StarfallMotion.rebound(dark: true, grew: false), StarfallMotion.rebound(dark: false, grew: true))
        XCTAssertLessThan(StarfallMotion.rebound(dark: false, grew: true), StarfallMotion.rebound(dark: false, grew: false))
        for id in 0..<100 {
            XCTAssertGreaterThan(StarfallMotion.drift(for: id, column: 0), 0)
            XCTAssertLessThan(StarfallMotion.drift(for: id, column: 6), 0)
            for column in 0..<7 { XCTAssertLessThanOrEqual(abs(StarfallMotion.drift(for: id, column: column)), 1.5) }
        }
        XCTAssertEqual(StarfallMotion.ripple(distance: 3, collected: 8, heavy: false), 0)
        XCTAssertEqual(StarfallMotion.ripple(distance: 0, collected: 8, heavy: false), 0)
        let near = StarfallMotion.ripple(distance: 1, collected: 5, heavy: false)
        XCTAssertGreaterThan(near, StarfallMotion.ripple(distance: 2, collected: 5, heavy: false))
        XCTAssertGreaterThan(near, StarfallMotion.ripple(distance: 1, collected: 3, heavy: false))
        XCTAssertGreaterThan(near, StarfallMotion.ripple(distance: 1, collected: 5, heavy: true))
        XCTAssertLessThan(near, 0.22)
    }

    @MainActor func testSkyRenderCancelsPendingFlightCompletion() async {
        let scene = FallingSkyScene(size: CGSize(width: 350, height: 350))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene)
        let old = FallingSky(seed: 5)
        var game = old
        let turn = game.letStarsFall()!
        let stale = expectation(description: "replaced flight must not finish")
        stale.isInverted = true
        scene.animate(turn, from: old, to: game) { stale.fulfill() }
        scene.render(old)
        await fulfillment(of: [stale], timeout: 1.2)
        XCTAssertFalse(scene.hasActions())
        view.presentScene(nil)
    }

    @MainActor func testCompleteCastIsBoundedAndReusesMaterialsAcrossRounds() throws {
        StarCast.prewarm()
        XCTAssertEqual(StarCast.cachedMaterialCount, 72)
        let cast = Jewel.allCases.map(Optional.some) + [nil]
        for kind in cast {
            for expression in StarCast.Expression.allCases {
                let first = StarCast.texture(for: kind, expression: expression)
                for _ in 0..<49 {
                    let node = JewelScene.makeStarCharacter(kind, expression: expression, radius: 22)
                    XCTAssertTrue(node.texture === first)
                    XCTAssertEqual(node.anchorPoint, CGPoint(x: 0.5, y: 0.5))
                    XCTAssertEqual(node.size.width, node.size.height)
                    XCTAssertLessThanOrEqual(node.size.width, 54)
                    XCTAssertFalse(node.hasActions())
                }
                XCTAssertEqual(first.size(), CGSize(width: 256, height: 256))
                XCTAssertEqual(first.filteringMode, .linear)
                XCTAssertFalse(first.usesMipmaps)
            }
        }
        XCTAssertEqual(StarCast.cachedMaterialCount, StarCast.maximumMaterials)
        XCTAssertEqual(StarCast.maximumRasterBytes, 18_874_368)
    }

    @MainActor func testTransparentPaddingAndStableSilhouettesAcrossExpressions() throws {
        for kind in Jewel.allCases.map(Optional.some) + [nil] {
            var neutralAlpha: [UInt8]?
            var expressions = Set<Data>()
            for expression in StarCast.Expression.allCases {
                let image = StarCast.image(for: kind, expression: expression)
                let cg = try XCTUnwrap(image.cgImage)
                var pixels = [UInt8](repeating: 0, count: 256 * 256 * 4)
                let context = try XCTUnwrap(CGContext(data: &pixels, width: 256, height: 256,
                    bitsPerComponent: 8, bytesPerRow: 256 * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(cg, in: CGRect(x: 0, y: 0, width: 256, height: 256))
                let alpha = stride(from: 3, to: pixels.count, by: 4).map { pixels[$0] }
                XCTAssertTrue(alpha.contains(255))
                for y in 0..<256 { for x in 0..<256 where x < 18 || x >= 238 || y < 18 || y >= 238 {
                    XCTAssertEqual(alpha[y * 256 + x], 0, "Cast must not clip its canvas")
                } }
                if let neutralAlpha { XCTAssertEqual(alpha, neutralAlpha, "Faces must not change silhouette/pivot") }
                else { neutralAlpha = alpha }
                expressions.insert(Data(pixels))
            }
            // Every gameplay expression must now be distinct.
            XCTAssertEqual(expressions.count, 4)
        }
    }

    @MainActor func testFallingSkyUsesTheCompleteCastAndRepeatedRendersDoNotAccumulateNodes() {
        var game = FallingSky(seed: 5)
        for _ in 0..<16 where !game.isOver { _ = game.letStarsFall() }
        XCTAssertTrue(game.board.contains { $0?.isDark == true })
        let scene = FallingSkyScene(size: CGSize(width: 378, height: 560))
        func castNodes(_ node: SKNode) -> [SKNode] {
            node.children.flatMap { child in
                (child.name?.hasPrefix("star-cast.") == true ? [child] : []) + castNodes(child)
            }
        }
        for _ in 0..<30 {
            scene.render(game)
            let nodes = castNodes(scene)
            XCTAssertEqual(nodes.count, game.occupiedCount)
            let names = Set(nodes.compactMap(\.name))
            for gem in game.board.compactMap({ $0 }) {
                let expression: StarCast.Expression = gem.grown ? .grown : .idle
                XCTAssertTrue(names.contains("star-cast.\(StarCast.character(for: gem.kind).name).\(expression.rawValue)"))
            }
        }
        XCTAssertEqual(StarCast.cachedMaterialCount, StarCast.maximumMaterials)
    }

    @MainActor func testExpressionChangesPreserveGeometryForEveryFamilyAndPose() {
        for kind in Jewel.allCases.map(Optional.some) + [nil] {
            let node = JewelScene.makeStarCharacter(kind, expression: .landing, radius: 18)
            node.anchorPoint = CGPoint(x: 0.4, y: 0.6)
            node.setScale(0.83)
            let size = node.size, anchor = node.anchorPoint, scale = node.xScale
            for expression in StarCast.Expression.allCases {
                StarCast.setExpression(expression, for: kind, on: node)
                XCTAssertEqual(node.size, size)
                XCTAssertEqual(node.anchorPoint, anchor)
                XCTAssertEqual(node.xScale, scale)
            }
        }
    }

    @MainActor func testAnimatedLandingsNeverExpandToTheTextureCanvas() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Full-animation geometry check requires normal motion; reduced-motion behavior is covered separately")
        }
        let scene = FallingSkyScene(size: CGSize(width: 350, height: 560))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 560))
        guard let windowScene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
            XCTFail("Hosted animation check requires an active window scene"); return
        }
        let previousKeyWindow = windowScene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; previousKeyWindow?.makeKey() }
        view.presentScene(scene)
        var game = FallingSky(seed: 5)
        let old = game
        guard let turn = game.letStarsFall() else { XCTFail("Expected first shower"); return }
        var complete = false
        scene.animate(turn, from: old, to: game) { complete = true }
        var observedRebound = false
        let restingY = scene.size.height / 2 - 3 * scene.size.height / 7.7
        // Sample throughout flight, landing, expression swap and settlement, not just the final frame.
        for _ in 0..<70 {
            try? await Task.sleep(for: .milliseconds(20))
            func inspect(_ parent: SKNode) {
                for child in parent.children {
                    if let sprite = child as? SKSpriteNode, sprite.name?.hasPrefix("star-cast.") == true {
                        XCTAssertLessThan(sprite.frame.width, 70, "Expression swap must retain game-sized sprite geometry")
                        XCTAssertLessThan(sprite.frame.height, 70)
                    }
                    inspect(child)
                }
            }
            inspect(scene)
            // The pieces layer contains only landed stars; travelers live in the effects layer.
            if scene.children[1].children.contains(where: { $0.position.y > restingY + 1 }) {
                observedRebound = true
            }
        }
        XCTAssertTrue(complete)
        XCTAssertTrue(observedRebound, "Normal-motion arrivals must visibly rebound before settling")
        for node in scene.children[1].children {
            XCTAssertEqual(node.position.y, restingY, accuracy: 0.01)
            XCTAssertEqual(node.xScale, 1, accuracy: 0.01)
            XCTAssertEqual(node.yScale, 1, accuracy: 0.01)
        }
        // Populate a reproducible neighborhood without depending on an animation to advance rules.
        for _ in 0..<4 { _ = game.letStarsFall() }
        let beforeClear = game
        guard let cell = game.legalGroups.first?.first, let clear = game.clear(cell) else {
            XCTFail("Seed must offer a clear with neighboring survivors"); return
        }
        var clearComplete = false
        scene.animate(clear, from: beforeClear, to: game) { clearComplete = true }
        let origins = Dictionary(uniqueKeysWithValues: scene.children[1].children.map { (ObjectIdentifier($0), $0.position) })
        var observedRipple = false
        // Inspect only the wave phase, before gravity starts at 260 ms.
        for _ in 0..<11 {
            try? await Task.sleep(for: .milliseconds(20))
            for node in scene.children[1].children where node.alpha == 1 {
                if let origin = origins[ObjectIdentifier(node)], hypot(node.position.x - origin.x, node.position.y - origin.y) > 0.3 {
                    observedRipple = true
                }
            }
        }
        XCTAssertTrue(observedRipple, "A neighboring survivor must react before gravity")
        let deadline = ContinuousClock.now + .seconds(3)
        while !clearComplete && ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertTrue(clearComplete)
        XCTAssertEqual(scene.children[1].children.count, game.occupiedCount)
    }

    @MainActor func testEveryCharacterHasACompleteTwelveFrameSheet() throws {
        for kind in Jewel.allCases.map(Optional.some) + [nil] {
            var unique = Set<Data>()
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let sheet = UIGraphicsImageRenderer(size: CGSize(width: 768, height: 1024), format: format).image { _ in
                for (row, expression) in StarCast.Expression.allCases.enumerated() {
                    for (column, facing) in StarCast.Facing.allCases.enumerated() {
                        let image = StarCast.image(for: kind, expression: expression, facing: facing)
                        if let png = image.pngData() { unique.insert(png) }
                        image.draw(at: CGPoint(x: column * 256, y: row * 256))
                        let node = JewelScene.makeStarCharacter(kind, expression: expression, radius: 22)
                        let size = node.size
                        StarCast.setExpression(expression, for: kind, on: node, facing: facing)
                        XCTAssertEqual(node.size, size)
                        XCTAssertEqual(node.anchorPoint, CGPoint(x: 0.5, y: 0.5))
                    }
                }
            }
            XCTAssertEqual(unique.count, 12, "Every turn and expression must be authored, not a duplicated frame")
            let attachment = XCTAttachment(image: sheet)
            attachment.name = "star-cast-sheet-" + StarCast.character(for: kind).name
            attachment.lifetime = .keepAlways; add(attachment)
        }
    }

    @MainActor func testCastReviewSheetAtBoardAndHeroSizes() {
        let kinds = [Jewel.aqua, .amber, .mint, .rose, .violet].map(Optional.some) + [nil]
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        let sheet = UIGraphicsImageRenderer(size: CGSize(width: 840, height: 670), format: format).image { render in
            UIColor(red: 0.06, green: 0.08, blue: 0.17, alpha: 1).setFill()
            render.fill(CGRect(x: 0, y: 0, width: 840, height: 670))
            let labels: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 15, weight: .medium), .foregroundColor: UIColor.white]
            for (index, kind) in kinds.enumerated() {
                let x = CGFloat(index) * 140
                (StarCast.character(for: kind).name as NSString).draw(at: CGPoint(x: x + 43, y: 14), withAttributes: labels)
                for (row, expression) in StarCast.Expression.allCases.enumerated() {
                    StarCast.image(for: kind, expression: expression).draw(in: CGRect(x: x + 12, y: 42 + CGFloat(row) * 102, width: 116, height: 116))
                }
                for (poseIndex, facing) in StarCast.Facing.allCases.enumerated() {
                    StarCast.image(for: kind, facing: facing).draw(in: CGRect(x: x + CGFloat(poseIndex) * 45, y: 560, width: 45, height: 45))
                }
                for (index, side) in [CGFloat(24), 36, 44].enumerated() {
                    StarCast.image(for: kind).draw(in: CGRect(x: x + 6 + CGFloat(index) * 43, y: 485, width: side, height: side))
                }
            }
        }
        let attachment = XCTAttachment(image: sheet)
        attachment.name = "star-cast-materials-and-gameplay-scale"; attachment.lifetime = .keepAlways
        add(attachment)
    }
}
