import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

@MainActor private final class CascadeReturnPresenter: FallingSkyPresenting {
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

final class CascadeReturnTests: XCTestCase {
    @MainActor private func makeStore(_ game: FallingSky, quiet: Bool = false)
    throws -> (FallingSkyStore, CascadeReturnPresenter, ManualRainClock, UserDefaults, SkyFeedbackRecorder) {
        let suite = "Starfall.CascadeReturn.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: defaults)
        let presenter = CascadeReturnPresenter(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        presenter.reduceMotion = quiet
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                   clock: clock, feedback: feedback)
        store.setSuspended(false)
        XCTAssertEqual(store.game, game)
        return (store, presenter, clock, defaults, feedback)
    }

    @MainActor private func perform(_ from: Cell, _ to: Cell, in store: FallingSkyStore,
                                   file: StaticString = #filePath, line: UInt = #line) throws -> FallingSkyTurn {
        let before = store.game
        var expected = before
        let turn = try XCTUnwrap(expected.nudge(from: from, to: to), file: file, line: line)
        XCTAssertTrue(store.performTechnique(.nudge(from, to), snapshot: before,
            generation: store.constellationInputGeneration), file: file, line: line)
        XCTAssertEqual(store.game, expected, file: file, line: line)
        return turn
    }

    @MainActor private func assertReceipt(_ event: StarlightCelebration, at index: Int,
                                         in phases: [SkyResolutionPhase],
                                         file: StaticString = #filePath, line: UInt = #line) {
        let phase = phases[index]
        XCTAssertEqual(event.patterns, phase.recipes.map { .init(recipe: $0) }, file: file, line: line)
        XCTAssertTrue(event.constellationPath.isEmpty, file: file, line: line)
        let prefix = phases.prefix(index).filter { $0.kind == .recipe }
            .suffix(StarlightCelebration.maximumPrecedingReturns)
        XCTAssertEqual(event.precedingReturns.map(\.depth), prefix.map(\.comboDepth), file: file, line: line)
        XCTAssertEqual(event.precedingReturns.map(\.patterns),
            prefix.map { $0.recipes.map { StarlightCelebration.Pattern(recipe: $0) } }, file: file, line: line)
        XCTAssertEqual(event.displayAward, phases.prefix(index + 1).reduce(0) { $0 + $1.award.displayPoints },
                       file: file, line: line)
        for (returned, actual) in zip(event.precedingReturns, prefix) {
            for pattern in returned.patterns {
                XCTAssertEqual(pattern.starIDs, Set(pattern.cells.compactMap {
                    actual.before[$0.row * FallingSky.side + $0.column]?.id
                }), file: file, line: line)
            }
        }
        XCTAssertEqual(event.contributors.map(\.cell), event.cells, file: file, line: line)
        XCTAssertEqual(event.contributors.reduce(0) { $0 + $1.reward }, phase.award.baseLight,
                       "Earlier figures do not emit another phase's physical light", file: file, line: line)
        XCTAssertLessThanOrEqual(event.packets.count, StarlightCelebration.maximumPackets, file: file, line: line)
    }

