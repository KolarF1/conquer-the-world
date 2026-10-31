--!nonstrict
-- Renders SoftArt samples into a contact sheet (build/art_soft.mask): radial sectors (fill and line) for n = 3 and 5,
-- a shadow and a glow. Run: lune run tools/art/soft_sheet.luau
local fs = require("@lune/fs")
local roblox = require("../../tests/prelude")
local SoftArt = require("../../src/client/UI/SoftArt")
local Raster = require("./raster")
local sheet = Raster.new(900, 300)
local function place(rgba, w, h, x0, y0)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local a = buffer.readu32(rgba, (y * w + x) * 4) // 16777216
			if x0 + x < sheet.w and y0 + y < sheet.h then
				buffer.writeu8(sheet.a, (y0 + y) * sheet.w + x0 + x, math.max(buffer.readu8(sheet.a, (y0 + y) * sheet.w + x0 + x), a))
			end
		end
	end
end
local x = 4
for _, n in { 3, 5 } do
	for _, kind in { "fill", "line" } do
		local rgba, w, h = SoftArt.segment_pixels(44, 116, n, kind, 2.2)
		place(rgba, w, h, x, 4)
		x += w + 4
	end
end
place(SoftArt.shadow_pixels(142, 40, 14), 142, 142, 4, 150)
place(SoftArt.glow_pixels(128), 128, 128, 160, 160)
place(SoftArt.disc_pixels(128), 128, 128, 300, 160)
place(SoftArt.arrow_pixels(), 64, 64, 440, 160)
place(SoftArt.spinner_ring_pixels(), 64, 64, 520, 160)
place(SoftArt.spinner_arc_pixels(), 64, 64, 600, 160)
local head = buffer.create(8)
buffer.writeu32(head, 0, sheet.w)
buffer.writeu32(head, 4, sheet.h)
fs.writeFile("build/art_soft.mask", buffer.tostring(head) .. buffer.tostring(sheet.a))
print("ok")
