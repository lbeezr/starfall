import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class StarCastTests: XCTestCase {
    @MainActor func testContactAndReadyRecipeSelectionUseOpenSparkRays() throws {
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        scene.render(SkyTechniqueExample.relay.game())
        for ready in [false, true] {
            if ready { scene.showConstellationTrace([Cell(0,0), Cell(0,1), Cell(1,1), Cell(1,0)], ready: true) }
            else { scene.showContact(Cell(0,0)) }
            var cues: [SKShapeNode] = []
            scene.enumerateChildNodes(withName: "//sky.input.contact") { node, _ in
                if let cue = node as? SKShapeNode { cues.append(cue) }
            }
            scene.enumerateChildNodes(withName: "//sky.input.drawing.armed") { node, _ in
                if let cue = node as? SKShapeNode { cues.append(cue) }
            }
            XCTAssertEqual(cues.count, ready ? 5 : 1)
            for cue in cues {
                let path = try XCTUnwrap(cue.path)
                var moves = 0, lines = 0, curvesOrClosures = 0
                path.applyWithBlock { element in
                    switch element.pointee.type {
                    case .moveToPoint: moves += 1
                    case .addLineToPoint: lines += 1
                    default: curvesOrClosures += 1
                    }
                }
                XCTAssertEqual(moves, 4); XCTAssertEqual(lines, 4)
                XCTAssertEqual(curvesOrClosures, 0, "Selection cues must not enclose stars in rings")
                XCTAssertEqual(cue.fillColor.cgColor.alpha, 0)
            }
            scene.clearConstellationTrace()
            XCTAssertNil(scene.childNode(withName: "//sky.input.contact"))
        }
    }

    @MainActor func testAuraPulseChangesOnlyOuterOpacityAndCancelsOnQuietSuspensionAndReplacement() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Pulse sampling requires normal system motion")
        }
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = windowScene.windows.first(where: \.isKeyWindow)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; previous?.makeKey() }
        let scene = FallingSkyScene(size: view.bounds.size); view.presentScene(scene)
        let game = ObservatoryReviewFixture.game(dense: false)
        let gem = try XCTUnwrap(game.board.compactMap { $0 }.first { $0.value == 2 })
        scene.render(game)
        let root = try XCTUnwrap(scene.children[1].childNode(withName: "sky.star.\(gem.id)") as? FallingSkyCharacter)
        let cue = try XCTUnwrap(root.character.childNode(withName: "sky.growth-cue"))
        let aura = try XCTUnwrap(cue.childNode(withName: "sky.growth-aura"))
        XCTAssertEqual(cue.children.count, 1, "Growth uses one radial aura, never another body or glints")
        let size = root.character.size
        var minimum = CGFloat(1), maximum = CGFloat(0)
        let deadline = ContinuousClock.now + .seconds(4)
        while maximum - minimum < 0.18 && ContinuousClock.now < deadline {
            minimum = min(minimum, aura.alpha); maximum = max(maximum, aura.alpha)
            XCTAssertGreaterThanOrEqual(aura.alpha, 0.139)
            XCTAssertLessThanOrEqual(aura.alpha, 0.341)
            XCTAssertEqual(root.character.size, size)
            XCTAssertEqual(root.character.xScale, 1)
            XCTAssertEqual(root.character.zRotation, 0)
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertGreaterThan(maximum - minimum, 0.18, "A full-motion aura must visibly breathe")
        let action = try XCTUnwrap(aura.action(forKey: "sky.growth-pulse"))
        root.update(gem, expression: .landing)
        XCTAssertTrue(aura.action(forKey: "sky.growth-pulse") === action, "Material refresh must preserve pulse phase")
        scene.reduceMotion = true
        XCTAssertFalse(aura.hasActions())
        XCTAssertEqual(aura.alpha, StarfallTheme.GrownStar.auraAlpha, accuracy: 0.000001)
        scene.reduceMotion = false
        XCTAssertTrue(aura.hasActions())
        scene.decorativeMotionActive = false
        XCTAssertFalse(aura.hasActions())
        scene.decorativeMotionActive = true
        XCTAssertTrue(aura.hasActions())
        scene.render(game)
        XCTAssertFalse(aura.hasActions(), "A retained reference to a replaced star must own no idle action")
        let replacement = try XCTUnwrap(scene.children[1].childNode(withName: "sky.star.\(gem.id)") as? FallingSkyCharacter)
        let replacementAura = try XCTUnwrap(replacement.character.childNode(withName: "sky.growth-cue/sky.growth-aura"))
        XCTAssertTrue(replacementAura.hasActions())
        var cleared = game
        let turn = try XCTUnwrap(cleared.clear(Cell(1, 1)))
        scene.animate(turn, from: game, to: cleared) {}
        XCTAssertFalse(replacementAura.hasActions(), "Column replacement/clear ends the previous cue before its exit")
        scene.render(game)
        let finalRoot = try XCTUnwrap(scene.children[1].childNode(withName: "sky.star.\(gem.id)") as? FallingSkyCharacter)
        let finalAura = try XCTUnwrap(finalRoot.character.childNode(withName: "sky.growth-cue/sky.growth-aura"))
        view.presentScene(nil)
        XCTAssertFalse(finalAura.hasActions(), "Detaching the scene cancels decorative motion")
    }

    @MainActor func testSpecialStarsNeverImplyDoubleValueEvenWithAGrownFlag() throws {
        for gem in [StarfallGem(id: 1, kind: nil, grown: true),
                    StarfallGem(id: 2, kind: nil, grown: true, light: true),
                    StarfallGem(id: 3, kind: nil, grown: true, gravity: .magnet),
                    StarfallGem(id: 4, kind: nil, grown: true, gravity: .hole)] {
            let node = FallingSkyCharacter(gem: gem, step: 45)
            node.setGrowthMotion(true)
            let cue = try XCTUnwrap(node.character.childNode(withName: "sky.growth-cue"))
            XCTAssertTrue(cue.isHidden)
            XCTAssertTrue(cue.children.allSatisfy { !$0.hasActions() })
            let expected = SkyPiece.makeNode(for: .init(gem), radius: 45 * StarfallMotion.pieceRadius)
            XCTAssertEqual(node.character.size, expected.size, "Special objects cannot imply a double-value body")
        }
        // Retained critical-mass saves have real stellar age, independently of a growth flag.
        for fresh in [StarfallGem(id: 1, kind: .amber), StarfallGem(id: 2, kind: nil, light: true)] {
            var previousWidth: CGFloat?
            for age in [0, CriticalMassRule.showersPerStage, CriticalMassRule.showersPerStage * 2] {
                var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(fresh)) as? [String: Any])
                if age > 0 { object["savedStellarAge"] = age }
                let aged = try JSONDecoder().decode(StarfallGem.self, from: JSONSerialization.data(withJSONObject: object))
                let root = FallingSkyCharacter(gem: aged, step: 45)
                if let previousWidth {
                    XCTAssertGreaterThan(root.character.size.width, previousWidth, "Historical age must still advance the body stage")
                }
                previousWidth = root.character.size.width
                XCTAssertEqual(aged.value, 1, "Historical size does not award a second light")
                XCTAssertTrue(try XCTUnwrap(root.character.childNode(withName: "sky.growth-cue")).isHidden)
            }
        }
    }

    @MainActor func testDoubleValueUsesOneLargerBodyAndOneAuraWithoutAccumulatingInQuietMode() throws {
        for step in [CGFloat(32), 45, 64] {
            for kind in Jewel.allCases.map(Optional.some) + [nil] {
                let ordinary = StarfallGem(id: 1, kind: kind)
                let grown = StarfallGem(id: 1, kind: kind, grown: true)
                let node = FallingSkyCharacter(gem: ordinary, step: step)
                let cue = try XCTUnwrap(node.character.childNode(withName: "sky.growth-cue"))
                XCTAssertTrue(cue.isHidden)
                let aura = try XCTUnwrap(cue.childNode(withName: "sky.growth-aura") as? SKSpriteNode)
                XCTAssertEqual(cue.children.count, 1)
                XCTAssertFalse(aura.texture === node.character.texture, "The aura must not be a duplicated silhouette")
                let bodyTexture = node.character.texture
                let normalSize = node.character.size
                for _ in 0..<20 {
                    for expression in StarCast.Expression.allCases {
                        node.update(grown, expression: expression)
                        XCTAssertEqual(cue.isHidden, kind == nil, "Dark stars never imply double value")
                        XCTAssertEqual(cue.children.count, 1)
                        XCTAssertEqual(node.children.count, 1, "Growth keeps one piece body")
                        XCTAssertFalse(cue.hasActions())
                        XCTAssertTrue(cue.children.allSatisfy { !$0.hasActions() })
                        XCTAssertTrue(node.character.texture === bodyTexture)
                        if kind != nil {
                            XCTAssertGreaterThan(node.character.size.width, normalSize.width)
                            let visibleWidth = node.character.size.width * SkyPiece.silhouetteSide / CGFloat(SkyPiece.rasterSide)
                            XCTAssertLessThan(visibleWidth, step, "The enlarged body must retain clearance between adjacent cells")
                        } else {
                            XCTAssertEqual(node.character.size, normalSize)
                        }
                        XCTAssertEqual(node.position, .zero)
                    }
                }
                node.update(ordinary, expression: .idle)
                XCTAssertTrue(cue.isHidden)
                XCTAssertEqual(node.character.size, normalSize)
            }
        }
        XCTAssertLessThanOrEqual(SkyPiece.cachedMaterialCount, SkyPiece.maximumMaterials)
    }


    @MainActor func testIndependentClearDoesNotCancelAnUnrelatedAnimatedShower() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Concurrent motion requires normal system motion")
        }
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = windowScene.windows.first(where: \.isKeyWindow)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; previous?.makeKey() }
        let scene = FallingSkyScene(size: view.bounds.size); view.presentScene(scene)
        var game = ObservatoryReviewFixture.game(dense: false)
        scene.render(game)
        let beforeRain = game
        let rain = try XCTUnwrap(game.letStarsFall())
        var rainDone = false, clearDone = false
        scene.animate(rain, from: beforeRain, to: game) { rainDone = true }
        let cell = try XCTUnwrap(game.legalGroups.compactMap(\.first).first { cell in
            let group = game.group(at: cell)
            return Set(group.union(game.darkStarsBeside(group)).map(\.column)).isDisjoint(with: rain.changingColumns)
        })
        let beforeClear = game
        let clear = try XCTUnwrap(game.clear(cell))
        scene.animate(clear, from: beforeClear, to: game) { clearDone = true }
        scene.showContact(Cell(0,3))
        var sawClearBeforeRain = false, sawFlight = false
        let deadline = ContinuousClock.now + .seconds(3)
        while (!rainDone || !clearDone) && ContinuousClock.now < deadline {
            sawClearBeforeRain = sawClearBeforeRain || (clearDone && !rainDone)
            sawFlight = sawFlight || scene.children[2].children.contains { $0.children.count > 1 }
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertTrue(rainDone); XCTAssertTrue(clearDone)
        XCTAssertTrue(sawClearBeforeRain); XCTAssertTrue(sawFlight)
        XCTAssertEqual(scene.children[1].children.count, game.occupiedCount)
        for case let node as FallingSkyCharacter in scene.children[1].children {
            let index = try XCTUnwrap(game.board.firstIndex { $0?.id == node.gem.id })
            XCTAssertEqual(node.gem, game.board[index])
            let expected = LandingGeometry(size: scene.size).scenePoint(Cell(index/7,index%7))
            XCTAssertEqual(node.position.x, expected.x, accuracy: 0.01)
            XCTAssertEqual(node.position.y, expected.y, accuracy: 0.01)
            XCTAssertFalse(node.hasActions())
        }
        var contacts: [SKNode] = []
        scene.enumerateChildNodes(withName: "//sky.input.contact") { node, _ in contacts.append(node) }
        XCTAssertEqual(contacts.count, 1, "Completing other columns must preserve a live contact outline")
        let capture = XCTAttachment(image: UIImage(cgImage: try XCTUnwrap(view.texture(from: scene)).cgImage()))
        capture.name = "concurrent-arrival-final"; capture.lifetime = .keepAlways; add(capture)
    }

    @MainActor func testCrystalBodiesStayPackagedAndOpenSpaceHasNoContactShadows() throws {
        let kinds = StarCast.Identity.allCases
        for kind in kinds {
            let name = StarCast.character(for: kind).name
            let body = try XCTUnwrap(UIImage(named: "StarCast" + name), "Missing bundled body for \(name)")
            XCTAssertEqual(body.size, CGSize(width: 256, height: 256))
            XCTAssertNotEqual(try XCTUnwrap(body.cgImage).alphaInfo, CGImageAlphaInfo.none)
            let offset = StarCast.groundOffset(for: kind, radius: 20)
            if kind == .magnet { XCTAssertEqual(offset, 0, "A field has no solid contact point") }
            else { XCTAssertGreaterThan(offset, 10) }
            XCTAssertLessThanOrEqual(offset, 20)
            XCTAssertEqual(StarCast.groundOffset(for: kind, radius: 30), offset * 1.5, accuracy: 0.01)
        }
        XCTAssertLessThan(StarCast.groundOffset(for: .colored(.violet), radius: 20),
                          StarCast.groundOffset(for: .colored(.aqua), radius: 20))
        var game = FallingSky(seed: 5)
        for _ in 0..<4 { _ = game.letStarsFall() }
        let scene = FallingSkyScene(size: CGSize(width: 350, height: 560))
        for _ in 0..<3 {
            scene.render(game)
            let roots = scene.children[0].children.filter { $0.name?.hasPrefix("sky.ground.") == true }
            XCTAssertTrue(roots.isEmpty,"Stars float in space without contact shadows")
        }
    }

    @MainActor func testContactFlightReachesReceiverAndCommittedDestination() {
        let flight = StarfallMotion.Flight(start: CGPoint(x: 20, y: 400),
            destination: CGPoint(x: 100, y: 40), contact: CGPoint(x: 80, y: 65), step: 45)
        XCTAssertEqual(flight.point(at: 0), flight.start)
        XCTAssertEqual(flight.point(at: StarfallMotion.contactFraction), flight.contact)
        XCTAssertEqual(flight.point(at: 1).x, flight.destination.x, accuracy: 0.001)
        XCTAssertEqual(flight.point(at: 1).y, flight.destination.y, accuracy: 0.001)
        XCTAssertEqual(flight.point(at: -1), flight.start)
        XCTAssertEqual(flight.point(at: 2).x, flight.destination.x, accuracy: 0.001)
    }

    @MainActor func testContactTransfersLocallyAndReturnsToStillness() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Contact comparison requires normal motion")
        }
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = windowScene.windows.first(where: \.isKeyWindow)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 560))
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; previous?.makeKey() }
        let scene = FallingSkyScene(size: view.bounds.size); view.presentScene(scene)
        var game = FallingSky(seed: 5)
        var sawContact = false, sawLight = false, sawGrowth = false
        for _ in 0..<8 {
            let old = game
            let turn = try XCTUnwrap(game.letStarsFall())
            sawGrowth = sawGrowth || turn.arrivals.contains(where: \.grew)
            var complete = false
            scene.animate(turn, from: old, to: game) { complete = true }
            let deadline = ContinuousClock.now + .seconds(3)
            while !complete && ContinuousClock.now < deadline {
                for node in scene.children[1].children {
                    if let root = node as? FallingSkyCharacter {
                        if !sawContact && hypot(root.character.position.x, root.character.position.y) > 0.3 {
                            sawContact = true
                            if let texture = view.texture(from: scene) {
                                let capture = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
                                capture.name = "native-contact-transfer"; capture.lifetime = .keepAlways; add(capture)
                            }
                        }
                    }
                }
                sawLight = sawLight || scene.children[2].children.contains { $0.name == "sky.clear-light" }
                try await Task.sleep(for: .milliseconds(16))
            }
            XCTAssertTrue(complete)
            XCTAssertEqual(scene.children[1].children.count, game.occupiedCount)
            XCTAssertTrue(scene.children[2].children.isEmpty)
            for node in scene.children[1].children {
                let root = try XCTUnwrap(node as? FallingSkyCharacter)
                XCTAssertFalse(root.hasActions()); XCTAssertFalse(root.character.hasActions())
                XCTAssertEqual(root.character.position, .zero)
                XCTAssertEqual(root.character.zRotation, 0)
                XCTAssertEqual(root.xScale, 1); XCTAssertEqual(root.yScale, 1)
                let index = try XCTUnwrap(game.board.firstIndex { $0?.id == root.gem.id })
                XCTAssertEqual(root.gem, game.board[index])
                let expected = LandingGeometry(size: scene.size).scenePoint(Cell(index/7, index%7))
                XCTAssertEqual(root.position.x, expected.x, accuracy: 0.01)
                XCTAssertEqual(root.position.y, expected.y, accuracy: 0.01)
                XCTAssertEqual(root.zRotation, 0)
            }
        }
        XCTAssertTrue(sawContact, "A real existing neighbor must receive a local impulse")
        XCTAssertTrue(sawLight); XCTAssertTrue(sawGrowth)
        scene.reduceMotion = true
        let old = game; let turn = try XCTUnwrap(game.letStarsFall())
        let done = expectation(description: "calm completion")
        scene.animate(turn, from: old, to: game) { done.fulfill() }
        await fulfillment(of: [done], timeout: 1)
        XCTAssertEqual(scene.children[1].children.count, game.occupiedCount)
        XCTAssertTrue(scene.children[2].children.isEmpty)
    }

    @MainActor func testSkyReactionWeightsAndBounds() {
        let sunny = SkyPieceMotion.profile(for: .colored(.amber)).rebound
        XCTAssertLessThan(SkyPieceMotion.profile(for: .dusk).rebound, sunny)
        XCTAssertLessThan(SkyPieceMotion.profile(for: .colored(.mint)).rebound, sunny)
        XCTAssertLessThan(sunny, SkyPieceMotion.profile(for: .colored(.aqua)).rebound)
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

    @MainActor func testOpalArrivalUsesItsOwnMaterialAndSurvivesCommittedRestore() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Normal-motion Opal arrival requires full animation")
        }
        var game = FallingSky(seed: 17, balance: .init(darkStars: .none), generation: .current)
        for _ in 0..<5 {
            XCTAssertNotNil(game.letStarsFall())
            for _ in 0..<49 {
                guard let first = game.legalGroups.first?.first else { break }
                XCTAssertNotNil(game.clear(first))
            }
        }
        let incoming = try XCTUnwrap(game.incoming.first(where: \.isLight))
        XCTAssertEqual(StarCast.Identity(incoming), .opal)
        XCTAssertNotEqual(StarCast.Identity(incoming), .dusk)
        let old = game, turn = try XCTUnwrap(game.letStarsFall())
        let opal = try XCTUnwrap(turn.arrivals.first(where: { $0.gem.isLight })?.gem)
        XCTAssertEqual(StarCast.Identity(opal), .opal)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 560))
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = windowScene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; previous?.makeKey() }
        let scene = FallingSkyScene(size: view.bounds.size); view.presentScene(scene)
        var complete = false, sawOpalInFlight = false, sawSoftLanding = false
        var frame = 0
        scene.animate(turn, from: old, to: game) { complete = true }
        let deadline = ContinuousClock.now + .seconds(3)
        while !complete && ContinuousClock.now < deadline {
            sawOpalInFlight = sawOpalInFlight || scene.children[2].children.contains {
                $0.children.contains { $0.name == "sky-piece.Opal" }
            }
            let landedOpal = scene.children[1].children.contains { ($0 as? FallingSkyCharacter)?.gem.id == opal.id }
            let travelingOpal = scene.children[2].children.contains { $0.name == "sky.flight.\(incoming.id)" }
            XCTAssertFalse(landedOpal && travelingOpal, "Landing must hand off one body without a duplicate flight sprite")
            sawSoftLanding = sawSoftLanding || scene.children[1].children.contains {
                ($0 as? FallingSkyCharacter)?.gem.isLight == true && ($0 as? FallingSkyCharacter)?.character.warpGeometry != nil
            }
            if frame.isMultiple(of: 3), let texture = view.texture(from: scene) {
                // Composite the native capture over an opaque preview stage before
                // GIF export; GIF cannot preserve the translucent effects' alpha.
                let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                let frameImage = UIGraphicsImageRenderer(size: view.bounds.size, format: format).image { context in
                    UIColor(red: 0.04, green: 0.055, blue: 0.12, alpha: 1).setFill()
                    context.fill(view.bounds)
                    UIImage(cgImage: texture.cgImage()).draw(in: view.bounds)
                }
                let capture = XCTAttachment(image: frameImage)
                capture.name = "opal-soft-motion-frame-\(String(format: "%03d", frame))"
                capture.lifetime = .keepAlways; add(capture)
            }
            frame += 1
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertTrue(sawSoftLanding, "Opal must deform during normal landing")
        XCTAssertTrue(complete, "Opal arrival must finish"); XCTAssertTrue(sawOpalInFlight, "Comet must carry the Opal body")
        let restored = try SkySaveArchive.decode(SkySaveArchive.encode(game))
        scene.render(restored)
        let root = try XCTUnwrap(scene.children[1].children.first { $0.name == "sky.star.\(opal.id)" } as? FallingSkyCharacter)
        XCTAssertNil(root.character.warpGeometry, "Committed restore must be round and free of transient deformation")
        XCTAssertEqual(root.character.name, "sky-piece.Opal")
        XCTAssertTrue(root.character.texture === SkyPiece.texture(for: .opal))
        XCTAssertFalse(root.character.texture === SkyPiece.texture(for: .dusk))
        XCTAssertLessThan(root.character.frame.width, 60)
        let character = FallingSkyCharacter(gem: opal, step: 45)
        character.softenLanding()
        let squash = character.character.warpGeometry
        character.showExpression(.idle)
        XCTAssertTrue(character.character.warpGeometry === squash, "Material refresh must preserve the soft landing")
        character.update(opal, expression: .idle)
        XCTAssertNil(character.character.warpGeometry); XCTAssertFalse(character.character.hasActions())
        scene.reduceMotion = true
        var quietComplete = false
        scene.animate(turn, from: old, to: game) { quietComplete = true }
        let quietDeadline = ContinuousClock.now + .seconds(1)
        while !quietComplete && ContinuousClock.now < quietDeadline { try await Task.sleep(for: .milliseconds(16)) }
        XCTAssertTrue(quietComplete)
        XCTAssertTrue(scene.children[2].children.isEmpty)
        for node in scene.children[1].children {
            let quiet = try XCTUnwrap(node as? FallingSkyCharacter)
            XCTAssertNil(quiet.character.warpGeometry)
            XCTAssertEqual(quiet.character.position, .zero)
        }
        if let texture = view.texture(from: scene) {
            let attachment = XCTAttachment(image: UIImage(cgImage: texture.cgImage()))
            attachment.name = "opal-committed-native-arrival"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }

    @MainActor func testOpalRoundMeshIsAnIdentityAtEveryVertex() {
        let grid = OpalMotion.round
        XCTAssertEqual(grid.vertexCount, 12)
        for index in 0..<grid.vertexCount {
            let source = grid.sourcePosition(at: index)
            let destination = grid.destPosition(at: index)
            let expected = SIMD2<Float>(Float(index % 3)/2, Float(index / 3)/3)
            XCTAssertEqual(source, expected)
            XCTAssertEqual(destination, expected, "Fractional middle rows must not collapse through integer division")
        }
    }

    @MainActor func testCompleteCastIsBoundedAndReusesMaterialsAcrossRounds() throws {
        StarCast.prewarm()
        XCTAssertEqual(StarCast.cachedMaterialCount, 86)
        let cast = StarCast.Identity.allCases
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
        XCTAssertEqual(StarCast.maximumRasterBytes, 22_544_384)
    }

    @MainActor func testTransparentPaddingAndStableSilhouettesAcrossExpressions() throws {
        for kind in StarCast.Identity.allCases {
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
            // Gravity objects have a fixed material; the seven faced stars keep authored expressions.
            XCTAssertEqual(expressions.count, kind == .magnet || kind == .hole ? 1 : 4)
        }
    }

    @MainActor func testFallingSkyUsesFacelessPiecesAndRepeatedRendersDoNotAccumulateNodes() {
        SkyPiece.prewarm()
        var game = FallingSky(seed: 5)
        for _ in 0..<16 where !game.isOver { _ = game.letStarsFall() }
        XCTAssertTrue(game.board.contains { $0?.isDark == true })
        let scene = FallingSkyScene(size: CGSize(width: 378, height: 560))
        func castNodes(_ node: SKNode) -> [SKNode] {
            node.children.flatMap { child in
                (child.name?.hasPrefix("sky-piece.") == true ? [child] : []) + castNodes(child)
            }
        }
        for _ in 0..<30 {
            scene.render(game)
            let nodes = castNodes(scene)
            XCTAssertEqual(nodes.count, game.occupiedCount)
            XCTAssertNil(scene.childNode(withName: "//star-cast.*"), "Story faces must not enter the gameplay board")
            let names = Set(nodes.compactMap(\.name))
            for gem in game.board.compactMap({ $0 }) {
                XCTAssertTrue(names.contains("sky-piece.\(StarCast.character(for: .init(gem)).name)"))
            }
        }
        XCTAssertEqual(SkyPiece.cachedMaterialCount, SkyPiece.maximumMaterials)
    }

    @MainActor func testExpressionChangesPreserveGeometryForEveryFamilyAndPose() {
        for kind in StarCast.Identity.allCases {
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
        let restingY = LandingGeometry(size: scene.size).scenePoint(Cell(0,0)).y
        // Sample throughout flight, landing, expression swap and settlement, not just the final frame.
        for _ in 0..<70 {
            try? await Task.sleep(for: .milliseconds(20))
            func inspect(_ parent: SKNode) {
                for child in parent.children {
                    if let sprite = child as? SKSpriteNode, sprite.name?.hasPrefix("sky-piece.") == true {
                        XCTAssertLessThan(sprite.frame.width, 70, "Material refresh must retain game-sized sprite geometry")
                        XCTAssertLessThan(sprite.frame.height, 70)
                    }
                    inspect(child)
                }
            }
            inspect(scene)
            // The pieces layer contains only landed stars; travelers live in the effects layer.
            if scene.children[1].children.contains(where: { (($0 as? FallingSkyCharacter)?.character.position.y ?? 0) > 1 }) {
                observedRebound = true
            }
        }
        XCTAssertTrue(complete)
        XCTAssertTrue(observedRebound, "Normal-motion arrivals must visibly rebound before settling")
        for node in scene.children[1].children {
            XCTAssertEqual(node.position.y, restingY, accuracy: 0.01)
            XCTAssertEqual(node.xScale, 1, accuracy: 0.01)
            XCTAssertEqual(node.yScale, 1, accuracy: 0.01)
            let art = try XCTUnwrap(node as? FallingSkyCharacter).character
            XCTAssertEqual(art.position, .zero)
            XCTAssertEqual(art.xScale, 1, accuracy: 0.01)
            XCTAssertEqual(art.yScale, 1, accuracy: 0.01)
            XCTAssertEqual(art.zRotation, 0, accuracy: 0.01)
            XCTAssertNil(art.warpGeometry)
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
        // Inspect only the wave phase, before gravity starts at 320 ms.
        for _ in 0..<11 {
            try? await Task.sleep(for: .milliseconds(20))
            for node in scene.children[1].children where node.alpha == 1 {
                if let origin = origins[ObjectIdentifier(node)] {
                    XCTAssertEqual(node.position, origin, "Contact response cannot move the committed parent before gravity")
                }
                if let art = (node as? FallingSkyCharacter)?.character, hypot(art.position.x, art.position.y) > 0.3 {
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
        for kind in StarCast.Identity.allCases {
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
            XCTAssertEqual(unique.count, kind == .magnet || kind == .hole ? 1 : 12, "Packaged gravity objects share one frame; faced stars retain all twelve authored poses")
            let attachment = XCTAttachment(image: sheet)
            attachment.name = "star-cast-sheet-" + StarCast.character(for: kind).name
            attachment.lifetime = .keepAlways; add(attachment)
        }
    }

    @MainActor func testCastReviewSheetAtBoardAndHeroSizes() {
        let kinds = StarCast.Identity.allCases
        let format = UIGraphicsImageRendererFormat(); format.scale = 2
        let width = CGFloat(kinds.count) * 140
        let sheet = UIGraphicsImageRenderer(size: CGSize(width: width, height: 670), format: format).image { render in
            UIColor(red: 0.06, green: 0.08, blue: 0.17, alpha: 1).setFill()
            render.fill(CGRect(x: 0, y: 0, width: width, height: 670))
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


extension StarCastTests {
    @MainActor func testPackagedGravityKeepsOpenFieldOpaqueHoleAndSharedMaterials() throws {
        var images: [Data] = []
        for identity in [StarCast.Identity.magnet, .hole] {
            let image = StarCast.image(for:identity)
            let cg = try XCTUnwrap(image.cgImage)
            var pixels = [UInt8](repeating:0,count:256*256*4)
            let context = try XCTUnwrap(CGContext(data:&pixels,width:256,height:256,bitsPerComponent:8,
                bytesPerRow:256*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cg,in:CGRect(x:0,y:0,width:256,height:256))
            let centerPixelIndex: Int = 131_587
            let centerAlpha: UInt8 = pixels[centerPixelIndex]
            if identity == .magnet { XCTAssertLessThanOrEqual(centerAlpha,16,"The attraction field must leave empty space visible") }
            else { XCTAssertGreaterThanOrEqual(centerAlpha,250,"The hole's dark center must occlude the board") }
            XCTAssertEqual(pixels[3],0)
            let texture = StarCast.texture(for:identity,expression:.idle)
            for expression in StarCast.Expression.allCases {
                for facing in StarCast.Facing.allCases {
                    XCTAssertTrue(StarCast.texture(for:identity,expression:expression,facing:facing) === texture)
                }
            }
            images.append(try XCTUnwrap(image.pngData()))
        }
        XCTAssertNotEqual(images[0],images[1])
        for reference in [StarCast.Identity.dusk,.opal] {
            XCTAssertFalse(images.contains(try XCTUnwrap(StarCast.image(for:reference).pngData())))
        }
        XCTAssertEqual(StarCast.cachedMaterialCount,86)
    }
}


extension StarCastTests {
    @MainActor func testAttractionFieldsHaveNoGroundShadowsOrStarDescription() throws {
        let game = GravityFixture.opportunity.game()
        let scene = FallingSkyScene(size:CGSize(width:350,height:560))
        scene.render(game)
        let fieldIDs = game.board.compactMap { $0 }.filter { $0.gravityKind == .magnet }.map(\.id)
        XCTAssertEqual(fieldIDs.count,2)
        for id in fieldIDs {
            XCTAssertNil(scene.children[0].childNode(withName:"sky.ground.\(id)"))
        }
        let roots = scene.children[0].children.filter { $0.name?.hasPrefix("sky.ground.") == true }
        XCTAssertTrue(roots.isEmpty)
        XCTAssertEqual(StarCast.character(for:.magnet).description,"Attraction field")
        XCTAssertNil(UIImage(named:"StarCastMagnet"),"The superseded solid star must not remain in the product")
    }
}
