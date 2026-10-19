import XCTest
import UIKit
import SpriteKit
import StarfallCore
@testable import Starfall

final class ObservatoryGeometryTests: XCTestCase {
    func testColumnOutlineContainsItsStarsAndExcludesNeighborCenters() {
        for size in [CGSize(width: 375, height: 667), CGSize(width: 390, height: 844), CGSize(width: 1024, height: 768)] {
            let mapping = LandingGeometry(size: size)
            for column in 0..<7 {
                let path = CGMutablePath()
                path.addLines(between: mapping.columnPolygon(column)); path.closeSubpath()
                for row in 0..<7 {
                    XCTAssertTrue(path.contains(mapping.viewPoint(Cell(row, column))))
                    if column < 6 { XCTAssertFalse(path.contains(mapping.viewPoint(Cell(row, column+1)))) }
                    if column > 0 { XCTAssertFalse(path.contains(mapping.viewPoint(Cell(row, column-1)))) }
                }
            }
        }
    }

    @MainActor func testProjectionRoundTripAndSharedEdgesOnPortraitSizes() {
        for size in [CGSize(width: 320, height: 640), CGSize(width: 667, height: 375), CGSize(width: 852, height: 393), CGSize(width: 375, height: 1000), CGSize(width: 440, height: 956), CGSize(width: 350, height: 610), CGSize(width: 378, height: 690), CGSize(width: 536, height: 930), CGSize(width: 768, height: 1024), CGSize(width: 1024, height: 768), CGSize(width: 375, height: 667)] {
            let mapping = LandingGeometry(size: size)
            for row in 0..<7 { for column in 0..<7 {
                let cell = Cell(row, column)
                let center = mapping.viewPoint(cell)
                XCTAssertEqual(mapping.cell(at: center), cell)
                XCTAssertEqual(mapping.scenePoint(cell).x, center.x, accuracy: 0.0001)
                XCTAssertEqual(mapping.scenePoint(cell).y, size.height-center.y, accuracy: 0.0001)
                let frame = mapping.frame(cell)
                XCTAssertGreaterThanOrEqual(frame.width, 44)
                XCTAssertGreaterThanOrEqual(frame.height, 44)
                XCTAssertTrue(CGRect(origin: .zero, size: size).contains(frame), "\(size) \(cell) \(frame)")
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
    func testBodyAndAwardSizingFitBothAxesOfTheSharedCell() {
        for size in [CGSize(width: 667, height: 375), CGSize(width: 852, height: 393),
                     CGSize(width: 1133, height: 744), CGSize(width: 369, height: 800)] {
            let mapping = LandingGeometry(size: size)
            for row in 0..<7 { for column in 0..<7 {
                let cell = mapping.frame(Cell(row,column))
                XCTAssertLessThanOrEqual(mapping.starStep, cell.height + 0.001)
                XCTAssertLessThanOrEqual(mapping.starStep, cell.width * 1.05)
            } }
        }
    }

    func testBoardIsCenteredInBothAxesIndependentOfSceneryAndHeaderSize() {
        for size in [CGSize(width:320,height:640),CGSize(width:393,height:852),CGSize(width:834,height:1194),CGSize(width:1194,height:834)] {
            let normal = LandingGeometry(size:size), large = LandingGeometry(size:size,largeHeader:true)
            XCTAssertEqual(normal.arenaFrame.midX,size.width/2,accuracy:0.001)
            XCTAssertEqual(normal.arenaFrame.midY,size.height/2,accuracy:0.001)
            XCTAssertEqual(normal.arenaFrame,large.arenaFrame)
            XCTAssertEqual(normal.viewPoint(Cell(3,3)).x,size.width/2,accuracy:0.001)
            XCTAssertEqual(normal.viewPoint(Cell(3,3)).y,size.height/2,accuracy:0.001)
        }
    }
    @MainActor func testAmbientClockFreezesWithoutCatchUp() {
        var clock = LandingAmbientClock()
        clock.setRunning(true, at: 10)
        XCTAssertEqual(clock.phase(at: 12), 2)
        clock.setRunning(false, at: 12)
        XCTAssertEqual(clock.phase(at: 1000), 2)
        clock.setRunning(true, at: 1000)
        clock.setRunning(true, at: 1001)
        XCTAssertEqual(clock.phase(at: 1002), 4)
        clock.setRunning(false, at: 1002)
        XCTAssertEqual(clock.phase(at: 5000), 4)

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
            let point = LandingGeometry(size: scene.size).scenePoint(Cell(row,column))
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
        let phone = CGSize(width: 402, height: 874)
        XCTAssertTrue(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: phone, topInset: 62, accessible: false))
        XCTAssertTrue(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: CGSize(width: 440, height: 956), topInset: 62, accessible: false))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: CGSize(width: 440, height: 956), topInset: 62, accessible: true))
        for hardware in ["", "iPhone14,6", "iPhone17,5", "future-device"] {
            XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: hardware, size: phone, topInset: 62, accessible: false))
        }
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: phone, topInset: 62, accessible: true))
        for (size, inset) in [(CGSize(width: 874, height: 402), CGFloat(0)),
                              (CGSize(width: 768, height: 1024), CGFloat(62)),
                              (phone, CGFloat(0)), (phone, CGFloat(82)),
                              (CGSize(width:402,height:778), CGFloat(62)),
                              (CGSize(width:402,height:900), CGFloat(62)),
                              (CGSize(width: 375, height: 667), CGFloat(20))] {
            XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone18,3", size: size, topInset: inset, accessible: false))
        }
    }
}


