import AppKit

// Accessibility coordinates start at the top left of the main screen, Cocoa ones at its bottom left
enum Screens {
    private static var mainScreenHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    // Converts either way, since flipping twice gives back the original
    static func flip(_ rect: CGRect) -> CGRect {
        CGRect(x: rect.minX, y: mainScreenHeight - rect.maxY, width: rect.width, height: rect.height)
    }

    static func flip(_ point: CGPoint) -> CGPoint {
        CGPoint(x: point.x, y: mainScreenHeight - point.y)
    }

    static func screen(containing point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }

    // Nearest screen that lies entirely to one side, allowing a point of overlap at the shared edge
    static func neighbor(of screen: NSScreen, toTheLeft: Bool) -> NSScreen? {
        let distance = { (other: NSScreen) in
            abs(other.frame.midX - screen.frame.midX) + abs(other.frame.midY - screen.frame.midY)
        }
        return NSScreen.screens
            .filter { other in
                guard other != screen else { return false }
                return toTheLeft ? other.frame.maxX <= screen.frame.minX + 1 : other.frame.minX >= screen.frame.maxX - 1
            }
            .min { distance($0) < distance($1) }
    }
}

extension CGRect {
    func isClose(to other: CGRect, tolerance: CGFloat = Config.Windows.frameTolerance) -> Bool {
        abs(minX - other.minX) < tolerance && abs(minY - other.minY) < tolerance
            && abs(width - other.width) < tolerance && abs(height - other.height) < tolerance
    }
}
