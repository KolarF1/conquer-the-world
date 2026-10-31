--!strict
-- Port of scripts/ui/ui_theme.gd
-- AIRFRONT design system: colour tokens, the 8 px spacing scale, Rubik weights, text metrics, the
-- icon cache, style factories and widget helpers. Everything is static so any component can use it.
--
-- Roblox notes (see build/notes/ui-kit.md):
--   * Colours: tokens are Color3; a translucent colour is an RGBA {color: Color3, alpha: number}
--     made with UITheme.c(col, a) (= Godot `Color(col, a)`) or UITheme.rgba(r, g, b, a). Every kit
--     function accepts Color3 or RGBA (or a Core RGBA8 int).
--   * Sizes are Godot logical px. The kit renders them at `UITheme.scale` (set by Widgets.Root).
--   * Godot font size S (em px) -> Roblox TextSize round(S * 1.185 * scale): Roblox TextSize is the
--     line height (ascent + descent), Rubik's is 1.185 em (verified: TextBounds == TTF advances).
--   * Text is measured synchronously with a hidden TextLabel once the Rubik weights are loaded
--     (UITheme.init() yields until they are); Lune falls back to approximate metrics.

local IS_ROBLOX = (game :: any) ~= nil

local UITheme = {}

UITheme.IS_ROBLOX = IS_ROBLOX

--- Shared Core module by name (ReplicatedStorage.Airfront.Core in Roblox, src/shared/Core in Lune),
--- required once and kept. A require later in a session can fail: in some live sessions every require
--- after some moment errors "Cannot require a RobloxScript module from a non RobloxScript context"
--- (from 2026-10-10, 34.6K a day by 10-23), so the client asks for what it needs at start
--- (UICtx.prime) and the kept module answers from then on.
local _core: { [string]: any } = {}
local function core(name: string): any
	local m = _core[name]
	if m ~= nil then
		return m
	end
	if IS_ROBLOX then
		local rs = game:GetService("ReplicatedStorage")
		m = require((rs:WaitForChild("Airfront") :: any):WaitForChild("Core"):WaitForChild(name))
	else
		m = (require :: any)("../../shared/Core/" .. name)
	end
	_core[name] = m
	return m
end
UITheme.core = core

local _Defs: any = nil
local function Defs(): any
	if _Defs == nil then
		local ok, d = pcall(core, "Defs")
		_Defs = if ok then d else false
	end
	return if _Defs then _Defs else nil
end

-- =============================================================================================
-- Colours
-- =============================================================================================

export type RGBA = { color: Color3, alpha: number }

local RGBA_MT = { __type = "RGBA" }
RGBA_MT.__index = RGBA_MT

local function rgba_of(c: Color3, a: number): RGBA
	return setmetatable({ color = c, alpha = a }, RGBA_MT) :: any
end

--- Color(r, g, b, a) with components 0..1.
function UITheme.rgba(r: number, g: number, b: number, a: number?): RGBA
	return rgba_of(Color3.new(r, g, b), if a == nil then 1.0 else a)
end

--- Godot `Color(col, alpha)`: the same colour with another alpha.
function UITheme.c(col: any, alpha: number): RGBA
	return rgba_of(UITheme.color3(col), alpha)
end

function UITheme.is_rgba(x: any): boolean
	return type(x) == "table" and getmetatable(x) == RGBA_MT
end

--- Color3 of any colour value (Color3 | RGBA | RGBA8 int).
function UITheme.color3(x: any): Color3
	if typeof(x) == "Color3" then
		return x
	end
	if type(x) == "table" and x.color ~= nil then
		return x.color
	end
	if type(x) == "number" then
		local r = bit32.band(bit32.rshift(x, 24), 255)
		local g = bit32.band(bit32.rshift(x, 16), 255)
		local b = bit32.band(bit32.rshift(x, 8), 255)
		return Color3.fromRGB(r, g, b)
	end
	return Color3.new(1, 1, 1)
end

--- Alpha (0..1) of any colour value.
function UITheme.alpha(x: any): number
	if type(x) == "table" and x.alpha ~= nil then
		return x.alpha
	end
	if type(x) == "number" then
		return bit32.band(x, 255) / 255.0
	end
	return 1.0
end

function UITheme.to_rgba(x: any): RGBA
	if UITheme.is_rgba(x) then
		return x
	end
	return rgba_of(UITheme.color3(x), UITheme.alpha(x))
end

--- Godot Color.lerp (alpha included). Returns a Color3 when both inputs are opaque Color3s.
function UITheme.lerp(a: any, b: any, t: number): any
	local ca, cb = UITheme.color3(a), UITheme.color3(b)
	local c = Color3.new(ca.R + (cb.R - ca.R) * t, ca.G + (cb.G - ca.G) * t, ca.B + (cb.B - ca.B) * t)
	if typeof(a) == "Color3" and typeof(b) == "Color3" then
		return c
	end
	local aa, ab = UITheme.alpha(a), UITheme.alpha(b)
	return rgba_of(c, aa + (ab - aa) * t)
end

--- Godot Color.get_luminance().
function UITheme.luminance(x: any): number
	local c = UITheme.color3(x)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

function UITheme.equal(a: any, b: any): boolean
	if a == b then
		return true
	end
	if a == nil or b == nil then
		return false
	end
	local ca, cb = UITheme.color3(a), UITheme.color3(b)
	return math.abs(ca.R - cb.R) < 1e-4
		and math.abs(ca.G - cb.G) < 1e-4
		and math.abs(ca.B - cb.B) < 1e-4
		and math.abs(UITheme.alpha(a) - UITheme.alpha(b)) < 1e-4
end

-- --- colour tokens (same as ui_theme.gd) ------------------------------------------------------
-- The look is Conquer the World's own: deep ink-teal plates (the upstream's were navy glass) with
-- a faintly teal hairline, warm-neutral text, a teal accent. tests/ui_look.luau keeps it readable.
UITheme.GLASS = UITheme.rgba(0.043, 0.075, 0.082, 0.86) -- #0b1315 @ 86 %
UITheme.GLASS_SOLID = UITheme.rgba(0.035, 0.063, 0.07, 0.97)
UITheme.GLASS_RAISED = UITheme.rgba(0.082, 0.13, 0.14, 0.95)
UITheme.LINE = UITheme.rgba(0.6, 0.95, 0.9, 0.13)
UITheme.LINE_2 = UITheme.rgba(0.6, 0.95, 0.9, 0.24)
UITheme.FILL = UITheme.rgba(1.0, 1.0, 1.0, 0.06)
UITheme.FILL_2 = UITheme.rgba(1.0, 1.0, 1.0, 0.11)
UITheme.TEXT = Color3.new(0.945, 0.965, 0.955)
UITheme.TEXT_2 = Color3.new(0.7, 0.78, 0.77)
UITheme.TEXT_3 = Color3.new(0.5, 0.6, 0.6)
-- Conquer the World's own accent (the upstream's was amber): a teal for primary actions. The
-- constant keeps its old name, which a few hundred call sites use. Currency stays GOLD.
UITheme.AMBER = Color3.new(0.243, 0.878, 0.812) -- #3ee0cf primary actions
UITheme.AMBER_HI = Color3.new(0.55, 0.95, 0.9)
UITheme.AMBER_LO = Color3.new(0.1, 0.6, 0.56)
UITheme.CYAN = Color3.new(0.4, 0.66, 1.0) -- info (a sky blue, so it stays apart from the teal)
UITheme.GREEN = Color3.new(0.37, 0.89, 0.6)
UITheme.RED = Color3.new(1.0, 0.33, 0.39)
--- the solid SurrenderButton's fill, hover and lip
UITheme.SURRENDER_RED = Color3.fromRGB(222, 48, 60)
UITheme.SURRENDER_RED_HI = Color3.fromRGB(240, 72, 82)
UITheme.SURRENDER_RED_LO = Color3.fromRGB(140, 20, 32)
UITheme.ORANGE = Color3.new(1.0, 0.58, 0.36)
UITheme.VIOLET = Color3.new(0.72, 0.62, 1.0)
UITheme.GOLD = Color3.new(1.0, 0.84, 0.4)
UITheme.INK = Color3.new(0.02, 0.09, 0.085) -- text on the accent
UITheme.WHITE = Color3.new(1, 1, 1)
UITheme.BLACK = Color3.new(0, 0, 0)
UITheme.CLEAR = UITheme.rgba(0, 0, 0, 0)

