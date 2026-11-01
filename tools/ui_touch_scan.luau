-- Paste in Client execute_luau with a screen open, on a touch preview: every visible button under the 44 logical px
-- touch target. Run the UI with workspace attribute AF_FORCE_TOUCH and CTW_CMD "phone 2"; SCALE is that UI scale.
-- Roblox's own top-bar row ("Bar") is raw px and stays out of the count.
local SCALE = 2
local pg = game:GetService("Players").LocalPlayer.PlayerGui
local function visible(o: Instance?): boolean
	while o ~= nil and o:IsA("GuiObject") do
		if not o.Visible then
			return false
		end
		o = o.Parent
	end
	return o ~= nil and (not o:IsA("ScreenGui") or o.Enabled)
end
local rows = {}
for _, b in pg:GetDescendants() do
	if b:IsA("GuiButton") and b.Name ~= "Blocker" and b.Parent.Name ~= "Bar" and visible(b) then
		local s = b.AbsoluteSize / SCALE
		if s.X > 0.5 and s.Y > 0.5 and (s.X < 43.5 or s.Y < 43.5) then
			table.insert(rows, string.format("%s/%s %dx%d", b.Parent.Name, b.Name, s.X, s.Y))
		end
	end
end
return #rows .. " under 44: " .. table.concat(rows, " ; ")
