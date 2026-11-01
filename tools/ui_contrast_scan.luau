-- Paste into Studio's Client datamodel (execute_luau) with a screen open: lists the text and icons on
-- it that barely show against what is drawn behind them. It asks Roblox what lies under each element's
-- centre (GetGuiObjectsAtPosition, topmost first), and blends down through the see-through layers.
--
-- A stroked label counts as readable when its stroke stands out. Anything over a part of the screen no
-- GUI covers (the map) is not judged: its background is the map's own colours.
local MIN_CONTRAST = 2.2
local pg = game:GetService("Players").LocalPlayer.PlayerGui

local function lin(c: number): number
	return if c <= 0.03928 then c / 12.92 else ((c + 0.055) / 1.055) ^ 2.4
end
local function lum(c: Color3): number
	return 0.2126 * lin(c.R) + 0.7152 * lin(c.G) + 0.0722 * lin(c.B)
end
local function contrast(a: Color3, b: Color3): number
	local x, y = lum(a), lum(b)
	return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

local function shown(g: GuiObject): boolean
	local n: Instance? = g
	while n ~= nil and n:IsA("GuiObject") do
		if not n.Visible then
			return false
		end
		n = n.Parent
	end
	local sg = g:FindFirstAncestorWhichIsA("ScreenGui")
	return sg ~= nil and sg.Enabled
end

--- The colour (and whether all of it is known) that lies behind g at its centre.
local function behind(g: GuiObject): (Color3?, number)
	local c = g.AbsolutePosition + g.AbsoluteSize * 0.5
	local list = pg:GetGuiObjectsAtPosition(c.X, c.Y)
	local seen = false
	local col, left = Color3.new(0, 0, 0), 1.0
	for _, o in list do
		if o == g then
			seen = true
		elseif seen and shown(o) and not g:IsAncestorOf(o) then
			local a, tint = 0.0, nil
			if o:IsA("ImageLabel") or o:IsA("ImageButton") then
				if o.Image ~= "" then
					a, tint = 1 - o.ImageTransparency, o.ImageColor3
				end
			end
			if a < 0.05 then
				a, tint = 1 - o.BackgroundTransparency, o.BackgroundColor3
			end
			if a >= 0.05 and tint ~= nil then
				col = Color3.new(col.R + tint.R * a * left, col.G + tint.G * a * left, col.B + tint.B * a * left)
				left *= 1 - a
				if left < 0.08 then
					return col, left
				end
			end
		end
	end
	return nil, left
end

local out = {}
for _, g in pg:GetDescendants() do
	if g:IsA("GuiObject") and shown(g) and g.AbsoluteSize.X > 2 and g.AbsoluteSize.Y > 2 then
		local fg, alpha, what = nil, 0, ""
		if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Text ~= "" then
			fg, alpha, what = g.TextColor3, 1 - g.TextTransparency, g.Text
		elseif (g:IsA("ImageLabel") or g:IsA("ImageButton")) and g.Image ~= "" and g.ImageRectSize.X > 0 and g.AbsoluteSize.X < 96 then
			fg, alpha, what = g.ImageColor3, 1 - g.ImageTransparency, "[icon " .. g.Name .. "]"
		end
		if fg ~= nil and alpha > 0.4 then
			local stroke = g:FindFirstChildOfClass("UIStroke")
			local bg = behind(g)
			if bg ~= nil then
				local ct = contrast(fg, bg)
				local ok = ct >= MIN_CONTRAST
				if not ok and stroke ~= nil and stroke.Transparency < 0.5 and contrast(stroke.Color, bg) >= MIN_CONTRAST then
					ok = true
				end
				if not ok then
					table.insert(out, string.format("%.1f  %s  (%s)", ct, what:sub(1, 40), g:GetFullName():sub(-44)))
				end
			end
		end
	end
end
table.sort(out)
return { count = #out, low = out }
