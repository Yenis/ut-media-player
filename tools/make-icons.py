#!/usr/bin/env python3
"""Draws the app icon: a cut gem with a faceted play triangle.

Writes assets/icon-512.png and assets/icon.png (256 px). Needs Pillow.
Run from the project folder: tools/make-icons.py
"""
import math
import os
from PIL import Image, ImageChops, ImageDraw

S = 4                      # drawn at four times the size, then scaled down
N = 512 * S
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'assets')

BG = (7, 7, 12)
AMBER = (232, 163, 23)
LIGHT = (255, 214, 110)
DEEP = (176, 104, 8)
C = (256, 256)


def P(pts):
    return [(x * S, y * S) for x, y in pts]


def hexpts(r):
    return [(C[0] + r * math.sin(math.radians(60 * i)),
             C[1] - r * math.cos(math.radians(60 * i))) for i in range(6)]


def mask(draw_fn):
    m = Image.new('L', (N, N), 0)
    draw_fn(ImageDraw.Draw(m))
    return m


def poly(pts, fill=255):
    return mask(lambda d: d.polygon(P(pts), fill=fill))


def solid(col):
    return Image.new('RGB', (N, N), col)


def grad(c1, c2):
    """c1 at the top left to c2 at the bottom right."""
    B = int(N * 1.5)
    g = Image.linear_gradient('L').resize((B, B), Image.BICUBIC).rotate(45, Image.BICUBIC)
    o = (B - N) // 2
    g = g.crop((o, o, o + N, o + N))
    a, b = 255 * 0.22, 255 * 0.78
    g = g.point(lambda v: max(0, min(255, int((v - a) * 255 / (b - a)))))
    return Image.composite(solid(c2), solid(c1), g)


im = solid(BG)

# The stone: six facets between the outline and an inner hexagon, lit from
# the top left.
outer, inner = hexpts(176), hexpts(118)
shades = [(44, 36, 22), (30, 27, 24), (20, 19, 24), (14, 14, 20), (22, 20, 23), (36, 31, 23)]
for i in range(6):
    j = (i + 1) % 6
    im.paste(solid(shades[i]), (0, 0), poly([outer[i], outer[j], inner[j], inner[i]]))
im.paste(solid((19, 19, 26)), (0, 0), poly(inner))


def facet_lines(d):
    for i in range(6):
        d.line(P([outer[i], inner[i]]), fill=150, width=3 * S)
    d.line(P(inner + [inner[0]]), fill=150, width=3 * S)


im.paste(solid(DEEP), (0, 0), mask(facet_lines))

# The outline.
ring = ImageChops.subtract(poly(hexpts(194)), poly(hexpts(176)))
im.paste(grad(LIGHT, AMBER), (0, 0), ring)

# The play triangle, cut into three facets around its centre.
tri = [(210, 190), (210, 322), (330, 256)]
centre = (sum(p[0] for p in tri) / 3.0, 256)
for col, pts in (((255, 206, 92), [tri[0], tri[2], centre]),
                 (AMBER, [tri[0], tri[1], centre]),
                 ((184, 112, 10), [tri[1], tri[2], centre])):
    im.paste(solid(col), (0, 0), poly(pts))

out = im.convert('RGBA')
out.putalpha(mask(lambda d: d.rounded_rectangle([0, 0, N - 1, N - 1], radius=104 * S, fill=255)))
out.resize((512, 512), Image.LANCZOS).save(os.path.join(OUT, 'icon-512.png'))
out.resize((256, 256), Image.LANCZOS).save(os.path.join(OUT, 'icon.png'))
