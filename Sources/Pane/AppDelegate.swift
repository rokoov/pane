import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = GestureMonitor()
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Pane")
        rebuildMenu()

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) {
            startMonitor()
            return
        }
        let interval = Config.permissionPollInterval
        permissionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard AXIsProcessTrusted() else { return }
            timer.invalidate()
            self?.startMonitor()
        }
    }

    private func startMonitor() {
        monitor.start()
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        if !monitor.isRunning {
            menu.addItem(item("Waiting for Accessibility access…", action: #selector(openAccessibilitySettings)))
            menu.addItem(.separator())
        }
        let toggles: [(title: String, isOn: Bool, action: Selector)] = [
            ("Enabled", Settings.isEnabled, #selector(toggleEnabled)),
            ("Swipe Anywhere While Holding ⌥", Settings.allowsSwipeAnywhere, #selector(toggleAnywhere)),
            ("Launch at Login", SMAppService.mainApp.status == .enabled, #selector(toggleLaunchAtLogin)),
        ]
        for toggle in toggles {
            menu.addItem(item(toggle.title, isOn: toggle.isOn, action: toggle.action))
        }
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pane", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, isOn: Bool? = nil, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let isOn { item.state = isOn ? .on : .off }
        return item
    }

    @objc private func toggleEnabled() {
        Settings.isEnabled.toggle()
        rebuildMenu()
    }

    @objc private func toggleAnywhere() {
        Settings.allowsSwipeAnywhere.toggle()
        rebuildMenu()
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("Pane: launch at login failed: \(error)")
        }
        rebuildMenu()
    }

    @objc private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url { NSWorkspace.shared.open(url) }
    }
}