-- --- spacing / radii (8 px scale with a 4 px half step) -----------------------------------------
UITheme.S1 = 4
UITheme.S2 = 8
UITheme.S3 = 12
UITheme.S4 = 16
UITheme.S5 = 24
UITheme.S6 = 32
UITheme.S7 = 48
UITheme.R_SM = 4
UITheme.R_MD = 7
UITheme.R_LG = 10

--- No backdrop blur in Roblox: glass panels take the GDScript no-frost path (tint alpha + 0.08,
--- "a slightly more opaque tint reads just as well" -- what the original used on phones) plus the
--- frost path's top sheen. Without the blur a lower alpha lets map icons / roads show through
--- sharply; 0.08 keeps the territory colour tinting the glass while hiding that detail.
UITheme.GLASS_BOOST = 0.08
--- Top sheen of the frosted glass (frost shader `sheen`, 0.045 when on).
UITheme.GLASS_SHEEN = 0.045

--- Frosted (screen-sampling) glass is unavailable in Roblox (kept for API parity).
UITheme.frost_enabled = false
--- Minimum text size applied to new labels (12 on phones, 0 = off).
UITheme.min_font_size = 0

--- Current UI scale (render px per logical px). Set by Widgets.Root / UITheme.set_scale.
UITheme.scale = 1.0

-- =============================================================================================
-- Fonts & text metrics
-- =============================================================================================

--- The UI font: Montserrat, which Roblox ships (rbxasset), so it loads everywhere. The upstream's was Rubik by an
--- asset id of its own account. Metrics below are Montserrat's (tools/art/make_font_metrics.py).
UITheme.FONT_FAMILY = "rbxasset://fonts/families/Montserrat.json"
--- Line height of Montserrat in em (hhea ascender 968 + descender 251, per 1000).
UITheme.LINE_EM = 1.219
--- Baseline from the top of a line, in em.
UITheme.ASCENT_EM = 0.968

local WEIGHT_ENUM: { [number]: any } = {}
if IS_ROBLOX then
	WEIGHT_ENUM = {
		[100] = Enum.FontWeight.Thin,
		[200] = Enum.FontWeight.ExtraLight,
		[300] = Enum.FontWeight.Light,
		[400] = Enum.FontWeight.Regular,
		[500] = Enum.FontWeight.Medium,
		[600] = Enum.FontWeight.SemiBold,
		[700] = Enum.FontWeight.Bold,
		[800] = Enum.FontWeight.ExtraBold,
		[900] = Enum.FontWeight.Heavy,
	}
end

local function snap_weight(w: number?): number
	local v = math.clamp(math.floor(((w or 500) + 50) / 100) * 100, 100, 900)
	return v
end
UITheme.snap_weight = snap_weight

local _fonts: { [number]: any } = {}

--- Rubik at a weight (100..900). (GDScript font(weight, spacing, tabular): spacing and tabular
--- digits are properties of the label in the kit, see Widgets.Label.)
function UITheme.font(weight: number?): any
	local w = snap_weight(weight)
	local f = _fonts[w]
	if f == nil and IS_ROBLOX then
		f = Font.new("rbxasset://fonts/families/Montserrat.json", WEIGHT_ENUM[w])
		_fonts[w] = f
	end
	return f
end

--- Roblox TextSize (render px) for a Godot font size (logical em px) at the current scale.
function UITheme.text_size(size: number): number
	return math.max(1, math.floor(size * UITheme.LINE_EM * UITheme.scale + 0.5))
end

