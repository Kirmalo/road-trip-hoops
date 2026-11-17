#!/usr/bin/env python3
"""Synthesize the Phase 6 twist sounds (P6-A5): original sounds made by script, except crowd_loud, which layers the
project's CC-BY crowd loop (assets/sfx/crowd.ogg, credited in CREDITS.md) with a synthesized roar and claps.

    python3 tools/make_twist_sfx.py NAME OUT        NAME = rain | wind | crowd_loud | fence | splash | sand_step
    python3 tools/make_twist_sfx.py all             writes all six into assets/sfx/

Loops (rain, wind, crowd_loud) are built circularly: noise is shaped in the frequency domain of the whole loop (so it
wraps by construction), every slow change (gusts, swells) completes a whole number of cycles per loop, and every
event (drops, claps, layered crowd copies) wraps around the end. The last sample flows into the first with no
crossfade needed; the script prints the wrap step to check. One-shots get a fast attack and a decaying tail.
Everything is mono 44.1 kHz, peak-normalized to -1 dBFS (like tools/make_sfx.py), Ogg Vorbis. Needs numpy and ffmpeg.
"""
import subprocess
import sys

import numpy as np

SR = 44100
PEAK = 0.89          # about -1 dB


def shaped_noise(n, rng, shape):
    """Circular noise of n samples whose spectrum magnitude follows shape(freqs) (wraps seamlessly)."""
    X = np.fft.rfft(rng.standard_normal(n))
    f = np.fft.rfftfreq(n, 1 / SR)
    y = np.fft.irfft(X * shape(f), n)
    return y / (np.std(y) + 1e-12)


def band(lo, hi, slope=2.0):
    """A soft band-pass magnitude curve (Butterworth-like edges)."""
    def h(f):
        f = np.maximum(f, 1e-3)
        hp = 1 / np.sqrt(1 + (lo / f) ** (2 * slope)) if lo > 0 else 1.0
        lp = 1 / np.sqrt(1 + (f / hi) ** (2 * slope))
        return hp * lp
    return h


def periodic(n, terms, base=1.0):
    """A slow envelope that repeats exactly over n samples: base + sum(a * sin(2 pi k t / n + p))."""
    t = np.arange(n) / n
    return base + sum(a * np.sin(2 * np.pi * k * t + p) for k, a, p in terms)


def add_wrapped(y, start, ev):
    """Add event ev into loop y at start, wrapping past the end."""
    n = len(y)
    idx = (start + np.arange(len(ev))) % n
    np.add.at(y, idx, ev)


def ping(freq, dur, decay, rng=None):
    t = np.arange(int(dur * SR)) / SR
    return np.sin(2 * np.pi * freq * t + (rng.uniform(0, 6.28) if rng is not None else 0)) * np.exp(-t / decay)


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True, stdin=subprocess.DEVNULL).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


# ----------------------------------------------------------------------------- loops

def rain(seed=3, length=4.0):
    """Steady rain on a court: a soft hiss bed, a low patter rumble, and hundreds of small drop ticks."""
    rng = np.random.default_rng(seed)
    n = int(length * SR)
    hiss = shaped_noise(n, rng, band(500, 7000, 1.5)) * 0.35
    patter = shaped_noise(n, rng, band(120, 900, 2.0)) * 0.30
    y = hiss * periodic(n, [(3, 0.06, 0.4), (7, 0.04, 1.9)]) + patter
    for _ in range(int(220 * length)):                        # drops: tiny decaying ticks, a few louder ones
        f = rng.uniform(1800, 6500)
        amp = rng.uniform(0.05, 0.25) * (2.2 if rng.random() < 0.04 else 1.0)
        ev = ping(f, 0.012, 0.0025, rng) * amp
        ev += rng.standard_normal(len(ev)) * np.exp(-np.arange(len(ev)) / (0.0015 * SR)) * amp * 0.6
        add_wrapped(y, rng.integers(n), ev)
    return y


