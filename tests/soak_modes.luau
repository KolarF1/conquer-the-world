--!nocheck
-- Every mode and every system at once, on real maps, with a person's seat in the match: no error, the mirror keeps up
-- through the real Protocol, a match that should end ends. The nearest thing to a full playthrough that runs offline.
-- Run: lune run tests/soak_modes.luau
local serde = require("@lune/serde")
require("./prelude")
local Defs = require("../src/shared/Core/Defs")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")
local GameState = require("../src/shared/Core/GameState")
local Protocol = require("../src/shared/Net/Protocol")
local Modes = require("../src/shared/Data/Modes")
local Doctrines = require("../src/shared/Data/Doctrines")

Protocol.set_codec({
	compress = function(b: buffer): buffer
		return buffer.fromstring(serde.compress("zstd", buffer.tostring(b)))
	end,
	decompress = function(b: buffer, _n: number): buffer
		return buffer.fromstring(serde.decompress("zstd", buffer.tostring(b)))
	end,
})

local fails = 0
local function expect(c: any, w: string)
	if c then
		print("  ok   " .. w)
	else
		fails += 1
		print("FAIL " .. w)
	end
end

local function start_on(map: any): number
	for k = map.land_count // 2, map.land_count - 1 do
		local t = map:land_tile(k)
		if map:is_contestable(t) then
			return t
		end
	end
	error("no land")
end

local RUNS = {
	{ "classic", "spine", 1 },
	{ "blitz", "thousandisles", 2 },
	{ "crown", "crescent", 1 },
	{ "deadline", "twinrealms", 0 },
	{ "skirmish", "marenostrum", 2 },
	{ "totalwar", "primeval", 1 },
}

for i, run in RUNS do
	local key, map_id, difficulty = run[1], run[2], run[3]
	local map = WorldMap.get(map_id)
	local cfg = Sim.with_defaults(Modes.apply({ seed = 100 + i, difficulty = difficulty, tribes = 30, max_humans = 1, time_limit_s = 0, nation_limit = 10 }, key))
	-- (quick eras, so the short run still reaches the Reckoning's drafts and edicts)
	if key ~= "blitz" then
		cfg.era_ticks = { 0, 150, 400, 700 }
	end
	local sim = Sim.new(map, cfg)
	local h = sim:add_human("me", "Me")
	assert(sim:human_start(h, start_on(map)), "spawn")
	local mirror = GameState.new(map)
	mirror:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(sim:snapshot()))))
	local events = 0
	local ok, err = pcall(function()
		for t = 1, 1100 do
			-- the person's habits: expand, draft, fire what they hold
			if t % 40 == 0 and sim.o_alive[h] == 1 and sim.phase == Defs.PHASE_PLAYING then
				sim:submit(h, { type = "ratio", ratio = 0.3 })
				local by = sim.doc_by[h]
				if by ~= nil then
					for draft = 1, 3 do
						local row = by[draft]
						if row ~= nil and row[6] == 0 then
							sim:submit(h, { type = "doctrine", kind = Doctrines.LIST[row[3 + (t % 3)]].key })
						end
					end
				end
				for _, name in Doctrines.EDICT_ORDER do
					sim:submit(h, { type = "edict", kind = name })
				end
			end
			local d = sim:step()
			if d ~= nil then
				events += #(d.ev or {})
				mirror:apply_delta(Protocol.decode_delta(Protocol.compress(Protocol.encode_delta(d, nil, sim.W))))
			end
			if sim.phase == Defs.PHASE_OVER then
				break
			end
		end
	end)
	expect(ok, key .. " on " .. map_id .. ": runs (" .. tostring(err) .. ")")
	expect(buffer.tostring(mirror.owner) == buffer.tostring(sim.owner), key .. ": the mirror's territory equals the sim's after " .. sim.tick .. " ticks, " .. events .. " events")
	expect(mirror.mode == key, key .. ": the mirror knows the mode")
	local alive = 0
	for id = 1, sim.owner_total do
		if sim.o_kind[id] == Defs.KIND_NATION and sim.o_alive[id] == 1 then
			alive += 1
		end
	end
	expect(alive >= 1 or sim.phase == Defs.PHASE_OVER, key .. ": nations are playing (" .. alive .. " alive)")
	expect(sim.world_event ~= nil or sim._world_next > 1 or sim.tick < sim.world_schedule[1][1] + sim.playing_since, key .. ": world events are running")
end

if fails > 0 then
	print("soak_modes: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("soak_modes: all passed")
