import XCTest
import SwiftUI
import UIKit
import Combine
@testable import StarfallCore
@testable import Starfall

@MainActor private final class RibbonResponsePresenter: FallingSkyPresenting {
    struct Presentation { let phase: (Int) -> Void; let complete: () -> Void }
    var reduceMotion = false
    var presentations: [Presentation] = []
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) {
        presentations.append(.init(phase: { _ in }, complete: completion))
    }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        presentations.append(.init(phase: phaseBegan, complete: completion))
    }
}

@MainActor private final class RibbonArchiveCounter { var writes = 0 }
@MainActor private final class RibbonLiveProbe: ObservableObject {
    @Published var award: StarlightCelebration?
    var registeredLight: CGRect?
    var admittedReceipt: UInt64?
}
@MainActor private struct RibbonLiveView: View {
    @ObservedObject var probe: RibbonLiveProbe
    let presentation: RestorationPresentation
    let size: CGSize
    var body: some View {
        RestorationEnvironment(presentation: presentation, active: true, ambientActive: false,
            quiet: false, award: probe.award, awardQuiet: false)
            .frame(width: size.width, height: size.height)
            .overlay(alignment: .bottomLeading) {
                Rectangle().fill(probe.award == nil ? Color.black : .white)
                    .frame(width: 6, height: 6).padding(4)
            }
            .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                GeometryReader { geometry in
                    if let anchor = anchors[.restorationLight] {
                        let origin = geometry.frame(in: .global).origin
                        let light = geometry[anchor].offsetBy(dx: origin.x, dy: origin.y)
                        Color.clear.onAppear { probe.registeredLight = light }
                            .onChange(of: light) { _, value in probe.registeredLight = value }
                    }
                }
            }
            .onChange(of: probe.award?.id) { _, value in probe.admittedReceipt = value }
            .ignoresSafeArea()
    }
}
@MainActor private final class RibbonDisplaySampler: NSObject {
    var frames = 0
    var sample: (() -> Void)?
    @objc func tick(_ display: CADisplayLink) { frames += 1; sample?() }
}

final class RibbonAwardResponseTests: XCTestCase {
    private let receiver = CGRect(x: 112, y: 84, width: 24, height: 24)
    private func exchange(_ move: (Int, Int), game: inout FallingSky) throws -> FallingSkyTurn {
        try XCTUnwrap(game.nudge(from: Cell(move.0 / 7, move.0 % 7), to: Cell(move.1 / 7, move.1 % 7)))
    }
    private func receipt(_ turn: FallingSkyTurn, index: Int, total: Int, id: UInt64 = 1) -> StarlightCelebration {
        .init(id: id, phase: turn.resolutionPhases[index],
              cumulativeAward: turn.resolutionPhases.prefix(index + 1).reduce(0) { $0 + $1.award.displayPoints },
              total: total, precedingPhases: Array(turn.resolutionPhases.prefix(index)))
    }
    private func ribbonEvent() throws -> StarlightCelebration {
        var game = FallingSky.freshChallenge(.ribbonCrossing)
        let turn = try exchange((8, 9), game: &game)
        return receipt(turn, index: 0, total: game.displayScore)
    }
    private func response(_ event: StarlightCelebration, receiver: CGRect? = nil,
                          composition: RestorationComposition = .phone, quiet: Bool = false) throws -> RibbonAwardResponse {
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        return try XCTUnwrap(RibbonAwardResponse(event: event, challenge: .ribbonCrossing,
            receiver: receiver ?? self.receiver, composition: composition,
            age: quiet ? 0 : arrival + StarlightCelebration.receiverDuration / 2, quiet: quiet))
    }

