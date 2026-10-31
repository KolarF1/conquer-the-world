--!nocheck
-- The commander's record: Orders, Medals, Missions, Season, Progress. All pure.
-- Run: lune run tests/progress.luau
require("./prelude")
local Career = require("../src/shared/Data/Career")
local Orders = require("../src/shared/Data/Orders")
local Medals = require("../src/shared/Data/Medals")
local Missions = require("../src/shared/Data/Missions")
local Season = require("../src/shared/Data/Season")
local Progress = require("../src/shared/Data/Progress")
local Modes = require("../src/shared/Data/Modes")
local MapList = require("../src/shared/Data/MapList")
local Settings = require("../src/shared/Net/Settings")
local Eras = require("../src/shared/Data/Eras")

local fails = 0
local function expect(c: any, w: string)
	if c then
		print("  ok   " .. w)
	else
		fails += 1
		print("FAIL " .. w)
	end
end

local DAY = 20760

-- Career ------------------------------------------------------------------------------------------
expect(#Career.RANKS == 20, "twenty ranks")
local last = -1
local asc = true
for _, r in Career.RANKS do
	asc = asc and r[2] > last and type(r[3]) == "string" and #r[3] > 0
	last = r[2]
end
expect(asc, "they ascend, each with an insignia mark")

-- Orders ------------------------------------------------------------------------------------------
expect(#Orders.DAILY >= 20 and #Orders.WEEKLY >= 10, "a real pool of orders")
local known = {}
for _, k in Progress.TOTALS do
	known[k] = true
end
for _, k in { "land10", "land25", "land50", "landmarks", "mission_stars" } do
	known[k] = true
end
for _, m in Modes.LIST do
	known["mode_" .. m.key] = true
	known["win_" .. m.key] = true
end
for _, pool in { Orders.DAILY, Orders.WEEKLY } do
	for _, o in pool do
		expect(known[o.stat] and o.goal > 0 and o.xp > 0 and #o.text <= 40, o.key .. ": a stat a report feeds, a short line")
	end
end
local a, b = Orders.daily(DAY), Orders.daily(DAY)
expect(#a == 3 and a[1] == b[1] and a[1] ~= a[2] and a[2] ~= a[3] and a[1] ~= a[3], "three distinct orders, the same all day")
local differ = false
for d = 1, 20 do
	differ = differ or Orders.daily(DAY + d)[1] ~= a[1]
end
expect(differ, "and they change with the day")
expect(Orders.weekly(DAY)[1] == Orders.weekly(DAY - DAY % 7 + 6)[1], "weekly orders hold all week")
local o0 = Orders.current({ d = DAY - 1, a = 5, w = DAY // 7, x = 3 }, DAY)
expect(o0.a == 0 and o0.x == 3, "a new day clears the dailies, not the weeklies")
do
	local order = Orders.daily(DAY)[1]
	local stats = { [order.stat] = order.goal }
	local o, done, xp = Orders.advance(nil, stats, DAY)
	expect(o.a == order.goal and table.find(done, order) ~= nil and xp >= order.xp, "reaching the goal completes it and pays")
	local _, done2 = Orders.advance(o, stats, DAY)
	expect(table.find(done2, order) == nil, "never twice")
end

-- Medals ------------------------------------------------------------------------------------------
expect(#Medals.LIST >= 48 and #Medals.LIST <= 64, "48+ medals, and they fit a saved string (" .. #Medals.LIST .. ")")
local keys = {}
for _, m in Medals.LIST do
	expect(not keys[m.key] and known[m.stat], m.key .. ": unique, on a known stat")
	keys[m.key] = true
end
local bits, fresh, xp = Medals.award("", { wins = 1 })
expect(#fresh == 1 and fresh[1].key == "wins1" and xp == 100 and #bits == #Medals.LIST, "a first win earns First Blood")
local _, again = Medals.award(bits, { wins = 1 })
expect(#again == 0, "once")
expect(Medals.earned(bits)[1] == true and Medals.earned(bits)[2] == false, "the string reads back")

-- Missions ----------------------------------------------------------------------------------------
expect(#Missions.LIST == 24 and Missions.MAX_STARS == 72, "24 missions, 72 stars")
local tk = {}
for i, m in Missions.LIST do
	expect(not tk[m.key] and MapList.get(m.map) ~= nil and (m.mode == nil or Modes.BY_KEY[m.mode] ~= nil), m.key .. ": unique, a real map and mode")
	tk[m.key] = true
	expect(#m.objectives == 3 and #m.brief <= 90, m.key .. ": three objectives, a short brief")
	for _, ob in m.objectives do
		expect(Missions.objective_text(ob) ~= "?", m.key .. ": every objective has words")
	end
	expect(m.difficulty >= 0 and m.difficulty <= 2 and Missions.THEATRES[m.theatre] ~= nil, m.key .. ": a difficulty and a theatre")
end
local empty = Missions.best("")
expect(Missions.unlocked(1, empty) and not Missions.unlocked(2, empty), "only the first is open at first")
empty[1] = 1
expect(Missions.unlocked(2, empty), "a star opens the next")
expect(not Missions.unlocked(7, empty), "a theatre waits for its stars")
local full = table.create(24, 3)
for i = 1, 24 do
	expect(Missions.unlocked(i, full), "all open at the end " .. i)
end
do
	-- the campaign can always be finished: earning stars in order opens every mission
	local best = table.create(24, 0)
	local reached = 0
	for i = 1, 24 do
		if Missions.unlocked(i, best) then
			reached += 1
			best[i] = 3
		end
	end
	expect(reached == 24, "three stars each carry a player through every theatre")
	-- and one star less each still does not lock anyone out by theatre IV? (2 stars a mission)
	local two = table.create(24, 0)
	local r2 = 0
	for i = 1, 24 do
		if Missions.unlocked(i, two) then
			r2 += 1
			two[i] = 2
		end
	end
	expect(r2 == 24, "so do two stars each (" .. r2 .. ")")
end
local m1 = Missions.LIST[1]
expect(Missions.stars(m1, { peak = 0.2, won = true, seconds = 600 }) == 3, "all objectives")
expect(Missions.stars(m1, { peak = 0.2, won = false, seconds = 600 }) == 1, "one objective")
expect(Missions.met({ survive = 600 }, { seconds = 700, eliminated = true, eliminated_at = 650 }), "standing long enough counts even if you fell later")
expect(not Missions.met({ survive = 600 }, { seconds = 700, eliminated = true, eliminated_at = 300 }), "falling early does not")
expect(not Missions.met({ no_nukes = true }, { won = true, nukes = 1 }), "no_nukes means none")
expect(Missions.encode(Missions.best("0123"))  == "012300000000000000000000", "stars read and write back")

-- Season ------------------------------------------------------------------------------------------
local s1 = Season.current(Season.EPOCH)
expect(s1.number == 1 and s1.days_left == 56 and s1.theme.name == "Cartographers", "Season 1")
expect(Season.current(Season.EPOCH + 56).number == 2 and Season.current(0).number == 1, "the next, and never below 1")
expect(Season.level(0).level == 1 and Season.level(499).level == 1 and Season.level(500).level == 2 and Season.level(1e9).level == 30, "levels")
expect(Season.title_at(s1.theme, 5) == s1.theme.titles[1] and Season.title_at(s1.theme, 6) == nil, "titles every fifth level")
local tb = Season.grant("", 2, 10)
expect(#Season.titles_of(tb) == 2 and Season.titles_of(tb)[1] == Season.THEMES[2].titles[1], "granted titles read back")
for _, t in Season.THEMES do
	expect(#t.titles == 6, t.name .. ": six titles")
end

-- Progress ----------------------------------------------------------------------------------------
local report = { seconds = 900, share = 0.3, peak = 0.3, won = true, drafts = 2, kills = 4, builds = 12, nukes = 1, edicts = 1, nemeses = 1, landmarks = 3, events = 2, mode = "blitz", map_id = "spine", difficulty = 2 }
local r = Progress.after_match(nil, report, DAY)
local c = r.career
expect(r.gained > 0 and c.xp == r.gained and c.matches == 1 and c.wins == 1, "a match pays and counts")
expect(c.t.kills == 4 and c.t.win_blitz == 1 and c.t.win_hard == 1 and c.t.win_invented == 1 and c.t.best_land == 30 and c.t.best_lm == 3, "the totals")
expect(#r.medals >= 4, "a first match earns its medals (" .. #r.medals .. ")")
expect(#r.lines >= 2, "and says what paid")
local short = Progress.after_match(c, { seconds = 30, won = true, peak = 1 }, DAY)
expect(short.gained == 0 and short.career.xp == c.xp, "a match too short pays nothing")
local r2 = Progress.after_match(c, report, DAY)
expect(r2.career.xp > c.xp and r2.career.t.best_land == 30 and r2.career.matches == 2, "records add up")
expect(Progress.after_match({ xp = "bad", t = 5, o = "x", medals = 7 }, report, DAY).career.matches == 1, "junk saved is a fresh career")
-- a mission
local m = Missions.LIST[1]
local rm = Progress.after_match(nil, { seconds = 600, peak = 0.2, won = true, drafts = 0, mission = m.key, map_id = m.map, difficulty = 0 }, DAY)
expect(rm.stars == 3 and Missions.best(rm.career.missions)[1] == 3 and rm.career.t.stars == 3, "a mission's stars are kept")
local rm2 = Progress.after_match(rm.career, { seconds = 600, peak = 0.2, won = false, drafts = 0, mission = m.key, map_id = m.map }, DAY)
expect(rm2.stars == 1 and Missions.best(rm2.career.missions)[1] == 3, "and only ever improve")
-- a season turning over
local rs = Progress.after_match({ season = 1, season_xp = 490, xp = 490 }, { seconds = 600, peak = 0.1, won = false, drafts = 0 }, Season.EPOCH)
expect(rs.career.season == 1 and rs.career.season_xp > 490 and rs.season_up, "XP climbs the season")
local rn = Progress.after_match(rs.career, { seconds = 600, peak = 0.1, won = false, drafts = 0 }, Season.EPOCH + 56)
expect(rn.career.season == 2 and rn.career.season_xp < rs.career.season_xp, "a new season starts the track again")
local big = Progress.after_match({ season = 1, season_xp = 1990 }, { seconds = 600, peak = 0.1, won = false, drafts = 0 }, Season.EPOCH)
expect(table.find(big.new_titles, Season.THEMES[1].titles[1]) ~= nil and #Progress.titles(big.career) >= 1, "level 5 grants a title, kept for good")
-- it survives the settings sanitiser
local cleaned = Settings.clean_section(c)
expect(cleaned.xp == c.xp and cleaned.medals == c.medals and cleaned.t.kills == 4 and cleaned.o.d == DAY, "the section survives Net/Settings as it is")
expect(Settings.bytes(cleaned) < Settings.MAX_SECTION_BYTES, "and is well under its size cap (" .. Settings.bytes(cleaned) .. ")")
expect(#c.medals <= Settings.MAX_STRING and #Missions.encode(table.create(24, 3)) <= Settings.MAX_STRING, "its strings fit")
-- the mission configs make playable matches
for _, mi in Missions.LIST do
	local cfg = Modes.apply({ tribes = 300 }, mi.mode)
	for k, v in mi.config or {} do
		cfg[k] = v
	end
	expect(cfg.era_ticks == nil or Eras.valid(cfg.era_ticks), mi.key .. ": a valid config")
end

if fails > 0 then
	print("progress: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("progress: all passed")
