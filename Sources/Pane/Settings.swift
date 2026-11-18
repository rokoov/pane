import Foundation

enum Settings {
    private static let defaults = UserDefaults.standard

    static var enabled: Bool {
        get { defaults.object(forKey: "enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "enabled") }
    }

    // Holding ⌥ lets the gesture work anywhere in a window, not just the title bar
    static var anywhereWithOption: Bool {
        get { defaults.object(forKey: "anywhereWithOption") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "anywhereWithOption") }
    }

    static let threshold: CGFloat = 40
    static let titleBarHeight: CGFloat = 44
}
