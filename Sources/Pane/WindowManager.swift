import AppKit
import ApplicationServices
import os

private let log = Logger(subsystem: "com.rokoov.pane", category: "window")

struct TargetWindow {
    let element: AXUIElement
    let pid: pid_t
    let frame: CGRect
}

enum WindowManager {
    private static let systemWide: AXUIElement = {
        let el = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(el, 0.15)
        return el
    }()

    // Topmost window under the cursor, straight from the window server, so plain scrolling never waits on an app
    static func windowUnder(_ point: CGPoint) -> (pid: pid_t, bounds: CGRect)? {
        let number = NSWindow.windowNumber(at: Screens.flip(point), belowWindowWithWindowNumber: 0)
        guard number > 0,
              let info = (CGWindowListCopyWindowInfo(.optionIncludingWindow, CGWindowID(number)) as? [[String: Any]])?.first,
              info[kCGWindowLayer as String] as? Int == 0,
              let pid = info[kCGWindowOwnerPID as String] as? pid_t,
              let dict = info[kCGWindowBounds as String] as? NSDictionary,
              let bounds = CGRect(dictionaryRepresentation: dict as CFDictionary) else { return nil }
        return (pid, bounds)
    }

    // The active app's main window, which is the one a swipe moves
    static func activeWindow() -> TargetWindow? {
        guard let app = element(systemWide, kAXFocusedApplicationAttribute),
              let win = element(app, kAXMainWindowAttribute) ?? element(app, kAXFocusedWindowAttribute) else { return nil }

        var pid: pid_t = 0
        AXUIElementGetPid(win, &pid)
        let subrole = string(win, kAXSubroleAttribute)
        guard pid != getpid(),
              subrole == kAXStandardWindowSubrole,
              bool(win, "AXFullScreen") != true,
              let frame = frame(of: win) else {
            log.debug("skipped window of pid \(pid), subrole \(subrole ?? "none", privacy: .public)")
            return nil
        }
        return TargetWindow(element: win, pid: pid, frame: frame)
    }

    // Slow apps take a while to move, which must not stall the event tap or the overlay animation
    private static let queue = DispatchQueue(label: "com.rokoov.pane.windows", qos: .userInteractive)

    static func setFrame(_ win: AXUIElement, _ r: CGRect) {
        queue.async {
            var origin = r.origin, size = r.size
            guard let p = AXValueCreate(.cgPoint, &origin), let s = AXValueCreate(.cgSize, &size) else { return }
            withoutEnhancedUI(win) {
                // Size, move, size again: macOS clamps a resize that runs past the Dock or screen edge, never a move
                let apply: () -> Void = {
                    AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, s)
                    AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, p)
                    AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, s)
                }
                apply()
                // Right after changing screens the app still clamps to the old one, so give it a moment
                for _ in 0..<3 {
                    guard let now = frame(of: win), !now.isClose(to: r) else { break }
                    usleep(50_000)
                    apply()
                }
            }
        }
    }

    static func minimize(_ win: AXUIElement) {
        queue.async { AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanTrue) }
    }

    private static func frame(of win: AXUIElement) -> CGRect? {
        guard let p = value(win, kAXPositionAttribute), let s = value(win, kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero, size = CGSize.zero
        guard AXValueGetValue(p, .cgPoint, &origin), AXValueGetValue(s, .cgSize, &size) else { return nil }
        return CGRect(origin: origin, size: size)
    }

    // Chrome/Electron animate AX moves slowly while AXEnhancedUserInterface is on
    private static func withoutEnhancedUI(_ win: AXUIElement, _ body: () -> Void) {
        var pid: pid_t = 0
        AXUIElementGetPid(win, &pid)
        let app = AXUIElementCreateApplication(pid)
        let enhanced = bool(app, "AXEnhancedUserInterface") == true
        if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse) }
        body()
        if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue) }
    }

    private static func raw(_ el: AXUIElement, _ name: String) -> CFTypeRef? {
        var v: CFTypeRef?
        return AXUIElementCopyAttributeValue(el, name as CFString, &v) == .success ? v : nil
    }

    private static func element(_ el: AXUIElement, _ name: String) -> AXUIElement? {
        guard let v = raw(el, name), CFGetTypeID(v) == AXUIElementGetTypeID() else { return nil }
        return (v as! AXUIElement)
    }

    private static func value(_ el: AXUIElement, _ name: String) -> AXValue? {
        guard let v = raw(el, name), CFGetTypeID(v) == AXValueGetTypeID() else { return nil }
        return (v as! AXValue)
    }

    private static func string(_ el: AXUIElement, _ name: String) -> String? {
        raw(el, name) as? String
    }

    private static func bool(_ el: AXUIElement, _ name: String) -> Bool? {
        (raw(el, name) as? NSNumber)?.boolValue
    }
}
