import XCTest
import SpriteKit
import UIKit
import StarfallCore
@testable import Starfall

final class NativeInputWindowTests: XCTestCase {
    private struct Window: Codable {
        let shower: Int
        let seed: UInt64
        let generation: Int
        let arrivals: Int
        let gravityPhases: Int
        let density: String
        let followingCadence: String
        let observedReady: Bool
        let presentationSeconds: Double?
        let readyToScheduledDeadlineSeconds: Double
        let readyToActualDueSeconds: Double
    }

    @MainActor func testRealSceneInputWindowsAcrossAutomaticStorm() async throws {
        var initial = FallingSky(seed: 17, generation: .current)
        for _ in 0..<8 {
            XCTAssertNotNil(initial.letStarsFall())
            for _ in 0..<49 {
                guard let cell = initial.legalGroups.first?.first else { break }
                XCTAssertNotNil(initial.clear(cell))
            }
        }
        XCTAssertFalse(initial.isOver)
        let windows = try await measure(initial: initial, through: 14, name: "native-input-windows-standard")
        XCTAssertEqual(windows.count, 5)
        XCTAssertEqual(windows.filter { $0.density == "heavy" }.count, 3)
    }

    @MainActor func testRealSceneInputWindowsWithNaturallyOccupiedOrbit() async throws {
        var selected: FallingSky?
        for seed in UInt64(0)..<80 where selected == nil {
            var game = FallingSky(seed: seed, generation: .current)
            for _ in 0..<8 where !game.isOver && selected == nil {
                XCTAssertNotNil(game.letStarsFall())
                for _ in 0..<49 where selected == nil {
                    guard let cell = game.legalGroups.compactMap(\.first).max(by: {
                        (game.gravityPreview(at: $0)?.orbit == nil ? 0 : 1) < (game.gravityPreview(at: $1)?.orbit == nil ? 0 : 1)
                    }) else { break }
                    XCTAssertNotNil(game.clear(cell))
                    if game.orbit != nil { selected = game }
                }
            }
        }
        let initial = try XCTUnwrap(selected, "Bounded deterministic setup must reach a natural first-event orbit")
        let windows = try await measure(initial: initial, through: initial.turns + 4, name: "native-input-windows-orbit")
        XCTAssertEqual(windows.count, 3)
        XCTAssertTrue(windows.contains { $0.gravityPhases > 0 })
    }

    @MainActor private func measure(initial: FallingSky, through finalShower: Int, name: String) async throws -> [Window] {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Normal-motion timing requires Reduce Motion and VoiceOver off")
        }
        var expected = initial
        var expectedGames: [Int: FallingSky] = [:]
        var expectedTurns: [Int: FallingSkyTurn] = [:]
        for shower in (initial.turns + 1)...finalShower {
            let turn = try XCTUnwrap(expected.letStarsFall())
            XCTAssertFalse(expected.isOver, "The fixed timing fixture must reach the complete first event")
            expectedGames[shower] = expected; expectedTurns[shower] = turn
        }
        let suite = "Starfall.NativeWindows.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "soundEnabled")
        defaults.set(false, forKey: "starfall.haptics")
        defaults.set(try SkySaveArchive.encode(initial), forKey: SkySaveArchive.key)
        let store = FallingSkyStore(defaults: defaults, arguments: [])
        XCTAssertEqual(store.game, initial)
        var events: [FallingSkyStore.TimingEvent] = []
        store.configureTimingTest(observe: { events.append($0) })

