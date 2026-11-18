import Foundation

// Preferences the menu bar toggles
enum Settings {
    private static let defaults = UserDefaults.standard

    static var isEnabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    // Holding ⌥ lets a swipe move the active window from anywhere on screen
    static var allowsSwipeAnywhere: Bool {
        get { defaults.object(forKey: "anywhereWithOption") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "anywhereWithOption") }
    }
}
