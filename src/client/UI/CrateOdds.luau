--!nonstrict
-- The crate's Details window: every item a crate can still give this player, with its own odds (Roblox's
-- paid random items policy: each outcome before purchase, behind a control that says "Details"). The rows
-- are the player's, from Cosmetics.item_odds, which is what the server rolls.

local UITheme = require("./UITheme")
local W = require("./Widgets")
local GlassPanel = require("./GlassPanel")
local UICtx = require("./UICtx")
local HelpOverlay = require("./HelpOverlay")
local Signal = UITheme.core("Signal")
local Cosmetics = UICtx.data("Cosmetics")

local CrateOdds = W.class(W.Control)

local function c3(hex: number): any
	return Color3.fromHex(string.format("%06x", hex))
end

function CrateOdds.new(c: any)
	local self = setmetatable({}, CrateOdds.__mt)
	W.Control._init(self)
	self.ctx = c
	self.closed = Signal.new()
	self.is_open = false
	self:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)
	self:set_mouse_filter(W.MOUSE_STOP)
	self:set_visible(false)
	-- (see HelpOverlay: a click on the window must not press what's underneath)
	UICtx.make("TextButton", {
		Name = "Blocker",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		Active = true,
		Selectable = false,
		ZIndex = 1,
	}, self.gui)
	self._dim = W.ColorRect.new(UITheme.rgba(0.01, 0.015, 0.05, 0.72))
	self._dim:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)
	self._dim:set_mouse_filter(W.MOUSE_STOP)
	self._dim.gui_input:Connect(function(e)
		if e.pressed and not self._panel:has_global_point(e.global_position) then
			self:close()
		end
	end)
	self:add_child(self._dim)
	self._panel = GlassPanel.new(18.0, 14.0, 16, true, 34)
	self._panel:set_tint(UITheme.GLASS_SOLID)
	self:add_child(self._panel)
	local v = UITheme.vbox(8)
	self._panel:add_child(v)
	local head = UITheme.hbox(10)
	local title = UITheme.label("CRATE ODDS", 18, 800, UITheme.TEXT, 2)
	title.size_flags_horizontal = W.EXPAND_FILL
	title.size_flags_vertical = W.SHRINK_CENTER
	head:add_child(title)
	local close = UITheme.button("", "GlassButton", "close", 40.0)
	close.expand_icon = true
	close.icon_alignment = W.ALIGN_CENTER
	close:add_theme_constant_override("icon_max_width", 13)
	close:set_min_size(Vector2.new(40, 40))
	close.pressed:Connect(function()
		self:close()
	end)
	head:add_child(close)
	v:add_child(head)
	self._note = UITheme.label("", 12, 500, UITheme.TEXT_2)
	self._note:set_autowrap(true)
	v:add_child(self._note)
	self._scroll = HelpOverlay.Scroll.new()
	self._scroll.size_flags_vertical = W.EXPAND_FILL
	v:add_child(self._scroll)
	return self
end

--- One row: the item's name, and its odds at the right.
local function row(name: string, odds: string): any
	local r = UITheme.hbox(10)
	local n = UITheme.label(name, 13, 500, UITheme.TEXT)
	n.size_flags_horizontal = W.EXPAND_FILL
	r:add_child(n)
	r:add_child(UITheme.label(odds, 13, 600, UITheme.TEXT))
	-- (clear of the scroll bar)
	local gap = W.Control.new()
	gap:set_min_size(Vector2.new(8, 0))
	gap:set_mouse_filter(W.MOUSE_IGNORE)
	r:add_child(gap)
	return r
end

--- `owned`: the set of item ids the player owns.
function CrateOdds._fill(self, owned: any)
	local old = self._list
	if old ~= nil then
		old:queue_free()
	end
	local list = UITheme.vbox(3)
	list.size_flags_horizontal = W.EXPAND_FILL
	self._list = list
	self._scroll:add_child(list)
	local any_rounded = false
	local shown = nil
	for _, e in Cosmetics.item_odds(owned) do
		if e.rarity ~= shown then
			shown = e.rarity
			local head = UITheme.hbox(8)
			head:add_child(UITheme.swatch(c3(e.rarity.color), 10.0, 3))
			head:add_child(UITheme.label(string.upper(e.rarity.name), 12, 800, UITheme.TEXT_2, 1))
			if #list:get_children() > 0 then
				local gap = W.Control.new()
				gap:set_min_size(Vector2.new(0, 6))
				gap:set_mouse_filter(W.MOUSE_IGNORE)
				list:add_child(gap)
			end
			list:add_child(head)
		end
		local text, rounded = Cosmetics.odds_text(e.odds)
		any_rounded = any_rounded or rounded
		local kind = if e.item.kind == "flag" then "Flag" else "Skin"
		list:add_child(row(string.format("%s  ·  %s", e.item.name, kind), text))
	end
	local note = "Your own odds for the next crate. Items you own can't drop, so these change as you collect."
	if any_rounded then
		note ..= " " .. Cosmetics.ODDS_ROUNDED_NOTE
	end
	self._note:set_text(note)
end

function CrateOdds.apply_layout(self)
	local area = self.ctx:clear_rect()
	local w = math.min(520.0, area.Width - 16.0)
	local h = math.min(640.0, area.Height - 12.0)
	local p = area.Min + (Vector2.new(area.Width, area.Height) - Vector2.new(w, h)) * 0.5
	p = Vector2.new(math.floor(p.X + 0.5), math.floor(p.Y + 0.5))
	-- (a wrapped label measures against its width: without one it asks for a line per letter)
	self._note:set_min_size(Vector2.new(w - 36.0, 0))
	self._panel:set_min_size(Vector2.new(w, h))
	self._panel:set_offsets(p.X, p.Y, p.X + w, p.Y + h)
	self._panel:reset_size()
end

function CrateOdds.open(self, owned: any)
	if self.is_open then
		return
	end
	self.is_open = true
	self:_fill(owned or {})
	self:apply_layout()
	self:set_visible(true)
	self._panel:set_modulate_a(1.0)
	self._dim:set_modulate_a(0.0)
	W.fade(self._dim, 1.0, 0.2)
	UICtx.pop_in(self._panel, 0.0, 0.96, 0.25)
	self.ctx:sfx("open")
end

function CrateOdds.close(self)
	if not self.is_open then
		return
	end
	self.is_open = false
	self.ctx:sfx("close")
	self:set_visible(false)
	self.closed:Fire()
end

return CrateOdds
