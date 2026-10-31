#!/usr/bin/env python3
"""Montserrat metrics for the UI kit's text layout (replaces the Rubik tables of tools/uikit/make_metrics.py).

Reads Montserrat-{Regular,Medium,Bold,Black}.ttf from Roblox Studio's content/fonts (weights 400, 500, 700, 900;
600 and 800 are interpolated), writes into src/client/UI/UITheme.luau: the GENERATED METRICS block (advances per
weight in em/1000 and the tabular digit), APPROX (rough per-class advances for Lune), and the line constants
(hhea ascender/descender). Usage: python tools/art/make_font_metrics.py [fonts dir]
"""
import glob, os, re, sys
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
THEME = os.path.join(ROOT, "src", "client", "UI", "UITheme.luau")
if len(sys.argv) > 1:
    fonts = sys.argv[1]
else:
    cands = sorted(glob.glob(os.path.expanduser("~/AppData/Local/Roblox/Versions/version-*/content/fonts")))
    fonts = next(c for c in cands if os.path.exists(os.path.join(c, "Montserrat-Regular.ttf")))
FILES = {400: "Montserrat-Regular.ttf", 500: "Montserrat-Medium.ttf", 700: "Montserrat-Bold.ttf", 900: "Montserrat-Black.ttf"}
EXTRA = "·×…−±✓’“”—–•"
chars = [chr(c) for c in range(32, 127)] + list(EXTRA)

adv, tnum = {}, {}
upm = asc = desc = None
for w, fn in FILES.items():
    f = TTFont(os.path.join(fonts, fn))
    cmap = f.getBestCmap()
    hm = f["hmtx"].metrics
    upm = f["head"].unitsPerEm
    asc, desc = f["hhea"].ascent, -f["hhea"].descent
    scale = 1000.0 / upm
    adv[w] = {ord(c): round(hm[cmap[ord(c)]][0] * scale) for c in chars if ord(c) in cmap}
    subs = {}
    if "GSUB" in f:
        for fr in f["GSUB"].table.FeatureList.FeatureRecord:
            if fr.FeatureTag == "tnum":
                for li in fr.Feature.LookupListIndex:
                    for st in f["GSUB"].table.LookupList.Lookup[li].SubTable:
                        if hasattr(st, "mapping"):
                            subs.update(st.mapping)
    g0 = cmap[ord("0")]
    tnum[w] = round(hm[subs.get(g0, g0)][0] * scale)
for w, a, b in ((600, 500, 700), (800, 700, 900)):
    adv[w] = {cp: round((adv[a][cp] + adv[b][cp]) / 2) for cp in adv[a]}
    tnum[w] = round((tnum[a] + tnum[b]) / 2)

lines = ["-- BEGIN GENERATED METRICS (tools/art/make_font_metrics.py) --",
         "-- Montserrat advances in em/1000: ADV[weight] = {codepoint -> advance}; TNUM[weight] = tabular digit.",
         "local ADV: { [number]: { [number]: number } } = {}",
         "local TNUM: { [number]: number } = {}"]
for w in (400, 500, 600, 700, 800, 900):
    pairs = ", ".join(f"[{cp}]={v}" for cp, v in sorted(adv[w].items()))
    lines.append(f"ADV[{w}] = {{ {pairs} }}")
    lines.append(f"TNUM[{w}] = {tnum[w]}")
lines.append("-- END GENERATED METRICS --")
block = "\n".join(lines)

def avg(w, rng):
    v = [adv[w][c] for c in rng if c in adv[w]]
    return round(sum(v) / len(v))
approx = ["local APPROX = {"]
for w in (400, 500, 600, 700, 800, 900):
    d = avg(w, range(48, 58)); u = avg(w, range(65, 91)); l = avg(w, range(97, 123))
    o = avg(w, [32, 33, 44, 45, 46, 58, 59, 40, 41, 47])
    approx.append(f"\t[{w}] = {{ d = {d}, u = {u}, l = {l}, o = {o} }},")
approx.append("}")

line_em = (asc + desc) / upm
src = open(THEME, encoding="utf-8").read()
src = re.sub(r"-- BEGIN GENERATED METRICS.*?-- END GENERATED METRICS --", lambda m: block, src, flags=re.S)
src = re.sub(r"local APPROX = \{.*?\n\}", lambda m: "\n".join(approx), src, count=1, flags=re.S)
src = re.sub(r"--- Line height of [A-Za-z]+ in em[^\n]*\nUITheme\.LINE_EM = [0-9.]+", f"--- Line height of Montserrat in em (hhea ascender {asc} + descender {desc}, per {upm}).\nUITheme.LINE_EM = {line_em:.3f}", src)
src = re.sub(r"UITheme\.ASCENT_EM = [0-9.]+", f"UITheme.ASCENT_EM = {asc / upm:.3f}", src)
ratio = tnum[700] / adv[700][ord("0")]
src = re.sub(r"UITheme\.TNUM_RATIO = [0-9.]+", f"UITheme.TNUM_RATIO = {ratio:.3f}", src)
src = re.sub(r"UITheme\.RBX_BASELINE = [0-9.]+ / [0-9.]+", f"UITheme.RBX_BASELINE = {asc / 1000:.3f} / {line_em:.3f}", src)
open(THEME, "w", encoding="utf-8", newline="\n").write(src)
print("updated", THEME, "line_em", round(line_em, 3), "asc", asc / upm, "tnum ratio", round(ratio, 3), "tnum700", tnum[700], "0@700", adv[700][ord('0')])
