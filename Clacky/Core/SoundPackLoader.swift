import Foundation

/// Discovers and parses Mechvibes-format sound packs from two locations:
///   1. The app bundle's `Resources/SoundPacks/` directory (shipped defaults).
///   2. `~/Library/Application Support/Clacky/SoundPacks/` (user-installed).
enum SoundPackLoader {
    static let appSupportDirectoryName = "Clacky"
    static let soundPacksFolderName = "SoundPacks"

    static func discoverAll() -> [SoundPack] {
        var packs: [SoundPack] = []
        var seenIDs = Set<String>()

        for url in bundleSearchPaths() + [userSoundPacksDirectory()] {
            for packDir in childDirectories(of: url) {
                guard let pack = load(from: packDir), !seenIDs.contains(pack.id) else { continue }
                seenIDs.insert(pack.id)
                packs.append(pack)
            }
        }
        return packs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Parse a single pack from a directory. Returns nil if `config.json` is
    /// missing or malformed.
    static func load(from directory: URL) -> SoundPack? {
        let configURL = directory.appendingPathComponent("config.json")
        guard let data = try? Data(contentsOf: configURL) else { return nil }
        guard let config = try? JSONDecoder().decode(MechvibesConfig.self, from: data) else { return nil }

        let id = config.id ?? directory.lastPathComponent
        let includesNumpad = config.includes_numpad ?? true

        switch config.key_define_type {
        case "single":
            guard let soundName = config.sound else { return nil }
            var slices: [String: SoundPack.Slice] = [:]
            for (key, define) in config.defines {
                if case let .slice(start, duration) = define {
                    slices[key] = .init(startMs: start, durationMs: duration)
                }
            }
            let kind: SoundPack.Kind = .single(
                soundFile: directory.appendingPathComponent(soundName),
                slices: slices
            )
            return SoundPack(id: id, name: config.name, directory: directory,
                             kind: kind, includesNumpad: includesNumpad)
        case "multi":
            var files: [String: URL] = [:]
            for (key, define) in config.defines {
                if case let .file(name) = define {
                    files[key] = directory.appendingPathComponent(name)
                }
            }
            return SoundPack(id: id, name: config.name, directory: directory,
                             kind: .multi(files: files), includesNumpad: includesNumpad)
        default:
            return nil
        }
    }

    static func userSoundPacksDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        let dir = base.appendingPathComponent(appSupportDirectoryName, isDirectory: true)
            .appendingPathComponent(soundPacksFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func bundleSearchPaths() -> [URL] {
        var paths: [URL] = []
        if let resourceURL = Bundle.main.resourceURL {
            paths.append(resourceURL.appendingPathComponent(soundPacksFolderName, isDirectory: true))
        }
        if let bundledPath = Bundle.main.url(forResource: soundPacksFolderName, withExtension: nil) {
            paths.append(bundledPath)
        }
        return paths
    }

    private static func childDirectories(of url: URL) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
    }
}
