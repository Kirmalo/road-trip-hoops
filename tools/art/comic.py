"""Comic-book drawing kit for the Road Trip Hoops story portraits (v2).

Everything is drawn procedurally at SS x the output resolution and box-filtered down, so edges come out smooth
(drawn, not pixel-snapped). Shapes are Catmull-Rom curves through hand-placed points; each part is filled with
hard-edged cel tones (base, shadow, halftone-dot or hatched deep shadow, crisp highlight) and inked with a
variable-weight line that is heavier on the side away from the light (upper left).

Original drawing code; no traced or downloaded art.
"""
import math

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SS = 4                                  # supersampling factor
SH = np.array([0.6, 0.8])               # shadow direction: light from the upper left
INK = (24, 16, 30)


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(a[i] * (1 - t) + b[i] * t for i in range(3))


def ramp(hexes):
    """4-tone game palette -> comic tones: hi (strong highlight), lt, base, sh (shadow), dp (deep)."""
    c = [hexc(h) for h in hexes]
    return {"hi": mix(c[0], (255, 255, 255), 0.35), "lt": c[0], "base": c[1], "sh": c[2], "dp": c[3]}


# ----------------------------------------------------------------------------- curves

def spline(pts, closed=True, step=0.25):
    """Catmull-Rom through pts; a point (x, y, 0) is a sharp corner. step is in output px."""
    P = [np.array(p[:2], float) for p in pts]
    corner = [len(p) > 2 and p[2] == 0 for p in pts]
    n = len(P)

    def tan(i):
        if corner[i]:
            return np.zeros(2)
        if closed:
            a, b = P[(i - 1) % n], P[(i + 1) % n]
        else:
            if i == 0 or i == n - 1:
                return np.zeros(2) if n < 3 else ((P[1] - P[0]) * 0.5 if i == 0 else (P[-1] - P[-2]) * 0.5)
            a, b = P[i - 1], P[i + 1]
        return (b - a) * 0.5

    out = []
    segs = n if closed else n - 1
    for i in range(segs):
        p0, p1 = P[i], P[(i + 1) % n]
        m0, m1 = tan(i), tan((i + 1) % n)
        L = np.linalg.norm(p1 - p0)
        k = max(2, int(L / step))
        for t in np.linspace(0, 1, k, endpoint=False):
            t2, t3 = t * t, t * t * t
            out.append((2 * t3 - 3 * t2 + 1) * p0 + (t3 - 2 * t2 + t) * m0 + (-2 * t3 + 3 * t2) * p1 + (t3 - t2) * m1)
    if not closed:
        out.append(P[-1])
    return np.array(out)


class Xf:
    """Local -> canvas transform: scale (sx, sy), rotate ang degrees (clockwise on screen), move to (cx, cy)."""

    def __init__(self, cx, cy, sx=1.0, sy=1.0, ang=0.0, pivot=(0.0, 0.0), front=0.0):
        self.cx, self.cy, self.sx, self.sy = cx, cy, sx, sy
        self.front = front      # local x > 0 is pushed out by up to front px (widens the face's front plane)
        a = math.radians(ang)
        self.c, self.s = math.cos(a), math.sin(a)
        self.px, self.py = pivot

    def __call__(self, pts):
        out = []
        for p in pts:
            lx = p[0] + self.front * min(1.0, max(0.0, p[0] / 60.0))
            x = (lx - self.px) * self.sx
            y = (p[1] - self.py) * self.sy
            q = (self.cx + self.px * self.sx + x * self.c - y * self.s,
                 self.cy + self.py * self.sy + x * self.s + y * self.c)
            out.append(q + tuple(p[2:]))
        return out

    def scale(self):
        return (self.sx + self.sy) * 0.5


# ----------------------------------------------------------------------------- canvas and masks

