--!nocheck
-- The Dominion strip and the doctrine draft (Conquer the World's own UI), built under Lune with real
-- Instances (tests/helpers/ui_env.luau): the pure model, the widgets built and driven against a stub of
-- the HUD context, the intent a card sends, and a PARTIAL layout check (under Lune the insets are 0 and the
-- real Roblox top bar is never measured, so this proves the draft's rect against the status and the
-- command bar it is given, not against Roblox's own chrome).
-- Run: lune run tests/ui_doctrine.luau
require("./helpers/ui_env").install()
local Defs = require("../src/shared/Core/Defs")
local Doctrines = require("../src/shared/Data/Doctrines")
local Eras = require("../src/shared/Data/Eras")
-- (Lune's TextButton has no MouseEnter / MouseLeave, which the kit's Button connects, so buttons are a
-- stand-in here: a control with a `pressed` signal. Everything else is the real kit.)
do
	local UITheme = require("../src/client/UI/UITheme")
	local W = require("../src/client/UI/Widgets")
	local Signal = require("../src/shared/Core/Signal")
	-- (no font assets under Lune: UITheme.font gives nil there, and a label cannot take nil)
	UITheme.font = function(_weight: number?)
		return Font.fromEnum(Enum.Font.Gotham)
	end
	UITheme.button = function(text: string, _variation: string?, _icon: string?, min_h: number?)
		local btn = W.Control.new()
		btn.pressed = Signal.new()
		btn.text = text
		btn.set_font_size = function() end
		btn.set_text = function(self, t)
			self.text = t
		end
		btn:set_min_size(Vector2.new(0, min_h or 44))
		return btn
	end
end
local DominionStrip = require("../src/client/UI/DominionStrip")
local DoctrineDraft = require("../src/client/UI/DoctrineDraft")

local fails = 0
local function expect(cond: any, what: string)
	if cond then
		print("  ok   " .. what)
	else
		fails += 1
		print("FAIL " .. what)
	end
end

-- the pure model --------------------------------------------------------------------------------
do
	local m = DominionStrip.model(Eras.DEFAULT, 0, {})
	expect(m.era == 1 and m.name == "Dawn" and m.roman == "I" and m.progress == 0 and m.next_s == 180 and m.next_name == "Expansion", "the Dawn at tick 0: next era in 3:00")
	m = DominionStrip.model(Eras.DEFAULT, 900, { "merchant", "nope" })
	expect(math.abs(m.progress - 0.5) < 1e-9 and #m.glyphs == 1 and m.glyphs[1] == "$", "half through the Dawn, one known pick shown")
	m = DominionStrip.model(Eras.DEFAULT, 99999, {})
	expect(m.era == 4 and m.progress == 1 and m.next_s == nil and m.name == "Reckoning", "past the last start: the Reckoning, nothing next")
	m = DominionStrip.model({ 0, 10, 20, 30 }, 15, {})
	expect(m.era == 2 and math.abs(m.progress - 0.5) < 1e-9, "a match's own era table is used")
end

-- a stub HUD context ----------------------------------------------------------------------------
local sent, sfx = {}, {}
local tick = 1000
local state = {
	phase = Defs.PHASE_PLAYING,
	playing_since = 0,
	eras = { 0, 1800, 5400, 9600 },
	doctrine = {},
	map = nil,
}
local ctx = {
	compact = false,
	touch = false,
	vp = Vector2.new(1280, 720),
	insets = { x = 0, y = 0, z = 0, w = 0 },
	state = state,
	me = function()
		return 7
	end,
	render_tick = function()
		return tick
	end,
	send = function(_, intent)
		table.insert(sent, intent)
	end,
	sfx = function(_, name)
		table.insert(sfx, name)
	end,
}

-- the strip -------------------------------------------------------------------------------------
do
	local strip = DominionStrip.new(ctx)
	strip:fix_widths()
	local eras_seen = {}
	strip.era_changed:Connect(function(e)
		table.insert(eras_seen, e)
	end)
	strip:refresh()
	expect(strip.node.visible and strip._name.text == "DAWN", "the strip shows the Dawn")
	expect(strip._next.text:find("EXPANSION", 1, true) ~= nil, "and what comes next, with a clock")
	tick = 1900
	strip:refresh()
	expect(strip._name.text == "EXPANSION" and #eras_seen == 1 and eras_seen[1] == 2, "an era change fires once (the first look does not)")
	strip:refresh()
	expect(#eras_seen == 1, "and not again on the next refresh")
	state.doctrine[7] = { [1] = { 7, 1, 1, 2, 3, 2, 0 } }
	strip:refresh()
	expect(strip._pip_labels[1].text == Doctrines.LIST[2].glyph, "a pick shows as a pip")
	tick = 9700
	strip:refresh()
	expect(strip._next.text == "FINAL ERA", "the last era has no next")
	state.eras = nil
	strip:refresh()
	expect(not strip.node.visible, "a match without eras hides the strip")
	state.eras = { 0, 1800, 5400, 9600 }
	tick = 1000
end

-- the draft -------------------------------------------------------------------------------------
do
	state.doctrine = {}
	local relayouts = 0
	local ui = {
		relayout = function()
			relayouts += 1
		end,
	}
	local draft = DoctrineDraft.new(ctx, ui)
	local root = require("../src/client/UI/Widgets").Control.new()
	root:add_child(draft)
	draft:refresh()
	expect(not draft.panel.visible and not draft.chip.visible, "nothing to draft: nothing on screen")
	local offer = Doctrines.offer(5, 7, 1)
	state.doctrine[7] = { [1] = { 7, 1, offer[1], offer[2], offer[3], 0, tick + 600 } }
	draft:refresh()
	expect(draft.panel.visible and #draft._cards == 3, "an open offer shows three cards")
	expect(draft._timer.text == "Auto-picks in 1:00", "with the countdown to the auto-pick")
	expect(draft._title.text == "DRAFT · EXPANSION", "titled with the era it opened")
	draft:apply_layout(80, 640)
	local r = draft.panel:get_global_rect()
	expect(r.Min.Y >= 80 and r.Max.Y <= 640 and r.Min.X >= 0 and r.Max.X <= 1280, "the draft sits inside the band it is given")
	-- phone width
	ctx.compact, ctx.vp = true, Vector2.new(844, 390)
	draft._row = nil
	draft:refresh()
	draft:apply_layout(70, 330)
	local rc = draft.panel:get_global_rect()
	expect(rc.Min.X >= 0 and rc.Max.X <= 844, "at 844 wide the three cards fit across (" .. math.floor(rc.Max.X - rc.Min.X) .. " px)")
	expect(rc.Max.Y - rc.Min.Y <= 330 - 70 + 40, "and are not taller than the free band by much (" .. math.floor(rc.Max.Y - rc.Min.Y) .. " of " .. (330 - 70) .. " px): the phone's band is tight, so Later folds it")
	-- later folds it to a chip; the chip opens it again
	draft._later.pressed:Fire()
	expect(not draft.panel.visible and draft.chip.visible and relayouts >= 1, "Later folds the draft to a chip")
	draft.chip.pressed:Fire()
	expect(draft.panel.visible and not draft.chip.visible, "and the chip opens it again")
	-- choosing sends the intent
	local key = Doctrines.LIST[offer[2]].key
	draft:choose(key)
	expect(#sent == 1 and sent[1].type == "doctrine" and sent[1].kind == key and #sent[1].kind <= 16, "a card sends the doctrine intent")
	expect(not draft.panel.visible, "and the draft folds away until the Sim answers")
	-- the Sim's answer closes it for good
	state.doctrine[7][1][6] = 2
	tick += 30
	draft:refresh()
	expect(not draft.panel.visible and not draft.chip.visible, "a made pick closes the draft")
	-- a draft for the player's next era opens a fresh one
	state.doctrine[7][2] = { 7, 2, 5, 6, 7, 0, tick + 600 }
	draft:refresh()
	expect(draft.panel.visible and #draft._cards == 3 and draft._title.text == "DRAFT · CONFLICT", "the next era's draft opens afresh")
	state.phase = Defs.PHASE_OVER
	draft:refresh()
	expect(not draft.panel.visible, "nothing is offered once the match is over")
end

-- the draft under a tutorial card, and while the tutorial has not reached its lesson ------------------
do
	ctx.compact, ctx.vp = true, Vector2.new(844, 390)
	state.phase = Defs.PHASE_PLAYING
	state.doctrine = {}
	local ui = {
		relayout = function() end,
		tutorial = { active = true, _i = 1 },
	}
	local draft = DoctrineDraft.new(ctx, ui)
	local root = require("../src/client/UI/Widgets").Control.new()
	root:add_child(draft)
	state.doctrine[7] = { [1] = { 7, 1, 1, 2, 3, 0, tick + 600 } }
	draft:refresh()
	expect(not draft.panel.visible and draft.chip.visible, "during the tutorial, before its eras lesson, a draft waits as the DRAFT chip")
	ui.tutorial.active = false
	draft._row = nil
	draft:refresh()
	expect(draft.panel.visible, "with no tutorial it opens")
	draft:apply_layout(200, 330) -- a band of 130 px: under a lesson card on a phone
	expect(not draft.panel.visible and draft.chip.visible, "a band too short for the cards folds it to the chip (it never runs over the command bar)")
	local chip = draft.chip:get_global_rect()
	expect(chip.Min.Y >= 200 and chip.Max.Y <= 330, "and the chip sits inside that band")
	local Tut = require("../src/shared/Data/Tutorial")
	ui.tutorial.active, ui.tutorial._i = true, Tut.step_index("eras")
	draft._row = nil
	draft._collapsed = false
	draft:refresh()
	expect(draft.panel.visible, "at the eras lesson the draft opens")
end

-- the timeline fill moves ------------------------------------------------------------------------------
do
	ctx.compact, ctx.vp = false, Vector2.new(1280, 720)
	local strip = DominionStrip.new(ctx)
	local root = require("../src/client/UI/Widgets").Control.new()
	root:add_child(strip.node)
	tick = 900 -- half through the Dawn
	state.doctrine = {}
	strip:refresh()
	local seg, fill = strip._segs[1].seg, strip._segs[1].fill
	seg:reset_size()
	local sw = seg:get_combined_minimum_size().X
	expect(sw > 0 and fill.anchor_right == 0.5, "the current era's fill is anchored to its progress (" .. tostring(fill.anchor_right) .. ")")
	expect(strip._segs[2].fill.visible == false, "later eras have no fill yet")
end

-- the edict chips: shown only for a held, chosen doctrine, with the cooldown, and a press sends the intent ---------
do
	ctx.compact, ctx.vp = false, Vector2.new(1280, 720)
	state.phase = Defs.PHASE_PLAYING
	local coin, army
	for i, d in Doctrines.LIST do
		if d.key == "coin" then
			coin = i
		elseif d.key == "grandarmy" then
			army = i
		end
	end
	local draft = DoctrineDraft.new(ctx, { relayout = function() end })
	local root = require("../src/client/UI/Widgets").Control.new()
	root:add_child(draft)
	state.doctrine = { [7] = { [3] = { 7, 3, coin, army, 1, 0, tick + 600 } } }
	state.edict_ready = {}
	draft:refresh()
	expect(not draft.edict_chips.windfall.visible and not draft.edict_chips.levy.visible, "an unchosen offer grants no edict chip")
	state.doctrine[7][3][6] = 1 -- picked the first card (coin)
	draft:refresh()
	expect(draft.edict_chips.windfall.visible and draft.edict_chips.windfall.text == "WINDFALL", "the chosen doctrine's edict shows, ready")
	expect(not draft.edict_chips.levy.visible, "the card not taken grants nothing")
	state.edict_ready[7] = tick + 150
	draft:refresh()
	expect(draft.edict_chips.windfall.text:find("WINDFALL ", 1, true) == 1 and draft.edict_chips.windfall.text ~= "WINDFALL", "while it cools the chip counts down (" .. draft.edict_chips.windfall.text .. ")")
	sent = {}
	draft.edict_chips.windfall.pressed:Fire()
	expect(#sent == 1 and sent[1].type == "edict" and sent[1].kind == "windfall", "a press sends the edict intent")
	state.phase = Defs.PHASE_OVER
	draft:refresh()
	expect(not draft.edict_chips.windfall.visible, "no chip once the match is over")
end

if fails > 0 then
	print("ui_doctrine: " .. fails .. " FAILED")
	require("@lune/process").exit(1)
end
print("ui_doctrine: all passed")
