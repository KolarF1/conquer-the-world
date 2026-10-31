--!strict
-- Renders every icon into a contact sheet (build/art_icons.rgba + .txt of the names in order) for
-- tools/art/rgba_to_png.py. Run: lune run tools/art/contact.luau [cell_px]
local fs = require("@lune/fs")
local process = require("@lune/process")
local Raster = require("./raster")
local Icons = require("./icons")

local cell = tonumber(process.args[1]) or 96
local names = {}
for k in Icons do
	if k ~= "ALIASES" then
		table.insert(names, k)
	end
end
table.sort(names)
local cols = 10
local rows = math.ceil(#names / cols)
local W, H = cols * (cell + 8) + 8, rows * (cell + 8) + 8
local sheet = Raster.new(W, H)
for i, name in names do
	local m = Raster.render(Icons[name], cell, cell, 64)
	local cx, cy = (i - 1) % cols, (i - 1) // cols
	Raster.blit(sheet, m, 8 + cx * (cell + 8), 8 + cy * (cell + 8))
end
local head = buffer.create(8)
buffer.writeu32(head, 0, W)
buffer.writeu32(head, 4, H)
fs.writeFile("build/art_icons.mask", buffer.tostring(head) .. buffer.tostring(sheet.a))
fs.writeFile("build/art_icons.txt", table.concat(names, "\n"))
print(string.format("%d icons, sheet %dx%d", #names, W, H))
