import Foundation

/// In-memory representation of a Mechvibes-compatible sound pack.
struct SoundPack: Identifiable, Hashable {
    let id: String
    let name: String
    let directory: URL
    let kind: Kind
    let includesNumpad: Bool

    enum Kind: Hashable {
        /// Sprite file containing every key sound, sliced by `[startMs, durationMs]`.
        case single(soundFile: URL, slices: [String: Slice])
        /// One audio file per key.
        case multi(files: [String: URL])
    }

    struct Slice: Hashable {
        let startMs: Double
        let durationMs: Double
    }
}

/// Codable representation of the Mechvibes `config.json` schema. Both pack
/// flavors (`"single"` sprite, `"multi"` per-file) are supported.
///
/// Reference: https://github.com/hainguyents13/mechvibes
struct MechvibesConfig: Codable {
    let id: String?
    let name: String
    let key_define_type: String
    let sound: String?
    let includes_numpad: Bool?
    let defines: [String: Define]

    enum Define: Codable, Hashable {
        case slice(start: Double, duration: Double)
        case file(String)
        case none

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() { self = .none; return }
            if let arr = try? container.decode([Double].self) {
                guard arr.count >= 2 else { self = .none; return }
                self = .slice(start: arr[0], duration: arr[1])
                return
            }
            if let str = try? container.decode(String.self) {
                self = .file(str); return
            }
            self = .none
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .none:
                try container.encodeNil()
            case .slice(let start, let duration):
                try container.encode([start, duration])
            case .file(let name):
                try container.encode(name)
            }
        }
    }
}
