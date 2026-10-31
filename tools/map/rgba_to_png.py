"""rgba -> PNGs: full size, the real fit scale of a phone viewport (nearest, as Roblox draws it), a 1:1 crop.
usage: python tools/map/rgba_to_png.py build/map_europe.rgba [crop_x crop_y]"""
import struct, sys
from PIL import Image

src = sys.argv[1]
raw = open(src, "rb").read()
w, h = struct.unpack("<II", raw[:8])
img = Image.frombytes("RGBA", (w, h), raw[8:])
base = src[:-5]
img.convert("RGB").save(base + "_full.png")
# phone: 844x390 viewport, map fitted with MapCamera.FIT_MARGIN (read from the source if you change it)
scale = min(844 / w, 390 / h) * 0.95
fw, fh = max(1, int(w * scale)), max(1, int(h * scale))
img.convert("RGB").resize((fw, fh), Image.NEAREST).save(base + "_phone.png")
cx = int(sys.argv[2]) if len(sys.argv) > 2 else w // 2
cy = int(sys.argv[3]) if len(sys.argv) > 3 else h // 2
img.convert("RGB").crop((cx - 200, cy - 125, cx + 200, cy + 125)).resize((1200, 750), Image.NEAREST).save(base + "_crop.png")
print("wrote", base + "_full.png", base + "_phone.png", f"({fw}x{fh})", base + "_crop.png")
