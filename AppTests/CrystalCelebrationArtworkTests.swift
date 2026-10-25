import XCTest
import UIKit
import SwiftUI
import StarfallCore
@testable import Starfall

final class CrystalCelebrationArtworkTests: XCTestCase {
    @MainActor func testPackagedAlphabetHasEveryViewAndLoadsOnlyOnce() throws {
        let artwork = CrystalCelebrationArtwork()
        let start = CACurrentMediaTime()
        let family = try XCTUnwrap(artwork.family)
        let elapsed = CACurrentMediaTime() - start
        XCTAssertEqual(family.metrics.count, 106)
        XCTAssertEqual(Set(family.views.keys), Set(stride(from: -35, through: 35, by: 5)))
        XCTAssertLessThanOrEqual(family.decodedAtlasBytes, 64 * 1024 * 1024)
        for sprites in family.views.values {
            XCTAssertEqual(sprites.count, 105)
            for sprite in sprites.values {
                XCTAssertEqual(sprite.image.cgImage?.width, sprite.frame.w)
                XCTAssertEqual(sprite.image.cgImage?.height, sprite.frame.h)
            }
        }
        artwork.prewarm(); artwork.prewarm()
        XCTAssertEqual(artwork.loadAttempts, 1)
        let note = XCTAttachment(string: "prewarmSeconds=\(elapsed); decodedAtlasBytes=\(family.decodedAtlasBytes); glyphFrames=1575")
        note.name = "crystal-depth-cache-budget"; note.lifetime = .keepAlways; add(note)
    }

    @MainActor func testExactAwardsCatalogueAndRepeatedGlyphLayout() throws {
        let family = try XCTUnwrap(CrystalCelebrationArtwork.shared.family)
        for value in [1, 3, 12, 21, 111, 3000, 12000, 150000, 999999] {
            let run = try XCTUnwrap(family.award(value))
            XCTAssertEqual(run.text, "+\(value.formatted())")
            XCTAssertEqual(run.letters.count, run.text.count)
            XCTAssertEqual(Set(run.letters.map(\.id)).count, run.letters.count)
            XCTAssertEqual(run.letters.map(\.pen), run.letters.map(\.pen).sorted())
        }
        for text in [SkyCopy.text(.celebrationBrilliant), SkyCopy.text(.celebrationConstellation),
                     SkyCopy.text(.celebrationSquare), SkyCopy.text(.celebrationCross),
                     SkyCopy.text(.celebrationRelay, values: ["count": "12"]), "AZaz gjpq !? ÷ …"] {
            let run = try XCTUnwrap(family.run(text))
            XCTAssertEqual(run.text, text)
            for sprites in family.views.values {
                for letter in run.letters {
                    let f = try XCTUnwrap(sprites[letter.key]).frame
                    XCTAssertGreaterThanOrEqual(letter.pen + f.offsetX, 0)
                    XCTAssertLessThanOrEqual(letter.pen + f.offsetX + f.width, run.width)
                    XCTAssertGreaterThanOrEqual(run.baseline + f.offsetY, 0)
                    XCTAssertLessThanOrEqual(run.baseline + f.offsetY + f.height, run.height)
                }
            }
        }
        XCTAssertNil(family.award(0)); XCTAssertNil(family.award(-1)); XCTAssertNil(family.award(Int.max))
        XCTAssertNil(family.run("café")); XCTAssertNil(family.run("☄️")); XCTAssertNil(family.run(String(repeating: "A", count: 41)))
    }

