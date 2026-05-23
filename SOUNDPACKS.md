# Bundled sound packs — attribution

Clacky bundles a small set of sound packs from the upstream
[Mechvibes](https://github.com/hainguyents13/mechvibes) repository (MIT
licensed). They are vendored unmodified except that each `config.json` `id`
and `name` was normalized so the menu shows readable labels.

| Pack | Upstream path |
| --- | --- |
| Cherry MX Blue (PBT) | `src/audio/cherrymx-blue-pbt` |
| Cherry MX Brown (PBT) | `src/audio/cherrymx-brown-pbt` |
| Cherry MX Black (PBT) | `src/audio/cherrymx-black-pbt` |
| Cherry MX Red (PBT) | `src/audio/cherrymx-red-pbt` |
| Topre Purple Hybrid (PBT) | `src/audio/topre-purple-hybrid-pbt` |

Each pack is © its original contributor and distributed under the MIT
license of the Mechvibes repository. To install additional community packs,
drop them into `~/Library/Application Support/Clacky/SoundPacks/`.

The `default-click` pack is synthesized at build time by
`scripts/make_default_pack.py` and is original to this repository.
