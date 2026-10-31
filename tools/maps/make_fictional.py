#!/usr/bin/env python3
"""Conquer the World's own maps: invented worlds drawn from layered noise and a shape per map, in the game's tile
format (WorldMap.luau). No outside data, so nothing to credit. Writes src/server/MapData/<Module>.luau and adds the
rows to src/shared/Data/MapList.luau (rows with the category "invented" are replaced, the real-Earth rows are left
alone). Deterministic: a map's seed is fixed.

Usage (from the repo root): python tools/maps/make_fictional.py [--only id] [--preview build/fictional]
"""
import argparse
import base64
import os
import re
import sys

import numpy as np
import zstandard
from PIL import Image
from scipy import ndimage

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_maps import LAND, REPO, SHORE, postprocess, tidy, lua_str, lua_list  # noqa: E402

REALMS = """Aldermark Valdoria Karthane Eskaron Tessaly Brannoch Morvane Ostrava Quillon Serrano Ithara Dunmere Halvard
Corvath Lyssandra Pellagia Tarsis Vorland Zephyria Ambria Calder Drusilla Elmarch Faircrest Gorran Hestia Ilmarin Jorvik
Kestrel Lorien Marrow Norwick Orlesk Pontus Rhovan Sundara Thorne Umbria Veyra Wexford Xanthe Yarrow Zarin Ashgrove
Blackmoor Cinderfell Dawnreach Emberlyn Frostmarch Greywater Highmoor Ironhold Jadeport Kingsmere Longstrand Mistral
Northgard Oakhaven Pinecrest Quarry Redwater Saltmarsh Tidewatch Underhill Vinehall Westmarch Yellowfen Stonehelm
Silverlode Goldcoast Ravenna Solace Meridian Arcadia Boreas Caldera Delphi Elysia Faros Galatia Hyperion""".split()


def fbm(shape, seed, base=4, octaves=6, persistence=0.55):
    """Layered smooth noise in 0..1: a coarse random grid resized up, finer and fainter each octave."""
    rng = np.random.default_rng(seed)
    h, w = shape
    out = np.zeros(shape)
    amp, total = 1.0, 0.0
    aspect = w / h
    for o in range(octaves):
        gy = base * 2 ** o + 1
        gx = int(gy * aspect) + 1
        grid = rng.random((gy, gx))
        zoom = (h / (gy - 1), w / (gx - 1))
        layer = ndimage.zoom(grid, zoom, order=3)[:h, :w]
        out[: layer.shape[0], : layer.shape[1]] += amp * layer
        total += amp
        amp *= persistence
    out /= total
    return (out - out.min()) / (out.max() - out.min())


def grids(h, w):
    y, x = np.mgrid[0:h, 0:w]
    return x / (w - 1) * 2 - 1, y / (h - 1) * 2 - 1  # -1..1 both ways


def blob(x, y, cx, cy, rx, ry):
    """1 at the centre, 0 at the ellipse's rim, negative outside."""
    return 1 - ((x - cx) / rx) ** 2 - ((y - cy) / ry) ** 2


def shape_pangaea(x, y):
    return np.maximum(blob(x, y, -0.1, 0, 0.85, 0.82), blob(x, y, 0.45, 0.3, 0.45, 0.45))


def shape_isles(x, y):
    # (islands come from the noise alone, see `isles` in build: this only fades them out towards the frame)
    return np.minimum(blob(x, y, 0, 0, 1.25, 1.25), 0.3)


def shape_twin(x, y):
    a = blob(x, y, -0.52, -0.05, 0.42, 0.78)
    b = blob(x, y, 0.52, 0.05, 0.42, 0.78)
    bridge = blob(x, y, 0.0, 0.0, 0.34, 0.1)
    return np.maximum(np.maximum(a, b), bridge)


def shape_inland(x, y):
    outer = blob(x, y, 0, 0, 0.94, 0.9)
    inner = blob(x, y, 0, 0, 0.5, 0.42)
    # (two straits to the open ocean)
    strait = np.exp(-((y - 0.04) / 0.05) ** 2) * (x > 0)
    return np.minimum(outer, -inner * 1.2 + 0.25) - strait * 1.1


def shape_crescent(x, y):
    r = np.sqrt((x + 0.25) ** 2 + (y * 1.05) ** 2)
    ang = np.arctan2(y, x + 0.25)
    band = 1 - ((r - 0.72) / 0.3) ** 2
    # (the horns taper away instead of ending in a cut)
    return np.minimum(band, (2.35 - np.abs(ang)) * 1.6)


