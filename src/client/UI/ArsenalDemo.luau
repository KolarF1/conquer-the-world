--!nonstrict
-- The Arsenal's animated item previews (a nuke landing on a map, a shell flying) drew with the upstream's art: effect
-- flipbooks and map scenes uploaded to its account, and a model of each weapon. None of that is ours, so the previews
-- are off: no item has a `_build_<key>`, and the shop shows the item's own glyph large (UI/Arsenal, `demo == nil`).
-- New previews can be added here as `ArsenalDemo._build_<item key>` when there is art of our own to play.
local ArsenalDemo = {}

--- Nothing to fetch.
function ArsenalDemo.preload() end

--- No preview is built (Arsenal checks `ArsenalDemo["_build_" .. key]` first, so this is not reached).
function ArsenalDemo.new(): any?
	return nil
end

return ArsenalDemo
