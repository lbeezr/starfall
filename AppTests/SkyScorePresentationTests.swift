import XCTest
import SwiftUI
import UIKit
@testable import StarfallCore
@testable import Starfall

@MainActor private final class ScoreExplanationPresenter: FallingSkyPresenting {
    var reduceMotion = false
    var phase: ((Int) -> Void)?
    var completion: (() -> Void)?
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 completion: @escaping () -> Void) { self.completion = completion }
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky,
                 phaseBegan: @escaping (Int) -> Void, completion: @escaping () -> Void) {
        phase = phaseBegan; self.completion = completion
    }
}

final class SkyScorePresentationTests: XCTestCase {
    @MainActor func testTerminalSummarySelectsOnlyOneCompleteCommittedScoreAndPreservesAllCopy() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        _ = try XCTUnwrap(game.nudge(from: Cell(1,2), to: Cell(1,3)))
        let result = try XCTUnwrap(SkyResultSnapshot(game: game))
        let line = SkyDialogueLibrary.line("ceremony.result", values: ["reason": result.reason, "score": result.scoreLabel])
        let range = try XCTUnwrap(SkyResultSummary.scoreRange(in: line.text, scoreLabel: result.scoreLabel))
        XCTAssertEqual(String(line.text[range]), result.scoreLabel)
        XCTAssertEqual(result.score, 19_000)
        XCTAssertEqual(result.target, 12_000)
        XCTAssertEqual(String(SkyResultSummary.content(line.text, scoreLabel: result.scoreLabel).characters), line.text)

