#!/usr/bin/env python3
"""Synthesize the Phase 8 reward sounds (P8-04) and the match countdown (P8-31): original sounds made by script, no
source recordings.

    python3 tools/make_ui_sfx.py NAME OUT        NAME = star | stat_up | unlock | countdown | go
    python3 tools/make_ui_sfx.py all             writes all of them into assets/sfx/

- star:    a bright two-note bell chime (a fifth up) with a short sparkle on top: a star earned.
- stat_up: three quick rising soft-square blips (a major arpeggio) with a tiny pitch slide: a stat point spent.
- unlock:  a rising four-note arpeggio that lands on a ringing major chord with a shimmer: a reward unlocked.
- countdown: one short bright beep (soft square A5 with a bell ping on top): each of "3", "2", "1".
- go:        the same beep an octave up, longer, with a fifth under it and a short sparkle: "GO!".

Levels are matched to the UI "tap" (the screens play `bounce` at -8 dB): each sound's loudest 100 ms window has the
same RMS as bounce.ogg's loudest window minus 8 dB, so `audio.play("star")` at 0 dB sits at the tap's level. Peaks
stay under -1 dBFS. Mono 44.1 kHz Ogg Vorbis, every sound under 1 s. Needs numpy and ffmpeg (like
tools/make_twist_sfx.py).
"""
import subprocess
import sys

import numpy as np

SR = 44100
PEAK = 0.89                 # about -1 dB, never exceeded
TAP_REF = "assets/sfx/bounce.ogg"
TAP_DB = -8.0               # the UI tap: audio.play("bounce", -8.0)
WINDOW = 0.1                # seconds, for the loudness match


def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.minimum(1, t / attack) * np.exp(-t / decay)


def bell(freq, dur, decay, rng):
    """A small bell / glockenspiel tone: inharmonic partials, the high ones dying faster."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    y = np.zeros(n)
    for ratio, amp, dk in ((1.0, 1.0, 1.0), (2.0, 0.45, 0.6), (2.76, 0.30, 0.4), (5.40, 0.12, 0.25)):
        y += amp * np.sin(2 * np.pi * freq * ratio * t + rng.uniform(0, 6.28)) * np.exp(-t / (decay * dk))
    return y * np.minimum(1, t / 0.002)


def soft_square(freq, dur, rng, slide=0.0):
    """A rounded square wave (odd harmonics, rolled off) with an optional upward pitch slide in cents."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = freq * 2 ** (slide / 1200 * np.minimum(1, t / 0.03))
    ph = 2 * np.pi * np.cumsum(f) / SR + rng.uniform(0, 6.28)
    y = np.zeros(n)
    for k in (1, 3, 5, 7):
        y += np.sin(k * ph) / k ** 1.6
    return y


def place(y, at, ev):
    a = int(at * SR)
    end = min(len(y), a + len(ev))
    y[a:end] += ev[:end - a]


def sparkle(n, rng, start, count, lo, hi, amp):
    """Tiny high pings scattered after start (glitter on top of a chime)."""
    y = np.zeros(n)
    for _ in range(count):
        at = start + rng.exponential(0.12)
        if at * SR >= n - 10:
            continue
        place(y, at, bell(rng.uniform(lo, hi), 0.08, 0.02, rng) * rng.uniform(0.3, 1.0) * amp)
    return y


# ----------------------------------------------------------------------------- sounds

def star(seed=21):
    rng = np.random.default_rng(seed)
    n = int(0.70 * SR)
    y = np.zeros(n)
    place(y, 0.0, bell(note(88), 0.65, 0.22, rng) * 0.8)       # E6
    place(y, 0.09, bell(note(95), 0.60, 0.30, rng))            # B6, a fifth up
    y += sparkle(n, rng, 0.10, 14, 5000, 9000, 0.18)
    return y


def stat_up(seed=23):
    rng = np.random.default_rng(seed)
    n = int(0.40 * SR)
    y = np.zeros(n)
    for i, m in enumerate((72, 76, 79)):                       # C5 E5 G5
        d = 0.16 if i < 2 else 0.24
        ev = soft_square(note(m), d, rng, slide=40) * env(int(d * SR), 0.003, 0.05 if i < 2 else 0.08)
        ev += 0.3 * bell(note(m + 12), d, 0.04, rng)           # a little ping an octave up for clarity
        place(y, i * 0.065, ev * (0.8 + 0.1 * i))
    return y


