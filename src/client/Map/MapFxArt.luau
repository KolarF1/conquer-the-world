--!nonstrict
-- The map's effects and rail tiles, ours (Art/FxData, drawn by tools/art/fx.luau): the explosion, the conquest flag
-- and banner, the SAM launch, construction dust, fire and smoke as one palette atlas with the layout FxLayer always
-- read (`id` is an ArtRef; each row is { x, y, w, h, frames }), and the rail tiles as an ArtRef each.
local RS = game:GetService("ReplicatedStorage")
local Airfront = RS:WaitForChild("Airfront")
local Pack = require(Airfront:WaitForChild("Art"):WaitForChild("Pack")) :: any
local Data = require(Airfront:WaitForChild("Art"):WaitForChild("FxData")) :: any
local MapArt = require(script.Parent:WaitForChild("MapArt")) :: any

local MapFxArt = {}

local function upload(rgba: buffer, w: number, h: number): any
	local ok, ref = pcall(function()
		local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(w, h) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), rgba)
		return { art = true, content = Content.fromObject(img) }
	end)
	return if ok then ref else { art = true, content = nil }
end

do
	local a = Data.atlas
	local idx = Pack.mask(a.data, a.w, a.h)
	local rgba = buffer.create(a.w * a.h * 4)
	for i = 0, a.w * a.h - 1 do
		local p = Data.palette[buffer.readu8(idx, i)]
		if p ~= nil then
			-- (the palette is 0xAARRGGBB; the image wants R, G, B, A bytes)
			buffer.writeu32(rgba, i * 4, (p // 65536) % 256 + ((p // 256) % 256) * 256 + (p % 256) * 65536 + (p // 16777216) * 16777216)
		end
	end
	MapFxArt.id = upload(rgba, a.w, a.h)
	for name, row in Data.rows do
		MapFxArt[name] = row
	end
	MapFxArt.rails = {}
	for name, r in Data.rails do
		local mask = Pack.mask(r.data, r.w, r.h)
		local white = buffer.create(r.w * r.h * 4)
		Pack.blit_white(white, r.w, mask, r.w, r.h, 0, 0)
		MapFxArt.rails[name] = upload(white, r.w, r.h)
	end
end

MapFxArt.set = MapArt.set

return MapFxArt