    func testSameRealFiveThousandPointsAnswersLanternAndRibbonWithTheirOwnMaterialAndCurrentDefinitions() throws {
        var lantern = FallingSky.freshChallenge(.firstLight)
        var ribbon = FallingSky.freshChallenge(.ribbonCrossing)
        let lanternTurn = try exchange((8, 9), game: &lantern), ribbonTurn = try exchange((8, 9), game: &ribbon)
        let lanternEvent = receipt(lanternTurn, index: 0, total: lantern.displayScore)
        let ribbonEvent = receipt(ribbonTurn, index: 0, total: ribbon.displayScore)
        XCTAssertEqual(lanternEvent.displayAward, 5_000)
        XCTAssertEqual(ribbonEvent.displayAward, 5_000)
        XCTAssertEqual(lanternEvent.collected, ribbonEvent.collected)
        let arrival = try XCTUnwrap(lanternEvent.lastPacketArrival(toRestoration: true))
        let warm = try XCTUnwrap(LanternAwardResponse(event: lanternEvent, challenge: .firstLight,
            receiver: receiver, age: arrival + 0.16, quiet: false))
        XCTAssertEqual(warm.aperture, receiver)
        XCTAssertGreaterThan(warm.apertureOpacity, 0)
        let stitched = try response(ribbonEvent)
        XCTAssertEqual(stitched.stitches.count, 8)
        XCTAssertEqual(stitched.seam.count, 2)
        XCTAssertNil(RibbonAwardResponse(event: lanternEvent, challenge: .firstLight, receiver: receiver,
                                         composition: .phone, age: arrival + 0.16, quiet: false))
        XCTAssertNil(LanternAwardResponse(event: ribbonEvent, challenge: .ribbonCrossing,
                                         receiver: receiver, age: arrival + 0.16, quiet: false))
        for opening in [FallingSky.freshChallenge(.ribbonCrossing), .fullBoardRibbon()] {
            var game = opening
            let turn = try exchange((8, 9), game: &game)
            XCTAssertEqual(opening.challengeRevision, opening.usesFullBoardRefill ? 7 : 4)
            XCTAssertEqual(turn.resolutionPhases.count, 3)
            _ = try response(receipt(turn, index: 2, total: game.displayScore))
            XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
            XCTAssertEqual(game.replay(), opening)
        }
    }

    func testFourCrossesKeepRegisteredCenterAndBoundedGeometryForEachActualComposition() throws {
        let event = try ribbonEvent()
        let examples: [(RestorationComposition, CGSize)] = [
            (.phone, CGSize(width: 390, height: 844)),
            (.tabletPortrait, CGSize(width: 834, height: 1194)),
            (.tabletLandscape, CGSize(width: 1194, height: 834))
        ]
        for (composition, size) in examples {
            let artwork = RestorationArtwork(challenge: .ribbonCrossing, composition: composition)
            let registered = RestorationLayout(size: size, artwork: artwork).light
            let normal = try response(event, receiver: registered, composition: composition)
            let quiet = try response(event, receiver: registered, composition: composition, quiet: true)
            XCTAssertEqual(normal.receiver, registered)
            XCTAssertEqual(quiet.seam, normal.seam)
            XCTAssertEqual(quiet.stitches, normal.stitches)
            XCTAssertEqual(quiet.bounds, normal.bounds)
            XCTAssertEqual(normal.seam.count, 2)
            XCTAssertEqual(normal.stitches.count, 8)
            XCTAssertTrue(normal.stitches.allSatisfy { $0.count == 2 })
            let a = normal.seam[0], b = normal.seam[1]
            let length = hypot(b.x - a.x, b.y - a.y)
            XCTAssertGreaterThan(length, 0)
            XCTAssertLessThanOrEqual(length, 42.000001)
            XCTAssertEqual((a.x + b.x) / 2, registered.midX, accuracy: 0.000001)
            XCTAssertEqual((a.y + b.y) / 2, registered.midY, accuracy: 0.000001)
            let axis = CGPoint(x: (b.x - a.x) / length, y: (b.y - a.y) / length)
            let across = normal.stitches.flatMap { $0 }.map {
                ($0.x - registered.midX) * -axis.y + ($0.y - registered.midY) * axis.x
            }
            XCTAssertLessThanOrEqual(try XCTUnwrap(across.max()) - XCTUnwrap(across.min()), 18.000001)
            let points = normal.seam + normal.stitches.flatMap { $0 }
            XCTAssertTrue(points.allSatisfy { normal.bounds.insetBy(dx: -0.000001, dy: -0.000001).contains($0) })
            XCTAssertGreaterThan(axis.y, 0)
            switch composition {
            case .phone: XCTAssertGreaterThan(axis.x, 0); XCTAssertLessThan(abs(axis.x / axis.y), 0.2)
            case .tabletPortrait: XCTAssertLessThan(axis.x, 0); XCTAssertGreaterThan(abs(axis.x / axis.y), 0.4)
            case .tabletLandscape: XCTAssertGreaterThan(axis.x, 0); XCTAssertGreaterThan(abs(axis.x / axis.y), 0.3)
            }
            var centers: [CGFloat] = []
            for index in stride(from: 0, to: normal.stitches.count, by: 2) {
                let first = normal.stitches[index], second = normal.stitches[index + 1]
                let one = CGPoint(x: (first[0].x + first[1].x) / 2, y: (first[0].y + first[1].y) / 2)
                let two = CGPoint(x: (second[0].x + second[1].x) / 2, y: (second[0].y + second[1].y) / 2)
                XCTAssertEqual(one.x, two.x, accuracy: 0.000001)
                XCTAssertEqual(one.y, two.y, accuracy: 0.000001)
                centers.append((one.x - registered.midX) * axis.x + (one.y - registered.midY) * axis.y)
            }
            XCTAssertEqual(centers, centers.sorted())
            XCTAssertEqual(Set(centers).count, 4)
            XCTAssertTrue(quiet.reveals.allSatisfy { $0 == 1 })
            XCTAssertGreaterThan(quiet.opacity, 0)
        }
    }

