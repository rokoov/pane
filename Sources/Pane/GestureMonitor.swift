import AppKit
import os

// Turns two-finger swipes on the active window's title bar into snaps and leaves every other scroll alone
final class GestureMonitor {
    private struct Snap {
        let layout: Layout
        let frame: CGRect
    }

    private let overlay = SnapOverlay()
    private var tap: CFMachPort?

    private var target: TargetWindow?
    private var screen: NSScreen?
    private var travel = CGVector.zero
    private var layout: Layout?
    private var snap: Snap?
    private var swallowsMomentum = false

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let callback: CGEventTapCallBack = { _, type, event, monitor in
            guard let monitor else { return Unmanaged.passUnretained(event) }
            return Unmanaged<GestureMonitor>.fromOpaque(monitor).takeUnretainedValue().handle(type, event)
        }
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.scrollWheel.rawValue),
            callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        guard let tap else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        return true
    }

    private func handle(_ type: CGEventType, _ cgEvent: CGEvent) -> Unmanaged<CGEvent>? {
        let pass = Unmanaged.passUnretained(cgEvent)
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return pass
        }
        guard Settings.isEnabled, let event = NSEvent(cgEvent: cgEvent) else { return pass }

        if !event.momentumPhase.isEmpty {
            return swallowsMomentum ? nil : pass
        }
        switch event.phase {
        case .began:
            return begin(event, at: cgEvent.location) ? nil : pass
        case .changed where target != nil:
            update(event)
            return nil
        case .ended where target != nil, .cancelled where target != nil:
            finish(commit: event.phase == .ended)
            return nil
        default:
            return pass
        }
    }

    // Starts tracking when the swipe is meant for the active window; false lets the scroll through
    private func begin(_ event: NSEvent, at point: CGPoint) -> Bool {
        // A lost ended event must not leave a stale swipe swallowing normal scrolling
        reset()
        let anywhere = Settings.allowsSwipeAnywhere && event.modifierFlags.contains(.option)
        guard let window = activeWindow(at: point, anywhere: anywhere) else { return false }

        let frame = Screens.flip(window.frame)
        target = window
        screen = Screens.screen(containing: CGPoint(x: frame.midX, y: frame.midY))
        travel = .zero
        update(event)
        return true
    }

    // The active window, when the swipe is on its own title bar or anywhere while holding ⌥
    private func activeWindow(at point: CGPoint, anywhere: Bool) -> TargetWindow? {
        if anywhere { return WindowManager.activeWindow() }
        // Plain scrolls are ruled out through the window server alone, before any app is asked
        guard let under = WindowManager.windowUnder(point),
            point.y - under.bounds.minY <= Config.Gesture.titleBarHeight,
            let window = WindowManager.activeWindow()
        else { return nil }
        guard window.pid == under.pid, window.frame.isClose(to: under.bounds) else {
            Logger.gesture.debug("title bar of an inactive window")
            return nil
        }
        return window
    }

    private func update(_ event: NSEvent) {
        // Finger travel, the same with natural scrolling on or off
        let inverted = event.isDirectionInvertedFromDevice
        travel.dx += inverted ? event.scrollingDeltaX : -event.scrollingDeltaX
        travel.dy += inverted ? -event.scrollingDeltaY : event.scrollingDeltaY

        let next = Layout(travel: travel)
        guard next != layout else { return }
        layout = next

        if let next, let target, let resolved = resolve(next, for: target) {
            snap = resolved
            overlay.show(resolved.frame, growingFrom: Screens.flip(target.frame))
        } else {
            snap = nil
            overlay.hide()
        }
    }

    // Swiping toward an edge the window already fills sends it to the next screen over
    private func resolve(_ layout: Layout, for window: TargetWindow) -> Snap? {
        guard let screen else { return nil }
        let current = Screens.flip(window.frame)
        if layout == .leftHalf || layout == .rightHalf,
            current.isClose(to: layout.frame(in: screen.visibleFrame)),
            let next = Screens.neighbor(of: screen, toTheLeft: layout == .leftHalf)
        {
            let opposite: Layout = layout == .leftHalf ? .rightHalf : .leftHalf
            return Snap(layout: opposite, frame: opposite.frame(in: next.visibleFrame))
        }
        return Snap(layout: layout, frame: layout.frame(in: screen.visibleFrame))
    }

    private func finish(commit: Bool) {
        let result = snap.map { "\($0.layout)" } ?? "none"
        Logger.gesture.debug(
            "swipe dx \(Double(self.travel.dx)) dy \(Double(self.travel.dy)) to \(result, privacy: .public) commit \(commit)"
        )
        if commit, let target, let snap {
            if snap.layout == .minimize {
                WindowManager.minimize(target.element)
            } else {
                WindowManager.setFrame(target.element, to: Screens.flip(snap.frame))
            }
        }
        reset()
        swallowsMomentum = true
    }

    private func reset() {
        overlay.hide()
        target = nil
        layout = nil
        snap = nil
        swallowsMomentum = false
    }
}
