import CoreGraphics

enum Layout {
    case leftHalf, rightHalf, maximize, minimize
    case topLeft, topRight, bottomLeft, bottomRight

    // From finger travel, positive right and up; nil while the swipe is still too short
    init?(travel: CGVector) {
        let horizontal = abs(travel.dx)
        let vertical = abs(travel.dy)
        guard max(horizontal, vertical) >= Config.Gesture.threshold else { return nil }

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

    // In Cocoa coordinates, origin at the bottom left, like the visible frame it divides
    func frame(in visible: CGRect) -> CGRect {
        let halfWidth = (visible.width / 2).rounded()
        let halfHeight = (visible.height / 2).rounded()
        let right = visible.minX + halfWidth
        let top = visible.minY + halfHeight
        switch self {
        case .leftHalf:
            return CGRect(x: visible.minX, y: visible.minY, width: halfWidth, height: visible.height)
        case .rightHalf:
            return CGRect(x: right, y: visible.minY, width: visible.width - halfWidth, height: visible.height)
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
