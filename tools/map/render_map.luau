--!nocheck
-- Renders a seeded match through the REAL MapSurface (headless, as tests/map_surface_repaint does) and
-- writes the composited RGBA picture: build/map_<id>.rgba = u32 w, u32 h, then w*h RGBA pixels.
-- tools/map/rgba_to_png.py turns that into PNGs (full, the real fit scale of a phone, and a crop).
-- Run: lune run tools/map/render_map.luau [map_id] [ticks] [seed]
local roblox = require("../../tests/prelude");
(getfenv() :: any).Instance = (roblox :: any).Instance;
(getfenv() :: any).Enum = (roblox :: any).Enum;
(getfenv() :: any).task = require("@lune/task");
(getfenv() :: any).warn = function() end
local fs = require("@lune/fs")
local process = require("@lune/process")
local WorldMap = require("../../src/shared/Core/WorldMap")
local Sim = require("../../src/shared/Core/Sim")
local GameState = require("../../src/shared/Core/GameState")
local MapSurface = require("../../src/client/Map/MapSurface")

local id = process.args[1] or "europe"
local ticks = tonumber(process.args[2]) or 1500
local seed = tonumber(process.args[3]) or 7
local map = WorldMap.get(id)
local sim = Sim.new(map, { seed = seed, difficulty = 1, tribes = 150, max_humans = 0 })
for _ = 1, ticks do
	sim:step()
end
local state = GameState.new(map)
state:load_snapshot(sim:snapshot())
local surface = MapSurface.new(nil)
surface:set_map(map)
surface:bind(state)
local guard = 0
while (surface._rebuild_active or surface:repaint_pending() > 0) and guard < 100000 do
	surface:step()
	guard += 1
end
local n = surface.N
local head = buffer.create(8)
buffer.writeu32(head, 0, surface.W)
buffer.writeu32(head, 4, surface.H)
fs.writeFile(string.format("build/map_%s.rgba", id), buffer.tostring(head) .. buffer.tostring(surface.comp))
print(string.format("rendered %s %dx%d after %d ticks (seed %d), owners=%d", id, surface.W, surface.H, ticks, seed, sim.owner_total))
