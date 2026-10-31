--!nonstrict
-- The doctrine draft (Conquer the World's own): when an era opens, three cards, one doctrine to keep.
-- Not a modal: the match keeps running and the map stays clickable around it; "Later" folds it to a
-- DRAFT chip, and a player who never chooses gets the first card when the timer runs out (the Sim
-- decides that, this only counts down). A card shows the doctrine's name, its numbers (what it gives, what
-- it costs) and one line of why.
--
--   DoctrineDraft.new(ctx, ui)
--   :refresh()                         reads ctx.state: the local player's open offer, if any
--   :apply_layout(top_y, bottom_y)     where it may sit (logical px): between the status and the command bar
--   .picked (Signal: key)              a card was chosen (the intent is sent here too)
local UITheme = require("./UITheme")
local W = require("./Widgets")
local GlassPanel = require("./GlassPanel")
local UICtx = require("./UICtx")
local Signal = UITheme.core("Signal")
local Defs = UICtx.core("Defs")
local Doctrines = UICtx.data("Doctrines")
local WorldEvents = UICtx.data("WorldEvents")
local Eras = UICtx.data("Eras")

local DoctrineDraft = W.class(W.Control)

DoctrineDraft.CARD_W = 196
DoctrineDraft.CARD_W_COMPACT = 148

--- The local player's open draft row in `state` ({ id, draft, a, b, c, chosen, deadline }), or nil.
function DoctrineDraft.open_row(state: any, me: number): { number }?
	if state == nil or me == 0 or state.doctrine == nil then
		return nil
	end
	local by = state.doctrine[me]
	if by == nil then
		return nil
	end
	local best: { number }? = nil
	for draft = 1, Doctrines.TIERS do
		local row = by[draft]
		if row ~= nil and row[6] == 0 then
			best = row
		end
	end
	return best
end

--- The text a card prints for a doctrine: its effect lines, gains first.
function DoctrineDraft.card_lines(d: any): { string }
	return Doctrines.effects(d)
end

function DoctrineDraft.new(c: any, ui: any)
	local self = setmetatable({}, DoctrineDraft.__mt)
	W.Control._init(self)
	local T = UITheme
	self.ctx = c
	self.ui = ui
	self.picked = Signal.new()
	self._row = nil :: any
	self._collapsed = false
	self._sent_at = -1.0
	self:set_mouse_filter(W.MOUSE_IGNORE)
	self:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)

	local panel = GlassPanel.new(14.0, 10.0, T.R_LG, true, 18)
	panel:set_tint(T.GLASS_SOLID)
	panel:set_accent(T.AMBER, 3.0)
	panel:set_border(T.c(T.AMBER, 0.45))
	self.panel = panel
	local v = T.vbox(8)
	panel:add_child(v)
	local head = T.hbox(10)
	self._title = T.label("DRAFT", 13, 800, T.AMBER, 2)
	self._title.size_flags_vertical = W.SHRINK_CENTER
	head:add_child(self._title)
	self._timer = T.label("", 12, 600, T.TEXT_2)
	self._timer.size_flags_vertical = W.SHRINK_CENTER
	head:add_child(self._timer)
	local sp = W.Control.new()
	sp.size_flags_horizontal = W.EXPAND_FILL
	sp:set_mouse_filter(W.MOUSE_IGNORE)
	head:add_child(sp)
	self._later = T.button("Later", "GhostButton", "", 30.0)
	self._later:set_font_size(12)
	self._later:set_min_size(Vector2.new(56, 30))
	self._later.pressed:Connect(function()
		self._collapsed = true
		self:_show()
		self.ui:relayout()
	end)
	head:add_child(self._later)
	v:add_child(head)
	self._hint = T.label("Pick one. It stays for the rest of the match.", 11, 500, T.TEXT_3)
	v:add_child(self._hint)
	self._cards_box = T.hbox(8)
	v:add_child(self._cards_box)
	self._cards = {}
	self:add_child(panel)
	panel:set_visible(false)

	self.chip = T.button("DRAFT", "PublicButton", "", 32.0)
	self.chip:set_font_size(12)
	self.chip:set_min_size(Vector2.new(84, 32))
	self.chip.pressed:Connect(function()
		self._collapsed = false
		self:_show()
		self.ui:relayout()
	end)
	self:add_child(self.chip)
	self.chip:set_visible(false)
	-- the active orders ("edicts") the player's doctrines grant: a chip each, with its cooldown
	self.edict_chips = {}
	for _, name in DoctrineDraft.EDICTS do
		local chip = T.button(string.upper(name), "PublicButton", "", 32.0)
		chip:set_font_size(12)
		chip:set_min_size(Vector2.new(132, 32))
		chip.pressed:Connect(function()
			self.ctx:send({ type = "edict", kind = name })
			self.ctx:sfx("confirm", -4.0)
		end)
		chip:set_visible(false)
		self:add_child(chip)
		self.edict_chips[name] = chip
	end
	-- the world event running, with its clock: a press repeats what it does
	self.event_chip = T.button("", "ChipButton", "", 32.0)
	self.event_chip:set_font_size(12)
	self.event_chip:set_min_size(Vector2.new(150, 32))
	self.event_chip.pressed:Connect(function()
		local we = self.ctx.state ~= nil and self.ctx.state.world_event
		local d = we and WorldEvents.LIST[we[1]]
		if d and self.ui ~= nil and self.ui.feed ~= nil then
			self.ui.feed:toast(Defs.MSG_INFO, d.line)
		end
	end)
	self.event_chip:set_visible(false)
	self:add_child(self.event_chip)
	-- King of the Hill: who holds the Crown, and for how long in all
	self.crown_chip = T.button("", "ChipButton", "", 32.0)
	self.crown_chip:set_font_size(12)
	self.crown_chip:set_min_size(Vector2.new(190, 32))
	self.crown_chip.pressed:Connect(function()
		local crown = self.ctx.state ~= nil and self.ctx.state.crown
		if crown and self.ctx.world ~= nil and type(self.ctx.world.focus_tile) == "function" then
			self.ctx.world:focus_tile(crown[1], -1.0, 0.6)
		end
	end)
	self.crown_chip:set_visible(false)
	self:add_child(self.crown_chip)
	-- (these sit on the map, whatever its colour: a dark plate, or pale land washes their text out)
	local plated = { self.chip, self.event_chip, self.crown_chip }
	for _, chip in self.edict_chips do
		table.insert(plated, chip)
	end
	for _, chip in plated do
		local plate = T.flat(T.rgba(0.03, 0.06, 0.08, 0.94), 10, T.LINE_2, 1, 12.0, 4.0)
		chip:add_theme_stylebox_override("normal", plate)
		chip:add_theme_stylebox_override("hover", T.flat(T.rgba(0.06, 0.11, 0.13, 0.96), 10, T.c(T.AMBER, 0.6), 1, 12.0, 4.0))
		chip:add_theme_stylebox_override("pressed", plate)
		chip:add_theme_color_override("font_color", T.TEXT)
		chip:add_theme_color_override("font_hover_color", T.TEXT)
	end
	self._acc = 0.0
	self:set_process(true)
	return self
