--!nocheck
-- Our invented maps (tools/maps/make_fictional.py): each builds, is a fair playing field, and carries a real match.
-- Run: lune run tests/maps_invented.luau
require("./prelude")
local Defs = require("../src/shared/Core/Defs")
local WorldMap = require("../src/shared/Core/WorldMap")
local MapList = require("../src/shared/Data/MapList")
local Sim = require("../src/shared/Core/Sim")
local SimLandmarks = require("../src/shared/Core/SimLandmarks")
local SimModes = require("../src/shared/Core/SimModes")
local fs = require("@lune/fs")

local fails = 0
local function expect(cond: any, what: string)
	if cond then
		print("  ok   " .. what)
	else
		fails += 1
		print("FAIL " .. what)
	end
end

local n = 0
for _, row in MapList.maps do
	if table.find(row.categories, "invented") then
		n += 1
		local map = WorldMap.get(row.id)
		expect(map ~= nil and map.W == row.width and map.H == row.height, row.id .. ": builds at its size")
		expect(map.land_count == row.land_tiles or math.abs(map.land_count - row.land_tiles) / row.land_tiles < 0.02, row.id .. ": land matches the registry")
		expect(#map.nations == row.nations and row.nations >= 30, row.id .. ": " .. row.nations .. " nations")
		local on_land, names = true, {}
		for _, nation in map.nations do
			on_land = on_land and nation.tile >= 0 and map:is_contestable(nation.tile)
			expect(not names[nation.name], row.id .. ": " .. nation.name .. " only once")
			names[nation.name] = true
		end
		expect(on_land, row.id .. ": every nation stands on contestable land")
		expect(#SimLandmarks.sites(map) == SimLandmarks.COUNT, row.id .. ": a full set of landmarks")
		expect(SimModes.crown_site(map) >= 0, row.id .. ": a place for the Crown")
		expect(fs.isFile("src/shared/Art/Thumbs/" .. row.id .. ".luau"), row.id .. ": a thumbnail")
		-- a real match runs: AI only, a few hundred ticks
		local sim = Sim.new(map, Sim.with_defaults({ seed = 7, difficulty = 1, tribes = 40, max_humans = 0, nation_limit = 10 }))
		for _ = 1, 300 do
			sim:step()
		end
		local alive = 0
		for id = 1, sim.owner_total do
			if sim.o_kind[id] == Defs.KIND_NATION and sim.o_alive[id] == 1 and sim.o_tiles[id] > 0 then
				alive += 1
			end
		end
		expect(alive >= 5, row.id .. ": a match runs on it (" .. alive .. " nations hold land after 30 s)")
	end
end
expect(n == 6, "six invented maps")

if fails > 0 then
	print("maps_invented: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("maps_invented: all passed")
