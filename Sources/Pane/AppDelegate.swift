import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let monitor = GestureMonitor()
    private let state = PaneState()
    private lazy var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private var permissionTimer: Timer?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Settings.registerDefaults()
        statusItem.button?.image = NSImage(systemSymbolName: "rectangle.split.2x1", accessibilityDescription: "Pane")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        if AXIsProcessTrustedWithOptions(options) { monitor.start() }
        watchPermission()
    }

    // Access can come and go at any time (granted later, reset by a macOS update). Without it the tap goes silent,
    // so Pane lets go of it, shows that it is waiting, and starts again once access is back
    private func watchPermission() {
        let interval = Config.permissionPollInterval
        permissionTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
    }

    private func checkPermission() {
        let isTrusted = AXIsProcessTrusted()
        if isTrusted && !monitor.isRunning {
            monitor.start()
        } else if !isTrusted && monitor.isRunning {
            monitor.stop()
        }
        monitor.ensureEnabled()
        if state.hasAccessibility != isTrusted { state.hasAccessibility = isTrusted }
    }

    // Built each time the menu opens, so it always matches the Settings window
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if !monitor.isRunning {
            menu.addItem(item("Waiting for Accessibility access…", action: #selector(openAccessibilitySettings)))
            menu.addItem(.separator())
        }
        let enabled = item("Enabled", action: #selector(toggleEnabled))
        enabled.state = Settings.isEnabled ? .on : .off
        menu.addItem(enabled)
        menu.addItem(.separator())
        menu.addItem(item("Settings…", action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Pane", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func item(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func toggleEnabled() {
        Settings.isEnabled.toggle()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(state: state)))
            window.title = "Pane Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        // Pane has no Dock icon, so it brings itself forward for the window to take focus
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(Config.accessibilitySettings)
    }
}