--- Line height in logical px of a label of font size `size` (Godot Label min height). Godot takes
--- the font's ascent / descent from FreeType's size metrics, rounded outwards to whole pixels
--- (verified on the original's captures: a 10 px caption is 13 px tall, 11 px -> 14, 12 px -> 15).
function UITheme.line_height(size: number): number
	return math.ceil(size * UITheme.ASCENT_EM - 1e-6) + math.ceil(size * (UITheme.LINE_EM - UITheme.ASCENT_EM) - 1e-6)
end

--- Baseline offset in logical px from the top of a line (Godot: ceil(ascent)).
function UITheme.ascent(size: number): number
	return math.ceil(size * UITheme.ASCENT_EM - 1e-6)
end

--- Rubik's tabular figures (OpenType "tnum") are 0.975x as wide as its proportional "0" at every
--- weight (663 vs 680 units at 700); the kit centres each digit in a cell of that width.
UITheme.TNUM_RATIO = 1.031

--- Where Roblox puts the baseline inside a TextLabel line of TextSize `ts` (fraction of ts).
UITheme.RBX_BASELINE = 0.968 / 1.219

-- Approximate Rubik advances (em/1000) for Lune / before fonts load: digits, upper, lower, other.
local APPROX = {
	[400] = { d = 583, u = 716, l = 574, o = 274 },
	[500] = { d = 590, u = 722, l = 583, o = 286 },
	[600] = { d = 600, u = 729, l = 593, o = 298 },
	[700] = { d = 609, u = 736, l = 604, o = 311 },
	[800] = { d = 620, u = 743, l = 616, o = 327 },
	[900] = { d = 631, u = 751, l = 628, o = 342 },
}

local function approx_width(text: string, px_em: number, weight: number): number
	local t = APPROX[math.clamp(weight, 400, 900)] or APPROX[500]
	local w = 0
	for _, cp in utf8.codes(text) do
		local k
		if cp >= 48 and cp <= 57 then
			k = t.d
		elseif cp >= 65 and cp <= 90 then
			k = t.u
		elseif cp >= 97 and cp <= 122 then
			k = t.l
		else
			k = t.o
		end
		w += k
	end
	return w * px_em / 1000.0
end

-- BEGIN GENERATED METRICS (tools/art/make_font_metrics.py) --
-- Montserrat advances in em/1000: ADV[weight] = {codepoint -> advance}; TNUM[weight] = tabular digit.
local ADV: { [number]: { [number]: number } } = {}
local TNUM: { [number]: number } = {}
ADV[400] = { [32]=262, [33]=260, [34]=373, [35]=696, [36]=615, [37]=829, [38]=669, [39]=202, [40]=329, [41]=329, [42]=386, [43]=575, [44]=212, [45]=382, [46]=212, [47]=335, [48]=662, [49]=361, [50]=568, [51]=564, [52]=661, [53]=566, [54]=609, [55]=589, [56]=638, [57]=609, [58]=212, [59]=212, [60]=575, [61]=575, [62]=575, [63]=567, [64]=1033, [65]=717, [66]=754, [67]=719, [68]=826, [69]=669, [70]=633, [71]=773, [72]=813, [73]=302, [74]=501, [75]=711, [76]=589, [77]=955, [78]=813, [79]=839, [80]=718, [81]=839, [82]=723, [83]=615, [84]=574, [85]=792, [86]=698, [87]=1111, [88]=656, [89]=635, [90]=651, [91]=318, [92]=335, [93]=318, [94]=576, [95]=500, [96]=600, [97]=590, [98]=678, [99]=563, [100]=678, [101]=604, [102]=339, [103]=685, [104]=676, [105]=269, [106]=274, [107]=601, [108]=269, [109]=1061, [110]=676, [111]=627, [112]=678, [113]=678, [114]=401, [115]=488, [116]=406, [117]=672, [118]=542, [119]=879, [120]=534, [121]=542, [122]=511, [123]=334, [124]=294, [125]=334, [126]=575, [177]=575, [183]=252, [215]=575, [8211]=500, [8212]=1000, [8217]=212, [8220]=382, [8221]=382, [8226]=295, [8230]=647, [8722]=575 }
TNUM[400] = 700
ADV[500] = { [32]=269, [33]=268, [34]=391, [35]=703, [36]=621, [37]=843, [38]=686, [39]=210, [40]=337, [41]=338, [42]=400, [43]=582, [44]=227, [45]=383, [46]=227, [47]=352, [48]=667, [49]=370, [50]=574, [51]=572, [52]=669, [53]=574, [54]=617, [55]=598, [56]=644, [57]=617, [58]=227, [59]=227, [60]=582, [61]=582, [62]=582, [63]=573, [64]=1034, [65]=732, [66]=757, [67]=723, [68]=826, [69]=670, [70]=635, [71]=772, [72]=812, [73]=310, [74]=513, [75]=719, [76]=594, [77]=955, [78]=812, [79]=840, [80]=722, [81]=840, [82]=727, [83]=621, [84]=587, [85]=791, [86]=712, [87]=1126, [88]=673, [89]=647, [90]=657, [91]=333, [92]=352, [93]=333, [94]=583, [95]=500, [96]=600, [97]=598, [98]=682, [99]=571, [100]=682, [101]=612, [102]=353, [103]=690, [104]=681, [105]=279, [106]=284, [107]=616, [108]=279, [109]=1057, [110]=681, [111]=635, [112]=682, [113]=682, [114]=410, [115]=501, [116]=414, [117]=677, [118]=559, [119]=899, [120]=552, [121]=559, [122]=521, [123]=351, [124]=299, [125]=351, [126]=582, [177]=582, [183]=267, [215]=582, [8211]=500, [8212]=1000, [8217]=227, [8220]=416, [8221]=416, [8226]=314, [8230]=691, [8722]=582 }
TNUM[500] = 700
ADV[600] = { [32]=276, [33]=278, [34]=414, [35]=712, [36]=630, [37]=860, [38]=707, [39]=220, [40]=347, [41]=348, [42]=417, [43]=590, [44]=244, [45]=384, [46]=244, [47]=372, [48]=673, [49]=381, [50]=582, [51]=582, [52]=679, [53]=584, [54]=627, [55]=609, [56]=652, [57]=627, [58]=244, [59]=244, [60]=590, [61]=590, [62]=590, [63]=581, [64]=1034, [65]=749, [66]=761, [67]=728, [68]=826, [69]=670, [70]=637, [71]=772, [72]=810, [73]=319, [74]=527, [75]=730, [76]=599, [77]=955, [78]=810, [79]=842, [80]=727, [81]=842, [82]=731, [83]=630, [84]=602, [85]=790, [86]=729, [87]=1144, [88]=694, [89]=662, [90]=664, [91]=350, [92]=372, [93]=350, [94]=592, [95]=500, [96]=600, [97]=608, [98]=686, [99]=581, [100]=687, [101]=622, [102]=370, [103]=695, [104]=686, [105]=290, [106]=296, [107]=638, [108]=290, [109]=1053, [110]=686, [111]=645, [112]=686, [113]=686, [114]=420, [115]=516, [116]=424, [117]=682, [118]=578, [119]=918, [120]=574, [121]=578, [122]=532, [123]=371, [124]=304, [125]=371, [126]=590, [177]=590, [183]=284, [215]=590, [8211]=500, [8212]=1000, [8217]=244, [8220]=457, [8221]=457, [8226]=336, [8230]=744, [8722]=590 }
TNUM[600] = 700
ADV[700] = { [32]=283, [33]=289, [34]=437, [35]=720, [36]=638, [37]=877, [38]=728, [39]=230, [40]=357, [41]=358, [42]=434, [43]=599, [44]=262, [45]=386, [46]=262, [47]=392, [48]=679, [49]=392, [50]=590, [51]=592, [52]=689, [53]=595, [54]=637, [55]=620, [56]=660, [57]=637, [58]=262, [59]=262, [60]=599, [61]=599, [62]=599, [63]=589, [64]=1035, [65]=766, [66]=765, [67]=733, [68]=826, [69]=671, [70]=639, [71]=771, [72]=808, [73]=328, [74]=541, [75]=740, [76]=604, [77]=955, [78]=808, [79]=844, [80]=732, [81]=844, [82]=735, [83]=638, [84]=618, [85]=788, [86]=746, [87]=1163, [88]=714, [89]=676, [90]=671, [91]=368, [92]=392, [93]=368, [94]=600, [95]=500, [96]=600, [97]=617, [98]=690, [99]=591, [100]=692, [101]=631, [102]=387, [103]=700, [104]=691, [105]=301, [106]=307, [107]=660, [108]=301, [109]=1049, [110]=691, [111]=655, [112]=690, [113]=690, [114]=431, [115]=531, [116]=435, [117]=687, [118]=598, [119]=937, [120]=595, [121]=598, [122]=543, [123]=391, [124]=309, [125]=391, [126]=599, [177]=599, [183]=302, [215]=599, [8211]=500, [8212]=1000, [8217]=262, [8220]=498, [8221]=498, [8226]=358, [8230]=798, [8722]=599 }
TNUM[700] = 700
ADV[800] = { [32]=292, [33]=302, [34]=463, [35]=730, [36]=648, [37]=897, [38]=752, [39]=242, [40]=369, [41]=370, [42]=454, [43]=610, [44]=283, [45]=388, [46]=283, [47]=416, [48]=686, [49]=405, [50]=599, [51]=603, [52]=700, [53]=607, [54]=649, [55]=632, [56]=669, [57]=649, [58]=283, [59]=283, [60]=610, [61]=610, [62]=610, [63]=598, [64]=1036, [65]=786, [66]=769, [67]=738, [68]=826, [69]=672, [70]=642, [71]=770, [72]=806, [73]=339, [74]=558, [75]=752, [76]=610, [77]=954, [78]=806, [79]=846, [80]=738, [81]=846, [82]=740, [83]=648, [84]=636, [85]=786, [86]=766, [87]=1184, [88]=738, [89]=693, [90]=679, [91]=389, [92]=416, [93]=389, [94]=610, [95]=500, [96]=600, [97]=628, [98]=695, [99]=603, [100]=698, [101]=642, [102]=406, [103]=706, [104]=696, [105]=314, [106]=320, [107]=686, [108]=314, [109]=1044, [110]=696, [111]=666, [112]=695, [113]=695, [114]=444, [115]=548, [116]=448, [117]=692, [118]=621, [119]=957, [120]=620, [121]=621, [122]=556, [123]=414, [124]=314, [125]=414, [126]=610, [177]=610, [183]=323, [215]=610, [8211]=500, [8212]=1000, [8217]=283, [8220]=546, [8221]=546, [8226]=384, [8230]=860, [8722]=610 }
TNUM[800] = 700
ADV[900] = { [32]=300, [33]=314, [34]=489, [35]=740, [36]=657, [37]=917, [38]=777, [39]=254, [40]=381, [41]=381, [42]=473, [43]=620, [44]=304, [45]=390, [46]=304, [47]=440, [48]=692, [49]=418, [50]=608, [51]=614, [52]=712, [53]=619, [54]=661, [55]=645, [56]=678, [57]=661, [58]=304, [59]=304, [60]=620, [61]=620, [62]=620, [63]=606, [64]=1037, [65]=806, [66]=773, [67]=744, [68]=826, [69]=673, [70]=644, [71]=769, [72]=804, [73]=350, [74]=574, [75]=765, [76]=617, [77]=954, [78]=804, [79]=848, [80]=743, [81]=848, [82]=745, [83]=657, [84]=654, [85]=784, [86]=786, [87]=1206, [88]=762, [89]=710, [90]=687, [91]=410, [92]=440, [93]=410, [94]=620, [95]=500, [96]=600, [97]=639, [98]=700, [99]=615, [100]=705, [101]=653, [102]=426, [103]=711, [104]=702, [105]=326, [106]=334, [107]=713, [108]=326, [109]=1040, [110]=702, [111]=678, [112]=700, [113]=700, [114]=456, [115]=565, [116]=460, [117]=698, [118]=644, [119]=977, [120]=645, [121]=644, [122]=570, [123]=438, [124]=320, [125]=438, [126]=620, [177]=620, [183]=344, [215]=620, [8211]=500, [8212]=1000, [8217]=304, [8220]=594, [8221]=594, [8226]=410, [8230]=922, [8722]=620 }
TNUM[900] = 700
-- END GENERATED METRICS --

-- Pair kerning (tools/uikit/make_kern.py -> UIKern.luau): Godot shaped letter-spaced text with the
-- font's kerning (HarfBuzz), so the per-glyph renderer applies the same pairs ("MULTIPLAYER": L|T).
local KERN_SRC: any = require("./UIKern")
local KERN: { [number]: { [number]: number } } = {}

local function kern_table(weight: number): { [number]: number }
	local w = math.clamp(weight, 400, 900)
	local t = KERN[w]
	if t ~= nil then
		return t
	end
	t = {}
	local src = if type(KERN_SRC) == "table" then KERN_SRC[w] else nil
	if type(src) == "string" then
		for i = 1, #src - 5, 6 do
			local a, b = string.byte(src, i, i + 1)
			local v = tonumber(string.sub(src, i + 2, i + 5))
			if v ~= nil then
				t[a * 128 + b] = v
			end
		end
	end
	KERN[w] = t
	return t
end

--- Pair kerning between code points `a` and `b` in em/1000 at `weight` (0 when none).
function UITheme.kern(a: number, b: number, weight: number?): number
	if a < 32 or a > 127 or b < 32 or b > 127 then
		return 0
	end
	return kern_table(snap_weight(weight))[a * 128 + b] or 0
end

--- Exact width (em/1000 sum, tabular digits optional) from the font's own advances, or nil when a
--- character is not in the table. Proportional text includes the font's pair kerning (tabular
--- templates do not: fixed-width number boxes, like the original's tnum shaping).
local function table_width(text: string, weight: number, tabular: boolean?): number?
	local adv = ADV[math.clamp(weight, 400, 900)]
	if adv == nil then
		return nil
	end
	local tn = TNUM[math.clamp(weight, 400, 900)]
	local kt = if tabular then nil else kern_table(weight)
	local t = 0
	local prev = -1
	for _, cp in utf8.codes(text) do
		if tabular and cp >= 48 and cp <= 57 then
			t += tn
		else
			local a = adv[cp]
			if a == nil then
				return nil
			end
			t += a
		end
		if kt ~= nil and prev >= 32 and prev < 128 and cp < 128 then
			t += kt[prev * 128 + cp] or 0
		end
		prev = cp
	end
	return t
end

local _measure_label: any = nil
local _fonts_ready = false
local _cache: { [string]: number } = {}
local _cache_n = 0

local function measure_label(): any
	if _measure_label ~= nil or not IS_ROBLOX then
		return _measure_label
	end
	local holder = Instance.new("ScreenGui")
	holder.Name = "AirfrontTextMeasure"
	holder.Enabled = false
	holder.ResetOnSpawn = false
	local l = Instance.new("TextLabel")
	l.Name = "Measure"
	l.Visible = false
	l.TextWrapped = false
	l.RichText = false
	l.Size = UDim2.fromOffset(100000, 100000)
	l.Parent = holder
	local ok, pg = pcall(function()
		local lp = game:GetService("Players").LocalPlayer
		return if lp ~= nil then lp:FindFirstChildOfClass("PlayerGui") else nil
	end)
	holder.Parent = if ok and pg ~= nil then pg else game:GetService("StarterGui")
	_measure_label = l
	return l
end

--- Load the Montserrat weights (yields). Call once at startup before building UI; afterwards all text
--- metrics are exact and synchronous.
-- Width of "0" at TextSize 100 per weight when Rubik is really loaded (Roblox falls back to
-- another font's metrics until it is): used to verify the load.
local PROBE_0 = { [400] = 54.3, [500] = 54.7, [600] = 55.2, [700] = 55.7, [800] = 56.3, [900] = 56.8 }
local _init_running = false

--- Fired once the Rubik weights are loaded and text metrics become exact (Widgets re-lays out
--- every tree then). UITheme.init() may be called by the app at startup (recommended: it yields
--- ~1-2 s once); if it is not, the kit starts it in the background on the first measurement and
--- uses approximate metrics until it completes -- never caching them.
UITheme.fonts_loaded = nil :: any

local function probe_ok(): boolean
	local l = measure_label()
	if l == nil then
		return false
	end
	for w, want in pairs(PROBE_0) do
		l.FontFace = UITheme.font(w)
		l.TextSize = 100
		l.TextWrapped = false
		l.Size = UDim2.fromOffset(1000000, 100000)
		l.Text = "0"
		if math.abs(l.TextBounds.X - want) > 2 then
			return false
		end
	end
	return true
end

--- Load the Montserrat weights (yields). Afterwards all text metrics are exact and synchronous.
function UITheme.init()
	if _fonts_ready or not IS_ROBLOX then
		return
	end
	if _init_running then
		while _init_running do
			task.wait()
		end
		return
	end
	_init_running = true
	local TS = game:GetService("TextService")
	for attempt = 1, 20 do
		for _, w in ipairs({ 400, 500, 600, 700, 800, 900 }) do
			local p = Instance.new("GetTextBoundsParams")
			p.Text = "0"
			p.Font = UITheme.font(w)
			p.Size = 20
			pcall(function()
				TS:GetTextBoundsAsync(p)
			end)
		end
		measure_label()
		if probe_ok() then
			break
		end
		if attempt == 20 and IS_ROBLOX and game:GetService("RunService"):IsStudio() then
			-- (live: a slow font download, nothing to act on — it filled the error report)
			warn("[UITheme] Montserrat metrics could not be verified; text layout may be approximate")
		end
		task.wait(0.25)
	end
	_fonts_ready = true
	_init_running = false
	table.clear(_cache)
	_cache_n = 0
	if UITheme.fonts_loaded ~= nil then
		UITheme.fonts_loaded:Fire()
	end
end

function UITheme.fonts_ready(): boolean
	return _fonts_ready
end

--- Raw width in render px of `text` at Roblox TextSize `ts` and `weight` (kerning included).
UITheme.REF_TS = 100

--- Width of `text` at Roblox TextSize REF_TS (100) in `weight`, kerning included (cached). Large
--- sizes are free of the small-size advance rounding, so scaling this down gives the font's true
--- (Godot-like, fractional) advances.
function UITheme.measure_ref(text: string, weight: number): number
	if text == "" then
		return 0
	end
	local w = snap_weight(weight)
	local key = w .. "|" .. text
	local v = _cache[key]
	if v ~= nil then
		return v
	end
	local l = if _fonts_ready then measure_label() else nil
	if l ~= nil then
		l.FontFace = UITheme.font(w)
		l.TextSize = UITheme.REF_TS
		l.TextWrapped = false
		l.Size = UDim2.fromOffset(1000000, 100000)
		-- Roblox sometimes returns a stale TextBounds (e.g. a trailing "r" missing) when the text
		-- changes from a prefix of itself; clearing it first always gives the right value.
		l.Text = ""
		l.Text = text
		v = l.TextBounds.X
	else
		-- fonts not loaded yet: approximate, do not cache, load in the background
		if IS_ROBLOX and not _init_running then
			task.spawn(UITheme.init)
		end
		return approx_width(text, UITheme.REF_TS / UITheme.LINE_EM, w)
	end
	if _cache_n > 4000 then
		table.clear(_cache)
		_cache_n = 0
	end
	_cache[key] = v
	_cache_n += 1
	return v :: number
end

--- Width in render px of `text` at Roblox TextSize `ts` (true advances, see measure_ref).
function UITheme.measure_px(text: string, ts: number, weight: number): number
	return UITheme.measure_ref(text, weight) * ts / UITheme.REF_TS
end

--- Height in logical px of `text` wrapped at `width` logical px (autowrap labels).
function UITheme.wrapped_height(text: string, size: number, weight: number, width: number): number
	return UITheme.line_height(size) * UITheme.wrapped_lines(text, size, weight, width)
end

--- Number of lines `text` takes when word-wrapped at `width` logical px.
function UITheme.wrapped_lines(text: string, size: number, weight: number, width: number): number
	local ts = UITheme.text_size(size)
	local s = UITheme.scale
	if text == "" then
		return 1
	end
	local l = if _fonts_ready then measure_label() else nil
	if l == nil then
		local w = approx_width(text, ts / UITheme.LINE_EM, snap_weight(weight)) / s
		return math.max(1, math.ceil(w / math.max(width, 1)))
	end
	local key = "wrap|" .. snap_weight(weight) .. "|" .. ts .. "|" .. math.floor(width * s) .. "|" .. text
	local v = _cache[key]
	if v == nil then
		l.FontFace = UITheme.font(weight)
		l.TextSize = ts
		l.TextWrapped = true
		l.Size = UDim2.fromOffset(math.max(1, math.floor(width * s)), 100000)
		l.Text = ""
		l.Text = text
		v = math.max(1, math.floor(l.TextBounds.Y / ts + 0.5))
		l.TextWrapped = false
		_cache[key] = v
		_cache_n += 1
	end
	return v :: number
end

--- Width in logical px of `text` rendered like a kit Label: Rubik at `size` / `weight`, `spacing`
--- px after every glyph, `tabular` digits (each digit as wide as "0", no kerning).
function UITheme.measure_text(text: string, size: number, weight: number?, spacing: number?, tabular: boolean?): number
	local w = weight or 500
	-- design-space em: layout widths do not depend on the render scale / TextSize rounding
	local k = size * UITheme.LINE_EM / UITheme.REF_TS
	local px
	-- Tabular templates ("888.8M"): the font's own advances + the tnum width (exact, what Godot's
	-- tnum shaping gives; no kerning applies between figures). Other text: Roblox's kerned width
	-- at TextSize 100, scaled (kerning like HarfBuzz); the table when fonts are not loaded / Lune.
	-- (letter-spaced text renders per glyph from the same table, so it measures from it too)
	local exact = if tabular
			or (spacing or 0) ~= 0
			or not _fonts_ready
		then table_width(text, snap_weight(w), tabular)
		else nil
	if exact ~= nil then
		px = exact / 1000 * size
	elseif tabular then
		local dw = UITheme.measure_ref("0", w) * UITheme.TNUM_RATIO
		px = 0
		for _, cp in utf8.codes(text) do
			if cp >= 48 and cp <= 57 then
				px += dw
			else
				px += UITheme.measure_ref(utf8.char(cp), w)
			end
		end
		px *= k
	else
		px = UITheme.measure_ref(text, w) * k
	end
	local sp = spacing or 0
	if sp ~= 0 then
		px += sp * math.max(0, utf8.len(text) or 0)
	end
	return math.ceil(px - 0.01)
end

--- Advance in render px of one character at Roblox TextSize `ts` (the font's own advances;
--- `tabular` digits take the tnum width). Used for tabular glyph layout.
function UITheme.char_adv_px(ch: string, ts: number, weight: number, tabular: boolean?): number
	local w = snap_weight(weight)
	local em = ts / UITheme.LINE_EM
	local cp = utf8.codepoint(ch)
	if tabular and cp >= 48 and cp <= 57 then
		local tn = TNUM[math.clamp(w, 400, 900)]
		if tn then
			return tn / 1000 * em
		end
	end
	local adv = ADV[math.clamp(w, 400, 900)]
	local a = adv and adv[cp]
	if a then
		return a / 1000 * em
	end
	return UITheme.measure_px(ch, ts, w)
end

--- GDScript text_width(template, size, weight = 700): width in logical px of `template` in Rubik
--- with tabular digits (templates like "888.8M" size fixed-width number boxes).
function UITheme.text_width(template: string, size: number, weight: number?, spacing: number?): number
	return UITheme.measure_text(template, size, weight or 700, spacing, true)
end

--- Pen positions (render px, fractional) of every glyph of `text` at TextSize `ts`: {x0, x1, ...}
--- (1-based, one per UTF-8 character) and the total advance. From the font's own advances plus its
--- pair kerning, like HarfBuzz shaped the original (Roblox's TextBounds of prefixes is not reliable).
function UITheme.glyph_positions(text: string, ts: number, weight: number): ({ number }, number)
	local xs = {}
	local x = 0
	local em = ts / UITheme.LINE_EM
	local kt = kern_table(snap_weight(weight))
	local prev = -1
	for _, cp in utf8.codes(text) do
		if prev >= 32 and prev < 128 and cp < 128 then
			local k = kt[prev * 128 + cp]
			if k ~= nil then
				x += k / 1000 * em
			end
		end
		table.insert(xs, x)
		x += UITheme.char_adv_px(utf8.char(cp), ts, weight, false)
		prev = cp
	end
	return xs, x
end

-- =============================================================================================
-- Scale
-- =============================================================================================

UITheme.DESIGN_W = 1600
UITheme.DESIGN_H = 900

--- UI scale for a viewport (render px). The original laid the HUD out in logical px on a 1600x900
--- design (Airship desktop); desktop screens scale that design to fit (1920x1080 -> 1.2,
--- 1366x768 -> 0.853, clamped to [0.75, 2.5]). Touch devices (phones / tablets) keep 1:1 points
--- like the original (so the phone layout rules apply) and only scale up on very large screens.
function UITheme.ui_scale(viewport: Vector2, touch_device: boolean?): number
	local s = math.min(viewport.X / UITheme.DESIGN_W, viewport.Y / UITheme.DESIGN_H)
	if touch_device then
		return math.clamp(s, 1.0, 2.0)
	end
	return math.clamp(s, 0.75, 2.5)
end

function UITheme.set_scale(s: number)
	UITheme.scale = s
end

-- =============================================================================================
-- Icons
-- =============================================================================================

local _icons: any = nil

--- Asset id of a white UI glyph (assets/icons/ui, assets/ui, "hud_*", "app_icon"), or nil when
--- the assets manifest does not have it (callers degrade gracefully: no icon).
--- Icons every Roblox client ships (rbxasset textures, white: tint with ImageColor3).
UITheme.BUILTIN_ICONS = {
	robux = "rbxasset://textures/ui/common/robux@3x.png",
}

local _crate_art: any = nil
--- The cosmetic crate's 2D art (white masks, tinted by the screens; the chest itself is 3D, ChestView): all of it made on
--- the device by UI/SoftArt and our glyphs, each an ArtRef made on first use.
function UITheme.crate_art(): any
	if _crate_art == nil then
		local names = { glow = "title_glow", rays = "crate_rays", ring = "crate_ring", flare = "crate_flare", sparkle = "crate_sparkle", streak = "crate_streak", beam = "crate_beam" }
		local soft: any = nil
		_crate_art = setmetatable({}, {
			__index = function(_, key)
				if key == "icon" then
					return UITheme.icon("crate")
				end
				local n = names[key]
				if n == nil then
					return nil
				end
				if soft == nil then
					soft = if IS_ROBLOX then require((script :: any).Parent:WaitForChild("SoftArt")).shapes() else (require :: any)("./SoftArt").shapes()
				end
				return soft[n]
			end,
		})
	end
	return _crate_art
end

local _atlas: any = nil
local function atlas(): any
	if _atlas == nil then
		_atlas = if IS_ROBLOX
			then require((script :: any).Parent:WaitForChild("ArtAtlas"))
			else (require :: any)("./ArtAtlas")
	end
	return _atlas
end

--- Puts an image (an ArtRef from `icon`, a legacy string id, or nil) on an ImageLabel.
function UITheme.set_image(label: any, ref: any)
	atlas().apply(label, ref)
end

--- `inst[key] = value`, except that an image key holding an ArtRef goes through the atlas.
function UITheme.assign(inst: any, key: string, value: any)
	if key == "Image" and type(value) == "table" and value.art == true then
		atlas().apply(inst, value)
	else
		inst[key] = value
	end
end

--- A glyph by name: OUR art (an ArtRef: Art/IconData through the atlas), or a string for the few Roblox
--- builds in (robux), or nil (callers degrade to no icon).
function UITheme.icon(icon_name: string): any?
	local builtin = UITheme.BUILTIN_ICONS[icon_name]
	if builtin ~= nil then
		return builtin
	end
	local ours = atlas().icon(icon_name)
	if ours ~= nil then
		return ours
	end
	return nil -- (the upstream's icon modules are no longer read: every glyph is ours)
end

-- =============================================================================================
-- Colours by meaning
-- =============================================================================================

function UITheme.msg_color(category: number): Color3
	local D = Defs()
	local good, bad, alert, alliance = 1, 2, 3, 4
	if D then
		good, bad, alert, alliance = D.MSG_GOOD, D.MSG_BAD, D.MSG_ALERT, D.MSG_ALLIANCE
	end
	if category == good then
		return UITheme.GREEN
	elseif category == bad then
		return UITheme.ORANGE
	elseif category == alert then
		return UITheme.RED
	elseif category == alliance then
		return UITheme.VIOLET
	end
	return UITheme.CYAN
end

function UITheme.msg_icon(category: number): string
	local D = Defs()
	local good, bad, alert, alliance = 1, 2, 3, 4
	if D then
		good, bad, alert, alliance = D.MSG_GOOD, D.MSG_BAD, D.MSG_ALERT, D.MSG_ALLIANCE
	end
	if category == good then
		return "crown"
	elseif category == bad then
		return "attack"
	elseif category == alert then
		return "target"
	elseif category == alliance then
		return "alliance"
	end
	return "info"
end

--- A readable UI variant of a nation colour (lifted when very dark). Accepts Color3 / RGBA8 int.
function UITheme.owner_ui_color(col: any): Color3
	local c = UITheme.color3(col)
	local l = UITheme.luminance(c)
	if l < 0.32 then
		return UITheme.lerp(c, UITheme.WHITE, 0.32 - l + 0.1)
	end
	return c
end

-- =============================================================================================
-- Style factories (StyleBoxFlat equivalents, drawn by Widgets)
-- =============================================================================================

export type Style = {
	kind: string, -- "flat" | "empty"
	bg: RGBA,
	radius: number,
	border: RGBA,
	bw: number,
	bw_bottom: number?, -- extra bottom border ("lip")
	mh: number,
	mv: number,
	margin: { number }?, -- explicit content margins {left, top, right, bottom}
	draw_center: boolean,
	shadow: { size: number, alpha: number, offset_y: number }?,
}

function UITheme.flat(bg: any, radius: number?, border: any?, bw: number?, mh: number?, mv: number?): Style
	return {
		kind = "flat",
		bg = UITheme.to_rgba(bg),
		radius = radius or UITheme.R_MD,
		border = if border ~= nil then UITheme.to_rgba(border) else UITheme.CLEAR,
		bw = bw or 0,
		mh = mh or 0,
		mv = mv or 0,
		draw_center = true,
	}
end

function UITheme.empty_box(mh: number?, mv: number?): Style
	return {
		kind = "empty",
		bg = UITheme.CLEAR,
		radius = 0,
		border = UITheme.CLEAR,
		bw = 0,
		mh = mh or 0,
		mv = mv or 0,
		draw_center = false,
	}
end

function UITheme.shadow_box(radius: number, size: number?, alpha: number?, offset_y: number?): Style
	local s = UITheme.empty_box()
	s.kind = "flat"
	s.radius = radius
	s.shadow = { size = size or 18, alpha = alpha or 0.45, offset_y = offset_y or 6.0 }
	return s
end

--- Copy of a style (StyleBoxFlat.duplicate()).
function UITheme.dup(s: Style): Style
	local t = table.clone(s) :: any
	if s.margin then
		t.margin = table.clone(s.margin)
	end
	if s.shadow then
		t.shadow = table.clone(s.shadow)
	end
	return t
end

--- Content margins of a style: left, top, right, bottom.
function UITheme.margins(s: Style?): (number, number, number, number)
	if s == nil then
		return 0, 0, 0, 0
	end
	if s.margin then
		return s.margin[1], s.margin[2], s.margin[3], s.margin[4]
	end
	return s.mh, s.mv, s.mh, s.mv
end

-- =============================================================================================
-- Theme (button variations: normal / hover / pressed / hover_pressed / disabled styles + colours)
-- =============================================================================================

local _theme: any = nil

local function button_styles(
	t: any,
	typ: string,
	n: any,
	h: any,
	p: any,
	border: any,
	border_h: any,
	fg: Color3,
	weight: number,
	radius: number?,
	mh: number?
)
	local r = radius or UITheme.R_MD
	local m = mh or 16.0
	local nb, hb = UITheme.to_rgba(border), UITheme.to_rgba(border_h)
	local na = UITheme.to_rgba(n)
	local v = {
		styles = {
			normal = UITheme.flat(n, r, nb, if nb.alpha > 0 then 1 else 0, m, 8.0),
			hover = UITheme.flat(h, r, hb, if hb.alpha > 0 then 1 else 0, m, 8.0),
			pressed = UITheme.flat(p, r, hb, if hb.alpha > 0 then 1 else 0, m, 8.0),
			hover_pressed = UITheme.flat(p, r, hb, if hb.alpha > 0 then 1 else 0, m, 8.0),
			disabled = UITheme.flat(
				UITheme.c(na.color, na.alpha * 0.5),
				r,
				UITheme.c(nb.color, nb.alpha * 0.5),
				if nb.alpha > 0 then 1 else 0,
				m,
				8.0
			),
		},
		colors = {
			font_color = fg,
			font_hover_color = UITheme.TEXT,
			font_pressed_color = UITheme.TEXT,
			font_hover_pressed_color = UITheme.TEXT,
			font_disabled_color = UITheme.c(fg, 0.35),
			icon_normal_color = fg,
			icon_hover_color = UITheme.TEXT,
			icon_pressed_color = UITheme.TEXT,
			icon_hover_pressed_color = UITheme.TEXT,
			icon_disabled_color = UITheme.c(fg, 0.35),
		},
		font_weight = weight,
		font_spacing = 1,
		font_size = 15,
		h_separation = 10,
	}
	t[typ] = v
	return v
end

--- Button variations (GDScript theme(): PrimaryButton, GlassButton, GhostButton, DangerButton,
--- ChipButton; "Button" = glass look).
function UITheme.theme(): any
	if _theme ~= nil then
		return _theme
	end
	local t = {}
	button_styles(
		t,
		"Button",
		UITheme.FILL,
		UITheme.FILL_2,
		UITheme.rgba(1, 1, 1, 0.03),
		UITheme.LINE,
		UITheme.LINE_2,
		UITheme.TEXT,
		600
	)
	button_styles(
		t,
		"GlassButton",
		UITheme.FILL,
		UITheme.FILL_2,
		UITheme.rgba(1, 1, 1, 0.03),
		UITheme.LINE,
		UITheme.LINE_2,
		UITheme.TEXT,
		600
	)
	-- the next public match (title): glass with a cyan accent so it stands out next to Play Solo
	button_styles(
		t,
		"PublicButton",
		UITheme.c(UITheme.CYAN, 0.1),
		UITheme.c(UITheme.CYAN, 0.18),
		UITheme.c(UITheme.CYAN, 0.06),
		UITheme.c(UITheme.CYAN, 0.55),
		UITheme.c(UITheme.CYAN, 0.9),
		UITheme.TEXT,
		600
	)
	local ghost = button_styles(
		t,
		"GhostButton",
		UITheme.rgba(1, 1, 1, 0.0),
		UITheme.FILL,
		UITheme.rgba(1, 1, 1, 0.03),
		UITheme.CLEAR,
		UITheme.CLEAR,
		UITheme.TEXT_2,
		600
	)
	ghost.colors.font_hover_color = UITheme.TEXT
	ghost.colors.icon_hover_color = UITheme.TEXT
	button_styles(
		t,
		"DangerButton",
		UITheme.c(UITheme.RED, 0.14),
		UITheme.c(UITheme.RED, 0.26),
		UITheme.c(UITheme.RED, 0.08),
		UITheme.c(UITheme.RED, 0.45),
		UITheme.c(UITheme.RED, 0.8),
		Color3.new(1.0, 0.78, 0.8),
		700
	)
	local chip = button_styles(
		t,
		"ChipButton",
		UITheme.rgba(1, 1, 1, 0.04),
		UITheme.FILL_2,
		UITheme.c(UITheme.AMBER, 0.2),
		UITheme.LINE,
		UITheme.LINE_2,
		UITheme.TEXT_2,
		600,
		999,
		14.0
	)
	chip.styles.hover_pressed = UITheme.flat(UITheme.c(UITheme.AMBER, 0.26), 999, UITheme.AMBER, 1, 14.0, 6.0)
	chip.styles.pressed = UITheme.flat(UITheme.c(UITheme.AMBER, 0.2), 999, UITheme.c(UITheme.AMBER, 0.9), 1, 14.0, 6.0)
	chip.colors.font_pressed_color = UITheme.AMBER_HI
	chip.colors.font_hover_pressed_color = UITheme.AMBER_HI
	chip.font_size = 13

	-- Primary: warm amber with a darker lip.
	local pn = UITheme.flat(UITheme.AMBER, UITheme.R_MD, UITheme.CLEAR, 0, 22.0, 10.0)
	pn.bw_bottom = 3
	pn.border = UITheme.to_rgba(UITheme.AMBER_LO)
	local ph = UITheme.dup(pn)
	ph.bg = UITheme.to_rgba(UITheme.AMBER_HI)
	local pp =
		UITheme.flat(UITheme.lerp(UITheme.AMBER_LO, UITheme.AMBER, 0.5), UITheme.R_MD, UITheme.CLEAR, 0, 22.0, 10.0)
	pp.margin = { 22.0, 12.0, 22.0, 8.0 }
	local pd = UITheme.flat(UITheme.rgba(1, 1, 1, 0.08), UITheme.R_MD, UITheme.LINE, 1, 22.0, 10.0)
	t.PrimaryButton = {
		styles = { normal = pn, hover = ph, pressed = pp, hover_pressed = pp, disabled = pd },
		colors = {
			font_color = UITheme.INK,
			font_hover_color = UITheme.INK,
			font_pressed_color = UITheme.INK,
			font_hover_pressed_color = UITheme.INK,
			font_disabled_color = UITheme.TEXT_3,
			icon_normal_color = UITheme.INK,
			icon_hover_color = UITheme.INK,
			icon_pressed_color = UITheme.INK,
			icon_hover_pressed_color = UITheme.INK,
			icon_disabled_color = UITheme.INK,
		},
		font_weight = 800,
		font_spacing = 2,
		font_size = 17,
		h_separation = 10,
	}
	-- Surrender: solid red with a darker lip, shaped like Primary (the game menu's SURRENDER, made big and
	-- red on 2026-10-19). DangerButton is only a red tint.
	local sn = UITheme.flat(UITheme.SURRENDER_RED, UITheme.R_MD, UITheme.CLEAR, 0, 22.0, 10.0)
	sn.bw_bottom = 3
	sn.border = UITheme.to_rgba(UITheme.SURRENDER_RED_LO)
	local sh = UITheme.dup(sn)
	sh.bg = UITheme.to_rgba(UITheme.SURRENDER_RED_HI)
	local sp = UITheme.flat(
		UITheme.lerp(UITheme.SURRENDER_RED_LO, UITheme.SURRENDER_RED, 0.5),
		UITheme.R_MD,
		UITheme.CLEAR,
		0,
		22.0,
		10.0
	)
	sp.margin = { 22.0, 12.0, 22.0, 8.0 }
	local white = Color3.new(1, 1, 1)
	t.SurrenderButton = {
		styles = { normal = sn, hover = sh, pressed = sp, hover_pressed = sp, disabled = pd },
		colors = {
			font_color = white,
			font_hover_color = white,
			font_pressed_color = white,
			font_hover_pressed_color = white,
			font_disabled_color = UITheme.TEXT_3,
			icon_normal_color = white,
			icon_hover_color = white,
			icon_pressed_color = white,
			icon_hover_pressed_color = white,
			icon_disabled_color = UITheme.TEXT_3,
		},
		font_weight = 800,
		font_spacing = 2,
		font_size = 17,
		h_separation = 10,
	}
	_theme = t
	return t
end

-- =============================================================================================
-- Widget helpers (return Widgets nodes; see Widgets.luau)
-- =============================================================================================

local _W: any = nil
local function W(): any
	if _W == nil then
		_W = require("./Widgets") :: any
	end
	return _W
end

function UITheme.label(text: string, size: number?, weight: number?, color: any?, spacing: number?): any
	local l = W().Label.new(text)
	l:set_mouse_filter(W().MOUSE_IGNORE)
	UITheme.style_label(l, size or 15, weight or 500, if color ~= nil then color else UITheme.TEXT, spacing or 0)
	return l
end

function UITheme.style_label(l: any, size: number, weight: number?, color: any?, spacing: number?)
	l:set_font(weight or 500, spacing or 0)
	l.base_fs = size
	l:set_font_size(math.max(size, UITheme.min_font_size))
	l:set_color(if color ~= nil then color else UITheme.TEXT)
end

--- Small upper-case caption ("TROOPS", "GOLD"...).
function UITheme.caption(text: string, size: number?, color: any?): any
	return UITheme.label(string.upper(text), size or 11, 700, if color ~= nil then color else UITheme.TEXT_3, 1)
end

--- Only re-applies a colour that really changed (GDScript set_font_color).
function UITheme.set_font_color(c: any, col: any, _prop: string?)
	if c.set_color then
		c:set_color(col)
	end
end

--- Lock a label to a fixed width: it clips instead of growing its container and (tabular) draws
--- digits in equal-width cells so animated numbers do not jitter.
function UITheme.fix_width(l: any, w: number, align: number?, tabular: boolean?)
	local tab = if tabular == nil then true else tabular
	l.clip_text = true
	l.text_overrun_behavior = if tab then W().OVERRUN_NONE else W().OVERRUN_ELLIPSIS
	l:set_min_size(Vector2.new(w, l.custom_minimum_size.Y))
	l.size_flags_horizontal = W().SHRINK_BEGIN
	l.horizontal_alignment = align or W().ALIGN_LEFT
	-- Roblox cannot use Rubik's tabular glyphs (its "1" has a foot there); equal-width digit
	-- cells are only used where numbers roll (CountLabel, clocks: `l.rolling = true`), which
	-- keeps them from jittering; static numbers render proportionally.
	l:set_tabular(tab and l.rolling == true)
	if tab and l.spacing ~= 0 then
		-- GDScript swaps in font(weight, 0, tabular): tabular labels lose their letter spacing
		l:set_font(l.weight, 0)
	end
	l:update_minimum_size()
end

function UITheme.icon_rect(icon_name: string, px: number, color: any?): any
	local r = W().Icon.new(icon_name)
	r:set_min_size(Vector2.new(px, px))
	r:set_color(if color ~= nil then color else UITheme.TEXT)
	r:set_mouse_filter(W().MOUSE_IGNORE)
	return r
end

function UITheme.hbox(sep: number?): any
	local b = W().Box.new(false)
	b.separation = if sep == nil then UITheme.S2 else sep
	b:set_mouse_filter(W().MOUSE_IGNORE)
	return b
end

function UITheme.vbox(sep: number?): any
	local b = W().Box.new(true)
	b.separation = if sep == nil then UITheme.S1 else sep
	b:set_mouse_filter(W().MOUSE_IGNORE)
	return b
end

--- Button in one of the theme variations: PrimaryButton, GlassButton, GhostButton, DangerButton,
--- ChipButton.
function UITheme.button(text: string, variation: string?, icon_name: string?, min_h: number?): any
	local b = W().Button.new(text, variation or "GlassButton")
	b:set_min_size(Vector2.new(0, min_h or 44.0))
	if icon_name ~= nil and icon_name ~= "" then
		b:set_icon(icon_name)
		b.expand_icon = false
		b:add_theme_constant_override("icon_max_width", 20)
	end
	return b
end

--- A thin vertical divider line.
function UITheme.vdivider(h: number?): any
	local d = W().ColorRect.new(UITheme.LINE)
	d:set_min_size(Vector2.new(1.0, h or 36.0))
	d.size_flags_vertical = W().SHRINK_CENTER
	d:set_mouse_filter(W().MOUSE_IGNORE)
	return d
end

function UITheme.hdivider(): any
	local d = W().ColorRect.new(UITheme.LINE)
	d:set_min_size(Vector2.new(0.0, 1.0))
	d:set_mouse_filter(W().MOUSE_IGNORE)
	return d
end

--- Rounded colour swatch (nation colour chip).
function UITheme.swatch(c: any, px: number?, radius: number?): any
	local p = W().Panel.new()
	local s = px or 12.0
	p:set_min_size(Vector2.new(s, s))
	p.size_flags_vertical = W().SHRINK_CENTER
	p:set_mouse_filter(W().MOUSE_IGNORE)
	p:add_theme_stylebox_override("panel", UITheme.flat(c, radius or 3, UITheme.rgba(1, 1, 1, 0.35), 1))
	return p
end

function UITheme.set_swatch_color(p: any, c: any)
	local sb = p:get_theme_stylebox("panel")
	if sb ~= nil and not UITheme.equal(sb.bg, c) then
		local n = UITheme.dup(sb)
		n.bg = UITheme.to_rgba(c)
		p:add_theme_stylebox_override("panel", n)
	end
end

-- =============================================================================================
-- Formatting
-- =============================================================================================

local function round(x: number): number
	return if x >= 0 then math.floor(x + 0.5) else -math.floor(-x + 0.5)
end

local function format_troops(value: number): string
	local D = Defs()
	if D and D.format_troops then
		return D.format_troops(value)
	end
	local v = math.abs(value)
	local s
	if v >= 1000000 then
		s = if v < 10000000 then string.format("%.2fM", v / 1000000) else string.format("%.1fM", v / 1000000)
	elseif v >= 1000 then
		s = if v < 100000 then string.format("%.1fK", v / 1000) else string.format("%dK", math.floor(v / 1000))
	else
		s = tostring(math.floor(v))
	end
	return (if value < 0 then "-" else "") .. s
end

function UITheme.fmt_num(v: number): string
	return format_troops(v)
end

--- Troops as players see them (Core/NumberFormat: render_troops = the internal count / 10, floored
--- like render_number, so a 25,000-troop start reads "2.50K"). Gold and other numbers use fmt_num.
function UITheme.fmt_troops(v: number): string
	return core("NumberFormat").render_troops(v)
end

--- Compact price: 50K, 125K, 1M, 1.5M, 25M.
function UITheme.fmt_cost(v: number): string
	if v >= 1000000 then
		local m = v / 1000000
		return if math.abs(m - round(m)) < 0.05 then string.format("%dM", round(m)) else string.format("%.1fM", m)
	end
	if v >= 1000 then
		local k = v / 1000
		return if (k >= 10 or math.abs(k - round(k)) < 0.05)
			then string.format("%dK", round(k))
			else string.format("%.1fK", k)
	end
	return tostring(math.floor(v))
end

function UITheme.fmt_pct(share: number): string
	local p = share * 100
	if p >= 10 then
		return string.format("%.1f%%", p)
	end
	return if p > 0 and p < 1 then string.format("%.2f%%", p) else string.format("%.1f%%", p)
end

function UITheme.fmt_time(seconds: number): string
	local s = math.max(0, math.floor(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s // 60) % 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

function UITheme.fmt_rate(v: number): string
	if math.abs(v) < 0.5 then
		return "±0/s"
	end
	return (if v > 0 then "+" else "−") .. format_troops(math.abs(v)) .. "/s"
end

return UITheme
