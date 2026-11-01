--!nocheck
-- Every shared module the UI asks for by name is in the folder it asks in: a wrong folder waits forever
-- in Roblox and stops the client at startup, and most UI files can't be loaded outside Roblox to find out.
local fs = require("@lune/fs")

local FOLDERS = { core = "src/shared/Core/", data = "src/shared/Data/" }
local fails, checked = 0, 0

for _, dir in { "src/client/UI/", "src/client/Map/" } do
	for _, file in fs.readDir(dir) do
		if string.sub(file, -5) == ".luau" then
			local src = fs.readFile(dir .. file)
			for kind, folder in FOLDERS do
				for name in string.gmatch(src, "UICtx%." .. kind .. '%("([%w_]+)"%)') do
					checked += 1
					if not fs.isFile(folder .. name .. ".luau") then
						fails += 1
						print(string.format("FAIL %s%s asks UICtx.%s for %s: not in %s", dir, file, kind, name, folder))
					end
				end
			end
		end
	end
end

print(string.format("  ok   %d shared module lookups checked", checked))
if checked < 10 then
	error("the check found almost nothing to check: has the lookup's spelling changed?")
end
if fails > 0 then
	error(tostring(fails) .. " failed")
end
