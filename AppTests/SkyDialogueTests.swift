import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class SkyDialogueTests: XCTestCase {
    func testTypedInterfaceInventoryAndTemplatesRejectMissingExtraAndInjectedValues() throws {
        let catalog = SkyDialogueLibrary.catalog
        XCTAssertEqual(Set(try XCTUnwrap(catalog.copy).keys), Set(SkyCopy.Key.allCases.map(\.rawValue)))
        for key in SkyCopy.Key.allCases {
            let source = try XCTUnwrap(catalog.copy?[key.rawValue])
            let tokens = try SkyDialogueCatalog.placeholders(in: source)
            let values = Dictionary(uniqueKeysWithValues: tokens.map { ($0, "7") })
            let rendered = try catalog.copyText(key.rawValue, values: values)
            XCTAssertFalse(rendered.contains("{"), key.rawValue)
            XCTAssertFalse(rendered.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, key.rawValue)
        }
        XCTAssertThrowsError(try catalog.copyText("missing"))
        XCTAssertThrowsError(try catalog.copyText("result.blocked"))
        XCTAssertThrowsError(try catalog.copyText("result.blocked", values: ["column": "4", "typo": "1"]))
        XCTAssertThrowsError(try catalog.copyText("result.blocked", values: ["column": "{score}"]))
        XCTAssertEqual(SkyCopy.count(.eventEatenOne, .eventEatenMany, 1), "I swallowed 1 star.")
        XCTAssertEqual(SkyCopy.count(.eventEatenOne, .eventEatenMany, 3), "I swallowed 3 stars.")
        let malformed = Data(#"{"schemaVersion":1,"scripts":[{"id":"x","lines":[{"id":"x.1","speaker":"sunny","text":"Hello","priority":"help"}]}],"copy":{"bad":"An unmatched {token"}}"#.utf8)
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(malformed))
    }

    func testContextKeepsTheOriginalSpeakerAndForecastTense() throws {
        let game = ConstellationFixture.stormWarning.game()
        let dusk = SkyDialogueLibrary.line("guide.dusk-collapse", values: ["swallowed": "I swallowed 1 star."])
        let combined = SkyDialogueLibrary.contextual(dusk, game: game, cadence: game.cadenceStep)
        XCTAssertEqual(combined.speaker, .dusk)
        XCTAssertTrue(combined.text.contains("Left those for me?"))
        XCTAssertTrue(combined.text.contains("1 lighter shower before the storm."))
        XCTAssertFalse(combined.text.contains(".."))
        XCTAssertEqual(SkyDialogueLibrary.line("guide.paused").speaker, .twinkle)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.growth", values: ["growth": "A star grew"]).speaker, .spark)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.clear", values: ["score": "3"]).speaker, .pip)
        XCTAssertEqual(SkyDialogueLibrary.line("guide.won", values: ["score": "20"]).speaker, .sunny)
    }

    @MainActor func testDuskTeasesOnlyAfterCommittedConsumptionOrAnActuallyDrainedClear() throws {
        func store(_ fixture: String) -> (FallingSkyStore, FallingSkyRecorder) {
            let suite = "Starfall.CopyDusk.\(UUID())", defaults = UserDefaults(suiteName: suite)!
            addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
            let presenter = FallingSkyRecorder()
            let store = FallingSkyStore(defaults: defaults,
                arguments: ["--starfalls-reset", "--dusk-fixture=\(fixture)"],
                presenter: presenter, clock: ManualRainClock())
            store.setSuspended(false)
            return (store, presenter)
        }
        let (eating, presenter) = store("imminent")
        eating.callShower()
        XCTAssertEqual(eating.guideLine.speaker, .dusk)
        XCTAssertTrue(eating.guideLine.text.contains("I swallowed 3 stars."))
        XCTAssertEqual(eating.game.score, 0)
        let committed = eating.game
        eating.setSuspended(true); presenter.finish()
        XCTAssertEqual(eating.game, committed)
        XCTAssertNil(eating.dialogue.line, "A stale callback cannot deliver a taunt")

        let (gray, grayPresenter) = store("zeroClear")
        gray.clear(Cell(0, 1)); grayPresenter.finish()
        XCTAssertEqual(gray.game.score, 0)
        XCTAssertEqual(gray.guideLine.id, "guide.gray-clear.1")
        XCTAssertEqual(gray.guideLine.speaker, .dusk)
        XCTAssertTrue(gray.guideLine.text.contains("No starlight that time"))
        XCTAssertTrue(gray.guideLine.text.contains("You cleared me away"))

        let (invalid, _) = store("unfed")
        let before = invalid.game
        invalid.clear(Cell(6, 6))
        XCTAssertEqual(invalid.game, before)
        XCTAssertEqual(invalid.guideLine.speaker, .sunny, "An invalid tap gets useful help, not a taunt")
        XCTAssertTrue(invalid.guideLine.text.hasPrefix(SkyDialogueLibrary.line("guide.match-help").text))
    }

    @MainActor func testDuskHelpUsesTheRetainedRuleAndTraceCelebrationUsesDistinctStars() throws {
        let suite = "Starfall.CopyRules.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        for (rule, count) in [(DuskRule.feeding, "3"), (.patientFeeding, "5")] {
            let text = SkyCopy.text(.helpDusk, values: ["feeds": String(rule.feedingShowers)])
            XCTAssertTrue(text.contains("After \(count) feeding showers"))
            let help = SkyDialogueLibrary.line("guide.dusk-help", values: ["feeds": String(rule.feedingShowers)])
            XCTAssertTrue(help.text.contains("After \(count) feeding showers"))
        }
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults,
            arguments: ["--starfalls-reset", "--constellation-fixture=overlap"],
            presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        let path = [Cell(0,4), Cell(1,3), Cell(2,4), Cell(1,5), Cell(1,6)]
        let original = store.game
        store.clearTracedConstellation(path, snapshot: original, generation: store.constellationInputGeneration)
        presenter.finish()
        XCTAssertEqual(store.guideLine.id, "guide.constellation.1")
        XCTAssertEqual(store.guideLine.speaker, .spark)
        XCTAssertTrue(store.guideLine.text.contains("You connected 5!"))
        XCTAssertEqual(store.game.occupiedCount, original.occupiedCount - 5)
    }

    private func line(_ id: String, speaker: SkySpeaker = .sunny,
                      priority: SkyDialogueLine.Priority = .routine, seconds: Double? = 5) -> SkyDialogueLine {
        .init(id: id, speaker: speaker, text: "Message \(id)", priority: priority, seconds: seconds)
    }

    func testCatalogRendersEveryBundledScriptAndRejectsAuthoringErrors() throws {
        let catalog = SkyDialogueLibrary.catalog
        let samples = ["count": "4", "score": "18", "stars": "5", "dark": "Dark star", "growth": "A star grew", "arrival": "One star arrived", "detail": "A fixture", "release": "The hole releases its stars after 3 more showers.", "feeds": "5", "swallowed": "I swallowed 3 stars.", "shape": "Square", "depth": "2", "phase": "Storm: 3 heavy showers left.", "cadence": "Showers are closer together now.", "summary": "Paused", "reason": "First Light complete!", "context": "A storm is coming"]
        for source in catalog.scripts {
            let values = samples.filter { key, _ in source.lines.contains { $0.text.contains("{\(key)}") } }
            let rendered = try catalog.script(source.id, values: values)
            XCTAssertFalse(rendered.lines.isEmpty)
            XCTAssertTrue(rendered.lines.allSatisfy { !$0.text.contains("{") })
        }
        XCTAssertThrowsError(try catalog.script("typo"))
        XCTAssertThrowsError(try catalog.script("sky.won"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "A {broken"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "A stray }"))
        XCTAssertThrowsError(try SkyDialogueCatalog.placeholders(in: "{nested{token}}"))
        XCTAssertThrowsError(try catalog.script("sky.won", values: ["score": "18", "typo": "unused"]))
        let source = SkyDialogueScript(id: "test", lines: [line("one")])
        func data(version: Int = 1, scripts: [SkyDialogueScript]) throws -> Data {
            let encoded = try JSONEncoder().encode(scripts)
            let array = try JSONSerialization.jsonObject(with: encoded)
            return try JSONSerialization.data(withJSONObject: ["schemaVersion": version, "scripts": array])
        }
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(version: 2, scripts: [source])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [source, source])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [.init(id: "empty", lines: [])])))
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(data(scripts: [.init(id: "long", lines: [
            .init(id: "bad", speaker: .sunny, text: String(repeating: "x", count: 401), priority: .help, seconds: nil)
        ])])))
        let bad = "{\"schemaVersion\":1,\"scripts\":[{\"id\":\"x\",\"lines\":[{\"id\":\"x.1\",\"speaker\":\"typo\",\"text\":\"Hello\",\"priority\":\"help\"}]}]}"
        XCTAssertThrowsError(try SkyDialogueCatalog.decode(Data(bad.utf8)))
    }

    @MainActor func testSpeakerSequenceAndPriorityHaveOneCurrentMessageAndNoBacklog() {
        let session = SkyDialogueSession()
        XCTAssertFalse(session.play(.init(id: "empty", lines: [])))
        XCTAssertFalse(session.show(.init(id: "bad", speaker: .sunny, text: "{score}", priority: .help, seconds: nil)))
        let welcome = line("hello", speaker: .spark, priority: .help, seconds: nil)
        let end = line("end", speaker: .nova, priority: .help, seconds: nil)
        XCTAssertTrue(session.play(.init(id: "map.arrival", lines: [welcome, end])))
        XCTAssertEqual(session.line?.spokenText, "Spark. Message hello")
        XCTAssertTrue(session.hasNext)
        XCTAssertFalse(session.show(line("routine")))
        XCTAssertFalse(session.show(welcome), "Repeated events must not rewind a script")
        session.next()
        XCTAssertEqual(session.line?.speaker, .nova); XCTAssertFalse(session.hasNext)
        XCTAssertTrue(session.show(line("storm", speaker: .dusk, priority: .warning)))
        XCTAssertFalse(session.show(line("late-help", priority: .help)))
        XCTAssertTrue(session.show(line("won", speaker: .twinkle, priority: .outcome, seconds: nil)))
        XCTAssertFalse(session.show(line("late-storm", priority: .warning)))
        XCTAssertEqual(session.line?.id, "won")
        session.dismiss(); session.reopen()
        XCTAssertEqual(session.line?.id, "won"); XCTAssertTrue(session.visible)
        XCTAssertFalse(session.hasNext, "Discarded events never become a queued script")
    }

    @MainActor func testExpiryRejectsStaleCallbacksAfterNewMessageReopenAndReset() {
        let session = SkyDialogueSession()
        session.show(line("first")); let old = session.revision
        session.show(line("second", speaker: .pip))
        session.expire(revision: old)
        XCTAssertTrue(session.visible); XCTAssertEqual(session.line?.speaker, .pip)
        let current = session.revision
        session.dismiss(); session.reopen(); session.expire(revision: current)
        XCTAssertTrue(session.visible)
        session.expire(revision: session.revision)
        XCTAssertFalse(session.visible); XCTAssertEqual(session.line?.id, "second")
        XCTAssertTrue(session.show(line("second", speaker: .pip)), "Explicit repeated requests can reopen closed information")
        let stale = session.revision
        session.reset(); session.show(line("new-sky")); session.expire(revision: stale)
        XCTAssertEqual(session.line?.id, "new-sky"); XCTAssertTrue(session.visible)
        session.play(.init(id: "manual", lines: [line("a"), line("b")]))
        session.expire(revision: session.revision)
        XCTAssertTrue(session.visible); XCTAssertTrue(session.hasNext, "Scripts wait for the player")
    }

    @MainActor func testAllSpeakerAssetsArePackagedWithTransparentMarginsAtBoundedSize() throws {
        for speaker in SkySpeaker.allCases {
            let image = try XCTUnwrap(UIImage(named: speaker.portraitAsset), speaker.rawValue)
            let cg = try XCTUnwrap(image.cgImage)
            XCTAssertEqual(cg.width, 256); XCTAssertEqual(cg.height, 256)
            XCTAssertTrue([CGImageAlphaInfo.premultipliedLast, .premultipliedFirst, .first, .last].contains(cg.alphaInfo))
            var pixels = [UInt8](repeating: 0, count: 256 * 256 * 4)
            let context = try XCTUnwrap(CGContext(data: &pixels, width: 256, height: 256,
                bitsPerComponent: 8, bytesPerRow: 1024, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(cg, in: CGRect(x: 0, y: 0, width: 256, height: 256))
            for edge in 0..<256 {
                for (x, y) in [(edge, 0), (edge, 255), (0, edge), (255, edge)] {
                    XCTAssertLessThan(pixels[(y * 256 + x) * 4 + 3], 16, "Full tips need transparent margins: \(speaker)")
                }
            }
        }
    }

    func testIslandPlacementFallsBackForUnknownSmallAndAccessibleLayouts() {
        XCTAssertTrue(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 440, height: 956), topInset: 62, accessible: false))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "unknown", size: .init(width: 440, height: 956), topInset: 62, accessible: false))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 440, height: 956), topInset: 62, accessible: true))
        XCTAssertFalse(SkyShowerPlacement.usesIsland(hardware: "iPhone17,2", size: .init(width: 956, height: 440), topInset: 0, accessible: false))
    }

    func testEveryForecastStarFinishesOnBothPathsBeforeReset() {
        for count in 1...5 {
            for spacing in [0.105, 16.0/108] {
                for index in 0..<count {
                    // Previous fixed-spacing mapping ends at 1-index*spacing: followers never arrive.
                    let oldEndpoint = 1 - Double(index)*spacing
                    if index > 0 { XCTAssertLessThan(oldEndpoint, 1) }
                    let arrival = 0.96 - Double(count-1-index)*0.045
                    let atEnd = SkyTrailMotion.sample(progress: arrival, index: index, count: count, spacing: spacing)
                    XCTAssertEqual(atEnd.position, 1, accuracy: 0.00001)
                    XCTAssertEqual(atEnd.opacity, 1, accuracy: 0.00001)
                    let reset = SkyTrailMotion.sample(progress: 1, index: index, count: count, spacing: spacing)
                    XCTAssertEqual(reset.position, 1); XCTAssertEqual(reset.opacity, 0)
                    var last = 0.0
                    for frame in 0...300 {
                        let sample = SkyTrailMotion.sample(progress: Double(frame)/300, index: index, count: count, spacing: spacing)
                        XCTAssertGreaterThanOrEqual(sample.position, last)
                        XCTAssertTrue((0...1).contains(sample.position))
                        if sample.opacity < 1 { XCTAssertEqual(sample.position, 1) }
                        last = sample.position
                    }
                }
            }
        }
    }
}


