import ApplicationServices
import Foundation

// Typed access to accessibility attributes
extension AXUIElement {
    var pid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(self, &pid)
        return pid
    }

    // In accessibility coordinates: origin at the top left of the main screen
    var frame: CGRect? {
        guard let position = axValue(kAXPositionAttribute), let size = axValue(kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(position, .cgPoint, &origin), AXValueGetValue(size, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    func element(_ name: String) -> AXUIElement? {
        guard let value = copyValue(name), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    func string(_ name: String) -> String? {
        copyValue(name) as? String
    }

    func bool(_ name: String) -> Bool? {
        (copyValue(name) as? NSNumber)?.boolValue
    }

    func set(_ name: String, to value: CFTypeRef) {
        AXUIElementSetAttributeValue(self, name as CFString, value)
    }

    private func axValue(_ name: String) -> AXValue? {
        guard let value = copyValue(name), CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        return (value as! AXValue)
    }

    private func copyValue(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success ? value : nil
    }
}
