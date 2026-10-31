--!nonstrict
-- Our flags on the device: turns a flag descriptor (Data/Cosmetics.flag_image: { art, kind = "flag", key, theme, w,
-- h }) into an EditableImage of Art/Emblem's heraldic emblem, once per flag and size, and registers itself as the
-- resolver for the kind (Art/Registry). Loading this module is what registers it.
local IS_ROBLOX = typeof(game) == "Instance"
local function shared(name: string): any
	if IS_ROBLOX then
		return require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild(name))
	end
	return (require :: any)("../../shared/Art/" .. name)
end
local Registry = shared("Registry")
local Emblem = shared("Emblem")

local FlagArt = {}

local cache: { [string]: any } = {}

--- The ArtRef of a flag descriptor (nil content when no EditableImage can be made: callers show nothing).
function FlagArt.resolve(desc: any): any
	local id = string.format("%s:%s:%d", tostring(desc.key), tostring(desc.theme or ""), desc.w)
	local ref = cache[id]
	if ref ~= nil then
		return ref
	end
	ref = { art = true, content = nil, offset = Vector2.zero, size = Vector2.new(desc.w, desc.h) }
	if IS_ROBLOX then
		pcall(function()
			local rgba = Emblem.pixels(tostring(desc.key), desc.w, desc.h, desc.theme)
			local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(desc.w, desc.h) })
			img:WritePixelsBuffer(Vector2.zero, Vector2.new(desc.w, desc.h), rgba)
			ref.content = Content.fromObject(img)
		end)
	end
	cache[id] = ref
	return ref
end

Registry.register("flag", FlagArt.resolve)

return FlagArt
