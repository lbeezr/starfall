import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class SkyReadingPlayfieldTests: XCTestCase {
    @MainActor func testReadingPlayfieldKeepsSceneryAndReceiptAnchorsFixedWhileTheNativeBoardScrolls() async throws {
        let sceneDeadline = ContinuousClock.now + .seconds(3)
        var availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        while availableScene == nil && ContinuousClock.now < sceneDeadline {
            try await Task.sleep(for: .milliseconds(20))
            availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        }
        let scene = try XCTUnwrap(availableScene, "The isolated hosted probe requires a connected window scene")
        let previous = scene.windows.first(where: \.isKeyWindow)
        for size in [CGSize(width: 375, height: 667), CGSize(width: 1024, height: 1366)] {
            let suite = "Starfall.ReadingAnchors.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let opening = FallingSky.freshChallenge(.firstLight)
            defaults.set(try SkySaveArchive.encode(opening), forKey: SkySaveArchive.key)
            defaults.set(false, forKey: "calmEffects")
            defaults.set(false, forKey: "soundEnabled")
            let store = FallingSkyStore(defaults: defaults, arguments: [], clock: ManualRainClock())
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(origin: .zero, size: size)
            let pixel = 1 / window.screen.scale
            var observed: [StarlightAnchor: CGRect] = [:]
            let host = UIHostingController(rootView: FallingSkyView(store: store,
                flow: SkyFlowState(arguments: ["--starfalls-reset", "--technique-review"]))
                .defaultAppStorage(defaults)
                .environment(\.scenePhase, .active)
                .environment(\.dynamicTypeSize, .accessibility5)
                .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                    GeometryReader { geometry in
                        let origin = geometry.frame(in: .global).origin
                        let rects = anchors.mapValues { geometry[$0].offsetBy(dx: origin.x, dy: origin.y) }
                        Color.clear.onAppear { observed = rects }
                            .onChange(of: rects) { _, value in observed = value }
                    }.allowsHitTesting(false)
                })
            let container = UIViewController()
            window.rootViewController = container
            container.view.frame = window.bounds
            container.addChild(host)
            host.view.frame = container.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.view.addSubview(host.view); host.didMove(toParent: container)
            window.makeKeyAndVisible()
            defer { store.setSuspended(true); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
            let ready = ContinuousClock.now + .seconds(3)
            while (!store.sceneReady || store.suspended || observed[.constellationReturn] == nil) && ContinuousClock.now < ready {
                try await Task.sleep(for: .milliseconds(20))
            }
            XCTAssertTrue(store.sceneReady); XCTAssertFalse(store.suspended)
            let canvas = try XCTUnwrap(store.scene.view)
            var ancestor: UIView? = canvas
            while ancestor != nil && !(ancestor is UIScrollView) { ancestor = ancestor?.superview }
            let scroll = try XCTUnwrap(ancestor as? UIScrollView)
            func visibleOpeningStars(in board: CGRect, viewport: CGRect) -> Int {
                let mapping = LandingGeometry(size: board.size)
                return (0..<49).filter { index in
                    let cell = Cell(index / 7, index % 7)
                    return opening.gem(at: cell) != nil && viewport.contains(mapping.frame(cell)
                        .offsetBy(dx: board.minX, dy: board.minY))
                }.count
            }
            let placementDeadline = ContinuousClock.now + .seconds(2)
            var previousBoard: CGRect?, previousOffset: CGPoint?, stableSamples = 0
            while stableSamples < 2 && ContinuousClock.now < placementDeadline {
                await Task.yield(); host.view.layoutIfNeeded()
                let currentBoard = observed[.board], currentOffset = scroll.contentOffset
                let visible = currentBoard.map { visibleOpeningStars(in: $0, viewport: window.convert(scroll.bounds, from: scroll)) } ?? 0
                if currentBoard == previousBoard, currentOffset == previousOffset,
                   currentBoard == window.convert(canvas.bounds, from: canvas), size.width >= 400 || visible >= 7 {
                    stableSamples += 1
                } else { stableSamples = 0 }
                previousBoard = currentBoard; previousOffset = currentOffset
                if stableSamples < 2 { try await Task.sleep(for: .milliseconds(20)) }
            }
            let board = try XCTUnwrap(observed[.board]), header = try XCTUnwrap(observed[.header])
            let score = try XCTUnwrap(observed[.score]), returnBand = try XCTUnwrap(observed[.constellationReturn])
            let light = try XCTUnwrap(observed[.restorationLight]), scenery = try XCTUnwrap(observed[.restorationScenery])
            let variant = "\(Int(size.width))x\(Int(size.height))-maximum-text"
            let frames = "window=\(window.bounds); host=\(window.convert(host.view.bounds, from: host.view)); header=\(header); score=\(score); return=\(returnBand); board=\(board); light=\(light); scenery=\(scenery)"
            let frameAttachment = XCTAttachment(string: frames)
            frameAttachment.name = "reading-layout-\(variant)"; frameAttachment.lifetime = .keepAlways; add(frameAttachment)
            let initialCapture = XCTAttachment(image: windowImage(window))
            initialCapture.name = "reading-before-assertions-\(variant)"; initialCapture.lifetime = .keepAlways; add(initialCapture)
            XCTAssertEqual(stableSamples, 2, "Initial reading placement must settle on actual opening stars: \(frames)")
            XCTAssertTrue(window.bounds.contains(header), "The complete header must fit its window: \(frames)")
            XCTAssertTrue(header.contains(score), "The score must fit its measured header: \(frames)")
            var measurementDiagnostics: [String] = []
            func attachedSize<Content: View>(of content: Content, width: CGFloat, label: String) -> CGSize {
                let measure = UIHostingController(rootView: content.environment(\.dynamicTypeSize, .accessibility5))
                // Measure content in a sibling host; only the live game retains
                // the window's safe-area layout and full-screen presentation.
                measure.safeAreaRegions = []
                container.addChild(measure)
                measure.view.frame = CGRect(x: 0, y: 0, width: width, height: window.bounds.height)
                measure.view.isHidden = true; container.view.addSubview(measure.view); measure.didMove(toParent: container)
                defer { measure.willMove(toParent: nil); measure.view.removeFromSuperview(); measure.removeFromParent() }
                measure.view.layoutIfNeeded()
                let measured = measure.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
                measurementDiagnostics.append("\(label): rawSize=\(measured); safeAreaInsets=\(measure.view.safeAreaInsets); traits=\(measure.traitCollection)")
                return measured
            }
            let nativeLine = attachedSize(of: Text(opening.displayScore.formatted())
                .font(StarfallTheme.Typography.gameTitle).monospacedDigit(), width: score.width, label: "official serif line")
            let minimumScoreHeight = size.width < 400
                ? 2 * nativeLine.height + StarfallTheme.Spacing.compact : nativeLine.height
            let requiredScore = attachedSize(of: SkyScoreInstrument(score: opening.displayScore,
                target: opening.displayTarget, hint: ""), width: score.width, label: "complete score")
            for measured in [nativeLine, requiredScore] {
                XCTAssertTrue(measured.width.isFinite && measured.height.isFinite && measured.width > 0 && measured.height > 0,
                              "Native score measurement must produce positive finite dimensions: \(measured)")
            }
            let scoreDiagnostics = XCTAttachment(string: "allocated=\(score); attachedRequired=\(requiredScore); officialNativeLine=\(nativeLine); minimumLines=\(minimumScoreHeight); parentTraits=\(container.traitCollection); windowTraits=\(window.traitCollection); measurements=\(measurementDiagnostics.joined(separator: "; "))")
            scoreDiagnostics.name = "reading-score-measurement-\(variant)"; scoreDiagnostics.lifetime = .keepAlways; add(scoreDiagnostics)
            XCTAssertGreaterThanOrEqual(score.height + pixel, minimumScoreHeight,
                                        "The actual score must reserve complete official native serif lines")
            XCTAssertGreaterThanOrEqual(score.height + pixel, requiredScore.height,
                                        "The native score's complete content must fit its allocated width and height")
            XCTAssertTrue(window.bounds.contains(returnBand), "The fixed return must fit its window: \(frames)")
            XCTAssertFalse(returnBand.intersects(header), "Header and fixed return must remain separate: \(frames)")
            let viewport = window.convert(scroll.bounds, from: scroll)
            XCTAssertEqual(board, window.convert(canvas.bounds, from: canvas))
            XCTAssertEqual(canvas.bounds.size, store.scene.size, "Receipt sources retain the complete native canvas")
            XCTAssertFalse(returnBand.intersects(viewport), "Scrolling cells cannot cover the fixed figure return")
            let arena = LandingGeometry(size: board.size).arenaFrame.offsetBy(dx: board.minX, dy: board.minY)
            let markerHeight = UIFontMetrics(forTextStyle: .caption1).scaledValue(
                for: SkyCeilingOverlay.baseMarkerHeight,
                compatibleWith: UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge))
            let ceilingClearance = SkyCeilingOverlay.requiredTopClearance(markerHeight: markerHeight)
            XCTAssertEqual(arena.minY + scroll.contentOffset.y + scroll.adjustedContentInset.top,
                           viewport.minY + ceilingClearance, accuracy: pixel,
                           "Initial scrolling must not conceal a second unused crown in the native canvas")
            let originalOffset = scroll.contentOffset.y
            let available = scroll.contentSize.height - scroll.bounds.height - originalOffset
            if size.width < 400 {
                XCTAssertGreaterThan(scroll.contentSize.height, scroll.bounds.height,
                                     "The compact AX5 reading layout must exercise real overflow")
                XCTAssertGreaterThanOrEqual(visibleOpeningStars(in: board, viewport: viewport), 7,
                                            "Compact reading must open on fully visible actual stars")
            } else if scroll.contentSize.height <= scroll.bounds.height {
                XCTAssertTrue(viewport.contains(arena), "A tablet layout that fits must show the complete playable arena")
            }
            let distance = min(80, max(0, available))
            if distance > 0 {
                scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: originalOffset + distance), animated: false)
                let moved = ContinuousClock.now + .seconds(2)
                while observed[.board] == board && ContinuousClock.now < moved {
                    await Task.yield(); host.view.layoutIfNeeded()
                    try await Task.sleep(for: .milliseconds(20))
                }
            }
            let scrolledBoard = try XCTUnwrap(observed[.board])
            XCTAssertEqual(board.minY - scrolledBoard.minY, distance, accuracy: pixel)
            XCTAssertEqual(scrolledBoard, window.convert(canvas.bounds, from: canvas))
            for (role, expected) in [(StarlightAnchor.header, header), (.score, score), (.constellationReturn, returnBand),
                                     (.restorationLight, light), (.restorationScenery, scenery)] {
                XCTAssertEqual(observed[role], expected, "Only foreground star sources scroll; \(role) remains fixed")
            }
            XCTAssertEqual(store.game, opening, "Scrolling cannot commit a move, shower or score")
            XCTAssertTrue(store.requestInput(.swap(Cell(1, 1), Cell(1, 2)), snapshot: store.game,
                                            generation: store.constellationInputGeneration))
            XCTAssertEqual(store.game.displayScore, 15_000)
            let receiptDeadline = ContinuousClock.now + .seconds(2)
            while store.celebration == nil && ContinuousClock.now < receiptDeadline {
                try await Task.sleep(for: .milliseconds(20))
            }
            let event = try XCTUnwrap(store.celebration, "Normal presentation must publish a real committed phase receipt")
            XCTAssertFalse(event.patterns.isEmpty)
            let award = StarlightCelebrationOverlay.awardRegion(board: scrolledBoard, header: header, accessible: true)
            let layout = try XCTUnwrap(CascadeReturnLayout(event: event, board: scrolledBoard, header: header,
                                                          award: award, protectedSky: returnBand))
            XCTAssertTrue(returnBand.contains(layout.current.skyBounds))
            XCTAssertFalse(layout.current.skyBounds.intersects(header))
            XCTAssertFalse(layout.current.skyBounds.intersects(viewport))
            XCTAssertEqual(layout.current.sourcePaths.count, event.patterns.count)
            for (pattern, points) in zip(event.patterns, layout.current.sourcePaths) {
                XCTAssertEqual(points, pattern.path.map {
                    let point = LandingGeometry(size: scrolledBoard.size).viewPoint($0)
                    return CGPoint(x: point.x + scrolledBoard.minX, y: point.y + scrolledBoard.minY)
                }, "The receipt must start at the scrolled native stars")
            }
            let midlifeDeadline = ContinuousClock.now + .seconds(2)
            while store.celebration?.id == event.id, Date.now.timeIntervalSince(event.started) < 0.2,
                  ContinuousClock.now < midlifeDeadline { try await Task.sleep(for: .milliseconds(20)) }
            let receiptAge = Date.now.timeIntervalSince(event.started)
            XCTAssertEqual(store.celebration?.id, event.id, "Capture the same genuine phase receipt")
            XCTAssertGreaterThanOrEqual(receiptAge, 0.2); XCTAssertLessThanOrEqual(receiptAge, 0.6)
            let receiptState = XCTAttachment(string: "receipt=\(event.id); age=\(receiptAge); scrollOffset=\(scroll.contentOffset); viewport=\(viewport); board=\(scrolledBoard); openingStarsFullyVisible=\(visibleOpeningStars(in: scrolledBoard, viewport: viewport))")
            receiptState.name = "reading-receipt-state-\(variant)"; receiptState.lifetime = .keepAlways; add(receiptState)
            let attachment = XCTAttachment(image: windowImage(window))
            attachment.name = "reading-anchors-\(variant)"
            attachment.lifetime = .keepAlways; add(attachment)
            let settled = ContinuousClock.now + .seconds(3)
            while store.busy && ContinuousClock.now < settled { try await Task.sleep(for: .milliseconds(20)) }
            XCTAssertFalse(store.busy)
            XCTAssertEqual(observed[.board], scrolledBoard, "Earned score cannot move the native board projection")
            XCTAssertEqual(observed[.constellationReturn], returnBand)
        }
    }

    @MainActor private func windowImage(_ window: UIWindow) -> UIImage {
        UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

}
