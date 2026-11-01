--!strict
-- Our UI glyphs, drawn from shapes on a 64 x 64 grid (tools/art/raster.luau describes the shape lists).
-- House style: solid, chunky silhouettes with a few clean cut-outs; 6 to 7 units of stroke; round
-- caps; nothing thinner than 4 units so a glyph still reads at 14 px. Every name the interface asks
-- for (UITheme.icon) is here: tests/art_coverage.luau checks the list against the code.
local I = {}

local pi, cos, sin = math.pi, math.cos, math.sin

local function poly(pts: { number }): { any }
	local out: { any } = { "poly" }
	for _, v in pts do
		table.insert(out, v)
	end
	return out
end

--- A regular polygon-ish outline from a radius function of the angle.
local function outline(cx: number, cy: number, n: number, rf: (number) -> number): { any }
	local pts = {}
	for i = 0, n - 1 do
		local a = (i / n) * 2 * pi - pi / 2
		local r = rf(a)
		table.insert(pts, cx + cos(a) * r)
		table.insert(pts, cy + sin(a) * r)
	end
	return poly(pts)
end

local function star(cx: number, cy: number, ro: number, ri: number): { any }
	local pts = {}
	for i = 0, 9 do
		local a = (i / 10) * 2 * pi - pi / 2
		local r = if i % 2 == 0 then ro else ri
		table.insert(pts, cx + cos(a) * r)
		table.insert(pts, cy + sin(a) * r)
	end
	return poly(pts)
end

local function gear(cx: number, cy: number, ro: number, ri: number, teeth: number): { any }
	local pts = {}
	for t = 0, teeth - 1 do
		local base = (t / teeth) * 2 * pi
		local step = 2 * pi / teeth
		for _, f in { { 0.0, ri }, { 0.18, ro }, { 0.42, ro }, { 0.6, ri } } do
			local a = base + f[1] * step
			table.insert(pts, cx + cos(a) * f[2])
			table.insert(pts, cy + sin(a) * f[2])
		end
	end
	return poly(pts)
end

--- The nuclear trefoil: three sector wedges round a hub (the radiation sign).
local function trefoil(cx: number, cy: number, r: number, w: number, hub: number): { { any } }
	local out: { { any } } = {}
	local r_in, r_out = r - w * 0.5 + 1, r + w * 0.5
	for k = 0, 2 do
		local mid = (90 + k * 120) * pi / 180
		local pts = { "poly" }
		for i = 0, 8 do
			local a = mid - pi / 6 + (i / 8) * (pi / 3)
			table.insert(pts, cx + cos(a) * r_out)
			table.insert(pts, cy + sin(a) * r_out)
		end
		for i = 8, 0, -1 do
			local a = mid - pi / 6 + (i / 8) * (pi / 3)
			table.insert(pts, cx + cos(a) * r_in)
			table.insert(pts, cy + sin(a) * r_in)
		end
		table.insert(out, pts)
	end
	table.insert(out, { "circle", cx, cy, hub })
	return out
end

local function cat(...: { any }): { any }
	local out = {}
	for _, list in { ... } do
		for _, item in list do
			table.insert(out, item)
		end
	end
	return out
end

local function person(cx: number, cy: number, s: number): { any }
	return {
		{ "circle", cx, cy - 11 * s, 7 * s },
		{ "poly", cx - 13 * s, cy + 22 * s, cx - 13 * s, cy + 6 * s, cx - 7 * s, cy - 1 * s, cx + 7 * s, cy - 1 * s, cx + 13 * s, cy + 6 * s, cx + 13 * s, cy + 22 * s },
	}
end

