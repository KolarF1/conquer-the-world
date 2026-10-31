--!nonstrict
-- The Dominion strip (Conquer the World's own): the match's arc on the HUD. One line under the status
-- pill's clock and control bar: the era's name, a four-segment timeline (the current era fills as it
-- runs), how long until the next, and the doctrines the player has drafted. It lives INSIDE TopStatus's
-- panel (a second row on a desktop, a roman numeral in the phone's one-line pill), so everything that
-- stacks under the status pill (alerts, the attacks panel, the tutorial card) already makes room for it.
--
--   DominionStrip.model(eras, since_play, picks) -> pure: what the strip shows
--   DominionStrip.new(ctx)       the widget; :refresh() reads ctx.state; .era_changed (Signal: era)
local UITheme = require("./UITheme")
local W = require("./Widgets")
local UICtx = require("./UICtx")
local Signal = UITheme.core("Signal")
local Eras = UICtx.data("Eras")
local Doctrines = UICtx.data("Doctrines")

--- (Not a Control of its own: a plain Control reports no minimum size for its children, so the strip is
--- a table that owns one hbox, `.node`, and TopStatus puts that node in its stack.)
local DominionStrip = {}
DominionStrip.__index = DominionStrip

DominionStrip.ROMAN = { "I", "II", "III", "IV" }
DominionStrip.SEG_W = 34
DominionStrip.SEG_H = 6

--- What the strip shows for a match with era starts `eras`, `since_play` ticks into play, and a
--- player who picked `picks` (doctrine keys): the era, its name, how far through it (0..1), seconds to
--- the next (nil in the last), and the picks' glyphs.
function DominionStrip.model(eras: { number }?, since_play: number, picks: { string }?)
	local starts = eras or Eras.DEFAULT
	local era = Eras.index(since_play, starts)
	local left = Eras.ticks_to_next(since_play, starts)
	local progress = 1.0
	if left ~= nil then
		local span = starts[era + 1] - starts[era]
		progress = math.clamp(1.0 - left / span, 0.0, 1.0)
	end
	local glyphs = {}
	for _, k in picks or {} do
		local d = Doctrines.BY_KEY[k]
		if d ~= nil then
			table.insert(glyphs, d.glyph)
		end
	end
	return {
		era = era,
		name = Eras.NAMES[era],
		roman = DominionStrip.ROMAN[era],
		blurb = Eras.BLURBS[era],
		progress = progress,
		next_s = if left ~= nil then math.ceil(left / 10) else nil,
		next_name = if left ~= nil then Eras.NAMES[era + 1] else nil,
		glyphs = glyphs,
		segments = #starts,
	}
end

function DominionStrip.new(c: any)
	local self = setmetatable({}, DominionStrip)
	local T = UITheme
	self.ctx = c
	self.era_changed = Signal.new()
	self._era = 0
	local row = T.hbox(10)
	self.node = row
	self._name = T.label("DAWN", 12, 800, T.AMBER, 2)
	self._name.size_flags_vertical = W.SHRINK_CENTER
	row:add_child(self._name)
	local segs = T.hbox(3)
	segs.size_flags_vertical = W.SHRINK_CENTER
	self._segs = {}
	for i = 1, #Eras.NAMES do
		local seg = W.ColorRect.new(T.c(T.WHITE, 0.14))
		seg:set_min_size(Vector2.new(DominionStrip.SEG_W, DominionStrip.SEG_H))
		seg:set_mouse_filter(W.MOUSE_IGNORE)
		-- (the current era's fill: a bar inside its segment, sized each refresh)
		local fill = W.ColorRect.new(T.AMBER)
		fill:set_mouse_filter(W.MOUSE_IGNORE)
		fill:set_anchors(0, 0, 0, 1)
		fill:set_offsets(0, 0, 0, 0)
		seg:add_child(fill)
		segs:add_child(seg)
		self._segs[i] = { seg = seg, fill = fill }
	end
	row:add_child(segs)
	self._next = T.label("", 11, 600, T.TEXT_2)
	self._next.size_flags_vertical = W.SHRINK_CENTER
	row:add_child(self._next)
	local sp = W.Control.new()
	sp.size_flags_horizontal = W.EXPAND_FILL
	sp:set_mouse_filter(W.MOUSE_IGNORE)
	row:add_child(sp)
	self._pips = T.hbox(4)
	self._pips.size_flags_vertical = W.SHRINK_CENTER
	self._pip_labels = {}
	for i = 1, Doctrines.TIERS do
		local p = T.label("·", 13, 800, T.TEXT_3)
		self._pips:add_child(p)
		self._pip_labels[i] = p
	end
	row:add_child(self._pips)
	return self
end

--- Fixed widths for the changing texts, so the pill never resizes.
function DominionStrip.fix_widths(self)
	local T = UITheme
	T.fix_width(self._name, T.text_width("RECKONING", 12, 800) + 14.0, W.ALIGN_LEFT, false)
	T.fix_width(self._next, T.text_width("RECKONING 8:88", 11, 600) + 2.0, W.ALIGN_LEFT, false)
end

--- The picks of the local player: doctrine keys in draft order.
function DominionStrip.picks_of(state: any, me: number): { string }
	local out = {}
	local by = if state ~= nil and me ~= 0 then state.doctrine[me] else nil
	if by == nil then
		return out
	end
	for draft = 1, Doctrines.TIERS do
		local row = by[draft]
		if row ~= nil and row[6] >= 1 and row[6] <= Doctrines.OFFER_SIZE then
			table.insert(out, Doctrines.LIST[row[2 + row[6]]].key)
		end
	end
	return out
end

--- True when the match has eras at all (a match without doctrines has none: the strip stays hidden).
function DominionStrip.active(self): boolean
	local s = self.ctx.state
	return s ~= nil and s.eras ~= nil and s.playing_since ~= nil and s.playing_since >= 0
end

function DominionStrip.refresh(self)
	local ctx = self.ctx
	local T = UITheme
	if not self:active() then
		self.node:set_visible(false)
		return
	end
	local s = ctx.state
	local since = ctx:render_tick() - s.playing_since
	local picks = DominionStrip.picks_of(s, ctx:me())
	local m = DominionStrip.model(s.eras, since, picks)
	self.node:set_visible(true)
	self._name:set_text(string.upper(m.name))
	for i, sg in self._segs do
		local done = i < m.era
		local cur = i == m.era
		sg.seg:set_color(T.c(T.WHITE, 0.14))
		sg.fill:set_visible(done or cur)
		sg.fill:set_anchors(0, 0, if done then 1.0 elseif cur then m.progress else 0.0, 1)
		sg.fill:set_offsets(0, 0, 0, 0)
		sg.fill:set_color(if done then T.c(T.AMBER, 0.55) else T.AMBER)
	end
	if m.next_s ~= nil then
		self._next:set_text(string.format("%s %s", string.upper(m.next_name), T.fmt_time(m.next_s)))
	else
		self._next:set_text("FINAL ERA")
	end
	for i, p in self._pip_labels do
		local g = m.glyphs[i]
		p:set_text(g or "·")
		T.set_font_color(p, if g ~= nil then T.GOLD else T.TEXT_3)
	end
	if m.era ~= self._era then
		local first = self._era == 0
		self._era = m.era
		if not first and m.era > 1 then
			self.era_changed:Fire(m.era)
		end
	end
end

--- A new match: forget the era shown.
function DominionStrip.reset(self)
	self._era = 0
end

return DominionStrip
