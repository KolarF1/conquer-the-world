--!nocheck
-- The UI's look (Conquer the World): the palette keeps its readability whatever it is tinted with.
-- WCAG contrast of the text tokens over a panel (as drawn: the tint, GLASS_BOOST more opaque, over a
-- map pixel of mid grey, the worst case between dark water and bright land), the dark text on the
-- primary button, and the radii staying on the 8 px scale's small side. The OLD_* numbers are the
-- upstream palette's, measured before the re-tint: the new look may not read worse than that.
-- Run: lune run tests/ui_look.luau
require("./prelude")
local T = require("../src/client/UI/UITheme")

local fails = 0
local function expect(c: any, w: string)
	if c then
		print("  ok   " .. w)
	else
		fails += 1
		print("FAIL " .. w)
	end
end

local function lin(v: number): number
	return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4
end
local function lum(c: Color3): number
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
local function contrast(a: Color3, b: Color3): number
	local la, lb = lum(a), lum(b)
	if la < lb then
		la, lb = lb, la
	end
	return (la + 0.05) / (lb + 0.05)
end
local function over(tint: any, back: Color3): Color3
	local t = T.to_rgba(tint)
	local a = math.min(1, t.alpha + T.GLASS_BOOST)
	return Color3.new(
		t.color.R * a + back.R * (1 - a),
		t.color.G * a + back.G * (1 - a),
		t.color.B * a + back.B * (1 - a)
	)
end

local grey = Color3.new(0.5, 0.5, 0.5)
local white = Color3.new(1, 1, 1)
local panel = over(T.GLASS, grey)
local panel_hi = over(T.GLASS, white)
-- the upstream palette over the same backdrop, measured by running this file before the re-tint
-- (TEXT 0.94 0.955 1.0, TEXT_2 0.68 0.73 0.86, TEXT_3 0.48 0.53 0.67 on its navy glass)
local OLD_TEXT, OLD_TEXT_2, OLD_TEXT_3 = 15.4, 8.8, 4.8

local c1, c2, c3 = contrast(T.TEXT, panel), contrast(T.TEXT_2, panel), contrast(T.TEXT_3, panel)
print(string.format("  text %.1f  text_2 %.1f  text_3 %.1f  (panel over grey)", c1, c2, c3))
expect(c1 >= 7 and c1 >= OLD_TEXT, "body text reads at 7:1 or better, and no worse than before")
expect(c2 >= 4.5 and c2 >= OLD_TEXT_2, "secondary text reads at 4.5:1 or better, and no worse than before")
expect(c3 >= 3 and c3 >= OLD_TEXT_3, "tertiary text reads at 3:1 or better, and no worse than before")
expect(contrast(T.TEXT, panel_hi) >= 4.5, "body text still reads where the panel sits over bright land")
expect(contrast(T.INK, T.AMBER) >= 7, "dark text on the primary button reads at 7:1 or better")
expect(contrast(T.INK, T.AMBER_HI) >= 7, "and on its hover")
expect(contrast(T.AMBER, panel) >= 7, "the accent reads as text on a panel")
expect(contrast(T.GOLD, panel) >= 7 and contrast(T.GREEN, panel) >= 7 and contrast(T.RED, panel) >= 4.5, "gold, green and red stay readable on a panel")
expect(contrast(T.AMBER, T.CYAN) >= 1.3 or math.abs(lum(T.AMBER) - lum(T.CYAN)) > 0.05, "accent and info are told apart")
expect(T.R_SM < T.R_MD and T.R_MD < T.R_LG and T.R_LG <= 12, "radii step up and stay crisp")
expect(T.LINE_2.alpha > T.LINE.alpha, "the strong line is stronger")

if fails > 0 then
	require("@lune/process").exit(1)
end
print("ui_look: all passed")
