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

    @MainActor func testCrowdedStoryHeaderKeepsNearFactsClearOfTheCeilingAcrossTextSizes() async throws {
        let sceneDeadline = ContinuousClock.now + .seconds(3)
        var availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        while availableScene == nil && ContinuousClock.now < sceneDeadline {
            try await Task.sleep(for: .milliseconds(20))
            availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        }
        let scene = try XCTUnwrap(availableScene, "The crowded Story probe requires a connected window scene")
        let previous = scene.windows.first(where: \.isKeyWindow)
        var crowded = FallingSky.freshChallenge(.firstLight)
        XCTAssertEqual(crowded.challengeRevision, 4)
        for _ in 0..<4 { _ = try XCTUnwrap(crowded.letStarsFall()) }
        let profiles: [(DynamicTypeSize, UIContentSizeCategory, String)] = [
            (.large, .large, "large"), (.xxxLarge, .extraExtraExtraLarge, "xxxLarge"),
            (.accessibility5, .accessibilityExtraExtraExtraLarge, "AX5")
        ]
        for (textSize, category, name) in profiles {
            let suite = "Starfall.CrowdedHeader.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            defaults.set(try SkySaveArchive.encode(crowded), forKey: SkySaveArchive.key)
            defaults.set(false, forKey: "calmEffects"); defaults.set(false, forKey: "soundEnabled")
            let clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], clock: clock)
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
            var observed: [StarlightAnchor: CGRect] = [:]
            let host = UIHostingController(rootView: FallingSkyView(store: store,
                flow: SkyFlowState(arguments: ["--starfalls-reset", "--technique-review"]))
                .defaultAppStorage(defaults)
                .environment(\.scenePhase, .active)
                .environment(\.dynamicTypeSize, textSize)
                .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                    GeometryReader { geometry in
                        let origin = geometry.frame(in: .global).origin
                        let rects = anchors.mapValues { geometry[$0].offsetBy(dx: origin.x, dy: origin.y) }
                        Color.clear.onAppear { observed = rects }
                            .onChange(of: rects) { _, value in observed = value }
                    }.allowsHitTesting(false)
                })
            let container = UIViewController()
            window.rootViewController = container; container.view.frame = window.bounds
            container.addChild(host); host.view.frame = container.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.view.addSubview(host.view); host.didMove(toParent: container)
            window.makeKeyAndVisible()
            defer { store.setSuspended(true); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
            let ready = ContinuousClock.now + .seconds(3)
            while (!store.sceneReady || store.suspended || store.scene.view == nil ||
                   observed[.board] == nil || observed[.header] == nil || observed[.score] == nil) && ContinuousClock.now < ready {
                try await Task.sleep(for: .milliseconds(20))
            }
            XCTAssertTrue(store.sceneReady); XCTAssertFalse(store.suspended)
            let canvas = try XCTUnwrap(store.scene.view)
            var ancestor: UIView? = canvas
            while ancestor != nil && !(ancestor is UIScrollView) { ancestor = ancestor?.superview }
            let scroll = ancestor as? UIScrollView
            let physicalScale = window.screen.scale
            func physicalEdges(_ frame: CGRect) -> [CGFloat] {
                [frame.minX, frame.minY, frame.maxX, frame.maxY].map { ($0 * physicalScale).rounded() }
            }
            func sameCanvasProjection(_ frame: CGRect?) -> Bool {
                guard let frame else { return false }
                let actual = window.convert(canvas.bounds, from: canvas)
                // Independent global bounding-box conversions may differ by an
                // ulp. Placement is exact on the physical grid; local dimensions
                // remain exact in the separate native/SpriteKit assertion.
                return frame.origin == actual.origin && physicalEdges(frame) == physicalEdges(actual)
            }
            func viewport() -> CGRect {
                window.bounds.intersection(scroll.map { window.convert($0.bounds, from: $0) } ?? window.bounds)
            }
            func visibleStars() -> Int {
                guard let board = observed[.board], let header = observed[.header] else { return 0 }
                let mapping = LandingGeometry(size: canvas.bounds.size)
                return (0..<49).filter { index in
                    let cell = Cell(index / 7, index % 7)
                    let frame = mapping.frame(cell).offsetBy(dx: board.minX, dy: board.minY)
                    return crowded.gem(at: cell) != nil && viewport().contains(frame) && !header.intersects(frame)
                }.count
            }
            func capture(_ stage: String) {
                let facts = XCTAttachment(string: "textSize=\(textSize); window=\(window.bounds); host=\(window.convert(host.view.bounds, from: host.view)); anchors=\(observed); canvas=\(window.convert(canvas.bounds, from: canvas)); canvasBounds=\(canvas.bounds); sceneSize=\(store.scene.size); viewport=\(viewport()); scrollOffset=\(String(describing: scroll?.contentOffset)); visibleOccupiedCells=\(visibleStars()); sceneReady=\(store.sceneReady); suspended=\(store.suspended); calmEffects=false; inheritedSystemReduceMotion=\(UIAccessibility.isReduceMotionEnabled); static committed four-shower Lantern, no pan or animation claim")
                facts.name = "crowded-story-\(name)-\(stage)-frames"; facts.lifetime = .keepAlways; add(facts)
                let image = XCTAttachment(image: windowImage(window))
                image.name = "crowded-story-\(name)-\(stage)"; image.lifetime = .keepAlways; add(image)
            }
            let placementDeadline = ContinuousClock.now + .seconds(3)
            var lastBoard: CGRect?, lastHeader: CGRect?, lastOffset: CGPoint?, stableSamples = 0
            while stableSamples < 2 && ContinuousClock.now < placementDeadline {
                await Task.yield(); host.view.layoutIfNeeded()
                let board = observed[.board], header = observed[.header], offset = scroll?.contentOffset
                if board != nil, header != nil, board == lastBoard, header == lastHeader, offset == lastOffset,
                   sameCanvasProjection(board), visibleStars() >= 7 {
                    stableSamples += 1
                } else { stableSamples = 0 }
                lastBoard = board; lastHeader = header; lastOffset = offset
                if stableSamples < 2 { try await Task.sleep(for: .milliseconds(20)) }
            }
            capture("initial")
            XCTAssertEqual(stableSamples, 2, "Initial crowded \(name) placement must settle on at least seven fully visible actual stars")
            XCTAssertGreaterThanOrEqual(visibleStars(), 7, "Crowded \(name) must retain a playable native star field")

            // Reveal the real ceiling through its existing scroll owner. This
            // proves layout extent and separation, not native pan acceptance.
            if let scroll {
                scroll.setContentOffset(CGPoint(x: scroll.contentOffset.x, y: -scroll.adjustedContentInset.top), animated: false)
                let ceilingDeadline = ContinuousClock.now + .seconds(2)
                stableSamples = 0; lastBoard = nil; lastOffset = nil
                while stableSamples < 2 && ContinuousClock.now < ceilingDeadline {
                    await Task.yield(); host.view.layoutIfNeeded()
                    let board = observed[.board], offset = scroll.contentOffset
                    if board != nil, board == lastBoard, offset == lastOffset,
                       offset.y == -scroll.adjustedContentInset.top,
                       sameCanvasProjection(board) { stableSamples += 1 }
                    else { stableSamples = 0 }
                    lastBoard = board; lastOffset = offset
                    if stableSamples < 2 { try await Task.sleep(for: .milliseconds(20)) }
                }
                XCTAssertEqual(stableSamples, 2, "The actual scroll owner must settle with the complete ceiling revealed")
            }
            capture("ceiling-revealed")
            let board = try XCTUnwrap(observed[.board]), header = try XCTUnwrap(observed[.header])
            let score = try XCTUnwrap(observed[.score])
            let snapshot = try XCTUnwrap(SkyCeilingSnapshot(game: store.game, mapping: LandingGeometry(size: canvas.bounds.size)))
            let markerHeight = UIFontMetrics(forTextStyle: .caption1).scaledValue(
                for: SkyCeilingOverlay.baseMarkerHeight,
                compatibleWith: UITraitCollection(preferredContentSizeCategory: category))
            let clearance = SkyCeilingOverlay.requiredTopClearance(markerHeight: markerHeight)
            let ceiling = CGRect(x: board.minX + snapshot.arena.minX,
                                 y: board.minY + snapshot.arena.minY - clearance,
                                 width: snapshot.arena.width, height: clearance)
            let geometry = XCTAttachment(string: "header=\(header); score=\(score); actualCanvas=\(board); sharedCeiling=\(ceiling); scaledMarkerHeight=\(markerHeight); clearance=\(clearance); viewport=\(viewport()); fullyVisibleOccupiedCells=\(visibleStars())")
            geometry.name = "crowded-story-\(name)-ceiling-geometry"; geometry.lifetime = .keepAlways; add(geometry)
            XCTAssertTrue(window.bounds.contains(header), "The complete \(name) header must fit the native window")
            XCTAssertTrue(header.contains(score), "The complete score must remain inside the crowded header")
            XCTAssertTrue(markerHeight.isFinite && markerHeight > 0)
            XCTAssertTrue(viewport().contains(ceiling), "The complete scaled \(name) ceiling must be reachable")
            XCTAssertLessThanOrEqual(header.maxY, ceiling.minY, "The crowded header must not cover the actual ceiling or scaled badges")
            XCTAssertFalse(header.intersects(ceiling))
            XCTAssertGreaterThanOrEqual(visibleStars(), 7, "Revealing the crowded \(name) ceiling must retain seven fully visible actual stars")
            let actualCanvas = window.convert(canvas.bounds, from: canvas)
            XCTAssertEqual(board.origin, actualCanvas.origin)
            XCTAssertEqual(physicalEdges(board), physicalEdges(actualCanvas))
            let projection = XCTAttachment(string: "rawAnchor=\(board); rawNative=\(actualCanvas); actualScreenScale=\(physicalScale); anchorPixelEdges=\(physicalEdges(board)); nativePixelEdges=\(physicalEdges(actualCanvas)); exactLocalCanvas=\(canvas.bounds.size); exactLocalScene=\(store.scene.size)")
            projection.name = "crowded-story-\(name)-physical-projection"; projection.lifetime = .keepAlways; add(projection)
            XCTAssertEqual(canvas.bounds.size, store.scene.size, "Header reflow must retain the native SpriteKit projection")
            XCTAssertEqual(snapshot.warnings.filter { $0.pressure == .full }.map(\.number), [2])
            XCTAssertEqual(snapshot.warnings.filter { $0.pressure == .oneSpace }.map(\.number), [1, 3, 4, 5, 6])
            XCTAssertEqual(store.game, crowded); XCTAssertEqual(clock.now, 0)
        }
    }

    @MainActor func testBusySetupPreservesHeaderWhileInspectionIsMuted() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        for textSize in [DynamicTypeSize.large, .accessibility5] {
            let suite = "Starfall.BusyHUD.\(UUID())", defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let opening = FallingSky.freshChallenge(.seedMoon)
            defaults.set(try SkySaveArchive.encode(opening), forKey: SkySaveArchive.key)
            defaults.set(false, forKey: "calmEffects"); defaults.set(false, forKey: "soundEnabled")
            let presenter = FallingSkyRecorder(), clock = ManualRainClock()
            let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: clock)
            let initialForecast = store.forecast
            let window = UIWindow(windowScene: scene)
            window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
            var observedHeader: CGRect?, observedBoard: CGRect?
            let host = UIHostingController(rootView: FallingSkyView(store: store,
                flow: SkyFlowState(arguments: ["--starfalls-reset", "--technique-review"]))
                .defaultAppStorage(defaults)
                .environment(\.scenePhase, .active)
                .environment(\.dynamicTypeSize, textSize)
                .overlayPreferenceValue(StarlightAnchors.self) { anchors in
                    GeometryReader { geometry in
                        let rect = anchors[.header].map { geometry[$0].offsetBy(
                            dx: geometry.frame(in: .global).minX, dy: geometry.frame(in: .global).minY) }
                        let boardRect = anchors[.board].map { geometry[$0].offsetBy(
                            dx: geometry.frame(in: .global).minX, dy: geometry.frame(in: .global).minY) }
                        Color.clear.onAppear { observedHeader = rect; observedBoard = boardRect }
                            .onChange(of: rect) { _, value in observedHeader = value }
                            .onChange(of: boardRect) { _, value in observedBoard = value }
                    }.allowsHitTesting(false)
                })
            let container = UIViewController()
            window.rootViewController = container; container.view.frame = window.bounds
            container.addChild(host); host.view.frame = container.view.bounds
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.view.addSubview(host.view); host.didMove(toParent: container); window.makeKeyAndVisible()
            defer { store.setSuspended(true); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
            let ready = ContinuousClock.now + .seconds(3)
            var lastHeader: CGRect?, stableSamples = 0
            while stableSamples < 2 && ContinuousClock.now < ready {
                await Task.yield(); host.view.layoutIfNeeded()
                if store.sceneReady, !store.suspended, store.isPaused { store.togglePause() }
                if store.sceneReady, !store.suspended, let header = observedHeader, header == lastHeader {
                    stableSamples += 1
                } else { stableSamples = 0 }
                lastHeader = observedHeader
                if stableSamples < 2 { try await Task.sleep(for: .milliseconds(20)) }
            }
            XCTAssertEqual(stableSamples, 2); XCTAssertFalse(store.busy)
            XCTAssertEqual(store.game, opening); XCTAssertEqual(store.forecast, initialForecast)
            XCTAssertFalse(store.isPaused)
            let initialDeadline = try XCTUnwrap(clock.deadline, "The admitted, explicitly started sky owns a real deadline")
            let header = try XCTUnwrap(observedHeader)
            XCTAssertTrue(window.bounds.contains(header))
            // The recorder holds completion; draw the real committed snapshot
            // through the existing scene owner rather than claiming motion.
            store.scene.render(store.game)
            if textSize.isAccessibilitySize {
                let canvas = try XCTUnwrap(store.scene.view)
                var ancestor: UIView? = canvas
                while ancestor != nil && !(ancestor is UIScrollView) { ancestor = ancestor?.superview }
                let scroll = try XCTUnwrap(ancestor as? UIScrollView)
                let placementDeadline = ContinuousClock.now + .seconds(2)
                var previousBoard: CGRect?, previousOffset: CGPoint?, placementSamples = 0, visible = 0
                while placementSamples < 2 && ContinuousClock.now < placementDeadline {
                    await Task.yield(); host.view.layoutIfNeeded()
                    let board = observedBoard, offset = scroll.contentOffset
                    let viewport = window.convert(scroll.bounds, from: scroll)
                    visible = board.map { bounds in
                        let mapping = LandingGeometry(size: bounds.size)
                        return (0..<49).filter { index in
                            let cell = Cell(index / 7, index % 7)
                            return opening.gem(at: cell) != nil && viewport.contains(mapping.frame(cell)
                                .offsetBy(dx: bounds.minX, dy: bounds.minY))
                        }.count
                    } ?? 0
                    if board == previousBoard, offset == previousOffset,
                       board == window.convert(canvas.bounds, from: canvas), visible >= 7 {
                        placementSamples += 1
                    } else { placementSamples = 0 }
                    previousBoard = board; previousOffset = offset
                    if placementSamples < 2 { try await Task.sleep(for: .milliseconds(20)) }
                }
                XCTAssertEqual(placementSamples, 2,
                    "Initial AX5 placement must settle on actual opening stars: board=\(String(describing: observedBoard)); offset=\(scroll.contentOffset); visible=\(visible)")
                let placement = XCTAttachment(string: "board=\(String(describing: observedBoard)); canvas=\(window.convert(canvas.bounds, from: canvas)); viewport=\(window.convert(scroll.bounds, from: scroll)); offset=\(scroll.contentOffset); fullyVisibleOccupiedCells=\(visible)")
                placement.name = "busy-hud-initial-AX5-placement"; placement.lifetime = .keepAlways; add(placement)
            }
            func capture(_ phase: String, busy: Bool) async throws {
                let game = store.game, forecast = store.forecast, generation = store.constellationInputGeneration
                let deadline = clock.deadline, now = clock.now, saved = defaults.data(forKey: SkySaveArchive.key)
                let source = try XCTUnwrap(SkyForecastInspection.Source(game: game, generation: generation,
                    forecast: forecast, arriving: store.showerCountdown.arriving))
                await Task.yield(); host.view.layoutIfNeeded()
                let image = windowImage(window)
                XCTAssertEqual(store.busy, busy); XCTAssertFalse(store.suspended)
                XCTAssertEqual(observedHeader, header, "Busy state must preserve the actual full-root header")
                XCTAssertEqual(store.game, game); XCTAssertEqual(store.forecast, forecast)
                XCTAssertEqual(store.constellationInputGeneration, generation)
                XCTAssertEqual(SkyForecastInspection.Source(game: store.game, generation: store.constellationInputGeneration,
                    forecast: store.forecast, arriving: store.showerCountdown.arriving), source)
                XCTAssertEqual(clock.deadline, deadline); XCTAssertEqual(clock.now, now)
                XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
                let category = textSize == .large ? "default" : "AX5"
                let attachment = XCTAttachment(image: image)
                attachment.name = "busy-hud-held-presenter-static-\(category)-\(phase)"
                attachment.lifetime = .keepAlways; add(attachment)
                let facts = XCTAttachment(string: "busy=\(store.busy); header=\(header); source=\(source); deadline=\(String(describing: deadline)); pauseGlyph=20pt; helpGlyph=24pt; source disables inspection only; native disabled touch/focus unperformed")
                facts.name = "busy-hud-state-\(category)-\(phase)"; facts.lifetime = .keepAlways; add(facts)
            }
            try await capture("before", busy: false)
            var expected = opening
            let turn = try XCTUnwrap(expected.nudge(from: Cell(0, 1), to: Cell(1, 1)))
            XCTAssertTrue(turn.resolutionPhases.isEmpty); XCTAssertEqual(turn.displayAward, 0)
            XCTAssertTrue(store.requestInput(.swap(Cell(0, 1), Cell(1, 1)), snapshot: store.game,
                                             generation: store.constellationInputGeneration))
            XCTAssertEqual(store.game, expected); XCTAssertEqual(store.game.displayScore, 0)
            XCTAssertEqual(store.game.displayTarget, 11_000); XCTAssertEqual(store.forecast, initialForecast)
            XCTAssertFalse(store.showerCountdown.arriving); XCTAssertTrue(store.busy)
            XCTAssertEqual(presenter.completions.count, 1)
            store.scene.render(store.game)
            try await capture("busy", busy: true)
            presenter.finish()
            XCTAssertFalse(store.busy); XCTAssertEqual(store.game, expected)
            store.scene.render(store.game)
            try await capture("after", busy: false)
            XCTAssertEqual(presenter.completions.count, 1); XCTAssertEqual(clock.deadline, initialDeadline)
        }
    }

    /// Render-boundary diagnostic; actual private menu presentation is exercised
    /// by the native Open Sky case. This method never simulates a cover.
    @MainActor func testActualOpenSkySceneAcrossFiveStarsEmptySuspensionAndNextShower() async throws {
        executionTimeAllowance = 30
        let sceneDeadline = ContinuousClock.now + .seconds(3)
        var available = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        while available == nil && ContinuousClock.now < sceneDeadline {
            try await Task.sleep(for: .milliseconds(20))
            available = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        }
        let owner = try XCTUnwrap(available), previous = owner.windows.first(where: \.isKeyWindow)
        let suite = "Starfall.EmptySceneBoundary.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "calmEffects"); defaults.set(false, forKey: "soundEnabled")
        let arguments = ["--starfalls-reset", "--dialogue-review", "--constellation-fixture=horizontalFive"]
        let clock = ManualRainClock()
        let store = FallingSkyStore(defaults: defaults, arguments: arguments, clock: clock)
        let window = UIWindow(windowScene: owner)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        var anchors: [StarlightAnchor: CGRect] = [:]
        let host = UIHostingController(rootView: FallingSkyView(store: store, flow: SkyFlowState(arguments: arguments))
            .defaultAppStorage(defaults).environment(\.scenePhase, .active)
            .environment(\.dynamicTypeSize, .large)
            .overlayPreferenceValue(StarlightAnchors.self) { values in
                GeometryReader { geometry in
                    let origin = geometry.frame(in: .global).origin
                    let resolved = values.mapValues { geometry[$0].offsetBy(dx: origin.x, dy: origin.y) }
                    Color.clear.onAppear { anchors = resolved }.onChange(of: resolved) { _, value in anchors = value }
                }.allowsHitTesting(false)
            })
        let container = UIViewController()
        window.rootViewController = container; container.view.frame = window.bounds
        container.addChild(host); host.view.frame = container.view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.view.addSubview(host.view); host.didMove(toParent: container); window.makeKeyAndVisible()
        defer { store.setSuspended(true); window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        func observe(_ phase: String, suspended: Bool) async throws {
            let deadline = ContinuousClock.now + .seconds(3)
            var previousFrame: CGRect?, stable = 0
            while stable < 2 && ContinuousClock.now < deadline {
                await Task.yield(); host.view.layoutIfNeeded()
                let frame = store.scene.view.map { window.convert($0.bounds, from: $0) }
                if store.sceneReady, !store.busy, store.suspended == suspended,
                   store.scene.view?.window === window, frame == previousFrame, anchors[.board] != nil {
                    stable += 1
                } else { stable = 0 }
                previousFrame = frame
                if stable < 2 { try await Task.sleep(for: .milliseconds(20)) }
            }
            XCTAssertEqual(stable, 2, "Real scene attachment and committed placement must settle: \(phase)")
            let canvas = try XCTUnwrap(store.scene.view)
            let game = store.game, generation = store.constellationInputGeneration
            let saved = defaults.data(forKey: SkySaveArchive.key), deadlineBefore = clock.deadline
            let capture = XCTAttachment(image: windowImage(window))
            capture.name = "open-sky-render-boundary-\(phase)"; capture.lifetime = .keepAlways; add(capture)
            let children = store.scene.children.map {
                "\(type(of: $0)):name=\($0.name ?? "nil"),children=\($0.children.count),alpha=\($0.alpha),hidden=\($0.isHidden),actions=\($0.hasActions())"
            }
            var ancestors: [String] = []
            var ancestor: UIView? = canvas
            for depth in 0..<12 {
                guard let view = ancestor else { break }
                ancestors.append("depth=\(depth); type=\(type(of: view)); frame=\(view.frame); windowFrame=\(window.convert(view.bounds, from: view)); background=\(String(describing: view.backgroundColor)); opaque=\(view.isOpaque); alpha=\(view.alpha); hidden=\(view.isHidden); layerBackground=\(String(describing: view.layer.backgroundColor)); layerOpaque=\(view.layer.isOpaque); layerOpacity=\(view.layer.opacity)")
                if view === host.view || view === container.view { break }
                ancestor = view.superview
            }
            let layers = "viewBackground=\(String(describing: canvas.backgroundColor)); viewOpaque=\(canvas.isOpaque); allowsTransparency=\(canvas.allowsTransparency); viewAlpha=\(canvas.alpha); hidden=\(canvas.isHidden); layerBackground=\(String(describing: canvas.layer.backgroundColor)); layerOpaque=\(canvas.layer.isOpaque); layerOpacity=\(canvas.layer.opacity); layerType=\(type(of: canvas.layer)); presentationOpacity=\(String(describing: canvas.layer.presentation()?.opacity))"
            let facts = XCTAttachment(string: "phase=\(phase); no modal cover presented; normal motion requested; inheritedReduceMotion=\(UIAccessibility.isReduceMotionEnabled); occupied=\(game.board.compactMap { $0 }.count); score=\(game.displayScore); turns=\(game.turns); suspended=\(store.suspended); paused=\(store.isPaused); busy=\(store.busy); sceneReady=\(store.sceneReady); scenePaused=\(store.scene.isPaused); sceneBackground=\(store.scene.backgroundColor); sceneSize=\(store.scene.size); canvasBounds=\(canvas.bounds); canvasWindowFrame=\(window.convert(canvas.bounds, from: canvas)); anchors=\(anchors); hostBackground=\(String(describing: host.view.backgroundColor)); hostOpaque=\(host.view.isOpaque); children=\(children); ancestors=\(ancestors); \(layers)")
            facts.name = "open-sky-render-properties-\(phase)"; facts.lifetime = .keepAlways; add(facts)
            // Observation may not commit, resume rain, alter saved state or
            // replace the genuine snapshot; layer values above are diagnostics.
            XCTAssertEqual(store.game, game); XCTAssertEqual(store.constellationInputGeneration, generation)
            XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), saved)
            XCTAssertEqual(clock.deadline, deadlineBefore); XCTAssertEqual(clock.now, 0)
            XCTAssertTrue(store.isPaused); XCTAssertEqual(store.suspended, suspended)
            XCTAssertEqual(canvas.bounds.size, store.scene.size)
        }
        try await observe("five-live", suspended: false)
        let opening = store.game, world = store.journey.journey
        XCTAssertEqual(opening, ConstellationFixture.horizontalFive.game().adoptingFeedingDusk())
        XCTAssertEqual(opening.board.compactMap { $0 }.count, 5)
        var expected = opening
        let path = (0..<5).map { Cell(0, $0) }
        let cleared = try XCTUnwrap(expected.clearConstellation(path))
        XCTAssertEqual(cleared.collected, 5)
        store.clearTracedConstellation(path, snapshot: store.game, generation: store.constellationInputGeneration)
        XCTAssertEqual(store.game, expected)
        try await observe("empty-live", suspended: false)
        XCTAssertEqual(store.game.board.compactMap { $0 }.count, 0); XCTAssertEqual(store.game.displayScore, 5)
        let recap = try XCTUnwrap(store.lastClear), emptySave = defaults.data(forKey: SkySaveArchive.key)
        store.setSuspended(true)
        try await observe("empty-store-suspended-without-cover", suspended: true)
        XCTAssertEqual(store.game, expected); XCTAssertEqual(store.lastClear, recap)
        XCTAssertEqual(defaults.data(forKey: SkySaveArchive.key), emptySave)
        store.setSuspended(false)
        try await observe("empty-resumed-without-cover", suspended: false)
        let arrival = try XCTUnwrap(expected.letStarsFall())
        XCTAssertEqual(arrival.collected, 0)
        store.callShower()
        XCTAssertEqual(store.game, expected)
        try await observe("one-no-award-shower", suspended: false)
        XCTAssertGreaterThan(store.game.board.compactMap { $0 }.count, 0)
        XCTAssertEqual(store.game.displayScore, 5); XCTAssertEqual(store.lastClear, recap)
        XCTAssertEqual(store.journey.journey, world)
        XCTAssertEqual(SkySaveArchive.load(from: defaults), store.game)
    }

    @MainActor func testNativeSceneTransferRejectsRetiringHostUpdatesAndTeardown() {
        // Isolated real SKView ownership proof. Actual private-menu dismissal,
        // input re-admission and clock preservation remain native journey gates.
        let frame = CGRect(x: 0, y: 0, width: 390, height: 900)
        let first = FallingSkyScene(size: frame.size), second = FallingSkyScene(size: frame.size)
        let old = FallingSkySceneSurface.Surface(frame: frame)
        let replacement = FallingSkySceneSurface.Surface(frame: frame)
        var firstReadiness: [Bool] = [], secondReadiness: [Bool] = []
        first.onReadinessChanged = { firstReadiness.append($0) }
        second.onReadinessChanged = { secondReadiness.append($0) }
        defer { old.releaseScene(); replacement.releaseScene() }

        old.install(first)
        XCTAssertTrue(first.view === old); XCTAssertTrue(old.scene === first)
        XCTAssertEqual(first.size, frame.size); XCTAssertEqual(old.bounds.size, frame.size)
        XCTAssertEqual(firstReadiness.last, true, "The positive-size native attachment must report ready")

        replacement.install(first)
        XCTAssertNil(old.scene, "Transfer must clear the retiring SKView before the new attachment")
        XCTAssertTrue(first.view === replacement); XCTAssertTrue(replacement.scene === first)
        XCTAssertEqual(first.size, replacement.bounds.size); XCTAssertEqual(first.size, frame.size)
        XCTAssertTrue(firstReadiness.contains(false), "Real detachment must report not-ready before transfer")
        XCTAssertEqual(firstReadiness.last, true, "The replacement must publish its own real readiness")
        let transferredCallbacks = firstReadiness

        old.install(first) // SwiftUI can update an already-retiring host.
        old.releaseScene() // Its later dismantle must also leave the new owner intact.
        XCTAssertNil(old.scene)
        XCTAssertTrue(first.view === replacement); XCTAssertTrue(replacement.scene === first)
        XCTAssertEqual(firstReadiness, transferredCallbacks,
                       "Stale update/teardown must not detach, reattach or emit a false readiness callback")
        XCTAssertEqual(first.size, replacement.bounds.size); XCTAssertEqual(first.size, frame.size)

        replacement.install(second) // A genuinely different request on the same view must work.
        XCTAssertNil(first.view); XCTAssertEqual(firstReadiness.last, false)
        XCTAssertTrue(second.view === replacement); XCTAssertTrue(replacement.scene === second)
        XCTAssertEqual(second.size, replacement.bounds.size); XCTAssertEqual(second.size, frame.size)
        XCTAssertEqual(secondReadiness.last, true)
        let replacementCallbacks = secondReadiness
        let retiredCallbacks = firstReadiness
        old.install(first); old.releaseScene()
        XCTAssertNil(old.scene); XCTAssertNil(first.view)
        XCTAssertTrue(second.view === replacement); XCTAssertTrue(replacement.scene === second)
        XCTAssertEqual(firstReadiness, retiredCallbacks); XCTAssertEqual(secondReadiness, replacementCallbacks)

        replacement.releaseScene()
        XCTAssertNil(replacement.scene); XCTAssertNil(second.view)
        XCTAssertEqual(secondReadiness.last, false, "Only current-owner teardown must detach the scene")
        XCTAssertGreaterThan(secondReadiness.count, replacementCallbacks.count)
        XCTAssertEqual(first.size, frame.size); XCTAssertEqual(second.size, frame.size)
        let facts = XCTAttachment(string: "Isolated native SKView transfer only; no game menu, Store or clock exercised. frame=\(frame); firstReadiness=\(firstReadiness); secondReadiness=\(secondReadiness)")
        facts.name = "native-scene-transfer-readiness"; facts.lifetime = .keepAlways; add(facts)
    }

    @MainActor private func windowImage(_ window: UIWindow) -> UIImage {
        UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

}
