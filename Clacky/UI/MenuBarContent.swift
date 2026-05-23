import SwiftUI

struct MenuBarContent: View {
    @Environment(AppController.self) private var controller
    @Environment(Preferences.self) private var preferences
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var prefs = preferences

        Toggle("Enabled", isOn: $prefs.isEnabled)
            .keyboardShortcut("e")

        Divider()

        Section("Volume") {
            // SwiftUI menus don't render sliders inline reliably across versions;
            // expose +/- and a current value readout instead.
            Button("Louder") { prefs.volume = min(1.0, prefs.volume + 0.1) }
            Button("Quieter") { prefs.volume = max(0.0, prefs.volume - 0.1) }
            Text("\(Int(prefs.volume * 100))%")
        }

        Divider()

        Section("Sound Pack") {
            ForEach(controller.availablePacks) { pack in
                Button {
                    controller.selectPack(id: pack.id)
                } label: {
                    if pack.id == prefs.selectedPackID {
                        Label(pack.name, systemImage: "checkmark")
                    } else {
                        Text(pack.name)
                    }
                }
            }
            if controller.availablePacks.isEmpty {
                Text("No sound packs found").foregroundStyle(.secondary)
            }
            Button("Reload Packs") {
                controller.reloadPacks()
            }
        }

        Divider()

        if !controller.hasAccessibilityPermission {
            Button("⚠️ Grant Accessibility Access…") {
                controller.requestAccessibilityPermission()
                openSettings()
            }
        } else if controller.needsRestart {
            Button("⚠️ Restart Clacky to activate") {
                controller.relaunchApp()
            }
        }

        Button("Settings…") {
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quit Clacky") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
