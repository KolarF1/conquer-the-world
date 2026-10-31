--!nonstrict
-- Soft and shaped UI art made on the device, small and cheap, none of it an asset id: the panel shadows (9-slice),
-- the title's vignette and glow, the dim behind the result screen, a disc glow, the coach's arrow head, the
-- spinner's ring and arc, and the radial menu's sector masks. Each generator is a pure function from its
-- parameters to RGBA bytes (white, coverage in alpha: the interface tints it), so the tests run them under
-- Lune; `ref` uploads one into an EditableImage once and keeps it.
local IS_ROBLOX = typeof(game) == "Instance"
local Raster = if IS_ROBLOX
	then require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("Raster"))
	else (require :: any)("../../shared/Art/Raster")
local Pack = if IS_ROBLOX
	then require((game:GetService("ReplicatedStorage"):WaitForChild("Airfront") :: any):WaitForChild("Art"):WaitForChild("Pack"))
	else (require :: any)("../../shared/Art/Pack")

local SoftArt = {}

local sqrt, max, min, floor, abs, atan2, pi, sin, cos = math.sqrt, math.max, math.min, math.floor, math.abs, math.atan2, math.pi, math.sin, math.cos

local function put(rgba: buffer, i: number, a: number)
	buffer.writeu32(rgba, i * 4, 0x00FFFFFF + floor(max(0, min(1, a)) * 255 + 0.5) * 16777216)
end

local function smooth(e0: number, e1: number, x: number): number
	local t = max(0, min(1, (x - e0) / (e1 - e0)))
	return t * t * (3 - 2 * t)
end