def wind(seed=5, length=8.0):
    """Gusty wind off the lake: a low roar, a breathy mid band and a faint whistle, swelling in gusts. Two noise
    bands with different gust curves give the feel of a moving pitch."""
    rng = np.random.default_rng(seed)
    n = int(length * SR)
    roar = shaped_noise(n, rng, band(40, 380, 2.0))
    mid = shaped_noise(n, rng, band(300, 1400, 1.5))
    high = shaped_noise(n, rng, band(900, 2600, 3.0))
    g1 = np.clip(periodic(n, [(1, 0.35, 0.2), (2, 0.25, 1.4), (5, 0.12, 2.7)], 0.65), 0.15, None)
    g2 = np.clip(periodic(n, [(1, 0.40, 2.2), (3, 0.22, 0.3), (4, 0.10, 1.0)], 0.45), 0.05, None)
    g3 = np.clip(periodic(n, [(2, 0.5, 0.9), (3, 0.3, 2.0)], 0.1), 0.0, None)
    return 0.9 * roar * g1 + 0.45 * mid * g2 + 0.18 * high * g3 ** 2


def crowd_loud(seed=9, src="assets/sfx/crowd.ogg"):
    """A packed old-school gym: the crowd loop (4.5 s, CC-BY) layered 4 times at far-apart circular offsets (a
    bigger crowd, no flanging), a synthesized low roar of many voices (vowel-like formant bands under a slow
    swell), and scattered hand claps and foot stomps. Same length as crowd.ogg."""
    rng = np.random.default_rng(seed)
    base = decode(src)
    n = len(base)
    base = base / (np.std(base) + 1e-12)
    y = np.zeros(n)
    for off, g in ((0.0, 1.0), (1.13, 0.8), (2.41, 0.75), (3.37, 0.7)):
        y += g * np.roll(base, int(off * SR))
    def vowels(f):
        f = np.maximum(f, 1e-3)
        return (np.exp(-((f - 450) / 220) ** 2) + 0.7 * np.exp(-((f - 1100) / 350) ** 2)
                + 0.35 * np.exp(-((f - 2600) / 600) ** 2)) * (1 / np.sqrt(1 + (90 / f) ** 4))
    roar = shaped_noise(n, rng, vowels) * periodic(n, [(1, 0.12, 0.5), (3, 0.08, 2.0)])
    y += 1.4 * roar
    for _ in range(int(30 * n / SR)):                         # claps: short bright noise bursts
        L = int(0.025 * SR)
        e = rng.standard_normal(L) * np.exp(-np.arange(L) / (0.004 * SR))
        e = np.convolve(e, np.array([1, -0.6]), mode="same")  # brighter
        add_wrapped(y, rng.integers(n), e * rng.uniform(0.3, 0.8))
    for _ in range(int(6 * n / SR)):                          # stomps on wooden bleachers: low thuds
        add_wrapped(y, rng.integers(n), ping(rng.uniform(70, 110), 0.15, 0.04, rng) * rng.uniform(0.8, 1.6))
    return y


# ----------------------------------------------------------------------------- one-shots

def fence(seed=13):
    """A ball hitting a chain-link fence: a dull panel thump, the panel shaking (amplitude wobble ~11 Hz), and a
    dense, decaying rattle of hundreds of small metallic link clicks."""
    rng = np.random.default_rng(seed)
    L = int(0.85 * SR)
    t = np.arange(L) / SR
    y = np.zeros(L)
    thump = np.sin(2 * np.pi * (95 - 30 * t) * t) * np.exp(-t / 0.06)
    y += 1.2 * thump
    shake = 0.55 + 0.45 * np.sin(2 * np.pi * 11 * t) ** 2
    for _ in range(420):                                      # link clicks, denser near the hit
        at = min(L - 1, int(rng.exponential(0.16) * SR))
        f = rng.uniform(2200, 7500)
        ev = ping(f, 0.01, 0.0018, rng) + 0.5 * rng.standard_normal(int(0.01 * SR)) * np.exp(
            -np.arange(int(0.01 * SR)) / (0.0012 * SR))
        end = min(L, at + len(ev))
        y[at:end] += ev[:end - at] * rng.uniform(0.15, 0.6) * shake[at]
    for f, d in ((1250, 0.18), (1870, 0.12), (2640, 0.09)):     # the wire ringing a little
        y += 0.10 * np.sin(2 * np.pi * f * t) * np.exp(-t / d)
    y *= np.minimum(1, t / 0.002)
    return y


