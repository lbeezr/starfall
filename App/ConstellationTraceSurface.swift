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
    var contact: ((CGPoint) -> Bool)? = nil
    var feedback: ((String) -> Void)? = nil
    var hasSelectedNeighbor: (() -> Bool)? = nil
    var swapStart: ((CGPoint) -> Bool)? = nil
    var beginSwap: ((CGPoint,CGPoint,UInt64) -> Bool)? = nil
    var endSwap: ((CGPoint) -> Void)? = nil

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
                return ObservatoryGeometry(size: input.size).cell(at: point) != nil
            }
            capture.horizontalOnlyAtStart = { [weak self] point in
                guard let input=self?.input else { return true }
                return input.traceStart(point) == nil
            }
            // Recognizers receive raw contacts before UIScrollView can delay UIView
            // touch delivery. Keep admission, moves and terminal events on this owner.
            capture.beganContact = { [weak self] touches, event in self?.beginContact(touches, event: event) }
            capture.movedContact = { [weak self] touches, event in self?.moveContact(touches, event: event) }
            capture.endedContact = { [weak self] touches, event in self?.endContact(touches, event: event) }
            capture.cancelledContact = { [weak self] in
                guard let self else { return }
                guard self.primary != nil else { return }
                self.cancelInput(reason: self.capture.yieldedToScroll ? nil : SkyCopy.text(.inputInterrupted))
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
        private var swapTask: Task<Void,Never>?
        private var swapDwell = SkySwapDwell()
        private var swapArmed = false
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            guard let input, input.enabled else { return false }
            return ObservatoryGeometry(size: input.size).cell(at: point) != nil
        }
        func cancelInput(reason: String? = nil) {
            swapTask?.cancel(); swapTask = nil; swapDwell = SkySwapDwell(); swapArmed = false
            capture.cancelCapture(); input?.cancel(); primary = nil; session.cancel(); blocked = true
            if let reason { input?.feedback?(reason) }
        }
        override func willMove(toWindow newWindow: UIWindow?) { if newWindow == nil { cancelInput() } }
        private func beginContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard primary == nil, touches.count == 1, (event?.allTouches?.count ?? 1) == 1 else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            blocked = false; swapDwell = SkySwapDwell(); swapArmed = false; primary = touches.first
            let origin = primary!.location(in: self)
            let eligible = input?.traceStart(origin) != nil
            guard session.begin(at: origin, traceEligible: eligible || input?.swapStart?(origin) == true) else { cancelInput(); return }
            guard input?.contact?(origin) != false else { primary = nil; session.cancel(); blocked = true; return }
            // Own the hold on touch-down, before drag recognition; release still taps normally.
            if eligible { input?.begin(origin) }
        }
        private func moveContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary), let input else { return }
            guard (event?.allTouches?.count ?? 1) == 1 else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            let location = primary.location(in: self)
            if session.move(to: location) {
                for touch in (event?.coalescedTouches(for: primary) ?? [primary]).suffix(64) {
                    guard !blocked else { break }
                    let point = touch.location(in: self)
                    input.move(point)
                    if input.hasSelectedNeighbor?() == true { session.claimDrag() }
                    updateSwapHold(point, input:input)
                }
            } else if session.canceled { cancelInput(reason: SkyCopy.text(.inputSameStar)) }
        }
        private func updateSwapHold(_ point: CGPoint, input: ConstellationTraceSurface) {
            guard let origin=session.origin, input.swapStart?(origin) == true else { return }
            let previous=swapDwell.target
            swapDwell.visit(origin:origin,point:point,mapping:ObservatoryGeometry(size:input.size))
            if swapArmed {
                if !swapDwell.eligible { cancelInput(reason:SkyCopy.text(.inputSwapCanceled)) }
                return
            }
            guard previous != swapDwell.target else { return }
            swapTask?.cancel(); swapTask=nil
            guard let target=swapDwell.target else { return }
            let contact = session.sequence
            swapTask=Task { @MainActor [weak self] in
                do { try await Task.sleep(for:.milliseconds(150)) } catch { return }
                guard !Task.isCancelled, let self, self.session.sequence == contact,
                      !self.blocked, self.primary != nil, self.swapDwell.target == target,
                      let current=self.input, current.enabled, current.generation == input.generation else { return }
                self.swapArmed = current.beginSwap?(origin,point,current.generation) == true
                if self.swapArmed { self.swapDwell.arm() }
            }
        }
        private func endContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary), let input else { cancelInput(); return }
            guard (event?.allTouches?.count ?? 1) == 1 else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            swapTask?.cancel(); swapTask=nil
            let location = primary.location(in: self)
            let outcome = session.finish(at: location, mapping: ObservatoryGeometry(size: input.size))
            self.primary = nil
            if swapArmed { input.endSwap?(location); swapArmed=false; return }
            switch outcome {
            case .trace: input.move(location); input.end()
            case .tap(let cell): input.cancel(); input.tap(cell)
            case .cancel: input.cancel(); input.feedback?(SkyCopy.text(.inputSameStar))
            }
        }
    }
    // A trace starting on an eligible star wins over the accessibility-size
    // scroll container. Other board starts yield on vertical movement to scroll.
    final class CaptureRecognizer: UIGestureRecognizer {
        var beganContact: ((Set<UITouch>, UIEvent) -> Void)?
        var movedContact: ((Set<UITouch>, UIEvent) -> Void)?
        var endedContact: ((Set<UITouch>, UIEvent) -> Void)?
        var cancelledContact: (() -> Void)?
        var shouldStart: ((CGPoint)->Bool)?
        var horizontalOnlyAtStart: ((CGPoint)->Bool)?
        private(set) var yieldedToScroll = false
        private var origin=CGPoint.zero
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent) {
            yieldedToScroll = false
            guard touches.count==1, event.allTouches?.count==1, let touch=touches.first else {
                cancelledContact?(); cancelCapture(); return
            }
            origin=touch.location(in:view)
            guard shouldStart?(origin) == true else { state = .failed; return }
            beganContact?(touches, event)
        }
        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent) {
            guard state == .possible || state == .began || state == .changed,
                  let touch=touches.first else { return }
            let point=touch.location(in:view)
            if state == .possible {
                let horizontalOnly = horizontalOnlyAtStart?(origin) == true
                let distance = hypot(point.x-origin.x,point.y-origin.y)
                let recognitionDistance = horizontalOnly ? ConstellationTouchSession.tapSlop : ConstellationTouchSession.dragThreshold
                if distance > recognitionDistance || (!horizontalOnly && distance == recognitionDistance) {
                    if horizontalOnly && abs(point.y-origin.y) > abs(point.x-origin.x) {
                        yieldedToScroll = true
                        cancelledContact?()
                        state = .failed
                        return
                    }
                    else { state = .began }
                }
            } else {state = .changed}
            movedContact?(touches, event)
        }
        override func touchesEnded(_ touches:Set<UITouch>,with event:UIEvent) {
            guard state == .possible || state == .began || state == .changed else { return }
            endedContact?(touches, event)
            if state == .possible || state == .began || state == .changed {
                state = state == .began || state == .changed ? .ended : .failed
            }
        }
        override func touchesCancelled(_ touches:Set<UITouch>,with event:UIEvent) { cancelledContact?(); cancelCapture() }
        override func reset() {
            // UIKit can end recognition without delivering UIView cancellation.
            cancelledContact?()
            super.reset()
        }
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
    static let dragThreshold: CGFloat = 6
    static let tapSlop: CGFloat = 18
    private var traceEligible = true
    private var maximumDistance: CGFloat = 0
    private var selectedNeighbor = false
    private(set) var canceled = false
    private(set) var sequence: UInt64 = 0
    private(set) var origin: CGPoint?
    private(set) var dragging = false

    mutating func begin(at point: CGPoint, traceEligible: Bool = true) -> Bool {
        guard origin == nil else { cancel(); return false }
        sequence &+= 1
        origin = point; dragging = false; canceled = false; self.traceEligible = traceEligible
        maximumDistance = 0; selectedNeighbor = false
        return true
    }
    @discardableResult mutating func move(to point: CGPoint) -> Bool {
        guard let origin, !canceled else { return false }
        let distance = hypot(point.x-origin.x, point.y-origin.y)
        maximumDistance = max(maximumDistance, distance)
        if traceEligible { dragging = dragging || distance >= Self.dragThreshold }
        else if distance > Self.tapSlop { canceled = true }
        return dragging
    }
    /// Sticky intent: a partial constellation must never fall back to an ordinary clear.
    mutating func claimDrag() { selectedNeighbor = true }

    mutating func finish(at point: CGPoint, mapping: ObservatoryGeometry) -> Outcome {
        defer { cancel() }
        guard let origin, !canceled else { return .cancel }
        let isDrawing = move(to: point)
        guard !canceled else { return .cancel }
        if !selectedNeighbor, maximumDistance <= Self.tapSlop,
           let cell = mapping.cell(at: origin), mapping.cell(at: point) == cell { return .tap(cell) }
        return isDrawing ? .trace : .cancel
    }
    mutating func cancel() {
        sequence &+= 1; origin = nil; dragging = false; canceled = false
        maximumDistance = 0; selectedNeighbor = false
    }
}

/// One-neighbor dwell eligibility is sticky for the entire physical contact.
/// Crossing a row or a second neighbor keeps a trace from later becoming a swap.
struct SkySwapDwell {
    private(set) var eligible = true
    private(set) var target: Cell?
    private var armed = false
    mutating func arm() { armed = eligible && target != nil }
    mutating func visit(origin: CGPoint, point: CGPoint, mapping: ObservatoryGeometry) {
        guard eligible else { return }
        guard let first=mapping.cell(at:origin), let cell=mapping.cell(at:point),
              first.row == cell.row, abs(first.column-cell.column) <= 1 else {
            eligible=false;target=nil;return
        }
        if armed && cell != target { eligible=false;target=nil;return }
        target = first == cell ? nil : cell
    }
}
