--!nocheck
-- Our art (tools/art, src/shared/Art): the packed glyphs decode to exactly what the rasteriser draws, every
-- icon name the interface asks for exists, and the runtime atlas lays out without gaps. The contact sheet
-- (tools/art/contact.luau) is how the pictures are judged; this keeps the data honest.
-- Run: lune run tests/art_pack.luau
require("./prelude")
local Raster = require("../tools/art/raster")
local Icons = require("../tools/art/icons")
local Pack = require("../src/shared/Art/Pack")
local IconData = require("../src/shared/Art/IconData")
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

-- the packed data is the rasteriser's output
local mismatched, empty = {}, {}
local count = 0
for name, text in IconData.icons do
	count += 1
	local want = Raster.render(Icons[name], IconData.size, IconData.size, 64)
	local got = Pack.mask(text, IconData.size, IconData.size)
	if buffer.tostring(got) ~= buffer.tostring(want.a) then
		table.insert(mismatched, name)
	end
	local lit = 0
	for i = 0, IconData.size * IconData.size - 1 do
		if buffer.readu8(got, i) > 0 then
			lit += 1
		end
	end
	if lit < 150 or lit > IconData.size * IconData.size * 0.9 then
		table.insert(empty, name .. "=" .. lit)
	end
end
expect(#mismatched == 0, "every packed icon equals a fresh render (" .. table.concat(mismatched, ", ") .. ")")
expect(#empty == 0, "no icon is empty or a solid block (" .. table.concat(empty, ", ") .. ")")
expect(count >= 50, count .. " icons")

-- base64 and run-length round trips
local b = Pack.base64("TWFu")
expect(buffer.tostring(b) == "Man", "base64 decodes")
expect(buffer.tostring(Pack.base64("TWE=")) == "Ma" and buffer.tostring(Pack.base64("TQ==")) == "M", "with padding")
local rle = Pack.unrle(buffer.fromstring(string.char(0, 3, 255, 2, 0, 1)), 6)
expect(buffer.readu8(rle, 2) == 0 and buffer.readu8(rle, 3) == 255 and buffer.readu8(rle, 4) == 255 and buffer.readu8(rle, 5) == 0, "run-length decodes")

-- every glyph name the interface can ask for is drawn (names read from the code)
local fs = require("@lune/fs")
local wanted = {}
local function scan(dir: string)
	for _, entry in fs.readDir(dir) do
		local path = dir .. "/" .. entry
		if fs.isDir(path) then
			if entry ~= "Dev" then
				scan(path)
			end
		elseif string.sub(entry, -5) == ".luau" then
			local src = fs.readFile(path)
			for name in string.gmatch(src, 'icon_rect%("([%w_]+)"') do
				wanted[name] = path
			end
			for name in string.gmatch(src, 'UITheme%.icon%("([%w_]+)"') do
				wanted[name] = path
			end
			for name in string.gmatch(src, 'Th%.icon%("([%w_]+)"') do
				wanted[name] = path
			end
			for name in string.gmatch(src, '[%s,{]icon = "([%w_]+)"') do
				wanted[name] = path
			end
		end
	end
end
scan("src/client")
scan("src/shared/Data")
local missing = {}
for name, where in wanted do
	if name ~= "robux" and not ArtAtlas.has(name) then
		table.insert(missing, name .. " (" .. where .. ")")
	end
end
table.sort(missing)
expect(#missing == 0, "every icon the code asks for exists:\n      " .. table.concat(missing, "\n      "))

-- the atlas layout
local rgba, w, h, cells = ArtAtlas.pixels()
expect(w == 8 * 64 and h % 64 == 0 and buffer.len(rgba) == w * h * 4, "atlas is " .. w .. "x" .. h)
local names = ArtAtlas.names()
expect(#names == count, "one cell per icon")
local seen = {}
local clash = false
for _, n in names do
	local key = cells[n][1] .. "," .. cells[n][2]
	clash = clash or seen[key]
	seen[key] = true
end
expect(not clash, "no two icons share a cell")
-- an icon's pixels are white with its coverage as alpha, in its cell
local c = cells.close
local lit = false
for y = 0, 63 do
	for x = 0, 63 do
		local px = buffer.readu32(rgba, ((c[2] + y) * w + c[1] + x) * 4)
		if px // 16777216 > 200 then
			lit = lit or (px % 16777216 == 0xFFFFFF)
		end
	end
end
expect(lit, "an icon's lit pixels are white")
expect(ArtAtlas.icon("close") == nil, "off Roblox no ref is made (callers show no icon)")

-- the map's art (MapData, from tools/art/mapart.luau)
do
	local MapData = require("../src/shared/Art/MapData")
	local Defs = require("../src/shared/Core/Defs")
	expect(#MapData.kinds == Defs.STRUCT_KIND_COUNT, "a plate and a glyph for every structure kind (" .. #MapData.kinds .. ")")
	expect(#MapData.unit_names == 12 and MapData.unit_names[1] == "transport" and MapData.unit_names[12] == "carriage_loaded", "twelve unit sprites in the layer's column order")
	for _, key in { "plate_rim", "plate_inset", "glyphs", "unit_body", "unit_rim" } do
		local e = MapData[key]
		local m = Pack.mask(e.data, e.w, e.h)
		local lit = 0
		for i = 0, e.w * e.h - 1 do
			if buffer.readu8(m, i) > 0 then
				lit += 1
			end
		end
		expect(buffer.len(m) == e.w * e.h and lit > e.w * e.h * 0.03, key .. ": " .. e.w .. "x" .. e.h .. ", " .. lit .. " lit pixels")
	end
	expect(MapData.plate_rim.w == 112 * #MapData.kinds and MapData.plate_rim.h == 112 and MapData.unit_body.w == 32 * 12 and MapData.unit_body.h == 32, "cell sizes are the layers' (112 and 32)")
	-- every unit sprite has a body and an outline
	local ub = Pack.mask(MapData.unit_body.data, MapData.unit_body.w, MapData.unit_body.h)
	local ur = Pack.mask(MapData.unit_rim.data, MapData.unit_rim.w, MapData.unit_rim.h)
	local all = true
	for k = 0, 11 do
		local body, rim = 0, 0
		for y = 0, 31 do
			for x = 0, 31 do
				body += if buffer.readu8(ub, y * 384 + k * 32 + x) > 100 then 1 else 0
				rim += if buffer.readu8(ur, y * 384 + k * 32 + x) > 100 then 1 else 0
			end
		end
		all = all and body >= 8 and rim >= 6
	end
	expect(all, "each unit sprite has a body and a rim")
end

-- the soft art generated on the device (UI/SoftArt): shadows, glows, radial sectors, the spinner
do
	local SoftArt = require("../src/client/UI/SoftArt")
	local function alpha(rgba: buffer, w: number, x: number, y: number): number
		return buffer.readu32(rgba, (y * w + x) * 4) // 16777216
	end
	local sh = SoftArt.shadow_pixels(142, 40, 14)
	expect(alpha(sh, 142, 0, 0) == 0 and alpha(sh, 142, 71, 71) < 20, "a shadow is clear at its edge and faded inside")
	expect(alpha(sh, 142, 71, 40) > 150, "and strongest where the panel's edge is (" .. alpha(sh, 142, 71, 40) .. ")")
	local v = SoftArt.vignette_pixels(64, 36)
	expect(alpha(v, 64, 32, 18) < 5 and alpha(v, 64, 0, 0) > 150, "the vignette is clear in the middle and dark at the corners")
	local g = SoftArt.glow_pixels(64)
	expect(alpha(g, 64, 32, 32) > 240 and alpha(g, 64, 0, 0) == 0, "the glow is bright in the middle and gone at the corners")
	local d = SoftArt.dim_pixels(64, 36)
	expect(alpha(d, 64, 32, 18) >= 120 and alpha(d, 64, 0, 0) > alpha(d, 64, 32, 18), "the dim never clears and deepens towards the edges")
	local lit = 0
	local arrow = SoftArt.arrow_pixels()
	for i = 0, 64 * 64 - 1 do
		lit += if alpha(arrow, 64, i % 64, i // 64) > 128 then 1 else 0
	end
	expect(lit > 600 and lit < 2500, "the arrow head is a solid shape (" .. lit .. " px)")
	for n = 2, 8 do
		for _, kind in { "fill", "line" } do
			local rgba, w, h, cx, cy = SoftArt.segment_pixels(44, 116, n, kind, 2.2)
			local lit2 = 0
			for i = 0, w * h - 1 do
				lit2 += if alpha(rgba, w, i % w, i // w) > 128 then 1 else 0
			end
			expect(lit2 > (if kind == "fill" then 500 else 80) and cx > 0 and cx < w and cy > 0 and cy < h + 200, string.format("sector %d %s: %dx%d, %d lit, centre at %.0f,%.0f", n, kind, w, h, lit2, cx, cy))
		end
	end
	local S = SoftArt.shapes()
	local seg = S.segments["desk_5_fill"]
	expect(seg ~= nil and seg.w > 0 and S.segments["nonsense"] == nil, "the manifest makes a sector by its key")
	expect(S.px == 1 and S.variants.touch.ro == 128, "and keeps the variants the radial menu picks from")
end

-- our flags (Art/Emblem), and the Cosmetics descriptors that ask for them
do
	local Emblem = require("../src/shared/Art/Emblem")
	local Cosmetics = require("../src/shared/Data/Cosmetics")
	local a = Emblem.pixels("fr", Emblem.W, Emblem.H)
	local b2 = Emblem.pixels("fr", Emblem.W, Emblem.H)
	local c = Emblem.pixels("de", Emblem.W, Emblem.H)
	expect(buffer.tostring(a) == buffer.tostring(b2), "a flag is the same every time")
	expect(buffer.tostring(a) ~= buffer.tostring(c), "different keys draw different flags")
	local opaque = true
	for i = 0, Emblem.W * Emblem.H - 1 do
		opaque = opaque and buffer.readu32(a, i * 4) // 16777216 == 255
	end
	expect(opaque, "every pixel is opaque")
	local distinct = {}
	local n = 0
	for _, it in Cosmetics.all() do
		if it.kind == "flag" then
			n += 1
			local px = Emblem.pixels(it.emblem, 24, 16, it.theme)
			distinct[buffer.tostring(px)] = true
		end
	end
	local d = 0
	for _ in distinct do
		d += 1
	end
	expect(n >= 200 and d >= n * 0.8, string.format("%d country flags, %d distinct at thumbnail size", n, d))
	local it = Cosmetics.item("flag_fr")
	local desc = Cosmetics.flag_image(it)
	expect(desc.art and desc.kind == "flag" and desc.key == "fr" and it.x == 0 and it.y == 0 and it.w == Cosmetics.FLAG_W and it.h == Cosmetics.FLAG_H, "a flag item is a descriptor with the whole-image rect")
end

if fails > 0 then
	print("art_pack: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("art_pack: all passed")
