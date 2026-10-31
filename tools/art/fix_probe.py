"""Rewrites UITheme's PROBE_0 (the width of "0" at TextSize 100 per weight, used to verify the font loaded) from the
generated ADV tables. Run after tools/art/make_font_metrics.py."""
import os, re
THEME = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "src", "client", "UI", "UITheme.luau")
src = open(THEME, encoding="utf-8").read()
line_em = float(re.search(r"UITheme\.LINE_EM = ([0-9.]+)", src).group(1))
parts = []
for w in (400, 500, 600, 700, 800, 900):
    m = re.search(r"ADV\[%d\] = \{(.*?)\}\n" % w, src, re.S)
    adv0 = int(re.search(r"\[48\]=(\d+)", m.group(1)).group(1))
    parts.append("[%d] = %.1f" % (w, adv0 / 1000 * 100 / line_em))
line = "local PROBE_0 = { " + ", ".join(parts) + " }"
src = re.sub(r"local PROBE_0 = \{[^}]*\}", line, src)
open(THEME, "w", encoding="utf-8", newline="\n").write(src)
print(line)
