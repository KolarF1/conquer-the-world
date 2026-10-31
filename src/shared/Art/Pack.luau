--!strict
-- Decoder for the art the build tools pack (tools/art/pack.luau): an 8-bit coverage mask as run-length
-- pairs (value, count) in base64. Pure Luau, the same under Lune (the tests) and in the game, so the pixels a
-- player sees are the ones the contact sheets show. Nothing is rasterised on the device.
local Pack = {}

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP: { [number]: number } = {}
for i = 1, #B64 do
	LOOKUP[string.byte(B64, i)] = i - 1
end

--- base64 text -> bytes as a buffer.
function Pack.base64(text: string): buffer
	local n = #text
	local pad = 0
	if string.sub(text, n, n) == "=" then
		pad += 1
	end
	if string.sub(text, n - 1, n - 1) == "=" then
		pad += 1
	end
	local out = buffer.create(n // 4 * 3 - pad)
	local o = 0
	local len = buffer.len(out)
	for i = 1, n, 4 do
		local a = LOOKUP[string.byte(text, i)] or 0
		local b = LOOKUP[string.byte(text, i + 1)] or 0
		local c = LOOKUP[string.byte(text, i + 2)] or 0
		local d = LOOKUP[string.byte(text, i + 3)] or 0
		local v = a * 262144 + b * 4096 + c * 64 + d
		if o < len then
			buffer.writeu8(out, o, v // 65536)
		end
		if o + 1 < len then
			buffer.writeu8(out, o + 1, (v // 256) % 256)
		end
		if o + 2 < len then
			buffer.writeu8(out, o + 2, v % 256)
		end
		o += 3
	end
	return out
end

--- Run-length pairs -> a coverage mask of `count` bytes.
function Pack.unrle(data: buffer, count: number): buffer
	local out = buffer.create(count)
	local o = 0
	local n = buffer.len(data)
	local i = 0
	while i + 1 < n and o < count do
		local v, run = buffer.readu8(data, i), buffer.readu8(data, i + 1)
		if v ~= 0 then
			for k = 0, run - 1 do
				if o + k < count then
					buffer.writeu8(out, o + k, v)
				end
			end
		end
		o += run
		i += 2
	end
	return out
end

--- base64 run-length text -> mask buffer of w * h bytes.
function Pack.mask(text: string, w: number, h: number): buffer
	return Pack.unrle(Pack.base64(text), w * h)
end

--- Writes `mask` (w x h coverage) into `rgba` (a buffer of atlas_w x atlas_h x 4 bytes) at pixel (x, y) as
--- white with that coverage as alpha (the interface tints it with ImageColor3).
function Pack.blit_white(rgba: buffer, atlas_w: number, mask: buffer, w: number, h: number, x: number, y: number)
	for sy = 0, h - 1 do
		local row = ((y + sy) * atlas_w + x) * 4
		for sx = 0, w - 1 do
			local a = buffer.readu8(mask, sy * w + sx)
			local o = row + sx * 4
			buffer.writeu32(rgba, o, 0x00FFFFFF + a * 16777216)
		end
	end
end

return Pack