def splash(seed=17):
    """A foot slapping a puddle: a wet noise burst whose band sweeps down, then a few droplet blips (rising
    sine chirps) falling back."""
    rng = np.random.default_rng(seed)
    L = int(0.45 * SR)
    t = np.arange(L) / SR
    burst = shaped_noise(L, rng, band(400, 5000, 1.5)) * np.exp(-t / 0.05) * np.minimum(1, t / 0.003)
    low = shaped_noise(L, rng, band(150, 900, 2.0)) * np.exp(-t / 0.08) * np.minimum(1, t / 0.004)
    y = 0.8 * burst + 0.6 * low
    for _ in range(9):                                        # droplets landing back
        at = int(rng.uniform(0.06, 0.32) * SR)
        d = int(rng.uniform(0.015, 0.035) * SR)
        tt = np.arange(d) / SR
        f0 = rng.uniform(500, 1100)
        ph = 2 * np.pi * np.cumsum(f0 * (1 + 6 * tt / tt[-1])) / SR
        ev = np.sin(ph) * np.exp(-tt / (d / SR / 3)) * rng.uniform(0.15, 0.4)
        end = min(L, at + d)
        y[at:end] += ev[:end - at]
    return y


def sand_step(seed=19):
    """A soft step in sand: a muffled low puff with a fine grainy crunch, quick attack, short tail."""
    rng = np.random.default_rng(seed)
    L = int(0.22 * SR)
    t = np.arange(L) / SR
    env = np.minimum(1, t / 0.008) * np.exp(-t / 0.045)
    puff = shaped_noise(L, rng, band(90, 700, 2.0)) * env
    grit = np.zeros(L)
    for _ in range(140):                                      # sand grains: tiny clicks under the envelope
        at = int(rng.uniform(0.0, 0.14) * SR)
        grit[at] += rng.uniform(-1, 1)
    grit = np.convolve(grit, np.exp(-np.arange(40) / 6.0), mode="same")
    grit = np.diff(grit, prepend=0.0) * env * 3.0             # high-passed, brighter crunch
    return 0.9 * puff + 0.35 * grit


SOUNDS = {"rain": (rain, True), "wind": (wind, True), "crowd_loud": (crowd_loud, True),
          "fence": (fence, False), "splash": (splash, False), "sand_step": (sand_step, False)}


def write(name, out):
    fn, loop = SOUNDS[name]
    y = fn()
    if not loop:
        y = y * np.minimum(1.0, (len(y) - np.arange(len(y))) / (0.03 * SR))   # end at silence
    y = y * PEAK / np.max(np.abs(y))
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", "3", "-map_metadata", "-1", out]
    subprocess.run(cmd, input=y.astype(np.float32).tobytes(), check=True)
    rms = 20 * np.log10(np.sqrt(np.mean(y ** 2)))
    extra = ""
    if loop:
        extra = ", wrap step %.4f (median step %.4f)" % (abs(y[-1] - y[0]), float(np.median(np.abs(np.diff(y)))))
    print("%s: %.2f s, RMS %.1f dBFS%s" % (out, len(y) / SR, rms, extra))


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "all":
        for name in SOUNDS:
            write(name, "assets/sfx/%s.ogg" % name)
    else:
        write(sys.argv[1], sys.argv[2])


if __name__ == "__main__":
    main()
