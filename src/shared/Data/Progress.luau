--!strict
-- A commander's record (Conquer the World's own): what one finished match does to the career: match XP (Data/Career),
-- Field Orders (Data/Orders), Medals (Data/Medals), War Room stars (Data/Missions) and the Season track (Data/Season).
-- Pure, kept in one settings section. The client reports all of it, so all of it is cosmetic: nothing here buys
-- anything, and nothing reads it but the player's own screens.
--
--   Progress.clean(saved)                     the saved section made safe
--   Progress.after_match(saved, report, day)  -> { career, gained, lines, medals, orders, stars, promoted, rank, ... }
--
-- A report: { seconds, share (final), peak (best), won, drafts, kills, builds, nukes, edicts, nemeses, landmarks (most
-- held at once), events, mode, map_id, difficulty, eliminated, eliminated_at, mission (a Missions key) }.
local Career = require("./Career")
local Orders = require("./Orders")
local Medals = require("./Medals")
local Missions = require("./Missions")
local Season = require("./Season")
local MapList = require("./MapList")

local Progress = {}

--- Lifetime totals in the section's nested `t`.
Progress.TOTALS = {
	"matches", "wins", "minutes", "kills", "builds", "nukes", "edicts", "drafts", "nemeses", "events", "best_land", "best_lm", "stars",
	"win_blitz", "win_crown", "win_deadline", "win_skirmish", "win_totalwar", "win_classic", "win_hard", "win_invented",
}

local function n(v: any): number
	return if type(v) == "number" and v == v then math.clamp(math.floor(v), 0, Career.XP_MAX) else 0
end

--- The saved section made safe: only what belongs here, numbers bounded, strings kept as they are read by position.
function Progress.clean(saved: any): { [string]: any }
	local s = if type(saved) == "table" then saved else {}
	local c = Career.clean(s)
	local out: { [string]: any } = { xp = c.xp, matches = c.matches, wins = c.wins }
	out.medals = if type(s.medals) == "string" then string.sub(s.medals, 1, 64) else ""
	out.missions = if type(s.missions) == "string" then string.sub(s.missions, 1, 64) else ""
	out.tbits = if type(s.tbits) == "string" then string.sub(s.tbits, 1, 64) else ""
	out.title = if type(s.title) == "string" then string.sub(s.title, 1, 40) else ""
	out.season = n(s.season)
	out.season_xp = n(s.season_xp)
	local t = {}
	local st = if type(s.t) == "table" then s.t else {}
	for _, k in Progress.TOTALS do
		t[k] = n(st[k])
	end
	out.t = t
	local o = if type(s.o) == "table" then s.o else {}
	local oo = {}
	for _, k in { "d", "w", "a", "b", "c", "x", "y", "z" } do
		oo[k] = n(o[k])
	end
	out.o = oo
	return out
end

--- What a report adds to stat counters (Orders and the lifetime totals read the same names).
function Progress.report_stats(r: { [string]: any }): { [string]: number }
	local mode = if type(r.mode) == "string" then r.mode else "classic"
	local won = r.won == true
	local peak = n((r.peak or 0) * 100)
	local row = if type(r.map_id) == "string" then MapList.get(r.map_id) else nil
	local invented = row ~= nil and table.find(row.categories, "invented") ~= nil
	local stats: { [string]: number } = {
		matches = 1,
		wins = if won then 1 else 0,
		minutes = (r.seconds or 0) // 60,
		kills = n(r.kills),
		builds = n(r.builds),
		nukes = n(r.nukes),
		edicts = n(r.edicts),
		drafts = n(r.drafts),
		nemeses = n(r.nemeses),
		events = n(r.events),
		landmarks = n(r.landmarks),
		land10 = if peak >= 10 then 1 else 0,
		land25 = if peak >= 25 then 1 else 0,
		land50 = if peak >= 50 then 1 else 0,
		mission_stars = 0,
	}
	stats["mode_" .. mode] = 1
	if won then
		stats["win_" .. mode] = 1
		if r.difficulty == 2 then
			stats.win_hard = 1
		end
		if invented then
			stats.win_invented = 1
		end
	end
	return stats
