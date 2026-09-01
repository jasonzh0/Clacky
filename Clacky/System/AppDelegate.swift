import AppKit

/// Reopening Clacky (Applications / Spotlight) brings Settings back,
/// which matters when the menu-bar extra is hidden.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        SettingsOpener.open()
        return true
    }
}
