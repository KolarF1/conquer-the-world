--!native
-- Eras and Doctrines (Conquer the World's own; Data/Eras, Data/Doctrines): at the start of each era after
-- the first every eligible owner is offered three doctrines and keeps the one it picks. Humans choose
-- (a pick intent, or the first offer after Doctrines.DRAFT_TIMEOUT_S); nations and bot players are
-- picked for by hash, at once. Also the place where every economic multiplier is computed: landmarks and
-- doctrines, timed edicts and world events all end up in m_gold / m_cap / m_conq / m_trade / m_atk / m_def /
-- m_regen / m_claim / m_rebate, set once a second (and on a pick), so the numbers the HUD shows (o_income, o_cap)
-- are the numbers earned.
--
-- Off unless the match config says `doctrines = true` (landmarks: `landmarks = true`; the multipliers run
-- when either is on). Nothing here draws from the Sim's RNG.
--
-- The wire: Ev.DOCTRINE { id, draft, a, b, c, chosen, deadline } (a, b, c: indices into Doctrines.LIST;
-- chosen: 1..3 or 0 while open; deadline: tick) and, in a snapshot, `eras` and `doctrine` (the same rows,
-- a dense array, owner first). Rows only: Protocol's table writer takes dense arrays, never holes.
local Defs = require("./Defs")
local Ev = require("./Ev")
local NumberFormat = require("./NumberFormat")
local SimLandmarks = require("./SimLandmarks")
local Doctrines = require("../Data/Doctrines")
local Eras = require("../Data/Eras")
local WorldEvents = require("../Data/WorldEvents")
local Personas = require("../Data/Personas")

local TICK_RATE = 10
local readi32 = buffer.readi32

local SimDoctrines = {}

function SimDoctrines.install(Sim: any)
	--- Called from Sim.new after the map is known (`seed`: the match's, for the offer hash).
	function Sim._init_doctrines(self: any, cfg: { [string]: any }, seed: number)
		self.doctrines_on = cfg.doctrines == true
		self.doctrines_ai = cfg.doctrines_ai ~= false
		self.events_on = cfg.world_events == true
		self.mults_on = self.doctrines_on or self.landmarks_on == true or self.events_on
		self.seed = seed
		self.eras = if Eras.valid(cfg.era_ticks) then cfg.era_ticks else Eras.DEFAULT
		self.era = 1
		--- Seconds a person has to choose (the tutorial gives more); clamped.
		self.draft_timeout_s = math.clamp(tonumber(cfg.draft_timeout_s) or Doctrines.DRAFT_TIMEOUT_S, 10, 600)
		self._mults_dirty = false
		--- owner id -> the keys it picked, in order
		self.o_doc = {} :: { [number]: { string } }
		--- every draft row ever opened, in opening order: { id, draft, a, b, c, chosen, deadline }
		self.doc_rows = {} :: { { number } }
		--- owner id -> draft -> its row (the same tables as in doc_rows)
		self.doc_by = {} :: { [number]: { [number]: { number } } }
		self._doc_tick = {} :: { [number]: number }
		self.m_gold = {} :: { [number]: number }
		self.m_cap = {} :: { [number]: number }
		self.m_conq = {} :: { [number]: number }
		self.m_trade = {} :: { [number]: number }
		self.m_atk = {} :: { [number]: number }
		self.m_def = {} :: { [number]: number }
		self.m_regen = {} :: { [number]: number }
		self.m_claim = {} :: { [number]: number }
		self.m_rebate = {} :: { [number]: number }
		--- owner id -> the timed edict running: { lever, mult, until_tick }
		self.o_buff = {} :: { [number]: { any } }
		--- World events: the match's schedule, the next to start, the one running { index, start, end, leader }.
		self.world_schedule = if self.events_on then WorldEvents.schedule(seed, self.eras) else {}
		self._world_next = 1
		self.world_event = nil :: { number }?
		--- owner id -> tick its next edict is ready (a person's, once used)
		self.o_edict_ready = {} :: { [number]: number }
		--- landmark site index -> the owner that held it at the last look (for the capture messages)
		self._lm_holder = {} :: { [number]: number }
	end

	--- A real person: a human nation nobody else is playing for (not a bot, not an AI, not a leaver).
	local function is_person(self: any, id: number): boolean
		return self.o_kind[id] == Defs.KIND_HUMAN and self.o_ai[id] == 0 and self.o_bot[id] == 0 and self.o_left[id] == 0
	end

	local function eligible(self: any, id: number): boolean
		if self.o_alive[id] == 0 or self.o_spawned[id] == 0 then
			return false
		end
		local k = self.o_kind[id]
		return k == Defs.KIND_HUMAN or (k == Defs.KIND_NATION and self.doctrines_ai)
	end

	local function emit(self: any, row: { number })
		self:ev({ Ev.DOCTRINE, row[1], row[2], row[3], row[4], row[5], row[6], row[7] })
	end

	--- `defer`: many picks at once (an era opening): the multipliers are refreshed once afterwards.
	local function apply_pick(self: any, id: number, row: { number }, slot: number, defer: boolean?)
		row[6] = slot
		local d = Doctrines.LIST[row[2 + slot]]
		local keys = self.o_doc[id]
		if keys == nil then
			keys = {}
			self.o_doc[id] = keys
		end
		table.insert(keys, d.key)
		emit(self, row)
		if defer then
			self._mults_dirty = true
		else
			self:_refresh_mults()
		end
		if is_person(self, id) then
			self:msg(-1, Defs.MSG_INFO, string.format("%s drafted %s", self.o_name[id], d.name))
		end
	end

	--- Opens draft `draft` for `id` (once): a person gets an offer with a fresh deadline, anyone else is
	--- picked for at once.
	local function open_draft(self: any, id: number, draft: number)
		local by = self.doc_by[id]
		if by == nil then
			by = {}
			self.doc_by[id] = by
		end
		if by[draft] ~= nil then
			return
		end
		local o = Doctrines.offer(self.seed, id, draft)
		local person = is_person(self, id)
		local row = { id, draft, o[1], o[2], o[3], 0, if person then self.tick + self.draft_timeout_s * TICK_RATE else 0 }
		by[draft] = row
		table.insert(self.doc_rows, row)
		if person then
			emit(self, row)
		else
			local slot = Doctrines.mix(self.seed, id, draft + 7) % Doctrines.OFFER_SIZE + 1
			if self.rivals_on and self.o_kind[id] == Defs.KIND_NATION then
				slot = Personas.pick(Personas.of(self.seed, id), o)
			end
			apply_pick(self, id, row, slot, true)
		end
	end

	--- Per tick while playing (before the economy): era changes, drafts, timeouts.
	function Sim._doctrines_tick(self: any)
		local since = self.tick - self.playing_since
		local era = Eras.index(since, self.eras)
		local second = self.tick % TICK_RATE == 0
		if era ~= self.era then
			self.era = era
			second = true
		end
		local draft = Eras.draft_of(era)
		if second and draft >= 1 then
			-- (once a second: the era's drafts, for anyone who has none yet: a late spawn gets the current
			-- era's with a fresh deadline)
			for id = 1, self.owner_total do
				if eligible(self, id) then
					open_draft(self, id, draft)
				end
			end
		end
		-- timeouts: a person who has not chosen gets the first offer
		for _, row in self.doc_rows do
			if row[6] == 0 and row[7] > 0 and self.tick >= row[7] then
				if eligible(self, row[1]) then
					apply_pick(self, row[1], row, 1, true)
				else
					row[6] = -1 -- (gone: closed without a pick)
					emit(self, row)
				end
			end
		end
		if self._mults_dirty then
			self._mults_dirty = false
			self:_refresh_mults()
		end
	end

	--- The pick intent: `key` out of the open offer, once, by a person. True when taken.
	function Sim.doctrine_choose(self: any, id: number, key: string): boolean
		if not self.doctrines_on or not is_person(self, id) or self._doc_tick[id] == self.tick then
			return false
		end
		self._doc_tick[id] = self.tick
		local idx = Doctrines.INDEX[key]
		if idx == nil then
			return false
		end
		local by = self.doc_by[id]
		if by == nil then
			return false
		end
		for draft = 1, Doctrines.TIERS do
			local row = by[draft]
			if row ~= nil and row[6] == 0 then
				for slot = 1, Doctrines.OFFER_SIZE do
					if row[2 + slot] == idx then
						apply_pick(self, id, row, slot)
						return true
					end
				end
			end
		end
		return false
	end

	--- Everything the economy multiplies by, recomputed (once a second, and on a pick): landmarks (who
	--- holds what, their strength by doctrine and era) and doctrines.
	function Sim._refresh_mults(self: any)
		if not self.mults_on then
			return
		end
		if self.landmarks_on then
			self.landmark_held = SimLandmarks.held(self.landmark_sites, self.owner)
			self:_landmark_news()
		end
		local reckoning = if self.era >= #Eras.NAMES then Eras.RECKONING_LANDMARK_MULT else 1.0
		local we = self.world_event
		local boost = self.boost
		local def = nil
		if we ~= nil then
			if self.tick < we[3] then
				def = WorldEvents.LIST[we[1]]
			else
				self.world_event = nil
			end
		end
		local Mint, Garrison, Citadel, Harbor, Granary, Foundry =
			SimLandmarks.KIND_MINT,
			SimLandmarks.KIND_GARRISON,
			SimLandmarks.KIND_CITADEL,
			SimLandmarks.KIND_HARBOR,
			SimLandmarks.KIND_GRANARY,
			SimLandmarks.KIND_FOUNDRY
		for id = 1, self.owner_total do
			if self.o_alive[id] == 0 then
				continue
			end
			local keys = self.o_doc[id] or {}
			local held = self.landmark_held[id]
			local gold = Doctrines.mult(keys, "gold")
			local cap = Doctrines.mult(keys, "cap")
			local conq = Doctrines.mult(keys, "conq")
			local trade = Doctrines.mult(keys, "trade")
			local atk = Doctrines.mult(keys, "atk")
			local defence = Doctrines.mult(keys, "def")
			local regen = Doctrines.mult(keys, "regen")
			local claim = Doctrines.mult(keys, "claim")
			local rebate = Doctrines.mult(keys, "rebate") - 1.0
			local strength = Doctrines.mult(keys, "lm") * reckoning
			if def ~= nil and def.lm ~= nil then
				strength *= def.lm
			end
			if held ~= nil then
				gold *= 1.0 + SimLandmarks.MINT_GOLD_BONUS * held[Mint] * strength
				cap *= 1.0 + SimLandmarks.GARRISON_CAP_BONUS * held[Garrison] * strength
				defence *= 1.0 + SimLandmarks.CITADEL_DEF_BONUS * held[Citadel] * strength
				trade *= 1.0 + SimLandmarks.HARBOR_TRADE_BONUS * held[Harbor] * strength
				regen *= 1.0 + SimLandmarks.GRANARY_REGEN_BONUS * held[Granary] * strength
				rebate += SimLandmarks.FOUNDRY_REBATE * held[Foundry] * strength
			end
			local buff = self.o_buff[id]
			if buff ~= nil then
				if self.tick >= buff[3] then
					self.o_buff[id] = nil
				elseif buff[1] == "gold" then
					gold *= buff[2]
				elseif buff[1] == "atk" then
					atk *= buff[2]
				elseif buff[1] == "def" then
					defence *= buff[2]
				elseif buff[1] == "regen" then
					regen *= buff[2]
				end
			end
			if boost ~= nil and self.o_kind[id] ~= Defs.KIND_TRIBE then
				gold *= boost.gold or 1.0
				regen *= boost.regen or 1.0
			end
			if def ~= nil and self.o_kind[id] ~= Defs.KIND_TRIBE and (def.leader ~= true or id == we[4]) then
				gold *= def.gold or 1.0
				trade *= def.trade or 1.0
				atk *= def.atk or 1.0
				defence *= def.def or 1.0
				regen *= def.regen or 1.0
				claim *= def.claim or 1.0
				rebate += def.rebate or 0.0
			end
			self.m_gold[id] = gold
			self.m_cap[id] = cap
			self.m_conq[id] = conq
			self.m_trade[id] = trade
			self.m_atk[id] = atk
			self.m_def[id] = defence
			self.m_regen[id] = regen
			self.m_claim[id] = claim
			self.m_rebate[id] = math.clamp(rebate, 0.0, 0.6)
		end
	end

	--- World events: once a second while playing, the next on the match's schedule begins when its time comes.
	function Sim._world_events_tick(self: any)
		local since = self.tick - self.playing_since
		local nextw = self.world_schedule[self._world_next]
		if nextw == nil or since < nextw[1] then
			return
		end
		self._world_next += 1
		local def = WorldEvents.LIST[nextw[2]]
		local leader = 0
		if def.leader then
			local best = -1
			for id = 1, self.owner_total do
				if self.o_alive[id] == 1 and self.o_kind[id] ~= Defs.KIND_TRIBE and self.o_tiles[id] > best then
					best = self.o_tiles[id]
					leader = id
				end
			end
		end
		self.world_event = { nextw[2], self.tick, self.tick + def.secs * TICK_RATE, leader }
		self:ev({ Ev.WORLD_EVENT, nextw[2], self.tick, self.tick + def.secs * TICK_RATE, leader })
		local on = if leader > 0 then " in " .. self.o_name[leader] else ""
		self:msg(-1, Defs.MSG_INFO, string.format("%s%s: %s", def.name, on, def.line))
	end

	--- A building's refund (doctrines, Foundries, world events), after its cost was paid.
	function Sim._rebate(self: any, id: number, cost: number)
		if self.mults_on then
			local r = self.m_rebate[id]
			if r ~= nil and r > 0 then
				self.o_gold[id] += cost * r
			end
		end
	end

	--- Who took a landmark: a message for everyone when a person is on either side of the change (an AI
	--- swapping a Mint with another AI is not news).
	function Sim._landmark_news(self: any)
		for i, s in self.landmark_sites do
			local now = readi32(self.owner, s.tile * 4)
			local was = self._lm_holder[i]
			if was == nil then
				self._lm_holder[i] = now
			elseif was ~= now then
				self._lm_holder[i] = now
				if now > 0 and (is_person(self, now) or (was > 0 and is_person(self, was))) then
					self:msg(
						-1,
						Defs.MSG_INFO,
						string.format("%s took the %s", self.o_name[now], SimLandmarks.KIND_NAMES[s.kind])
					)
				end
			end
		end
	end

	--- An edict a doctrine holder may use (Doctrines.EDICTS). Once EDICT_COOLDOWN_TICKS, for a person who holds a
	--- doctrine granting it.
	SimDoctrines.EDICT_COOLDOWN_TICKS = 1800
	function Sim.edict_use(self: any, id: number, name: string): boolean
		if not self.doctrines_on or not is_person(self, id) then
			return false
		end
		return self:_edict_fire(id, name)
	end

	--- Fires edict `name` for `id` when it holds it and the cooldown is over (a person's intent; a nation's turn).
	function Sim._edict_fire(self: any, id: number, name: string): boolean
		if (self.o_edict_ready[id] or 0) > self.tick then
			return false
		end
		local e = Doctrines.EDICTS[name]
		if e == nil then
			return false
		end
		local owns = false
		for _, key in self.o_doc[id] or {} do
			local d = Doctrines.BY_KEY[key]
			if d ~= nil and d.edict == name then
				owns = true
			end
		end
		if not owns then
			return false
		end
		local buff_until = 0
		if e.gold_s ~= nil then
			local gold = self.o_income[id] * e.gold_s
			self.o_gold[id] += gold
			if is_person(self, id) then
				self:msg(id, Defs.MSG_GOOD, string.format("%s: +%s gold", e.name, NumberFormat.render_number(math.floor(gold))))
			end
		elseif e.troops ~= nil then
			local add = math.max(0, math.min(self.o_cap[id] * e.troops, self.o_cap[id] - self.o_troops[id]))
			self.o_troops[id] += add
			if is_person(self, id) then
				self:msg(id, Defs.MSG_GOOD, string.format("%s: +%s troops", e.name, NumberFormat.render_troops(math.floor(add))))
			end
		else
			buff_until = self.tick + e.secs * TICK_RATE
			self.o_buff[id] = { e.lever, e.mult, buff_until }
			if is_person(self, id) then
				self:msg(id, Defs.MSG_GOOD, string.format("%s: %s", e.name, e.line))
			end
			self:_refresh_mults()
		end
		self.o_edict_ready[id] = self.tick + SimDoctrines.EDICT_COOLDOWN_TICKS
		self:ev({ Ev.EDICT, id, self.o_edict_ready[id], buff_until })
		return true
	end

	--- The passive gold income per second of `id` with its multipliers (what o_income holds).
	function Sim._income_of(self: any, id: number, passive: number): number
		return passive * (self.m_gold[id] or 1.0)
	end

	--- The troop cap of `id` with its multipliers (what o_cap holds), from the rules' base `cap`.
	function Sim._cap_of(self: any, id: number, cap: number): number
		local m = self.m_cap[id]
		return if m == nil then cap else math.floor(cap * m)
	end

	--- Snapshot keys (nil when the system is off: a snapshot of an upstream-style match is unchanged).
	function Sim._doctrine_snapshot(self: any): ({ number }?, { { number } }?, { { number } }?, { number }?)
		local we = self.world_event
		local we_row = if we ~= nil then { we[1], we[2], we[3], we[4] } else nil
		if not self.doctrines_on then
			return nil, nil, nil, we_row
		end
		local edicts = {}
		for id = 1, self.owner_total do
			local t = self.o_edict_ready[id]
			if t ~= nil then
				local b = self.o_buff[id]
				table.insert(edicts, { id, t, if b ~= nil then b[3] else 0 })
			end
		end
		local rows = {}
		for _, r in self.doc_rows do
			table.insert(rows, { r[1], r[2], r[3], r[4], r[5], r[6], r[7] })
		end
		local eras = {}
		for i, t in self.eras do
			eras[i] = t
		end
		return eras, rows, edicts, we_row
	end
end

return SimDoctrines