end

--- A finished match. Nothing happens for one too short to count.
function Progress.after_match(saved: any, r: { [string]: any }, day: number)
	local c = Progress.clean(saved)
	local rank_before = Career.rank(c.xp).index
	local match_xp = Career.match_xp(r.seconds or 0, r.peak or r.share or 0, r.won == true, r.drafts or 0)
	local out: { [string]: any } = { career = c, gained = 0, lines = {}, medals = {}, orders = {}, stars = 0, promoted = false, rank = Career.rank(c.xp), new_titles = {} }
	if match_xp <= 0 then
		return out
	end
	local lines = out.lines
	table.insert(lines, { "Match", match_xp })
	local stats = Progress.report_stats(r)
	-- the War Room
	local mission_xp = 0
	if type(r.mission) == "string" then
		local i = Missions.INDEX[r.mission]
		if i ~= nil then
			local best = Missions.best(c.missions)
			local got = Missions.stars(Missions.LIST[i], r)
			out.stars = got
			out.mission_stars_new = math.max(got - best[i], 0)
			if got > best[i] then
				mission_xp = (got - best[i]) * 150
				best[i] = got
				c.missions = Missions.encode(best)
				table.insert(lines, { "War Room", mission_xp })
			end
			stats.mission_stars = out.mission_stars_new
			c.t.stars = Missions.total_stars(best)
		end
	end
	-- totals
	local t = c.t
	for _, k in Progress.TOTALS do
		if k ~= "best_land" and k ~= "best_lm" and k ~= "stars" then
			t[k] = math.min(t[k] + (stats[k] or 0), Career.XP_MAX)
		end
	end
	t.best_land = math.max(t.best_land, n((r.peak or 0) * 100))
	t.best_lm = math.max(t.best_lm, n(r.landmarks))
	c.matches += 1
	if r.won == true then
		c.wins += 1
	end
	-- orders and medals
	local o, done, order_xp = Orders.advance(c.o, stats, day)
	c.o = o
	out.orders = done
	if order_xp > 0 then
		table.insert(lines, { "Field Orders", order_xp })
	end
	local bits, fresh, medal_xp = Medals.award(c.medals, t)
	c.medals = bits
	out.medals = fresh
	if medal_xp > 0 then
		table.insert(lines, { "Medals", medal_xp })
	end
	for _, m in fresh do
		if m.title ~= nil then
			table.insert(out.new_titles, m.title)
		end
	end
	local gained = match_xp + mission_xp + order_xp + medal_xp
	c.xp = math.min(c.xp + gained, Career.XP_MAX)
	-- the season
	local sea = Season.current(day)
	if c.season ~= sea.number then
		c.season = sea.number
		c.season_xp = 0
	end
	local level_before = Season.level(c.season_xp).level
	c.season_xp += gained
	local lv = Season.level(c.season_xp).level
	out.season_level = lv
	out.season_up = lv > level_before
	if out.season_up then
		c.tbits = Season.grant(c.tbits, sea.theme_index, lv)
		for level = level_before + 1, lv do
			local title = Season.title_at(sea.theme, level)
			if title ~= nil then
				table.insert(out.new_titles, title)
			end
		end
	end
	out.gained = gained
	out.rank = Career.rank(c.xp)
	out.promoted = out.rank.index > rank_before
	return out
end

--- Every title a career has: medals' and seasons'.
function Progress.titles(saved: any): { string }
	local c = Progress.clean(saved)
	local out = {}
	for i, on in Medals.earned(c.medals) do
		local title = Medals.LIST[i].title
		if on and title ~= nil then
			table.insert(out, title)
		end
	end
	for _, title in Season.titles_of(c.tbits) do
		table.insert(out, title)
	end
	return out
end

--- Whole UTC days since the epoch, from os.time() seconds.
function Progress.day_of(seconds: number): number
	return math.floor(seconds / 86400)
end

return Progress
