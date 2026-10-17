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
    func stopSounds()
}

extension GameFeedback: FallingSkyFeedbackProviding {
    func collected(soundEnabled: Bool, hapticsEnabled: Bool, reducedMotion: Bool) {
        if soundEnabled && !UIAccessibility.isVoiceOverRunning { sound.play() }
        if hapticsEnabled && !reducedMotion && !UIAccessibility.isReduceMotionEnabled {
            impact.impactOccurred(intensity: 0.55)
        }
    }
}
