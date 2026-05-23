import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            SoundSettingsView()
                .tabItem { Label("Sound", systemImage: "speaker.wave.2") }
            PermissionsView()
                .tabItem { Label("Permissions", systemImage: "lock.shield") }
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(20)
    }
}

struct GeneralSettingsView: View {
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var prefs = preferences
        Form {
            Toggle("Enable typing sounds", isOn: $prefs.isEnabled)
            Toggle("Play sound on key release too", isOn: $prefs.playOnKeyUp)
            Toggle("Launch at login", isOn: Binding(
                get: { prefs.launchAtLogin },
                set: { newValue in
                    prefs.launchAtLogin = newValue
                    LaunchAtLogin.setEnabled(newValue)
                }
            ))
        }
        .formStyle(.grouped)
    }
}

struct SoundSettingsView: View {
    @Environment(AppController.self) private var controller
    @Environment(Preferences.self) private var preferences

    var body: some View {
        @Bindable var prefs = preferences
        Form {
            Section("Sound pack") {
                Picker("Active pack", selection: Binding(
                    get: { prefs.selectedPackID },
                    set: { controller.selectPack(id: $0) }
                )) {
                    ForEach(controller.availablePacks) { pack in
                        Text(pack.name).tag(pack.id)
                    }
                }
                Button("Reload packs") { controller.reloadPacks() }
                Button("Open packs folder") {
                    NSWorkspace.shared.open(SoundPackLoader.userSoundPacksDirectory())
                }
            }
            Section("Volume & feel") {
                LabeledContent("Volume") {
                    Slider(value: $prefs.volume, in: 0...1)
                }
                LabeledContent("Pitch variation") {
                    Slider(value: $prefs.pitchVariation, in: 0...0.08)
                }
                LabeledContent("Loudness variation") {
                    Slider(value: $prefs.gainVariation, in: 0...0.2)
                }
            }
        }
        .formStyle(.grouped)
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "keyboard.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Clacky").font(.title).bold()
            Text("An open-source mechanical keyboard sound player for macOS.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Compatible with Mechvibes sound packs.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Link("github.com/jasonzh0/Clacky", destination: URL(string: "https://github.com/jasonzh0/Clacky")!)
                .font(.footnote)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
