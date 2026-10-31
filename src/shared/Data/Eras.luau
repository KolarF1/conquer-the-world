--!strict
-- Eras (Conquer the World's own): a match has an arc. Four eras by ticks since play began; each of the
-- last three opens a Doctrine draft (Data/Doctrines) and the last, the Reckoning, doubles what landmarks
-- pay. Pure data and pure functions: the Sim, the client mirror and the UI all read the same table (the
-- Sim puts it in its snapshot as `eras`, so a client never guesses a match's own).
local Eras = {}

Eras.NAMES = { "Dawn", "Expansion", "Conflict", "Reckoning" }
--- One line each: what the era is for (shown on the banner and the Dominion panel).
Eras.BLURBS = {
	"Claim land and find your neighbours.",
	"Build up: your first doctrine, your first landmarks.",
	"The fronts harden. Hold what matters.",
	"Landmarks pay double. Finish it.",
}
--- Ticks (10 a second) since the start of play at which each era begins.
Eras.DEFAULT = { 0, 1800, 5400, 9600 } -- 0:00, 3:00, 9:00, 16:00
--- The tutorial's match: the first draft comes within the first couple of minutes.
Eras.TUTORIAL = { 0, 1200, 4200, 7800 }
--- Landmark bonuses in the last era.
Eras.RECKONING_LANDMARK_MULT = 2.0

--- The era (1..#starts) `since_play` ticks into play falls in; 1 before play and for junk.
function Eras.index(since_play: number, starts: { number }?): number
	local s = starts or Eras.DEFAULT
	local t = if type(since_play) == "number" and since_play == since_play then since_play else 0
	local era = 1
	for i = 2, #s do
		if t >= s[i] then
			era = i
		end
	end
	return era
end

--- Ticks until the next era begins (nil in the last one).
function Eras.ticks_to_next(since_play: number, starts: { number }?): number?
	local s = starts or Eras.DEFAULT
	local era = Eras.index(since_play, s)
	if era >= #s then
		return nil
	end
	return s[era + 1] - math.max(since_play, 0)
end

--- A draft is the doctrine pick of era 2..#starts: draft 1 opens with era 2.
function Eras.draft_of(era: number): number
	return math.max(era - 1, 0)
end

--- True when `starts` is a usable era table: numbers, strictly rising, the first 0, four of them.
function Eras.valid(starts: any): boolean
	if type(starts) ~= "table" or #starts ~= #Eras.NAMES or starts[1] ~= 0 then
		return false
	end
	for i = 2, #starts do
		if type(starts[i]) ~= "number" or starts[i] ~= starts[i] or starts[i] <= starts[i - 1] then
			return false
		end
	end
	return true
end

return Eras
