--!strict
-- The map's art, ours: structure plates (a silhouette per kind, a rim and an inset), glyphs, and the units'
-- 13 px sprites (pointing right; the layer rotates them). Writes src/shared/Art/MapData.luau (packed
-- masks) and build/art_map.mask (a contact sheet for tools/art/mask_to_png.py).
-- Run: lune run tools/art/mapart.luau
local fs = require("@lune/fs")
local Raster = require("./raster")
local Icons = require("./icons")
local Pack = require("./codec")

local pi, cos, sin = math.pi, math.cos, math.sin

-- structure kinds in Defs.S_* order
local KINDS = { "city", "port", "factory", "defense", "sam", "silo", "artillery", "airfield", "railgun" }
local CELL = 112

--- A regular n-gon scaled about the cell centre (shrink: pixels taken off the radius).
local function ngon(n: number, rot: number, shrink: number, r0: number?): { any }
	local r = (r0 or 50) - shrink
	local pts: { any } = { "poly" }
	for i = 0, n - 1 do
		local a = rot + (i / n) * 2 * pi
		table.insert(pts, 56 + cos(a) * r)
		table.insert(pts, 56 + sin(a) * r)
	end
	return pts
end

-- The plates fill 70% of their 112 px cell, centred: the layer sizes a plate from the cell (the upstream's art had the
-- same margin), and a full-cell plate came out 1.4x too big next to its progress bar (seen in Studio, 2026-10-31).
local FILL = 0.7
local function scaled(item: { any }): { any }
	local out = { item[1] }
	local op = item[1]
	local function sc(v: number): number
		return 56 + (v - 56) * FILL
	end
	if op == "circle" then
		out[2], out[3], out[4] = sc(item[2]), sc(item[3]), item[4] * FILL
	elseif op == "box" then
		out[2], out[3], out[4], out[5], out[6] = sc(item[2]), sc(item[3]), sc(item[4]), sc(item[5]), (item[6] or 0) * FILL
	else
		for i = 2, #item do
			out[i] = sc(item[i])
		end
	end
	return out
end

--- The plate silhouette of kind `k` (1-based) inset by `s` px.
local function plate_raw(k: number, s: number): { any }
	local name = KINDS[k]
	if name == "city" then
		return { "box", 8 + s, 8 + s, 104 - s, 104 - s, 24 - s * 0.6 }
	elseif name == "port" then
		return { "circle", 56, 56, 50 - s }
	elseif name == "factory" then
		return ngon(8, pi / 8, s, 52)
	elseif name == "defense" then
		return {
			"poly",
			56, 6 + s,
			104 - s, 22 + s * 0.6,
			104 - s, 56,
			56, 106 - s,
			8 + s, 56,
			8 + s, 22 + s * 0.6,
		}
	elseif name == "sam" then
		return { "poly", 56, 4 + s, 106 - s, 56, 56, 108 - s, 6 + s, 56 }
	elseif name == "silo" then
		return ngon(6, 0, s, 52)
	elseif name == "artillery" then
		return { "poly", 56, 6 + s * 1.4, 106 - s * 1.3, 96 - s * 0.6, 6 + s * 1.3, 96 - s * 0.6 }
	elseif name == "airfield" then
		return { "box", 4 + s, 22 + s, 108 - s, 90 - s, 34 - s }
	end
	-- railgun: a home-plate pentagon
	return { "poly", 8 + s, 12 + s, 104 - s, 12 + s, 104 - s, 66, 56, 106 - s, 8 + s, 66 }
end

-- structure plates: rim strip and inset strip, 9 cells of 112 px
local function plate(k: number, s: number): { any }
	return scaled(plate_raw(k, s))
end

