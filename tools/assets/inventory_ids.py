"""Lists every rbxassetid:// id under src (outside Dev) that is not in docs/OWNED_ASSETS.txt, per file.
The same rule tools/check.js enforces. usage: python tools/assets/inventory_ids.py"""
import glob, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(ROOT)
owned = set(re.findall(r"^(\d{6,})", open("docs/OWNED_ASSETS.txt").read(), re.M))
tot = {}
for f in glob.glob("src/**/*.luau", recursive=True):
    if "/Dev/" in f.replace(chr(92), "/"):
        continue
    s = open(f, "rb").read().decode(errors="ignore")
    ids = [i for i in re.findall(r"rbxassetid://(\d+)", s) if i not in owned]
    if ids:
        tot[f] = len(ids)
for f, n in sorted(tot.items(), key=lambda x: -x[1]):
    print(n, f)
print(sum(tot.values()), "foreign ids in", len(tot), "files")