def shape_spine(x, y):
    return blob(x, y, 0, 0, 0.92, 0.85)


def spine_ridge(x, y):
    """The Spine: a range across the land, with three passes through it."""
    path = 0.1 * np.sin(y * 4.5)
    ridge = np.exp(-((x - path) / 0.05) ** 2)
    for py in (-0.45, 0.0, 0.5):
        ridge *= 1 - 0.95 * np.exp(-((y - py) / 0.05) ** 2)
    return ridge


# id, name, module, width, height, nations, seed, shape, land level (noise weight), min_gap, multiplayer frequency
MAPS = [
    dict(id="primeval", name="Primeval", module="Primeval", w=1500, h=1000, nations=48, seed=101, shape=shape_pangaea, noise=0.75, level=0.02, gap=60),
    dict(id="thousandisles", name="Thousand Isles", module="ThousandIsles", w=1500, h=1000, nations=36, seed=202, shape=shape_isles, noise=0.8, level=0.34, gap=60, isles=0.60),
    dict(id="twinrealms", name="Twin Realms", module="TwinRealms", w=1500, h=1000, nations=40, seed=303, shape=shape_twin, noise=0.55, level=0.02, gap=60, warp=0.3),
    dict(id="marenostrum", name="Mare Nostrum", module="MareNostrum", w=1400, h=1050, nations=40, seed=404, shape=shape_inland, noise=0.45, level=0.0, gap=55, warp=0.3),
    dict(id="crescent", name="The Crescent", module="Crescent", w=1500, h=1000, nations=36, seed=505, shape=shape_crescent, noise=0.6, level=0.0, gap=60),
    dict(id="spine", name="The Spine", module="Spine", w=1500, h=1000, nations=44, seed=606, shape=shape_spine, noise=0.7, level=0.02, gap=60),
]


def build(spec):
    h, w = spec["h"], spec["w"]
    x, y = grids(h, w)
    n = fbm((h, w), spec["seed"], base=3, octaves=8, persistence=0.62)
    # (the shape is bent by the noise before it is cut, so no coast keeps the ellipse it came from)
    wx = fbm((h, w), spec["seed"] + 10, base=3, octaves=6, persistence=0.6) - 0.5
    wy = fbm((h, w), spec["seed"] + 11, base=3, octaves=6, persistence=0.6) - 0.5
    warp = spec.get("warp", 0.45)
    field = spec["shape"](x + wx * warp, y + wy * warp) + (n - 0.5) * spec["noise"] * 2
    if spec.get("isles"):
        fine = fbm((h, w), spec["seed"] + 12, base=9, octaves=6, persistence=0.55)
        field = fine + spec["shape"](x, y) * 0.5
        land = field > np.quantile(field, spec["isles"])
    else:
        land = field > spec["level"]
    # (never touching the frame: the sea goes all the way round)
    edge = np.zeros((h, w), dtype=bool)
    edge[:6, :] = edge[-6:, :] = edge[:, :6] = edge[:, -6:] = True
    land[edge] = False
    lakes = tidy(land)
    # elevation: bigger noise, higher inland, mountains in the noise's top
    relief = fbm((h, w), spec["seed"] + 1, base=4, octaves=6)
    inland = ndimage.distance_transform_edt(land)
    height = relief * 0.8 + np.clip(inland / 90.0, 0, 1) * 0.2
    if spec["id"] == "spine":
        height = np.maximum(height, spine_ridge(x, y) * 1.25)
    q = np.quantile(height[land], [0.62, 0.9]) if land.any() else [0.5, 0.8]
    mag = np.where(
        height < q[0],
        np.clip(height / q[0], 0, 1) * 9.0,
        np.where(height < q[1], 10 + (height - q[0]) / (q[1] - q[0]) * 9.0, 20 + np.clip((height - q[1]) / (1.0 - q[1] + 1e-6), 0, 1) * 10.0),
    )
    if spec["id"] == "spine":
        mag = np.where(spine_ridge(x, y) > 0.55, 30, mag)
    raw = np.where(land, LAND | np.floor(mag).astype(np.uint8), 0).astype(np.uint8)
    tiles = postprocess(raw.tobytes(), w, h)
    grid = np.frombuffer(tiles, dtype=np.uint8).reshape(h, w)
    return grid, int(land.sum())