def unlock(seed=29):
    rng = np.random.default_rng(seed)
    n = int(0.95 * SR)
    y = np.zeros(n)
    for i, m in enumerate((67, 72, 76, 79)):                   # G4 C5 E5 G5, quick arpeggio up
        d = 0.18
        ev = soft_square(note(m), d, rng) * env(int(d * SR), 0.003, 0.06) * 0.55
        ev += bell(note(m + 12), d, 0.06, rng) * 0.35
        place(y, i * 0.07, ev)
    at = 0.28                                                  # the chord: C6 E6 G6 C7 bells with a slow vibrato
    d = n / SR - at
    t = np.arange(int(d * SR)) / SR
    trem = 1 + 0.12 * np.sin(2 * np.pi * 7 * t)
    for m, a in ((84, 1.0), (88, 0.8), (91, 0.7), (96, 0.45)):
        place(y, at, bell(note(m), d, 0.32, rng) * a * trem)
    place(y, at, soft_square(note(60), d, rng) * env(int(d * SR), 0.01, 0.15) * 0.35)   # C4 body under it
    y += sparkle(n, rng, at, 22, 4500, 10000, 0.22)
    return y


def countdown(seed=31):
    rng = np.random.default_rng(seed)
    d = 0.16
    n = int(d * SR)
    y = soft_square(note(81), d, rng) * env(n, 0.002, 0.05)          # A5
    y += 0.35 * bell(note(93), d, 0.03, rng)                          # a ping an octave up for the attack
    return y


def go(seed=37):
    rng = np.random.default_rng(seed)
    d = 0.42
    n = int(d * SR)
    y = soft_square(note(93), d, rng, slide=30) * env(n, 0.003, 0.16)            # A6, a little pitch lift
    y += 0.5 * soft_square(note(86), d, rng) * env(n, 0.003, 0.12)              # E6 under it
    y += 0.4 * bell(note(105), d, 0.08, rng)
    y += sparkle(n, rng, 0.04, 8, 5000, 9000, 0.15)
    return y


SOUNDS = {"star": star, "stat_up": stat_up, "unlock": unlock, "countdown": countdown, "go": go}


def decode(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True, stdin=subprocess.DEVNULL).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def loudest_window_rms(y):
    w = int(WINDOW * SR)
    if len(y) <= w:
        return float(np.sqrt(np.mean(y ** 2)))
    c = np.concatenate([[0.0], np.cumsum(y ** 2)])
    return float(np.sqrt(np.max(c[w:] - c[:-w]) / w))


def db(x):
    return 20 * np.log10(max(x, 1e-12))


def write(name, out, target_db):
    y = SOUNDS[name]()
    y = y * np.minimum(1.0, (len(y) - np.arange(len(y))) / (0.03 * SR))     # end at silence
    y = y * 10 ** ((target_db - db(loudest_window_rms(y))) / 20)
    peak = np.max(np.abs(y))
    if peak > PEAK:
        print("  %s: peak limited (%.1f dB over -1 dBFS)" % (name, db(peak / PEAK)))
        y = y * PEAK / peak
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", "3", "-map_metadata", "-1", out]
    subprocess.run(cmd, input=y.astype(np.float32).tobytes(), check=True)
    print("%s: %.2f s, loudest %d ms RMS %.1f dBFS (target %.1f), peak %.1f dBFS"
          % (out, len(y) / SR, int(WINDOW * 1000), db(loudest_window_rms(y)), target_db, db(np.max(np.abs(y)))))


def main():
    target = db(loudest_window_rms(decode(TAP_REF))) + TAP_DB
    if len(sys.argv) > 1 and sys.argv[1] == "all":
        for name in SOUNDS:
            write(name, "assets/sfx/%s.ogg" % name, target)
    elif len(sys.argv) == 3:
        write(sys.argv[1], sys.argv[2], target)
    else:
        print(__doc__)
        sys.exit(1)


if __name__ == "__main__":
    main()
