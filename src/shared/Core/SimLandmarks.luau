--!native
-- Landmarks (Conquer the World's own system, not part of upstream): a handful of fixed sites on
-- the map that reward whoever holds the ground under them, so a war has places worth fighting for.
--
-- They are derived from the map alone (no RNG draw, no snapshot field), so every Sim and every
-- client mirror agrees on where they are, and the upstream parity / mirror tests are untouched.
-- Off unless the match config says `landmarks = true`.
--
--   Mint      +MINT_GOLD_BONUS of the owner's passive gold income, per Mint held
--   Garrison  +GARRISON_CAP_BONUS of the owner's troop cap, per Garrison held
--   Citadel   +CITADEL_DEF_BONUS defence            Harbor   +HARBOR_TRADE_BONUS trade gold
--   Granary   +GRANARY_REGEN_BONUS troop regrowth   Foundry  +FOUNDRY_REBATE of a building's cost back
-- Held = the owner of the site's tile, never a mid-air or neutral tile (owner 0 earns nothing).

local SimLandmarks = {}

SimLandmarks.KIND_MINT = 1
SimLandmarks.KIND_GARRISON = 2
SimLandmarks.KIND_CITADEL = 3
SimLandmarks.KIND_HARBOR = 4
SimLandmarks.KIND_GRANARY = 5
SimLandmarks.KIND_FOUNDRY = 6
SimLandmarks.KIND_NAMES = { "Gold Mine", "Garrison", "Citadel", "Harbor", "Granary", "Foundry" }
--- The badge's mark on the map and what holding one does, per kind.
SimLandmarks.KIND_GLYPHS = { "$", "+", "#", "~", "%", "^" }
--- The icon and tile colour of each kind on the map.
SimLandmarks.KIND_ICONS = { "lm_mine", "lm_garrison", "lm_citadel", "lm_harbor", "wheat", "lm_foundry" }
SimLandmarks.KIND_LINES = { "+20% gold", "+8% troop cap", "+8% defence", "+25% trade gold", "+15% troop regrowth", "+5% building refund" }
SimLandmarks.MINT_GOLD_BONUS = 0.20
SimLandmarks.GARRISON_CAP_BONUS = 0.08
SimLandmarks.CITADEL_DEF_BONUS = 0.08
SimLandmarks.HARBOR_TRADE_BONUS = 0.25
SimLandmarks.GRANARY_REGEN_BONUS = 0.15
SimLandmarks.FOUNDRY_REBATE = 0.05
SimLandmarks.COUNT = 12

local readi32 = buffer.readi32

--- The sites of `map`: { { tile = i, kind = k }, … }, evenly spread through the land tiles in scan
--- order (so they spread over the rows), the kinds in turn. Pure in the map.
function SimLandmarks.sites(map: any, count: number?): { { tile: number, kind: number } }
	local n = count or SimLandmarks.COUNT
	local out = {}
	local land = map.land_count
	if land <= 0 then
		return out
	end
	local taken = {}
	for i = 1, n do
		local k = math.floor((i - 0.5) * land / n)
		-- walk to the next contestable tile that is not already a site
		local tile = map:land_tile(math.min(k, land - 1))
		local guard = 0
		while (not map:is_contestable(tile) or taken[tile]) and guard < land do
			k = (k + 1) % land
			tile = map:land_tile(k)
			guard += 1
		end
		if guard < land then
			taken[tile] = true
			table.insert(out, { tile = tile, kind = (i - 1) % #SimLandmarks.KIND_NAMES + 1 })
		end
	end
	return out
end

--- Per owner id: the landmarks held by kind, for a list of sites and an owner buffer.
function SimLandmarks.held(sites: { { tile: number, kind: number } }, owner: buffer): { [number]: { number } }
	local held = {}
	for _, s in sites do
		local id = readi32(owner, s.tile * 4)
		if id > 0 then
			local h = held[id]
			if h == nil then
				h = { 0, 0, 0, 0, 0, 0 }
				held[id] = h
			end
			h[s.kind] += 1
		end
	end
	return held
end

function SimLandmarks.install(Sim: any)
	--- Called from Sim.new after the map is known.
	function Sim._init_landmarks(self: any, cfg: { [string]: any })
		self.landmarks_on = cfg.landmarks == true
		self.landmark_sites = if self.landmarks_on then SimLandmarks.sites(self.map) else {}
		self.landmark_held = {} :: { [number]: { number } }
	end
end

return SimLandmarks
