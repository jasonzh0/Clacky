#!/usr/bin/env python3
"""Generate the shipped "default-click" sound pack.

We can't safely vendor third-party Mechvibes community packs without
case-by-case license review, so the app ships with a single synthesized
click that's good enough to verify everything works. Users install real
packs into ~/Library/Application Support/Clacky/SoundPacks/.

Output: Clacky/Resources/SoundPacks/default-click/{key.wav,config.json}
"""

from __future__ import annotations
import json
import math
import os
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACK_DIR = ROOT / "Clacky" / "Resources" / "SoundPacks" / "default-click"
SAMPLE_RATE = 44_100


def render_click(duration_ms: int = 60, seed: int = 0) -> bytes:
    """Synthesize a short, slightly noisy click — a punchy attack + quick decay."""
    rng = random.Random(seed)
    n_samples = int(SAMPLE_RATE * duration_ms / 1000)
    samples = []
    # Two-stage envelope: very fast attack, exponential decay.
    attack = max(1, int(SAMPLE_RATE * 0.0015))   # ~1.5 ms attack
    decay_tau = duration_ms / 1000 / 4            # decay time constant
    base_freq = 1800 + rng.uniform(-150, 150)
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Damped sine + a touch of pink-ish noise for body
        env = (i / attack) if i < attack else math.exp(-(t - attack / SAMPLE_RATE) / decay_tau)
        tone = math.sin(2 * math.pi * base_freq * t) * 0.5
        noise = (rng.random() * 2 - 1) * 0.35
        # Click "clack" with a quick high-freq snap layered in
        snap = math.sin(2 * math.pi * 5200 * t) * math.exp(-t / 0.004) * 0.4
        v = (tone + noise + snap) * env * 0.6
        v = max(-1.0, min(1.0, v))
        samples.append(int(v * 32767))
    return struct.pack("<%dh" % len(samples), *samples)


def write_wav(path: Path, pcm: bytes) -> None:
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(pcm)


def main() -> None:
    PACK_DIR.mkdir(parents=True, exist_ok=True)
    # Single "any-key" click; the AudioEngine falls back to this when the
    # struck key isn't present in `defines`.
    write_wav(PACK_DIR / "key.wav", render_click(60, seed=1))
    # A slightly thicker click for the space bar — gives some texture.
    write_wav(PACK_DIR / "space.wav", render_click(85, seed=2))

    config = {
        "id": "default-click",
        "name": "Default Click",
        "key_define_type": "multi",
        "includes_numpad": True,
        "defines": {
            # 57 = Space (Mechvibes/iohook code)
            "57": "space.wav",
            # Any other key falls through to the generic any-key clip via the
            # engine; we still list a few common ones so packs that look up by
            # specific code find something.
            "28": "key.wav",   # Enter
            "14": "key.wav",   # Backspace
            "any": "key.wav",  # Convention used by some packs as the fallback key
        },
    }
    (PACK_DIR / "config.json").write_text(json.dumps(config, indent=2))
    print(f"Wrote default pack to {PACK_DIR}")


if __name__ == "__main__":
    main()
