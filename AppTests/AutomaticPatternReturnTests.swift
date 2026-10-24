import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

@MainActor private final class PatternPhasePresenter: FallingSkyPresenting {
    var reduceMotion = false
    var phases: [(Int) -> Void] = []
    var completions: [() -> Void] = []
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) { completions.append(completion) }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        phases.append(phaseBegan); completions.append(completion)
    }
}

final class AutomaticPatternReturnTests: XCTestCase {
    /// Geometry fixtures run the unchanged production resolver. They establish
    /// simultaneous topology/resource behavior, not reachable saved histories.
    private func board(_ rows: [String]) -> [StarfallGem?] {
        let kinds: [Character: Jewel] = ["A": .aqua, "R": .rose, "V": .violet, "M": .mint, "Y": .amber]
        var result = Array<StarfallGem?>(repeating: nil, count: 49)
        var id = 0
        for (row, text) in rows.enumerated() {
            for (column, symbol) in text.enumerated() where symbol != "." {
                result[row * 7 + column] = .init(id: id, kind: kinds[symbol]!)
                id += 1
            }
        }
        return result
    }

    private func receipt(_ phase: SkyResolutionPhase, id: UInt64 = 1) -> StarlightCelebration {
        StarlightCelebration(id: id, phase: phase, cumulativeAward: phase.award.displayPoints,
                            total: phase.award.displayPoints)
    }

    private func assertActualRecipes(_ event: StarlightCelebration, phase: SkyResolutionPhase,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(event.constellationPath.isEmpty, file: file, line: line)
        XCTAssertEqual(event.patterns.count, phase.recipes.count, file: file, line: line)
        for (pattern, actual) in zip(event.patterns, phase.recipes) {
            XCTAssertEqual(pattern.shape, actual.shape, file: file, line: line)
            XCTAssertEqual(pattern.cells, actual.cells, file: file, line: line)
            XCTAssertEqual(pattern.path, actual.presentationPath, file: file, line: line)
            XCTAssertEqual(pattern.starIDs, actual.starIDs, file: file, line: line)
            XCTAssertEqual(pattern.starIDs, Set(pattern.cells.compactMap {
                phase.before[$0.row * 7 + $0.column]?.id
            }), file: file, line: line)
        }
        XCTAssertEqual(Set(event.patterns.flatMap(\.cells)), phase.cleared, file: file, line: line)
        XCTAssertEqual(event.contributors.reduce(0) { $0 + $1.reward }, phase.award.baseLight, file: file, line: line)
        XCTAssertLessThanOrEqual(event.packets.count, StarlightCelebration.maximumPackets, file: file, line: line)
    }