class Canvas:
    def __init__(self, w, h, zoom=1.0, anchor=(0.0, 0.0)):
        """zoom scales the whole drawing about anchor (output px): drawing coordinates stay the same."""
        self.w, self.h = w, h
        self.z, self.ax, self.ay = zoom, anchor[0], anchor[1]
        self.W, self.H = w * SS, h * SS
        self.rgb = np.zeros((self.H, self.W, 3), np.float32)
        self.a = np.zeros((self.H, self.W), bool)
        self.k = np.zeros((self.H, self.W), bool)       # pixels that are ink
        yy, xx = np.mgrid[0:self.H, 0:self.W].astype(np.float32)
        self.xx, self.yy = (xx + 0.5) / SS, (yy + 0.5) / SS
        self._dots = {}
        self.glows = []         # (mask, color) of flat glow parts, repainted after the rim (glow(), reglow())

    def X(self, x):
        return (self.ax + (x - self.ax) * self.z) * SS

    def Y(self, y):
        return (self.ay + (y - self.ay) * self.z) * SS

    def X(self, x):
        return (self.ax + (x - self.ax) * self.z) * SS

    def Y(self, y):
        return (self.ay + (y - self.ay) * self.z) * SS

    # masks -------------------------------------------------------------
    def empty(self):
        return np.zeros((self.H, self.W), bool)

    def poly(self, pts, closed=True):
        path = spline(pts, closed=True) if closed else np.array([p[:2] for p in pts], float)
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).polygon([(self.X(x), self.Y(y)) for x, y in path], fill=255)
        return np.array(im) > 127

    def ellipse(self, cx, cy, rx, ry):
        im = Image.new("L", (self.W, self.H), 0)
        ImageDraw.Draw(im).ellipse([self.X(cx) - rx * self.z * SS, self.Y(cy) - ry * self.z * SS,
                                      self.X(cx) + rx * self.z * SS, self.Y(cy) + ry * self.z * SS], fill=255)
        return np.array(im) > 127

    def line(self, pts, w, taper=(0.3, 0.3), w_end=None, closed=False, smooth=True):
        """A brush stroke along a curve: width w (px), tapered over the given fractions at each end."""
        path = spline(pts, closed=closed, step=0.2) if smooth else np.array([p[:2] for p in pts], float)
        seg = np.sqrt(((path[1:] - path[:-1]) ** 2).sum(1))
        s = np.concatenate([[0], np.cumsum(seg)])
        L = max(s[-1], 1e-6)
        im = Image.new("L", (self.W, self.H), 0)
        d = ImageDraw.Draw(im)
        ta, tb = taper
        for (x, y), si in zip(path, s):
            t = si / L
            f = 1.0
            if ta > 0:
                f = min(f, t / ta)
            if tb > 0:
                f = min(f, (1 - t) / tb)
            f = max(0.12, f) ** 0.6
            ww = w if w_end is None else w + (w_end - w) * t
            r = ww * 0.5 * f * SS * self.z
            X, Y = self.X(x), self.Y(y)
            d.ellipse([X - r, Y - r, X + r, Y + r], fill=255)
        return np.array(im) > 127

    def samp(self, M, dx, dy, fill=True):
        """N[p] = M[p + (dx, dy)] (px); outside the canvas reads as fill."""
        dx, dy = int(round(dx * SS * self.z)), int(round(dy * SS * self.z))
        h, w = M.shape
        out = np.full_like(M, fill)
        if abs(dx) >= w or abs(dy) >= h:
            return out
        out[max(0, -dy):min(h, h - dy), max(0, -dx):min(w, w - dx)] = \
            M[max(0, dy):min(h, h + dy), max(0, dx):min(w, w + dx)]
        return out

    def crescent(self, M, d, along=SH):
        """The part of M on the side away from the light, depth d px (form shadow)."""
        return M & ~self.samp(M, along[0] * d, along[1] * d)

    def sheen(self, M, inset, width, along=SH):
        """A band width px wide, inset px in from the lit edge (a crisp comic highlight)."""
        a = self.samp(M, -along[0] * inset, -along[1] * inset, fill=False)
        b = self.samp(M, -along[0] * (inset + width), -along[1] * (inset + width), fill=False)
        return M & a & ~b

    def band(self, M, r, lo=0.55, hi=1.45, dirs=36):
        """Ink outline outside M, r px nominal, thicker on the shadow side."""
        D = np.zeros_like(M)
        for k in range(dirs):
            a = 2 * math.pi * k / dirs
            d = np.array([math.cos(a), math.sin(a)])
            rr = r * (lo + (hi - lo) * max(0.0, float(d @ SH)) ** 0.8)
            for f in (1.0, 0.6, 0.3):
                D |= self.samp(M, -d[0] * rr * f, -d[1] * rr * f, fill=False)
        return D & ~M

    def soft(self, M, sigma):
        im = Image.fromarray((M * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(sigma * SS * self.z))
        return np.asarray(im, np.float32) / 255.0

    def dots(self, field, spacing=3.6, rmax=0.62, ang=40.0):
        """Halftone dots, radius growing with field (0..1)."""
        key = (spacing, ang)
        if key not in self._dots:
            a = math.radians(ang)
            u = (self.xx * math.cos(a) + self.yy * math.sin(a)) / spacing
            v = (-self.xx * math.sin(a) + self.yy * math.cos(a)) / spacing
            du, dv = u - np.round(u), v - np.round(v)
            self._dots[key] = np.sqrt(du * du + dv * dv)
        return self._dots[key] < rmax * np.sqrt(np.clip(field, 0, 1))

    def hatch(self, field, spacing=3.2, ang=-35.0, wmax=0.55):
        a = math.radians(ang)
        t = (self.xx * math.cos(a) + self.yy * math.sin(a)) / spacing
        fr = np.abs(t - np.round(t))
        return fr < 0.5 * wmax * np.clip(field, 0, 1)

    # paint ---------------------------------------------------------------
    def paint(self, M, col):
        self.rgb[M] = col
        self.a |= M
        self.k &= ~M

    def ink(self, M, col=INK):
        self.rgb[M] = col
        self.a |= M
        self.k |= M

    def rim(self, col, width=3.0, strength=0.6, along=(1.0, -0.15), keep=None):
        """A colored back light just inside the silhouette on the side away from the key light; ink stays."""
        n = math.hypot(*along)
        dx, dy = along[0] / n, along[1] / n
        inside = self.a & ~self.k
        far = ~self.samp(self.a, dx * width * 2.2, dy * width * 2.2, fill=True)
        R = inside & far

        if keep is not None:
            R &= keep
        self.rgb[R] = self.rgb[R] * (1 - strength) + np.array(col, np.float32) * strength

    def cel(self, M, tones, shadow=None, deep=None, hi=None, dots=True, dot_sp=3.4, ink=2.0, ink_lo=0.55,
            ink_hi=1.45, hatch=None, flat=None):
        """Fill a part with cel tones and ink its outline. shadow/deep/hi are masks (clipped to M);
        flat is extra shadow in the plain shadow tone (small shapes, no dots)."""
        self.paint(M, tones["base"])
        if shadow is not None:
            S = shadow & M
            self.rgb[S] = tones["sh"]
            if dots:
                f = self.soft(S, 3.0) * S
                f = np.clip((f - 0.35) / 0.65, 0, 1)
                self.rgb[self.dots(f, dot_sp) & S] = tones["dp"]
            if hatch is not None:
                f = self.soft(S, 2.5) * S
                self.rgb[self.hatch(np.clip((f - 0.3) * 1.6, 0, 1), **hatch) & S] = tones["dp"]
        if flat is not None:
            F = flat & M
            if shadow is not None:
                F &= ~shadow
            self.rgb[F] = tones["sh"]
        if deep is not None:
            self.rgb[deep & M] = tones["dp"]

        if hi is not None:
            self.rgb[hi & M] = tones["hi"]
        if ink:
            self.ink(self.band(M, ink, ink_lo, ink_hi))
        return M

    # Phase 12 (P12-15), opt-in: flat glow parts (the New Generation's cyber light). Nothing calls these unless a
    # portrait asks for a glow part, so every older portrait stays byte for byte the same.
    def glow(self, M, col):
        """Paint M in one flat, unshaded glow color and remember it, so reglow() can put it back over the rim light."""
        self.paint(M, col)
        self.glows.append((M, col))
        return M

    def reglow(self):
        for M, col in self.glows:
            self.rgb[M & ~self.k] = col

    def tint(self, field, col, keep=None):
        """Light of color col over the drawing, strength field (0..1 per pixel); ink and glow parts stay."""
        M = self.a & ~self.k
        if keep is not None:
            M &= keep
        for G, _ in self.glows:
            M &= ~G
        f = np.clip(field, 0, 1)[M][:, None]
        self.rgb[M] = self.rgb[M] * (1 - f) + np.array(col, np.float32) * f

    def image(self, out_scale=1):
        rgb = self.rgb * self.a[:, :, None]
        im = np.dstack([np.clip(rgb, 0, 255), self.a * 255.0]).astype(np.uint8)
        big = Image.fromarray(im, "RGBA")
        # premultiplied box filter down to the output size
        pre = big.convert("RGBa")
        small = pre.reduce(SS).convert("RGBA")
        return small
