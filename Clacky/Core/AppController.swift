import Foundation
import Observation
import AppKit

/// Coordinates the key listener, audio engine, and pack loader. The single owner
/// of the runtime pipeline; UI talks to this rather than to the subsystems directly.
@Observable
@MainActor
final class AppController {
    static let shared = AppController()

    private(set) var availablePacks: [SoundPack] = []
    private(set) var hasAccessibilityPermission: Bool = false
    /// True while the global key event tap is active and delivering events.
    private(set) var listenerIsRunning: Bool = false
    /// True when accessibility is granted but the tap couldn't be created —
    /// usually means the user toggled the permission while the process was
    /// already running and macOS hasn't refreshed it yet. Restarting Clacky
    /// fixes it.
    private(set) var needsRestart: Bool = false

    private let listener = KeyEventListener()
    private let engine = AudioEngine()
    private let preferences = Preferences.shared
    private var permissionPollTimer: Timer?
    private var didPromptOnLaunch = false
    private var activationObserver: NSObjectProtocol?

    private init() {}

    func start() {
        reloadPacks()
        loadSelectedPack()

        listener.onEvent = { [weak self] keyCode, isDown in
            self?.handleKeyEvent(keyCode: keyCode, isDown: isDown)
        }

        engine.setMasterVolume(Float(preferences.volume))

        refreshPermissionStatus()
        if hasAccessibilityPermission {
            startListening()
        } else {
            // Show the system Accessibility dialog the first time we run
            // without trust. macOS only shows it once per app — after that the
            // user has to go through System Settings, which our UI deep-links to.
            AccessibilityPermissions.prompt()
            didPromptOnLaunch = true
            schedulePermissionPolling()
        }

        observeAppActivation()
        observeVolume()
    }

    func reloadPacks() {
        availablePacks = SoundPackLoader.discoverAll()
    }

    func refreshPermissionStatus() {
        let trusted = AccessibilityPermissions.isTrusted()
        if trusted != hasAccessibilityPermission {
            hasAccessibilityPermission = trusted
        }
    }

    func requestAccessibilityPermission() {
        AccessibilityPermissions.prompt()
        AccessibilityPermissions.openSystemSettings()
        schedulePermissionPolling()
    }

    /// Relaunch the app. Used when the user has granted Accessibility access to
    /// a still-running process and the kernel hasn't propagated it — the only
    /// reliable fix is to start a fresh process.
    func relaunchApp() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = ["-n", bundlePath]
        try? task.run()
        // Give the new instance a moment to spawn before we die.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApplication.shared.terminate(nil)
        }
    }

    private func schedulePermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { timer.invalidate(); return }
                let trusted = AccessibilityPermissions.isTrusted()
                if trusted != self.hasAccessibilityPermission {
                    self.hasAccessibilityPermission = trusted
                }
                if trusted {
                    timer.invalidate()
                    self.permissionPollTimer = nil
                    self.startListening()
                }
            }
        }
    }

    private func startListening() {
        do {
            try listener.start()
            listenerIsRunning = true
            needsRestart = false
        } catch {
            listenerIsRunning = false
            // We hit this when AXIsProcessTrusted() returns true but the kernel
            // hasn't refreshed event-tap permissions for our PID — i.e., the
            // user toggled Accessibility on while the app was already running.
            // Only remedy is to relaunch.
            needsRestart = hasAccessibilityPermission
            NSLog("Clacky: failed to start key listener: \(error.localizedDescription)")
        }
    }

    private func observeAppActivation() {
        activationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in AppController.shared.onAppActivated() }
        }
    }

    private func onAppActivated() {
        // User likely just returned from System Settings — re-check trust and
        // retry the listener if it isn't already running.
        refreshPermissionStatus()
        if hasAccessibilityPermission && !listenerIsRunning {
            startListening()
        }
    }

    private func loadSelectedPack() {
        let pack = availablePacks.first(where: { $0.id == preferences.selectedPackID })
            ?? availablePacks.first
        guard let pack else { return }
        engine.loadPack(pack)
        if pack.id != preferences.selectedPackID {
            preferences.selectedPackID = pack.id
        }
    }

    func selectPack(id: String) {
        guard let pack = availablePacks.first(where: { $0.id == id }) else { return }
        preferences.selectedPackID = id
        engine.loadPack(pack)
    }

    private func handleKeyEvent(keyCode: CGKeyCode, isDown: Bool) {
        guard preferences.isEnabled else { return }
        if !isDown && !preferences.playOnKeyUp { return }
        engine.play(
            keyCode: keyCode,
            pitchJitter: Float(preferences.pitchVariation),
            gainJitter: Float(preferences.gainVariation)
        )
    }

    private func observeVolume() {
        withObservationTracking {
            _ = preferences.volume
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.engine.setMasterVolume(Float(self.preferences.volume))
                self.observeVolume()
            }
        }
    }
}