        let host = try SceneHost(scene: store.scene)
        defer { store.setSuspended(true); host.close() }
        let attachLimit = ContinuousClock.now + .seconds(3)
        while !store.sceneReady && ContinuousClock.now < attachLimit {
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertTrue(store.sceneReady)
        XCTAssertTrue(store.scene.view === host.view)
        XCTAssertFalse(store.scene.reduceMotion)
        store.setSuspended(false); store.togglePause()
        let limit = ContinuousClock.now + .seconds(30)
        while store.game.turns < finalShower && !store.game.isOver && ContinuousClock.now < limit {
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertEqual(store.game.turns, finalShower)
        XCTAssertFalse(store.game.isOver)
        // The final arrival closes the preceding window; its own presentation is censored.
        store.togglePause()

        let arrivals = events.filter { $0.kind == .automaticShower }
        XCTAssertEqual(arrivals.count, finalShower - initial.turns)
        for event in arrivals { XCTAssertEqual(event.snapshot.game, expectedGames[event.snapshot.game.turns]) }
        XCTAssertLessThan(events.count, 200)
        var windows: [Window] = []
        for shower in (initial.turns + 1)..<finalShower {
            let began = try XCTUnwrap(arrivals.first { $0.snapshot.game.turns == shower })
            let following = try XCTUnwrap(arrivals.first { $0.snapshot.game.turns == shower + 1 })
            let ready = events.first {
                $0.kind == .state && $0.snapshot.game.turns == shower && $0.snapshot.canClear
                    && !$0.snapshot.busy && !$0.snapshot.paused && !$0.snapshot.suspended
            }
            let due = try XCTUnwrap(events.first { $0.kind == .due && $0.snapshot.game.turns == shower })
            let scheduled = try XCTUnwrap(began.snapshot.scheduledDeadline)
            let turn = try XCTUnwrap(expectedTurns[shower])
            if let ready {
                XCTAssertGreaterThanOrEqual(ready.snapshot.time, began.snapshot.time)
                XCTAssertLessThanOrEqual(ready.snapshot.time, following.snapshot.time)
            }
            windows.append(.init(shower: shower, seed: initial.seed, generation: initial.generation.rawValue, arrivals: turn.arrivals.count, gravityPhases: turn.gravityPhases.count,
                density: initial.generation.phase(for: shower)?.isStorm == true ? "heavy" : "lighter",
                followingCadence: String(describing: began.snapshot.cadence.phase), observedReady: ready != nil,
                presentationSeconds: ready.map { $0.snapshot.time - began.snapshot.time },
                readyToScheduledDeadlineSeconds: ready.map { max(0, scheduled - $0.snapshot.time) } ?? 0,
                readyToActualDueSeconds: ready.map { max(0, due.snapshot.time - $0.snapshot.time) } ?? 0))
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let capture = XCTAttachment(data: try encoder.encode(windows), uniformTypeIdentifier: "public.json")
        capture.name = name; capture.lifetime = .keepAlways; add(capture)
        let trace = events.map { event in
            TraceEvent(kind: String(describing: event.kind), time: event.snapshot.time, game: event.snapshot.game,
                deadline: event.snapshot.scheduledDeadline, sourceDeadline: event.showerDeadline,
                busy: event.snapshot.busy, ready: event.snapshot.canClear, paused: event.snapshot.paused,
                suspended: event.snapshot.suspended, inputGeneration: event.snapshot.inputGeneration)
        }
        let eventCapture = XCTAttachment(data: try encoder.encode(trace), uniformTypeIdentifier: "public.json")
        eventCapture.name = name + ".events"; eventCapture.lifetime = .keepAlways; add(eventCapture)
        let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
        var cleared = store.game
        XCTAssertNotNil(cleared.clear(cell))
        store.clear(cell)
        XCTAssertEqual(store.game, cleared)
        let clearLimit = ContinuousClock.now + .seconds(3)
        while store.busy && ContinuousClock.now < clearLimit { try await Task.sleep(for: .milliseconds(16)) }
        XCTAssertFalse(store.busy); XCTAssertTrue(store.canClear); XCTAssertTrue(store.isPaused)
        XCTAssertEqual(store.game, cleared)
        return windows
    }
}


private struct TraceEvent: Codable {
    let kind: String
    let time: Double
    let game: FallingSky
    let deadline: Double?
    let sourceDeadline: Double?
    let busy: Bool
    let ready: Bool
    let paused: Bool
    let suspended: Bool
    let inputGeneration: UInt64
}

@MainActor private final class SceneHost {
    let view = SKView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    private let window: UIWindow
    private let previous: UIWindow?
    init(scene: FallingSkyScene) throws {
        let session = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        previous = session.windows.first(where: \.isKeyWindow)
        window = UIWindow(windowScene: session); window.frame = view.frame
        let controller = UIViewController(); controller.view = view
        window.rootViewController = controller; window.makeKeyAndVisible()
        view.presentScene(scene)
    }
    func close() {
        view.presentScene(nil); window.isHidden = true; previous?.makeKey()
    }
}