I.city = {
	{ "box", 8, 30, 24, 56, 2 },
	{ "box", 25, 14, 40, 56, 2 },
	{ "box", 41, 24, 56, 56, 2 },
	{ "erase", { "box", 29, 20, 33, 25 } },
	{ "erase", { "box", 33, 20, 37, 25 } },
	{ "erase", { "box", 29, 29, 33, 34 } },
	{ "erase", { "box", 33, 29, 37, 34 } },
	{ "erase", { "box", 12, 36, 20, 40 } },
	{ "erase", { "box", 45, 30, 52, 34 } },
	{ "erase", { "box", 45, 38, 52, 42 } },
}
I.port = {
	{ "ring", 32, 13, 5, 4.5 },
	{ "line", 32, 18, 32, 50, 5.5 },
	{ "line", 22, 27, 42, 27, 5 },
	{ "arc", 32, 34, 20, 18, 162, 5.5 },
	{ "poly", 10, 40, 18, 40, 14, 48 },
	{ "poly", 54, 40, 46, 40, 50, 48 },
}
I.factory = {
	poly({ 6, 56, 6, 28, 20, 38, 20, 28, 34, 38, 34, 28, 48, 38, 48, 56 }),
	{ "box", 44, 10, 56, 56, 1.5 },
	{ "erase", { "box", 12, 44, 18, 50 } },
	{ "erase", { "box", 24, 44, 30, 50 } },
	{ "erase", { "box", 36, 46, 42, 52 } },
}
I.defense = {
	poly({ 32, 6, 55, 15, 55, 34, 32, 58, 9, 34, 9, 15 }),
	{ "erase", poly({ 32, 17, 45, 22, 45, 33, 32, 47, 19, 33, 19, 22 }) },
	{ "circle", 32, 31, 6 },
}
I.sam = {
	{ "box", 6, 50, 58, 58, 2 },
	{ "line", 16, 50, 26, 40, 6 },
	{ "line", 36, 50, 26, 40, 6 },
	{ "line", 14, 42, 46, 12, 8 },
	poly({ 42, 6, 60, 4, 54, 22 }),
	poly({ 10, 30, 22, 34, 18, 46, 6, 44 }),
}
I.silo = {
	poly({ 32, 2, 41, 18, 23, 18 }),
	{ "box", 23, 19, 41, 46, 1 },
	poly({ 23, 32, 12, 48, 23, 46 }),
	poly({ 41, 32, 52, 48, 41, 46 }),
	{ "box", 4, 52, 60, 60, 2 },
}
I.artillery = {
	{ "line", 24, 38, 52, 14, 10 },
	{ "circle", 24, 44, 12 },
	{ "erase", { "circle", 24, 44, 4.5 } },
	{ "box", 6, 54, 44, 59, 2 },
}
I.airfield = {
	{ "line", 32, 6, 32, 56, 8 },
	poly({ 32, 22, 58, 38, 58, 44, 32, 36, 6, 44, 6, 38 }),
	poly({ 32, 46, 44, 56, 44, 60, 32, 55, 20, 60, 20, 56 }),
}
I.railgun = {
	{ "box", 4, 24, 46, 32, 2 },
	{ "box", 4, 36, 46, 44, 2 },
	{ "circle", 50, 34, 11 },
	{ "erase", { "circle", 50, 34, 4.5 } },
	{ "line", 12, 30, 12, 38, 3 },
}
I.warship = {
	poly({ 4, 38, 60, 38, 50, 52, 14, 52 }),
	{ "box", 20, 24, 44, 38, 2 },
	{ "line", 44, 30, 58, 24, 4 },
	{ "line", 32, 10, 32, 24, 4 },
	{ "erase", { "box", 25, 28, 29, 32 } },
	{ "erase", { "box", 34, 28, 38, 32 } },
}
I.boat = {
	poly({ 8, 40, 56, 40, 48, 54, 16, 54 }),
	poly({ 31, 8, 31, 36, 12, 36 }),
	poly({ 35, 14, 35, 36, 52, 36 }),
}
I.atom = cat(trefoil(32, 32, 17, 15, 6), { { "ring", 32, 32, 28, 3.5 } })
I.hydrogen = {
	{ "circle", 18, 22, 13 },
	{ "circle", 32, 16, 15 },
	{ "circle", 46, 22, 13 },
	{ "box", 26, 26, 38, 50, 2 },
	poly({ 26, 44, 38, 44, 50, 58, 14, 58 }),
}
I.mega = cat(trefoil(32, 32, 14, 13, 5), { { "ring", 32, 32, 23, 3 }, { "ring", 32, 32, 29, 3 }, { "line", 32, 2, 32, 8, 3 }, { "line", 32, 56, 32, 62, 3 } })
I.mirv = {
	{ "line", 16, 14, 16, 42, 6 },
	poly({ 16, 56, 22, 42, 10, 42 }),
	{ "line", 32, 8, 32, 36, 6 },
	poly({ 32, 50, 38, 36, 26, 36 }),
	{ "line", 48, 14, 48, 42, 6 },
	poly({ 48, 56, 54, 42, 42, 42 }),
}
I.scatter = {
	{ "circle", 32, 14, 6 },
	{ "circle", 14, 30, 6 },
	{ "circle", 50, 30, 6 },
	{ "circle", 22, 50, 6 },
	{ "circle", 42, 50, 6 },
	{ "line", 32, 21, 32, 30, 3 },
	{ "line", 19, 36, 22, 42, 3 },
	{ "line", 45, 36, 42, 42, 3 },
}
I.airstrike = {
	{ "circle", 14, 44, 8 },
	poly({ 9, 22, 19, 22, 17, 38, 11, 38 }),
	{ "circle", 32, 50, 8 },
	poly({ 27, 26, 37, 26, 35, 44, 29, 44 }),
	{ "circle", 50, 44, 8 },
	poly({ 45, 22, 55, 22, 53, 38, 47, 38 }),
	{ "line", 8, 12, 56, 12, 5 },
}
I.slug = {
	poly({ 32, 4, 44, 22, 44, 50, 20, 50, 20, 22 }),
	{ "erase", { "box", 20, 36, 44, 39 } },
	{ "box", 18, 52, 46, 58, 2 },
}
I.reinforce = cat(person(24, 30, 0.8), { { "box", 40, 36, 58, 44, 2 }, { "box", 45, 31, 53, 49, 2 } })
I.reload = {
	{ "arc", 32, 32, 20, 40, 320, 7 },
	poly({ 40, 10, 58, 20, 36, 28 }),
}
I.arsenal = {
	{ "box", 8, 24, 56, 56, 3 },
	{ "box", 6, 16, 58, 26, 2 },
	{ "erase", { "box", 26, 34, 38, 38 } },
	{ "erase", { "box", 13, 31, 17, 49 } },
	{ "erase", { "box", 47, 31, 51, 49 } },
}
I.lock = {
	{ "box", 14, 28, 50, 58, 5 },
	{ "arc", 32, 28, 11, 180, 360, 6.5 },
	{ "erase", { "circle", 32, 42, 5 } },
	{ "erase", { "box", 30, 42, 34, 51 } },
}
I.star = { star(32, 33, 28, 12) }
I.crown = {
	poly({ 6, 50, 6, 20, 20, 34, 32, 12, 44, 34, 58, 20, 58, 50 }),
	{ "box", 6, 50, 58, 58, 2 },
	{ "erase", { "circle", 32, 40, 3.5 } },
}
I.troops = cat(person(32, 30, 1.05), { { "box", 20, 4, 44, 10, 3 } })
I.users = cat(person(22, 30, 0.9), person(42, 34, 0.9))
I.pops = cat(person(16, 34, 0.7), person(32, 30, 0.8), person(48, 34, 0.7))
I.alliance = {
	{ "ring", 22, 32, 15, 7 },
	{ "ring", 42, 32, 15, 7 },
	{ "erase", { "box", 28, 14, 36, 20 } },
}
I.betray = {
	poly({ 32, 4, 40, 36, 24, 36 }),
	{ "box", 17, 36, 47, 42, 2 },
	{ "box", 28, 42, 36, 54, 2 },
	{ "circle", 32, 58, 4 },
}
I.donate = {
	{ "box", 10, 28, 54, 58, 3 },
	{ "box", 7, 20, 57, 30, 2 },
	{ "erase", { "box", 29, 20, 35, 58 } },
	{ "ring", 22, 14, 6.5, 5 },
	{ "ring", 42, 14, 6.5, 5 },
}
I.gold = {
	{ "circle", 32, 32, 27 },
	{ "erase", { "ring", 32, 32, 19, 4 } },
	poly({ 32, 17, 41, 32, 32, 47, 23, 32 }),
}
I.clock = {
	{ "ring", 32, 32, 25, 7 },
	{ "line", 32, 32, 32, 16, 6 },
	{ "line", 32, 32, 44, 38, 6 },
}
I.close = { { "line", 14, 14, 50, 50, 8 }, { "line", 50, 14, 14, 50, 8 } }
I.check = { { "line", 12, 34, 26, 48, 8 }, { "line", 26, 48, 52, 16, 8 } }
I.chevron = { { "line", 22, 10, 44, 32, 8 }, { "line", 44, 32, 22, 54, 8 } }
I.exit = {
	{ "line", 14, 10, 14, 54, 6.5 },
	{ "line", 14, 10, 36, 10, 6.5 },
	{ "line", 14, 54, 36, 54, 6.5 },
	{ "line", 26, 32, 52, 32, 6.5 },
	poly({ 46, 20, 62, 32, 46, 44 }),
}
do
	local lens = {}
	for i = 0, 15 do
		local t = i / 15
		local x = 4 + 56 * t
		local y = 32 - 20 * sin(pi * t)
		table.insert(lens, x)
		table.insert(lens, y)
	end
	for i = 15, 0, -1 do
		local t = i / 15
		local x = 4 + 56 * t
		local y = 32 + 20 * sin(pi * t)
		table.insert(lens, x)
		table.insert(lens, y)
	end
	I.eye = { poly(lens), { "erase", { "circle", 32, 32, 10 } }, { "circle", 32, 32, 5 } }