end

--- The edict names, in the order their chips sit.
DoctrineDraft.EDICTS = Doctrines.EDICT_ORDER

--- The edicts (names) the local player's doctrines grant.
function DoctrineDraft.my_edicts(state: any, me: number): { [string]: boolean }
	local out = {}
	local by = if state ~= nil and me ~= 0 and state.doctrine ~= nil then state.doctrine[me] else nil
	for draft = 1, Doctrines.TIERS do
		local row = if by ~= nil then by[draft] else nil
		if row ~= nil and row[6] >= 1 and row[6] <= Doctrines.OFFER_SIZE then
			local d = Doctrines.LIST[row[2 + row[6]]]
			if d.edict ~= nil then
				out[d.edict] = true
			end
		end
	end
	return out
end

--- The running world event's chip, and its text: "GOLD RUSH 1:12". True when it changed visibility.
function DoctrineDraft._refresh_event(self): boolean
	local ctx = self.ctx
	local s = ctx.state
	local we = if s ~= nil and s.phase == Defs.PHASE_PLAYING then s.world_event else nil
	local left = if we ~= nil then math.ceil((we[3] - ctx:render_tick()) / Defs.TICK_RATE) else 0
	local on = left > 0
	local was = self.event_chip.visible
	self.event_chip:set_visible(on)
	if on then
		local d = WorldEvents.LIST[we[1]]
		self.event_chip:set_text(string.format("%s %s", string.upper(d.name), UITheme.fmt_time(left)))
	end
	return was ~= on
end