extension SkyDialogueTests {
    @MainActor func testCommittedClearPublishesFeedbackAfterPresentationAndRestoresWithoutTransientCopy() throws {
        let suite = "Starfall.DialogueCompletion.\(UUID())", defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try SkySaveArchive.encode(FallingSky(seed: 5, generation: .current, duskRule: .patientFeeding)), forKey: SkySaveArchive.key)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults,
            arguments: [],
            presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        for _ in 0..<6 { store.callShower(); presenter.finish() }
        let darkIndex = try XCTUnwrap(store.game.board.firstIndex { $0?.isDark == true })
        store.clear(Cell(darkIndex / 7, darkIndex % 7))
        let help = store.pausedGuideLine
        XCTAssertEqual(help.speaker, .dusk)
        XCTAssertTrue(help.text.contains("beside me to send me off"))
        let source = store.game, cell = Cell(0,0)
        let value = source.reward(of: source.group(at: cell))
        XCTAssertGreaterThanOrEqual(value, 3)
        store.clear(cell)
        XCTAssertEqual(store.game.score, value, "Core reward commits before the result animation")
        XCTAssertEqual(store.pausedGuideLine, help, "Visible copy stays at its prior event until presentation completion")
        presenter.finish()
        let clear = SkyDialogueLibrary.line("guide.clear", values: ["score": String(value)])
        XCTAssertEqual(store.pausedGuideLine, SkyDialogueLibrary.contextual(clear, game: store.game, cadence: store.nextShowerCadence))
        let committed = store.game
        let restored = FallingSkyStore(defaults: defaults, arguments: [],
            presenter: FallingSkyRecorder(), clock: ManualRainClock())
        restored.setSuspended(false)
        XCTAssertEqual(restored.game, committed)
        XCTAssertTrue(restored.isPaused)
        XCTAssertEqual(restored.pausedGuideLine, SkyDialogueLibrary.contextual(SkyDialogueLibrary.line("guide.restore"), game: restored.game, cadence: restored.nextShowerCadence))
        XCTAssertFalse(restored.pausedGuideLine.text.contains("+"))
    }
}
