import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class StarlightCelebrationTests: XCTestCase {
    func testEveryRestorationPacketArrivesBeforeTheWinningClearHandsOff() {
        let flight = StarlightCelebration.packetFlight(toRestoration: true)
        XCTAssertEqual(StarlightCelebration.maximumPackets, 6)
        XCTAssertEqual(flight.start, StarfallMotion.gatherDuration)
        for index in 0..<StarlightCelebration.maximumPackets {
            XCTAssertLessThan(flight.arrivalTime(packetIndex: index), StarfallMotion.clearDuration,
                              "Packet \(index) must reach the location before the result removes the overlay")
            XCTAssertEqual(flight.progress(at: StarfallMotion.clearDuration, packetIndex: index), 1)
        }
        XCTAssertEqual(flight.arrivalTime(packetIndex: 5), 0.455, accuracy: 0.000001)
        XCTAssertEqual(flight.progress(at: 0, packetIndex: 0), 0)
    }

    func testScoreDestinationKeepsItsExistingPacketTiming() {
        let flight = StarlightCelebration.packetFlight(toRestoration: false)
        XCTAssertEqual(flight.start, 0.15)
        XCTAssertEqual(flight.duration, 0.48)
        XCTAssertEqual(flight.stagger, 0.025)
        XCTAssertEqual(flight.progress(at: 0.14, packetIndex: 0), 0)
        XCTAssertEqual(flight.progress(at: 0.39, packetIndex: 0), 0.5, accuracy: 0.000001)
        XCTAssertEqual(flight.arrivalTime(packetIndex: 0), 0.63, accuracy: 0.000001)
        XCTAssertEqual(flight.arrivalTime(packetIndex: 5), 0.755, accuracy: 0.000001)
        XCTAssertEqual(flight.progress(at: StarlightCelebration.duration, packetIndex: 5), 1)
    }

    @MainActor func testHeaderRegistrationPreservesNestedScoreBoardAndRestorationLight() async throws {
        let registered = expectation(description: "All celebration anchors reach the overlay")
        var didRegister = false
        var observed: Set<StarlightAnchor> = []
        let probe = VStack {
            Text("12").starlightAnchor(.score)
        }
        .starlightAnchor(.header)
        .background {
            ZStack {
                Color.clear.starlightAnchor(.board)
                Color.clear.frame(width: 18, height: 18).starlightAnchor(.restorationLight)
                Color.clear.frame(width: 100, height: 80).starlightAnchor(.restorationScenery)
            }
        }
        .overlayPreferenceValue(StarlightAnchors.self) { anchors in
            Color.clear
                .onAppear { inspect(Set(anchors.keys)) }
                .onChange(of: Set(anchors.keys)) { _, roles in inspect(roles) }
        }
        func inspect(_ roles: Set<StarlightAnchor>) {
            observed = roles
            if roles == [.score, .header, .board, .restorationLight, .restorationScenery], !didRegister {
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
        XCTAssertEqual(observed, [.score, .header, .board, .restorationLight, .restorationScenery])
    }

    @MainActor func testRestoredSceneryAnchorResolvesTheExpandedCanvasInOverlayCoordinates() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        // SwiftUI aligns the positioned region to device pixels. Its fractional
        // origin/extent can differ from the analytic rectangle by one pixel.
        let physicalPixel = 1 / window.screen.scale
        let registered = expectation(description: "Mapped scenery reaches the overlay after canvas translation")
        let size = CGSize(width: 375, height: 1200)
        let layout = RestorationLayout(size: size, artwork: .init(challenge: .ribbonCrossing, composition: .phone))
        var observedCanvas: CGRect?
        var observed: CGRect?
        var didRegister = false
        func inspect(canvas: CGRect, scenery: CGRect) {
            observedCanvas = canvas
            observed = scenery
            let expected = layout.restoredSceneryBounds.offsetBy(dx: canvas.minX, dy: canvas.minY)
            // The expanded canvas is pixel-aligned too: a 1200-point frame can
            // resolve to 1200⅓ points on a 3× display after this translation.
            if abs(canvas.width - size.width) <= physicalPixel,
               abs(canvas.height - size.height) <= physicalPixel,
               abs(scenery.maxY - expected.maxY) <= physicalPixel, !didRegister {
                didRegister = true; registered.fulfill()
            }
        }
        let probe = ZStack(alignment: .topLeading) {
            RestorationEnvironment(presentation: .init(challenge: .ribbonCrossing,
                                                       progress: .init(score: 18, target: 18)),
                                   active: false, ambientActive: false, quiet: true)
                .frame(width: size.width, height: size.height)
                .starlightAnchor(.board)
                .offset(x: 17, y: -145)
        }
        .frame(width: 500, height: 852, alignment: .topLeading)
        .overlayPreferenceValue(StarlightAnchors.self) { anchors in
            GeometryReader { geometry in
                if let canvas = anchors[.board], let scenery = anchors[.restorationScenery] {
                    let canvasFrame = geometry[canvas], sceneryFrame = geometry[scenery]
                    Color.clear
                        .onAppear { inspect(canvas: canvasFrame, scenery: sceneryFrame) }
                        .onChange(of: canvasFrame) { _, value in inspect(canvas: value, scenery: sceneryFrame) }
                        .onChange(of: sceneryFrame) { _, value in inspect(canvas: canvasFrame, scenery: value) }
                }
            }
        }
        window.rootViewController = UIHostingController(rootView: probe)
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        await fulfillment(of: [registered], timeout: 3)
        let canvas = try XCTUnwrap(observedCanvas)
        XCTAssertEqual(canvas.minX, 17, accuracy: physicalPixel)
        XCTAssertEqual(canvas.minY, -145, accuracy: physicalPixel)
        XCTAssertEqual(canvas.width, size.width, accuracy: physicalPixel)
        XCTAssertEqual(canvas.height, size.height, accuracy: physicalPixel)
        let scenery = try XCTUnwrap(observed)
        let expected = layout.restoredSceneryBounds.offsetBy(dx: 17, dy: -145)
        XCTAssertEqual(scenery.minX, expected.minX, accuracy: physicalPixel)
        XCTAssertEqual(scenery.minY, expected.minY, accuracy: physicalPixel)
        XCTAssertEqual(scenery.width, expected.width, accuracy: physicalPixel)
        XCTAssertEqual(scenery.height, expected.height, accuracy: physicalPixel)
    }

    @MainActor func testOrdinaryAwardActuallyRendersAboveTheBoard() async throws {
        for quiet in [false, true] {
            let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
            let previous = scene.windows.first(where: \.isKeyWindow)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            let host = UIHostingController(rootView: AnyView(Color.black))
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
            host.view.layoutIfNeeded()
            let before = SkyTechniqueExample.rescue.game()
            var after = before
            let turn = try XCTUnwrap(after.clear(Cell(0, 0)))
            let receipt = try XCTUnwrap(StarlightCelebration(id: 1, turn: turn, from: before, total: after.score))
            host.rootView = AnyView(StarlightCelebrationOverlay(event: receipt,
                board: CGRect(x: 0, y: 0, width: 390, height: 844),
                score: CGRect(x: 12, y: 59, width: 35, height: 21),
                header: CGRect(x: 12, y: 47, width: 366, height: 44), quiet: quiet).background(Color.black))
            var brightPixels = 0
            var capture: UIImage?
            let deadline = ContinuousClock.now + .milliseconds(900)
            repeat {
                await Task.yield()
                host.view.layoutIfNeeded()
                let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                capture = image
                let cg = try XCTUnwrap(image.cgImage)
                let crop = try XCTUnwrap(cg.cropping(to: CGRect(x: 130 * image.scale, y: 100 * image.scale,
                    width: 130 * image.scale, height: 110 * image.scale)))
                var pixels = [UInt8](repeating: 0, count: crop.width * crop.height * 4)
                let context = try XCTUnwrap(CGContext(data: &pixels, width: crop.width, height: crop.height,
                    bitsPerComponent: 8, bytesPerRow: crop.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
                brightPixels = stride(from: 0, to: pixels.count, by: 4).filter {
                    pixels[$0] > 100 || pixels[$0+1] > 100 || pixels[$0+2] > 100
                }.count
                if brightPixels < 40 { try await Task.sleep(for: .milliseconds(20)) }
            } while brightPixels < 40 && ContinuousClock.now < deadline
            let attachment = XCTAttachment(image: try XCTUnwrap(capture))
            attachment.name = "ordinary-award-rendered-\(quiet ? "quiet" : "normal")"; attachment.lifetime = .keepAlways; add(attachment)
            XCTAssertGreaterThan(brightPixels, 40, "The committed +3 must render in the sky, not merely exist in receipt state")
        }
    }

    @MainActor func testFullGameRendersOrdinaryRecipeTraceAndRelayAwards() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        for example in [SkyTechniqueExample.nudge, .relay, .trace, .fork] {
            let suite = "Starfall.RenderAward.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = FallingSkyStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--technique-review", "--technique-example=\(example.rawValue)"],
                clock: ManualRainClock())
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
            var observedAwardRegion: CGRect?
            let host = UIHostingController(rootView: FallingSkyView(store: store,
                flow: SkyFlowState(arguments: ["--starfalls-reset", "--technique-review"]))
                .environment(\.scenePhase, .active)
                .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                    GeometryReader { geometry in
                        if let board = anchors[.board], let header = anchors[.header] {
                            let origin = geometry.frame(in: .global).origin
                            let region = StarlightCelebrationOverlay.awardRegion(
                                board: geometry[board], header: geometry[header], accessible: false)
                                .offsetBy(dx: origin.x, dy: origin.y)
                            Color.clear
                                .onAppear { observedAwardRegion = region }
                                .onChange(of: region) { _, value in observedAwardRegion = value }
                        }
                    }.allowsHitTesting(false)
                })
            window.rootViewController = host; window.makeKeyAndVisible()
            defer { window.isHidden = true; window.rootViewController = nil; store.setSuspended(true); previous?.makeKey() }
            let readyDeadline = ContinuousClock.now + .seconds(3)
            while (!store.sceneReady || store.suspended || observedAwardRegion?.isEmpty != false)
                    && ContinuousClock.now < readyDeadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            XCTAssertTrue(store.sceneReady); XCTAssertFalse(store.suspended)
            let awardRegion = try XCTUnwrap(observedAwardRegion)
            XCTAssertFalse(awardRegion.isEmpty)
            XCTAssertTrue(window.bounds.contains(awardRegion))
            let initial = windowImage(window)
            let baseline = try awardInk(in: initial, region: awardRegion)
            for action in 0..<(example == .relay ? 2 : 1) {
                let oldTotal = store.game.score
                switch example {
                case .nudge: store.clear(Cell(0, 0))
                case .trace: store.clearTracedConstellation((0..<5).map { Cell(0, $0) },
                    snapshot: store.game, generation: store.constellationInputGeneration)
                default:
                    let recipe = try XCTUnwrap(store.game.recipes.first { example != .fork || $0.shape == .cross })
                    XCTAssertTrue(store.performTechnique(.recipe(recipe), snapshot: store.game,
                        generation: store.constellationInputGeneration))
                }
                let receipt = try XCTUnwrap(store.celebration)
                XCTAssertEqual(store.game.score - oldTotal, receipt.collected)
                XCTAssertEqual(receipt.collected, example == .nudge ? 3 : (example == .relay ? 4 : 5))
                switch example {
                case .nudge: XCTAssertEqual(receipt.level, .ordinary)
                case .trace: XCTAssertEqual(receipt.level, .constellation)
                case .fork: XCTAssertEqual(receipt.level, .recipe(.cross))
                default: XCTAssertEqual(receipt.level, action == 0 ? .recipe(.square) : .relay(2))
                }
                var captured = false
                let end = ContinuousClock.now + .seconds(2)
                var frame = 0
                repeat {
                    await Task.yield()
                    let image = windowImage(window)
                    XCTAssertEqual(observedAwardRegion, awardRegion,
                                   "Compare award ink in the same measured region as the baseline")
                    if !captured, try awardInk(in: image, region: awardRegion) > baseline + 100 {
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "game-award-\(example.rawValue)-\(action)"
                        attachment.lifetime = .keepAlways; add(attachment); captured = true
                    }
                    if frame == 3 || frame == 7 {
                        let attachment = XCTAttachment(image: image)
                        attachment.name = "game-motion-\(example.rawValue)-\(action)-\(frame)"
                        attachment.lifetime = .keepAlways; add(attachment)
                    }
                    frame += 1
                    try await Task.sleep(for: .milliseconds(100))
                } while store.celebration != nil && ContinuousClock.now < end
                XCTAssertTrue(captured, "Full game must visibly draw the \(example.rawValue) award in its intended region")
                XCTAssertNil(store.celebration)
            }
        }
    }

    /// Current-rule history, full SpriteKit presentation, no alternate rules or quiet effects.
    /// Attachments support visual review; assertions alone do not establish readability.
    @MainActor func testCrowdedCurrentSkyAwardsAtCompactLargeAndMaximumText() async throws {
        var game = FallingSky.freshSurvival(seed: 28)
        // With automatic aging retired, the old 29-shower history is terminal.
        // Twelve showers retain a dense live sky and the same exact +8 award.
        for _ in 0..<12 { XCTAssertNotNil(game.letStarsFall()) }
        XCTAssertFalse(game.isOver)
        XCTAssertFalse(game.hasCriticalMass)
        XCTAssertEqual(game.board.compactMap { $0 }.count, 33)
        let group = try XCTUnwrap(game.legalGroups.max(by: {
            game.reward(of: Set($0)) < game.reward(of: Set($1))
        }))
        XCTAssertEqual(game.reward(of: Set(group)), 8)
        XCTAssertTrue(game.legalGroups.contains { Set($0.map(\.column)).isDisjoint(with: Set(group.map(\.column))) })
        let chosen = (game: game, group: group)
        XCTAssertFalse(UIAccessibility.isReduceMotionEnabled, "Do not use quiet motion to validate this scenario")
        let note = XCTAttachment(string: "seed=28; showers=12; occupied=33; reward=8; group=\(group)")
        note.name = "crowded-current-history"; note.lifetime = .keepAlways; add(note)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        for size in [CGSize(width: 375, height: 667), CGSize(width: 430, height: 932)] {
            for maximumText in [false, true] {
                let suite = "Starfall.CrowdedAward.\(UUID())", defaults = UserDefaults(suiteName: suite)!
                defer { defaults.removePersistentDomain(forName: suite) }
                defaults.set(false, forKey: "calmEffects")
                defaults.set(try SkySaveArchive.encode(chosen.game), forKey: SkySaveArchive.key)
                let store = FallingSkyStore(defaults: defaults, arguments: [], clock: ManualRainClock())
                let window = UIWindow(windowScene: scene)
                window.frame = CGRect(origin: .zero, size: size)
                window.rootViewController = UIHostingController(rootView: FallingSkyView(store: store,
                    flow: SkyFlowState(arguments: ["--starfalls-reset", "--technique-review"]))
                    .environment(\.scenePhase, .active)
                    .dynamicTypeSize(maximumText ? .accessibility5 : .large)
                    .defaultAppStorage(defaults))
                window.makeKeyAndVisible()
                defer { store.setSuspended(true); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
                let ready = ContinuousClock.now + .seconds(3)
                while (!store.sceneReady || store.suspended) && ContinuousClock.now < ready {
                    try await Task.sleep(for: .milliseconds(20))
                }
                XCTAssertTrue(store.sceneReady); XCTAssertFalse(store.suspended)
                XCTAssertFalse(store.scene.reduceMotion, "This review requires normal SpriteKit motion")
                let variant = "\(Int(size.width))x\(Int(size.height))-\(maximumText ? "maximum" : "default")"
                func capture(_ phase: String) {
                    let attachment = XCTAttachment(image: windowImage(window))
                    attachment.name = "crowded-\(variant)-\(phase)"; attachment.lifetime = .keepAlways; add(attachment)
                }
                capture("before")
                store.clear(try XCTUnwrap(chosen.group.first))
                let event = try XCTUnwrap(store.celebration)
                XCTAssertGreaterThanOrEqual(event.collected, 8)
                XCTAssertTrue(store.game.legalGroups.contains { group in group.contains { store.canClear($0) } },
                    "The large award must leave an independent committed match available")
                var captured: Set<Int> = []
                let deadline = ContinuousClock.now + .seconds(2)
                while store.celebration != nil && ContinuousClock.now < deadline {
                    let age = Date.now.timeIntervalSince(event.started)
                    for (index, threshold) in [0.18, 0.65, 1.1].enumerated() where age >= threshold && !captured.contains(index) {
                        capture("phase-\(index)"); captured.insert(index)
                    }
                    try await Task.sleep(for: .milliseconds(20))
                }
                XCTAssertEqual(captured, [0, 1, 2]); XCTAssertNil(store.celebration)
                capture("after")
            }
        }
    }

    @MainActor private func windowImage(_ window: UIWindow) -> UIImage {
        UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    private func awardInk(in image: UIImage, region: CGRect) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        // Resolve the same live anchors as the award, in window capture coordinates.
        let crop = try XCTUnwrap(cg.cropping(to: region.applying(CGAffineTransform(scaleX:image.scale,y:image.scale))))
        var pixels = [UInt8](repeating: 0, count: crop.width * crop.height * 4)
        let context = try XCTUnwrap(CGContext(data: &pixels, width: crop.width, height: crop.height,
            bitsPerComponent: 8, bytesPerRow: crop.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        return stride(from: 0, to: pixels.count, by: 4).filter {
            // Illustrated rewards inherit a family color; require the same amount of
            // additional bright ink, without requiring that ink to be neutral white.
            max(pixels[$0], pixels[$0+1], pixels[$0+2]) > 210
        }.count
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

    @MainActor func testContributorColorsAndWeightsComeFromRewardingPreclearStars() throws {
        let original = ConstellationFixture.opalTrace.game(), path = (0..<5).map { Cell($0, 2) }
        let (store, _, _, _) = try makeStore(original)
        let before = store.game
        store.clearTracedConstellation(path, snapshot: before, generation: store.constellationInputGeneration)
        let receipt = try XCTUnwrap(store.celebration)
        XCTAssertEqual(receipt.contributors.map(\.cell), receipt.cells)
        XCTAssertEqual(receipt.contributors.map(\.reward).reduce(0, +), receipt.collected)
        XCTAssertTrue(receipt.contributors.contains { $0.identity == .white })
        XCTAssertTrue(receipt.contributors.contains { $0.reward == 2 })
        for source in receipt.contributors {
            XCTAssertGreaterThan(source.reward, 0)
            XCTAssertEqual(source.identity, before.gem(at: source.cell)?.identity)
            XCTAssertEqual(source.reward, before.reward(of: [source.cell]))
        }
        XCTAssertFalse(receipt.contributors.contains { $0.cell == Cell(3, 2) })
        XCTAssertLessThanOrEqual(receipt.packets.count, 6)
        XCTAssertEqual(receipt.packets.first, receipt.contributors.first)
        XCTAssertEqual(receipt.packets.last, receipt.contributors.last)
        store.restart(sameSky: true)
        XCTAssertEqual(receipt.contributors.map(\.reward).reduce(0, +), 7, "Receipt remains a pre-clear value snapshot")
    }

    @MainActor func testLargeHarvestSamplesWholeGroupWithSixPacketsAndExactGrownWeight() throws {
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(FallingSky(seed: 5))) as? [String: Any])
        var board: [Any] = Array(repeating: NSNull(), count: 49)
        for index in 0..<14 {
            board[index] = ["id": index, "kind": Jewel.rose.rawValue, "grown": index.isMultiple(of: 2)] as [String: Any]
        }
        object["board"] = board; object["starsLanded"] = 21; object["turns"] = 5
        let before = try JSONDecoder().decode(FallingSky.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertTrue(before.isValidSave)
        var after = before
        let turn = try XCTUnwrap(after.clear(Cell(0, 0)))
        let receipt = try XCTUnwrap(StarlightCelebration(id: 1, turn: turn, from: before, total: after.score))
        XCTAssertEqual(receipt.collected, 21)
        XCTAssertEqual(receipt.level, .brilliant)
        XCTAssertTrue(receipt.isExceptional)
        XCTAssertEqual(receipt.energy, 1)
        XCTAssertEqual(receipt.packets.count, 6)
        XCTAssertEqual(Set(receipt.packets.map(\.cell)).count, 6)
        XCTAssertEqual(receipt.packets.first?.cell, Cell(0, 0))
        XCTAssertEqual(receipt.packets.last?.cell, Cell(1, 6))
        XCTAssertTrue(receipt.contributors.allSatisfy { $0.identity == .colored(.rose) })
        XCTAssertEqual(receipt.contributors.filter { $0.reward == 2 }.count, 7)
        XCTAssertTrue(after.isValidSave)
    }

    func testAwardEnergyIncreasesAndCapsWithoutChangingCategories() {
        XCTAssertEqual(StarlightCelebration.energy(for: 0), 0)
        let energies = (3...18).map(StarlightCelebration.energy(for:))
        XCTAssertTrue(zip(energies, energies.dropFirst()).allSatisfy { $0 < $1 })
        XCTAssertEqual(StarlightCelebration.energy(for: 18), 1)
        XCTAssertEqual(StarlightCelebration.energy(for: 98), 1)
    }

    @MainActor func testAwardLetteringLeavesEveryPlayableRowClear() {
        for size in [CGSize(width: 375, height: 667), CGSize(width: 390, height: 844),
                     CGSize(width: 430, height: 932), CGSize(width: 1024, height: 1366)] {
            for accessible in [false, true] {
                let reading = FallingSkyView.readingCanvas(viewport: size, accessible: accessible)
                let canvas = reading.size
                let mapping = LandingGeometry(size:canvas,largeHeader:accessible)
                let board = CGRect(origin: CGPoint(x: 13, y: 27), size: canvas)
                let header = mapping.crownFrame.offsetBy(dx:board.minX,dy:board.minY)
                let region = StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: accessible)
                XCTAssertGreaterThan(region.height, 20)
                XCTAssertFalse(region.intersects(header))
                XCTAssertTrue(board.contains(region))
                if accessible {
                    XCTAssertLessThanOrEqual(region.maxY, board.minY + reading.visibleHeight)
                    let guideTop = board.minY + reading.visibleHeight + StarfallTheme.Spacing.small
                    XCTAssertLessThan(region.maxY, guideTop, "Accessible awards must end before the reading guide")
                }
                for row in 0..<7 {
                    for column in 0..<7 {
                        let cell = mapping.frame(Cell(row, column))
                            .offsetBy(dx: board.minX, dy: board.minY)
                        XCTAssertFalse(region.intersects(cell), "Every phase is clipped to this protected region")
                    }
                }
            }
        }
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
