--!nonstrict
-- EditableImage memory (phones ran out of it before: Locker.luau's 2026-09-29 note) and the cost of making our art on the
-- device. A scripted worst session is added up from the real sizes (the atlases, the strips, a Locker flags tab, the shop's
-- cards, every radial variant, the shadows, the thumbnails) and must stay under BUDGET_PX; each generator that runs on the
-- device is timed (Lune is slower than the game, so the limits are generous).
-- Run: lune run tests/art_budget.luau
local roblox = require("./prelude");
(getfenv() :: any).Instance = (roblox :: any).Instance;
(getfenv() :: any).Enum = (roblox :: any).Enum;
(getfenv() :: any).task = require("@lune/task")
local IconData = require("../src/shared/Art/IconData")
local MapData = require("../src/shared/Art/MapData")
local FxData = require("../src/shared/Art/FxData")
local Cosmetics = require("../src/shared/Data/Cosmetics")
local Emblem = require("../src/shared/Art/Emblem")
local SoftArt = require("../src/client/UI/SoftArt")
local ArtAtlas = require("../src/client/UI/ArtAtlas")

local fails = 0
local function expect(c: any, w: string)
	if c then
		print("  ok   " .. w)
	else
		fails += 1
		print("FAIL " .. w)
	end
end

local px = 0
local lines = {}
local function add(label: string, n: number)
	px += n
	table.insert(lines, string.format("%-34s %9d px", label, n))
end

local _, aw, ah = ArtAtlas.pixels()
add("icon atlas", aw * ah)
add("structure glyphs", MapData.glyphs.w * MapData.glyphs.h)
add("structure plates", MapData.plate_rim.w * MapData.plate_rim.h)
add("unit sprites + crown", MapData.unit_body.w * MapData.unit_body.h + 64 * 64)
add("effects atlas", FxData.atlas.w * FxData.atlas.h)
add("rail tiles (6)", 6 * 16 * 16)
add("thumbnails (12 maps)", 12 * 160 * 140)
add("bot badges", Cosmetics.BOT_BADGES * 48 * 48)
local flags = 0
for _, it in Cosmetics.all() do
	if it.kind == "flag" then
		flags += Cosmetics.FLAG_W * Cosmetics.FLAG_H
	end
end
add("Locker flags tab (every country)", flags)
add("shop cards (30 big flags)", 30 * Cosmetics.FLAG_BIG_W * Cosmetics.FLAG_BIG_H)
local shadows = 0
for _, s in { { 142 }, { 166 }, { 206 }, { 246 }, { 286 }, { 326 } } do
	shadows += s[1] * s[1]
end
add("panel shadows (6 sizes)", shadows)
local sectors = 0
for _, variant in { { 44, 116 }, { 44, 122 }, { 50, 128 }, { 50, 134 } } do
	for n = 2, 8 do
		for _, kind in { "fill", "line" } do
			local _, w, h = SoftArt.segment_pixels(variant[1], variant[2], n, kind, 2.2)
			sectors += w * h
		end
	end
end
add("radial sectors (every variant)", sectors)
add("title + dim + glows + crate light", 256 * 144 * 2 + 128 * 128 * 2 + 256 * 256 * 2 + 128 * 128 + 64 * 64 * 5 + 96 * 24 + 64 * 256)
for _, l in lines do
	print("  " .. l)
end
local BUDGET_PX = 3500000 -- about 14 MB of RGBA: the map (World) is about 8 MB on top, so this is the worst session, not a typical one
print(string.format("  total %d px = %.1f MB RGBA (budget %.1f MB)", px, px * 4 / 1048576, BUDGET_PX * 4 / 1048576))
expect(px <= BUDGET_PX, "the worst session's art stays under the budget")
expect(flags <= 700000, "all 258 country flags together are under 2.7 MB")

local function time_ms(f: () -> ()): number
	local t = os.clock()
	f()
	return (os.clock() - t) * 1000
end
local t1 = time_ms(function() SoftArt.shadow_pixels(326, 40, 120) end)
local t2 = time_ms(function() SoftArt.segment_pixels(44, 122, 2, "fill", 2.2) end)
local t3 = time_ms(function() SoftArt.rays_pixels(256) end)
local t4 = time_ms(function()
	for _, it in Cosmetics.all() do
		if it.kind == "flag" then
			Emblem.pixels(it.emblem, Cosmetics.FLAG_W, Cosmetics.FLAG_H, it.theme)
		end
	end
end)
local t5 = time_ms(function() ArtAtlas.pixels() end)
print(string.format("  Lune ms: shadow 326 = %.0f, sector n=2 = %.0f, rays 256 = %.0f, 258 flags = %.0f, icon atlas = %.0f", t1, t2, t3, t4, t5))
expect(t1 < 400 and t2 < 400 and t3 < 400 and t4 < 2500 and t5 < 1500, "nothing made on the device takes long even in Lune (the game runs it natively, several times faster)")

if fails > 0 then
	require("@lune/process").exit(1)
end
print("art_budget: all passed")
