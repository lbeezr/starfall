import UIKit
import StarfallCore

/// Device feedback is independent of the deterministic rules and SpriteKit playback.
@MainActor protocol GameFeedbackProviding: AnyObject {
    func cleared(_ turn: Turn, outcome: Outcome, soundEnabled: Bool, calmEffects: Bool)
    func announce(_ message: String)
    func stopSounds()
}

@MainActor final class GameFeedback: GameFeedbackProviding {
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()
    private let traceReady = UIImpactFeedbackGenerator(style: .rigid)
    private let sound: any ClearSoundPlaying

    init(sound: (any ClearSoundPlaying)? = nil) {
        self.sound = sound ?? QuietTuckPlayer()
    }

    func cleared(_ turn: Turn, outcome: Outcome, soundEnabled: Bool, calmEffects: Bool) {
        if soundEnabled { sound.play() }
        guard !calmEffects, !UIAccessibility.isReduceMotionEnabled else { return }
        if outcome == .won {
            notification.notificationOccurred(.success)
        } else {
            impact.impactOccurred(intensity: 0.45)
        }
    }

    func announce(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        stopSounds() // The result announcement never waits for, or competes with, a tail.
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    func stopSounds() { sound.stop() }
}

/// Falling-sky cues use the same bounded local sound and haptic owner.
@MainActor protocol FallingSkyFeedbackProviding: AnyObject {
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool)
    func collected(_ level: StarlightCelebration.Level, soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool)
    func traceStep(count: Int, enabled: Bool)
    func announce(_ message: String)
    func stopSounds()
}

extension FallingSkyFeedbackProviding {
    func traceStep(count: Int, enabled: Bool) {}
    // Existing injected feedback clients preserve their preference/recording contract.
    func collected(_ level: StarlightCelebration.Level, soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        collected(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled, reducedMotion: reducedMotion)
    }
}

extension GameFeedback: FallingSkyFeedbackProviding {
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        collected(.ordinary, soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled, reducedMotion: reducedMotion)
    }

    func collected(_ level: StarlightCelebration.Level, soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        if soundEnabled && !UIAccessibility.isVoiceOverRunning { sound.play(level) }
        if hapticsEnabled && !reducedMotion && !UIAccessibility.isReduceMotionEnabled {
            if level == .ordinary { impact.impactOccurred(intensity: 0.55) }
            else { notification.notificationOccurred(.success) }
        }
    }

    func traceStep(count: Int, enabled: Bool) {
        guard enabled, !UIAccessibility.isReduceMotionEnabled, !UIAccessibility.isVoiceOverRunning else { return }
        if count == 5 { traceReady.impactOccurred(intensity: 0.8) }
        else { impact.impactOccurred(intensity: min(0.85, 0.2 + Double(count) * 0.1)) }
        impact.prepare(); traceReady.prepare()
    }

}
