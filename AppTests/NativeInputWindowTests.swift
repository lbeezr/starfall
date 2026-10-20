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
        let criticalMassRuleVersion: Int?
        let cadenceID: String
        let collapseSources: Int
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

    @MainActor func testRealSceneCriticalMassInputWindowsAcrossAutomaticStorm() async throws {
        var initial = FallingSky(seed: 0, generation: .current, criticalMass: true)
        for _ in 0..<8 { XCTAssertNotNil(initial.letStarsFall()) }
        XCTAssertTrue(initial.isValidSave && !initial.isOver)
        let windows = try await measure(initial: initial, through: 14, name: "native-input-windows-critical-mass")
        XCTAssertEqual(windows.count, 5)
        XCTAssertTrue(windows.allSatisfy { $0.criticalMassRuleVersion == CriticalMassRule.version })
        XCTAssertTrue(windows.allSatisfy { $0.collapseSources == 0 && $0.gravityPhases == 0 })
        XCTAssertEqual(windows.filter { $0.density == "heavy" }.count, 3)
    }

    @MainActor func testRealSceneFreshSurvivalInputWindowsAcrossAutomaticStorm() async throws {
        var initial = FallingSky.freshSurvival(seed: 0)
        for _ in 0..<8 { XCTAssertNotNil(initial.letStarsFall()) }
        XCTAssertTrue(initial.isValidSave && !initial.isOver)
        let windows = try await measure(initial: initial, through: 14, name: "native-input-windows-fresh-survival")
        XCTAssertEqual(windows.count, 5)
        XCTAssertTrue(windows.allSatisfy { $0.cadenceID == SkyCadenceID.announcedCycleV1.rawValue })
        XCTAssertTrue(windows.allSatisfy { $0.collapseSources == 0 })
        // The normal fresh game must offer an actual input window after every sampled shower.
        XCTAssertTrue(windows.allSatisfy {
            $0.observedReady && $0.readyToScheduledDeadlineSeconds >= 0.5
        })
    }

    @MainActor func testRealSceneInputWindowsAfterRetiringHistoricalOrbit() async throws {
        let initial = try naturalOrbit()
        let windows = try await measure(initial: initial, through: initial.turns + 4, name: "native-input-windows-retired-orbit")
        XCTAssertEqual(windows.count, 3)
        XCTAssertTrue(windows.allSatisfy { $0.gravityPhases == 0 }, "A normal restore must retire the old orbit before any shower")
    }

    @MainActor private func naturalOrbit() throws -> FallingSky {
        var selected: FallingSky?
        // Keep this renderer-timeline reproduction on its original deterministic history.
        // New supply histories have separate native coverage in GravityOpportunityNativeTests.
        for seed in UInt64(0)..<80 where selected == nil {
            var game = FallingSky(seed: seed, generation: .gravityOrbits)
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
        return try XCTUnwrap(selected, "Bounded deterministic setup must reach a natural first-event orbit")
    }

    @MainActor func testGravityTimelineKeepsLandingAfterPhasesWithinFastShowerBudget() {
        let budget = SkyCadenceID.announcedCycleV2.step(committedShowers: 10, pace: .brisk).delay
        let cases: [[GravityPhase.Event]] = [[.rotation], [.release, .settling]]
        for events in cases {
            let timeline = StarfallMotion.GravityTimeline(phases: events, arrivals: 5)
            XCTAssertGreaterThan(timeline.flightStart + StarfallMotion.flightDuration, timeline.phaseEnd)
            XCTAssertGreaterThan(timeline.flightStart + StarfallMotion.receiverResponseDelay, timeline.phaseEnd, "Receiver response must wait for gravity motion too")
            XCTAssertLessThan(timeline.flightStart, timeline.phaseEnd, "Airborne approach must overlap prior motion")
            XCTAssertLessThan(timeline.completion, budget - 0.25, "Reserve a bounded input opportunity without changing cadence")
        }
        let collision = StarfallMotion.GravityTimeline(phases: [.removal, .collision, .capture], arrivals: 0)
        XCTAssertEqual(collision.completion, collision.phaseEnd, "A clear without arrivals retains its complete phase sequence")
    }

    @MainActor func testIncomingFlightOverlapsRotationButLandsAfterIt() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Normal-motion overlap requires system quiet modes off")
        }
        var game = try naturalOrbit()
        XCTAssertNotNil(game.letStarsFall())
        let old = game, turn = try XCTUnwrap(game.letStarsFall())
        XCTAssertTrue(turn.gravityPhases.contains { $0.event == .rotation })
        let first = try XCTUnwrap(turn.arrivals.first { !$0.grew })
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        let timeline = StarfallMotion.GravityTimeline(phases: turn.gravityPhases.map(\.event), arrivals: turn.arrivals.count)
        let start = ProcessInfo.processInfo.systemUptime
        var complete = false, sawOverlap = false, sawReceiverResponse = false
        let rotatingIDs = Set((old.orbit?.slots ?? []).compactMap { old.gem(at: $0)?.id })
        var firstLanding: Double?
        var captured = Set<Int>()
        scene.animate(turn, from: old, to: game) { complete = true }
        let limit = ContinuousClock.now + .seconds(4)
        while !complete && ContinuousClock.now < limit {
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            let airborne = scene.childNode(withName: "//sky.flight.\(first.star.id)") != nil
            let grounded = scene.childNode(withName: "//sky.star.\(first.gem.id)") != nil
            sawOverlap = sawOverlap || (airborne && elapsed < timeline.phaseEnd)
            if grounded && firstLanding == nil { firstLanding = elapsed }
            if scene.children[1].children.contains(where: { ($0 as? FallingSkyCharacter)?.character.action(forKey: "sky.character-response") != nil }) {
                sawReceiverResponse = true
                for id in rotatingIDs {
                    let captive = try XCTUnwrap(scene.childNode(withName: "//sky.star.\(id)"))
                    XCTAssertFalse(captive.hasActions(), "Gravity movement must end before receiver responses begin")
                }
            }
            for arrival in turn.arrivals where !arrival.grew {
                XCTAssertFalse(scene.childNode(withName: "//sky.flight.\(arrival.star.id)") != nil
                    && scene.childNode(withName: "//sky.star.\(arrival.gem.id)") != nil)
            }
            for (index, time) in [0.15, 0.48, 0.70, 1.10].enumerated() where elapsed >= time && !captured.contains(index) {
                captured.insert(index)
                if let texture = host.view.texture(from: scene) {
                    let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
                    let image = UIGraphicsImageRenderer(size: host.view.bounds.size, format: format).image { context in
                        UIColor(red: 0.04, green: 0.055, blue: 0.12, alpha: 1).setFill(); context.fill(host.view.bounds)
                        UIImage(cgImage: texture.cgImage()).draw(in: host.view.bounds)
                    }
                    let frame = XCTAttachment(image: image); frame.name = "gravity-overlap-\(index)-\(elapsed)"
                    frame.lifetime = .keepAlways; add(frame)
                }
            }
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertTrue(complete); XCTAssertTrue(sawOverlap); XCTAssertTrue(sawReceiverResponse)
        XCTAssertGreaterThanOrEqual(try XCTUnwrap(firstLanding), timeline.phaseEnd)
        XCTAssertFalse(scene.hasActions())
        for gem in game.board.compactMap({ $0 }) { XCTAssertNotNil(scene.childNode(withName: "//sky.star.\(gem.id)")) }
        XCTAssertTrue(scene.children[2].children.isEmpty)
    }

    @MainActor func testQuietPresentationReleasesInputAsSoonAsFinalBoardIsRendered() throws {
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        scene.reduceMotion = true
        var cases: [(FallingSky, FallingSkyTurn, FallingSky)] = []
        let trace = SkyTechniqueExample.trace.game()
        var clear = trace
        cases.append((trace, try XCTUnwrap(clear.clear(Cell(0,0))), clear))
        var swap = trace
        cases.append((trace, try XCTUnwrap(swap.nudge(from:Cell(0,0),to:Cell(0,1))), swap))
        let fresh = FallingSky.freshSurvival(seed:0)
        var shower = fresh
        cases.append((fresh, try XCTUnwrap(shower.letStarsFall()), shower))
        var orbit = try naturalOrbit()
        XCTAssertNotNil(orbit.letStarsFall())
        let orbitBefore = orbit, phase = try XCTUnwrap(orbit.letStarsFall())
        XCTAssertFalse(phase.presentationPhases.isEmpty)
        cases.append((orbitBefore, phase, orbit))
        for (old, turn, game) in cases {
            scene.render(old)
            var completions = 0
            scene.animate(turn, from:old, to:game) { completions += 1 }
            XCTAssertEqual(completions,1,"A rendered quiet board must not retain a delayed completion")
            XCTAssertFalse(scene.hasActions(),"No completion may outlive the already finished presentation")
            let visible = scene.children[1].children.compactMap { ($0 as? FallingSkyCharacter)?.gem }.sorted { $0.id < $1.id }
            XCTAssertEqual(visible,game.board.compactMap { $0 }.sorted { $0.id < $1.id })
        }
    }

    @MainActor func testOverlapReplacementCancelsOldCompletionAndQuietPresentationMatches() async throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("The cancellation reproduction starts with normal motion")
        }
        var game = try naturalOrbit()
        XCTAssertNotNil(game.letStarsFall())
        let old = game, turn = try XCTUnwrap(game.letStarsFall())
        let first = try XCTUnwrap(turn.arrivals.first)
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        var staleComplete = false, quietComplete = false
        scene.animate(turn, from: old, to: game) { staleComplete = true }
        let appeared = ContinuousClock.now + .seconds(2)
        while scene.childNode(withName: "//sky.flight.\(first.star.id)") == nil && ContinuousClock.now < appeared {
            try await Task.sleep(for: .milliseconds(16))
        }
        XCTAssertNotNil(scene.childNode(withName: "//sky.flight.\(first.star.id)"))
        scene.render(old)
        XCTAssertFalse(scene.hasActions()); XCTAssertTrue(scene.children[2].children.isEmpty)
        scene.reduceMotion = true
        scene.animate(turn, from: old, to: game) { quietComplete = true }
        let quietLimit = ContinuousClock.now + .seconds(2)
        while !quietComplete && ContinuousClock.now < quietLimit { try await Task.sleep(for: .milliseconds(16)) }
        XCTAssertTrue(quietComplete)
        let normalLimit = ContinuousClock.now + .seconds(2)
        while !staleComplete && ContinuousClock.now < normalLimit { try await Task.sleep(for: .milliseconds(16)) }
        XCTAssertFalse(staleComplete, "Replacement must cancel the old grouped presentation, including its completion")
        XCTAssertFalse(scene.hasActions()); XCTAssertTrue(scene.children[2].children.isEmpty)
        let visible = scene.children[1].children.compactMap { ($0 as? FallingSkyCharacter)?.gem }.sorted { $0.id < $1.id }
        XCTAssertEqual(visible, game.board.compactMap { $0 }.sorted { $0.id < $1.id })
    }

    @MainActor func testFreshStoryOpeningRainsInAndSettlesExactSavedBoard() async throws {
        try requireNormalMotion()
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let first = FallingSky.freshChallenge(.firstLight)
        scene.prepareOpening(first)
        let host = try SceneHost(scene: scene); defer { host.close() }
        XCTAssertTrue(scene.children[1].children.isEmpty,
                      "Attaching the prepared scene must not flash its resting opening")
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let game = FallingSky.freshChallenge(challenge)
            XCTAssertTrue(game.supportsAutomaticRecipes)
            XCTAssertGreaterThan(game.occupiedCount, 20)
            scene.prepareOpening(game)
            XCTAssertTrue(scene.children[1].children.isEmpty)
            try await awaitSceneFrame(scene)
            var completions = 0, sawFlight = false, sawPartialLanding = false
            scene.presentOpening(game) { completions += 1 }
            let limit = ContinuousClock.now + .seconds(3)
            while completions == 0 && ContinuousClock.now < limit {
                let flights = scene.children[2].children.filter { $0.name?.hasPrefix("sky.flight.") == true }
                let landed = scene.children[1].children.compactMap { $0 as? FallingSkyCharacter }
                sawFlight = sawFlight || !flights.isEmpty
                if !flights.isEmpty && !landed.isEmpty && landed.count < game.occupiedCount {
                    if !sawPartialLanding { capture(scene, host: host, name: "\(challenge)-opening-rain") }
                    sawPartialLanding = true
                }
                for gem in landed {
                    XCTAssertNil(scene.childNode(withName: "//sky.flight.\(gem.gem.id)"),
                                 "An opening star must have one visible body at landing")
                }
                try await Task.sleep(for: .milliseconds(12))
            }
            XCTAssertEqual(completions, 1)
            XCTAssertTrue(sawFlight)
            XCTAssertTrue(sawPartialLanding, "The half-board should arrive progressively, not appear at once")
            assertBoard(game, in: scene)
            XCTAssertFalse(scene.hasActions())
            XCTAssertTrue(scene.children[2].children.isEmpty)
            capture(scene, host: host, name: "\(challenge)-opening-settled")
        }
    }

    @MainActor func testStoryOpeningReplacementAndQuietModeCancelUnfinishedRain() async throws {
        try requireNormalMotion()
        let game = FallingSky.freshChallenge(.firstLight)
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        try await awaitSceneFrame(scene)
        var staleCompletions = 0
        scene.presentOpening(game) { staleCompletions += 1 }
        let appeared = ContinuousClock.now + .seconds(2)
        while scene.children[2].children.isEmpty && ContinuousClock.now < appeared {
            try await Task.sleep(for: .milliseconds(12))
        }
        XCTAssertFalse(scene.children[2].children.isEmpty)
        scene.render(game)
        assertBoard(game, in: scene)
        let cancellationLimit = ContinuousClock.now + .milliseconds(1400)
        while staleCompletions == 0 && ContinuousClock.now < cancellationLimit {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(staleCompletions, 0)
        XCTAssertFalse(scene.hasActions())
        XCTAssertTrue(scene.children[2].children.isEmpty)
        scene.reduceMotion = true
        var quietCompletions = 0
        scene.presentOpening(game) { quietCompletions += 1 }
        XCTAssertEqual(quietCompletions, 1)
        assertBoard(game, in: scene)
        XCTAssertFalse(scene.hasActions())
        XCTAssertTrue(scene.children[2].children.isEmpty)
    }

    @MainActor func testRecipeCascadeShowsPopThenFallThenNextPop() async throws {
        try requireNormalMotion()
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        for challenge in [StarfallChallenge.firstLight, .ribbonCrossing] {
            let before = FallingSky.freshChallenge(challenge)
            var after = before
            let turn = try XCTUnwrap(after.nudge(from: Cell(1, 1), to: Cell(1, 2)))
            XCTAssertGreaterThanOrEqual(turn.resolutionPhases.count, 2)
            let first = turn.resolutionPhases[0], second = turn.resolutionPhases[1]
            let falling = try XCTUnwrap(second.cleared.compactMap { cell -> (Int, Cell, Cell)? in
                guard let gem = second.before[cell.row * 7 + cell.column],
                      let prior = first.before.firstIndex(where: { $0?.id == gem.id }),
                      prior != cell.row * 7 + cell.column else { return nil }
                return (gem.id, Cell(prior / 7, prior % 7), cell)
            }.first)
            scene.render(before)
            try await awaitSceneFrame(scene)
            var phases: [Int] = [], completions = 0, sawFallingSurvivor = false
            var positionAtSecondPop: CGPoint?
            scene.animate(turn, from: before, to: after, phaseBegan: { index in
                phases.append(index)
                if index == 1 {
                    positionAtSecondPop = scene.childNode(withName: "//sky.star.\(falling.0)")?.position
                    for cell in first.cleared {
                        if let id = first.before[cell.row * 7 + cell.column]?.id {
                            XCTAssertNil(scene.childNode(withName: "//sky.star.\(id)"),
                                         "The first pop must end before the second pop begins")
                        }
                    }
                }
            }, completion: { completions += 1 })
            let limit = ContinuousClock.now + .seconds(5)
            while completions == 0 && ContinuousClock.now < limit {
                if phases == [0], let node = scene.childNode(withName: "//sky.star.\(falling.0)"),
                   node.action(forKey: "sky.recipe-settle") != nil {
                    let start = LandingGeometry(size: scene.size).scenePoint(falling.1)
                    let end = LandingGeometry(size: scene.size).scenePoint(falling.2)
                    if hypot(node.position.x - start.x, node.position.y - start.y) > 1,
                       hypot(node.position.x - end.x, node.position.y - end.y) > 1 {
                        if !sawFallingSurvivor { capture(scene, host: host, name: "\(challenge)-cascade-survivor-fall") }
                        sawFallingSurvivor = true
                    }
                }
                try await Task.sleep(for: .milliseconds(12))
            }
            XCTAssertEqual(completions, 1)
            XCTAssertEqual(phases, Array(turn.resolutionPhases.indices))
            XCTAssertTrue(sawFallingSurvivor)
            let settled = LandingGeometry(size: scene.size).scenePoint(falling.2)
            let observed = try XCTUnwrap(positionAtSecondPop)
            XCTAssertEqual(observed.x, settled.x, accuracy: 0.01)
            XCTAssertEqual(observed.y, settled.y, accuracy: 0.01,
                           "A causal follow-up must start from the completed survivor fall")
            assertBoard(after, in: scene)
            XCTAssertFalse(scene.hasActions())
            XCTAssertTrue(scene.children[2].children.isEmpty)
        }
    }

    @MainActor func testRecipeCascadeReplacementAndQuietModeDiscardRemainingCallbacks() async throws {
        try requireNormalMotion()
        let before = FallingSky.freshChallenge(.ribbonCrossing)
        var after = before
        let turn = try XCTUnwrap(after.nudge(from: Cell(1, 1), to: Cell(1, 2)))
        XCTAssertGreaterThanOrEqual(turn.resolutionPhases.count, 2)
        let scene = FallingSkyScene(size: CGSize(width: 390, height: 844))
        let host = try SceneHost(scene: scene); defer { host.close() }
        scene.render(before)
        try await awaitSceneFrame(scene)
        var phases: [Int] = [], staleCompletions = 0
        scene.animate(turn, from: before, to: after, phaseBegan: { phases.append($0) },
                      completion: { staleCompletions += 1 })
        let firstPopLimit = ContinuousClock.now + .seconds(2)
        while phases.isEmpty && ContinuousClock.now < firstPopLimit {
            try await Task.sleep(for: .milliseconds(12))
        }
        XCTAssertEqual(phases, [0])
        scene.render(after)
        let cancellationLimit = ContinuousClock.now + .seconds(2)
        while staleCompletions == 0 && ContinuousClock.now < cancellationLimit {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertEqual(staleCompletions, 0)
        XCTAssertEqual(phases, [0])
        assertBoard(after, in: scene)
        scene.reduceMotion = true
        var quietCompletions = 0, quietPhases: [Int] = []
        scene.animate(turn, from: before, to: after, phaseBegan: { quietPhases.append($0) },
                      completion: { quietCompletions += 1 })
        XCTAssertEqual(quietCompletions, 1)
        XCTAssertTrue(quietPhases.isEmpty, "Quiet presentation keeps one aggregate receipt")
        assertBoard(after, in: scene)
        XCTAssertFalse(scene.hasActions())
        XCTAssertTrue(scene.children[2].children.isEmpty)
    }

    @MainActor private func requireNormalMotion() throws {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Normal-motion presentation requires system quiet modes off")
        }
    }

    @MainActor private func awaitSceneFrame(_ scene: FallingSkyScene) async throws {
        var ready = false
        scene.run(.run { ready = true }, withKey: "test.story-scene-ready")
        let limit = ContinuousClock.now + .seconds(2)
        while !ready && ContinuousClock.now < limit { try await Task.sleep(for: .milliseconds(5)) }
        XCTAssertTrue(ready, "The native host must render before sampling brief animation phases")
    }

    @MainActor private func assertBoard(_ game: FallingSky, in scene: FallingSkyScene,
                                       file: StaticString = #filePath, line: UInt = #line) {
        let visible = scene.children[1].children.compactMap { $0 as? FallingSkyCharacter }
        XCTAssertEqual(visible.map(\.gem).sorted { $0.id < $1.id },
                       game.board.compactMap { $0 }.sorted { $0.id < $1.id }, file: file, line: line)
        for (index, gem) in game.board.enumerated() {
            guard let gem, let node = visible.first(where: { $0.gem.id == gem.id }) else { continue }
            let expected = LandingGeometry(size: scene.size).scenePoint(Cell(index / 7, index % 7))
            XCTAssertEqual(node.position.x, expected.x, accuracy: 0.01, file: file, line: line)
            XCTAssertEqual(node.position.y, expected.y, accuracy: 0.01, file: file, line: line)
        }
    }

    @MainActor private func capture(_ scene: FallingSkyScene, host: SceneHost, name: String) {
        guard let texture = host.view.texture(from: scene) else {
            XCTFail("The active native scene must provide a capture")
            return
        }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let image = UIGraphicsImageRenderer(size: host.view.bounds.size, format: format).image { context in
            UIColor(red: 0.04, green: 0.055, blue: 0.12, alpha: 1).setFill()
            context.fill(host.view.bounds)
            UIImage(cgImage: texture.cgImage()).draw(in: host.view.bounds)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor private func measure(initial: FallingSky, through finalShower: Int, name: String) async throws -> [Window] {
        guard !UIAccessibility.isReduceMotionEnabled && !UIAccessibility.isVoiceOverRunning else {
            throw XCTSkip("Normal-motion timing requires Reduce Motion and VoiceOver off")
        }
        let normalized = initial.removingGravity().adoptingFeedingDusk().disablingAutomaticAging()
        var expected = normalized
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
        XCTAssertEqual(store.game, normalized)
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
                criticalMassRuleVersion: initial.hasCriticalMass ? CriticalMassRule.version : nil, cadenceID: initial.cadenceID.rawValue,
                collapseSources: turn.stellarCollapses.count, density: initial.generation.phase(for: shower)?.isStorm == true ? "heavy" : "lighter",
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
                busy: event.snapshot.busy, ready: event.snapshot.canClear,
                admittedTapGroups: event.snapshot.admittedTapGroups, paused: event.snapshot.paused,
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
    let admittedTapGroups: Int
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
