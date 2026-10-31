-- Audio keys -> OUR sounds. Only ids the owner uploaded for this game are used (the six SFX and two tracks of
-- legacy/conquest/docs/UPLOAD_ASSETS.md); a key with no good match is left out, and the director skips a missing key
-- (silent, never someone else's sound). More sounds: add the file to assets/audio, upload it (tools/assets/upload_ours.py
-- when a key is in .secrets/roblox_api_key), and add its id to docs/OWNED_ASSETS.txt and to RULES in this file's generator.
-- (generated; see tools/assets/make_our_audio.py)
return {
	music = {
		menu = { id = "rbxassetid://119425620491833", length = 180.0 },
		war = { id = "rbxassetid://73509293262264", length = 240.0 },
	},
	sfx = {
		boat_launch = { id = "rbxassetid://137499164850957", length = 0.5 },
		nuke_explosion = { id = "rbxassetid://126284092426471", length = 2.0 },
		nuke_launch = { id = "rbxassetid://126284092426471", length = 2.0 },
		sam_intercept = { id = "rbxassetid://122548385802638", length = 1.2 },
		sam_launch = { id = "rbxassetid://137499164850957", length = 0.5 },
		shell_fire = { id = "rbxassetid://137499164850957", length = 0.5 },
		warship = { id = "rbxassetid://90458037613275", length = 1.0 },
		alliance = { id = "rbxassetid://90458037613275", length = 1.0 },
		ally_request = { id = "rbxassetid://90458037613275", length = 1.0 },
		betrayal = { id = "rbxassetid://126284092426471", length = 2.0 },
		build = { id = "rbxassetid://122548385802638", length = 1.2 },
		conquer = { id = "rbxassetid://133770403709310", length = 3.0 },
		countdown_tick = { id = "rbxassetid://137499164850957", length = 0.5 },
		defeat = { id = "rbxassetid://140116904842751", length = 0.6 },
		expand = { id = "rbxassetid://137499164850957", length = 0.5 },
		game_start = { id = "rbxassetid://126284092426471", length = 2.0 },
		nuke_alarm = { id = "rbxassetid://126284092426471", length = 2.0 },
		order_ack = { id = "rbxassetid://137499164850957", length = 0.5 },
		spawn_confirm = { id = "rbxassetid://122548385802638", length = 1.2 },
		ui_click = { id = "rbxassetid://137499164850957", length = 0.5 },
		ui_error = { id = "rbxassetid://140116904842751", length = 0.6 },
		ui_open = { id = "rbxassetid://137499164850957", length = 0.5 },
		under_attack = { id = "rbxassetid://126284092426471", length = 2.0 },
		victory = { id = "rbxassetid://133770403709310", length = 3.0 },
	},
}
