#!/usr/bin/env python3
"""Turn a downloaded music track into a seamless game loop (mono Ogg Vorbis, loudness matched).

Two jobs (the commands used for assets/music are in tools/make_music.sh):

  find   python3 tools/make_music.py find SRC --min 60 --max 120 [--from 4 --to 170]
         Prints the best loop (start, end in seconds): the two points where the music around them sounds the most
         alike (self-similarity of log-spectra over +-3 s), refined to the sample by waveform correlation.
  cut    python3 tools/make_music.py cut SRC OUT --start S --end E [--xfade 0.04] [--lufs -16] [--q 3]
         Keeps [S, E). The last XFADE seconds are crossfaded into the audio just before S, so jumping from the end
         back to the start (Godot's loop) continues the music without a click. Downmixes to mono, scales to the
         target loudness (EBU R128 integrated, measured by ffmpeg; peaks kept under -1 dBFS) and encodes Ogg Vorbis.
         --start 0 --end full uses the whole file (for tracks made to loop); then the crossfade uses the file's
         own first and last samples (a short equal-power blend of the wrap point).

Needs numpy and ffmpeg (libvorbis, ebur128). The source files stay outside the repo (see CREDITS.md for pages).
"""
import argparse
import re
import subprocess

import numpy as np

SR = 44100
HOP = 0.05       # seconds per feature frame (find)
WIN = 3.0        # seconds of music on each side of the loop points that must match (find)
PEAK = 10 ** (-1.0 / 20)


def decode(path, channels=1):
    cmd = ["ffmpeg", "-v", "error", "-i", path, "-ac", str(channels), "-ar", str(SR), "-f", "f32le", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).astype(np.float64)


def features(y):
    n = int(HOP * SR)
    nfft = 4096
    frames = (len(y) - nfft) // n
    win = np.hanning(nfft)
    edges = np.geomspace(60, 12000, 49)
    f = np.fft.rfftfreq(nfft, 1 / SR)
    idx = [(f >= a) & (f < b) for a, b in zip(edges[:-1], edges[1:])]
    F = np.zeros((frames, len(idx)))
    for k in range(frames):
        S = np.abs(np.fft.rfft(y[k * n:k * n + nfft] * win)) ** 2
        F[k] = [np.log(S[m].sum() + 1e-9) for m in idx]
    F -= F.mean(axis=1, keepdims=True)   # timbre shape, not loudness
    F /= np.linalg.norm(F, axis=1, keepdims=True) + 1e-9
    return F


def refine(y, s, e, search=0.03, win=0.12):
    """Shift e (samples) by up to +-search so the waveform after e matches the waveform after s."""
    w = int(win * SR)
    r = int(search * SR)
    a = y[s:s + w]
    best, best_d = -1e9, 0
    for d in range(-r, r + 1):
        b = y[e + d:e + d + w]
        if len(b) < w:
            continue
        c = float(a @ b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-12)
        if c > best:
            best, best_d = c, d
    return e + best_d, best


def find(args):
    y = decode(args.src)
    F = features(y)
    n = len(F)
    w = int(WIN / HOP)
    lo, hi = int(args.min / HOP), int(args.max / HOP)
    s_lo = max(w, int(args.from_ / HOP))
    e_hi = min(n - w, int(args.to / HOP)) if args.to else n - w
    best = []
    for lag in range(lo, hi + 1):
        s_idx = np.arange(s_lo, e_hi - lag)
        if len(s_idx) == 0:
            continue
        sim = (F[s_idx] * F[s_idx + lag]).sum(axis=1)
        full = np.full(n, np.nan)
        full[s_idx] = sim
        # mean similarity over +-WIN around the pair: cumulative sum over the valid run
        c = np.concatenate([[0.0], np.cumsum(np.nan_to_num(full))])
        if len(s_idx) <= 2 * w:
            continue
        ss = s_idx[w:-w]
        m = (c[ss + w + 1] - c[ss - w]) / (2 * w + 1)
        for k in np.argsort(m)[-3:]:   # the best few start points for this loop length
            best.append((float(m[k]), int(ss[k]), int(ss[k]) + lag))
    best.sort(reverse=True)
    shown = 0
    used = []
    for m, s, e in best:
        if any(abs(s - a) < w and abs(e - b) < w for a, b in used):
            continue
        used.append((s, e))
        ss, ee = int(s * HOP * SR), int(e * HOP * SR)
        ee2, corr = refine(y, ss, ee)
        print("similarity %.4f  start %.4f  end %.4f  length %.2f s  waveform corr %.3f"
              % (m, ss / SR, ee2 / SR, (ee2 - ss) / SR, corr))
        shown += 1
        if shown >= 5:
            break


def loudness(y):
    cmd = ["ffmpeg", "-v", "info", "-nostats", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-af", "ebur128", "-f", "null", "-"]
    out = subprocess.run(cmd, input=y.astype(np.float32).tobytes(), capture_output=True).stderr.decode()
    m = re.findall(r"I:\s+(-?[\d.]+) LUFS", out)
    return float(m[-1])


def cut(args):
    y = decode(args.src)
    s = int(round(args.start * SR))
    e = len(y) if args.end == "full" else int(round(float(args.end) * SR))
    xf = int(args.xfade * SR)
    out = y[s:e].copy()
    t = np.linspace(0.0, 1.0, xf)
    fin, fout = np.sin(t * np.pi / 2), np.cos(t * np.pi / 2)
    if s >= xf:
        # end of the loop fades into the music just before the loop start
        out[-xf:] = out[-xf:] * fout + y[s - xf:s] * fin
    else:
        # whole-file loop: blend the wrap point (last xf samples into the first xf)
        head, tail = out[:xf].copy(), out[-xf:].copy()
        out = out[:-xf]
        out[:xf] = tail * fout + head * fin
    lu = loudness(out)
    g = 10 ** ((args.lufs - lu) / 20)
    pk = np.max(np.abs(out)) * g
    if pk > PEAK:
        g *= PEAK / pk
    out *= g
    cmd = ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(SR), "-ac", "1", "-i", "-",
           "-c:a", "libvorbis", "-q:a", str(args.q), args.out]
    subprocess.run(cmd, input=out.astype(np.float32).tobytes(), check=True)
    jump = abs(out[-1] - out[0])
    print("%s: %.2f s, loudness %.1f -> %.1f LUFS, peak %.1f dBFS, wrap step %.4f"
          % (args.out, len(out) / SR, lu, lu + 20 * np.log10(g), 20 * np.log10(np.max(np.abs(out))), jump))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    f = sub.add_parser("find")
    f.add_argument("src")
    f.add_argument("--min", type=float, default=60)
    f.add_argument("--max", type=float, default=120)
    f.add_argument("--from", dest="from_", type=float, default=0.0)
    f.add_argument("--to", type=float, default=0.0)
    c = sub.add_parser("cut")
    c.add_argument("src")
    c.add_argument("out")
    c.add_argument("--start", type=float, default=0.0)
    c.add_argument("--end", default="full")
    c.add_argument("--xfade", type=float, default=0.04)
    c.add_argument("--lufs", type=float, default=-16.0)
    c.add_argument("--q", type=float, default=3)
    a = ap.parse_args()
    find(a) if a.cmd == "find" else cut(a)


if __name__ == "__main__":
    main()
