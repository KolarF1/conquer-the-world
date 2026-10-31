--!strict
-- Our art engine, build time only (runs under Lune, never in the game): signed-distance shapes rasterised
-- with analytic anti-aliasing into 8-bit coverage masks. Icons and sprites are described once, as shape
-- lists on a design grid (64 x 64 units for icons), rasterised here at the sizes the game needs, packed
-- (tools/art/pack.luau) and shipped as data; the client never rasterises, it only decodes and uploads, so
-- the pixels a player sees are the ones in the contact sheets this repo renders.
--
-- A shape list is an array of items { op, args... } drawn in order onto a mask:
--   { "circle", cx, cy, r }              { "ring", cx, cy, r, w }
--   { "box", x0, y0, x1, y1, r? }        a rounded rectangle (corner radius r, default 0)
--   { "line", x1, y1, x2, y2, w }        a capsule
--   { "poly", x1, y1, x2, y2, x3, y3 ... }   a filled polygon (any winding, may be concave)
--   { "arc", cx, cy, r, a0, a1, w }      a stroked arc, angles in degrees (0 = right, clockwise on screen)
--   { "erase", item }                    the item cuts a hole instead of adding
-- Coordinates are design units; `render` scales them to pixels.
local Raster = {}

local floor, ceil, sqrt, max, min, abs = math.floor, math.ceil, math.sqrt, math.max, math.min, math.abs
local atan2, pi = math.atan2, math.pi

export type Mask = { w: number, h: number, a: buffer }

function Raster.new(w: number, h: number): Mask
	return { w = w, h = h, a = buffer.create(w * h) }
end

-- signed distances (negative inside), in design units ----------------------------------------------------

local function sd_circle(px, py, cx, cy, r)
	return sqrt((px - cx) ^ 2 + (py - cy) ^ 2) - r
end

local function sd_box(px, py, x0, y0, x1, y1, r)
	local cx, cy = (x0 + x1) * 0.5, (y0 + y1) * 0.5
	local hx, hy = (x1 - x0) * 0.5 - r, (y1 - y0) * 0.5 - r
	local qx, qy = abs(px - cx) - hx, abs(py - cy) - hy
	return sqrt(max(qx, 0) ^ 2 + max(qy, 0) ^ 2) + min(max(qx, qy), 0) - r
end

