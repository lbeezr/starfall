import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class LanternLandingPresentationTests: XCTestCase {
    func testArtworkFamilyUsesIdiomViewportAndActualCanvasShape() {
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: false, isLandscape: false, size: .init(width: 393, height: 852)), .phone)
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: false, isLandscape: true, size: .init(width: 844, height: 393)), .tabletLandscape)
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: false, isLandscape: true, size: .init(width: 844, height: 900)), .tabletPortrait)
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: true, isLandscape: false, size: .init(width: 744, height: 1133)), .tabletPortrait)
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: true, isLandscape: true, size: .init(width: 1133, height: 744)), .tabletLandscape)
        XCTAssertEqual(LanternLandingArtwork.selected(isTablet: true, isLandscape: true, size: .init(width: 1024, height: 1200)), .tabletPortrait)
    }

    func testWholePaintingFillsCanvasAndKeepsItsRegisteredLanternDestination() {
        let samples: [(CGSize, LanternLandingArtwork, CGPoint)] = [
            (.init(width: 393, height: 852), .phone, .init(x: 125.358, y: 68.160)),
            (.init(width: 744, height: 1133), .tabletPortrait, .init(x: 132.3705, y: 89.507)),
            (.init(width: 1133, height: 744), .tabletLandscape, .init(x: 182.413, y: 215.646)),
            (.init(width: 1024, height: 1366), .tabletPortrait, .init(x: 223.091, y: 107.914)),
            (.init(width: 1366, height: 1024), .tabletLandscape, .init(x: 219.926, y: 323.492))
        ]
        for (size, artwork, light) in samples {
            let layout = LanternLandingLayout(size: size, artwork: artwork)
            let canvas = CGRect(origin: .zero, size: size)
            XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(canvas), "Artwork leaves a seam at \(size)")
            XCTAssertEqual(layout.imageFrame.midX, canvas.midX, accuracy: 0.001)
            XCTAssertEqual(layout.imageFrame.midY, canvas.midY, accuracy: 0.001)
            XCTAssertEqual(layout.imageFrame.width / layout.imageFrame.height,
                           artwork.sourceSize.width / artwork.sourceSize.height, accuracy: 0.000001)
            XCTAssertTrue(canvas.contains(layout.light), "Lantern destination was cropped out at \(size)")
            XCTAssertTrue(canvas.contains(layout.lantern), "The moth lantern was cropped out at \(size)")
            XCTAssertEqual(layout.light.midX, light.x, accuracy: 0.001)
            XCTAssertEqual(layout.light.midY, light.y, accuracy: 0.001)
            XCTAssertEqual(layout.light.width, layout.light.height, accuracy: 0.001)
        }
    }

    func testExpandedLandscapeCanvasKeepsWholeLanternAboveBoardWithoutExposingAnEdge() {
        let samples: [(CGSize, CGPoint)] = [
            (.init(width: 667, height: 900), .init(x: 143.15, y: 71.1)),
            (.init(width: 844, height: 900), .init(x: 183.992, y: 60.768)),
            (.init(width: 852, height: 900), .init(x: 185.736, y: 61.344)),
            (.init(width: 667, height: 1200), .init(x: 79.7, y: 94.8)),
            (.init(width: 1024, height: 1200), .init(x: 223.232, y: 73.728))
        ]
        for (size, expectedLight) in samples {
            let artwork = LanternLandingArtwork.selected(isTablet: false, isLandscape: true, size: size)
            XCTAssertEqual(artwork, .tabletPortrait)
            let layout = LanternLandingLayout(size: size, artwork: artwork)
            let canvas = CGRect(origin: .zero, size: size)
            XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(canvas))
            XCTAssertTrue(canvas.insetBy(dx: -0.001, dy: -0.001).contains(layout.lantern))
            XCTAssertTrue(layout.lantern.contains(layout.light))
            XCTAssertLessThan(layout.lantern.maxY, LandingGeometry(size: size).arenaFrame.minY)
            XCTAssertEqual(layout.imageFrame.width / layout.imageFrame.height, 3.0 / 4.0, accuracy: 0.000001)
            XCTAssertEqual(layout.light.midX, expectedLight.x, accuracy: 0.001)
            XCTAssertEqual(layout.light.midY, expectedLight.y, accuracy: 0.001)
            XCTAssertEqual(layout.light.width, layout.light.height, accuracy: 0.001)
        }
    }

    func testRestorationSceneryKeepsTheSharedBoardAndHeaderFrames() {
        let samples: [(CGSize, CGRect, CGRect)] = [
            (.init(width: 393, height: 852), .init(x: 6, y: 235.5, width: 381, height: 381), .init(x: 12, y: 83.5, width: 369, height: 84)),
            (.init(width: 667, height: 900), .init(x: 93.5, y: 210, width: 480, height: 480), .init(x: 99.5, y: 58, width: 468, height: 84)),
            (.init(width: 844, height: 900), .init(x: 182, y: 210, width: 480, height: 480), .init(x: 188, y: 58, width: 468, height: 84)),
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
        var names: Set<String> = []
        for artwork in LanternLandingArtwork.allCases {
            for stage in StarlightRestoration.Milestone.allCases {
                let name = artwork.asset(for: stage)
                XCTAssertTrue(names.insert(name).inserted, "Two device states share the asset \(name)")
                let image = try XCTUnwrap(UIImage(named: name), "Missing packaged \(name)")
                let pixels = try XCTUnwrap(image.cgImage, "Missing raster for \(name)")
                XCTAssertEqual(pixels.width, Int(artwork.sourceSize.width), name)
                XCTAssertEqual(pixels.height, Int(artwork.sourceSize.height), name)
                XCTAssertEqual(image.size.width / image.size.height,
                               artwork.sourceSize.width / artwork.sourceSize.height, accuracy: 0.000001, name)
            }
        }
        XCTAssertEqual(names.count, 15)
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
