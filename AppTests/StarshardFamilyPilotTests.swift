import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

/// Real packaged artwork and SpriteKit presentation; requires hosted Apple tests.
final class StarshardFamilyPilotTests: XCTestCase {
    @MainActor func testOptInRendersAllFiveRealTexturesWithAuthoredPivots() throws {
        let game = Game(seed: 42)
        XCTAssertEqual(Set(game.board), Set(Jewel.allCases))
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        scene.crystalPilotEnabled = false
        scene.starshardFamilyPilotEnabled = false
        scene.render(game)
        XCTAssertFalse(scene.starshardFamilyPilotIsActive)
        let defaultTexture = try XCTUnwrap(scene.renderedTexture(at: Cell(0, 0)))
        scene.starshardFamilyPilotEnabled = true
        scene.render(game)
        XCTAssertTrue(scene.starshardFamilyPilotIsActive)
        XCTAssertEqual(scene.renderedJewelCount, 49)
        let step: CGFloat = 350 / 7.7
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let kind = try XCTUnwrap(game.jewel(at: cell))
            let frames = try XCTUnwrap(StarshardArtwork.shared.frames(for: kind))
            XCTAssertTrue(scene.renderedTexture(at: cell) === frames.neutralFrame)
            let side = frames.canvasSide(radius: step * 0.37)
            // SpriteKit transforms round to Float32; retain a 0.0001-point bound.
            let size = try XCTUnwrap(scene.renderedSize(at: cell))
            XCTAssertEqual(size.width, side, accuracy: 0.0001)
            XCTAssertEqual(size.height, side, accuracy: 0.0001)
            XCTAssertEqual(scene.renderedAnchorPoint(at: cell), CGPoint(x: 0.5, y: 0.5))
            let position = try XCTUnwrap(scene.renderedPosition(at: cell))
            XCTAssertEqual(position.x, 175 + CGFloat(column - 3) * step, accuracy: 0.0001)
            XCTAssertEqual(position.y, 175 + CGFloat(row - 3) * step, accuracy: 0.0001)
        } }
        scene.starshardFamilyPilotEnabled = false
        scene.render(game)
        XCTAssertFalse(scene.starshardFamilyPilotIsActive)
        XCTAssertTrue(scene.renderedTexture(at: Cell(0, 0)) === defaultTexture)
    }

    func testUITapFixturesAreLegalGroupsOfAllFiveKinds() {
        let game = Game(seed: 0)
        let fixtures: [(Jewel, Cell, Int)] = [
            (.rose, Cell(0, 0), 3), (.aqua, Cell(5, 3), 3), (.amber, Cell(3, 6), 3),
            (.violet, Cell(3, 1), 4), (.mint, Cell(3, 4), 3)
        ]
        for (kind, cell, count) in fixtures {
            XCTAssertEqual(game.jewel(at: cell), kind)
            XCTAssertEqual(game.group(at: cell).count, count)
        }
        XCTAssertEqual(Game.target, 70)
        XCTAssertEqual(Game.startingMoves, 18)
    }

    @MainActor func testEveryKindUsesOwnBoundedFragmentsAndCancellationCleansActions() throws {
        if UIAccessibility.isVoiceOverRunning { throw XCTSkip("VoiceOver correctly bypasses animated bursts") }
        for kind in Jewel.allCases {
            let (old, new, turn) = try turnFixture(kind: kind)
            let scene = makeScene()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
            view.presentScene(scene); scene.isPaused = true; scene.render(old)
            var completions = 0
            scene.animate(turn: turn, old: old, new: new) { completions += 1 }
            XCTAssertEqual(scene.transientNodeCount, 48)
            XCTAssertTrue(scene.hasActions())
            let frames = try XCTUnwrap(StarshardArtwork.shared.frames(for: kind))
            let fragmentIDs = Set(frames.fragments.map(ObjectIdentifier.init))
            var fragments = 0
            for node in allNodes(in: scene) {
                guard let sprite = node as? SKSpriteNode, let texture = sprite.texture,
                      fragmentIDs.contains(ObjectIdentifier(texture)) else { continue }
                fragments += 1
            }
            XCTAssertEqual(fragments, 48, "Burst must use this kind's cached fragments")
            scene.cancelAnimations(); scene.render(new)
            assertSettled(scene, game: new)
            XCTAssertEqual(completions, 0)
            withExtendedLifetime(view) {}
        }
    }

    @MainActor func testReducedMotionAndUnattachedPresentationCompleteImmediatelyForEveryKind() throws {
        for kind in Jewel.allCases {
            let (old, new, turn) = try turnFixture(kind: kind)
            for reducedMotion in [false, true] {
                let scene = makeScene()
                var retainedView: SKView?
                if reducedMotion {
                    retainedView = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
                    retainedView?.presentScene(scene)
                    scene.reduceMotion = true
                }
                scene.render(old)
                var completions = 0
                scene.animate(turn: turn, old: old, new: new) { completions += 1 }
                XCTAssertEqual(completions, 1)
                assertSettled(scene, game: new)
                withExtendedLifetime(retainedView) {}
            }
        }
    }

    @MainActor func testStoreCancellationResetAndCalmKeepCommittedRules() throws {
        for kind in Jewel.allCases {
            let (old, _, _) = try turnFixture(kind: kind)
            let suite = "StarshardFamilyPilotTests.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try JSONEncoder().encode(old), forKey: "starfall.game.v1")
            let store = GameStore(defaults: defaults, arguments: [])
            store.soundEnabled = false
            let scene = store.scene
            scene.size = CGSize(width: 350, height: 350)
            scene.starshardFamilyPilotEnabled = true
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
            view.presentScene(scene); scene.isPaused = true; store.start()
            store.tap(Cell(0, 0))
            let committed = store.game
            XCTAssertEqual(committed.moves, 17)
            XCTAssertEqual(committed.score, 49)
            if store.busy {
                store.tap(Cell(0, 0))
                XCTAssertEqual(store.game, committed)
            } else {
                XCTAssertTrue(UIAccessibility.isVoiceOverRunning)
            }
            store.settlePresentation()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, committed)
            assertSettled(scene, game: committed)
            store.restart()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game.moves, 18)
            XCTAssertEqual(store.game.score, 0)
            assertSettled(scene, game: store.game)
            // The SwiftUI shell supplies this same Calm/system Reduce Motion bridge.
            store.calmEffects = true
            store.updateReducedMotion(store.calmEffects)
            XCTAssertTrue(defaults.bool(forKey: "calmEffects"))
            let legal = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
                .first { store.game.group(at: $0).count >= 3 })
            let previous = store.game
            store.tap(legal)
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game.moves, previous.moves - 1)
            assertSettled(scene, game: store.game)
            withExtendedLifetime(view) {}
        }
    }

    @MainActor func testAnimatedCompletionFiresOnceForEveryKind() async throws {
        if UIAccessibility.isVoiceOverRunning { throw XCTSkip("VoiceOver correctly settles immediately") }
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes.first { $0 is UIWindowScene } as? UIWindowScene)
        for kind in Jewel.allCases {
            let (old, new, turn) = try turnFixture(kind: kind)
            let scene = makeScene()
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
            let window = UIWindow(windowScene: windowScene)
            window.frame = windowScene.coordinateSpace.bounds
            let controller = UIViewController()
            controller.view.addSubview(view); window.rootViewController = controller
            window.isHidden = false
            defer { view.presentScene(nil); window.isHidden = true }
            view.presentScene(scene); scene.render(old)
            let done = expectation(description: "\(kind) animated turn completed")
            done.assertForOverFulfill = true
            var completions = 0
            scene.animate(turn: turn, old: old, new: new) { completions += 1; done.fulfill() }
            XCTAssertGreaterThan(scene.transientNodeCount, 0)
            await fulfillment(of: [done], timeout: 5)
            XCTAssertEqual(completions, 1)
            assertSettled(scene, game: new)
            scene.cancelAnimations()
            XCTAssertEqual(completions, 1)
            withExtendedLifetime(window) {}
        }
    }

    @MainActor func testRapidInvalidNudgesAreReplaceableAndCalmCancelsThem() throws {
        let suite = "StarshardFamilyNudgeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults, arguments: ["--reset-save", "--seed=0"])
        let scene = store.scene
        scene.size = CGSize(width: 350, height: 350)
        scene.starshardFamilyPilotEnabled = true
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene); scene.isPaused = true; store.start()
        let old = store.game
        let invalid = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
            .first { old.group(at: $0).count < 3 })
        for _ in 0..<10 { store.tap(invalid) }
        XCTAssertEqual(store.game, old)
        XCTAssertFalse(store.busy)
        var animatedNodes = 0
        for node in allNodes(in: scene) {
            if node.action(forKey: "touch-feedback") != nil { animatedNodes += 1 }
        }
        XCTAssertEqual(animatedNodes, 1)
        store.updateReducedMotion(true)
        store.tap(invalid)
        XCTAssertEqual(store.game, old)
        assertSettled(scene, game: old)
        withExtendedLifetime(view) {}
    }

    @MainActor func testValidTurnRestoresAnInterruptedInvalidNudge() async throws {
        if UIAccessibility.isVoiceOverRunning || UIAccessibility.isReduceMotionEnabled {
            throw XCTSkip("Accessibility motion settings correctly bypass animated nudges")
        }
        let windowScene = try XCTUnwrap(UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }.first)
        for familyPilot in [false, true] {
            let suite = "StarfallInterruptedNudge.\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = GameStore(defaults: defaults, arguments: ["--reset-save", "--seed=0"])
            let scene = store.scene
            scene.size = CGSize(width: 350, height: 350)
            scene.starshardFamilyPilotEnabled = familyPilot
            scene.crystalPilotEnabled = false
            let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
            let window = UIWindow(windowScene: windowScene)
            window.frame = windowScene.coordinateSpace.bounds
            let controller = UIViewController()
            controller.view.addSubview(view)
            window.rootViewController = controller
            window.isHidden = false
            defer { view.presentScene(nil); window.isHidden = true }
            view.presentScene(scene)
            store.start()
            XCTAssertEqual(scene.starshardFamilyPilotIsActive, familyPilot)
            let old = store.game
            let group = try XCTUnwrap(old.legalGroups.first)
            let invalid = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
                .first { candidate in old.group(at: candidate).count < 3
                    && !group.contains(where: { $0.column == candidate.column }) })
            let position = try XCTUnwrap(scene.renderedPosition(at: invalid))
            let sprite = try XCTUnwrap(allNodes(in: scene).compactMap { $0 as? SKSpriteNode }
                .first { $0.position == position })
            let neutralTexture = try XCTUnwrap(sprite.texture)
            let sampledNudge = expectation(description: "Sample actual nudge; family=\(familyPilot)")
            var sampled = false
            store.tap(invalid)
            XCTAssertEqual(store.game, old)
            // Pause on an observed intermediate pose instead of assuming a frame
            // arrived after a fixed sleep. The next turn cannot tick while paused.
            scene.run(.customAction(withDuration: 2) { _, _ in
                guard !sampled,
                      sprite.xScale < 0.999 || sprite.texture !== neutralTexture else { return }
                sampled = true
                scene.isPaused = true
                sampledNudge.fulfill()
            }, withKey: "nudge-observer")
            await fulfillment(of: [sampledNudge], timeout: 5)
            XCTAssertTrue(sampled)
            store.tap(try XCTUnwrap(group.first))
            XCTAssertEqual(store.game.moves, old.moves - 1)
            XCTAssertTrue(store.busy)
            XCTAssertNil(sprite.action(forKey: "touch-feedback"))
            XCTAssertEqual(sprite.xScale, 1, accuracy: 0.0001)
            XCTAssertEqual(sprite.yScale, 1, accuracy: 0.0001)
            XCTAssertTrue(sprite.texture === neutralTexture)
            store.settlePresentation()
            XCTAssertFalse(store.busy)
            withExtendedLifetime(window) {}
        }
    }

    @MainActor func testFullCellHitTargetsRejectPaddingAndNonfiniteLocations() throws {
        let scene = JewelScene(size: CGSize(width: 350, height: 420))
        scene.render(Game(seed: 42))
        let step: CGFloat = 350 / 7.7
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let center = try XCTUnwrap(scene.renderedPosition(at: cell))
            XCTAssertEqual(scene.cell(at: center), cell)
            // Near the cell corners still counts, independent of the jewel silhouette.
            for x in [-0.49, 0.49] { for y in [-0.49, 0.49] {
                XCTAssertEqual(scene.cell(at: CGPoint(x: center.x + x * step, y: center.y + y * step)), cell)
            } }
        } }
        for point in [CGPoint.zero, CGPoint(x: 175, y: 1), CGPoint(x: 349, y: 210),
                      CGPoint(x: CGFloat.nan, y: 210), CGPoint(x: 175, y: CGFloat.infinity)] {
            XCTAssertNil(scene.cell(at: point))
        }
        scene.size = .zero
        XCTAssertNil(scene.cell(at: .zero))
    }

    @MainActor func testGroupPreviewIsStaticExactAndClearedByRendering() throws {
        let suite = "StarshardPreviewTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults, arguments: ["--reset-save", "--seed=0"])
        store.start()
        let scene = store.scene
        scene.size = CGSize(width: 350, height: 350)
        scene.reduceMotion = true
        let old = store.game
        let group = old.group(at: Cell(0, 0))
        scene.showTouchPreview(at: Cell(0, 0))
        XCTAssertEqual(scene.previewedCells, group)
        XCTAssertEqual(store.game, old)
        XCTAssertFalse(store.busy)
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            XCTAssertEqual(try XCTUnwrap(scene.renderedAlpha(at: cell)), group.contains(cell) ? 1 : 0.48,
                           accuracy: 0.0001)
        } }
        XCTAssertFalse(scene.hasActions())
        scene.render(old)
        XCTAssertTrue(scene.previewedCells.isEmpty)
        for row in 0..<7 { for column in 0..<7 {
            XCTAssertEqual(scene.renderedAlpha(at: Cell(row, column)), 1)
        } }
    }

    @MainActor func testDefaultClearSparkCountIsBoundedAndRepeatedNudgesReplaceActions() throws {
        if UIAccessibility.isVoiceOverRunning || UIAccessibility.isReduceMotionEnabled {
            throw XCTSkip("System accessibility correctly bypasses motion")
        }
        let (old, new, turn) = try turnFixture(kind: .rose)
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        scene.crystalPilotEnabled = false
        scene.starshardFamilyPilotEnabled = false
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene); scene.isPaused = true; scene.render(old)
        for _ in 0..<20 { scene.nudge(Cell(0, 0)) }
        XCTAssertEqual(allNodes(in: scene).filter { $0.action(forKey: "touch-feedback") != nil }.count, 1)
        scene.animate(turn: turn, old: old, new: new) {}
        XCTAssertGreaterThan(scene.transientNodeCount, 0)
        XCTAssertLessThanOrEqual(scene.transientNodeCount, JewelScene.maximumClearSparks)
        scene.cancelAnimations(); scene.render(new)
        XCTAssertEqual(scene.transientNodeCount, 0)
        XCTAssertTrue(allNodes(in: scene).allSatisfy { !$0.hasActions() })
        withExtendedLifetime(view) {}
    }

    @MainActor func testResizeAndDetachmentSettleCommittedStoreAndUnlockInput() throws {
        let suite = "StarshardResizeTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults, arguments: ["--reset-save", "--seed=0"])
        let scene = store.scene
        scene.starshardFamilyPilotEnabled = true
        scene.size = CGSize(width: 350, height: 350)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene); scene.isPaused = true; store.start()
        store.tap(Cell(0, 0))
        let committed = store.game
        XCTAssertEqual(committed.moves, 17)
        scene.size = CGSize(width: 390, height: 390)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, committed)
        assertSettled(scene, game: committed)
        let legal = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
            .first { store.game.group(at: $0).count >= 3 })
        store.tap(legal)
        let beforeDetach = store.game
        view.presentScene(nil)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, beforeDetach)
        assertSettled(scene, game: beforeDetach)
        withExtendedLifetime(view) {}
    }

    @MainActor func testCalmSettingAloneSuppressesValidAndInvalidAnimations() throws {
        let suite = "StarshardDirectCalmTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = GameStore(defaults: defaults, arguments: ["--reset-save", "--seed=0"])
        let scene = store.scene
        scene.starshardFamilyPilotEnabled = true
        scene.size = CGSize(width: 350, height: 350)
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene); scene.isPaused = true; store.start()
        store.calmEffects = true // Do not rely on SwiftUI forwarding the setting first.
        store.tap(Cell(0, 0))
        XCTAssertEqual(store.game.moves, 17)
        XCTAssertFalse(store.busy)
        let invalid = try XCTUnwrap((0..<49).map { Cell($0 / 7, $0 % 7) }
            .first { store.game.group(at: $0).count < 3 })
        let committed = store.game
        for _ in 0..<10 { store.tap(invalid) }
        XCTAssertEqual(store.game, committed)
        assertSettled(scene, game: committed)
        withExtendedLifetime(view) {}
    }

    @MainActor func testArrivalPreservesSurvivorRecoveryAndRefillIdentityAndCancelsAllTrails() throws {
        if UIAccessibility.isVoiceOverRunning || UIAccessibility.isReduceMotionEnabled {
            throw XCTSkip("System accessibility correctly bypasses motion")
        }
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(Game(seed: 1))) as? [String: Any])
        var board = (0..<49).map { ($0 / 7 + $0 % 7) % 5 }
        for row in 0..<3 { board[row * 7] = Jewel.rose.rawValue }
        fields["board"] = board
        // Match the core recovery fixture's generator before its first refill.
        // Game(seed:) already consumed random values to generate its original board.
        fields["random"] = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SeededRandom(seed: 1)))
        var game = try JSONDecoder().decode(Game.self, from: JSONSerialization.data(withJSONObject: fields))
        let turn = try XCTUnwrap(game.tap(Cell(0, 0)))
        XCTAssertEqual(turn.cleared.count, 3)
        XCTAssertTrue(turn.reshuffled)
        let mapping = RefillMapping(turn: turn, settled: game)
        XCTAssertEqual(mapping.pieces.filter { $0.origin == .recovery }.map(\.destination),
                       [Cell(0, 0), Cell(0, 1), Cell(0, 2)])
        let scene = SKScene(size: CGSize(width: 350, height: 350))
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 350, height: 350))
        view.presentScene(scene); scene.isPaused = true
        let effects = SKNode(); scene.addChild(effects)
        var nodes: [Cell: SKNode] = [:]
        for piece in mapping.pieces { let node = SKNode(); scene.addChild(node); nodes[piece.destination] = node }
        func point(_ cell: Cell) -> CGPoint { CGPoint(x: 25 + cell.column * 50, y: 25 + cell.row * 50) }
        let arrivals = StarfallArrivalEffects()
        var completions = 0
        arrivals.play(mapping: mapping, nodes: nodes, boardBounds: CGRect(origin: .zero, size: scene.size),
                      step: 50, in: effects, calmEffects: false, reduceMotion: false, point: point) { completions += 1 }
        for piece in mapping.pieces {
            let node = try XCTUnwrap(nodes[piece.destination])
            let destination = point(piece.destination)
            switch piece.origin {
            case let .survivor(source):
                XCTAssertEqual(node.position.x, destination.x)
                XCTAssertEqual(node.position.y, point(source).y)
                XCTAssertEqual(node.alpha, 1)
                if source == piece.destination { XCTAssertFalse(node.hasActions()) }
            case .recovery:
                XCTAssertEqual(node.position, destination)
                XCTAssertEqual(node.alpha, 0)
            case .refill:
                XCTAssertGreaterThan(node.position.x, destination.x)
                XCTAssertGreaterThan(node.position.y, destination.y)
                XCTAssertEqual(node.alpha, 0)
            }
        }
        XCTAssertEqual(effects.children.count, 1) // The bounded phase clock.
        XCTAssertLessThanOrEqual(nodes.values.reduce(0) { $0 + $1.children.count }, StarfallArrivalEffects.maximumTrails)
        arrivals.cancel(); arrivals.cancel()
        XCTAssertEqual(completions, 0)
        XCTAssertTrue(effects.children.isEmpty)
        for (cell, node) in nodes {
            XCTAssertEqual(node.position, point(cell))
            XCTAssertEqual(node.alpha, 1)
            XCTAssertFalse(node.hasActions())
            XCTAssertTrue(node.children.isEmpty)
        }
        let (_, fullGame, fullTurn) = try turnFixture(kind: .mint)
        arrivals.play(mapping: RefillMapping(turn: fullTurn, settled: fullGame), nodes: nodes,
                      boardBounds: CGRect(origin: .zero, size: scene.size), step: 50,
                      in: effects, calmEffects: false, reduceMotion: false, point: point) { completions += 1 }
        XCTAssertEqual(nodes.values.reduce(0) { $0 + $1.children.count }, StarfallArrivalEffects.maximumTrails)
        XCTAssertEqual(effects.children.count, 1)
        arrivals.cancel()
        XCTAssertTrue(effects.children.isEmpty)
        XCTAssertEqual(completions, 0)
        XCTAssertTrue(nodes.values.allSatisfy { !$0.hasActions() && $0.children.isEmpty && $0.alpha == 1 })
        withExtendedLifetime(view) {}
    }

    @MainActor func testUnattachedArrivalCompletesSynchronouslyOnceWithNoEffects() throws {
        let (_, game, turn) = try turnFixture(kind: .mint)
        let mapping = RefillMapping(turn: turn, settled: game)
        let effects = SKNode()
        let nodes = Dictionary(uniqueKeysWithValues: mapping.pieces.map { ($0.destination, SKNode()) })
        let arrivals = StarfallArrivalEffects()
        var completions = 0
        arrivals.play(mapping: mapping, nodes: nodes, boardBounds: CGRect(x: 0, y: 0, width: 350, height: 350),
                      step: 50, in: effects, calmEffects: false, reduceMotion: false,
                      point: { CGPoint(x: 25 + $0.column * 50, y: 25 + $0.row * 50) }) { completions += 1 }
        XCTAssertEqual(completions, 1)
        arrivals.cancel()
        XCTAssertEqual(completions, 1)
        XCTAssertTrue(effects.children.isEmpty)
        XCTAssertTrue(nodes.values.allSatisfy { !$0.hasActions() && $0.children.isEmpty && $0.alpha == 1 })
    }

    @MainActor private func makeScene() -> JewelScene {
        let scene = JewelScene(size: CGSize(width: 350, height: 350))
        scene.crystalPilotEnabled = false
        scene.starshardFamilyPilotEnabled = true
        return scene
    }

    private func turnFixture(kind: Jewel) throws -> (Game, Game, Turn) {
        let data = try JSONEncoder().encode(Game(seed: 42))
        var fields = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        fields["board"] = Array(repeating: kind.rawValue, count: 49)
        let old = try JSONDecoder().decode(Game.self, from: JSONSerialization.data(withJSONObject: fields))
        var new = old
        let turn = try XCTUnwrap(new.tap(Cell(0, 0)))
        XCTAssertEqual(turn.cleared.count, 49)
        return (old, new, turn)
    }

    @MainActor private func assertSettled(_ scene: JewelScene, game: Game,
                                        file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(scene.renderedJewelCount, 49, file: file, line: line)
        XCTAssertEqual(scene.transientNodeCount, 0, file: file, line: line)
        XCTAssertFalse(scene.hasActions(), file: file, line: line)
        for node in allNodes(in: scene) {
            XCTAssertFalse(node.hasActions(), file: file, line: line)
        }
        for row in 0..<7 { for column in 0..<7 {
            let cell = Cell(row, column)
            let frames = StarshardArtwork.shared.frames(for: game.jewel(at: cell)!)
            XCTAssertTrue(scene.renderedTexture(at: cell) === frames?.neutralFrame, file: file, line: line)
        } }
    }

    @MainActor private func allNodes(in root: SKNode) -> [SKNode] {
        root.children.flatMap { [$0] + allNodes(in: $0) }
    }
}
