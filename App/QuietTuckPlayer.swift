import AVFoundation
import UIKit

@MainActor protocol ClearSoundPlaying: AnyObject {
    func play()
    func play(_ level: StarlightCelebration.Level)
    func stop()
}

extension ClearSoundPlaying {
    func play(_ level: StarlightCelebration.Level) { play() }
}

/// A new contact replaces the previous tail. No audio callback controls gameplay.
@MainActor protocol TuckAudioOutput: AnyObject {
    /// Returns whether the request was accepted, not a promise of audible output.
    func start(take: Int) -> Bool
    func stop()
}

@MainActor final class QuietTuckPlayer: ClearSoundPlaying {
    private let output: any TuckAudioOutput
    private let isActive: @MainActor () -> Bool
    private let notifications: NotificationCenter
    private var observers: [NSObjectProtocol] = []
    private var nextTake = 0
    private var interrupted = false

    init(output: (any TuckAudioOutput)? = nil,
         notifications: NotificationCenter = .default,
         isActive: @escaping @MainActor () -> Bool = { UIApplication.shared.applicationState == .active }) {
        self.output = output ?? BundledTuckOutput()
        self.notifications = notifications
        self.isActive = isActive
        observers.append(notifications.addObserver(forName: AVAudioSession.interruptionNotification,
                                                   object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                guard let self,
                      let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                self.interrupted = type == .began
                self.stop() // Ending an interruption never replays a missed contact.
            }
        })
        observers.append(notifications.addObserver(forName: AVAudioSession.routeChangeNotification,
                                                   object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated {
                guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                      raw == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
                self?.stop() // A future explicit tap may use the new route; no tail transfers.
            }
        })
        observers.append(notifications.addObserver(forName: UIApplication.willResignActiveNotification,
                                                   object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        })
    }

    deinit { observers.forEach(notifications.removeObserver) }

    func play() {
        guard !interrupted, isActive() else { return }
        if output.start(take: nextTake) { nextTake = (nextTake + 1) % 4 }
    }

    func play(_ level: StarlightCelebration.Level) {
        guard level != .ordinary else { play(); return }
        guard !interrupted, isActive() else { return }
        let take: Int
        switch level {
        case .ordinary: return // Handled by the rotating ordinary path above.
        case .brilliant: take = 4
        case .constellation: take = 5
        case .recipe: take = 6
        case .relay, .cascade: take = 7
        }
        _ = output.start(take: take)
    }

    func stop() { output.stop() }
}

/// Eight bounded local sources, one audible voice. Loading and session activation are lazy.
@MainActor final class BundledTuckOutput: TuckAudioOutput {
    static let names = (1...4).map { String(format: "sf_quiet_tuck_%02d", $0) }
    static let celebrationNames = ["sf_brilliant", "sf_constellation", "sf_recipe", "sf_relay"]
    private let worker: TuckAudioWorker
    private let hasAllFiles: Bool

    init(bundle: Bundle = .main,
         queue: DispatchQueue = DispatchQueue(label: "com.starfall.quiet-tucks", qos: .userInitiated),
         didStart: (@Sendable (Int) -> Void)? = nil) {
        let urls = Self.names.compactMap {
            bundle.url(forResource: $0, withExtension: "mp3", subdirectory: "Audio")
        } + Self.celebrationNames.compactMap {
            bundle.url(forResource: $0, withExtension: "wav", subdirectory: "Audio")
        }
        hasAllFiles = urls.count == Self.names.count + Self.celebrationNames.count
        worker = TuckAudioWorker(urls: urls, queue: queue, didStart: didStart)
    }

    func start(take: Int) -> Bool {
        guard hasAllFiles, (0..<(Self.names.count + Self.celebrationNames.count)).contains(take) else { return false }
        worker.request(take: take)
        return true
    }

    func stop() { worker.cancel() }
}

/// Player/session access stays on one queue; only the request token crosses threads.
/// Invalidating the token is synchronous, so slow activation cannot revive a muted cue.
private final class TuckAudioWorker: @unchecked Sendable {
    private let urls: [URL]
    private let queue: DispatchQueue
    private let didStart: (@Sendable (Int) -> Void)?
    private let lock = NSLock()
    private var requestID: UInt64 = 0
    private var players: [AVAudioPlayer] = []
    private var attemptedLoad = false
    private var sessionActive = false

    init(urls: [URL], queue: DispatchQueue, didStart: (@Sendable (Int) -> Void)?) {
        self.urls = urls
        self.queue = queue
        self.didStart = didStart
    }

    private func invalidate() -> UInt64 {
        lock.withLock { requestID &+= 1; return requestID }
    }

    private func isCurrent(_ token: UInt64) -> Bool {
        lock.withLock { requestID == token }
    }

    func request(take: Int) {
        let token = invalidate()
        queue.async { [self] in play(take: take, token: token) }
    }

    func cancel() {
        _ = invalidate()
        queue.async { [self] in stopVoices() }
    }

    private func play(take: Int, token: UInt64) {
        guard isCurrent(token) else { return }
        if !attemptedLoad {
            attemptedLoad = true
            // All packaged cues or silence: a packaging failure must never block a move.
            players = (try? urls.map { url in
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.7
                return player
            }) ?? []
        }
        guard players.indices.contains(take), isCurrent(token) else { return }
        do {
            if !sessionActive {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.ambient, mode: .default)
                try session.setActive(true)
                sessionActive = true
            }
            guard isCurrent(token) else { stopVoices(); return }
            players.forEach { $0.stop() }
            let player = players[take]
            player.currentTime = 0
            guard player.prepareToPlay(), isCurrent(token) else { stopVoices(); return }
            let started = player.play()
            guard isCurrent(token) else { stopVoices(); return }
            if started { didStart?(take) }
        } catch {
            stopVoices()
        }
    }

    private func stopVoices() {
        players.forEach { $0.stop() }
        if sessionActive {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            sessionActive = false
        }
    }
}
