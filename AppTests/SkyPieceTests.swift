import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class SkyPieceTests: XCTestCase {
    @MainActor private var families: [StarCast.Identity] {
        Jewel.allCases.map(StarCast.Identity.colored) + [.dusk, .opal]
    }

    @MainActor private func gem(_ identity: StarCast.Identity, id: Int, grown: Bool = false) -> StarfallGem {
        switch identity {
        case .colored(let kind): StarfallGem(id: id, kind: kind, grown: grown)
        case .opal: StarfallGem(id: id, kind: nil, light: true)
        default: StarfallGem(id: id, kind: nil)
        }
    }

    @MainActor func testGameplayUsesPackagedFacelessMaterialsAndPreservesStoryPortraits() throws {
        SkyPiece.prewarm()
        StarCast.prewarm()
        XCTAssertEqual(SkyPiece.cachedMaterialCount, 9)
        XCTAssertEqual(SkyPiece.maximumRasterBytes, 6_029_312,
                       "Seven rest/shell/mask sets and two shared historical textures stay bounded")
        for identity in families {
            let name = StarCast.character(for: identity).name
            let asset = try XCTUnwrap(UIImage(named: "SkyPiece" + name))
            let gameplay = SkyPiece.image(for: identity)
            let shellPixels = try pixels(asset), gameplayPixels = try pixels(gameplay)
            XCTAssertNotEqual(gameplayPixels, shellPixels, "The shared resting material must fill the translucent shell with light")
            let shellAlpha = stride(from: 3, to: shellPixels.count, by: 4).map { shellPixels[$0] }
            let gameplayAlpha = stride(from: 3, to: gameplayPixels.count, by: 4).map { gameplayPixels[$0] }
            XCTAssertGreaterThan(shellAlpha.filter { $0 > 8 && $0 < 240 }.count, 256,
                                 "Every authored shell needs a translucent interior")
            XCTAssertGreaterThan(gameplayAlpha.filter { $0 >= 240 }.count,
                                 shellAlpha.filter { $0 >= 240 }.count,
                                 "The resting composite must give the translucent interior visible substance")
            XCTAssertNotEqual(try pixels(gameplay), try pixels(StarCast.image(for: identity)), "Story and gameplay materials have separate roles")
            let texture = SkyPiece.texture(for: identity)
            let portrait = StarCast.texture(for: identity, expression: .idle)
            for _ in 0..<30 {
                let node = FallingSkyCharacter(gem: gem(identity, id: 1), step: 45)
                for expression in StarCast.Expression.allCases {
                    for facing in StarCast.Facing.allCases {
                        node.showExpression(expression, facing: facing)
                        XCTAssertTrue(node.character.texture === texture)
                        XCTAssertEqual(node.character.name, "sky-piece." + name)
                        XCTAssertNotNil(node.character.value(forAttributeNamed: "a_light"))
                        XCTAssertEqual(LivingLight.drain(on: node.character), 0)
                        XCTAssertEqual(LivingLight.pressure(on: node.character), 0)
                    }
                }
            }
            XCTAssertTrue(StarCast.texture(for: identity, expression: .idle) === portrait)
            XCTAssertFalse(texture === portrait)
            XCTAssertEqual(texture.size(), CGSize(width: 256, height: 256))
            XCTAssertEqual(texture.filteringMode, .linear)
            XCTAssertFalse(texture.usesMipmaps)
        }
        for identity in [StarCast.Identity.magnet, .hole] {
            XCTAssertTrue(SkyPiece.texture(for: identity) === StarCast.texture(for: identity, expression: .idle),
                          "Retained faceless gravity objects share their existing material")
        }
        XCTAssertEqual(SkyPiece.cachedMaterialCount, SkyPiece.maximumMaterials)
        XCTAssertEqual(StarCast.cachedMaterialCount, StarCast.maximumMaterials)
    }

    @MainActor func testGameplayBodiesKeepTransparentPaddingAndDistinctSmallSilhouettes() throws {
        var silhouettes = Set<Data>()
        for identity in families {
            let image = SkyPiece.image(for: identity)
            XCTAssertEqual(image.size, CGSize(width: 256, height: 256))
            let rgba = try pixels(image)
            let alpha = stride(from: 3, to: rgba.count, by: 4).map { rgba[$0] }
            XCTAssertTrue(alpha.contains { $0 >= 240 }, "A luminous interior must remain substantial against the scene")
            for y in 0..<256 { for x in 0..<256 where x < 18 || x >= 238 || y < 18 || y >= 238 {
                XCTAssertEqual(alpha[y * 256 + x], 0, "Pieces need transparent clearance around every edge")
            } }
            let small = try pixels(image, side: 24)
            silhouettes.insert(Data(stride(from: 3, to: small.count, by: 4).map { small[$0] >= 128 ? 255 : 0 }))
        }
        XCTAssertEqual(silhouettes.count, families.count, "All seven families must retain different silhouettes at the smallest review size")
    }

    @MainActor func testRestingNativeLightMatchesTheCachedForecastMaterial() throws {
        let size = CGSize(width: 256, height: 256)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        defer { view.presentScene(nil) }
        var pairs: [(UIImage, UIImage)] = []
        for identity in families {
            let scene = SKScene(size: size)
            scene.backgroundColor = .clear
            let node = SkyPiece.makeNode(for: identity, radius: SkyPiece.silhouetteSide / 2)
            node.position = CGPoint(x: 128, y: 128)
            scene.addChild(node); view.presentScene(scene)
            XCTAssertNotNil(node.value(forAttributeNamed: "a_light"))
            let live = UIImage(cgImage: try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: size))).cgImage())
            node.shader = nil
            let cached = UIImage(cgImage: try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: size))).cgImage())
            let livePixels = try pixels(live), cachedPixels = try pixels(cached)
            var difference = 0, comparedChannels = 0
            for offset in stride(from: 0, to: livePixels.count, by: 4)
                where max(livePixels[offset + 3], cachedPixels[offset + 3]) > 8 {
                for channel in 0..<4 {
                    difference += abs(Int(livePixels[offset + channel]) - Int(cachedPixels[offset + channel]))
                    comparedChannels += 1
                }
            }
            XCTAssertGreaterThan(comparedChannels, 256, "Native materials must actually render")
            XCTAssertLessThan(Double(difference) / Double(max(1, comparedChannels)), 12,
                              "\(identity): board and forecast resting materials must agree despite GPU sampling/rounding")
            pairs.append((live, cached))
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let review = UIGraphicsImageRenderer(size: CGSize(width: 256, height: CGFloat(pairs.count * 128)), format: format).image { _ in
            for (row, pair) in pairs.enumerated() {
                pair.0.draw(in: CGRect(x: 0, y: CGFloat(row * 128), width: 128, height: 128))
                pair.1.draw(in: CGRect(x: 128, y: CGFloat(row * 128), width: 128, height: 128))
            }
        }
        attach(review, name: "living-light-native-rest-left-cached-forecast-right")
    }

    @MainActor func testMaterialRefreshPreservesChildPoseAndResetRestoresIt() {
        for identity in families {
            let root = FallingSkyCharacter(gem: gem(identity, id: 1), step: 45)
            let node = root.character
            let neutralSize = node.size
            node.anchorPoint = CGPoint(x: 0.4, y: 0.6)
            node.position = CGPoint(x: 2, y: -3)
            node.xScale = 0.83; node.yScale = 1.12; node.zRotation = 0.21
            node.warpGeometry = OpalMotion.squashed
            // SpriteKit stores transforms at Float precision and reports scaled size.
            // Preserve its actual posed readbacks, then compare reset with the neutral size.
            let size = node.size, warp = node.warpGeometry, anchor = node.anchorPoint
            let position = node.position, xScale = node.xScale, yScale = node.yScale, rotation = node.zRotation
            for expression in StarCast.Expression.allCases {
                root.showExpression(expression)
                XCTAssertEqual(node.size, size)
                XCTAssertEqual(node.anchorPoint, anchor)
                XCTAssertEqual(node.position, position)
                XCTAssertEqual(node.xScale, xScale); XCTAssertEqual(node.yScale, yScale)
                XCTAssertEqual(node.zRotation, rotation); XCTAssertTrue(node.warpGeometry === warp)
            }
            root.cancelLocalMotion()
            assertStill(root)
            XCTAssertEqual(node.size, neutralSize)
            XCTAssertEqual(node.anchorPoint, anchor)
        }
    }

    @MainActor func testLivingLightStateIsLocalAndResetPreservesCommittedDrain() throws {
        for identity in families {
            let first = FallingSkyCharacter(gem: gem(identity, id: 1), step: 45)
            let second = FallingSkyCharacter(gem: gem(identity, id: 2), step: 45)
            let firstShader = try XCTUnwrap(first.character.shader)
            let secondShader = try XCTUnwrap(second.character.shader)
            XCTAssertTrue(firstShader === secondShader, "Pieces of one family reuse one immutable shader program")
            XCTAssertTrue(first.character.texture === second.character.texture,
                          "Independent presentation state still reuses the bounded resting material")
            first.setDrain(1)
            XCTAssertEqual(LivingLight.drain(on: first.character), 1)
            XCTAssertEqual(LivingLight.drain(on: second.character), 0)
            LivingLight.reset(first.character)
            XCTAssertTrue(first.character.shader === firstShader)
            XCTAssertEqual(LivingLight.drain(on: first.character), 1,
                           "Cancelling decorative light cannot erase committed historical drainage")
            XCTAssertEqual(LivingLight.offset(on: first.character), .zero)
            XCTAssertFalse(LivingLight.isResponding(on: first.character))
        }
    }

    @MainActor func testFamilyPerspectiveProfilesAreDistinctAndStayWithinFiniteBounds() {
        let profiles = families.map { SkyPieceMotion.profile(for: $0) }
        for index in profiles.indices {
            for other in profiles.indices where other > index {
                XCTAssertNotEqual(profiles[index], profiles[other], "Family motion must not collapse to one shared response")
            }
            let profile = profiles[index]
            for direction in [CGFloat(-1), 1] {
                let corners = SkyPieceMotion.perspectiveVertices(yaw: direction * profile.yaw, pitch: profile.pitch)
                XCTAssertEqual(corners.count, 4)
                for corner in corners {
                    XCTAssertTrue(corner.x.isFinite && corner.y.isFinite)
                    XCTAssertGreaterThanOrEqual(corner.x, -0.15); XCTAssertLessThanOrEqual(corner.x, 1.15)
                    XCTAssertGreaterThanOrEqual(corner.y, -0.15); XCTAssertLessThanOrEqual(corner.y, 1.15)
                }
                let horizontal = corners[1] - corners[0], vertical = corners[2] - corners[0]
                XCTAssertGreaterThan(horizontal.x * vertical.y - horizontal.y * vertical.x, 0.5,
                                     "A shallow pose must not fold or collapse the artwork")
            }
        }
    }

    @MainActor func testNativeGameplayReviewAtSmallSizesWithSilhouettesGrayAndGrownAura() throws {
        let size = CGSize(width: 1008, height: 900)
        let scene = SKScene(size: size)
        scene.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.17, alpha: 1)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.presentScene(scene)
        defer { view.presentScene(nil) }
        let lightBand = SKSpriteNode(color: UIColor(white: 0.92, alpha: 1), size: CGSize(width: size.width, height: 140))
        lightBand.position = CGPoint(x: size.width / 2, y: 570); scene.addChild(lightBand)
        let silhouetteBand = SKSpriteNode(color: .white, size: CGSize(width: size.width, height: 140))
        silhouetteBand.position = CGPoint(x: size.width / 2, y: 410); scene.addChild(silhouetteBand)
        label("Native gameplay material • visible body sizes 24 / 36 / 44 pt", at: CGPoint(x: size.width / 2, y: 866), in: scene, size: 18)
        let grayscale = SKShader(source: """
        void main() {
            vec4 color = texture2D(u_texture, v_tex_coord);
            float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
            gl_FragColor = vec4(vec3(gray), color.a);
        }
        """)
        for (column, identity) in families.enumerated() {
            let x = CGFloat(column) * 144
            label(StarCast.character(for: identity).name, at: CGPoint(x: x + 72, y: 810), in: scene, size: 17)
            for (row, y) in [CGFloat(730), 570, 410, 250].enumerated() {
                for (index, side) in [CGFloat(24), 36, 44].enumerated() {
                    let node = SkyPiece.makeNode(for: identity, radius: side / 2)
                    node.position = CGPoint(x: x + 24 + CGFloat(index) * 46, y: y)
                    if row == 2 { node.shader = nil; node.color = .black; node.colorBlendFactor = 1 }
                    if row == 3 { node.shader = grayscale }
                    scene.addChild(node)
                }
                label(["Dark sky", "Light sky", "Silhouette", "Grayscale"][row],
                      at: CGPoint(x: x + 72, y: y + 48), in: scene, size: 11,
                      color: row == 1 || row == 2 ? .darkGray : .white)
            }
            for (index, grown) in [false, true].enumerated() {
                let root = FallingSkyCharacter(gem: gem(identity, id: column, grown: grown),
                                              step: 44 / StarfallMotion.pieceRadius / 2)
                root.position = CGPoint(x: x + 38 + CGFloat(index) * 68, y: 92)
                root.setGrowthMotion(false); scene.addChild(root)
            }
            let caption = identity == .dusk || identity == .opal ? "Special · no growth" : "1 light     2 lights"
            label(caption, at: CGPoint(x: x + 72, y: 152), in: scene, size: 11)
        }
        let texture = try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: size)))
        attach(UIImage(cgImage: texture.cgImage()), name: "sky-piece-native-material-review")
    }

    @MainActor func testEveryFamilyHasFiniteNativeFlightLandingAndContactMotion() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("All-family motion evidence requires normal system motion")
        }
        let size = CGSize(width: 420, height: 400)
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        let owner = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior = owner.windows.first(where: \.isKeyWindow), window = UIWindow(windowScene: owner)
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.frame = view.frame; window.makeKeyAndVisible()
        defer { view.presentScene(nil); window.isHidden = true; prior?.makeKey() }
        let scene = SKScene(size: size)
        scene.backgroundColor = UIColor(red: 0.06, green: 0.08, blue: 0.17, alpha: 1)
        let roots = families.enumerated().map { index, identity in
            let root = FallingSkyCharacter(gem: gem(identity, id: index), step: 56)
            root.position = CGPoint(x: 32 + CGFloat(index) * 56, y: 270)
            root.zPosition = CGFloat(index + 1)
            scene.addChild(root)
            label(StarCast.character(for: identity).name, at: CGPoint(x: root.position.x, y: 350), in: scene, size: 10)
            return root
        }
        let restingNeighbor = FallingSkyCharacter(gem: gem(families[0], id: 99), step: 56)
        restingNeighbor.position = CGPoint(x: 32, y: 88)
        scene.addChild(restingNeighbor)
        label("Still Spark", at: CGPoint(x: 32, y: 118), in: scene, size: 9)
        view.presentScene(scene)
        var firstFrame = false
        scene.run(.run { firstFrame = true }, withKey: "review.ready")
        let readyDeadline = ContinuousClock.now + .seconds(2)
        while !firstFrame && ContinuousClock.now < readyDeadline { try await Task.sleep(for: .milliseconds(16)) }
        XCTAssertTrue(firstFrame, "The visible native host must start rendering before action sampling")
        let phaseLabel = label("Flight", at: CGPoint(x: size.width / 2, y: 34), in: scene, size: 16)
        var reviewFrames: [UIImage] = []
        func capture(_ name: String) throws {
            let texture = try XCTUnwrap(view.texture(from: scene, crop: CGRect(origin: .zero, size: size)))
            let image = UIImage(cgImage: texture.cgImage())
            attach(image, name: name)
            if reviewFrames.count < 48 { reviewFrames.append(image) }
        }
        var controlArrivalReady = false, capturedControlArrival = false
        func sample(_ phase: String, movesBody: Bool = true) async throws {
            var observed = Set<Int>(), observedLight = Set<Int>(), frame = 0
            let deadline = ContinuousClock.now + .seconds(2)
            repeat {
                if controlArrivalReady {
                    try capture("sky-piece-motion-mismatched-legacy-duration-control-arrival")
                    for root in roots { root.cancelLocalMotion(); assertStill(root) }
                    controlArrivalReady = false; capturedControlArrival = true
                }
                assertStill(restingNeighbor)
                for (index, root) in roots.enumerated() {
                    let art = root.character
                    XCTAssertTrue(art.position.x.isFinite && art.position.y.isFinite && art.zRotation.isFinite)
                    XCTAssertGreaterThan(art.xScale, 0.7); XCTAssertLessThan(art.xScale, 1.3)
                    XCTAssertGreaterThan(art.yScale, 0.7); XCTAssertLessThan(art.yScale, 1.3)
                    XCTAssertLessThan(hypot(art.position.x, art.position.y), 20)
                    XCTAssertTrue(art.texture === SkyPiece.texture(for: families[index]))
                    let light = LivingLight.offset(on: art)
                    XCTAssertTrue(light.x.isFinite && light.y.isFinite)
                    XCTAssertLessThanOrEqual(hypot(light.x, light.y), LivingLight.maximumOffset + 0.0001,
                                             "Internal light must stay within its shared material bounds")
                    if hypot(light.x, light.y) > 0.0001 { observedLight.insert(index) }
                    if abs(art.zRotation) > 0.005 || abs(art.xScale - 1) > 0.005
                        || abs(art.yScale - 1) > 0.005 || hypot(art.position.x, art.position.y) > 0.1 {
                        observed.insert(index)
                    }
                    if !movesBody {
                        XCTAssertEqual(art.position, .zero)
                        XCTAssertEqual(art.xScale, 1, accuracy: 0.0001)
                        XCTAssertEqual(art.yScale, 1, accuracy: 0.0001)
                        XCTAssertEqual(art.zRotation, 0, accuracy: 0.0001)
                        XCTAssertNil(art.warpGeometry, "Attention moves internal light, not the playable body")
                    }
                }
                if frame.isMultiple(of: 3) && phase != "legacy-duration-control" {
                    try capture("sky-piece-motion-\(phase)-\(String(format: "%03d", frame))")
                }
                frame += 1
                try await Task.sleep(for: .milliseconds(20))
            } while roots.contains(where: { $0.hasActions() || $0.character.hasActions() }) && ContinuousClock.now < deadline
            XCTAssertEqual(observed.count, movesBody ? roots.count : 0,
                           "\(phase) must preserve its intended body-motion contract")
            XCTAssertEqual(observedLight.count, roots.count, "Every family must show a sampled internal-light \(phase) response")
            XCTAssertTrue(roots.allSatisfy { !$0.hasActions() && !$0.character.hasActions() }, "\(phase) must finish within its finite budget")
        }
        try capture("sky-piece-motion-before")
        for (phase, duration) in [("legacy-duration-control", 0.34),
                                  ("flight", StarfallMotion.flightDuration), ("opening-flight", 0.34)] {
            let mismatched = phase == "legacy-duration-control"
            phaseLabel.text = mismatched ? "Mismatched legacy-duration control"
                : phase == "flight" ? "Flight" : "Short opening flight"
            var arrivals = Set<Int>(), arrivalChecks = Set<Int>()
            // Allow 50 ms (three 60 Hz frames) for child cleanup after the parent arrives.
            // SpriteKit time keeps this boundary tied to actual travel, not test polling.
            let frameTolerance: TimeInterval = 3.0 / 60
            for (index, root) in roots.enumerated() {
                root.position.y = 270
                let direction: CGFloat = index.isMultiple(of: 2) ? 1 : -1
                if phase == "flight" || mismatched {
                    SkyPieceMotion.prepareFlight(root.character, identity: families[index], direction: direction)
                } else {
                    SkyPieceMotion.prepareFlight(root.character, identity: families[index], direction: direction,
                                                 duration: duration)
                }
                root.run(.sequence([
                    .moveTo(y: 170, duration: duration),
                    .run { arrivals.insert(index) },
                    .wait(forDuration: frameTolerance),
                    .run { [weak root] in
                        guard let root else { return }
                        if mismatched {
                            let art = root.character, light = LivingLight.offset(on: art)
                            XCTAssertGreaterThan(hypot(light.x, light.y), 0.0001,
                                "The unchanged ordinary-duration control still carries light response after short travel")
                            XCTAssertTrue(art.warpGeometry != nil || abs(art.zRotation) > 0.005
                                || abs(art.xScale - 1) > 0.005 || abs(art.yScale - 1) > 0.005,
                                "The control must expose a measured unfinished body pose")
                        } else {
                            self.assertStill(root)
                        }
                        XCTAssertEqual(root.position.y, 170, accuracy: 0.001,
                                       "\(phase) must settle at its actual arrival destination")
                        arrivalChecks.insert(index)
                        if mismatched && arrivalChecks.count == roots.count { controlArrivalReady = true }
                    }
                ]), withKey: "review.flight")
            }
            try await sample(phase)
            XCTAssertEqual(arrivals.count, roots.count, "Every family must finish its \(phase) travel")
            XCTAssertEqual(arrivalChecks, arrivals, "Every \(phase) arrival must check body and light settling")
            if mismatched { XCTAssertTrue(capturedControlArrival, "Capture and reset the bounded native component control") }
            else { try capture("sky-piece-motion-\(phase)-arrival-settled") }
        }
        phaseLabel.text = "Landing"
        for (index, root) in roots.enumerated() {
            root.land(direction: index.isMultiple(of: 2) ? 1 : -1, step: 56)
        }
        try await sample("landing")
        for root in roots { assertStill(root); XCTAssertEqual(root.position.y, 170, accuracy: 0.001) }
        phaseLabel.text = "Contact"
        for root in roots {
            root.acknowledge(from: CGPoint(x: root.position.x - 10, y: root.position.y),
                             impulse: CGVector(dx: 0.15, dy: -0.08), step: 56)
        }
        try await sample("contact")
        phaseLabel.text = "Settled"
        for root in roots { assertStill(root); XCTAssertEqual(root.position.y, 170, accuracy: 0.001) }
        try capture("sky-piece-motion-settled")
        phaseLabel.text = "Attention"
        for root in roots { root.attend() }
        try await sample("attention", movesBody: false)
        for root in roots { assertStill(root); XCTAssertEqual(root.position.y, 170, accuracy: 0.001) }
        for root in roots {
            for _ in 0..<5 { root.attend() }
            root.cancelLocalMotion()
            assertStill(root)
        }
        try await Task.sleep(for: .milliseconds(700))
        for root in roots {
            assertStill(root)
            XCTAssertEqual(root.position.y, 170, accuracy: 0.001,
                           "Replaced or cancelled attention cannot revive a stale response")
        }
        phaseLabel.text = "Grown bodies · one cell apart"
        for (index, root) in roots.enumerated() {
            root.update(gem(families[index], id: index, grown: true), expression: .grown)
            let aura = try XCTUnwrap(root.character.childNode(withName: "sky.growth-cue/sky.growth-aura"))
            XCTAssertLessThan(root.zPosition + root.character.zPosition + (aura.parent?.zPosition ?? 0) + aura.zPosition, 1,
                              "Even the highest-row aura must stay behind the lowest body")
        }
        try capture("sky-piece-motion-grown-before")
        phaseLabel.text = "Grown landing"
        for (index, root) in roots.enumerated() {
            root.land(direction: index.isMultiple(of: 2) ? 1 : -1, step: 56)
        }
        try await sample("grown-landing")
        for root in roots { assertStill(root); XCTAssertEqual(root.position.y, 170, accuracy: 0.001) }
        phaseLabel.text = "Grown contact"
        for root in roots {
            root.acknowledge(from: CGPoint(x: root.position.x - 10, y: root.position.y),
                             impulse: CGVector(dx: 0.15, dy: -0.08), step: 56)
        }
        try await sample("grown-contact")
        phaseLabel.text = "Grown settled"
        for root in roots { assertStill(root); XCTAssertEqual(root.position.y, 170, accuracy: 0.001) }
        try capture("sky-piece-motion-grown-settled")
        for root in roots {
            for _ in 0..<5 { root.land(direction: 1, step: 56) }
            root.setPieceMotion(false); assertStill(root)
            root.land(direction: -1, step: 56)
            root.acknowledge(from: .zero, impulse: CGVector(dx: 1, dy: 1), step: 56)
            root.attend()
            assertStill(root)
            XCTAssertEqual(root.position.y, 170, accuracy: 0.001)
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let thumbnail = CGSize(width: size.width / 2, height: size.height / 2)
        let review = UIGraphicsImageRenderer(size: CGSize(width: thumbnail.width * 4,
            height: CGFloat((reviewFrames.count + 3) / 4) * thumbnail.height), format: format).image { _ in
            for (index, frame) in reviewFrames.enumerated() {
                frame.draw(in: CGRect(x: CGFloat(index % 4) * thumbnail.width, y: CGFloat(index / 4) * thumbnail.height,
                                      width: thumbnail.width, height: thumbnail.height))
            }
        }
        attach(review, name: "sky-piece-native-motion-contact-sheet")
    }

    @MainActor func testQuietSuspensionReplacementAndDetachmentResetLocalArtwork() throws {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let scene = FallingSkyScene(size: view.bounds.size)
        view.presentScene(scene)
        defer { view.presentScene(nil) }
        let game = ObservatoryReviewFixture.game(dense: false)
        scene.render(game)
        func roots() -> [FallingSkyCharacter] { scene.children[1].children.compactMap { $0 as? FallingSkyCharacter } }
        func startResponse() {
            for root in roots() {
                root.land(direction: 1, step: 45)
                root.attend()
            }
        }
        startResponse()
        scene.reduceMotion = true
        for root in roots() { assertStill(root) }
        scene.reduceMotion = false
        startResponse()
        scene.decorativeMotionActive = false
        for root in roots() { assertStill(root) }
        scene.decorativeMotionActive = true
        startResponse()
        let replaced = roots()
        scene.render(game)
        for root in replaced { assertStill(root) }
        for root in roots() { assertStill(root) }
        startResponse()
        let detached = roots()
        view.presentScene(nil)
        for root in detached { assertStill(root) }
        XCTAssertEqual(detached.map(\.gem).sorted { $0.id < $1.id },
                       game.board.compactMap { $0 }.sorted { $0.id < $1.id },
                       "Presentation cancellation must preserve committed identities")
    }

    @MainActor private func assertStill(_ root: FallingSkyCharacter, file: StaticString = #filePath, line: UInt = #line) {
        let art = root.character
        XCTAssertEqual(art.position, .zero, file: file, line: line)
        XCTAssertEqual(art.xScale, 1, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(art.yScale, 1, accuracy: 0.0001, file: file, line: line)
        XCTAssertEqual(art.zRotation, 0, accuracy: 0.0001, file: file, line: line)
        XCTAssertNil(art.warpGeometry, file: file, line: line)
        XCTAssertFalse(art.hasActions(), file: file, line: line)
        XCTAssertEqual(LivingLight.offset(on: art), .zero, file: file, line: line)
        XCTAssertFalse(LivingLight.isResponding(on: art), file: file, line: line)
    }

    @MainActor private func pixels(_ image: UIImage, side: Int = 256) throws -> [UInt8] {
        var rgba = [UInt8](repeating: 0, count: side * side * 4)
        let context = try XCTUnwrap(CGContext(data: &rgba, width: side, height: side, bitsPerComponent: 8,
                                             bytesPerRow: side * 4, space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(try XCTUnwrap(image.cgImage), in: CGRect(x: 0, y: 0, width: side, height: side))
        return rgba
    }

    @MainActor @discardableResult private func label(_ text: String, at position: CGPoint, in scene: SKScene,
                                                     size: CGFloat, color: UIColor = .white) -> SKLabelNode {
        let node = SKLabelNode(text: text)
        node.fontName = "AvenirNext-Medium"; node.fontSize = size; node.fontColor = color
        node.position = position; scene.addChild(node); return node
    }

    private func attach(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
