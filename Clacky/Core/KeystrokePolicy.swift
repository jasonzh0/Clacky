import Foundation

/// Decides whether a captured key event should trigger a sound.
enum KeystrokePolicy {
    /// macOS delivers extra `keyDown` events while a key is held (`keyboardEventAutorepeat`).
    /// Those are not new presses, so they should be silent by default.
    static func shouldPlay(
        isDown: Bool,
        isRepeat: Bool,
        ignoreKeyRepeat: Bool,
        playOnKeyUp: Bool
    ) -> Bool {
        if isRepeat && ignoreKeyRepeat { return false }
        if !isDown && !playOnKeyUp { return false }
        return true
    }
}
