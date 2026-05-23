import AppKit
import ApplicationServices

enum AccessibilityPermissions {
    /// Non-prompting trust check. Safe to call on every app activation.
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Triggers the system prompt asking the user to grant Accessibility access.
    /// Only effective on first call per app launch.
    @discardableResult
    static func prompt() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Deep-link to System Settings → Privacy & Security → Accessibility.
    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
