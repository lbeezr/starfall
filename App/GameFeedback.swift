import AudioToolbox
import UIKit
import StarfallCore

/// Device feedback is independent of the deterministic rules and SpriteKit playback.
@MainActor protocol GameFeedbackProviding: AnyObject {
    func cleared(_ turn: Turn, outcome: Outcome, soundEnabled: Bool, calmEffects: Bool)
    func announce(_ message: String)
}

@MainActor final class GameFeedback: GameFeedbackProviding {
    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notification = UINotificationFeedbackGenerator()

    func cleared(_ turn: Turn, outcome: Outcome, soundEnabled: Bool, calmEffects: Bool) {
        if soundEnabled { AudioServicesPlaySystemSound(1104) }
        guard !calmEffects, !UIAccessibility.isReduceMotionEnabled else { return }
        if outcome == .won {
            notification.notificationOccurred(.success)
        } else {
            impact.impactOccurred(intensity: 0.45)
        }
    }

    func announce(_ message: String) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
