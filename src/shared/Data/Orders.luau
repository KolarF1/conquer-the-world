--!strict
-- Field Orders (Conquer the World's own): three daily and three weekly goals, a pure hash of the UTC day, so everyone
-- has the same orders and nothing is stored but how far along the player is. They pay career XP, which is
-- cosmetic (Data/Career), so the client's word is enough.
--
-- A stat is what a match report adds up (Data/Progress.report_stats): matches, wins, minutes, kills, builds, edicts,
-- drafts, nukes, nemeses, landmarks, events, land10, land25, land50, and mode_<key> / win_<key>.
local Doctrines = require("./Doctrines")

local Orders = {}

export type Order = { key: string, text: string, stat: string, goal: number, xp: number }

Orders.DAILY = {
	{ key = "d_play2", text = "Finish 2 matches", stat = "matches", goal = 2, xp = 120 },
	{ key = "d_play3", text = "Finish 3 matches", stat = "matches", goal = 3, xp = 180 },
	{ key = "d_win1", text = "Win a match", stat = "wins", goal = 1, xp = 250 },
	{ key = "d_min20", text = "Play for 20 minutes", stat = "minutes", goal = 20, xp = 120 },
	{ key = "d_min45", text = "Play for 45 minutes", stat = "minutes", goal = 45, xp = 220 },
	{ key = "d_kill3", text = "Eliminate 3 nations", stat = "kills", goal = 3, xp = 150 },
	{ key = "d_kill8", text = "Eliminate 8 nations", stat = "kills", goal = 8, xp = 280 },
	{ key = "d_build10", text = "Put up 10 buildings", stat = "builds", goal = 10, xp = 120 },
	{ key = "d_build25", text = "Put up 25 buildings", stat = "builds", goal = 25, xp = 220 },
	{ key = "d_edict2", text = "Issue 2 edicts", stat = "edicts", goal = 2, xp = 180 },
	{ key = "d_draft4", text = "Draft 4 doctrines", stat = "drafts", goal = 4, xp = 140 },
	{ key = "d_nuke2", text = "Launch 2 nuclear weapons", stat = "nukes", goal = 2, xp = 180 },
	{ key = "d_lm4", text = "Hold 4 landmarks in a match", stat = "landmarks", goal = 4, xp = 160 },
	{ key = "d_land10", text = "Hold 10% of the land", stat = "land10", goal = 1, xp = 120 },
	{ key = "d_land25", text = "Hold 25% of the land", stat = "land25", goal = 1, xp = 220 },
	{ key = "d_nemesis", text = "Slay your nemesis", stat = "nemeses", goal = 1, xp = 260 },
	{ key = "d_blitz", text = "Play a Blitz match", stat = "mode_blitz", goal = 1, xp = 120 },
	{ key = "d_crown", text = "Play King of the Hill", stat = "mode_crown", goal = 1, xp = 120 },
	{ key = "d_total", text = "Play a Total War match", stat = "mode_totalwar", goal = 1, xp = 120 },
	{ key = "d_dead", text = "Play a Deadline match", stat = "mode_deadline", goal = 1, xp = 120 },
	{ key = "d_skirm", text = "Play a Skirmish", stat = "mode_skirmish", goal = 1, xp = 120 },
	{ key = "d_winblitz", text = "Win a Blitz match", stat = "win_blitz", goal = 1, xp = 260 },
	{ key = "d_event3", text = "Live through 3 world events", stat = "events", goal = 3, xp = 120 },
	{ key = "d_mission", text = "Earn 2 stars in the War Room", stat = "mission_stars", goal = 2, xp = 200 },
} :: { Order }

Orders.WEEKLY = {
	{ key = "w_win5", text = "Win 5 matches", stat = "wins", goal = 5, xp = 900 },
	{ key = "w_play15", text = "Finish 15 matches", stat = "matches", goal = 15, xp = 700 },
	{ key = "w_min240", text = "Play for 4 hours", stat = "minutes", goal = 240, xp = 900 },
	{ key = "w_kill40", text = "Eliminate 40 nations", stat = "kills", goal = 40, xp = 800 },
	{ key = "w_build150", text = "Put up 150 buildings", stat = "builds", goal = 150, xp = 700 },
	{ key = "w_edict10", text = "Issue 10 edicts", stat = "edicts", goal = 10, xp = 700 },
	{ key = "w_land50", text = "Hold half the land, 3 times", stat = "land50", goal = 3, xp = 900 },
	{ key = "w_nemesis5", text = "Slay 5 nemeses", stat = "nemeses", goal = 5, xp = 900 },
	{ key = "w_lm30", text = "Hold 30 landmarks across matches", stat = "landmarks", goal = 30, xp = 700 },
	{ key = "w_nuke15", text = "Launch 15 nuclear weapons", stat = "nukes", goal = 15, xp = 700 },
	{ key = "w_missions", text = "Earn 10 stars in the War Room", stat = "mission_stars", goal = 10, xp = 900 },
	{ key = "w_crown3", text = "Win King of the Hill 3 times", stat = "win_crown", goal = 3, xp = 900 },
} :: { Order }

Orders.PER_SET = 3

--- Three distinct indices into a pool, from a hash of `period`. Pure.
local function pick(pool_size: number, period: number, salt: number): { number }
	local h = Doctrines.mix(period, salt, 17)
	local taken, out = {}, {}
	for _ = 1, Orders.PER_SET do
		h = (h * 48271 + 11) % 1000003
		local k = h % pool_size + 1
		while taken[k] do
			k = k % pool_size + 1
		end
		taken[k] = true
		table.insert(out, k)
	end
	return out
end

--- Today's orders ({ Order, Order, Order }); `day`: whole days since the epoch.
function Orders.daily(day: number): { Order }
	local out = {}
	for _, i in pick(#Orders.DAILY, day, 1) do
		table.insert(out, Orders.DAILY[i])
	end
	return out
end

--- This week's.
function Orders.weekly(day: number): { Order }
	local out = {}
	for _, i in pick(#Orders.WEEKLY, day // 7, 2) do
		table.insert(out, Orders.WEEKLY[i])
	end
	return out
end

--- The saved progress made safe and current: a new day clears the daily counts, a new week the weekly.
--- { d = day, a, b, c = daily counts, w = week, x, y, z = weekly counts }.
function Orders.current(saved: any, day: number): { [string]: number }
	local s = if type(saved) == "table" then saved else {}
	local function n(v: any): number
		return if type(v) == "number" and v == v then math.clamp(math.floor(v), 0, 1000000) else 0
	end
	local o = { d = day, w = day // 7, a = 0, b = 0, c = 0, x = 0, y = 0, z = 0 }
	if s.d == day then
		o.a, o.b, o.c = n(s.a), n(s.b), n(s.c)
	end
	if s.w == day // 7 then
		o.x, o.y, o.z = n(s.x), n(s.y), n(s.z)
	end
	return o
end

--- Adds a match's stats (stat -> amount). Returns the new progress, the orders it completed, and the XP they pay.
function Orders.advance(saved: any, stats: { [string]: number }, day: number): ({ [string]: number }, { Order }, number)
	local o = Orders.current(saved, day)
	local done: { Order } = {}
	local xp = 0
	local function step(list: { Order }, keys: { string })
		for i, order in list do
			local k = keys[i]
			local before = o[k]
			local after = before + (stats[order.stat] or 0)
			o[k] = math.min(after, order.goal)
			if before < order.goal and after >= order.goal then
				table.insert(done, order)
				xp += order.xp
			end
		end
	end
	step(Orders.daily(day), { "a", "b", "c" })
	step(Orders.weekly(day), { "x", "y", "z" })
	return o, done, xp
end

return Orders
