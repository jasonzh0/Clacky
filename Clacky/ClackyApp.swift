import SwiftUI

@main
struct ClackyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var controller = AppController.shared
    @State private var preferences = Preferences.shared

    init() {
        AppController.shared.start()
        // Instantiate the Sparkle updater so its scheduled background update
        // checks begin (the singleton starts the updater in its initializer).
        _ = UpdaterController.shared
    }

    var body: some Scene {
        @Bindable var prefs = preferences

        MenuBarExtra(isInserted: $prefs.showMenuBarIcon) {
            MenuBarContent()
                .environment(controller)
                .environment(preferences)
        } label: {
            Label("Clacky", systemImage: preferences.isEnabled ? "keyboard.fill" : "keyboard")
        }
        .menuBarExtraStyle(.menu)
    }
}
