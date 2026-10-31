--!nocheck
-- Game modes (Data/Modes, Core/SimModes): the data, each mode's rules in the Sim, and the wire.
-- Run: lune run tests/modes.luau
local serde = require("@lune/serde")
require("./prelude")
local Defs = require("../src/shared/Core/Defs")
local Ev = require("../src/shared/Core/Ev")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")
local SimModes = require("../src/shared/Core/SimModes")
local GameState = require("../src/shared/Core/GameState")
local Protocol = require("../src/shared/Net/Protocol")
local Modes = require("../src/shared/Data/Modes")
local Eras = require("../src/shared/Data/Eras")

Protocol.set_codec({
	compress = function(b: buffer): buffer
		return buffer.fromstring(serde.compress("zstd", buffer.tostring(b)))
	end,
	decompress = function(b: buffer, _n: number): buffer
		return buffer.fromstring(serde.decompress("zstd", buffer.tostring(b)))
	end,
})

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
local START
for k = 0, world.land_count - 1 do
	local t = world:land_tile(k)
	if world:is_contestable(t) then
		local x, y = world:tile_x(t), world:tile_y(t)
		if x > 60 and y > 60 and x < world.W - 60 and y < world.H - 60 then
			START = t
			break
		end
	end
end

local function match(mode: string?, seed: number?): (any, number)
	local cfg = { seed = seed or 9, difficulty = 1, tribes = 0, max_humans = 1, time_limit_s = 0, nations = true, nation_limit = 6 }
	Modes.apply(cfg, mode)
	Sim.with_defaults(cfg)
	local sim = Sim.new(world, cfg)
	local h = sim:add_human("me", "Me")
	assert(sim:human_start(h, START), "spawn accepted")
	while sim.phase ~= Defs.PHASE_PLAYING do
		sim:step()
	end
	return sim, h
end

-- data
expect(#Modes.LIST == 6, "six modes")
for _, m in Modes.LIST do
	expect(#m.name > 0 and #m.line > 0 and #m.line <= 70, m.key .. ": a name and a short line")
end
local c0 = Modes.apply({}, "nope")
expect(c0.mode == "classic", "an unknown mode is Conquest")
local c1 = Modes.apply({ tribes = 100 }, "skirmish")
expect(c1.tribes == 40 and c1.nation_limit == 12, "Skirmish scales the tribes and limits the nations")
local c2 = Modes.apply({ win_share = 0.5 }, "blitz")
expect(c2.win_share == 0.5, "what the caller set stays")
expect(Eras.valid(Modes.BY_KEY.blitz.config.era_ticks), "Blitz's era table is valid")
local seen, n = {}, 0
for seed = 1, 400 do
	local k = Modes.public_pick(seed)
	expect(Modes.BY_KEY[k] ~= nil and Modes.BY_KEY[k].public ~= nil or seed > 3, "pick " .. seed)
	if not seen[k] then
		seen[k] = true
		n += 1
	end
end
expect(n == 4 and not seen.deadline and not seen.skirmish, "public matches rotate through the crowd's four")

-- Blitz
do
	local s, h = match("blitz", 3)
	expect(s.eras[2] == 600 and s.win_share == 0.6 and s.draft_timeout_s == 30, "Blitz: its eras, share and draft clock")
	local bm = GameState.new(world)
	bm:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(s:snapshot()))))
	expect(bm.win_share == 0.6, "the client knows the goal through the real Protocol, for the status bar")
	local cm = GameState.new(world)
	cm:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(match("classic", 3):snapshot()))))
	expect(cm.win_share == nil, "and a plain match sends none")
	for _ = 1, 15 do
		s:step()
	end
	expect(math.abs(s.m_gold[h] - 1.5) < 1e-9 and math.abs(s.m_regen[h] - 1.5) < 1e-9, "and the flood of gold and troops")
end

-- Deadline
do
	local s, h = match("deadline", 4)
	expect(s.time_limit_ticks == s.playing_since + 12000, "Deadline: a solo match with a clock (" .. s.time_limit_ticks .. ")")
	s.time_limit_ticks = s.tick + 5
	for _ = 1, 20 do
		s:step()
	end
	expect(s.phase == Defs.PHASE_OVER and s.over_reason == Defs.OVER_TIME, "the clock ends it")
	local solo = match("classic", 4)
	expect(solo.time_limit_ticks == 0, "a plain solo match has none")
end

-- Total War
do
	local s, h = match("totalwar", 5)
	local foe
	for id = 1, s.owner_total do
		if s.o_kind[id] == Defs.KIND_NATION and s.o_alive[id] == 1 then
			foe = id
			break
		end
	end
	expect(s:ally_request(h, foe) == false and not s:has_request(h, foe), "Total War refuses alliances")
	local c = match("classic", 5)
	expect(c:ally_request(h, foe) ~= false, "Conquest allows them")
