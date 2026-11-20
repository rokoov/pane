import CoreGraphics

enum Layout {
    case leftHalf, rightHalf, maximize, minimize
    case topLeft, topRight, bottomLeft, bottomRight
    case leftTwoThirds, leftThird, rightTwoThirds, rightThird

    // Widths a window steps through when it is swiped again toward the edge it already hugs
    private static let leftWidths: [Layout] = [.leftHalf, .leftTwoThirds, .leftThird]
    private static let rightWidths: [Layout] = [.rightHalf, .rightTwoThirds, .rightThird]

    // From finger travel, positive right and up; nil while the swipe is shorter than the threshold
    init?(travel: CGVector, threshold: CGFloat) {
        let horizontal = abs(travel.dx)
        let vertical = abs(travel.dy)
        guard max(horizontal, vertical) >= threshold else { return nil }

        if min(horizontal, vertical) >= max(horizontal, vertical) * Config.Gesture.diagonalRatio {
            switch (travel.dx > 0, travel.dy > 0) {
            case (false, true): self = .topLeft
            case (true, true): self = .topRight
            case (false, false): self = .bottomLeft
            case (true, false): self = .bottomRight
            }
        } else if horizontal > vertical {
            self = travel.dx > 0 ? .rightHalf : .leftHalf
        } else {
            self = travel.dy > 0 ? .maximize : .minimize
        }
    }

    // For a half: the width after the one the window already fills on that side, or nil if it doesn't hug it
    func nextWidth(after frame: CGRect, in visible: CGRect) -> Layout? {
        let widths: [Layout]
        switch self {
        case .leftHalf: widths = Self.leftWidths
        case .rightHalf: widths = Self.rightWidths
        default: return nil
        }
        guard let index = widths.firstIndex(where: { frame.isClose(to: $0.frame(in: visible)) }) else { return nil }
        return widths[(index + 1) % widths.count]
    }

    // In Cocoa coordinates, origin at the bottom left, like the visible frame it divides
    func frame(in visible: CGRect) -> CGRect {
        let halfWidth = (visible.width / 2).rounded()
        let halfHeight = (visible.height / 2).rounded()
        let third = (visible.width / 3).rounded()
        let right = visible.minX + halfWidth
        let top = visible.minY + halfHeight
        switch self {
        case .leftHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: halfWidth, height: visible.height)
        case .rightHalf:
            return CGRect(x: right, y: visible.minY, width: visible.width - halfWidth, height: visible.height)
        case .leftTwoThirds:
            return CGRect(x: visible.minX, y: visible.minY, width: visible.width - third, height: visible.height)
        case .leftThird:
            return CGRect(x: visible.minX, y: visible.minY, width: third, height: visible.height)
        case .rightTwoThirds:
            return CGRect(
                x: visible.minX + third, y: visible.minY, width: visible.width - third, height: visible.height)
        case .rightThird:
            return CGRect(x: visible.maxX - third, y: visible.minY, width: third, height: visible.height)
        case .maximize:
            return visible
        case .minimize:
            let size = CGSize(
                width: visible.width * Config.Preview.minimizeScale.width,
                height: visible.height * Config.Preview.minimizeScale.height
            )
            return CGRect(x: visible.midX - size.width / 2, y: visible.minY, width: size.width, height: size.height)
        case .topLeft:
            return CGRect(x: visible.minX, y: top, width: halfWidth, height: visible.height - halfHeight)
        case .topRight:
            return CGRect(x: right, y: top, width: visible.width - halfWidth, height: visible.height - halfHeight)
        case .bottomLeft:
            return CGRect(x: visible.minX, y: visible.minY, width: halfWidth, height: halfHeight)
        case .bottomRight:
            return CGRect(x: right, y: visible.minY, width: visible.width - halfWidth, height: halfHeight)
        }
    }
}
