import AppKit

enum Screens {
    static var primaryHeight: CGFloat { NSScreen.screens.first?.frame.height ?? 0 }

    // Flips between AX (top-left origin) and Cocoa (bottom-left origin), works both ways
    static func flip(_ r: CGRect) -> CGRect {
        CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
    }

    static func flip(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x, y: primaryHeight - p.y)
    }

    static func screen(containing p: CGPoint) -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(p, $0.frame, false) } ?? NSScreen.main
    }

    static func neighbor(of s: NSScreen, left: Bool) -> NSScreen? {
        let distance = { (o: NSScreen) in abs(o.frame.midX - s.frame.midX) + abs(o.frame.midY - s.frame.midY) }
        return NSScreen.screens
            .filter { $0 != s && (left ? $0.frame.maxX <= s.frame.minX + 1 : $0.frame.minX >= s.frame.maxX - 1) }
            .min { distance($0) < distance($1) }
    }
}

extension CGRect {
    func isClose(to o: CGRect, tolerance: CGFloat = 10) -> Bool {
        abs(minX - o.minX) < tolerance && abs(minY - o.minY) < tolerance
            && abs(width - o.width) < tolerance && abs(height - o.height) < tolerance
    }
}
