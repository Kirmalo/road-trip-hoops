#!/usr/bin/env python3
"""Turn a downloaded sound file into a short game sound effect.

Trims, optionally high-passes, converts to mono 44.1 kHz, peak-normalizes,
fades the ends (or crossfades them into a seamless loop) and writes Ogg Vorbis.
Needs ffmpeg (with libvorbis) and numpy. Example (the commands used for
assets/sfx are in tools/make_sfx.sh):

    python3 tools/make_sfx.py SOURCE.wav assets/sfx/rim.ogg --start 0.02 --end 0.70
"""
import argparse
import subprocess
import numpy as np

SR = 44100


def decode(path, highpass):
    af = ["-af", f"highpass=f={highpass},highpass=f={highpass}"] if highpass else []
    cmd = ["ffmpeg", "-v", "error", "-i", path] + af + ["-ac", "1", "-ar", str(SR), "-f", "f32le", "-"]
    return np.frombuffer(subprocess.run(cmd, capture_output=True, check=True).stdout, np.float32).astype(np.float64)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("out")
    ap.add_argument("--start", type=float, default=0.0, help="seconds")
    ap.add_argument("--end", type=float, default=None, help="seconds")
    ap.add_argument("--highpass", type=float, default=0.0, help="Hz, 0 = off")
    ap.add_argument("--fade-in", type=float, default=0.003, help="seconds")
    ap.add_argument("--fade-out", type=float, default=0.03, help="seconds")
    ap.add_argument("--loop", type=float, default=0.0,
                    help="crossfade this many seconds of the tail into the head for a seamless loop")
    ap.add_argument("--peak-db", type=float, default=-1.0)
    ap.add_argument("--quality", type=float, default=3.0, help="libvorbis -q:a")
    a = ap.parse_args()

    x = decode(a.src, a.highpass)
    s = int(a.start * SR)
    e = len(x) if a.end is None else min(len(x), int(a.end * SR))
    x = x[s:e].copy()

    if a.loop > 0:
        n = int(a.loop * SR)
        t = np.linspace(0.0, np.pi / 2, n)
        head, tail = x[:n], x[-n:]
        x = np.concatenate([tail * np.cos(t) + head * np.sin(t), x[n:-n]])
    else:
        fi, fo = int(a.fade_in * SR), int(a.fade_out * SR)
        if fi:
            x[:fi] *= np.linspace(0.0, 1.0, fi)
        if fo:
            x[-fo:] *= np.linspace(1.0, 0.0, fo)

    x -= x.mean()
    x *= (10 ** (a.peak_db / 20)) / max(np.abs(x).max(), 1e-9)
    enc = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", str(a.quality), "-map_metadata", "-1", a.out]
    subprocess.run(enc, input=x.astype(np.float32).tobytes(), check=True)
    print(f"{a.out}: {len(x) / SR:.2f} s")


if __name__ == "__main__":
    main()
