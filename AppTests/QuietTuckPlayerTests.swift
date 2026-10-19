import AVFoundation
import XCTest
import StarfallCore
@testable import Starfall

final class QuietTuckPlayerTests: XCTestCase {
    @MainActor func testCelebrationUsesOneDistinctVoiceAndPreservesOrdinaryRotation() {
        let output = RecordingTuckOutput()
        let player = QuietTuckPlayer(output: output, notifications: NotificationCenter(), isActive: { true })
        player.play(); player.play(.brilliant); player.play(.constellation); player.play(.recipe(.square)); player.play(.recipe(.cross)); player.play(.relay(2)); player.play(.relay(9)); player.play()
        XCTAssertEqual(output.takes, [0, 4, 5, 6, 6, 7, 7, 1])
        player.stop(); XCTAssertEqual(output.stops, 1)
    }

    @MainActor func testCelebrationResourcesDecodeWithFiniteDuration() throws {
        for (name,duration) in zip(BundledTuckOutput.celebrationNames,[0.74,0.74,0.42,0.54]) {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Audio"))
            let decoded = try AVAudioPlayer(contentsOf: url)
            XCTAssertEqual(decoded.duration, duration, accuracy: 0.005)
        }
    }

    @MainActor func testRotationSurvivesStopsAndNeverQueuesPlayback() async {
        let output = RecordingTuckOutput()
        let player = QuietTuckPlayer(output: output, notifications: NotificationCenter(), isActive: { true })
        for _ in 0..<4 { player.play() }
        player.stop()
        XCTAssertEqual(output.takes, [0, 1, 2, 3])
        player.play()
        XCTAssertEqual(output.takes, [0, 1, 2, 3, 0])
        XCTAssertEqual(output.stops, 1)
    }

    @MainActor func testInterruptedAndInactiveTapsAreDroppedWithoutReplay() async {
        let center = NotificationCenter()
        let output = RecordingTuckOutput()
        var active = true
        let player = QuietTuckPlayer(output: output, notifications: center, isActive: { active })
        player.play(); player.play(.recipe(.square))
        center.post(name: AVAudioSession.interruptionNotification, object: nil,
                    userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        player.play(); player.play(.relay(2))
        XCTAssertEqual(output.takes, [0, 6])
        center.post(name: AVAudioSession.interruptionNotification, object: nil,
                    userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue])
        XCTAssertEqual(output.takes, [0, 6])
        active = false
        player.play(); player.play(.relay(2))
        XCTAssertEqual(output.takes, [0, 6])
        active = true
        player.play(); player.play(.relay(2))
        XCTAssertEqual(output.takes, [0, 6, 1, 7])
    }

    @MainActor func testHeadphoneDisconnectAndInactivityStopWithoutReplaying() async {
        let center = NotificationCenter()
        let output = RecordingTuckOutput()
        let player = QuietTuckPlayer(output: output, notifications: center, isActive: { true })
        player.play()
        center.post(name: AVAudioSession.routeChangeNotification, object: nil,
                    userInfo: [AVAudioSessionRouteChangeReasonKey: AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue])
        center.post(name: UIApplication.willResignActiveNotification, object: nil)
        XCTAssertEqual(output.stops, 2)
        XCTAssertEqual(output.takes, [0])
    }

    @MainActor func testRejectedPlaybackRequestDoesNotConsumeSelectedTake() async {
        let output = RecordingTuckOutput()
        let player = QuietTuckPlayer(output: output, notifications: NotificationCenter(), isActive: { true })
        output.succeeds = false
        player.play()
        output.succeeds = true
        player.play()
        player.play()
        XCTAssertEqual(output.takes, [0, 0, 1])
    }

    @MainActor func testFeedbackUsesOneSelectedContactForEveryOutcomeAndHonorsMute() async throws {
        let sound = RecordingClearSound()
        let feedback = GameFeedback(sound: sound)
        var game = Game(seed: 42)
        let turn = try XCTUnwrap(game.tap(Cell(1, 1)))
        for outcome in [Outcome.playing, .won, .lost] {
            feedback.cleared(turn, outcome: outcome, soundEnabled: true, calmEffects: true)
        }
        XCTAssertEqual(sound.plays, 3)
        feedback.cleared(turn, outcome: .playing, soundEnabled: false, calmEffects: true)
        XCTAssertEqual(sound.plays, 3)
        feedback.stopSounds()
        XCTAssertEqual(sound.stops, 1)
    }

    @MainActor func testShippedFilesDecodeAndAllNativeCuesCanStart() async throws {
        for name in BundledTuckOutput.names {
            let url = try XCTUnwrap(Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio"))
            let decoded = try AVAudioPlayer(contentsOf: url)
            XCTAssertEqual(decoded.duration, 0.48, accuracy: 0.005)
            XCTAssertEqual(decoded.numberOfChannels, 2)
        }
        let starts = (0..<8).map { expectation(description: "Native take \($0) starts") }
        let queue = DispatchQueue(label: "StarfallNativeAudioTest")
        let output = BundledTuckOutput(queue: queue, didStart: { starts[$0].fulfill() })
        for take in 0..<8 {
            XCTAssertTrue(output.start(take: take))
            await fulfillment(of: [starts[take]], timeout: 5)
        }
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .ambient)
        output.stop()
        let drained = expectation(description: "Native audio stops")
        queue.async { drained.fulfill() }
        await fulfillment(of: [drained], timeout: 5)
        // Starting a native player is not a listening or physical-device acceptance result.
    }

    @MainActor func testSlowAudioQueueDropsSupersededAndMutedRequests() async {
        let queue = DispatchQueue(label: "StarfallAudioCancellationTest")
        let started = expectation(description: "Only latest unmuted request starts")
        let output = BundledTuckOutput(queue: queue, didStart: { take in
            XCTAssertEqual(take, 7)
            started.fulfill()
        })
        queue.suspend()
        XCTAssertTrue(output.start(take: 0))
        XCTAssertTrue(output.start(take: 6))
        output.stop()
        XCTAssertTrue(output.start(take: 7))
        queue.resume()
        await fulfillment(of: [started], timeout: 5)
        output.stop()
        let drained = expectation(description: "Latest audio stops")
        queue.async { drained.fulfill() }
        await fulfillment(of: [drained], timeout: 5)
    }

    @MainActor func testMuteInvalidatesQueuedAudioBeforeItCanStart() async {
        let queue = DispatchQueue(label: "StarfallAudioMuteTest")
        let drained = expectation(description: "Canceled work drains")
        let output = BundledTuckOutput(queue: queue, didStart: { _ in
            XCTFail("A muted pending contact must never start")
        })
        queue.suspend()
        XCTAssertTrue(output.start(take: 0))
        output.stop()
        queue.async { drained.fulfill() }
        queue.resume()
        await fulfillment(of: [drained], timeout: 5)
    }

    @MainActor func testMissingResourcesFailSilently() async throws {
        let output = BundledTuckOutput(bundle: Bundle(for: Self.self))
        XCTAssertFalse(output.start(take: 0))
        output.stop()
    }
}

@MainActor private final class RecordingTuckOutput: TuckAudioOutput {
    var takes: [Int] = []
    var stops = 0
    var succeeds = true
    func start(take: Int) -> Bool { takes.append(take); return succeeds }
    func stop() { stops += 1 }
}

@MainActor private final class RecordingClearSound: ClearSoundPlaying {
    var plays = 0
    var stops = 0
    func play() { plays += 1 }
    func stop() { stops += 1 }
}
