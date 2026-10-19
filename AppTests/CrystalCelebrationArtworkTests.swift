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
        for value in [1, 3, 12, 21, 111, 999999] {
            let run = try XCTUnwrap(family.award(value))
            XCTAssertEqual(run.text, "+\(value)")
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
