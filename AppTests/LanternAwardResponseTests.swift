import XCTest
import SwiftUI
import UIKit
import Combine
@testable import StarfallCore
@testable import Starfall

@MainActor private final class LanternResponsePresenter: FallingSkyPresenting {
    struct Presentation {
        let phase: (Int) -> Void
        let complete: () -> Void
    }
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

@MainActor private final class LanternArchiveCounter { var writes = 0 }

@MainActor private final class LanternLiveResponseProbe: ObservableObject {
    @Published var award: StarlightCelebration?
    var registeredLight: CGRect?
    var admittedReceipt: UInt64?
}

@MainActor private struct LanternLiveResponseView: View {
    @ObservedObject var probe: LanternLiveResponseProbe
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

@MainActor private final class LanternDisplaySampler: NSObject {
    var frames = 0
    var sample: (() -> Void)?
    @objc func tick(_ display: CADisplayLink) { frames += 1; sample?() }
}

final class LanternAwardResponseTests: XCTestCase {
    private let receiver = CGRect(x: 112, y: 84, width: 24, height: 24)

    private func committed(_ opening: FallingSky, move: (Int, Int))
    throws -> (FallingSky, FallingSkyTurn, StarlightCelebration) {
        var game = opening
        let turn = try XCTUnwrap(game.nudge(from: Cell(move.0 / 7, move.0 % 7),
                                           to: Cell(move.1 / 7, move.1 % 7)))
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        let event = StarlightCelebration(id: 1, phase: phase, cumulativeAward: turn.displayAward,
            total: game.displayScore, precedingPhases: Array(turn.resolutionPhases.dropLast()))
        return (game, turn, event)
    }

    @MainActor private func makeStore(_ game: FallingSky)
    throws -> (FallingSkyStore, LanternResponsePresenter, ManualRainClock, UserDefaults, LanternArchiveCounter) {
        let suite = "Starfall.LanternAwardResponse.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: defaults)
        let presenter = LanternResponsePresenter(), clock = ManualRainClock(), counter = LanternArchiveCounter()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
            archiveWriter: { game, defaults in
                counter.writes += 1
                try SkySaveArchive.save(game, to: defaults)
            })
        store.setSuspended(false)
        XCTAssertEqual(store.game, game)
        return (store, presenter, clock, defaults, counter)
    }

