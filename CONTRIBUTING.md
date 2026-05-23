# Contributing to Clacky

Thanks for considering a contribution. Clacky is small, native, and focused — keeping it that way is a goal in itself.

## Getting started

```bash
brew install xcodegen
xcodegen generate
open Clacky.xcodeproj
```

The `.xcodeproj` is **not** committed — it's generated reproducibly from `project.yml`. Re-run `xcodegen generate` whenever you change `project.yml` or add/remove top-level source files. (XcodeGen auto-discovers files under the directories listed in `project.yml > targets > Clacky > sources`, so most additions don't require a regen.)

## Code style

- Swift 5.10+, target macOS 14
- Prefer SwiftUI for new UI, AppKit only where SwiftUI lacks coverage (NSStatusItem alternatives, deep system integrations)
- `@Observable` over `ObservableObject`
- Avoid third-party dependencies — `Core/`, `UI/`, `System/`, `Permissions/` should all stay first-party
- Keep `AudioEngine` allocation-free in the per-keystroke hot path

## Sound packs

The currently-bundled packs come from the MIT-licensed upstream Mechvibes repository — see [SOUNDPACKS.md](SOUNDPACKS.md) for the list and `scripts/fetch_default_packs.sh` for the refresh script. If you'd like to propose bundling additional packs, please:

1. Identify the upstream source and its license
2. Confirm the license permits redistribution in an MIT-licensed app
3. Open an issue with the license details *before* opening a PR adding audio files

## Tests

Run via Xcode (⌘U) or:

```bash
xcodebuild test -project Clacky.xcodeproj -scheme Clacky -destination 'platform=macOS'
```

New `Core/` logic should come with unit tests where reasonable.

## Reporting bugs

Include:

- macOS version
- Apple Silicon vs Intel
- Sound pack you were using (and where it came from)
- Steps to reproduce, expected vs actual behavior
