--!nocheck
-- How long does an AI-only match run, and how big is the leader over time, with our systems on against the inherited
-- base? Eras are timed against this: a match that always ends before the Reckoning would waste it.
-- Run: lune run tools/length_probe.luau [map] [difficulty] [max_ticks]
require("../tests/prelude")
local process = require("@lune/process")
local Defs = require("../src/shared/Core/Defs")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")

local map_id = process.args[1] or "world"
local difficulty = tonumber(process.args[2]) or 1
local MAX = tonumber(process.args[3]) or 15000
local map = WorldMap.get(map_id)

for _, on in { true, false } do
	for _, seed in { 3, 4 } do
		local cfg = { seed = seed, difficulty = difficulty, max_humans = 0 }
		if on then
			Sim.with_defaults(cfg)
		end
		local sim = Sim.new(map, cfg)
		local marks = {}
		for t = 1, MAX do
			sim:step()
			if sim.phase == Defs.PHASE_OVER then
				break
			end
			if t % 3000 == 0 then
				local top = 0
				for id = 1, sim.owner_total do
					if sim.o_alive[id] == 1 then
						top = math.max(top, sim.o_tiles[id])
					end
				end
				table.insert(marks, string.format("%dmin:%.0f%%", t // 600, top / map.contestable_count * 100))
			end
		end
		print(string.format("%s %s seed %d: %s over=%s at %d s  leader %s", map_id, if on then "ON " else "off", seed, sim.phase == Defs.PHASE_OVER and "ended" or "running", tostring(sim.phase == Defs.PHASE_OVER), (sim.tick - sim.playing_since) // 10, table.concat(marks, " ")))
	end
end