--- A panel shadow for the 9-slice: a rounded rectangle of half-extent (size / 2 - feather) with corner `radius`,
--- falling off outside over `feather` px and fading out a few px inside (the panel's own fill sits there).
function SoftArt.shadow_pixels(size: number, feather: number, radius: number): buffer
	local rgba = buffer.create(size * size * 4)
	local c = (size - 1) * 0.5
	local half = size * 0.5 - feather
	local r = min(radius, half)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local qx, qy = abs(x - c) - (half - r), abs(y - c) - (half - r)
			local d = sqrt(max(qx, 0) ^ 2 + max(qy, 0) ^ 2) + min(max(qx, qy), 0) - r
			local a
			if d >= 0 then
				a = (1 - min(d / feather, 1)) ^ 2.2 * 0.9
			else
				a = 0.9 * smooth(-feather * 0.45, 0, d)
			end
			put(rgba, y * size + x, a)
		end
	end
	return rgba
end

--- The title's vignette: clear in the middle, dark at the edges.
function SoftArt.vignette_pixels(w: number, h: number): buffer
	local rgba = buffer.create(w * h * 4)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local dx, dy = (x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1
			put(rgba, y * w + x, smooth(0.45, 1.25, sqrt(dx * dx + dy * dy)) * 0.9)
		end
	end
	return rgba
end

--- A glow: bright in the middle, gone at the edge.
function SoftArt.glow_pixels(size: number): buffer
	local rgba = buffer.create(size * size * 4)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx, dy = (x + 0.5) / size * 2 - 1, (y + 0.5) / size * 2 - 1
			put(rgba, y * size + x, (1 - min(sqrt(dx * dx + dy * dy), 1)) ^ 2.2)
		end
	end
	return rgba
end

--- The dim behind the result screen: darker towards the edges, never clear.
function SoftArt.dim_pixels(w: number, h: number): buffer
	local rgba = buffer.create(w * h * 4)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local dx, dy = (x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1
			put(rgba, y * w + x, 0.5 + 0.4 * smooth(0.2, 1.3, sqrt(dx * dx + dy * dy)))
		end
	end
	return rgba
end

--- A round panel's soft shadow: the disc (26 of 36 of the radius) solid, then falling off.
function SoftArt.disc_pixels(size: number): buffer
	local rgba = buffer.create(size * size * 4)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx, dy = (x + 0.5) / size * 2 - 1, (y + 0.5) / size * 2 - 1
			local r = sqrt(dx * dx + dy * dy)
			put(rgba, y * size + x, if r <= 26 / 36 then 0.9 else 0.9 * (1 - smooth(26 / 36, 1, r)))
		end
	end
	return rgba
end

local function shape_pixels(items: { any }, size: number, grid: number): buffer
	local m = Raster.render(items, size, size, grid)
	local rgba = buffer.create(size * size * 4)
	Pack.blit_white(rgba, size, m.a, size, size, 0, 0)
	return rgba
end

--- The coach's arrow head (a rounded triangle pointing down, 64 px).
function SoftArt.arrow_pixels(): buffer
	return shape_pixels({ { "poly", 8, 12, 56, 12, 32, 54 } }, 64, 64)
end

--- The spinner: the faint full ring and the 1.9 rad arc from angle 0 (right, clockwise), 64 px.
function SoftArt.spinner_ring_pixels(): buffer
	return shape_pixels({ { "ring", 32, 32, 26, 7 } }, 64, 64)
end

function SoftArt.spinner_arc_pixels(): buffer
	return shape_pixels({ { "arc", 32, 32, 26, 0, 1.9 * 180 / pi, 7 } }, 64, 64)
end

--- Crate-opening light: radiating rays, a four-point flare, a thin ring, a small sparkle, a streak and a beam.
function SoftArt.rays_pixels(size: number): buffer
	local rgba = buffer.create(size * size * 4)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx, dy = (x + 0.5) / size * 2 - 1, (y + 0.5) / size * 2 - 1
			local r = sqrt(dx * dx + dy * dy)
			local th = atan2(dy, dx)
			local ray = (0.5 + 0.5 * cos(th * 16)) ^ 3
			put(rgba, y * size + x, if r >= 1 then 0 else ray * (1 - r) ^ 1.1)
		end
	end
	return rgba
end

function SoftArt.flare_pixels(size: number): buffer
	local rgba = buffer.create(size * size * 4)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx, dy = abs((x + 0.5) / size * 2 - 1), abs((y + 0.5) / size * 2 - 1)
			local h = max(0, 1 - dx) ^ 2.5 * max(0, 1 - dy * 7) ^ 1.5
			local v = max(0, 1 - dy) ^ 2.5 * max(0, 1 - dx * 7) ^ 1.5
			local core = max(0, 1 - sqrt(dx * dx + dy * dy) * 3) ^ 2
			put(rgba, y * size + x, max(h, v, core))
		end
	end
	return rgba
end

function SoftArt.ring_pixels(size: number): buffer
	local rgba = buffer.create(size * size * 4)
	for y = 0, size - 1 do
		for x = 0, size - 1 do
			local dx, dy = (x + 0.5) / size * 2 - 1, (y + 0.5) / size * 2 - 1
			local r = sqrt(dx * dx + dy * dy)
			put(rgba, y * size + x, max(0, 1 - abs(r - 0.82) / 0.07) ^ 1.5)
		end
	end
	return rgba
end

function SoftArt.streak_pixels(w: number, h: number): buffer
	local rgba = buffer.create(w * h * 4)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local dx, dy = (x + 0.5) / w * 2 - 1, (y + 0.5) / h * 2 - 1
			put(rgba, y * w + x, max(0, 1 - abs(dy)) ^ 2.5 * max(0, 1 - abs(dx)) ^ 0.7)
		end
	end
	return rgba
end

function SoftArt.beam_pixels(w: number, h: number): buffer
	local rgba = buffer.create(w * h * 4)
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local dx, dy = (x + 0.5) / w * 2 - 1, (y + 0.5) / h
			put(rgba, y * w + x, max(0, 1 - abs(dx)) ^ 2.2 * smooth(0, 0.25, dy) * (1 - smooth(0.6, 1, dy)))
		end
	end
	return rgba
end

--- A radial menu sector (the ring centred on "up"): `kind` "fill" (the solid sector) or "line" (its outline),
--- for a ring of inner radius ri / outer ro (logical px, one image px each), n segments with a gap. Returns
--- the pixels, the image size and where the ring's centre is inside it.
function SoftArt.segment_pixels(ri: number, ro: number, n: number, kind: string, gap_deg: number)
	local span = 2 * pi / n
	local half = span * 0.5 - (gap_deg * pi / 180) * 0.5
	-- the crop: the sector's corners and its arc's extremes
	local xs, ys = {}, {}
	for i = 0, 16 do
		local th = -half + (i / 16) * 2 * half
		for _, r in { ri, ro } do
			table.insert(xs, sin(th) * r)
			table.insert(ys, -cos(th) * r)
		end
	end
	local x0, x1, y0, y1 = min(table.unpack(xs)), max(table.unpack(xs)), min(table.unpack(ys)), max(table.unpack(ys))
	local pad = 3
	local w, h = math.ceil(x1 - x0) + 2 * pad, math.ceil(y1 - y0) + 2 * pad
	local cx, cy = -x0 + pad, -y0 + pad
	local rgba = buffer.create(w * h * 4)
	local stroke = 1.6
	for y = 0, h - 1 do
		for x = 0, w - 1 do
			local px, py = x + 0.5 - cx, y + 0.5 - cy
			local r = sqrt(px * px + py * py)
			local th = atan2(px, -py)
			-- distance to the sector's boundary (negative inside)
			local dr = max(ri - r, r - ro)
			local dth = (abs(th) - half) * r
			local d = max(dr, dth)
			local a
			if kind == "fill" then
				a = max(0, min(1, 0.5 - d))
			else
				a = max(0, min(1, 0.5 - (abs(d + stroke * 0.5) - stroke * 0.5)))
			end
			put(rgba, y * w + x, a)
		end
	end
	return rgba, w, h, cx, cy
end

-- upload ---------------------------------------------------------------------------------------

local _refs: { [string]: any } = {}

--- An EditableImage of what `make` returns (rgba, w, h) as an ArtRef, made once per `key`.
function SoftArt.ref(key: string, make: () -> (buffer, number, number)): any
	local r = _refs[key]
	if r ~= nil then
		return r
	end
	r = { art = true, content = nil }
	if IS_ROBLOX then
		local ok = pcall(function()
			local rgba, w, h = make()
			local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(w, h) })
			img:WritePixelsBuffer(Vector2.zero, Vector2.new(w, h), rgba)
			r.content = Content.fromObject(img)
		end)
		if not ok then
			r.content = nil
		end
	end
	_refs[key] = r
	return r
end

--- The 9-slice shadow for a manifest entry { feather, radius, size, slice }.
function SoftArt.shadow(e: any): any
	return SoftArt.ref(string.format("shadow:%d:%d:%d", e.size, e.feather, e.radius), function()
		return SoftArt.shadow_pixels(e.size, e.feather, e.radius), e.size, e.size
	end)
end

--- The shapes manifest the interface reads (UICtx.shapes): the radial variants and a lazily made sector
--- per key ("desk_5_fill"), plus the soft images, each an ArtRef made on first use.
function SoftArt.shapes(): any
	local S = {
		px = 1,
		gap_deg = 2.2,
		variants = {
			desk = { ri = 44, ro = 116 },
			desk_hov = { ri = 44, ro = 122 },
			touch = { ri = 50, ro = 128 },
			touch_hov = { ri = 50, ro = 134 },
		},
	}
	local segments = {}
	S.segments = setmetatable(segments, {
		__index = function(t, key)
			local variant, n, kind = string.match(key, "^(.-)_(%d+)_(%a+)$")
			local v = variant and S.variants[variant]
			if v == nil then
				return nil
			end
			local rgba, w, h, cx, cy = SoftArt.segment_pixels(v.ri, v.ro, tonumber(n), kind, S.gap_deg)
			local entry = { w = w, h = h, cx = cx, cy = cy, x = 0, y = 0 }
			entry.ref = SoftArt.ref("seg:" .. key, function()
				return rgba, w, h
			end)
			rawset(t, key, entry)
			return entry
		end,
	})
	local lazy = {
		title_vignette = function()
			return SoftArt.ref("vignette", function()
				return SoftArt.vignette_pixels(256, 144), 256, 144
			end)
		end,
		title_glow = function()
			return SoftArt.ref("glow", function()
				return SoftArt.glow_pixels(128), 128, 128
			end)
		end,
		over_dim = function()
			return SoftArt.ref("dim", function()
				return SoftArt.dim_pixels(256, 144), 256, 144
			end)
		end,
		disc_glow = function()
			return SoftArt.ref("disc", function()
				return SoftArt.disc_pixels(128), 128, 128
			end)
		end,
		arrow_head = function()
			return SoftArt.ref("arrow", function()
				return SoftArt.arrow_pixels(), 64, 64
			end)
		end,
		crate_rays = function()
			return SoftArt.ref("crate_rays", function()
				return SoftArt.rays_pixels(256), 256, 256
			end)
		end,
		crate_flare = function()
			return SoftArt.ref("crate_flare", function()
				return SoftArt.flare_pixels(128), 128, 128
			end)
		end,
		crate_ring = function()
			return SoftArt.ref("crate_ring", function()
				return SoftArt.ring_pixels(256), 256, 256
			end)
		end,
		crate_sparkle = function()
			return SoftArt.ref("crate_sparkle", function()
				return SoftArt.flare_pixels(64), 64, 64
			end)
		end,
		crate_streak = function()
			return SoftArt.ref("crate_streak", function()
				return SoftArt.streak_pixels(96, 24), 96, 24
			end)
		end,
		crate_beam = function()
			return SoftArt.ref("crate_beam", function()
				return SoftArt.beam_pixels(64, 256), 64, 256
			end)
		end,
		spinner_ring = function()
			return SoftArt.ref("spin_ring", function()
				return SoftArt.spinner_ring_pixels(), 64, 64
			end)
		end,
		spinner_arc = function()
			return SoftArt.ref("spin_arc", function()
				return SoftArt.spinner_arc_pixels(), 64, 64
			end)
		end,
	}
	return setmetatable(S, {
		__index = function(_, key)
			local f = lazy[key]
			return if f ~= nil then f() else nil
		end,
	})
end

return SoftArt
