-- Run in Studio's Edit datamodel with tools/studio_push.py serving: brings the place's scripts up to date, and removes
-- scripts no longer in the tree. Returns what changed.
local Http = game:GetService("HttpService")
local rows = Http:JSONDecode(Http:GetAsync("http://127.0.0.1:34999/manifest", true))
local changed, seen = {}, {}
for _, r in rows do
	local parts = string.split(r.path, "/")
	local node: Instance = game:GetService(parts[1])
	for i = 2, #parts do
		local child = node:FindFirstChild(parts[i])
		if child == nil then
			child = Instance.new(if i == #parts then r.kind else "Folder")
			child.Name = parts[i]
			child.Parent = node
		end
		node = child
	end
	seen[node] = true
	local s = node :: any
	if s.Source ~= r.source then
		s.Source = r.source
		table.insert(changed, r.path)
	end
end
for _, root in { game.ReplicatedStorage.Airfront, game.ServerScriptService.AirfrontServer, game.StarterPlayer.StarterPlayerScripts.AirfrontClient } do
	for _, d in root:GetDescendants() do
		if d:IsA("LuaSourceContainer") and not seen[d] then
			table.insert(changed, "removed " .. d:GetFullName())
			d:Destroy()
		end
	end
end
return #changed .. " changed: " .. table.concat(changed, ", ")
