#!/usr/bin/env python3
"""Synthesize an original basketball net "swish" (no source recording, so no license needed).

Physics: the ball rubs through a nylon net for ~0.1-0.2 s. That is broadband friction noise, strongest in the
2-8 kHz range, whose band slides down as the ball slows and the net opens ("shhhw"), plus many tiny snaps where
strings slip over the ball (the soft rattle), then the net swings back with a quieter, darker tail.
Built from: band-passed white noise with a falling centre frequency, random short noise "ticks" in the first
200 ms, and a low-passed tail. Quick attack, ~0.45 s total. Needs numpy and ffmpeg (libvorbis).

    python3 tools/make_swish.py assets/sfx/swish.ogg
"""
import subprocess
import sys

import numpy as np

SR = 44100
LENGTH = 0.48          # seconds
F_START = 5600.0       # band centre at the start of the swish (Hz)
F_END = 2600.0         # band centre at the end
Q = 0.9                # band-pass width (low Q = wide, airy)
TICKS = 26             # string snaps in the rattle
TICK_SPAN = 0.20       # seconds the rattle lasts
TICK_DB = -9.0         # rattle level relative to the swish body
TARGET_MEAN_DB = -23.5  # loudness matched to the old stand-in (ffmpeg volumedetect mean), so the game mix stays
PEAK = 0.93            # about -0.6 dB


def bandpass(x, fc, q):
    """RBJ band-pass biquad (constant 0 dB peak gain) with a per-sample centre frequency fc (array)."""
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for n in range(len(x)):
        w0 = 2 * np.pi * fc[n] / SR
        alpha = np.sin(w0) / (2 * q)
        a0 = 1 + alpha
        b0, b2 = alpha / a0, -alpha / a0
        a1, a2 = -2 * np.cos(w0) / a0, (1 - alpha) / a0
        yn = b0 * x[n] + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1 = x1, x[n]
        y2, y1 = y1, yn
        y[n] = yn
    return y


def onepole_lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for n in range(len(x)):
        acc = (1 - a) * x[n] + a * acc
        y[n] = acc
    return y


def synth(seed=11):
    rng = np.random.default_rng(seed)
    n = int(SR * LENGTH)
    t = np.arange(n) / SR
    # body: falling band of noise
    fc = F_END + (F_START - F_END) * np.exp(-t / 0.09)
    body = bandpass(rng.standard_normal(n), fc, Q)
    env = np.minimum(1.0, t / 0.012) * np.exp(-np.maximum(t - 0.05, 0.0) / 0.075)
    body *= env
    # rattle: short high ticks (strings snapping over the ball), denser early
    rattle = np.zeros(n)
    for _ in range(TICKS):
        t0 = TICK_SPAN * rng.random() ** 1.6
        i0 = int(t0 * SR)
        ln = int(SR * rng.uniform(0.0015, 0.004))
        if i0 + ln >= n:
            continue
        g = rng.standard_normal(ln) * np.hanning(ln) * rng.uniform(0.4, 1.0)
        rattle[i0:i0 + ln] += g
    rattle = bandpass(rattle, np.full(n, 4200.0), 1.4)
    rattle *= 10 ** (TICK_DB / 20) * np.max(np.abs(body)) / max(np.max(np.abs(rattle)), 1e-9)
    # tail: the net swinging back, darker and quieter
    tail = onepole_lp(rng.standard_normal(n), 1800.0)
    tail *= 0.16 * np.exp(-np.maximum(t - 0.12, 0.0) / 0.12) * np.minimum(1.0, np.maximum(t - 0.06, 0.0) / 0.06)
    tail = tail - onepole_lp(tail, 300.0)  # no rumble
    y = body + rattle + tail * np.max(np.abs(body)) / max(np.max(np.abs(tail)), 1e-9) * 0.35
    fade = np.minimum(1.0, (LENGTH - t) / 0.06)
    return y * fade


def level(y):
    """Scale to the target mean loudness (dB over the whole file, like ffmpeg volumedetect), peak-limited."""
    mean_db = 10 * np.log10(np.mean(y * y) + 1e-20)
    y = y * 10 ** ((TARGET_MEAN_DB - mean_db) / 20)
    pk = np.max(np.abs(y))
    return y * (PEAK / pk) if pk > PEAK else y


def write_ogg(y, out):
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", "4", out]
    subprocess.run(cmd, input=y.astype(np.float32).tobytes(), check=True)


def main(out):
    write_ogg(level(synth()), out)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/sfx/swish.ogg")
