--!nocheck
-- Landmarks (Core/SimLandmarks, Conquer the World's own system): the sites are a pure function of
-- the map, they pay only their holder, and with the flag off the economy is exactly upstream's.
-- Run: lune run tests/landmarks.luau
require("./prelude")
local Defs = require("../src/shared/Core/Defs")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")
local SimLandmarks = require("../src/shared/Core/SimLandmarks")

local fails = 0
local function expect(cond: any, what: string)
	if cond then
		print("  ok   " .. what)
	else
		fails += 1
		print("FAIL " .. what)
	end
end

local world = WorldMap.shared()

-- sites ------------------------------------------------------------------------------------------
local a = SimLandmarks.sites(world)
local b = SimLandmarks.sites(world)
expect(#a == SimLandmarks.COUNT, "a full set of sites on the default map (" .. #a .. ")")
local same, seen, valid, kinds = true, {}, true, { 0, 0, 0, 0, 0, 0 }
for i, s in a do
	same = same and s.tile == b[i].tile and s.kind == b[i].kind
	valid = valid and world:is_contestable(s.tile) and not seen[s.tile]
	seen[s.tile] = true
	kinds[s.kind] += 1
end
expect(same, "the sites are the same every time (a pure function of the map)")
expect(valid, "every site is distinct contestable land")
for k = 1, #SimLandmarks.KIND_NAMES do
	expect(kinds[k] == 2, SimLandmarks.KIND_NAMES[k] .. ": two on the map")
end
expect(#SimLandmarks.KIND_GLYPHS == #SimLandmarks.KIND_NAMES and #SimLandmarks.KIND_LINES == #SimLandmarks.KIND_NAMES, "every kind has a badge mark and a line")

-- holding ----------------------------------------------------------------------------------------
local owner = buffer.create(world.N * 4)
local mint, garrison
for _, s in a do
	if s.kind == 1 and mint == nil then
		mint = s
	elseif s.kind == 2 and garrison == nil then
		garrison = s
	end
end
buffer.writei32(owner, mint.tile * 4, 7)
buffer.writei32(owner, garrison.tile * 4, 7)
local held = SimLandmarks.held(a, owner)
expect(held[7] ~= nil and held[7][1] == 1 and held[7][2] == 1, "held counts a Mint and a Garrison for owner 7")
expect(held[0] == nil, "unowned sites pay nobody")

-- economy ----------------------------------------------------------------------------------------
local function start_tile(): number
	for k = 0, world.land_count - 1 do
		local t = world:land_tile(k)
		if world:is_contestable(t) and not seen[t] then
			local x, y = world:tile_x(t), world:tile_y(t)
			if x > 40 and y > 40 and x < world.W - 40 and y < world.H - 40 then
				return t
			end
		end
	end
	error("no start tile")
end
local START = start_tile()

local function playing(landmarks: boolean): (any, number)
	local sim = Sim.new(world, {
		seed = 5,
		difficulty = 1,
		tribes = 0,
		max_humans = 1,
		nations = false,
		landmarks = landmarks,
	})
	local h = sim:add_human("me", "Me")
	assert(sim:human_start(h, START), "spawn accepted")
	while sim.phase ~= Defs.PHASE_PLAYING do
		sim:step()
	end
	return sim, h
end

local off, hoff = playing(false)
local on, hon = playing(true)
expect(not off.landmarks_on and on.landmarks_on, "the flag turns the system on")
expect(#off.landmark_sites == 0 and #on.landmark_sites == SimLandmarks.COUNT, "sites exist only when on")

-- nothing held: identical to upstream
for _ = 1, 30 do
	off:step()
	on:step()
end
expect(off.o_gold[hoff] == on.o_gold[hon] and off.o_troops[hoff] == on.o_troops[hon], "holding no landmark changes nothing")

-- hand the human a Mint: the INCOME the HUD shows rises by exactly the bonus, and the gold earned in a
-- second is that income (o_income refreshes on a staggered (tick + id) % 10 schedule, so settle first)
buffer.writei32(on.owner, mint.tile * 4, hon)
for _ = 1, 21 do
	on:step()
	off:step()
end
local snap_income = on:snapshot().owners[hon][11]
expect(math.abs(on.o_income[hon] / off.o_income[hoff] - (1 + SimLandmarks.MINT_GOLD_BONUS)) < 1e-9, string.format("a Mint pays +%d%% income (got x%.4f)", SimLandmarks.MINT_GOLD_BONUS * 100, on.o_income[hon] / off.o_income[hoff]))
expect(snap_income == math.floor(on.o_income[hon] + on.o_bonus_rate[hon]), "and the snapshot's income row says so (the HUD shows the earned number)")
local g0 = on.o_gold[hon]
for _ = 1, 10 do
	on:step()
end
expect(math.abs((on.o_gold[hon] - g0) - on.o_income[hon]) < 1e-6, "a second of play earns exactly the shown income")

-- and a Garrison raises the troop cap
buffer.writei32(on.owner, garrison.tile * 4, hon)
for _ = 1, 11 do
	on:step()
	off:step()
end
expect(on.o_cap[hon] > off.o_cap[hoff], "a Garrison raises the troop cap (" .. on.o_cap[hon] .. " vs " .. off.o_cap[hoff] .. ")")

-- the new kinds pay through the levers
do
	local sim, h = playing(true)
	local function give(kind)
		for _, st in sim.landmark_sites do
			if st.kind == kind then
				buffer.writei32(sim.owner, st.tile * 4, h)
				return
			end
		end
	end
	sim:step()
	give(SimLandmarks.KIND_CITADEL)
	give(SimLandmarks.KIND_HARBOR)
	give(SimLandmarks.KIND_GRANARY)
	give(SimLandmarks.KIND_FOUNDRY)
	sim:_refresh_mults()
	expect(math.abs(sim.m_def[h] - 1.08) < 1e-9, "a Citadel raises defence")
	expect(math.abs(sim.m_trade[h] - 1.25) < 1e-9, "a Harbor raises trade gold")
	expect(math.abs(sim.m_regen[h] - 1.15) < 1e-9, "a Granary raises regrowth")
	expect(math.abs(sim.m_rebate[h] - 0.05) < 1e-9, "a Foundry refunds part of a building")
end

if fails > 0 then
	print("landmarks: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("landmarks: all passed")
