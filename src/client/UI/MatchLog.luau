--!nonstrict
-- What happened in this match, from the local player's side (Conquer the World's own): the land over time and the
-- moments worth remembering, for the War Report, and the counts a match report needs (Data/Progress). It only
-- listens to the mirror; nothing here touches the match.
--
--   log:reset(state)                 a new match
--   log:<on_*>(...)                  fed by UIRoot from the mirror's signals
--   log:report(won, extras)          the match report so far
local UICtx = require("./UICtx")
local Defs = UICtx.core("Defs")

local MatchLog = {}
MatchLog.__index = MatchLog

--- A sample of the land every this many ticks; the list halves itself past MAX_SAMPLES.
MatchLog.SAMPLE_TICKS = 50
MatchLog.MAX_SAMPLES = 96
MatchLog.MAX_MOMENTS = 40

function MatchLog.new(ctx: any)
	local self = setmetatable({}, MatchLog)
	self.ctx = ctx
	self:reset(nil)
	return self
end

function MatchLog.reset(self, state: any)
	self.state = state
	self.samples = {} :: { { number } } -- { seconds, my share, the leader's share }
	self.moments = {} :: { { any } } -- { seconds, text, good }
	self.step = MatchLog.SAMPLE_TICKS
	self.next_tick = 0
	self.builds = 0
	self.nukes = 0
	self.edicts = 0
	self.nemeses = 0
	self.events = 0
	self.landmarks = 0
	self.eliminated_at = nil
	self.was_nemesis = 0
	self.last_out = 0
	self.last_killer = 0
	self.lm_poll = 0
end

function MatchLog._secs(self): number
	return self.ctx:match_seconds()
end

function MatchLog.moment(self, text: string, good: boolean?)
	if #self.moments < MatchLog.MAX_MOMENTS then
		table.insert(self.moments, { self:_secs(), text, good == true })
	end
end

--- Every mirror tick.
function MatchLog.on_tick(self, tick: number)
	local s, me = self.state, self.ctx:me()
	if s == nil or me == 0 or s.phase ~= Defs.PHASE_PLAYING then
		return
	end
	if tick >= self.next_tick then
		self.next_tick = tick + self.step
		local top = 0.0
		for id, o in s.owners do
			if o.kind ~= Defs.KIND_TRIBE and o.alive then
				top = math.max(top, s:land_share(id))
			end
		end
		table.insert(self.samples, { self:_secs(), s:land_share(me), top })
		if #self.samples > MatchLog.MAX_SAMPLES then
			local kept = {}
			for i = 1, #self.samples, 2 do
				table.insert(kept, self.samples[i])
			end
			self.samples = kept
			self.step *= 2
		end
		self:_count_landmarks(s, me)
	end
end

function MatchLog._count_landmarks(self, s: any, me: number)
	local SimLandmarks = UICtx.core("SimLandmarks")
	if self._sites_map ~= s.map then
		self._sites_map = s.map
		self._sites = SimLandmarks.sites(s.map)
	end
	local n = 0
	for _, site in self._sites do
		if s:tile_owner(site.tile) == me then
			n += 1
		end
	end
	if n > self.landmarks then
		self.landmarks = n
		if n >= 3 then
			self:moment(string.format("You held %d landmarks at once", n), true)
		end
	end
end

function MatchLog.on_structure(self, sid: number)
	local s = self.state
	local st = s ~= nil and s.structures[sid]
	if st and st.owner == self.ctx:me() then
		self.builds += 1
	end
end

function MatchLog.on_nuke(self, uid: number)
	local s = self.state
	local n = s ~= nil and s.nukes[uid]
	if n and n.owner == self.ctx:me() then
		self.nukes += 1
		if self.nukes == 1 then
			self:moment("You launched your first nuclear weapon", false)
		end
	end
end

function MatchLog.on_edict(self, owner: number)
	if owner == self.ctx:me() then
		self.edicts += 1
	end
end

function MatchLog.on_world_event(self, index: number)
	self.events += 1
	local d = UICtx.data("WorldEvents").LIST[index]
	if d ~= nil then
		self:moment(d.name, d.good)
	end
end

function MatchLog.on_era(self, era: number)
	local name = UICtx.data("Eras").NAMES[era]
	if name ~= nil then
		self:moment("The " .. name .. " began", true)
	end
end

function MatchLog.on_eliminated(self, id: number, killer: number)
	self.last_out, self.last_killer = id, killer
	local s, me = self.state, self.ctx:me()
	if s == nil or me == 0 then
		return
	end
	if id == me then
		self.eliminated_at = self:_secs()
		self:moment(if killer > 0 then "Your nation fell to " .. s:owner_name(killer) else "Your nation fell", false)
	elseif killer == me and s.owners[id] ~= nil and s.owners[id].kind ~= Defs.KIND_TRIBE then
		self:moment("You eliminated " .. s:owner_name(id), true)
	end
end

function MatchLog.on_nemesis(self, person: number, nation: number)
	local s, me = self.state, self.ctx:me()
	if s == nil or person ~= me then
		return
	end
	if nation > 0 then
		self.was_nemesis = nation
		self:moment(s:owner_name(nation) .. " became your nemesis", false)
	else
		if self.was_nemesis == self.last_out and self.last_killer == me then
			self.nemeses += 1
			self:moment("You slew your nemesis", true)
		end
		self.was_nemesis = 0
	end
end

--- The match report so far (Data/Progress).
function MatchLog.report(self, won: boolean, extras: { [string]: any }): { [string]: any }
	local s, me = self.state, self.ctx:me()
	local secs = self.eliminated_at or self:_secs()
	local drafts = 0
	if s ~= nil and me ~= 0 then
		for _, row in pairs(s.doctrine[me] or {}) do
			if row[6] >= 1 then
				drafts += 1
			end
		end
	end
	local r = {
		seconds = secs,
		share = if s ~= nil and me ~= 0 then s:land_share(me) else 0,
		won = won,
		drafts = drafts,
		builds = self.builds,
		nukes = self.nukes,
		edicts = self.edicts,
		nemeses = self.nemeses,
		events = self.events,
		landmarks = self.landmarks,
		eliminated = self.eliminated_at ~= nil,
		eliminated_at = self.eliminated_at,
		mode = if s ~= nil then s.mode else nil,
		map_id = if s ~= nil and s.map ~= nil then s.map.id else nil,
	}
	for k, v in extras do
		r[k] = v
	end
	return r
end

return MatchLog
