#!/usr/bin/env python3
"""Synthesize an original basketball bounce on a wood floor (no source recording, so no license needed).

Physics: the ball is on the floor for ~5-8 ms. The impact gives a short broadband click; the ball's rubber skin
and the pressurised air inside give a low "thump" whose pitch drops as the ball leaves the floor (the deformed
ball springs back and the contact patch shrinks); the hollow wood floor answers with a damped body resonance and
the ball's shell and air a short "ping". Built from: a softly saturated decaying sine sweeping 165 -> 95 Hz, three
damped wood modes (210, 440, 690 Hz), a ~1 kHz ping and a 3 ms low-passed noise click. ~0.25 s.
Needs numpy and ffmpeg (libvorbis).

    python3 tools/make_bounce.py assets/sfx/bounce.ogg
"""
import subprocess
import sys

import numpy as np

SR = 44100
LENGTH = 0.25             # seconds
THUMP_F0, THUMP_F1 = 165.0, 95.0   # thump pitch: start and end (Hz)
THUMP_DROP_S = 0.025      # time constant of the pitch drop
THUMP_DECAY_S = 0.045     # thump loudness decay time constant
THUMP_LEVEL = 0.5
WOOD_MODES = [(210.0, 0.050, 0.45), (440.0, 0.040, 0.75), (690.0, 0.025, 0.45)]   # floor modes: Hz, decay s, level
SHELL = (980.0, 0.035, 0.45)                                # ball shell/air ping: Hz, decay s, level
DRIVE = 1.8               # soft saturation of the thump: adds harmonics so small tablet speakers (which
                          # play little below ~250 Hz) still carry the bounce
CLICK_S = 0.003           # impact click length
CLICK_LEVEL = 0.5
TARGET_MEAN_DB = -19.5    # loudness matched to the old stand-in, so the -8 dB dribble stays as soft as before
PEAK = 0.89               # about -1 dB


def onepole_lp(x, fc):
    a = np.exp(-2 * np.pi * fc / SR)
    y = np.zeros_like(x)
    acc = 0.0
    for n in range(len(x)):
        acc = (1 - a) * x[n] + a * acc
        y[n] = acc
    return y


def synth(seed=5):
    rng = np.random.default_rng(seed)
    n = int(SR * LENGTH)
    t = np.arange(n) / SR
    attack = np.minimum(1.0, t / 0.0012)
    # thump with a pitch drop: integrate the falling frequency into a phase
    f = THUMP_F1 + (THUMP_F0 - THUMP_F1) * np.exp(-t / THUMP_DROP_S)
    phase = 2 * np.pi * np.cumsum(f) / SR
    thump = np.tanh(DRIVE * np.sin(phase)) / np.tanh(DRIVE) * np.exp(-t / THUMP_DECAY_S) * THUMP_LEVEL
    y = thump.copy()
    for hz, dec, lv in WOOD_MODES:
        y += lv * np.sin(2 * np.pi * hz * t + 0.3) * np.exp(-t / dec)
    hz, dec, lv = SHELL
    y += lv * np.sin(2 * np.pi * hz * t) * np.exp(-t / dec)
    # impact click: a few ms of noise, low-passed so it's a knock, not a hiss
    k = int(SR * CLICK_S)
    click = np.zeros(n)
    click[:k] = rng.standard_normal(k) * np.hanning(2 * k)[k:]
    click = onepole_lp(click, 3500.0)
    click *= CLICK_LEVEL / max(np.max(np.abs(click)), 1e-9)
    y = y * attack + click
    y -= onepole_lp(y, 40.0)  # remove DC / sub-rumble
    return y * np.minimum(1.0, (LENGTH - t) / 0.03)


def level(y):
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
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/sfx/bounce.ogg")
