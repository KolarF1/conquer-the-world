-- Audio keys -> OUR sounds. Only ids the owner uploaded for this game are used (the six SFX and two tracks of
-- legacy/conquest/docs/UPLOAD_ASSETS.md); a key with no good match is left out, and the director skips a missing key
-- (silent, never someone else's sound). More sounds: add the file to assets/audio, upload it (tools/assets/upload_ours.py
-- when a key is in .secrets/roblox_api_key), and add its id to docs/OWNED_ASSETS.txt and to RULES in this file's generator.
-- (generated; see tools/assets/make_our_audio.py)
return {
	sfx = {
		buy_spend = { id = "rbxassetid://122548385802638", length = 1.2 },
		eliminate = { id = "rbxassetid://140116904842751", length = 0.6 },
		expand_pop = { id = "rbxassetid://122548385802638", length = 1.2 },
		star_get = { id = "rbxassetid://133770403709310", length = 3.0 },
		star_tick = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_back = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_click = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_confirm = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_error = { id = "rbxassetid://140116904842751", length = 0.6 },
		ui_locked = { id = "rbxassetid://140116904842751", length = 0.6 },
		ui_open = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_tab = { id = "rbxassetid://137499164850957", length = 0.5 },
		unlock = { id = "rbxassetid://133770403709310", length = 3.0 },
	},
}