    func testArrivalRevealsCrossesInOrderWhileQuietShowsTheSameCompleteTemporaryFigure() throws {
        let event = try ribbonEvent(), arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        XCTAssertNil(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: receiver,
                                         composition: .phone, age: arrival - 0.000001, quiet: false))
        let early = try XCTUnwrap(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: receiver,
            composition: .phone, age: arrival + StarlightCelebration.receiverDuration * 0.2, quiet: false))
        let late = try XCTUnwrap(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: receiver,
            composition: .phone, age: arrival + StarlightCelebration.receiverDuration * 0.8, quiet: false))
        XCTAssertEqual(early.stitches, late.stitches)
        XCTAssertEqual(early.reveals.count, 8)
        XCTAssertGreaterThan(early.reveals[0], early.reveals[6])
        XCTAssertGreaterThan(late.reveals.reduce(0, +), early.reveals.reduce(0, +))
        for index in stride(from: 0, to: early.reveals.count, by: 2) {
            XCTAssertEqual(early.reveals[index], early.reveals[index + 1])
            XCTAssertTrue((0...1).contains(early.reveals[index]))
        }
        let quiet = try response(event, quiet: true)
        XCTAssertEqual(quiet.seam, early.seam)
        XCTAssertEqual(quiet.stitches, early.stitches)
        XCTAssertTrue(quiet.reveals.allSatisfy { $0 == 1 })
        for motion in [false, true] {
            XCTAssertNil(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: receiver,
                composition: .phone, age: StarlightCelebration.duration, quiet: motion))
        }
    }

    func testWrongPlaceMissingAwardAndInvalidGeometryOrAgeCannotAcquireASeam() throws {
        let event = try ribbonEvent()
        for challenge in [StarfallChallenge?.none] + StarfallChallenge.allCases
            .filter({ $0 != .ribbonCrossing }).map(Optional.some) {
            XCTAssertNil(RibbonAwardResponse(event: event, challenge: challenge, receiver: receiver,
                                             composition: .phone, age: 0, quiet: true))
        }
        let bad: [CGRect] = [.zero, .null, .infinite,
            CGRect(x: CGFloat.nan, y: 0, width: 12, height: 12),
            CGRect(x: 0, y: 0, width: CGFloat.infinity, height: 12),
            CGRect(x: 0, y: 0, width: 12, height: 0)]
        for quiet in [false, true] {
            for rectangle in bad {
                XCTAssertNil(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: rectangle,
                                                 composition: .phone, age: 0.6, quiet: quiet))
            }
            for age in [-0.001, Double.nan, .infinity, -.infinity, StarlightCelebration.duration] {
                XCTAssertNil(RibbonAwardResponse(event: event, challenge: .ribbonCrossing, receiver: receiver,
                                                 composition: .phone, age: age, quiet: quiet))
            }
        }
        // Value-only validation fixture; it is not a reachable zero-award Story history.
        let phase = SkyResolutionPhase(kind: .recipe, before: Array(repeating: nil, count: 49), cleared: [], comboDepth: 1)
        let empty = StarlightCelebration(id: 7, phase: phase, cumulativeAward: 0, total: 0)
        XCTAssertNil(RibbonAwardResponse(event: empty, challenge: .ribbonCrossing, receiver: receiver,
                                         composition: .phone, age: 0, quiet: true))
    }

    @MainActor private func store(_ opening: FallingSky) throws
    -> (FallingSkyStore, RibbonResponsePresenter, ManualRainClock, UserDefaults, RibbonArchiveCounter) {
        let suite = "Starfall.RibbonAwardResponse.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(opening, to: defaults)
        let presenter = RibbonResponsePresenter(), clock = ManualRainClock(), counter = RibbonArchiveCounter()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
            archiveWriter: { game, defaults in counter.writes += 1; try SkySaveArchive.save(game, to: defaults) })
        store.setSuspended(false)
        return (store, presenter, clock, defaults, counter)
    }
    @MainActor private func perform(_ move: (Int, Int), store: FallingSkyStore,
                                   presenter: RibbonResponsePresenter) throws
    -> (FallingSkyTurn, RibbonResponsePresenter.Presentation) {
        var expected = store.game
        let turn = try exchange(move, game: &expected)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(move.0 / 7, move.0 % 7), Cell(move.1 / 7, move.1 % 7)),
            snapshot: store.game, generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        return (turn, try XCTUnwrap(presenter.presentations.last))
    }

    @MainActor func testBothCurrentModesCommitBeforeResponseWithoutExtraSaveWorldOrClockWrites() throws {
        for opening in [FallingSky.freshChallenge(.ribbonCrossing), .fullBoardRibbon()] {
            let (store, presenter, clock, defaults, counter) = try store(opening)
            defer { store.setSuspended(true) }
            if !opening.usesFullBoardRefill { store.togglePause(); clock.advance(1) }
            let deadline = clock.deadline
            let (turn, presentation) = try perform((8, 9), store: store, presenter: presenter)
            let game = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
            let world = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
            for index in turn.resolutionPhases.indices {
                presentation.phase(index)
                let event = try XCTUnwrap(store.celebration)
                _ = try response(event)
                _ = try response(event, quiet: true)
                XCTAssertEqual(store.game, game)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                XCTAssertEqual(counter.writes, writes)
                XCTAssertEqual(clock.deadline, deadline)
                XCTAssertTrue(store.busy)
            }
            presentation.complete()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(game.replay(), opening)
        }
    }

    @MainActor func testReplacementSuspensionAndReplayRejectOldThreadReceiptAndLateCallbacks() throws {
        for boundary in ["replacement", "suspension", "replay"] {
            let opening = FallingSky.fullBoardRibbon()
            let (store, presenter, clock, defaults, counter) = try store(opening)
            defer { store.setSuspended(true) }
            let (turn, old) = try perform((8, 9), store: store, presenter: presenter)
            old.phase(turn.resolutionPhases.count - 1)
            let oldEvent = try XCTUnwrap(store.celebration)
            if boundary == "replacement" {
                old.complete()
                let (nextTurn, next) = try perform((11, 12), store: store, presenter: presenter)
                XCTAssertNil(store.celebration)
                next.phase(nextTurn.resolutionPhases.count - 1)
                XCTAssertNotEqual(store.celebration?.id, oldEvent.id)
            } else if boundary == "suspension" { store.setSuspended(true) }
            else { store.restart(sameSky: true) }
            let current = store.celebration, game = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
            let world = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
            old.phase(0); old.phase(turn.resolutionPhases.count - 1); old.complete()
            XCTAssertEqual(store.celebration, current)
            XCTAssertEqual(store.game, game)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
            XCTAssertEqual(counter.writes, writes)
            XCTAssertNil(clock.deadline)
            if boundary != "replacement" { XCTAssertNil(store.celebration) }
            if boundary == "replay" { XCTAssertEqual(store.game, opening) }
        }
    }

    @MainActor func testFrozenRibbonWinningRouteRepairsBeforeThreadAndKeepsExactReplay() throws {
        let opening = FallingSky.fullBoardRibbon()
        let (store, presenter, clock, defaults, counter) = try store(opening)
        defer { store.setSuspended(true) }
        let route = [(8,9), (11,12), (31,38), (17,24), (9,16), (9,10), (1,8), (1,2), (1,8),
                     (9,10), (10,11), (22,29), (2,3), (2,9), (1,8), (37,38), (2,3), (16,17)]
        var final: RibbonResponsePresenter.Presentation?
        for (index, move) in route.enumerated() {
            let (turn, presentation) = try perform(move, store: store, presenter: presenter)
            if index == route.count - 1 {
                XCTAssertEqual(store.game.outcome, .won)
                XCTAssertEqual(store.game.displayScore, 229_000)
                XCTAssertTrue(store.journey.journey.completed.contains(.ribbonCrossing))
                let game = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
                let world = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
                presentation.phase(turn.resolutionPhases.count - 1)
                _ = try response(XCTUnwrap(store.celebration))
                XCTAssertEqual(store.game, game)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), world)
                XCTAssertEqual(counter.writes, writes)
                XCTAssertTrue(store.busy)
                final = presentation
            } else { presentation.complete() }
        }
        try XCTUnwrap(final).complete()
        XCTAssertFalse(store.busy)
        store.restart(sameSky: true)
        let replay = defaults.data(forKey: SkySaveArchive.key)
        final?.phase(0); final?.complete()
        XCTAssertNil(store.celebration)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), replay)
        XCTAssertNil(clock.deadline)
    }

    private enum Painter { case model, scenery, overlay }
    @MainActor private func render(_ event: StarlightCelebration, age: TimeInterval, quiet: Bool,
                                  painter: Painter, challenge: StarfallChallenge = .ribbonCrossing,
                                  active: Bool = true, exclusions: [CGRect] = []) throws -> UIImage {
        let size = CGSize(width: 240, height: 192)
        let content = Canvas { context, canvas in
            switch painter {
            case .model:
                if let response = RibbonAwardResponse(event: event, challenge: challenge,
                    receiver: self.receiver, composition: .phone, age: age, quiet: quiet) {
                    RibbonAwardResponse.draw(in: &context, response: response, canvasSize: canvas, exclusions: exclusions)
                }
            case .scenery:
                let environment = RestorationEnvironment(presentation: .init(challenge: challenge,
                    progress: .init(score: 30_000, target: 220_000)), active: active, ambientActive: false,
                    quiet: quiet, award: event, awardQuiet: quiet)
                environment.drawAward(in: &context, age: age, canvasSize: canvas, receiver: self.receiver)
            case .overlay:
                let overlay = StarlightCelebrationOverlay(event: event, board: .init(origin: .zero, size: size),
                    score: .zero, header: exclusions.first ?? .zero, quiet: quiet,
                    lightDestination: self.receiver, restorationChallenge: challenge)
                overlay.drawReceiver(in: &context, age: age, canvasSize: canvas)
            }
        }.frame(width: size.width, height: size.height).background(Color.black)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return try XCTUnwrap(renderer.uiImage)
    }

    @MainActor func testActualSceneryOwnerDrawsThreadsBelowHeaderWithoutDuplicateOrEarlyAcknowledgement() throws {
        let event = try ribbonEvent(), arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        // This covering container reproduces the prior compositing counterexample:
        // a transparent part of the header must not mask its underlying scenery.
        let coveringHeader = CGRect(x: 0, y: 0, width: 240, height: 128)
        XCTAssertTrue(coveringHeader.contains(receiver))
        let cases: [(String, Painter, TimeInterval, Bool, Bool, StarfallChallenge, Bool)] = [
            ("before-arrival", .scenery, arrival - 0.001, false, true, .ribbonCrossing, false),
            ("actual-threads", .model, arrival + 0.16, false, true, .ribbonCrossing, true),
            ("scenery-under-header", .scenery, arrival + 0.16, false, true, .ribbonCrossing, true),
            ("quiet-complete-threads", .scenery, 0, true, true, .ribbonCrossing, true),
            ("no-foreground-duplicate", .overlay, arrival + 0.16, false, true, .ribbonCrossing, false),
            ("inactive-scenery", .scenery, arrival + 0.16, false, false, .ribbonCrossing, false),
            ("other-scenery-unchanged", .scenery, arrival + 0.16, false, true, .kiteHarbor, false),
            ("other-generic-receiver-retained", .overlay, arrival + 0.16, false, true, .kiteHarbor, true)
        ]
        for example in cases {
            // The model's positive control must remain unmasked. The covering
            // header is the scenery/foreground ownership counterexample; the
            // independent partial-mask model case below owns clipping coverage.
            let exclusions: [CGRect]
            if case .model = example.1 { exclusions = [] }
            else { exclusions = [coveringHeader] }
            let image = try render(event, age: example.2, quiet: example.3, painter: example.1,
                challenge: example.5, active: example.4, exclusions: exclusions)
            if example.6 { XCTAssertGreaterThan(try ink(image), 25, example.0) }
            else { XCTAssertEqual(try ink(image), 0, example.0) }
            let attachment = XCTAttachment(image: image)
            attachment.name = "ribbon-award-\(example.0)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        // Independent synthetic clipping check; these are not native HUD coordinates.
        let exclusion = CGRect(x: receiver.midX, y: 60, width: 40, height: 80)
        let clipped = try render(event, age: 0, quiet: true, painter: .model, exclusions: [exclusion])
        XCTAssertGreaterThan(try ink(clipped), 25)
        XCTAssertEqual(try ink(clipped, region: exclusion), 0)
    }

    @MainActor func testSameAmbientPausedEnvironmentAdmitsNormalThreadFramesAfterActualArrival() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let size = CGSize(width: 390, height: 844)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        var game = FallingSky.freshChallenge(.ribbonCrossing)
        let turn = try exchange((8, 9), game: &game)
        let presentation = try XCTUnwrap(RestorationPresentation.selected(game: game, entry: nil))
        let probe = RibbonLiveProbe(), sampler = RibbonDisplaySampler()
        let host = UIHostingController(rootView: RibbonLiveView(probe: probe, presentation: presentation, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        let display = CADisplayLink(target: sampler, selector: #selector(RibbonDisplaySampler.tick(_:)))
        display.add(to: .main, forMode: .common)
        defer {
            sampler.sample = nil; display.invalidate()
            window.isHidden = true; window.rootViewController = nil; previous?.makeKey()
        }
        let readyDeadline = ContinuousClock.now + .seconds(3)
        while (sampler.frames < 2 || probe.registeredLight == nil) && ContinuousClock.now < readyDeadline {
            try await Task.sleep(for: .milliseconds(8))
        }
        XCTAssertGreaterThanOrEqual(sampler.frames, 2, "The visible body needs actual display frames before the receipt")
        XCTAssertNotNil(host.view.window)
        let registered = try XCTUnwrap(probe.registeredLight)
        XCTAssertTrue(window.bounds.contains(registered))
        let geometry = try response(receipt(turn, index: 0, total: game.displayScore), receiver: registered, quiet: true)
        let crop = geometry.bounds.insetBy(dx: -1, dy: -1).integral.intersection(window.bounds)
        XCTAssertGreaterThan(crop.width, 0)
        XCTAssertGreaterThan(crop.height, 0)
        host.view.layoutIfNeeded()
        let baselineFull = windowImage(window, region: window.bounds), baselineImage = windowImage(window, region: crop)
        let baseline = try rgba(baselineImage)
        XCTAssertGreaterThan(try ink(baselineFull), 25)

        // The same hosting root and Environment survive nil -> immutable receipt.
        // No quiet presentation, manual draw helper or nominally timed capture substitutes for it.
        let event = receipt(turn, index: 0, total: game.displayScore, id: 93)
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        var before = 0, delivered = 0, visible = 0
        var records: [String] = [], failure: String?
        var answerCrop: UIImage?, answerFull: UIImage?
        sampler.sample = {
            let began = Date.now.timeIntervalSince(event.started)
            guard began < StarlightCelebration.duration else { return }
            let image = self.windowImage(window, region: crop)
            let ended = Date.now.timeIntervalSince(event.started)
            do {
                let current = try self.rgba(image)
                guard current.count == baseline.count else { failure = "Registered thread crop changed pixel dimensions"; return }
                var changed = 0
                for index in stride(from: 0, to: current.count, by: 4) {
                    if max(abs(Int(current[index]) - Int(baseline[index])),
                           abs(Int(current[index + 1]) - Int(baseline[index + 1])),
                           abs(Int(current[index + 2]) - Int(baseline[index + 2]))) > 2 { changed += 1 }
                }
                records.append("display=\(sampler.frames) began=\(began) ended=\(ended) "
                    + "admitted=\(probe.admittedReceipt == event.id) changed=\(changed)")
                if ended < arrival {
                    before += 1
                    XCTAssertEqual(changed, 0, "Thread must not appear before last-packet arrival: \(records.last!)")
                }
                if began >= arrival && ended <= arrival + StarlightCelebration.receiverDuration {
                    delivered += 1
                    if changed > 25 {
                        visible += 1
                        if answerCrop == nil {
                            answerCrop = image
                            answerFull = self.windowImage(window, region: window.bounds)
                        }
                    }
                }
            } catch { failure = String(describing: error) }
        }
        probe.award = event
        let deadline = ContinuousClock.now + .seconds(1.7)
        while Date.now.timeIntervalSince(event.started) < StarlightCelebration.duration
                && ContinuousClock.now < deadline && failure == nil {
            try await Task.sleep(for: .milliseconds(8))
        }
        sampler.sample = nil
        let final = windowImage(window, region: window.bounds)
        let marker = CGRect(x: 4, y: size.height - 10, width: 6, height: 6)
        let markerInk = try ink(final, region: marker)
        let summary = "arrival=\(arrival) before=\(before) delivered=\(delivered) visible=\(visible) "
            + "admitted=\(probe.admittedReceipt == event.id) marker=\(markerInk) failure=\(failure ?? "none") "
            + "registered=\(registered) crop=\(crop)"
        let diagnostics = XCTAttachment(string: ([summary] + records).joined(separator: "\n"))
        diagnostics.name = "ribbon-live-normal-thread-samples"
        diagnostics.lifetime = .keepAlways
        add(diagnostics)
        XCTAssertNil(failure)
        XCTAssertEqual(probe.admittedReceipt, event.id)
        XCTAssertGreaterThan(markerInk, 0, "Composited marker must prove the same view admitted its new receipt")
        XCTAssertGreaterThan(before, 0, "Missing pre-arrival samples/readiness: \(summary)")
        XCTAssertGreaterThan(delivered, 0, "Missing samples wholly inside actual arrival window: \(summary)")
        XCTAssertGreaterThan(visible, 0, "No actual thread pixel response in delivered samples: \(summary)")
        for (name, image) in [("baseline", Optional(baselineFull)), ("thread-crop", answerCrop),
                              ("thread-full", answerFull), ("final-admission", Optional(final))] {
            if let image {
                let attachment = XCTAttachment(image: image)
                attachment.name = "ribbon-live-normal-\(name)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor private func windowImage(_ window: UIWindow, region: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        return UIGraphicsImageRenderer(size: region.size, format: format).image { context in
            context.cgContext.translateBy(x: -region.minX, y: -region.minY)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
    private func rgba(_ image: UIImage, region: CGRect? = nil) throws -> [UInt8] {
        var cg = try XCTUnwrap(image.cgImage)
        if let region { cg = try XCTUnwrap(cg.cropping(to: region.applying(.init(scaleX: image.scale, y: image.scale)))) }
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: cg.width, height: cg.height,
            bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return bytes
    }
    private func ink(_ image: UIImage, region: CGRect? = nil) throws -> Int {
        let bytes = try rgba(image, region: region)
        return stride(from: 0, to: bytes.count, by: 4).filter {
            max(bytes[$0], bytes[$0 + 1], bytes[$0 + 2]) > 2
        }.count
    }
}
