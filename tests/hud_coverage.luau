-- HudCoverage: the share of the screen a list of HUD rects covers.
-- Run: lune run tests/hud_coverage.luau
require("./prelude")
local C = require("../src/client/UI/HudCoverage")

local function near(a: number, b: number, what: string)
	assert(math.abs(a - b) < 1e-9, what .. ": got " .. tostring(a) .. ", want " .. tostring(b))
end

near(C.share({}, 100, 100), 0, "nothing")
near(C.share({ { x0 = 0, y0 = 0, x1 = 10, y1 = 10 } }, 100, 100), 0.01, "one box")
near(C.share({ { x0 = 0, y0 = 0, x1 = 10, y1 = 10 }, { x0 = 0, y0 = 0, x1 = 10, y1 = 10 } }, 100, 100), 0.01, "a repeat counts once")
near(C.share({ { x0 = 0, y0 = 0, x1 = 10, y1 = 10 }, { x0 = 5, y0 = 5, x1 = 15, y1 = 15 } }, 100, 100), 0.0175, "an overlap counts once")
near(C.share({ { x0 = 0, y0 = 0, x1 = 10, y1 = 10 }, { x0 = 20, y0 = 20, x1 = 30, y1 = 30 } }, 100, 100), 0.02, "apart")
near(C.share({ { x0 = -50, y0 = -50, x1 = 10, y1 = 10 } }, 100, 100), 0.01, "clipped to the screen")
near(C.share({ { x0 = 0, y0 = 0, x1 = 100, y1 = 100 } }, 100, 100), 1, "all of it")
near(C.share({ { x0 = 5, y0 = 5, x1 = 5, y1 = 50 } }, 100, 100), 0, "an empty box")
assert(C.BUDGET_DESKTOP <= 0.15 and C.BUDGET_PHONE <= 0.1, "budgets stay tight")
print("hud_coverage: ok")
