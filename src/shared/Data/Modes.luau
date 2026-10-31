--!strict
-- Game modes (Conquer the World's own): ways to play a match, chosen on the solo menu; public matches rotate
-- through the ones that suit a crowd. A mode is a set of match-config keys (Core/Sim, Core/SimModes) and nothing
-- else, so a mission (Data/Missions) can use one too.
local Modes = {}

export type Mode = { key: string, name: string, line: string, config: { [string]: any }, public: number? }

Modes.DEFAULT = "classic"

Modes.LIST = {
	{
		key = "classic",
		name = "Conquest",
		line = "The full war. Hold 80% of the world to win.",
		config = {},
		public = 7,
	},
	{
		key = "blitz",
		name = "Blitz",
		line = "Eras fly by, gold and troops flood in. Hold 60% to win.",
		config = {
			era_ticks = { 0, 600, 1800, 3600 },
			win_share = 0.6,
			draft_timeout_s = 30,
			boost = { gold = 1.5, regen = 1.5 },
		},
		public = 1,
	},
	{
		key = "crown",
		name = "King of the Hill",
		line = "Hold the Crown at the heart of the map for ten minutes in all.",
		config = { crown_ticks = 6000 },
		public = 1,
	},
	{
		key = "deadline",
		name = "Deadline",
		line = "Twenty minutes on the clock. Most land when it ends wins.",
		config = { solo_clock = true, time_limit_s = 1200 },
	},
	{
		key = "skirmish",
		name = "Skirmish",
		line = "Twelve nations and open land. A quick, clean fight.",
		config = { nation_limit = 12, tribes_scale = 0.4 },
	},
	{
		key = "totalwar",
		name = "Total War",
		line = "No alliances, no truces. Everyone stands alone.",
		config = { no_alliances = true },
		public = 1,
	},
} :: { Mode }

Modes.BY_KEY = {} :: { [string]: Mode }
for _, m in Modes.LIST do
	Modes.BY_KEY[m.key] = m
end

--- `config` with mode `key`'s keys filled in (a key the caller already set stays); stamps `config.mode`.
function Modes.apply(config: { [string]: any }, key: string?): { [string]: any }
	local m = Modes.BY_KEY[key or Modes.DEFAULT] or Modes.BY_KEY[Modes.DEFAULT]
	config.mode = m.key
	for k, v in m.config do
		if k == "tribes_scale" then
			-- (no count yet: the Sim scales the map's own default)
			if type(config.tribes) == "number" then
				config.tribes = math.floor(config.tribes * v)
			else
				config.tribes_scale = v
			end
		elseif k == "time_limit_s" then
			-- (a multiplayer match keeps its own, shorter or not)
			if (config.time_limit_s or 0) == 0 then
				config.time_limit_s = v
			end
		elseif config[k] == nil then
			config[k] = v
		end
	end
	return config
end

--- The mode of a public match with `seed`: weighted by `public`. Pure.
function Modes.public_pick(seed: number): string
	local total = 0
	for _, m in Modes.LIST do
		total += m.public or 0
	end
	local x = (math.floor(seed) * 48271 + 12345) % 1000003 % total
	for _, m in Modes.LIST do
		x -= m.public or 0
		if x < 0 then
			return m.key
		end
	end
	return Modes.DEFAULT
end

return Modes
