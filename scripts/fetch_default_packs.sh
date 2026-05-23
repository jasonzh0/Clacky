#!/usr/bin/env bash
# Download the official Mechvibes default sound packs and stage them in
# Clacky/Resources/SoundPacks/. Source is the upstream MIT-licensed
# Mechvibes repo: https://github.com/hainguyents13/mechvibes
#
# We don't mirror every upstream pack — bundle size matters. We pick a small
# representative set covering the main switch flavors. Users can drop any
# additional community pack into ~/Library/Application Support/Clacky/SoundPacks/.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/Clacky/Resources/SoundPacks"
UPSTREAM="https://raw.githubusercontent.com/hainguyents13/mechvibes/master/src/audio"

# pack_id display_name
PACKS=(
  "cherrymx-blue-pbt|Cherry MX Blue (PBT)"
  "cherrymx-brown-pbt|Cherry MX Brown (PBT)"
  "cherrymx-black-pbt|Cherry MX Black (PBT)"
  "cherrymx-red-pbt|Cherry MX Red (PBT)"
  "topre-purple-hybrid-pbt|Topre Purple Hybrid (PBT)"
)

mkdir -p "$DEST"

echo "Installing ${#PACKS[@]} packs into $DEST"

for entry in "${PACKS[@]}"; do
  IFS='|' read -r pack_id display_name <<< "$entry"
  pack_dir="$DEST/$pack_id"
  mkdir -p "$pack_dir"

  echo "  - $pack_id: fetching config.json"
  config_tmp="$(mktemp)"
  curl -fsSL "$UPSTREAM/$pack_id/config.json" -o "$config_tmp"

  echo "  - $pack_id: fetching sound.ogg"
  audio_tmp="$(mktemp)"
  curl -fsSL "$UPSTREAM/$pack_id/sound.ogg" -o "$audio_tmp"

  # Patch config: replace id and name with friendly values, preserve everything else.
  python3 - "$config_tmp" "$pack_id" "$display_name" <<'PY'
import json, sys
path, pack_id, name = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    cfg = json.load(f)
cfg["id"] = pack_id
cfg["name"] = name
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
PY

  mv "$config_tmp" "$pack_dir/config.json"
  mv "$audio_tmp" "$pack_dir/sound.ogg"
  size_kb=$(( $(stat -f%z "$pack_dir/sound.ogg") / 1024 ))
  echo "  - $pack_id: OK (${size_kb} KB)"
done

# Write attribution file
cat > "$ROOT/SOUNDPACKS.md" <<'EOF'
# Bundled sound packs — attribution

Clacky bundles a small set of sound packs from the upstream
[Mechvibes](https://github.com/hainguyents13/mechvibes) repository (MIT
licensed). They are vendored unmodified except that each `config.json` `id`
and `name` was normalized so the menu shows readable labels.

| Pack | Upstream path |
| --- | --- |
EOF
for entry in "${PACKS[@]}"; do
  IFS='|' read -r pack_id display_name <<< "$entry"
  echo "| $display_name | \`src/audio/$pack_id\` |" >> "$ROOT/SOUNDPACKS.md"
done
cat >> "$ROOT/SOUNDPACKS.md" <<'EOF'

Each pack is © its original contributor and distributed under the MIT
license of the Mechvibes repository. To install additional community packs,
drop them into `~/Library/Application Support/Clacky/SoundPacks/`.
EOF

echo "Done. See SOUNDPACKS.md for attribution."
