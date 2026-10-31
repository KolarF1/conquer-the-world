--!native
-- Rivals (Conquer the World's own; Data/Personas): AI nations with a character. A persona bends the nation's
-- aggression and doctrine picks; a nation that comes for a person says so, and one that keeps coming becomes that
-- person's nemesis, worth a bounty when it falls. Off unless the match config says `rivals = true`. Nothing here
-- draws from the Sim's RNG.
--
-- The wire: `persona_seed` in a snapshot (a client works every persona out from it) and Ev.NEMESIS.
local Defs = require("./Defs")
local Ev = require("./Ev")
local NumberFormat = require("./NumberFormat")
local Personas = require("../Data/Personas")
local Doctrines = require("../Data/Doctrines")

local SimRivals = {}

--- At most one taunt per person in this many ticks.
SimRivals.TAUNT_GAP_TICKS = 450
--- A nation's attacks on a person that make it their nemesis.
SimRivals.NEMESIS_HITS = 3
--- The bounty on a nemesis: this many seconds of the avenger's income.
SimRivals.BOUNTY_S = 90
--- How often a nation with an edict looks at using it, in ticks.
SimRivals.EDICT_LOOK_TICKS = 300

function SimRivals.install(Sim: any)
	local base_started = Sim._on_attack_started

	function Sim._init_rivals(self: any, cfg: { [string]: any }, seed: number)
		self.rivals_on = cfg.rivals == true
		self.persona_seed = seed
		--- person -> tick of the last taunt, and nation * 4096 + person -> attacks so far
		self._taunt_tick = {} :: { [number]: number }
		self._rival_hits = {} :: { [number]: number }
		--- person -> their nemesis (a nation)
		self.o_nemesis = {} :: { [number]: number }
	end

	--- After the AI's setup: the personas' temper.
	function Sim._rivals_setup(self: any)
		if not self.rivals_on then
			return
		end
		for id = 1, self.owner_total do
			if self.o_kind[id] == Defs.KIND_NATION then
				self.ai.aggression[id] *= Personas.of(self.persona_seed, id).aggr
			end
		end
	end

	function Sim._on_attack_started(self: any, a: any)
		base_started(self, a)
		if not self.rivals_on then
			return
		end
		local from, to = a.attacker, a.target
		if to == nil or to <= 0 or self.o_kind[from] ~= Defs.KIND_NATION or not self:is_human(to) or self.o_bot[to] == 1 then
			return
		end
		local k = from * 4096 + to
		local n = (self._rival_hits[k] or 0) + 1
		self._rival_hits[k] = n
		if self.tick >= (self._taunt_tick[to] or -100000) + SimRivals.TAUNT_GAP_TICKS then
			self._taunt_tick[to] = self.tick
			local p = Personas.of(self.persona_seed, from)
			self:msg(to, Defs.MSG_INFO, string.format("%s: %s", self.o_name[from], Personas.taunt(p, self.persona_seed, from, n)))
		end
		if n >= SimRivals.NEMESIS_HITS and self.o_nemesis[to] == nil then
			self.o_nemesis[to] = from
			self:ev({ Ev.NEMESIS, to, from })
			self:msg(to, Defs.MSG_ALERT, string.format("%s is now your nemesis. Bring it down for a bounty.", self.o_name[from]))
		end
	end

	--- After an owner fell: a person who brought down their nemesis collects.
	function Sim._rivals_eliminated(self: any, id: number, killer: number)
		if not self.rivals_on then
			return
		end
		for person, nemesis in self.o_nemesis do
			if nemesis == id then
				self.o_nemesis[person] = 0
				self:ev({ Ev.NEMESIS, person, 0 })
				if person == killer and self.o_alive[person] == 1 then
					local bounty = self.o_income[person] * SimRivals.BOUNTY_S
					self.o_gold[person] += bounty
					self:msg(person, Defs.MSG_GOOD, string.format("Nemesis slain: +%s gold bounty", NumberFormat.render_number(math.floor(bounty))))
				end
			end
		end
	end

	--- Nations use the edicts their doctrines grant.
	function Sim._rivals_tick(self: any)
		if not self.doctrines_on or self.tick % SimRivals.EDICT_LOOK_TICKS ~= 0 then
			return
		end
		for id = 1, self.owner_total do
			if self.o_alive[id] == 1 and self.o_kind[id] == Defs.KIND_NATION then
				local keys = self.o_doc[id]
				if keys ~= nil and keys[3] ~= nil then
					local d = Doctrines.BY_KEY[keys[3]]
					if d ~= nil and d.edict ~= nil then
						self:_edict_fire(id, d.edict)
					end
				end
			end
		end
	end

	--- Snapshot rows of the nemeses.
	function Sim._nemesis_rows(self: any): { { number } }?
		if not self.rivals_on then
			return nil
		end
		local rows = {}
		for id = 1, self.owner_total do
			local n = self.o_nemesis[id]
			if n ~= nil then
				table.insert(rows, { id, n })
			end
		end
		return rows
	end
end

return SimRivals
