import XCTest
import UIKit
import SpriteKit
import SwiftUI
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
    @MainActor func testLayeredMapPackagesRegisteredTransparentIslandPairs() throws {
        let content = WorldMapContent.production
        XCTAssertEqual(content.islands.map(\.location), WorldLocation.allCases.filter { $0.challenge != nil },
                       "Every playable destination must have exactly one island in progression order")
        for artwork in content.islands {
            let registration = artwork.registration
            let attachments = [registration.markerAnchor, registration.leadingPort, registration.trailingPort,
                               registration.upperPort, registration.lowerPort]
            XCTAssertTrue(attachments.allSatisfy { CGRect(x: 0, y: 0, width: 1, height: 1).contains($0) })
            var visibleUnion = CGRect.null
            for name in [artwork.damagedAsset, artwork.restoredAsset] {
                let image = try XCTUnwrap(UIImage(named: name)?.cgImage, name)
                XCTAssertEqual(CGFloat(image.width), registration.sourceSize.width, name)
                XCTAssertEqual(CGFloat(image.height), registration.sourceSize.height, name)
                XCTAssertTrue([CGImageAlphaInfo.first, .last, .premultipliedFirst, .premultipliedLast].contains(image.alphaInfo), name)
                let alpha = try alphaCoverage(image, attachments: attachments)
                // Measured generator exports include isolated 1/255 glow
                // fringe at corners; this is distinct from the alpha>=128 body.
                XCTAssertTrue(alpha.corners.allSatisfy { $0 <= 1 }, "\(name) must not have a visible corner matte")
                XCTAssertGreaterThan(alpha.transparentPixelCount, 0, "\(name) must contain actual transparent pixels")
                XCTAssertGreaterThan(alpha.solidPixelCount, image.width * image.height / 20, "\(name) must contain visible terrain")
                XCTAssertTrue(alpha.attachmentAlpha.allSatisfy { $0 >= 128 },
                              "\(name): pins and route ports must attach to body pixels in both repair states")
                visibleUnion = visibleUnion.union(alpha.solidBounds)
            }
            // The catalogue records the union of both states at alpha >= 128,
            // so swapping repair state cannot alter the registered canvas.
            let sourceBounds = CGRect(x: registration.visibleBounds.minX * registration.sourceSize.width,
                                      y: registration.visibleBounds.minY * registration.sourceSize.height,
                                      width: registration.visibleBounds.width * registration.sourceSize.width,
                                      height: registration.visibleBounds.height * registration.sourceSize.height)
            XCTAssertEqual(visibleUnion.minX, sourceBounds.minX, accuracy: 1, artwork.location.id)
            XCTAssertEqual(visibleUnion.minY, sourceBounds.minY, accuracy: 1, artwork.location.id)
            XCTAssertEqual(visibleUnion.maxX, sourceBounds.maxX, accuracy: 1, artwork.location.id)
            XCTAssertEqual(visibleUnion.maxY, sourceBounds.maxY, accuracy: 1, artwork.location.id)
            XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(registration.markerAnchor))
        }
        let sky = try XCTUnwrap(UIImage(named: "WorldMapSky")?.cgImage)
        XCTAssertGreaterThan(sky.width, 0); XCTAssertGreaterThan(sky.height, 0)
        let cloud = try XCTUnwrap(UIImage(named: "WorldMapCloud")?.cgImage)
        XCTAssertTrue([CGImageAlphaInfo.first, .last, .premultipliedFirst, .premultipliedLast].contains(cloud.alphaInfo))
        let cloudAlpha = try alphaCoverage(cloud)
        XCTAssertTrue(cloudAlpha.corners.allSatisfy { $0 <= 1 })
        XCTAssertGreaterThan(cloudAlpha.transparentPixelCount, 0)
    }

    @MainActor func testRetiredMapPlatesAndNightscapesAreNotPackaged() {
        for name in ["WorldMapDamaged", "WorldMapRestored", "NightVeil", "NightIce", "MoonwakeMoon", "MoonwakeHull", "MoonwakeCloth", "NebulaBankLeft", "NebulaBankRight", "ShatterlightCrown", "ShatterlightCrescent", "ShatterlightShard", "ShatterlightShelter", "GardenCanopy", "GardenPod", "GardenMoth", "RingdriftPlanet", "RingdriftRings"] {
            XCTAssertNil(UIImage(named: name), name)
        }
        XCTAssertEqual(WorldLocation.allCases.compactMap(\.challenge), StarfallChallenge.allCases)
    }

    private func alphaCoverage(_ image: CGImage, attachments: [CGPoint] = []) throws
        -> (corners: [UInt8], transparentPixelCount: Int, solidPixelCount: Int, solidBounds: CGRect, attachmentAlpha: [UInt8]) {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        try pixels.withUnsafeMutableBytes { bytes in
            let context = try XCTUnwrap(CGContext(data: bytes.baseAddress, width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: width * 4,
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        let corners = [0, width - 1, width * (height - 1), width * height - 1].map { pixels[$0 * 4 + 3] }
        let attachmentAlpha = attachments.map { point in
            let x = min(width - 1, max(0, Int((point.x * CGFloat(width)).rounded())))
            let y = min(height - 1, max(0, Int((point.y * CGFloat(height)).rounded())))
            return pixels[(y * width + x) * 4 + 3]
        }
        var count = 0, transparentCount = 0, minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0..<height { for x in 0..<width {
            let alpha = pixels[(y * width + x) * 4 + 3]
            if alpha == 0 { transparentCount += 1 }
            if alpha >= 128 {
                count += 1
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x + 1); maxY = max(maxY, y + 1)
            }
        } }
        let bounds = count == 0 ? CGRect.null : CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        return (corners, transparentCount, count, bounds, attachmentAlpha)
    }
}

private extension WorldMapIslandRegistration {
    /// Deliberately neutral test data; production uses each family's measured registration.
    static let squareIsland = Self(
        sourceSize: CGSize(width: 1024, height: 1024),
        visibleBounds: CGRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84), canvasInset: 0.08,
        markerAnchor: CGPoint(x: 0.50, y: 0.66),
        leadingPort: CGPoint(x: 0.12, y: 0.64), trailingPort: CGPoint(x: 0.88, y: 0.64),
        upperPort: CGPoint(x: 0.50, y: 0.12), lowerPort: CGPoint(x: 0.50, y: 0.88)
    )
}

