import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class LanternLandingPresentationTests: XCTestCase {
    func testDockAndLanternStayWithinTheSceneryMargins() {
        let sizes = [CGSize(width: 393, height: 852), CGSize(width: 744, height: 1133),
                     CGSize(width: 1024, height: 1366), CGSize(width: 1366, height: 1024)]
        for size in sizes {
            for largeHeader in [false, true] {
                let layout = LanternLandingLayout(size: size, largeHeader: largeHeader)
                let board = LandingGeometry(size: size, largeHeader: largeHeader).arenaFrame
                XCTAssertTrue(layout.dock.contains(layout.light), "Lantern anchor escaped its dock at \(size)")
                XCTAssertTrue(CGRect(origin: .zero, size: size).contains(layout.dock), "Dock escaped the canvas at \(size)")
                if layout.usesWings {
                    // The wing's final ten points contain the receding bridge/sky.
                    // Preserve that bounded edge allowance without moving the board.
                    XCTAssertLessThanOrEqual(layout.dock.maxX, board.minX + 10, "Left wing encroached at \(size)")
                    XCTAssertGreaterThanOrEqual(layout.rail.minX, board.maxX - 10, "Right wing encroached at \(size)")
                } else {
                    // The approved dock ends at source y=0.279 within its 0...0.31 crop.
                    let paintedBottom = layout.dock.minY + layout.dock.height * (0.279 / 0.31)
                    XCTAssertLessThanOrEqual(paintedBottom, board.minY, "Painted dock obscures the top row at \(size)")
                    XCTAssertGreaterThanOrEqual(layout.rail.minY, board.maxY, "Rail obscures the bottom row at \(size)")
                }
            }
        }
    }

    func testRestorationSceneryKeepsTheSharedBoardAndHeaderFrames() {
        let samples: [(CGSize, CGRect, CGRect)] = [
            (.init(width: 393, height: 852), .init(x: 6, y: 235.5, width: 381, height: 381), .init(x: 12, y: 83.5, width: 369, height: 84)),
            (.init(width: 744, height: 1133), .init(x: 62, y: 256.5, width: 620, height: 620), .init(x: 68, y: 104.5, width: 608, height: 84)),
            (.init(width: 1024, height: 1366), .init(x: 202, y: 373, width: 620, height: 620), .init(x: 208, y: 221, width: 608, height: 84)),
            (.init(width: 1366, height: 1024), .init(x: 381, y: 210, width: 604, height: 604), .init(x: 387, y: 58, width: 592, height: 84))
        ]
        for (size, board, header) in samples {
            let normal = LandingGeometry(size: size)
            let large = LandingGeometry(size: size, largeHeader: true)
            XCTAssertEqual(normal.arenaFrame, board)
            XCTAssertEqual(normal.crownFrame, header)
            XCTAssertEqual(large.arenaFrame, board)
            XCTAssertEqual(LanternLandingLayout(size: size).dock, LanternLandingLayout(size: size, largeHeader: true).dock)
            for row in 0..<7 {
                for column in 0..<7 {
                    let cell = Cell(row, column)
                    XCTAssertEqual(normal.cell(at: normal.viewPoint(cell)), cell)
                    XCTAssertEqual(large.viewPoint(cell), normal.viewPoint(cell))
                }
            }
        }
    }

    @MainActor func testEveryRestorationAssetIsPackagedAtTheRegisteredAspectRatio() throws {
        for stage in StarlightRestoration.Milestone.allCases {
            let name = String(format: "LanternLanding%03d", stage.rawValue)
            let image = try XCTUnwrap(UIImage(named: name), "Missing packaged \(name)")
            let pixels = try XCTUnwrap(image.cgImage, "Missing raster for \(name)")
            XCTAssertEqual(pixels.width, 887, name)
            XCTAssertEqual(pixels.height, 1774, name)
            XCTAssertEqual(image.size.width / image.size.height, 887.0 / 1774.0, accuracy: 0.000001, name)
        }
    }

    private func progressedChallenge() throws -> FallingSky {
        var game = FallingSky(challenge: .firstLight)
        for _ in 0..<80 where game.score == 0 && !game.isOver {
            if let cell = game.legalGroups.first?.first { _ = game.clear(cell) }
            else { _ = game.letStarsFall() }
        }
        XCTAssertGreaterThan(game.score, 0)
        XCTAssertLessThan(game.score, StarfallChallenge.firstLight.target)
        XCTAssertTrue(game.isValidSave)
        return game
    }

    @MainActor private func store(saved game: FallingSky) throws -> (FallingSkyStore, FallingSkyRecorder, UserDefaults) {
        let suite = "Starfall.LanternPresentation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(game), forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder()
        return (FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                               clock: ManualRainClock()), presenter, defaults)
    }

    @MainActor func testChallengePreviewAndCancelPreserveSavedRestoration() throws {
        let original = try progressedChallenge()
        let (store, _, defaults) = try store(saved: original)
        let saved = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))

        for action in [SkyFlowAction.firstLight, .replay] {
            var flow = SkyFlowState(arguments: ["--starfalls-reset"])
            XCTAssertEqual(flow.handle(action, hasSavedSky: true), .staged)
            let staged = flow
            let preview = try XCTUnwrap(LanternLandingPresentation.selected(game: store.game, entry: flow.entry))
            XCTAssertEqual(preview.fraction, 0)
            XCTAssertEqual(preview.target, StarfallChallenge.firstLight.target)
            XCTAssertEqual(flow, staged)
            XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
            XCTAssertEqual(LanternLandingPresentation.selected(game: store.game, entry: flow.entry), original.restoration)
            XCTAssertEqual(store.game, original)
            XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved)
        }

        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                       clock: ManualRainClock())
        XCTAssertEqual(LanternLandingPresentation.selected(game: restored.game, entry: nil), original.restoration)
    }

    @MainActor func testOpenSkyPreviewHidesRetainedChallengeUntilCancel() throws {
        let original = try progressedChallenge()
        let (store, _, defaults) = try store(saved: original)
        let saved = defaults.data(forKey: FallingSkyStore.saveKey)
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.start, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.entry, .fresh)
        XCTAssertNil(LanternLandingPresentation.selected(game: store.game, entry: flow.entry))
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(LanternLandingPresentation.selected(game: store.game, entry: flow.entry), original.restoration)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved)
    }

    func testOpenSkyDoesNotAcquireRestorationFromInitialOrReplayEntry() {
        let game = FallingSky.freshSurvival(seed: 42)
        for entry in [SkyEntryRequest?.none, .initial, .fresh, .replay] {
            XCTAssertNil(LanternLandingPresentation.selected(game: game, entry: entry))
        }
        XCTAssertEqual(LanternLandingPresentation.selected(game: game, entry: .firstLight)?.fraction, 0)
    }

    @MainActor func testRestorationUsesCommittedClearBeforePresentationFinishes() throws {
        var opening = FallingSky(challenge: .firstLight)
        for _ in 0..<80 where opening.legalGroups.isEmpty && !opening.isOver { _ = opening.letStarsFall() }
        let cell = try XCTUnwrap(opening.legalGroups.first?.first)
        let (store, presenter, defaults) = try store(saved: opening)
        store.setSuspended(false)
        store.clear(cell)
        XCTAssertTrue(store.busy)
        XCTAssertGreaterThan(store.game.score, 0)
        let committed = try XCTUnwrap(LanternLandingPresentation.selected(game: store.game, entry: nil))
        XCTAssertEqual(committed.score, store.game.score)
        XCTAssertEqual(committed.fraction, Double(store.game.score) / Double(StarfallChallenge.firstLight.target))
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))).restoration, committed)

        store.setSuspended(true)
        presenter.finish()
        XCTAssertEqual(LanternLandingPresentation.selected(game: store.game, entry: nil), committed,
                       "An interrupted clear cannot roll restoration back to its earlier visual state")
    }
}
