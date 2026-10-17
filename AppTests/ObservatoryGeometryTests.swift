import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class ObservatoryGeometryTests: XCTestCase {
    @MainActor func testProjectionRoundTripAndSharedEdgesOnPortraitSizes() {
        for size in [CGSize(width: 375, height: 1000), CGSize(width: 440, height: 956), CGSize(width: 350, height: 610), CGSize(width: 378, height: 690), CGSize(width: 536, height: 930), CGSize(width: 768, height: 1024), CGSize(width: 1024, height: 768), CGSize(width: 375, height: 667)] {
            let mapping = ObservatoryGeometry(size: size)
            for row in 0..<7 { for column in 0..<7 {
                let cell = Cell(row, column)
                let center = mapping.viewPoint(cell)
                XCTAssertEqual(mapping.cell(at: center), cell)
                XCTAssertEqual(mapping.scenePoint(cell).x, center.x, accuracy: 0.0001)
                XCTAssertEqual(mapping.scenePoint(cell).y, size.height-center.y, accuracy: 0.0001)
                let frame = mapping.frame(cell)
                XCTAssertGreaterThanOrEqual(frame.width, 44)
                XCTAssertGreaterThanOrEqual(frame.height, 44)
                XCTAssertTrue(CGRect(origin: .zero, size: size).contains(frame))
                let polygon = mapping.polygon(cell)
                if column < 6 {
                    let next = mapping.polygon(Cell(row,column+1))
                    XCTAssertEqual(polygon[1], next[0]); XCTAssertEqual(polygon[2], next[3])
                    XCTAssertEqual(mapping.cell(at: CGPoint(x: polygon[1].x-0.1, y: polygon[1].y+0.1))?.column, column)
                }
                if row > 0 {
                    let next = mapping.polygon(Cell(row-1,column))
                    XCTAssertEqual(polygon[3], next[0]); XCTAssertEqual(polygon[2], next[1])
                }
            } }
            XCTAssertNil(mapping.cell(at: .zero))
        }
    }
    func testPortraitArtworkReachesBothScreenEdgesWithoutStretching() {
        for size in [CGSize(width: 440, height: 956), CGSize(width: 393, height: 852), CGSize(width: 375, height: 667)] {
            let rect = ObservatoryGeometry(size: size).imageRect
            XCTAssertLessThanOrEqual(rect.minY, 0.001)
            XCTAssertGreaterThanOrEqual(rect.maxY, size.height-0.001)
            XCTAssertEqual(rect.width/rect.height, ObservatoryGeometry.artworkAspect, accuracy: 0.0001)
        }
    }
    @MainActor func testLayeredArtworkIsIncludedAndTransparentLayersDecode() throws {
        for name in ["ObservatoryBackground", "ObservatoryTelescope", "ObservatoryLantern", "ObservatoryFog"] {
            let image = try XCTUnwrap(UIImage(named: name))
            let pixels = try XCTUnwrap(image.cgImage)
            XCTAssertGreaterThan(pixels.height, 1700)
            XCTAssertLessThan(pixels.height, 1900)
            if name != "ObservatoryBackground" {
                XCTAssertTrue([CGImageAlphaInfo.premultipliedFirst,.premultipliedLast,.first,.last].contains(pixels.alphaInfo))
            }
        }
    }
    @MainActor func testAmbientClockFreezesWithoutCatchUpAndPropsDoNotOverlapCells() {
        var clock = ObservatoryAmbientClock()
        clock.setRunning(true, at: 10)
        XCTAssertEqual(clock.phase(at: 12), 2)
        clock.setRunning(false, at: 12)
        XCTAssertEqual(clock.phase(at: 1000), 2)
        clock.setRunning(true, at: 1000)
        clock.setRunning(true, at: 1001)
        XCTAssertEqual(clock.phase(at: 1002), 4)
        clock.setRunning(false, at: 1002)
        XCTAssertEqual(clock.phase(at: 5000), 4)
        let mapping = ObservatoryGeometry(size: CGSize(width: 369, height: 800))
        for prop in [ObservatoryProp.telescope,.lantern] {
            let frame = mapping.propFrame(prop)
            XCTAssertGreaterThanOrEqual(frame.width,44)
            XCTAssertGreaterThanOrEqual(frame.height,44)
            for row in 0..<7 { for column in 0..<7 {
                XCTAssertFalse(frame.intersects(mapping.frame(Cell(row,column))))
            } }
        }
    }
    #if DEBUG
    @MainActor func testFixturesValidateAndRetainCastAndDeterministicFuture() throws {
        for dense in [false,true] {
            let game = ObservatoryReviewFixture.game(dense: dense)
            XCTAssertTrue(game.isValidSave)
            XCTAssertEqual(Set(game.board.compactMap { $0?.kind }), Set(Jewel.allCases))
            XCTAssertTrue(game.board.contains { $0?.isDark == true })
            XCTAssertTrue(game.board.contains { $0?.grown == true })
            var restored = try JSONDecoder().decode(FallingSky.self, from: JSONEncoder().encode(game))
            var original = game
            _ = original.clear(Cell(0,0)); _ = restored.clear(Cell(0,0))
            _ = original.letStarsFall(); _ = restored.letStarsFall()
            XCTAssertEqual(original, restored)
        }
    }
    @MainActor func testRendererPresentsCommittedCentersWithoutSquashingCast() {
        let scene = FallingSkyScene(size: CGSize(width: 378, height: 690))
        let game = ObservatoryReviewFixture.game(dense: true)
        scene.render(game)
        // Actual SpriteKit sprites use this same projection; cast textures retain their authored canvas size.
        let characters = scene.children.flatMap(\.children).compactMap { $0 as? FallingSkyCharacter }
        let sprites = characters.map(\.character)
        XCTAssertEqual(sprites.count, 49)
        for row in 0..<7 { for column in 0..<7 {
            let point = ObservatoryGeometry(size: scene.size).scenePoint(Cell(row,column))
            // SpriteKit stores node coordinates as Float; subpixel tolerance preserves the contract.
            let matches = characters.filter { hypot($0.position.x-point.x,$0.position.y-point.y) < 0.001 }
            XCTAssertEqual(matches.count,1)
        } }
        XCTAssertTrue(sprites.allSatisfy { $0.xScale == 1 && $0.yScale == 1 })
    }
    #endif
}

final class SkyShowerPlacementTests: XCTestCase {
    func testOnlyCalibratedPortraitUsesCameraMargin() {
        let phone = CGSize(width: 402, height: 778)
        XCTAssertTrue(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: phone, topInset: 62, accessible: false))
        for hardware in ["", "iPhone14,6", "iPhone17,5", "future-device"] {
            XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: hardware, size: phone, topInset: 62, accessible: false))
        }
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: phone, topInset: 62, accessible: true))
        for (size, inset) in [(CGSize(width: 874, height: 402), CGFloat(0)),
                              (CGSize(width: 768, height: 1024), CGFloat(62)),
                              (phone, CGFloat(0)), (phone, CGFloat(82)),
                              (CGSize(width: 375, height: 667), CGFloat(20))] {
            XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: size, topInset: inset, accessible: false))
        }
    }
}
