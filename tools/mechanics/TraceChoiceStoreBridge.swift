/// Test-only bridge appended to an exported hosted-test target; never shipping code.
final class TraceChoiceStoreBridge: XCTestCase {
    @MainActor func testStageOrCommitChosenWalk() throws {
        #if !targetEnvironment(simulator)
        throw XCTSkip("Fixture staging is simulator-only; preserve the phone lab round")
        #else
        let data = try XCTUnwrap(Data(base64Encoded: "__SAVED_STATE__"))
        let initial = try JSONDecoder().decode(FallingSky.self, from: data)
        XCTAssertTrue(initial.isValidSave && !initial.isOver)
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "starfall.constellations.candidate"))
        defaults.set(data, forKey: FallingSkyStore.saveKey)
        let presenter = FallingSkyRecorder()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter, clock: ManualRainClock())
        store.setSuspended(false)
        XCTAssertEqual(store.game, initial)
        let environment = ProcessInfo.processInfo.environment
        let text = environment["STARFALL_CHOICE_WALK"] ?? environment["TEST_RUNNER_STARFALL_CHOICE_WALK"] ?? ""
        if !text.isEmpty {
            let tokens = text.split(separator: ",")
            guard tokens.count <= 196 else { throw NSError(domain: "TraceChoiceBridge", code: 1) }
            let path = try tokens.map { token -> Cell in
                let numbers = token.split(separator: ":")
                guard numbers.count == 2, let row = Int(numbers[0]), let column = Int(numbers[1]),
                      (0..<7).contains(row), (0..<7).contains(column) else {
                    throw NSError(domain: "TraceChoiceBridge", code: 2)
                }
                return Cell(row, column)
            }
            XCTAssertNotNil(initial.constellationCells(along: path))
            store.clearTracedConstellation(path, snapshot: initial, generation: store.constellationInputGeneration)
            XCTAssertGreaterThan(store.game.score, initial.score)
            presenter.finish()
            XCTAssertFalse(store.busy)
        }
        let restored = try JSONDecoder().decode(FallingSky.self,
            from: XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey)))
        XCTAssertEqual(restored, store.game)
        XCTAssertTrue(restored.isValidSave)
        let attachment = XCTAttachment(string: String(data: try JSONEncoder().encode(restored), encoding: .utf8)!)
        attachment.name = "Selected-choice-committed-state"; attachment.lifetime = .keepAlways; add(attachment)
        #endif
    }
}
