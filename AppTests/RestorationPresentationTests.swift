import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class RestorationPresentationTests: XCTestCase {
    func testArtworkFamilyUsesIdiomViewportAndActualCanvasShape() {
        XCTAssertEqual(RestorationComposition.selected(isTablet: false, isLandscape: false, size: .init(width: 393, height: 852)), .phone)
        XCTAssertEqual(RestorationComposition.selected(isTablet: false, isLandscape: true, size: .init(width: 844, height: 393)), .tabletLandscape)
        XCTAssertEqual(RestorationComposition.selected(isTablet: false, isLandscape: true, size: .init(width: 844, height: 900)), .tabletPortrait)
        XCTAssertEqual(RestorationComposition.selected(isTablet: true, isLandscape: false, size: .init(width: 744, height: 1133)), .tabletPortrait)
        XCTAssertEqual(RestorationComposition.selected(isTablet: true, isLandscape: true, size: .init(width: 1133, height: 744)), .tabletLandscape)
        XCTAssertEqual(RestorationComposition.selected(isTablet: true, isLandscape: true, size: .init(width: 1024, height: 1200)), .tabletPortrait)
    }

    func testWholePaintingFillsCanvasAndKeepsItsRegisteredLanternDestination() {
        let samples: [(CGSize, RestorationComposition, CGPoint)] = [
            (.init(width: 393, height: 852), .phone, .init(x: 125.358, y: 68.160)),
            (.init(width: 744, height: 1133), .tabletPortrait, .init(x: 132.3705, y: 89.507)),
            (.init(width: 1133, height: 744), .tabletLandscape, .init(x: 182.413, y: 215.646)),
            (.init(width: 1024, height: 1366), .tabletPortrait, .init(x: 223.091, y: 107.914)),
            (.init(width: 1366, height: 1024), .tabletLandscape, .init(x: 219.926, y: 323.492))
        ]
        for (size, artwork, light) in samples {
            let layout = RestorationLayout(size: size, artwork: RestorationArtwork(challenge: .firstLight, composition: artwork))
            let canvas = CGRect(origin: .zero, size: size)
            XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(canvas), "Artwork leaves a seam at \(size)")
            XCTAssertEqual(layout.imageFrame.midX, canvas.midX, accuracy: 0.001)
            XCTAssertEqual(layout.imageFrame.midY, canvas.midY, accuracy: 0.001)
            XCTAssertEqual(layout.imageFrame.width / layout.imageFrame.height,
                           RestorationArtwork(challenge: .firstLight, composition: artwork).sourceSize.width / RestorationArtwork(challenge: .firstLight, composition: artwork).sourceSize.height, accuracy: 0.000001)
            XCTAssertTrue(canvas.contains(layout.light), "Lantern destination was cropped out at \(size)")
            XCTAssertTrue(canvas.contains(layout.focal), "The moth lantern was cropped out at \(size)")
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
            let artwork = RestorationComposition.selected(isTablet: false, isLandscape: true, size: size)
            XCTAssertEqual(artwork, .tabletPortrait)
            let layout = RestorationLayout(size: size, artwork: RestorationArtwork(challenge: .firstLight, composition: artwork))
            let canvas = CGRect(origin: .zero, size: size)
            XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(canvas))
            XCTAssertTrue(canvas.insetBy(dx: -0.001, dy: -0.001).contains(layout.focal))
            XCTAssertTrue(layout.focal.contains(layout.light))
            XCTAssertLessThan(layout.focal.maxY, LandingGeometry(size: size).arenaFrame.minY)
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
        for challenge in StarfallChallenge.allCases {
            for composition in RestorationComposition.allCases {
                let artwork = RestorationArtwork(challenge: challenge, composition: composition)
                for stage in StarlightRestoration.Milestone.allCases {
                    let name = artwork.asset(for: stage)
                    XCTAssertTrue(names.insert(name).inserted, "Two device states share the asset \(name)")
                    let image = try XCTUnwrap(UIImage(named: name), "Missing packaged \(name)")
                    let pixels = try XCTUnwrap(image.cgImage, "Missing raster for \(name)")
                    let source = artwork.sourceSize(for: stage)
                    XCTAssertEqual(pixels.width, Int(source.width), name)
                    XCTAssertEqual(pixels.height, Int(source.height), name)
                    XCTAssertEqual(image.size.width / image.size.height,
                                   source.width / source.height, accuracy: 0.000001, name)
                }
            }
        }
        XCTAssertEqual(names.count, 105)
    }

    @MainActor func testSeedLandscapePaintingsFillCanvasAtTheirActualPixelAspectRatio() throws {
        let artwork = RestorationArtwork(challenge: .seedMoon, composition: .tabletLandscape)
        let canvases = [CGSize(width: 1366, height: 1024), CGSize(width: 1133, height: 744),
                        CGSize(width: 844, height: 393)]
        for stage in StarlightRestoration.Milestone.allCases {
            let name = artwork.asset(for: stage)
            let image = try XCTUnwrap(UIImage(named: name), "Missing packaged \(name)")
            let pixels = try XCTUnwrap(image.cgImage, "Missing raster for \(name)")
            for size in canvases {
                let layout = RestorationLayout(size: size, artwork: artwork, milestone: stage)
                XCTAssertEqual(layout.imageFrame.width / layout.imageFrame.height,
                               CGFloat(pixels.width) / CGFloat(pixels.height), accuracy: 0.000001, name)
                XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001)
                    .contains(CGRect(origin: .zero, size: size)), "Painting leaves an edge at \(size): \(name)")
            }
        }
    }

    func testRestorationLightStaysVisibleOutsideNativeBoardAcrossViewportFamilies() {
        let samples: [(CGSize, Bool, Bool)] = [
            (.init(width: 393, height: 852), false, false),
            (.init(width: 375, height: 900), false, false),
            (.init(width: 375, height: 1200), false, false),
            (.init(width: 393, height: 1200), false, false),
            (.init(width: 667, height: 900), false, true),
            (.init(width: 844, height: 900), false, true),
            (.init(width: 667, height: 1200), false, true),
            (.init(width: 744, height: 1133), true, false),
            (.init(width: 1024, height: 1366), true, false),
            (.init(width: 1133, height: 744), true, true),
            (.init(width: 1366, height: 1024), true, true),
            (.init(width: 1024, height: 1200), true, true)
        ]
        for challenge in StarfallChallenge.allCases {
            for (size, tablet, landscape) in samples {
                let composition = RestorationComposition.selected(isTablet: tablet, isLandscape: landscape, size: size)
                let artwork = RestorationArtwork(challenge: challenge, composition: composition)
                let layout = RestorationLayout(size: size, artwork: artwork)
                let canvas = CGRect(origin: .zero, size: size)
                let board = LandingGeometry(size: size).arenaFrame
                XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(canvas))
                XCTAssertTrue(canvas.contains(layout.light), "Light cropped for \(challenge) at \(size)")
                XCTAssertFalse(board.intersects(layout.light), "Light overlaps stars for \(challenge) at \(size)")
                XCTAssertTrue(canvas.insetBy(dx: -0.001, dy: -0.001).contains(layout.focal), "Landmark cropped for \(challenge) at \(size)")
                XCTAssertTrue(layout.focal.contains(layout.light), "Landmark no longer contains the light for \(challenge) at \(size)")
            }
        }
    }

    func testResultClearanceFollowsMappedSceneryAcrossExpandedAndScrolledCanvases() {
        let samples: [(CGSize, RestorationComposition)] = [
            (.init(width: 393, height: 852), .phone),
            (.init(width: 375, height: 900), .phone),
            (.init(width: 375, height: 1200), .phone),
            (.init(width: 667, height: 1200), .tabletPortrait),
            (.init(width: 744, height: 1133), .tabletPortrait),
            (.init(width: 1366, height: 1024), .tabletLandscape)
        ]
        for challenge in StarfallChallenge.allCases {
            for (size, composition) in samples {
                let scene = RestorationLayout(size: size, artwork: .init(challenge: challenge, composition: composition))
                let protected = scene.restoredSceneryBounds
                XCTAssertTrue(protected.contains(scene.light))
                for safeAreaTop: CGFloat in [0, 59] {
                    for scrollOffset: CGFloat in [0, -180] {
                        let resolved = protected.offsetBy(dx: 0, dy: scrollOffset - safeAreaTop)
                        let ceremony = SkyCeremonyLayout(screen: .won, challenge: challenge,
                                                         safeAreaTop: safeAreaTop, restoredSceneryBounds: resolved)
                        let headingTop = StarfallTheme.Spacing.section + ceremony.minimumTopSpace + ceremony.spacing
                        XCTAssertGreaterThanOrEqual(headingTop + 0.001, resolved.maxY + StarfallTheme.Spacing.medium,
                                                    "Result covers \(challenge) at \(size), offset \(scrollOffset)")
                        XCTAssertGreaterThanOrEqual(headingTop + safeAreaTop, 230)
                    }
                }
            }
        }
        // The actual AX phone painting places the seam below the old fixed
        // 230-point clearance. Its full focal band ends at 336 points.
        let accessible = RestorationLayout(size: .init(width: 375, height: 1200),
                                           artwork: .init(challenge: .ribbonCrossing, composition: .phone))
        XCTAssertEqual(accessible.light.midY, 297.6, accuracy: 0.001)
        XCTAssertEqual(accessible.restoredSceneryBounds.maxY, 336, accuracy: 0.001)
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
            let preview = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: flow.entry))
            XCTAssertEqual(preview.challenge, .firstLight)
            XCTAssertEqual(preview.progress.fraction, 0)
            XCTAssertEqual(preview.progress.target, action == .replay ? original.displayTarget : FallingSky.freshChallenge(.firstLight).displayTarget)
            XCTAssertEqual(flow, staged)
            XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
            XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: flow.entry)?.progress, original.restoration)
            XCTAssertEqual(store.game, original)
            XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved)
        }

        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: FallingSkyRecorder(),
                                       clock: ManualRainClock())
        XCTAssertEqual(RestorationPresentation.selected(game: restored.game, entry: nil)?.progress, original.restoration)
    }

    @MainActor func testOpenSkyPreviewHidesRetainedChallengeUntilCancel() throws {
        let original = try progressedChallenge()
        let (store, _, defaults) = try store(saved: original)
        let saved = defaults.data(forKey: FallingSkyStore.saveKey)
        var flow = SkyFlowState(arguments: [])
        XCTAssertEqual(flow.handle(.start, hasSavedSky: true), .staged)
        XCTAssertEqual(flow.entry, .fresh)
        XCTAssertNil(RestorationPresentation.selected(game: store.game, entry: flow.entry))
        XCTAssertEqual(flow.handle(.home, hasSavedSky: true), .home)
        XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: flow.entry)?.progress, original.restoration)
        XCTAssertEqual(defaults.data(forKey: FallingSkyStore.saveKey), saved)
    }

    func testOpenSkyDoesNotAcquireRestorationFromInitialOrReplayEntry() {
        let game = FallingSky.freshSurvival(seed: 42)
        for entry in [SkyEntryRequest?.none, .initial, .fresh, .replay] {
            XCTAssertNil(RestorationPresentation.selected(game: game, entry: entry))
        }
        XCTAssertEqual(RestorationPresentation.selected(game: game, entry: .firstLight)?.progress.fraction, 0)
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
        let committed = try XCTUnwrap(RestorationPresentation.selected(game: store.game, entry: nil))
        XCTAssertEqual(committed.challenge, .firstLight)
        XCTAssertEqual(committed.progress.score, store.game.score)
        XCTAssertEqual(committed.progress.fraction, Double(store.game.score) / Double(StarfallChallenge.firstLight.target))
        XCTAssertEqual(try SkySaveArchive.decode(XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))).restoration, committed.progress)

        store.setSuspended(true)
        presenter.finish()
        XCTAssertEqual(RestorationPresentation.selected(game: store.game, entry: nil), committed,
                       "An interrupted clear cannot roll restoration back to its earlier visual state")
    }
}
