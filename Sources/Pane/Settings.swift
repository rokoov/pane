import Foundation

// Preferences from the Settings window and the menu, kept in UserDefaults
enum Settings {
    enum Key {
        static let enabled = "enabled"
        static let swipeAnywhere = "anywhereWithOption"
        static let threshold = "threshold"
        static let haptics = "haptics"
        static let preview = "preview"
    }

    private static let defaults = UserDefaults.standard

    // What every preference starts as; the Settings window reads the same keys
    static func registerDefaults() {
        defaults.register(defaults: [
            Key.enabled: true,
            Key.swipeAnywhere: true,
            Key.threshold: Double(Config.Gesture.threshold),
            Key.haptics: true,
            Key.preview: true,
        ])
    }

    static var isEnabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    // Holding ⌥ lets a swipe move the active window from anywhere on screen
    static var allowsSwipeAnywhere: Bool { defaults.bool(forKey: Key.swipeAnywhere) }

    // Points of finger travel before a swipe picks a layout
    static var threshold: CGFloat { CGFloat(defaults.double(forKey: Key.threshold)) }

    // A tick in the trackpad each time the preview moves to a new layout
    static var playsHaptics: Bool { defaults.bool(forKey: Key.haptics) }

    static var showsPreview: Bool { defaults.bool(forKey: Key.preview) }
}
