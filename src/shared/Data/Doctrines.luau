--!strict
-- Doctrines (Conquer the World's own): at each era after the first, every player drafts one of three
-- offered doctrines, a permanent bend of the match. Twenty-four in three tiers; each draft offers three of
-- its tier's eight (which three is a hash of the match seed, the player and the draft, so a match has its own
-- choices and the Sim's random sequence is untouched).
--
-- A doctrine is a set of additive levers; a player's multiplier for a lever is 1 + the sum of their picks:
--   gold   passive gold income              cap    troop cap
--   lm     landmark bonuses                 conq   gold taken by conquering a nation
--   trade  gold from trade ships and trains
--   atk    attack strength                  def    defence
--   regen  troop regrowth                   claim  cheaper claims on open land
--   rebate share of a building's cost refunded
-- Trade-offs are never paid in cap (a lowered cap would delete troops in one tick). `key` travels in an
-- intent's 16-character `kind` string. `edict` (tier 3) names the active order the doctrine grants.
local Doctrines = {}

export type Doctrine = {
	key: string,
	name: string,
	tier: number,
	glyph: string,
	line: string,
	gold: number?,
	cap: number?,
	lm: number?,
	conq: number?,
	trade: number?,
	atk: number?,
	def: number?,
	regen: number?,
	claim: number?,
	rebate: number?,
	edict: string?,
}

Doctrines.LEVERS = { "gold", "cap", "lm", "conq", "trade", "atk", "def", "regen", "claim", "rebate" }
Doctrines.TIERS = 3
--- A human who has not chosen this many seconds after the draft opened gets the first offer.
Doctrines.DRAFT_TIMEOUT_S = 60
--- Offers per draft.
Doctrines.OFFER_SIZE = 3

Doctrines.LIST = {
	-- tier 1: the Expansion
	{ key = "merchant", name = "Merchant Guild", tier = 1, glyph = "$", line = "Coin flows faster.", gold = 0.20 },
	{ key = "levy", name = "Levy Banners", tier = 1, glyph = "+", line = "A bigger army fits.", cap = 0.15 },
	{ key = "cartographer", name = "Cartographers", tier = 1, glyph = "N", line = "Landmarks pay more.", lm = 0.50 },
	{ key = "tithe", name = "Tithe Collectors", tier = 1, glyph = "%", line = "Conquest pays more.", conq = 0.50, gold = 0.05 },
	{ key = "drill", name = "Drill Sergeants", tier = 1, glyph = "D", line = "Ranks fill back up sooner.", regen = 0.25 },
	{ key = "pioneers", name = "Pioneers", tier = 1, glyph = "P", line = "Open land comes cheap.", claim = 0.40 },
	{ key = "masons", name = "Master Masons", tier = 1, glyph = "M", line = "Every building hands coin back.", rebate = 0.15 },
	{ key = "wardens", name = "Border Wardens", tier = 1, glyph = "W", line = "Your land is harder to take.", def = 0.12 },
	-- tier 2: the Conflict
	{ key = "charter", name = "Trade Charter", tier = 2, glyph = "~", line = "Ships and trains pay more.", trade = 0.50 },
	{ key = "plunder", name = "Plunderers", tier = 2, glyph = "!", line = "Take a nation's gold twice over.", conq = 1.0, gold = -0.10 },
	{ key = "standing", name = "Standing Army", tier = 2, glyph = "#", line = "A much bigger army, a dearer one.", cap = 0.25, gold = -0.10 },
	{ key = "mercenary", name = "Mercenary Pact", tier = 2, glyph = "&", line = "Hired steel for hard coin.", gold = 0.30, trade = -0.30 },
	{ key = "vanguard", name = "Vanguard", tier = 2, glyph = "V", line = "Strike first, guard less.", atk = 0.18, def = -0.05 },
	{ key = "bastion", name = "Bastion Doctrine", tier = 2, glyph = "B", line = "Walls first, sorties later.", def = 0.22, atk = -0.05 },
	{ key = "conscripts", name = "Conscription", tier = 2, glyph = "C", line = "Every village sends its young.", regen = 0.40, gold = -0.10 },
	{ key = "engineers", name = "Royal Engineers", tier = 2, glyph = "E", line = "Build wide and be paid for it.", rebate = 0.25, trade = 0.10 },
	-- tier 3: the Reckoning
	{ key = "coin", name = "Empire of Coin", tier = 3, glyph = "$", line = "Gold in a flood. Edict: Windfall.", gold = 0.40, edict = "windfall" },
	{ key = "grandarmy", name = "Grand Army", tier = 3, glyph = "+", line = "A host of its own. Edict: Levy.", cap = 0.30, edict = "levy" },
	{ key = "wonders", name = "Wonder Keepers", tier = 3, glyph = "N", line = "Landmarks pay twice as much. Edict: Jubilee.", lm = 1.0, edict = "jubilee" },
	{ key = "spoils", name = "Warlord's Spoils", tier = 3, glyph = "!", line = "War pays, and what follows. Edict: Blitz.", conq = 1.5, trade = 0.25, edict = "blitz" },
	{ key = "ironwall", name = "Iron Wall", tier = 3, glyph = "I", line = "They break on you. Edict: Fortify.", def = 0.30, edict = "fortify" },
	{ key = "lightning", name = "Lightning War", tier = 3, glyph = "L", line = "Over before they form up. Edict: Blitz.", atk = 0.28, gold = -0.10, edict = "blitz" },
	{ key = "service", name = "National Service", tier = 3, glyph = "S", line = "A nation under arms. Edict: Muster.", regen = 0.50, cap = 0.10, edict = "muster" },
	{ key = "golden", name = "Golden Age", tier = 3, glyph = "G", line = "Everything pays. Edict: Jubilee.", gold = 0.20, trade = 0.20, rebate = 0.10, edict = "jubilee" },
} :: { Doctrine }

--- The active orders tier 3 doctrines grant (Core/SimDoctrines). One cooldown covers them all. `gold_s`: that
--- many seconds of income at once; `troops`: that share of the cap as troops, up to the cap; `lever` / `mult`
--- for `secs`: a timed multiplier.
Doctrines.EDICT_ORDER = { "windfall", "levy", "jubilee", "blitz", "fortify", "muster" }
Doctrines.EDICTS = {
	windfall = { name = "Windfall", line = "A minute of income at once", gold_s = 60 },
	levy = { name = "Levy", line = "A fifth of your cap as troops", troops = 0.2 },
	jubilee = { name = "Jubilee", line = "Double gold for a minute", lever = "gold", mult = 2.0, secs = 60 },
	blitz = { name = "Blitz", line = "+40% attack for 45 seconds", lever = "atk", mult = 1.4, secs = 45 },
	fortify = { name = "Fortify", line = "+50% defence for a minute", lever = "def", mult = 1.5, secs = 60 },
	muster = { name = "Muster", line = "Triple regrowth for a minute", lever = "regen", mult = 3.0, secs = 60 },
} :: { [string]: any }

--- key -> doctrine, and key -> its index in LIST (what travels in events: a small integer).
Doctrines.BY_KEY = {} :: { [string]: Doctrine }
Doctrines.INDEX = {} :: { [string]: number }
for i, d in Doctrines.LIST do
	Doctrines.BY_KEY[d.key] = d
	Doctrines.INDEX[d.key] = i
end

--- The doctrines of a tier, in LIST order.
function Doctrines.pool(tier: number): { Doctrine }
	local out = {}
	for _, d in Doctrines.LIST do
		if d.tier == tier then
			table.insert(out, d)
		end
	end
	return out
end

--- A well-mixed integer from three small ones, in 0 .. 1000002. Stepwise modulo keeps every product
--- exact in a double (a plain product of a 31-bit seed would not be).
function Doctrines.mix(seed: number, id: number, draft: number): number
	local a = (math.floor(seed) % 100003) * 7919
	local b = (math.floor(id) % 4099) * 104729
	local c = (math.floor(draft) % 97) * 1299709
	local h = (a + b + c) % 1000003
	h = (h * 48271 + 12345) % 1000003
	return (h * 69621 + 1) % 1000003
end

--- The three offered for `draft` (1-based) to owner `id` in a match with `seed`: three distinct doctrines
--- of the draft's tier chosen by hash; indices into LIST, in LIST order. Pure.
function Doctrines.offer(seed: number, id: number, draft: number): { number }
	local tier = math.clamp(draft, 1, Doctrines.TIERS)
	local pool = Doctrines.pool(tier)
	local h = Doctrines.mix(seed, id, draft)
	local taken = {}
	for _ = 1, Doctrines.OFFER_SIZE do
		h = (h * 48271 + 11) % 1000003
		local k = h % #pool + 1
		while taken[k] do
			k = k % #pool + 1
		end
		taken[k] = true
	end
	local out = {}
	for i, d in pool do
		if taken[i] then
			table.insert(out, Doctrines.INDEX[d.key])
		end
	end
	return out
end

--- The multiplier on `lever` of a player who picked `keys`.
function Doctrines.mult(keys: { string }, lever: string): number
	local m = 1.0
	for _, k in keys do
		local d = Doctrines.BY_KEY[k]
		if d ~= nil then
			m += (d :: any)[lever] or 0
		end
	end
	return math.max(m, 0.2)
end

--- One line of numbers for a doctrine, "+20% gold, -10% trade": what a card prints under its name.
function Doctrines.effects(d: Doctrine): { string }
	local names = {
		gold = "gold",
		cap = "troop cap",
		lm = "landmark bonuses",
		conq = "conquest gold",
		trade = "trade gold",
		atk = "attack",
		def = "defence",
		regen = "troop regrowth",
		claim = "cheaper claims",
		rebate = "building refund",
	}
	local out = {}
	for _, lever in Doctrines.LEVERS do
		local v = (d :: any)[lever]
		if v ~= nil and v ~= 0 then
			table.insert(out, string.format("%s%d%% %s", if v > 0 then "+" else "-", math.floor(math.abs(v) * 100 + 0.5), names[lever]))
		end
	end
	return out
end

return Doctrines
