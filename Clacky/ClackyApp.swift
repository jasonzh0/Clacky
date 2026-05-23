import SwiftUI

@main
struct ClackyApp: App {
    @State private var controller = AppController.shared

    init() {
        AppController.shared.start()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environment(controller)
                .environment(Preferences.shared)
        } label: {
            Label("Clacky", systemImage: Preferences.shared.isEnabled ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(controller)
                .environment(Preferences.shared)
                .frame(minWidth: 480, minHeight: 360)
        }
    }
}