end

-- King of the Hill
do
	local tile = SimModes.crown_site(world)
	expect(tile >= 0 and world:is_contestable(tile) and tile == SimModes.crown_site(world), "the Crown's site is pure contestable land")
	local s, h = match("crown", 6)
	expect(s.crown_tile == tile and s.crown_need == 6000, "the Crown is on the map")
	buffer.writei32(s.owner, tile * 4, h)
	for _ = 1, 15 do
		s:step()
	end
	expect(s.crown_holder == 0 and (s.crown_ticks[h] or 0) == 0, "before it opens, holding the ground counts for nothing")
	s.crown_open = 0
	local off = match("classic", 6)
	expect(off.crown_tile == -1 and off:snapshot().crown == nil, "no Crown in Conquest, and no snapshot key")
	buffer.writei32(s.owner, tile * 4, h)
	local got
	for _ = 1, 25 do
		local d = s:step()
		for _, e in d.ev or {} do
			if e[1] == Ev.CROWN then
				got = e
			end
		end
	end
	expect(s.crown_holder == h and got ~= nil and got[2] == h and (s.crown_ticks[h] or 0) >= 20, "holding the ground holds the Crown (" .. tostring(s.crown_ticks[h]) .. ")")
	local snap = s:snapshot()
	local mirror = GameState.new(world)
	mirror:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(snap))))
	expect(mirror.mode == "crown" and mirror.crown ~= nil and mirror.crown[1] == tile and mirror.crown[3] == h and mirror.crown_ticks[h] == s.crown_ticks[h], "a late joiner sees it through the real Protocol")
	s.crown_ticks[h] = 5998
	buffer.writei32(s.owner, tile * 4, h)
	for _ = 1, 5 do
		buffer.writei32(s.owner, tile * 4, h)
		s:step()
	end
	expect(s.phase == Defs.PHASE_OVER and s.over_reason == Defs.OVER_CROWN and s.winner == h, "enough time ends the match, and the holder wins")
	local mid = GameState.new(world)
	mid:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(s:snapshot()))))
	expect(mid.phase == Defs.PHASE_OVER, "and the mirror agrees")
end

-- a public match: the server's own road (MatchServer._start_match) applies a rotated mode
do
	local MatchServer = require("../src/server/MatchServer")
	local got
	local fake = setmetatable({
		deps = {
			seed = function()
				return 7
			end,
			modes = {
				public_pick = Modes.public_pick,
				apply = function(c, k)
					Modes.apply(c, k)
					got = c
					return c
				end,
			},
			make_sim = function() end,
		},
		_map_id = "world",
		_continue_start = function() end,
	}, { __index = MatchServer })
	MatchServer._start_match(fake)
	expect(got ~= nil and got.mode == Modes.public_pick(7) and got.max_humans == MatchServer.MP_MAX_HUMANS, "the server's own start applies the rotated mode (" .. tostring(got and got.mode) .. ")")
	local cfg = Modes.apply({ time_limit_s = 2400 }, Modes.public_pick(7))
	expect(cfg.mode == Modes.public_pick(7) and cfg.time_limit_s == 2400, "a public match keeps its own clock under any mode")
	-- each of the crowd's modes builds a Sim the way the server does, and a Crown match ends on the Crown
	for _, key in { "classic", "blitz", "crown", "totalwar" } do
		local c = Modes.apply({ seed = 5, difficulty = 0, tribes = 20, max_humans = 4, time_limit_s = 2400, spawn_ticks = 30, nation_limit = 6, map_id = "world" }, key)
		Sim.with_defaults(c)
		local sim = Sim.new(world, c)
		for _ = 1, 40 do
			sim:step()
		end
		expect(sim.phase ~= nil and sim.mode == key, "public " .. key .. ": the Sim takes the config")
		if key == "crown" then
			sim.crown_open = 0
			local a = sim:add_bot_player("Seat", true)
			buffer.writei32(sim.owner, sim.crown_tile * 4, a)
			sim.o_alive[a] = 1
			sim.crown_ticks[a] = 5998
			for _ = 1, 5 do
				buffer.writei32(sim.owner, sim.crown_tile * 4, a)
				sim.phase = Defs.PHASE_PLAYING
				sim:step()
			end
			expect(sim.over_reason == Defs.OVER_CROWN and sim.winner == a, "a public Crown match ends on the Crown")
		end
	end
end

if fails > 0 then
	print("modes: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("modes: all passed")