local rim = Raster.new(CELL * #KINDS, CELL)
local inset = Raster.new(CELL * #KINDS, CELL)
for k = 1, #KINDS do
	local r = Raster.new(CELL, CELL)
	Raster.draw(r, plate(k, 0), 1, 0, 0)
	Raster.blit(rim, r, (k - 1) * CELL, 0)
	local i = Raster.new(CELL, CELL)
	Raster.draw(i, plate(k, 10 / FILL), 1, 0, 0)
	Raster.blit(inset, i, (k - 1) * CELL, 0)
end

-- glyphs: the structure icons, 64 px, one strip
local GL = 64
local glyphs = Raster.new(GL * #KINDS, GL)
for k, name in KINDS do
	Raster.blit(glyphs, Raster.render(Icons[name], GL, GL, 64), (k - 1) * GL, 0)
end

-- units, 13 x 13, pointing right: transport, trade, warship, atom, hydrogen, mirv, sam, shell, warhead, train,
-- carriage, carriage_loaded
local UNITS = {
	transport = { { "poly", 0.8, 4, 9, 4, 12.4, 6.5, 9, 9.2, 0.8, 9.2 }, { "box", 2.6, 1.8, 6.4, 4.6, 0.4 } },
	trade = { { "poly", 0.8, 5, 9, 5, 12.4, 7, 9, 9.6, 0.8, 9.6 }, { "box", 2, 2.2, 5.2, 5.2, 0.3 }, { "box", 5.8, 3, 8.6, 5.2, 0.3 } },
	warship = { { "poly", 0.4, 4.4, 10, 4.4, 12.8, 6.5, 10, 8.6, 0.4, 8.6 }, { "circle", 5, 6.5, 2 }, { "line", 5, 6.5, 9.6, 6.5, 1.2 } },
	atom = { { "box", 1.8, 4.8, 9, 8.2, 1.4 }, { "poly", 9, 4.8, 12.6, 6.5, 9, 8.2 }, { "poly", 1.8, 4.8, 0.4, 2.4, 4.6, 4.8 }, { "poly", 1.8, 8.2, 0.4, 10.6, 4.6, 8.2 } },
	hydrogen = { { "box", 1.4, 4.2, 9, 8.8, 1.6 }, { "poly", 9, 4.2, 12.8, 6.5, 9, 8.8 }, { "poly", 1.4, 4.2, 0.2, 1.6, 4.8, 4.2 }, { "poly", 1.4, 8.8, 0.2, 11.4, 4.8, 8.8 } },
	mirv = { { "box", 1.6, 5, 9, 8, 1.2 }, { "poly", 9, 5, 12.6, 6.5, 9, 8 }, { "circle", 4, 2.6, 1.3 }, { "circle", 4, 10.4, 1.3 }, { "circle", 8, 1.8, 1.1 }, { "circle", 8, 11.2, 1.1 } },
	sam = { { "box", 1.4, 5.6, 9.6, 7.4, 0.8 }, { "poly", 9.6, 5.6, 12.6, 6.5, 9.6, 7.4 }, { "poly", 1.4, 5.6, 0.2, 3.4, 3.8, 5.6 }, { "poly", 1.4, 7.4, 0.2, 9.6, 3.8, 7.4 } },
	shell = { { "circle", 7.5, 6.5, 2.6 }, { "line", 2, 6.5, 5, 6.5, 1.6 } },
	warhead = { { "poly", 1.5, 4.6, 11.5, 6.5, 1.5, 8.4 } },
	train = { { "box", 0.8, 4, 10, 9, 1 }, { "poly", 10, 4, 12.5, 6.5, 10, 9 }, { "box", 2, 2.2, 5, 4.2, 0.4 } },
	carriage = { { "box", 0.8, 4.4, 12.2, 8.6, 0.8 } },
	carriage_loaded = { { "box", 0.8, 5, 12.2, 9, 0.8 }, { "box", 2.2, 2.6, 10.8, 5.2, 0.5 } },
}
local UNIT_ORDER = { "transport", "trade", "warship", "atom", "hydrogen", "mirv", "sam", "shell", "warhead", "train", "carriage", "carriage_loaded" }
local UC = 13
local body = Raster.new(UC * #UNIT_ORDER, UC)
local rimu = Raster.new(UC * #UNIT_ORDER, UC)
for k, name in UNIT_ORDER do
	local m = Raster.new(UC, UC)
	for _, item in UNITS[name] do
		Raster.draw(m, item, 1, 0, 0)
	end
	-- outline: one pixel round the body (dilate, take the body away)
	local o = Raster.new(UC, UC)
	for y = 0, UC - 1 do
		for x = 0, UC - 1 do
			local near = 0
			for dy = -1, 1 do
				for dx = -1, 1 do
					local sx, sy = x + dx, y + dy
					if sx >= 0 and sy >= 0 and sx < UC and sy < UC then
						near = math.max(near, buffer.readu8(m.a, sy * UC + sx))
					end
				end
			end
			local here = buffer.readu8(m.a, y * UC + x)
			buffer.writeu8(o.a, y * UC + x, math.max(0, near - here))
		end
	end
	Raster.blit(body, m, (k - 1) * UC, 0)
	Raster.blit(rimu, o, (k - 1) * UC, 0)
end

-- the data module
local function entry(name: string, m: Raster.Mask): string
	return string.format("\t%s = { w = %d, h = %d, data = \"%s\" },", name, m.w, m.h, Pack.b64(Pack.rle(m)))
end
local out = {
	"-- GENERATED by tools/art/mapart.luau: do not edit by hand.",
	"-- The map's art, ours: run-length coverage masks in base64 (Art/Pack decodes them).",
	"return {",
	"\tkinds = { " .. (function()
		local t = {}
		for _, k in KINDS do
			table.insert(t, '"' .. k .. '"')
		end
		return table.concat(t, ", ")
	end)() .. " },",
	"\tunit_names = { " .. (function()
		local t = {}
		for _, k in UNIT_ORDER do
			table.insert(t, '"' .. k .. '"')
		end
		return table.concat(t, ", ")
	end)() .. " },",
	entry("plate_rim", rim),
	entry("plate_inset", inset),
	entry("glyphs", glyphs),
	entry("unit_body", body),
	entry("unit_rim", rimu),
	"}",
}
fs.writeFile("src/shared/Art/MapData.luau", table.concat(out, "\n") .. "\n")

-- contact sheet: plates with glyphs over them in a few colours, and the units enlarged 8x
local cols = { 255, 190, 120 }
local sheet = Raster.new(UC * 8 * #UNIT_ORDER + 16, CELL * 3 + 16 + UC * 8 + 24)
for row = 1, 3 do
	for k = 1, #KINDS do
		local x0 = 8 + (k - 1) * CELL
		local y0 = 8 + (row - 1) * CELL
		for y = 0, CELL - 1 do
			for x = 0, CELL - 1 do
				local r = buffer.readu8(rim.a, y * rim.w + (k - 1) * CELL + x)
				local i = buffer.readu8(inset.a, y * inset.w + (k - 1) * CELL + x)
				local v = math.max(r // 3, i * cols[row] // 255)
				local gx, gy = x - 24, y - 24
				local gv = 0
				if gx >= 0 and gy >= 0 and gx < 64 and gy < 64 then
					gv = buffer.readu8(glyphs.a, gy * glyphs.w + (k - 1) * GL + gx)
				end
				local val = if gv > 0 then math.max(0, v - gv // 2) else v
				buffer.writeu8(sheet.a, (y0 + y) * sheet.w + x0 + x, val)
			end
		end
	end
end
for k = 1, #UNIT_ORDER do
	for y = 0, UC - 1 do
		for x = 0, UC - 1 do
			local b = buffer.readu8(body.a, y * body.w + (k - 1) * UC + x)
			local r = buffer.readu8(rimu.a, y * rimu.w + (k - 1) * UC + x)
			local v = math.max(b, r // 2)
			for dy = 0, 7 do
				for dx = 0, 7 do
					local px, py = 8 + (k - 1) * UC * 8 + x * 8 + dx, 8 + CELL * 3 + 8 + y * 8 + dy
					if px < sheet.w then
						buffer.writeu8(sheet.a, py * sheet.w + px, v)
					end
				end
			end
		end
	end
end
local head = buffer.create(8)
buffer.writeu32(head, 0, sheet.w)
buffer.writeu32(head, 4, sheet.h)
fs.writeFile("build/art_map.mask", buffer.tostring(head) .. buffer.tostring(sheet.a))
print("map art packed")