final class WorldMapLayoutTests: XCTestCase {
    @MainActor func testNativeTargetsRemainSeparateAndReachableInScrollableWorld() {
        let content = WorldMapContent.production
        for textSize in [DynamicTypeSize.large, .xLarge] {
            for width in [CGFloat(375), 393, 440, 834, 1194] {
                let side = WorldMapLayout.islandSide(width: width, count: content.islands.count)
                var islands: [WorldLocation: WorldMapIslandGeometry] = [:]
                for artwork in content.islands {
                    let nameWidth = min(240, side - 32)
                    func measured(selected: Bool) -> CGSize {
                        let name = WorldMapNameplate(title: artwork.location.title, selected: selected)
                            .environment(\.dynamicTypeSize, textSize).frame(width: nameWidth)
                        return UIHostingController(rootView: name).sizeThatFits(in: CGSize(width: nameWidth, height: 1_000))
                    }
                    let normal = measured(selected: false)
                    XCTAssertEqual(normal, measured(selected: true), "Selection must not move its target")
                    islands[artwork.location] = WorldMapIslandGeometry(registration: artwork.registration,
                                                                       canvasSide: side, nameSize: normal)
                }
                let world = WorldMapLayout(width: width, content: content, nodeSizes: islands.mapValues(\.size))
                let worldBounds = CGRect(origin: .zero, size: world.size)
                XCTAssertEqual(world.columns, width < 700 ? 1 : width >= 1050 ? 3 : 2)
                if width < 700 { XCTAssertGreaterThanOrEqual(world.size.height, 1_500, "Compact worlds scroll; they do not shrink") }
                var targets: [CGRect] = []
                for artwork in content.islands {
                    let island = islands[artwork.location]!
                    let frame = world.nodeFrame(artwork.location)
                    XCTAssertTrue(worldBounds.contains(frame), "Every island can be reached by vertical scrolling")
                    XCTAssertGreaterThanOrEqual(frame.minX, 0)
                    XCTAssertLessThanOrEqual(frame.maxX, width)
                    let localBounds = CGRect(origin: .zero, size: island.size)
                    XCTAssertTrue(localBounds.contains(island.artworkFrame))
                    XCTAssertTrue(localBounds.contains(island.pinFrame))
                    XCTAssertTrue(localBounds.contains(island.nameFrame))
                    XCTAssertFalse(island.artworkFrame.intersects(island.nameFrame), "Names must not cover the landmark")
                    XCTAssertGreaterThanOrEqual(frame.width, 44)
                    XCTAssertGreaterThanOrEqual(frame.height, 44)
                    let tip = WorldMapIslandGeometry.point(artwork.registration.markerAnchor, in: island.artworkFrame)
                    XCTAssertEqual(island.pinFrame.midX, tip.x, accuracy: 0.001)
                    XCTAssertEqual(island.pinFrame.minY + WorldMapMarkerMetrics.pinTipY, tip.y, accuracy: 0.001)
                    XCTAssertEqual(island.artworkFrame.width / island.artworkFrame.height,
                                   artwork.registration.sourceSize.width / artwork.registration.sourceSize.height, accuracy: 0.0001)
                    targets.append(frame)
                }
                for (index, target) in targets.enumerated() {
                    for other in targets.dropFirst(index + 1) { XCTAssertFalse(target.intersects(other), "Native targets must never overlap") }
                }
            }
        }
    }

