--!nonstrict
-- Renders every map thumbnail (Art/Thumbs/*) with the in-game palette into build/art_thumbs.rgba. Run: lune run tools/art/thumb_sheet.luau
local fs = require("@lune/fs")
local roblox = require("../../tests/prelude");
(getfenv() :: any).Instance = (roblox :: any).Instance;
(getfenv() :: any).Enum = (roblox :: any).Enum;
(getfenv() :: any).task = require("@lune/task");
(getfenv() :: any).warn = function() end
local MapSurface = require("../../src/client/Map/MapSurface")
local ThumbArt = require("../../src/client/UI/ThumbArt")
local ids = { "africa", "asia", "europe", "northamerica", "southamerica", "world" }
local sw, sh = 3 * 168 + 8, 2 * 168 + 8
local sheet = buffer.create(sw * sh * 4)
buffer.fill(sheet, 0, 0x14)
for i, id in ids do
	local data = require("../../src/shared/Art/Thumbs/" .. id)
	local px = ThumbArt.pixels(data, MapSurface.terrain_pixel)
	local x0, y0 = 8 + ((i - 1) % 3) * 168, 8 + ((i - 1) // 3) * 168
	for y = 0, data.h - 1 do
		for x = 0, data.w - 1 do
			buffer.writeu32(sheet, ((y0 + y) * sw + x0 + x) * 4, buffer.readu32(px, (y * data.w + x) * 4))
		end
	end
end
local head = buffer.create(8)
buffer.writeu32(head, 0, sw)
buffer.writeu32(head, 4, sh)
fs.writeFile("build/art_thumbs.rgba", buffer.tostring(head) .. buffer.tostring(sheet))
print("ok")
