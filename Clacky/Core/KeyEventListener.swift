import Foundation
import CoreGraphics
import ApplicationServices

/// Wraps a session-level `CGEventTap` that fires on every keyDown / keyUp anywhere
/// in the system, forwarding `(keyCode, isDown)` to `onEvent` on a background queue.
/// The tap is listen-only — it never modifies or swallows events.
final class KeyEventListener {
    enum ListenerError: Error, LocalizedError {
        case missingPermission
        case tapCreationFailed

        var errorDescription: String? {
            switch self {
            case .missingPermission: return "Accessibility permission has not been granted."
            case .tapCreationFailed: return "Failed to create the system event tap."
            }
        }
    }

    /// Called on the listener's background queue for every key event.
    var onEvent: ((CGKeyCode, Bool) -> Void)?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var runLoop: CFRunLoop?
    private let queue = DispatchQueue(label: "com.clacky.KeyEventListener", qos: .userInteractive)
    private var thread: Thread?

    deinit { stop() }

    func start() throws {
        guard AXIsProcessTrusted() else { throw ListenerError.missingPermission }
        guard eventTap == nil else { return }

        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        let callback: CGEventTapCallBack = { _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let listener = Unmanaged<KeyEventListener>.fromOpaque(refcon).takeUnretainedValue()
            if type == .keyDown || type == .keyUp {
                let code = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
                listener.dispatch(keyCode: code, isDown: type == .keyDown)
            }
            return Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: userInfo
        ) else {
            throw ListenerError.tapCreationFailed
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        runLoopSource = source

        let thread = Thread { [weak self] in
            let loop = CFRunLoopGetCurrent()
            self?.runLoop = loop
            CFRunLoopAddSource(loop, source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "com.clacky.KeyEventListener"
        thread.qualityOfService = .userInteractive
        self.thread = thread
        thread.start()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let loop = runLoop, let source = runLoopSource {
            CFRunLoopRemoveSource(loop, source, .commonModes)
            CFRunLoopStop(loop)
        }
        runLoopSource = nil
        eventTap = nil
        runLoop = nil
        thread = nil
    }

    private func dispatch(keyCode: CGKeyCode, isDown: Bool) {
        queue.async { [weak self] in
            self?.onEvent?(keyCode, isDown)
        }
    }
}
