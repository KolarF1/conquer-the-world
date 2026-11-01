#!/usr/bin/env python3
"""The experience's store thumbnails: real gameplay screenshots, cropped to 16:9, with a short caption.

Usage: python tools/assets/make_thumbnails.py <world> <front> <draft> <warroom> [--out assets/branding/thumbnails]
Each argument is a screenshot from Studio. Writes 1920x1080 PNGs.
"""
import argparse
import glob
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

TEAL = (61, 224, 206)
WHITE = (255, 255, 255)
SIZE = (1920, 1080)


def font(weight, px):
    roots = glob.glob(os.path.expandvars(r"%LOCALAPPDATA%\Roblox\Versions\*\content\fonts\Montserrat-" + weight + ".ttf"))
    roots += glob.glob(os.path.expandvars(r"%LOCALAPPDATA%\Roblox Studio\**\Montserrat-" + weight + ".ttf"), recursive=True)
    if not roots:
        raise SystemExit("Montserrat-" + weight + ".ttf not found in the Studio install")
    return ImageFont.truetype(roots[0], px)


def crop_16_9(im, left=None, top=None):
    w, h = im.size
    if w / h > 16 / 9:
        nw = int(h * 16 / 9)
        x = (w - nw) // 2 if left is None else left
        im = im.crop((x, 0, x + nw, h))
    else:
        nh = int(w * 9 / 16)
        y = (h - nh) // 2 if top is None else top
        im = im.crop((0, y, w, y + nh))
    return im.resize(SIZE, Image.LANCZOS).convert("RGBA")


def shade(im, box, strength=215, direction="up", span=None):
    """A dark gradient, so a caption reads on anything."""
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    layer = Image.new("L", (w, h), 0)
    px = layer.load()
    for j in range(h):
        for i in range(w):
            if direction == "up":
                f = j / h
            else:
                f = 1 - i / w
            px[i, j] = int(strength * min(f * 1.5, 1.0))
    black = Image.new("RGBA", (w, h), (4, 12, 18, 255))
    im.paste(black, (x0, y0), layer)


def text(im, xy, s, f, fill=WHITE, anchor="la", spacing=0):
    """Text with a soft shadow; `spacing` adds letter spacing."""
    shadow = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(shadow)
    main = Image.new("RGBA", im.size, (0, 0, 0, 0))
    m = ImageDraw.Draw(main)
    width = sum(f.getlength(c) + spacing for c in s) - spacing
    x, y = xy
    if anchor[0] == "m":
        x -= width / 2
    for c in s:
        d.text((x + 3, y + 5), c, font=f, fill=(0, 0, 0, 230))
        m.text((x, y), c, font=f, fill=fill)
        x += f.getlength(c) + spacing
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    im.alpha_composite(shadow)
    im.alpha_composite(main)


def caption(im, title, sub):
    shade(im, (0, 730, 1920, 1080))
    text(im, (960, 815), title, font("Black", 104), anchor="ma", spacing=4)
    text(im, (960, 945), sub, font("Bold", 46), fill=TEAL, anchor="ma")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("world")
    ap.add_argument("front")
    ap.add_argument("draft")
    ap.add_argument("warroom")
    ap.add_argument("--out", default="assets/branding/thumbnails")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    im = crop_16_9(Image.open(a.world))
    caption(im, "CONQUER THE WORLD", "Real-time strategy. One map. Every nation for itself.")
    im.convert("RGB").save(os.path.join(a.out, "1_world.png"))

    im = crop_16_9(Image.open(a.front))
    caption(im, "BUILD. EXPAND. INVADE.", "Cities, ports, railways, warships and missile silos")
    im.convert("RGB").save(os.path.join(a.out, "2_front.png"))

    im = crop_16_9(Image.open(a.draft))
    caption(im, "DRAFT YOUR DOCTRINE", "24 doctrines, 6 edicts: no two wars play the same")
    im.convert("RGB").save(os.path.join(a.out, "3_draft.png"))

    im = crop_16_9(Image.open(a.warroom), left=0)
    shade(im, (0, 0, 660, 1080), strength=255, direction="right")
    text(im, (40, 370), "WAR", font("Black", 118), spacing=3)
    text(im, (40, 490), "ROOM", font("Black", 118), spacing=3)
    text(im, (44, 640), "24 missions", font("Bold", 50), fill=TEAL)
    text(im, (44, 705), "72 stars to earn", font("Bold", 50), fill=TEAL)
    im.convert("RGB").save(os.path.join(a.out, "4_warroom.png"))
    print("written to", a.out)


main()
