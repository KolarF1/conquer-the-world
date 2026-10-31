--!nocheck
-- How do War Room missions and modes play out? A smart bot sits in the player's seat: it plays like a nation, so what
-- it reaches is a rough floor for a person who is paying attention, not a promise. Prints, per mission: the bot's best land, when
-- it fell or won, how long the match ran and which objectives it met.
-- Run: lune run tools/balance_probe.luau [first] [last] [max_ticks]
require("../tests/prelude")
local process = require("@lune/process")
local Defs = require("../src/shared/Core/Defs")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")
local Modes = require("../src/shared/Data/Modes")
local Missions = require("../src/shared/Data/Missions")

local first = tonumber(process.args[1]) or 1
local last = tonumber(process.args[2]) or #Missions.LIST
local MAX = tonumber(process.args[3]) or 14000

for i = first, last do
	local m = Missions.LIST[i]
	local map = WorldMap.get(m.map)
	for _, seed in { 11, 22 } do
		local cfg = Modes.apply({ seed = seed, difficulty = m.difficulty, max_humans = 2, spawn_ticks = 30 }, m.mode)
		for k, v in m.config or {} do
			cfg[k] = v
		end
		Sim.with_defaults(cfg)
		-- (the limit a solo match would have, without the solo rule that the match waits for a pick)
		local sim = Sim.new(map, cfg)
		local bot = sim:add_bot_player("Seat", true)
		local peak, out_tick = 0, nil
		local t0 = os.clock()
		for _ = 1, MAX do
			sim:step()
			local land = map.contestable_count
			if sim.o_alive[bot] == 1 then
				peak = math.max(peak, sim.o_tiles[bot] / land)
			elseif out_tick == nil then
				out_tick = sim.tick - sim.playing_since
			end
			if sim.phase == Defs.PHASE_OVER then
				break
			end
		end
		local won = sim.phase == Defs.PHASE_OVER and sim.winner == bot
		local secs = (out_tick or (sim.tick - sim.playing_since)) // 10
		local report = { peak = peak, won = won, seconds = secs, kills = 0, eliminated = out_tick ~= nil, eliminated_at = if out_tick then secs else nil }
		print(string.format("%2d %-14s seed %d diff %d  peak %5.1f%%  %s at %4d s  over=%s reason=%d stars(land/win/time only)=%d  (%.0fs real)", i, m.key, seed, m.difficulty, peak * 100, if won then "WON" elseif out_tick then "FELL" else "alive", secs, tostring(sim.phase == Defs.PHASE_OVER), sim.over_reason, Missions.stars(m, report), os.clock() - t0))
	end
end
