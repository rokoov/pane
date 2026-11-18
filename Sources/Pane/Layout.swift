import CoreGraphics

enum Layout: Equatable {
    case leftHalf, rightHalf, maximize, minimize
    case topLeft, topRight, bottomLeft, bottomRight

    // Frames are in Cocoa coordinates (origin bottom-left)
    func frame(in v: CGRect) -> CGRect {
        let w = (v.width / 2).rounded(), h = (v.height / 2).rounded()
        switch self {
        case .leftHalf: return CGRect(x: v.minX, y: v.minY, width: w, height: v.height)
        case .rightHalf: return CGRect(x: v.minX + w, y: v.minY, width: v.width - w, height: v.height)
        case .maximize: return v
        case .minimize: return CGRect(x: v.midX - v.width * 0.15, y: v.minY, width: v.width * 0.3, height: v.height * 0.2)
        case .topLeft: return CGRect(x: v.minX, y: v.minY + h, width: w, height: v.height - h)
        case .topRight: return CGRect(x: v.minX + w, y: v.minY + h, width: v.width - w, height: v.height - h)
        case .bottomLeft: return CGRect(x: v.minX, y: v.minY, width: w, height: h)
        case .bottomRight: return CGRect(x: v.minX + w, y: v.minY, width: v.width - w, height: h)
        }
    }

    // dx/dy are finger movement, positive = right/up
    static func from(dx: CGFloat, dy: CGFloat, threshold: CGFloat) -> Layout? {
        let ax = abs(dx), ay = abs(dy)
        guard max(ax, ay) >= threshold else { return nil }
        if min(ax, ay) >= max(ax, ay) * 0.5 {
            switch (dx > 0, dy > 0) {
            case (false, true): return .topLeft
            case (true, true): return .topRight
            case (false, false): return .bottomLeft
            case (true, false): return .bottomRight
            }
        }
        if ax > ay { return dx > 0 ? .rightHalf : .leftHalf }
        return dy > 0 ? .maximize : .minimize
    }
}
