import CoreGraphics

/// Translates between macOS `CGKeyCode` virtual key codes and Mechvibes
/// (iohook/uIOhook) scancodes used as keys in Mechvibes pack `config.json` files.
///
/// Mechvibes packs identify keys by their iohook code — a Linux/Windows-style
/// scancode that is the same across every Mechvibes platform but differs from
/// macOS virtual key codes. We translate at lookup time so existing community
/// packs work unmodified.
enum KeycodeMap {
    /// Look up the Mechvibes config-key string for a macOS virtual key code.
    /// Returns nil for keys outside the standard US layout — callers should fall
    /// back to a generic clip.
    static func mechvibesKey(for keyCode: CGKeyCode) -> String? {
        cgToMechvibes[keyCode]
    }

    static let cgToMechvibes: [CGKeyCode: String] = [
        0x35: "1",        // Escape
        0x12: "2",        // 1
        0x13: "3",        // 2
        0x14: "4",        // 3
        0x15: "5",        // 4
        0x17: "6",        // 5
        0x16: "7",        // 6
        0x1A: "8",        // 7
        0x1C: "9",        // 8
        0x19: "10",       // 9
        0x1D: "11",       // 0
        0x1B: "12",       // -
        0x18: "13",       // =
        0x33: "14",       // Backspace (Delete on Mac)
        0x30: "15",       // Tab
        0x0C: "16",       // Q
        0x0D: "17",       // W
        0x0E: "18",       // E
        0x0F: "19",       // R
        0x11: "20",       // T
        0x10: "21",       // Y
        0x20: "22",       // U
        0x22: "23",       // I
        0x1F: "24",       // O
        0x23: "25",       // P
        0x21: "26",       // [
        0x1E: "27",       // ]
        0x24: "28",       // Return
        0x3B: "29",       // Left Control
        0x00: "30",       // A
        0x01: "31",       // S
        0x02: "32",       // D
        0x03: "33",       // F
        0x05: "34",       // G
        0x04: "35",       // H
        0x26: "36",       // J
        0x28: "37",       // K
        0x25: "38",       // L
        0x29: "39",       // ;
        0x27: "40",       // '
        0x32: "41",       // `
        0x38: "42",       // Left Shift
        0x2A: "43",       // \
        0x06: "44",       // Z
        0x07: "45",       // X
        0x08: "46",       // C
        0x09: "47",       // V
        0x0B: "48",       // B
        0x2D: "49",       // N
        0x2E: "50",       // M
        0x2B: "51",       // ,
        0x2F: "52",       // .
        0x2C: "53",       // /
        0x3C: "54",       // Right Shift
        0x43: "55",       // Keypad *
        0x3A: "56",       // Left Option/Alt
        0x31: "57",       // Space
        0x39: "58",       // Caps Lock
        0x7A: "59",       // F1
        0x78: "60",       // F2
        0x63: "61",       // F3
        0x76: "62",       // F4
        0x60: "63",       // F5
        0x61: "64",       // F6
        0x62: "65",       // F7
        0x64: "66",       // F8
        0x65: "67",       // F9
        0x6D: "68",       // F10
        0x47: "69",       // Keypad Clear (NumLock equivalent)
        0x59: "71",       // Keypad 7
        0x5B: "72",       // Keypad 8
        0x5C: "73",       // Keypad 9
        0x4E: "74",       // Keypad -
        0x56: "75",       // Keypad 4
        0x57: "76",       // Keypad 5
        0x58: "77",       // Keypad 6
        0x45: "78",       // Keypad +
        0x53: "79",       // Keypad 1
        0x54: "80",       // Keypad 2
        0x55: "81",       // Keypad 3
        0x52: "82",       // Keypad 0
        0x41: "83",       // Keypad .
        0x67: "87",       // F11
        0x6F: "88",       // F12
        // Extended (e0-prefixed) keys
        0x4C: "57372",    // Keypad Enter
        0x3E: "57373",    // Right Control
        0x4B: "57397",    // Keypad /
        0x3D: "57400",    // Right Option/Alt
        0x73: "57415",    // Home
        0x7E: "57416",    // Up Arrow
        0x74: "57417",    // Page Up
        0x7B: "57419",    // Left Arrow
        0x7C: "57421",    // Right Arrow
        0x77: "57423",    // End
        0x7D: "57424",    // Down Arrow
        0x79: "57425",    // Page Down
        0x75: "57427",    // Forward Delete
        0x37: "3675",     // Left Command (Win)
        0x36: "3676"      // Right Command (Win)
    ]
}