end
I.globe = {
	{ "ring", 32, 32, 26, 6 },
	{ "line", 6, 32, 58, 32, 5 },
	{ "arc", 32, 32, 14, 270, 90, 5 },
	{ "arc", 32, 32, 14, 90, 270, 5 },
	{ "line", 32, 6, 32, 58, 5 },
}
I.help = {
	{ "arc", 32, 24, 12, 180, 70, 8 },
	{ "line", 40, 32, 32, 42, 8 },
	{ "line", 32, 42, 32, 46, 8 },
	{ "circle", 32, 57, 4.5 },
}
I.info = {
	{ "circle", 32, 32, 28 },
	{ "erase", { "circle", 32, 18, 4.5 } },
	{ "erase", { "line", 32, 28, 32, 46, 8 } },
}
I.layers = {
	poly({ 32, 6, 58, 20, 32, 34, 6, 20 }),
	{ "line", 8, 32, 32, 44, 6 },
	{ "line", 32, 44, 56, 32, 6 },
	{ "line", 8, 44, 32, 56, 6 },
	{ "line", 32, 56, 56, 44, 6 },
}
I.leaderboard = {
	{ "box", 8, 34, 22, 56, 2 },
	{ "box", 25, 18, 39, 56, 2 },
	{ "box", 42, 40, 56, 56, 2 },
	star(32, 8, 6, 2.6),
}
I.music_on = {
	{ "circle", 20, 48, 9 },
	{ "line", 28, 46, 28, 12, 6 },
	poly({ 28, 12, 52, 20, 52, 30, 28, 24 }),
}
I.music_off = {
	{ "circle", 20, 48, 9 },
	{ "line", 28, 46, 28, 12, 6 },
	poly({ 28, 12, 52, 20, 52, 30, 28, 24 }),
	{ "erase", { "line", 8, 56, 56, 8, 11 } },
	{ "line", 8, 56, 56, 8, 5 },
}
I.play = { poly({ 16, 8, 56, 32, 16, 56 }) }
I.lm_mine = {
	poly({ 6, 26, 18, 12, 34, 6, 50, 8, 58, 18, 46, 14, 34, 16, 20, 20 }),
	{ "line", 31, 13, 46, 56, 6 },
	poly({ 6, 46, 18, 38, 30, 44, 28, 58, 10, 60 }),
}
I.lm_garrison = {
	poly({ 32, 12, 62, 56, 2, 56 }),
	{ "erase", poly({ 32, 32, 43, 56, 21, 56 }) },
	{ "line", 32, 14, 32, 3, 3 },
	poly({ 32, 3, 46, 8, 32, 12 }),
}
I.lm_citadel = {
	{ "box", 6, 22, 22, 60, 0 },
	{ "box", 42, 22, 58, 60, 0 },
	{ "box", 20, 32, 44, 60, 0 },
	{ "box", 6, 14, 10, 24, 0 },
	{ "box", 12, 14, 16, 24, 0 },
	{ "box", 18, 14, 22, 24, 0 },
	{ "box", 42, 14, 46, 24, 0 },
	{ "box", 48, 14, 52, 24, 0 },
	{ "box", 54, 14, 58, 24, 0 },
	{ "erase", { "box", 26, 44, 38, 62, 5 } },
}
I.lm_harbor = {
	poly({ 24, 24, 40, 24, 47, 60, 17, 60 }),
	{ "erase", { "box", 14, 38, 50, 44, 0 } },
	{ "box", 26, 11, 38, 22, 1 },
	poly({ 23, 11, 32, 2, 41, 11 }),
	poly({ 42, 13, 62, 7, 62, 21, 42, 19 }),
	poly({ 22, 13, 2, 7, 2, 21, 22, 19 }),
}
I.lm_foundry = {
	poly({ 4, 18, 60, 18, 60, 22, 46, 32, 42, 42, 52, 56, 12, 56, 22, 42, 20, 32, 4, 26 }),
}
I.wheat = {
	{ "line", 32, 58, 32, 10, 4 },
	poly({ 32, 4, 37, 12, 32, 20, 27, 12 }),
	poly({ 32, 22, 46, 14, 50, 22, 36, 30 }),
	poly({ 32, 22, 18, 14, 14, 22, 28, 30 }),
	poly({ 32, 36, 46, 28, 50, 36, 36, 44 }),
	poly({ 32, 36, 18, 28, 14, 36, 28, 44 }),
}
I.retreat = {
	{ "arc", 36, 36, 18, 270, 90, 7 },
	{ "line", 36, 18, 14, 18, 7 },
	poly({ 14, 6, 14, 30, -2, 18 }),
}
I.settings = {
	gear(32, 32, 28, 21, 8),
	{ "erase", { "circle", 32, 32, 9 } },
}
I.skull = {
	{ "circle", 32, 28, 22 },
	{ "box", 20, 40, 44, 58, 4 },
	{ "erase", { "circle", 23, 30, 6.5 } },
	{ "erase", { "circle", 41, 30, 6.5 } },
	{ "erase", poly({ 32, 35, 28, 44, 36, 44 }) },
	{ "erase", { "box", 28, 50, 29.5, 58 } },
	{ "erase", { "box", 34.5, 50, 36, 58 } },
}
I.target = {
	{ "ring", 32, 32, 25, 6 },
	{ "ring", 32, 32, 14, 5.5 },
	{ "circle", 32, 32, 4.5 },
	{ "line", 32, 2, 32, 12, 4.5 },
	{ "line", 32, 52, 32, 62, 4.5 },
	{ "line", 2, 32, 12, 32, 4.5 },
	{ "line", 52, 32, 62, 32, 4.5 },
}
I.github = {
	{ "line", 22, 14, 6, 32, 7 },
	{ "line", 6, 32, 22, 50, 7 },
	{ "line", 42, 14, 58, 32, 7 },
	{ "line", 58, 32, 42, 50, 7 },
	{ "line", 36, 10, 28, 54, 6 },
}
I.attack = {
	{ "line", 10, 54, 46, 18, 7 },
	poly({ 46, 18, 56, 6, 58, 8, 52, 20 }),
	{ "line", 54, 54, 18, 18, 7 },
	poly({ 18, 18, 8, 6, 6, 8, 12, 20 }),
	{ "line", 8, 40, 20, 52, 6 },
	{ "line", 56, 40, 44, 52, 6 },
}
I.calm = {
	{ "ring", 32, 32, 26, 6 },
	{ "line", 32, 6, 32, 58, 6 },
	{ "line", 32, 32, 14, 50, 6 },
	{ "line", 32, 32, 50, 50, 6 },
}
I.crate = {
	{ "box", 6, 14, 58, 54, 3 },
	{ "erase", { "line", 12, 20, 52, 48, 4.5 } },
	{ "erase", { "line", 52, 20, 12, 48, 4.5 } },
	{ "erase", { "box", 6, 31, 12, 37 } },
}
--- The title screen's emblem: a shield holding a globe (the game's mark).
I.app_icon = {
	poly({ 32, 2, 59, 12, 59, 36, 32, 62, 5, 36, 5, 12 }),
	{ "erase", poly({ 32, 9, 52, 17, 52, 34, 32, 54, 12, 34, 12, 17 }) },
	{ "ring", 32, 31, 13, 4.5 },
	{ "line", 19, 31, 45, 31, 3.5 },
	{ "line", 32, 18, 32, 44, 3.5 },
	{ "arc", 32, 31, 8, 270, 90, 3 },
	{ "arc", 32, 31, 8, 90, 270, 3 },
}
I.robux = { { "circle", 32, 32, 26 }, { "erase", { "box", 22, 22, 42, 42, 3 } } }

--- Names that are the same drawing under another key (the HUD's variants).
I.ALIASES = {
	hud_exit = "exit",
	hud_globe = "globe",
	hud_help = "help",
	hud_leaderboard = "leaderboard",
	hud_music_off = "music_off",
	hud_music_on = "music_on",
	hud_settings = "settings",
}

return I