    @MainActor private func exchange(_ move: (Int, Int), in store: FallingSkyStore,
                                    presenter: LanternResponsePresenter) throws
    -> (FallingSkyTurn, LanternResponsePresenter.Presentation) {
        let before = store.game
        var expected = before
        let from = Cell(move.0 / 7, move.0 % 7), to = Cell(move.1 / 7, move.1 % 7)
        let turn = try XCTUnwrap(expected.nudge(from: from, to: to))
        XCTAssertTrue(store.performTechnique(.nudge(from, to), snapshot: before,
                                             generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        return (turn, try XCTUnwrap(presenter.presentations.last))
    }

    private func arrivedResponse(_ event: StarlightCelebration, receiver: CGRect? = nil,
                                 quiet: Bool = false) throws -> LanternAwardResponse {
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        return try XCTUnwrap(LanternAwardResponse(event: event, challenge: .firstLight,
            receiver: receiver ?? self.receiver,
            age: quiet ? 0 : arrival + StarlightCelebration.receiverDuration / 2, quiet: quiet))
    }

    func testCurrentSkyAwardAnswersBelowQuarterAndFullBoardAwardAnswersAcrossQuarterWithoutChangingProgress() throws {
        let openings: [(FallingSky, (Int, Int), Int, StarlightRestoration.Milestone)] = [
            (.freshChallenge(.firstLight), (8, 9), 15_000, .unrestored),
            (.fullBoardLantern(), (27, 34), 42_000, .quarter)
        ]
        for (opening, move, points, milestone) in openings {
            XCTAssertEqual(opening.challengeRevision, opening.usesFullBoardRefill ? 6 : 4)
            let (game, _, event) = try committed(opening, move: move)
            let progress = try XCTUnwrap(game.restoration)
            XCTAssertEqual(game.displayScore, points)
            XCTAssertEqual(progress.milestone, milestone)
            XCTAssertEqual(progress.fraction, Double(points) / 150_000, accuracy: 0.000001)
            let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
            XCTAssertNil(LanternAwardResponse(event: event, challenge: game.challenge, receiver: receiver,
                                              age: arrival - 0.000001, quiet: false))
            let atArrival = try XCTUnwrap(LanternAwardResponse(event: event, challenge: game.challenge,
                receiver: receiver, age: arrival, quiet: false))
            XCTAssertEqual(atArrival.apertureOpacity, 0)
            XCTAssertEqual(atArrival.haloOpacity, 0)
            let lit = try arrivedResponse(event)
            XCTAssertGreaterThan(lit.apertureOpacity, 0)
            XCTAssertGreaterThan(lit.haloOpacity, 0)
            XCTAssertEqual(game.restoration, progress)
            XCTAssertEqual(game.replay(), opening)
            XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
        }
    }

    func testOnlyPositiveLanternAwardsCanAnswerAnActualReceiver() throws {
        let (_, _, event) = try committed(.freshChallenge(.firstLight), move: (8, 9))
        let age = try XCTUnwrap(event.lastPacketArrival(toRestoration: true)) + 0.1
        for challenge in [StarfallChallenge?.none] + StarfallChallenge.allCases
            .filter({ $0 != .firstLight }).map(Optional.some) {
            XCTAssertNil(LanternAwardResponse(event: event, challenge: challenge, receiver: receiver,
                                              age: age, quiet: false))
            XCTAssertNil(LanternAwardResponse(event: event, challenge: challenge, receiver: receiver,
                                              age: 0, quiet: true))
        }
        // Value-only admission fixtures do not claim a reachable zero-award Story phase.
        let emptyPhase = SkyResolutionPhase(kind: .recipe, before: Array(repeating: nil, count: 49),
                                            cleared: [], comboDepth: 1)
        let emptyEvent = StarlightCelebration(id: 2, phase: emptyPhase, cumulativeAward: 0, total: 0)
        XCTAssertNil(emptyEvent.lastPacketArrival(toRestoration: true))
        XCTAssertNil(LanternAwardResponse(event: emptyEvent, challenge: .firstLight, receiver: receiver,
                                          age: 0.5, quiet: false))
        XCTAssertNil(LanternAwardResponse(event: emptyEvent, challenge: .firstLight, receiver: receiver,
                                          age: 0.5, quiet: true))
        var game = FallingSky.freshChallenge(.firstLight)
        let phase = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2))?.resolutionPhases.first)
        for award in [0, -1] {
            let uncredited = StarlightCelebration(id: 3, phase: phase, cumulativeAward: award, total: award)
            XCTAssertFalse(uncredited.packets.isEmpty)
            XCTAssertNil(LanternAwardResponse(event: uncredited, challenge: .firstLight,
                                              receiver: receiver, age: age, quiet: false))
        }
    }

    func testInvalidReceiverAndExpiredOrNonfiniteAgeNeverProduceSceneryResponse() throws {
        let (_, _, event) = try committed(.freshChallenge(.firstLight), move: (8, 9))
        let badRectangles: [CGRect] = [
            .zero, .null, .infinite,
            CGRect(x: CGFloat.nan, y: 10, width: 20, height: 20),
            CGRect(x: 10, y: CGFloat.infinity, width: 20, height: 20),
            CGRect(x: 10, y: 10, width: 0, height: 20),
            CGRect(x: 10, y: 10, width: 20, height: 0),
            CGRect(x: 10, y: 10, width: CGFloat.infinity, height: 20)
        ]
        for quiet in [false, true] {
            for bad in badRectangles {
                XCTAssertNil(LanternAwardResponse(event: event, challenge: .firstLight, receiver: bad,
                                                  age: 0.7, quiet: quiet))
            }
            for age in [-0.001, StarlightCelebration.duration, 99, Double.nan, .infinity, -.infinity] {
                XCTAssertNil(LanternAwardResponse(event: event, challenge: .firstLight, receiver: receiver,
                                                  age: age, quiet: quiet))
            }
        }
    }

