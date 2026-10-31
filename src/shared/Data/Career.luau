--!strict
-- Career (Conquer the World's own): a commander's rank from the matches they play. Cosmetic only, on
-- purpose: the XP is reported by the client and kept in the player's settings, so it must never buy
-- anything (no Stars, no crates, nothing sold). It is a record, and a name on the title screen.
local Career = {}

--- { name, XP needed, insignia }, ascending. The insignia is plain text: chevrons, then bars, then stars.
Career.RANKS = {
	{ "Recruit", 0, "·" },
	{ "Private", 300, "^" },
	{ "Corporal", 800, "^^" },
	{ "Sergeant", 1600, "^^^" },
	{ "Staff Sergeant", 2800, "^^^^" },
	{ "Ensign", 4500, "|" },
	{ "Lieutenant", 7000, "||" },
	{ "Captain", 10500, "|||" },
	{ "Major", 15000, "||||" },
	{ "Lt. Colonel", 21000, "*" },
	{ "Colonel", 29000, "**" },
	{ "Brigadier", 39000, "***" },
	{ "Commodore", 52000, "****" },
	{ "Warlord", 68000, "*****" },
	{ "Marshal", 88000, "+" },
	{ "Grand Marshal", 112000, "++" },
	{ "Regent", 142000, "+++" },
	{ "Sovereign", 180000, "++++" },
	{ "Emperor", 230000, "+++++" },
	{ "Conqueror", 300000, "#" },
}
--- The settings section it is kept in.
Career.SECTION = "career"
--- A match shorter than this earns nothing (restarting at once is not a career).
Career.MIN_SECONDS = 120
--- Most one match can pay.
Career.MATCH_MAX = 1500
Career.XP_MAX = 10000000

--- XP for a finished match: `seconds` played, the final land `share` (0..1), `won`, doctrines `drafts`.
function Career.match_xp(seconds: number, share: number, won: boolean, drafts: number): number
	local s = if type(seconds) == "number" and seconds == seconds then seconds else 0
	if s < Career.MIN_SECONDS then
		return 0
	end
	local sh = if type(share) == "number" and share == share then math.clamp(share, 0, 1) else 0
	local d = if type(drafts) == "number" and drafts == drafts then math.clamp(math.floor(drafts), 0, 3) else 0
	local xp = math.min(s / 60, 30) * 8 + sh * 1000 + d * 25 + (if won then 400 else 0)
	return math.clamp(math.floor(xp), 0, Career.MATCH_MAX)
end

--- The rank of `xp`: its index, name, the XP into it, the XP it spans (0 in the last), progress 0..1.
function Career.rank(xp: number)
	local x = if type(xp) == "number" and xp == xp then math.clamp(math.floor(xp), 0, Career.XP_MAX) else 0
	local i = 1
	for k, r in Career.RANKS do
		if x >= r[2] then
			i = k
		end
	end
	local nextr = Career.RANKS[i + 1]
	local span = if nextr ~= nil then nextr[2] - Career.RANKS[i][2] else 0
	return {
		index = i,
		name = Career.RANKS[i][1],
		insignia = Career.RANKS[i][3],
		into = x - Career.RANKS[i][2],
		span = span,
		progress = if span > 0 then (x - Career.RANKS[i][2]) / span else 1,
		xp = x,
	}
end

--- A saved career section made safe: numbers only, never negative, never absurd.
function Career.clean(saved: any): { xp: number, matches: number, wins: number }
	local s = if type(saved) == "table" then saved else {}
	local function n(v: any): number
		return if type(v) == "number" and v == v then math.clamp(math.floor(v), 0, Career.XP_MAX) else 0
	end
	return { xp = n(s.xp), matches = n(s.matches), wins = n(s.wins) }
end

--- The career after a match: the new record, the XP paid and whether the rank rose.
function Career.after_match(saved: any, seconds: number, share: number, won: boolean, drafts: number)
	local c = Career.clean(saved)
	local before = Career.rank(c.xp).index
	local gained = Career.match_xp(seconds, share, won, drafts)
	if gained > 0 then
		c.xp = math.min(c.xp + gained, Career.XP_MAX)
		c.matches += 1
		if won then
			c.wins += 1
		end
	end
	return { career = c, gained = gained, promoted = Career.rank(c.xp).index > before, rank = Career.rank(c.xp) }
end

return Career
