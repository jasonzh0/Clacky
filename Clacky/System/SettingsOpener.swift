import AppKit

/// Opens Clacky settings from AppKit entry points (reopen, menu bar, etc.).
enum SettingsOpener {
    static func open() {
        Task { @MainActor in
            SettingsWindowController.shared.show()
        }
    }
}