    @MainActor func testGenuineSkyTwoPhaseReturnKeepsBothCommittedFiguresAndTheRunningDeadline() throws {
        let opening = FallingSky.freshChallenge(.firstLight)
        XCTAssertEqual(opening.challengeRevision, 4)
        let (store, presenter, clock, defaults, feedback) = try makeStore(opening)
        defer { store.setSuspended(true) }
        store.togglePause()
        clock.advance(1.5)
        let deadline = try XCTUnwrap(clock.deadline), countdown = store.showerCountdown
        let turn = try perform(Cell(1,1), Cell(1,2), in: store)
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        XCTAssertEqual(turn.displayAward, 15_000)
        let committed = store.game, bytes = try XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))
        XCTAssertEqual(try SkySaveArchive.decode(bytes), committed)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        XCTAssertNil(store.celebration)
        for index in turn.resolutionPhases.indices {
            presentation.phase(index)
            let event = try XCTUnwrap(store.celebration)
            assertReceipt(event, at: index, in: turn.resolutionPhases)
            XCTAssertEqual(event.total, event.displayAward)
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
            XCTAssertEqual(clock.deadline, deadline)
            XCTAssertEqual(store.showerCountdown, countdown)
            XCTAssertTrue(store.busy)
        }
        XCTAssertEqual(feedback.clears, 2)
        presentation.complete()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(clock.deadline, deadline)
        XCTAssertEqual(committed.replay(), opening)
    }

    @MainActor func testGenuineRibbonFullBoardThreePhaseReturnKeepsChronologicalPrefixWithoutAClock() throws {
        let opening = FallingSky.fullBoardRibbon()
        XCTAssertEqual(opening.challengeRevision, 7)
        let (store, presenter, clock, defaults, feedback) = try makeStore(opening)
        defer { store.setSuspended(true) }
        let turn = try perform(Cell(1,1), Cell(1,2), in: store)
        XCTAssertEqual(turn.resolutionPhases.count, 3)
        let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        for index in turn.resolutionPhases.indices {
            presentation.phase(index)
            assertReceipt(try XCTUnwrap(store.celebration), at: index, in: turn.resolutionPhases)
            XCTAssertNil(clock.deadline)
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
            XCTAssertTrue(store.busy)
        }
        XCTAssertEqual(store.celebration?.precedingReturns.map(\.depth), [1, 2])
        XCTAssertEqual(feedback.clears, 3)
        presentation.complete()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(committed.replay(), opening)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(bytes)), committed)
    }

    @MainActor func testOnlyIncreasingValidPhaseCallbacksCanPublishAndSkippedPhaseKeepsActualPrefix() throws {
        let (store, presenter, clock, defaults, feedback) = try makeStore(.fullBoardRibbon())
        defer { store.setSuspended(true) }
        let turn = try perform(Cell(1,1), Cell(1,2), in: store)
        XCTAssertEqual(turn.resolutionPhases.count, 3)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
        for invalid in [-1, turn.resolutionPhases.count, Int.max] { presentation.phase(invalid) }
        XCTAssertNil(store.celebration)
        XCTAssertEqual(feedback.clears, 0)
        presentation.phase(1)
        let second = try XCTUnwrap(store.celebration)
        assertReceipt(second, at: 1, in: turn.resolutionPhases)
        for invalid in [1, 0, -1, turn.resolutionPhases.count] { presentation.phase(invalid) }
        XCTAssertEqual(store.celebration, second)
        XCTAssertEqual(feedback.clears, 1)
        presentation.phase(2)
        let third = try XCTUnwrap(store.celebration)
        assertReceipt(third, at: 2, in: turn.resolutionPhases)
        XCTAssertNotEqual(second.id, third.id)
        XCTAssertGreaterThanOrEqual(third.started, second.started)
        for invalid in [0, 1, 2, Int.min] { presentation.phase(invalid) }
        XCTAssertEqual(store.celebration, third)
        XCTAssertEqual(feedback.clears, 2)
        presentation.complete()
        presentation.phase(2)
        presentation.complete()
        XCTAssertEqual(store.celebration, third)
        XCTAssertEqual(feedback.clears, 2)
        XCTAssertFalse(store.busy)
        XCTAssertNil(clock.deadline)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
    }

    @MainActor func testQuietTwoAndThreePhaseReturnsShowTheSameFinalCausalPrefixOnce() throws {
        for opening in [FallingSky.freshChallenge(.firstLight), .fullBoardRibbon()] {
            let (store, presenter, clock, defaults, feedback) = try makeStore(opening, quiet: true)
            defer { store.setSuspended(true) }
            let turn = try perform(Cell(1,1), Cell(1,2), in: store)
            let final = try XCTUnwrap(turn.resolutionPhases.indices.last)
            let event = try XCTUnwrap(store.celebration)
            assertReceipt(event, at: final, in: turn.resolutionPhases)
            let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
            let presentation = try XCTUnwrap(presenter.presentations.last)
            for index in turn.resolutionPhases.indices { presentation.phase(index) }
            XCTAssertEqual(store.celebration, event)
            XCTAssertEqual(feedback.clears, 1)
            XCTAssertTrue(store.busy)
            presentation.complete()
            XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, committed)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
            XCTAssertNil(clock.deadline)
        }
    }

    @MainActor func testSeparateRapidActionsDoNotBecomeOneChainOrInheritEarlierReturn() throws {
        let (store, presenter, clock, defaults, feedback) = try makeStore(.freshChallenge(.firstLight))
        defer { store.setSuspended(true) }
        let initial = try perform(Cell(1,1), Cell(1,2), in: store)
        let firstPresentation = try XCTUnwrap(presenter.presentations.last)
        initial.resolutionPhases.indices.forEach(firstPresentation.phase)
        firstPresentation.complete()
        XCTAssertEqual(store.game.displayScore, 15_000)

        let line = try perform(Cell(0,0), Cell(0,1), in: store)
        XCTAssertEqual(line.displayAward, 5_000)
        XCTAssertEqual(line.resolutionPhases.count, 1)
        let linePresentation = try XCTUnwrap(presenter.presentations.last)
        linePresentation.phase(0)
        let lineEvent = try XCTUnwrap(store.celebration)
        assertReceipt(lineEvent, at: 0, in: line.resolutionPhases)
        XCTAssertEqual(lineEvent.level, .recipe(.line))
        XCTAssertTrue(lineEvent.precedingReturns.isEmpty)
        linePresentation.complete()

        // No sleep or presentation expiry separates these committed decisions.
        let square = try perform(Cell(0,5), Cell(1,5), in: store)
        XCTAssertEqual(square.displayAward, 5_000)
        XCTAssertEqual(square.resolutionPhases.count, 1)
        let squarePresentation = try XCTUnwrap(presenter.presentations.last)
        squarePresentation.phase(0)
        let squareEvent = try XCTUnwrap(store.celebration)
        assertReceipt(squareEvent, at: 0, in: square.resolutionPhases)
        XCTAssertEqual(squareEvent.level, .recipe(.square))
        XCTAssertTrue(squareEvent.precedingReturns.isEmpty)
        XCTAssertNotEqual(lineEvent.id, squareEvent.id)
        firstPresentation.phase(1); firstPresentation.complete()
        linePresentation.phase(0); linePresentation.complete()
        XCTAssertEqual(store.celebration, squareEvent)
        XCTAssertTrue(store.busy)
        squarePresentation.complete()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(feedback.clears, 4)
        XCTAssertEqual(store.game.displayScore, 25_000)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testTwoSimultaneousPracticeSquaresStayOnePhaseAndNeverWriteTheRetainedRound() throws {
        let retained = FallingSky.fullBoardLantern()
        let suite = "Starfall.CascadeReturn.Practice.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(retained, to: defaults)
        let bytes = defaults.data(forKey: SkySaveArchive.key)
        let presenter = CascadeReturnPresenter(), clock = ManualRainClock()
        var writes = 0
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock,
            tutorial: .fullBoardImmediate, archiveWriter: { _, _ in writes += 1 })
        store.setSuspended(false)
        defer { store.setSuspended(true) }
        var expected = SkyTutorial.fullBoardImmediate.game()
        let turn = try XCTUnwrap(SkyTutorial.fullBoardImmediate.actions.first?.perform(in: &expected))
        XCTAssertEqual(turn.resolutionPhases.count, 1)
        let action = try XCTUnwrap(store.tutorial?.next)
        guard case .swap(let from, let to) = action else { return XCTFail("Comparison retains its actual exchange") }
        XCTAssertTrue(store.requestInput(.swap(from, to), snapshot: store.game,
                                        generation: store.constellationInputGeneration))
        let presentation = try XCTUnwrap(presenter.presentations.last)
        presentation.phase(0)
        let event = try XCTUnwrap(store.celebration)
        assertReceipt(event, at: 0, in: turn.resolutionPhases)
        XCTAssertEqual(event.patterns.map(\.shape), [.square, .square])
        XCTAssertTrue(event.patterns[0].starIDs.isDisjoint(with: event.patterns[1].starIDs))
        XCTAssertTrue(event.precedingReturns.isEmpty)
        XCTAssertEqual(store.game, expected)
        presentation.complete()
        XCTAssertEqual(writes, 0)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), retained)
        XCTAssertNil(clock.deadline)
    }

    @MainActor func testExpiredEarlierReceiptDoesNotFinishGameplayOrEraseTheLaterActualPrefix() async throws {
        let (store, presenter, clock, defaults, feedback) = try makeStore(.freshChallenge(.firstLight))
        defer { store.setSuspended(true) }
        let turn = try perform(Cell(1,1), Cell(1,2), in: store)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        presentation.phase(0)
        let earlierID = try XCTUnwrap(store.celebration).id
        let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
        let deadline = ContinuousClock.now + .seconds(3)
        while store.celebration != nil && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertNil(store.celebration)
        XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        XCTAssertNil(clock.deadline)
        presentation.phase(1)
        let later = try XCTUnwrap(store.celebration)
        XCTAssertNotEqual(later.id, earlierID)
        assertReceipt(later, at: 1, in: turn.resolutionPhases)
        XCTAssertEqual(feedback.clears, 2)
        XCTAssertTrue(store.busy)
        presentation.complete()
        XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, committed)
    }

    @MainActor func testInterruptionRetiresWholeCascadeAndRejectsAllLatePhasesWithoutReawarding() throws {
        for boundary in ["background", "motion", "geometry", "replay"] {
            let opening = FallingSky.fullBoardRibbon()
            let (store, presenter, clock, defaults, feedback) = try makeStore(opening)
            defer { store.setSuspended(true) }
            let turn = try perform(Cell(1,1), Cell(1,2), in: store)
            let presentation = try XCTUnwrap(presenter.presentations.last)
            presentation.phase(0); presentation.phase(1)
            XCTAssertEqual(store.celebration?.precedingReturns.count, 1, boundary)
            switch boundary {
            case "background": store.setSuspended(true)
            case "motion": store.setReducedMotion(true)
            case "geometry": store.settlePresentation(reason: "cascade-test-layout")
            default: store.restart(sameSky: true)
            }
            let game = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
            XCTAssertNil(store.celebration, boundary)
            XCTAssertFalse(store.busy, boundary)
            turn.resolutionPhases.indices.forEach(presentation.phase)
            presentation.complete()
            XCTAssertNil(store.celebration, boundary)
            XCTAssertEqual(feedback.clears, 2, boundary)
            XCTAssertEqual(store.game, game, boundary)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes, boundary)
            XCTAssertNil(clock.deadline, boundary)
            if boundary == "replay" { XCTAssertEqual(game, opening) }
        }
    }

    @MainActor func testBackgroundDuringCascadePreservesRealRemainingTimeAndCommittedArchive() throws {
        let (store, presenter, clock, defaults, feedback) = try makeStore(.freshChallenge(.firstLight))
        defer { store.setSuspended(true) }
        store.togglePause()
        clock.advance(1.25)
        let remaining = store.showerCountdown.remaining
        let turn = try perform(Cell(1,1), Cell(1,2), in: store)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        presentation.phase(1)
        assertReceipt(try XCTUnwrap(store.celebration), at: 1, in: turn.resolutionPhases)
        let committed = store.game, bytes = defaults.data(forKey: SkySaveArchive.key)
        store.setSuspended(true)
        clock.advance(100)
        presentation.phase(0); presentation.phase(1); presentation.complete()
        XCTAssertNil(store.celebration)
        XCTAssertFalse(store.busy)
        XCTAssertEqual(feedback.clears, 1)
        XCTAssertEqual(store.game, committed)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
        store.setSuspended(false)
        XCTAssertEqual(try XCTUnwrap(clock.deadline) - clock.now, remaining, accuracy: 0.000001)
        XCTAssertEqual(store.game, committed)
        XCTAssertNil(store.celebration)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), bytes)
    }

    @MainActor func testFinalActionWinsBeforeEitherReturnAndExactReplayRejectsOldCascade() throws {
        let opening = FallingSky.freshChallenge(.silverPools)
        let (store, presenter, clock, defaults, feedback) = try makeStore(opening)
        defer { store.setSuspended(true) }
        let turn = try perform(Cell(1,2), Cell(1,3), in: store)
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        XCTAssertEqual(store.game.outcome, .won)
        XCTAssertEqual(store.game.displayScore, 19_000)
        let winner = store.game, winnerBytes = defaults.data(forKey: SkySaveArchive.key)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), winner)
        let presentation = try XCTUnwrap(presenter.presentations.last)
        for index in turn.resolutionPhases.indices {
            presentation.phase(index)
            assertReceipt(try XCTUnwrap(store.celebration), at: index, in: turn.resolutionPhases)
            XCTAssertEqual(store.game, winner)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), winnerBytes)
            XCTAssertTrue(store.busy)
            XCTAssertNil(clock.deadline)
        }
        presentation.complete()
        XCTAssertFalse(store.busy)
        store.restart(sameSky: true)
        let replayBytes = defaults.data(forKey: SkySaveArchive.key)
        XCTAssertEqual(store.game, opening)
        XCTAssertNil(store.celebration)
        presentation.phase(0); presentation.phase(1); presentation.complete()
        XCTAssertEqual(feedback.clears, 2)
        XCTAssertEqual(store.game, opening)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), replayBytes)
        XCTAssertNil(store.celebration)
    }

    @MainActor private func ribbonPhases() throws -> [SkyResolutionPhase] {
        var game = FallingSky.fullBoardRibbon()
        let phases = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2))).resolutionPhases
        XCTAssertEqual(phases.count, 3)
        return phases
    }

    @MainActor private func finalReceipt(_ phases: [SkyResolutionPhase]) throws -> StarlightCelebration {
        let phase = try XCTUnwrap(phases.last)
        let award = phases.reduce(0) { $0 + $1.award.displayPoints }
        return .init(id: 1, phase: phase, cumulativeAward: award, total: award,
                     precedingPhases: Array(phases.dropLast()))
    }

    @MainActor func testBoundedPresentationPrefixKeepsLastTwoActualRecipePathsAndExcludesManualOrFutureDepths() throws {
        let source = try XCTUnwrap(ribbonPhases().first)
        // This value-only resource-bound fixture reuses actual recipe identities
        // at synthetic depths. It does not claim a reachable six-phase history.
        let phases = (1...6).map { depth in
            SkyResolutionPhase(kind: .recipe, before: source.before, cleared: source.cleared,
                               recipes: source.recipes, comboDepth: depth)
        }
        let manual = SkyResolutionPhase(kind: .manual, before: source.before, cleared: source.cleared,
                                        comboDepth: 1)
        let current = phases[4]
        let event = StarlightCelebration(id: 1, phase: current, cumulativeAward: 1, total: 1,
            precedingPhases: [manual] + Array(phases.prefix(4)) + [phases[4], phases[5]])
        XCTAssertEqual(StarlightCelebration.maximumPrecedingReturns, 2)
        XCTAssertEqual(event.precedingReturns.map(\.depth), [3, 4])
        XCTAssertEqual(event.precedingReturns.map(\.patterns),
            [phases[2], phases[3]].map { $0.recipes.map { StarlightCelebration.Pattern(recipe: $0) } })
        XCTAssertEqual(event.patterns, current.recipes.map { .init(recipe: $0) })
        XCTAssertEqual(event.packets.count, min(source.cleared.count, StarlightCelebration.maximumPackets))

        let sourceGame = ConstellationFixture.singleGap.game()
        let walk = [0, 1, 2, 3, 5].map { Cell(0,$0) }
        var drawnGame = sourceGame
        let drawnTurn = try XCTUnwrap(drawnGame.clearConstellation(walk))
        let drawn = try XCTUnwrap(StarlightCelebration(id: 2, turn: drawnTurn, from: sourceGame,
            total: drawnGame.displayScore, path: walk))
        XCTAssertEqual(drawn.constellationPath, walk)
        XCTAssertTrue(drawn.precedingReturns.isEmpty)
        XCTAssertTrue(drawn.patterns.isEmpty)
    }

    @MainActor func testChronologicalSlotsKeepEachExactTopologyAndReserveSeparateLabelAndHUDSpace() throws {
        let phases = try ribbonPhases(), event = try finalReceipt(phases)
        let examples: [(CGRect, CGRect, CGRect?)] = [
            (CGRect(x: 0, y: 0, width: 390, height: 844), CGRect(x: 20, y: 20, width: 350, height: 96), nil),
            (CGRect(x: 0, y: 0, width: 834, height: 1194), CGRect(x: 24, y: 24, width: 786, height: 88), nil),
            (CGRect(x: 0, y: -140, width: 390, height: 900), CGRect(x: 20, y: 20, width: 350, height: 96),
             CGRect(x: 20, y: 124, width: 350, height: 80)),
            // Actual 3x hosted reading coordinates retain the full-height band's
            // edges without recentering through a rounded midpoint.
            (CGRect(x: 0, y: 61.66666666666663, width: 1024, height: 1285.3333333333335),
             CGRect(x: 12, y: 51, width: 1000, height: 158.66666666666666),
             CGRect(x: 0, y: 217.66666666666666, width: 1024, height: 79.99999999999997))
        ]
        for (board, header, protectedSky) in examples {
            let award = protectedSky == nil
                ? StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: false)
                : CGRect(x: 20, y: 212, width: 350, height: 64)
            let layout = try XCTUnwrap(CascadeReturnLayout(event: event, board: board, header: header,
                                                           award: award, protectedSky: protectedSky))
            let slots = layout.preceding + [layout.current]
            XCTAssertEqual(slots.count, 3)
            XCTAssertEqual(layout.chevrons.count, 2)
            for (index, slot) in slots.enumerated() {
                let patterns = phases[index].recipes.map { StarlightCelebration.Pattern(recipe: $0) }
                let original = try XCTUnwrap(PatternReturnLayout(patterns: patterns, board: board,
                    header: header, award: award, protectedSky: protectedSky))
                if let protectedSky {
                    XCTAssertTrue(protectedSky.contains(original.skyBounds),
                                  "The single-figure fit must remain contained before fitting the cascade strip")
                }
                XCTAssertEqual(slot.patterns, patterns)
                XCTAssertEqual(slot.sourcePaths, original.sourcePaths,
                               "A prior return retains its own phase's pre-clear coordinates")
                XCTAssertEqual(slot.starCells, original.starCells)
                XCTAssertEqual(slot.sourcePaths.map(\.count), slot.destinationPaths.map(\.count))
                XCTAssertEqual(slot.labelBounds, layout.labelBounds)
                XCTAssertFalse(slot.skyBounds.intersects(header))
                XCTAssertFalse(slot.skyBounds.intersects(layout.labelBounds))
                if let protectedSky { XCTAssertTrue(protectedSky.contains(slot.skyBounds)) }
                for path in slot.destinationPaths {
                    XCTAssertTrue(path.allSatisfy(slot.skyBounds.contains))
                    XCTAssertTrue(path.allSatisfy { !header.contains($0) && !layout.labelBounds.contains($0) })
                }
                if index > 0 {
                    XCTAssertLessThan(slots[index - 1].skyBounds.maxX, slot.skyBounds.minX)
                    XCTAssertFalse(slots[index - 1].skyBounds.intersects(slot.skyBounds))
                }
            }
            for (index, chevron) in layout.chevrons.enumerated() {
                XCTAssertEqual(chevron.count, 3)
                XCTAssertTrue(chevron.allSatisfy {
                    $0.x > slots[index].skyBounds.maxX && $0.x < slots[index + 1].skyBounds.minX
                })
                XCTAssertTrue(chevron.allSatisfy { !header.contains($0) && !layout.labelBounds.contains($0) })
            }
            XCTAssertEqual(layout.current.points(at: 0), layout.current.sourcePaths)
            XCTAssertEqual(layout.current.points(at: 0, quiet: true),
                           layout.current.points(at: ConstellationReturnLayout.arrivalTime))
        }
    }

    @MainActor func testUnchainedAndSimultaneousRecipesRetainTheirExistingFitWithoutFalseChevron() throws {
        var game = SkyTutorial.fullBoardImmediate.game()
        let turn = try XCTUnwrap(SkyTutorial.fullBoardImmediate.actions.first?.perform(in: &game))
        let phase = try XCTUnwrap(turn.resolutionPhases.first)
        let event = StarlightCelebration(id: 1, phase: phase, cumulativeAward: turn.displayAward,
                                        total: game.displayScore)
        let board = CGRect(x: 0, y: 0, width: 390, height: 844)
        let header = CGRect(x: 20, y: 20, width: 350, height: 96)
        let award = StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: false)
        let original = try XCTUnwrap(PatternReturnLayout(patterns: event.patterns, board: board,
                                                        header: header, award: award))
        let layout = try XCTUnwrap(CascadeReturnLayout(event: event, board: board, header: header, award: award))
        XCTAssertTrue(layout.preceding.isEmpty)
        XCTAssertTrue(layout.chevrons.isEmpty)
        XCTAssertEqual(layout.current.sourcePaths, original.sourcePaths)
        XCTAssertEqual(layout.current.destinationPaths, original.destinationPaths)
        XCTAssertEqual(layout.current.skyBounds, original.skyBounds)
        XCTAssertEqual(layout.current.labelBounds, original.labelBounds)
        XCTAssertEqual(layout.current.patterns.count, 2)
    }

    @MainActor func testReceiverAcknowledgesOnlyActualActivePacketArrivalAndQuietShowsSameStaticReceipt() throws {
        let phases = try ribbonPhases()
        let activeOnly = StarlightCelebration(id: 1, phase: phases[2], cumulativeAward: 1, total: 1)
        let chained = try finalReceipt(phases)
        XCTAssertEqual(chained.packets, activeOnly.packets)
        for restoration in [false, true] {
            let flight = StarlightCelebration.packetFlight(toRestoration: restoration)
            let arrival = try XCTUnwrap(chained.lastPacketArrival(toRestoration: restoration))
            XCTAssertEqual(arrival, flight.arrivalTime(packetIndex: chained.packets.count - 1))
            XCTAssertEqual(chained.lastPacketArrival(toRestoration: restoration),
                           activeOnly.lastPacketArrival(toRestoration: restoration))
            XCTAssertNil(chained.receiverProgress(at: arrival - 0.000001, toRestoration: restoration))
            XCTAssertEqual(chained.receiverProgress(at: arrival, toRestoration: restoration), 0)
            XCTAssertGreaterThan(try XCTUnwrap(chained.receiverProgress(at: arrival + 0.16,
                                                                       toRestoration: restoration)), 0)
            let finished = arrival + StarlightCelebration.receiverDuration + 4 * arrival.ulp
            XCTAssertEqual(chained.receiverProgress(at: finished, toRestoration: restoration), 1)
            XCTAssertNil(chained.receiverProgress(at: StarlightCelebration.duration,
                                                  toRestoration: restoration))
            XCTAssertNil(chained.receiverProgress(at: -.infinity, toRestoration: restoration))
            XCTAssertNil(chained.receiverProgress(at: .nan, toRestoration: restoration))
            XCTAssertEqual(chained.receiverProgress(at: 0, toRestoration: restoration, quiet: true), 1)
            XCTAssertEqual(chained.receiverProgress(at: 1.3, toRestoration: restoration, quiet: true), 1)
            XCTAssertNil(chained.receiverProgress(at: -0.01, toRestoration: restoration, quiet: true))
            XCTAssertNil(chained.receiverProgress(at: StarlightCelebration.duration,
                                                  toRestoration: restoration, quiet: true))
        }
    }

    @MainActor func testRenderedChronologicalFiguresRemainVisibleAndOnlyArrivedPacketsLightTheReceiver() async throws {
        let event = try finalReceipt(ribbonPhases())
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let host = UIHostingController(rootView: AnyView(Color.black))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previousWindow?.makeKey() }
        let board = window.bounds, header = CGRect(x: 20, y: 20, width: 350, height: 96)
        let score = CGRect(x: 284, y: 30, width: 70, height: 32)
        let award = StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: false)
        let layout = try XCTUnwrap(CascadeReturnLayout(event: event, board: board, header: header, award: award))
        XCTAssertEqual(layout.preceding.count, 2)
        let arrival = try XCTUnwrap(event.lastPacketArrival(toRestoration: false))
        let examples: [(String, Double, Bool, Bool)] = [
            ("early-prior-figures", 0.3, false, false),
            ("arrived-three-figures", 0.98, false, false),
            ("quiet-same-three-figures", 0.3, true, false),
            ("receiver-before-arrival", arrival - 0.000001, false, true),
            ("receiver-actual-arrival", arrival + StarlightCelebration.receiverDuration / 2, false, true),
            ("receiver-quiet-static", 0.3, true, true)
        ]
        let marker = CGRect(x: 4, y: 834, width: 6, height: 6)
        let figureRegion = CGRect(x: 0, y: 0, width: 390, height: 828)
        for (index, example) in examples.enumerated() {
            let overlay = StarlightCelebrationOverlay(event: event, board: board, score: score,
                                                      header: header, quiet: example.2)
            let markerLit = index.isMultiple(of: 2)
            host.rootView = AnyView(Canvas { context, size in
                if example.3 { overlay.drawReceiver(in: &context, age: example.1, canvasSize: size) }
                else { overlay.drawCascade(in: &context, layout: layout, age: example.1, canvasSize: size) }
                context.fill(Path(marker), with: .color(markerLit ? .white : .black))
            }.background(Color.black).ignoresSafeArea().id(example.0))
            let expectsInk = index != 3
            var rendered: UIImage?
            var ready = false
            let deadline = ContinuousClock.now + .milliseconds(900)
            repeat {
                await Task.yield()
                host.view.layoutIfNeeded()
                rendered = windowImage(window)
                let image = try XCTUnwrap(rendered)
                let markerInk = try ink(in: image, region: marker)
                let figureInk = try ink(in: image, region: figureRegion)
                ready = (markerLit ? markerInk > 0 : markerInk == 0)
                    && (expectsInk ? figureInk > 25 : figureInk == 0)
                if !ready { try await Task.sleep(for: .milliseconds(20)) }
            } while !ready && ContinuousClock.now < deadline
            XCTAssertTrue(ready, example.0)
            let image = try XCTUnwrap(rendered)
            if !example.3 {
                for previous in layout.preceding {
                    XCTAssertGreaterThan(try ink(in: image, region: previous.skyBounds), 25,
                                         "Every preceding committed figure stays visible: \(example.0)")
                }
                if index > 0 {
                    XCTAssertGreaterThan(try ink(in: image, region: layout.current.skyBounds), 25, example.0)
                }
                for points in layout.chevrons {
                    let x = points.map(\.x), y = points.map(\.y)
                    let region = CGRect(x: x.min()! - 1, y: y.min()! - 1,
                                        width: x.max()! - x.min()! + 2, height: y.max()! - y.min()! + 2)
                    XCTAssertGreaterThan(try ink(in: image, region: region), 0, example.0)
                }
                for exclusion in [score, header, layout.labelBounds] {
                    XCTAssertEqual(try ink(in: image, region: exclusion), 0, example.0)
                }
            } else if index > 3 {
                XCTAssertGreaterThan(try ink(in: image, region: score.insetBy(dx: -18, dy: -14)), 25, example.0)
                XCTAssertEqual(try ink(in: image, region: score.insetBy(dx: 8, dy: 8)), 0,
                               "Receiver acknowledgement leaves the exact score's interior clear")
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "cascade-return-\(example.0)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    @MainActor private func windowImage(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        return UIGraphicsImageRenderer(bounds: window.bounds, format: format).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    private func ink(in image: UIImage, region: CGRect) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        let pixelsRegion = region.applying(CGAffineTransform(scaleX: image.scale, y: image.scale))
        let crop = try XCTUnwrap(cg.cropping(to: pixelsRegion))
        var pixels = [UInt8](repeating: 0, count: crop.width * crop.height * 4)
        let context = try XCTUnwrap(CGContext(data: &pixels, width: crop.width, height: crop.height,
            bitsPerComponent: 8, bytesPerRow: crop.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(crop, in: CGRect(x: 0, y: 0, width: crop.width, height: crop.height))
        return stride(from: 0, to: pixels.count, by: 4).filter {
            max(pixels[$0], pixels[$0 + 1], pixels[$0 + 2]) > 2
        }.count
    }
}
