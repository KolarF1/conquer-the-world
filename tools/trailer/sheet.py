#!/usr/bin/env python3
"""A contact sheet of a recording, one frame every STEP seconds, stamped with its time, and the real frame count.
Usage: python tools/trailer/sheet.py <video> <out.png> [step_s] [cols]
"""
import subprocess
import sys

import imageio_ffmpeg
from PIL import Image, ImageDraw

src, out = sys.argv[1], sys.argv[2]
step = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0
cols = int(sys.argv[4]) if len(sys.argv) > 4 else 6
print("frames, secs:", imageio_ffmpeg.count_frames_and_secs(src))
ff = imageio_ffmpeg.get_ffmpeg_exe()
W, H = 320, 180
raw = subprocess.run(
    [ff, "-loglevel", "error", "-i", src, "-vf", f"fps=1/{step},scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
    capture_output=True,
    check=True,
).stdout
n = len(raw) // (W * H * 3)
rows = (n + cols - 1) // cols
sheet = Image.new("RGB", (cols * W, rows * H))
d = ImageDraw.Draw(sheet)
for i in range(n):
    im = Image.frombytes("RGB", (W, H), raw[i * W * H * 3 : (i + 1) * W * H * 3])
    x, y = (i % cols) * W, (i // cols) * H
    sheet.paste(im, (x, y))
    d.rectangle((x, y, x + 52, y + 14), fill=(0, 0, 0))
    d.text((x + 3, y + 2), f"{i * step:.0f}s", fill=(255, 255, 0))
sheet.save(out)
print(n, "frames in sheet")
