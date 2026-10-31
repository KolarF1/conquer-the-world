--!strict
-- The War Room (Conquer the World's own): a campaign of 24 missions in 4 theatres. A mission is a solo match with a
-- map, a difficulty, a game mode and extra match-config keys, and three objectives, each worth a star. A mission opens
-- once the one before it has a star; a theatre opens at a number of stars. Kept as a string of digits (the best stars
-- per mission, LIST order, APPEND ONLY) in the career settings section. Cosmetic: stars pay career XP only.
--
-- An objective reads a match report (Data/Progress): { win = true }, { peak = 0.3 } (share of land at best),
-- { kills = 3 }, { within = 900 } (won in at most that many seconds), { survive = 600 } (still standing that many
-- seconds in), { landmarks = 4 } (held at once), { builds = 10 }, { edicts = 1 }, { nemeses = 1 }, { no_nukes = true }.
local Missions = {}

export type Objective = { [string]: any }
export type Mission = {
	key: string,
	theatre: number,
	name: string,
	brief: string,
	map: string,
	difficulty: number,
	mode: string?,
	config: { [string]: any }?,
	tribes: number?,
	objectives: { Objective },
}

Missions.THEATRES = {
	{ name = "First Command", line = "Learn the trade on friendly ground.", stars = 0 },
	{ name = "The Long War", line = "Longer fronts, sharper neighbours.", stars = 8 },
	{ name = "Strange Shores", line = "Worlds that do not exist, and wars that should not.", stars = 22 },
	{ name = "The Reckoning", line = "Everything you have learned, on Brutal.", stars = 36 },
}

local S = { nation_limit = 12 }
local function small(n: number): { [string]: any }
	return { nation_limit = n }
end

--- Short text of an objective, for the briefing.
function Missions.objective_text(o: Objective): string
	if o.win then
		return "Win the match"
	elseif o.peak then
		return string.format("Hold %d%% of the land", math.floor(o.peak * 100 + 0.5))
	elseif o.kills then
		return string.format("Eliminate %d nations", o.kills)
	elseif o.within then
		return string.format("Win within %d minutes", o.within // 60)
	elseif o.survive then
		return string.format("Stand for %d minutes", o.survive // 60)
	elseif o.landmarks then
		return string.format("Hold %d landmarks at once", o.landmarks)
	elseif o.builds then
		return string.format("Put up %d buildings", o.builds)
	elseif o.edicts then
		return string.format("Issue %d edict%s", o.edicts, if o.edicts == 1 then "" else "s")
	elseif o.nemeses then
		return "Slay your nemesis"
	elseif o.no_nukes then
		return "Win without a nuclear weapon"
	end
	return "?"
end

Missions.LIST = {
	-- I. First Command
	{ key = "landfall", theatre = 1, name = "Landfall", brief = "A quiet corner of South America and a dozen rivals. Plant a flag and grow.", map = "southamerica", difficulty = 0, mode = "skirmish", config = { win_share = 0.6 }, objectives = { { peak = 0.15 }, { win = true }, { within = 1200 } } },
	{ key = "breadbasket", theatre = 1, name = "Breadbasket", brief = "Europe's farmland feeds whoever holds it. Take the landmarks and the rest follows.", map = "europe", difficulty = 0, config = { nation_limit = 16, win_share = 0.6 }, objectives = { { landmarks = 2 }, { landmarks = 4 }, { win = true } } },
	{ key = "builders", theatre = 1, name = "Builders' Peace", brief = "Your neighbours are slow to anger. Spend the calm wisely.", map = "africa", difficulty = 0, config = { nation_limit = 14, win_share = 0.6 }, objectives = { { builds = 8 }, { builds = 20 }, { win = true } } },
	{ key = "firstwar", theatre = 1, name = "First War", brief = "North America, and not enough room on it. Bring down your rivals one at a time.", map = "northamerica", difficulty = 0, config = small(14), objectives = { { kills = 1 }, { kills = 3 }, { peak = 0.4 } } },
	{ key = "racetogold", theatre = 1, name = "Twenty Minutes", brief = "The clock is the enemy. Most land at the bell wins.", map = "asia", difficulty = 0, mode = "deadline", config = small(16), objectives = { { survive = 600 }, { peak = 0.2 }, { win = true } } },
	{ key = "hillfort", theatre = 1, name = "The Hill Fort", brief = "One hill. It opens at five minutes; hold it for ten, in all.", map = "europe", difficulty = 0, mode = "crown", config = small(12), objectives = { { survive = 600 }, { win = true }, { within = 1320 } } },
	-- II. The Long War
	{ key = "continent", theatre = 2, name = "A Continent Divided", brief = "All of Africa, every nation at once. Finish it.", map = "africa", difficulty = 1, objectives = { { peak = 0.2 }, { peak = 0.4 }, { win = true } } },
	{ key = "greatgame", theatre = 2, name = "The Great Game", brief = "Asia's crowded heart. Make friends, then stop being one.", map = "asia", difficulty = 1, config = small(30), objectives = { { kills = 3 }, { kills = 8 }, { win = true } } },
	{ key = "blitzkrieg", theatre = 2, name = "Lightning Season", brief = "Eras fly by and gold floods in. Hit first.", map = "europe", difficulty = 1, mode = "blitz", objectives = { { peak = 0.25 }, { win = true }, { within = 720 } } },
	{ key = "isolation", theatre = 2, name = "Splendid Isolation", brief = "Nobody signs anything here. Stand alone in Total War.", map = "northamerica", difficulty = 1, mode = "totalwar", config = small(20), objectives = { { survive = 900 }, { peak = 0.3 }, { win = true } } },
	{ key = "vendetta", theatre = 2, name = "Vendetta", brief = "Somebody here will come for you three times. Make it their last.", map = "southamerica", difficulty = 1, config = small(18), objectives = { { kills = 2 }, { nemeses = 1 }, { win = true } } },
	{ key = "worldstage", theatre = 2, name = "World Stage", brief = "The whole Earth, and everyone on it.", map = "world", difficulty = 1, objectives = { { peak = 0.1 }, { peak = 0.25 }, { win = true } } },
	-- III. Strange Shores
	{ key = "primeval", theatre = 3, name = "Primeval", brief = "One land under one sky. Nowhere to hide on Primeval.", map = "primeval", difficulty = 1, config = small(24), objectives = { { peak = 0.2 }, { landmarks = 5 }, { win = true } } },
	{ key = "isles", theatre = 3, name = "Thousand Isles", brief = "Land is scarce and the sea is everywhere. Boats win this one.", map = "thousandisles", difficulty = 1, config = small(20), objectives = { { peak = 0.15 }, { peak = 0.35 }, { win = true } } },
	{ key = "bridge", theatre = 3, name = "The Bridge", brief = "Twin Realms, one narrow neck of land. Whoever holds it holds both.", map = "twinrealms", difficulty = 1, config = small(20), objectives = { { kills = 3 }, { peak = 0.35 }, { win = true } } },
	{ key = "inlandsea", theatre = 3, name = "Mare Nostrum", brief = "Everybody touches the inland sea. Own the trade, own the world.", map = "marenostrum", difficulty = 1, config = small(24), objectives = { { builds = 15 }, { peak = 0.3 }, { win = true } } },
	{ key = "horns", theatre = 3, name = "The Horns", brief = "King of the Hill on The Crescent, with the Crown in the bend.", map = "crescent", difficulty = 1, mode = "crown", config = small(18), objectives = { { survive = 600 }, { win = true }, { within = 1500 } } },
	{ key = "passes", theatre = 3, name = "The Three Passes", brief = "A wall of mountains splits The Spine. Three ways through.", map = "spine", difficulty = 1, config = small(24), objectives = { { peak = 0.2 }, { kills = 5 }, { win = true } } },
	-- IV. The Reckoning
	{ key = "brutalstart", theatre = 4, name = "No Quarter", brief = "Brutal nations, Skirmish rules. See how far you have come.", map = "europe", difficulty = 2, mode = "skirmish", config = { win_share = 0.6 }, objectives = { { survive = 600 }, { peak = 0.25 }, { win = true } } },
	{ key = "lastalliance", theatre = 4, name = "Against Everyone", brief = "Total War on Brutal. Nobody will help you and nobody will stop.", map = "asia", difficulty = 2, mode = "totalwar", config = small(24), objectives = { { survive = 900 }, { kills = 5 }, { win = true } } },
	{ key = "cleanhands", theatre = 4, name = "Clean Hands", brief = "Win a hard war without touching the bomb.", map = "africa", difficulty = 2, config = small(24), objectives = { { peak = 0.3 }, { win = true }, { no_nukes = true } } },
	{ key = "crownbrutal", theatre = 4, name = "Heavy Is the Head", brief = "King of the Hill on Brutal. They will all come for you.", map = "world", difficulty = 2, mode = "crown", config = small(30), objectives = { { survive = 600 }, { win = true }, { within = 1800 } } },
	{ key = "stormfront", theatre = 4, name = "Stormfront", brief = "Blitz on Brutal. You have twelve minutes to matter.", map = "spine", difficulty = 2, mode = "blitz", objectives = { { peak = 0.2 }, { win = true }, { within = 780 } } },
	{ key = "finalwar", theatre = 4, name = "The Last War", brief = "The whole Earth, on Brutal, every nation. This is what it was all for.", map = "world", difficulty = 2, objectives = { { peak = 0.25 }, { edicts = 1 }, { win = true } } },
} :: { Mission }

Missions.INDEX = {} :: { [string]: number }
for i, m in Missions.LIST do
	Missions.INDEX[m.key] = i
end

Missions.MAX_STARS = #Missions.LIST * 3

--- Best stars per mission, from a saved string.
function Missions.best(saved: any): { number }
	local s = if type(saved) == "string" then saved else ""
	local out = {}
	for i = 1, #Missions.LIST do
		out[i] = math.clamp(tonumber(string.sub(s, i, i)) or 0, 0, 3)
	end
	return out
end

function Missions.encode(best: { number }): string
	local parts = {}
	for i = 1, #Missions.LIST do
		parts[i] = tostring(best[i] or 0)
	end
	return table.concat(parts)
end

function Missions.total_stars(best: { number }): number
	local n = 0
	for _, v in best do
		n += v
	end
	return n
end

--- True when mission `i` may be played: its theatre's stars are met, and the mission before it in its theatre has
--- a star (the first of a theatre needs only the stars).
function Missions.unlocked(i: number, best: { number }): boolean
	local m = Missions.LIST[i]
	if m == nil or Missions.total_stars(best) < Missions.THEATRES[m.theatre].stars then
		return false
	end
	local prev = Missions.LIST[i - 1]
	return prev == nil or prev.theatre ~= m.theatre or (best[i - 1] or 0) >= 1
end

--- Whether a report meets one objective.
function Missions.met(o: Objective, r: { [string]: any }): boolean
	if o.win then
		return r.won == true
	elseif o.peak then
		return (r.peak or 0) >= o.peak
	elseif o.kills then
		return (r.kills or 0) >= o.kills
	elseif o.within then
		return r.won == true and (r.seconds or math.huge) <= o.within
	elseif o.survive then
		-- (winning sooner counts: nobody should lose a star for ending the war early)
		return r.won == true or ((r.seconds or 0) >= o.survive and (r.eliminated ~= true or (r.eliminated_at or 0) >= o.survive))
	elseif o.landmarks then
		return (r.landmarks or 0) >= o.landmarks
	elseif o.builds then
		return (r.builds or 0) >= o.builds
	elseif o.edicts then
		return (r.edicts or 0) >= o.edicts
	elseif o.nemeses then
		return (r.nemeses or 0) >= o.nemeses
	elseif o.no_nukes then
		return r.won == true and (r.nukes or 0) == 0
	end
	return false
end

--- Stars a match earned on mission `m`: one per objective met.
function Missions.stars(m: Mission, r: { [string]: any }): number
	local n = 0
	for _, o in m.objectives do
		if Missions.met(o, r) then
			n += 1
		end
	end
	return n
end

return Missions
