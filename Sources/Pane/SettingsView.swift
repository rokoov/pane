import ServiceManagement
import SwiftUI

// What the Settings window shows live, kept up to date by the app delegate
final class PaneState: ObservableObject {
    @Published var hasAccessibility = AXIsProcessTrusted()
}

struct SettingsView: View {
    @ObservedObject var state: PaneState
    @AppStorage(Settings.Key.enabled) private var isEnabled = true
    @AppStorage(Settings.Key.swipeAnywhere) private var allowsSwipeAnywhere = true
    @AppStorage(Settings.Key.threshold) private var threshold = Double(Config.Gesture.threshold)
    @AppStorage(Settings.Key.preview) private var showsPreview = true
    @AppStorage(Settings.Key.haptics) private var playsHaptics = true
    @State private var launchesAtLogin = SMAppService.mainApp.status == .enabled

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "–"
    }

    var body: some View {
        Form {
            Section {
                Toggle("Snap windows with swipes", isOn: $isEnabled)
                Toggle("Launch at login", isOn: $launchesAtLogin)
                    .onChange(of: launchesAtLogin) { setLaunchAtLogin($0) }
            }
            Section("Gestures") {
                Toggle("Swipe anywhere while holding ⌥", isOn: $allowsSwipeAnywhere)
                Slider(value: $threshold, in: Config.Gesture.thresholdRange) {
                    Text("Swipe length")
                } minimumValueLabel: {
                    Text("Short")
                } maximumValueLabel: {
                    Text("Long")
                }
                Toggle("Show where the window will land", isOn: $showsPreview)
                Toggle("Haptic feedback", isOn: $playsHaptics)
            }
            Section("Permission") {
                LabeledContent("Accessibility") {
                    if state.hasAccessibility {
                        Label("Allowed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Open System Settings") { NSWorkspace.shared.open(Config.accessibilitySettings) }
                    }
                }
            }
            Section {
                LabeledContent("Version", value: version)
                Link("Pane on GitHub", destination: Config.repository)
                Link("Check for updates", destination: Config.latestRelease)
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func setLaunchAtLogin(_ isOn: Bool) {
        do {
            if isOn {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("Pane: launch at login failed: \(error)")
        }
        // A login item the user switched off in System Settings can only be switched back on there
        if SMAppService.mainApp.status == .requiresApproval { SMAppService.openSystemSettingsLoginItems() }
        launchesAtLogin = SMAppService.mainApp.status == .enabled
    }
}
