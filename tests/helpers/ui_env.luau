--!nocheck
-- The Roblox globals the UI kit needs to be BUILT under Lune (real Instances from @lune/roblox), exposed
-- per test, never in tests/prelude.luau: the prelude is shared by every inherited test, and some of the
-- code under test branches on whether it is running in Roblox. Call UIEnv.install() first, before any
-- require of a UI module.
local UIEnv = {}

function UIEnv.install()
	local roblox = require("../prelude")
	local env = getfenv(2) :: any
	for _, name in { "Instance", "Enum", "Font", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence", "ColorSequenceKeypoint", "TweenInfo", "UDim", "UDim2", "Vector2", "Rect" } do
		if (roblox :: any)[name] ~= nil then
			env[name] = (roblox :: any)[name]
		end
	end
	env.task = env.task or require("@lune/task")
	env.warn = env.warn or function() end
	return roblox
end

return UIEnv