    func testOneIslandProofUsesProductionRegistrationAndDoesNotCreateFutureTargets() {
        let production = WorldMapContent.production
        XCTAssertEqual(production.islands.map(\.location), WorldLocation.allCases.filter { $0.challenge != nil })
        let lantern = production.islands[0]
        let content = WorldMapContent(islands: [lantern], connections: [])
        for width in [CGFloat(375), 834, 1194] {
            let side = WorldMapLayout.islandSide(width: width, count: 1)
            let island = WorldMapIslandGeometry(registration: lantern.registration, canvasSide: side,
                                                nameSize: CGSize(width: 240, height: 40))
            let world = WorldMapLayout(width: width, content: content, nodeSizes: [.firstLight: island.size])
            XCTAssertEqual(world.columns, 1)
            XCTAssertEqual(world.nodeFrame(.firstLight).midX, width / 2, accuracy: 0.001)
            for location in WorldLocation.allCases where location != .firstLight {
                XCTAssertEqual(world.nodeFrame(location), .zero)
            }
        }
    }

    func testNativeRoutesConnectRegisteredPortsInBothDirections() throws {
        let registration = WorldMapContent.production.islands[0].registration
        let source = CGRect(x: 30, y: 300, width: 160, height: 160)
        for destination in [CGRect(x: 230, y: 300, width: 160, height: 160),
                            CGRect(x: 30, y: 60, width: 160, height: 160)] {
            let path = WorldMapRouteGeometry.path(source: source, destination: destination,
                                                  sourceRegistration: registration, destinationRegistration: registration)
            let port = destination.midY < source.midY ? registration.lowerPort : registration.leadingPort
            let endpoint = try XCTUnwrap(path.currentPoint)
            let expected = WorldMapIslandGeometry.point(port, in: destination)
            XCTAssertEqual(endpoint.x, expected.x, accuracy: 0.001)
            XCTAssertEqual(endpoint.y, expected.y, accuracy: 0.001)
            XCTAssertFalse(path.isEmpty)
        }
        XCTAssertTrue(WorldMapRouteGeometry.path(source: .zero, destination: source,
                                                sourceRegistration: registration, destinationRegistration: registration).isEmpty)
    }

    func testRestorationArtSelectionIsIndependentOfAccessAndSelection() {
        let journey = WorldJourney(legacyAccess: true)
        let legacyLocations: Set<WorldLocation> = [.firstLight, .ribbonCrossing, .kiteHarbor, .seedMoon, .silverPools]
        let first = WorldMapPresentation(journey: journey, selected: .firstLight)
        let other = WorldMapPresentation(journey: journey, selected: .silverPools)
        XCTAssertEqual(first.destinations, other.destinations)
        for artwork in WorldMapContent.production.islands {
            let state = first.destination(artwork.location)!
            XCTAssertEqual(state.canEnter, legacyLocations.contains(artwork.location),
                           "Legacy access preserves the original five places without unlocking later content")
            XCTAssertFalse(state.restored)
            XCTAssertEqual(artwork.asset(restored: state.restored), artwork.damagedAsset,
                           "Access or selection must never repair an island")
            XCTAssertNotEqual(artwork.damagedAsset, artwork.restoredAsset)
        }
    }

