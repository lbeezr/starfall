import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

/// Observe the actual display loop without replacing the scene's update owner.
@MainActor private final class DepartureFrameSampler: NSObject, SKSceneDelegate {
    var completedFrames = 0
    var sample: (() -> Void)?

    nonisolated func didFinishUpdate(for scene: SKScene) {
        MainActor.assumeIsolated {
            completedFrames += 1
            sample?()
        }
    }
}

final class HelperDepartureTests: XCTestCase {
    @MainActor private func requireNormalMotion() throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Departure movement sampling requires normal system motion; quiet behavior is checked separately")
        }
    }

    @MainActor private func host() throws -> (SKView, FallingSkyScene) {
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = windowScene.windows.first(where: \.isKeyWindow)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let window = UIWindow(windowScene: windowScene); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        let scene = FallingSkyScene(size: view.bounds.size); view.presentScene(scene)
        addTeardownBlock { @MainActor in
            view.presentScene(nil); window.isHidden = true; window.rootViewController = nil
            previous?.makeKey()
        }
        return (view, scene)
    }

    @MainActor private func characters(_ scene: FallingSkyScene) -> [FallingSkyCharacter] {
        scene.children.flatMap { $0.children.compactMap { $0 as? FallingSkyCharacter } }
    }

    @MainActor private func departures(_ scene: FallingSkyScene) -> [FallingSkyCharacter] {
        characters(scene).filter { $0.action(forKey: FallingSkyCharacter.departureKey) != nil }
    }

    @MainActor private func assertRetired(_ bodies: [FallingSkyCharacter], file: StaticString = #filePath, line: UInt = #line) {
        for body in bodies {
            XCTAssertNil(body.parent, file: file, line: line)
            XCTAssertFalse(body.hasActions(), file: file, line: line)
            XCTAssertFalse(body.character.hasActions(), file: file, line: line)
            XCTAssertNil(body.action(forKey: FallingSkyCharacter.departureKey), file: file, line: line)
        }
    }

    @MainActor private func assertSettled(_ scene: FallingSkyScene, game: FallingSky,
                                         file: StaticString = #filePath, line: UInt = #line) throws {
        let bodies = characters(scene)
        XCTAssertEqual(bodies.count, game.occupiedCount, file: file, line: line)
        XCTAssertEqual(Set(bodies.map { $0.gem.id }), Set(game.board.compactMap { $0?.id }), file: file, line: line)
        for body in bodies {
            let index = try XCTUnwrap(game.board.firstIndex { $0?.id == body.gem.id }, file: file, line: line)
            XCTAssertEqual(body.gem, game.board[index], file: file, line: line)
            let point = LandingGeometry(size: scene.size).scenePoint(Cell(index / 7, index % 7))
            // SpriteKit's transformed positions are measured at Float32 precision.
            XCTAssertEqual(Float(body.position.x), Float(point.x), file: file, line: line)
            XCTAssertEqual(Float(body.position.y), Float(point.y), file: file, line: line)
            XCTAssertNil(body.action(forKey: FallingSkyCharacter.departureKey), file: file, line: line)
        }
    }

    @MainActor func testActualBodiesLiftAndTumbleWithoutChangingTheirMaterialOrGrownSize() async throws {
        try requireNormalMotion()
        let (view, scene) = try host()
        let gems = [StarfallGem(id: 1, kind: .rose), StarfallGem(id: 2, kind: .aqua, grown: true),
                    StarfallGem(id: 3, kind: nil, light: true)]
        XCTAssertEqual(StarfallMotion.departureDuration, 0.18, accuracy: 0.000001)
        XCTAssertEqual(StarfallMotion.clearDuration, 0.56)
        XCTAssertEqual(StarfallMotion.gravityStart, 0.32)
        let sampler = DepartureFrameSampler()
        scene.delegate = sampler
        defer { sampler.sample = nil; scene.delegate = nil }
        for gem in gems {
            let body = FallingSkyCharacter(gem: gem, step: 54)
            body.position = CGPoint(x: 195, y: 300); scene.addChild(body)
            let original = body.position, size = body.character.size, texture = body.character.texture
            let children = body.children.count, innerChildren = body.character.children.count
            // Two completed callbacks with the resting body ensure that the
            // visible SKView has rendered a frame before its short action starts.
            let readyFrame = sampler.completedFrames + 2
            let readyDeadline = ContinuousClock.now + .seconds(1)
            while sampler.completedFrames < readyFrame && ContinuousClock.now < readyDeadline {
                try await Task.sleep(for: .milliseconds(8))
            }
            XCTAssertNotNil(view.window, "gem \(gem.id): the rendering host must remain attached")
            XCTAssertFalse(view.isPaused); XCTAssertFalse(scene.isPaused)
            XCTAssertGreaterThanOrEqual(sampler.completedFrames, readyFrame,
                                        "gem \(gem.id): no rendered-frame readiness before departure")
            var lifted = false, drifted = false, turned = false, lateFade = false, captured = false
            var captureAttempted = false, frameStates: [String] = []
            let started = ProcessInfo.processInfo.systemUptime
            sampler.sample = {
                let frame = sampler.completedFrames
                frameStates.append("frame=\(frame) elapsed=\(ProcessInfo.processInfo.systemUptime - started) "
                    + "position=\(body.position) rotation=\(body.zRotation) alpha=\(body.alpha) attached=\(body.parent != nil)")
                guard body.parent != nil else { return }
                lifted = lifted || body.position.y > original.y + 1
                drifted = drifted || abs(body.position.x - original.x) > 0.5
                turned = turned || abs(body.zRotation) > 0.01
                lateFade = lateFade || (body.alpha > 0 && body.alpha < 0.95)
                let state = "gem \(gem.id), frame \(frame)"
                XCTAssertEqual(body.character.size, size, state)
                XCTAssertEqual(body.xScale, 1, state); XCTAssertEqual(body.yScale, 1, state)
                XCTAssertTrue(body.character.texture === texture, state)
                XCTAssertEqual(body.children.count, children, state)
                XCTAssertEqual(body.character.children.count, innerChildren, state)
                // Rasterization is synchronous. It must not interrupt sampling
                // before the brief late-fade frame has actually been observed.
                if lifted && drifted && turned && lateFade && !captureAttempted {
                    captureAttempted = true
                    if let image = view.texture(from: scene)?.cgImage() {
                        let attachment = XCTAttachment(image: UIImage(cgImage: image))
                        attachment.name = "helper-departure-actual-body-\(gem.id)"
                        attachment.lifetime = .keepAlways; self.add(attachment); captured = true
                    }
                }
            }
            body.depart(step: 54)
            XCTAssertNotNil(body.action(forKey: FallingSkyCharacter.departureKey))
            let deadline = ContinuousClock.now + .seconds(1)
            while body.parent != nil && ContinuousClock.now < deadline {
                try await Task.sleep(for: .milliseconds(8))
            }
            sampler.sample = nil
            let state = "gem=\(gem.id) grown=\(gem.grown) lifted=\(lifted) drifted=\(drifted) "
                + "turned=\(turned) lateFade=\(lateFade) captured=\(captured) captureAttempted=\(captureAttempted)"
            let diagnostics = XCTAttachment(string: ([state] + frameStates).joined(separator: "\n"))
            diagnostics.name = "helper-departure-frame-states-\(gem.id)"
            diagnostics.lifetime = .keepAlways; add(diagnostics)
            XCTAssertTrue(lifted, state); XCTAssertTrue(drifted, state)
            XCTAssertTrue(turned, state); XCTAssertTrue(lateFade, state)
            XCTAssertTrue(captured, state)
            assertRetired([body])
        }
    }

    @MainActor func testManualDeparturesUseEveryCoreClearedIdentityAndFinishBeforeTheExistingHandoff() async throws {
        try requireNormalMotion()
        let (_, scene) = try host()
        let diagonal = (0..<5).map { Cell($0, $0) }
        let branch = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,3), Cell(0,4), Cell(1,5), Cell(1,6)]
        let examples: [(FallingSky, [Cell]?, Cell?)] = [
            (ConstellationFixture.diagonalSix.game(), diagonal, nil),
            (ConstellationFixture.overlap.game(), branch, nil),
            (ConstellationFixture.opalTrace.game().adoptingFeedingDusk(), (0..<5).map { Cell($0, 2) }, nil),
            (SkyTutorial.grown.game(), nil, Cell(0,0)),
            (DuskFixture.zeroClear.game(rule: .patientFeeding), nil, Cell(0,1))
        ]
        for (source, walk, tap) in examples {
            var game = source
            let turn: FallingSkyTurn
            if let walk { turn = try XCTUnwrap(game.clearConstellation(walk)) }
            else { turn = try XCTUnwrap(game.clear(XCTUnwrap(tap))) }
            let committed = game
            let expected = Set(turn.cleared.compactMap { source.gem(at: $0)?.id })
            scene.render(source)
            var completions = 0
            scene.animate(turn, from: source, to: game) { completions += 1 }
            let outgoing = departures(scene)
            XCTAssertEqual(Set(outgoing.map { $0.gem.id }), expected,
                           "Drained stars and neighboring Dusk still leave; only credited light has a reward gate")
            XCTAssertEqual(characters(scene).count, source.occupiedCount, "No duplicate helper sprites are inserted")
            XCTAssertEqual(completions, 0)
            if let walk {
                let receipt = try XCTUnwrap(StarlightCelebration(id: 1, turn: turn, from: source,
                                                               total: game.displayScore, path: walk))
                XCTAssertEqual(receipt.constellationPath, walk)
                if source.isDrained(at: Cell(3,2)) {
                    XCTAssertTrue(receipt.constellationPath.contains(Cell(3,2)))
                    XCTAssertFalse(receipt.contributors.contains { $0.cell == Cell(3,2) })
                }
            }
            var bodiesGoneBeforeHandoff = false
            let deadline = ContinuousClock.now + .seconds(2)
            while completions == 0 && ContinuousClock.now < deadline {
                if outgoing.allSatisfy({ $0.parent == nil }) { bodiesGoneBeforeHandoff = true }
                try await Task.sleep(for: .milliseconds(10))
            }
            XCTAssertTrue(bodiesGoneBeforeHandoff, "The 0.18-second decoration cannot own the 0.56-second clear handoff")
            XCTAssertEqual(completions, 1)
            assertRetired(outgoing)
            try assertSettled(scene, game: committed)
            XCTAssertEqual(game, committed)
            XCTAssertEqual(game.incoming, source.incoming); XCTAssertEqual(game.turns, source.turns)
        }
    }

    @MainActor func testAutomaticPhasesDepartTheirOwnBeforeIdentitiesInCommittedOrder() async throws {
        try requireNormalMotion()
        let (_, scene) = try host()
        let source = FallingSky.freshChallenge(.firstLight)
        var game = source
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        var order: [Int] = [], outgoing: [[FallingSkyCharacter]] = [], completions = 0
        scene.render(source)
        scene.animate(turn, from: source, to: game, phaseBegan: { index in
            XCTAssertEqual(completions, 0)
            if let previous = outgoing.last { self.assertRetired(previous) }
            let phase = turn.resolutionPhases[index]
            let expected = Set(phase.cleared.compactMap { phase.before[$0.row * 7 + $0.column]?.id })
            let bodies = self.departures(scene)
            XCTAssertEqual(Set(bodies.map { $0.gem.id }), expected)
            for body in bodies {
                XCTAssertEqual(phase.before.compactMap { $0 }.first { $0.id == body.gem.id }, body.gem)
            }
            order.append(index); outgoing.append(bodies)
        }, completion: { completions += 1 })
        let deadline = ContinuousClock.now + .seconds(4)
        while completions == 0 && ContinuousClock.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(order, [0,1]); XCTAssertEqual(completions, 1)
        XCTAssertEqual(outgoing.count, 2)
        outgoing.forEach { assertRetired($0) }
        try assertSettled(scene, game: game)
        XCTAssertTrue(game.isValidSave)
    }

    @MainActor func testInterruptedDeparturesRemoveActionsFromWithdrawnBodies() throws {
        try requireNormalMotion()
        let (view, scene) = try host()
        let source = ConstellationFixture.diagonalSix.game()
        var game = source
        let turn = try XCTUnwrap(game.clearConstellation((0..<5).map { Cell($0, $0) }))
        for boundary in ["replacement", "resize", "quiet", "suspension", "detach"] {
            view.presentScene(scene); scene.size = view.bounds.size
            scene.reduceMotion = false; scene.decorativeMotionActive = true; scene.render(source)
            scene.animate(turn, from: source, to: game) {}
            let outgoing = departures(scene)
            XCTAssertEqual(outgoing.count, 5, boundary)
            switch boundary {
            case "replacement": scene.render(game)
            case "resize": scene.size = CGSize(width: 430, height: 932)
            case "quiet": scene.reduceMotion = true
            case "suspension": scene.decorativeMotionActive = false
            default: view.presentScene(nil)
            }
            assertRetired(outgoing)
            XCTAssertTrue(departures(scene).isEmpty)
            // Store readiness owns whole-scene/clock settlement. This assertion
            // only concerns the outgoing bodies that left the committed dictionary.
            scene.render(game)
        }
    }

    @MainActor func testQuietAndDetachedClearsSettleImmediatelyAndZeroLightCreatesNoReceipt() throws {
        let (_, attached) = try host()
        let source = SkyTutorial.grown.game()
        var game = source
        let turn = try XCTUnwrap(game.clear(Cell(0,0)))
        for scene in [attached, FallingSkyScene(size: CGSize(width: 390, height: 844))] {
            scene.reduceMotion = scene === attached; scene.render(source)
            let cleared = characters(scene).filter { body in turn.cleared.contains { source.gem(at: $0)?.id == body.gem.id } }
            var completions = 0
            scene.animate(turn, from: source, to: game) { completions += 1 }
            XCTAssertEqual(completions, 1)
            XCTAssertTrue(departures(scene).isEmpty)
            assertRetired(cleared)
            try assertSettled(scene, game: game)
        }
        let suite = "Starfall.HelperDepartureZero.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(DuskFixture.zeroClear.game(rule: .patientFeeding)), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        let before = store.game
        store.clear(Cell(0,1))
        XCTAssertEqual(store.game.score, before.score)
        XCTAssertNil(store.celebration)
        presenter.finish()
        XCTAssertNil(store.celebration)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), store.game)
        store.setSuspended(true)
    }
}
