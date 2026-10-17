import XCTest
import UIKit
import StarfallCore
@testable import Starfall

final class SkyLeaderboardTests: XCTestCase {
    @MainActor private func make() -> (SkyLeaderboard, RankingClientStub, UserDefaults) {
        let suite = "Rankings.Tests.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        addTeardownBlock { defaults.removePersistentDomain(forName: suite) }
        let client = RankingClientStub()
        return (SkyLeaderboard(defaults: defaults, client: client), client, defaults)
    }

    func testPendingBestAcknowledgementPreservesANewerOfflineScore() {
        var records = SkyRankingRecords()
        records.record(score: 42, playerID: "A")
        records.record(score: 46, playerID: "A")
        records.acknowledge(score: 42, playerID: "A")
        XCTAssertEqual(records.accounts["A"]?.pending, 46)
        records.acknowledge(score: 46, playerID: "A")
        records.record(score: 31, playerID: "A")
        XCTAssertNil(records.accounts["A"]?.pending)
        XCTAssertEqual(records.localBest, 46)
        XCTAssertTrue(records.isValid)
    }

    @MainActor func testSignedOutResultStaysLocalAfterSignIn() async {
        let (model, client, _) = make()
        model.record(SkyRankedResult(score: 42, playerID: nil))
        client.player = SkyRankingPlayer(id: "B", name: "Bee")
        model.connectionChanged(true)
        await model.waitUntilIdle()
        XCTAssertEqual(model.records.localBest, 42)
        XCTAssertTrue(client.submissions.isEmpty)
    }

    @MainActor func testOfflineResultSurvivesRelaunchAndSubmitsOnlyForItsOwner() async {
        let (model, client, defaults) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        model.authenticationChanged()
        model.record(SkyRankedResult(score: 46, playerID: "A"))
        XCTAssertTrue(client.submissions.isEmpty)
        let restored = SkyLeaderboard(defaults: defaults, client: client)
        client.player = SkyRankingPlayer(id: "B", name: "Bee")
        restored.connectionChanged(true)
        await restored.waitUntilIdle()
        XCTAssertTrue(client.submissions.isEmpty)
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        restored.authenticationChanged()
        await restored.waitUntilIdle()
        XCTAssertEqual(client.submissions.map(\.0), [46])
        XCTAssertEqual(client.submissions.map(\.1), ["A"])
        XCTAssertNil(restored.records.accounts["A"]?.pending)
        XCTAssertEqual(restored.records.accounts["A"]?.submitted, 46)
    }

    @MainActor func testFailedSubmissionKeepsPendingAndCachedScopesSeparate() async {
        let (model, client, _) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        client.failSubmission = true
        model.record(SkyRankedResult(score: 42, playerID: "A"))
        model.connectionChanged(true)
        await model.waitUntilIdle()
        XCTAssertEqual(model.account?.pending, 42)
        XCTAssertNotNil(model.message)
        XCTAssertEqual(model.standings?.entries.first?.name, "Friend")
        model.scope = .global; model.refresh()
        await model.waitUntilIdle()
        XCTAssertEqual(model.standings?.entries.first?.name, "Global")
        model.connectionChanged(false)
        model.scope = .friends
        XCTAssertEqual(model.standings?.entries.first?.name, "Friend")
        XCTAssertFalse(model.loading)
    }

    @MainActor func testAccountSwitchRejectsLateSubmissionAndStandings() async {
        let (model, client, _) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        client.holdSubmission = true
        model.record(SkyRankedResult(score: 42, playerID: "A"))
        model.connectionChanged(true)
        await client.waitForSubmission()
        client.player = SkyRankingPlayer(id: "B", name: "Bee")
        model.authenticationChanged()
        client.finishSubmission()
        await model.waitUntilIdle()
        XCTAssertEqual(model.records.accounts["A"]?.pending, 42)
        XCTAssertEqual(model.records.accounts["A"]?.submitted, 0)
        XCTAssertNil(model.records.accounts["A"]?.friends)
        XCTAssertEqual(model.player?.id, "B")
    }

