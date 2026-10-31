--!native
-- Game modes in the Sim (Conquer the World's own; Data/Modes): a lower win share, a clock on a solo match, no
-- alliances, a flat boost for everyone, and the Crown: a site at the heart of the map, whoever holds the ground
-- under it for `crown_ticks` in all, once it opens, wins. All off unless the match config says so. No RNG draws.
--
-- The wire: `mode` (the key) and `crown` ({ tile, need, holder }) with `crown_rows` ({ id, ticks }) in a snapshot;
-- Ev.CROWN when the holder changes and every CROWN_SEND_TICKS while held.
local Defs = require("./Defs")
local Ev = require("./Ev")

local SimModes = {}

SimModes.CROWN_SEND_TICKS = 20
--- The Crown counts for nobody before this long into play (whoever spawned on it would simply win).
SimModes.CROWN_OPEN_TICKS = 3000
--- Announcements of a holder's progress, in remaining ticks.
SimModes.CROWN_WARN = { 1200, 600 }

--- The Crown's tile on `map`: the contestable land tile nearest the land's centre of mass. Pure in the map.
function SimModes.crown_site(map: any): number
	local land = map.land_count
	if land <= 0 then
		return -1
	end
	local step = math.max(land // 4000, 1)
	local sx, sy, n = 0, 0, 0
	for k = 0, land - 1, step do
		local t = map:land_tile(k)
		sx += map:tile_x(t)
		sy += map:tile_y(t)
		n += 1
	end
	local cx, cy = sx / n, sy / n
	local best, best_d = -1, math.huge
	for k = 0, land - 1, step do
		local t = map:land_tile(k)
		if map:is_contestable(t) then
			local dx, dy = map:tile_x(t) - cx, map:tile_y(t) - cy
			local d = dx * dx + dy * dy
			if d < best_d then
				best, best_d = t, d
			end
		end
	end
	return best
end

function SimModes.install(Sim: any)
	function Sim._init_modes(self: any, cfg: { [string]: any })
		self.mode = if type(cfg.mode) == "string" then cfg.mode else nil
		self.win_share = if type(cfg.win_share) == "number" then cfg.win_share else nil
		self.solo_clock = cfg.solo_clock == true
		self.no_alliances = cfg.no_alliances == true
		self.boost = if type(cfg.boost) == "table" then cfg.boost else nil
		self.crown_need = if type(cfg.crown_ticks) == "number" then cfg.crown_ticks else 0
		self.crown_tile = if self.crown_need > 0 then SimModes.crown_site(self.map) else -1
		self.crown_holder = 0
		self.crown_open = SimModes.CROWN_OPEN_TICKS
		self._crown_opened = false
		--- owner id -> ticks they have held the Crown
		self.crown_ticks = {} :: { [number]: number }
		self._crown_warned = {} :: { [number]: { [number]: boolean } }
		if self.boost ~= nil then
			self.mults_on = true
		end
	end

	--- Every tick while playing: who holds the Crown, and whether they have held it long enough.
	function Sim._crown_tick(self: any)
		if self.crown_tile < 0 or self.tick - self.playing_since < self.crown_open then
			return
		end
		if not self._crown_opened then
			self._crown_opened = true
			self:msg(-1, Defs.MSG_ALERT, "The Crown is up for grabs. Hold it to win.")
		end
		local now = buffer.readi32(self.owner, self.crown_tile * 4)
		if now > 0 and self.o_kind[now] == Defs.KIND_TRIBE then
			now = 0
		end
		if now ~= self.crown_holder then
			self.crown_holder = now
			self:ev({ Ev.CROWN, now, if now > 0 then self.crown_ticks[now] or 0 else 0 })
			if now > 0 then
				self:msg(-1, Defs.MSG_INFO, self.o_name[now] .. " holds the Crown")
			end
		end
		if now <= 0 then
			return
		end
		local t = (self.crown_ticks[now] or 0) + 1
		self.crown_ticks[now] = t
		if self.tick % SimModes.CROWN_SEND_TICKS == 0 then
			self:ev({ Ev.CROWN, now, t })
		end
		local left = self.crown_need - t
		for _, w in SimModes.CROWN_WARN do
			if left == w then
				self:msg(-1, Defs.MSG_ALERT, string.format("%s has held the Crown: %d seconds to go", self.o_name[now], w // 10))
			end
		end
		if left <= 0 then
			self:msg(-1, Defs.MSG_ALERT, self.o_name[now] .. " kept the Crown and wins")
			self:_game_over(now, Defs.OVER_CROWN, 0)
		end
	end

	--- Snapshot rows.
	function Sim._crown_snapshot(self: any): ({ number }?, { { number } }?)
		if self.crown_tile < 0 then
			return nil, nil
		end
		local rows = {}
		for id = 1, self.owner_total do
			local t = self.crown_ticks[id]
			if t ~= nil then
				table.insert(rows, { id, t })
			end
		end
		return { self.crown_tile, self.crown_need, self.crown_holder }, rows
	end
end

return SimModes
