import SwiftUI
import UIKit
import StarfallCore

// UIKit owns physical contact/release/cancel. Native star buttons remain the
// accessibility controls behind the surface; all outcomes still go through Core.
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
    var swapStart: ((CGPoint) -> Bool)? = nil
    var swap: ((Cell, Cell, UInt64) -> Void)? = nil

    func makeUIView(context: Context) -> Surface {
        let view = Surface(); view.installCapture(); view.isMultipleTouchEnabled = true
        view.isAccessibilityElement = false; view.accessibilityElementsHidden = true
        return view
    }
    func updateUIView(_ view: Surface, context: Context) { view.updateInput(self) }

    final class Surface: UIView {
        private(set) var input: ConstellationTraceSurface?
        private let capture = CaptureRecognizer()
        private weak var scrollOwner: UIScrollView?
        private var primary: UITouch?
        private(set) var session = ConstellationTouchSession()
        private var blocked = false
        private var holdTask: Task<Void, Never>?

        func updateInput(_ value: ConstellationTraceSurface) {
            if let old = input, old.generation != value.generation || old.size != value.size || !value.enabled {
                cancelInput()
            }
            input = value
        }
        func installCapture() {
            capture.cancelsTouchesInView = false
            capture.shouldStart = { [weak self] point in
                guard let input = self?.input, input.enabled else { return false }
                return ObservatoryGeometry(size: input.size).cell(at: point) != nil
            }
            capture.yieldsToScrollAtStart = { [weak self] point in
                guard let input = self?.input else { return true }
                return input.traceStart(point) == nil && input.swapStart?(point) != true
            }
            capture.beganContact = { [weak self] touches, event in self?.beginContact(touches, event: event) }
            capture.movedContact = { [weak self] touches, event in self?.moveContact(touches, event: event) }
            capture.endedContact = { [weak self] touches, event in self?.endContact(touches, event: event) }
            capture.cancelledContact = { [weak self] in
                guard let self, self.primary != nil else { return }
                self.cancelInput(reason: self.capture.yieldedToScroll ? nil : SkyCopy.text(.inputInterrupted))
            }
            addGestureRecognizer(capture)
        }
        override func didMoveToWindow() {
            super.didMoveToWindow()
            var ancestor = superview
            while let view = ancestor {
                if let scroll = view as? UIScrollView {
                    if scrollOwner !== scroll { scroll.panGestureRecognizer.require(toFail: capture); scrollOwner = scroll }
                    break
                }
                ancestor = view.superview
            }
        }
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            guard let input, input.enabled else { return false }
            return ObservatoryGeometry(size: input.size).cell(at: point) != nil
        }
        func cancelInput(reason: String? = nil) {
            holdTask?.cancel(); holdTask = nil
            // Retire the local ticket before cancellation can reenter via UIKit/SwiftUI.
            primary = nil; session.cancel(); blocked = true
            capture.cancelCapture(); input?.cancel()
            if let reason { input?.feedback?(reason) }
        }
        override func willMove(toWindow newWindow: UIWindow?) { if newWindow == nil { cancelInput() } }

        private func beginContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard primary == nil, touches.count == 1, (event?.allTouches?.count ?? 1) == 1,
                  let touch = touches.first else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            primary = touch
            beginInput(at: touch.location(in: self))
        }
        private func moveContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary) else { return }
            guard (event?.allTouches?.count ?? 1) == 1 else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            for touch in (event?.coalescedTouches(for: primary) ?? [primary]).suffix(64) {
                guard !blocked else { break }
                moveInput(to: touch.location(in: self))
            }
        }
        private func endContact(_ touches: Set<UITouch>, event: UIEvent?) {
            guard !blocked, let primary, touches.contains(primary) else { cancelInput(); return }
            guard (event?.allTouches?.count ?? 1) == 1 else { cancelInput(reason: SkyCopy.text(.inputOneFinger)); return }
            endInput(at: primary.location(in: self))
        }

        // These sample methods are the production adapter, also exercised without
        // constructing synthetic UITouch objects in hosted regression checks.
        func beginInput(at origin: CGPoint) {
            guard let input, input.enabled else { cancelInput(); return }
            blocked = false
            guard session.begin(at: origin, traceEligible: input.traceStart(origin) != nil,
                                swapEligible: input.swapStart?(origin) == true),
                  input.contact?(origin) != false else { cancelInput(); return }
            guard session.canHold else { return }
            let ticket = session.sequence, generation = input.generation
            holdTask = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .milliseconds(ConstellationTouchSession.holdMilliseconds)) }
                catch { return }
                guard !Task.isCancelled else { return }
                self?.armDrawing(ticket: ticket, generation: generation)
            }
        }
        func armDrawing(ticket: UInt64, generation: UInt64) {
            guard !blocked, let input, input.enabled, input.generation == generation,
                  let origin = session.origin, session.armTrace(ticket: ticket) else { return }
            input.begin(origin)
        }
        func moveInput(to point: CGPoint) {
            guard !blocked, let input else { return }
            let wasDrawing = session.isDrawing
            let event = session.move(to: point, mapping: ObservatoryGeometry(size: input.size))
            if !session.canHold { holdTask?.cancel(); holdTask = nil }
            switch event {
            case .swap(let from, let to):
                // Session is consumed before committing: redraw, finger-up and old
                // hold timers cannot turn this contact into another board action.
                input.swap?(from, to, input.generation)
                input.cancel()
            case .trace: input.move(point)
            case .cancel: cancelInput(reason: SkyCopy.text(wasDrawing ? .inputTraceOffBoard : .inputSameStar))
            case .none: break
            }
        }
        func endInput(at point: CGPoint) {
            // A final-only sample follows exactly the same directional decision.
            moveInput(to: point)
            guard !blocked, let input else { return }
            holdTask?.cancel(); holdTask = nil; primary = nil
            let outcome = session.finish(at: point, mapping: ObservatoryGeometry(size: input.size))
            switch outcome {
            case .trace: input.end()
            case .tap(let cell): input.cancel(); input.tap(cell)
            case .cancel, .none: input.cancel()
            }
        }
    }
    // Occupied interactive stars own all directions. Empty board starts may scroll.
    final class CaptureRecognizer: UIGestureRecognizer {
        var beganContact: ((Set<UITouch>, UIEvent) -> Void)?
        var movedContact: ((Set<UITouch>, UIEvent) -> Void)?
        var endedContact: ((Set<UITouch>, UIEvent) -> Void)?
        var cancelledContact: (() -> Void)?
        var shouldStart: ((CGPoint)->Bool)?
        var yieldsToScrollAtStart: ((CGPoint)->Bool)?
        private(set) var yieldedToScroll = false
        private var origin=CGPoint.zero
        private var yieldsToScroll = true
        override func touchesBegan(_ touches:Set<UITouch>,with event:UIEvent) {
            yieldedToScroll = false
            guard touches.count==1, event.allTouches?.count==1, let touch=touches.first else {
                cancelledContact?(); cancelCapture(); return
            }
            origin=touch.location(in:view)
            guard shouldStart?(origin) == true else { state = .failed; return }
            yieldsToScroll = yieldsToScrollAtStart?(origin) == true
            beganContact?(touches, event)
        }
        override func touchesMoved(_ touches:Set<UITouch>,with event:UIEvent) {
            guard state == .possible || state == .began || state == .changed,
                  let touch=touches.first else { return }
            let point=touch.location(in:view)
            if state == .possible {
                let horizontalOnly = yieldsToScroll
                let distance = hypot(point.x-origin.x,point.y-origin.y)
                let recognitionDistance = horizontalOnly ? ConstellationTouchSession.tapSlop : ConstellationTouchSession.holdSlop
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

/// A touch chooses its action once, independent of star color. Durations only
/// select drawing while stationary; movement commits one directional exchange.
struct ConstellationTouchSession {
    enum Event: Equatable { case none, trace, swap(Cell, Cell), cancel }
    enum Outcome: Equatable { case none, tap(Cell), trace, cancel }
    private enum Mode { case idle, pending, drawing, consumed }
    static let holdMilliseconds = SkyGestureTiming.drawingHoldMilliseconds
    static let holdSlop: CGFloat = 8
    static let tapSlop: CGFloat = 18
    private var mode = Mode.idle
    private var traceEligible = false
    private var swapEligible = false
    private var maximumDistance: CGFloat = 0
    private(set) var sequence: UInt64 = 0
    private(set) var origin: CGPoint?
    var isDrawing: Bool { mode == .drawing }
    var canHold: Bool { mode == .pending && (traceEligible || swapEligible) && maximumDistance <= Self.holdSlop }

    static func swapThreshold(_ cell: Cell, mapping: ObservatoryGeometry) -> CGFloat {
        let frame = mapping.frame(cell)
        return min(18, max(12, min(frame.width, frame.height) * 0.25))
    }
    mutating func begin(at point: CGPoint, traceEligible: Bool = true, swapEligible: Bool = false) -> Bool {
        guard origin == nil else { cancel(); return false }
        sequence &+= 1; origin = point; mode = .pending; maximumDistance = 0
        self.traceEligible = traceEligible; self.swapEligible = swapEligible
        return true
    }
    mutating func armTrace(ticket: UInt64) -> Bool {
        guard ticket == sequence, canHold else { return false }
        mode = .drawing
        return true
    }
    mutating func move(to point: CGPoint, mapping: ObservatoryGeometry) -> Event {
        guard let origin, mode == .pending || mode == .drawing else { return .none }
        guard let from = mapping.cell(at: origin), point.x.isFinite, point.y.isFinite else {
            mode = .consumed; return .cancel
        }
        let dx = point.x-origin.x, dy = point.y-origin.y
        maximumDistance = max(maximumDistance, hypot(dx, dy))
        if mode == .drawing {
            guard mapping.cell(at: point) != nil else { mode = .consumed; return .cancel }
            return .trace
        }
        if swapEligible, max(abs(dx), abs(dy)) >= Self.swapThreshold(from, mapping: mapping) {
            // A fast/coarse sample may already be outside the board. Direction
            // names one adjacent destination; that destination owns validity.
            // UIKit y increases down the screen; Core row zero is the bottom.
            let to = abs(dx) >= abs(dy)
                ? Cell(from.row, from.column + (dx > 0 ? 1 : -1))
                : Cell(from.row + (dy < 0 ? 1 : -1), from.column)
            mode = .consumed
            guard (0..<FallingSky.side).contains(to.row), (0..<FallingSky.side).contains(to.column) else { return .cancel }
            return .swap(from, to)
        }
        guard mapping.cell(at: point) != nil else { mode = .consumed; return .cancel }
        if !swapEligible && maximumDistance > Self.tapSlop && !canHold { mode = .consumed; return .cancel }
        return .none
    }
    mutating func finish(at point: CGPoint, mapping: ObservatoryGeometry) -> Outcome {
        defer { cancel() }
        guard let origin else { return .cancel }
        switch mode {
        case .drawing: return mapping.cell(at: point) == nil ? .cancel : .trace
        case .pending:
            guard maximumDistance <= Self.tapSlop, let cell = mapping.cell(at: origin),
                  mapping.cell(at: point) == cell else { return .cancel }
            return .tap(cell)
        case .consumed: return .none
        case .idle: return .cancel
        }
    }
    mutating func cancel() {
        sequence &+= 1; origin = nil; mode = .idle; maximumDistance = 0
        traceEligible = false; swapEligible = false
    }
}