    @MainActor func testSixFigureScoreAndTargetReflowAtLargeTextWithoutShrinking() async throws {
        let sceneDeadline = ContinuousClock.now + .seconds(3)
        var availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        while availableScene == nil && ContinuousClock.now < sceneDeadline {
            try await Task.sleep(for: .milliseconds(20))
            availableScene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        }
        let scene = try XCTUnwrap(availableScene), previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 375, height: 667)
        window.backgroundColor = UIColor(StarfallTheme.Colors.skyTop)
        let container = UIViewController()
        window.rootViewController = container; container.view.frame = window.bounds; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        let pixel = 1 / window.screen.scale
        var diagnostics: [String] = [], sizes: [String: CGSize] = [:]
        func measured<Content: View>(_ content: Content, width: CGFloat, textSize: DynamicTypeSize,
                                     label: String, capture: Bool = false) -> CGSize {
            let key = "\(label)-\(width)-\(textSize)"
            if let cached = sizes[key] { return cached }
            let host = UIHostingController(rootView: content.environment(\.dynamicTypeSize, textSize)
                .environment(\.colorScheme, .dark))
            // Plain-parent siblings inherit window traits. Measurement alone
            // ignores safe areas, which must not inflate the text requirement.
            host.safeAreaRegions = []
            container.addChild(host)
            host.view.frame = CGRect(x: 12, y: window.safeAreaInsets.top + 12, width: width, height: 600)
            host.view.backgroundColor = .clear; host.view.isHidden = !capture
            container.view.addSubview(host.view); host.didMove(toParent: container)
            defer { host.willMove(toParent: nil); host.view.removeFromSuperview(); host.removeFromParent() }
            host.view.layoutIfNeeded()
            let fitted = host.sizeThatFits(in: CGSize(width: width, height: .greatestFiniteMagnitude))
            XCTAssertTrue(fitted.width.isFinite && fitted.height.isFinite && fitted.width > 0 && fitted.height > 0,
                          "Native measurement must be positive and finite: \(key)=\(fitted)")
            diagnostics.append("\(key)=\(fitted)")
            sizes[key] = fitted
            if capture {
                host.view.frame.size = fitted; host.view.layoutIfNeeded()
                let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                let attachment = XCTAttachment(image: image)
                attachment.name = "score-component-\(key)"; attachment.lifetime = .keepAlways; add(attachment)
            }
            return fitted
        }
        func size(_ score: Int, target: Int?, width: CGFloat, textSize: DynamicTypeSize) -> CGSize {
            let capture = textSize == .accessibility5
                && ((width == 300 && ((target == 150_000 && [0, 15_000].contains(score))
                    || (target == 220_000 && score == 220_000) || (target == nil && score == 15_000)))
                    || (width == 240 && target == 150_000 && [0, 149_000].contains(score)))
            return measured(SkyScoreInstrument(score: score, target: target, hint: ""),
                width: width, textSize: textSize, label: "\(score)-of-\(target.map(String.init) ?? "none")", capture: capture)
        }
        // Retain the original above-objective and narrow-width stress cases.
        for target in [150000, 220000] {
            let regular = size(149000, target: target, width: 300, textSize: .large)
            let accessible = size(149000, target: target, width: 300, textSize: .accessibility5)
            let compact = size(219000, target: target, width: 240, textSize: .accessibility5)
            XCTAssertLessThanOrEqual(regular.width, 301)
            XCTAssertLessThanOrEqual(accessible.width, 301)
            XCTAssertLessThanOrEqual(compact.width, 241)
            XCTAssertGreaterThan(accessible.height, regular.height,
                                 "Exact six-figure totals must wrap instead of shrinking their native text")
            XCTAssertGreaterThanOrEqual(compact.height, accessible.height)
        }
        let cases: [(Int, Int?)] = [(0, 150_000), (15_000, 150_000), (149_000, 150_000), (150_000, 150_000),
                                    (219_000, 220_000), (220_000, 220_000), (0, nil), (15_000, nil), (220_000, nil)]
        for textSize in [DynamicTypeSize.large, .accessibility5] {
            // The original narrow proposals remain; 620 also exercises a wide
            // native instrument without prescribing one fixed row count.
            for width in [CGFloat(240), 300, 620] {
                var reserved: [Int: CGSize] = [:]
                for (score, target) in cases {
                    let actual = size(score, target: target, width: width, textSize: textSize)
                    let context = "score=\(score), target=\(String(describing: target)), width=\(width), text=\(textSize)"
                    XCTAssertLessThanOrEqual(actual.width, width + 1, context)
                    // Keep the complete 24-point symbol and existing 8-point gap
                    // when proposing native text; widening the symbol steals
                    // the narrow objective's final unbroken line.
                    let textWidth = width - 24 - StarfallTheme.Spacing.small
                    let earned = measured(Text(score.formatted()).font(StarfallTheme.Typography.instrumentScore)
                        .monospacedDigit().fixedSize(horizontal: false, vertical: true),
                        width: textWidth, textSize: textSize, label: "earned-\(score)")
                    let originalRole = measured(Text(score.formatted()).font(StarfallTheme.Typography.gameTitle)
                        .monospacedDigit().fixedSize(horizontal: false, vertical: true),
                        width: textWidth, textSize: textSize, label: "native-serif-\(score)")
                    XCTAssertEqual(earned, originalRole, "The shared score role retains its complete native serif font: \(context)")
                    var requiredHeight = earned.height
                    if let target {
                        let objective = measured(Text("/ \(target.formatted())")
                            .font(StarfallTheme.Typography.instrumentTarget).monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true),
                            width: textWidth, textSize: textSize, label: "objective-\(target)")
                        let originalObjective = measured(Text("/ \(target.formatted())")
                            .font(StarfallTheme.Typography.gameTitle.weight(.regular)).monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true),
                            width: textWidth, textSize: textSize, label: "native-objective-\(target)")
                        XCTAssertEqual(objective, originalObjective,
                            "The shared target role retains its complete native serif font: \(context)")
                        let inline = measured((Text("\(score.formatted()) ").font(StarfallTheme.Typography.instrumentScore)
                            + Text("/ \(target.formatted())").font(StarfallTheme.Typography.instrumentTarget))
                            .monospacedDigit().fixedSize(), width: width, textSize: textSize,
                            label: "complete-inline-\(score)-\(target)")
                        if inline.width > textWidth {
                            requiredHeight = earned.height + StarfallTheme.Spacing.compact + objective.height
                        } else { requiredHeight = max(earned.height, objective.height) }
                        if textSize.isAccessibilitySize {
                            if let first = reserved[target] {
                                XCTAssertEqual(actual, first, "Earning toward one objective preserves its reserved AX layout: \(context)")
                            } else { reserved[target] = actual }
                        }
                    }
                    XCTAssertGreaterThanOrEqual(actual.height + pixel, requiredHeight,
                        "Complete native earned/objective text must fit; only pixel rounding is allowed: \(context)")
                }
            }
        }
        let attachment = XCTAttachment(string: "Component fitting only; synthetic totals are not earned-game histories. "
            + "Optical alignment still requires whole-native-screen review. Window traits=\(window.traitCollection)\n"
            + diagnostics.joined(separator: "\n"))
        attachment.name = "score-native-font-and-boundary-measurements"; attachment.lifetime = .keepAlways; add(attachment)
    }

    @MainActor func testMalformedOrIncompleteFamilyFallsBackAndCachesFailure() throws {
        var requests = 0
        let missing = CrystalCelebrationArtwork(imageProvider: { name in
            requests += 1
            return name == "CrystalDepthZ00" ? nil : UIImage(named: name)
        })
        XCTAssertNil(missing.family); let initial = requests
        missing.prewarm(); XCTAssertNil(missing.family)
        XCTAssertEqual(requests, initial); XCTAssertEqual(missing.loadAttempts, 1)
        XCTAssertNil(CrystalCelebrationArtwork(dataProvider: { Data("{}".utf8) }).family)
        let data = try XCTUnwrap(NSDataAsset(name: "CrystalDepthMetrics")?.data)
        var source = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var views = try XCTUnwrap(source["views"] as? [[String: Any]])
        views[0]["yaw"] = 0; source["views"] = views
        let duplicate = try JSONSerialization.data(withJSONObject: source)
        XCTAssertNil(CrystalCelebrationArtwork(dataProvider: { duplicate }).family)
    }

    func testTurnIsBoundedSettlesAndQuietModesAlwaysUseFront() {
        var visited = Set<Int>()
        for index in [0, 5, 39] {
            for age in stride(from: -0.1, through: 1.4, by: 0.01) {
                let yaw = CrystalLetterMotion.yaw(age: age, index: index, quiet: false)
                XCTAssertTrue((-35...35).contains(yaw)); XCTAssertEqual(yaw % 5, 0); visited.insert(yaw)
                XCTAssertEqual(CrystalLetterMotion.yaw(age: age, index: index, quiet: true), 0)
            }
            XCTAssertEqual(CrystalLetterMotion.yaw(age: 0.8, index: index, quiet: false), 0)
            XCTAssertEqual(CrystalLetterMotion.yaw(age: 100, index: index, quiet: false), 0)
        }
        XCTAssertGreaterThan(visited.count, 6)
        XCTAssertEqual(CrystalLetterMotion.yaw(age: .nan, index: 0, quiet: false), 0)
    }

    @MainActor func testNativeSpriteFramesChangePixelsWithStableLayout() async throws {
        let family = try XCTUnwrap(CrystalCelebrationArtwork.shared.family)
        let run = try XCTUnwrap(family.run("Relay! +128"))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        let host = UIHostingController(rootView: AnyView(Color.black))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil; previous?.makeKey() }
        var normal: [Data] = [], quiet: [Data] = []
        for calm in [false, true] {
            for age in [0.02, 0.25, 0.8] {
                host.rootView = AnyView(CrystalGlyphLine(run: run, family: family, capHeight: 50,
                    maximumWidth: 350, age: age, quiet: calm)
                    .frame(width: 390, height: 844).background(StarfallTheme.Colors.skyTop))
                host.view.layoutIfNeeded()
                let rendered = expectation(description: "Native sprite view reached display")
                DispatchQueue.main.async { rendered.fulfill() }
                await fulfillment(of: [rendered], timeout: 3)
                let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
                    window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
                }
                let cg = try XCTUnwrap(image.cgImage)
                let crop = try XCTUnwrap(cg.cropping(to: CGRect(x: 20 * image.scale, y: 350 * image.scale,
                    width: 350 * image.scale, height: 150 * image.scale)))
                let pixels = try XCTUnwrap(UIImage(cgImage: crop).pngData())
                if calm { quiet.append(pixels) } else { normal.append(pixels) }
                let attachment = XCTAttachment(image: image)
                attachment.name = "crystal-depth-\(calm ? "quiet" : "normal")-\(age)"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
        XCTAssertNotEqual(normal[0], normal[1]); XCTAssertNotEqual(normal[1], normal[2])
        XCTAssertEqual(quiet[0], quiet[1]); XCTAssertEqual(quiet[1], quiet[2]); XCTAssertEqual(normal[2], quiet[2])
    }

    @MainActor func testRasterBoundsUseSourceCoordinatesAndIgnoreTransparentFringe() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 24, height: 16), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 3, y: 2, width: 7, height: 5))
            UIColor.white.withAlphaComponent(0.01).setFill(); context.fill(CGRect(x: 20, y: 13, width: 1, height: 1))
        }
        let cg = try XCTUnwrap(image.cgImage)
        XCTAssertEqual(ArtworkRaster.alphaBounds(in: cg, threshold: 160), CGRect(x: 3, y: 2, width: 7, height: 5))
        XCTAssertEqual(ArtworkRaster.alphaBounds(in: cg), CGRect(x: 3, y: 2, width: 18, height: 12))
    }
}
