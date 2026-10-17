// Appended only to the isolated native-lab view by prepare-native-lab.py.
// UIKit owns touch cancellation and release semantics; SwiftUI Button cannot
// express a held intent that survives recognition but commits only on release.
private struct NativeChargeCell: UIViewRepresentable {
    let label: String
    let value: Int
    let identifier: String
    let enabled: Bool
    let canCharge: Bool
    let armed: Bool
    let prepare: () -> UInt64?
    let arm: (UInt64?) -> Void
    let commit: (UInt64?) -> Void
    let cancel: (UInt64?) -> Void
    let tap: () -> Void
    let accessibleCharge: () -> Void

    func makeUIView(context: Context) -> ChargeButton {
        let button = ChargeButton(type: .custom)
        button.addTarget(button, action: #selector(ChargeButton.tapped), for: .touchUpInside)
        button.addTarget(button, action: #selector(ChargeButton.cancelled), for: .touchUpOutside)
        let hold = IntentLongPress(target: button, action: #selector(ChargeButton.held(_:)))
        hold.prepare = { [weak button] in button?.down() }
        hold.minimumPressDuration = 0.65
        hold.allowableMovement = 12
        button.addGestureRecognizer(hold)
        return button
    }

    func updateUIView(_ button: ChargeButton, context: Context) {
        button.input = self
        button.isEnabled = enabled
        button.gestureRecognizers?.first(where: { $0 is IntentLongPress })?.isEnabled = canCharge
        button.accessibilityLabel = label
        button.accessibilityValue = "\(value) starlight connected"
        button.accessibilityIdentifier = identifier
        button.accessibilityHint = canCharge
            ? "Tap to clear. Hold then release for supernova; drag away to cancel."
            : "Tap a matching group worth at least three. Supernova needs five."
        button.accessibilityCustomActions = canCharge ? [UIAccessibilityCustomAction(name: "Supernova", target: button, selector: #selector(ChargeButton.accessibleSupernova))] : []
        button.layer.borderColor = UIColor(StarfallTheme.Colors.actionPrimary).cgColor
        button.layer.borderWidth = armed ? 3 : 0
        button.layer.cornerRadius = 12
    }

    final class ChargeButton: UIButton {
        var input: NativeChargeCell?
        private var leftCell = false
        private var ticket: UInt64?
        @objc func down() { leftCell = false; ticket = input?.prepare() }
        @objc func tapped() { input?.cancel(ticket); input?.tap() }
        @objc func cancelled() { input?.cancel(ticket) }
        @objc func accessibleSupernova() -> Bool {
            guard isEnabled, input?.canCharge == true else { return false }
            input?.accessibleCharge(); return true
        }
        override func accessibilityActivate() -> Bool {
            guard isEnabled else { return false }
            input?.tap(); return true
        }
        @objc func held(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began: input?.arm(ticket)
            case .changed:
                if !bounds.contains(recognizer.location(in: self)) {
                    leftCell = true; input?.cancel(ticket)
                }
            case .ended:
                if !leftCell && bounds.contains(recognizer.location(in: self)) { input?.commit(ticket) }
                else { input?.cancel(ticket) }
            case .cancelled, .failed: input?.cancel(ticket)
            default: break
            }
        }
    }

    final class IntentLongPress: UILongPressGestureRecognizer {
        var prepare: (() -> Void)?
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
            prepare?()
            super.touchesBegan(touches, with: event)
        }
    }
}
