--!strict
-- Seasons (Conquer the World's own): every 56 days a new season, and a free track of 30 levels climbed with career XP.
-- Every fifth level grants a title of that season's theme, kept for good. Cosmetic, like all of the career: nothing
-- here is sold or spends anything. The seasons repeat their themes; a returning theme's titles are already yours.
local Season = {}

Season.DAYS = 56
Season.LEVELS = 30
Season.XP_PER_LEVEL = 500
--- The day (since the epoch) Season 1 began: 2026-11-01.
Season.EPOCH = 20758

Season.THEMES = {
	{ name = "Cartographers", line = "Every border is a line someone drew.", titles = { "the Surveyor", "Inker of Coasts", "Master of Charts", "Keeper of the Atlas", "the Meridian", "Lord of the Compass" } },
	{ name = "Iron Winter", line = "The fronts freeze. The war does not.", titles = { "the Frostbitten", "Winter's Own", "Warden of the North", "the Unthawed", "Iron Marshal", "Sovereign of Winter" } },
	{ name = "Gilded Age", line = "Everything has a price, and you can pay it.", titles = { "the Solvent", "Merchant Lord", "Master of Coin", "the Gilded", "Sultan of Trade", "Emperor of Gold" } },
	{ name = "Ashfall", line = "The sky remembers what you did.", titles = { "the Scorched", "Bringer of Ash", "Lord of Fallout", "the Unburnt", "Ashen Marshal", "Sovereign of Cinders" } },
}

--- The season on `day`: its number (1-based; never below 1), theme, and days left.
function Season.current(day: number)
	local n = math.max((day - Season.EPOCH) // Season.DAYS, 0) + 1
	local theme = Season.THEMES[(n - 1) % #Season.THEMES + 1]
	local ends = Season.EPOCH + n * Season.DAYS
	return { number = n, theme = theme, days_left = math.max(ends - day, 0), theme_index = (n - 1) % #Season.THEMES + 1 }
end

--- The level of `xp` earned this season: 1..LEVELS, the XP into it, and progress 0..1.
function Season.level(xp: number)
	local x = if type(xp) == "number" and xp == xp then math.max(math.floor(xp), 0) else 0
	local lv = math.min(x // Season.XP_PER_LEVEL + 1, Season.LEVELS)
	local into = x - (lv - 1) * Season.XP_PER_LEVEL
	return { level = lv, into = into, progress = if lv >= Season.LEVELS then 1 else into / Season.XP_PER_LEVEL }
end

--- The title of reaching `level` in theme `t`, nil on other levels.
function Season.title_at(t: any, level: number): string?
	if level % 5 ~= 0 then
		return nil
	end
	return t.titles[level // 5]
end

--- The index (1..24) of theme `t`'s slot-th title in the saved bit string `tbits`.
function Season.bit_index(theme_index: number, slot: number): number
	return (theme_index - 1) * 6 + slot
end

--- Every title in saved `tbits`.
function Season.titles_of(tbits: any): { string }
	local s = if type(tbits) == "string" then tbits else ""
	local out = {}
	for ti, t in Season.THEMES do
		for slot, title in t.titles do
			if string.sub(s, Season.bit_index(ti, slot), Season.bit_index(ti, slot)) == "1" then
				table.insert(out, title)
			end
		end
	end
	return out
end

--- `tbits` with the titles of theme `ti` up to `level` set.
function Season.grant(tbits: any, ti: number, level: number): string
	local s = if type(tbits) == "string" then tbits else ""
	local parts = {}
	local n = #Season.THEMES * 6
	for i = 1, n do
		parts[i] = if string.sub(s, i, i) == "1" then "1" else "0"
	end
	for slot = 1, level // 5 do
		parts[Season.bit_index(ti, slot)] = "1"
	end
	return table.concat(parts)
end

return Season
