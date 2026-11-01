--!nonstrict
-- The War Report (Conquer the World's own; the results screen's WAR REPORT button): how the match went: your land
-- against the leader's over time (a bar chart, drawn from UI/MatchLog's samples), the moments worth remembering, and
-- what the match paid your career.
local UITheme = require("./UITheme")
local W = require("./Widgets")
local GlassPanel = require("./GlassPanel")
local UICtx = require("./UICtx")
local HelpOverlay = require("./HelpOverlay")
local Signal = UITheme.core("Signal")

local WarReport = W.class(W.Control)

WarReport.SIZE = Vector2.new(640, 440)
WarReport.CHART_H = 120

function WarReport.new(c: any)
	local self = setmetatable({}, WarReport.__mt)
	W.Control._init(self)
	self.ctx = c
	self.closed = Signal.new()
	self.is_open = false
	self:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)
	self:set_mouse_filter(W.MOUSE_STOP)
	self:set_visible(false)
	self._dim = W.ColorRect.new(UITheme.rgba(0.01, 0.015, 0.05, 0.78))
	self._dim:set_anchors_and_offsets_preset(W.PRESET_FULL_RECT)
	self._dim.gui_input:Connect(function(e)
		if e.pressed and not self._panel:has_global_point(e.global_position) then
			self:close()
		end
	end)
	self:add_child(self._dim)
	self._panel = GlassPanel.new(22.0, 18.0, 18, true, 34)
	self._panel:set_tint(UITheme.GLASS_SOLID)
	self:add_child(self._panel)
	local v = UITheme.vbox(10)
	self._panel:add_child(v)
	local head = UITheme.hbox(12)
	local title = UITheme.label("WAR REPORT", 20, 800, UITheme.TEXT, 3)
	title.size_flags_vertical = W.SHRINK_CENTER
	head:add_child(title)
	self._sub = UITheme.label("", 13, 600, UITheme.TEXT_2)
	self._sub.size_flags_horizontal = W.EXPAND_FILL
	self._sub.size_flags_vertical = W.SHRINK_CENTER
	head:add_child(self._sub)
	local close = W.Button.new("", "GhostButton")
	close:set_icon("close")
	close.expand_icon = true
	close:set_min_size(Vector2.new(34, 34))
	close:add_theme_constant_override("icon_max_width", 13)
	close:add_theme_stylebox_override("normal", UITheme.empty_box(8, 8))
	close:add_theme_stylebox_override("hover", UITheme.flat(UITheme.FILL, 8, UITheme.CLEAR, 0, 8, 8))
	close.size_flags_vertical = W.SHRINK_CENTER
	close.pressed:Connect(function()
		self:close()
	end)
	head:add_child(close)
	v:add_child(head)
	self._scroll = HelpOverlay.Scroll.new()
	self._scroll:set_min_size(WarReport.SIZE)
	v:add_child(self._scroll)
	return self
end

--- The chart: one column per sample; the leader's land behind, yours in front.
function WarReport._chart(self, samples: { { number } }): any
	local T = UITheme
	local chart = W.Control.new()
	chart:set_mouse_filter(W.MOUSE_IGNORE)
	chart:set_min_size(Vector2.new(0, WarReport.CHART_H))
	chart.size_flags_horizontal = W.EXPAND_FILL
	local n = #samples
	local top = 0.05
	for _, s in samples do
		top = math.max(top, s[3], s[2])
	end
	for i, s in samples do
		local l, r = (i - 1) / n, i / n
		local lead = W.ColorRect.new(T.c(T.WHITE, 0.14))
		lead:set_mouse_filter(W.MOUSE_IGNORE)
		lead:set_anchors(l, 1 - s[3] / top, r, 1)
		lead:set_offsets(0, 0, -1, 0)
		chart:add_child(lead)
		local mine = W.ColorRect.new(T.AMBER)
		mine:set_mouse_filter(W.MOUSE_IGNORE)
		mine:set_anchors(l, 1 - s[2] / top, r, 1)
		mine:set_offsets(0, 0, -1, 0)
		chart:add_child(mine)
	end
	return chart