    func testQuietResponseKeepsRegisteredApertureAndBoundedHaloAcrossAllLanternCompositions() throws {
        let (_, _, event) = try committed(.fullBoardLantern(), move: (27, 34))
        let examples: [(RestorationComposition, CGSize)] = [
            (.phone, CGSize(width: 390, height: 844)),
            (.tabletPortrait, CGSize(width: 834, height: 1194)),
            (.tabletLandscape, CGSize(width: 1194, height: 834))
        ]
        for (composition, size) in examples {
            let artwork = RestorationArtwork(challenge: .firstLight, composition: composition)
            let registered = RestorationLayout(size: size, artwork: artwork).light
            let normal = try arrivedResponse(event, receiver: registered)
            let quiet = try arrivedResponse(event, receiver: registered, quiet: true)
            XCTAssertEqual(normal.receiver, registered)
            XCTAssertEqual(normal.aperture, registered)
            XCTAssertEqual(quiet.aperture, normal.aperture)
            XCTAssertEqual(quiet.halo, normal.halo)
            XCTAssertTrue(normal.halo.contains(normal.aperture))
            XCTAssertTrue(registered.insetBy(dx: -18, dy: -18).contains(normal.halo))
            XCTAssertGreaterThan(quiet.apertureOpacity, 0)
            XCTAssertGreaterThan(quiet.haloOpacity, 0)
            XCTAssertLessThanOrEqual(quiet.apertureOpacity, 1)
            XCTAssertLessThanOrEqual(quiet.haloOpacity, 1)
            let held = try XCTUnwrap(LanternAwardResponse(event: event, challenge: .firstLight,
                receiver: registered, age: 1.3, quiet: true))
            XCTAssertEqual(held.aperture, quiet.aperture)
            XCTAssertEqual(held.halo, quiet.halo)
            XCTAssertEqual(held.apertureOpacity, quiet.apertureOpacity)
            XCTAssertEqual(held.haloOpacity, quiet.haloOpacity)
        }
    }

