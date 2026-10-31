--!nonstrict
-- Our own art on the device: the packed glyph masks (shared/Art/IconData, drawn by tools/art and checked in
-- contact sheets) decoded and uploaded once into one EditableImage atlas. No asset id is involved, so
-- nothing depends on an upload or on an account's permissions. An ArtRef is { art = true, content, offset,
-- size }; `apply` puts a ref (or a legacy string id) on an ImageLabel. Without EditableImage (Lune, a
-- refused allocation) `icon` returns nil and every caller already degrades to "no icon".
local IS_ROBLOX = typeof(game) == "Instance"
local Pack = if IS_ROBLOX
	then require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("Pack"))
	else (require :: any)("../../shared/Art/Pack")
local IconData = if IS_ROBLOX
	then require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("IconData"))
	else (require :: any)("../../shared/Art/IconData")

local Registry = if IS_ROBLOX
	then require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("Registry"))
	else (require :: any)("../../shared/Art/Registry")
-- (loading FlagArt registers the flag resolver)
local FlagArt = if IS_ROBLOX then require((script :: any).Parent:WaitForChild("FlagArt")) else (require :: any)("./FlagArt")
local ThumbArt = if IS_ROBLOX then require((script :: any).Parent:WaitForChild("ThumbArt")) else (require :: any)("./ThumbArt")

local ArtAtlas = {}

ArtAtlas.COLS = 8

local _built = false
local _refs: { [string]: any } = {}
local _failed = false

--- Names of every glyph in the atlas, sorted (the layout order).
function ArtAtlas.names(): { string }
	local out = {}
	for k in IconData.icons do
		table.insert(out, k)
	end
	table.sort(out)
	return out
end

--- The atlas pixel size and the cell of glyph number `i` (1-based).
function ArtAtlas.layout(count: number): (number, number)
	local rows = math.ceil(count / ArtAtlas.COLS)
	return ArtAtlas.COLS * IconData.size, rows * IconData.size
end

--- The atlas as RGBA bytes (white, coverage in alpha) and each glyph's cell offset: the part that needs
--- no Roblox (the tests run it).
function ArtAtlas.pixels()
	local names = ArtAtlas.names()
	local size = IconData.size
	local w, h = ArtAtlas.layout(#names)
	local rgba = buffer.create(w * h * 4)
	local cells = {}
	for i, name in names do
		local cx, cy = ((i - 1) % ArtAtlas.COLS) * size, ((i - 1) // ArtAtlas.COLS) * size
		Pack.blit_white(rgba, w, Pack.mask(IconData.icons[name], size, size), size, size, cx, cy)
		cells[name] = { cx, cy }
	end
	return rgba, w, h, cells
end

local function build()
	if _built then
		return
	end
	_built = true
	if not IS_ROBLOX then
		return
	end
	local ok = pcall(function()
		local rgba, w, h, cells = ArtAtlas.pixels()
		local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(w, h) })
		img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), rgba)
		local content = Content.fromObject(img)
		local s = IconData.size
		for name, c in cells do
			_refs[name] = { art = true, content = content, offset = Vector2.new(c[1], c[2]), size = Vector2.new(s, s) }
		end
	end)
	if not ok then
		_failed = true
		table.clear(_refs)
	end
end

--- The ref of glyph `name` (an alias resolves), or nil.
function ArtAtlas.icon(name: string): any?
	build()
	return _refs[IconData.aliases[name] or name]
end

--- True when `name` is one of ours (an atlas or not: a name check for tests).
function ArtAtlas.has(name: string): boolean
	return IconData.icons[IconData.aliases[name] or name] ~= nil
end

--- Puts `ref` on `label`: an ArtRef as content + rect, a string as its id, nil as no image.
function ArtAtlas.apply(label: any, ref: any)
	ref = Registry.resolve(ref)
	if type(ref) == "table" and ref.art == true then
		if ref.content ~= nil then
			label.ImageContent = ref.content
		end
		label.ImageRectOffset = ref.offset or Vector2.zero
		label.ImageRectSize = ref.size or Vector2.zero
	else
		-- (an ImageLabel that held an EditableImage can stay stuck on it when a string id is set next: clear the
		-- content first, DevForum "ImageContent bugs after switching from URI to Object to URI")
		if IS_ROBLOX then
			pcall(function()
				label.ImageContent = Content.none
			end)
		end
		label.Image = if type(ref) == "string" then ref else ""
		if IS_ROBLOX then
			label.ImageRectOffset = Vector2.zero
			label.ImageRectSize = Vector2.zero
		end
	end
end

return ArtAtlas