end

--- `log`: UI/MatchLog; `result`: Data/Progress.after_match's answer (nil when the match paid nothing).
function WarReport.open(self, log: any, result: any)
	local T = UITheme
	if self._content ~= nil then
		self._scroll:remove_child(self._content)
		self._content:queue_free()
	end
	local v = T.vbox(8)
	v.size_flags_horizontal = W.EXPAND_FILL
	local wrap = T.hbox(0)
	wrap:add_child(v)
	local gutter = W.Control.new()
	gutter:set_min_size(Vector2.new(12, 0))
	gutter:set_mouse_filter(W.MOUSE_IGNORE)
	wrap:add_child(gutter)
	self._content = wrap
	self._scroll:add_child(wrap)
	local samples = log.samples
	local best = 0.0
	for _, s in samples do
		best = math.max(best, s[2])
	end
	self._sub:set_text(string.format("Best: %s of the land", T.fmt_pct(best)))
	if #samples >= 2 then
		local legend = T.hbox(12)
		legend:add_child(T.label("YOUR LAND", 11, 800, T.AMBER, 1))
		legend:add_child(T.label("THE LEADER'S", 11, 800, T.TEXT_2, 1))
		v:add_child(legend)
		v:add_child(self:_chart(samples))
	else
		v:add_child(T.label("Too short a match for a chart.", 12, 500, T.TEXT_2))
	end
	if result ~= nil and result.gained > 0 then
		v:add_child(T.label(string.format("CAREER: +%d XP · %s", result.gained, string.upper(result.rank.name)), 12, 800, T.GOLD, 1))
		for _, line in result.lines do
			v:add_child(T.label(string.format("%s  +%d", line[1], line[2]), 12, 600, T.TEXT_2))
		end
		if result.stars ~= nil and result.mission ~= nil then
			v:add_child(T.label(string.format("War Room: %s, %d of 3 stars", result.mission, result.stars), 12, 700, T.GOLD))
		end
		for _, order in result.orders do
			v:add_child(T.label("Order complete: " .. order.text, 12, 600, T.GREEN))
		end
		for _, m in result.medals do
			v:add_child(T.label("Medal: " .. m.name, 12, 700, T.GOLD))
		end
		for _, t in result.new_titles do
			v:add_child(T.label("New title: " .. t, 12, 700, T.AMBER))
		end
	end
	if #log.moments > 0 then
		v:add_child(T.label("MOMENTS", 12, 800, T.AMBER, 2))
		for _, m in log.moments do
			local row = T.hbox(10)
			local at = T.label(T.fmt_time(m[1]), 11, 700, T.TEXT_3)
			at:set_min_size(Vector2.new(46, 0))
			row:add_child(at)
			row:add_child(T.label(m[2], 12, 600, if m[3] then T.TEXT else T.TEXT_2))
			v:add_child(row)
		end
	end
	self.is_open = true
	self:set_visible(true)
	self:apply_layout()
	self.ctx:sfx("open")
end

function WarReport.close(self)
	if not self.is_open then
		return
	end
	self.is_open = false
	self:set_visible(false)
	self.ctx:sfx("close")
	self.closed:Fire()
end

function WarReport.apply_layout(self)
	local area = self.ctx:clear_rect()
	local w = math.clamp(area.Width - 60, 300, WarReport.SIZE.X)
	local h = math.clamp(area.Height - 90, 120, WarReport.SIZE.Y)
	self._scroll:set_min_size(Vector2.new(w, h))
	local pn = self._panel
	local sz = pn:get_combined_minimum_size()
	local p = area.Min + (Vector2.new(area.Width, area.Height) - sz) * 0.5
	local y = math.max(p.Y, area.Min.Y + 4.0)
	local x = math.floor(p.X + 0.5)
	pn:set_offsets(x, math.floor(y + 0.5), x, math.floor(y + 0.5))
	pn:reset_size()
end

return WarReport
