--!strict
-- Personas (Conquer the World's own): every AI nation has a character, a pure hash of the match seed and its id,
-- so the Sim's random sequence is untouched and every client can name it. A persona bends how hard the nation
-- picks fights (`aggr`, on top of the AI's own aggression), which doctrines it prefers (`likes`: lever -> weight)
-- and what it says when it comes for a person.
local Doctrines = require("./Doctrines")

local Personas = {}

export type Persona = { key: string, name: string, line: string, aggr: number, likes: { [string]: number }, taunts: { string } }

Personas.LIST = {
	{
		key = "conqueror",
		name = "Conqueror",
		line = "Wants all of it. Attacks early and often.",
		aggr = 1.25,
		likes = { atk = 3, cap = 2, conq = 2 },
		taunts = { "Your borders are a suggestion.", "Kneel, and keep your capital.", "I have taken better land than yours.", "A map should have one colour." },
	},
	{
		key = "merchant",
		name = "Merchant Prince",
		line = "Would rather be rich. Slow to war, deep pockets.",
		aggr = 0.85,
		likes = { gold = 3, trade = 3, rebate = 2 },
		taunts = { "Nothing personal. Your ports are simply worth more to me.", "Consider this a hostile acquisition.", "I can afford this war. Can you?", "Everything has a price. Today, it is your coast." },
	},
	{
		key = "warden",
		name = "Warden",
		line = "Fortifies, waits, and rarely forgives.",
		aggr = 0.75,
		likes = { def = 3, regen = 2, cap = 2 },
		taunts = { "You were warned.", "I only wanted the border straight.", "My walls have grown. So has my patience, and it has ended.", "Peace was on offer. Remember that." },
	},
	{
		key = "schemer",
		name = "Schemer",
		line = "Hunts the weak and the wealthy, and holds landmarks.",
		aggr = 1.0,
		likes = { conq = 3, lm = 3, claim = 1 },
		taunts = { "I do so admire what you have built. May I?", "Your allies told me where to strike.", "You looked busy. How unfortunate.", "This was decided some time ago." },
	},
	{
		key = "zealot",
		name = "Zealot",
		line = "Throws army after army. Never tires.",
		aggr = 1.35,
		likes = { regen = 3, atk = 2, claim = 1 },
		taunts = { "We do not run out of soldiers.", "Your land was promised to us.", "Every one of ours you kill, two arrive.", "Pray faster." },
	},
} :: { Persona }

--- A nation's persona in a match with `seed`.
function Personas.of(seed: number, id: number): Persona
	return Personas.LIST[Doctrines.mix(seed, id, 31) % #Personas.LIST + 1]
end

--- The slot (1..#offer) a persona takes from `offer` (indices into Doctrines.LIST): the doctrine it likes most;
--- the first on a tie. Pure.
function Personas.pick(p: Persona, offer: { number }): number
	local best, best_v = 1, -math.huge
	for slot, idx in offer do
		local d: any = Doctrines.LIST[idx]
		local v = 0.0
		for lever, weight in p.likes do
			v += (d[lever] or 0) * weight
		end
		if v > best_v then
			best, best_v = slot, v
		end
	end
	return best
end

--- The line it says on coming for a person, `n`: a running count.
function Personas.taunt(p: Persona, seed: number, id: number, n: number): string
	return p.taunts[Doctrines.mix(seed, id, 43 + n) % #p.taunts + 1]
end

return Personas
