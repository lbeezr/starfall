import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class SkyRestoredPlacePresentationTests: XCTestCase {
    @MainActor private func completedLantern() throws -> SkyRestoredPlaceSnapshot {
        // This existing historical fixture still earns its repair through the
        // ordinary Core clear; a view never constructs a winning game.
        var game = ObservatoryReviewFixture.game(dense: false, score: 14, challenge: .firstLight)
        XCTAssertNotNil(game.clear(Cell(0, 0)))
        XCTAssertTrue(game.isValidSave)
        XCTAssertEqual(game.outcome, .won)
        var journey = WorldJourney()
        journey.record(game)
        journey.select(.firstLight)
        return try XCTUnwrap(SkyRestoredPlaceSnapshot(location: .firstLight, journey: journey))
    }

    @MainActor func testNativeHeaderReflowsWithoutTakingTheRegisteredPaintingSpace() throws {
        let snapshot = try completedLantern()
        let reader = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: {})
        let samples: [(CGSize, Bool, DynamicTypeSize)] = [
            (.init(width: 390, height: 844), false, .large),
            (.init(width: 320, height: 568), false, .accessibility5),
            (.init(width: 834, height: 1210), true, .accessibility3),
            (.init(width: 1210, height: 834), true, .accessibility3)
        ]
        for (viewport, tablet, textSize) in samples {
            let header = UIHostingController(rootView: reader.header.environment(\.dynamicTypeSize, textSize))
            let reading = header.sizeThatFits(in: CGSize(width: viewport.width, height: 10_000))
            XCTAssertLessThanOrEqual(reading.width, viewport.width)
            XCTAssertGreaterThanOrEqual(reading.height, StarfallTheme.Layout.minimumTarget + 24)
            XCTAssertLessThan(reading.height, viewport.height - 100,
                              "Native text wraps while leaving an actual painting viewport")
            let canvas = CGSize(width: viewport.width, height: viewport.height - reading.height)
            let composition = RestorationComposition.selected(isTablet: tablet,
                isLandscape: viewport.width > viewport.height, size: canvas)
            let artwork = RestorationArtwork(challenge: snapshot.challenge, composition: composition)
            let layout = RestorationLayout(size: canvas, artwork: artwork)
            let bounds = CGRect(origin: .zero, size: canvas)
            XCTAssertTrue(layout.imageFrame.insetBy(dx: -0.001, dy: -0.001).contains(bounds))
            XCTAssertTrue(bounds.insetBy(dx: -0.001, dy: -0.001).contains(layout.focal))
            XCTAssertTrue(bounds.insetBy(dx: -0.001, dy: -0.001).contains(layout.light))
            XCTAssertEqual(layout.imageFrame.width / layout.imageFrame.height,
                           artwork.sourceSize.width / artwork.sourceSize.height, accuracy: 0.000001)
            let globalFocal = layout.focal.offsetBy(dx: 0, dy: reading.height)
            XCTAssertGreaterThanOrEqual(globalFocal.minY, reading.height,
                                        "The pinned native header does not cover the registered lantern")
        }
        let ordinary = UIHostingController(rootView: reader.header.environment(\.dynamicTypeSize, .large))
            .sizeThatFits(in: CGSize(width: 390, height: 10_000))
        let largest = UIHostingController(rootView: reader.header.environment(\.dynamicTypeSize, .accessibility5))
            .sizeThatFits(in: CGSize(width: 390, height: 10_000))
        XCTAssertGreaterThan(largest.height, ordinary.height, "Reading grows instead of scaling down")
        let wideLargest = UIHostingController(rootView: reader.header.environment(\.dynamicTypeSize, .accessibility3))
            .sizeThatFits(in: CGSize(width: 1210, height: 10_000))
        let narrowLargest = UIHostingController(rootView: reader.header.environment(\.dynamicTypeSize, .accessibility3))
            .sizeThatFits(in: CGSize(width: 320, height: 10_000))
        XCTAssertLessThan(wideLargest.height, narrowLargest.height,
                          "An actual wide viewport must recover space while the same large text wraps on a narrow one")
    }

    @MainActor func testActualViewerPaintingIsTheExistingCompleteRegisteredEnvironment() throws {
        let snapshot = try completedLantern()
        let viewer = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: {})
        let samples: [(CGSize, Bool, Bool, RestorationComposition)] = [
            (.init(width: 390, height: 740), false, false, .phone),
            (.init(width: 834, height: 1000), true, false, .tabletPortrait),
            (.init(width: 1210, height: 630), true, true, .tabletLandscape)
        ]
        for (size, tablet, landscape, composition) in samples {
            let actual = try render(viewer.painting(isTablet: tablet, isLandscape: landscape), size: size)
            let reference = try render(RestorationEnvironment(presentation: snapshot.presentation,
                active: false, ambientActive: true, quiet: true,
                isTablet: tablet, isLandscape: landscape, award: nil), size: size)
            XCTAssertEqual(actual.pngData(), reference.pngData(),
                           "The viewer must not add a board, reward response, mask or alternate painting")
            let artwork = RestorationArtwork(challenge: .firstLight, composition: composition)
            let source = try XCTUnwrap(UIImage(named: artwork.asset(for: .complete)))
            XCTAssertEqual(source.cgImage?.width, Int(artwork.sourceSize.width))
            XCTAssertEqual(source.cgImage?.height, Int(artwork.sourceSize.height))
            XCTAssertEqual(snapshot.presentation.progress.milestone, .complete)
            XCTAssertGreaterThan(try warmPixels(actual), 100,
                                 "The complete actual lantern material must be present, not a blank canvas")
            if composition != .tabletPortrait {
                let attachment = XCTAttachment(image: actual)
                attachment.name = "restored-lantern-existing-\(composition)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor func testInactiveNormalAndCalmKeepTheSameCompleteFigureWithoutADeliveryReceipt() throws {
        let snapshot = try completedLantern(), size = CGSize(width: 390, height: 740)
        let normal = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: false, back: {})
        let calm = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: {})
        let normalImage = try render(normal.painting(isTablet: false, isLandscape: false), size: size)
        let calmImage = try render(calm.painting(isTablet: false, isLandscape: false), size: size)
        XCTAssertEqual(normalImage.pngData(), calmImage.pngData(),
                       "Inactive and Calm retain the same completed place; no award is replayed")
    }

    @MainActor func testPublicViewerUsesTheWholeCoverAndNeverCallsBackDuringReadingOrLayout() throws {
        let snapshot = try completedLantern()
        var callbacks = 0
        for size in [CGSize(width: 390, height: 844), CGSize(width: 834, height: 1210),
                     CGSize(width: 1210, height: 834)] {
            let view = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: { callbacks += 1 })
                .environment(\.dynamicTypeSize, .accessibility3)
                .frame(width: size.width, height: size.height)
            let host = UIHostingController(rootView: view)
            let fitted = host.sizeThatFits(in: size)
            XCTAssertEqual(fitted.width, size.width, accuracy: 0.001)
            XCTAssertEqual(fitted.height, size.height, accuracy: 0.001)
            let image = try render(view, size: size)
            XCTAssertEqual(image.cgImage?.width, Int(size.width))
            XCTAssertEqual(image.cgImage?.height, Int(size.height))
            XCTAssertEqual(callbacks, 0, "Viewing and orientation changes never enter, replay or dismiss a round")
            if size.width == 390 {
                let attachment = XCTAttachment(image: image)
                attachment.name = "restored-lantern-full-cover-accessibility"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }

    @MainActor func testPassivePaintingPassesNativeHitTestingToTheExistingUnderlyingSurface() async throws {
        let snapshot = try completedLantern()
        let underneath = UIView()
        let size = CGSize(width: 390, height: 740)
        let viewer = SkyRestoredPlaceView(snapshot: snapshot, active: false, quiet: true, back: {})
        let host = UIHostingController(rootView: ZStack {
            HitSurface(view: underneath)
            viewer.painting(isTablet: false, isLandscape: false)
        }.frame(width: size.width, height: size.height))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousWindow?.makeKey()
        }
        host.view.frame = CGRect(origin: .zero, size: size)
        host.view.layoutIfNeeded()
        let readyDeadline = ContinuousClock.now + .seconds(3)
        while (underneath.window == nil || underneath.bounds.isEmpty) && ContinuousClock.now < readyDeadline {
            try await Task.sleep(for: .milliseconds(8))
        }
        XCTAssertNotNil(underneath.window)
        XCTAssertFalse(underneath.bounds.isEmpty)
        let point = CGPoint(x: size.width / 2, y: size.height / 2)
        let hit = host.view.hitTest(point, with: nil)
        XCTAssertTrue(hit === underneath || hit?.isDescendant(of: underneath) == true,
                      "The decorative painting must not acquire an input surface")
    }

    @MainActor private struct HitSurface: UIViewRepresentable {
        let view: UIView
        func makeUIView(context: Context) -> UIView { view }
        func updateUIView(_ uiView: UIView, context: Context) {}
    }

    @MainActor private func render<Content: View>(_ content: Content, size: CGSize) throws -> UIImage {
        let renderer = ImageRenderer(content: content.frame(width: size.width, height: size.height))
        renderer.scale = 1
        return try XCTUnwrap(renderer.uiImage)
    }

    @MainActor private func warmPixels(_ image: UIImage) throws -> Int {
        let raster = try XCTUnwrap(image.cgImage)
        var bytes = [UInt8](repeating: 0, count: raster.width * raster.height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: raster.width, height: raster.height,
            bitsPerComponent: 8, bytesPerRow: raster.width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(raster, in: CGRect(x: 0, y: 0, width: raster.width, height: raster.height))
        return stride(from: 0, to: bytes.count, by: 4).filter {
            Int(bytes[$0]) > Int(bytes[$0 + 2]) + 20 && bytes[$0] > 60
        }.count
    }
}
