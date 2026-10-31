--!nonstrict
-- The map's effects and rail tiles, ours: pixel art a pixel to a map tile, drawn from shapes here and packed as palette
-- indices (the effects) and white masks (the rails, the flag's cloth). Writes src/shared/Art/FxData.luau and
-- build/art_fx.mask (a contact sheet). Run: lune run tools/art/fx.luau
local fs = require("@lune/fs")
local Raster = require("./raster")
local Codec = require("./codec")

local pi, sin, cos = math.pi, math.sin, math.cos

-- palette index -> RGBA8 (0 = clear)
local PALETTE = {
	[1] = 0xFF1C1C22, -- soot
	[2] = 0xFF45454F, -- dark smoke
	[3] = 0xFF7A7A86, -- smoke
	[4] = 0xFFB4B4BE, -- light smoke
	[5] = 0xFF9E2418, -- red
	[6] = 0xFFE0701E, -- orange
	[7] = 0xFFFFC94A, -- yellow
	[8] = 0xFFFFF4D6, -- white hot
	[9] = 0xFFFFFFFF, -- white (tinted layers)
	[10] = 0xFFB0B0B0, -- cloth grey
	[11] = 0xFF707070, -- cloth shade
	[12] = 0xFF303030, -- pole
}

--- A frame canvas of palette indices.
local function canvas(w: number, h: number)
	return { w = w, h = h, p = buffer.create(w * h) }
end

--- Paints index `idx` where `shape` covers a pixel by half or more.
local function paint(c, shape, idx: number)
	local m = Raster.new(c.w, c.h)
	Raster.draw(m, shape, 1, 0, 0)
	for i = 0, c.w * c.h - 1 do
		if buffer.readu8(m.a, i) >= 128 then
			buffer.writeu8(c.p, i, idx)
		end
	end
end

local function puff(c, x, y, r, idx)
	paint(c, { "circle", x, y, r }, idx)
end

-- rows of the effects atlas (same names and sizes the layer reads) -------------------------------
local ROWS = {
	{ name = "nuke", w = 60, h = 60, frames = 12 },
	{ name = "flag", w = 24, h = 24, frames = 10 },
	{ name = "banner", w = 24, h = 24, frames = 10 },
	{ name = "sam", w = 48, h = 38, frames = 9 },
	{ name = "building", w = 17, h = 15, frames = 10 },
	{ name = "fire", w = 7, h = 13, frames = 6 },
	{ name = "smoke", w = 11, h = 12, frames = 4 },
	{ name = "big_smoke", w = 24, h = 16, frames = 5 },
	{ name = "smoke_fire", w = 24, h = 16, frames = 5 },
}

local draw = {}

function draw.nuke(c, f)
	local t = f / 11
	local ease = sin(t * pi / 2)
	local cy = 36 - ease * 8
	-- the shock ring
	if t < 0.85 then
		paint(c, { "ring", 30, 38, 6 + ease * 22, 1.6 }, 4)
	end
	-- stem
	if t > 0.25 then
		paint(c, { "box", 26, cy, 34, 54, 2 }, if t > 0.7 then 3 else 2)
	end
	local r = 4 + ease * 20
	local hot = if t < 0.45 then 1 else 0
	paint(c, { "circle", 30, cy, r }, if t > 0.75 then 2 else 5)
	paint(c, { "circle", 30, cy, r * 0.78 }, if t > 0.75 then 3 else 6)
	if t < 0.9 then
		paint(c, { "circle", 30, cy, r * 0.52 }, if t > 0.6 then 6 else 7)
	end
	if hot == 1 then
		paint(c, { "circle", 30, cy, r * 0.26 }, 8)
	end
	-- the cap's lobes
	if t > 0.3 then
		paint(c, { "circle", 30 - r * 0.8, cy + r * 0.25, r * 0.38 }, if t > 0.75 then 2 else 5)
		paint(c, { "circle", 30 + r * 0.8, cy + r * 0.25, r * 0.38 }, if t > 0.75 then 2 else 5)
	end
end

function draw.flag(c, f)
	local ph = f / 10 * 2 * pi
	paint(c, { "line", 3, 2, 3, 22, 1.6 }, 9)
	local top, bot = {}, {}
	for i = 0, 9 do
		local x = 4 + i * 1.8
		local wave = sin(ph + i * 0.7) * 1.6
		table.insert(top, x)
		table.insert(top, 3 + wave)
		table.insert(bot, x)
		table.insert(bot, 13 + wave)
	end
	local pts = { "poly" }
	for i = 1, #top do
		table.insert(pts, top[i])
	end
	for i = #bot - 1, 1, -2 do
		table.insert(pts, bot[i])
		table.insert(pts, bot[i + 1])
	end
	paint(c, pts, 9)
end

function draw.banner(c, f)
	local ph = f / 10 * 2 * pi
	paint(c, { "line", 3, 2, 3, 22, 1.6 }, 12)
	local pts = { "poly" }
	local lo = {}
	for i = 0, 9 do
		local x = 4 + i * 1.8
		local wave = sin(ph + i * 0.7) * 1.6
		table.insert(pts, x)
		table.insert(pts, 3 + wave)
		table.insert(lo, x)
		table.insert(lo, 13 + wave)
	end
	for i = #lo - 1, 1, -2 do
		table.insert(pts, lo[i])
		table.insert(pts, lo[i + 1])
	end
	paint(c, pts, 10)
	-- the cloth's shade, a fold that travels
	local fx = 4 + ((f % 10) / 10) * 16
	paint(c, { "box", fx, 3, fx + 3, 13, 0 }, 11)
end

function draw.sam(c, f)
	local t = f / 8
	local y = 32 - t * 26
	-- exhaust and puffs
	for i = 0, 3 do
		local py = y + 6 + i * 4
		if py < 36 then
			puff(c, 24 + sin(i + f) * 1.5, py, 2.2 + i * 0.5, if i == 0 then 6 elseif i == 1 then 3 else 4)
		end
	end
	paint(c, { "box", 22.6, y - 6, 25.4, y + 4, 0.6 }, 9)
	paint(c, { "poly", 22.6, y - 6, 25.4, y - 6, 24, y - 10 }, 9)
	paint(c, { "box", 21, y + 1, 22.6, y + 5, 0 }, 4)
	paint(c, { "box", 25.4, y + 1, 27, y + 5, 0 }, 4)
	if f < 3 then
		puff(c, 24, 34, 5 - f, 4)
	end
end

function draw.building(c, f)
	local t = f / 9
	paint(c, { "box", 2, 12, 15, 14, 0 }, 3)
	local rise = 2 + t * 9
	paint(c, { "box", 4, 12 - rise, 13, 12, 0.5 }, if f % 2 == 0 then 4 else 3)
	puff(c, 3 + sin(f) * 1.5, 10 - t * 3, 2.2, 4)
	puff(c, 14 - sin(f * 1.3) * 1.5, 11 - t * 2, 1.8, 3)
end

function draw.fire(c, f)
	local flick = sin(f * 1.9) * 0.8
	paint(c, { "poly", 3.5, 1 + flick, 6, 8, 5.2, 12, 1.8, 12, 1, 8 }, 5)
	paint(c, { "poly", 3.5, 4 + flick, 5.2, 9, 4.6, 12, 2.4, 12, 1.8, 9 }, 6)
	paint(c, { "poly", 3.5, 8, 4.4, 11, 2.6, 11 }, 7)
end

function draw.smoke(c, f)
	local t = f / 3
	puff(c, 5.5, 9 - t * 3, 2.6 + t * 1.4, 3)
	puff(c, 4, 7 - t * 3, 1.8 + t, 2)
	puff(c, 7.5, 6 - t * 3, 1.6 + t, 4)
end

function draw.big_smoke(c, f)
	local t = f / 4
	puff(c, 12, 11 - t * 2, 5 + t * 2.4, 2)
	puff(c, 8, 9 - t * 3, 3.4 + t * 1.6, 3)
	puff(c, 16, 8 - t * 3, 3 + t * 1.8, 3)
	puff(c, 12, 6 - t * 3, 2.4 + t * 1.4, 4)
end

function draw.smoke_fire(c, f)
	draw.big_smoke(c, f)
	local t = f / 4
	puff(c, 11, 13, 2.4 - t, 6)
	puff(c, 14, 13.5, 1.6, 7)
	puff(c, 9, 14, 1.4, 5)
end

local width = 0
local height = 0
for _, r in ROWS do
	r.y = height
	height += r.h
	width = math.max(width, r.w * r.frames)
end
local atlas = Raster.new(width, height) -- palette indices as bytes
local sheet = Raster.new(width * 3, height * 3 + 8)
for _, r in ROWS do
	for f = 0, r.frames - 1 do
		local c = canvas(r.w, r.h)
		draw[r.name](c, f)
		for y = 0, r.h - 1 do
			for x = 0, r.w - 1 do
				local idx = buffer.readu8(c.p, y * r.w + x)
				buffer.writeu8(atlas.a, (r.y + y) * width + f * r.w + x, idx)
			end
		end
	end
end
-- contact sheet: palette colours (grey ramp of the RGB) at 3x
for y = 0, height - 1 do
	for x = 0, width - 1 do
		local idx = buffer.readu8(atlas.a, y * width + x)
		local col = PALETTE[idx]
		local v = 0
		if col ~= nil then
			local rr, gg, bb = col % 256, (col // 256) % 256, (col // 65536) % 256
			v = math.floor((rr + gg + bb) / 3)
		end
		for dy = 0, 2 do
			for dx = 0, 2 do
				buffer.writeu8(sheet.a, (y * 3 + dy) * sheet.w + x * 3 + dx, v)
			end
		end
	end
end
local head = buffer.create(8)
buffer.writeu32(head, 0, sheet.w)
buffer.writeu32(head, 4, sheet.h)
fs.writeFile("build/art_fx.mask", buffer.tostring(head) .. buffer.tostring(sheet.a))

-- rail tiles: 16 x 16 white masks. h / v straight, tl tr bl br the four bends (centre at that corner)
local T = 16
local function rail(name: string)
	local m = Raster.new(T, T)
	local function item(i)
		Raster.draw(m, i, 1, 0, 0)
	end
	if name == "h" then
		item({ "box", 0, 4, T, 5.6, 0 })
		item({ "box", 0, 10.4, T, 12, 0 })
		for x = 1, T - 1, 4 do
			item({ "box", x, 2.5, x + 1.6, 13.5, 0 })
		end
	elseif name == "v" then
		item({ "box", 4, 0, 5.6, T, 0 })
		item({ "box", 10.4, 0, 12, T, 0 })
		for y = 1, T - 1, 4 do
			item({ "box", 2.5, y, 13.5, y + 1.6, 0 })
		end
	else
		local cx = if name == "tl" or name == "bl" then 0 else T
		local cy = if name == "tl" or name == "tr" then 0 else T
		local a0 = ({ tl = 0, tr = 90, bl = 270, br = 180 })[name]
		item({ "arc", cx, cy, 5, a0, a0 + 90, 1.6 })
		item({ "arc", cx, cy, 11, a0, a0 + 90, 1.6 })
		for k = 0, 4 do
			local a = (a0 + 8 + k * 18.5) * pi / 180
			item({ "line", cx + cos(a) * 3.4, cy + sin(a) * 3.4, cx + cos(a) * 12.6, cy + sin(a) * 12.6, 1.6 })
		end
	end
	return m
end

local out = {
	"-- GENERATED by tools/art/fx.luau: do not edit by hand.",
	"-- The map's effects (palette indices, one atlas laid out as the layer reads it) and rail tiles (white masks), ours.",
	"return {",
	"\tpalette = {",
}
for i = 1, #PALETTE do
	table.insert(out, string.format("\t\t[%d] = 0x%08X,", i, PALETTE[i]))
end
table.insert(out, "\t},")
table.insert(out, "\trows = {")
for _, r in ROWS do
	table.insert(out, string.format("\t\t%s = { x = 0, y = %d, w = %d, h = %d, frames = %d },", r.name, r.y, r.w, r.h, r.frames))
end
table.insert(out, "\t},")
table.insert(out, string.format("\tatlas = { w = %d, h = %d, data = \"%s\" },", width, height, Codec.b64(Codec.rle(atlas))))
table.insert(out, "\trails = {")
for _, name in { "h", "v", "tl", "tr", "bl", "br" } do
	table.insert(out, string.format("\t\t%s = { w = %d, h = %d, data = \"%s\" },", name, T, T, Codec.b64(Codec.rle(rail(name)))))
end
table.insert(out, "\t},")
table.insert(out, "}")
fs.writeFile("src/shared/Art/FxData.luau", table.concat(out, "\n") .. "\n")
print("fx packed", width, height)