    func testEmptyViewportHasNoMapTargets() {
        let world = WorldMapLayout(width: 0, content: .production, nodeSizes: [:])
        XCTAssertEqual(world.size, .zero)
        for location in WorldLocation.allCases { XCTAssertEqual(world.nodeFrame(location), .zero) }
        let island = WorldMapIslandGeometry(registration: .squareIsland, canvasSide: 0,
                                            nameSize: CGSize(width: 240, height: 40))
        XCTAssertEqual(island.size, .zero)
        XCTAssertEqual(island.artworkFrame, .zero)
        XCTAssertEqual(island.pinFrame, .zero)
        XCTAssertEqual(island.nameFrame, .zero)
    }

    @MainActor func testUnspecifiedAndInfiniteLayoutProposalsHaveFiniteIdealSizes() {
        for proposed in [nil, CGFloat.infinity, -.infinity, .nan] as [CGFloat?] {
            XCTAssertEqual(WorldMapLayout.resolvedWidth(proposed), 375)
            XCTAssertEqual(WorldMapLayout.resolvedWidth(proposed, ideal: 190), 190)
        }
        XCTAssertEqual(WorldMapLayout.resolvedWidth(0), 0)
        XCTAssertEqual(WorldMapLayout.resolvedWidth(-1), 0)
        XCTAssertEqual(WorldMapLayout.resolvedWidth(834), 834)

        let renderer = WorldMapPainting(journey: WorldJourney(), selected: .firstLight, quiet: true) { _ in }
        let host = UIHostingController(rootView: renderer)
        for proposal in [CGSize(width: CGFloat.infinity, height: CGFloat.infinity),
                         CGSize(width: 375, height: CGFloat.infinity), .zero] {
            let size = host.sizeThatFits(in: proposal)
            XCTAssertTrue(size.width.isFinite && size.height.isFinite, "\(proposal) produced \(size)")
            XCTAssertGreaterThanOrEqual(size.width, 0); XCTAssertGreaterThanOrEqual(size.height, 0)
            if proposal.width > 0 {
                XCTAssertEqual(size.width, 375, accuracy: 0.001)
                XCTAssertGreaterThanOrEqual(size.height, 1_500)
            }
        }
    }

    func testNonfiniteGeometryIsEmptyAndCannotCreateInvalidTargets() {
        for width in [CGFloat.infinity, -.infinity, .nan] {
            let world = WorldMapLayout(width: width, content: .production, nodeSizes: [:])
            XCTAssertEqual(world.size, .zero)
            XCTAssertEqual(WorldMapLayout.islandSide(width: width, count: 5), 0)
            for location in WorldLocation.allCases { XCTAssertEqual(world.nodeFrame(location), .zero) }
            let island = WorldMapIslandGeometry(registration: .squareIsland, canvasSide: width,
                                                nameSize: CGSize(width: 240, height: 40))
            XCTAssertEqual(island.size, .zero)
            XCTAssertEqual(island.artworkFrame, .zero)
            XCTAssertEqual(island.pinFrame, .zero)
            XCTAssertEqual(island.nameFrame, .zero)
        }
    }

