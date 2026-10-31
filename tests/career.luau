--!nocheck
-- Career (Data/Career): the rank ladder and the XP a match pays. Cosmetic only; the test also pins that.
-- Run: lune run tests/career.luau
require("./prelude")
local Career = require("../src/shared/Data/Career")

local fails = 0
local function expect(c: any, w: string)
	if c then
		print("  ok   " .. w)
	else
		fails += 1
		print("FAIL " .. w)
	end
end

local last = -1
local ascending = true
for _, r in Career.RANKS do
	ascending = ascending and r[2] > last
	last = r[2]
end
expect(ascending and Career.RANKS[1][2] == 0, "ranks ascend from 0 XP")
expect(Career.rank(0).name == "Recruit" and Career.rank(299).name == "Recruit" and Career.rank(300).name == "Private", "the rank at its threshold")
expect(Career.rank(300000).name == "Conqueror" and Career.rank(99999999).name == "Conqueror" and Career.rank(300000).span == 0 and Career.rank(300000).progress == 1, "the last rank has no next")
expect(math.abs(Career.rank(425).progress - 0.25) < 1e-9, "progress inside a rank")
expect(Career.rank(-5).name == "Recruit" and Career.rank(0 / 0).name == "Recruit" and Career.rank("x").name == "Recruit", "junk is a Recruit")

expect(Career.match_xp(60, 0.5, true, 3) == 0, "a match under two minutes pays nothing")
expect(Career.match_xp(600, 0.05, false, 0) == 80 + 50, "ten minutes and 5% of the land")
expect(Career.match_xp(600, 0.8, true, 3) == 80 + 800 + 75 + 400, "a win with 80% and three drafts")
expect(Career.match_xp(100000, 1, true, 99) == Career.MATCH_MAX, "one match never pays past its cap")
expect(Career.match_xp(600, 0 / 0, false, 0 / 0) == 80, "NaN counts as nothing")
expect(Career.match_xp(600, 5, false, -3) == 80 + 1000, "share is clamped to 1, drafts to 0..3")

local c = Career.clean({ xp = -50, matches = "x", wins = 3.7 })
expect(c.xp == 0 and c.matches == 0 and c.wins == 3, "a saved section is repaired")
expect(Career.clean(nil).xp == 0 and Career.clean(5).wins == 0, "nothing saved is a fresh career")
local r = Career.after_match({ xp = 200, matches = 4, wins = 1 }, 600, 0.3, false, 1)
expect(r.gained == 80 + 300 + 25 and r.career.xp == 200 + 405 and r.career.matches == 5 and r.promoted and r.rank.name == "Private", "a match adds XP, counts, and can promote")
r = Career.after_match({ xp = 10 }, 30, 1, true, 3)
expect(r.gained == 0 and r.career.xp == 10 and r.career.matches == 0 and not r.promoted, "a throwaway match changes nothing")
expect(Career.SECTION == "career" and #Career.SECTION <= 24, "its own settings section")

if fails > 0 then
	require("@lune/process").exit(1)
end
print("career: all passed")
