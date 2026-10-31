--!nonstrict
-- Map thumbnails on the device (Art/Thumbs/<id>: terrain bytes packed by tools/art/thumbs.luau), coloured with the
-- in-game palette (MapSurface.terrain_pixel), so a card shows the map as the game draws it. Registers itself as the
-- resolver of the "mapthumb" kind (Art/Registry); a descriptor is { art = true, kind = "mapthumb", id = map id }.
local IS_ROBLOX = typeof(game) == "Instance"
local function art(name: string): any
	if IS_ROBLOX then
		return require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild(name))
	end
	return (require :: any)("../../shared/Art/" .. name)
end
local Registry = art("Registry")
local Pack = art("Pack")

local ThumbArt = {}

local cache: { [string]: any } = {}

--- RGBA pixels (opaque) of the thumbnail `data` ({ w, h, data }) in the palette `colour_of(terrain byte) -> RGBA8`.
function ThumbArt.pixels(data: any, colour_of: (number) -> number): buffer
	local bytes = Pack.mask(data.data, data.w, data.h)
	local rgba = buffer.create(data.w * data.h * 4)
	local lut = {}
	for i = 0, data.w * data.h - 1 do
		local tb = buffer.readu8(bytes, i)
		local c = lut[tb]
		if c == nil then
			c = colour_of(tb)
			lut[tb] = c
		end
		buffer.writeu32(rgba, i * 4, c)
	end
	return rgba
end

function ThumbArt.resolve(desc: any): any
	local ref = cache[desc.id]
	if ref ~= nil then
		return ref
	end
	ref = { art = true, content = nil, offset = Vector2.zero, size = Vector2.zero }
	if IS_ROBLOX then
		pcall(function()
			local data = require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("Thumbs"):WaitForChild(desc.id)) -- (a folder of one module per map)
			local MapSurface = require((script :: any).Parent.Parent:WaitForChild("Map"):WaitForChild("MapSurface"))
			local rgba = ThumbArt.pixels(data, MapSurface.terrain_pixel)
			local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(data.w, data.h) })
			img:WritePixelsBuffer(Vector2.zero, Vector2.new(data.w, data.h), rgba)
			ref.content = Content.fromObject(img)
		end)
	end
	cache[desc.id] = ref
	return ref
end

Registry.register("mapthumb", ThumbArt.resolve)

return ThumbArt
