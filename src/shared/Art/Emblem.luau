--!strict
-- Our flags: heraldic emblems drawn from a key (a country code, a shop flag's key). A field pattern, three
-- colours from a curated palette, a charge taken from our glyph set, a darker rim. Everything is a function of
-- the key, so a flag looks the same on every device and every run, and none of it is someone else's art.
-- `pixels` is pure (RGBA bytes, opaque); the client uploads it (UI/FlagArt), the tests render it.
local Pack = require("./Pack")
local IconData = require("./IconData")

local Emblem = {}

Emblem.W = 57
Emblem.H = 38

local PALETTES = {
	{ 0x1F3A5F, 0xE8C547, 0xF4F1E8 },
	{ 0x7A1F2B, 0xF2E6C9, 0xD9A441 },
	{ 0x0F5C4D, 0xE9E2C8, 0xC4492F },
	{ 0x2B2F77, 0xD8DBE8, 0xF0B429 },
	{ 0x8A2D12, 0x222222, 0xF2CF66 },
	{ 0x196F6B, 0xF0E8D8, 0xDB5A42 },
	{ 0x4A2A6B, 0xE8D9A8, 0x7FD1B9 },
	{ 0x1C1C28, 0xCF3A3A, 0xE9E9E9 },
	{ 0x3D5A2E, 0xE6D9A0, 0xA8341C },
	{ 0x0B4F8A, 0xF2F2F2, 0xE04A3B },
	{ 0x6B3F1D, 0xE8C07A, 0x2B6A63 },
	{ 0xB5332A, 0x1D2A48, 0xF1E4B8 },
}

local CHARGES = { "star", "crown", "globe", "defense", "port", "city", "target", "gold", "eye", "layers", "troops", "airfield", "artillery" }

--- A theme's own charge (the shop flags' themes); anything else is picked by the key's hash.
Emblem.THEME_CHARGE = {
	Halloween = "skull",
	Empires = "crown",
	Doomsday = "atom",
	Naval = "port",
	Space = "star",
	Elements = "globe",
	Fun = "gold",
}

--- A well-mixed integer of a string (FNV-1a, kept in 32 bits).
function Emblem.hash(s: string): number
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = (h * 16777619) % 4294967296
	end
	return h
end

local _masks: { [string]: buffer } = {}
local function mask_of(name: string): buffer
	local m = _masks[name]
	if m == nil then
		m = Pack.mask(IconData.icons[name], IconData.size, IconData.size)
		_masks[name] = m
	end
	return m
end

local function rgb(c: number): (number, number, number)
	return c // 65536, (c // 256) % 256, c % 256
end

--- The flag of `key` (and `theme`, when it has one) at w x h px: RGBA bytes.
function Emblem.pixels(key: string, w: number, h: number, theme: string?): buffer
	local hv = Emblem.hash(key)
	local pal = PALETTES[hv % #PALETTES + 1]
	local pattern = (hv // 16) % 8 + 1
	local charge = Emblem.THEME_CHARGE[theme or ""] or CHARGES[(hv // 256) % #CHARGES + 1]
	if not IconData.icons[charge] then
		charge = "star"
	end
	local flip = (hv // 4096) % 2 == 1
	local c1, c2, c3 = pal[1], pal[2], pal[3]
	if flip then
		c1, c2 = c2, c1
	end
	local out = buffer.create(w * h * 4)
	local cx = if pattern == 6 then 0.36 * w elseif pattern == 7 then 0.6 * w else 0.5 * w
	local size = 0.6 * h
	local m = mask_of(charge)
	local scale = IconData.size / size
	local gx0, gy0 = cx - size * 0.5, h * 0.5 - size * 0.5
	local aspect = w / h
	local msize = IconData.size
	local function cover(px: number, py: number): number
		local sx, sy = (px - gx0) * scale, (py - gy0) * scale
		if sx < 0 or sy < 0 or sx >= msize or sy >= msize then
			return 0
		end
		return buffer.readu8(m, math.floor(sy) * msize + math.floor(sx)) / 255
	end
	for y = 0, h - 1 do
		local v = (y + 0.5) / h
		for x = 0, w - 1 do
			local u = (x + 0.5) / w
			local use2
			if pattern == 1 then
				use2 = false
			elseif pattern == 2 then
				use2 = v >= 0.5
			elseif pattern == 3 then
				use2 = u >= 0.5
			elseif pattern == 4 then
				use2 = u + v * 0.75 >= 1.0
			elseif pattern == 5 then
				use2 = v >= 1 / 3 and v < 2 / 3
			elseif pattern == 6 then
				use2 = math.abs(u - 0.36) < 0.085 or math.abs(v - 0.5) < 0.12
			elseif pattern == 7 then
				use2 = math.abs(v - 0.5) < 0.5 * (0.62 - u) / 0.62 and u < 0.62
			else
				use2 = math.abs(u - v) * math.min(aspect, 1.6) < 0.1 or math.abs(u + v - 1) * math.min(aspect, 1.6) < 0.1
			end
			local r, g, b = rgb(if use2 then c2 else c1)
			-- the charge: a dark shadow one pixel down and right, then the glyph
			local sh = cover(x - 1 + 0.5, y - 1 + 0.5) * 0.45
			if sh > 0 then
				r, g, b = r * (1 - sh), g * (1 - sh), b * (1 - sh)
			end
			local a = cover(x + 0.5, y + 0.5)
			if a > 0 then
				local cr, cg, cb = rgb(c3)
				r, g, b = r * (1 - a) + cr * a, g * (1 - a) + cg * a, b * (1 - a) + cb * a
			end
			-- the rim: a darker frame two pixels wide
			local edge = math.min(x, y, w - 1 - x, h - 1 - y)
			if edge < 2 then
				local k = if edge == 0 then 0.55 else 0.8
				r, g, b = r * k, g * k, b * k
			end
			buffer.writeu32(out, (y * w + x) * 4, math.floor(r + 0.5) + math.floor(g + 0.5) * 256 + math.floor(b + 0.5) * 65536 + 4278190080)
		end
	end
	return out
end

return Emblem
