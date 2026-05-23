# Clacky

An open-source, native Swift macOS app that plays mechanical keyboard sounds as you type — a free, open alternative to [Klack](https://tryklack.com).

- Native SwiftUI menu-bar app, no Electron
- Five [Mechvibes](https://github.com/hainguyents13/mechvibes) sound packs bundled out of the box (Cherry MX Blue / Brown / Black / Red, Topre Purple Hybrid)
- Drop-in support for any other community Mechvibes pack — including `.ogg` packs (decoded natively via CoreAudio)
- Low-latency polyphonic audio (`AVAudioEngine`, 16-voice pool)
- Per-keystroke gain & pitch jitter for natural variation
- Launch at login, global keystroke listener (Accessibility-permission-based, listen-only)
- macOS 14 (Sonoma) and later, Apple Silicon & Intel

> Clacky never records, transmits, or stores your keystrokes. The event tap only reads the key code so the engine knows which sound to play.

## Requirements

- macOS 14 Sonoma or later
- Xcode 15 or later (Xcode 16+ recommended)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — generates the `.xcodeproj` from `project.yml`

## Building

```bash
# 1. Install XcodeGen (one time)
brew install xcodegen

# 2. Generate the Xcode project
xcodegen generate

# 3. Open in Xcode and Run, or build from CLI:
xcodebuild -project Clacky.xcodeproj -scheme Clacky -configuration Debug build
```

On first launch, Clacky asks for Accessibility access. Open **System Settings → Privacy & Security → Accessibility** and toggle Clacky on. The menu-bar icon goes active as soon as the permission flips.

## Sound packs

Clacky reads Mechvibes packs unmodified. A pack is a directory containing:

```
my-pack/
  config.json       # the Mechvibes manifest
  sound.ogg         # sprite mode: master file
  # or: individual per-key files for multi mode
```

Pack discovery looks in two places:

1. The app bundle's `Resources/SoundPacks/` — five bundled Mechvibes packs ship here (see [SOUNDPACKS.md](SOUNDPACKS.md)).
2. `~/Library/Application Support/Clacky/SoundPacks/` — drop community packs here. They appear in the menu bar after **Reload Packs** or a relaunch.

`.ogg` packs work as-is — CoreAudio on macOS 14+ decodes Ogg Vorbis natively, so the original Mechvibes packs play without conversion.

Browse community packs at [github.com/hainguyents13/mechvibes](https://github.com/hainguyents13/mechvibes) (the upstream pack collection) and on the Mechvibes community archive.

To refresh the bundled set from upstream Mechvibes:

```bash
bash scripts/fetch_default_packs.sh
```

## Pack format

See [SoundPack.swift](Clacky/Core/SoundPack.swift) for the full schema. Two flavors:

- **Sprite (`key_define_type: "single"`)** — one master audio file plus `[startMs, durationMs]` slices per key.
- **Per-file (`key_define_type: "multi"`)** — one audio file per key.

Keys are Mechvibes/iohook scancodes (e.g., `30` = A, `57` = Space, `57416` = Up arrow). Clacky translates macOS virtual key codes to these at lookup time via [`KeycodeMap`](Clacky/Core/KeycodeMap.swift).

## Project layout

```
Clacky/
  ClackyApp.swift              # @main, MenuBarExtra + Settings scene
  Info.plist, *.entitlements
  Assets.xcassets/
  Resources/SoundPacks/        # five bundled Mechvibes packs
  Core/
    AppController.swift        # top-level coordinator
    KeyEventListener.swift     # CGEventTap wrapper
    AudioEngine.swift          # AVAudioEngine voice pool
    SoundPack.swift            # Mechvibes-compatible models
    SoundPackLoader.swift      # bundle + Application Support discovery
    KeycodeMap.swift           # CGKeyCode ↔ Mechvibes/iohook table
    Preferences.swift          # @Observable, UserDefaults-backed
  Permissions/AccessibilityPermissions.swift
  System/LaunchAtLogin.swift
  UI/
    MenuBarContent.swift
    SettingsView.swift
    PermissionsView.swift
ClackyTests/
  KeycodeMapTests.swift
  SoundPackLoaderTests.swift
scripts/
  fetch_default_packs.sh       # downloads bundled Mechvibes packs from upstream
project.yml                    # XcodeGen project spec
SOUNDPACKS.md                  # attribution for bundled packs
```

## Tests

```bash
xcodebuild test -project Clacky.xcodeproj -scheme Clacky -destination 'platform=macOS'
```

## Releasing

Tag-driven, fully automated on GitHub Actions — see [RELEASE.md](RELEASE.md).
TL;DR: `make bump-patch && git tag vX.Y.Z && git push --tags`.

## Contributing

Issues and PRs welcome. Please:

- Run `xcodegen generate` before opening any PR that touches the project structure
- Run the test suite locally
- Keep PRs focused — one concern per PR

## License

MIT — see [LICENSE](LICENSE).

## Credits

- Pack format compatibility, bundled sound packs, and community library: [Mechvibes](https://github.com/hainguyents13/mechvibes) (MIT)
- Inspiration: [Klack](https://tryklack.com)