extension SkyShowerPlacementTests {
    func testEveryResizedOrAccessibleCalibratedCanvasUsesHeaderFallback() {
        for (hardware, size) in [("iPhone18,3",CGSize(width:402,height:874)),("iPhone17,2",CGSize(width:440,height:956))] {
            for delta in [CGFloat(-100), -2, 2, 100] {
                XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware:hardware,size:CGSize(width:size.width,height:size.height+delta),topInset:62,accessible:false))
                XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware:hardware,size:CGSize(width:size.width+delta,height:size.height),topInset:62,accessible:false))
            }
            XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware:hardware,size:size,topInset:62,accessible:true))
        }
    }
}

final class OfficialWorldArtworkTests: XCTestCase {
    @MainActor func testOfficialMapReplacesRetiredNightscapeResources() throws {
        for name in ["WorldMapDamaged", "WorldMapRestored"] {
            let map = try XCTUnwrap(UIImage(named: name)?.cgImage)
            XCTAssertEqual(map.width, 1024); XCTAssertEqual(map.height, 1536)
        }
        for name in ["NightVeil", "NightIce", "MoonwakeMoon", "MoonwakeHull", "MoonwakeCloth", "NebulaBankLeft", "NebulaBankRight", "ShatterlightCrown", "ShatterlightCrescent", "ShatterlightShard", "ShatterlightShelter", "GardenCanopy", "GardenPod", "GardenMoth", "RingdriftPlanet", "RingdriftRings"] {
            XCTAssertNil(UIImage(named: name), name)
        }
        XCTAssertEqual(WorldLocation.allCases.compactMap(\.challenge), StarfallChallenge.allCases)
    }
}

final class LandingArchitectureGeometryTests: XCTestCase {
    func testEmptyViewportHasNoInputCellsOrInvalidProjectionRange() {
        for size in [CGSize.zero,CGSize(width:0,height:844),CGSize(width:390,height:0)] {
            let mapping = LandingGeometry(size:size)
            XCTAssertEqual(mapping.arenaFrame,.zero)
            XCTAssertNil(mapping.cell(at:.zero))
            for row in 0..<7 { for column in 0..<7 { XCTAssertEqual(mapping.frame(Cell(row,column)),.zero) } }
        }
    }
    func testHeaderDialogueAndActionsStayOutsideEveryCell() {
        for size in [CGSize(width:320,height:900),CGSize(width:369,height:800),CGSize(width:440,height:956),CGSize(width:834,height:1194),CGSize(width:1194,height:834)] {
            let map = LandingGeometry(size:size)
            for row in 0..<7 { for column in 0..<7 {
                let cell = Cell(row,column), frame = map.frame(cell)
                for region in [map.crownFrame,map.communicationContentFrame,map.actionFrame(0),map.actionFrame(1)] {
                    XCTAssertFalse(frame.intersects(region))
                    XCTAssertTrue(CGRect(origin:.zero,size:size).contains(region))
                }
                XCTAssertEqual(map.cell(at:map.viewPoint(cell)),cell)
                XCTAssertGreaterThanOrEqual(frame.height,44)
                XCTAssertGreaterThanOrEqual(frame.width,44)
            } }
        }
    }
}