    @MainActor func testDrawingCurrentArrivalCannotWriteRoundOrWorldOrMoveTheRealDeadline() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        let (store, presenter, clock, defaults, counter) = try makeStore(opening)
        defer { store.setSuspended(true) }
        store.togglePause()
        clock.advance(1.25)
        let deadline = try XCTUnwrap(clock.deadline)
        let (turn, presentation) = try exchange((8, 9), in: store, presenter: presenter)
        XCTAssertEqual(turn.displayAward, 15_000)
        let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
        let worldBytes = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
        presentation.phase(turn.resolutionPhases.count - 1)
        let event = try XCTUnwrap(store.celebration)
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        for age in [arrival - 0.001, arrival, arrival + 0.16, 1.3] {
            for quiet in [false, true] {
                _ = LanternAwardResponse(event: event, challenge: store.game.challenge,
                                          receiver: receiver, age: age, quiet: quiet)
            }
        }
        let environment = RestorationEnvironment(presentation: try XCTUnwrap(
            RestorationPresentation.selected(game: committed, entry: nil)), active: true,
            ambientActive: false, quiet: false, award: event, awardQuiet: false)
        _ = try rendered(event: event, age: arrival + 0.16, quiet: false,
                         throughOverlay: false, environment: environment)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(store.game.restoration?.milestone, .unrestored)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
        XCTAssertEqual(counter.writes, writes)
        XCTAssertEqual(clock.deadline, deadline)
        XCTAssertTrue(store.busy)
        presentation.complete()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(counter.writes, writes)
        XCTAssertEqual(clock.deadline, deadline)
        XCTAssertEqual(committed.replay(), opening)
    }

    @MainActor func testReplacementSuspensionAndReplayRetireCurrentResponseAndRejectEarlierCallbacks() throws {
        for boundary in ["replacement", "suspension", "replay"] {
            let opening = FallingSky.freshChallenge(.firstLight)
            let (store, presenter, clock, defaults, counter) = try makeStore(opening)
            defer { store.setSuspended(true) }
            let (turn, old) = try exchange((8, 9), in: store, presenter: presenter)
            old.phase(turn.resolutionPhases.count - 1)
            let oldEvent = try XCTUnwrap(store.celebration)
            XCTAssertNotNil(try arrivedResponse(oldEvent))
            if boundary == "replacement" {
                old.complete()
                let (nextTurn, next) = try exchange((0, 1), in: store, presenter: presenter)
                XCTAssertNil(store.celebration)
                next.phase(nextTurn.resolutionPhases.count - 1)
                XCTAssertNotEqual(store.celebration?.id, oldEvent.id)
            } else if boundary == "suspension" { store.setSuspended(true) }
            else { store.restart(sameSky: true) }
            let current = store.celebration, game = store.game
            let bytes = defaults.data(forKey: SkySaveArchive.key)
            let worldBytes = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
            old.phase(0); old.phase(turn.resolutionPhases.count - 1); old.complete()
            XCTAssertEqual(store.celebration, current, boundary)
            XCTAssertEqual(store.game, game, boundary)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes, boundary)
            XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes, boundary)
            XCTAssertEqual(counter.writes, writes, boundary)
            XCTAssertNil(clock.deadline, boundary)
            if boundary != "replacement" { XCTAssertNil(store.celebration, boundary) }
            if boundary == "replay" { XCTAssertEqual(store.game, opening) }
        }
    }

    @MainActor func testLanternWinningActionCommitsRepairBeforeResponseAndExactReplayDiscardsIt() throws {
        let opening = FallingSky.fullBoardLantern()
        let (store, presenter, clock, defaults, counter) = try makeStore(opening)
        defer { store.setSuspended(true) }
        // Existing production Full Board witness, not a new search or aggregate save.
        let route = [(27,34), (1,2), (31,32), (12,13), (16,17),
                     (8,9), (11,12), (29,30), (29,36), (9,16)]
        var preceding: LanternResponsePresenter.Presentation?
        var last: LanternResponsePresenter.Presentation?
        for (index, move) in route.enumerated() {
            let (turn, presentation) = try exchange(move, in: store, presenter: presenter)
            if index == route.count - 1 {
                XCTAssertEqual(store.game.outcome, .won)
                XCTAssertEqual(store.game.restoration?.milestone, .complete)
                XCTAssertTrue(store.journey.journey.completed.contains(.firstLight))
                let winner = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
                let worldBytes = defaults.data(forKey: WorldJourneyStore.key), writes = counter.writes
                XCTAssertNil(store.celebration)
                preceding?.phase(0); preceding?.complete()
                XCTAssertNil(store.celebration)
                presentation.phase(turn.resolutionPhases.count - 1)
                let event = try XCTUnwrap(store.celebration)
                _ = try arrivedResponse(event)
                XCTAssertEqual(store.game, winner)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
                XCTAssertEqual(defaults.data(forKey: WorldJourneyStore.key), worldBytes)
                XCTAssertEqual(counter.writes, writes)
                XCTAssertTrue(store.busy)
                last = presentation
            } else {
                if !turn.resolutionPhases.isEmpty { presentation.phase(turn.resolutionPhases.count - 1) }
                presentation.complete()
                preceding = presentation
            }
        }
        try XCTUnwrap(last).complete()
        XCTAssertFalse(store.busy)
        store.restart(sameSky: true)
        let replayBytes = defaults.data(forKey: SkySaveArchive.key)
        XCTAssertEqual(store.game, opening)
        XCTAssertNil(store.celebration)
        last?.phase(0); last?.complete()
        XCTAssertNil(store.celebration)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), replayBytes)
        XCTAssertNil(clock.deadline)
    }

    @MainActor private func rendered(event: StarlightCelebration, age: TimeInterval, quiet: Bool,
                                     throughOverlay: Bool, challenge: StarfallChallenge? = .firstLight,
                                     exclusions: [CGRect] = [], environment: RestorationEnvironment? = nil) throws -> UIImage {
        let size = CGSize(width: 240, height: 192)
        let content = Canvas { context, canvas in
            if let environment {
                environment.drawAward(in: &context, age: age, canvasSize: canvas, receiver: self.receiver)
            } else if throughOverlay {
                let overlay = StarlightCelebrationOverlay(event: event,
                    board: CGRect(origin: .zero, size: size), score: exclusions.first ?? .zero,
                    header: exclusions.dropFirst().first ?? .zero, quiet: quiet,
                    lightDestination: self.receiver, restorationChallenge: challenge)
                overlay.drawReceiver(in: &context, age: age, canvasSize: canvas)
            } else if let response = LanternAwardResponse(event: event, challenge: challenge,
                receiver: self.receiver, age: age, quiet: quiet) {
                LanternAwardResponse.draw(in: &context, response: response,
                                          canvasSize: canvas, exclusions: exclusions)
            }
        }.frame(width: size.width, height: size.height).background(Color.black)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        return try XCTUnwrap(renderer.uiImage)
    }

    @MainActor func testRenderedApertureIsBlankBeforeArrivalWarmAfterwardAndClippedOutsideHUD() throws {
        let (_, _, event) = try committed(.freshChallenge(.firstLight), move: (8, 9))
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        let score = CGRect(x: 130, y: 78, width: 14, height: 36)
        let header = CGRect(x: 104, y: 70, width: 10, height: 48)
        let cases: [(String, TimeInterval, Bool, Bool, [CGRect])] = [
            ("before-arrival", arrival - 0.001, false, false, []),
            ("actual-arrival", arrival + 0.16, false, false, []),
            ("quiet-static", 0, true, false, []),
            ("synthetic-model-HUD-clipping", arrival + 0.16, false, true, [score, header])
        ]
        for (index, example) in cases.enumerated() {
            let image = try rendered(event: event, age: example.1, quiet: example.2,
                                     throughOverlay: false, exclusions: example.4)
            let pixels = try raster(image)
            if index == 0 { XCTAssertEqual(pixels.lit, 0) }
            else {
                XCTAssertGreaterThan(pixels.warm, 25, example.0)
                XCTAssertGreaterThan(try raster(image, crop: receiver).lit, 25, example.0)
                if example.3 {
                    for exclusion in example.4 {
                        XCTAssertEqual(try raster(image, crop: exclusion).lit, 0, example.0)
                    }
                }
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "lantern-award-\(example.0)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor func testEnvironmentOwnsArrivalBelowHeaderAndOverlayNeverDuplicatesItsResponse() throws {
        let (game, _, event) = try committed(.freshChallenge(.firstLight), move: (8, 9))
        let presentation = try XCTUnwrap(RestorationPresentation.selected(game: game, entry: nil))
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        // The header's preference bounds may cover the aperture even where the
        // actual chrome is transparent. Scenery must not use that container as
        // an exclusion mask; the foreground overlay must not draw a duplicate.
        let coveringHeader = CGRect(x: 0, y: 0, width: 240, height: 128)
        XCTAssertTrue(coveringHeader.contains(receiver))
        for quiet in [false, true] {
            let foreground = try rendered(event: event, age: quiet ? 0 : arrival + 0.16,
                quiet: quiet, throughOverlay: true, exclusions: [.zero, coveringHeader])
            XCTAssertEqual(try raster(foreground).lit, 0, "Lantern's response has exactly one scenery owner")
        }
        let cases: [(String, TimeInterval, Bool, Bool, Bool, Bool?, Bool, StarfallChallenge, Bool)] = [
            ("before-arrival", arrival - 0.001, true, true, false, nil, true, .firstLight, false),
            ("arrived", arrival + 0.16, true, true, false, nil, true, .firstLight, true),
            ("ambient-paused", arrival + 0.16, true, false, false, nil, true, .firstLight, true),
            ("inactive", arrival + 0.16, false, true, false, nil, true, .firstLight, false),
            ("no-current-award", arrival + 0.16, true, true, false, nil, false, .firstLight, false),
            ("other-location", arrival + 0.16, true, true, false, nil, true, .kiteHarbor, false),
            ("transparency-before-arrival", 0, true, true, true, false, true, .firstLight, false),
            ("transparency-after-arrival", arrival + 0.16, true, true, true, false, true, .firstLight, true),
            ("actual-calm-static", 0, true, false, true, true, true, .firstLight, true),
            ("expired", StarlightCelebration.duration, true, true, false, nil, true, .firstLight, false)
        ]
        for example in cases {
            let selected = RestorationPresentation(challenge: example.7, progress: presentation.progress)
            let environment = RestorationEnvironment(presentation: selected, active: example.2,
                ambientActive: example.3, quiet: example.4, award: example.6 ? event : nil,
                awardQuiet: example.5)
            let image = try rendered(event: event, age: example.1, quiet: example.4,
                                     throughOverlay: false, environment: environment)
            let pixels = try raster(image)
            if example.8 {
                XCTAssertGreaterThan(pixels.warm, 25, example.0)
                XCTAssertGreaterThan(try raster(image, crop: receiver).lit, 25, example.0)
            } else { XCTAssertEqual(pixels.lit, 0, example.0) }
            let attachment = XCTAttachment(image: image)
            attachment.name = "lantern-scenery-owner-\(example.0)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor func testActualEnvironmentBodyWarmsRegisteredPhoneApertureWithoutChangingTheRestOfThePainting() throws {
        let size = CGSize(width: 390, height: 844), canvas = CGRect(x: 0, y: 0, width: 390, height: 844)
        var game = FallingSky.freshChallenge(.firstLight)
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
        XCTAssertEqual(game.displayScore, 15_000)
        let presentation = try XCTUnwrap(RestorationPresentation.selected(game: game, entry: nil))
        XCTAssertEqual(presentation.progress.milestone, .unrestored)
        let artwork = RestorationArtwork(challenge: .firstLight, composition: .phone)
        let registered = RestorationLayout(size: size, artwork: artwork).light
        XCTAssertTrue(canvas.contains(registered))

        func renderBody(award: StarlightCelebration?) throws -> UIImage {
            let content = RestorationEnvironment(presentation: presentation, active: true,
                ambientActive: false, quiet: true, award: award, awardQuiet: true)
                .frame(width: size.width, height: size.height)
            let renderer = ImageRenderer(content: content)
            renderer.scale = 2
            return try XCTUnwrap(renderer.uiImage)
        }
        // Decode and lay out the actual bundled paintings before creating the
        // short-lived receipt. Both renders hold ambient phase and milestone fixed.
        let baseline = try renderBody(award: nil)
        XCTAssertGreaterThan(try raster(baseline).lit, 25)
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        let event = StarlightCelebration(id: 1, phase: phase, cumulativeAward: turn.displayAward,
            total: game.displayScore, precedingPhases: Array(turn.resolutionPhases.dropLast()), started: .now)
        let response = try arrivedResponse(event, receiver: registered, quiet: true)
        let answered = try renderBody(award: event)
        XCTAssertLessThan(Date.now.timeIntervalSince(event.started), StarlightCelebration.duration,
                          "The body must be observed while its actual receipt is still live")
        let oldAperture = try rgba(baseline, crop: registered), newAperture = try rgba(answered, crop: registered)
        XCTAssertEqual(oldAperture.count, newAperture.count)
        var changed = 0, warmer = 0
        for index in stride(from: 0, to: min(oldAperture.count, newAperture.count), by: 4) {
            let red = Int(newAperture[index]) - Int(oldAperture[index])
            let green = Int(newAperture[index + 1]) - Int(oldAperture[index + 1])
            let blue = Int(newAperture[index + 2]) - Int(oldAperture[index + 2])
            if max(abs(red), abs(green), abs(blue)) > 2 { changed += 1 }
            if red > blue + 3 { warmer += 1 }
        }
        XCTAssertGreaterThan(changed, 25, "The real body Canvas must reach its registered light aperture")
        XCTAssertGreaterThan(warmer, 25, "That aperture must answer in the warm material direction")
        let affected = response.halo.insetBy(dx: -1, dy: -1).integral.intersection(canvas)
        let untouched = [
            CGRect(x: 0, y: 0, width: canvas.width, height: affected.minY),
            CGRect(x: 0, y: affected.maxY, width: canvas.width, height: canvas.maxY - affected.maxY),
            CGRect(x: 0, y: affected.minY, width: affected.minX, height: affected.height),
            CGRect(x: affected.maxX, y: affected.minY, width: canvas.maxX - affected.maxX, height: affected.height)
        ]
        for region in untouched where region.width > 0 && region.height > 0 {
            XCTAssertEqual(try rgba(baseline, crop: region), try rgba(answered, crop: region),
                           "Award response must not repaint scenery outside its bounded halo")
        }
        for (name, image) in [("baseline-no-award", baseline), ("current-quiet-award", answered)] {
            let attachment = XCTAttachment(image: image)
            attachment.name = "lantern-actual-environment-body-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor func testExistingAmbientPausedEnvironmentAdmitsAndPaintsAnActualNormalAward() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let size = CGSize(width: 390, height: 844)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        var game = FallingSky.freshChallenge(.firstLight)
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
        let presentation = try XCTUnwrap(RestorationPresentation.selected(game: game, entry: nil))
        let probe = LanternLiveResponseProbe(), sampler = LanternDisplaySampler()
        let host = UIHostingController(rootView: LanternLiveResponseView(probe: probe,
            presentation: presentation, size: size))
        window.rootViewController = host
        window.makeKeyAndVisible()
        let display = CADisplayLink(target: sampler, selector: #selector(LanternDisplaySampler.tick(_:)))
        display.add(to: .main, forMode: .common)
        defer {
            sampler.sample = nil; display.invalidate()
            window.isHidden = true; window.rootViewController = nil; previousWindow?.makeKey()
        }
        let readyDeadline = ContinuousClock.now + .seconds(3)
        while (sampler.frames < 2 || probe.registeredLight == nil) && ContinuousClock.now < readyDeadline {
            try await Task.sleep(for: .milliseconds(8))
        }
        XCTAssertGreaterThanOrEqual(sampler.frames, 2, "The visible host must receive real display frames before the receipt")
        XCTAssertNotNil(host.view.window)
        let registered = try XCTUnwrap(probe.registeredLight)
        XCTAssertTrue(window.bounds.contains(registered))
        host.view.layoutIfNeeded()
        let baselineFull = liveWindowImage(window, region: window.bounds)
        let baselineCrop = liveWindowImage(window, region: registered)
        let baseline = try rgba(baselineCrop, crop: CGRect(origin: .zero, size: baselineCrop.size))
        XCTAssertGreaterThan(try raster(baselineFull).lit, 25)

        // Do not replace the hosting root or Environment identity. Only the
        // current immutable receipt changes while its ambient timeline rests.
        let phase = try XCTUnwrap(turn.resolutionPhases.last)
        let event = StarlightCelebration(id: 91, phase: phase, cumulativeAward: turn.displayAward,
            total: game.displayScore, precedingPhases: Array(turn.resolutionPhases.dropLast()), started: .now)
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: true))
        var beforeSamples = 0, deliveredSamples = 0, warmSamples = 0
        var records: [String] = [], samplingFailure: String?
        var warmedCrop: UIImage?, warmedFull: UIImage?
        sampler.sample = {
            let began = Date.now.timeIntervalSince(event.started)
            guard began < StarlightCelebration.duration else { return }
            let image = self.liveWindowImage(window, region: registered)
            let ended = Date.now.timeIntervalSince(event.started)
            do {
                let current = try self.rgba(image, crop: CGRect(origin: .zero, size: image.size))
                guard current.count == baseline.count else {
                    samplingFailure = "Registered crop changed pixel dimensions"
                    return
                }
                var changed = 0, warmer = 0
                for index in stride(from: 0, to: current.count, by: 4) {
                    let red = Int(current[index]) - Int(baseline[index])
                    let green = Int(current[index + 1]) - Int(baseline[index + 1])
                    let blue = Int(current[index + 2]) - Int(baseline[index + 2])
                    if max(abs(red), abs(green), abs(blue)) > 2 { changed += 1 }
                    if red > blue + 3 { warmer += 1 }
                }
                records.append("display=\(sampler.frames) began=\(began) ended=\(ended) "
                    + "admitted=\(probe.admittedReceipt == event.id) changed=\(changed) warmer=\(warmer)")
                if ended < arrival {
                    beforeSamples += 1
                    XCTAssertEqual(changed, 0, "No aperture response before actual last-packet arrival: \(records.last!)")
                }
                if began >= arrival && ended <= arrival + StarlightCelebration.receiverDuration {
                    deliveredSamples += 1
                    if warmer > 25 {
                        warmSamples += 1
                        if warmedCrop == nil {
                            warmedCrop = image
                            // Capture the complete composition only after the
                            // bounded aperture sample has proved a warm response.
                            warmedFull = self.liveWindowImage(window, region: window.bounds)
                        }
                    }
                }
            } catch { samplingFailure = String(describing: error) }
        }
        probe.award = event
        let samplingDeadline = ContinuousClock.now + .seconds(1.7)
        while Date.now.timeIntervalSince(event.started) < StarlightCelebration.duration
                && ContinuousClock.now < samplingDeadline && samplingFailure == nil {
            try await Task.sleep(for: .milliseconds(8))
        }
        sampler.sample = nil
        let finalFull = liveWindowImage(window, region: window.bounds)
        let marker = CGRect(x: 4, y: size.height - 10, width: 6, height: 6)
        let actualMarker = try raster(finalFull, crop: marker).lit
        let summary = "arrival=\(arrival) receiptDuration=\(StarlightCelebration.duration) "
            + "beforeSamples=\(beforeSamples) deliveredSamples=\(deliveredSamples) warmSamples=\(warmSamples) "
            + "admitted=\(probe.admittedReceipt == event.id) markerLit=\(actualMarker) failure=\(samplingFailure ?? "none") "
            + "registered=\(registered)"
        let diagnostics = XCTAttachment(string: ([summary] + records).joined(separator: "\n"))
        diagnostics.name = "lantern-live-normal-response-samples"
        diagnostics.lifetime = .keepAlways
        add(diagnostics)
        XCTAssertNil(samplingFailure)
        XCTAssertEqual(probe.admittedReceipt, event.id, "The same hosted view must admit the new receipt")
        XCTAssertGreaterThan(actualMarker, 0, "Actual composited pixels must show the new receipt's marker")
        XCTAssertGreaterThan(beforeSamples, 0, "No pre-arrival rendered samples; inspect readiness/sample intervals: \(summary)")
        XCTAssertGreaterThan(deliveredSamples, 0, "No rendered sample wholly inside the arrival response window: \(summary)")
        XCTAssertGreaterThan(warmSamples, 0, "Actual normal Environment did not show warm response in observed delivered frames: \(summary)")
        for (name, image) in [("baseline", Optional(baselineFull)), ("warm-aperture", warmedCrop),
                              ("warm-full-composition", warmedFull), ("final-admission", Optional(finalFull))] {
            if let image {
                let attachment = XCTAttachment(image: image)
                attachment.name = "lantern-live-normal-\(name)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor private func liveWindowImage(_ window: UIWindow, region: CGRect) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        return UIGraphicsImageRenderer(size: region.size, format: format).image { context in
            context.cgContext.translateBy(x: -region.minX, y: -region.minY)
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }

    private func rgba(_ image: UIImage, crop: CGRect) throws -> [UInt8] {
        let source = try XCTUnwrap(image.cgImage)
        let cg = try XCTUnwrap(source.cropping(to: crop.applying(.init(scaleX: image.scale, y: image.scale))))
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: cg.width, height: cg.height,
            bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        return bytes
    }

    private func raster(_ image: UIImage, crop: CGRect? = nil) throws -> (lit: Int, warm: Int) {
        var cg = try XCTUnwrap(image.cgImage)
        if let crop {
            cg = try XCTUnwrap(cg.cropping(to: crop.applying(.init(scaleX: image.scale, y: image.scale))))
        }
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: cg.width, height: cg.height,
            bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        let offsets = stride(from: 0, to: bytes.count, by: 4)
        let lit = offsets.filter { max(bytes[$0], bytes[$0 + 1], bytes[$0 + 2]) > 2 }.count
        let warm = offsets.filter { Int(bytes[$0]) > Int(bytes[$0 + 2]) + 10 && bytes[$0] > 24 }.count
        return (lit, warm)
    }
}