    func testAddingAnIslandPreservesCompactRowSpacing() {
        let production = WorldMapContent.production
        let expansion = WorldMapIslandArtwork(location: .sunwheelMill, damagedAsset: "unused-damaged",
                                              restoredAsset: "unused-restored", registration: .squareIsland)
        XCTAssertFalse(production.islands.contains { $0.location == expansion.location })
        let expanded = WorldMapContent(islands: production.islands + [expansion], connections: production.connections)
        var measuredHeights: [CGFloat] = []
        for content in [production, expanded] {
            let side = WorldMapLayout.islandSide(width: 375, count: content.islands.count)
            let sizes = Dictionary(uniqueKeysWithValues: content.islands.map {
                ($0.location, WorldMapIslandGeometry(registration: $0.registration, canvasSide: side,
                                                     nameSize: CGSize(width: 240, height: 40)).size)
            })
            let world = WorldMapLayout(width: 375, content: content, nodeSizes: sizes)
            measuredHeights.append(world.size.height)
            let rows = Set(content.islands.map { world.nodeFrame($0.location).midY }).sorted()
            XCTAssertEqual(rows.count, content.islands.count)
            for (first, second) in zip(rows, rows.dropFirst()) { XCTAssertGreaterThanOrEqual(second - first, side + 24) }
        }
        XCTAssertGreaterThan(measuredHeights[1], measuredHeights[0], "An added destination extends the world instead of compressing existing rows")
    }

    func testPairedTabletRowsKeepProgressionConnectionsInTheSameColumn() {
        for count in [5, 6] {
            let islands = WorldLocation.allCases.prefix(count).map {
                WorldMapIslandArtwork(location: $0, damagedAsset: "unused-damaged",
                                      restoredAsset: "unused-restored", registration: .squareIsland)
            }
            let content = WorldMapContent(islands: islands, connections: [])
            let sizes = Dictionary(uniqueKeysWithValues: islands.map {
                ($0.location, CGSize(width: 280, height: 300))
            })
            let world = WorldMapLayout(width: 834, content: content, nodeSizes: sizes)
            XCTAssertEqual(world.columns, 2)
            let frames = islands.map { world.nodeFrame($0.location) }
            let rows = Dictionary(grouping: frames, by: \.midY)
            var alignedTransitions = 0
            for (source, destination) in zip(frames, frames.dropFirst()) {
                if source.midY == destination.midY {
                    XCTAssertNotEqual(source.midX, destination.midX)
                } else {
                    XCTAssertLessThan(destination.midY, source.midY, "Progression moves toward the next row")
                    // An odd destination count starts with a centered singleton.
                    // Connections between complete pairs must join their nearest
                    // endpoints rather than crossing the world diagonally.
                    if rows[source.midY]?.count == 2, rows[destination.midY]?.count == 2 {
                        XCTAssertEqual(source.midX, destination.midX, accuracy: 0.001,
                                       "\(count) islands: paired rows must form a continuous winding path")
                        alignedTransitions += 1
                    }
                }
            }
            XCTAssertGreaterThan(alignedTransitions, 0, "Both odd and even catalogues must exercise a paired-row turn")
        }
    }

    @MainActor func testWholeIslandControlFitsMinimumMapViewportWithoutShrinkingNames() {
        for textSize in [DynamicTypeSize.large, .xLarge] {
            for height in [WorldMapLayout.minimumViewportHeight, 300, 400] {
                for artwork in WorldMapContent.production.islands {
                    let presentation = WorldMapDestinationPresentation(location: artwork.location, journey: WorldJourney())
                    func measured(selected: Bool) -> CGSize {
                        let island = WorldMapIslandNode(artwork: artwork, presentation: presentation, selected: selected,
                                                        maximumNodeHeight: height - WorldMapLayout.targetViewportInset * 2, action: {})
                            .environment(\.dynamicTypeSize, textSize)
                        return UIHostingController(rootView: island).sizeThatFits(in: CGSize(width: 300, height: 1_000))
                    }
                    let size = measured(selected: false)
                    XCTAssertEqual(size, measured(selected: true), "Selection must not move the island or its native target")
                    XCTAssertGreaterThanOrEqual(size.width, WorldMapLayout.minimumIslandSide)
                    XCTAssertLessThanOrEqual(size.width, 300)
                    XCTAssertGreaterThanOrEqual(size.height, 44)
                    XCTAssertLessThanOrEqual(size.height, height - WorldMapLayout.targetViewportInset * 2 + 0.001,
                                             "\(artwork.location) at \(textSize) must clear both clipped viewport edges")
                }
            }
        }
    }