local function sd_segment(px, py, x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	local l2 = dx * dx + dy * dy
	local t = if l2 == 0 then 0 else max(0, min(1, ((px - x1) * dx + (py - y1) * dy) / l2))
	local qx, qy = x1 + t * dx, y1 + t * dy
	return sqrt((px - qx) ^ 2 + (py - qy) ^ 2)
end

local function sd_poly(px, py, pts)
	local n = #pts // 2
	local d = math.huge
	local inside = false
	local j = n
	for i = 1, n do
		local xi, yi = pts[i * 2 - 1], pts[i * 2]
		local xj, yj = pts[j * 2 - 1], pts[j * 2]
		d = min(d, sd_segment(px, py, xi, yi, xj, yj))
		if (yi > py) ~= (yj > py) and px < (xj - xi) * (py - yi) / (yj - yi) + xi then
			inside = not inside
		end
		j = i
	end
	return if inside then -d else d
end

local function sd_arc(px, py, cx, cy, r, a0, a1, w)
	local ang = atan2(py - cy, px - cx) * 180 / pi
	local lo, hi = a0, a1
	if hi < lo then
		hi += 360
	end
	local a = ang
	while a < lo do
		a += 360
	end
	local d
	if a <= hi then
		d = abs(sqrt((px - cx) ^ 2 + (py - cy) ^ 2) - r)
	else
		local ax, ay = cx + r * math.cos(lo * pi / 180), cy + r * math.sin(lo * pi / 180)
		local bx, by = cx + r * math.cos(hi * pi / 180), cy + r * math.sin(hi * pi / 180)
		d = min(sqrt((px - ax) ^ 2 + (py - ay) ^ 2), sqrt((px - bx) ^ 2 + (py - by) ^ 2))
	end
	return d - w * 0.5
end

--- The signed distance function of one item.
local function field(item: any): (number, number) -> number
	local op = item[1]
	if op == "circle" then
		local cx, cy, r = item[2], item[3], item[4]
		return function(x, y)
			return sd_circle(x, y, cx, cy, r)
		end
	elseif op == "ring" then
		local cx, cy, r, w = item[2], item[3], item[4], item[5]
		return function(x, y)
			return abs(sd_circle(x, y, cx, cy, r)) - w * 0.5
		end
	elseif op == "box" then
		local x0, y0, x1, y1, r = item[2], item[3], item[4], item[5], item[6] or 0
		return function(x, y)
			return sd_box(x, y, x0, y0, x1, y1, r)
		end
	elseif op == "line" then
		local x1, y1, x2, y2, w = item[2], item[3], item[4], item[5], item[6]
		return function(x, y)
			return sd_segment(x, y, x1, y1, x2, y2) - w * 0.5
		end
	elseif op == "poly" then
		local pts = {}
		for i = 2, #item do
			pts[i - 1] = item[i]
		end
		return function(x, y)
			return sd_poly(x, y, pts)
		end
	elseif op == "arc" then
		local cx, cy, r, a0, a1, w = item[2], item[3], item[4], item[5], item[6], item[7]
		return function(x, y)
			return sd_arc(x, y, cx, cy, r, a0, a1, w)
		end
	end
	error("unknown shape op " .. tostring(op))
end

local function bounds(item: any): (number, number, number, number)
	local op = item[1]
	if op == "circle" then
		return item[2] - item[4], item[3] - item[4], item[2] + item[4], item[3] + item[4]
	elseif op == "ring" then
		local r = item[4] + item[5] * 0.5
		return item[2] - r, item[3] - r, item[2] + r, item[3] + r
	elseif op == "box" then
		return item[2], item[3], item[4], item[5]
	elseif op == "line" then
		local h = item[6] * 0.5
		return min(item[2], item[4]) - h, min(item[3], item[5]) - h, max(item[2], item[4]) + h, max(item[3], item[5]) + h
	elseif op == "arc" then
		local r = item[4] + item[7] * 0.5
		return item[2] - r, item[3] - r, item[2] + r, item[3] + r
	end
	local x0, y0, x1, y1 = math.huge, math.huge, -math.huge, -math.huge
	for i = 2, #item, 2 do
		x0, x1 = min(x0, item[i]), max(x1, item[i])
		y0, y1 = min(y0, item[i + 1]), max(y1, item[i + 1])
	end
	return x0, y0, x1, y1
end

--- Draws `item` (or { "erase", item }) onto `mask`; `scale` px per design unit, (ox, oy) the mask-pixel
--- position of design (0, 0).
function Raster.draw(mask: Mask, item: any, scale: number, ox: number, oy: number)
	local erase = false
	if item[1] == "erase" then
		erase = true
		item = item[2]
	end
	local f = field(item)
	local bx0, by0, bx1, by1 = bounds(item)
	local px0 = max(0, floor(bx0 * scale + ox) - 2)
	local py0 = max(0, floor(by0 * scale + oy) - 2)
	local px1 = min(mask.w - 1, ceil(bx1 * scale + ox) + 2)
	local py1 = min(mask.h - 1, ceil(by1 * scale + oy) + 2)
	local a = mask.a
	local inv = 1 / scale
	for y = py0, py1 do
		for x = px0, px1 do
			local d = f(((x + 0.5) - ox) * inv, ((y + 0.5) - oy) * inv) * scale
			local c = max(0, min(1, 0.5 - d))
			if c > 0 then
				local i = y * mask.w + x
				local cur = buffer.readu8(a, i)
				if erase then
					buffer.writeu8(a, i, floor(cur * (1 - c) + 0.5))
				else
					buffer.writeu8(a, i, max(cur, floor(c * 255 + 0.5)))
				end
			end
		end
	end
end

--- Renders a shape list into a fresh w x h mask; the design grid `grid` units square fills it.
function Raster.render(shapes: { any }, w: number, h: number, grid: number): Mask
	local m = Raster.new(w, h)
	local scale = w / grid
	for _, item in shapes do
		Raster.draw(m, item, scale, 0, 0)
	end
	return m
end

--- Copies `src` into `dst` at (x, y), taking the larger coverage (an atlas cell).
function Raster.blit(dst: Mask, src: Mask, x: number, y: number)
	for sy = 0, src.h - 1 do
		for sx = 0, src.w - 1 do
			local dx, dy = x + sx, y + sy
			if dx >= 0 and dy >= 0 and dx < dst.w and dy < dst.h then
				local i = dy * dst.w + dx
				buffer.writeu8(dst.a, i, max(buffer.readu8(dst.a, i), buffer.readu8(src.a, sy * src.w + sx)))
			end
		end
	end
end

return Raster
