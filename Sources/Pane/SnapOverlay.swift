import AppKit

// Blurred preview of where the window will land
final class SnapOverlay {
    private let panel: NSPanel
    private var isShown = false

    init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
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
        blur.layer?.cornerRadius = Config.Preview.cornerRadius
        blur.layer?.cornerCurve = .continuous
        blur.layer?.masksToBounds = true
        blur.layer?.borderWidth = Config.Preview.borderWidth
        blur.layer?.borderColor = NSColor.white.withAlphaComponent(Config.Preview.borderOpacity).cgColor
        panel.contentView = blur
    }

    // The first preview of a swipe grows out of the window's own frame
    func show(_ frame: CGRect, growingFrom start: CGRect) {
        let target = frame.insetBy(dx: Config.Preview.inset, dy: Config.Preview.inset)
        if !isShown {
            isShown = true
            // Still fading out: carry on from where it is instead of jumping back to the window
            if !panel.isVisible {
                panel.setFrame(start, display: false)
                panel.orderFrontRegardless()
            }
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Config.Preview.moveDuration
            context.timingFunction = Config.Preview.timing
            panel.animator().setFrame(target, display: true)
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard isShown else { return }
        isShown = false
        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = Config.Preview.fadeDuration
                panel.animator().alphaValue = 0
            },
            completionHandler: { [weak self] in
                guard let self, !self.isShown else { return }
                self.panel.orderOut(nil)
            }
        )
    }
}