    @MainActor func testTabletOverviewFitsAllCurrentDestinationsAtNativeTextSizes() {
        let content = WorldMapContent.production
        // Three portrait rows need 920pt at the 280pt minimum row budget;
        // landscape's two rows fit comfortably in 630pt.
        for viewport in [CGSize(width: 834, height: 920), CGSize(width: 1194, height: 630)] {
            for textSize in [DynamicTypeSize.large, .xLarge] {
                let world = measuredWorld(content: content, viewport: viewport, textSize: textSize)
                let viewportBounds = CGRect(origin: .zero, size: viewport)
                XCTAssertLessThanOrEqual(world.size.height, viewport.height + 0.001)
                let frames = content.islands.map { world.nodeFrame($0.location) }
                for frame in frames {
                    XCTAssertTrue(viewportBounds.insetBy(dx: -0.001, dy: -0.001).contains(frame))
                    XCTAssertGreaterThanOrEqual(frame.width, WorldMapLayout.minimumIslandSide)
                    XCTAssertGreaterThanOrEqual(frame.height, 44)
                }
                for (index, frame) in frames.enumerated() {
                    for other in frames.dropFirst(index + 1) { XCTAssertFalse(frame.intersects(other)) }
                }
                let renderer = WorldMapPainting(journey: WorldJourney(), selected: .firstLight, quiet: true,
                                               select: { _ in }, maximumNodeHeight: viewport.height)
                    .environment(\.dynamicTypeSize, textSize)
                let nativeSize = UIHostingController(rootView: renderer)
                    .sizeThatFits(in: CGSize(width: viewport.width, height: CGFloat.infinity))
                XCTAssertEqual(nativeSize.height, world.size.height, accuracy: 0.001,
                               "The scene must use the same row budget as its native destination controls")
            }
        }
    }

    @MainActor func testExpandedTabletWorldScrollsInsteadOfShrinkingItsIslands() {
        let production = WorldMapContent.production
        let additions = WorldLocation.allCases.filter { $0.challenge == nil }.prefix(2).map {
            WorldMapIslandArtwork(location: $0, damagedAsset: "unused-damaged", restoredAsset: "unused-restored",
                                  registration: .squareIsland)
        }
        let expanded = WorldMapContent(islands: production.islands + additions, connections: production.connections)
        let viewport = CGSize(width: 834, height: 920)
        let world = measuredWorld(content: expanded, viewport: viewport, textSize: .xLarge)
        XCTAssertGreaterThan(world.size.height, viewport.height)
        for artwork in expanded.islands {
            let frame = world.nodeFrame(artwork.location)
            XCTAssertGreaterThanOrEqual(frame.width, WorldMapLayout.minimumIslandSide)
            XCTAssertGreaterThanOrEqual(frame.height, 44)
            XCTAssertTrue(CGRect(origin: .zero, size: world.size).contains(frame))
        }
        XCTAssertEqual(WorldMapLayout.nodeHeightLimit(width: 375, viewportHeight: 400, count: 5), 400,
                       "Compact phones retain the winding scroll layout")
        XCTAssertEqual(WorldMapLayout.nodeHeightLimit(width: 834, viewportHeight: 900, count: 5),
                       WorldMapLayout.minimumViewportHeight,
                       "A short tablet cannot force rows below the declared minimum")
    }

    @MainActor private func measuredWorld(content: WorldMapContent, viewport: CGSize, textSize: DynamicTypeSize) -> WorldMapLayout {
        let side = WorldMapLayout.islandSide(width: viewport.width, count: content.islands.count)
        let rowHeight = WorldMapLayout.nodeHeightLimit(width: viewport.width, viewportHeight: viewport.height,
                                                       count: content.islands.count)!
        let sizes = Dictionary(uniqueKeysWithValues: content.islands.map { artwork in
            let presentation = WorldMapDestinationPresentation(location: artwork.location, journey: WorldJourney())
            let island = WorldMapIslandNode(artwork: artwork, presentation: presentation, selected: false,
                                            maximumNodeHeight: viewport.height, action: {})
                .environment(\.dynamicTypeSize, textSize)
            let size = UIHostingController(rootView: island).sizeThatFits(in: CGSize(width: side, height: rowHeight))
            return (artwork.location, size)
        })
        return WorldMapLayout(width: viewport.width, content: content, nodeSizes: sizes)
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