    @MainActor func testProductionFallingSkyAndBothFullBoardLocationsRetainEveryCommittedPhase() throws {
        let openings = [FallingSky.freshChallenge(.firstLight), .freshChallenge(.ribbonCrossing),
                        .fullBoardLantern(), .fullBoardRibbon(),
                        FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 5)))]
        for opening in openings {
            var game = opening
            let turn = try XCTUnwrap(game.nudge(from: Cell(1,1), to: Cell(1,2)))
            XCTAssertFalse(turn.resolutionPhases.isEmpty)
            var accumulated = 0
            for (index, phase) in turn.resolutionPhases.enumerated() {
                accumulated += phase.award.displayPoints
                let event = StarlightCelebration(id: UInt64(index), phase: phase,
                                                cumulativeAward: accumulated, total: game.displayScore)
                assertActualRecipes(event, phase: phase)
                XCTAssertEqual(event.displayAward, accumulated)
                XCTAssertEqual(event.total, game.displayScore)
                if index > 0 { XCTAssertEqual(event.level, .cascade(index + 1)) }
            }
            XCTAssertEqual(accumulated, turn.displayAward)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(try SkySaveArchive.decode(SkySaveArchive.encode(game)), game)
            XCTAssertEqual(game.replay(), opening, "The return does not choose another content revision or supply")
        }
    }

    @MainActor func testActualFullBoardComparisonPreservesBothDisjointSquares() throws {
        var game = SkyTutorial.fullBoardImmediate.game()
        let turn = try XCTUnwrap(SkyTutorial.fullBoardImmediate.actions.first?.perform(in: &game))
        let phase = try XCTUnwrap(turn.resolutionPhases.first)
        XCTAssertEqual(phase.recipes.map(\.shape), [.square, .square])
        XCTAssertTrue(phase.recipes[0].starIDs.isDisjoint(with: phase.recipes[1].starIDs))
        let event = receipt(phase)
        assertActualRecipes(event, phase: phase)
        XCTAssertEqual(event.patterns.count, 2)
        XCTAssertEqual(event.patterns.flatMap(\.path).count, 10)
        XCTAssertEqual(Set(event.patterns.flatMap(\.cells)).count, 8)
    }

    @MainActor func testSquareCrossCurrentFourThroughSevenAndRetainedSevenKeepTheirExactTopology() throws {
        let figures: [([String], Int?, StarRecipe.Shape, Int)] = [
            (["AA.....", "AA....."], 4, .square, 4),
            ([".A.....", "AAA....", ".A....."], 4, .cross, 5)
        ] + (4...7).map { ([String(repeating: "A", count: $0)], Optional(4), .line, $0) }
          + [(["AAAAAAA"], 7, .line, 7)]
        for (rows, lineLength, shape, count) in figures {
            let phase = try XCTUnwrap(SkyRecipeResolution.resolve(board(rows), lineLength: lineLength).first)
            let event = receipt(phase)
            assertActualRecipes(event, phase: phase)
            let pattern = try XCTUnwrap(event.patterns.first)
            XCTAssertEqual(event.patterns.count, 1)
            XCTAssertEqual(pattern.shape, shape)
            XCTAssertEqual(pattern.cells.count, count)
            if shape == .square {
                XCTAssertEqual(pattern.path.first, pattern.path.last)
                XCTAssertEqual(pattern.path.count, 5)
            } else if shape == .cross {
                XCTAssertEqual(pattern.path.count, 8)
                XCTAssertEqual(pattern.path.filter { $0 == Cell(1,1) }.count, 4)
            } else { XCTAssertEqual(pattern.path, pattern.cells) }
        }
        XCTAssertTrue(SkyRecipeResolution.resolve(board(["AAAAAA"]), lineLength: 7).isEmpty,
                      "A retained six-star near-line must not acquire a current four-star return")
    }

    @MainActor func testOverlappingSquareAndLinesKeepAllOutlinesAndSpendThePhysicalUnionOnce() throws {
        let phase = try XCTUnwrap(SkyRecipeResolution.resolve(
            board(["AAAA...", "AA.....", "A......", "A......"]), lineLength: 4).first)
        let event = receipt(phase)
        assertActualRecipes(event, phase: phase)
        XCTAssertEqual(event.patterns.map(\.shape), [.square, .line, .line])
        XCTAssertEqual(event.patterns.reduce(0) { $0 + $1.cells.count }, 12)
        XCTAssertEqual(Set(event.patterns.flatMap(\.starIDs)).count, 8)
        XCTAssertEqual(event.collected, 8)
        XCTAssertEqual(event.displayAward, 13_000)
        let layout = try makeLayout(event.patterns)
        XCTAssertEqual(layout.starCells.count, 8)
        XCTAssertEqual(layout.sourcePaths.count, 3)
        for index in event.patterns.indices {
            XCTAssertEqual(layout.sourcePaths[index].count, event.patterns[index].path.count)
        }
        let shared = Cell(0,0)
        let points = zip(event.patterns, layout.destinationPaths).flatMap { pattern, path in
            zip(pattern.path, path).filter { $0.0 == shared }.map(\.1)
        }
        XCTAssertGreaterThan(points.count, 2)
        XCTAssertTrue(points.allSatisfy { $0 == points.first })
    }

    @MainActor func testDenseProductionResolverKeepsAllSeventyFiveRecipesBeyondManualWalkBudget() throws {
        let phases = SkyRecipeResolution.resolve(board(Array(repeating: "AAAAAAA", count: 7)), lineLength: 4)
        let phase = try XCTUnwrap(phases.first)
        XCTAssertEqual(phases.count, 1)
        XCTAssertEqual(phase.recipes.filter { $0.shape == .square }.count, 36)
        XCTAssertEqual(phase.recipes.filter { $0.shape == .cross }.count, 25)
        XCTAssertEqual(phase.recipes.filter { $0.shape == .line }.count, 14)
        let event = receipt(phase)
        assertActualRecipes(event, phase: phase)
        XCTAssertEqual(event.patterns.count, 75)
        XCTAssertEqual(event.patterns.flatMap(\.path).count, 478)
        XCTAssertGreaterThan(event.patterns.flatMap(\.path).count, ConstellationReturnLayout.maximumWalkEntries)
        let layout = try makeLayout(event.patterns)
        XCTAssertEqual(layout.patterns.count, 75)
        XCTAssertEqual(layout.sourcePaths.flatMap { $0 }.count, 478)
        XCTAssertEqual(layout.destinationPaths.flatMap { $0 }.count, 478)
        XCTAssertEqual(layout.starCells.count, 49)
        XCTAssertEqual(layout.starCells, (0..<49).map { Cell($0 / 7, $0 % 7) })
        XCTAssertLessThanOrEqual(event.patterns.count, PatternReturnLayout.maximumPatterns)
        XCTAssertTrue(layout.patterns.allSatisfy { $0.path.count <= PatternReturnLayout.maximumPathEntries })
    }

    @MainActor func testRetainedManualPhaseAndAutomaticFollowupAreClassifiedByCommittedAction() throws {
        let selected = Set((0..<5).map { Cell(0,$0) })
        let phases = SkyRecipeResolution.resolve(board(["AAAAARR", ".....RR"]), manualClear: selected)
        XCTAssertEqual(phases.map(\.kind), [.manual, .recipe])
        XCTAssertTrue(receipt(phases[0]).patterns.isEmpty,
                      "A manual clear in retained revision-two resolution is not an automatic figure")
        assertActualRecipes(receipt(phases[1]), phase: phases[1])
        XCTAssertEqual(receipt(phases[1]).patterns.map(\.shape), [.square])

        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight, revision: 2)))
        var game = retained
        let turn = try XCTUnwrap(game.clear(Cell(0,0)))
        XCTAssertEqual(turn.resolutionPhases.first?.kind, .manual)
        XCTAssertTrue(receipt(try XCTUnwrap(turn.resolutionPhases.first)).patterns.isEmpty)
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.replay(), retained)
    }

    @MainActor func testOpenSkyManualWalkAndDirectRecipeKeepDifferentReturnIdentity() throws {
        let source = ConstellationFixture.singleGap.game(), walk = [0,1,2,3,5].map { Cell(0,$0) }
        var manual = source
        let turn = try XCTUnwrap(manual.clearConstellation(walk))
        let drawn = try XCTUnwrap(StarlightCelebration(id: 1, turn: turn, from: source,
                                                     total: manual.displayScore, path: walk))
        XCTAssertEqual(drawn.constellationPath, walk)
        XCTAssertTrue(drawn.patterns.isEmpty)

        var old = SkyTutorial.square.game()
        XCTAssertNotNil(SkyLesson.square.moves.first?.perform(in: &old))
        let recipe = try XCTUnwrap(old.recipes.first)
        var direct = old
        let clear = try XCTUnwrap(direct.activate(recipe))
        let automatic = try XCTUnwrap(StarlightCelebration(id: 2, turn: clear, from: old,
                                                          total: direct.displayScore, recipe: recipe))
        XCTAssertTrue(automatic.constellationPath.isEmpty)
        XCTAssertEqual(automatic.patterns, [.init(recipe: recipe)])
        let tapped = try XCTUnwrap(StarlightCelebration(id: 3, turn: clear, from: old, total: direct.displayScore))
        XCTAssertTrue(tapped.constellationPath.isEmpty)
        XCTAssertTrue(tapped.patterns.isEmpty, "A generic tap receipt must not infer an automatic route")
    }

    @MainActor private func makeLayout(_ patterns: [StarlightCelebration.Pattern]) throws -> PatternReturnLayout {
        let board = CGRect(x: 0, y: 0, width: 390, height: 844)
        let header = CGRect(x: 20, y: 20, width: 350, height: 96)
        return try XCTUnwrap(PatternReturnLayout(patterns: patterns, board: board, header: header,
            award: StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: false)))
    }

    @MainActor func testAllSeparatePatternsShareOneAffineTransformAcrossPhoneTabletAndScrolledBand() throws {
        let phase = try XCTUnwrap(SkyRecipeResolution.resolve(board(["AA...RR", "AA...RR"]), lineLength: 4).first)
        let patterns = receipt(phase).patterns
        let variants: [(CGRect, CGRect, CGRect?)] = [
            (CGRect(x: 0, y: 0, width: 390, height: 844), CGRect(x: 20, y: 20, width: 350, height: 96), nil),
            (CGRect(x: 0, y: 0, width: 834, height: 1194), CGRect(x: 24, y: 24, width: 786, height: 88), nil),
            (CGRect(x: 0, y: -140, width: 390, height: 900), CGRect(x: 20, y: 20, width: 350, height: 96),
             CGRect(x: 20, y: 124, width: 350, height: 80))
        ]
        for (board, header, protectedSky) in variants {
            let award = protectedSky == nil
                ? StarlightCelebrationOverlay.awardRegion(board: board, header: header, accessible: false)
                : CGRect(x: 20, y: 212, width: 350, height: 64)
            let layout = try XCTUnwrap(PatternReturnLayout(patterns: patterns, board: board, header: header,
                                                          award: award, protectedSky: protectedSky))
            XCTAssertEqual(layout.patterns, patterns)
            XCTAssertEqual(layout.points(at: 0), layout.sourcePaths)
            let arrived = layout.points(at: ConstellationReturnLayout.arrivalTime)
            XCTAssertEqual(layout.points(at: 0, quiet: true), arrived)
            XCTAssertEqual(layout.points(at: 1.3, quiet: true), arrived)
            for ((source, destination), actual) in zip(zip(layout.sourcePaths, layout.destinationPaths), arrived) {
                XCTAssertEqual(actual.count, destination.count)
                for ((start, end), point) in zip(zip(source, destination), actual) {
                    // The endpoint passes through one subtraction and one addition.
                    // Their CGFloat rounding is bounded at these coordinates' own
                    // scale; this is not an absolute geometric/rendering epsilon.
                    let xULP = max(1, abs(start.x), abs(end.x)).ulp
                    let yULP = max(1, abs(start.y), abs(end.y)).ulp
                    XCTAssertEqual(point.x, end.x, accuracy: 4 * xULP)
                    XCTAssertEqual(point.y, end.y, accuracy: 4 * yULP)
                }
            }
            let mapping = LandingGeometry(size: board.size)
            for (pattern, points) in zip(patterns, layout.sourcePaths) {
                XCTAssertEqual(points, pattern.path.map {
                    let point = mapping.viewPoint($0)
                    return CGPoint(x: point.x + board.minX, y: point.y + board.minY)
                })
            }
            let source = layout.sourcePaths.flatMap { $0 }, destination = layout.destinationPaths.flatMap { $0 }
            let dx = source[1].x - source[0].x, dy = source[1].y - source[0].y
            let scale = hypot(destination[1].x - destination[0].x, destination[1].y - destination[0].y) / hypot(dx, dy)
            XCTAssertGreaterThan(scale, 0)
            for (from, to) in zip(source, destination) {
                XCTAssertEqual(to.x - destination[0].x, (from.x - source[0].x) * scale, accuracy: 0.000001)
                XCTAssertEqual(to.y - destination[0].y, (from.y - source[0].y) * scale, accuracy: 0.000001)
                XCTAssertTrue(layout.skyBounds.contains(to))
                XCTAssertFalse(header.contains(to)); XCTAssertFalse(layout.labelBounds.contains(to))
            }
            XCTAssertFalse(layout.skyBounds.intersects(layout.labelBounds))
            if let protectedSky { XCTAssertTrue(protectedSky.contains(layout.skyBounds)) }
        }
    }

    @MainActor func testPatternLayoutRejectsMalformedOrNonfiniteGeometryWithoutTruncatingAValidPhase() throws {
        let phase = try XCTUnwrap(SkyRecipeResolution.resolve(board(["AA.....", "AA....."])).first)
        let patterns = receipt(phase).patterns
        let board = CGRect(x: 0, y: 0, width: 390, height: 844)
        let header = CGRect(x: 20, y: 20, width: 350, height: 96), award = CGRect(x: 20, y: 124, width: 350, height: 64)
        XCTAssertNil(PatternReturnLayout(patterns: [], board: board, header: header, award: award))
        XCTAssertNil(PatternReturnLayout(patterns: patterns, board: .zero, header: header, award: award))
        XCTAssertNil(PatternReturnLayout(patterns: patterns, board: board,
            header: CGRect(x: CGFloat.nan, y: 0, width: 350, height: 96), award: award))
        XCTAssertNil(PatternReturnLayout(patterns: patterns, board: board, header: header, award: award,
            protectedSky: CGRect(x: 20, y: 124, width: CGFloat.infinity, height: 80)))
        let outside = StarRecipe(shape: .line, cells: [Cell(0,0), Cell(0,1), Cell(0,2), Cell(7,3)], starIDs: [1,2,3,4])
        XCTAssertNil(PatternReturnLayout(patterns: [.init(recipe: outside)], board: board, header: header, award: award))
        let duplicate = StarRecipe(shape: .line, cells: [Cell(0,0), Cell(0,0)], starIDs: [1,2])
        XCTAssertNil(PatternReturnLayout(patterns: [.init(recipe: duplicate)], board: board, header: header, award: award))
    }

    @MainActor private func makeStore(_ game: FallingSky, quiet: Bool = false)
    throws -> (FallingSkyStore, PatternPhasePresenter, ManualRainClock, UserDefaults) {
        let suite = "Starfall.AutomaticPatternReturn.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(game), forKey: SkySaveArchive.key)
        let presenter = PatternPhasePresenter(), clock = ManualRainClock()
        presenter.reduceMotion = quiet
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
        store.setSuspended(false)
        return (store, presenter, clock, defaults)
    }

    @MainActor func testStoryInspectionNonclearingSetupAndOpenSkyDrawingKeepDistinctPublication() throws {
        for opening in [FallingSky.freshChallenge(.firstLight), .fullBoardLantern(), .fullBoardRibbon()] {
            let (store, presenter, _, defaults) = try makeStore(opening)
            defer { store.setSuspended(true) }
            let saved = defaults.data(forKey: SkySaveArchive.key)
            store.clear(Cell(0,0))
            XCTAssertEqual(store.game, opening); XCTAssertNil(store.celebration)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
            store.clearTracedConstellation((0..<5).map { Cell(0,$0) }, snapshot: opening,
                                          generation: store.constellationInputGeneration)
            XCTAssertEqual(store.game, opening); XCTAssertNil(store.celebration)
            var expected = opening
            let setup = try XCTUnwrap(expected.nudge(from: Cell(0,0), to: Cell(0,1)))
            XCTAssertEqual(setup.displayAward, 0)
            XCTAssertTrue(store.performTechnique(.nudge(Cell(0,0), Cell(0,1)), snapshot: opening,
                                                 generation: store.constellationInputGeneration))
            presenter.completions.last?()
            XCTAssertEqual(store.game, expected); XCTAssertNil(store.celebration)
        }
    }

    @MainActor func testWinningCommitPrecedesEveryPhaseReturnAndStaleCallbacksCannotReplaceReplay() throws {
        let opening = FallingSky.freshChallenge(.silverPools)
        let (store, presenter, clock, defaults) = try makeStore(opening)
        defer { store.setSuspended(true) }
        var expected = opening
        let turn = try XCTUnwrap(expected.nudge(from: Cell(1,2), to: Cell(1,3)))
        XCTAssertEqual(expected.outcome, .won)
        XCTAssertEqual(turn.resolutionPhases.count, 2)
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,2), Cell(1,3)), snapshot: opening,
                                             generation: store.constellationInputGeneration))
        XCTAssertEqual(store.game, expected)
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
        XCTAssertTrue(store.busy); XCTAssertNil(clock.deadline)
        let saved = defaults.data(forKey: SkySaveArchive.key)
        let phaseCallback = try XCTUnwrap(presenter.phases.first)
        let completion = try XCTUnwrap(presenter.completions.first)
        for (index, phase) in turn.resolutionPhases.enumerated() {
            phaseCallback(index)
            assertActualRecipes(try XCTUnwrap(store.celebration), phase: phase)
            XCTAssertEqual(store.game, expected); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
            XCTAssertTrue(store.busy, "A pattern return cannot finish presentation or withhold the already-earned win")
        }
        completion(); XCTAssertFalse(store.busy)
        store.restart(sameSky: true)
        let replay = store.game, replayBytes = defaults.data(forKey: SkySaveArchive.key)
        XCTAssertEqual(replay, opening)
        XCTAssertNil(store.celebration)
        phaseCallback(0); phaseCallback(1); completion()
        XCTAssertNil(store.celebration)
        XCTAssertEqual(store.game, replay); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), replayBytes)
    }

    @MainActor func testQuietReceiptIsTheActualLastPhaseAndDoesNotOwnScoreOrCompletion() throws {
        for opening in [FallingSky.freshChallenge(.firstLight), .fullBoardLantern()] {
            let (store, presenter, _, defaults) = try makeStore(opening, quiet: true)
            defer { store.setSuspended(true) }
            var expected = opening
            let turn = try XCTUnwrap(expected.nudge(from: Cell(1,1), to: Cell(1,2)))
            XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)), snapshot: opening,
                                                 generation: store.constellationInputGeneration))
            let event = try XCTUnwrap(store.celebration)
            assertActualRecipes(event, phase: try XCTUnwrap(turn.resolutionPhases.last))
            XCTAssertEqual(event.displayAward, turn.displayAward)
            XCTAssertEqual(store.game, expected)
            XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: SkySaveArchive.key))), expected)
            presenter.phases.first?(0)
            XCTAssertEqual(store.celebration, event, "A normal phase callback cannot replace the quiet aggregate")
            XCTAssertTrue(store.busy)
            presenter.completions.first?()
            XCTAssertFalse(store.busy); XCTAssertEqual(store.game, expected)
        }
    }

    @MainActor func testPatternReceiptExpiryDoesNotCompleteGameplayAndInterruptionRejectsLatePhases() async throws {
        let (store, presenter, _, defaults) = try makeStore(.freshChallenge(.ribbonCrossing))
        defer { store.setSuspended(true) }
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,1), Cell(1,2)), snapshot: store.game,
                                             generation: store.constellationInputGeneration))
        let phase = try XCTUnwrap(presenter.phases.first), completion = try XCTUnwrap(presenter.completions.first)
        phase(0)
        XCTAssertFalse(try XCTUnwrap(store.celebration).patterns.isEmpty)
        let committed = store.game, saved = defaults.data(forKey: SkySaveArchive.key)
        let deadline = ContinuousClock.now + .seconds(3)
        while store.celebration != nil && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        XCTAssertNil(store.celebration); XCTAssertTrue(store.busy)
        XCTAssertEqual(store.game, committed); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
        store.setSuspended(true)
        phase(1); completion()
        XCTAssertNil(store.celebration); XCTAssertFalse(store.busy)
        XCTAssertEqual(store.game, committed); XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
    }

    @MainActor func testRenderedAutomaticPatternsRemainSeparateAndLeaveMeasuredHUDClear() async throws {
        let phase = try XCTUnwrap(SkyRecipeResolution.resolve(board(["AA...RR", "AA...RR"]), lineLength: 4).first)
        let event = receipt(phase)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let host = UIHostingController(rootView: AnyView(Color.black))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        let header = CGRect(x: 20, y: 20, width: 350, height: 96)
        let award = StarlightCelebrationOverlay.awardRegion(board: window.bounds, header: header, accessible: false)
        let layout = try XCTUnwrap(PatternReturnLayout(patterns: event.patterns, board: window.bounds,
                                                       header: header, award: award))
        let flightAge = 0.48, point = layout.points(at: flightAge)[0][1]
        let crossingScore = CGRect(x: point.x - 8, y: point.y - 6, width: 16, height: 12)
        let offRouteScore = CGRect(x: 330, y: 780, width: 40, height: 36)
        let cases: [(String, Double, Bool, CGRect)] = [
            ("flight-control", flightAge, false, offRouteScore),
            ("flight-hud-exclusion", flightAge, false, crossingScore),
            ("arrived-separate-squares", 0.98, false, offRouteScore),
            ("quiet-same-separate-squares", 0.3, true, offRouteScore)
        ]
        let marker = CGRect(x: 4, y: 834, width: 6, height: 6)
        let figureRegion = CGRect(x: 0, y: 0, width: 390, height: 828)
        for (index, example) in cases.enumerated() {
            let overlay = StarlightCelebrationOverlay(event: event, board: window.bounds,
                score: example.3, header: header, quiet: example.2)
            let markerLit = index.isMultiple(of: 2)
            host.rootView = AnyView(Canvas { context, size in
                overlay.drawPatterns(in: &context, layout: layout, age: example.1, canvasSize: size)
                context.fill(Path(marker), with: .color(markerLit ? .white : .black))
            }.background(Color.black).ignoresSafeArea().id(example.0))
            var rendered: UIImage?
            var ready = false
            let deadline = ContinuousClock.now + .milliseconds(900)
            repeat {
                await Task.yield(); host.view.layoutIfNeeded()
                rendered = windowImage(window)
                let image = try XCTUnwrap(rendered)
                let markerInk = try ink(in: image, region: marker)
                ready = try ink(in: image, region: figureRegion) > 25 && (markerLit ? markerInk > 0 : markerInk == 0)
                if !ready { try await Task.sleep(for: .milliseconds(20)) }
            } while !ready && ContinuousClock.now < deadline
            XCTAssertTrue(ready, example.0)
            let image = try XCTUnwrap(rendered)
            if index == 0 { XCTAssertGreaterThan(try ink(in: image, region: crossingScore), 0) }
            for region in [example.3, header, layout.labelBounds] {
                XCTAssertEqual(try ink(in: image, region: region), 0, "Pattern ink/shadow must not cover HUD: \(example.0)")
            }
            if index >= 2 {
                let left = layout.destinationPaths[0], right = layout.destinationPaths[1]
                let gap = CGPoint(x: (left.map(\.x).max()! + right.map(\.x).min()!) / 2,
                                  y: left[0].y)
                XCTAssertEqual(try ink(in: image, region: CGRect(x: gap.x - 2, y: gap.y - 2, width: 4, height: 4)), 0,
                               "Separate simultaneous squares must not acquire a connecting line")
                for path in layout.destinationPaths {
                    let x = path.map(\.x), y = path.map(\.y)
                    let bounds = CGRect(x: x.min()! - 5, y: y.min()! - 5,
                                        width: x.max()! - x.min()! + 10, height: y.max()! - y.min()! + 10)
                    XCTAssertGreaterThan(try ink(in: image, region: bounds), 25, "Every actual square must remain visible")
                }
            }
            let attachment = XCTAttachment(image: image)
            attachment.name = "automatic-pattern-\(example.0)"; attachment.lifetime = .keepAlways; add(attachment)
        }
    }

    @MainActor private func windowImage(_ window: UIWindow) -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = window.screen.scale
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
