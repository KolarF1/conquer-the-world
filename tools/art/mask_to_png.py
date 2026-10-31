"""mask (u32 w, u32 h, then w*h coverage bytes) -> PNG: white glyphs on a dark slate ground.
usage: python tools/art/mask_to_png.py build/art_icons.mask"""
import struct, sys
from PIL import Image
src = sys.argv[1]
raw = open(src, "rb").read()
w, h = struct.unpack("<II", raw[:8])
m = Image.frombytes("L", (w, h), raw[8:])
bg = Image.new("RGB", (w, h), (18, 28, 32))
fg = Image.new("RGB", (w, h), (236, 244, 242))
out = Image.composite(fg, bg, m)
out.save(src[:-5] + ".png")
print("wrote", src[:-5] + ".png", w, h)
