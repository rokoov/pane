import AppKit
import os

// A window a swipe acts on, with its frame in accessibility coordinates
struct TargetWindow {
    let element: AXUIElement
    let pid: pid_t
    let frame: CGRect
}

enum WindowManager {
    private enum Attribute {
        static let enhancedUserInterface = "AXEnhancedUserInterface"
        static let fullScreen = "AXFullScreen"
    }

    // Every accessibility call is capped, so a hung app can't stall scrolling for long
    static func capMessagingTimeout() {
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), Config.Windows.messagingTimeout)
    }

    // Slow apps take a while to move, which must not stall the event tap or the preview animation
    private static let queue = DispatchQueue(label: "com.rokoov.pane.windows", qos: .userInteractive)

    // Topmost window under the cursor, straight from the window server, so plain scrolling never waits on an app
    static func windowUnder(_ point: CGPoint) -> (pid: pid_t, bounds: CGRect)? {
        let windowNumber = NSWindow.windowNumber(at: Screens.flip(point), belowWindowWithWindowNumber: 0)
        guard windowNumber > 0,
            let list = CGWindowListCopyWindowInfo(.optionIncludingWindow, CGWindowID(windowNumber)) as? [[String: Any]],
            let info = list.first,
            info[kCGWindowLayer as String] as? Int == 0,
            let pid = info[kCGWindowOwnerPID as String] as? pid_t,
            let bounds = info[kCGWindowBounds as String] as? NSDictionary,
            let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary)
        else { return nil }
        return (pid, frame)
    }

    // The frontmost app's main window, which is the one a swipe moves. The frontmost app comes from NSWorkspace:
    // accessibility's system-wide focus query returns nothing while some apps are in front
    static func activeWindow() -> TargetWindow? {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return nil }
        let app = AXUIElementCreateApplication(frontmost.processIdentifier)
        guard let window = app.element(kAXMainWindowAttribute) ?? app.element(kAXFocusedWindowAttribute) else {
            Logger.window.debug("no main window in \(frontmost.bundleIdentifier ?? "?", privacy: .public)")
            return nil
        }

        let pid = window.pid
        let subrole = window.string(kAXSubroleAttribute)
        guard pid != getpid(),
            subrole == kAXStandardWindowSubrole,
            window.bool(Attribute.fullScreen) != true,
            let frame = window.frame
        else {
            Logger.window.debug("skipped window of pid \(pid), subrole \(subrole ?? "none", privacy: .public)")
            return nil
        }
        return TargetWindow(element: window, pid: pid, frame: frame)
    }

    static func setFrame(_ window: AXUIElement, to target: CGRect) {
        queue.async {
            var origin = target.origin
            var size = target.size
            guard let position = AXValueCreate(.cgPoint, &origin), let dimensions = AXValueCreate(.cgSize, &size) else {
                return
            }
            withoutEnhancedUserInterface(window) {
                // Size, move, size again: macOS clamps a resize that runs past the Dock or screen edge, never a move
                let apply = {
                    window.set(kAXSizeAttribute, to: dimensions)
                    window.set(kAXPositionAttribute, to: position)
                    window.set(kAXSizeAttribute, to: dimensions)
                }
                apply()
                // Right after changing screens the app still clamps to the old one, so give it a moment
                for _ in 0..<Config.Windows.moveRetries {
                    guard let frame = window.frame, !frame.isClose(to: target) else { break }
                    Thread.sleep(forTimeInterval: Config.Windows.moveRetryDelay)
                    apply()
                }
            }
        }
    }

    static func minimize(_ window: AXUIElement) {
        queue.async { window.set(kAXMinimizedAttribute, to: kCFBooleanTrue) }
    }

    // Chrome and Electron animate accessibility moves slowly while AXEnhancedUserInterface is on
    private static func withoutEnhancedUserInterface(_ window: AXUIElement, _ body: () -> Void) {
        let app = AXUIElementCreateApplication(window.pid)
        guard app.bool(Attribute.enhancedUserInterface) == true else { return body() }
        app.set(Attribute.enhancedUserInterface, to: kCFBooleanFalse)
        defer { app.set(Attribute.enhancedUserInterface, to: kCFBooleanTrue) }
        body()
    }
}
