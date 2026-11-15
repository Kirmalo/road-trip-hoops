#!/usr/bin/env python3
"""Synthesize an original referee-style pea whistle (no source recording, so no license needed).

A ~3 kHz tone whose pitch and loudness are wobbled ~28 times a second by the "pea", plus a little breath noise,
with a quick attack and release. Needs numpy and ffmpeg (libvorbis).

    python3 tools/make_whistle.py assets/sfx/whistle.ogg
"""
import subprocess
import sys
import numpy as np

SR = 44100
LENGTH = 0.65      # seconds
BASE_HZ = 3000.0   # whistle pitch
TRILL_HZ = 28.0    # pea rattle rate


def main(out):
    rng = np.random.default_rng(7)
    t = np.arange(int(SR * LENGTH)) / SR
    trill = np.sin(2 * np.pi * TRILL_HZ * t)
    freq = BASE_HZ * (1.0 + 0.035 * trill)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    tone = np.sin(phase) + 0.25 * np.sin(2 * phase)
    am = 0.75 + 0.25 * trill
    noise = rng.standard_normal(len(t))
    noise = np.convolve(noise, np.ones(8) / 8, mode="same") * 0.12
    env = np.minimum(1.0, t / 0.02) * np.minimum(1.0, (LENGTH - t) / 0.08)
    y = (tone * am + noise) * env
    y = y / np.max(np.abs(y)) * 0.89  # about -1 dB peak
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", "4", out]
    subprocess.run(cmd, input=y.astype(np.float32).tobytes(), check=True)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/sfx/whistle.ogg")
