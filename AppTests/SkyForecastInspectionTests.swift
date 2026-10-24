import XCTest
import SwiftUI
import UIKit
import StarfallCore
@testable import Starfall

final class SkyForecastInspectionTests: XCTestCase {
    private typealias Source = SkyForecastInspection.Source
    private typealias Harness = (store: FallingSkyStore, presenter: FallingSkyRecorder,
                                clock: ManualRainClock, feedback: SkyFeedbackRecorder, defaults: UserDefaults)

    @MainActor private func make(_ game: FallingSky) throws -> Harness {
        let suite = "Starfall.ForecastInspection.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        try SkySaveArchive.save(game, to: defaults)
        let presenter = FallingSkyRecorder(), clock = ManualRainClock(), feedback = SkyFeedbackRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter,
                                    clock: clock, feedback: feedback)
        store.setSuspended(false)
        if store.isPaused { store.togglePause() }
        return (store, presenter, clock, feedback, defaults)
    }

    @MainActor private func source(_ store: FallingSkyStore) throws -> Source {
        try XCTUnwrap(Source(game: store.game, generation: store.constellationInputGeneration,
                             forecast: store.forecast, arriving: store.showerCountdown.arriving))
    }

    @MainActor func testRepeatedDestinationsKeepTheirOwnOrderedStarIdentities() throws {
        // The existing hostile display fixture is not a historical save claim.
        let forecast = [IncomingStar(id:40,kind:.aqua,column:6), IncomingStar(id:12,kind:.rose,column:0),
                        IncomingStar(id:99,kind:.amber,column:6)]
        let context = try XCTUnwrap(Source(game: FallingSky(seed:42), generation:7,
                                           forecast:forecast, arriving:false))
        let first = try XCTUnwrap(SkyForecastInspection(entryID:40,source:context))
        let last = try XCTUnwrap(SkyForecastInspection(entryID:99,source:context))
        XCTAssertEqual(first.entry(in:context), .init(id:40,family:.colored(.aqua),column:7))
        XCTAssertEqual(last.entry(in:context), .init(id:99,family:.colored(.amber),column:7))
        XCTAssertNotEqual(first.entry(in:context)?.id, last.entry(in:context)?.id)
        XCTAssertEqual(SkyForecastSnapshot(forecast:forecast).entries.map(\.id), [40,12,99])
        XCTAssertNil(SkyForecastInspection(entryID:6,source:context))
        XCTAssertNil(first.entry(in:nil), "An unavailable view has no column cue")
    }

    @MainActor func testSelectionRejectsChangedBoardGenerationOrderMaterialDestinationAndArrivalState() throws {
        let game = FallingSky.freshChallenge(.seedMoon), forecast = game.incoming
        let original = try XCTUnwrap(Source(game:game,generation:3,forecast:forecast,arriving:false))
        let selected = try XCTUnwrap(SkyForecastInspection(entryID:forecast[0].id,source:original))
        var changedBoard = game
        XCTAssertNotNil(changedBoard.nudge(from:Cell(0,1),to:Cell(1,1)))
        XCTAssertEqual(changedBoard.incoming, forecast)
        var material = forecast, destination = forecast
        material[0] = IncomingStar(id:forecast[0].id,kind:.rose,column:forecast[0].column)
        XCTAssertNotEqual(material[0].identity, forecast[0].identity)
        destination[0] = IncomingStar(id:forecast[0].id,kind:forecast[0].kind,column:(forecast[0].column+1)%7)
        let variants: [(FallingSky, UInt64, [IncomingStar], Bool)] = [
            (changedBoard,3,forecast,false), (game,4,forecast,false),
            (game,3,Array(forecast.reversed()),false), (game,3,material,false),
            (game,3,destination,false), (game,3,forecast,true)
        ]
        for (current,generation,displayed,arriving) in variants {
            let next = try XCTUnwrap(Source(game:current,generation:generation,forecast:displayed,arriving:arriving))
            XCTAssertNil(selected.entry(in:next))
        }
        XCTAssertNotNil(selected.entry(in:original))
    }

    @MainActor func testInvalidForecastsFullBoardsAndRealTerminalRoundsCannotCreateInspection() throws {
        let game = FallingSky.freshChallenge(.firstLight), forecast = game.incoming
        let invalid = [[], [IncomingStar(id:-1,kind:.aqua,column:0)], [forecast[0],forecast[0]],
                       [IncomingStar(id:0,kind:.aqua,column:-1)], [IncomingStar(id:0,kind:.aqua,column:7)],
                       (0..<50).map { IncomingStar(id:$0,kind:.aqua,column:$0%7) }]
        for displayed in invalid {
            XCTAssertNil(Source(game:game,generation:0,forecast:displayed,arriving:false))
        }
        let retained = FallingSky(definition: try XCTUnwrap(StoryChallengeDefinition(.firstLight,revision:5)))
        for full in [retained,.fullBoardLantern(),.fullBoardRibbon()] {
            XCTAssertNil(Source(game:full,generation:0,forecast:forecast,arriving:false),
                         "Even a supplied nonempty array cannot create a Full Board shower")
        }
        var won = FallingSky.freshChallenge(.silverPools)
        XCTAssertNotNil(won.nudge(from:Cell(1,2),to:Cell(1,3)))
        XCTAssertEqual(won.outcome,.won)
        XCTAssertNil(Source(game:won,generation:0,forecast:won.incoming,arriving:true))
    }

    @MainActor func testRealExchangeSuspensionAndSameOpeningReplayRetireOldSelections() throws {
        let fixture = try make(.freshChallenge(.seedMoon))
        defer { fixture.store.setSuspended(true) }
        let store = fixture.store, before = try source(store)
        let selected = try XCTUnwrap(SkyForecastInspection(entryID:store.forecast[0].id,source:before))
        let forecast = store.forecast
        XCTAssertTrue(store.requestInput(.swap(Cell(0,1),Cell(1,1)),snapshot:store.game,
                                         generation:store.constellationInputGeneration))
        XCTAssertEqual(store.forecast,forecast)
        XCTAssertNil(selected.entry(in:try source(store)))
        fixture.presenter.finish()
        fixture.clock.advance(1)
        let active = try source(store)
        let activeSelection = try XCTUnwrap(SkyForecastInspection(entryID:forecast[0].id,source:active))
        let game = store.game, bytes = fixture.defaults.data(forKey:SkySaveArchive.key)
        let remaining = store.showerCountdown.remaining
        store.setSuspended(true)
        XCTAssertNil(activeSelection.entry(in:try source(store)))
        XCTAssertNil(fixture.clock.deadline)
        fixture.clock.advance(20)
        store.setSuspended(false)
        XCTAssertNil(activeSelection.entry(in:try source(store)))
        XCTAssertEqual(store.game,game)
        XCTAssertEqual(fixture.defaults.data(forKey:SkySaveArchive.key),bytes)
        XCTAssertEqual(store.showerCountdown.remaining,remaining,accuracy:0.000001)
        store.restart(sameSky:true)
        let replayed = store.game, replaySource = try source(store)
        let replaySelection = try XCTUnwrap(SkyForecastInspection(entryID:store.forecast[0].id,source:replaySource))
        store.restart(sameSky:true)
        XCTAssertEqual(store.game,replayed, "The same opening is still a distinct UI input generation")
        XCTAssertNil(replaySelection.entry(in:try source(store)))
    }

    @MainActor func testReadOnlyInspectionPreservesDeadlineSavesAndActualShowerThenFollowsDisplayedRefresh() throws {
        var opening = SkyTutorial.storyRoom.game()
        XCTAssertNotNil(opening.nudge(from:Cell(0,1),to:Cell(0,2)))
        XCTAssertTrue(opening.isValidSave)
        let fixture = try make(opening)
        defer { fixture.store.setSuspended(true) }
        let store = fixture.store
        fixture.clock.advance(1.25)
        let context = try source(store), forecast = store.forecast, game = store.game
        let selected = try XCTUnwrap(SkyForecastInspection(entryID:forecast[0].id,source:context))
        let saved = fixture.defaults.data(forKey:SkySaveArchive.key)
        let world = fixture.defaults.data(forKey:WorldJourneyStore.key)
        let mastery = fixture.defaults.data(forKey:StoryMasteryStore.key)
        let journey = store.journey.journey, generation = store.constellationInputGeneration
        let deadline = try XCTUnwrap(fixture.clock.deadline), remainder = store.showerCountdown.remaining
        let presentations = fixture.presenter.completions.count
        let clears = fixture.feedback.clears, announcements = fixture.feedback.announcements
        for star in forecast {
            let inspection = try XCTUnwrap(SkyForecastInspection(entryID:star.id,source:context))
            XCTAssertEqual(inspection.entry(in:context)?.column,star.column+1)
            XCTAssertNil(inspection.entry(in:nil))
        }
        XCTAssertEqual(store.game,game)
        XCTAssertEqual(store.forecast,forecast)
        XCTAssertEqual(store.journey.journey,journey)
        XCTAssertEqual(store.constellationInputGeneration,generation)
        XCTAssertFalse(store.constellationTracing)
        XCTAssertNil(store.bufferedInput)
        XCTAssertEqual(fixture.clock.deadline,deadline)
        XCTAssertEqual(store.showerCountdown.remaining,remainder)
        XCTAssertEqual(fixture.presenter.completions.count,presentations)
        XCTAssertEqual(fixture.feedback.clears,clears)
        XCTAssertEqual(fixture.feedback.announcements,announcements)
        XCTAssertEqual(fixture.defaults.data(forKey:SkySaveArchive.key),saved)
        XCTAssertEqual(fixture.defaults.data(forKey:WorldJourneyStore.key),world)
        XCTAssertEqual(fixture.defaults.data(forKey:StoryMasteryStore.key),mastery)

        var control = try SkySaveArchive.decode(try XCTUnwrap(saved))
        let expected = try XCTUnwrap(control.letStarsFall())
        fixture.clock.advance(deadline-fixture.clock.now)
        XCTAssertEqual(store.game,control, "Reading cannot change the next committed random continuation")
        XCTAssertEqual(store.pending?.arrivals,expected.arrivals)
        XCTAssertEqual(store.forecast,forecast)
        XCTAssertNotEqual(store.game.incoming,forecast)
        XCTAssertTrue(store.showerCountdown.arriving)
        XCTAssertNil(selected.entry(in:try source(store)))
        let arriving = try source(store), arrivingGeneration = store.constellationInputGeneration
        let inFlight = try XCTUnwrap(SkyForecastInspection(entryID:forecast[0].id,source:arriving))
        XCTAssertEqual(inFlight.entry(in:arriving)?.column,forecast[0].column+1)
        let future = try XCTUnwrap(Source(game:store.game,generation:arrivingGeneration,
                                         forecast:store.game.incoming,arriving:true))
        XCTAssertNil(inFlight.entry(in:future), "Do not substitute Core’s following preview for the displayed arriving shower")
        fixture.presenter.finish()
        XCTAssertEqual(store.constellationInputGeneration,arrivingGeneration)
        XCTAssertEqual(store.forecast,control.incoming)
        XCTAssertFalse(store.showerCountdown.arriving)
        XCTAssertNil(inFlight.entry(in:try source(store)), "Presentation completion alone refreshes displayed identity")
        XCTAssertEqual(SkySaveArchive.load(from:fixture.defaults),control)
    }

    @MainActor func testColumnBoundsMatchOnlyTheSelectedBoardColumnAcrossViewportSizes() throws {
        for size in [CGSize(width:390,height:844), CGSize(width:834,height:1194), CGSize(width:1194,height:834)] {
            let mapping = LandingGeometry(size:size)
            for column in 1...7 {
                let entry = SkyForecastSnapshot.Entry(id:column,family:.colored(.aqua),column:column)
                let bounds = try XCTUnwrap(SkyForecastColumnOverlay(entry:entry,mapping:mapping).columnBounds)
                let nativeColumn = mapping.frame(Cell(6,column-1)).union(mapping.frame(Cell(0,column-1)))
                XCTAssertEqual(bounds,nativeColumn)
                for row in 0..<7 { for other in 0..<7 {
                    XCTAssertEqual(bounds.contains(mapping.viewPoint(Cell(row,other))),other == column-1)
                } }
            }
            let invalid = SkyForecastSnapshot.Entry(id:0,family:.colored(.aqua),column:0)
            XCTAssertNil(SkyForecastColumnOverlay(entry:invalid,mapping:mapping).columnBounds)
        }
    }

    @MainActor func testHostedNormalAndLargestTextRenderOneUnfilledCueAndNoFullBoardCue() async throws {
        let owner = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let prior = owner.windows.first(where:\.isKeyWindow)
        let size = CGSize(width:390,height:844), mapping = LandingGeometry(size:CGSize(width:390,height:844))
        let window = UIWindow(windowScene:owner)
        window.frame = CGRect(origin:.zero,size:size)
        defer { window.isHidden = true; prior?.makeKey() }
        let game = FallingSky.freshChallenge(.seedMoon)
        let context = try XCTUnwrap(Source(game:game,generation:1,forecast:game.incoming,arriving:false))
        let inspection = try XCTUnwrap(SkyForecastInspection(entryID:game.incoming[0].id,source:context))
        let entry = try XCTUnwrap(inspection.entry(in:context))
        let bounds = try XCTUnwrap(SkyForecastColumnOverlay(entry:entry,mapping:mapping).columnBounds)
        for accessible in [false,true] {
            let type: DynamicTypeSize = accessible ? .accessibility5 : .large
            // Target labels, 44-point bounds and reading-surface containment
            // belong to the real XCTest journeys: SwiftUI does not expose its
            // out-of-process AX children through UIKit container traversal.
            // This hosted boundary checks actual rendered column ink instead.
            for current in [Source?.some(context), nil,
                            Source(game:.fullBoardLantern(),generation:1,forecast:game.incoming,arriving:false)] {
                let visible = inspection.entry(in:current)
                let content = ZStack {
                    Color.black
                    if let visible { SkyForecastColumnOverlay(entry:visible,mapping:mapping) }
                }.frame(width:size.width,height:size.height).environment(\.dynamicTypeSize,type).ignoresSafeArea()
                let controller = UIHostingController(rootView:content)
                window.rootViewController = controller
                window.makeKeyAndVisible()
                controller.view.setNeedsLayout(); controller.view.layoutIfNeeded()
                let limit = ContinuousClock.now + .seconds(2)
                while (controller.view.bounds.size != size || controller.view.window == nil) && ContinuousClock.now < limit {
                    try await Task.sleep(for:.milliseconds(10))
                    controller.view.layoutIfNeeded()
                }
                XCTAssertEqual(controller.view.bounds.size,size)
                let format = UIGraphicsImageRendererFormat(); format.scale = window.screen.scale
                let image = UIGraphicsImageRenderer(bounds:window.bounds,format:format).image { _ in
                    window.drawHierarchy(in:window.bounds,afterScreenUpdates:true)
                }
                if visible != nil {
                    XCTAssertGreaterThan(try ink(image,region:bounds.insetBy(dx:-4,dy:-4)),25)
                    XCTAssertEqual(try ink(image,region:bounds.insetBy(dx:7,dy:7)),0, "The locator is an outline, not a column fill")
                    for other in 0..<7 where other != entry.column-1 {
                        let points = mapping.columnPolygon(other)
                        let rect = CGRect(x:points[0].x,y:points[0].y,width:points[1].x-points[0].x,
                                          height:points[2].y-points[0].y).insetBy(dx:7,dy:7)
                        XCTAssertEqual(try ink(image,region:rect),0)
                    }
                    let attachment = XCTAttachment(image:image)
                    attachment.name = accessible ? "forecast-column-largest-type" : "forecast-column-normal"
                    attachment.lifetime = .keepAlways; add(attachment)
                } else {
                    XCTAssertEqual(try ink(image,region:mapping.arenaFrame.insetBy(dx:-4,dy:-4)),0)
                }
            }
        }
    }

    private func ink(_ image: UIImage, region: CGRect) throws -> Int {
        let cg = try XCTUnwrap(image.cgImage)
        let crop = try XCTUnwrap(cg.cropping(to:region.applying(CGAffineTransform(scaleX:image.scale,y:image.scale))))
        var pixels = [UInt8](repeating:0,count:crop.width*crop.height*4)
        let context = try XCTUnwrap(CGContext(data:&pixels,width:crop.width,height:crop.height,
            bitsPerComponent:8,bytesPerRow:crop.width*4,space:CGColorSpaceCreateDeviceRGB(),
            bitmapInfo:CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(crop,in:CGRect(x:0,y:0,width:crop.width,height:crop.height))
        return stride(from:0,to:pixels.count,by:4).filter { max(pixels[$0],pixels[$0+1],pixels[$0+2]) > 8 }.count
    }
}
