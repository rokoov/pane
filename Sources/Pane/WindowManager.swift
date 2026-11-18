import AppKit
import ApplicationServices

struct TargetWindow {
    let element: AXUIElement
    let frame: CGRect
}

enum WindowManager {
    private static let systemWide: AXUIElement = {
        let el = AXUIElementCreateSystemWide()
        AXUIElementSetMessagingTimeout(el, 0.15)
        return el
    }()

    // Topmost window under the cursor, straight from the window server, so plain scrolling never waits on the app
    static func bounds(at point: CGPoint) -> CGRect? {
        let number = NSWindow.windowNumber(at: Screens.flip(point), belowWindowWithWindowNumber: 0)
        guard number > 0,
              let info = (CGWindowListCopyWindowInfo(.optionIncludingWindow, CGWindowID(number)) as? [[String: Any]])?.first,
              info[kCGWindowLayer as String] as? Int == 0,
              let bounds = info[kCGWindowBounds as String] as? NSDictionary else { return nil }
        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    static func window(at point: CGPoint, in bounds: CGRect) -> TargetWindow? {
        // Hit-test the title bar rather than the content, so web views don't build their accessibility tree
        let probe = CGPoint(x: point.x, y: min(point.y, bounds.minY + 10))
        var hit: AXUIElement?
        guard AXUIElementCopyElementAtPosition(systemWide, Float(probe.x), Float(probe.y), &hit) == .success,
              let hit, let win = windowElement(from: hit) else { return nil }

        var pid: pid_t = 0
        AXUIElementGetPid(win, &pid)
        guard pid != getpid(),
              string(win, kAXSubroleAttribute) == kAXStandardWindowSubrole,
              bool(win, "AXFullScreen") != true,
              let frame = frame(of: win), frame.contains(point) else { return nil }
        return TargetWindow(element: win, frame: frame)
    }

    static func setFrame(_ win: AXUIElement, _ r: CGRect) {
        var origin = r.origin, size = r.size
        guard let p = AXValueCreate(.cgPoint, &origin), let s = AXValueCreate(.cgSize, &size) else { return }
        withoutEnhancedUI(win) {
            // Position, size, position again so windows clamped by the old size still land right
            AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, p)
            AXUIElementSetAttributeValue(win, kAXSizeAttribute as CFString, s)
            AXUIElementSetAttributeValue(win, kAXPositionAttribute as CFString, p)
        }
    }

    static func minimize(_ win: AXUIElement) {
        AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
    }

    private static func windowElement(from el: AXUIElement) -> AXUIElement? {
        var current: AXUIElement? = el
        for _ in 0..<25 {
            guard let c = current else { return nil }
            if string(c, kAXRoleAttribute) == kAXWindowRole { return c }
            if let w = element(c, kAXWindowAttribute) { return w }
            current = element(c, kAXParentAttribute)
        }
        return nil
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
