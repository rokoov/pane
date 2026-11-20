import Foundation
import QuartzCore

// Tuning values, each with its unit and what raising it does
enum Config {
    enum Gesture {
        // Points of finger travel before a swipe picks a layout; higher needs a longer swipe. Settings moves it
        // within the range, from short to long
        static let threshold: CGFloat = 40
        static let thresholdRange: ClosedRange<Double> = 20...80
        // Points from the top of the active window that count as its title bar
        static let titleBarHeight: CGFloat = 44
        // Shorter axis over longer axis from which a swipe is diagonal; higher makes quarters harder to hit
        static let diagonalRatio: CGFloat = 0.5
    }

    enum Preview {
        // Points between the preview's edge and the frame the window will take
        static let inset: CGFloat = 8
        static let cornerRadius: CGFloat = 16
        static let borderWidth: CGFloat = 1
        static let borderOpacity: CGFloat = 0.3
        // Seconds to glide to a new target and to fade out
        static let moveDuration: TimeInterval = 0.2
        static let fadeDuration: TimeInterval = 0.15
        // Starts fast and settles gently
        static let timing = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1)
        // Share of the screen's width and height the minimize preview takes above the Dock
        static let minimizeScale = CGSize(width: 0.3, height: 0.2)
    }

    enum Windows {
        // Seconds an app gets to answer an accessibility call; higher waits longer on a hung app
        static let messagingTimeout: Float = 0.15
        // Points two frames may differ by and still count as the same
        static let frameTolerance: CGFloat = 10
        // Extra tries, and seconds between them, for a window still clamped to the screen it left
        static let moveRetries = 3
        static let moveRetryDelay: TimeInterval = 0.05
    }

    // Seconds between checks that Accessibility access is still granted and the event tap still on
    static let permissionPollInterval: TimeInterval = 2

    static let repository = URL(string: "https://github.com/rokoov/pane")!
    static let latestRelease = URL(string: "https://github.com/rokoov/pane/releases/latest")!
    static let accessibilitySettings = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
}
