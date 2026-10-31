--!nocheck
-- Eras and Doctrines (Conquer the World's own): the data, the sim rules, and the wire. Everything here goes
-- through the real Protocol (encode / decode) for the mirror, never straight from Sim to GameState, because
-- the solo path skips Protocol and only a multiplayer match would meet its schema limits.
-- Run: lune run tests/doctrines.luau
local serde = require("@lune/serde")
require("./prelude")
local Defs = require("../src/shared/Core/Defs")
local Ev = require("../src/shared/Core/Ev")
local WorldMap = require("../src/shared/Core/WorldMap")
local Sim = require("../src/shared/Core/Sim")
local GameState = require("../src/shared/Core/GameState")
local Protocol = require("../src/shared/Net/Protocol")
local Doctrines = require("../src/shared/Data/Doctrines")
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

-- ---------------------------------------------------------------------------------------------
-- Data: Eras
-- ---------------------------------------------------------------------------------------------
expect(Eras.valid(Eras.DEFAULT) and Eras.valid(Eras.TUTORIAL), "the default and the tutorial's eras are valid tables")
expect(not Eras.valid({ 0, 5, 5, 9 }) and not Eras.valid({ 1, 2, 3, 4 }) and not Eras.valid({ 0, 1, 2 }) and not Eras.valid("x"), "junk eras are refused")
expect(Eras.index(0) == 1 and Eras.index(1799) == 1 and Eras.index(1800) == 2 and Eras.index(9600) == 4 and Eras.index(-5) == 1, "era at a tick")
expect(Eras.index(0 / 0) == 1, "NaN is the first era")
expect(Eras.ticks_to_next(1000) == 800 and Eras.ticks_to_next(9600) == nil, "ticks to the next era, none in the last")
expect(Eras.draft_of(1) == 0 and Eras.draft_of(2) == 1 and Eras.draft_of(4) == 3, "drafts open with era 2")
expect(Eras.TUTORIAL[2] <= 1800, "the tutorial's first draft is within three minutes")

-- ---------------------------------------------------------------------------------------------
-- Data: Doctrines
-- ---------------------------------------------------------------------------------------------
expect(#Doctrines.LIST == 24, "twenty-four doctrines")
local keys, levers = {}, {}
for _, l in Doctrines.LEVERS do
	levers[l] = true
end
local tier_n = { 0, 0, 0 }
local bad_key, bad_lever, net_bad = nil, nil, nil
for _, d in Doctrines.LIST do
	if keys[d.key] or #d.key > 16 or #d.key == 0 then
		bad_key = d.key
	end
	keys[d.key] = true
	tier_n[d.tier] += 1
	local net = 0
	for k, v in d :: any do
		if type(v) == "number" and k ~= "tier" then
			if not levers[k] then
				bad_lever = k
			end
			net += v * ({ gold = 1, cap = 1, lm = 0.4, conq = 0.25, trade = 0.4, atk = 1, def = 1, regen = 0.6, claim = 0.4, rebate = 0.6 })[k]
		end
	end
	-- a trade-off still has to be worth taking, and nothing may be a free lunch
	if net <= 0.05 or net > 0.5 then
		net_bad = d.key .. " " .. net
	end
end
expect(bad_key == nil, "keys are unique and fit an intent's 16 characters (" .. tostring(bad_key) .. ")")
expect(bad_lever == nil, "only known levers (" .. tostring(bad_lever) .. ")")
expect(tier_n[1] == 8 and tier_n[2] == 8 and tier_n[3] == 8, "eight doctrines a tier")
expect(net_bad == nil, "every doctrine nets a modest positive value (" .. tostring(net_bad) .. ")")
for _, d in Doctrines.LIST do
	expect((d.cap or 0) >= 0, d.key .. ": never lowers the troop cap (a lowered cap would delete troops in a tick)")
end
for _, d in Doctrines.pool(3) do
	expect(d.edict ~= nil and Doctrines.EDICTS[d.edict] ~= nil, d.key .. ": grants a known edict")
end
local seen = {}
local distinct, in_pool, deterministic, varies = true, true, true, false
for seed = 1, 40 do
	for id = 1, 20 do
		for draft = 1, 3 do
			local o = Doctrines.offer(seed, id, draft)
			local o2 = Doctrines.offer(seed, id, draft)
			distinct = distinct and #o == 3 and o[1] ~= o[2] and o[2] ~= o[3] and o[1] ~= o[3]
			for i = 1, 3 do
				deterministic = deterministic and o[i] == o2[i]
				in_pool = in_pool and Doctrines.LIST[o[i]].tier == draft
				seen[o[i]] = true
			end
			if seed > 1 and o[1] ~= Doctrines.offer(1, id, draft)[1] or o[3] ~= Doctrines.offer(1, id, draft)[3] then
				varies = true
			end
		end
	end
end
local n_seen = 0
for _ in seen do
	n_seen += 1
end
expect(distinct and in_pool and deterministic, "offers: three distinct doctrines of the draft's tier, the same every time")
expect(n_seen == 24 and varies, "across seeds and players every doctrine is offered and offers differ")
expect(Doctrines.mult({}, "gold") == 1.0 and math.abs(Doctrines.mult({ "merchant", "tithe" }, "gold") - 1.25) < 1e-9, "multipliers add up (1 + the sum)")
expect(Doctrines.mult({ "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder", "plunder" }, "gold") == 0.2, "a multiplier never falls below 0.2")
expect(Doctrines.mult({ "nope" }, "gold") == 1.0, "an unknown key counts for nothing")
local eff = Doctrines.effects(Doctrines.BY_KEY.plunder)
expect(#eff == 2 and eff[1] == "-10% gold" or eff[2] == "-10% gold", "a card prints its numbers, trade-off included")

-- ---------------------------------------------------------------------------------------------
-- Sim
-- ---------------------------------------------------------------------------------------------
local world = WorldMap.shared()
local function start_tile(): number
	for k = 0, world.land_count - 1 do
		local t = world:land_tile(k)
		if world:is_contestable(t) then
			local x, y = world:tile_x(t), world:tile_y(t)
			if x > 60 and y > 60 and x < world.W - 60 and y < world.H - 60 then
				return t
			end
		end
	end
	error("no start tile")
end
local START = start_tile()
local ERAS = { 0, 100, 300, 500 }

local function match(flags: { [string]: any }?, seed: number?): (any, number)
	local cfg = { seed = seed or 9, difficulty = 1, tribes = 0, max_humans = 1, nations = true, nation_limit = 6, era_ticks = ERAS }
	for k, v in flags or {} do
		cfg[k] = v
	end
	local sim = Sim.new(world, cfg)
	local h = sim:add_human("me", "Me")
	assert(sim:human_start(h, START), "spawn accepted")
	while sim.phase ~= Defs.PHASE_PLAYING do
		sim:step()
	end
	return sim, h
end
local function run(sim: any, ticks: number)
	for _ = 1, ticks do
		sim:step()
	end
end

-- off by default, whatever DEFAULTS says
do
	expect(Sim.DEFAULTS.doctrines == true and Sim.DEFAULTS.landmarks == true, "the shipped game turns both systems on")
	local sim, h = match(nil)
	run(sim, 150)
	expect(not sim.doctrines_on and #sim.doc_rows == 0 and sim:snapshot().doctrine == nil and sim:snapshot().eras == nil, "Sim.new leaves doctrines off, and its snapshot has no new keys")
end

-- on: the first draft opens with era 2
local sim, h = match({ doctrines = true })
local start = sim.playing_since
expect(sim.doctrines_on and sim.era == 1 and #sim.doc_rows == 0, "no draft during the Dawn")
local income_before, cap_before = nil, nil
run(sim, 90)
income_before, cap_before = sim.o_income[h], sim.o_cap[h]
run(sim, 20)
expect(sim.era == 2, "era 2 begins at its tick")
local row = sim.doc_by[h] and sim.doc_by[h][1]
expect(row ~= nil and row[6] == 0 and row[7] > sim.tick and row[7] <= sim.tick + Doctrines.DRAFT_TIMEOUT_S * 10, "the human has an open offer with a deadline ahead")
local nation_rows, picked = 0, 0
for _, r in sim.doc_rows do
	if r[1] ~= h then
		nation_rows += 1
		if r[6] >= 1 and r[6] <= 3 then
			picked += 1
		end
	end
end
expect(nation_rows > 0 and picked == nation_rows, "nations are picked for at once (" .. picked .. " of " .. nation_rows .. ")")
local offered = Doctrines.offer(9, h, 1)
expect(row[3] == offered[1] and row[4] == offered[2] and row[5] == offered[3], "the offer is the pure function's")

-- a wrong pick, then a right one
local not_offered
for _, d in Doctrines.pool(1) do
	if Doctrines.INDEX[d.key] ~= offered[1] and Doctrines.INDEX[d.key] ~= offered[2] and Doctrines.INDEX[d.key] ~= offered[3] then
		not_offered = d.key
	end
end
sim:submit(h, { type = "doctrine", kind = not_offered })
sim:step()
expect(sim.doc_by[h][1][6] == 0 and sim.o_doc[h] == nil, "a doctrine that was not offered is refused")
local nation
for id = 1, sim.owner_total do
	if sim.o_kind[id] == Defs.KIND_NATION and sim.o_alive[id] == 1 then
		nation = id
	end
end
sim:submit(nation, { type = "doctrine", kind = Doctrines.LIST[offered[1]].key })
sim:step()
expect(sim.o_doc[h] == nil, "nobody else can pick for the human, and a nation cannot be told to pick")
local pick = Doctrines.LIST[offered[2]]
sim:submit(h, { type = "doctrine", kind = pick.key })
sim:step()
expect(sim.doc_by[h][1][6] == 2 and sim.o_doc[h][1] == pick.key, "the offered doctrine is taken (" .. pick.key .. ")")
sim:submit(h, { type = "doctrine", kind = Doctrines.LIST[offered[1]].key })
sim:step()
expect(#sim.o_doc[h] == 1, "no second pick from the same draft")
-- the numbers move by what the card says, and the shown numbers are the earned ones
run(sim, 25)
local gm = 1 + (pick.gold or 0)
local cm = 1 + (pick.cap or 0)
expect(math.abs(sim.o_income[h] / income_before - gm) < 0.02, string.format("income moved by the card's %+d%% (x%.3f)", (pick.gold or 0) * 100, sim.o_income[h] / income_before))
expect(sim.o_cap[h] >= cap_before * (cm - 0.02), "the troop cap moved by the card's amount")
expect(sim:snapshot().owners[h][10] == math.floor(sim.o_cap[h]), "and the snapshot's cap row is the real cap")

-- a human who does not choose gets the first offer when the deadline passes
do
	local s2, h2 = match({ doctrines = true }, 11)
	run(s2, 110)
	local r2 = s2.doc_by[h2][1]
	expect(r2[6] == 0, "open before the deadline")
	run(s2, Doctrines.DRAFT_TIMEOUT_S * 10 + 5)
	expect(r2[6] == 1 and s2.o_doc[h2][1] == Doctrines.LIST[r2[3]].key, "the first offer is taken when the timer runs out")
	-- era 3 opens another draft (tier 2), and its offers are tier 2's
	run(s2, 200)
	local r3 = s2.doc_by[h2][2]
	expect(r3 ~= nil and Doctrines.LIST[r3[3]].tier == 2, "the Conflict opens a tier 2 draft")
end

-- same seed, same drafts
do
	local a, ha = match({ doctrines = true }, 21)
	local b, hb = match({ doctrines = true }, 21)
	run(a, 400)
	run(b, 400)
	local same = #a.doc_rows == #b.doc_rows
	for i, r in a.doc_rows do
		for k = 1, 7 do
			same = same and b.doc_rows[i] ~= nil and b.doc_rows[i][k] == r[k]
		end
	end
	expect(same and #a.doc_rows > 0, "two matches with one seed draft the same (" .. #a.doc_rows .. " rows)")
end

-- the Reckoning doubles landmarks
do
	local s3, h3 = match({ doctrines = true, landmarks = true }, 5)
	local mint
	for _, s in s3.landmark_sites do
		if s.kind == 1 then
			mint = s
		end
	end
	run(s3, 40)
	buffer.writei32(s3.owner, mint.tile * 4, h3)
	run(s3, 40)
	local base = s3.m_gold[h3]
	run(s3, 500)
	buffer.writei32(s3.owner, mint.tile * 4, h3)
	run(s3, 15)
	expect(s3.era == 4, "era 4 reached")
	local keys3 = s3.o_doc[h3] or {}
	local lm = Doctrines.mult(keys3, "lm") * Eras.RECKONING_LANDMARK_MULT
	local want = (1 + 0.20 * lm) * Doctrines.mult(keys3, "gold")
	expect(math.abs(s3.m_gold[h3] - want) < 1e-9, string.format("in the Reckoning a Mint pays x%.2f (landmark strength x%.1f)", s3.m_gold[h3], lm))
	expect(base < s3.m_gold[h3] or Doctrines.mult(keys3, "gold") < 1, "and more than it did before")
end

-- Edicts and landmark news
do
	local s5, h5 = match({ doctrines = true, landmarks = true }, 41)
	run(s5, 2)
	-- hand the human a tier 3 doctrine with an edict, as a pick would
	s5.o_doc[h5] = { "coin", "grandarmy" }
	run(s5, 3)
	local g0 = s5.o_gold[h5]
	s5:submit(h5, { type = "edict", kind = "levy" })
	s5.o_troops[h5] = 1000
	s5:step()
	expect(s5.o_troops[h5] > 1000 + s5.o_cap[h5] * 0.15, "the Levy brings a fifth of the cap as troops")
	local ready = s5.o_edict_ready[h5]
	expect(ready ~= nil and ready > s5.tick, "and starts its cooldown")
	s5.o_troops[h5] = 1000
	s5:submit(h5, { type = "edict", kind = "levy" })
	s5:step()
	expect(s5.o_troops[h5] < 2000, "a second Levy inside the cooldown does nothing")
	s5:submit(h5, { type = "edict", kind = "windfall" })
	s5:step()
	expect(s5.o_gold[h5] - g0 < s5.o_income[h5] * 5, "one cooldown covers every edict: a Windfall right after a Levy waits too")
	local s8, h8 = match({ doctrines = true }, 44)
	run(s8, 3)
	s8.o_doc[h8] = { "coin" }
	local g8 = s8.o_gold[h8]
	s8:submit(h8, { type = "edict", kind = "windfall" })
	s8:step()
	expect(s8.o_gold[h8] - g8 > s8.o_income[h8] * 50, "the Windfall pays about a minute of income at once")
	s5:submit(h5, { type = "edict", kind = "bogus" })
	s5:step()
	local rows = s5:snapshot().edict
	expect(rows ~= nil and #rows == 1 and rows[1][1] == h5, "the snapshot carries the cooldown as a dense row")
	-- not held, not allowed
	local s6, h6 = match({ doctrines = true }, 42)
	run(s6, 3)
	s6.o_doc[h6] = { "merchant" }
	s6:submit(h6, { type = "edict", kind = "windfall" })
	local g1 = s6.o_gold[h6]
	s6:step()
	expect(s6.o_edict_ready[h6] == nil, "an edict no held doctrine grants is refused")
	-- a person taking a landmark is news
	local s7, h7 = match({ doctrines = true, landmarks = true }, 43)
	local site = s7.landmark_sites[1]
	run(s7, 12)
	local news = 0
	local before_msgs = #s7.d_ev
	buffer.writei32(s7.owner, site.tile * 4, h7)
	for _ = 1, 12 do
		local d = s7:step()
		for _, e in d.ev or {} do
			if e[1] == Ev.MSG and string.find(tostring(e[4]), "took the", 1, true) then
				news += 1
			end
		end
	end
	expect(news == 1, "a person taking a landmark is announced once (" .. news .. ")")
end

-- New levers: attack, defence, regrowth, claims, refunds
do
	local s9, h9 = match({ doctrines = true }, 61)
	run(s9, 3)
	s9.o_doc[h9] = { "drill", "ironwall", "lightning", "pioneers", "masons" }
	s9:_refresh_mults()
	expect(math.abs(s9.m_regen[h9] - 1.25) < 1e-9 and math.abs(s9.m_def[h9] - 1.30) < 1e-9, "regrowth and defence take the cards' numbers")
	expect(math.abs(s9.m_atk[h9] - 1.28) < 1e-9 and math.abs(s9.m_claim[h9] - 1.40) < 1e-9, "attack and claims too")
	expect(math.abs(s9.m_rebate[h9] - 0.15) < 1e-9, "the refund is a share, not a multiplier")
	local g = s9.o_gold[h9]
	s9:_rebate(h9, 1000)
	expect(math.abs(s9.o_gold[h9] - g - 150) < 1e-6, "a building hands back the refund")
	-- regrowth: the same army grows faster
	local a1, ha = match({ doctrines = true }, 62)
	local b1, hb = match({ doctrines = true }, 62)
	run(a1, 3)
	run(b1, 3)
	b1.o_doc[hb] = { "service", "conscripts" }
	b1:_refresh_mults()
	a1.o_troops[ha], b1.o_troops[hb] = 2000, 2000
	a1:step()
	b1:step()
	expect(b1.o_troops[hb] > a1.o_troops[ha], "a regrowth doctrine fills the ranks sooner")
	-- timed edicts
	local s10, h10 = match({ doctrines = true }, 63)
	run(s10, 3)
	s10.o_doc[h10] = { "ironwall" }
	s10:submit(h10, { type = "edict", kind = "fortify" })
	s10:step()
	expect(math.abs(s10.m_def[h10] - 1.30 * 1.5) < 1e-9 and s10.o_buff[h10] ~= nil, "Fortify multiplies defence while it runs")
	local rows = s10:snapshot().edict
	expect(rows[1][3] == s10.o_buff[h10][3], "the snapshot carries when it ends")
	run(s10, 610)
	expect(s10.o_buff[h10] == nil and math.abs(s10.m_def[h10] - 1.30) < 1e-9, "and it ends on time")
	for name, e in Doctrines.EDICTS do
		expect(type(e.name) == "string" and type(e.line) == "string" and (e.gold_s or e.troops or (e.lever and e.mult and e.secs)), "edict " .. name .. " is complete")
		expect(table.find(Doctrines.EDICT_ORDER, name) ~= nil, "edict " .. name .. " has a chip")
	end
	-- combat: a defence lever slows and costs the attacker
	local function fight(defkeys, atkkeys)
		local f, hf = match({ doctrines = true }, 70)
		run(f, 3)
		local foe
		for id = 1, f.owner_total do
			if f.o_kind[id] == Defs.KIND_NATION and f.o_alive[id] == 1 then
				foe = id
				break
			end
		end
		f.o_doc[foe] = defkeys
		f.o_doc[hf] = atkkeys
		f:_refresh_mults()
		return f.m_def[foe] / f.m_atk[hf]
	end
	expect(fight({ "ironwall" }, {}) > 1 and fight({}, { "lightning" }) < 1, "the combat ratio moves with both sides' levers")
end

-- World events
do
	local WorldEvents = require("../src/shared/Data/WorldEvents")
	expect(#WorldEvents.LIST == 12, "twelve world events")
	local keys2 = {}
	for _, d in WorldEvents.LIST do
		expect(not keys2[d.key] and d.secs >= 30 and #d.line > 0, d.key .. ": unique, with a time and a line")
		keys2[d.key] = true
	end
	local sch = WorldEvents.schedule(9, Eras.DEFAULT)
	local rising, norepeat = true, true
	for i = 2, #sch do
		rising = rising and sch[i][1] > sch[i - 1][1]
		norepeat = norepeat and sch[i][2] ~= sch[i - 1][2]
	end
	expect(rising and norepeat and sch[1][1] >= Eras.DEFAULT[2], "the schedule rises, starts in the Expansion and never repeats back to back")
	local seen_ev = {}
	for seed = 1, 60 do
		for _, r in WorldEvents.schedule(seed, Eras.DEFAULT) do
			seen_ev[r[2]] = true
		end
	end
	local n_ev = 0
	for _ in seen_ev do
		n_ev += 1
	end
	expect(n_ev == 12, "across seeds every event comes up")
	local s, h = match({ world_events = true, doctrines = false }, 81)
	expect(s.events_on and s.mults_on, "the flag turns events on")
	local off = match(nil, 81)
	expect(not off.events_on and #off.world_schedule == 0 and off:snapshot().world_event == nil, "off by default, no snapshot key")
	local fired
	local first = s.world_schedule[1]
	local guard = 0
	while fired == nil and guard < first[1] + 400 do
		guard += 1
		local d = s:step()
		for _, e in d.ev or {} do
			if e[1] == Ev.WORLD_EVENT then
				fired = e
			end
		end
	end
	expect(fired ~= nil and fired[2] == first[2], "the first event begins on schedule (" .. WorldEvents.LIST[first[2]].key .. ")")
	expect(s.world_event ~= nil and s:snapshot().world_event[1] == first[2], "the snapshot carries it for a late joiner")
	local mirror = GameState.new(world)
	mirror:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(s:snapshot()))))
	expect(mirror.world_event ~= nil and mirror.world_event[1] == first[2] and mirror.world_event[3] == s.world_event[3], "through the real Protocol")
	-- the numbers: force a gold event and a leader event
	local g1, hg = match({ world_events = true }, 83)
	run(g1, 3)
	g1.world_event = { 1, g1.tick, g1.tick + 500, 0 }
	g1:_refresh_mults()
	expect(math.abs(g1.m_gold[hg] - 1.5) < 1e-9, "a Gold Rush multiplies gold")
	local idx
	for i, d in WorldEvents.LIST do
		if d.key == "taxrevolt" then
			idx = i
		end
	end
	g1.world_event = { idx, g1.tick, g1.tick + 500, hg + 1 }
	g1:_refresh_mults()
	expect(g1.m_gold[hg] == 1.0, "a leader's event spares everyone else")
	g1.world_event = { idx, g1.tick, g1.tick + 500, hg }
	g1:_refresh_mults()
	expect(math.abs(g1.m_gold[hg] - 0.6) < 1e-9, "and falls on the leader")
	g1.world_event = { 1, g1.tick - 10, g1.tick - 1, 0 }
	g1:_refresh_mults()
	expect(g1.world_event == nil and g1.m_gold[hg] == 1.0, "and an event ends by itself")
end

-- Rivals
do
	local Personas = require("../src/shared/Data/Personas")
	expect(#Personas.LIST == 5, "five personas")
	local a, b = Personas.of(9, 4), Personas.of(9, 4)
	expect(a == b, "a nation's persona is pure")
	local seen_p, seen_n = {}, 0
	for id = 1, 80 do
		local p = Personas.of(9, id)
		if not seen_p[p.key] then
			seen_p[p.key] = true
			seen_n += 1
		end
	end
	expect(seen_n == 5, "a match has all kinds")
	for _, p in Personas.LIST do
		expect(#p.taunts >= 4 and p.aggr > 0, p.key .. ": lines and a temper")
	end
	local gold_offer = { Doctrines.INDEX.levy, Doctrines.INDEX.merchant, Doctrines.INDEX.wardens }
	local merchant
	for _, p in Personas.LIST do
		if p.key == "merchant" then
			merchant = p
		end
	end
	expect(Personas.pick(merchant, gold_offer) == 2, "a merchant takes the gold card")
	local s, h = match({ doctrines = true, rivals = true, nation_limit = 6 }, 91)
	local off = match({ doctrines = true }, 91)
	local nation
	for id = 1, s.owner_total do
		if s.o_kind[id] == Defs.KIND_NATION and s.o_alive[id] == 1 then
			nation = id
			break
		end
	end
	expect(s.ai.aggression[nation] == off.ai.aggression[nation] * Personas.of(91, nation).aggr or math.abs(s.ai.aggression[nation] / off.ai.aggression[nation] - Personas.of(91, nation).aggr) < 1e-5, "a persona bends the AI's aggression")
	-- the attack hook: taunt, then nemesis, then a bounty
	local msgs = {}
	local function collect(d)
		for _, e in d.ev or {} do
			if e[1] == Ev.MSG then
				table.insert(msgs, tostring(e[4]))
			end
		end
	end
	s:_on_attack_started({ attacker = nation, target = h })
	collect(s:step())
	expect(#msgs >= 1 and string.find(msgs[1], s.o_name[nation], 1, true) ~= nil, "a nation coming for a person says so")
	s:_on_attack_started({ attacker = nation, target = h })
	s:_on_attack_started({ attacker = nation, target = h })
	expect(s.o_nemesis[h] == nation, "the third attack makes it the nemesis")
	local snapn = s:snapshot()
	expect(snapn.persona_seed == 91 and snapn.nemesis ~= nil and snapn.nemesis[1][2] == nation, "the snapshot carries both")
	local mir = GameState.new(world)
	mir:load_snapshot(Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(snapn))))
	expect(mir.persona_seed == 91 and mir.nemesis[h] == nation, "through the real Protocol")
	s.o_income[h] = 100
	local g = s.o_gold[h]
	s:_rivals_eliminated(nation, h)
	expect(math.abs(s.o_gold[h] - g - 9000) < 1e-6 and s.o_nemesis[h] == 0, "the avenger collects the bounty")
	-- nations fire their edicts
	local s2 = match({ doctrines = true, rivals = true }, 92)
	local n2
	for id = 1, s2.owner_total do
		if s2.o_kind[id] == Defs.KIND_NATION and s2.o_alive[id] == 1 then
			n2 = id
			break
		end
	end
	s2.o_doc[n2] = { "merchant", "charter", "coin" }
	local g2 = s2.o_gold[n2]
	for _ = 1, 320 do
		s2:step()
	end
	expect(s2.o_edict_ready[n2] ~= nil, "a nation with an edict uses it")
	expect(not match(nil, 93).rivals_on, "off by default")
end

-- ---------------------------------------------------------------------------------------------
-- The wire
-- ---------------------------------------------------------------------------------------------
do
	local intent = Protocol.encode_intent({ type = "doctrine", kind = "grandarmy" })
	local back = intent ~= nil and Protocol.decode_intent(intent)
	expect(back and back.type == "doctrine" and back.kind == "grandarmy", "the doctrine intent round-trips")
	local ed = Protocol.decode_intent(Protocol.encode_intent({ type = "edict", kind = "windfall" }) :: buffer)
	expect(ed and ed.type == "edict" and ed.kind == "windfall", "the edict intent round-trips")
	local long = Protocol.decode_intent(Protocol.encode_intent({ type = "doctrine", kind = "abcdefghijklmnopqrstuvwxyz" }) :: buffer)
	expect(long == nil or #long.kind <= 16, "a long key never gets past 16 characters")
end

do
	-- a multiplayer-style mirror: the snapshot and every delta through the Protocol, compressed
	local s4, h4 = match({ doctrines = true, landmarks = true, world_events = true, rivals = true }, 31)
	run(s4, 105)
	local mirror = GameState.new(world)
	local snap = Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(s4:snapshot())))
	mirror:load_snapshot(snap)
	expect(mirror.eras ~= nil and mirror.eras[2] == 100 and #mirror.eras == 4, "a snapshot carries the eras")
	expect(mirror.doctrine[h4] ~= nil and mirror.doctrine[h4][1] ~= nil and mirror.doctrine[h4][1][6] == 0, "a late joiner's snapshot carries the open offer and its deadline")
	local events = 0
	local fired = 0
	mirror.doctrine_changed:Connect(function()
		fired += 1
	end)
	s4:submit(h4, { type = "doctrine", kind = Doctrines.LIST[mirror.doctrine[h4][1][4]].key })
	for _ = 1, 700 do
		local d = s4:step()
		for _, e in d.ev or {} do
			if e[1] == Ev.DOCTRINE then
				events += 1
			end
		end
		mirror:apply_delta(Protocol.decode_delta(Protocol.compress(Protocol.encode_delta(d, nil, s4.W))))
	end
	local same = true
	for _, r in s4.doc_rows do
		local m = mirror.doctrine[r[1]] and mirror.doctrine[r[1]][r[2]]
		for k = 1, 7 do
			same = same and m ~= nil and m[k] == r[k]
		end
	end
	-- the whole picture, not only the new rows: territory, and each owner's cap and income as shown
	local grid_same = buffer.tostring(mirror.owner) == buffer.tostring(s4.owner)
	local stats_same = true
	for id = 1, s4.owner_total do
		local o = mirror.owners[id]
		if o ~= nil and s4.o_alive[id] == 1 then
			stats_same = stats_same and o.max_troops == math.floor(s4.o_cap[id])
		end
	end
	expect(grid_same and stats_same, "territory and troop caps on the mirror equal the sim's with both systems on")
	expect(events > 0 and fired > 0 and same, "the mirror holds every draft row the sim does after " .. events .. " events through the wire")
	local snap2 = Protocol.decode_snapshot(Protocol.compress(Protocol.encode_snapshot(s4:snapshot())))
	local late = GameState.new(world)
	late:load_snapshot(snap2)
	local same2 = true
	for _, r in s4.doc_rows do
		local m = late.doctrine[r[1]] and late.doctrine[r[1]][r[2]]
		for k = 1, 7 do
			same2 = same2 and m ~= nil and m[k] == r[k]
		end
	end
	expect(same2, "and so does a client that joined late, from a snapshot")
end

if fails > 0 then
	print("doctrines: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("doctrines: all passed")