def pick_nations(spec, grid, taken):
    """Spots spread over the land: repeatedly the inland tile farthest from every nation placed. Names are hashed
    out of REALMS, never twice on one map."""
    is_land = (grid & LAND) != 0
    inland = is_land & ((grid & SHORE) == 0)
    rng = np.random.default_rng(spec["seed"] + 2)
    h, w = grid.shape
    ys, xs = np.nonzero(inland)
    order = rng.permutation(len(ys))
    names = list(REALMS)
    rng.shuffle(names)
    spots = []
    dist = np.full(len(ys), np.inf)
    gap2 = spec["gap"] ** 2
    cur = order[0]
    # (a light jitter so it is not a perfect lattice)
    for i in range(spec["nations"]):
        if i > 0:
            score = dist * (0.85 + 0.3 * rng.random(len(ys)))
            cur = int(np.argmax(score))
            if dist[cur] < gap2:
                break
        sx, sy = int(xs[cur]), int(ys[cur])
        spots.append((sx, sy))
        d = (xs - sx) ** 2 + (ys - sy) ** 2
        dist = np.minimum(dist, d)
    out = []
    for i, (sx, sy) in enumerate(spots):
        name = names[i % len(names)]
        out.append({"name": name, "flag": "ctw_" + name.lower(), "x": sx, "y": sy})
    return out


def write_module(spec, grid, land_tiles, nations):
    h, w = grid.shape
    z = zstandard.ZstdCompressor(level=19, write_content_size=True).compress(grid.tobytes())
    lines = [
        "-- GENERATED by tools/maps/make_fictional.py. Do not edit. An invented world, Conquer the World's own.",
        "-- terrain = base64(zstd(width * height bytes)), the tile byte format of WorldMap.luau.",
        "return {",
        "\tid = %s," % lua_str(spec["id"]),
        "\tname = %s," % lua_str(spec["name"]),
        "\tmodule = %s," % lua_str(spec["module"]),
        "\twidth = %d," % w,
        "\theight = %d," % h,
        "\tk_lin = 1.0,",
        "\tcategories = %s," % lua_list(["invented"]),
        "\tmultiplayer_frequency = 6,",
        "\tforced_modifiers = {},",
        "\tland_tiles = %d," % land_tiles,
        "\tnations = {",
    ]
    for n in nations:
        lines.append("\t\t{ name = %s, flag = %s, x = %d, y = %d }," % (lua_str(n["name"]), lua_str(n["flag"]), n["x"], n["y"]))
    lines += ["\t},", '\tcodec = "zstd+base64",', "\tsize = %d," % (w * h), '\tterrain = "%s",' % base64.b64encode(z).decode("ascii"), "}", ""]
    with open(os.path.join(REPO, "src", "server", "MapData", spec["module"] + ".luau"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    return len(z)


def registry(rows):
    path = os.path.join(REPO, "src", "shared", "Data", "MapList.luau")
    s = open(path, encoding="utf-8").read()
    s = re.sub(r'\t\{ id = "[^\n]*"invented"[^\n]*\n', "", s)
    add = "".join(
        '\t{ id = %s, name = %s, module = %s, width = %d, height = %d, k_lin = 1.0, categories = { "invented" }, multiplayer_frequency = 6, land_tiles = %d, nations = %d },\n'
        % (lua_str(sp["id"]), lua_str(sp["name"]), lua_str(sp["module"]), sp["w"], sp["h"], land, count)
        for sp, land, count in rows
    )
    s = s.replace("MapList.maps = {\n", "MapList.maps = {\n" + add, 1)
    open(path, "w", encoding="utf-8", newline="\n").write(s)


def preview(path, grid):
    h, w = grid.shape
    img = np.zeros((h, w, 3), dtype=np.uint8)
    land = (grid & LAND) != 0
    mag = (grid & 31).astype(float)
    img[..., 0] = np.where(land, 110 + mag * 3, 20)
    img[..., 1] = np.where(land, 140 + mag, 60)
    img[..., 2] = np.where(land, 80 + mag * 2, 90)
    Image.fromarray(img).resize((w // 2, h // 2)).save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only")
    ap.add_argument("--preview")
    a = ap.parse_args()
    rows = []
    for spec in MAPS:
        if a.only and spec["id"] != a.only:
            continue
        grid, land = build(spec)
        nations = pick_nations(spec, grid, set())
        size = write_module(spec, grid, land, nations)
        rows.append((spec, land, len(nations)))
        print(spec["id"], grid.shape, "land", land, "share %.2f" % (land / grid.size), "nations", len(nations), "bytes", size)
        if a.preview:
            os.makedirs(a.preview, exist_ok=True)
            preview(os.path.join(a.preview, spec["id"] + ".png"), grid)
    if not a.only:
        registry(rows)


main()
