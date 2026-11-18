import AppKit

final class GestureMonitor {
    private var tap: CFMachPort?
    private let overlay = SnapOverlay()

    private var window: TargetWindow?
    private var screen: NSScreen?
    private var dx: CGFloat = 0
    private var dy: CGFloat = 0
    private var layout: Layout?
    private var resolved: (layout: Layout, frame: CGRect)?
    private var swallowMomentum = false

    var isRunning: Bool { tap != nil }

    @discardableResult
    func start() -> Bool {
        guard tap == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            return Unmanaged<GestureMonitor>.fromOpaque(refcon).takeUnretainedValue().handle(type, event)
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                          eventsOfInterest: mask, callback: callback,
                                          userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return false }
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        return true
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        guard Settings.enabled, let ns = NSEvent(cgEvent: event) else { return Unmanaged.passUnretained(event) }

        if !ns.momentumPhase.isEmpty {
            return swallowMomentum ? nil : Unmanaged.passUnretained(event)
        }
        switch ns.phase {
        case .began:
            return begin(ns, event)
        case .changed where window != nil:
            update(ns)
            return nil
        case .ended where window != nil, .cancelled where window != nil:
            finish(commit: ns.phase == .ended)
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }

    private func begin(_ ns: NSEvent, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        swallowMomentum = false
        let point = event.location
        guard let win = WindowManager.window(at: point) else { return Unmanaged.passUnretained(event) }

        let anywhere = Settings.anywhereWithOption && ns.modifierFlags.contains(.option)
        guard anywhere || point.y - win.frame.minY <= Settings.titleBarHeight else { return Unmanaged.passUnretained(event) }

        window = win
        screen = Screens.screen(containing: Screens.flip(point))
        dx = 0
        dy = 0
        layout = nil
        resolved = nil
        update(ns)
        return nil
    }

    private func update(_ ns: NSEvent) {
        // Normalize to finger movement regardless of natural scrolling
        let inverted = ns.isDirectionInvertedFromDevice
        dx += inverted ? ns.scrollingDeltaX : -ns.scrollingDeltaX
        dy += inverted ? -ns.scrollingDeltaY : ns.scrollingDeltaY

        let next = Layout.from(dx: dx, dy: dy, threshold: Settings.threshold)
        guard next != layout else { return }
        layout = next

        if let next, let target = resolve(next) {
            resolved = target
            overlay.show(target.frame, from: window.map { Screens.flip($0.frame) })
        } else {
            resolved = nil
            overlay.hide()
        }
    }

    private func resolve(_ l: Layout) -> (layout: Layout, frame: CGRect)? {
        guard let screen, let window else { return nil }
        let current = Screens.flip(window.frame)

        // Swiping toward an edge the window already fills sends it to the next monitor
        if l == .leftHalf || l == .rightHalf,
           current.isClose(to: l.frame(in: screen.visibleFrame)),
           let next = Screens.neighbor(of: screen, left: l == .leftHalf) {
            let flipped: Layout = l == .leftHalf ? .rightHalf : .leftHalf
            return (flipped, flipped.frame(in: next.visibleFrame))
        }
        return (l, l.frame(in: screen.visibleFrame))
    }

    private func finish(commit: Bool) {
        if commit, let window, let resolved {
            if resolved.layout == .minimize {
                WindowManager.minimize(window.element)
            } else {
                WindowManager.setFrame(window.element, Screens.flip(resolved.frame))
            }
        }
        overlay.hide()
        window = nil
        layout = nil
        resolved = nil
        swallowMomentum = true
    }
}
