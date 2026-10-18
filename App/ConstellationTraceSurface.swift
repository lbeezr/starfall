import SwiftUI
import UIKit
import StarfallCore


// UIKit gives the board an explicit release/cancel/multitouch contract. The native
// SwiftUI star buttons remain the accessibility controls behind this touch surface.
struct ConstellationTraceSurface: UIViewRepresentable {
    let size: CGSize
    let enabled: Bool
    let generation: UInt64
    let traceStart: (CGPoint) -> Cell?
    let tap: (Cell) -> Void
    let begin: (CGPoint) -> Void
    let move: (CGPoint) -> Void
    let end: () -> Void
    let cancel: () -> Void

    func makeUIView(context: Context) -> Surface {
        let view = Surface(); view.installCapture(); view.isMultipleTouchEnabled = true
        view.isAccessibilityElement = false; view.accessibilityElementsHidden = true
        return view
    }
    func updateUIView(_ view: Surface, context: Context) {
        view.updateInput(self)
    }
    final class Surface: UIView {
        private(set) var input: ConstellationTraceSurface?
        func updateInput(_ value: ConstellationTraceSurface) {
            if let old = input, old.generation != value.generation || old.size != value.size || !value.enabled {
                cancelInput()
            }
            input = value
        }
        private let capture = CaptureRecognizer()
        private weak var scrollOwner: UIScrollView?
        func installCapture() {
            capture.cancelsTouchesInView = false
            capture.shouldStart = { [weak self] point in
                guard let self, let input=self.input, input.enabled else { return false }
                return input.traceStart(point) != nil
            }
            addGestureRecognizer(capture)
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            var ancestor=superview
            while let view=ancestor {
                if let scroll=view as? UIScrollView {
                    if scrollOwner !== scroll { scroll.panGestureRecognizer.require(toFail:capture);scrollOwner=scroll }
                    break
                }
                ancestor=view.superview
            }
        }
        private var primary: UITouch?
        private var session = ConstellationTouchSession()
        private var blocked = false
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            guard let input, input.enabled else { return false }
            return ObservatoryGeometry(size: input.size).cell(at: point) != nil
        }
        func cancelInput() { capture.cancelCapture(); input?.cancel(); primary = nil; session.cancel(); blocked = true }
        override func willMove(toWindow newWindow: UIWindow?) { if newWindow == nil { cancelInput() } }
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard primary == nil, touches.count == 1, (event?.allTouches?.count ?? 1) == 1 else { cancelInput(); return }
            blocked = false; primary = touches.first
            let origin = primary!.location(in: self)
            guard session.begin(at: origin) else { cancelInput(); return }
            // Own the hold on touch-down, before drag recognition; release still taps normally.
            if input?.traceStart(origin) != nil { input?.begin(origin) }
        }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary), let input else { return }
            let location = primary.location(in: self)
            if session.move(to: location) {
                for touch in (event?.coalescedTouches(for: primary) ?? [primary]).suffix(64) { input.move(touch.location(in: self)) }
            }
        }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary), let input else { cancelInput(); return }
            let location = primary.location(in: self)
            let outcome = session.finish(at: location, mapping: ObservatoryGeometry(size: input.size))
            self.primary = nil
            switch outcome {
            case .trace: input.move(location); input.end()
            case .tap(let cell): input.cancel(); input.tap(cell)
            case .cancel: input.cancel()
            }
        }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { cancelInput() }
    }
    // A trace starting on an eligible star wins over the accessibility-size
    // scroll container. Other starts fail immediately, preserving normal scroll.
    final class CaptureRecognizer: UIGestureRecognizer {
        var shouldStart: ((CGPoint)->Bool)?
        private var origin=CGPoint.zero
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent) {
            guard touches.count==1, event.allTouches?.count==1, let touch=touches.first else { cancelCapture();return }
            origin=touch.location(in:view)
            if shouldStart?(origin) != true { state = .failed }
        }
        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent) {
            guard state == .possible || state == .began || state == .changed,
                  let touch=touches.first else { return }
            let point=touch.location(in:view)
            if state == .possible {
                if hypot(point.x-origin.x,point.y-origin.y)>=ConstellationTouchSession.dragThreshold {state = .began}
            } else {state = .changed}
        }
        override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent) {
            state = state == .began || state == .changed ? .ended : .failed
        }
        override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent) {cancelCapture()}
        func cancelCapture() {
            if state == .began || state == .changed {state = .cancelled}
            else if state == .possible {state = .failed}
        }
    }

}

/// One physical touch has exactly one terminal classification. Kept independent of
/// UITouch so boundary samples and interruption sequences exercise production logic.
struct ConstellationTouchSession {
    enum Outcome: Equatable { case tap(Cell), trace, cancel }
    static let dragThreshold: CGFloat = 8
    private(set) var origin: CGPoint?
    private(set) var dragging = false

    mutating func begin(at point: CGPoint) -> Bool {
        guard origin == nil else { cancel(); return false }
        origin = point; dragging = false
        return true
    }
    @discardableResult mutating func move(to point: CGPoint) -> Bool {
        guard let origin else { return false }
        dragging = dragging || hypot(point.x-origin.x, point.y-origin.y) >= Self.dragThreshold
        return dragging
    }
    mutating func finish(at point: CGPoint, mapping: ObservatoryGeometry) -> Outcome {
        defer { cancel() }
        guard origin != nil else { return .cancel }
        if move(to: point) { return .trace }
        return mapping.cell(at: point).map(Outcome.tap) ?? .cancel
    }
    mutating func cancel() { origin = nil; dragging = false }
}
