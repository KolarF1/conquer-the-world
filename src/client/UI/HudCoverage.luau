--!strict
-- How much of the screen the always-on HUD covers (2026-11-01: the map is the game, so the HUD has a budget).
-- Pure: the share of a screen covered by a list of rects, overlaps counted once. UIRoot.hud_coverage (Studio's
-- debug channel) feeds it the real panels; tests/hud_coverage.luau checks the sums.

local HudCoverage = {}

--- Share of the screen the HUD may cover with nothing opened. Our own numbers, not a published standard:
--- OpenFront's HUD measured about 9% on a phone (a screenshot, by eye).
HudCoverage.BUDGET_DESKTOP = 0.15
HudCoverage.BUDGET_PHONE = 0.10

export type Box = { x0: number, y0: number, x1: number, y1: number }

--- The union's area of `boxes` clipped to a w x h screen, as a share of the screen (0..1).
function HudCoverage.share(boxes: { Box }, w: number, h: number): number
	if w <= 0 or h <= 0 then
		return 0
	end
	-- cut the screen at every box's left and right edge; in each slice, add up the merged spans
	local xs = { 0, w }
	for _, b in boxes do
		table.insert(xs, math.clamp(b.x0, 0, w))
		table.insert(xs, math.clamp(b.x1, 0, w))
	end
	table.sort(xs)
	local area = 0
	for i = 1, #xs - 1 do
		local a, z = xs[i], xs[i + 1]
		if z > a then
			local spans = {}
			for _, b in boxes do
				if b.x0 < z and b.x1 > a and b.y1 > b.y0 then
					table.insert(spans, { math.clamp(b.y0, 0, h), math.clamp(b.y1, 0, h) })
				end
			end
			table.sort(spans, function(p, q)
				return p[1] < q[1]
			end)
			local covered, reach = 0, 0
			for _, sp in spans do
				local from = math.max(sp[1], reach)
				if sp[2] > from then
					covered += sp[2] - from
					reach = sp[2]
				end
			end
			area += covered * (z - a)
		end
	end
	return area / (w * h)
end

return HudCoverage
