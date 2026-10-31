--!strict
-- Medals (Conquer the World's own): the commander's long record. A medal is earned once, when a lifetime total or a
-- best-of-one-match reaches its mark; it pays XP and a few grant a title. Kept as a string of 0s and 1s in the career
-- settings section, in LIST order: APPEND ONLY, a saved string reads by position.
local Medals = {}

export type Medal = { key: string, name: string, line: string, stat: string, n: number, xp: number, title: string? }

--- "Win 1 matches" reads "Win a match".
local function once(text: string, n: number): string
	if n ~= 1 then
		return text
	end
	for _, pair in { { "1 matches", "a match" }, { "1 nuclear weapons", "a nuclear weapon" }, { "1 edicts", "an edict" }, { "1 nemeses", "a nemesis" } } do
		local a, b = string.find(text, pair[1], 1, true)
		if a ~= nil then
			return string.sub(text, 1, a - 1) .. pair[2] .. string.sub(text, b + 1)
		end
	end
	return text
end

local function ladder(out: { Medal }, stat: string, line: string, steps: { { any } })
	for i, s in steps do
		table.insert(out, {
			key = stat .. tostring(i),
			name = s[1],
			line = once(string.format(line, s[2]), s[2]),
			stat = stat,
			n = s[2],
			xp = 100 * i,
			title = s[3],
		})
	end
end

local list: { Medal } = {}
ladder(list, "wins", "Win %d matches", {
	{ "First Blood", 1 },
	{ "Veteran", 10 },
	{ "Warlord", 50, "the Warlord" },
	{ "Undefeated", 200, "the Undefeated" },
})
ladder(list, "matches", "Finish %d matches", {
	{ "Enlisted", 1 },
	{ "Regular", 10 },
	{ "Old Guard", 50 },
	{ "Lifer", 250, "the Tireless" },
})
ladder(list, "kills", "Eliminate %d nations", {
	{ "Giant Killer", 5 },
	{ "Scourge", 50 },
	{ "Destroyer of Nations", 250, "the Destroyer" },
	{ "Extinction", 1000, "Ender of Nations" },
})
ladder(list, "builds", "Put up %d buildings", {
	{ "Foundation", 10 },
	{ "Master Builder", 100 },
	{ "Architect", 500, "the Architect" },
	{ "Empire of Stone", 2000 },
})
ladder(list, "nukes", "Launch %d nuclear weapons", {
	{ "Fission", 1 },
	{ "Fallout", 25 },
	{ "Atomic Age", 100, "the Radiant" },
})
ladder(list, "edicts", "Issue %d edicts", {
	{ "By Decree", 1 },
	{ "Lawgiver", 25 },
	{ "Absolute Rule", 100, "the Absolute" },
})
ladder(list, "drafts", "Draft %d doctrines", {
	{ "Student of War", 3 },
	{ "Strategist", 30 },
	{ "Doctrinaire", 150 },
})
ladder(list, "minutes", "Play for %d minutes", {
	{ "One Hour War", 60 },
	{ "Ten Hour War", 600 },
	{ "Fifty Hour War", 3000, "the Everlasting" },
})
ladder(list, "best_land", "Hold %d%% of the land in a match", {
	{ "Foothold", 10 },
	{ "Great Power", 25 },
	{ "Superpower", 50 },
	{ "World Conqueror", 80, "Conqueror of Worlds" },
})
ladder(list, "nemeses", "Slay %d nemeses", {
	{ "Vengeance", 1 },
	{ "Grudge Keeper", 5 },
	{ "Nemesis of Nemeses", 25, "the Unforgiving" },
})
ladder(list, "best_lm", "Hold %d landmarks at once", {
	{ "Sightseer", 3 },
	{ "Curator", 6 },
	{ "Keeper of Wonders", 10, "Keeper of Wonders" },
})
ladder(list, "stars", "Earn %d stars in the War Room", {
	{ "Cadet", 10 },
	{ "Staff Officer", 30 },
	{ "Grand Strategist", 60 },
	{ "Perfect Campaign", 72, "the Flawless" },
})
ladder(list, "win_blitz", "Win %d Blitz matches", { { "Lightning", 5 } })
ladder(list, "win_crown", "Win %d King of the Hill matches", { { "Crowned", 5, "the Crowned" } })
ladder(list, "win_deadline", "Win %d Deadline matches", { { "Beat the Clock", 5 } })
ladder(list, "win_skirmish", "Win %d Skirmishes", { { "Duelist", 5 } })
ladder(list, "win_totalwar", "Win %d Total War matches", { { "Alone Against All", 5, "the Lone Wolf" } })
ladder(list, "win_hard", "Win %d matches on Brutal", { { "Brutal", 1 }, { "Merciless", 10, "the Merciless" } })
ladder(list, "win_invented", "Win %d matches on invented maps", { { "Explorer", 3 } })

Medals.LIST = list

--- The bits of a saved string, padded to LIST's length. `true` per earned medal.
function Medals.earned(bits: any): { boolean }
	local s = if type(bits) == "string" then bits else ""
	local out = {}
	for i = 1, #Medals.LIST do
		out[i] = string.sub(s, i, i) == "1"
	end
	return out
end

--- Saved string of a bit list.
function Medals.encode(flags: { boolean }): string
	local parts = table.create(#Medals.LIST, "0")
	for i = 1, #Medals.LIST do
		if flags[i] then
			parts[i] = "1"
		end
	end
	return table.concat(parts)
end

--- The medals `totals` now reaches that `bits` lacks. Returns the new string, those medals, and the XP they pay.
function Medals.award(bits: any, totals: { [string]: number }): (string, { Medal }, number)
	local flags = Medals.earned(bits)
	local fresh: { Medal } = {}
	local xp = 0
	for i, m in Medals.LIST do
		if not flags[i] and (totals[m.stat] or 0) >= m.n then
			flags[i] = true
			table.insert(fresh, m)
			xp += m.xp
		end
	end
	return Medals.encode(flags), fresh, xp
end

return Medals
