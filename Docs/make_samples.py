#!/usr/bin/env python3
"""Generate calm, botanical placeholder images for Resources/SampleImages/.

These are procedural stand-ins so the whole Scan -> detect -> overlay flow can
run in the iOS Simulator on bundled images before the author photographs real
plants. Pure Python stdlib (zlib + struct) writes 8-bit truecolour PNGs, so no
image libraries are required in this build environment.

Each image draws a stem with a few *nodes* (the junctions the anatomy model is
trained to find) and leaves branching from them, so the placeholder actually
resembles the anatomy the Cut & Trim guide reasons about.
"""
import math
import struct
import zlib

W = H = 720


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def clamp8(v):
    return 0 if v < 0 else 255 if v > 255 else int(v)


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        # RGB buffer
        self.px = bytearray(w * h * 3)

    def set(self, x, y, rgb):
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y * self.w + x) * 3
            self.px[i] = clamp8(rgb[0])
            self.px[i + 1] = clamp8(rgb[1])
            self.px[i + 2] = clamp8(rgb[2])

    def blend(self, x, y, rgb, a):
        """Alpha-composite rgb over the existing pixel (a in 0..1)."""
        if not (0 <= x < self.w and 0 <= y < self.h):
            return
        i = (y * self.w + x) * 3
        for k in range(3):
            base = self.px[i + k]
            self.px[i + k] = clamp8(base + (rgb[k] - base) * a)

    def png_bytes(self):
        # filter byte (0 = none) prefix per scanline
        raw = bytearray()
        stride = self.w * 3
        for y in range(self.h):
            raw.append(0)
            start = y * stride
            raw.extend(self.px[start:start + stride])
        compressed = zlib.compress(bytes(raw), 9)

        def chunk(tag, data):
            out = struct.pack(">I", len(data)) + tag + data
            crc = zlib.crc32(tag + data) & 0xFFFFFFFF
            return out + struct.pack(">I", crc)

        sig = b"\x89PNG\r\n\x1a\n"
        ihdr = struct.pack(">IIBBBBB", self.w, self.h, 8, 2, 0, 0, 0)
        return sig + chunk(b"IHDR", ihdr) + chunk(b"IDAT", compressed) + chunk(b"IEND", b"")


def draw_leaf(c, cx, cy, angle_deg, length, width, color):
    """Draw a soft rotated-ellipse leaf with a faint central vein."""
    ang = math.radians(angle_deg)
    ca, sa = math.cos(ang), math.sin(ang)
    a2, b2 = (length / 2) ** 2, (width / 2) ** 2
    vein = lerp(color, (255, 255, 255), 0.28)
    for dy in range(-length, length + 1):
        for dx in range(-length, length + 1):
            # rotate the sample point into the leaf's local frame
            lx = dx * ca + dy * sa
            ly = -dx * sa + dy * ca
            d = (lx * lx) / a2 + (ly * ly) / b2
            if d <= 1.0:
                # soft edge feather
                edge = max(0.0, 1.0 - d)
                a = min(1.0, 0.35 + edge * 0.9)
                shade = 0.82 + 0.18 * (1.0 - abs(ly) / (width / 2 + 1))
                col = tuple(int(color[k] * shade) for k in range(3))
                c.blend(cx + dx, cy + dy, col, a)
                if abs(ly) < 2.2 and lx > -length * 0.42:
                    c.blend(cx + dx, cy + dy, vein, 0.5)


def draw_disc(c, cx, cy, r, color, a=1.0):
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            if dx * dx + dy * dy <= r * r:
                edge = 1.0 - (dx * dx + dy * dy) / (r * r + 1)
                c.blend(cx + dx, cy + dy, color, min(1.0, a * (0.5 + edge)))


def make(path, leaf_color, stem_color, node_color, top_bg, bot_bg,
         leaf_len, leaf_wid, nodes):
    c = Canvas(W, H)
    # vertical gradient background with a gentle centre glow
    for y in range(H):
        t = y / H
        row = lerp(top_bg, bot_bg, t)
        for x in range(W):
            vig = 1.0 - 0.10 * (abs(x - W / 2) / (W / 2))
            c.set(x, y, tuple(int(row[k] * vig) for k in range(3)))

    cx = W // 2
    # main stem
    for y in range(int(H * 0.22), int(H * 0.86)):
        sway = int(14 * math.sin(y / 90.0))
        for w in range(-6, 7):
            a = 1.0 - abs(w) / 8.0
            c.blend(cx + sway + w, y, stem_color, max(0.0, a))

    # nodes + alternating leaves (this is the anatomy the model localises)
    side = 1
    for ny in nodes:
        sway = int(14 * math.sin(ny / 90.0))
        nx = cx + sway
        draw_leaf(c, nx + side * int(leaf_len * 0.42), ny - 18,
                  35 * side, leaf_len, leaf_wid, leaf_color)
        draw_disc(c, nx, ny, 9, node_color, 0.9)
        side *= -1

    # a growth tip at the top
    draw_leaf(c, cx + int(14 * math.sin((H * 0.22) / 90.0)), int(H * 0.20),
              0, int(leaf_len * 0.7), int(leaf_wid * 0.7), leaf_color)

    with open(path, "wb") as f:
        f.write(c.png_bytes())
    print("wrote", path)


BASE = "/home/user/CuttingsToGrow/CuttingsToGrow/Resources/SampleImages"

# Distinct palettes per species so the four cards read as intentional.
make(f"{BASE}/pothos.png",
     leaf_color=(96, 156, 74), stem_color=(120, 140, 92),
     node_color=(210, 196, 120), top_bg=(244, 241, 230), bot_bg=(214, 226, 200),
     leaf_len=150, leaf_wid=104, nodes=[560, 470, 380, 300])

make(f"{BASE}/monstera.png",
     leaf_color=(52, 110, 66), stem_color=(96, 120, 80), node_color=(190, 200, 150),
     top_bg=(238, 238, 228), bot_bg=(196, 214, 188),
     leaf_len=196, leaf_wid=150, nodes=[560, 430, 320])

make(f"{BASE}/philodendron.png",
     leaf_color=(70, 132, 78), stem_color=(104, 128, 84), node_color=(198, 190, 132),
     top_bg=(243, 240, 231), bot_bg=(205, 221, 196),
     leaf_len=150, leaf_wid=132, nodes=[566, 476, 386, 300])

make(f"{BASE}/basil.png",
     leaf_color=(104, 170, 78), stem_color=(126, 150, 96), node_color=(200, 206, 150),
     top_bg=(246, 244, 234), bot_bg=(219, 231, 203),
     leaf_len=120, leaf_wid=92, nodes=[576, 500, 424, 348, 280])

print("done")
