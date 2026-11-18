import AppKit

final class SnapOverlay {
    private let panel: NSPanel
    private var visible = false

    init() {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
        panel.alphaValue = 0

        let blur = NSVisualEffectView()
        blur.material = .hudWindow
        blur.blendingMode = .behindWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 16
        blur.layer?.cornerCurve = .continuous
        blur.layer?.masksToBounds = true
        blur.layer?.borderWidth = 1
        blur.layer?.borderColor = NSColor.white.withAlphaComponent(0.3).cgColor
        panel.contentView = blur
    }

    // from: the window's current frame, so the first preview grows out of the window itself
    func show(_ frame: CGRect, from: CGRect?) {
        let target = frame.insetBy(dx: 8, dy: 8)
        if !visible {
            visible = true
            // Still fading out: carry on from where it is instead of jumping back to the window
            if !panel.isVisible {
                panel.setFrame(from ?? target.insetBy(dx: target.width * 0.1, dy: target.height * 0.1), display: false)
                panel.orderFrontRegardless()
            }
        }
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.2
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 0.9, 0.3, 1)
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard visible else { return }
        visible = false
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            guard let self, !self.visible else { return }
            self.panel.orderOut(nil)
        })
    }
}
