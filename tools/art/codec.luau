--!strict
-- Run-length + base64 packing of coverage masks (the decoder is src/shared/Art/Pack.luau).
local Raster = require("./raster")

local M = {}

--- Mask -> run-length (value, count) byte string.
function M.rle(m: Raster.Mask): string
	local out = {}
	local a = m.a
	local n = m.w * m.h
	local i = 0
	while i < n do
		local v = buffer.readu8(a, i)
		local run = 1
		while i + run < n and run < 255 and buffer.readu8(a, i + run) == v do
			run += 1
		end
		table.insert(out, string.char(v, run))
		i += run
	end
	return table.concat(out)
end

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
function M.b64(s: string): string
	local out = {}
	for i = 1, #s, 3 do
		local a, b, c = string.byte(s, i), string.byte(s, i + 1), string.byte(s, i + 2)
		local v = a * 65536 + (b or 0) * 256 + (c or 0)
		local c1, c2, c3, c4 = v // 262144, (v // 4096) % 64, (v // 64) % 64, v % 64
		table.insert(out, string.sub(B64, c1 + 1, c1 + 1) .. string.sub(B64, c2 + 1, c2 + 1) .. (if b then string.sub(B64, c3 + 1, c3 + 1) else "=") .. (if c then string.sub(B64, c4 + 1, c4 + 1) else "="))
	end
	return table.concat(out)
end

return M
