--!strict
-- A separate experience to test changes in before they go live: set its universe id here if you make one (what
-- differs there: Data/Products' ids, the game menu's "Replay as new player").
local Staging = {}

--- The staging experience's universe id (none yet).
Staging.UNIVERSE = nil :: number?

--- True in the staging experience.
function Staging.here(): boolean
	return Staging.UNIVERSE ~= nil and typeof(game) == "Instance" and (game :: any).GameId == Staging.UNIVERSE
end

return Staging