    @MainActor func testBackgroundAndScopeSwitchRejectLateFetch() async {
        let (model, client, _) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        client.holdStandings = true
        model.connectionChanged(true)
        await client.waitForFetch()
        model.scope = .global; model.suspend()
        client.finishFetch()
        await Task.yield()
        XCTAssertNil(model.account?.friends)
        XCTAssertFalse(model.loading)
        let before = client.fetches
        model.connectionChanged(false); model.connectionChanged(true)
        XCTAssertEqual(client.fetches, before, "Background reconnect must not start a new request")
        client.holdStandings = false
        model.resume()
        await model.waitUntilIdle()
        XCTAssertNotNil(model.account?.global)
    }

    @MainActor func testTimeoutStopsSpinnerRejectsLateFetchAndAllowsRefresh() async {
        let (_, client, defaults) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        client.holdStandings = true
        let model = SkyLeaderboard(defaults: defaults, client: client, monitorsConnection: false,
                                   requestTimeout: .milliseconds(50))
        model.connectionChanged(true)
        await client.waitForFetch()
        await model.waitUntilIdle()
        XCTAssertTrue(model.message?.contains("taking too long") == true)
        client.finishFetch()
        await Task.yield()
        XCTAssertNil(model.standings)
        client.holdStandings = false
        model.refresh()
        await model.waitUntilIdle()
        XCTAssertNotNil(model.standings)
    }

    @MainActor func testScopeChangeRejectsAFormerScopeResponse() async {
        let (model, client, _) = make()
        client.player = SkyRankingPlayer(id: "A", name: "Aye")
        client.holdStandings = true
        model.connectionChanged(true)
        await client.waitForFetch()
        client.holdStandings = false
        model.scope = .global; model.refresh()
        await model.waitUntilIdle()
        client.finishFetch()
        await Task.yield()
        XCTAssertNil(model.account?.friends)
        XCTAssertEqual(model.account?.global?.entries.first?.name, "Global")
    }

    @MainActor func testCorruptRecordsAndSidecarDoNotInvalidateGameSave() throws {
        let (_, _, defaults) = make()
        var invalid = SkyRankingRecords()
        invalid.localBest = -1
        defaults.set(try JSONEncoder().encode(invalid), forKey: SkyRankingRecords.key)
        XCTAssertEqual(SkyLeaderboard(defaults: defaults, client: RankingClientStub()).records.localBest, 0)
        let game = FallingSky(seed: 5)
        let data = try JSONEncoder().encode(game)
        defaults.set(data, forKey: FallingSkyStore.saveKey)
        defaults.set(Data("bad".utf8), forKey: SkyRankingSession.key)
        XCTAssertFalse(SkyRankingSession.restore(defaults: defaults, gameData: data).eligible)
        XCTAssertEqual(FallingSkyStore(defaults: defaults, arguments: []).game, game)
    }

