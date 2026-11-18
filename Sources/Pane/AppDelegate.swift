import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let monitor = GestureMonitor()
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Pane")
        rebuildMenu()

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            startMonitor()
        } else {
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
                guard AXIsProcessTrusted() else { return }
                timer.invalidate()
                self?.startMonitor()
            }
        }
    }

    private func startMonitor() {
        monitor.start()
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        if !monitor.isRunning {
            let waiting = NSMenuItem(title: "Waiting for Accessibility access…", action: #selector(openAccessibility), keyEquivalent: "")
            waiting.target = self
            menu.addItem(waiting)
            menu.addItem(.separator())
        }

        menu.addItem(toggle("Enabled", Settings.enabled, #selector(toggleEnabled)))
        menu.addItem(toggle("Swipe Anywhere While Holding ⌥", Settings.anywhereWithOption, #selector(toggleAnywhere)))
        menu.addItem(toggle("Launch at Login", SMAppService.mainApp.status == .enabled, #selector(toggleLogin)))
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Pane", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
        statusItem.menu = menu
    }

    private func toggle(_ title: String, _ on: Bool, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    @objc private func toggleEnabled() {
        Settings.enabled.toggle()
        rebuildMenu()
    }

    @objc private func toggleAnywhere() {
        Settings.anywhereWithOption.toggle()
        rebuildMenu()
    }

    @objc private func toggleLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled { try service.unregister() } else { try service.register() }
        } catch {
            NSLog("Pane: launch at login failed: \(error)")
        }
        rebuildMenu()
    }

    @objc private func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
