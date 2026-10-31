--!strict
-- World events (Conquer the World's own): every few minutes something happens to the whole world for a
-- minute or two: a gold rush, a plague, a market crash, or an uprising in the land of whoever is ahead. A
-- match's schedule is a pure hash of its seed and its era table, so the Sim's random sequence is untouched and
-- every copy agrees. Levers multiply (`rebate` adds); `leader = true`: it falls only on the biggest nation at the
-- moment it begins, which keeps a runaway match interesting.
local Doctrines = require("./Doctrines")

local WorldEvents = {}

export type Event = {
	key: string,
	name: string,
	line: string,
	secs: number,
	good: boolean,
	leader: boolean?,
	gold: number?,
	trade: number?,
	atk: number?,
	def: number?,
	regen: number?,
	claim: number?,
	rebate: number?,
	lm: number?,
}

WorldEvents.LIST = {
	{ key = "goldrush", name = "Gold Rush", line = "+50% gold everywhere for 90 seconds", secs = 90, good = true, gold = 1.5 },
	{ key = "harvest", name = "Bumper Harvest", line = "+50% troop regrowth for 90 seconds", secs = 90, good = true, regen = 1.5 },
	{ key = "tradewinds", name = "Trade Winds", line = "Double trade gold for 2 minutes", secs = 120, good = true, trade = 2.0 },
	{ key = "warfever", name = "War Fever", line = "+25% attack for everyone for a minute", secs = 60, good = true, atk = 1.25 },
	{ key = "winter", name = "Hard Winter", line = "+30% defence for everyone for 90 seconds", secs = 90, good = true, def = 1.3 },
	{ key = "landboom", name = "Land Boom", line = "Open land costs half for a minute", secs = 60, good = true, claim = 2.0 },
	{ key = "buildboom", name = "Building Boom", line = "25% back on every building for 90 seconds", secs = 90, good = true, rebate = 0.25 },
	{ key = "pilgrims", name = "Pilgrim Season", line = "Landmarks pay double for 90 seconds", secs = 90, good = true, lm = 2.0 },
	{ key = "plague", name = "Plague", line = "-40% troop regrowth everywhere for a minute", secs = 60, good = false, regen = 0.6 },
	{ key = "crash", name = "Market Crash", line = "-30% gold everywhere for a minute", secs = 60, good = false, gold = 0.7 },
	{ key = "uprising", name = "Uprising", line = "-50% troop regrowth for a minute", secs = 60, good = false, leader = true, regen = 0.5 },
	{ key = "taxrevolt", name = "Tax Revolt", line = "-40% gold for a minute", secs = 60, good = false, leader = true, gold = 0.6 },
} :: { Event }

--- How many events a match can have (more than any match lasts).
WorldEvents.MAX = 16
--- Spread of a start around its slot, in ticks.
WorldEvents.JITTER = 300

--- The schedule of a match: { { since_play_tick, index }, ... }, rising, starting in the Expansion. Pure. Never
--- the same event twice running.
function WorldEvents.schedule(seed: number, eras: { number }): { { number } }
	local first = eras[2]
	local period = math.max(math.floor(eras[#eras] / 3.2), 600)
	local out = {}
	local prev = 0
	for k = 1, WorldEvents.MAX do
		local h = Doctrines.mix(seed, k, 53)
		local idx = h % #WorldEvents.LIST + 1
		if idx == prev then
			idx = idx % #WorldEvents.LIST + 1
		end
		prev = idx
		local jitter = (h // 7) % math.min(WorldEvents.JITTER, period // 3)
		table.insert(out, { first + period // 4 + (k - 1) * period + jitter, idx })
	end
	return out
end

return WorldEvents
