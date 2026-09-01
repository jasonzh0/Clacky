import AppKit
import SwiftUI

/// Presents Settings in a normal AppKit window so reopen works even when the
/// menu-bar extra is hidden (SwiftUI's Settings scene does not reliably open
/// via `showSettingsWindow:` on current macOS).
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)

        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingController = NSHostingController(
            rootView: SettingsView()
                .environment(AppController.shared)
                .environment(Preferences.shared)
                .frame(minWidth: 480, minHeight: 360)
        )

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Clacky Settings"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 520, height: 420))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        self.window = window
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