    @MainActor func testCommittedTerminalResultPrecedesAnimationAndCannotRepeatOnRestart() throws {
        let (_, _, defaults) = make()
        let presenter = RankingPresenter()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter)
        var results: [SkyRankedResult] = []
        store.rankedPlayerID = { "A" }
        store.rankedResultHandler = { results.append($0) }
        store.setSuspended(false)
        // Earn a score, then let columns fill through the real deterministic rules.
        store.callShower(); presenter.finish()
        let cell = try XCTUnwrap(store.game.legalGroups.first?.first)
        store.clear(cell); presenter.finish()
        for _ in 0..<150 where !store.game.isOver { store.callShower(); presenter.finish() }
        XCTAssertTrue(store.game.isOver)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.score, store.game.score)
        XCTAssertEqual(results.first?.playerID, "A")
        store.setSuspended(true); store.deliverRankedResult(); presenter.finish()
        XCTAssertEqual(results.count, 1)
        store.restart(sameSky: true); presenter.finish()
        XCTAssertEqual(results.count, 1)
    }

    @MainActor func testUndeliveredTerminalResultRestoresWithOriginalOwner() throws {
        let (_, _, defaults) = make()
        let presenter = RankingPresenter()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter)
        store.rankedPlayerID = { "Original" }
        store.setSuspended(false)
        store.callShower(); presenter.finish()
        store.clear(try XCTUnwrap(store.game.legalGroups.first?.first)); presenter.finish()
        for _ in 0..<150 where !store.game.isOver { store.callShower(); presenter.finish() }
        XCTAssertTrue(store.game.isOver)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter)
        restored.rankedPlayerID = { "NewAccount" }
        var results: [SkyRankedResult] = []
        restored.rankedResultHandler = { results.append($0) }
        restored.deliverRankedResult(); restored.deliverRankedResult()
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.playerID, "Original")
        XCTAssertEqual(results.first?.score, store.game.score)
    }

    @MainActor func testChangedThenResetBalanceAndLegacySavesNeverBecomeRanked() throws {
        let (_, _, defaults) = make()
        let presenter = RankingPresenter()
        let store = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter)
        store.setSuspended(false)
        store.setBalance(StarfallBalance(pace: .gentle))
        store.setBalance(StarfallBalance())
        let data = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertFalse(SkyRankingSession.restore(defaults: defaults, gameData: data).eligible)
        store.restart(sameSky: true)
        let fresh = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertTrue(SkyRankingSession.restore(defaults: defaults, gameData: fresh).eligible)
        defaults.removeObject(forKey: SkyRankingSession.key)
        let restored = FallingSkyStore(defaults: defaults, arguments: [], presenter: presenter)
        restored.setSuspended(false)
        let legacy = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertFalse(SkyRankingSession.restore(defaults: defaults, gameData: legacy).eligible)
        restored.startFirstLight()
        let challenge = try XCTUnwrap(defaults.data(forKey: FallingSkyStore.saveKey))
        XCTAssertFalse(SkyRankingSession.restore(defaults: defaults, gameData: challenge).eligible)
    }
}

@MainActor private extension SkyLeaderboard {
    func waitUntilIdle(file: StaticString = #filePath, line: UInt = #line) async {
        let limit = Date().addingTimeInterval(3)
        while loading && Date() < limit { await Task.yield() }
        XCTAssertFalse(loading, file: file, line: line)
    }
}
@MainActor private final class RankingClientStub: SkyRankingClient {
    var player: SkyRankingPlayer?
    var authenticationChanged: (() -> Void)?
    var submissions: [(Int, String)] = []
    var failSubmission = false, holdSubmission = false, holdStandings = false
    var fetches = 0
    var submission: CheckedContinuation<Void, Never>?
    var fetch: CheckedContinuation<Void, Never>?
    func authenticate(present: @escaping (UIViewController) -> Void) { authenticationChanged?() }
    func submit(score: Int, playerID: String) async throws {
        submissions.append((score, playerID))
        if holdSubmission { await withCheckedContinuation { submission = $0 } }
        if failSubmission { throw URLError(.notConnectedToInternet) }
    }
    func standings(scope: SkyRankingScope) async throws -> SkyStandings {
        fetches += 1
        if holdStandings { await withCheckedContinuation { fetch = $0 } }
        return SkyStandings(updated: Date(), entries: [SkyRankingEntry(id: "other", name: scope == .friends ? "Friend" : "Global", rank: 1, score: 50)], local: nil)
    }
    func waitForSubmission() async {
        let limit = Date().addingTimeInterval(3)
        while submission == nil && Date() < limit { await Task.yield() }
        XCTAssertNotNil(submission)
    }
    func waitForFetch() async {
        let limit = Date().addingTimeInterval(3)
        while fetch == nil && Date() < limit { await Task.yield() }
        XCTAssertNotNil(fetch)
    }
    func finishSubmission() { submission?.resume(); submission = nil }
    func finishFetch() { fetch?.resume(); fetch = nil }
}
@MainActor private final class RankingPresenter: FallingSkyPresenting {
    var reduceMotion = false
    var completion: (() -> Void)?
    func render(_ game: FallingSky) {}
    func animate(_ turn: FallingSkyTurn, from old: FallingSky, to game: FallingSky, completion: @escaping () -> Void) { self.completion = completion }
    func finish() { completion?() }
}