--- The Crown's chip: "CROWN: RUSSIA 2:14 / 5:00", or that it is free. True when it changed visibility.
function DoctrineDraft._refresh_crown(self): boolean
	local s = self.ctx.state
	local crown = if s ~= nil and s.phase == Defs.PHASE_PLAYING then s.crown else nil
	local was = self.crown_chip.visible
	self.crown_chip:set_visible(crown ~= nil)
	if crown ~= nil then
		local holder = crown[3]
		local opens = (s.playing_since or 0) + UICtx.core("SimModes").CROWN_OPEN_TICKS - self.ctx:render_tick()
		local who = if holder == self.ctx:me() then "YOU" elseif holder > 0 then string.upper(s:owner_name(holder)) else "FREE"
		local held = if holder > 0 then (s.crown_ticks[holder] or 0) // Defs.TICK_RATE else 0
		if opens > 0 then
			self.crown_chip:set_text(string.format("CROWN OPENS IN %s", UITheme.fmt_time(math.ceil(opens / Defs.TICK_RATE))))
		else
			self.crown_chip:set_text(string.format("CROWN: %s %s / %s", who, UITheme.fmt_time(held), UITheme.fmt_time(crown[2] // Defs.TICK_RATE)))
		end
	end
	return was ~= (crown ~= nil)
end

--- Chips for the edicts held: "WINDFALL" when ready, "WINDFALL 2:41" while it cools.
function DoctrineDraft._refresh_edicts(self)
	local ctx = self.ctx
	local s = ctx.state
	local mine = DoctrineDraft.my_edicts(s, ctx:me())
	local playing = s ~= nil and s.phase == Defs.PHASE_PLAYING
	local ready_at = if s ~= nil and s.edict_ready ~= nil then (s.edict_ready[ctx:me()] or 0) else 0
	local left = math.max(0, math.ceil((ready_at - ctx:render_tick()) / Defs.TICK_RATE))
	for name, chip in self.edict_chips do
		local on = playing and mine[name] == true
		chip:set_visible(on)
		if on then
			local running = if s.edict_buff ~= nil then (s.edict_buff[ctx:me()] or 0) else 0
			local run_left = math.ceil((running - ctx:render_tick()) / Defs.TICK_RATE)
			if run_left > 0 then
				chip:set_text(string.format("%s ON %s", string.upper(name), UITheme.fmt_time(run_left)))
			else
				chip:set_text(if left > 0 then string.format("%s %s", string.upper(name), UITheme.fmt_time(left)) else string.upper(name))
			end
		end
	end
end

--- Builds the three cards of `row`.
function DoctrineDraft._build_cards(self, row: { number })
	local T = UITheme
	local ctx = self.ctx
	for _, card in self._cards do
		card:queue_free()
	end
	table.clear(self._cards)
	local w = if ctx.compact then DoctrineDraft.CARD_W_COMPACT else DoctrineDraft.CARD_W
	local small = ctx.compact
	for slot = 1, Doctrines.OFFER_SIZE do
		local d = Doctrines.LIST[row[2 + slot]]
		local card = GlassPanel.new(10.0, 8.0, T.R_MD, false, 0)
		card:set_tint(T.GLASS_RAISED)
		card:set_border(T.LINE_2)
		-- (every card the height of the tallest, three effect lines: no ragged row)
		card:set_min_size(Vector2.new(w, if small then 128 else 150))
		local cv = T.vbox(4)
		local top = T.hbox(6)
		local glyph = T.label(d.glyph, if small then 18 else 22, 900, T.GOLD)
		glyph.size_flags_vertical = W.SHRINK_CENTER
		top:add_child(glyph)
		local name = T.label(d.name, if small then 12 else 14, 800, T.TEXT)
		name:set_autowrap(true)
		name.size_flags_horizontal = W.EXPAND_FILL
		name.size_flags_vertical = W.SHRINK_CENTER
		top:add_child(name)
		cv:add_child(top)
		for _, line in DoctrineDraft.card_lines(d) do
			local cost = string.sub(line, 1, 1) == "-"
			cv:add_child(T.label(line, if small then 11 else 12, 700, if cost then T.RED else T.GREEN))
		end
		local why = T.label(d.line, if small then 10 else 11, 500, T.TEXT_2)
		why:set_autowrap(true)
		why:set_min_size(Vector2.new(w - 20, 0))
		cv:add_child(why)
		local pick = T.button("Choose", "PrimaryButton", "", if small then 32.0 else 36.0)
		pick:set_font_size(if small then 12 else 14)
		pick.pressed:Connect(function()
			self:choose(d.key)
		end)
		cv:add_child(pick)
		card:add_child(cv)
		self._cards_box:add_child(card)
		table.insert(self._cards, card)
	end
end

--- Takes doctrine `key`: sends the intent and folds away until the Sim's answer arrives.
function DoctrineDraft.choose(self, key: string)
	if self._row == nil then
		return
	end
	self.ctx:send({ type = "doctrine", kind = key })
	self._sent_at = self.ctx:render_tick()
	self.ctx:sfx("confirm", -4.0)
	self.picked:Fire(key)
	self:_show()
end

function DoctrineDraft._show(self)
	local open = self._row ~= nil and (self._sent_at < 0 or self.ctx:render_tick() - self._sent_at > 20)
	self.panel:set_visible(open and not self._collapsed)
	self.chip:set_visible(open and self._collapsed)
end

--- Reads the state: the player's open offer (a new one builds its cards and opens).
function DoctrineDraft.refresh(self)
	local ctx = self.ctx
	local s = ctx.state
	local row = DoctrineDraft.open_row(s, ctx:me())
	if s ~= nil and (s.phase ~= Defs.PHASE_PLAYING) then
		row = nil
	end
	local changed = (row == nil) ~= (self._row == nil) or (row ~= nil and self._row ~= nil and row[2] ~= self._row[2])
	self._row = row
	if changed and row ~= nil then
		self._collapsed = self:_tutorial_holds()
		self._sent_at = -1.0
		self:_build_cards(row)
		local era_name = Eras.NAMES[math.min(row[2] + 1, #Eras.NAMES)]
		self._title:set_text(string.format("DRAFT · %s", string.upper(era_name)))
		ctx:sfx("unlock", -6.0)
	end
	if row ~= nil then
		local left = math.max(0, math.ceil((row[7] - ctx:render_tick()) / Defs.TICK_RATE))
		self._timer:set_text(string.format("Auto-picks in %s", UITheme.fmt_time(left)))
	end
	self:_show()
	self:_refresh_edicts()
end

--- True while the tutorial has not reached its "eras" lesson: a draft that opens earlier waits folded as
--- the DRAFT chip, so nothing unexplained covers the card the player is reading.
function DoctrineDraft._tutorial_holds(self): boolean
	local tut = if self.ui ~= nil then self.ui.tutorial else nil
	if tut == nil or not tut.active then
		return false
	end
	local at = UICtx.data("Tutorial").step_index("eras")
	return at ~= nil and (tut._i or 1) < at
end

function DoctrineDraft._process(self, dt: number)
	if self._row ~= nil then
		self:refresh()
	end
	self._acc += dt
	if self._acc >= 0.25 then
		self._acc = 0.0
		self:_refresh_edicts()
		local a, b = self:_refresh_event(), self:_refresh_crown()
		if (a or b) and self.ui ~= nil then
			self.ui:relayout()
		end
	end
end

--- Where it sits: centred in the band between the status (above) and the command bar (below); the
--- chip, when folded, just under the status.
function DoctrineDraft.apply_layout(self, top_y: number, bottom_y: number)
	local ctx = self.ctx
	local vp, ins = ctx.vp, ctx.insets
	-- (the cards do not fit the free band, as on a phone under the tutorial's card: fold to the chip)
	if self._row ~= nil and not self._collapsed and self._sent_at < 0 then
		self.panel:reset_size()
		if self.panel:get_combined_minimum_size().Y > (bottom_y - top_y) + 4.0 then
			self._collapsed = true
			self:_show()
		end
	end
	if self.chip.visible then
		local sz = self.chip:get_combined_minimum_size()
		UICtx.move_node(self.chip, Vector2.new(math.floor((vp.X - sz.X) * 0.5), math.floor(top_y)))
	end
	-- the edict chips: a row under the status (under the DRAFT chip when it is there)
	local ey = top_y + (if self.chip.visible then 38.0 else 0.0)
	local total, row = 0.0, {}
	if self.crown_chip.visible then
		table.insert(row, self.crown_chip)
		total += self.crown_chip:get_combined_minimum_size().X + 8.0
	end
	if self.event_chip.visible then
		table.insert(row, self.event_chip)
		total += self.event_chip:get_combined_minimum_size().X + 8.0
	end
	for _, name in DoctrineDraft.EDICTS do
		local chip = self.edict_chips[name]
		if chip.visible then
			table.insert(row, chip)
			total += chip:get_combined_minimum_size().X + 8.0
		end
	end
	local x = math.floor((vp.X - (total - 8.0)) * 0.5)
	for _, chip in row do
		UICtx.move_node(chip, Vector2.new(x, math.floor(ey)))
		x += chip:get_combined_minimum_size().X + 8.0
	end
	if self.panel.visible then
		self.panel:reset_size()
		local sz = self.panel:get_combined_minimum_size()
		local x = math.clamp((vp.X - sz.X) * 0.5, ins.x + 8.0, math.max(ins.x + 8.0, vp.X - ins.z - sz.X - 8.0))
		local y = math.max(top_y, top_y + (bottom_y - top_y - sz.Y) * 0.4)
		UICtx.move_node(self.panel, Vector2.new(math.floor(x), math.floor(y)))
	end
end

--- The panel's rect in logical px (nil when folded), for what must keep clear of it.
function DoctrineDraft.rect(self)
	if self.panel.visible then
		return self.panel:get_global_rect()
	end
	return nil
end

return DoctrineDraft