        let openScore = SkyCopy.text(.resultScore, values: ["score": SkyCopy.score(5)])
        let historicalScore = SkyCopy.text(.resultChallengeScore, values: ["score": "18", "target": "18"])
        for score in [openScore, historicalScore] {
            let copy = "A retained ending. \(score). Ready for another sky?"
            XCTAssertEqual(String(copy[try XCTUnwrap(SkyResultSummary.scoreRange(in: copy, scoreLabel: score))]), score)
            XCTAssertEqual(String(SkyResultSummary.content(copy, scoreLabel: score).characters), copy)
        }
        let fallbacks: [(String, String?)] = [
            (line.text, nil), (line.text, ""), (line.text, "Unknown score"),
            ("\(result.scoreLabel). Again: \(result.scoreLabel).", result.scoreLabel),
            ("15 starlight.", "5 starlight"), ("\(openScore)More", openScore)
        ]
        for (copy, score) in fallbacks {
            XCTAssertNil(SkyResultSummary.scoreRange(in: copy, scoreLabel: score))
            XCTAssertEqual(String(SkyResultSummary.content(copy, scoreLabel: score).characters), copy)
        }
    }

    @MainActor func testTerminalSummaryKeepsNativeLargestTextReflowForTargetAndOpenSkyResults() throws {
        let fixtures: [(String, String, String, String)] = [
            ("silver", "ceremony.result", "Silver Pools complete! One silver cascade now flows through every pool.",
             SkyCopy.text(.resultChallengeScore, values: ["score": "19,000", "target": "12,000"])),
            ("full-board", "ceremony.result", "First Light complete! Lantern Landing is restored.",
             SkyCopy.text(.resultChallengeScore, values: ["score": "156,000", "target": "150,000"])),
            ("open-sky", "ceremony.full", "Column 1 has no room for the next star.",
             SkyCopy.text(.resultScore, values: ["score": "5"]))
        ]
        for (name, key, reason, score) in fixtures {
            let line = SkyDialogueLibrary.line(key, values: ["reason": reason, "score": score])
            let content = SkyResultSummary.content(line.text, scoreLabel: score)
            XCTAssertEqual(String(content.characters), line.text)
            for width: CGFloat in [330, 420] {
                func reading(_ size: DynamicTypeSize) -> some View {
                    Text(content).font(StarfallTheme.Typography.supporting)
                        .foregroundStyle(StarfallTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel(line.spokenText).environment(\.dynamicTypeSize, size)
                }
                let normal = UIHostingController(rootView: reading(.large)).sizeThatFits(in: CGSize(width: width, height: 4_000))
                let largest = UIHostingController(rootView: reading(.accessibility5)).sizeThatFits(in: CGSize(width: width, height: 4_000))
                XCTAssertLessThanOrEqual(normal.width, width)
                XCTAssertLessThanOrEqual(largest.width, width)
                XCTAssertGreaterThan(largest.height, normal.height, "Full native type must grow instead of shrinking")
                XCTAssertLessThan(largest.height, 2_000, "The unchanged result reader owns scrolling")
                let renderer = ImageRenderer(content: reading(.accessibility5).padding(16)
                    .frame(width: width + 32).background(StarfallTheme.Colors.skyTop))
                let attachment = XCTAttachment(image: try XCTUnwrap(renderer.uiImage))
                attachment.name = "hosted-terminal-summary-\(name)-AX5-width-\(Int(width))-content-fixture"
                attachment.lifetime = .keepAlways; add(attachment)
            }
        }
    }

    @MainActor func testSessionCapturesWinningWholeActionBeforeCallbacksAndCancellationKeepsIt() throws {
        let old = FallingSky.freshChallenge(.silverPools)
        var game = old
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,2), to: Cell(1,3)))
        let session = SkyLightReceiptSession()
        session.capture(turn, from: old, to: game, path: [], recipe: nil)
        let explanation = try XCTUnwrap(session.lastScore)
        XCTAssertEqual(explanation.total, 19_000)
        XCTAssertEqual(explanation.phases.map(\.points), [5_000,14_000])
        XCTAssertEqual(game.outcome, .won)
        session.cancel()
        XCTAssertEqual(session.lastScore, explanation)
        session.beginRound()
        XCTAssertNil(session.lastScore)
        XCTAssertNil(SkyLightReceiptSession().lastScore, "A cold session cannot invent earlier components")
    }

    @MainActor func testNoAwardSetupKeepsRecordAndNewSeparateClearReplacesItWithoutChain() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let session = SkyLightReceiptSession()
        let old = game
        let first = try XCTUnwrap(game.nudge(from: Cell(0,2), to: Cell(1,2)))
        session.capture(first, from: old, to: game, path: [], recipe: nil)
        XCTAssertEqual(session.lastScore?.total, 7_000)
        let before = game
        let second = try XCTUnwrap(game.nudge(from: Cell(3,2), to: Cell(3,1)))
        session.capture(second, from: before, to: game, path: [], recipe: nil)
        XCTAssertEqual(game.displayScore,12_000)
        XCTAssertEqual(session.lastScore?.total,5_000)
        XCTAssertEqual(session.lastScore?.phases.map(\.comboBonus),[0])
        let unchanged = session.lastScore
        session.capture(FallingSkyTurn(cleared: [], collected: 0, settled: game.board,
                                      forecast: game.incoming, arrivals: [], blockedColumn: nil),
                        from: game, to: game, path: [], recipe: nil)
        XCTAssertEqual(session.lastScore,unchanged)
    }

    @MainActor func testLiveReceiptsCopyOnlyPublishedPhasePrefixAndQuietFinalHasCompleteAggregate() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,2), to: Cell(1,3)))
        let phases = turn.resolutionPhases
        let first = StarlightCelebration(id: 1, phase: phases[0], cumulativeAward:5_000,total:5_000)
        let last = StarlightCelebration(id: 2, phase: phases[1], cumulativeAward:19_000,total:19_000,
                                        precedingPhases:[phases[0]])
        XCTAssertEqual(first.scoreExplanation?.phases.map(\.points),[5_000])
        XCTAssertEqual(last.scoreExplanation?.phases.map(\.points),[5_000,14_000])
        XCTAssertEqual(last.scoreExplanation?.total,last.displayAward)
        XCTAssertEqual(StarlightCelebration.duration,1.4)
        XCTAssertEqual(last.packets.count,min(StarlightCelebration.maximumPackets,last.contributors.count))
    }

    @MainActor func testCompleteStaticReadingGrowsAtLargestTextAndCompactEquationFitsReceipt() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let old = game
        let turn = try XCTUnwrap(game.nudge(from: Cell(1,2),to: Cell(1,3)))
        let explanation = try XCTUnwrap(SkyScoreExplanation(turn:turn,from:old))
        let normal = UIHostingController(rootView: SkyScoreExplanationView(explanation:explanation)
            .environment(\.dynamicTypeSize,.large))
        let largest = UIHostingController(rootView: SkyScoreExplanationView(explanation:explanation)
            .environment(\.dynamicTypeSize,.accessibility5))
        let ordinarySize = normal.sizeThatFits(in:CGSize(width:330,height:4_000))
        let largestSize = largest.sizeThatFits(in:CGSize(width:330,height:4_000))
        XCTAssertLessThanOrEqual(ordinarySize.width,330)
        XCTAssertLessThanOrEqual(largestSize.width,330)
        XCTAssertGreaterThan(largestSize.height,ordinarySize.height)
        XCTAssertLessThan(largestSize.height,2_000,"The native terminal reader scrolls; text never shrinks")
        let caption = UIHostingController(rootView:Text(explanation.compactText).font(.caption2)
            .monospacedDigit().fixedSize(horizontal:false,vertical:true)
            .environment(\.dynamicTypeSize,.large))
        for width:CGFloat in [180,220,330] {
            let measured = caption.sizeThatFits(in:CGSize(width:width,height:1_000))
            XCTAssertLessThanOrEqual(measured.width,width)
            XCTAssertLessThanOrEqual(measured.height,30)
        }
        let rendered = ImageRenderer(content:SkyScoreExplanationView(explanation:explanation)
            .environment(\.dynamicTypeSize,.large).padding(16).frame(width:390)
            .background(StarfallTheme.Colors.skyTop))
        let attachment = XCTAttachment(image:try XCTUnwrap(rendered.uiImage))
        attachment.name = "score-complete-committed-components"
        attachment.lifetime = .keepAlways
        add(attachment)
        let live = StarlightCelebration(id:3,phase:turn.resolutionPhases[1],cumulativeAward:19_000,
                                        total:19_000,precedingPhases:[turn.resolutionPhases[0]])
        let label = ImageRenderer(content:SkyScoreReceiptLabel(event:live,tint:.yellow,width:220,height:72,
                                                              age:0.5,quiet:false)
            .environment(\.dynamicTypeSize,.large).background(StarfallTheme.Colors.skyTop))
        let liveAttachment = XCTAttachment(image:try XCTUnwrap(label.uiImage))
        liveAttachment.name = "score-live-cumulative-components"
        liveAttachment.lifetime = .keepAlways
        add(liveAttachment)
    }

    @MainActor func testNarrowLiveRegionKeepsThePrimaryAwardRatherThanClippingComponentText() throws {
        var game = FallingSky.freshChallenge(.silverPools)
        let turn = try XCTUnwrap(game.nudge(from:Cell(1,2),to:Cell(1,3)))
        let receipt = StarlightCelebration(id:4,phase:turn.resolutionPhases[1],cumulativeAward:19_000,
                                          total:19_000,precedingPhases:[turn.resolutionPhases[0]])
        for size:DynamicTypeSize in [.large,.xxxLarge] {
            let actual = ImageRenderer(content:SkyScoreReceiptLabel(event:receipt,tint:.yellow,
                width:80,height:40,age:0.5,quiet:true).environment(\.dynamicTypeSize,size))
            let primary = ImageRenderer(content:CrystalCelebrationLabel(event:receipt,tint:.yellow,
                width:80,height:40,showsTitle:true,age:0.5,quiet:true)
                .frame(width:80,height:40).environment(\.dynamicTypeSize,size))
            XCTAssertEqual(try XCTUnwrap(actual.uiImage).pngData(),try XCTUnwrap(primary.uiImage).pngData())
        }
    }

    @MainActor func testStoreTerminalCaptureDoesNotWaitOrAlterExactSaveAndColdRestoreOmitsIt() throws {
        let suite = "Starfall.ScoreExplanation.\(UUID())"
        let defaults = try XCTUnwrap(UserDefaults(suiteName:suite))
        defer { defaults.removePersistentDomain(forName:suite) }
        try SkySaveArchive.save(FallingSky.freshChallenge(.silverPools),to:defaults)
        let presenter = ScoreExplanationPresenter(), clock = ManualRainClock()
        let store = FallingSkyStore(defaults:defaults,arguments:[],presenter:presenter,clock:clock)
        store.setSuspended(false)
        defer { store.setSuspended(true) }
        let opening = store.game
        XCTAssertTrue(store.performTechnique(.nudge(Cell(1,2),Cell(1,3)),snapshot:opening,
                                              generation:store.constellationInputGeneration))
        XCTAssertEqual(store.finalScoreExplanation?.total,19_000)
        XCTAssertNil(store.celebration)
        XCTAssertEqual(store.game.outcome,.won)
        XCTAssertNil(clock.deadline)
        let bytes = defaults.data(forKey:SkySaveArchive.key)
        let world = defaults.data(forKey:WorldJourneyStore.key)
        store.settlePresentation(reason:"terminal")
        presenter.phase?(0); presenter.phase?(1); presenter.completion?()
        XCTAssertNil(store.celebration, "Retired callbacks cannot revive the terminal receipt")
        XCTAssertEqual(store.finalScoreExplanation?.total,19_000)
        XCTAssertEqual(defaults.data(forKey:SkySaveArchive.key),bytes)
        XCTAssertEqual(defaults.data(forKey:WorldJourneyStore.key),world)
        let restored = FallingSkyStore(defaults:defaults,arguments:[],presenter:FallingSkyRecorder(),clock:ManualRainClock())
        XCTAssertEqual(restored.game,store.game)
        XCTAssertNil(restored.finalScoreExplanation)
    }
}
